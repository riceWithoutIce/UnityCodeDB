using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbManagerWindow : EditorWindow
    {
        private static readonly string[] TabNames =
        {
            "Overview",
            "Setup",
            "Index",
            "MCP",
            "Policy"
        };

        private static readonly string[] CustomProbeLanguageLabels =
        {
            "C#",
            "Shader/HLSL",
            "Lua",
            "JavaScript"
        };

        private static readonly string[] CustomProbeLanguageValues =
        {
            "CSharp",
            "ShaderHlsl",
            "Lua",
            "JavaScript"
        };

        private const float CustomProbeLanguageLabelWidth = 70f;
        private const float CustomProbeLanguageWidth = 130f;
        private const float CustomProbeQueryLabelWidth = 106f;
        private const float CustomProbeQueryMinWidth = 160f;
        private const float InlineControlHeight = 22f;
        private const float McpSnippetHeight = 76f;
        private const float ContentHorizontalPadding = 8f;
        private const float BodyVerticalSpacing = 4f;
        private const float HeaderProfileWidth = 106f;
        private const float HeaderBrandIconWidth = 36f;
        private const float HeaderBrandIconSize = 32f;
        private const float HeaderContentHeight = 40f;
        private const float HeaderControlsMinWidth = 174f;
        private const float HeaderPackageVersionHeight = 16f;
        private const float UserActionStatusHeight = 48f;
        private const float UserActionStatusGap = 4f;
        private const double TransientStatusRefreshSeconds = 5d;
        private const double TransientStatusRetrySeconds = 1.5d;
        private const int MaximumTransientStatusRetries = 3;
        internal const string RemoveIntegrationConfirmationTitle = "Remove CodeDB Integration";
        internal const string RemoveIntegrationConfirmationMessage =
            "Remove the obsolete CodeDB integration from this Unity project?\n\n"
            + "CodeDB will remove only an exact Package-owned control selection, Owner Identity evidence, and generated MCP registration after proving the recorded owner has exited.\n\n"
            + "Existing instances, indexes, leases, user Assets and source, unrelated MCP content, and external processes are preserved. "
            + "After removal reaches Uninstalled, use Install CodeDB to create a fresh integration from the current Package.";
        internal const string McpConfigurationReadyMessage = "Project configuration is ready";
        internal const string McpConfigurationAttentionMessage = "Project configuration needs attention";
        internal const string McpClientUnobservedLabel = "Not observed";
        internal const string UninstallCodeDBConfirmationTitle = "Uninstall CodeDB from Project";
        internal const string UninstallCodeDBConfirmationMessage =
            "Uninstall CodeDB integration from this Unity project?\n\n"
            + "The Unity Package remains installed. CodeDB will first publish the logical UNINSTALLED state, remove only its owned MCP registration keys and current instance selection, "
            + "then retain the prior instance as inert pending cleanup unless exact file ownership permits removal.\n\n"
            + "Provider binaries, indexes, adapters, custom runtime configuration, user policy, business files, unrelated MCP content, and external processes are preserved. "
            + "A live external MCP keeps its exact execution closure until it exits naturally. Unproved index and instance content will not be deleted automatically.";
        internal const string InstallCodeDBConfirmationTitle = "Install CodeDB";
        internal const string InstallCodeDBConfirmationMessage =
            "Install CodeDB integration into this Unity project?\n\n"
            + "CodeDB will create and validate a fresh project-local instance, restore only its owned project MCP registration keys, "
            + "and atomically publish INSTALLED only after the complete status and bounded-query path succeeds. Unrelated project and MCP configuration remains unchanged.";
        private const float CustomProbeSingleRowMinWidth =
            CustomProbeLanguageLabelWidth
            + CustomProbeLanguageWidth
            + CustomProbeQueryLabelWidth
            + CustomProbeQueryMinWidth
            + AICodedbActionGridView.Gap
            + AICodedbActionGridView.ButtonWidth;

        private static AICodedbStatusSnapshot _lastKnownReadySnapshot;
        private static string _lastKnownReadyProjectRoot = string.Empty;
        private static string _lastKnownReadyPackageRoot = string.Empty;
        private static DateTime _lastKnownReadyAtUtc;

        private static string ActivitySidebarWidthPrefsKey =>
            "Rice.AI.Codedb.Manager.ActivitySidebarWidth." + AICodedbProjectSettings.ProjectSlug;

        private Vector2 _scrollPosition;
        private AICodedbStatusSnapshot _statusSnapshot;
        private AICodedbEditorExecutionContext _executionContext;
        private AICodedbManagerStatusBoundary _statusBoundary;
        private string _historicalActionWarning = string.Empty;
        private DateTimeOffset _readyObservationAtUtc;
        private AICodedbCommandResult _lastResult;
        private string _lastResultTitle = string.Empty;
        private bool _postCommandStatusObservationInFlight;
        private string _postCommandStatusObservationDetail = string.Empty;
        private float _activitySidebarWidth = AICodedbManagerLayout.ActivityDefaultWidth;
        private float _activityResizeStartMouseX;
        private float _activityResizeStartWidth;
        private float _mainContentWidth = AICodedbManagerLayout.MainContentMinWidth;
        private AICodedbActivityPanel _activityPanel;
        private AICodedbWatcherStatus _watcherStatus;
        private bool _watcherStatusLoaded;
        private bool _watcherRefreshScheduled;
        private bool _hostStatusRefreshInFlight;
        private AICodedbRetainedEffectsObservation _retainedEffectsObservation;
        private AICodedbManagerActionSession _attachedActionSession;
        private int _hostStatusRefreshGeneration;
        private int _windowStatusGeneration;
        private CancellationTokenSource _windowStatusCancellation;
        private long _cachedLifecycleStatusRevision = -1;
        private bool _watcherStatusRefreshInFlight;
        private bool _userActionInFlight;
        private bool _actionRecoveryInspectionInFlight;
        private double _nextActionRecoveryInspectionAt;
        private double _nextUserActionRepaintAt;
        private AICodedbUserActionStatus _userActionStatus;
        private double _nextHostStatusRefreshAt;
        private bool _transientStatusRefreshPending;
        private int _transientStatusRefreshAttempts;
        private double _nextTransientStatusRefreshAt;
        private int _playModeStatusGeneration;
        private bool _playModeRestoreScheduled;
        private int _selectedTab;
        private bool _showOverviewDetails;
        private bool _showProviderGuidance;
        private bool _showAdvancedHostFiles;
        private bool _showIndexDiagnostics;
        private bool _showIndexMaintenance;
        private bool _showMcpSnippet;
        private bool _showMcpPolicy;
        private bool _showRestrictedCapabilities;
        private bool _showPolicyDetails;
        private int _customProbeLanguageIndex;
        private string _customProbeQuery = string.Empty;

        internal static void Open()
        {
            Open(AICodedbManagerTab.Overview);
        }

        internal static void Open(AICodedbManagerTab tab)
        {
            using (AICodedbLifecycleEvidence.BeginCallback(AICodedbLifecycleCallbackKind.ManagerOpen))
            {
                AICodedbLifecycleEvidence.RecordManagerObservation(AICodedbManagerObservationKind.Open);
                var window = GetWindow<AICodedbManagerWindow>(false, "CodeDB Manager");
                window.ApplyWindowTitle();
                window.minSize = new Vector2(900f, 460f);
                window._selectedTab = (int)tab;
                window.Show();
                window.BeginStatusRefresh();
                window.Repaint();
            }
        }

        private void OnEnable()
        {
            using (AICodedbLifecycleEvidence.BeginCallback(AICodedbLifecycleCallbackKind.ManagerEnable))
            {
                ResetWindowStatusLifetime();
                _statusBoundary = null;
                AICodedbLifecycleEvidence.RecordManagerObservation(AICodedbManagerObservationKind.Enable);
                _executionContext = AICodedbPaths.CaptureExecutionContext();
                ApplyWindowTitle();
                _activitySidebarWidth = EditorPrefs.GetFloat(
                    ActivitySidebarWidthPrefsKey,
                    AICodedbManagerLayout.ActivityDefaultWidth);
                _activityPanel = new AICodedbActivityPanel();
                _userActionStatus = new AICodedbUserActionStatus();
                AttachCurrentActionSession();
                RestoreDurableActionAsync();
                _watcherStatus = AICodedbWatcherStatusBuilder.Build(null);
                _watcherStatusLoaded = false;
                EditorApplication.update -= ObserveTransientHostStatus;
                EditorApplication.update += ObserveTransientHostStatus;
                EditorApplication.playModeStateChanged -= OnManagerPlayModeStateChanged;
                EditorApplication.playModeStateChanged += OnManagerPlayModeStateChanged;
                RefreshStatus();
                if (IsPlayModeDisplaySuspended())
                    SchedulePlayModeRestore();
                _nextHostStatusRefreshAt = EditorApplication.timeSinceStartup + 1d;
                BeginStatusRefresh();
            }
        }

        private void OnDisable()
        {
            AICodedbLifecycleEvidence.RecordManagerClosed();
            CancelWindowStatusLifetime();
            EditorApplication.update -= ObserveTransientHostStatus;
            EditorApplication.playModeStateChanged -= OnManagerPlayModeStateChanged;
            if (_watcherRefreshScheduled)
                EditorApplication.delayCall -= RefreshWatcherStatusDelayed;
            _watcherRefreshScheduled = false;
            if (_playModeRestoreScheduled)
                EditorApplication.delayCall -= RestorePlayModeAfterReload;
            _playModeRestoreScheduled = false;
        }

        private void ResetWindowStatusLifetime()
        {
            CancelWindowStatusLifetime();
            _windowStatusCancellation = new CancellationTokenSource();
            _cachedLifecycleStatusRevision = -1;
        }

        private void CancelWindowStatusLifetime()
        {
            unchecked
            {
                _windowStatusGeneration++;
            }
            var cancellation = _windowStatusCancellation;
            _windowStatusCancellation = null;
            if (cancellation != null)
            {
                cancellation.Cancel();
                // The captured token can still be consumed by Bridge and
                // snapshot workers after OnDisable returns. Let the detached
                // source be collected with those workers instead of disposing
                // their cancellation registration boundary prematurely.
            }
            _hostStatusRefreshInFlight = false;
            _hostStatusRefreshGeneration = _windowStatusGeneration;
        }

        private bool TryCaptureWindowStatusLifetime(
            out int generation,
            out CancellationToken cancellationToken)
        {
            generation = _windowStatusGeneration;
            var cancellation = _windowStatusCancellation;
            if (cancellation == null || cancellation.IsCancellationRequested)
            {
                cancellationToken = new CancellationToken(true);
                return false;
            }

            cancellationToken = cancellation.Token;
            return true;
        }

        private void OnGUI()
        {
            using (AICodedbLifecycleEvidence.BeginCallback(AICodedbLifecycleCallbackKind.ManagerGui))
            {
                AICodedbLifecycleEvidence.RecordManagerObservation(AICodedbManagerObservationKind.Repaint);
                // Domain Reload can recreate the IMGUI window before the
                // play-mode callback has published its SessionState handoff. The
                // restore is display-only and makes every repaint self-healing.
                if (IsPlayModeDisplaySuspended())
                    RestoreReadySnapshotForPlayMode();
                if (_statusSnapshot == null)
                    RefreshStatus();

                DrawHeader();
                DrawBodyLayout();
            }
        }

        private void DrawBodyLayout()
        {
            var historicalWarning = GetHistoricalActionWarning();
            var historicalWarningHeight = string.IsNullOrEmpty(historicalWarning) ? 0f
                : EditorStyles.helpBox.CalcHeight(new GUIContent(historicalWarning),
                    Mathf.Max(1f, position.width - BodyVerticalSpacing)) + UserActionStatusGap;
            if (!string.IsNullOrEmpty(historicalWarning))
                EditorGUILayout.HelpBox(historicalWarning, MessageType.Warning);
            var userActionPresentation = GetUserActionPresentation();
            if (userActionPresentation.IsVisible)
            {
                DrawUserActionStatus(userActionPresentation);
                EditorGUILayout.Space(UserActionStatusGap);
            }

            var panelHorizontalMargin = Mathf.Max(0f, EditorStyles.helpBox.margin.horizontal);
            var bodyHeight = Mathf.Max(
                0f,
                position.height
                - AICodedbManagerStyles.HeaderHeight
                - BodyVerticalSpacing
                - historicalWarningHeight
                - (userActionPresentation.IsVisible
                    ? UserActionStatusHeight + UserActionStatusGap
                    : 0f));
            var layout = AICodedbManagerLayout.Resolve(
                position.width,
                bodyHeight,
                _activitySidebarWidth,
                panelHorizontalMargin);
            if (layout.IsWide)
            {
                _activitySidebarWidth = layout.ActivityWidth;
                using (new EditorGUILayout.HorizontalScope(GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true)))
                {
                    DrawMainContentArea(layout.MainContentWidth);
                    DrawActivityResizeHandle(layout.AvailableWidth);
                    DrawActivityPanel(layout);
                }
                return;
            }

            using (new EditorGUILayout.VerticalScope(GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true)))
            {
                DrawMainContentArea(layout.MainContentWidth);
                EditorGUILayout.Space(AICodedbActionGridView.Gap);
                DrawActivityPanel(layout);
            }
        }

        private void RefreshStatus()
        {
            if (_statusSnapshot != null)
            {
                if (IsPlayModeDisplaySuspended()
                    && _statusSnapshot.ProductStatus.State != AICodedbProductState.Ready)
                {
                    RestoreReadySnapshotForPlayMode();
                }
                return;
            }

            _statusSnapshot = IsPlayModeDisplaySuspended()
                ? TryGetStatusSnapshotForPlayMode()
                : TryGetCachedReadySnapshot(_executionContext);
            if (_statusSnapshot == null && !IsPlayModeDisplaySuspended())
            {
                AICodedbProductState persistedState;
                AICodedbEditorLifecycle.AICodedbTerminalConvergenceFailure persistedTerminalFailure;
                if (AICodedbEditorLifecycle.TryGetPersistedProductState(
                        _executionContext.ProjectRoot,
                        out persistedState,
                        out persistedTerminalFailure))
                {
                    _statusSnapshot = AICodedbStatusSnapshot.CreateCachedState(
                        _executionContext.ProjectDisplayName,
                        persistedState == AICodedbProductState.Ready
                            ? AICodedbProductState.Starting : persistedState,
                        AICodedbEditorLifecycle.IsReconcileInFlight,
                        GetCachedCoordinatorFailureCategory(),
                        persistedTerminalFailure);
                }
            }
            if (_statusSnapshot == null)
            {
                _statusSnapshot = AICodedbEditorLifecycle.IsReconcileInFlight
                    ? AICodedbStatusSnapshot.CreateStarting(
                        _executionContext.ProjectDisplayName,
                        GetCachedCoordinatorFailureCategory())
                    : AICodedbStatusSnapshot.CreateCachedState(
                        _executionContext.ProjectDisplayName,
                        AICodedbProductState.Starting,
                        false,
                        GetCachedCoordinatorFailureCategory());
            }
            // A cached Ready snapshot is still a verified observation. Record
            // it before Play can trigger a domain reload, even when the
            // lifecycle worker's most recent result is still Starting.
            // Restoring a display cache is not a fresh observation; do not renew
            // its Ready timestamp or turn old history into current evidence.
            if (_statusSnapshot.ProductStatus.State == AICodedbProductState.Ready)
                _readyObservationAtUtc = new DateTimeOffset(DateTime.SpecifyKind(_lastKnownReadyAtUtc, DateTimeKind.Utc));
            ApplyDisclosurePolicy(true);
        }

        private void ObserveTransientHostStatus()
        {
            AttachCurrentActionSession();
            var recoveringAction = AICodedbManagerActionSession.CurrentFor(_executionContext);
            if (recoveringAction != null && recoveringAction.IsRecovering
                && !recoveringAction.IsEvidenceConflict
                && !_actionRecoveryInspectionInFlight
                && EditorApplication.timeSinceStartup >= _nextActionRecoveryInspectionAt
                && !EditorApplication.isCompiling && !EditorApplication.isUpdating)
            {
                _nextActionRecoveryInspectionAt = EditorApplication.timeSinceStartup + 2d;
                InspectActionRecoveryAsync(recoveringAction);
            }
            if (_userActionInFlight
                && _userActionStatus != null
                && _userActionStatus.Phase == AICodedbUserActionPhase.Running)
            {
                if (EditorApplication.timeSinceStartup >= _nextUserActionRepaintAt)
                {
                    _nextUserActionRepaintAt = EditorApplication.timeSinceStartup + 0.25d;
                    Repaint();
                }
                return;
            }

            // Lifecycle owns the background materializer pass. Consume its
            // cached result when it changes instead of launching a new status
            // process whenever the Manager is opened or repainted.
            if (TryApplyCachedLifecycleStatus())
                return;

            if (_transientStatusRefreshPending
                && EditorApplication.timeSinceStartup >= _nextTransientStatusRefreshAt
                && !EditorApplication.isCompiling
                && !EditorApplication.isUpdating
                && !IsPlayModeDisplaySuspended())
            {
                // Play-mode resume is owned by the lifecycle worker. Manager
                // update ticks remain cache-only and retry the in-memory read
                // after a bounded delay instead of requesting backend work.
                _nextTransientStatusRefreshAt =
                    EditorApplication.timeSinceStartup + TransientStatusRetrySeconds;
                return;
            }

            if (_statusSnapshot == null || _hostStatusRefreshInFlight)
                return;
            if (_statusSnapshot.IsProjectUninstalled)
                return;
            if (_statusSnapshot.IsProjectNotIntegrated)
                return;
            if (EditorApplication.isCompiling
                || EditorApplication.isUpdating
                || IsPlayModeDisplaySuspended())
                return;

            var suppressed = AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                _statusSnapshot.HostUpgradeStatus,
                _statusSnapshot.RuntimeContractTargetGenerationId);
            if (_statusSnapshot.ProductStatus.State == AICodedbProductState.Ready
                && !ShouldAutoObserveHostStatus(
                    _statusSnapshot.HostPayloadStatus.State,
                    _statusSnapshot.HostUpgradeStatus.Phase,
                    _statusSnapshot.HostUpdatePolicyValue.IsEnabled,
                    suppressed))
            {
                return;
            }
            if (EditorApplication.timeSinceStartup < _nextHostStatusRefreshAt)
                return;

            _nextHostStatusRefreshAt = EditorApplication.timeSinceStartup + TransientStatusRefreshSeconds;
        }

        private void AttachCurrentActionSession()
        {
            var session = AICodedbManagerActionSession.CurrentFor(_executionContext);
            if (session == null)
            {
                if (_attachedActionSession != null && !_attachedActionSession.IsRunning
                    && string.Equals(_attachedActionSession.Context.ProjectRoot,
                        _executionContext.ProjectRoot, StringComparison.OrdinalIgnoreCase))
                {
                    // The durable aggregate cleared this Window's historical
                    // session. Clear only its stale projection; preserve results
                    // and any foreign/running static owner.
                    _userActionInFlight = false;
                    _userActionStatus = new AICodedbUserActionStatus();
                    _attachedActionSession = null;
                }
                return;
            }

            _attachedActionSession = session;
            _userActionStatus = session.Status;
            _userActionInFlight = session.IsRunning || session.IsRecovering;
            var displayedResult = AICodedbManagerActionSession.SelectDisplayResult(session.Result, session.InitialCommandResult);
            if (!session.IsRunning && !ReferenceEquals(_lastResult, displayedResult))
            {
                _lastResult = displayedResult;
                _lastResultTitle = session.Title;
                GetActivityPanel().ResetForNewResult(_lastResult, _lastResultTitle);
            }
        }

        private async void RestoreDurableActionAsync()
        {
            var context = _executionContext;
            var generation = _windowStatusGeneration;
            var restored = await Task.Run(() =>
            {
                var observation = AICodedbRetainedEffectsObservation.Parse(
                    AICodedbHostPayloadMaterializer.ReadStatus(context), context);
                var read = AICodedbManagerActionJournal.Read(context, observation);
                AICodedbManagerStatusBoundary boundary = null;
                try { boundary = AICodedbManagerStatusBoundary.Capture(context); }
                catch (Exception) { /* Incomplete Package evidence cannot authorize Ready. */ }
                return Tuple.Create(read, boundary);
            });
            if (this == null || generation != _windowStatusGeneration
                || !IsSameStatusContext(_executionContext, context))
                return;
            var read = restored.Item1;
            _statusBoundary = restored.Item2;
            _historicalActionWarning = read.HistoricalWarning;
            _retainedEffectsObservation = read.State == AICodedbManagerActionIndexState.Empty
                ? read.EffectsObservation : null;
            AICodedbManagerActionSession.RestoreDurable(context, read,
                EditorApplication.timeSinceStartup);
            AttachCurrentActionSession();
            TryApplyCachedLifecycleStatus();
            Repaint();
        }

        private async Task RefreshRetainedEffectsAsync(AICodedbEditorExecutionContext context,
            int generation, CancellationToken cancellationToken)
        {
            _retainedEffectsObservation = null;
            var read = await Task.Run(() =>
            {
                var observation = AICodedbRetainedEffectsObservation.Parse(
                    AICodedbHostPayloadMaterializer.ReadStatus(context, cancellationToken), context);
                return AICodedbManagerActionJournal.Read(context, observation);
            }, cancellationToken);
            if (this == null || cancellationToken.IsCancellationRequested
                || generation != _windowStatusGeneration
                || !IsSameStatusContext(_executionContext, context)) return;
            _historicalActionWarning = read.HistoricalWarning;
            _retainedEffectsObservation = read.State == AICodedbManagerActionIndexState.Empty
                ? read.EffectsObservation : null;
            AICodedbManagerActionSession.RestoreDurable(context, read, EditorApplication.timeSinceStartup);
            AttachCurrentActionSession();
        }

        private string GetHistoricalActionWarning()
        {
            return BuildHistoricalActionWarning(
                AICodedbManagerActionSession.CurrentFor(_executionContext), _historicalActionWarning);
        }

        internal static string BuildHistoricalActionWarning(
            AICodedbManagerActionSession session, string retainedWarning)
        {
            var warning = retainedWarning ?? string.Empty;
            if (session == null || !session.IsRecovering)
                return warning;
            var commandOutcome = session.Result != null && session.Result.HasAuthoritativeTerminalEvidence
                ? "has a recorded command outcome, but retained admission/project effects remain uncertain."
                : "has an unknown command outcome.";
            return "Previous action " + session.ActionId + " (" + session.Title
                + ", original Package " + (session.HasOriginalContext ? session.Context.PackageRoot : "unavailable")
                + ") " + commandOutcome + " Current product status is independent."
                + " New project changes remain blocked until execution safety is proved."
                + (string.IsNullOrEmpty(session.DurableIndexReleaseDetail) ? string.Empty
                    : "\nAction index: " + session.DurableIndexReleaseDetail)
                + (string.IsNullOrEmpty(warning) ? string.Empty : "\n" + warning);
        }

        private async void InspectActionRecoveryAsync(AICodedbManagerActionSession session)
        {
            _actionRecoveryInspectionInFlight = true;
            try
            {
                var direct = await Task.Run(() =>
                    AICodedbProcessRunner.RecoverManagerAction(session.Context, session.ActionId, session.StorageLayout));
                var outcome = direct.State == AICodedbManagerActionRecoveryState.NotFound
                    ? await AICodedbEditorLifecycle.RecoverManagerActionAsync(
                        session.Context, session.ActionId)
                    : direct;
                if (this == null || !ReferenceEquals(
                        AICodedbManagerActionSession.CurrentFor(_executionContext), session))
                    return;
                if ((outcome.State == AICodedbManagerActionRecoveryState.Terminal
                     || outcome.State == AICodedbManagerActionRecoveryState.PreEffectRefusal)
                    && outcome.Result != null
                    && string.Equals(outcome.Result.ActionId, session.ActionId, StringComparison.Ordinal)
                    && await Task.Run(() =>
                    {
                        return session.TryReleaseDurableIndex(outcome.Result, out var _);
                    })
                    && session.TryCompleteRecovery(outcome.Result,
                        EditorApplication.timeSinceStartup))
                {
                    AttachCurrentActionSession();
                    BeginStatusRefresh(true);
                }
                else
                {
                    session.SetRecoveryDetail(outcome.State == AICodedbManagerActionRecoveryState.Terminal
                                              || outcome.State == AICodedbManagerActionRecoveryState.PreEffectRefusal
                        ? "Authenticated command evidence exists, but the project action index could not be released. "
                            + session.DurableIndexReleaseDetail
                        : outcome.Detail);
                }
                Repaint();
            }
            catch (Exception exception)
            {
                session.SetRecoveryDetail("The previous action's command evidence is unavailable: "
                    + exception.Message);
            }
            finally
            {
                _actionRecoveryInspectionInFlight = false;
            }
        }

        private void ApplyStatusSnapshot(AICodedbStatusSnapshot snapshot)
        {
            ApplyStatusSnapshot(snapshot, true, _statusSnapshot == null);
        }

        private void ApplyStatusSnapshot(
            AICodedbStatusSnapshot snapshot,
            bool invalidateReadyCache,
            bool initializeDisclosures,
            DateTimeOffset? readyObservedAt = null)
        {
            if (snapshot == null)
                return;
            _statusSnapshot = snapshot;
            _readyObservationAtUtc = snapshot.ProductStatus.State == AICodedbProductState.Ready
                ? readyObservedAt ?? DateTimeOffset.UtcNow : default(DateTimeOffset);
            CacheReadySnapshot(_executionContext, snapshot, _readyObservationAtUtc.UtcDateTime);
            if (invalidateReadyCache && snapshot.ProductStatus.State != AICodedbProductState.Ready)
                InvalidateReadySnapshot(_executionContext.ProjectRoot);
            if (_userActionStatus != null)
                _userActionStatus.UpdateProductState(snapshot.ProductStatus.State);
            ApplyDisclosurePolicy(initializeDisclosures);
        }

        private async Task<bool> RefreshStatusAsync(AICodedbCommandResult hostPayloadResult)
        {
            if (!TryCaptureWindowStatusLifetime(
                    out var windowStatusGeneration,
                    out var cancellationToken))
            {
                return false;
            }

            AICodedbLifecycleEvidence.RecordManagerStatusRefreshStarted();
            var disposition = AICodedbManagerStatusRefreshDisposition.Failed;
            var playModeStatusGeneration = _playModeStatusGeneration;
            var context = _executionContext;
            using (var observationLifetime = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
            try
            {
                var observation = AICodedbStatusSnapshot.RefreshAsync(
                    context,
                    hostPayloadResult,
                    observationLifetime.Token);
                if (await Task.WhenAny(observation, Task.Delay(5000, cancellationToken)) != observation)
                {
                    observationLifetime.Cancel();
                    // This bounds observation, not backend execution or effects.
                    // A late worker cannot reach ApplyStatusSnapshot in this pass.
                    var ignored = observation.ContinueWith(completed => { var fault = completed.Exception; },
                        TaskContinuationOptions.OnlyOnFaulted);
                    disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
                    return false;
                }
                var snapshot = await observation;
                if (this == null
                    || windowStatusGeneration != _windowStatusGeneration
                    || !IsSameStatusContext(_executionContext, context)
                    || cancellationToken.IsCancellationRequested)
                {
                    disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
                    return false;
                }
                if (!ShouldApplyStatusRefreshResult(
                        windowStatusGeneration,
                        _windowStatusGeneration,
                        cancellationToken.IsCancellationRequested,
                        playModeStatusGeneration,
                        _playModeStatusGeneration,
                        IsPlayModeDisplaySuspended()))
                {
                    if (IsPlayModeDisplaySuspended())
                        RestoreReadySnapshotForPlayMode();
                    else
                    {
                        _transientStatusRefreshPending = true;
                        _nextTransientStatusRefreshAt = EditorApplication.timeSinceStartup;
                    }
                    disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
                    return false;
                }

                ApplyStatusSnapshot(snapshot, true, false);
                await RefreshRetainedEffectsAsync(context, windowStatusGeneration, cancellationToken);
                disposition = AICodedbManagerStatusRefreshDisposition.Completed;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
            }
            finally
            {
                if (windowStatusGeneration != _windowStatusGeneration
                    || cancellationToken.IsCancellationRequested)
                {
                    disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
                }
                AICodedbLifecycleEvidence.RecordManagerStatusRefreshFinished(disposition);
            }
            return disposition == AICodedbManagerStatusRefreshDisposition.Completed;
        }

        private void BeginStatusRefresh(bool force = false)
        {
            if (IsPlayModeDisplaySuspended())
            {
                RestoreReadySnapshotForPlayMode();
                return;
            }
            if (_hostStatusRefreshInFlight
                || EditorApplication.isCompiling
                || EditorApplication.isUpdating
                || IsPlayModeDisplaySuspended())
            {
                return;
            }
            if (!force
                && _statusSnapshot != null
                && (_statusSnapshot.ProductStatus.State == AICodedbProductState.Ready
                    || _statusSnapshot.ProductStatus.State == AICodedbProductState.MissingPrerequisite
                    || _statusSnapshot.ProductStatus.State == AICodedbProductState.Uninstalled))
            {
                return;
            }

            if (!force)
            {
                TryApplyCachedLifecycleStatus();
                return;
            }

            // Manager remains cache-only. Once lifecycle initialization has
            // completed, an explicit refresh raises one observation intent;
            // before that boundary the initial lifecycle pass will publish the
            // first cache revision without a Manager-owned fallback process.
            _transientStatusRefreshPending = true;
            _nextTransientStatusRefreshAt = EditorApplication.timeSinceStartup;
            AICodedbLifecycleEvidence.RecordManagerStatusRequest(true);
            if (AICodedbEditorLifecycle.IsLifecycleInitialized)
                AICodedbEditorLifecycle.RequestBackgroundStatusObservation(true);
            TryApplyCachedLifecycleStatus();
        }

        private bool TryApplyCachedLifecycleStatus()
        {
            AICodedbLifecycleEvidence.RecordManagerObservation(AICodedbManagerObservationKind.CacheRead);
            if (_hostStatusRefreshInFlight
                || IsPlayModeDisplaySuspended()
                || string.IsNullOrWhiteSpace(_executionContext.ProjectRoot))
                return false;

            if (_statusSnapshot != null && ShouldExpireDisplayedReady(
                    _statusSnapshot.ProductStatus.State, _readyObservationAtUtc, DateTimeOffset.UtcNow))
                ApplyStatusSnapshot(AICodedbStatusSnapshot.CreateStarting(_executionContext.ProjectDisplayName));

            AICodedbCommandResult cachedResult;
            AICodedbProductStatus cachedProductStatus;
            bool hasProductStatus;
            AICodedbSupervisorSnapshot cachedSupervisorSnapshot;
            AICodedbEditorLifecycle.AICodedbTerminalConvergenceFailure cachedTerminalFailure;
            long revision;
            if (!AICodedbEditorLifecycle.TryGetCachedLifecycleStatus(
                    out cachedResult,
                    out cachedProductStatus,
                    out hasProductStatus,
                    out cachedSupervisorSnapshot,
                    out cachedTerminalFailure,
                    out revision)
                || revision <= _cachedLifecycleStatusRevision)
                return false;

            // Lifecycle/Bridge owns product classification and authentication.
            // This additional display boundary cannot promote an incomplete,
            // stale or foreign observation to Ready, regardless of old history.
            if ((_statusBoundary == null && cachedProductStatus.State == AICodedbProductState.Ready)
                || (_statusBoundary != null
                    && !_statusBoundary.CanDisplay(_executionContext, cachedProductStatus.State,
                        hasProductStatus, cachedSupervisorSnapshot, DateTimeOffset.UtcNow)))
            {
                ApplyStatusSnapshot(AICodedbStatusSnapshot.CreateStarting(_executionContext.ProjectDisplayName));
                return false;
            }

            _cachedLifecycleStatusRevision = revision;
            if (hasProductStatus || cachedTerminalFailure != null)
            {
                ApplyStatusSnapshot(
                    AICodedbStatusSnapshot.CreateCachedStatus(
                        _executionContext.ProjectDisplayName,
                        cachedProductStatus,
                        AICodedbEditorLifecycle.IsReconcileInFlight,
                        GetCoordinatorFailureCategory(cachedSupervisorSnapshot),
                        cachedTerminalFailure),
                    true,
                    false,
                    cachedSupervisorSnapshot?.ObservedAtUtc);
                Repaint();
                return true;
            }
            if (cachedResult == null)
                return false;
            ApplyCachedLifecycleStatusAsync(cachedResult, cachedSupervisorSnapshot);
            return true;
        }

        private async void ApplyCachedLifecycleStatusAsync(
            AICodedbCommandResult cachedResult,
            AICodedbSupervisorSnapshot cachedSupervisorSnapshot)
        {
            if (_hostStatusRefreshInFlight
                || cachedResult == null
                || !TryCaptureWindowStatusLifetime(
                    out var windowStatusGeneration,
                    out var cancellationToken))
                return;

            _hostStatusRefreshInFlight = true;
            _hostStatusRefreshGeneration = windowStatusGeneration;
            AICodedbLifecycleEvidence.RecordManagerStatusRefreshStarted();
            var disposition = AICodedbManagerStatusRefreshDisposition.Failed;
            var playModeStatusGeneration = _playModeStatusGeneration;
            var context = _executionContext;
            try
            {
                var snapshot = await AICodedbStatusSnapshot.RefreshAsync(
                    context,
                    cachedResult,
                    cancellationToken,
                    GetCoordinatorFailureCategory(cachedSupervisorSnapshot));
                if (this == null
                    || !IsSameStatusContext(_executionContext, context)
                    || !ShouldApplyStatusRefreshResult(
                        windowStatusGeneration,
                        _windowStatusGeneration,
                        cancellationToken.IsCancellationRequested,
                        playModeStatusGeneration,
                        _playModeStatusGeneration,
                        IsPlayModeDisplaySuspended()))
                {
                    disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
                    return;
                }

                ApplyStatusSnapshot(snapshot, true, false);
                await RefreshRetainedEffectsAsync(context, windowStatusGeneration, cancellationToken);
                _transientStatusRefreshPending = false;
                _transientStatusRefreshAttempts = 0;
                Repaint();
                disposition = AICodedbManagerStatusRefreshDisposition.Completed;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
            }
            catch (Exception exception)
            {
                if (this != null)
                    Debug.LogWarning("CodeDB Manager cached status refresh failed: " + exception.Message);
            }
            finally
            {
                if (windowStatusGeneration != _windowStatusGeneration
                    || cancellationToken.IsCancellationRequested)
                {
                    disposition = AICodedbManagerStatusRefreshDisposition.Cancelled;
                }
                AICodedbLifecycleEvidence.RecordManagerStatusRefreshFinished(disposition);
                if (_hostStatusRefreshGeneration == windowStatusGeneration)
                    _hostStatusRefreshInFlight = false;
            }
        }

        private void OnManagerPlayModeStateChanged(PlayModeStateChange state)
        {
            _playModeStatusGeneration++;
            if (state == PlayModeStateChange.ExitingEditMode && _statusSnapshot != null)
            {
                AICodedbEditorLifecycle.RecordProductStateForPlayMode(
                    _executionContext.ProjectRoot,
                    _statusSnapshot.ProductStatus.State);
            }
            if (state != PlayModeStateChange.EnteredEditMode)
            {
                RestoreReadySnapshotForPlayMode();
                if (state == PlayModeStateChange.EnteredPlayMode)
                    SchedulePlayModeRestore();
                Repaint();
                return;
            }

            if (state == PlayModeStateChange.EnteredEditMode)
            {
                // Clear the temporary Play handoff even when the lifecycle
                // initializer has not yet rebuilt its static project identity.
                AICodedbEditorLifecycle.ClearProductStateForPlayMode(
                    _executionContext.ProjectRoot);
                _transientStatusRefreshAttempts = 0;
                _transientStatusRefreshPending = true;
                _nextTransientStatusRefreshAt = EditorApplication.timeSinceStartup + TransientStatusRetrySeconds;
                Repaint();
            }
        }

        private AICodedbStatusSnapshot TryGetStatusSnapshotForPlayMode()
        {
            AICodedbProductState state;
            if (!AICodedbEditorLifecycle.TryGetProductStateForPlayMode(
                    _executionContext.ProjectRoot,
                    out state))
                return null;

            switch (state)
            {
                case AICodedbProductState.Ready:
                    return TryGetCachedReadySnapshot(_executionContext)
                           ?? AICodedbStatusSnapshot.CreateCachedReady(
                               _executionContext.ProjectDisplayName,
                               GetCachedCoordinatorFailureCategory(), true);
                case AICodedbProductState.MissingPrerequisite:
                    return AICodedbStatusSnapshot.CreateCachedMissingPrerequisite(
                        _executionContext.ProjectDisplayName,
                        GetCachedCoordinatorFailureCategory(), true);
                default:
                    return null;
            }
        }

        private bool RestoreReadySnapshotForPlayMode()
        {
            if (_statusSnapshot != null
                && (_statusSnapshot.ProductStatus.State == AICodedbProductState.Ready
                    || _statusSnapshot.ProductStatus.State == AICodedbProductState.MissingPrerequisite))
            {
                return true;
            }

            if (!IsPlayModeDisplaySuspended())
            {
                return false;
            }

            AICodedbProductState capturedState;
            var hasCapturedState = AICodedbEditorLifecycle.TryGetProductStateForPlayMode(
                _executionContext.ProjectRoot,
                out capturedState);
            if (hasCapturedState
                && (capturedState == AICodedbProductState.NeedsAttention
                    || capturedState == AICodedbProductState.Uninstalled))
            {
                return false;
            }

            // Keep an in-domain verified snapshot usable even if the lifecycle
            // callback has not published its SessionState handoff yet.
            var snapshot = hasCapturedState
                ? TryGetStatusSnapshotForPlayMode()
                : null;
            snapshot = snapshot ?? TryGetCachedReadySnapshot(_executionContext);
            if (snapshot == null)
                return false;

            if (snapshot.ProductStatus.State != AICodedbProductState.Ready
                && snapshot.ProductStatus.State != AICodedbProductState.MissingPrerequisite)
                return false;

            _statusSnapshot = snapshot;
            // A Play handoff is display-only, not a renewed live observation.
            if (_userActionStatus != null)
                _userActionStatus.UpdateProductState(snapshot.ProductStatus.State);
            ApplyDisclosurePolicy(false);
            return true;
        }

        internal static bool ShouldRestoreReadyForPlayMode(
            bool isPlayingOrWillChangePlaymode,
            AICodedbProductState currentState,
            bool canUsePersistedReadyState)
        {
            return isPlayingOrWillChangePlaymode
                   && currentState != AICodedbProductState.Ready
                   && canUsePersistedReadyState;
        }

        internal static bool IsPlayModeDisplaySuspended(
            bool editorPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return editorPlayingOrWillChangePlaymode || applicationPlaying;
        }

        private static bool IsPlayModeDisplaySuspended()
        {
            return IsPlayModeDisplaySuspended(
                EditorApplication.isPlayingOrWillChangePlaymode,
                Application.isPlaying);
        }

        private void SchedulePlayModeRestore()
        {
            if (_playModeRestoreScheduled)
                return;
            _playModeRestoreScheduled = true;
            EditorApplication.delayCall += RestorePlayModeAfterReload;
        }

        private void RestorePlayModeAfterReload()
        {
            _playModeRestoreScheduled = false;
            if (this == null || !IsPlayModeDisplaySuspended())
                return;
            if (RestoreReadySnapshotForPlayMode())
            {
                _playModeStatusGeneration++;
                Repaint();
            }
        }

        internal static bool ShouldApplyStatusRefreshResult(
            int requestGeneration,
            int currentGeneration,
            bool isPlayingOrWillChangePlaymode)
        {
            return requestGeneration == currentGeneration
                   && !isPlayingOrWillChangePlaymode;
        }

        internal static bool ShouldApplyStatusRefreshResult(
            int requestWindowGeneration,
            int currentWindowGeneration,
            bool cancellationRequested,
            int requestPlayModeGeneration,
            int currentPlayModeGeneration,
            bool isPlayingOrWillChangePlaymode)
        {
            return requestWindowGeneration == currentWindowGeneration
                   && !cancellationRequested
                   && ShouldApplyStatusRefreshResult(
                       requestPlayModeGeneration,
                       currentPlayModeGeneration,
                       isPlayingOrWillChangePlaymode);
        }

        private static AICodedbStatusSnapshot TryGetCachedReadySnapshot(AICodedbEditorExecutionContext context)
        {
            if (_lastKnownReadySnapshot == null
                || _lastKnownReadySnapshot.ProductStatus.State != AICodedbProductState.Ready
                || !CanUseCachedReadyObservation(context.ProjectRoot, context.PackageRoot,
                    _lastKnownReadyProjectRoot, _lastKnownReadyPackageRoot,
                    _lastKnownReadyAtUtc, DateTime.UtcNow))
            {
                return null;
            }

            return _lastKnownReadySnapshot;
        }

        private static void CacheReadySnapshot(AICodedbEditorExecutionContext context,
            AICodedbStatusSnapshot snapshot, DateTime observedAt)
        {
            if (snapshot == null || snapshot.ProductStatus.State != AICodedbProductState.Ready)
                return;

            _lastKnownReadySnapshot = snapshot;
            _lastKnownReadyProjectRoot = context.ProjectRoot;
            _lastKnownReadyPackageRoot = context.PackageRoot;
            _lastKnownReadyAtUtc = observedAt;
            AICodedbEditorLifecycle.RecordVerifiedReadyForCurrentPackage(context.ProjectRoot);
        }

        internal static bool IsSameStatusContext(
            AICodedbEditorExecutionContext expected, AICodedbEditorExecutionContext observed)
        {
            return !string.IsNullOrWhiteSpace(expected.ProjectRoot)
                && !string.IsNullOrWhiteSpace(expected.PackageRoot)
                && string.Equals(expected.ProjectRoot, observed.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                && string.Equals(expected.PackageRoot, observed.PackageRoot, StringComparison.OrdinalIgnoreCase);
        }

        internal static bool CanUseCachedReadyObservation(string projectRoot, string packageRoot,
            string observedProjectRoot, string observedPackageRoot, DateTime observedAt, DateTime now)
        {
            return !string.IsNullOrWhiteSpace(projectRoot) && !string.IsNullOrWhiteSpace(packageRoot)
                && string.Equals(projectRoot, observedProjectRoot, StringComparison.OrdinalIgnoreCase)
                && string.Equals(packageRoot, observedPackageRoot, StringComparison.OrdinalIgnoreCase)
                && AICodedbManagerStatusBoundary.IsReadyObservationFresh(observedAt, now);
        }

        internal static bool ShouldExpireDisplayedReady(AICodedbProductState state,
            DateTimeOffset observedAt, DateTimeOffset now)
        {
            return state == AICodedbProductState.Ready
                && !AICodedbManagerStatusBoundary.IsReadyObservationFresh(observedAt, now);
        }

        private static AICodedbCoordinatorFailureCategory GetCachedCoordinatorFailureCategory()
        {
            return GetCoordinatorFailureCategory(
                AICodedbEditorLifecycle.GetCachedLifecycleSupervisorSnapshot());
        }

        private static AICodedbCoordinatorFailureCategory GetCoordinatorFailureCategory(
            AICodedbSupervisorSnapshot supervisorSnapshot)
        {
            return supervisorSnapshot == null
                ? AICodedbCoordinatorFailureCategory.NotEvaluated
                : supervisorSnapshot.CoordinatorFailureCategory;
        }

        private static void InvalidateReadySnapshot(string projectRoot)
        {
            if (string.IsNullOrWhiteSpace(projectRoot)
                || string.Equals(
                    AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\'),
                    _lastKnownReadyProjectRoot,
                    StringComparison.OrdinalIgnoreCase))
            {
                _lastKnownReadySnapshot = null;
                _lastKnownReadyProjectRoot = string.Empty;
                _lastKnownReadyPackageRoot = string.Empty;
                _lastKnownReadyAtUtc = default(DateTime);
            }
        }

        internal static bool ShouldPreserveReadyDuringTransientRefresh(
            AICodedbProductState previousState,
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan convergencePlan,
            bool hasVerifiedReadyForCurrentPackage,
            bool reconcileInFlight,
            int attempt,
            int maximumAttempts)
        {
            var hasStableReadyState = previousState == AICodedbProductState.Ready
                                      || (previousState == AICodedbProductState.Starting
                                          && hasVerifiedReadyForCurrentPackage);
            return hasStableReadyState
                   && convergencePlan == AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability
                   && (reconcileInFlight || attempt < maximumAttempts);
        }

        /// <summary>
        /// Keeps a valid current instance in Starting while its MCP availability
        /// recovery pass is still running. A bounded retry window prevents a
        /// persistent failure from being hidden as an indefinitely healthy state.
        /// </summary>
        internal static bool ShouldKeepRecoverableAvailabilityStarting(
            AICodedbProductState previousState,
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan convergencePlan,
            bool reconcileInFlight,
            int attempt,
            int maximumAttempts)
        {
            if (convergencePlan != AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability)
                return false;
            if (previousState == AICodedbProductState.MissingPrerequisite
                || previousState == AICodedbProductState.Uninstalled)
            {
                return false;
            }

            return reconcileInFlight || attempt < maximumAttempts;
        }

        internal static bool ShouldPresentRecoverableAvailabilityAsStarting(
            AICodedbProductState previousState,
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan convergencePlan,
            bool reconcileInFlight,
            int attempt,
            int maximumAttempts)
        {
            return previousState == AICodedbProductState.NeedsAttention
                   && ShouldKeepRecoverableAvailabilityStarting(
                       previousState,
                       convergencePlan,
                       reconcileInFlight,
                       attempt,
                       maximumAttempts);
        }

        internal static bool ShouldAutoObserveHostStatus(
            AICodedbHostPayloadState payloadState,
            AICodedbHostUpgradePhase upgradePhase,
            bool automaticUpdatesEnabled,
            bool automaticUpgradeSuppressed)
        {
            if (payloadState == AICodedbHostPayloadState.Draining)
                return true;
            if (upgradePhase == AICodedbHostUpgradePhase.Installing
                || upgradePhase == AICodedbHostUpgradePhase.Switching
                || upgradePhase == AICodedbHostUpgradePhase.Rollback)
            {
                return true;
            }
            return payloadState == AICodedbHostPayloadState.UpgradeReady
                   && automaticUpdatesEnabled
                   && !automaticUpgradeSuppressed;
        }

        internal static bool IsCurrentHostUpgradeFailure(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            return upgradeStatus.Phase == AICodedbHostUpgradePhase.Invalid
                   || AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                       upgradeStatus,
                       currentGenerationId);
        }

        internal static bool IsCurrentHostUpgradeInProgress(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            if (string.IsNullOrWhiteSpace(currentGenerationId)
                || !string.Equals(upgradeStatus.GenerationId, currentGenerationId, StringComparison.Ordinal))
            {
                return false;
            }

            return upgradeStatus.Phase == AICodedbHostUpgradePhase.Installing
                   || upgradeStatus.Phase == AICodedbHostUpgradePhase.Switching
                   || upgradeStatus.Phase == AICodedbHostUpgradePhase.Rollback;
        }

        internal static bool ShouldPrioritizeHostUpgradeStatus(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            return IsCurrentHostUpgradeFailure(upgradeStatus, currentGenerationId)
                   || IsCurrentHostUpgradeInProgress(upgradeStatus, currentGenerationId);
        }

        internal static string GetHostUpgradeStatusLabel(AICodedbHostUpgradePhase phase)
        {
            switch (phase)
            {
                case AICodedbHostUpgradePhase.Installing:
                    return "INSTALLING";
                case AICodedbHostUpgradePhase.Switching:
                    return "SWITCHING";
                case AICodedbHostUpgradePhase.Rollback:
                    return "ROLLBACK";
                case AICodedbHostUpgradePhase.CheckFailed:
                case AICodedbHostUpgradePhase.Invalid:
                    return "CHECK_FAILED";
                default:
                    return string.Empty;
            }
        }

        internal static string GetHostUpgradeActionLabel(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            return IsCurrentHostUpgradeFailure(upgradeStatus, currentGenerationId)
                ? "Retry update"
                : "Update now";
        }

        private void RefreshAllStatus()
        {
            RefreshStatus();
            BeginStatusRefresh(true);
            if (_selectedTab == (int)AICodedbManagerTab.Index)
                ScheduleWatcherStatusRefresh();
        }

        private void DrawHeader()
        {
            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox, GUILayout.Height(AICodedbManagerStyles.HeaderHeight)))
            {
                DrawHeaderBrandIcon();
                GUILayout.Label(
                    "\u25cf",
                    AICodedbManagerStyles.GetStateDotStyle(GetDisplayedProductState()),
                    GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                    GUILayout.Height(HeaderContentHeight));

                using (new EditorGUILayout.VerticalScope())
                {
                    GUILayout.Space(4f);
                    EditorGUILayout.LabelField(GetHeaderTitle(), AICodedbManagerStyles.HeaderTitle);
                    EditorGUILayout.LabelField(GetHeaderDescription(), AICodedbManagerStyles.HeaderSubtitle);
                }

                GUILayout.FlexibleSpace();
                var packageVersionContent = AICodedbBrandAssets.CreatePackageVersionContent();
                var controlsWidth = Mathf.Max(
                    HeaderControlsMinWidth,
                    AICodedbManagerStyles.HeaderPackageVersion.CalcSize(packageVersionContent).x);
                using (new EditorGUILayout.VerticalScope(GUILayout.Width(controlsWidth)))
                {
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        GUILayout.FlexibleSpace();
                        if (GUILayout.Button(
                                AICodedbProjectSettings.DefaultToolProfile,
                                EditorStyles.miniButton,
                                GUILayout.Width(HeaderProfileWidth),
                                GUILayout.Height(24f)))
                        {
                            SelectTab(AICodedbManagerTab.Policy);
                        }

                        DrawHeaderIconButton("Refresh", "Refresh status", RefreshAllStatus);
                        DrawHeaderIconButton("pane options", "More actions", ShowHeaderMenu);
                    }

                    EditorGUILayout.LabelField(
                        packageVersionContent,
                        AICodedbManagerStyles.HeaderPackageVersion,
                        GUILayout.Width(controlsWidth),
                        GUILayout.Height(HeaderPackageVersionHeight));
                }
            }
            var removalStatus = GetRemovalPresentationStatus();
            var removalBusy = IsRemovalActionBusy();
            if (IsRemovalActionVisible(removalStatus)
                && !IsRemovalActionEnabled(removalStatus, _statusSnapshot.IsProjectUninstalled, removalBusy))
                EditorGUILayout.HelpBox(GetRemovalActionLabel(removalStatus) + ": "
                    + GetRemovalActionDisabledReason(removalStatus, removalBusy), MessageType.Info);
        }

        private void ApplyWindowTitle()
        {
            titleContent = AICodedbBrandAssets.CreateWindowTitleContent();
        }

        private static void DrawHeaderBrandIcon()
        {
            var layoutRect = GUILayoutUtility.GetRect(
                HeaderBrandIconWidth,
                HeaderBrandIconWidth,
                HeaderContentHeight,
                HeaderContentHeight);
            var icon = AICodedbBrandAssets.Icon;
            if (icon == null)
                return;

            var iconRect = new Rect(
                layoutRect.x + (layoutRect.width - HeaderBrandIconSize) * 0.5f,
                layoutRect.y + (layoutRect.height - HeaderBrandIconSize) * 0.5f,
                HeaderBrandIconSize,
                HeaderBrandIconSize);
            GUI.DrawTexture(iconRect, icon, ScaleMode.ScaleToFit, true);
        }

        private void DrawHeaderIconButton(string iconName, string tooltip, Action action)
        {
            var content = new GUIContent(EditorGUIUtility.IconContent(iconName))
            {
                tooltip = tooltip
            };
            if (GUILayout.Button(
                    content,
                    EditorStyles.miniButton,
                    GUILayout.Width(AICodedbManagerStyles.IconButtonSize),
                    GUILayout.Height(AICodedbManagerStyles.IconButtonSize)))
            {
                action?.Invoke();
            }
        }

        private void ShowHeaderMenu()
        {
            var removalStatus = GetRemovalPresentationStatus();
            var menu = new GenericMenu();
            menu.AddItem(new GUIContent("Open/Provider"), false, AICodedbActions.OpenProviderFolder);
            menu.AddItem(new GUIContent("Open/Runtime"), false, AICodedbActions.OpenRuntimeFolder);
            menu.AddItem(new GUIContent("Open/Config"), false, AICodedbActions.OpenConfigFolder);
            menu.AddSeparator(string.Empty);
            if (CanUseHostCommands(_statusSnapshot.HostGenerationSelection.State))
            {
                menu.AddItem(
                    new GUIContent("Provider Guidance"),
                    false,
                    () => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance));
            }
            else
            {
                menu.AddDisabledItem(new GUIContent("Provider Guidance"));
            }
            menu.AddSeparator(string.Empty);
            menu.AddItem(new GUIContent("Uninstall CodeDB from Project"), false, RunUninstallCodeDBWithConfirmation);
            if (IsRemoveIntegrationMenuAvailable(removalStatus))
                menu.AddItem(new GUIContent("Remove CodeDB Integration"), false, RunRemoveIntegrationWithConfirmation);
            menu.ShowAsContext();
        }

        private void DrawTabBar()
        {
            EditorGUILayout.Space(4f);
            var nextTab = GUILayout.Toolbar(_selectedTab, TabNames, GUILayout.Height(28f));
            if (nextTab != _selectedTab)
            {
                using (AICodedbLifecycleEvidence.BeginCallback(AICodedbLifecycleCallbackKind.ManagerTabChanged))
                {
                    AICodedbLifecycleEvidence.RecordManagerObservation(AICodedbManagerObservationKind.TabChange);
                    _selectedTab = nextTab;
                    _scrollPosition = Vector2.zero;
                }
            }
            EditorGUILayout.Space(6f);
        }

        private void DrawMainContentArea(float width)
        {
            _mainContentWidth = Mathf.Max(0f, width);
            using (new EditorGUILayout.VerticalScope(GUILayout.Width(width), GUILayout.ExpandHeight(true)))
            {
                if (_statusSnapshot.IsProjectUninstalled)
                {
                    DrawUninstalledContent();
                    return;
                }

                DrawTabBar();
                _scrollPosition = EditorGUILayout.BeginScrollView(
                    _scrollPosition,
                    false,
                    false,
                    GUIStyle.none,
                    GUI.skin.verticalScrollbar,
                    GUI.skin.scrollView,
                    GUILayout.ExpandWidth(true),
                    GUILayout.ExpandHeight(true));
                using (new EditorGUILayout.HorizontalScope())
                {
                    GUILayout.Space(ContentHorizontalPadding);
                    using (new EditorGUILayout.VerticalScope(GUILayout.ExpandWidth(true)))
                        DrawSelectedTabContent();
                    GUILayout.Space(ContentHorizontalPadding);
                }
                EditorGUILayout.EndScrollView();
            }
        }

        private void DrawUninstalledContent()
        {
            _scrollPosition = EditorGUILayout.BeginScrollView(
                _scrollPosition,
                false,
                false,
                GUIStyle.none,
                GUI.skin.verticalScrollbar,
                GUI.skin.scrollView,
                GUILayout.ExpandWidth(true),
                GUILayout.ExpandHeight(true));
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Space(ContentHorizontalPadding);
                using (new EditorGUILayout.VerticalScope(GUILayout.ExpandWidth(true)))
                {
                    EditorGUILayout.Space(6f);
                    AICodedbSectionView.DrawPageHeader(
                        "CodeDB",
                        "Project integration",
                        string.Empty,
                        null);
                    AICodedbSectionView.DrawBanner(
                        "CodeDB is uninstalled from this project",
                        "The Package remains available, while automatic installation and watcher attachment are disabled.",
                        AICodedbStatusState.Inactive,
                        _userActionInFlight ? GetUserActionPresentation().ButtonLabel : "Install CodeDB",
                        _userActionInFlight ? null : (Action)RunInstallCodeDBWithConfirmation);
                }
                GUILayout.Space(ContentHorizontalPadding);
            }
            EditorGUILayout.EndScrollView();
        }

        private void DrawSelectedTabContent()
        {
            switch ((AICodedbManagerTab)_selectedTab)
            {
                case AICodedbManagerTab.Overview:
                    DrawOverviewTab();
                    break;
                case AICodedbManagerTab.Setup:
                    DrawSetupTab();
                    break;
                case AICodedbManagerTab.Index:
                    DrawIndexTab();
                    break;
                case AICodedbManagerTab.Mcp:
                    DrawMcpTab();
                    break;
                case AICodedbManagerTab.Policy:
                    DrawPolicyTab();
                    break;
            }
        }

        private void DrawOverviewTab()
        {
            AICodedbSectionView.DrawPageHeader(
                "Overview",
                "项目状态与建议操作",
                string.Empty,
                null,
                false);
            var removalStatus = GetRemovalPresentationStatus();
            var removeIntegrationAvailable = IsRemoveIntegrationAvailable(
                _statusSnapshot.HostGenerationSelection.State,
                _statusSnapshot.HostPayloadStatus.State,
                _statusSnapshot.HostUpgradeStatus.Phase,
                removalStatus.RemovalPreflightPassed);
            var removalActionAvailable = removeIntegrationAvailable
                                         || IsUninstallAvailable(
                                             removalStatus,
                                             _statusSnapshot.IsProjectUninstalled);
            var freshInstallRecoveryAvailable = IsFreshInstallRecoveryAvailable(
                _statusSnapshot.ProductStatus,
                _statusSnapshot.HostPayloadStatus,
                AICodedbManagerActionSession.CurrentFor(_executionContext),
                _executionContext, _retainedEffectsObservation);
            var primaryAction = GetPrimaryActionCallback(removalStatus,
                removalActionAvailable, freshInstallRecoveryAvailable);
            AICodedbSectionView.DrawBanner(
                GetOverviewStatusTitle(),
                GetOverviewStatusDescription(),
                GetDisplayedProductState(),
                GetPrimaryActionLabel(),
                primaryAction);

            _showOverviewDetails = AICodedbSectionView.DrawDisclosure(
                _showOverviewDetails,
                "Diagnostics",
                "Optional technical details",
                DrawOverviewTechnicalDetails);
        }

        private Action GetPrimaryActionCallback(AICodedbProductStatus removalStatus,
            bool removalActionAvailable, bool freshInstallRecoveryAvailable)
        {
            return ResolvePrimaryAction(
                removalStatus,
                removalActionAvailable,
                _userActionInFlight,
                freshInstallRecoveryAvailable)
                    || ResolveProviderInstallAction(
                        _statusSnapshot.ProductStatus,
                        _userActionInFlight)
                    ? (Action)RunPrimaryAction
                    : null;
        }

        private void DrawOverviewTechnicalDetails()
        {
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostPayload);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.CurrentInstance);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.CoordinatorFailure);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.TerminalConvergenceFailure);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ControlContractMigration);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostGeneration);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProviderExecutable);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProjectMcpConfig);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.McpAvailability);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.Cleanup);
            });
        }

        private void DrawSetupTab()
        {
            if (_statusSnapshot.IsProjectNotIntegrated)
                AICodedbSectionView.DrawBanner("CodeDB is not installed in this project",
                    _statusSnapshot.ProductStatus.Detail, AICodedbStatusState.Inactive,
                    "Install CodeDB", _userActionInFlight ? null : (Action)RunInstallCodeDBWithConfirmation);
            AICodedbSectionView.DrawPageHeader(
                "Setup",
                "Provider、配置与项目本地运行时",
                "Verify runtime",
                GetHostAction(() => RunAction("Verify Runtime", AICodedbActions.RunVerifyRuntime)));

            AICodedbSectionView.DrawStatusGroup("Environment", string.Empty, null, () =>
            {
                var providerState = _statusSnapshot.GetProviderState();
                var offerConfigureDependencies = ShouldOfferConfigureDependencies(_statusSnapshot.ProductStatus);
                AICodedbSectionView.DrawStatusRow(
                    "Provider",
                    "External executable",
                    providerState,
                    GetStateLabel(providerState, "Ready"),
                    offerConfigureDependencies
                        ? GetConfigureDependenciesLabel()
                        : providerState == AICodedbStatusState.Ok ? "Open" : "Guidance",
                    offerConfigureDependencies
                        ? GetConfigureDependenciesAction()
                        : providerState == AICodedbStatusState.Ok
                            ? (Action)AICodedbActions.OpenProviderFolder
                            : GetHostAction(() => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance)));

                var runtimeState = _statusSnapshot.GetRuntimeState();
                AICodedbSectionView.DrawStatusRow(
                    "Runtime",
                    "Project-local runtime",
                    runtimeState,
                    GetStateLabel(runtimeState, "Ready"),
                    runtimeState == AICodedbStatusState.Ok ? "Open" : "Prepare",
                    runtimeState == AICodedbStatusState.Ok
                        ? (Action)AICodedbActions.OpenRuntimeFolder
                        : GetHostAction(() => RunAction("Prepare Runtime", AICodedbActions.RunPrepareRuntime)));

                var configState = _statusSnapshot.GetConfigState();
                AICodedbSectionView.DrawStatusRow(
                    "Configuration",
                    _statusSnapshot.CurrentInstanceStatus.IsCurrent
                        ? "Active project runtime config"
                        : "Provider config and runtime template",
                    configState,
                    GetStateLabel(configState, "Current"),
                    "Regenerate",
                    GetHostAction(() => RunAction("Regenerate Runtime Config", AICodedbActions.RunRegenerateRuntimeConfig)));
            });

            _showProviderGuidance = AICodedbSectionView.DrawDisclosure(
                _showProviderGuidance,
                "Provider guidance",
                "Install or update",
                DrawProviderGuidanceActions);

            _showAdvancedHostFiles = AICodedbSectionView.DrawDisclosure(
                _showAdvancedHostFiles,
                "Advanced host files",
                GetHostPayloadSummary(),
                DrawAdvancedHostFiles);

        }

        private void DrawProviderGuidanceActions()
        {
            if (ShouldOfferConfigureDependencies(_statusSnapshot.ProductStatus))
            {
                DrawActionGrid(
                    AICodedbActionButton.Create(GetConfigureDependenciesLabel(), GetConfigureDependenciesAction()),
                    AICodedbActionButton.Create("Show guidance", GetHostAction(() => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance))),
                    AICodedbActionButton.Create("Open provider", AICodedbActions.OpenProviderFolder),
                    AICodedbActionButton.Create("Open config", AICodedbActions.OpenConfigFolder));
                return;
            }

            DrawActionGrid(
                AICodedbActionButton.Create("Show guidance", GetHostAction(() => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance))),
                AICodedbActionButton.Create("Open provider", AICodedbActions.OpenProviderFolder),
                AICodedbActionButton.Create("Open config", AICodedbActions.OpenConfigFolder));
        }

        private Action GetConfigureDependenciesAction()
        {
            return CanConfigureDependencies(_userActionInFlight)
                ? (Action)(() => RunUserActionAsync(
                    "Configure CodeDB Dependencies",
                    progressLine => AICodedbActions.RunInstallProviderAsync(progressLine),
                    RecheckHostPayloadAfterProviderAsync,
                    requestReconcileAfterAction: false,
                    refreshStatusAfterAction: false))
                : null;
        }

        private async Task<AICodedbCommandResult> RecheckHostPayloadAfterProviderAsync(
            AICodedbCommandResult providerResult)
        {
            if (providerResult == null || !providerResult.Succeeded)
                return providerResult;

            var outcome = await AICodedbActions.RunHostAdmissionAfterProviderAsync(providerResult);
            AICodedbManagerActionSession.CurrentFor(_executionContext)?.RecordPostOutcome(outcome);
            TryApplyCachedLifecycleStatus();
            return ResolvePostProviderReconcileResult(providerResult, outcome);
        }

        internal static AICodedbCommandResult ResolvePostProviderReconcileResult(
            AICodedbCommandResult providerResult,
            AICodedbEditorLifecycle.AICodedbReconcileOutcome outcome)
        {
            if (providerResult == null || !providerResult.Succeeded)
                return providerResult ?? new AICodedbCommandResult(4, string.Empty,
                    "Provider installation did not return a command result.", false);
            if (outcome == null)
                return new AICodedbCommandResult(4, string.Empty,
                    "Lifecycle did not return a post-Provider reconcile outcome.", false);

            return outcome.LastCommandResult ?? providerResult;
        }

        private string GetConfigureDependenciesLabel()
        {
            var presentation = GetUserActionPresentation();
            return presentation.IsRunning
                   && GetUserActionStatus().Title.IndexOf("Dependencies", StringComparison.OrdinalIgnoreCase) >= 0
                ? presentation.ButtonLabel
                : "Configure Dependencies";
        }

        private void DrawAdvancedHostFiles()
        {
            var updateAction = _statusSnapshot.HostPayloadStatus.CanUpgradeAutomatically
                && !IsCurrentHostUpgradeInProgress(
                    _statusSnapshot.HostUpgradeStatus,
                    _statusSnapshot.RuntimeContractTargetGenerationId)
                ? (Action)(() => RunAction("Host Payload Upgrade", AICodedbActions.RunHostPayloadUpgrade))
                : null;
            var redeployAction = _statusSnapshot.HostPayloadStatus.CanRedeploy
                ? (Action)RunHostPayloadRedeployWithConfirmation
                : null;
            var updateLabel = IsCurrentHostUpgradeInProgress(
                    _statusSnapshot.HostUpgradeStatus,
                    _statusSnapshot.RuntimeContractTargetGenerationId)
                    ? "Update in progress"
                    : GetHostUpgradeActionLabel(
                        _statusSnapshot.HostUpgradeStatus,
                        _statusSnapshot.RuntimeContractTargetGenerationId);
            DrawActionGrid(2,
                AICodedbActionButton.Create("Inspect host files", () => RunAction("Host Payload DryRun", AICodedbActions.RunHostPayloadDryRun)),
                AICodedbActionButton.Create("Verify host files", () => RunAction("Host Payload Verify", AICodedbActions.RunHostPayloadVerify)),
                AICodedbActionButton.Create(updateLabel, updateAction),
                AICodedbActionButton.Create("Redeploy host", redeployAction),
                AICodedbActionButton.Create("Sync host files", RunHostPayloadSyncWithConfirmation),
                AICodedbActionButton.Create("Remove host files", RunHostPayloadRemoveWithConfirmation));
            EditorGUILayout.Space(6f);
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostPayload);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostGeneration);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostLastKnownGood);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostUpgrade);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostUpdatePolicy);
                AICodedbDetailRowView.DrawValue("Materializer", "Package tool", AICodedbPaths.HostPayloadMaterializerScriptPath);
                AICodedbDetailRowView.DrawValue("Ownership marker", "Project path", AICodedbProjectSettings.HostPayloadMarkerRelativePath);
                AICodedbDetailRowView.DrawValue("Current pointer", "Ignored runtime", AICodedbProjectSettings.HostCurrentPointerRelativePath);
                AICodedbDetailRowView.DrawValue("Rollback pointer", "Ignored runtime", AICodedbProjectSettings.HostLastKnownGoodPointerRelativePath);
                if (_statusSnapshot.HostPayloadStatus.LegacyMcpSessionCount > 0)
                {
                    AICodedbDetailRowView.DrawValue(
                        "Legacy MCP sessions",
                        "Draining host-use leases",
                        _statusSnapshot.HostPayloadStatus.LegacyMcpSessionCount.ToString());
                }
                for (var index = 0; index < _statusSnapshot.HostPayloadStatus.ActiveOwners.Length; index++)
                {
                    AICodedbDetailRowView.DrawValue(
                        "Active owner " + (index + 1),
                        "Active lease owner",
                        _statusSnapshot.HostPayloadStatus.ActiveOwners[index]);
                }
            });
        }

        private void DrawIndexTab()
        {
            AICodedbSectionView.DrawPageHeader(
                "Index",
                "自动刷新、Freshness 与发现后端",
                "Refresh if stale",
                GetHostAction(() => RunSupervisorMaintenanceAction("Refresh If Stale", "RefreshIfStale")));

            DrawAutomaticRefresh();
            AICodedbSectionView.DrawStatusGroup(
                "Discovery data",
                "Check freshness",
                GetHostAction(() => RunAction("Check Freshness", AICodedbActions.RunFreshnessCheck)),
                () =>
                {
                    var indexState = _statusSnapshot.GetIndexState();
                    AICodedbSectionView.DrawStatusRow(
                        "Project index",
                        "C#, Lua and JavaScript discovery",
                        indexState,
                        GetStateLabel(indexState, "Current"));
                    var adapterState = _statusSnapshot.GetTextAdapterState();
                    AICodedbSectionView.DrawStatusRow(
                        "Shader / HLSL adapter",
                        "Shader, HLSL, Compute and CGINC",
                        adapterState,
                        GetStateLabel(adapterState, "Current"));
                });

            _showIndexDiagnostics = AICodedbSectionView.DrawDisclosure(
                _showIndexDiagnostics,
                "Diagnostics",
                "Probes and health checks",
                DrawIndexDiagnostics);
            _showIndexMaintenance = AICodedbSectionView.DrawDisclosure(
                _showIndexMaintenance,
                "Maintenance",
                "Controlled operations",
                DrawIndexMaintenance);
        }

        private void DrawAutomaticRefresh()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                using (new EditorGUILayout.HorizontalScope(GUILayout.MinHeight(52f)))
                {
                    GUILayout.Label(
                        "\u25cf",
                        AICodedbManagerStyles.GetStateDotStyle(GetWatcherDisplayState()),
                        GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                        GUILayout.Height(52f));
                    using (new EditorGUILayout.VerticalScope())
                    {
                        GUILayout.Space(3f);
                        EditorGUILayout.LabelField("Automatic refresh", AICodedbManagerStyles.RowTitle);
                        EditorGUILayout.LabelField(GetWatcherDescription(), AICodedbManagerStyles.RowDescription);
                    }

                    GUILayout.FlexibleSpace();
                    EditorGUILayout.LabelField(
                        GetWatcherLabel(),
                        AICodedbManagerStyles.GetStateValueStyle(GetWatcherDisplayState()),
                        GUILayout.Width(112f),
                        GUILayout.Height(52f));
                }

                AICodedbSectionView.DrawDivider();
                DrawLifecyclePolicyToggles();
                EditorGUILayout.Space(4f);
                var hasCurrentGeneration = CanUseLifecycleControls(_statusSnapshot.HostGenerationSelection.State);
                DrawActionGrid(3,
                    AICodedbActionButton.Create("Start now", hasCurrentGeneration ? (Action)(() => RunAction("Start Now", AICodedbActions.RunStartWatcher)) : null),
                    AICodedbActionButton.Create("Stop now", hasCurrentGeneration ? (Action)(() => RunAction("Stop Now", AICodedbActions.RunStopWatcher)) : null),
                    AICodedbActionButton.Create("Restart", hasCurrentGeneration ? (Action)(() => RunAction("Restart", AICodedbActions.RunRestartWatcher)) : null));
                if (!hasCurrentGeneration)
                    EditorGUILayout.HelpBox("Lifecycle controls require the current selected instance. Return to Overview and use Remove CodeDB Integration when an obsolete identity is reported.", MessageType.Info);

                var repairLabel = GetWatcherRepairLabel();
                if (!string.IsNullOrWhiteSpace(repairLabel))
                {
                    AICodedbSectionView.DrawDivider();
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        GUILayout.FlexibleSpace();
                        AICodedbSectionView.DrawCommandButton(repairLabel, GetWatcherRepairAction(), false);
                    }
                }
            }

            EditorGUILayout.Space(AICodedbManagerStyles.SectionGap);
        }

        private void DrawLifecyclePolicyToggles()
        {
            var previousMixedValue = EditorGUI.showMixedValue;
            EditorGUI.showMixedValue = !_watcherStatusLoaded || !_watcherStatus.HasKnownOptIn;
            var hasCurrentGeneration = CanUseLifecycleControls(_statusSnapshot.HostGenerationSelection.State);
            using (new EditorGUI.DisabledScope(!hasCurrentGeneration || !_watcherStatusLoaded || !_watcherStatus.HasKnownOptIn))
            {
                EditorGUI.BeginChangeCheck();
                var requestedStartWithEditor = EditorGUILayout.ToggleLeft(
                    "Start with Unity Editor",
                    _watcherStatus.IsOptInEnabled,
                    GUILayout.Height(InlineControlHeight));
                if (EditorGUI.EndChangeCheck())
                {
                    if (requestedStartWithEditor)
                        RunEnableWatcherWithConfirmation();
                    else
                        RunAction("Disable Start with Unity Editor", AICodedbActions.RunDisableWatcher);
                }
            }
            EditorGUI.showMixedValue = previousMixedValue;

            var updatePolicy = _statusSnapshot.HostUpdatePolicyValue;
            EditorGUI.showMixedValue = !updatePolicy.IsValid;
            EditorGUI.BeginChangeCheck();
            var requestedAutomaticUpdates = EditorGUILayout.ToggleLeft(
                "Automatic host updates",
                updatePolicy.IsEnabled,
                GUILayout.Height(InlineControlHeight));
            if (EditorGUI.EndChangeCheck())
            {
                RunAction(
                    "Automatic Host Updates",
                    () => AICodedbActions.SetAutomaticHostUpdates(requestedAutomaticUpdates));
                if (requestedAutomaticUpdates)
                    AICodedbEditorLifecycle.RequestReconcile();
            }
            EditorGUI.showMixedValue = previousMixedValue;
        }

        private void DrawIndexDiagnostics()
        {
            DrawActionGrid(
                AICodedbActionButton.Create("Check freshness", GetHostAction(() => RunAction("Check Freshness", AICodedbActions.RunFreshnessCheck))),
                AICodedbActionButton.Create("Watcher status", GetHostAction(() => RunAction("Watcher Status", AICodedbActions.RunWatcherStatus))),
                AICodedbActionButton.Create("Runtime health", GetHostAction(() => RunAction("Runtime Health", AICodedbActions.RunRuntimeHealth))),
                AICodedbActionButton.Create("Unity smoke", GetHostAction(() => RunAction("Unity Project Smoke", AICodedbActions.RunUnityProjectSmoke))),
                AICodedbActionButton.Create("Language probe", GetHostAction(() => RunAction("Language Probe", AICodedbActions.RunLanguageProbe))),
                AICodedbActionButton.Create("C# probe", GetHostAction(() => RunAction("C# Probe", AICodedbActions.RunCSharpProbe))),
                AICodedbActionButton.Create("Shader probe", GetHostAction(() => RunAction("Shader Adapter Probe", AICodedbActions.RunShaderAdapterProbe))));
            EditorGUILayout.Space(6f);
            EditorGUILayout.LabelField("Custom probe", EditorStyles.miniBoldLabel);
            DrawCustomProbeSection();
        }

        private void DrawIndexMaintenance()
        {
            DrawActionGrid(
                AICodedbActionButton.Create("Refresh index", GetHostAction(() => RunSupervisorMaintenanceAction("Refresh Index", "RefreshIndex"))),
                AICodedbActionButton.Create("Build shader", GetHostAction(() => RunSupervisorMaintenanceAction("Build Shader Adapter", "BuildShaderAdapter"))),
                AICodedbActionButton.Create("Open runtime", AICodedbActions.OpenRuntimeFolder),
                AICodedbActionButton.Create("Clean index", GetHostAction(RunCleanIndexWithConfirmation)),
                AICodedbActionButton.Create("Rebuild index", GetHostAction(RunRebuildIndexWithConfirmation)));
            EditorGUILayout.Space(6f);
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawValue("Index", "Relative path", _statusSnapshot.IndexRootRelativePath);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.IndexManifest);
                AICodedbDetailRowView.DrawValue("Shader adapter", "Relative path", _statusSnapshot.TextAdapterRootRelativePath);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.TextAdapterManifest);
                AICodedbDetailRowView.DrawValue("Watcher", "Runtime", _statusSnapshot.WatchRootRelativePath);
            });
        }

        private void DrawMcpTab()
        {
            AICodedbSectionView.DrawPageHeader(
                "MCP",
                "当前项目的配置与 Package 后端",
                "Verify configuration",
                GetHostAction(() => RunAction("Project Config Validation", AICodedbActions.RunRegistrationValidation)));

            var configurationState = _statusSnapshot.ProjectMcpConfig.State;
            var backendState = _statusSnapshot.McpAvailability.State;
            AICodedbSectionView.DrawBanner(
                configurationState == AICodedbStatusState.Ok
                    ? McpConfigurationReadyMessage
                    : McpConfigurationAttentionMessage,
                AICodedbProjectSettings.ProjectMcpConfigRelativePath + " · " + AICodedbProjectSettings.ProviderSlug,
                configurationState,
                "Copy snippet",
                CopyMcpSnippet);

            AICodedbSectionView.DrawStatusGroup("Project MCP", string.Empty, null, () =>
            {
                AICodedbSectionView.DrawStatusRow(
                    "Scope",
                    "Project-local configuration",
                    AICodedbStatusState.Ok,
                    "Project-owned");
                AICodedbSectionView.DrawStatusRow(
                    "Configuration",
                    AICodedbProjectSettings.ProviderSlug,
                    configurationState,
                    GetStateLabel(configurationState, "Ready"));
                AICodedbSectionView.DrawStatusRow(
                    "Package backend",
                    "Initialize, tools, status, and bounded query",
                    backendState,
                    GetStateLabel(backendState, "Available"));
                AICodedbSectionView.DrawStatusRow(
                    "Codex client",
                    "Verified separately in a new project task",
                    AICodedbStatusState.Inactive,
                    McpClientUnobservedLabel);
                var runtimeState = _statusSnapshot.GetRuntimeState();
                AICodedbSectionView.DrawStatusRow(
                    "Runtime root",
                    "Relative to the Unity project",
                    runtimeState,
                    GetStateLabel(runtimeState, "Valid"));
            });

            _showMcpSnippet = AICodedbSectionView.DrawDisclosure(
                _showMcpSnippet,
                "Project configuration snippet",
                "Copy-only",
                DrawMcpProjectSnippetSection);
            _showMcpPolicy = AICodedbSectionView.DrawDisclosure(
                _showMcpPolicy,
                "Configuration policy",
                "Project-local only",
                DrawMcpPolicy);
        }

        private void DrawMcpProjectSnippetSection()
        {
            EditorGUILayout.LabelField(
                "Target: " + AICodedbProjectSettings.ProjectMcpConfigRelativePath,
                EditorStyles.miniLabel);
            DrawActionGrid(
                AICodedbActionButton.Create("Show draft", GetHostAction(() => RunAction("Registration Draft", AICodedbActions.RunRegistrationDraft))),
                AICodedbActionButton.Create("Copy snippet", CopyMcpSnippet));
            var snippet = AICodedbProjectSettings.BuildProjectMcpRegistrationSnippet();
            var rect = GUILayoutUtility.GetRect(
                GUIContent.none,
                AICodedbManagerStyles.OutputText,
                GUILayout.Height(McpSnippetHeight),
                GUILayout.ExpandWidth(true));
            EditorGUI.SelectableLabel(rect, snippet, AICodedbManagerStyles.OutputText);
        }

        private void DrawMcpPolicy()
        {
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProjectMcpConfig);
                AICodedbDetailRowView.DrawValue("Configuration", "Scope", "Project-local only");
                AICodedbDetailRowView.DrawValue("Configuration", "Target", AICodedbProjectSettings.ProjectMcpConfigRelativePath);
                AICodedbDetailRowView.DrawValue("Server", "Name", AICodedbProjectSettings.ProviderSlug);
                AICodedbDetailRowView.DrawValue("Global config", "Not used", "CodeDB does not create a user-global project registration.");
            });
            EditorGUILayout.HelpBox(
                "CodeDB owns only its managed keys in the project-local configuration. A new Codex task loads that configuration independently.",
                MessageType.Info);
        }

        private void DrawPolicyTab()
        {
            AICodedbSectionView.DrawPageHeader("Policy", "默认工具权限与项目边界", string.Empty, null);
            DrawPolicyProfile();
            AICodedbSectionView.DrawStatusGroup("Ownership boundaries", string.Empty, null, () =>
            {
                AICodedbSectionView.DrawStatusRow(
                    "Project scope",
                    "Current Unity project paths only",
                    AICodedbStatusState.Ok,
                    "Enforced");
                AICodedbSectionView.DrawStatusRow(
                    "Generated data",
                    "Ignored project-local runtime",
                    AICodedbStatusState.Ok,
                    "Local");
                AICodedbSectionView.DrawStatusRow(
                    "Source confirmation",
                    "Direct source or rg for important facts",
                    AICodedbStatusState.Inactive,
                    "Required");
            });

            _showRestrictedCapabilities = AICodedbSectionView.DrawDisclosure(
                _showRestrictedCapabilities,
                "Restricted capabilities",
                "6 restricted by default",
                DrawRestrictedCapabilities);
            _showPolicyDetails = AICodedbSectionView.DrawDisclosure(
                _showPolicyDetails,
                "Profile details",
                "Project and provider identity",
                () => DrawDetailsPanel(() =>
                {
                    AICodedbDetailRowView.DrawStatus(_statusSnapshot.ToolProfile);
                    AICodedbDetailRowView.DrawValue("Project", "Slug", AICodedbProjectSettings.ProjectSlug);
                    AICodedbDetailRowView.DrawValue("Provider", "Slug", AICodedbProjectSettings.ProviderSlug);
                }));
        }

        private void DrawPolicyProfile()
        {
            var policyState = _statusSnapshot.GetPolicyState();
            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox, GUILayout.MinHeight(64f)))
            {
                GUILayout.Label(
                    "\u25cf",
                    AICodedbManagerStyles.GetStateDotStyle(policyState),
                    GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                    GUILayout.Height(50f));
                using (new EditorGUILayout.VerticalScope())
                {
                    EditorGUILayout.LabelField("Discover Read", AICodedbManagerStyles.RowTitle);
                    EditorGUILayout.LabelField("用于发现文件、读取 outline 和方法体；关键结论仍需源码确认。", AICodedbManagerStyles.RowDescription);
                }

                GUILayout.FlexibleSpace();
                AICodedbSectionView.DrawCapabilityLabel("Search", policyState);
                AICodedbSectionView.DrawCapabilityLabel("Outline", policyState);
                AICodedbSectionView.DrawCapabilityLabel("Read", policyState);
            }

            EditorGUILayout.Space(AICodedbManagerStyles.SectionGap);
        }

        private static void DrawRestrictedCapabilities()
        {
            AICodedbSectionView.DrawNeutralCapability("Edit");
            AICodedbSectionView.DrawNeutralCapability("Shell");
            AICodedbSectionView.DrawNeutralCapability("Remote");
            AICodedbSectionView.DrawNeutralCapability("Memory");
            AICodedbSectionView.DrawNeutralCapability("Cross-project");
            AICodedbSectionView.DrawNeutralCapability("Broad export");
        }

        private static void DrawDetailsPanel(Action drawRows)
        {
            using (new EditorGUILayout.VerticalScope())
            {
                AICodedbDetailRowView.DrawHeader();
                drawRows();
            }
        }

        private void DrawActionGrid(params AICodedbActionButton[] buttons)
        {
            DrawActionGrid(AICodedbActionGridView.DefaultColumns, buttons);
        }

        private void DrawActionGrid(int maxColumns, params AICodedbActionButton[] buttons)
        {
            var availableWidth = Mathf.Max(
                0f,
                _mainContentWidth
                - (ContentHorizontalPadding * 2f)
                - AICodedbActionGridView.ContainerHorizontalPadding);
            AICodedbActionGridView.Draw(availableWidth, maxColumns, buttons);
        }

        private void DrawCustomProbeSection()
        {
            var availableWidth = Mathf.Max(
                0f,
                _mainContentWidth
                - (ContentHorizontalPadding * 2f)
                - AICodedbActionGridView.ContainerHorizontalPadding);
            if (availableWidth >= CustomProbeSingleRowMinWidth)
            {
                using (new EditorGUILayout.HorizontalScope(GUILayout.Height(AICodedbActionGridView.RowHeight)))
                {
                    DrawCustomProbeLanguageField();
                    DrawCustomProbeQueryField(CustomProbeQueryMinWidth);
                    GUILayout.Space(AICodedbActionGridView.Gap);
                    DrawRunProbeButton();
                }
                return;
            }

            using (new EditorGUILayout.HorizontalScope(GUILayout.Height(InlineControlHeight)))
            {
                DrawCustomProbeLanguageField();
                GUILayout.FlexibleSpace();
            }

            using (new EditorGUILayout.HorizontalScope(GUILayout.Height(AICodedbActionGridView.RowHeight)))
            {
                DrawCustomProbeQueryField(80f);
                GUILayout.Space(AICodedbActionGridView.Gap);
                DrawRunProbeButton();
            }
        }

        private void DrawCustomProbeLanguageField()
        {
            EditorGUILayout.LabelField(
                "Language",
                GUILayout.Width(CustomProbeLanguageLabelWidth),
                GUILayout.Height(InlineControlHeight));
            _customProbeLanguageIndex = EditorGUILayout.Popup(
                _customProbeLanguageIndex,
                CustomProbeLanguageLabels,
                GUILayout.Width(CustomProbeLanguageWidth),
                GUILayout.Height(InlineControlHeight));
        }

        private void DrawCustomProbeQueryField(float minimumWidth)
        {
            EditorGUILayout.LabelField(
                "Custom Test Text",
                GUILayout.Width(CustomProbeQueryLabelWidth),
                GUILayout.Height(InlineControlHeight));
            _customProbeQuery = EditorGUILayout.TextField(
                _customProbeQuery ?? string.Empty,
                GUILayout.MinWidth(minimumWidth),
                GUILayout.Height(InlineControlHeight),
                GUILayout.ExpandWidth(true));
        }

        private void DrawRunProbeButton()
        {
            using (new EditorGUI.DisabledScope(
                       string.IsNullOrWhiteSpace(_customProbeQuery)
                       || !CanUseHostCommands(_statusSnapshot.HostGenerationSelection.State)))
            {
                if (GUILayout.Button(
                        "Run probe",
                        GUI.skin.button,
                        GUILayout.Width(AICodedbActionGridView.ButtonWidth),
                        GUILayout.Height(AICodedbActionGridView.ButtonHeight)))
                {
                    var query = (_customProbeQuery ?? string.Empty).Trim();
                    var language = CustomProbeLanguageValues[Mathf.Clamp(
                        _customProbeLanguageIndex, 0, CustomProbeLanguageValues.Length - 1)];
                    RunAction("Language Custom Probe", () => RunLanguageCustomProbe(query, language));
                }
            }
        }

        private string GetPrimaryActionLabel()
        {
            if (_statusSnapshot == null)
                return string.Empty;
            if (_userActionInFlight)
                return GetUserActionPresentation().ButtonLabel;
            var freshInstallRecovery = _statusSnapshot.ProductStatus.State == AICodedbProductState.NeedsAttention
                && IsFreshInstallRecoveryAvailable(_statusSnapshot.ProductStatus, _statusSnapshot.HostPayloadStatus,
                    AICodedbManagerActionSession.CurrentFor(_executionContext), _executionContext, _retainedEffectsObservation);
            return GetPrimaryActionLabel(GetRemovalPresentationStatus(), freshInstallRecovery);
        }

        internal static string GetPrimaryActionLabel(AICodedbProductStatus status, bool freshInstallRecovery)
        {
            switch (status.State)
            {
                case AICodedbProductState.Uninstalled:
                case AICodedbProductState.NotIntegrated:
                    return "Install CodeDB";
                case AICodedbProductState.Ready:
                    return "Uninstall CodeDB from Project";
                case AICodedbProductState.NeedsAttention:
                {
                    if (freshInstallRecovery)
                        return "Install CodeDB";
                    if (IsRemoveIntegrationMenuAvailable(status))
                        return "Remove CodeDB Integration";
                    return "Uninstall CodeDB from Project";
                }
                case AICodedbProductState.MissingPrerequisite:
                    return IsProviderInstallAvailable(status)
                        ? "Configure Dependencies"
                        : string.Empty;
                default:
                    return string.Empty;
            }
        }

        private void RunPrimaryAction()
        {
            if (_statusSnapshot != null
                && IsProviderInstallAvailable(_statusSnapshot.ProductStatus))
            {
                RunUserActionAsync(
                    "Configure CodeDB Dependencies",
                    progressLine => AICodedbActions.RunInstallProviderAsync(progressLine),
                    RecheckHostPayloadAfterProviderAsync,
                    requestReconcileAfterAction: false,
                    refreshStatusAfterAction: false);
                return;
            }

            if (_statusSnapshot != null && IsFreshInstallRecoveryAvailable(
                    _statusSnapshot.ProductStatus,
                    _statusSnapshot.HostPayloadStatus,
                    AICodedbManagerActionSession.CurrentFor(_executionContext),
                    _executionContext, _retainedEffectsObservation))
                RunInstallCodeDBWithConfirmation();
            else if (_statusSnapshot != null && (_statusSnapshot.IsProjectUninstalled || _statusSnapshot.IsProjectNotIntegrated))
                RunInstallCodeDBWithConfirmation();
            else if (_statusSnapshot != null &&
                     IsRemoveIntegrationMenuAvailable(GetRemovalPresentationStatus()))
                RunRemoveIntegrationWithConfirmation();
            else if (_statusSnapshot != null &&
                     IsUninstallAvailable(
                         GetRemovalPresentationStatus(), _statusSnapshot.IsProjectUninstalled))
                RunUninstallCodeDBWithConfirmation();
        }

        private void RunRemoveIntegrationWithConfirmation()
        {
            var cachedProductStatus = GetRemovalPresentationStatus();
            if (IsRemovalActionBusy()
                || !IsRemoveIntegrationMenuAvailable(cachedProductStatus))
                return;
            ConfirmAndRunRemoveIntegration(
                () => EditorUtility.DisplayDialog(
                    RemoveIntegrationConfirmationTitle,
                    RemoveIntegrationConfirmationMessage,
                    "Remove Integration",
                    "Cancel"),
                confirmedProjectMutation => RunUserActionAsync(
                    "Remove CodeDB Integration",
                    () => AICodedbActions.RunRemoveIntegrationCodeDBAsync(
                        cachedProductStatus,
                        confirmedProjectMutation),
                    false));
        }

        internal static bool ConfirmAndRunRemoveIntegration(Func<bool> confirm, Action<bool> remove)
        {
            if (confirm == null)
                throw new ArgumentNullException(nameof(confirm));
            if (remove == null)
                throw new ArgumentNullException(nameof(remove));
            if (!confirm())
                return false;

            remove(true);
            return true;
        }

        private void RunUninstallCodeDBWithConfirmation()
        {
            ConfirmAndRunUninstallCodeDB(
                IsRemovalActionBusy(),
                () => { AttachCurrentActionSession(); Repaint(); },
                () => EditorUtility.DisplayDialog(
                    UninstallCodeDBConfirmationTitle,
                    UninstallCodeDBConfirmationMessage,
                    "Uninstall CodeDB",
                    "Cancel"),
                () =>
                {
                    var retained = AICodedbManagerActionSession.CurrentFor(_executionContext);
                    if (retained != null && retained.IsRecovering && retained.HasOriginalContext
                        && retained.Title == "Install CodeDB")
                        RunFailedCandidateUninstallRecoveryAsync(retained);
                    else
                        RunUserActionAsync("Uninstall CodeDB from Project", AICodedbActions.RunUninstallCodeDBAsync);
                });
        }

        private async void RunFailedCandidateUninstallRecoveryAsync(AICodedbManagerActionSession original)
        {
            if (_actionRecoveryInspectionInFlight || original == null || !original.IsRecovering
                || !original.HasOriginalContext) return;
            _actionRecoveryInspectionInFlight = true;
            try
            {
                var result = await AICodedbHostPayloadMaterializer.RunFailedCandidateUninstallRecoveryAsync(
                    _executionContext, original.ActionId);
                if (!result.Succeeded)
                {
                    original.SetRecoveryDetail(result.GetSummary() + " " + result.StandardError);
                    return;
                }
                var read = await Task.Run(() => AICodedbManagerActionJournal.Read(_executionContext));
                if (read.State != AICodedbManagerActionIndexState.Empty || read.Index == null
                    || read.Index.ActionId != original.ActionId || read.HistoricalResult == null
                    || !read.HistoricalResult.FailedCandidateEffectsRetained)
                {
                    original.SetRecoveryDetail("The confirmed Uninstall has no complete matching effects disposition. " + read.Detail);
                    return;
                }
                var released = await Task.Run(() => AICodedbManagerActionJournal.TryReleaseRetainedEffects(read.Index, out var _));
                if (!released) { original.SetRecoveryDetail("The retained effects index publication is incomplete."); return; }
                original.CompleteRetainedEffectsRecovery(read.HistoricalResult, EditorApplication.timeSinceStartup);
                AICodedbEditorLifecycle.RequestReconcile();
            }
            finally
            {
                _actionRecoveryInspectionInFlight = false;
                AttachCurrentActionSession();
                Repaint();
            }
        }

        private bool IsRemovalActionBusy()
        {
            var session = AICodedbManagerActionSession.CurrentFor(_executionContext);
            return IsRemovalActionBusy(_userActionInFlight, _actionRecoveryInspectionInFlight,
                session != null && session.IsRecovering && session.HasOriginalContext
                && session.Title == "Install CodeDB");
        }

        internal static bool IsRemovalActionBusy(bool actionInFlight, bool inspectionInFlight, bool retainedRecovery)
        {
            // The existing confirmed failed-candidate recovery is not a running action.
            return inspectionInFlight || (actionInFlight && !retainedRecovery);
        }

        internal static bool IsRemovalActionVisible(AICodedbProductStatus status)
        {
            // The uninstall entry is a durable project command, not a cached
            // readiness affordance. Unknown/malformed authority is classified
            // by the backend after confirmation and must remain callable.
            return true;
        }

        internal static string GetRemovalActionLabel(AICodedbProductStatus status)
        {
            return status.RequiresReinstall ? "Remove CodeDB Integration" : "Uninstall CodeDB from Project";
        }

        internal static bool IsRemovalActionEnabled(AICodedbProductStatus status, bool isProjectUninstalled, bool actionInFlight)
        {
            return !actionInFlight;
        }

        internal static string GetRemovalActionDisabledReason(AICodedbProductStatus status, bool actionInFlight)
        {
            if (actionInFlight) return "Wait for the current CodeDB action to finish.";
            const string prefix = " Removal preflight: ";
            var diagnostic = status.DiagnosticDetail ?? string.Empty;
            var start = diagnostic.LastIndexOf(prefix, StringComparison.Ordinal);
            if (start >= 0)
            {
                // This segment is the lifecycle's bounded, redacted cached diagnostic.
                var reason = diagnostic.Substring(start + prefix.Length);
                return reason.Length > 900 ? reason.Substring(0, 900) : reason;
            }
            if (status.AttentionReason == AICodedbProductAttentionReason.ControlContractInvalidOrAmbiguous
                || status.AttentionReason == AICodedbProductAttentionReason.ControlContractAuthenticationUnavailable)
                return "Integration ownership is not authenticated. Refresh status before trying again.";
            return "Removal admission has not passed. Refresh status to check availability.";
        }

        internal static bool IsUninstallAvailable(
            AICodedbProductStatus status,
            bool isProjectUninstalled)
        {
            // Availability answers whether the confirmed request can be
            // submitted. Effect classification, ownership and no-op handling
            // belong to the durable backend admission, not the cached status.
            return true;
        }

        internal static bool IsRemoveIntegrationMenuAvailable(AICodedbProductStatus status)
        {
            return status.RequiresReinstall
                   && status.RemovalPreflightPassed;
        }

        private AICodedbProductStatus GetRemovalPresentationStatus()
        {
            if (_statusSnapshot == null)
                return default(AICodedbProductStatus);
            var displayed = _statusSnapshot.ProductStatus;
            AICodedbCommandResult ignoredResult;
            AICodedbProductStatus cached;
            bool hasCached;
            long ignoredRevision;
            AICodedbEditorLifecycle.TryGetCachedLifecycleStatus(
                out ignoredResult, out cached, out hasCached, out ignoredRevision);
            return ResolveRemovalPresentationStatus(displayed, cached, hasCached);
        }

        internal static AICodedbProductStatus ResolveRemovalPresentationStatus(
            AICodedbProductStatus displayed,
            AICodedbProductStatus cached,
            bool hasCached)
        {
            return hasCached && cached.State == displayed.State
                ? cached
                : displayed;
        }

        private void RunInstallCodeDBWithConfirmation()
        {
            ConfirmAndRunInstallCodeDB(
                () => EditorUtility.DisplayDialog(
                    InstallCodeDBConfirmationTitle,
                    InstallCodeDBConfirmationMessage,
                    "Install CodeDB",
                    "Cancel"),
                () => RunUserActionAsync("Install CodeDB", AICodedbActions.RunInstallCodeDBAsync));
        }

        internal static bool ConfirmAndRunUninstallCodeDB(Func<bool> confirm, Action uninstall)
        {
            return ConfirmAndRunProjectIntegrationAction(confirm, uninstall);
        }

        internal static bool ConfirmAndRunUninstallCodeDB(
            bool busy, Action observeCurrent, Func<bool> confirm, Action uninstall)
        {
            if (busy)
            {
                observeCurrent();
                return false;
            }
            return ConfirmAndRunUninstallCodeDB(confirm, uninstall);
        }

        internal static bool ConfirmAndRunInstallCodeDB(Func<bool> confirm, Action install)
        {
            return ConfirmAndRunProjectIntegrationAction(confirm, install);
        }

        private static bool ConfirmAndRunProjectIntegrationAction(Func<bool> confirm, Action action)
        {
            if (confirm == null)
                throw new ArgumentNullException(nameof(confirm));
            if (action == null)
                throw new ArgumentNullException(nameof(action));
            if (!confirm())
                return false;

            action();
            return true;
        }

        internal static bool IsRemoveIntegrationAvailable(
            AICodedbHostGenerationState generationState,
            AICodedbHostPayloadState payloadState,
            AICodedbHostUpgradePhase upgradePhase,
            bool removalPreflightPassed)
        {
            // Host readiness does not grant removal; the cached worker preflight does.
            return removalPreflightPassed
                   && Enum.IsDefined(typeof(AICodedbHostGenerationState), generationState)
                   && Enum.IsDefined(typeof(AICodedbHostPayloadState), payloadState)
                   && Enum.IsDefined(typeof(AICodedbHostUpgradePhase), upgradePhase);
        }

        internal static bool ResolvePrimaryAction(
            AICodedbProductStatus productStatus,
            bool recoveryAvailable,
            bool actionInFlight)
        {
            return ResolvePrimaryAction(productStatus, recoveryAvailable, actionInFlight, false);
        }

        internal static bool ResolvePrimaryAction(
            AICodedbProductStatus productStatus,
            bool recoveryAvailable,
            bool actionInFlight,
            bool freshInstallRecoveryAvailable)
        {
            if (actionInFlight)
                return false;
            if (productStatus.State == AICodedbProductState.Uninstalled || productStatus.State == AICodedbProductState.NotIntegrated)
                return true;
            if (productStatus.State == AICodedbProductState.Ready)
                return true;
            if (freshInstallRecoveryAvailable && productStatus.State == AICodedbProductState.NeedsAttention)
                return true;
            return productStatus.State == AICodedbProductState.NeedsAttention;
        }

        internal static bool IsFreshInstallRecoveryAvailable(
            AICodedbProductStatus productStatus,
            AICodedbHostPayloadStatus hostPayloadStatus,
            AICodedbManagerActionSession historicalSession,
            AICodedbEditorExecutionContext currentContext,
            AICodedbRetainedEffectsObservation effectsObservation = null)
        {
            if ((historicalSession != null && (historicalSession.IsRecovering || historicalSession.IsRunning))
                || effectsObservation == null || !effectsObservation.Safe
                || !effectsObservation.InstallEligible
                || productStatus.State != AICodedbProductState.NeedsAttention
                || productStatus.AttentionReason != AICodedbProductAttentionReason.None
                || hostPayloadStatus.State != AICodedbHostPayloadState.SetupRequired)
                return false;
            return string.Equals(effectsObservation.Context.ProjectRoot, currentContext.ProjectRoot,
                    StringComparison.OrdinalIgnoreCase)
                && string.Equals(effectsObservation.Context.PackageRoot, currentContext.PackageRoot,
                    StringComparison.OrdinalIgnoreCase);
        }

        internal static bool ResolveProviderInstallAction(
            AICodedbProductStatus productStatus,
            bool actionInFlight)
        {
            return !actionInFlight && IsProviderInstallAvailable(productStatus);
        }

        internal static bool ShouldShowPersistentDependencyAction(AICodedbProductStatus productStatus)
        {
            return IsProviderInstallAvailable(productStatus);
        }

        internal static bool ShouldOfferConfigureDependencies(AICodedbProductStatus productStatus)
        {
            return IsProviderInstallAvailable(productStatus);
        }

        internal static bool CanConfigureDependencies(bool actionInFlight)
        {
            return !actionInFlight;
        }

        internal static bool IsProviderInstallAvailable(AICodedbProductStatus productStatus)
        {
            if (productStatus.State != AICodedbProductState.MissingPrerequisite)
                return false;

            var reasonCode = productStatus.Command.ReasonCode ?? string.Empty;
            if (reasonCode.StartsWith("PROVIDER_", StringComparison.Ordinal))
                return true;

            var detail = productStatus.Detail ?? string.Empty;
            return detail.IndexOf("Provider", StringComparison.OrdinalIgnoreCase) >= 0
                   && detail.IndexOf("Node.js", StringComparison.OrdinalIgnoreCase) < 0;
        }

        private void CopyMcpSnippet()
        {
            EditorGUIUtility.systemCopyBuffer = AICodedbProjectSettings.BuildProjectMcpRegistrationSnippet();
        }

        private void RunCleanIndexWithConfirmation()
        {
            if (!EditorUtility.DisplayDialog(
                    "Clean codedb index",
                    "Remove generated index data only? Provider executable and runtime config will be preserved.",
                    "Clean Index",
                    "Cancel"))
            {
                return;
            }

            RunSupervisorMaintenanceAction("Clean Index", "CleanIndex");
        }

        private void RunRebuildIndexWithConfirmation()
        {
            if (!EditorUtility.DisplayDialog(
                    "Rebuild codedb index",
                    "Remove generated index data, then refresh the project-local index? Provider executable and runtime config will be preserved.",
                    "Rebuild Index",
                    "Cancel"))
            {
                return;
            }

            RunSupervisorMaintenanceAction("Rebuild Index", "RebuildIndex");
        }

        private void RunEnableWatcherWithConfirmation()
        {
            if (!EditorUtility.DisplayDialog(
                    "Enable automatic refresh",
                    "Enable CodeDB for this project? The preference persists across Editor restarts, while the backend runs only when an interactive Editor is online.",
                    "Enable",
                    "Cancel"))
            {
                return;
            }

            RunAction("Enable Start with Unity Editor", AICodedbActions.RunEnableWatcher);
        }

        private void RunHostPayloadSyncWithConfirmation()
        {
            if (!EditorUtility.DisplayDialog(
                    "Sync package-managed host files",
                    "Synchronize only the manifest-closed CodeDB Host payload and ownership marker in this Unity project? "
                    + "Unknown content, drift, path collisions, invalid ownership, and active unsafe owners remain blocked. "
                    + "Provider data, business files, version-control metadata, and external MCP clients are preserved.",
                    "Sync Host Files",
                    "Cancel"))
            {
                return;
            }

            RunAction("Host Payload Sync", AICodedbActions.RunHostPayloadSync);
        }

        private async void RunHostPayloadRedeployWithConfirmation()
        {
            await RunUserActionAsync(
                "Host Payload Redeploy",
                _ => Task.Run(() =>
                {
                    using (AICodedbPaths.UseActionStage(AICodedbActions.RedeployUiPreflightStage, false))
                        return AICodedbActions.RunHostPayloadDryRun();
                }),
                ContinueHostPayloadRedeployAfterPreflightAsync);
        }

        private async Task<AICodedbCommandResult> ContinueHostPayloadRedeployAfterPreflightAsync(
            AICodedbCommandResult preflightResult)
        {
            await RefreshStatusAsync(preflightResult);
            if (!preflightResult.Succeeded)
            {
                _lastResultTitle = "Host Payload Redeploy Preflight";
                return BuildPreEffectManagerDecision(preflightResult.ExitCode,
                    preflightResult.StandardOutput, preflightResult.StandardError,
                    preflightResult.ElapsedMilliseconds);
            }

            var hostPayload = _statusSnapshot.HostPayloadStatus;
            if (!hostPayload.CanRedeploy)
            {
                EditorUtility.DisplayDialog(
                    "Redeploy status changed",
                    "The Manager refreshed CodeDB status and Redeploy is no longer available. Review the updated Host status before continuing.",
                    "OK");
                return BuildPreEffectManagerDecision(
                    4,
                    preflightResult.StandardOutput,
                    "Redeploy is no longer available after the background preflight.",
                    preflightResult.ElapsedMilliseconds);
            }

            if (hostPayload.ActiveOwners.Length > 0 && !hostPayload.HasOnlyLegacyWatcherOwners)
            {
                var mcpGuidance = hostPayload.ActiveMcpSessionCount > 0
                    ? "CodeDB is still connected to " + hostPayload.ActiveMcpSessionCount + " MCP client"
                      + (hostPayload.ActiveMcpSessionCount == 1 ? string.Empty : "s")
                      + ". Disconnect this project from those clients, then click Redeploy host again."
                    : "CodeDB is still in use by an owner that cannot be stopped safely from the Manager. Close the connected CodeDB client, refresh status, then click Redeploy host again.";
                EditorUtility.DisplayDialog(
                    "Redeploy host is blocked",
                    mcpGuidance + " The Manager never terminates external client processes.",
                    "OK");
                return BuildPreEffectManagerDecision(
                    4,
                    preflightResult.StandardOutput,
                    mcpGuidance,
                    preflightResult.ElapsedMilliseconds);
            }

            var stopLegacyWatcher = hostPayload.LegacyWatcherCount > 0;
            var watcherGuidance = stopLegacyWatcher
                ? "CodeDB is currently running. The Manager will stop the legacy watcher gracefully, replace the recognized package-owned Host files, and configure the current Host generation. "
                : "If the legacy watcher starts before Redeploy runs, the Manager will stop it gracefully. ";
            if (!EditorUtility.DisplayDialog(
                    "Redeploy legacy CodeDB host",
                    watcherGuidance
                    + "Replace only byte-exact package-owned legacy Host files with the current generation and regenerate the ignored runtime config? "
                    + "The Provider executable, indexes, Shader adapter, MCP registration, business Assets, unowned files, and version-control metadata are preserved. "
                    + "Any drift, unexpected generation state, or new active owner will stop the operation.",
                    stopLegacyWatcher ? "Stop and Redeploy" : "Redeploy Host",
                    "Cancel"))
            {
                return BuildCancelledHostPayloadRedeployResult(preflightResult);
            }

            return await Task.Run(() => AICodedbActions.RunHostPayloadRedeploy(true));
        }

        internal static AICodedbCommandResult BuildCancelledHostPayloadRedeployResult(
            AICodedbCommandResult preflightResult)
        {
            return BuildPreEffectManagerDecision(
                1,
                preflightResult == null ? string.Empty : preflightResult.StandardOutput,
                "Host Payload Redeploy was cancelled by the user.",
                preflightResult == null ? 0 : preflightResult.ElapsedMilliseconds);
        }

        private static AICodedbCommandResult BuildPreEffectManagerDecision(
            int exitCode, string output, string detail, long elapsedMilliseconds,
            string actionId = null)
        {
            return new AICodedbCommandResult(exitCode, output, detail, false,
                elapsedMilliseconds, false, false, actionId ?? AICodedbPaths.CurrentActionId,
                false, AICodedbManagerActionEvidenceKind.PreEffectRefusal);
        }

        private void RunHostPayloadRemoveWithConfirmation()
        {
            if (!EditorUtility.DisplayDialog(
                    "Remove package-managed host files",
                    "Remove only files proven byte-exact and owned by the installed CodeDB marker, its validated selected generation, and CodeDB pointers? "
                    + "Provider data, MCP client configuration, business Assets, unrelated generations, unrelated Host files, and version-control metadata are outside this action. "
                    + "Unknown content or drift blocks the operation without deletion.",
                    "Remove Host Files",
                    "Cancel"))
            {
                return;
            }

            RunAction("Host Payload Remove", AICodedbActions.RunHostPayloadRemove);
        }

        private static AICodedbCommandResult RunLanguageCustomProbe(string query, string language)
        {
            if (string.IsNullOrEmpty(query))
                return new AICodedbCommandResult(-1, string.Empty, "Language Custom Probe text is empty.", false);

            if (string.Equals(language, "ShaderHlsl", StringComparison.Ordinal))
                return AICodedbActions.RunShaderAdapterSearch(query);
            return AICodedbActions.RunProviderCustomProbe(language, query);
        }

        private void RunAction(string title, Func<AICodedbCommandResult> action)
        {
            if (_userActionInFlight || action == null)
                return;

            // Diagnostics and watcher controls use the same asynchronous
            // command lane as ordinary user actions. The callback only queues
            // work and paints cached progress; PowerShell/Node/IPC work stays
            // off Unity's main thread.
            RunUserActionAsync(
                title,
                _ => Task.Run(action));
        }

        private void RunSupervisorMaintenanceAction(string title, string action)
        {
            RunUserActionAsync(
                title,
                _ => AICodedbEditorLifecycle.RunSupervisorMaintenanceCommandAsync(action),
                requestReconcileAfterAction: true,
                refreshStatusAfterAction: false);
        }

        private static bool IsSupervisorAction(string title)
        {
            switch (title)
            {
                case "Refresh If Stale":
                case "Refresh Index":
                case "Build Shader Adapter":
                case "Clean Index":
                case "Rebuild Index":
                case "Start Now":
                case "Stop Now":
                case "Restart":
                case "Enable Start with Unity Editor":
                case "Disable Start with Unity Editor":
                case "Install CodeDB":
                case "Uninstall CodeDB from Project":
                    return true;
                default:
                    return false;
            }
        }

        private static bool IsDualRouteAction(string title)
        {
            return title == "Install CodeDB" || title == "Uninstall CodeDB from Project";
        }

        private static bool IsDirectOnlyAction(string title)
        {
            switch (title)
            {
                case "Remove CodeDB Integration":
                case "Configure CodeDB Dependencies":
                case "Host Payload DryRun":
                case "Host Payload Verify":
                case "Host Payload Upgrade":
                case "Host Payload Redeploy":
                case "Host Payload Sync":
                case "Host Payload Remove":
                case "Provider Guidance":
                case "Verify Runtime":
                case "Prepare Runtime":
                case "Regenerate Runtime Config":
                case "Check Freshness":
                case "Runtime Health":
                case "Unity Project Smoke":
                case "Language Probe":
                case "C# Probe":
                case "Shader Adapter Probe":
                case "Project Config Validation":
                case "Registration Draft":
                case "Language Custom Probe":
                    return true;
                default:
                    return false;
            }
        }

        private static AICodedbCommandResult UnconfirmedActionResult(string actionId, string detail)
        {
            return new AICodedbCommandResult(4, string.Empty, detail, false,
                0, false, false, actionId, false,
                AICodedbManagerActionEvidenceKind.Indeterminate);
        }

        private static async Task<AICodedbCommandResult> ResolveActionEvidenceAsync(
            AICodedbManagerActionSession session, AICodedbCommandResult reported)
        {
            if (reported != null
                && reported.ManagerActionEvidenceKind == AICodedbManagerActionEvidenceKind.PreEffectRefusal
                && string.Equals(reported.ActionId, session.ActionId, StringComparison.Ordinal))
                return reported;

            var direct = await Task.Run(() => AICodedbProcessRunner.RecoverManagerAction(
                session.Context, session.ActionId, session.StorageLayout));
            if (direct.State == AICodedbManagerActionRecoveryState.Conflict
                || direct.State == AICodedbManagerActionRecoveryState.Pending)
                return UnconfirmedActionResult(session.ActionId, direct.Detail);

            if (direct.State == AICodedbManagerActionRecoveryState.PreEffectRefusal)
                return direct.Result;

            if (IsSupervisorAction(session.Title))
            {
                var supervisor = await AICodedbEditorLifecycle.RecoverManagerActionAsync(
                    session.Context, session.ActionId);
                if (direct.State == AICodedbManagerActionRecoveryState.Terminal
                    && supervisor.State == AICodedbManagerActionRecoveryState.Terminal)
                    return UnconfirmedActionResult(session.ActionId,
                        "Both direct writer and Supervisor claim the same action; neither result was adopted.");
                if (direct.State == AICodedbManagerActionRecoveryState.Terminal)
                    return IsDualRouteAction(session.Title) ? direct.Result
                        : UnconfirmedActionResult(session.ActionId,
                            "A Supervisor-owned action has an unexpected direct writer terminal.");
                if (supervisor.State == AICodedbManagerActionRecoveryState.Terminal)
                    return supervisor.Result;
                return UnconfirmedActionResult(session.ActionId,
                    "No authenticated Supervisor terminal is available: " + supervisor.Detail);
            }

            return direct.State == AICodedbManagerActionRecoveryState.Terminal
                ? direct.Result
                : UnconfirmedActionResult(session.ActionId,
                    "No authenticated one-shot writer terminal is available: " + direct.Detail);
        }

        private void RunUserActionAsync(
            string title,
            Func<Task<AICodedbCommandResult>> action,
            bool requestReconcileAfterAction = true)
        {
            if (action == null)
                return;

            RunUserActionAsync(
                title,
                progressLine => action(),
                requestReconcileAfterAction);
        }

        private async void RunUserActionAsync(
            string title,
            Func<Action<string>, Task<AICodedbCommandResult>> action,
            bool requestReconcileAfterAction = true,
            bool refreshStatusAfterAction = true)
        {
            await RunUserActionAsync(
                title,
                action,
                null,
                requestReconcileAfterAction,
                refreshStatusAfterAction);
        }

        private async Task RunUserActionAsync(
            string title,
            Func<Action<string>, Task<AICodedbCommandResult>> action,
            Func<AICodedbCommandResult, Task<AICodedbCommandResult>> continueOnMainThread,
            bool requestReconcileAfterAction = true,
            bool refreshStatusAfterAction = true)
        {
            if (action == null
                || !AICodedbManagerActionSession.TryStart(
                    title,
                    _executionContext,
                    EditorApplication.timeSinceStartup,
                    out var session))
                return;

            // These two local/read-only controls do not dispatch a durable
            // writer or Supervisor operation.
            var durable = title != "Automatic Host Updates" && title != "Watcher Status";
            if (durable)
            {
                var durableIndex = session.DurableIndex;
                var admission = await Task.Run(() =>
                {
                    // Fresh read-only evidence for this dispatch; no UI-cached
                    // classification is passed as a reusable write permit.
                    var effects = AICodedbRetainedEffectsObservation.Parse(
                        AICodedbHostPayloadMaterializer.ReadStatus(durableIndex.Context), durableIndex.Context);
                    var admitted = AICodedbManagerActionJournal.TryAdmit(durableIndex, out var detail, effects);
                    return new { Admitted = admitted, Detail = detail };
                });
                if (!admission.Admitted)
                {
                    var read = await Task.Run(() => AICodedbManagerActionJournal.Read(session.Context));
                    if (read.State == AICodedbManagerActionIndexState.Empty)
                    {
                        session.CompletePreEffectRefusal(admission.Detail, EditorApplication.timeSinceStartup);
                    }
                    else
                    {
                        session.AbortBeforeAdmission();
                        AICodedbManagerActionSession.RestoreDurable(session.Context, read,
                            EditorApplication.timeSinceStartup);
                    }
                    AttachCurrentActionSession();
                    Repaint();
                    return;
                }
                session.MarkDurableAdmitted();
            }

            InvalidateReadySnapshot(_executionContext.ProjectRoot);
            _transientStatusRefreshAttempts = 0;
            _transientStatusRefreshPending = false;
            _userActionInFlight = true;
            _nextUserActionRepaintAt = EditorApplication.timeSinceStartup;
            var actionStatus = session.Status;
            _userActionStatus = actionStatus;
            _lastResultTitle = title;
            GetActivityPanel().ResetForRunningAction();
            ShowUserActionNotification(actionStatus.BuildPresentation(EditorApplication.timeSinceStartup));
            Repaint();
            AICodedbCommandResult result;
            AICodedbManagerDispatchTracker dispatchTracker;
            var returnedNormally = false;
            using (AICodedbPaths.UseActionContext(
                       session.Context, durable ? session.ActionId : string.Empty,
                       session.EffectClass, session.AuthorizationSource))
            {
                dispatchTracker = AICodedbPaths.CurrentActionDispatchTracker;
                try
                {
                    result = await action(line => { actionStatus.UpdateProgressLine(line); });
                    session.RecordInitialCommandResult(result);
                    if (continueOnMainThread != null && this != null)
                        result = await continueOnMainThread(result);
                    returnedNormally = true;
                }
                catch (Exception exception)
                {
                    result = new AICodedbCommandResult(
                        -1,
                        string.Empty,
                        exception.Message,
                        false, 0, false, false, session.ActionId, false,
                        AICodedbManagerActionEvidenceKind.Indeterminate);
                }
            }
            if (durable)
            {
                if (returnedNormally && result != null && !result.Succeeded
                    && result.ManagerActionEvidenceKind == AICodedbManagerActionEvidenceKind.Indeterminate
                    && !dispatchTracker.DirectWriterDispatchAttempted
                    && IsDirectOnlyAction(title))
                    result = BuildPreEffectManagerDecision(result.ExitCode,
                        result.StandardOutput, result.StandardError,
                        result.ElapsedMilliseconds, session.ActionId);
                try
                {
                    result = await ResolveActionEvidenceAsync(session, result);
                }
                catch (Exception exception)
                {
                    result = UnconfirmedActionResult(session.ActionId,
                        "Exact action evidence lookup failed: " + exception.Message);
                }
            }
            if (durable && result != null
                && ((result.HasAuthoritativeTerminalEvidence && result.TerminalForManagerAction)
                    || result.ManagerActionEvidenceKind == AICodedbManagerActionEvidenceKind.PreEffectRefusal)
                && string.Equals(result.ActionId, session.ActionId, StringComparison.Ordinal))
            {
                await Task.Run(() => session.TryReleaseDurableIndex(result, out var _));
            }
            if (this == null)
            {
                session.FinishAfterWindowClose(result, EditorApplication.timeSinceStartup);
                if (requestReconcileAfterAction && !session.IsRecovering
                    && CanRequestActionReconcile(title, result))
                    AICodedbEditorLifecycle.RequestReconcile();
                return;
            }
            _lastResult = AICodedbManagerActionSession.SelectDisplayResult(result, session.InitialCommandResult);
            GetActivityPanel().ResetForNewResult(_lastResult, _lastResultTitle);
            // Command progress ends independently of the read-only observation.
            session.Complete(result, _statusSnapshot == null
                ? AICodedbProductState.Starting : _statusSnapshot.ProductStatus.State,
                false, EditorApplication.timeSinceStartup);
            _userActionInFlight = false;
            Repaint();
            var statusRefreshSucceeded = session.PostActionProductState.HasValue;
            try
            {
                if (refreshStatusAfterAction)
                {
                    _postCommandStatusObservationInFlight = true;
                    _postCommandStatusObservationDetail = "Observing current product status (at most 5000 ms); command progress has ended.";
                    statusRefreshSucceeded = await RefreshStatusAsync(_lastResult);
                }
            }
            catch (Exception exception)
            {
                statusRefreshSucceeded = false;
                Debug.LogWarning("CodeDB Manager status refresh after action failed: " + exception.Message);
            }
            finally
            {
                _postCommandStatusObservationInFlight = false;
                _postCommandStatusObservationDetail = statusRefreshSucceeded ? string.Empty
                    : "Current product status observation is unavailable; recorded command result and next-change permission remain independent.";
            }

            if (this == null)
            {
                session.FinishAfterWindowClose(result, EditorApplication.timeSinceStartup);
                if (requestReconcileAfterAction && !session.IsRecovering
                    && CanRequestActionReconcile(title, result))
                    AICodedbEditorLifecycle.RequestReconcile();
                return;
            }

            session.RecordStatusObservation(statusRefreshSucceeded);
            ShowUserActionNotification(actionStatus.BuildPresentation(EditorApplication.timeSinceStartup));
            if (requestReconcileAfterAction && !session.IsRecovering
                && CanRequestActionReconcile(title, result))
                AICodedbEditorLifecycle.RequestReconcile();
            Repaint();
        }

        internal static bool CanRequestActionReconcile(string title, AICodedbCommandResult result)
        {
            return title.StartsWith("Install CodeDB", StringComparison.Ordinal)
                ? AICodedbActions.CanRequestInstallReconcile(result)
                : AICodedbManagerActionSession.CanRequestPostCommandReconcile(result);
        }

        private void DrawActivityPanel(AICodedbManagerLayoutMetrics layout)
        {
            if (GetActivityPanel().Draw(
                    _lastResult,
                    _lastResultTitle,
                    GetUserActionPresentation(),
                    layout))
            {
                if (AICodedbManagerActionSession.ClearCompleted())
                {
                    _lastResult = null;
                    _lastResultTitle = string.Empty;
                    GetUserActionStatus().Clear();
                }
            }
        }

        private AICodedbActivityPanel GetActivityPanel()
        {
            return _activityPanel ?? (_activityPanel = new AICodedbActivityPanel());
        }

        private AICodedbUserActionStatus GetUserActionStatus()
        {
            return _userActionStatus ?? (_userActionStatus = new AICodedbUserActionStatus());
        }

        private AICodedbUserActionPresentation GetUserActionPresentation()
        {
            return GetUserActionStatus().BuildPresentation(EditorApplication.timeSinceStartup);
        }

        private void DrawUserActionStatus(AICodedbUserActionPresentation presentation)
        {
            if (_postCommandStatusObservationInFlight || !string.IsNullOrEmpty(_postCommandStatusObservationDetail))
                EditorGUILayout.HelpBox(_postCommandStatusObservationDetail, MessageType.Info);
            using (new EditorGUILayout.HorizontalScope(
                       EditorStyles.helpBox,
                       GUILayout.Height(UserActionStatusHeight),
                       GUILayout.ExpandWidth(true)))
            {
                GUILayout.Label(
                    "\u25cf",
                    AICodedbManagerStyles.GetStateDotStyle(presentation.State),
                    GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                    GUILayout.Height(28f));
                using (new EditorGUILayout.VerticalScope())
                {
                    EditorGUILayout.LabelField(
                        GetUserActionStatus().Title,
                        AICodedbManagerStyles.RowTitle,
                        GUILayout.Height(18f));
                    EditorGUILayout.LabelField(
                        presentation.Detail,
                        AICodedbManagerStyles.RowDescription,
                        GUILayout.Height(18f));
                }

                GUILayout.FlexibleSpace();
                using (new EditorGUILayout.VerticalScope(GUILayout.Width(220f)))
                {
                    EditorGUILayout.LabelField(presentation.StatusLabel, EditorStyles.boldLabel);
                    EditorGUILayout.LabelField(presentation.ElapsedText, AICodedbManagerStyles.DisclosureSummary);
                }
            }
        }

        private void ShowUserActionNotification(AICodedbUserActionPresentation presentation)
        {
            if (!string.IsNullOrWhiteSpace(presentation.NotificationText))
                ShowNotification(new GUIContent(presentation.NotificationText));
        }

        private void ScheduleWatcherStatusRefresh()
        {
            if (_watcherRefreshScheduled)
                return;
            AICodedbLifecycleEvidence.RecordManagerWatcherStatusRequest();
            _watcherRefreshScheduled = true;
            EditorApplication.delayCall += RefreshWatcherStatusDelayed;
        }

        private void RefreshWatcherStatusDelayed()
        {
            _watcherRefreshScheduled = false;
            if (this == null)
                return;
            RefreshWatcherStatusSilentlyAsync();
        }

        private async void RefreshWatcherStatusSilentlyAsync()
        {
            if (_watcherStatusRefreshInFlight
                || EditorApplication.isCompiling
                || EditorApplication.isUpdating
                || IsPlayModeDisplaySuspended())
            {
                return;
            }
            _watcherStatusRefreshInFlight = true;
            try
            {
                var result = await AICodedbActions.RunWatcherStatusAsync();
                if (this == null)
                    return;
                _watcherStatus = AICodedbWatcherStatusBuilder.Build(result);
                _watcherStatusLoaded = true;
                ApplyWatcherDisclosurePolicy();
                Repaint();
            }
            catch (Exception exception)
            {
                if (this != null)
                    Debug.LogWarning("CodeDB Manager watcher status refresh failed: " + exception.Message);
            }
            finally
            {
                _watcherStatusRefreshInFlight = false;
            }
        }

        private void ApplyDisclosurePolicy(bool initialize)
        {
            if (initialize)
            {
                _showOverviewDetails = false;
                _showProviderGuidance = false;
                _showAdvancedHostFiles = false;
                _showIndexDiagnostics = false;
                _showIndexMaintenance = false;
                _showMcpSnippet = false;
                _showMcpPolicy = false;
                _showRestrictedCapabilities = false;
                _showPolicyDetails = false;
            }
        }

        private void ApplyWatcherDisclosurePolicy()
        {
            // Diagnostics remain opt-in for ordinary users; watcher details are
            // still available by expanding the Index diagnostics disclosure.
        }

        private AICodedbStatusState GetWatcherDisplayState()
        {
            return _watcherStatusLoaded ? _watcherStatus.DisplayState : AICodedbStatusState.Inactive;
        }

        private string GetWatcherLabel()
        {
            return _watcherStatusLoaded ? _watcherStatus.Label : "Checking...";
        }

        private string GetWatcherDescription()
        {
            return _watcherStatusLoaded
                ? _watcherStatus.Detail
                : "Reading the project-local automatic-refresh state.";
        }

        private string GetWatcherRepairLabel()
        {
            if (!_watcherStatusLoaded)
                return string.Empty;
            return ResolveWatcherRepairLabel(
                _statusSnapshot.HostGenerationSelection.State,
                _watcherStatus.State);
        }

        internal static bool CanUseLifecycleControls(AICodedbHostGenerationState generationState)
        {
            return generationState == AICodedbHostGenerationState.Current;
        }

        internal static bool CanUseHostCommands(AICodedbHostGenerationState generationState)
        {
            return generationState == AICodedbHostGenerationState.Current;
        }

        private Action GetHostAction(Action action)
        {
            return !_userActionInFlight
                   && CanUseHostCommands(_statusSnapshot.HostGenerationSelection.State)
                ? action
                : null;
        }

        internal static string ResolveWatcherRepairLabel(
            AICodedbHostGenerationState generationState,
            AICodedbWatcherState watcherState)
        {
            if (!CanUseLifecycleControls(generationState))
                return string.Empty;
            switch (watcherState)
            {
                case AICodedbWatcherState.Stale:
                    return "Repair watcher";
                case AICodedbWatcherState.DisabledRunning:
                    return "Pause watcher";
                case AICodedbWatcherState.Unknown:
                case AICodedbWatcherState.Error:
                    return "Check watcher";
                default:
                    return string.Empty;
            }
        }

        private Action GetWatcherRepairAction()
        {
            if (!CanUseLifecycleControls(_statusSnapshot.HostGenerationSelection.State))
                return null;
            switch (_watcherStatus.State)
            {
                case AICodedbWatcherState.Stale:
                    return () => RunAction("Restart", AICodedbActions.RunRestartWatcher);
                case AICodedbWatcherState.DisabledRunning:
                    return () => RunAction("Disable Start with Unity Editor", AICodedbActions.RunDisableWatcher);
                default:
                    return () => RunAction("Watcher Status", AICodedbActions.RunWatcherStatus);
            }
        }

        private void DrawActivityResizeHandle(float availableWidth)
        {
            GUILayout.Box(
                GUIContent.none,
                GUIStyle.none,
                GUILayout.Width(AICodedbManagerLayout.SplitterWidth),
                GUILayout.ExpandHeight(true));
            var splitterRect = GUILayoutUtility.GetLastRect();
            var controlId = GUIUtility.GetControlID(FocusType.Passive, splitterRect);
            var currentEvent = Event.current;
            EditorGUIUtility.AddCursorRect(splitterRect, MouseCursor.ResizeHorizontal, controlId);

            switch (currentEvent.GetTypeForControl(controlId))
            {
                case EventType.MouseDown:
                    if (currentEvent.button == 0 && splitterRect.Contains(currentEvent.mousePosition))
                    {
                        GUIUtility.hotControl = controlId;
                        _activityResizeStartMouseX = currentEvent.mousePosition.x;
                        _activityResizeStartWidth = _activitySidebarWidth;
                        currentEvent.Use();
                    }
                    break;
                case EventType.MouseDrag:
                    if (GUIUtility.hotControl == controlId)
                    {
                        var mouseDeltaX = currentEvent.mousePosition.x - _activityResizeStartMouseX;
                        _activitySidebarWidth = AICodedbManagerLayout.ClampActivityWidth(
                            _activityResizeStartWidth - mouseDeltaX,
                            availableWidth);
                        Repaint();
                        currentEvent.Use();
                    }
                    break;
                case EventType.MouseUp:
                case EventType.MouseLeaveWindow:
                    if (GUIUtility.hotControl == controlId)
                    {
                        GUIUtility.hotControl = 0;
                        EditorPrefs.SetFloat(ActivitySidebarWidthPrefsKey, _activitySidebarWidth);
                        currentEvent.Use();
                    }
                    break;
                case EventType.Repaint:
                    DrawActivityResizeHandleVisual(
                        splitterRect,
                        GUIUtility.hotControl == controlId,
                        splitterRect.Contains(currentEvent.mousePosition));
                    break;
            }
        }

        private static void DrawActivityResizeHandleVisual(Rect splitterRect, bool isDragging, bool isHovering)
        {
            var handleRect = new Rect(
                splitterRect.x + Mathf.Floor((splitterRect.width - 1f) * 0.5f),
                splitterRect.y + 2f,
                1f,
                Mathf.Max(0f, splitterRect.height - 4f));
            var color = isDragging
                ? new Color(0.45f, 0.62f, 0.82f, 0.95f)
                : isHovering
                    ? new Color(0.5f, 0.5f, 0.5f, 0.9f)
                    : new Color(0.42f, 0.42f, 0.42f, 0.75f);
            EditorGUI.DrawRect(handleRect, color);
        }

        private void SelectTab(AICodedbManagerTab tab)
        {
            using (AICodedbLifecycleEvidence.BeginCallback(AICodedbLifecycleCallbackKind.ManagerTabChanged))
            {
                AICodedbLifecycleEvidence.RecordManagerObservation(AICodedbManagerObservationKind.TabChange);
                _selectedTab = (int)tab;
                _scrollPosition = Vector2.zero;
                Repaint();
            }
        }

        private string GetHeaderTitle()
        {
            if (TryGetActionStatusOverride(out var presentation))
                return GetActionStatusTitle(presentation);
            return _statusSnapshot.OverallTitle;
        }

        private string GetHeaderDescription()
        {
            if (TryGetActionStatusOverride(out var presentation))
                return GetActionStatusDescription(presentation);
            return _statusSnapshot.OverallDescription;
        }

        private string GetOverviewStatusTitle()
        {
            if (TryGetActionStatusOverride(out var presentation))
                return GetActionStatusTitle(presentation);
            switch (_statusSnapshot.ProductStatus.State)
            {
                case AICodedbProductState.Ready:
                    return "CodeDB is ready";
                case AICodedbProductState.Starting:
                    return "CodeDB is starting";
                case AICodedbProductState.Uninstalled:
                    return "CodeDB is uninstalled";
                case AICodedbProductState.NotIntegrated:
                    return "CodeDB is not installed in this project";
                case AICodedbProductState.MissingPrerequisite:
                    return "CodeDB needs a prerequisite";
                default:
                    return "CodeDB needs attention";
            }
        }

        private string GetOverviewStatusDescription()
        {
            if (TryGetActionStatusOverride(out var presentation))
                return GetActionStatusDescription(presentation);
            if (_statusSnapshot.ProductStatus.RequiresReinstall)
                return IsRemoveIntegrationMenuAvailable(GetRemovalPresentationStatus())
                    ? "This integration cannot run under the current Package. Its removal authority is verified; uninstall the project integration, then install it fresh."
                    : "This integration cannot run under the current Package. Removal requires review before any project state changes.";
            return _statusSnapshot.OverallDescription;
        }

        private AICodedbStatusState GetDisplayedProductState()
        {
            return TryGetActionStatusOverride(out _)
                ? AICodedbStatusState.Warning
                : _statusSnapshot.OverallState;
        }

        private bool TryGetActionStatusOverride(out AICodedbUserActionPresentation presentation)
        {
            presentation = default(AICodedbUserActionPresentation);
            if (_userActionStatus == null)
                return false;
            presentation = GetUserActionPresentation();
            return ShouldOverrideProductStatus(_userActionStatus.Phase,
                presentation, _userActionStatus.HasFreshProductState);
        }

        internal static bool ShouldOverrideProductStatus(AICodedbUserActionPhase phase,
            AICodedbUserActionPresentation presentation, bool hasFreshProductState)
        {
            // Recovery remains visible as history and keeps mutation admission
            // blocked, but is not a current product-status classification.
            return phase != AICodedbUserActionPhase.Recovery && (presentation.IsRunning
                   || (phase == AICodedbUserActionPhase.Completed
                       && presentation.State == AICodedbStatusState.Warning)
                   || (phase == AICodedbUserActionPhase.Failed && !hasFreshProductState));
        }

        private string GetActionStatusDescription(AICodedbUserActionPresentation presentation)
        {
            return _userActionStatus.Phase == AICodedbUserActionPhase.Failed
                   && !_userActionStatus.HasFreshProductState
                ? "The command failed and current CodeDB status is unavailable."
                : presentation.Detail;
        }

        private static string GetActionStatusTitle(AICodedbUserActionPresentation presentation)
        {
            if (presentation.IsRunning)
                return "CodeDB action in progress";
            if (string.Equals(presentation.StatusLabel, "Completed - needs attention",
                    StringComparison.Ordinal))
                return "CodeDB needs attention";
            return "CodeDB status unconfirmed";
        }

        private string GetHostPayloadLabel()
        {
            switch (_statusSnapshot.HostPayloadStatus.State)
            {
                case AICodedbHostPayloadState.Current:
                    return "Current";
                case AICodedbHostPayloadState.Draining:
                    return "Ready / Draining";
                case AICodedbHostPayloadState.UpgradeReady:
                    return "UPGRADE_READY";
                case AICodedbHostPayloadState.RedeployRequired:
                    return "REDEPLOY_REQUIRED";
                case AICodedbHostPayloadState.SetupRequired:
                    return "SETUP_REQUIRED";
                case AICodedbHostPayloadState.UpdateRequired:
                    return "UPDATE_REQUIRED";
                case AICodedbHostPayloadState.Conflict:
                    return "CONFLICT";
                case AICodedbHostPayloadState.Blocked:
                    return "BLOCKED";
                default:
                    return "Unknown";
            }
        }

        private string GetHostPayloadSummary()
        {
            var protection = _statusSnapshot.HostPayloadStatus.IsCurrent
                ? " · protected"
                : string.Empty;
            var ownerCount = _statusSnapshot.HostPayloadStatus.ActiveOwners.Length;
            var owners = ownerCount > 0 ? " · " + ownerCount + " active owner" + (ownerCount == 1 ? string.Empty : "s") : string.Empty;
            return GetHostPayloadLabel() + protection + owners;
        }

        private static string GetStateLabel(AICodedbStatusState state, string okLabel)
        {
            switch (state)
            {
                case AICodedbStatusState.Ok:
                    return okLabel;
                case AICodedbStatusState.Inactive:
                    return "Inactive";
                case AICodedbStatusState.Warning:
                    return "Needs attention";
                case AICodedbStatusState.Error:
                    return "Error";
                default:
                    return "Unknown";
            }
        }
    }

    // Presentation boundary only: Lifecycle/Bridge remains the product-state
    // authority. Captured off the main thread; comparisons never touch disk.
    internal sealed class AICodedbManagerStatusBoundary
    {
        private const double ReadyObservationFreshnessSeconds = 30d;
        private readonly AICodedbEditorExecutionContext _context;
        private readonly string _generationId;
        private readonly string _contractSha256;
        private readonly string _runtimePath;

        internal AICodedbManagerStatusBoundary(AICodedbEditorExecutionContext context,
            string generationId, string contractSha256, string runtimePath)
        {
            _context = context;
            _generationId = generationId;
            _contractSha256 = contractSha256;
            _runtimePath = runtimePath;
        }

        internal static AICodedbManagerStatusBoundary Capture(AICodedbEditorExecutionContext context)
        {
            var contract = AICodedbPackageRuntimeContractStore.Read(context.PackageRoot);
            return new AICodedbManagerStatusBoundary(context, contract.Target.GenerationId,
                contract.Sha256, AICodedbSupervisorLauncher.GetSupervisorRuntimePath(
                    context.ProjectRoot, contract.ControlContract));
        }

        internal bool CanDisplay(AICodedbEditorExecutionContext context,
            AICodedbProductState state, bool hasProductStatus,
            AICodedbSupervisorSnapshot observation, DateTimeOffset now)
        {
            if (!AICodedbManagerWindow.IsSameStatusContext(_context, context))
                return false;
            if (observation != null && !string.IsNullOrWhiteSpace(observation.RuntimePath)
                && !SamePath(_runtimePath, observation.RuntimePath))
                return false;
            if (state != AICodedbProductState.Ready)
                return true;
            return observation != null && CanDisplayReadyEvidence(context,
                observation.RuntimePath, observation.TargetGenerationId,
                observation.RuntimeContractSha256,
                hasProductStatus && observation.IsCoreReady
                    && observation.HasOperationalReadinessObservation,
                observation.ObservedAtUtc, now);
        }

        internal bool CanDisplayReadyEvidence(AICodedbEditorExecutionContext context,
            string runtimePath, string generationId, string contractSha256,
            bool hasAuthenticatedProductReady, DateTimeOffset observedAt, DateTimeOffset now)
        {
            return AICodedbManagerWindow.IsSameStatusContext(_context, context)
                && hasAuthenticatedProductReady
                && !string.IsNullOrEmpty(_generationId) && !string.IsNullOrEmpty(_contractSha256)
                && SamePath(_runtimePath, runtimePath)
                && string.Equals(_generationId, generationId, StringComparison.Ordinal)
                && string.Equals(_contractSha256, contractSha256, StringComparison.Ordinal)
                && IsReadyObservationFresh(observedAt, now);
        }

        internal static bool IsReadyObservationFresh(DateTimeOffset observedAt, DateTimeOffset now)
        {
            return observedAt <= now
                && now - observedAt <= TimeSpan.FromSeconds(ReadyObservationFreshnessSeconds);
        }

        private static bool SamePath(string expected, string observed)
        {
            return !string.IsNullOrWhiteSpace(expected) && !string.IsNullOrWhiteSpace(observed)
                && string.Equals(expected.Replace('\\', '/').TrimEnd('/'),
                    observed.Replace('\\', '/').TrimEnd('/'), StringComparison.OrdinalIgnoreCase);
        }
    }

    internal sealed class AICodedbManagerActionSession
    {
        private const string PendingKeyPrefix = "Rice.AI.Codedb.Manager.PendingAction.";
        private static readonly object Gate = new object();
        private static AICodedbManagerActionSession _current;

        internal string ActionId { get; }
        internal string Title { get; }
        internal string EffectClass { get; }
        internal string AuthorizationSource { get; }
        internal AICodedbEditorExecutionContext Context { get; }
        internal AICodedbUserActionStatus Status { get; }
        internal AICodedbCommandResult Result { get; private set; }
        internal AICodedbCommandResult InitialCommandResult { get; private set; }
        internal string PostActionDetail { get; private set; } = string.Empty;
        internal AICodedbProductState? PostActionProductState { get; private set; }
        internal bool IsRunning { get; private set; }
        internal bool IsRecovering { get; private set; }
        internal bool IsEvidenceConflict { get; private set; }
        internal bool HasOriginalContext { get; private set; } = true;
        private bool _durableAdmitted;
        private bool _legacyReceipt;
        internal string StorageLayout { get; private set; } = AICodedbPaths.CompactReceiptLayout;
        internal AICodedbManagerActionIndex DurableIndex => new AICodedbManagerActionIndex(
            ActionId, Title, EffectClass, AuthorizationSource, Context, StorageLayout);

        private AICodedbManagerActionSession(
            string title,
            AICodedbEditorExecutionContext context,
            double now,
            string actionId,
            bool recovering)
        {
            ActionId = actionId;
            Title = title;
            Context = context;
            EffectClass = ClassifyEffect(title);
            AuthorizationSource = ClassifyAuthority(title);
            Status = new AICodedbUserActionStatus();
            if (recovering)
                Status.Recover(title, now);
            else
                Status.Start(title, now);
            IsRunning = !recovering;
            IsRecovering = recovering;
        }

        internal static bool TryStart(
            string title,
            AICodedbEditorExecutionContext context,
            double now,
            out AICodedbManagerActionSession session)
        {
            lock (Gate)
            {
                RestorePending(context, now);
                if (_current != null && (_current.IsRunning || _current.IsRecovering))
                {
                    session = null;
                    return false;
                }

                var candidate = new AICodedbManagerActionSession(
                    title, context, now, Guid.NewGuid().ToString("N"), false);
                SessionState.SetString(PendingKey(context),
                    candidate.ActionId + "|" + title + "|" + context.PackageRoot);
                session = candidate;
                _current = candidate;
                return true;
            }
        }

        internal static AICodedbManagerActionSession CurrentFor(AICodedbEditorExecutionContext context)
        {
            lock (Gate)
            {
                RestorePending(context, EditorApplication.timeSinceStartup);
                return _current != null
                       && string.Equals(_current.Context.ProjectRoot, context.ProjectRoot,
                           StringComparison.OrdinalIgnoreCase)
                    ? _current : null;
            }
        }

        internal static void RestoreDurable(AICodedbEditorExecutionContext currentContext,
            AICodedbManagerActionIndexRead read, double now)
        {
            lock (Gate)
            {
                if (_current != null && _current.IsRunning)
                    return;
                if (read.State == AICodedbManagerActionIndexState.Empty)
                {
                    if (read.EffectsObservation != null && read.EffectsObservation.Safe
                        && _current != null && !_current.IsRunning
                        && string.Equals(_current.Context.ProjectRoot, currentContext.ProjectRoot,
                            StringComparison.OrdinalIgnoreCase)
                        && (_current.IsEvidenceConflict && string.IsNullOrEmpty(_current.ActionId)
                            || Array.IndexOf(read.HistoricalActionIds, _current.ActionId) >= 0))
                    {
                        ClearSupersededPending(currentContext, _current.ActionId);
                        // No representative command result is manufactured for
                        // an aggregate. History remains in the journal warning.
                        _current = null;
                    }
                    if (read.EffectsObservation != null && read.EffectsObservation.Safe && _current == null)
                    {
                        var pendingId = ReadPendingActionId(currentContext);
                        if (Array.IndexOf(read.HistoricalActionIds, pendingId) >= 0)
                            ClearSupersededPending(currentContext, pendingId);
                    }
                    if (read.EffectsObservation != null)
                        return; // observations never manufacture or select a historical command session
                    if (read.HistoricalResult != null && read.Index != null
                        && (_current == null || (!_current.IsRunning
                            && string.Equals(_current.Context.ProjectRoot, currentContext.ProjectRoot,
                                StringComparison.OrdinalIgnoreCase))))
                    {
                        var superseded = _current;
                        var supersededActionId = superseded != null && superseded.IsRecovering
                            ? superseded.ActionId
                            : ReadPendingActionId(currentContext);
                        // A durable retained result is the source of truth after a
                        // reload. Replace any stale recovering SessionState action
                        // for this project, even when its action id is different.
                        _current = new AICodedbManagerActionSession(read.Index.Title,
                            read.Index.Context, now, read.Index.ActionId, true);
                        _current.StorageLayout = read.Index.StorageLayout;
                        if (_current.TryCompleteRecovery(read.HistoricalResult, now)
                            && AICodedbSupervisorProtocol.IsManagerActionId(supersededActionId)
                            && !string.Equals(supersededActionId, _current.ActionId,
                                StringComparison.Ordinal)
                            && (superseded == null || string.Equals(superseded.Context.ProjectRoot,
                                currentContext.ProjectRoot, StringComparison.OrdinalIgnoreCase)))
                            ClearSupersededPending(currentContext, supersededActionId);
                    }
                    return;
                }
                if (read.State == AICodedbManagerActionIndexState.Conflict)
                {
                    var prior = _current != null && _current.IsRecovering && _current.HasOriginalContext
                        && AICodedbSupervisorProtocol.IsManagerActionId(_current.ActionId)
                        && string.Equals(_current.ActionId, read.ActionId, StringComparison.Ordinal)
                        && string.Equals(_current.Context.ProjectRoot, currentContext.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                        ? _current : null;
                    var retainedId = AICodedbSupervisorProtocol.IsManagerActionId(read.ActionId)
                        ? read.ActionId : prior?.ActionId ?? string.Empty;
                    _current = new AICodedbManagerActionSession(
                        "Previous CodeDB action", read.Index?.Context ?? prior?.Context ?? currentContext,
                        now, retainedId, true);
                    _current.IsEvidenceConflict = true;
                    _current.HasOriginalContext = read.Index != null || prior != null;
                    _current.StorageLayout = read.Index?.StorageLayout ?? prior?.StorageLayout;
                    _current.Status.SetRecoveryDetail(read.Detail);
                    return;
                }
                if (_current != null && _current.IsRecovering
                    && string.Equals(_current.ActionId, read.Index.ActionId, StringComparison.Ordinal)
                    && string.Equals(_current.Context.PackageRoot,
                        read.Index.Context.PackageRoot, StringComparison.OrdinalIgnoreCase))
                {
                    _current._durableAdmitted = !read.IsLegacyReceipt;
                    _current._legacyReceipt = read.IsLegacyReceipt;
                    _current.StorageLayout = read.Index.StorageLayout;
                    return;
                }
                _current = new AICodedbManagerActionSession(read.Index.Title,
                    read.Index.Context, now, read.Index.ActionId, true);
                _current._durableAdmitted = !read.IsLegacyReceipt;
                _current._legacyReceipt = read.IsLegacyReceipt;
                _current.StorageLayout = read.Index.StorageLayout;
            }
        }

        internal void MarkDurableAdmitted()
        {
            _durableAdmitted = true;
            _legacyReceipt = false;
        }

        internal void AbortBeforeAdmission()
        {
            lock (Gate)
            {
                if (!ReferenceEquals(_current, this) || !IsRunning)
                    return;
                IsRunning = false;
                _current = null;
                if (SessionState.GetString(PendingKey(Context), string.Empty)
                    .StartsWith(ActionId + "|", StringComparison.Ordinal))
                    SessionState.SetString(PendingKey(Context), string.Empty);
            }
        }

        internal bool TryReleaseDurableIndex(AICodedbCommandResult result, out string detail)
        {
            var released = TryReleaseDurableIndexCore(result, out detail);
            DurableIndexReleased = released;
            DurableIndexReleaseDetail = released ? "The exact action index was released." : detail;
            return released;
        }

        internal bool? DurableIndexReleased { get; private set; }
        internal string DurableIndexReleaseDetail { get; private set; } = string.Empty;

        private bool TryReleaseDurableIndexCore(AICodedbCommandResult result, out string detail)
        {
            _durableIndexRetained = true;
            if (result == null || !string.Equals(result.ActionId, ActionId, StringComparison.Ordinal)
                || (result.ManagerActionEvidenceKind != AICodedbManagerActionEvidenceKind.PreEffectRefusal
                    && (!result.HasAuthoritativeTerminalEvidence || !result.TerminalForManagerAction)))
            {
                detail = "The original action has no authenticated final disposition.";
                return false;
            }
            if (RequiresRetainedAdmission(result))
            {
                detail = "The command result is retained; incomplete execution/output observation does not release admission.";
                return false;
            }
            if (_legacyReceipt)
            {
                _durableIndexRetained = false;
                detail = string.Empty;
                return true;
            }
            if (!_durableAdmitted)
            {
                detail = "The Manager action has no durable admission.";
                return false;
            }
            var disposition = result.ManagerActionEvidenceKind
                              == AICodedbManagerActionEvidenceKind.PreEffectRefusal
                ? AICodedbManagerActionEvidenceKind.PreEffectRefusal
                : AICodedbManagerActionEvidenceKind.CommandTerminal;
            var released = AICodedbManagerActionJournal.TryRelease(DurableIndex, disposition, out detail);
            _durableIndexRetained = !released;
            return released;
        }

        private bool _durableIndexRetained;

        internal static bool RequiresRetainedAdmission(AICodedbCommandResult result)
        {
            return result == null || result.TimedOut || result.OutputOverflow || result.OutputDrainIncomplete;
        }

        internal static AICodedbCommandResult SelectDisplayResult(
            AICodedbCommandResult resolved, AICodedbCommandResult reported)
        {
            return resolved != null && resolved.HasAuthoritativeTerminalEvidence ? resolved
                : reported != null && reported.HasAuthoritativeTerminalEvidence ? reported : resolved;
        }

        internal static bool CanRequestPostCommandReconcile(AICodedbCommandResult result)
        {
            return result != null && result.HasAuthoritativeTerminalEvidence
                && result.Succeeded && !RequiresRetainedAdmission(result);
        }

        internal void RecordStatusObservation(bool completed)
        {
            if (!completed)
                PostActionDetail = "Post-command status observation is unavailable or exceeded its 5000 ms budget; command outcome and change admission are independent.";
        }

        internal void CompletePreEffectRefusal(string detail, double now)
        {
            Complete(new AICodedbCommandResult(4, string.Empty, detail, false,
                    0, false, false, ActionId, false,
                    AICodedbManagerActionEvidenceKind.PreEffectRefusal),
                AICodedbProductState.Starting, false, now);
        }

        internal void Complete(
            AICodedbCommandResult result,
            AICodedbProductState productState,
            bool statusRefreshSucceeded,
            double now)
        {
            lock (Gate)
            {
                if (!ReferenceEquals(_current, this) || !IsRunning)
                    return;
                if (result == null || (_durableAdmitted
                    && (!string.Equals(result.ActionId, ActionId, StringComparison.Ordinal)
                        || (!result.TerminalForManagerAction
                            && result.ManagerActionEvidenceKind != AICodedbManagerActionEvidenceKind.PreEffectRefusal)))
                    || (!result.HasAuthoritativeTerminalEvidence
                    && result.ManagerActionEvidenceKind != AICodedbManagerActionEvidenceKind.PreEffectRefusal))
                {
                    Status.Recover(Title, now);
                    if (result != null)
                        Status.SetRecoveryDetail(result.StandardError);
                    IsRunning = false;
                    IsRecovering = true;
                    return;
                }
                Result = result;
                Status.Complete(result, PostActionProductState ?? productState,
                    statusRefreshSucceeded, now, PostActionDetail);
                IsRunning = false;
                IsRecovering = _durableIndexRetained;
                if (IsRecovering)
                    return;
                if (SessionState.GetString(PendingKey(Context), string.Empty)
                    .StartsWith(ActionId + "|", StringComparison.Ordinal))
                    SessionState.SetString(PendingKey(Context), string.Empty);
            }
        }

        internal void RecordInitialCommandResult(AICodedbCommandResult result)
        {
            InitialCommandResult = result;
        }

        internal void RecoverAfterWindowClose(AICodedbCommandResult result, double now)
        {
            lock (Gate)
            {
                if (!ReferenceEquals(_current, this) || !IsRunning)
                    return;
                Result = result;
                Status.Recover(Title, now);
                if (result != null)
                    Status.SetRecoveryDetail(result.StandardError);
                IsRunning = false;
                IsRecovering = true;
            }
        }

        internal void FinishAfterWindowClose(AICodedbCommandResult result, double now)
        {
            if (result == null || (_durableAdmitted
                && (!string.Equals(result.ActionId, ActionId, StringComparison.Ordinal)
                    || (!result.TerminalForManagerAction
                        && result.ManagerActionEvidenceKind != AICodedbManagerActionEvidenceKind.PreEffectRefusal)))
                || (!result.HasAuthoritativeTerminalEvidence
                && result.ManagerActionEvidenceKind != AICodedbManagerActionEvidenceKind.PreEffectRefusal))
                RecoverAfterWindowClose(result, now);
            else
                Complete(result, AICodedbProductState.Starting, false, now);
        }

        internal bool TryCompleteRecovery(AICodedbCommandResult result, double now)
        {
            lock (Gate)
            {
                if (!ReferenceEquals(_current, this) || !IsRecovering
                    || IsEvidenceConflict
                    || result == null || (!result.HasAuthoritativeTerminalEvidence
                        && result.ManagerActionEvidenceKind != AICodedbManagerActionEvidenceKind.PreEffectRefusal
                        && !result.FailedCandidateEffectsRetained)
                    || !string.Equals(result.ActionId, ActionId, StringComparison.Ordinal))
                    return false;
                Result = result;
                Status.Complete(result, AICodedbProductState.Starting, false, now);
                if (result.FailedCandidateEffectsRetained) _durableIndexRetained = false;
                IsRecovering = _durableIndexRetained;
                if (IsRecovering)
                    return true;
                if (SessionState.GetString(PendingKey(Context), string.Empty)
                    .StartsWith(ActionId + "|", StringComparison.Ordinal))
                    SessionState.SetString(PendingKey(Context), string.Empty);
                return true;
            }
        }

        internal bool CompleteRetainedEffectsRecovery(AICodedbCommandResult result, double now)
        {
            lock (Gate)
            {
                if (!ReferenceEquals(_current, this) || !IsRecovering || !HasOriginalContext
                    || result == null || !result.FailedCandidateEffectsRetained || result.ActionId != ActionId)
                    return false;
                IsEvidenceConflict = false;
                _durableIndexRetained = false;
                return TryCompleteRecovery(result, now);
            }
        }

        internal void SetRecoveryDetail(string detail)
        {
            if (IsRecovering)
                Status.SetRecoveryDetail(detail);
        }

        internal void RecordPostOutcome(AICodedbEditorLifecycle.AICodedbReconcileOutcome outcome)
        {
            if (outcome == null)
                return;
            PostActionDetail = outcome.Detail;
            switch (outcome.Disposition)
            {
                case AICodedbEditorLifecycle.AICodedbReconcileDisposition.Ready:
                    PostActionProductState = AICodedbProductState.Ready;
                    break;
                case AICodedbEditorLifecycle.AICodedbReconcileDisposition.Uninstalled:
                    PostActionProductState = AICodedbProductState.Uninstalled;
                    break;
                case AICodedbEditorLifecycle.AICodedbReconcileDisposition.MissingPrerequisite:
                    PostActionProductState = AICodedbProductState.MissingPrerequisite;
                    break;
                case AICodedbEditorLifecycle.AICodedbReconcileDisposition.NeedsAttention:
                    PostActionProductState = AICodedbProductState.NeedsAttention;
                    break;
                default:
                    PostActionProductState = AICodedbProductState.Starting;
                    break;
            }
        }

        internal static bool ClearCompleted()
        {
            lock (Gate)
            {
                if (_current == null)
                    return true;
                if (_current.IsRecovering)
                {
                    // Keep the durable pending marker so the next admission
                    // restores Recovery instead of creating a second owner.
                    _current = null;
                    return false;
                }
                if (_current.IsRunning)
                    return false;
                _current = null;
                return true;
            }
        }

        private static void RestorePending(AICodedbEditorExecutionContext context, double now)
        {
            if (_current != null && (_current.IsRunning || _current.IsRecovering))
                return;
            var pending = SessionState.GetString(PendingKey(context), string.Empty);
            if (string.IsNullOrEmpty(pending))
                return;
            var parts = pending.Split(new[] { '|' }, 3);
            if (parts.Length != 3 || !Guid.TryParseExact(parts[0], "N", out _))
            {
                _current = new AICodedbManagerActionSession(
                    "Previous CodeDB action", context, now, string.Empty, true);
                return;
            }
            var originalContext = new AICodedbEditorExecutionContext(context.Platform,
                context.ProjectRoot, parts[2], context.ProjectDisplayName);
            _current = new AICodedbManagerActionSession(
                parts[1], originalContext, now, parts[0], true);
        }

        private static void ClearSupersededPending(
            AICodedbEditorExecutionContext context, string supersededActionId)
        {
            if (!AICodedbSupervisorProtocol.IsManagerActionId(supersededActionId))
                return;
            var key = PendingKey(context);
            var pending = SessionState.GetString(key, string.Empty);
            if (pending.StartsWith(supersededActionId + "|", StringComparison.Ordinal))
                SessionState.SetString(key, string.Empty);
        }

        private static string ReadPendingActionId(AICodedbEditorExecutionContext context)
        {
            var pending = SessionState.GetString(PendingKey(context), string.Empty);
            var parts = pending.Split(new[] { '|' }, 3);
            return parts.Length == 3 && AICodedbSupervisorProtocol.IsManagerActionId(parts[0])
                ? parts[0] : string.Empty;
        }

        private static string PendingKey(AICodedbEditorExecutionContext context)
        {
            return PendingKeyPrefix + context.ProjectRoot;
        }

        internal static string ClassifyEffect(string title)
        {
            switch (title)
            {
                case "Host Payload DryRun":
                case "Host Payload Verify":
                    return "Observation";
                case "Host Payload Upgrade":
                    return "LifecycleMutation";
                case "Configure CodeDB Dependencies":
                    return "ProviderInstallation";
                case "Host Payload Redeploy":
                case "Host Payload Sync":
                case "Host Payload Remove":
                case "Install CodeDB":
                case "Uninstall CodeDB from Project":
                case "Remove CodeDB Integration":
                    return "ConfirmedProjectMutation";
                default:
                    return "ExistingBackendEffect";
            }
        }

        internal static string ClassifyAuthority(string title)
        {
            switch (title)
            {
                case "Host Payload DryRun":
                case "Host Payload Verify":
                    return "PackageMaterializer";
                case "Host Payload Upgrade":
                    return "MaterializerAndInstanceAuthority";
                case "Configure CodeDB Dependencies":
                    return "ProviderInstallerAndLifecycle";
                case "Host Payload Redeploy":
                case "Host Payload Sync":
                case "Host Payload Remove":
                case "Install CodeDB":
                case "Uninstall CodeDB from Project":
                case "Remove CodeDB Integration":
                    return "UserConfirmationAndBackendAdmission";
                default:
                    return "ExistingActionSpecificBackend";
            }
        }
    }

    internal enum AICodedbManagerTab
    {
        Overview = 0,
        Setup = 1,
        Index = 2,
        Mcp = 3,
        Policy = 4
    }
}
