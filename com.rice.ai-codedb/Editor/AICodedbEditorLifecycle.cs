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
        // Lifecycle maintenance is best-effort. A Play/domain-reload boundary
        // must never inherit a user-sized (10 minute) watcher transaction.
        internal const int LifecycleMaintenanceTimeoutMilliseconds = 15000;

        private const double ReconcileRetrySeconds = 30d;
        private const double InitialReconcileDelaySeconds = 1.5d;
        private const int MaximumInitializationRetries = 5;
        private const int InitializationRetryDeferralFrames = 30;
        private const string ManagedBy = "com.rice.ai-codedb";
        private const string SessionIdKey = "Rice.AICodedb.EditorLifecycle.SessionId";
        private const string SessionCreatedAtKey = "Rice.AICodedb.EditorLifecycle.CreatedAtUtc";
        private const string SessionProjectIdentityKey = "Rice.AICodedb.EditorLifecycle.ProjectIdentity";
        private const string LastProductStateKeyPrefix = "Rice.AICodedb.EditorLifecycle.LastProductState.";
        private const string LastPackageFingerprintKeyPrefix = "Rice.AICodedb.EditorLifecycle.LastPackageFingerprint.";
        private const string LastVerifiedReadyFingerprintKeyPrefix = "Rice.AICodedb.EditorLifecycle.LastVerifiedReadyFingerprint.";
        private const string LeasePrerequisiteCurrentKeyPrefix = "Rice.AICodedb.EditorLifecycle.LeasePrerequisiteCurrent.";
        private const string TerminalConvergenceFailureKeyPrefix = "Rice.AICodedb.EditorLifecycle.TerminalConvergenceFailure.";
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
        private static AICodedbCommandResult _cachedHostStatusResult;
        private static AICodedbProductStatus _cachedLifecycleProductStatus;
        private static AICodedbSupervisorSnapshot _cachedLifecycleSupervisorSnapshot;
        private static AICodedbTerminalConvergenceFailure _cachedTerminalConvergenceFailure;
        private static bool _hasCachedLifecycleProductStatus;
        private static long _cachedHostStatusRevision;
        private static int _automaticSupervisorStartAllowed;
        private static int _scheduledMigrationAdmissionBlocked;
        private static int _currentInstanceAvailabilityRecoveryAttempts;
        private static readonly object LeaseIoLock = new object();
        private static readonly object HostStatusCacheLock = new object();
        private static readonly AICodedbEditorBackgroundScheduler BackgroundScheduler =
            new AICodedbEditorBackgroundScheduler();
        private static readonly AICodedbSupervisorIntentAdapter SupervisorIntentAdapter =
            new AICodedbSupervisorIntentAdapter();
        private static readonly AICodedbSupervisorBridge SupervisorBridge =
            new AICodedbSupervisorBridge();
        private static bool _initialized;
        private static bool _initializationQueued;
        private static bool _initializationCompletionQueued;
        private static Task<LifecycleInitializationData> _initializationWork;
        private static int _initializationDeferralFrames = 2;
        private static int _initializationRetryCount;
        private static bool _initialReconcileQueued;
        private static double _initialReconcileNotBefore;
        private static volatile bool _quitting;

        static AICodedbEditorLifecycle()
        {
            if (Application.isBatchMode)
                return;

            AICodedbLifecycleEvidence.InitializeMainThread();
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.InitializeOnLoad);
            try
            {
                _projectRoot = AICodedbPaths.ProjectRoot;
                _projectIdentity = ReadSessionProjectIdentity();
                // Do not touch Package Manager, the project filesystem, or a
                // Process object from an InitializeOnLoad constructor. Unity
                // invokes this constructor while the managed domain is being
                // rebuilt; those calls can wait on UPM/IPC and leave the Editor
                // stuck in "Reloading Domain" before the first frame is drawn.
                QueueDeferredInitialization();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"CodeDB Editor lifecycle initialization was skipped: {exception.Message}");
            }
            finally
            {
                callback.Dispose();
            }
        }

        private static void QueueDeferredInitialization()
        {
            if (_initializationQueued || _quitting)
                return;

            _initializationQueued = true;
            EditorApplication.delayCall += Initialize;
        }

        private static void Initialize()
        {
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.DeferredInitialize);
            _initializationQueued = false;
            try
            {
                if (!ShouldInitializeLifecycle(_quitting))
                    return;

                if (_initializationWork != null)
                    return;

                // Give Unity a couple of idle editor frames to finish package and
                // script bookkeeping. If the user enters Play immediately, keep
                // deferring instead of starting any CodeDB work in that transition.
                if (_initializationDeferralFrames > 0
                    || ShouldDeferLifecycleInitialization(
                        EditorApplication.isCompiling,
                        EditorApplication.isUpdating,
                        EditorApplication.isPlayingOrWillChangePlaymode,
                        Application.isPlaying))
                {
                    if (_initializationDeferralFrames > 0)
                        _initializationDeferralFrames--;
                    QueueDeferredInitialization();
                    return;
                }

                // Package identity is the only resolved Unity context needed
                // synchronously. Project validation and process identity are
                // prepared on a worker so a cold Play transition never waits
                // for directory or Process APIs from this callback.
                _projectRoot = AICodedbPaths.ProjectRoot;
                _executionContext = AICodedbPaths.CaptureExecutionContext();
                _sessionId = GetOrCreateSessionValue(SessionIdKey, () => Guid.NewGuid().ToString("N"));
                _sessionCreatedAtUtc = GetOrCreateSessionValue(SessionCreatedAtKey, () => DateTime.UtcNow.ToString("o"));
                _leasePath = string.Empty;
                _editorPid = 0;
                _processStartTicks = string.Empty;
                _initializationWork = Task.Run(() => PrepareLifecycleInitialization(_projectRoot));
                QueueInitializationCompletion();
            }
            catch (Exception exception)
            {
                HandleInitializationFailure(exception);
            }
            finally
            {
                callback.Dispose();
            }
        }

        private static void QueueInitializationCompletion()
        {
            if (_initializationCompletionQueued || _quitting)
                return;

            _initializationCompletionQueued = true;
            EditorApplication.update -= CompleteDeferredInitialization;
            EditorApplication.update += CompleteDeferredInitialization;
        }

        private static void CompleteDeferredInitialization()
        {
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.InitializationCompletion);
            try
            {
                if (_quitting)
                {
                    EditorApplication.update -= CompleteDeferredInitialization;
                    _initializationCompletionQueued = false;
                    return;
                }

                var work = _initializationWork;
                if (work == null || !work.IsCompleted)
                    return;

                // Do not consume the worker result while Unity is entering Play or
                // rebuilding scripts. The completed result remains in memory and
                // is applied on a later idle Editor frame.
                if (ShouldDeferLifecycleInitialization(
                        EditorApplication.isCompiling,
                        EditorApplication.isUpdating,
                        EditorApplication.isPlayingOrWillChangePlaymode,
                        Application.isPlaying))
                    return;

                _initializationWork = null;
                EditorApplication.update -= CompleteDeferredInitialization;
                _initializationCompletionQueued = false;
                var prepared = work.GetAwaiter().GetResult();
                _projectRoot = prepared.ProjectRoot;
                _projectIdentity = prepared.ProjectIdentity;
                SessionState.SetString(SessionProjectIdentityKey, _projectIdentity);
                _editorPid = prepared.EditorPid;
                _processStartTicks = prepared.ProcessStartTicks;
                _lastProductState = ReadPersistedProductState(_projectIdentity);
                var persistedTerminalFailure = ReadPersistedTerminalConvergenceFailure(_projectIdentity);
                if (persistedTerminalFailure != null)
                {
                    // A retained authenticated terminal failure is stronger
                    // than a coarse or transient state restored from the
                    // adjacent SessionState key. It remains fail-closed until
                    // a newer authenticated terminal observation replaces it.
                    _lastProductState = AICodedbProductState.NeedsAttention;
                    lock (HostStatusCacheLock)
                    {
                        _cachedTerminalConvergenceFailure = persistedTerminalFailure;
                        _cachedLifecycleProductStatus = persistedTerminalFailure.ToProductStatus();
                        _cachedLifecycleSupervisorSnapshot = null;
                        _cachedHostStatusResult = null;
                        _hasCachedLifecycleProductStatus = true;
                        _cachedHostStatusRevision++;
                    }
                }
                _packageFingerprintChanged = HasPackageFingerprintChanged(_projectIdentity);
                Interlocked.Exchange(
                    ref _leasePrerequisiteCurrent,
                    ShouldRestoreLeasePrerequisite(
                        ReadPersistedLeasePrerequisite(_projectIdentity),
                        _packageFingerprintChanged)
                        ? 1
                        : 0);
                if (_packageFingerprintChanged)
                    PersistLeasePrerequisite(_projectIdentity, false);

                EditorApplication.update -= OnEditorUpdate;
                EditorApplication.update += OnEditorUpdate;
                EditorApplication.quitting -= OnEditorQuitting;
                EditorApplication.quitting += OnEditorQuitting;
                EditorApplication.playModeStateChanged -= OnPlayModeStateChanged;
                EditorApplication.playModeStateChanged += OnPlayModeStateChanged;
                AssemblyReloadEvents.beforeAssemblyReload -= OnBeforeAssemblyReload;
                AssemblyReloadEvents.beforeAssemblyReload += OnBeforeAssemblyReload;

                _initialized = true;
                var maintenanceSuspended = IsPlayModeMaintenanceSuspended();
                BackgroundScheduler.SetMaintenanceSuspended(maintenanceSuspended);
                SupervisorIntentAdapter.SetMaintenanceSuspended(maintenanceSuspended);
                _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
                _initializationRetryCount = 0;
                _initialReconcileNotBefore =
                    EditorApplication.timeSinceStartup + InitialReconcileDelaySeconds;
                // The first pass must classify prerequisites and the selected
                // instance before any lease can be published, but it must not
                // compete with an immediate Play transition. Later reload and
                // resume paths use the persisted Ready short-circuit.
                if (!maintenanceSuspended)
                    QueueInitialReconcile();
                else
                    QueueLeaseRefresh();
                QueueSupervisorReconnect(true);
            }
            catch (Exception exception)
            {
                HandleInitializationFailure(exception);
            }
            finally
            {
                callback.Dispose();
            }
        }

        private static LifecycleInitializationData PrepareLifecycleInitialization(string projectRoot)
        {
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.Hash);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.Process);
            var validatedRoot = ValidateProjectRoot(projectRoot);
            var projectIdentity = CreateProjectIdentityFromCanonicalPath(validatedRoot);
            using (var process = Process.GetCurrentProcess())
            {
                return new LifecycleInitializationData(
                    validatedRoot,
                    projectIdentity,
                    process.Id,
                    process.StartTime.ToUniversalTime().Ticks.ToString(CultureInfo.InvariantCulture));
            }
        }

        private static void HandleInitializationFailure(Exception exception)
        {
            _initialized = false;
            _initializationWork = null;
            EditorApplication.update -= CompleteDeferredInitialization;
            _initializationCompletionQueued = false;
            // Package Manager can still be settling after a reload. Retry on a
            // later editor callback without doing work in the reload callback.
            Debug.LogWarning($"CodeDB Editor lifecycle initialization was deferred: {exception.Message}");
            if (++_initializationRetryCount <= MaximumInitializationRetries)
            {
                _initializationDeferralFrames = InitializationRetryDeferralFrames;
                QueueDeferredInitialization();
            }
        }

        private static void QueueInitialReconcile()
        {
            if (_initialReconcileQueued || _quitting)
                return;

            _initialReconcileQueued = true;
            EditorApplication.delayCall += TryStartInitialReconcile;
        }

        private static void TryStartInitialReconcile()
        {
            _initialReconcileQueued = false;
            if (!_initialized || _quitting)
                return;

            if (EditorApplication.timeSinceStartup < _initialReconcileNotBefore
                || ShouldDeferReconcile(
                    EditorApplication.isCompiling,
                    EditorApplication.isUpdating,
                    IsPlayModeMaintenanceSuspended()))
            {
                QueueInitialReconcile();
                return;
            }

            // Run on the background scheduler; this callback only starts the
            // worker and never performs project, hash, lease, or process I/O.
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
            AICodedbLifecycleEvidence.InitializeMainThread();
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.ScriptsReloaded);
            try
            {
                AICodedbLifecycleEvidence.RecordDomainReload();
                // A domain reload invalidates the managed IPC handle. Reconnect
                // the Bridge to the selected instance, but never launch a
                // replacement/upgrade loop for an already healthy backend.
                SupervisorBridge.Invalidate();
                SupervisorIntentAdapter.Invalidate();
                EditorApplication.delayCall += RequestReconcileIfNeeded;
                EditorApplication.delayCall += ReconnectSupervisorAfterReload;
            }
            finally
            {
                callback.Dispose();
                AICodedbLifecycleEvidence.PersistAndEmit("scripts_reloaded");
            }
        }

        internal static bool ShouldDeferLifecycleInitialization(
            bool isCompiling,
            bool isUpdating,
            bool isPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return isCompiling
                   || isUpdating
                   || (isPlayingOrWillChangePlaymode && !applicationPlaying);
        }

        private static void OnEditorUpdate()
        {
            if (!_initialized || _quitting)
                return;

            var playTransition = IsPlayModeMaintenanceSuspended();
            var maintenanceSuspended = ShouldSuspendMaintenance(
                EditorApplication.isCompiling,
                EditorApplication.isUpdating,
                playTransition);
            BackgroundScheduler.SetMaintenanceSuspended(maintenanceSuspended);
            SupervisorIntentAdapter.SetMaintenanceSuspended(maintenanceSuspended);
            if (EditorApplication.timeSinceStartup < _nextHeartbeatAt)
                return;

            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.Heartbeat);
            try
            {
                _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
                if (maintenanceSuspended)
                {
                    // Keep the interactive Editor lease alive while maintenance is
                    // suspended so the coordinator does not mistake Play mode for
                    // an offline Editor. The write remains on the lease worker.
                    if (playTransition
                        && _lastProductState != AICodedbProductState.MissingPrerequisite)
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
                var cachedMigrationAdmissionBlocked =
                    Volatile.Read(ref _scheduledMigrationAdmissionBlocked) != 0;
                if (ShouldQueueScheduledReconcile(
                        EditorApplication.timeSinceStartup,
                        ref _nextReconcileAt,
                        false,
                        cachedMigrationAdmissionBlocked,
                        Volatile.Read(ref _reconcileInFlight) != 0))
                    BeginReconcile(false);
                else if (cachedMigrationAdmissionBlocked)
                    QueuePrerequisiteRecheck();
                QueueLeaseRefresh();
            }
            finally
            {
                callback.Dispose();
            }
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
            bool maintenanceSuspended,
            bool cachedMigrationAdmissionBlocked = false,
            bool reconcileInFlight = false)
        {
            if (maintenanceSuspended
                || !ShouldAllowMigrationAdmissionTrigger(
                    true,
                    cachedMigrationAdmissionBlocked)
                || now < nextReconcileAt)
                return false;

            nextReconcileAt = now + ReconcileRetrySeconds;
            return !reconcileInFlight;
        }

        internal static bool ShouldAllowMigrationAdmissionTrigger(
            bool scheduledTrigger,
            bool cachedMigrationAdmissionBlocked)
        {
            return !scheduledTrigger || !cachedMigrationAdmissionBlocked;
        }

        private static void OnPlayModeStateChanged(PlayModeStateChange state)
        {
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.PlayModeTransition);
            try
            {
                AICodedbLifecycleEvidence.RecordPlayTransition();
                if (state == PlayModeStateChange.ExitingEditMode)
                {
                    // A cold Play transition can arrive before deferred lifecycle
                    // initialization has cached the project identity. In that
                    // window the handoff is display-only and must not validate or
                    // hash the project root on Unity's callback thread.
                    if (_initialized)
                        RecordProductStateForPlayModeIfAbsent();
                    CancelBackgroundMaintenanceForBoundary();
                }
                else if (state == PlayModeStateChange.EnteredEditMode)
                    ClearProductStateForPlayMode();

                var suspended = ShouldSuspendMaintenance(
                    EditorApplication.isCompiling,
                    EditorApplication.isUpdating,
                    state != PlayModeStateChange.EnteredEditMode);
                BackgroundScheduler.SetMaintenanceSuspended(suspended);
                SupervisorIntentAdapter.SetMaintenanceSuspended(suspended);
                if (state == PlayModeStateChange.EnteredPlayMode && !_quitting)
                {
                    // Stable Play permits query-priority reconnects. Maintenance
                    // remains suspended until Edit mode resumes.
                    QueueSupervisorReconnect(false);
                }
                else if (!suspended && !_quitting)
                {
                    _nextReconcileAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
                    if (ShouldForceReconcileAfterPlayModeResume(_packageFingerprintChanged))
                        BeginReconcile(true);
                    else if (ShouldReconcileAfterPlayModeResume(_lastProductState))
                        BeginReconcile(false);
                    QueueSupervisorReconnect(false);
                }
            }
            finally
            {
                callback.Dispose();
                AICodedbLifecycleEvidence.PersistAndEmit("play_" + state);
            }
        }

        private static void OnEditorQuitting()
        {
            AICodedbLifecycleEvidence.RecordEditorQuittingBoundary(
                true,
                Volatile.Read(ref _reconcileInFlight) != 0,
                SupervisorIntentAdapter.Snapshot);
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.EditorQuitting);
            try
            {
                _quitting = true;
                CancelBackgroundMaintenanceForBoundary();
                QueueEditorLeaseDeletion();
                QueueOwnedSupervisorShutdown();
                SupervisorBridge.Dispose();
                SupervisorIntentAdapter.Dispose();
                EditorApplication.update -= CompleteDeferredInitialization;
                _initializationCompletionQueued = false;
                EditorApplication.update -= OnEditorUpdate;
                EditorApplication.playModeStateChanged -= OnPlayModeStateChanged;
            }
            finally
            {
                callback.Dispose();
                AICodedbLifecycleEvidence.RecordEditorQuittingBoundary(
                    false,
                    Volatile.Read(ref _reconcileInFlight) != 0,
                    SupervisorIntentAdapter.Snapshot);
                AICodedbLifecycleEvidence.PersistAndEmit("editor_quitting");
            }
        }

        private static void OnBeforeAssemblyReload()
        {
            var callback = AICodedbLifecycleEvidence.BeginCallback(
                AICodedbLifecycleCallbackKind.BeforeAssemblyReload);
            try
            {
                // Invalidate only Unity-side admission and IPC waiters. The
                // external Supervisor owns backend processes across Domain Reload.
                CancelBackgroundMaintenanceForBoundary();
                SupervisorBridge.Invalidate();
                SupervisorIntentAdapter.Invalidate();
                EditorApplication.update -= CompleteDeferredInitialization;
                _initializationCompletionQueued = false;
            }
            finally
            {
                callback.Dispose();
                AICodedbLifecycleEvidence.PersistAndEmit("before_assembly_reload");
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

            AICodedbLifecycleEvidence.RecordReconcileStarted();
            // Every reconcile epoch must re-establish the read-only control
            // contract admission before an automatic reconnect can start.
            Interlocked.Exchange(ref _automaticSupervisorStartAllowed, 0);
            _nextReconcileAt = EditorApplication.timeSinceStartup + ReconcileRetrySeconds;
            try
            {
                var previousProductState = _lastProductState;
                // This adapter only moves lifecycle intent off the callback and
                // guards the local lifetime. The external Supervisor owns
                // runtime ordering, coalescing, and maintenance admission.
                var result = await SupervisorIntentAdapter.Dispatch(
                    AICodedbSupervisorRequestKind.Reconcile,
                    cancellationToken => BackgroundScheduler.QueueMaintenance(
                        (canContinue, workerCancellationToken) => RunReconcileWorker(
                            _executionContext,
                            force,
                            previousProductState,
                            canContinue,
                            workerCancellationToken)),
                    true);
                if (result == null || _quitting)
                    return;
                if (result.HasProductState)
                {
                    _lastProductState = result.ProductState;
                    if (result.ProductState == AICodedbProductState.Uninstalled)
                    {
                        PublishAuthoritativeUninstalledCache();
                        PersistTerminalConvergenceFailure(
                            _projectIdentity,
                            null);
                    }
                    PersistProductState(_projectIdentity, result.ProductState);
                    if (result.ProductState != AICodedbProductState.Uninstalled)
                    {
                        var terminalFailure = GetCachedTerminalConvergenceFailure();
                        PersistTerminalConvergenceFailure(
                            _projectIdentity,
                            terminalFailure);
                    }
                    PersistLeasePrerequisite(
                        _projectIdentity,
                        Volatile.Read(ref _leasePrerequisiteCurrent) != 0);
                    RecordReconciledPackageFingerprint(_projectIdentity);
                    _packageFingerprintChanged = ShouldRetainPendingPackageChange(
                        _packageFingerprintChanged,
                        true);
                }
                if (result.RetrySoon)
                {
                    _nextReconcileAt = Math.Min(
                        _nextReconcileAt,
                        EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds);
                }
                AICodedbLifecycleEvidence.RecordReconcileCompleted(
                    result.HasProductState ? result.ProductState : previousProductState);
                AICodedbLifecycleEvidence.PersistAndEmit("reconcile_completed");
                if (!string.IsNullOrWhiteSpace(result.Warning))
                    Debug.LogWarning(result.Warning);
            }
            catch (OperationCanceledException)
            {
                // Play, compilation, and Domain Reload deliberately cancel
                // queued maintenance. The next lifecycle signal will enqueue
                // a fresh epoch instead of reporting a spurious failure.
            }
            catch (Exception exception)
            {
                if (!_quitting)
                    Debug.LogWarning($"CodeDB Editor lifecycle reconcile failed: {exception.Message}");
            }
            finally
            {
                Interlocked.Exchange(ref _reconcileInFlight, 0);
                QueueSupervisorReconnect(false);
            }
        }

        private static LifecycleReconcileResult RunReconcileWorker(
            AICodedbEditorExecutionContext context,
            bool force,
            AICodedbProductState previousProductState,
            Func<bool> canContinue,
            CancellationToken cancellationToken)
        {
            if (cancellationToken.IsCancellationRequested
                || !canContinue())
                return null;

            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FullStatus);
            var integrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
            var migrationStatus = AICodedbControlContractMigrationStore.Read(
                context.ProjectRoot,
                context.PackageRoot);
            if (migrationStatus.BlocksAutomaticStart)
                Interlocked.Exchange(ref _automaticSupervisorStartAllowed, 0);
            if (cancellationToken.IsCancellationRequested || !canContinue())
                return null;

            // The immutable coordinator requires an interactive Editor lease
            // before it can start. Establish that lease from the read-only
            // prerequisite DryRun before asking the Supervisor to admit its
            // first coordinator-backed Probe.
            var independentPrerequisiteRead = !HasPublishedEditorLease();
            var independentPrerequisiteCurrent = false;
            var coordinatorAdmissionAllowed = !independentPrerequisiteRead;
            var coordinatorAdmissionDisposition = independentPrerequisiteRead
                ? AICodedbCoordinatorAdmissionDisposition.PrerequisiteEvidenceUntrustworthy
                : AICodedbCoordinatorAdmissionDisposition.ExistingLease;
            AICodedbCommandResult independentPrerequisiteResult = null;
            AICodedbProductStatus independentPrerequisiteStatus = default(AICodedbProductStatus);
            if (independentPrerequisiteRead
                && integrationStatus.IsValid
                && !integrationStatus.IsUninstalled)
            {
                independentPrerequisiteResult = RememberHostStatusResult(
                    AICodedbHostPayloadMaterializer.ReadStatus(context, cancellationToken));
                independentPrerequisiteStatus = AICodedbProductStatusBuilder.Build(
                    integrationStatus,
                    independentPrerequisiteResult);
                AICodedbProductLayerState prerequisite;
                var prerequisiteEvidenceDisposition = ClassifyIndependentPrerequisiteEvidence(
                    independentPrerequisiteResult,
                    independentPrerequisiteStatus,
                    out prerequisite);
                AICodedbLifecycleEvidence.RecordPrerequisiteEvidenceDisposition(
                    prerequisiteEvidenceDisposition);
                independentPrerequisiteCurrent =
                    prerequisiteEvidenceDisposition ==
                    AICodedbPrerequisiteEvidenceDisposition.TrustworthyCurrent;
                if (!independentPrerequisiteCurrent)
                {
                    coordinatorAdmissionDisposition =
                        prerequisiteEvidenceDisposition ==
                        AICodedbPrerequisiteEvidenceDisposition.TrustworthyMissing
                        ? AICodedbCoordinatorAdmissionDisposition.PrerequisiteMissing
                        : AICodedbCoordinatorAdmissionDisposition.PrerequisiteEvidenceUntrustworthy;
                }
                else if (ShouldPublishEditorLeaseAfterPrerequisite(
                             integrationStatus,
                             independentPrerequisiteStatus))
                {
                    var leaseDisposition = AICodedbCoordinatorAdmissionDisposition.Unknown;
                    ApplyPrerequisiteGatedLeaseRefresh(
                        integrationStatus,
                        independentPrerequisiteStatus,
                        () => leaseDisposition = TryRefreshEditorLeaseForAdmission(context));
                    coordinatorAdmissionDisposition = leaseDisposition;
                }
                else
                    coordinatorAdmissionDisposition = AICodedbCoordinatorAdmissionDisposition.IntegrationNotEligible;
                AICodedbLifecycleEvidence.RecordCoordinatorAdmissionDisposition(
                    coordinatorAdmissionDisposition);
                coordinatorAdmissionAllowed = ShouldAttemptCoordinatorAdmission(
                    true,
                    independentPrerequisiteCurrent,
                    HasPublishedEditorLease());
                if (coordinatorAdmissionAllowed)
                {
                    Interlocked.Exchange(ref _leasePrerequisiteCurrent, 1);
                    Interlocked.Exchange(ref _missingPrerequisiteFingerprint, string.Empty);
                }
                else
                    Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
            }
            if (cancellationToken.IsCancellationRequested || !canContinue())
                return null;

            AICodedbLifecycleEvidence.ResetPostAdmissionEvidence();
            AICodedbProductStatus migrationProductStatus;
            AICodedbCommandResult migrationAdmissionResult;
            if (TryResolveControlContractMigrationBlock(
                    integrationStatus,
                    migrationStatus,
                    independentPrerequisiteCurrent
                        ? independentPrerequisiteResult
                        : null,
                    () =>
                    {
                        if (!coordinatorAdmissionAllowed)
                            return independentPrerequisiteResult;
                        var result = RunSupervisorCommand(
                            context,
                            "materialize",
                            "Probe",
                            cancellationToken);
                        return cancellationToken.IsCancellationRequested || !canContinue()
                            ? null
                            : result;
                    },
                    out migrationProductStatus,
                    out migrationAdmissionResult))
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.MigrationBlocked);
                var suppressScheduledMigrationAdmission =
                    integrationStatus.IsValid
                    && !integrationStatus.IsUninstalled
                    && migrationProductStatus.State == AICodedbProductState.NeedsAttention;
                Interlocked.Exchange(
                    ref _scheduledMigrationAdmissionBlocked,
                    suppressScheduledMigrationAdmission ? 1 : 0);
                Interlocked.Exchange(ref _automaticSupervisorStartAllowed, 0);
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                if (integrationStatus.IsUninstalled || !integrationStatus.IsValid)
                    DeleteEditorLease();
                if (migrationProductStatus.State == AICodedbProductState.MissingPrerequisite
                    || suppressScheduledMigrationAdmission)
                {
                    Interlocked.Exchange(
                        ref _missingPrerequisiteFingerprint,
                        CaptureMachinePrerequisiteEvidenceFingerprint(context));
                }
                else
                    Interlocked.Exchange(ref _missingPrerequisiteFingerprint, string.Empty);
                RememberLifecycleProductStatus(migrationProductStatus, migrationAdmissionResult);
                if (!integrationStatus.IsValid)
                {
                    return LifecycleReconcileResult.WithWarning(
                        AICodedbProductState.NeedsAttention,
                        "CodeDB project integration desired state is invalid: " + integrationStatus.Detail);
                }
                return LifecycleReconcileResult.WithState(migrationProductStatus.State);
            }

            if (independentPrerequisiteRead && !coordinatorAdmissionAllowed)
            {
                Interlocked.Exchange(ref _automaticSupervisorStartAllowed, 0);
                if (independentPrerequisiteStatus.State == AICodedbProductState.MissingPrerequisite)
                {
                    Interlocked.Exchange(
                        ref _missingPrerequisiteFingerprint,
                        CaptureMachinePrerequisiteEvidenceFingerprint(context));
                    RememberLifecycleProductStatus(
                        independentPrerequisiteStatus,
                        independentPrerequisiteResult);
                    return LifecycleReconcileResult.WithState(
                        AICodedbProductState.MissingPrerequisite);
                }

                var detail = string.IsNullOrWhiteSpace(independentPrerequisiteStatus.Detail)
                    ? "CodeDB could not establish the current Editor lease before coordinator admission."
                    : independentPrerequisiteStatus.Detail;
                var blockedStatus = new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention,
                    independentPrerequisiteStatus.Prerequisite,
                    independentPrerequisiteStatus.Installed,
                    independentPrerequisiteStatus.Configured,
                    independentPrerequisiteStatus.McpAvailable,
                    detail,
                    independentPrerequisiteStatus.Command,
                    AICodedbProductAttentionReason.None,
                    independentPrerequisiteStatus.DiagnosticDetail);
                RememberLifecycleProductStatus(blockedStatus, independentPrerequisiteResult);
                return LifecycleReconcileResult.WithWarning(
                    AICodedbProductState.NeedsAttention,
                    detail);
            }

            Interlocked.Exchange(ref _scheduledMigrationAdmissionBlocked, 0);
            Interlocked.Exchange(ref _automaticSupervisorStartAllowed, 1);
            if (!force && !BackendNeedsReconcile(context, previousProductState))
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.BackendReconcileNotRequired);
                return null;
            }

            if (integrationStatus.State == AICodedbProjectIntegrationState.Invalid)
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.IntegrationInvalid);
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                DeleteEditorLease();
                return LifecycleReconcileResult.WithWarning(
                    AICodedbProductState.NeedsAttention,
                    "CodeDB project integration desired state is invalid: " + integrationStatus.Detail);
            }
            if (ShouldRunAutomaticUninstallCleanup(integrationStatus))
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.UninstallCleanup);
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                DeleteEditorLease();
                if (!canContinue())
                {
                    RememberLifecycleProductStatus(
                        AICodedbProductStatusBuilder.Build(integrationStatus, null));
                    return LifecycleReconcileResult.WithState(AICodedbProductState.Uninstalled);
                }
                var cleanupResult = RememberHostStatusResult(
                    RunSupervisorCommand(context, "materialize", "Upgrade", cancellationToken));
                RememberLifecycleProductStatus(
                    AICodedbProductStatusBuilder.Build(integrationStatus, null));
                return cleanupResult.Succeeded
                    ? LifecycleReconcileResult.WithState(AICodedbProductState.Uninstalled)
                    : LifecycleReconcileResult.WithWarning(
                        AICodedbProductState.Uninstalled,
                        $"CodeDB automatic uninstall cleanup failed: {cleanupResult.GetSummary()} {cleanupResult.StandardError}".Trim());
            }
            if (integrationStatus.IsUninstalled)
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.Uninstalled);
                Interlocked.Exchange(ref _leasePrerequisiteCurrent, 0);
                DeleteEditorLease();
                RememberLifecycleProductStatus(
                    AICodedbProductStatusBuilder.Build(integrationStatus, null));
                return LifecycleReconcileResult.WithState(AICodedbProductState.Uninstalled);
            }

            if (!canContinue())
                return null;
            var hostResult = RunSupervisorCommand(
                context,
                "materialize",
                "Probe",
                cancellationToken);
            var hostStatus = BuildHostPayloadStatus(hostResult, context);
            var productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, hostResult);
            productStatus = RememberLifecycleProductStatus(productStatus, hostResult);
            AICodedbLifecycleEvidence.RecordPostAdmissionProductLayers(productStatus);
            AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                AICodedbPostAdmissionDisposition.InitialSupervisorProbeEvaluated);
            var workerResult = LifecycleReconcileResult.WithState(productStatus.State);
            if (productStatus.State == AICodedbProductState.MissingPrerequisite)
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.ProbeReportedMissingPrerequisite);
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
            var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot, context.PackageRoot);
            AICodedbLifecycleEvidence.RecordCurrentInstanceState(currentInstance.State);
            if (currentInstance.State == AICodedbCurrentInstanceState.Invalid)
            {
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    AICodedbPostAdmissionDisposition.CurrentInstanceInvalid);
                Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                workerResult.ProductState = AICodedbProductState.NeedsAttention;
                workerResult.Warning = "CodeDB current instance identity is invalid: " + currentInstance.Detail;
                return workerResult;
            }
            if (!currentInstance.Present || currentInstance.IsCurrent || currentInstance.IsTrustedPrevious)
            {
                var convergencePlan = ResolveCurrentInstanceConvergencePlan(
                    currentInstance.State,
                    productStatus,
                    integrationStatus.CleanupState);
                AICodedbLifecycleEvidence.RecordCurrentInstanceConvergencePlan(convergencePlan);
                AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                    ResolvePostAdmissionConvergenceDisposition(convergencePlan));
                if (convergencePlan == AICodedbCurrentInstanceConvergencePlan.Retire)
                {
                    var retirementResult = RunSupervisorCommand(
                        context,
                        "materialize",
                        "Upgrade",
                        cancellationToken);
                    productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, retirementResult);
                    productStatus = RememberLifecycleProductStatus(productStatus, retirementResult);
                    workerResult.ProductState = productStatus.State;
                    if (productStatus.State == AICodedbProductState.Ready)
                        RefreshEditorLeaseForIntegrationState(context);
                    else
                        workerResult.Warning =
                            $"CodeDB automatic retired-instance convergence failed: {retirementResult.GetSummary()} {retirementResult.StandardError}".Trim();
                    return workerResult;
                }
                if (convergencePlan == AICodedbCurrentInstanceConvergencePlan.Deploy)
                {
                    Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                    if (!canContinue())
                        return workerResult;
                    var instanceResult = RunSupervisorCommand(
                        context,
                        "materialize",
                        "Upgrade",
                        cancellationToken);
                    productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, instanceResult);
                    productStatus = RememberLifecycleProductStatus(productStatus, instanceResult);
                    workerResult.ProductState = productStatus.State;
                    if (!canContinue())
                        return workerResult;
                    var verifiedInstanceResult = RunSupervisorCommand(
                        context,
                        "materialize",
                        "Probe",
                        cancellationToken);
                    productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, verifiedInstanceResult);
                    productStatus = RememberLifecycleProductStatus(productStatus, verifiedInstanceResult);
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
                        canContinue,
                        cancellationToken);
                }

                Interlocked.Exchange(ref _currentInstanceAvailabilityRecoveryAttempts, 0);
                RefreshEditorLeaseForIntegrationState(context);
                return workerResult;
            }
            AICodedbLifecycleEvidence.RecordCurrentInstanceConvergencePlan(
                AICodedbCurrentInstanceConvergencePlan.Blocked);
            AICodedbLifecycleEvidence.RecordPostAdmissionDisposition(
                AICodedbPostAdmissionDisposition.ConvergenceBlocked);
            workerResult.ProductState = AICodedbProductState.NeedsAttention;
            workerResult.Warning = "CodeDB selected-instance state is unsupported by the v0.3 Supervisor route.";
            return workerResult;
        }

        internal static bool TryResolveControlContractMigrationBlock(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbControlContractMigrationStatus migrationStatus,
            Func<AICodedbCommandResult> prerequisiteAdmissionProbe,
            out AICodedbProductStatus productStatus,
            out AICodedbCommandResult admissionResult)
        {
            return TryResolveControlContractMigrationBlock(
                integrationStatus,
                migrationStatus,
                null,
                prerequisiteAdmissionProbe,
                out productStatus,
                out admissionResult);
        }

        internal static bool TryResolveControlContractMigrationBlock(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbControlContractMigrationStatus migrationStatus,
            AICodedbCommandResult independentPrerequisiteResult,
            Func<AICodedbCommandResult> prerequisiteAdmissionProbe,
            out AICodedbProductStatus productStatus,
            out AICodedbCommandResult admissionResult)
        {
            admissionResult = null;
            if (migrationStatus.IsUsableForAutomaticStart)
            {
                productStatus = default(AICodedbProductStatus);
                return false;
            }

            if (integrationStatus.IsUninstalled || !integrationStatus.IsValid)
            {
                productStatus = AICodedbProductStatusBuilder.Build(integrationStatus, null);
                return true;
            }

            admissionResult = independentPrerequisiteResult
                              ?? (prerequisiteAdmissionProbe == null
                                  ? null
                                  : prerequisiteAdmissionProbe());
            var prerequisiteStatus = AICodedbProductStatusBuilder.Build(
                integrationStatus,
                admissionResult);
            AICodedbProductLayerState prerequisite;
            if (!TryReadTrustworthyPrerequisiteEvidence(
                    admissionResult,
                    prerequisiteStatus,
                    out prerequisite))
            {
                productStatus = new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    string.IsNullOrWhiteSpace(prerequisiteStatus.Detail)
                        ? "CodeDB could not verify the current prerequisite state."
                        : prerequisiteStatus.Detail,
                    prerequisiteStatus.Command,
                    AICodedbProductAttentionReason.None,
                    migrationStatus.DiagnosticDetail);
                return true;
            }

            if (prerequisite == AICodedbProductLayerState.Missing)
            {
                productStatus = new AICodedbProductStatus(
                    AICodedbProductState.MissingPrerequisite,
                    AICodedbProductLayerState.Missing,
                    prerequisiteStatus.Installed,
                    prerequisiteStatus.Configured,
                    prerequisiteStatus.McpAvailable,
                    prerequisiteStatus.Detail,
                    prerequisiteStatus.Command,
                    AICodedbProductAttentionReason.None,
                    migrationStatus.DiagnosticDetail);
                return true;
            }

            var reason = migrationStatus.RequiresReinstall
                ? AICodedbProductAttentionReason.ControlContractReinstallRequired
                : AICodedbProductAttentionReason.ControlContractInvalidOrAmbiguous;
            productStatus = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                migrationStatus.Detail,
                default(AICodedbMaterializerCommandStatus),
                reason,
                migrationStatus.DiagnosticDetail);
            return true;
        }

        private static bool TryReadTrustworthyPrerequisiteEvidence(
            AICodedbCommandResult result,
            AICodedbProductStatus productStatus,
            out AICodedbProductLayerState prerequisite)
        {
            prerequisite = AICodedbProductLayerState.Unknown;
            if (result == null
                || result.TimedOut
                || !result.Succeeded
                || (productStatus.Command.Present && !productStatus.Command.IsValid))
            {
                return false;
            }

            return TryReadPrerequisiteMarker(result, productStatus, out prerequisite);
        }

        private static AICodedbPrerequisiteEvidenceDisposition ClassifyIndependentPrerequisiteEvidence(
            AICodedbCommandResult result,
            AICodedbProductStatus productStatus,
            out AICodedbProductLayerState prerequisite)
        {
            return ClassifyIndependentPrerequisiteEvidence(
                result != null,
                result != null && result.TimedOut,
                productStatus.Command.Present,
                productStatus.Command.IsValid,
                result == null ? string.Empty : result.StandardOutput,
                productStatus.Prerequisite,
                out prerequisite);
        }

        internal static AICodedbPrerequisiteEvidenceDisposition ClassifyIndependentPrerequisiteEvidence(
            bool resultPresent,
            bool timedOut,
            bool commandEnvelopePresent,
            bool commandEnvelopeValid,
            string standardOutput,
            AICodedbProductLayerState productStatusPrerequisite,
            out AICodedbProductLayerState prerequisite)
        {
            prerequisite = AICodedbProductLayerState.Unknown;
            if (!resultPresent)
                return AICodedbPrerequisiteEvidenceDisposition.ResultAbsent;
            if (timedOut)
                return AICodedbPrerequisiteEvidenceDisposition.CommandTimedOut;
            if (commandEnvelopePresent && !commandEnvelopeValid)
                return AICodedbPrerequisiteEvidenceDisposition.CommandEnvelopeInvalid;

            return ClassifyPrerequisiteMarker(
                standardOutput,
                productStatusPrerequisite,
                out prerequisite);
        }

        private static bool TryReadPrerequisiteMarker(
            AICodedbCommandResult result,
            AICodedbProductStatus productStatus,
            out AICodedbProductLayerState prerequisite)
        {
            var disposition = ClassifyPrerequisiteMarker(
                result.StandardOutput,
                productStatus.Prerequisite,
                out prerequisite);
            return disposition == AICodedbPrerequisiteEvidenceDisposition.TrustworthyCurrent
                   || disposition == AICodedbPrerequisiteEvidenceDisposition.TrustworthyMissing;
        }

        private static AICodedbPrerequisiteEvidenceDisposition ClassifyPrerequisiteMarker(
            string standardOutput,
            AICodedbProductLayerState productStatusPrerequisite,
            out AICodedbProductLayerState prerequisite)
        {
            prerequisite = AICodedbProductLayerState.Unknown;

            const string prefix = "[PRODUCT_LAYER PREREQUISITE]";
            var markerCount = 0;
            var markerValue = string.Empty;
            foreach (var line in (standardOutput ?? string.Empty).Split(
                         new[] { "\r\n", "\n" },
                         StringSplitOptions.None))
            {
                var trimmed = line.Trim();
                if (!trimmed.StartsWith(prefix, StringComparison.Ordinal))
                    continue;
                markerCount++;
                markerValue = trimmed.Substring(prefix.Length).Trim();
            }

            if (markerCount != 1)
                return AICodedbPrerequisiteEvidenceDisposition.MarkerCardinalityInvalid;
            if (IsExactPrerequisiteMarker(markerValue, "CURRENT"))
                prerequisite = AICodedbProductLayerState.Current;
            else if (IsExactPrerequisiteMarker(markerValue, "MISSING"))
                prerequisite = AICodedbProductLayerState.Missing;
            else
                return AICodedbPrerequisiteEvidenceDisposition.MarkerMalformed;

            if (productStatusPrerequisite != prerequisite)
                return AICodedbPrerequisiteEvidenceDisposition.MarkerProductStatusMismatch;
            return prerequisite == AICodedbProductLayerState.Current
                ? AICodedbPrerequisiteEvidenceDisposition.TrustworthyCurrent
                : AICodedbPrerequisiteEvidenceDisposition.TrustworthyMissing;
        }

        private static bool IsExactPrerequisiteMarker(string value, string state)
        {
            return string.Equals(value, state, StringComparison.Ordinal)
                   || string.Equals(value, state + " -", StringComparison.Ordinal)
                   || value.StartsWith(state + " - ", StringComparison.Ordinal);
        }

        /// <summary>
        /// Routes lifecycle commands through the project-local Supervisor. The
        /// call is made only from the background scheduler; Unity callbacks
        /// consume the resulting cache and never wait for this method.
        /// </summary>
        private static AICodedbCommandResult RunSupervisorCommand(
            AICodedbEditorExecutionContext context,
            string command,
            string action,
            CancellationToken cancellationToken)
        {
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.SynchronousIpc);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.PowerShellOrNode);
            var response = SupervisorBridge.SendCommand(
                context.ProjectRoot,
                command,
                action,
                null,
                false,
                cancellationToken);
            if (response != null && response.Snapshot != null)
                RememberSupervisorSnapshot(response.Snapshot);
            var commandResult = response == null
                ? new AICodedbCommandResult(4, string.Empty, "The project Supervisor returned no command response.", false)
                : response.ToCommandResult();
            if (!commandResult.Succeeded
                && IsSupervisorOneShotFallbackAllowed(commandResult)
                && string.Equals(command, "materialize", StringComparison.Ordinal))
            {
                AICodedbLifecycleEvidence.RecordMaterializerCommand(true);
                // The Bridge grants this only for an empty-runtime bootstrap.
                // Outage or ambiguous-owner failures never enter this branch.
                if (string.Equals(action, "Probe", StringComparison.Ordinal))
                    return AICodedbHostPayloadMaterializer.ReadStatus(context, cancellationToken);
                if (string.Equals(action, "Upgrade", StringComparison.Ordinal))
                    return AICodedbHostPayloadMaterializer.RunUpgrade(context, cancellationToken);
            }
            if (string.Equals(command, "materialize", StringComparison.Ordinal))
                AICodedbLifecycleEvidence.RecordMaterializerCommand(false);
            return commandResult;
        }

        internal static bool IsSupervisorOneShotFallbackAllowed(AICodedbCommandResult result)
        {
            return result != null
                   && !result.Succeeded
                   && result.OneShotFallbackAuthorized;
        }

        internal static async Task<AICodedbCommandResult> RunSupervisorCommandAsync(
            string command,
            string action,
            bool confirmedProjectMutation,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            var projectRoot = _projectRoot;
            if (string.IsNullOrWhiteSpace(projectRoot))
                projectRoot = AICodedbPaths.ProjectRoot;
            var response = await SupervisorBridge.SendCommandAsync(
                projectRoot,
                command,
                action,
                null,
                confirmedProjectMutation,
                cancellationToken);
            if (string.Equals(command, "materialize", StringComparison.Ordinal))
                AICodedbLifecycleEvidence.RecordMaterializerCommand(false);
            if (response != null && response.Snapshot != null)
                RememberSupervisorSnapshot(response.Snapshot);
            return response == null
                ? new AICodedbCommandResult(4, string.Empty, "The project Supervisor returned no command response.", false)
                : response.ToCommandResult();
        }

        /// <summary>
        /// Submits a Manager maintenance intent through the local lifetime gate;
        /// runtime admission and execution remain owned by the project Supervisor.
        /// </summary>
        internal static async Task<AICodedbCommandResult> RunSupervisorMaintenanceCommandAsync(
            string action)
        {
            var projectRoot = _projectRoot;
            if (string.IsNullOrWhiteSpace(projectRoot))
                projectRoot = AICodedbPaths.ProjectRoot;

            var response = await SupervisorIntentAdapter.Dispatch(
                AICodedbSupervisorRequestKind.Maintenance,
                cancellationToken => SupervisorBridge.SendCommandAsync(
                    projectRoot,
                    "maintenance",
                    action,
                    null,
                    false,
                    cancellationToken),
                true);
            if (response != null && response.Snapshot != null)
            {
                // Do not publish a Supervisor-only cache revision. The requested
                // reconcile will bind product and Supervisor evidence atomically.
                AICodedbLifecycleEvidence.RecordSupervisorObservation(response.Snapshot);
            }
            return response == null
                ? new AICodedbCommandResult(4, string.Empty, "The project Supervisor returned no maintenance response.", false)
                : response.ToCommandResult();
        }

        private static void RememberSupervisorSnapshot(AICodedbSupervisorSnapshot snapshot)
        {
            if (snapshot == null)
                return;
            // The Bridge remains the source of truth for the observation. A
            // cache revision lets Manager consume it without contacting the
            // runtime or becoming a second readiness authority.
            lock (HostStatusCacheLock)
            {
                _cachedLifecycleSupervisorSnapshot = snapshot;
                _cachedHostStatusRevision++;
            }
            AICodedbLifecycleEvidence.RecordSupervisorObservation(snapshot);
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
            var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot, context.PackageRoot);
            if (!currentInstance.Present)
                return true;
            if (currentInstance.IsTrustedPrevious)
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
            // wait for their owners to drain. PENDING requests only the
            // bounded retirement branch; it never redeploys current.
            if (!currentInstancePresent)
                return true;
            return currentInstanceIsCurrent
                   && (productState != AICodedbProductState.Ready
                       || cleanupState == AICodedbProjectCleanupState.Pending);
        }

        internal static AICodedbCurrentInstanceConvergencePlan ResolveCurrentInstanceConvergencePlan(
            bool currentInstancePresent,
            bool currentInstanceIsCurrent,
            AICodedbProductStatus productStatus)
        {
            return ResolveCurrentInstanceConvergencePlan(
                !currentInstancePresent
                    ? AICodedbCurrentInstanceState.Missing
                    : currentInstanceIsCurrent
                        ? AICodedbCurrentInstanceState.Current
                        : AICodedbCurrentInstanceState.Invalid,
                productStatus);
        }

        internal static AICodedbCurrentInstanceConvergencePlan ResolveCurrentInstanceConvergencePlan(
            AICodedbCurrentInstanceState currentInstanceState,
            AICodedbProductStatus productStatus)
        {
            return ResolveCurrentInstanceConvergencePlan(
                currentInstanceState,
                productStatus,
                AICodedbProjectCleanupState.Complete);
        }

        internal static AICodedbCurrentInstanceConvergencePlan ResolveCurrentInstanceConvergencePlan(
            AICodedbCurrentInstanceState currentInstanceState,
            AICodedbProductStatus productStatus,
            AICodedbProjectCleanupState cleanupState)
        {
            if (currentInstanceState == AICodedbCurrentInstanceState.Missing
                || currentInstanceState == AICodedbCurrentInstanceState.TrustedPrevious)
                return AICodedbCurrentInstanceConvergencePlan.Deploy;
            if (currentInstanceState != AICodedbCurrentInstanceState.Current)
                return AICodedbCurrentInstanceConvergencePlan.Blocked;
            if (productStatus.State == AICodedbProductState.Ready)
                return cleanupState == AICodedbProjectCleanupState.Pending
                    ? AICodedbCurrentInstanceConvergencePlan.Retire
                    : AICodedbCurrentInstanceConvergencePlan.None;
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

        internal static AICodedbPostAdmissionDisposition ResolvePostAdmissionConvergenceDisposition(
            AICodedbCurrentInstanceConvergencePlan plan)
        {
            switch (plan)
            {
                case AICodedbCurrentInstanceConvergencePlan.Retire:
                    return AICodedbPostAdmissionDisposition.RetirementSelected;
                case AICodedbCurrentInstanceConvergencePlan.Deploy:
                    return AICodedbPostAdmissionDisposition.DeploymentSelected;
                case AICodedbCurrentInstanceConvergencePlan.RecoverAvailability:
                    return AICodedbPostAdmissionDisposition.AvailabilityRecoverySelected;
                case AICodedbCurrentInstanceConvergencePlan.Blocked:
                    return AICodedbPostAdmissionDisposition.ConvergenceBlocked;
                default:
                    return AICodedbPostAdmissionDisposition.ConvergenceComplete;
            }
        }

        private static LifecycleReconcileResult RecoverCurrentInstanceAvailability(
            AICodedbEditorExecutionContext context,
            AICodedbProjectIntegrationStatus integrationStatus,
            Func<bool> canContinue,
            CancellationToken cancellationToken)
        {
            if (!canContinue())
                return null;

            AICodedbCommandResult ensureResult;
            var probeResult = RunWatcherThenAvailability(
                canContinue,
                () => RunSupervisorCommand(context, "watcher", "Ensure", cancellationToken),
                () => RunSupervisorCommand(
                    context,
                    "materialize",
                    "Probe",
                    cancellationToken),
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
            productStatus = RememberLifecycleProductStatus(productStatus, probeResult);
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

        internal static bool ShouldSuspendMaintenance(
            bool isCompiling,
            bool isUpdating,
            bool isPlayModeMaintenanceSuspended)
        {
            return isCompiling || isUpdating || isPlayModeMaintenanceSuspended;
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
                && !ShouldSuspendMaintenance(
                    EditorApplication.isCompiling,
                    EditorApplication.isUpdating,
                    IsPlayModeMaintenanceSuspended()))
                BeginReconcile(true);
        }

        /// <summary>
        /// Requests a best-effort background observation without forcing the
        /// mutation/convergence branch. The Manager uses this as a lifecycle
        /// signal; it never launches a materializer process itself.
        /// </summary>
        internal static void RequestBackgroundStatusObservation()
        {
            RequestBackgroundStatusObservation(false);
        }

        internal static void RequestBackgroundStatusObservation(bool force)
        {
            if (_initialized && !_quitting)
                QueueSupervisorReconnect(force);
        }

        internal static bool IsLifecycleInitialized => _initialized && !_quitting;

        private static void CancelBackgroundMaintenanceForBoundary()
        {
            BackgroundScheduler.SetMaintenanceSuspended(true);
            SupervisorIntentAdapter.SetMaintenanceSuspended(true);
        }

        internal static AICodedbSupervisorSnapshot GetCachedSupervisorSnapshot()
        {
            return SupervisorBridge.CachedSnapshot;
        }

        internal static AICodedbSupervisorReadinessState GetCachedSupervisorReadiness()
        {
            return SupervisorBridge.CachedSnapshot.ReadinessState;
        }

        internal static AICodedbSupervisorQueueSnapshot GetSupervisorQueueSnapshot()
        {
            return SupervisorIntentAdapter.Snapshot;
        }

        private static void QueueSupervisorReconnect(bool force)
        {
            if (!_initialized
                || _quitting
                || Volatile.Read(ref _automaticSupervisorStartAllowed) == 0
                || ShouldDeferSupervisorReconnect(
                    EditorApplication.isCompiling,
                    EditorApplication.isUpdating,
                    EditorApplication.isPlayingOrWillChangePlaymode,
                    Application.isPlaying)
                || string.IsNullOrWhiteSpace(_projectRoot))
                return;

            // The Bridge owns its worker and never blocks this Editor callback.
            // The local adapter guards only this Unity lifetime; the project
            // Supervisor owns query priority and runtime admission.
            var projectRoot = _projectRoot;
            var task = SupervisorIntentAdapter.Dispatch(
                AICodedbSupervisorRequestKind.Reconnect,
                cancellationToken => SupervisorBridge.ReconnectAsync(projectRoot, force),
                false);
            _ = task.ContinueWith(
                completed =>
                {
                    if (completed.IsFaulted && !_quitting)
                        Debug.LogWarning("CodeDB Supervisor reconnect failed: " + completed.Exception.GetBaseException().Message);
                },
                CancellationToken.None,
                TaskContinuationOptions.OnlyOnFaulted | TaskContinuationOptions.ExecuteSynchronously,
                TaskScheduler.Default);
            _ = task.ContinueWith(
                completed => RememberSupervisorSnapshot(completed.Result),
                CancellationToken.None,
                TaskContinuationOptions.OnlyOnRanToCompletion | TaskContinuationOptions.ExecuteSynchronously,
                TaskScheduler.Default);
        }

        internal static bool ShouldDeferSupervisorReconnect(
            bool isCompiling,
            bool isUpdating,
            bool isPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return ShouldDeferLifecycleInitialization(
                isCompiling,
                isUpdating,
                isPlayingOrWillChangePlaymode,
                applicationPlaying);
        }

        private static void QueueOwnedSupervisorShutdown()
        {
            if (string.IsNullOrWhiteSpace(_projectRoot))
                return;

            try
            {
                // This only schedules a worker. The quitting callback neither
                // reads Supervisor evidence nor waits for named-pipe I/O.
                AICodedbLifecycleEvidence.RecordShutdownRequested();
                var task = SupervisorBridge.RequestOwnedShutdownAsync(
                    _projectRoot,
                    "unity-bridge");
                _ = task.ContinueWith(
                    completed => AICodedbLifecycleEvidence.RecordShutdownDisposition(completed.Result),
                    CancellationToken.None,
                    TaskContinuationOptions.OnlyOnRanToCompletion | TaskContinuationOptions.ExecuteSynchronously,
                    TaskScheduler.Default);
                _ = task.ContinueWith(
                    completed =>
                    {
                        // Observe a fault without touching Unity APIs. The
                        // Supervisor also has a coordinator-offline fallback.
                        _ = completed.Exception;
                    },
                    CancellationToken.None,
                    TaskContinuationOptions.OnlyOnFaulted | TaskContinuationOptions.ExecuteSynchronously,
                    TaskScheduler.Default);
            }
            catch
            {
                // Final shutdown is best-effort and must never block Editor exit.
            }
        }

        private static void ReconnectSupervisorAfterReload()
        {
            if (!ShouldReconnectSupervisorAfterDomainReload(_initialized, _quitting))
                return;

            QueueSupervisorReconnect(true);
        }

        internal static bool ShouldReconnectSupervisorAfterDomainReload(
            bool initialized,
            bool quitting)
        {
            return initialized && !quitting;
        }

        private static void RequestReconcileIfNeeded()
        {
            if (!_initialized
                || _quitting
                || IsPlayModeMaintenanceSuspended())
                return;

            _nextReconcileAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            if (ShouldForceReconcileAfterPlayModeResume(_packageFingerprintChanged))
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

        internal static bool ShouldForceReconcileAfterPlayModeResume(bool packageFingerprintChanged)
        {
            return packageFingerprintChanged;
        }

        internal static bool ShouldRetainPendingPackageChange(
            bool packageFingerprintChanged,
            bool reconcileCompleted)
        {
            return packageFingerprintChanged && !reconcileCompleted;
        }

        internal static bool ShouldForceAvailabilityReconcileAfterPlayModeResume(
            AICodedbProductState previousProductState)
        {
            _ = previousProductState;
            return false;
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

        private static AICodedbTerminalConvergenceFailure ReadPersistedTerminalConvergenceFailure(
            string projectIdentity)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return null;

            var serialized = SessionState.GetString(
                TerminalConvergenceFailureKeyPrefix + projectIdentity,
                string.Empty);
            AICodedbTerminalConvergenceFailure failure;
            return AICodedbTerminalConvergenceFailure.TryDeserialize(
                       serialized,
                       GetCurrentPackageFingerprint(),
                       out failure)
                ? failure
                : null;
        }

        private static void PersistTerminalConvergenceFailure(
            string projectIdentity,
            AICodedbTerminalConvergenceFailure failure)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return;

            SessionState.SetString(
                TerminalConvergenceFailureKeyPrefix + projectIdentity,
                failure == null || !failure.IsValid ? string.Empty : failure.Serialize());
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

        private static bool ReadPersistedLeasePrerequisite(string projectIdentity)
        {
            return !string.IsNullOrWhiteSpace(projectIdentity)
                   && string.Equals(
                       SessionState.GetString(
                           LeasePrerequisiteCurrentKeyPrefix + projectIdentity,
                           string.Empty),
                       "true",
                       StringComparison.Ordinal);
        }

        private static void PersistLeasePrerequisite(
            string projectIdentity,
            bool prerequisiteCurrent)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return;
            SessionState.SetString(
                LeasePrerequisiteCurrentKeyPrefix + projectIdentity,
                prerequisiteCurrent ? "true" : string.Empty);
        }

        internal static bool ShouldRestoreLeasePrerequisite(
            bool persistedPrerequisiteCurrent,
            bool packageFingerprintChanged)
        {
            return persistedPrerequisiteCurrent && !packageFingerprintChanged;
        }

        internal static bool HasVerifiedReadyForCurrentPackage()
        {
            return HasVerifiedReadyForCurrentPackage(_projectRoot);
        }

        /// <summary>
        /// Reads the verified Ready marker for an explicit project root. This
        /// overload is limited to identity validation and SessionState reads so
        /// a Manager domain-reload callback can restore the handoff before the
        /// deferred lifecycle initializer runs.
        /// </summary>
        internal static bool HasVerifiedReadyForCurrentPackage(string projectRoot)
        {
            string projectIdentity;
            if (!TryResolveProjectIdentity(projectRoot, out projectIdentity))
                return false;
            return HasVerifiedReadyForPublishedProjectIdentity(projectIdentity);
        }

        private static bool HasVerifiedReadyForPublishedProjectIdentity(string projectIdentity)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return false;
            var fingerprint = SessionState.GetString(
                LastVerifiedReadyFingerprintKeyPrefix + projectIdentity,
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
            RecordProductStateForPlayMode(_projectRoot, state);
        }

        internal static void RecordProductStateForPlayMode(
            string projectRoot,
            AICodedbProductState state)
        {
            string projectIdentity;
            if (!TryResolveProjectIdentity(projectRoot, out projectIdentity))
                return;

            // The Manager can receive ExitingEditMode while its most recent
            // worker callback is still Starting. Preserve the stronger
            // same-package Ready observation instead of replacing it with a
            // transient state just before Domain Reload.
            if (state == AICodedbProductState.Starting
                && HasVerifiedReadyForCurrentPackage(projectRoot))
            {
                state = AICodedbProductState.Ready;
            }

            SessionState.SetString(
                PlayModeProductStateKeyPrefix + projectIdentity,
                state.ToString());
            SessionState.SetString(
                PlayModePackageFingerprintKeyPrefix + projectIdentity,
                GetCurrentPackageFingerprint());
        }

        internal static bool TryGetProductStateForPlayMode(out AICodedbProductState state)
        {
            return TryGetProductStateForPlayMode(_projectRoot, out state);
        }

        internal static bool TryGetProductStateForPlayMode(
            string projectRoot,
            out AICodedbProductState state)
        {
            state = AICodedbProductState.Starting;
            string projectIdentity;
            if (!TryResolveProjectIdentity(projectRoot, out projectIdentity))
                return false;

            var fingerprint = SessionState.GetString(
                PlayModePackageFingerprintKeyPrefix + projectIdentity,
                string.Empty);
            if (!string.Equals(fingerprint, GetCurrentPackageFingerprint(), StringComparison.Ordinal))
            {
                // The verified-ready marker is independently package-bound.
                // It covers the narrow window where Play begins before the
                // Manager callback can publish the temporary handoff key.
                if (HasVerifiedReadyForCurrentPackage(projectRoot))
                {
                    state = AICodedbProductState.Ready;
                    return true;
                }
                return false;
            }

            var value = SessionState.GetString(
                PlayModeProductStateKeyPrefix + projectIdentity,
                string.Empty);
            if (Enum.TryParse(value, false, out state))
            {
                if (state == AICodedbProductState.Starting
                    && HasVerifiedReadyForCurrentPackage(projectRoot))
                {
                    state = AICodedbProductState.Ready;
                }
                return true;
            }

            // The Manager may have verified Ready immediately before a domain
            // reload, before the play-mode callback could publish the display
            // state. Keep that stronger same-package evidence usable.
            if (HasVerifiedReadyForCurrentPackage(projectRoot))
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
            ClearProductStateForPlayMode(_projectRoot);
        }

        internal static void ClearProductStateForPlayMode(string projectRoot)
        {
            string projectIdentity;
            if (!TryResolveProjectIdentity(projectRoot, out projectIdentity))
                return;
            SessionState.SetString(PlayModeProductStateKeyPrefix + projectIdentity, string.Empty);
            SessionState.SetString(PlayModePackageFingerprintKeyPrefix + projectIdentity, string.Empty);
        }

        /// <summary>
        /// Records a verified Ready result for the current package in
        /// SessionState so a Manager domain reload during Play can retain the
        /// same display without performing project I/O.
        /// </summary>
        internal static void RecordVerifiedReadyForCurrentPackage()
        {
            RecordVerifiedReadyForCurrentPackage(_projectRoot);
        }

        internal static void RecordVerifiedReadyForCurrentPackage(string projectRoot)
        {
            string projectIdentity;
            if (!TryResolveProjectIdentity(projectRoot, out projectIdentity))
                return;
            // The Manager's complete read-only snapshot is an independent
            // Ready observation. The background lifecycle may still be
            // finishing the same convergence pass (or may have reported a
            // transient state), so do not discard this evidence merely because
            // its last worker result is not Ready yet.
            _lastProductState = AICodedbProductState.Ready;
            PersistProductState(projectIdentity, AICodedbProductState.Ready);
        }

        private static bool TryResolveProjectIdentity(
            string projectRoot,
            out string projectIdentity)
        {
            projectIdentity = string.Empty;
            if (string.IsNullOrWhiteSpace(projectRoot))
            {
                projectIdentity = _projectIdentity;
                return !string.IsNullOrWhiteSpace(projectIdentity);
            }

            // Reuse the initialized identity for the same project. During a
            // domain reload the lifecycle fields can be empty, so derive the
            // display-only SessionState key from the normalized path without
            // validating directories or touching project files. Mutation and
            // lease paths still perform their full validation on a worker.
            if (!string.IsNullOrWhiteSpace(_projectIdentity)
                && !string.IsNullOrWhiteSpace(_projectRoot)
                && string.Equals(
                    AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\'),
                    AICodedbPaths.NormalizePath(_projectRoot).TrimEnd('/', '\\'),
                    StringComparison.OrdinalIgnoreCase))
            {
                projectIdentity = _projectIdentity;
                return true;
            }

            try
            {
                projectIdentity = CreateProjectIdentityFromPath(projectRoot);
                return !string.IsNullOrWhiteSpace(projectIdentity);
            }
            catch
            {
                projectIdentity = string.Empty;
                return false;
            }
        }

        /// <summary>
        /// Selects an identity already published by lifecycle initialization
        /// for display-only cache reads. It never derives or validates an
        /// identity on the caller's thread.
        /// </summary>
        internal static bool TryGetPublishedProjectIdentityForDisplay(
            string projectRoot,
            string publishedProjectRoot,
            string publishedProjectIdentity,
            out string projectIdentity)
        {
            projectIdentity = string.Empty;
            if (string.IsNullOrWhiteSpace(projectRoot)
                || string.IsNullOrWhiteSpace(publishedProjectRoot)
                || string.IsNullOrWhiteSpace(publishedProjectIdentity))
            {
                return false;
            }

            try
            {
                var requestedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\');
                var availableRoot = AICodedbPaths.NormalizePath(publishedProjectRoot).TrimEnd('/', '\\');
                if (string.IsNullOrWhiteSpace(requestedRoot)
                    || string.IsNullOrWhiteSpace(availableRoot)
                    || !string.Equals(requestedRoot, availableRoot, StringComparison.OrdinalIgnoreCase))
                {
                    return false;
                }
            }
            catch
            {
                return false;
            }

            projectIdentity = publishedProjectIdentity;
            return true;
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

        /// <summary>
        /// Returns the most recent read-only materializer result produced by
        /// the lifecycle worker. Manager uses this handoff instead of starting
        /// a new PowerShell process merely because its window was opened.
        /// </summary>
        internal static bool TryGetCachedHostStatusResult(
            out AICodedbCommandResult result,
            out long revision)
        {
            lock (HostStatusCacheLock)
            {
                result = _cachedHostStatusResult;
                revision = _cachedHostStatusRevision;
                return result != null && !_hasCachedLifecycleProductStatus;
            }
        }

        internal static bool TryGetCachedLifecycleStatus(
            out AICodedbCommandResult result,
            out AICodedbProductStatus productStatus,
            out bool hasProductStatus,
            out long revision)
        {
            AICodedbSupervisorSnapshot ignored;
            return TryGetCachedLifecycleStatus(
                out result,
                out productStatus,
                out hasProductStatus,
                out ignored,
                out revision);
        }

        internal static bool TryGetCachedLifecycleStatus(
            out AICodedbCommandResult result,
            out AICodedbProductStatus productStatus,
            out bool hasProductStatus,
            out AICodedbSupervisorSnapshot supervisorSnapshot,
            out long revision)
        {
            AICodedbTerminalConvergenceFailure ignored;
            return TryGetCachedLifecycleStatus(
                out result,
                out productStatus,
                out hasProductStatus,
                out supervisorSnapshot,
                out ignored,
                out revision);
        }

        internal static bool TryGetCachedLifecycleStatus(
            out AICodedbCommandResult result,
            out AICodedbProductStatus productStatus,
            out bool hasProductStatus,
            out AICodedbSupervisorSnapshot supervisorSnapshot,
            out AICodedbTerminalConvergenceFailure terminalFailure,
            out long revision)
        {
            lock (HostStatusCacheLock)
            {
                result = _cachedHostStatusResult;
                productStatus = _cachedLifecycleProductStatus;
                hasProductStatus = _hasCachedLifecycleProductStatus;
                supervisorSnapshot = _cachedLifecycleSupervisorSnapshot;
                terminalFailure = _cachedTerminalConvergenceFailure;
                revision = _cachedHostStatusRevision;
                return result != null || hasProductStatus || terminalFailure != null;
            }
        }

        internal static AICodedbSupervisorSnapshot GetCachedLifecycleSupervisorSnapshot()
        {
            lock (HostStatusCacheLock)
                return _cachedLifecycleSupervisorSnapshot;
        }

        internal static AICodedbTerminalConvergenceFailure GetCachedTerminalConvergenceFailure()
        {
            lock (HostStatusCacheLock)
                return _cachedTerminalConvergenceFailure;
        }

        /// <summary>
        /// Reads the last persisted product state using SessionState only.
        /// This is a display hint for Manager startup; the lifecycle worker
        /// remains authoritative for live status and mutations.
        /// </summary>
        internal static bool TryGetPersistedProductState(
            string projectRoot,
            out AICodedbProductState state)
        {
            AICodedbTerminalConvergenceFailure ignored;
            return TryGetPersistedProductState(
                projectRoot,
                _projectRoot,
                _projectIdentity,
                out state,
                out ignored);
        }

        internal static bool TryGetPersistedProductState(
            string projectRoot,
            out AICodedbProductState state,
            out AICodedbTerminalConvergenceFailure terminalFailure)
        {
            return TryGetPersistedProductState(
                projectRoot,
                _projectRoot,
                _projectIdentity,
                out state,
                out terminalFailure);
        }

        internal static bool TryGetPersistedProductState(
            string projectRoot,
            string publishedProjectRoot,
            string publishedProjectIdentity,
            out AICodedbProductState state)
        {
            AICodedbTerminalConvergenceFailure ignored;
            return TryGetPersistedProductState(
                projectRoot,
                publishedProjectRoot,
                publishedProjectIdentity,
                out state,
                out ignored);
        }

        internal static bool TryGetPersistedProductState(
            string projectRoot,
            string publishedProjectRoot,
            string publishedProjectIdentity,
            out AICodedbProductState state,
            out AICodedbTerminalConvergenceFailure terminalFailure)
        {
            state = AICodedbProductState.Starting;
            terminalFailure = null;
            string projectIdentity;
            if (!TryGetPublishedProjectIdentityForDisplay(
                    projectRoot,
                    publishedProjectRoot,
                    publishedProjectIdentity,
                    out projectIdentity))
                return false;

            terminalFailure = ReadPersistedTerminalConvergenceFailure(projectIdentity);
            if (terminalFailure != null)
            {
                state = AICodedbProductState.NeedsAttention;
                return true;
            }

            var value = SessionState.GetString(
                LastProductStateKeyPrefix + projectIdentity,
                string.Empty);
            if (Enum.TryParse(value, false, out state))
                return true;

            if (HasVerifiedReadyForPublishedProjectIdentity(projectIdentity))
            {
                state = AICodedbProductState.Ready;
                return true;
            }

            return false;
        }

        private static AICodedbCommandResult RememberHostStatusResult(
            AICodedbCommandResult result)
        {
            if (result == null)
                return null;

            lock (HostStatusCacheLock)
            {
                _cachedHostStatusResult = result;
                _cachedLifecycleProductStatus = _cachedTerminalConvergenceFailure == null
                    ? default(AICodedbProductStatus)
                    : _cachedTerminalConvergenceFailure.ToProductStatus();
                _cachedLifecycleSupervisorSnapshot = null;
                _hasCachedLifecycleProductStatus = _cachedTerminalConvergenceFailure != null;
                _cachedHostStatusRevision++;
            }
            return result;
        }

        /// <summary>
        /// Publishes one coherent lifecycle cache tuple and advances its
        /// revision under the single cache lock.
        /// </summary>
        internal static void PublishLifecycleStatusCache(
            AICodedbCommandResult result,
            AICodedbProductStatus productStatus,
            bool hasProductStatus,
            AICodedbSupervisorSnapshot supervisorSnapshot,
            AICodedbTerminalConvergenceFailure terminalFailure)
        {
            lock (HostStatusCacheLock)
            {
                _cachedHostStatusResult = result;
                _cachedLifecycleProductStatus = productStatus;
                _cachedLifecycleSupervisorSnapshot = supervisorSnapshot;
                _cachedTerminalConvergenceFailure = terminalFailure;
                _hasCachedLifecycleProductStatus = hasProductStatus;
                _cachedHostStatusRevision++;
            }
        }

        internal static void PublishAuthoritativeUninstalledCache()
        {
            PublishLifecycleStatusCache(
                null,
                new AICodedbProductStatus(
                    AICodedbProductState.Uninstalled,
                    AICodedbProductLayerState.Unknown,
                    AICodedbProductLayerState.Unknown,
                    AICodedbProductLayerState.Unknown,
                    AICodedbProductLayerState.Unknown,
                    "CodeDB is uninstalled from this project; live checks resume after installation.",
                    default(AICodedbMaterializerCommandStatus),
                    AICodedbProductAttentionReason.None,
                    string.Empty),
                true,
                null,
                null);
        }

        private static AICodedbProductStatus RememberLifecycleProductStatus(
            AICodedbProductStatus productStatus,
            AICodedbCommandResult result = null)
        {
            AICodedbSupervisorSnapshot supervisorSnapshot;
            var authoritativeUninstalled =
                productStatus.State == AICodedbProductState.Uninstalled;
            if (authoritativeUninstalled)
                supervisorSnapshot = null;
            else
                productStatus = BindProductStatusToSupervisorObservation(
                    productStatus,
                    result,
                    SupervisorBridge.CachedSnapshot,
                    out supervisorSnapshot);

            AICodedbTerminalConvergenceFailure existingFailure;
            lock (HostStatusCacheLock)
                existingFailure = _cachedTerminalConvergenceFailure;

            AICodedbTerminalConvergenceFailure candidateFailure;
            var hasCandidateFailure = TryCreateTerminalConvergenceFailure(
                productStatus,
                result,
                supervisorSnapshot,
                out candidateFailure);
            var acceptedCandidate = hasCandidateFailure
                && ShouldReplaceTerminalConvergenceFailure(existingFailure, candidateFailure);
            var clearedFailure = ShouldClearTerminalConvergenceFailure(
                existingFailure,
                productStatus,
                result,
                supervisorSnapshot);

            if (authoritativeUninstalled)
                existingFailure = ResolveTerminalConvergenceFailureForProductState(
                    existingFailure,
                    productStatus.State);
            else if (acceptedCandidate)
                existingFailure = candidateFailure;
            else if (clearedFailure)
                existingFailure = null;
            else if (existingFailure != null
                     && productStatus.State != AICodedbProductState.Uninstalled)
            {
                // Starting, missing, malformed, or stale observations are not
                // authenticated replacements for the terminal envelope.
                productStatus = existingFailure.ToProductStatus();
            }

            PublishLifecycleStatusCache(
                result,
                productStatus,
                true,
                supervisorSnapshot,
                existingFailure);
            return productStatus;
        }

        internal static AICodedbProductStatus BindProductStatusToSupervisorObservation(
            AICodedbProductStatus productStatus,
            AICodedbCommandResult result,
            AICodedbSupervisorSnapshot observedSupervisorSnapshot,
            out AICodedbSupervisorSnapshot supervisorSnapshot)
        {
            const string prefix = "[SUPERVISOR_OPERATIONAL_READINESS]";
            supervisorSnapshot = null;
            if (result == null)
                return productStatus;

            try
            {
                string marker = null;
                var markerCount = 0;
                foreach (var line in (result.StandardOutput ?? string.Empty).Split(
                             new[] { "\r\n", "\n" },
                             StringSplitOptions.None))
                {
                    var trimmed = line.Trim();
                    if (!trimmed.StartsWith(prefix, StringComparison.Ordinal))
                        continue;
                    markerCount++;
                    marker = trimmed.Substring(prefix.Length).Trim();
                }

                if (markerCount == 0)
                {
                    return productStatus.State == AICodedbProductState.Ready
                        ? CreateObservationBindingFailure(
                            productStatus,
                            "Ready materializer output has no Supervisor operational observation.")
                        : productStatus;
                }
                if (markerCount != 1 || string.IsNullOrWhiteSpace(marker))
                {
                    return CreateObservationBindingFailure(
                        productStatus,
                        "Materializer output must contain exactly one operational observation marker.");
                }
                if (string.Equals(marker, "UNAVAILABLE", StringComparison.Ordinal))
                {
                    return productStatus.State == AICodedbProductState.Ready
                        ? CreateObservationBindingFailure(
                            productStatus,
                            "Ready materializer output has no authenticated Supervisor authority.")
                        : productStatus;
                }
                if (Encoding.UTF8.GetByteCount(marker) > 32 * 1024)
                {
                    return CreateObservationBindingFailure(
                        productStatus,
                        "The operational observation marker exceeds the bounded size.");
                }

                var observation = AICodedbStrictJson.ParseObject(
                    marker,
                    "Materializer Supervisor operational readiness");
                if (!AICodedbSupervisorProtocol.HasExactOperationalReadinessFields(observation))
                {
                    return CreateObservationBindingFailure(
                        productStatus,
                        "The materializer operational observation field set is invalid.");
                }
                var snapshot = observedSupervisorSnapshot;
                var observationId = AICodedbStrictJson.GetRequiredString(
                    observation,
                    "observation_id",
                    "Materializer Supervisor operational readiness");
                var revision = AICodedbStrictJson.GetRequiredInt64(
                    observation,
                    "revision",
                    "Materializer Supervisor operational readiness");
                if (snapshot == null
                    || !snapshot.HasOperationalReadinessObservation
                    || snapshot.OperationalObservationSchemaVersion
                        != AICodedbStrictJson.GetRequiredInt32(
                            observation,
                            "schema_version",
                            "Materializer Supervisor operational readiness")
                    || !string.Equals(
                        snapshot.OperationalObservationId,
                        observationId,
                        StringComparison.Ordinal)
                    || snapshot.OperationalObservationRevision != revision
                    || !string.Equals(
                        snapshot.OwnerEpoch,
                        AICodedbStrictJson.GetRequiredString(
                            observation,
                            "owner_epoch",
                            "Materializer Supervisor operational readiness"),
                        StringComparison.Ordinal)
                    || !string.Equals(
                        snapshot.SupervisorId,
                        AICodedbStrictJson.GetRequiredString(
                            observation,
                            "supervisor_id",
                            "Materializer Supervisor operational readiness"),
                        StringComparison.Ordinal)
                    || snapshot.SupervisorProcessId
                        != AICodedbStrictJson.GetRequiredInt32(
                            observation,
                            "supervisor_pid",
                            "Materializer Supervisor operational readiness"))
                {
                    return CreateObservationBindingFailure(
                        productStatus,
                        "Materializer and Bridge operational observations do not identify the same revision.");
                }

                supervisorSnapshot = snapshot;
                return productStatus;
            }
            catch (Exception exception)
            {
                return CreateObservationBindingFailure(
                    productStatus,
                    "The materializer operational observation is invalid: " + exception.Message);
            }
        }

        private static AICodedbProductStatus CreateObservationBindingFailure(
            AICodedbProductStatus productStatus,
            string detail)
        {
            return new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                productStatus.Prerequisite,
                productStatus.Installed,
                productStatus.Configured,
                AICodedbProductLayerState.Blocked,
                detail,
                productStatus.Command,
                AICodedbProductAttentionReason.None,
                productStatus.DiagnosticDetail);
        }

        internal static bool TryCreateTerminalConvergenceFailure(
            AICodedbProductStatus productStatus,
            AICodedbCommandResult result,
            AICodedbSupervisorSnapshot supervisorSnapshot,
            out AICodedbTerminalConvergenceFailure failure)
        {
            failure = null;
            if (productStatus.State != AICodedbProductState.NeedsAttention
                || result == null
                || result.TimedOut
                || !IsAuthenticatedTerminalObservation(supervisorSnapshot))
                return false;

            var command = AICodedbMaterializerCommandStatusParser.Parse(result.StandardOutput);
            var reasonCode = command.IsValid && !string.IsNullOrWhiteSpace(command.ReasonCode)
                ? command.ReasonCode
                : supervisorSnapshot.ReasonCode;
            if (!IsBoundedTerminalToken(reasonCode))
                reasonCode = "CONVERGENCE_FAILURE";

            var boundedStatus = new AICodedbProductStatus(
                productStatus.State,
                productStatus.Prerequisite,
                productStatus.Installed,
                productStatus.Configured,
                productStatus.McpAvailable,
                BoundedEvidenceText(productStatus.Detail),
                productStatus.Command,
                productStatus.AttentionReason,
                BoundedEvidenceText(productStatus.DiagnosticDetail));
            failure = new AICodedbTerminalConvergenceFailure(
                boundedStatus,
                reasonCode,
                AICodedbTerminalConvergenceFailure.ProducerName,
                GetCurrentPackageFingerprint(),
                supervisorSnapshot.TargetGenerationId,
                supervisorSnapshot.SelectedGenerationId,
                supervisorSnapshot.SelectedInstanceId,
                supervisorSnapshot.RuntimeContractSha256,
                supervisorSnapshot.OperationalObservationId,
                supervisorSnapshot.SupervisorId,
                supervisorSnapshot.OwnerEpoch,
                supervisorSnapshot.OperationalObservationRevision);
            return failure.IsValid;
        }

        internal static bool ShouldReplaceTerminalConvergenceFailure(
            AICodedbTerminalConvergenceFailure existing,
            AICodedbTerminalConvergenceFailure candidate)
        {
            if (candidate == null || !candidate.IsValid)
                return false;
            if (existing == null || !existing.IsValid)
                return true;
            if (!string.Equals(
                    existing.PackageFingerprint,
                    candidate.PackageFingerprint,
                    StringComparison.Ordinal))
                return false;
            return !HasSameTerminalAuthority(
                       existing,
                       candidate.SupervisorId,
                       candidate.OwnerEpoch)
                   || candidate.Revision > existing.Revision;
        }

        internal static AICodedbTerminalConvergenceFailure
            ResolveTerminalConvergenceFailureForProductState(
                AICodedbTerminalConvergenceFailure existing,
                AICodedbProductState productState)
        {
            return productState == AICodedbProductState.Uninstalled
                ? null
                : existing;
        }

        internal static bool IsAuthenticatedTerminalSuccess(
            AICodedbProductStatus productStatus,
            AICodedbCommandResult result,
            AICodedbSupervisorSnapshot supervisorSnapshot)
        {
            return productStatus.State == AICodedbProductState.Ready
                   && result != null
                   && result.Succeeded
                   && !result.TimedOut
                   && productStatus.Prerequisite == AICodedbProductLayerState.Current
                   && productStatus.Installed == AICodedbProductLayerState.Current
                   && productStatus.Configured == AICodedbProductLayerState.Current
                   && productStatus.McpAvailable == AICodedbProductLayerState.Current
                   && IsAuthenticatedTerminalObservation(supervisorSnapshot)
                   && supervisorSnapshot.ReadinessState == AICodedbSupervisorReadinessState.CoreReady;
        }

        internal static bool ShouldClearTerminalConvergenceFailure(
            AICodedbTerminalConvergenceFailure existing,
            AICodedbProductStatus productStatus,
            AICodedbCommandResult result,
            AICodedbSupervisorSnapshot supervisorSnapshot)
        {
            return existing != null
                   && existing.IsValid
                   && IsAuthenticatedTerminalSuccess(productStatus, result, supervisorSnapshot)
                   && string.Equals(
                       existing.PackageFingerprint,
                       GetCurrentPackageFingerprint(),
                       StringComparison.Ordinal)
                   && (!HasSameTerminalAuthority(
                           existing,
                           supervisorSnapshot.SupervisorId,
                           supervisorSnapshot.OwnerEpoch)
                       || supervisorSnapshot.OperationalObservationRevision > existing.Revision);
        }

        private static bool HasSameTerminalAuthority(
            AICodedbTerminalConvergenceFailure existing,
            string supervisorId,
            string ownerEpoch)
        {
            return existing != null
                   && string.Equals(
                       existing.SupervisorId,
                       supervisorId,
                       StringComparison.Ordinal)
                   && string.Equals(
                       existing.OwnerEpoch,
                       ownerEpoch,
                       StringComparison.Ordinal);
        }

        private static bool IsAuthenticatedTerminalObservation(
            AICodedbSupervisorSnapshot supervisorSnapshot)
        {
            if (supervisorSnapshot == null
                || !supervisorSnapshot.HasOperationalReadinessObservation
                || supervisorSnapshot.OperationalObservationRevision <= 0
                || supervisorSnapshot.ReadinessState == AICodedbSupervisorReadinessState.Unknown
                || supervisorSnapshot.ReadinessState == AICodedbSupervisorReadinessState.Starting
                || supervisorSnapshot.ReadinessState == AICodedbSupervisorReadinessState.Maintenance
                || supervisorSnapshot.ReadinessState == AICodedbSupervisorReadinessState.Stopping
                || supervisorSnapshot.ReadinessState == AICodedbSupervisorReadinessState.Stopped)
                return false;

            return IsBoundedTerminalToken(supervisorSnapshot.TargetGenerationId)
                   && IsBoundedTerminalToken(supervisorSnapshot.SelectedGenerationId)
                   && IsBoundedTerminalToken(supervisorSnapshot.RuntimeContractSha256)
                   && IsBoundedTerminalToken(supervisorSnapshot.OperationalObservationId)
                   && IsBoundedTerminalToken(supervisorSnapshot.SupervisorId)
                   && IsBoundedTerminalToken(supervisorSnapshot.OwnerEpoch);
        }

        private static bool IsBoundedTerminalToken(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length > 128)
                return false;
            foreach (var character in value)
            {
                if ((character >= 'a' && character <= 'z')
                    || (character >= 'A' && character <= 'Z')
                    || (character >= '0' && character <= '9')
                    || character == '.'
                    || character == '_'
                    || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        private static string BoundedEvidenceText(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return string.Empty;

            var builder = new StringBuilder(Math.Min(value.Length, 2048));
            foreach (var character in value.Trim())
            {
                if (builder.Length >= 2048)
                    break;
                builder.Append(char.IsControl(character) ? ' ' : character);
            }
            return builder.ToString().Trim();
        }

        private static bool HasPackageFingerprintChanged(string projectIdentity)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return true;

            var fingerprint = GetCurrentPackageFingerprint();
            var key = LastPackageFingerprintKeyPrefix + projectIdentity;
            var previous = SessionState.GetString(key, string.Empty);
            return !string.Equals(previous, fingerprint, StringComparison.Ordinal);
        }

        private static void RecordReconciledPackageFingerprint(string projectIdentity)
        {
            if (string.IsNullOrWhiteSpace(projectIdentity))
                return;

            SessionState.SetString(
                LastPackageFingerprintKeyPrefix + projectIdentity,
                GetCurrentPackageFingerprint());
        }

        private static string GetCurrentPackageFingerprint()
        {
            return string.Join(
                "|",
                AICodedbBrandAssets.PackageVersion,
                typeof(AICodedbEditorLifecycle).Assembly.ManifestModule.ModuleVersionId.ToString("N"));
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

        internal static bool ShouldAttemptCoordinatorAdmission(
            bool independentPrerequisiteRead,
            bool prerequisiteCurrent,
            bool editorLeasePublished)
        {
            return !independentPrerequisiteRead
                   || (prerequisiteCurrent && editorLeasePublished);
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
                    var statusResult = RememberHostStatusResult(
                        RunSupervisorCommand(context, "materialize", "Probe", CancellationToken.None));
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
                var observedFingerprint = await SupervisorIntentAdapter.Dispatch(
                    AICodedbSupervisorRequestKind.ObserveStatus,
                    cancellationToken => BackgroundScheduler.QueueMaintenance(
                        canContinue => canContinue() && !cancellationToken.IsCancellationRequested
                            ? CaptureMachinePrerequisiteEvidenceFingerprint(_executionContext)
                            : string.Empty),
                    true);
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
            _ = TryRefreshEditorLeaseForAdmission(context);
        }

        private static AICodedbCoordinatorAdmissionDisposition TryRefreshEditorLeaseForAdmission(
            AICodedbEditorExecutionContext context)
        {
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.BlockingLock);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            try
            {
                lock (LeaseIoLock)
                {
                    var integrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
                    var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot, context.PackageRoot);
                    var initialDisposition = ClassifyEditorLeasePublication(
                        integrationStatus,
                        currentInstance,
                        false);
                    if (initialDisposition != AICodedbCoordinatorAdmissionDisposition.LeasePublicationFailed)
                    {
                        DeleteEditorLease();
                        return initialDisposition;
                    }

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
                    return ClassifyEditorLeasePublication(
                        integrationStatus,
                        currentInstance,
                        HasPublishedEditorLease());
                }
            }
            catch
            {
                return AICodedbCoordinatorAdmissionDisposition.LeasePublicationFailed;
            }
        }

        internal static AICodedbCoordinatorAdmissionDisposition ClassifyEditorLeasePublication(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbCurrentInstanceStatus currentInstance,
            bool leasePublished)
        {
            return ClassifyEditorLeasePublication(
                integrationStatus.State,
                currentInstance.State,
                currentInstance.Present,
                currentInstance.CanPublishEditorLease,
                leasePublished);
        }

        internal static AICodedbCoordinatorAdmissionDisposition ClassifyEditorLeasePublication(
            AICodedbProjectIntegrationState integrationState,
            AICodedbCurrentInstanceState currentInstanceState,
            bool currentInstancePresent,
            bool canPublishEditorLease,
            bool leasePublished)
        {
            if (integrationState != AICodedbProjectIntegrationState.Installed)
                return AICodedbCoordinatorAdmissionDisposition.IntegrationNotEligible;
            if (currentInstanceState == AICodedbCurrentInstanceState.Invalid)
                return AICodedbCoordinatorAdmissionDisposition.CurrentInstanceInvalid;
            if (!currentInstancePresent)
                return AICodedbCoordinatorAdmissionDisposition.CurrentInstanceMissing;
            if (!canPublishEditorLease)
                return AICodedbCoordinatorAdmissionDisposition.CurrentInstanceIneligible;
            return leasePublished
                ? AICodedbCoordinatorAdmissionDisposition.EditorLeasePublished
                : AICodedbCoordinatorAdmissionDisposition.LeasePublicationFailed;
        }

        private static bool HasPublishedEditorLease()
        {
            lock (LeaseIoLock)
            {
                return !string.IsNullOrWhiteSpace(_leasePath)
                       && File.Exists(_leasePath);
            }
        }

        internal static bool ShouldPublishEditorLeaseForInstance(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbCurrentInstanceStatus currentInstance)
        {
            return ShouldPublishEditorLease(integrationStatus)
                   && currentInstance.CanPublishEditorLease;
        }

        private static void RefreshEditorLeaseHeartbeat()
        {
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.BlockingLock);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            lock (LeaseIoLock)
            {
                if (string.IsNullOrWhiteSpace(_leasePath))
                {
                    // Domain Reload clears managed fields but preserves the
                    // current Editor session and its durable lease. Re-resolve
                    // the exact selected-instance lease path on this worker.
                    RefreshEditorLeaseForIntegrationState(_executionContext);
                    return;
                }

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
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.BlockingLock);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            string leasePath;
            lock (LeaseIoLock)
            {
                leasePath = _leasePath;
                _leasePath = string.Empty;
            }

            DeleteEditorLeaseAtPath(leasePath);
        }

        private static void QueueEditorLeaseDeletion()
        {
            var leasePath = TakeEditorLeasePathForDeletion(ref _leasePath);

            if (string.IsNullOrWhiteSpace(leasePath))
                return;

            // Unity's quitting callback must not wait on filesystem metadata or
            // deletion. Capture the exact path before the domain starts to
            // unload and let the lease worker perform best-effort cleanup.
            _ = BackgroundScheduler.QueueLease(() => DeleteEditorLeaseAtPath(leasePath));
        }

        internal static string TakeEditorLeasePathForDeletion(ref string leasePath)
        {
            return Interlocked.Exchange(ref leasePath, string.Empty);
        }

        private static void DeleteEditorLeaseAtPath(string leasePath)
        {
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            try
            {
                if (!string.IsNullOrWhiteSpace(leasePath) && File.Exists(leasePath))
                    File.Delete(leasePath);
            }
            catch (Exception exception)
            {
                if (!_quitting)
                    Debug.LogWarning($"CodeDB could not remove its Editor lease: {exception.Message}");
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
                var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot, context.PackageRoot);
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
            int concurrentReadAttempts,
            CancellationToken cancellationToken)
        {
            var attempts = IsConcurrentUpgrade(upgradeResult) ? concurrentReadAttempts : 1;
            AICodedbHostPayloadStatus status = default(AICodedbHostPayloadStatus);
            for (var attempt = 0; attempt < attempts; attempt++)
            {
                if (!canContinue())
                    return status;
                status = BuildHostPayloadStatus(
                    RememberHostStatusResult(
                        RunSupervisorCommand(context, "materialize", "Probe", cancellationToken)),
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
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.Hash);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.Process);
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
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem);
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.Hash);
            var canonical = ValidateProjectRoot(projectRoot);
            return CreateProjectIdentityFromCanonicalPath(canonical);
        }

        private static string CreateProjectIdentityFromPath(string projectRoot)
        {
            AICodedbLifecycleEvidence.RecordWork(AICodedbLifecycleWorkKind.Hash);
            if (string.IsNullOrWhiteSpace(projectRoot))
                return string.Empty;

            var canonical = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\');
            if (string.IsNullOrWhiteSpace(canonical))
                return string.Empty;

            return CreateProjectIdentityFromCanonicalPath(canonical);
        }

        private static string CreateProjectIdentityFromCanonicalPath(string canonicalPath)
        {
            var canonical = canonicalPath.ToLowerInvariant();
            using (var sha256 = SHA256.Create())
            {
                var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(canonical));
                var builder = new StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return "sha256:" + builder;
            }
        }

        private static string ReadSessionProjectIdentity()
        {
            var value = SessionState.GetString(SessionProjectIdentityKey, string.Empty);
            if (value.Length != "sha256:".Length + 64
                || !value.StartsWith("sha256:", StringComparison.Ordinal))
                return string.Empty;
            for (var index = "sha256:".Length; index < value.Length; index++)
            {
                var character = value[index];
                if ((character < '0' || character > '9')
                    && (character < 'a' || character > 'f'))
                    return string.Empty;
            }
            return value;
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
            Retire,
            Deploy,
            RecoverAvailability,
            Blocked
        }

        internal enum AICodedbPostAdmissionDisposition
        {
            NotEvaluated,
            MigrationBlocked,
            BackendReconcileNotRequired,
            IntegrationInvalid,
            UninstallCleanup,
            Uninstalled,
            InitialSupervisorProbeEvaluated,
            ProbeReportedMissingPrerequisite,
            CurrentInstanceInvalid,
            RetirementSelected,
            DeploymentSelected,
            AvailabilityRecoverySelected,
            ConvergenceBlocked,
            ConvergenceComplete
        }

        internal enum AICodedbCoordinatorAdmissionDisposition
        {
            Unknown,
            ExistingLease,
            PrerequisiteMissing,
            PrerequisiteEvidenceUntrustworthy,
            IntegrationNotEligible,
            CurrentInstanceMissing,
            CurrentInstanceInvalid,
            CurrentInstanceIneligible,
            EditorLeasePublished,
            LeasePublicationFailed
        }

        internal enum AICodedbPrerequisiteEvidenceDisposition
        {
            Unknown,
            ResultAbsent,
            CommandTimedOut,
            CommandEnvelopeInvalid,
            MarkerCardinalityInvalid,
            MarkerMalformed,
            MarkerProductStatusMismatch,
            TrustworthyCurrent,
            TrustworthyMissing
        }

        /// <summary>
        /// The single lifecycle-owned terminal failure handoff. It is bound to
        /// an authenticated Supervisor operational observation so a coarse
        /// persisted product state can never manufacture actionable detail.
        /// </summary>
        internal sealed class AICodedbTerminalConvergenceFailure
        {
            internal const int SchemaVersion = 1;
            internal const string ProducerName = "SupervisorOperationalReadiness";

            private readonly AICodedbProductStatus _productStatus;
            private readonly string _reasonCode;
            private readonly string _producer;
            private readonly string _packageFingerprint;
            private readonly string _targetGenerationId;
            private readonly string _selectedGenerationId;
            private readonly string _selectedInstanceId;
            private readonly string _runtimeContractSha256;
            private readonly string _observationId;
            private readonly string _supervisorId;
            private readonly string _ownerEpoch;
            private readonly long _revision;

            internal AICodedbTerminalConvergenceFailure(
                AICodedbProductStatus productStatus,
                string reasonCode,
                string producer,
                string packageFingerprint,
                string targetGenerationId,
                string selectedGenerationId,
                string selectedInstanceId,
                string runtimeContractSha256,
                string observationId,
                string supervisorId,
                string ownerEpoch,
                long revision)
            {
                _productStatus = new AICodedbProductStatus(
                    productStatus.State,
                    productStatus.Prerequisite,
                    productStatus.Installed,
                    productStatus.Configured,
                    productStatus.McpAvailable,
                    BoundedEvidenceText(productStatus.Detail),
                    productStatus.Command,
                    productStatus.AttentionReason,
                    BoundedEvidenceText(productStatus.DiagnosticDetail));
                _reasonCode = reasonCode ?? string.Empty;
                _producer = producer ?? string.Empty;
                _packageFingerprint = packageFingerprint ?? string.Empty;
                _targetGenerationId = targetGenerationId ?? string.Empty;
                _selectedGenerationId = selectedGenerationId ?? string.Empty;
                _selectedInstanceId = selectedInstanceId ?? string.Empty;
                _runtimeContractSha256 = runtimeContractSha256 ?? string.Empty;
                _observationId = observationId ?? string.Empty;
                _supervisorId = supervisorId ?? string.Empty;
                _ownerEpoch = ownerEpoch ?? string.Empty;
                _revision = revision;
            }

            internal AICodedbProductStatus ProductStatus => _productStatus;
            internal string ReasonCode => _reasonCode;
            internal string Producer => _producer;
            internal string PackageFingerprint => _packageFingerprint;
            internal string TargetGenerationId => _targetGenerationId;
            internal string SelectedGenerationId => _selectedGenerationId;
            internal string SelectedInstanceId => _selectedInstanceId;
            internal string RuntimeContractSha256 => _runtimeContractSha256;
            internal string ObservationId => _observationId;
            internal string SupervisorId => _supervisorId;
            internal string OwnerEpoch => _ownerEpoch;
            internal long Revision => _revision;

            internal string Binding => string.Join(
                "/",
                _targetGenerationId,
                _selectedGenerationId,
                string.IsNullOrWhiteSpace(_selectedInstanceId) ? "-" : _selectedInstanceId,
                _observationId,
                _supervisorId,
                _ownerEpoch,
                _revision.ToString(CultureInfo.InvariantCulture));

            internal string DisplayDetail
            {
                get
                {
                    var detail = string.IsNullOrWhiteSpace(_productStatus.Detail)
                        ? "The authenticated Supervisor convergence attempt failed."
                        : _productStatus.Detail;
                    var diagnostic = string.IsNullOrWhiteSpace(_productStatus.DiagnosticDetail)
                        ? string.Empty
                        : " Diagnostic: " + _productStatus.DiagnosticDetail;
                    return detail
                           + diagnostic
                           + " Reason: " + _reasonCode
                           + "; Producer: " + _producer
                           + "; Binding: " + Binding;
                }
            }

            internal bool IsValid
            {
                get
                {
                    return _productStatus.State == AICodedbProductState.NeedsAttention
                           && IsDefined(typeof(AICodedbProductLayerState), _productStatus.Prerequisite)
                           && IsDefined(typeof(AICodedbProductLayerState), _productStatus.Installed)
                           && IsDefined(typeof(AICodedbProductLayerState), _productStatus.Configured)
                           && IsDefined(typeof(AICodedbProductLayerState), _productStatus.McpAvailable)
                           && IsDefined(
                               typeof(AICodedbProductAttentionReason),
                               _productStatus.AttentionReason)
                           && IsBoundedEvidenceToken(_reasonCode)
                           && string.Equals(_producer, ProducerName, StringComparison.Ordinal)
                           && IsBoundedEvidenceText(_packageFingerprint, 256)
                           && IsBoundedEvidenceToken(_targetGenerationId)
                           && IsBoundedEvidenceToken(_selectedGenerationId)
                           && (string.IsNullOrWhiteSpace(_selectedInstanceId)
                               || IsBoundedEvidenceToken(_selectedInstanceId))
                           && IsBoundedEvidenceToken(_runtimeContractSha256)
                           && IsBoundedEvidenceToken(_observationId)
                           && IsBoundedEvidenceToken(_supervisorId)
                           && IsBoundedEvidenceToken(_ownerEpoch)
                           && _revision > 0
                           && IsBoundedEvidenceText(_productStatus.Detail, 2048)
                           && IsBoundedEvidenceText(_productStatus.DiagnosticDetail, 2048);
                }
            }

            internal AICodedbProductStatus ToProductStatus()
            {
                return new AICodedbProductStatus(
                    _productStatus.State,
                    _productStatus.Prerequisite,
                    _productStatus.Installed,
                    _productStatus.Configured,
                    _productStatus.McpAvailable,
                    _productStatus.Detail,
                    default(AICodedbMaterializerCommandStatus),
                    _productStatus.AttentionReason,
                    _productStatus.DiagnosticDetail);
            }

            internal string Serialize()
            {
                return JsonUtility.ToJson(new AICodedbTerminalConvergenceFailureDocument
                {
                    schema_version = SchemaVersion,
                    package_fingerprint = _packageFingerprint,
                    product_state = _productStatus.State.ToString(),
                    prerequisite = _productStatus.Prerequisite.ToString(),
                    installed = _productStatus.Installed.ToString(),
                    configured = _productStatus.Configured.ToString(),
                    mcp_available = _productStatus.McpAvailable.ToString(),
                    attention_reason = _productStatus.AttentionReason.ToString(),
                    reason_code = _reasonCode,
                    producer = _producer,
                    target_generation_id = _targetGenerationId,
                    selected_generation_id = _selectedGenerationId,
                    selected_instance_id = _selectedInstanceId,
                    runtime_contract_sha256 = _runtimeContractSha256,
                    observation_id = _observationId,
                    supervisor_id = _supervisorId,
                    owner_epoch = _ownerEpoch,
                    revision = _revision,
                    detail = _productStatus.Detail,
                    diagnostic_detail = _productStatus.DiagnosticDetail
                });
            }

            internal static bool TryDeserialize(
                string serialized,
                string expectedPackageFingerprint,
                out AICodedbTerminalConvergenceFailure failure)
            {
                failure = null;
                if (string.IsNullOrWhiteSpace(serialized)
                    || string.IsNullOrWhiteSpace(expectedPackageFingerprint))
                    return false;

                try
                {
                    var document = JsonUtility.FromJson<AICodedbTerminalConvergenceFailureDocument>(serialized);
                    if (document == null
                        || document.schema_version != SchemaVersion
                        || !string.Equals(
                            document.package_fingerprint,
                            expectedPackageFingerprint,
                            StringComparison.Ordinal))
                        return false;

                    AICodedbProductState productState;
                    AICodedbProductLayerState prerequisite;
                    AICodedbProductLayerState installed;
                    AICodedbProductLayerState configured;
                    AICodedbProductLayerState mcpAvailable;
                    AICodedbProductAttentionReason attentionReason;
                    if (!TryParseDefinedEnum(document.product_state, out productState)
                        || !TryParseDefinedEnum(document.prerequisite, out prerequisite)
                        || !TryParseDefinedEnum(document.installed, out installed)
                        || !TryParseDefinedEnum(document.configured, out configured)
                        || !TryParseDefinedEnum(document.mcp_available, out mcpAvailable)
                        || !TryParseDefinedEnum(document.attention_reason, out attentionReason))
                        return false;

                    failure = new AICodedbTerminalConvergenceFailure(
                        new AICodedbProductStatus(
                            productState,
                            prerequisite,
                            installed,
                            configured,
                            mcpAvailable,
                            document.detail,
                            default(AICodedbMaterializerCommandStatus),
                            attentionReason,
                            document.diagnostic_detail),
                        document.reason_code,
                        document.producer,
                        document.package_fingerprint,
                        document.target_generation_id,
                        document.selected_generation_id,
                        document.selected_instance_id,
                        document.runtime_contract_sha256,
                        document.observation_id,
                        document.supervisor_id,
                        document.owner_epoch,
                        document.revision);
                    return failure.IsValid;
                }
                catch (Exception)
                {
                    failure = null;
                    return false;
                }
            }

            private static bool TryParseDefinedEnum<T>(string value, out T parsed)
                where T : struct
            {
                parsed = default(T);
                if (string.IsNullOrWhiteSpace(value)
                    || !Enum.TryParse(value, false, out parsed)
                    || !Enum.IsDefined(typeof(T), parsed))
                    return false;
                return string.Equals(parsed.ToString(), value, StringComparison.Ordinal);
            }

            private static bool IsDefined(Type enumType, object value)
            {
                return Enum.IsDefined(enumType, value);
            }

            private static bool IsBoundedEvidenceToken(string value)
            {
                if (string.IsNullOrWhiteSpace(value) || value.Length > 128)
                    return false;
                foreach (var character in value)
                {
                    if ((character >= 'a' && character <= 'z')
                        || (character >= 'A' && character <= 'Z')
                        || (character >= '0' && character <= '9')
                        || character == '.'
                        || character == '_'
                        || character == '-')
                        continue;
                    return false;
                }
                return true;
            }

            private static bool IsBoundedEvidenceText(string value, int maximumLength)
            {
                if (value == null || value.Length > maximumLength)
                    return false;
                foreach (var character in value)
                {
                    if (char.IsControl(character))
                        return false;
                }
                return true;
            }

            [Serializable]
            private sealed class AICodedbTerminalConvergenceFailureDocument
            {
                public int schema_version;
                public string package_fingerprint;
                public string product_state;
                public string prerequisite;
                public string installed;
                public string configured;
                public string mcp_available;
                public string attention_reason;
                public string reason_code;
                public string producer;
                public string target_generation_id;
                public string selected_generation_id;
                public string selected_instance_id;
                public string runtime_contract_sha256;
                public string observation_id;
                public string supervisor_id;
                public string owner_epoch;
                public long revision;
                public string detail;
                public string diagnostic_detail;
            }
        }

        private sealed class LifecycleInitializationData
        {
            internal string ProjectRoot { get; }
            internal string ProjectIdentity { get; }
            internal int EditorPid { get; }
            internal string ProcessStartTicks { get; }

            internal LifecycleInitializationData(
                string projectRoot,
                string projectIdentity,
                int editorPid,
                string processStartTicks)
            {
                ProjectRoot = projectRoot;
                ProjectIdentity = projectIdentity;
                EditorPid = editorPid;
                ProcessStartTicks = processStartTicks;
            }
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
        private readonly object _maintenanceLock = new object();
        private readonly HashSet<CancellationTokenSource> _activeMaintenanceCancellations =
            new HashSet<CancellationTokenSource>();
        private int _maintenanceSuspended;

        internal bool IsMaintenanceSuspended => Volatile.Read(ref _maintenanceSuspended) != 0;

        internal void SetMaintenanceSuspended(bool suspended)
        {
            var wasSuspended = Interlocked.Exchange(ref _maintenanceSuspended, suspended ? 1 : 0);
            if (!suspended)
                return;
            if (wasSuspended != 0)
                return;

            // The Unity boundary owns admission tokens only. Detached runtime
            // processes belong to the authenticated project Supervisor and
            // survive Play, compilation, and Domain Reload.
            CancelMaintenance();
        }

        internal Task<T> QueueMaintenance<T>(Func<Func<bool>, T> work)
        {
            if (work == null)
                throw new ArgumentNullException(nameof(work));

            return QueueMaintenance((canContinue, cancellationToken) => work(canContinue));
        }

        internal Task<T> QueueMaintenance<T>(Func<Func<bool>, CancellationToken, T> work)
        {
            if (work == null)
                throw new ArgumentNullException(nameof(work));

            CancellationTokenSource cancellation;
            lock (_maintenanceLock)
            {
                if (IsMaintenanceSuspended)
                    return Task.FromResult(default(T));

                cancellation = new CancellationTokenSource();
                _activeMaintenanceCancellations.Add(cancellation);
            }

            return Task.Run(() =>
            {
                try
                {
                    if (IsMaintenanceSuspended || cancellation.IsCancellationRequested)
                        return default(T);

                    return work(
                        () => !IsMaintenanceSuspended && !cancellation.IsCancellationRequested,
                        cancellation.Token);
                }
                finally
                {
                    lock (_maintenanceLock)
                        _activeMaintenanceCancellations.Remove(cancellation);
                    cancellation.Dispose();
                }
            });
        }

        internal void CancelMaintenance()
        {
            CancellationTokenSource[] cancellations;
            lock (_maintenanceLock)
                cancellations = new List<CancellationTokenSource>(_activeMaintenanceCancellations).ToArray();

            foreach (var cancellation in cancellations)
            {
                try
                {
                    cancellation.Cancel();
                }
                catch (ObjectDisposedException)
                {
                    // The worker completed concurrently with the boundary.
                }
            }
        }

        internal Task QueueLease(Action work)
        {
            if (work == null)
                throw new ArgumentNullException(nameof(work));
            return Task.Run(work);
        }
    }
}
