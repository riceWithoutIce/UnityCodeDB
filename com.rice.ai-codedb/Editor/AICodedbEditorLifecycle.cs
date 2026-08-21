using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    [InitializeOnLoad]
    internal static class AICodedbEditorLifecycle
    {
        internal const int LeaseSchemaVersion = 1;
        internal const double HeartbeatIntervalSeconds = 5d;
        internal const int ConcurrentUpgradeStatusReadAttempts = 12;
        internal const int ConcurrentUpgradeRetryDelayMilliseconds = 250;
        internal const int MaximumCurrentInstanceAvailabilityRecoveryAttempts = 3;

        private const double ReconcileRetrySeconds = 30d;
        private const string ManagedBy = "com.rice.ai-codedb";
        private const string SessionIdKey = "Rice.AICodedb.EditorLifecycle.SessionId";
        private const string SessionCreatedAtKey = "Rice.AICodedb.EditorLifecycle.CreatedAtUtc";
        private const string LastProductStateKeyPrefix = "Rice.AICodedb.EditorLifecycle.LastProductState.";
        private const string LastPackageFingerprintKeyPrefix = "Rice.AICodedb.EditorLifecycle.LastPackageFingerprint.";
        private const string LastVerifiedReadyFingerprintKeyPrefix = "Rice.AICodedb.EditorLifecycle.LastVerifiedReadyFingerprint.";
        private const string PlayModeProductStateKeyPrefix = "Rice.AICodedb.EditorLifecycle.PlayModeProductState.";
        private const string PlayModePackageFingerprintKeyPrefix = "Rice.AICodedb.EditorLifecycle.PlayModePackageFingerprint.";

        private static string _projectRoot;
        private static AICodedbEditorExecutionContext _executionContext;
        private static string _projectIdentity;
        private static string _sessionId;
        private static string _sessionCreatedAtUtc;
        private static string _leasePath;
        private static int _editorPid;
        private static string _processStartTicks;
        private static bool _packageFingerprintChanged;
        private static double _nextHeartbeatAt;
        private static double _nextReconcileAt;
        private static int _reconcileInFlight;
        private static int _leaseRefreshInFlight;
        private static int _prerequisiteRecheckInFlight;
        private static int _leasePrerequisiteCurrent;
        private static string _missingPrerequisiteFingerprint = string.Empty;
        private static AICodedbProductState _lastProductState = AICodedbProductState.Starting;
        private static int _currentInstanceAvailabilityRecoveryAttempts;
        private static readonly object LeaseIoLock = new object();
        private static readonly AICodedbEditorBackgroundScheduler BackgroundScheduler =
            new AICodedbEditorBackgroundScheduler();
        private static bool _initialized;
        private static volatile bool _quitting;

        static AICodedbEditorLifecycle()
        {
            if (Application.isBatchMode)
                return;

            try
            {
                _projectRoot = ValidateProjectRoot(AICodedbPaths.ProjectRoot);
                _executionContext = AICodedbPaths.CaptureExecutionContext();
                _projectIdentity = CreateProjectIdentity(_projectRoot);
                _lastProductState = ReadPersistedProductState(_projectIdentity);
                _packageFingerprintChanged = ReadAndRecordPackageFingerprint(_projectIdentity);
                _sessionId = GetOrCreateSessionValue(SessionIdKey, () => Guid.NewGuid().ToString("N"));
                _sessionCreatedAtUtc = GetOrCreateSessionValue(SessionCreatedAtKey, () => DateTime.UtcNow.ToString("o"));
                // The immutable-instance engine owns the runtime lease location.
                // Do not create a legacy lease before a validated instance is selected.
                _leasePath = string.Empty;

                using (var process = Process.GetCurrentProcess())
                {
                    _editorPid = process.Id;
                    _processStartTicks = process.StartTime.ToUniversalTime().Ticks.ToString(CultureInfo.InvariantCulture);
                }

                EditorApplication.update -= OnEditorUpdate;
                EditorApplication.update += OnEditorUpdate;
                EditorApplication.quitting -= OnEditorQuitting;
                EditorApplication.quitting += OnEditorQuitting;
                EditorApplication.playModeStateChanged -= OnPlayModeStateChanged;
                EditorApplication.playModeStateChanged += OnPlayModeStateChanged;
                EditorApplication.delayCall += Initialize;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"CodeDB Editor lifecycle initialization was skipped: {exception.Message}");
            }
        }

        private static void Initialize()
        {
            if (!ShouldInitializeLifecycle(_quitting))
                return;

            _initialized = true;
            BackgroundScheduler.SetMaintenanceSuspended(IsPlayModeMaintenanceSuspended());
            _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            // The first pass must always classify prerequisites and the
            // selected instance before any lease can be published. Later
            // reload/resume paths use the persisted Ready short-circuit.
            BeginReconcile(true);
        }

        internal static bool ShouldInitializeLifecycle(bool quitting)
        {
            // The lease path is selected after prerequisite and current-instance
            // validation. It must not gate startup of the reconcile worker.
            return !quitting;
        }

        internal static bool TryGetCurrentEditorLeaseIdentity(
            out string sessionId,
            out int processId,
            out string processStartTicks)
        {
            sessionId = _sessionId;
            processId = _editorPid;
            processStartTicks = _processStartTicks;
            return !string.IsNullOrWhiteSpace(sessionId)
                && processId > 0
                && !string.IsNullOrWhiteSpace(processStartTicks);
        }

        [DidReloadScripts]
        private static void OnScriptsReloaded()
        {
            // A domain reload briefly invalidates IPC handles and process
            // observations. Reconnect only when the last stable state was not
            // Ready; a reload must not start a replacement/upgrade loop for an
            // already usable immutable instance.
            EditorApplication.delayCall += RequestReconcileIfNeeded;
        }

        private static void OnEditorUpdate()
        {
            if (!_initialized || _quitting || EditorApplication.timeSinceStartup < _nextHeartbeatAt)
                return;

            _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            var playTransition = IsPlayModeMaintenanceSuspended();
            BackgroundScheduler.SetMaintenanceSuspended(playTransition);
            if (playTransition)
            {
                // Keep the interactive Editor lease alive while maintenance is
                // suspended so the coordinator does not mistake Play mode for
                // an offline Editor. The write remains on the lease worker.
                if (_lastProductState != AICodedbProductState.MissingPrerequisite)
                    QueueLeaseRefresh();
                _nextReconcileAt = Math.Max(
                    _nextReconcileAt,
                    EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds);
                return;
            }
            if (_lastProductState == AICodedbProductState.MissingPrerequisite)
            {
                QueuePrerequisiteRecheck();
                return;
            }
            if (ShouldQueueScheduledReconcile(
                    EditorApplication.timeSinceStartup,
                    ref _nextReconcileAt,
                    false))
                BeginReconcile(false);
            QueueLeaseRefresh();
        }

        internal static bool ShouldRunScheduledReconcile(
            double now,
            ref double nextReconcileAt,
            Func<bool> backendNeedsReconcile)
        {
            if (now < nextReconcileAt)
                return false;

            nextReconcileAt = now + ReconcileRetrySeconds;
            return backendNeedsReconcile != null && backendNeedsReconcile();
        }

        internal static bool ShouldQueueScheduledReconcile(
            double now,
            ref double nextReconcileAt,
            bool maintenanceSuspended)
        {
            if (maintenanceSuspended || now < nextReconcileAt)
                return false;

            nextReconcileAt = now + ReconcileRetrySeconds;
            return true;
        }

        private static void OnPlayModeStateChanged(PlayModeStateChange state)
        {
            if (state == PlayModeStateChange.ExitingEditMode)
                RecordProductStateForPlayModeIfAbsent();
            else if (state == PlayModeStateChange.EnteredEditMode)
                ClearProductStateForPlayMode();

            var suspended = state != PlayModeStateChange.EnteredEditMode;
            BackgroundScheduler.SetMaintenanceSuspended(suspended);
            if (!suspended && !_quitting)
            {
                _nextReconcileAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
                if (ShouldForceAvailabilityReconcileAfterPlayModeResume(_lastProductState))
                {
                    // Play mode can interrupt the coordinator without a domain
                    // reload. Re-enter the same background worker so it can
                    // recover availability in place; the convergence plan
                    // keeps a current immutable instance from being replaced.
                    BeginReconcile(true);
                }
                else if (ShouldReconcileAfterPlayModeResume(_lastProductState))
                    BeginReconcile(false);
            }
        }

        private static void OnEditorQuitting()
        {
            _quitting = true;
            BackgroundScheduler.SetMaintenanceSuspended(true);
            EditorApplication.update -= OnEditorUpdate;
            EditorApplication.playModeStateChanged -= OnPlayModeStateChanged;
            try
            {
                DeleteEditorLease();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"CodeDB could not remove its Editor lease during shutdown: {exception.Message}");
            }
        }

        private static async void BeginReconcile(bool force)
        {
            if (_quitting)
                return;
            if (ShouldDeferReconcile(
                    EditorApplication.isCompiling,
                    EditorApplication.isUpdating,
                    IsPlayModeMaintenanceSuspended()))
            {
                _nextReconcileAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
                return;
            }
            if (Interlocked.CompareExchange(ref _reconcileInFlight, 1, 0) != 0)
                return;

            _nextReconcileAt = EditorApplication.timeSinceStartup + ReconcileRetrySeconds;
            try
            {
                var previousProductState = _lastProductState;
                var result = await BackgroundScheduler.QueueMaintenance(
                    canContinue => RunReconcileWorker(
                        _executionContext,
                        force,
                        previousProductState,
                        canContinue));
                if (result == null || _quitting)
                    return;
                if (result.HasProductState)
                {
                    _lastProductState = result.ProductState;
                    PersistProductState(_projectIdentity, result.ProductState);
                }
                if (result.RetrySoon)
                {
                    _nextReconcileAt = Math.Min(
                        _nextReconcileAt,
                        EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds);
                }
                if (!string.IsNullOrWhiteSpace(result.Warning))
                    Debug.LogWarning(result.Warning);
            }
            catch (Exception exception)
            {
                if (!_quitting)
                    Debug.LogWarning($"CodeDB Editor lifecycle reconcile failed: {exception.Message}");
            }
            finally
            {
                Interlocked.Exchange(ref _reconcileInFlight, 0);
            }
        }

        private static LifecycleReconcileResult RunReconcileWorker(
            AICodedbEditorExecutionContext context,
            bool force,
            AICodedbProductState previousProductState,
            Func<bool> canContinue)
        {
            if (!canContinue() || (!force && !BackendNeedsReconcile(context, previousProductState)))
                return null;

            var integrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
            if (integrationStatus.State == AICodedbProjectIntegrationState.Invalid)
            {
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                DeleteEditorLease();
                return LifecycleReconcileResult.WithWarning(
                    AICodedbProductState.NeedsAttention,
                    "CodeDB project integration desired state is invalid: " + integrationStatus.Detail);
            }
            if (ShouldRunAutomaticUninstallCleanup(integrationStatus))
            {
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                DeleteEditorLease();
                if (!canContinue())
                    return LifecycleReconcileResult.WithState(AICodedbProductState.Uninstalled);
                var cleanupResult = AICodedbHostPayloadMaterializer.RunUpgrade(context);
                return cleanupResult.Succeeded
                    ? LifecycleReconcileResult.WithState(AICodedbProductState.Uninstalled)
                    : LifecycleReconcileResult.WithWarning(
                        AICodedbProductState.Uninstalled,
                        $"CodeDB automatic uninstall cleanup failed: {cleanupResult.GetSummary()} {cleanupResult.StandardError}".Trim());
            }
            if (integrationStatus.IsUninstalled)
            {
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                DeleteEditorLease();
                return LifecycleReconcileResult.WithState(AICodedbProductState.Uninstalled);
            }

            if (!canContinue())
                return null;
            var hostResult = AICodedbHostPayloadMaterializer.ReadStatus(context);
            var hostStatus = BuildHostPayloadStatus(hostResult, context);
            var productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, hostResult);
            var workerResult = LifecycleReconcileResult.WithState(productStatus.State);
            if (productStatus.State == AICodedbProductState.MissingPrerequisite)
            {
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                Interlocked.Exchange(
                    ref _missingPrerequisiteFingerprint,
                    CaptureMachinePrerequisiteEvidenceFingerprint(context));
                return workerResult;
            }
            if (!ApplyPrerequisiteGatedLeaseRefresh(
                    integrationStatus,
                    productStatus,
                    () =>
                    {
                        Interlocked.Exchange(ref _leasePrerequisiteCurrent, 1);
                        Interlocked.Exchange(ref _missingPrerequisiteFingerprint, string.Empty);
                        RefreshEditorLeaseForIntegrationState(context);
                    }))
            {
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                return workerResult;
            }
            if (!canContinue())
                return workerResult;

            // Automatic lifecycle convergence is instance-first. The legacy
            // flat/generation path remains available to diagnostics, but it
            // must not be selected after a Package reload.
            var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot);
            if (currentInstance.Present && !currentInstance.IsCurrent)
            {
                Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                workerResult.ProductState = AICodedbProductState.NeedsAttention;
                workerResult.Warning = "CodeDB current instance identity is invalid: " + currentInstance.Detail;
                return workerResult;
            }
            if (!currentInstance.Present || currentInstance.IsCurrent)
            {
                var convergencePlan = ResolveCurrentInstanceConvergencePlan(
                    currentInstance.Present,
                    currentInstance.IsCurrent,
                    productStatus);
                if (convergencePlan == AICodedbCurrentInstanceConvergencePlan.Deploy)
                {
                    Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                    if (!canContinue())
                        return workerResult;
                    var instanceResult = AICodedbHostPayloadMaterializer.RunUpgrade(context);
                    productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, instanceResult);
                    workerResult.ProductState = productStatus.State;
                    if (!canContinue())
                        return workerResult;
                    var verifiedInstanceResult = AICodedbHostPayloadMaterializer.ReadStatus(context);
                    productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, verifiedInstanceResult);
                    workerResult.ProductState = productStatus.State;
                    if (productStatus.State == AICodedbProductState.Ready)
                    {
                        RefreshEditorLeaseForIntegrationState(context);
                        return workerResult;
                    }
                    workerResult.Warning =
                        $"CodeDB automatic instance convergence failed: {instanceResult.GetSummary()} {instanceResult.StandardError}".Trim();
                    return workerResult;
                }

                if (convergencePlan == AICodedbCurrentInstanceConvergencePlan.RecoverAvailability)
                {
                    return RecoverCurrentInstanceAvailability(
                        context,
                        integrationStatus,
                        canContinue);
                }

                Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                RefreshEditorLeaseForIntegrationState(context);
                return workerResult;
            }

            var watcherEnsured = false;
            var availabilityConvergedByUpgrade = false;
            var upgradeStatus = AICodedbHostUpgradeStatusStore.Read(
                context.ProjectRoot,
                AICodedbProjectSettings.CurrentGenerationId);
            if (hostStatus.IsCurrent && ShouldRunAutomaticGenerationCleanup(
                    upgradeStatus,
                    AICodedbProjectSettings.CurrentGenerationId))
            {
                if (!canContinue())
                    return workerResult;
                var cleanupResult = AICodedbHostPayloadMaterializer.RunUpgrade(context);
                productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, cleanupResult);
                workerResult.ProductState = productStatus.State;
                if (!canContinue())
                    return workerResult;
                hostStatus = ReadHostStatusAfterUpgrade(
                    context,
                    cleanupResult,
                    canContinue,
                    ConcurrentUpgradeStatusReadAttempts);
                if (!hostStatus.IsCurrent)
                {
                    if (!IsConcurrentUpgrade(cleanupResult))
                    {
                        workerResult.Warning =
                            $"CodeDB automatic generation cleanup failed: {cleanupResult.GetSummary()} {cleanupResult.StandardError}".Trim();
                    }
                    else
                    {
                        workerResult.RetrySoon = true;
                    }
                    return workerResult;
                }
                availabilityConvergedByUpgrade = cleanupResult.Succeeded && productStatus.IsReady;
                watcherEnsured = availabilityConvergedByUpgrade;
            }
            else if (hostStatus.CanUpgradeAutomatically)
            {
                var updatePolicy = AICodedbHostUpdatePolicyStore.Read(context.ProjectRoot);
                if (!updatePolicy.IsValid)
                {
                    workerResult.Warning = "CodeDB automatic host update policy is invalid: " + updatePolicy.Detail;
                }
                else if (updatePolicy.IsEnabled && !IsAutomaticHostUpgradeSuppressed(
                             upgradeStatus,
                             AICodedbProjectSettings.CurrentGenerationId))
                {
                    if (!canContinue())
                        return workerResult;
                    var upgradeResult = AICodedbHostPayloadMaterializer.RunUpgrade(context);
                    productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, upgradeResult);
                    workerResult.ProductState = productStatus.State;
                    if (!canContinue())
                        return workerResult;
                    hostStatus = ReadHostStatusAfterUpgrade(
                        context,
                        upgradeResult,
                        canContinue,
                        ConcurrentUpgradeStatusReadAttempts);
                    if (!hostStatus.IsCurrent)
                    {
                        if (!IsConcurrentUpgrade(upgradeResult))
                        {
                            workerResult.Warning =
                                $"CodeDB automatic host upgrade failed: {upgradeResult.GetSummary()} {upgradeResult.StandardError}".Trim();
                        }
                        else
                        {
                            workerResult.RetrySoon = true;
                        }
                        return workerResult;
                    }
                    availabilityConvergedByUpgrade = upgradeResult.Succeeded && productStatus.IsReady;
                    watcherEnsured = availabilityConvergedByUpgrade;
                }
            }

            if (!canContinue())
                return workerResult;
            var generation = AICodedbHostGenerationStore.Resolve(context.ProjectRoot, context.PackageRoot);
            if (!CanEnsureHostGeneration(hostStatus, generation.State))
                return workerResult;

            if (ShouldRunAvailabilityConvergence(hostStatus, availabilityConvergedByUpgrade))
            {
                if (!canContinue())
                    return workerResult;
                AICodedbCommandResult ensureResult;
                var convergenceResult = RunWatcherThenAvailability(
                    canContinue,
                    () => AICodedbActions.RunEnsureWatcher(context),
                    () => productStatus.Configured == AICodedbProductLayerState.Current
                        ? AICodedbHostPayloadMaterializer.RunProbe(context)
                        : AICodedbHostPayloadMaterializer.RunUpgrade(context),
                    out ensureResult);
                if (!ensureResult.Succeeded)
                {
                    workerResult.ProductState = AICodedbProductState.NeedsAttention;
                    workerResult.Warning =
                        $"CodeDB Editor lifecycle reconcile failed: {ensureResult.GetSummary()} {ensureResult.StandardError}".Trim();
                    return workerResult;
                }
                watcherEnsured = true;
                if (convergenceResult == null)
                    return workerResult;
                productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, convergenceResult);
                workerResult.ProductState = productStatus.State;
                if (!convergenceResult.Succeeded)
                {
                    workerResult.Warning =
                        $"CodeDB automatic project availability convergence failed: {convergenceResult.GetSummary()} {convergenceResult.StandardError}".Trim();
                    return workerResult;
                }

                if (!canContinue())
                    return workerResult;
                var verifiedResult = AICodedbHostPayloadMaterializer.ReadStatus(context);
                productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, verifiedResult);
                workerResult.ProductState = productStatus.State;
                if (!productStatus.IsReady)
                {
                    workerResult.Warning =
                        "CodeDB automatic convergence completed without reaching Ready: " + productStatus.Detail;
                    return workerResult;
                }
            }

            if (!watcherEnsured)
            {
                if (!canContinue())
                    return workerResult;
                var ensureResult = AICodedbActions.RunEnsureWatcher(context);
                if (!ensureResult.Succeeded)
                {
                    workerResult.ProductState = AICodedbProductState.NeedsAttention;
                    workerResult.Warning =
                        $"CodeDB Editor lifecycle reconcile failed: {ensureResult.GetSummary()} {ensureResult.StandardError}".Trim();
                }
            }
            return workerResult;
        }

        internal static AICodedbCommandResult RunWatcherThenAvailability(
            Func<bool> canContinue,
            Func<AICodedbCommandResult> ensureWatcher,
            Func<AICodedbCommandResult> availability,
            out AICodedbCommandResult ensureResult)
        {
            if (canContinue == null)
                throw new ArgumentNullException(nameof(canContinue));
            if (ensureWatcher == null)
                throw new ArgumentNullException(nameof(ensureWatcher));
            if (availability == null)
                throw new ArgumentNullException(nameof(availability));

            ensureResult = ensureWatcher();
            if (!ensureResult.Succeeded || !canContinue())
                return null;
            return availability();
        }

        internal static bool ShouldRunAvailabilityConvergence(
            AICodedbHostPayloadStatus hostStatus,
            bool availabilityConvergedByUpgrade)
        {
            return hostStatus.IsCurrent && !availabilityConvergedByUpgrade;
        }

        private static bool BackendNeedsReconcile(
            AICodedbEditorExecutionContext context,
            AICodedbProductState lastProductState)
        {
            var integrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
            if (ShouldRunAutomaticUninstallCleanup(integrationStatus))
                return true;
            if (integrationStatus.IsUninstalled)
                return false;
            if (!integrationStatus.IsValid)
                return false;
            if (!ShouldInspectBackendForScheduledReconcile(lastProductState))
                return false;
            var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot);
            if (!currentInstance.Present)
                return true;
            if (!currentInstance.IsCurrent)
                return false;
            return ShouldRunInstalledInstanceConvergence(
                currentInstance.Present,
                currentInstance.IsCurrent,
                lastProductState,
                integrationStatus.CleanupState);
        }

        internal static bool ShouldRunInstalledInstanceConvergence(
            bool currentInstancePresent,
            bool currentInstanceIsCurrent,
            AICodedbProductState productState,
            AICodedbProjectCleanupState cleanupState)
        {
            // A Ready current instance remains usable while retired instances
            // wait for their owners to drain. Cleanup must not redeploy the
            // current instance or start a full convergence loop.
            _ = cleanupState;
            if (!currentInstancePresent)
                return true;
            return currentInstanceIsCurrent && productState != AICodedbProductState.Ready;
        }

        internal static AICodedbCurrentInstanceConvergencePlan ResolveCurrentInstanceConvergencePlan(
            bool currentInstancePresent,
            bool currentInstanceIsCurrent,
            AICodedbProductStatus productStatus)
        {
            if (!currentInstancePresent)
                return AICodedbCurrentInstanceConvergencePlan.Deploy;
            if (!currentInstanceIsCurrent)
                return AICodedbCurrentInstanceConvergencePlan.Blocked;
            if (productStatus.State == AICodedbProductState.Ready)
                return AICodedbCurrentInstanceConvergencePlan.None;
            if (productStatus.Prerequisite != AICodedbProductLayerState.Current)
                return AICodedbCurrentInstanceConvergencePlan.Blocked;

            if (productStatus.Installed == AICodedbProductLayerState.Current
                && productStatus.Configured == AICodedbProductLayerState.Current)
            {
                return productStatus.McpAvailable == AICodedbProductLayerState.Unavailable
                       || productStatus.McpAvailable == AICodedbProductLayerState.Pending
                    ? AICodedbCurrentInstanceConvergencePlan.RecoverAvailability
                    : AICodedbCurrentInstanceConvergencePlan.Blocked;
            }

            return AICodedbCurrentInstanceConvergencePlan.Deploy;
        }

        private static LifecycleReconcileResult RecoverCurrentInstanceAvailability(
            AICodedbEditorExecutionContext context,
            AICodedbProjectIntegrationStatus integrationStatus,
            Func<bool> canContinue)
        {
            if (!canContinue())
                return null;

            AICodedbCommandResult ensureResult;
            var probeResult = RunWatcherThenAvailability(
                canContinue,
                () => AICodedbActions.RunEnsureWatcher(context),
                () => AICodedbHostPayloadMaterializer.RunProbe(context),
                out ensureResult);
            if (probeResult == null)
            {
                if (ensureResult == null || ensureResult.Succeeded || !canContinue())
                    return null;

                var failedAttempt = Interlocked.Increment(ref _currentInstanceAvailabilityRecoveryAttempts);
                if (failedAttempt < MaximumCurrentInstanceAvailabilityRecoveryAttempts)
                {
                    var retryAfterEnsureFailure = LifecycleReconcileResult.WithState(AICodedbProductState.Starting);
                    retryAfterEnsureFailure.RetrySoon = true;
                    return retryAfterEnsureFailure;
                }

                return LifecycleReconcileResult.WithWarning(
                    AICodedbProductState.NeedsAttention,
                    "CodeDB could not restore current-instance availability: "
                    + $"{ensureResult.GetSummary()} {ensureResult.StandardError}".Trim());
            }

            var productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, probeResult);
            if (productStatus.IsReady)
            {
                Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                RefreshEditorLeaseForIntegrationState(context);
                return LifecycleReconcileResult.WithState(AICodedbProductState.Ready);
            }

            var attempt = Interlocked.Increment(ref _currentInstanceAvailabilityRecoveryAttempts);
            if (attempt < MaximumCurrentInstanceAvailabilityRecoveryAttempts)
            {
                var retry = LifecycleReconcileResult.WithState(AICodedbProductState.Starting);
                retry.RetrySoon = true;
                return retry;
            }

            var detail = ensureResult.Succeeded
                ? productStatus.Detail
                : $"{ensureResult.GetSummary()} {ensureResult.StandardError}".Trim();
            return LifecycleReconcileResult.WithWarning(
                AICodedbProductState.NeedsAttention,
                "CodeDB could not restore current-instance availability without replacing the instance: " + detail);
        }

        internal static bool ShouldInspectBackendForScheduledReconcile(
            AICodedbProductState lastProductState)
        {
            return lastProductState != AICodedbProductState.MissingPrerequisite;
        }

        internal static bool ShouldReconcileCoordinator(
            bool currentPointerExists,
            AICodedbHostGenerationState generationState,
            string selectedGenerationId,
            int coordinatorPid,
            string coordinatorGenerationId,
            Func<int, bool> processAliveProvider)
        {
            if (currentPointerExists
                && generationState != AICodedbHostGenerationState.Current
                && generationState != AICodedbHostGenerationState.Previous
                && generationState != AICodedbHostGenerationState.DowngradeReviewRequired)
                return true;
            if (coordinatorPid <= 0)
                return true;
            if ((generationState == AICodedbHostGenerationState.Current
                 || generationState == AICodedbHostGenerationState.Previous
                 || generationState == AICodedbHostGenerationState.DowngradeReviewRequired)
                && !string.Equals(coordinatorGenerationId, selectedGenerationId, StringComparison.Ordinal))
                return true;
            if (processAliveProvider == null)
                return true;
            return !processAliveProvider(coordinatorPid);
        }

        internal static bool CanEnsureHostGeneration(
            AICodedbHostPayloadStatus hostStatus,
            AICodedbHostGenerationState generationState)
        {
            return hostStatus.IsCurrent
                   || generationState == AICodedbHostGenerationState.Legacy;
        }

        internal static bool ShouldDeferReconcile(bool isCompiling, bool isUpdating)
        {
            return ShouldDeferReconcile(isCompiling, isUpdating, false);
        }

        internal static bool ShouldDeferReconcile(
            bool isCompiling,
            bool isUpdating,
            bool isPlayingOrWillChangePlaymode)
        {
            return isCompiling || isUpdating || isPlayingOrWillChangePlaymode;
        }

        internal static bool IsPlayModeMaintenanceSuspended(
            bool editorPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            // During a domain reload Unity can briefly report the editor flag
            // as false even though the runtime is already in Play mode. Treat
            // either signal as suspended so no reconcile or lease/status I/O
            // is started in that window.
            return editorPlayingOrWillChangePlaymode || applicationPlaying;
        }

        private static bool IsPlayModeMaintenanceSuspended()
        {
            return IsPlayModeMaintenanceSuspended(
                EditorApplication.isPlayingOrWillChangePlaymode,
                Application.isPlaying);
        }

        internal static bool ShouldReconcileAutomaticHostUpgrade(
            bool markerExists,
            bool currentPointerExists,
            AICodedbHostGenerationState generationState,
            AICodedbHostUpdatePolicy updatePolicy,
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            if (!updatePolicy.IsValid || !updatePolicy.IsEnabled)
                return false;
            if (generationState == AICodedbHostGenerationState.DowngradeReviewRequired)
                return false;
            if (IsAutomaticHostUpgradeSuppressed(upgradeStatus, currentGenerationId))
                return false;
            if (!markerExists)
            {
                return !currentPointerExists
                       && generationState == AICodedbHostGenerationState.Unavailable;
            }
            if (generationState == AICodedbHostGenerationState.Legacy)
                return true;
            return generationState != AICodedbHostGenerationState.Current;
        }

        internal static bool ShouldRunAutomaticGenerationCleanup(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            return upgradeStatus.Phase == AICodedbHostUpgradePhase.Current
                   && upgradeStatus.CleanupState == AICodedbProjectCleanupState.Pending
                   && !string.IsNullOrWhiteSpace(currentGenerationId)
                   && string.Equals(
                       upgradeStatus.GenerationId,
                       currentGenerationId,
                       StringComparison.Ordinal);
        }

        internal static bool IsAutomaticHostUpgradeSuppressed(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            return upgradeStatus.Phase == AICodedbHostUpgradePhase.CheckFailed
                   && !string.IsNullOrWhiteSpace(currentGenerationId)
                   && string.Equals(
                       upgradeStatus.GenerationId,
                       currentGenerationId,
                       StringComparison.Ordinal);
        }

        private static bool IsProcessAlive(int processId)
        {
            try
            {
                using (var process = Process.GetProcessById(processId))
                    return !process.HasExited;
            }
            catch
            {
                return false;
            }
        }

        internal static void RequestReconcile()
        {
            _nextReconcileAt = 0d;
            if (_initialized
                && !_quitting
                && !IsPlayModeMaintenanceSuspended())
                BeginReconcile(true);
        }

        private static void RequestReconcileIfNeeded()
        {
            if (!_initialized
                || _quitting
                || IsPlayModeMaintenanceSuspended())
                return;

            _nextReconcileAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            if (ShouldForceAvailabilityReconcileAfterPlayModeResume(_lastProductState))
                BeginReconcile(true);
            else if (ShouldReconcileAfterPlayModeResume(_lastProductState))
                BeginReconcile(false);
        }

        internal static bool ShouldReconcileAfterPlayModeResume(AICodedbProductState previousProductState)
        {
            return previousProductState != AICodedbProductState.Ready
                   && previousProductState != AICodedbProductState.MissingPrerequisite
                   && previousProductState != AICodedbProductState.Uninstalled;
        }

        internal static bool ShouldForceAvailabilityReconcileAfterPlayModeResume(
            AICodedbProductState previousProductState)
        {
            return previousProductState == AICodedbProductState.Ready;
        }

        private static AICodedbProductState ReadPersistedProductState(string projectIdentity)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return AICodedbProductState.Starting;

            var value = SessionState.GetString(LastProductStateKeyPrefix + projectIdentity, string.Empty);
            AICodedbProductState state;
            return Enum.TryParse(value, false, out state)
                ? state
                : AICodedbProductState.Starting;
        }

        private static void PersistProductState(string projectIdentity, AICodedbProductState state)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return;

            SessionState.SetString(LastProductStateKeyPrefix + projectIdentity, state.ToString());
            if (state == AICodedbProductState.Ready)
            {
                SessionState.SetString(
                    LastVerifiedReadyFingerprintKeyPrefix + projectIdentity,
                    GetCurrentPackageFingerprint());
            }
            else if (state == AICodedbProductState.NeedsAttention
                     || state == AICodedbProductState.MissingPrerequisite
                     || state == AICodedbProductState.Uninstalled)
            {
                SessionState.SetString(LastVerifiedReadyFingerprintKeyPrefix + projectIdentity, string.Empty);
            }
        }

        internal static bool HasVerifiedReadyForCurrentPackage()
        {
            if (string.IsNullOrWhiteSpace(_projectIdentity))
                return false;
            var fingerprint = SessionState.GetString(
                LastVerifiedReadyFingerprintKeyPrefix + _projectIdentity,
                string.Empty);
            return string.Equals(fingerprint, GetCurrentPackageFingerprint(), StringComparison.Ordinal);
        }

        /// <summary>
        /// Returns whether the last completed lifecycle result is a verified
        /// Ready state that may be displayed while Play mode suspends live
        /// maintenance. This is SessionState-only and deliberately performs
        /// no project or process I/O.
        /// </summary>
        internal static bool CanUsePersistedReadyStateDuringPlay()
        {
            AICodedbProductState state;
            if (TryGetProductStateForPlayMode(out state))
                return state == AICodedbProductState.Ready;
            return HasVerifiedReadyForCurrentPackage();
        }

        /// <summary>
        /// Captures the Manager's last displayed product state before Play.
        /// SessionState survives a Play-mode domain reload without touching
        /// project files or starting a process.
        /// </summary>
        internal static void RecordProductStateForPlayMode(AICodedbProductState state)
        {
            if (string.IsNullOrWhiteSpace(_projectIdentity))
                return;

            // The Manager can receive ExitingEditMode while its most recent
            // worker callback is still Starting. Preserve the stronger
            // same-package Ready observation instead of replacing it with a
            // transient state just before Domain Reload.
            if (state == AICodedbProductState.Starting
                && HasVerifiedReadyForCurrentPackage())
            {
                state = AICodedbProductState.Ready;
            }

            SessionState.SetString(
                PlayModeProductStateKeyPrefix + _projectIdentity,
                state.ToString());
            SessionState.SetString(
                PlayModePackageFingerprintKeyPrefix + _projectIdentity,
                GetCurrentPackageFingerprint());
        }

        internal static bool TryGetProductStateForPlayMode(out AICodedbProductState state)
        {
            state = AICodedbProductState.Starting;
            if (string.IsNullOrWhiteSpace(_projectIdentity))
                return false;

            var fingerprint = SessionState.GetString(
                PlayModePackageFingerprintKeyPrefix + _projectIdentity,
                string.Empty);
            if (!string.Equals(fingerprint, GetCurrentPackageFingerprint(), StringComparison.Ordinal))
                return false;

            var value = SessionState.GetString(
                PlayModeProductStateKeyPrefix + _projectIdentity,
                string.Empty);
            if (Enum.TryParse(value, false, out state))
            {
                if (state == AICodedbProductState.Starting
                    && HasVerifiedReadyForCurrentPackage())
                {
                    state = AICodedbProductState.Ready;
                }
                return true;
            }

            // The Manager may have verified Ready immediately before a domain
            // reload, before the play-mode callback could publish the display
            // state. Keep that stronger same-package evidence usable.
            if (HasVerifiedReadyForCurrentPackage())
            {
                state = AICodedbProductState.Ready;
                return true;
            }
            return false;
        }

        private static void RecordProductStateForPlayModeIfAbsent()
        {
            AICodedbProductState ignored;
            if (TryGetProductStateForPlayMode(out ignored))
                return;
            RecordProductStateForPlayMode(_lastProductState);
        }

        private static void ClearProductStateForPlayMode()
        {
            if (string.IsNullOrWhiteSpace(_projectIdentity))
                return;
            SessionState.SetString(PlayModeProductStateKeyPrefix + _projectIdentity, string.Empty);
            SessionState.SetString(PlayModePackageFingerprintKeyPrefix + _projectIdentity, string.Empty);
        }

        /// <summary>
        /// Records a verified Ready result for the current package in
        /// SessionState so a Manager domain reload during Play can retain the
        /// same display without performing project I/O.
        /// </summary>
        internal static void RecordVerifiedReadyForCurrentPackage()
        {
            if (string.IsNullOrWhiteSpace(_projectIdentity))
                return;
            // The Manager's complete read-only snapshot is an independent
            // Ready observation. The background lifecycle may still be
            // finishing the same convergence pass (or may have reported a
            // transient state), so do not discard this evidence merely because
            // its last worker result is not Ready yet.
            _lastProductState = AICodedbProductState.Ready;
            PersistProductState(_projectIdentity, AICodedbProductState.Ready);
        }

        internal static bool ShouldUsePersistedReadyStateDuringPlay(
            AICodedbProductState lastProductState,
            bool packageFingerprintMatches)
        {
            // A verified Manager snapshot can race the lifecycle worker and
            // leave its latest result at Starting. That is still safe to show
            // during Play because the separate package fingerprint is the
            // durable proof that Ready was observed. Terminal states remain
            // fail-closed and cannot inherit the old display.
            return (lastProductState == AICodedbProductState.Ready
                    || lastProductState == AICodedbProductState.Starting)
                   && packageFingerprintMatches;
        }

        internal static bool IsReconcileInFlight => Volatile.Read(ref _reconcileInFlight) != 0;

        private static bool ReadAndRecordPackageFingerprint(string projectIdentity)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return true;

            var fingerprint = GetCurrentPackageFingerprint();
            var key = LastPackageFingerprintKeyPrefix + projectIdentity;
            var previous = SessionState.GetString(key, string.Empty);
            SessionState.SetString(key, fingerprint);
            return !string.Equals(previous, fingerprint, StringComparison.Ordinal);
        }

        private static string GetCurrentPackageFingerprint()
        {
            return string.Join(
                "|",
                AICodedbProjectSettings.CurrentPackageVersion,
                AICodedbProjectSettings.CurrentPayloadVersion,
                AICodedbProjectSettings.CurrentGenerationId,
                AICodedbProjectSettings.CurrentPayloadSequence.ToString(CultureInfo.InvariantCulture));
        }

        internal static bool ShouldPublishEditorLease(AICodedbProjectIntegrationStatus integrationStatus)
        {
            return integrationStatus.State == AICodedbProjectIntegrationState.Installed;
        }

        internal static bool ShouldPublishEditorLeaseAfterPrerequisite(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbProductStatus productStatus)
        {
            return ShouldPublishEditorLease(integrationStatus)
                   && productStatus.Prerequisite == AICodedbProductLayerState.Current;
        }

        internal static bool ApplyPrerequisiteGatedLeaseRefresh(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbProductStatus productStatus,
            Action refreshLease)
        {
            if (refreshLease == null)
                throw new ArgumentNullException(nameof(refreshLease));
            if (!ShouldPublishEditorLeaseAfterPrerequisite(integrationStatus, productStatus))
                return false;
            refreshLease();
            return true;
        }

        internal static bool ShouldRunAutomaticUninstallCleanup(AICodedbProjectIntegrationStatus integrationStatus)
        {
            return integrationStatus.State == AICodedbProjectIntegrationState.Uninstalled
                   && integrationStatus.CleanupState == AICodedbProjectCleanupState.Pending;
        }

        internal static bool ShouldRefreshEditorLease(
            bool prerequisiteCurrent,
            bool reconcileInFlight,
            bool quitting)
        {
            // Keep the argument for the existing test/API boundary; it is
            // intentionally not a heartbeat suppression signal.
            _ = reconcileInFlight;
            // Lease liveness is independent from the maintenance worker. A
            // long materialization/reconcile must not let the coordinator
            // reclaim an otherwise valid interactive Editor session.
            return prerequisiteCurrent && !quitting;
        }

        /// <summary>
        /// Publishes the current interactive Editor lease immediately before
        /// an explicit watcher command. Automatic reconciliation establishes
        /// prerequisite safety first; this method never bypasses that gate.
        /// </summary>
        internal static bool TryPrepareCurrentEditorLease(
            AICodedbEditorExecutionContext context,
            out string detail)
        {
            detail = string.Empty;
            if (_quitting)
            {
                detail = "The Unity Editor is closing.";
                return false;
            }
            if (Volatile.Read(ref _leasePrerequisiteCurrent) == 0)
            {
                // A Manager can be opened before the first background pass has
                // published the lease. Reuse the read-only materializer status
                // as the prerequisite gate so an explicit Start does not lose
                // a race with Editor initialization.
                try
                {
                    var integrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
                    var statusResult = AICodedbHostPayloadMaterializer.ReadStatus(context);
                    var productStatus = AICodedbProductStatusBuilder.Build(
                        integrationStatus,
                        statusResult);
                    if (!ShouldPublishEditorLeaseAfterPrerequisite(integrationStatus, productStatus))
                    {
                        detail = productStatus.State == AICodedbProductState.MissingPrerequisite
                            ? "CodeDB dependencies are still being configured. Complete Configure Dependencies, then try again."
                            : "The current Editor session is still starting. Wait for CodeDB status to finish loading, then try again.";
                        return false;
                    }
                    Interlocked.Exchange(ref _leasePrerequisiteCurrent, 1);
                }
                catch (Exception exception)
                {
                    detail = "The current Editor session is still starting: " + exception.Message;
                    return false;
                }
            }

            try
            {
                RefreshEditorLeaseForIntegrationState(context);
                lock (LeaseIoLock)
                {
                    if (!string.IsNullOrWhiteSpace(_leasePath) && File.Exists(_leasePath))
                        return true;
                }

                detail = "CodeDB could not publish the current Editor session lease.";
                return false;
            }
            catch (Exception exception)
            {
                detail = "CodeDB could not prepare the current Editor session: " + exception.Message;
                return false;
            }
        }

        internal static bool ShouldTriggerPrerequisiteRecheck(
            string recordedFingerprint,
            string observedFingerprint)
        {
            return !string.IsNullOrWhiteSpace(recordedFingerprint)
                   && !string.IsNullOrWhiteSpace(observedFingerprint)
                   && !string.Equals(recordedFingerprint, observedFingerprint, StringComparison.Ordinal);
        }

        private static async void QueueLeaseRefresh()
        {
            if (!ShouldRefreshEditorLease(
                    Volatile.Read(ref _leasePrerequisiteCurrent) != 0,
                    Volatile.Read(ref _reconcileInFlight) != 0,
                    _quitting)
                || Interlocked.CompareExchange(ref _leaseRefreshInFlight, 1, 0) != 0)
                return;
            try
            {
                await BackgroundScheduler.QueueLease(() =>
                {
                    if (ShouldRefreshEditorLease(
                            Volatile.Read(ref _leasePrerequisiteCurrent) != 0,
                            Volatile.Read(ref _reconcileInFlight) != 0,
                            _quitting))
                    {
                        RefreshEditorLeaseHeartbeat();
                    }
                });
            }
            catch (Exception exception)
            {
                if (!_quitting)
                    Debug.LogWarning($"CodeDB Editor lease heartbeat failed: {exception.Message}");
            }
            finally
            {
                Interlocked.Exchange(ref _leaseRefreshInFlight, 0);
            }
        }

        private static async void QueuePrerequisiteRecheck()
        {
            if (_quitting
                || Volatile.Read(ref _reconcileInFlight) != 0
                || Interlocked.CompareExchange(ref _prerequisiteRecheckInFlight, 1, 0) != 0)
                return;
            try
            {
                var observedFingerprint = await BackgroundScheduler.QueueMaintenance(
                    canContinue => canContinue()
                        ? CaptureMachinePrerequisiteEvidenceFingerprint(_executionContext)
                        : string.Empty);
                if (_quitting || BackgroundScheduler.IsMaintenanceSuspended)
                    return;
                var recordedFingerprint = Volatile.Read(ref _missingPrerequisiteFingerprint);
                if (!ShouldTriggerPrerequisiteRecheck(recordedFingerprint, observedFingerprint))
                    return;

                RefreshProcessPathFromMachineEvidence();
                _nextReconcileAt = 0d;
                BeginReconcile(true);
            }
            catch (Exception exception)
            {
                if (!_quitting)
                    Debug.LogWarning($"CodeDB prerequisite recheck failed: {exception.Message}");
            }
            finally
            {
                Interlocked.Exchange(ref _prerequisiteRecheckInFlight, 0);
            }
        }

        private static void RefreshEditorLeaseForIntegrationState(AICodedbEditorExecutionContext context)
        {
            lock (LeaseIoLock)
            {
                var integrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
                var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot);
                if (ShouldPublishEditorLease(integrationStatus) && currentInstance.IsCurrent)
                {
                    var previousLeasePath = _leasePath;
                    _leasePath = Path.Combine(
                        context.GetProjectPath(currentInstance.EditorLeaseRelativePath),
                        _sessionId + ".json");
                    if (!string.IsNullOrWhiteSpace(previousLeasePath)
                        && !string.Equals(previousLeasePath, _leasePath, StringComparison.OrdinalIgnoreCase)
                        && File.Exists(previousLeasePath))
                    {
                        File.Delete(previousLeasePath);
                    }
                    PublishLease();
                }
                else
                    DeleteEditorLease();
            }
        }

        private static void RefreshEditorLeaseHeartbeat()
        {
            lock (LeaseIoLock)
            {
                // Reconciliation owns instance/state transitions. During a
                // long transition, refresh the already selected lease path
                // without rereading partially published control files; the
                // next completed reconcile will move or remove it as needed.
                if (!string.IsNullOrWhiteSpace(_leasePath)
                    && File.Exists(_leasePath)
                    && Directory.Exists(Path.GetDirectoryName(_leasePath)))
                {
                    AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(_projectRoot, _leasePath);
                    PublishLease();
                }
            }
        }

        private static void DeleteEditorLease()
        {
            lock (LeaseIoLock)
            {
                if (!string.IsNullOrWhiteSpace(_leasePath) && File.Exists(_leasePath))
                    File.Delete(_leasePath);
            }
        }

        internal static string GetApplicableManualMode(
            ManualRuntimeDocument manual,
            string[] activeEditorSessionIds,
            string projectRoot,
            string projectIdentity)
        {
            string manualRoot;
            string expectedRoot;
            if (manual == null
                || manual.schema_version != LeaseSchemaVersion
                || !string.Equals(manual.managed_by, ManagedBy, StringComparison.Ordinal)
                || !TryNormalizeRoot(manual.project_root, out manualRoot)
                || !TryNormalizeRoot(projectRoot, out expectedRoot)
                || !string.Equals(manualRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrWhiteSpace(projectIdentity)
                || !string.Equals(manual.project_identity, projectIdentity, StringComparison.Ordinal)
                || activeEditorSessionIds == null
                || manual.editor_session_ids == null
                || manual.editor_session_ids.Length == 0
                || (manual.mode != "started" && manual.mode != "stopped"))
                return "none";

            foreach (var sessionId in manual.editor_session_ids)
            {
                if (!IsValidSessionId(sessionId))
                    return "none";
            }

            foreach (var sessionId in manual.editor_session_ids)
            {
                foreach (var activeSessionId in activeEditorSessionIds)
                {
                    if (string.Equals(sessionId, activeSessionId, StringComparison.Ordinal))
                        return manual.mode;
                }
            }
            return "none";
        }

        private static string[] GetActiveEditorSessionIds(AICodedbEditorExecutionContext context)
        {
            var sessions = new HashSet<string>(StringComparer.Ordinal);
            try
            {
                var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot);
                if (!currentInstance.IsCurrent)
                    return new string[0];
                var leaseRoot = context.GetProjectPath(currentInstance.EditorLeaseRelativePath);
                if (!Directory.Exists(leaseRoot))
                    return new string[0];

                var now = DateTime.UtcNow;
                foreach (var path in Directory.GetFiles(leaseRoot, "*.json"))
                {
                    var lease = ReadEditorLease(path);
                    if (IsActiveEditorLease(
                            lease,
                            path,
                            _projectRoot,
                            _projectIdentity,
                            now,
                            GetProcessStartTicks))
                        sessions.Add(lease.session_id);
                }
            }
            catch
            {
                // The PowerShell coordinator remains authoritative for lease cleanup.
            }
            var result = new string[sessions.Count];
            sessions.CopyTo(result);
            return result;
        }

        internal static bool IsActiveEditorLease(
            EditorLeaseDocument lease,
            string leasePath,
            string projectRoot,
            string projectIdentity,
            DateTime nowUtc,
            Func<int, string> processStartTicksProvider)
        {
            try
            {
                DateTime createdAt;
                DateTime heartbeatAt;
                string leaseRoot;
                string expectedRoot;
                if (lease == null
                    || lease.schema_version != LeaseSchemaVersion
                    || !string.Equals(lease.managed_by, ManagedBy, StringComparison.Ordinal)
                    || !IsValidSessionId(lease.session_id)
                    || !string.Equals(Path.GetFileName(leasePath), lease.session_id + ".json", StringComparison.Ordinal)
                    || lease.editor_pid <= 0
                    || !IsUnsignedInteger(lease.process_start_ticks)
                    || !TryNormalizeRoot(lease.project_root, out leaseRoot)
                    || !TryNormalizeRoot(projectRoot, out expectedRoot)
                    || !string.Equals(leaseRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                    || string.IsNullOrWhiteSpace(projectIdentity)
                    || !string.Equals(lease.project_identity, projectIdentity, StringComparison.Ordinal)
                    || !DateTime.TryParse(lease.created_at_utc, null, DateTimeStyles.RoundtripKind, out createdAt)
                    || !DateTime.TryParse(lease.heartbeat_at_utc, null, DateTimeStyles.RoundtripKind, out heartbeatAt))
                    return false;

                var createdUtc = createdAt.ToUniversalTime();
                var heartbeatUtc = heartbeatAt.ToUniversalTime();
                var now = nowUtc.ToUniversalTime();
                if (createdUtc > heartbeatUtc
                    || heartbeatUtc < now.AddSeconds(-90)
                    || heartbeatUtc > now.AddSeconds(30)
                    || processStartTicksProvider == null)
                    return false;

                var actualStartTicks = processStartTicksProvider(lease.editor_pid);
                return string.Equals(actualStartTicks, lease.process_start_ticks, StringComparison.Ordinal);
            }
            catch
            {
                return false;
            }
        }

        internal static async Task<AICodedbHostPayloadStatus> ReadHostStatusAfterUpgradeAsync(
            AICodedbCommandResult upgradeResult,
            Func<Task<AICodedbCommandResult>> readStatusAsync,
            Func<bool> markerExists,
            Func<string> currentGenerationId,
            Func<int, Task> delayAsync,
            int concurrentReadAttempts)
        {
            if (readStatusAsync == null)
                throw new ArgumentNullException(nameof(readStatusAsync));
            if (markerExists == null)
                throw new ArgumentNullException(nameof(markerExists));
            if (currentGenerationId == null)
                throw new ArgumentNullException(nameof(currentGenerationId));
            if (delayAsync == null)
                throw new ArgumentNullException(nameof(delayAsync));
            if (concurrentReadAttempts <= 0)
                throw new ArgumentOutOfRangeException(nameof(concurrentReadAttempts));

            var attempts = IsConcurrentUpgrade(upgradeResult) ? concurrentReadAttempts : 1;
            AICodedbHostPayloadStatus status = default(AICodedbHostPayloadStatus);
            for (var attempt = 0; attempt < attempts; attempt++)
            {
                var result = await readStatusAsync();
                status = AICodedbHostPayloadStatusBuilder.Build(
                    markerExists(),
                    result,
                    currentGenerationId());
                if (status.IsCurrent || attempt + 1 >= attempts)
                    return status;
                await delayAsync(ConcurrentUpgradeRetryDelayMilliseconds);
            }
            return status;
        }

        private static AICodedbHostPayloadStatus ReadHostStatusAfterUpgrade(
            AICodedbEditorExecutionContext context,
            AICodedbCommandResult upgradeResult,
            Func<bool> canContinue,
            int concurrentReadAttempts)
        {
            var attempts = IsConcurrentUpgrade(upgradeResult) ? concurrentReadAttempts : 1;
            AICodedbHostPayloadStatus status = default(AICodedbHostPayloadStatus);
            for (var attempt = 0; attempt < attempts; attempt++)
            {
                if (!canContinue())
                    return status;
                status = BuildHostPayloadStatus(
                    AICodedbHostPayloadMaterializer.ReadStatus(context),
                    context);
                if (status.IsCurrent || attempt + 1 >= attempts)
                    return status;
                for (var waited = 0; waited < ConcurrentUpgradeRetryDelayMilliseconds; waited += 25)
                {
                    if (!canContinue())
                        return status;
                    Thread.Sleep(Math.Min(25, ConcurrentUpgradeRetryDelayMilliseconds - waited));
                }
            }
            return status;
        }

        internal static bool IsConcurrentUpgrade(AICodedbCommandResult result)
        {
            if (result == null || result.ExitCode != 4 || result.TimedOut)
                return false;
            var combined = (result.StandardOutput ?? string.Empty) + "\n" + (result.StandardError ?? string.Empty);
            return combined.IndexOf("Another payload materialization is active", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static AICodedbHostPayloadStatus BuildHostPayloadStatus(
            AICodedbCommandResult result,
            AICodedbEditorExecutionContext context)
        {
            return AICodedbHostPayloadStatusBuilder.Build(
                File.Exists(context.GetProjectPath(AICodedbProjectSettings.HostPayloadMarkerRelativePath)),
                result,
                GetCurrentHostGenerationId(context));
        }

        private static string GetCurrentHostGenerationId(AICodedbEditorExecutionContext context)
        {
            var generation = AICodedbHostGenerationStore.Resolve(context.ProjectRoot, context.PackageRoot);
            return generation.State == AICodedbHostGenerationState.Current
                ? generation.GenerationId
                : string.Empty;
        }

        private static string GetProcessStartTicks(int processId)
        {
            try
            {
                using (var process = Process.GetProcessById(processId))
                {
                    if (process.HasExited)
                        return string.Empty;
                    return process.StartTime.ToUniversalTime().Ticks.ToString(CultureInfo.InvariantCulture);
                }
            }
            catch
            {
                return string.Empty;
            }
        }

        private static bool TryNormalizeRoot(string path, out string normalized)
        {
            normalized = string.Empty;
            try
            {
                normalized = AICodedbPaths.NormalizePath(path).TrimEnd('/');
                return !string.IsNullOrWhiteSpace(normalized);
            }
            catch
            {
                return false;
            }
        }

        private static bool IsValidSessionId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 128)
                return false;
            foreach (var character in value)
            {
                if ((character < 'A' || character > 'Z')
                    && (character < 'a' || character > 'z')
                    && (character < '0' || character > '9')
                    && character != '.'
                    && character != '_'
                    && character != '-')
                    return false;
            }
            return true;
        }

        private static bool IsUnsignedInteger(string value)
        {
            if (string.IsNullOrEmpty(value))
                return false;
            foreach (var character in value)
            {
                if (character < '0' || character > '9')
                    return false;
            }
            return true;
        }

        private static string CaptureMachinePrerequisiteEvidenceFingerprint(
            AICodedbEditorExecutionContext context)
        {
            var providerExecutablePath = context.MachineProviderExecutablePath;
            var providerManifestPath = string.IsNullOrWhiteSpace(providerExecutablePath)
                ? string.Empty
                : Path.Combine(Path.GetDirectoryName(providerExecutablePath), "provider-manifest.json");
            return CreateMachinePrerequisiteEvidenceFingerprint(
                Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Process),
                Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User),
                Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Machine),
                providerManifestPath,
                providerExecutablePath);
        }

        internal static string CreateMachinePrerequisiteEvidenceFingerprint(
            string processPath,
            string userPath,
            string machinePath,
            string providerManifestPath,
            string providerExecutablePath)
        {
            var evidence = new StringBuilder();
            evidence.Append("process_path=").Append(processPath ?? string.Empty).Append('\n');
            evidence.Append("user_path=").Append(userPath ?? string.Empty).Append('\n');
            evidence.Append("machine_path=").Append(machinePath ?? string.Empty).Append('\n');
            AppendPrerequisiteFileEvidence(evidence, "provider_manifest", providerManifestPath);
            AppendPrerequisiteFileEvidence(evidence, "provider_executable", providerExecutablePath);
            using (var sha256 = SHA256.Create())
            {
                var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(evidence.ToString()));
                var result = new StringBuilder(bytes.Length * 2);
                foreach (var value in bytes)
                    result.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return result.ToString();
            }
        }

        private static void AppendPrerequisiteFileEvidence(
            StringBuilder evidence,
            string label,
            string path)
        {
            evidence.Append(label).Append("_path=").Append(path ?? string.Empty).Append('\n');
            if (string.IsNullOrWhiteSpace(path))
            {
                evidence.Append(label).Append("_state=missing\n");
                return;
            }
            try
            {
                var file = new FileInfo(path);
                file.Refresh();
                if (!file.Exists)
                {
                    evidence.Append(label).Append("_state=missing\n");
                    return;
                }
                evidence.Append(label).Append("_state=present\n");
                evidence.Append(label).Append("_length=").Append(file.Length).Append('\n');
                evidence.Append(label).Append("_write_ticks=")
                    .Append(file.LastWriteTimeUtc.Ticks)
                    .Append('\n');
                evidence.Append(label).Append("_attributes=")
                    .Append(((int)file.Attributes).ToString(CultureInfo.InvariantCulture))
                    .Append('\n');
            }
            catch (Exception exception)
            {
                evidence.Append(label).Append("_state=unreadable:")
                    .Append(exception.GetType().FullName)
                    .Append('\n');
            }
        }

        private static void RefreshProcessPathFromMachineEvidence()
        {
            var processPath = Environment.GetEnvironmentVariable(
                "PATH",
                EnvironmentVariableTarget.Process);
            var userPath = Environment.GetEnvironmentVariable(
                "PATH",
                EnvironmentVariableTarget.User);
            var machinePath = Environment.GetEnvironmentVariable(
                "PATH",
                EnvironmentVariableTarget.Machine);
            var mergedPath = MergePrerequisitePathEvidence(processPath, userPath, machinePath);
            if (!string.IsNullOrWhiteSpace(mergedPath))
                Environment.SetEnvironmentVariable(
                    "PATH",
                    mergedPath,
                    EnvironmentVariableTarget.Process);
        }

        internal static string MergePrerequisitePathEvidence(
            string processPath,
            string userPath,
            string machinePath)
        {
            var paths = new List<string>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var value in new[] { processPath, userPath, machinePath })
            {
                if (string.IsNullOrWhiteSpace(value))
                    continue;
                foreach (var entry in value.Split(Path.PathSeparator))
                {
                    var normalized = entry.Trim().Trim('"');
                    if (string.IsNullOrWhiteSpace(normalized) || !seen.Add(normalized))
                        continue;
                    paths.Add(normalized);
                }
            }
            return string.Join(Path.PathSeparator.ToString(), paths.ToArray());
        }

        private static void PublishLease()
        {
            if (string.IsNullOrWhiteSpace(_leasePath))
                return;
            Directory.CreateDirectory(Path.GetDirectoryName(_leasePath));
            var document = new EditorLeaseDocument
            {
                schema_version = LeaseSchemaVersion,
                managed_by = ManagedBy,
                session_id = _sessionId,
                editor_pid = _editorPid,
                process_start_ticks = _processStartTicks,
                project_root = _projectRoot,
                project_identity = _projectIdentity,
                created_at_utc = _sessionCreatedAtUtc,
                heartbeat_at_utc = DateTime.UtcNow.ToString("o")
            };
            WriteJsonAtomic(_leasePath, JsonUtility.ToJson(document, true) + "\n");
        }

        internal static string ValidateProjectRoot(string projectRoot)
        {
            var root = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            if (string.IsNullOrWhiteSpace(root) || !Directory.Exists(root))
                throw new InvalidOperationException("Unity project root does not exist.");

            foreach (var marker in new[] { "Assets", "Packages", "ProjectSettings" })
            {
                if (!Directory.Exists(Path.Combine(root, marker)))
                    throw new InvalidOperationException($"Unity project root is missing {marker}.");
            }

            return root;
        }

        internal static string CreateProjectIdentity(string projectRoot)
        {
            var canonical = ValidateProjectRoot(projectRoot).ToLowerInvariant();
            using (var sha256 = SHA256.Create())
            {
                var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(canonical));
                var builder = new StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return "sha256:" + builder;
            }
        }

        private static string GetOrCreateSessionValue(string key, Func<string> factory)
        {
            var value = SessionState.GetString(key, string.Empty);
            if (!string.IsNullOrWhiteSpace(value))
                return value;

            value = factory();
            SessionState.SetString(key, value);
            return value;
        }

        internal static EditorLeaseDocument ReadEditorLease(string path)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB Editor lease");
                if (value == null)
                    return null;
                return new EditorLeaseDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB Editor lease"),
                    managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "CodeDB Editor lease"),
                    session_id = AICodedbStrictJson.GetRequiredString(value, "session_id", "CodeDB Editor lease"),
                    editor_pid = AICodedbStrictJson.GetRequiredInt32(value, "editor_pid", "CodeDB Editor lease"),
                    process_start_ticks = AICodedbStrictJson.GetRequiredString(value, "process_start_ticks", "CodeDB Editor lease"),
                    project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "CodeDB Editor lease"),
                    project_identity = AICodedbStrictJson.GetRequiredString(value, "project_identity", "CodeDB Editor lease"),
                    created_at_utc = AICodedbStrictJson.GetRequiredString(value, "created_at_utc", "CodeDB Editor lease"),
                    heartbeat_at_utc = AICodedbStrictJson.GetRequiredString(value, "heartbeat_at_utc", "CodeDB Editor lease")
                };
            }
            catch
            {
                return null;
            }
        }

        private static ManualRuntimeDocument ReadManualRuntime(string path)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB manual runtime state");
                if (value == null)
                    return null;
                return new ManualRuntimeDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB manual runtime state"),
                    managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "CodeDB manual runtime state"),
                    mode = AICodedbStrictJson.GetRequiredString(value, "mode", "CodeDB manual runtime state"),
                    project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "CodeDB manual runtime state"),
                    project_identity = AICodedbStrictJson.GetRequiredString(value, "project_identity", "CodeDB manual runtime state"),
                    editor_session_ids = AICodedbStrictJson.GetRequiredStringArray(
                        value,
                        "editor_session_ids",
                        "CodeDB manual runtime state")
                };
            }
            catch
            {
                return null;
            }
        }

        private static DesiredStateDocument ReadDesiredState(
            string path,
            string expectedProjectRoot,
            string expectedProjectIdentity)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB desired state");
                if (value == null)
                    return null;
                var document = new DesiredStateDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB desired state"),
                    managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "CodeDB desired state"),
                    desired_state = AICodedbStrictJson.GetRequiredString(value, "desired_state", "CodeDB desired state"),
                    project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "CodeDB desired state"),
                    project_identity = AICodedbStrictJson.GetRequiredString(value, "project_identity", "CodeDB desired state")
                };
                string actualRoot;
                string expectedRoot;
                if (document.schema_version != LeaseSchemaVersion
                    || !string.Equals(document.managed_by, ManagedBy, StringComparison.Ordinal)
                    || (document.desired_state != "enabled" && document.desired_state != "disabled")
                    || !TryNormalizeRoot(document.project_root, out actualRoot)
                    || !TryNormalizeRoot(expectedProjectRoot, out expectedRoot)
                    || !string.Equals(actualRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                    || string.IsNullOrWhiteSpace(expectedProjectIdentity)
                    || !string.Equals(
                        document.project_identity,
                        expectedProjectIdentity,
                        StringComparison.Ordinal))
                    return null;
                return document;
            }
            catch
            {
                return null;
            }
        }

        private static CoordinatorStateDocument ReadCoordinatorState(string path, string expectedProjectRoot)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB coordinator state");
                if (value == null)
                    return null;
                var document = new CoordinatorStateDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB coordinator state"),
                    coordinator_pid = AICodedbStrictJson.GetRequiredInt32(value, "coordinator_pid", "CodeDB coordinator state"),
                    generation_id = AICodedbStrictJson.GetRequiredString(value, "generation_id", "CodeDB coordinator state"),
                    root = AICodedbStrictJson.GetRequiredString(value, "root", "CodeDB coordinator state")
                };
                string actualRoot;
                string expectedRoot;
                if (document.schema_version != 2
                    || document.coordinator_pid <= 0
                    || !TryNormalizeRoot(document.root, out actualRoot)
                    || !TryNormalizeRoot(expectedProjectRoot, out expectedRoot)
                    || !string.Equals(actualRoot, expectedRoot, StringComparison.OrdinalIgnoreCase))
                    return null;
                return document;
            }
            catch
            {
                return null;
            }
        }

        private static Dictionary<string, object> ReadEvidenceObject(string path, string label)
        {
            if (!File.Exists(path))
                return null;
            if ((File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0)
                throw new InvalidOperationException(label + " cannot be a reparse point.");
            return AICodedbStrictJson.ReadObject(path, 64 * 1024, label);
        }

        private static void WriteJsonAtomic(string targetPath, string content)
        {
            var directory = Path.GetDirectoryName(targetPath);
            if (string.IsNullOrWhiteSpace(directory))
                throw new InvalidOperationException("CodeDB lease path has no parent directory.");

            Directory.CreateDirectory(directory);
            var temporaryPath = Path.Combine(directory, "." + Path.GetFileName(targetPath) + "." + Guid.NewGuid().ToString("N") + ".tmp");
            var backupPath = Path.Combine(directory, "." + Path.GetFileName(targetPath) + "." + Guid.NewGuid().ToString("N") + ".bak");
            try
            {
                using (var stream = new FileStream(temporaryPath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                using (var writer = new StreamWriter(stream, new UTF8Encoding(false)))
                {
                    writer.Write(content);
                    writer.Flush();
                    stream.Flush(true);
                }

                if (File.Exists(targetPath))
                {
                    File.Replace(temporaryPath, targetPath, backupPath);
                    File.Delete(backupPath);
                }
                else
                    File.Move(temporaryPath, targetPath);
            }
            finally
            {
                if (File.Exists(temporaryPath))
                    File.Delete(temporaryPath);
                if (File.Exists(backupPath))
                    File.Delete(backupPath);
            }
        }

        private sealed class LifecycleReconcileResult
        {
            internal bool HasProductState { get; private set; }
            internal AICodedbProductState ProductState { get; set; }
            internal bool RetrySoon { get; set; }
            internal string Warning { get; set; }

            internal static LifecycleReconcileResult WithState(AICodedbProductState state)
            {
                return new LifecycleReconcileResult
                {
                    HasProductState = true,
                    ProductState = state,
                    Warning = string.Empty
                };
            }

            internal static LifecycleReconcileResult WithWarning(
                AICodedbProductState state,
                string warning)
            {
                var result = WithState(state);
                result.Warning = warning ?? string.Empty;
                return result;
            }
        }

        internal enum AICodedbCurrentInstanceConvergencePlan
        {
            None,
            Deploy,
            RecoverAvailability,
            Blocked
        }

        [Serializable]
        internal sealed class EditorLeaseDocument
        {
            public int schema_version;
            public string managed_by;
            public string session_id;
            public int editor_pid;
            public string process_start_ticks;
            public string project_root;
            public string project_identity;
            public string created_at_utc;
            public string heartbeat_at_utc;
        }

        [Serializable]
        private sealed class DesiredStateDocument
        {
            public int schema_version;
            public string managed_by;
            public string desired_state;
            public string project_root;
            public string project_identity;
        }

        [Serializable]
        internal sealed class ManualRuntimeDocument
        {
            public int schema_version;
            public string managed_by;
            public string mode;
            public string project_root;
            public string project_identity;
            public string[] editor_session_ids;
        }

        [Serializable]
        private sealed class CoordinatorStateDocument
        {
            public int schema_version;
            public int coordinator_pid;
            public string generation_id;
            public string root;
        }
    }

    internal sealed class AICodedbEditorBackgroundScheduler
    {
        private int _maintenanceSuspended;

        internal bool IsMaintenanceSuspended => Volatile.Read(ref _maintenanceSuspended) != 0;

        internal void SetMaintenanceSuspended(bool suspended)
        {
            Interlocked.Exchange(ref _maintenanceSuspended, suspended ? 1 : 0);
        }

        internal Task<T> QueueMaintenance<T>(Func<Func<bool>, T> work)
        {
            if (work == null)
                throw new ArgumentNullException(nameof(work));
            return Task.Run(() =>
            {
                if (IsMaintenanceSuspended)
                    return default(T);
                return work(() => !IsMaintenanceSuspended);
            });
        }

        internal Task QueueLease(Action work)
        {
            if (work == null)
                throw new ArgumentNullException(nameof(work));
            return Task.Run(work);
        }
    }
}
