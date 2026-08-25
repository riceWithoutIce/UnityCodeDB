using System;
using System.IO;
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
        private const double ReadySnapshotCacheSeconds = 120d;
        private const double TransientStatusRetrySeconds = 1.5d;
        private const int MaximumTransientStatusRetries = 3;
        internal const string ReinstallCodeDBConfirmationTitle = "Reinstall CodeDB";
        internal const string ReinstallCodeDBConfirmationMessage =
            "Reinstall CodeDB integration for this Unity project?\n\n"
            + "CodeDB will create and validate a fresh project-local instance, update only its owned project MCP registration keys, "
            + "and switch future sessions only after initialize, tools/list, codedb_status, and a bounded query succeed.\n\n"
            + "The machine Provider, reviewed custom runtime configuration, business files, user policy, unrelated MCP content, "
            + "comments, ordering, and existing immutable instances are preserved. Retired Package-owned state is cleaned in the background. "
            + "External MCP clients and unrelated processes are never terminated.";
        internal const string UninstallCodeDBConfirmationTitle = "Uninstall CodeDB from Project";
        internal const string UninstallCodeDBConfirmationMessage =
            "Uninstall CodeDB integration from this Unity project?\n\n"
            + "The Unity Package remains installed. CodeDB will first publish the logical UNINSTALLED state, remove only its owned MCP registration keys and current instance selection, "
            + "then retire authenticated Package-owned state in the background.\n\n"
            + "Provider binaries, indexes, adapters, custom runtime configuration, user policy, business files, unrelated MCP content, and external processes are preserved. "
            + "A live external MCP keeps its exact execution closure until it exits naturally; cleanup then completes automatically.";
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
        private static DateTime _lastKnownReadyAtUtc;

        private static string ActivitySidebarWidthPrefsKey =>
            "Rice.AI.Codedb.Manager.ActivitySidebarWidth." + AICodedbProjectSettings.ProjectSlug;

        private Vector2 _scrollPosition;
        private AICodedbStatusSnapshot _statusSnapshot;
        private AICodedbEditorExecutionContext _executionContext;
        private AICodedbCommandResult _lastResult;
        private string _lastResultTitle = string.Empty;
        private float _activitySidebarWidth = AICodedbManagerLayout.ActivityDefaultWidth;
        private float _activityResizeStartMouseX;
        private float _activityResizeStartWidth;
        private float _mainContentWidth = AICodedbManagerLayout.MainContentMinWidth;
        private AICodedbActivityPanel _activityPanel;
        private AICodedbWatcherStatus _watcherStatus;
        private bool _watcherStatusLoaded;
        private bool _watcherRefreshScheduled;
        private bool _hostStatusRefreshInFlight;
        private long _cachedLifecycleStatusRevision = -1;
        private bool _watcherStatusRefreshInFlight;
        private bool _userActionInFlight;
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
            var window = GetWindow<AICodedbManagerWindow>(false, "CodeDB Manager");
            window.ApplyWindowTitle();
            window.minSize = new Vector2(900f, 460f);
            window._selectedTab = (int)tab;
            window.Show();
            window.BeginStatusRefresh();
            if (tab == AICodedbManagerTab.Index)
                window.ScheduleWatcherStatusRefresh();
            window.Repaint();
        }

        private void OnEnable()
        {
            _executionContext = AICodedbPaths.CaptureExecutionContext();
            ApplyWindowTitle();
            _activitySidebarWidth = EditorPrefs.GetFloat(
                ActivitySidebarWidthPrefsKey,
                AICodedbManagerLayout.ActivityDefaultWidth);
            _activityPanel = new AICodedbActivityPanel();
            _userActionStatus = new AICodedbUserActionStatus();
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

        private void OnDisable()
        {
            EditorApplication.update -= ObserveTransientHostStatus;
            EditorApplication.playModeStateChanged -= OnManagerPlayModeStateChanged;
            if (_watcherRefreshScheduled)
                EditorApplication.delayCall -= RefreshWatcherStatusDelayed;
            _watcherRefreshScheduled = false;
            if (_playModeRestoreScheduled)
                EditorApplication.delayCall -= RestorePlayModeAfterReload;
            _playModeRestoreScheduled = false;
        }

        private void OnGUI()
        {
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

        private void DrawBodyLayout()
        {
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
                : TryGetCachedReadySnapshot(_executionContext.ProjectRoot);
            if (_statusSnapshot == null && !IsPlayModeDisplaySuspended())
            {
                AICodedbProductState persistedState;
                if (AICodedbEditorLifecycle.TryGetPersistedProductState(
                        _executionContext.ProjectRoot,
                        out persistedState))
                {
                    _statusSnapshot = AICodedbStatusSnapshot.CreateCachedState(
                        _executionContext.ProjectDisplayName,
                        persistedState);
                }
            }
            _statusSnapshot = _statusSnapshot
                ?? AICodedbStatusSnapshot.CreateStarting(_executionContext.ProjectDisplayName);
            // A cached Ready snapshot is still a verified observation. Record
            // it before Play can trigger a domain reload, even when the
            // lifecycle worker's most recent result is still Starting.
            CacheReadySnapshot(_executionContext.ProjectRoot, _statusSnapshot);
            ApplyDisclosurePolicy(true);
        }

        private void RefreshStatus(AICodedbCommandResult hostPayloadResult)
        {
            if (IsPlayModeDisplaySuspended())
            {
                RestoreReadySnapshotForPlayMode();
                _transientStatusRefreshPending = true;
                return;
            }
            var initializeDisclosures = _statusSnapshot == null;
            _statusSnapshot = AICodedbStatusSnapshot.Refresh(hostPayloadResult);
            ApplyStatusSnapshot(_statusSnapshot, true, initializeDisclosures);
        }

        private void ObserveTransientHostStatus()
        {
            if (_userActionInFlight)
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
                _transientStatusRefreshPending = false;
                // Play-mode resume is owned by the lifecycle worker. Do not
                // launch a second materializer from the Manager's update
                // callback; that duplicates backend startup and can race the
                // worker's post-Play recovery. The request only schedules the
                // existing background pass, whose cached result is consumed
                // above on a later editor frame.
                AICodedbEditorLifecycle.RequestBackgroundStatusObservation();
                TryApplyCachedLifecycleStatus();
                return;
            }

            if (_statusSnapshot == null || _hostStatusRefreshInFlight)
                return;
            if (_statusSnapshot.IsProjectUninstalled)
                return;
            if (EditorApplication.isCompiling
                || EditorApplication.isUpdating
                || IsPlayModeDisplaySuspended())
                return;

            var suppressed = AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                _statusSnapshot.HostUpgradeStatus,
                AICodedbProjectSettings.CurrentGenerationId);
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
            AICodedbEditorLifecycle.RequestBackgroundStatusObservation();
        }

        private async void RefreshTransientHostStatusAsync()
        {
            if (_hostStatusRefreshInFlight)
                return;
            _hostStatusRefreshInFlight = true;
            var playModeStatusGeneration = _playModeStatusGeneration;
            try
            {
                var result = await AICodedbHostPayloadMaterializer.ReadStatusAsync(_executionContext);
                var snapshot = await AICodedbStatusSnapshot.RefreshAsync(_executionContext, result);
                if (this == null || _userActionInFlight)
                    return;

                if (!ShouldApplyStatusRefreshResult(
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
                    return;
                }

                var previousState = _statusSnapshot == null
                    ? AICodedbProductState.Starting
                    : _statusSnapshot.ProductStatus.State;
                var convergencePlan = AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                    snapshot.CurrentInstanceStatus.Present,
                    snapshot.CurrentInstanceStatus.IsCurrent,
                    snapshot.ProductStatus);
                if (ShouldPreserveReadyDuringTransientRefresh(
                        previousState,
                        convergencePlan,
                        AICodedbEditorLifecycle.HasVerifiedReadyForCurrentPackage(
                            _executionContext.ProjectRoot),
                        AICodedbEditorLifecycle.IsReconcileInFlight,
                        _transientStatusRefreshAttempts,
                        MaximumTransientStatusRetries))
                {
                    _transientStatusRefreshAttempts++;
                    _transientStatusRefreshPending = true;
                    _nextTransientStatusRefreshAt = EditorApplication.timeSinceStartup + TransientStatusRetrySeconds;
                    return;
                }

                if (ShouldKeepRecoverableAvailabilityStarting(
                        previousState,
                        convergencePlan,
                        AICodedbEditorLifecycle.IsReconcileInFlight,
                        _transientStatusRefreshAttempts,
                        MaximumTransientStatusRetries))
                {
                    // A previous failed probe can have already painted
                    // Needs attention/Reinstall before the lifecycle worker
                    // has had a chance to restart the current instance. Once
                    // the immutable instance is verified and only MCP
                    // availability is missing, expose the honest transient
                    // state instead of leaving the stale recovery action on
                    // screen during the bounded retry window.
                    if (ShouldPresentRecoverableAvailabilityAsStarting(
                            previousState,
                            convergencePlan,
                            AICodedbEditorLifecycle.IsReconcileInFlight,
                            _transientStatusRefreshAttempts,
                            MaximumTransientStatusRetries))
                    {
                        ApplyStatusSnapshot(
                            AICodedbStatusSnapshot.CreateStarting(_executionContext.ProjectDisplayName),
                            false,
                            false);
                        Repaint();
                    }
                    _transientStatusRefreshAttempts++;
                    _transientStatusRefreshPending = true;
                    _nextTransientStatusRefreshAt = EditorApplication.timeSinceStartup + TransientStatusRetrySeconds;
                    return;
                }

                _transientStatusRefreshAttempts = 0;
                _transientStatusRefreshPending = false;
                ApplyStatusSnapshot(snapshot, true, false);
                Repaint();
            }
            catch (Exception exception)
            {
                if (this != null)
                    Debug.LogWarning("CodeDB Manager automatic status refresh failed: " + exception.Message);
            }
            finally
            {
                _hostStatusRefreshInFlight = false;
            }
        }

        private void ApplyStatusSnapshot(AICodedbStatusSnapshot snapshot)
        {
            ApplyStatusSnapshot(snapshot, true, _statusSnapshot == null);
        }

        private void ApplyStatusSnapshot(
            AICodedbStatusSnapshot snapshot,
            bool invalidateReadyCache,
            bool initializeDisclosures)
        {
            if (snapshot == null)
                return;
            _statusSnapshot = snapshot;
            CacheReadySnapshot(_executionContext.ProjectRoot, snapshot);
            if (invalidateReadyCache && snapshot.ProductStatus.State != AICodedbProductState.Ready)
                InvalidateReadySnapshot(_executionContext.ProjectRoot);
            if (_userActionStatus != null)
                _userActionStatus.UpdateProductState(snapshot.ProductStatus.State);
            ApplyDisclosurePolicy(initializeDisclosures);
        }

        private async Task RefreshStatusAsync(AICodedbCommandResult hostPayloadResult)
        {
            var playModeStatusGeneration = _playModeStatusGeneration;
            var snapshot = await AICodedbStatusSnapshot.RefreshAsync(
                _executionContext,
                hostPayloadResult);
            if (this == null)
                return;
            if (!ShouldApplyStatusRefreshResult(
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
                return;
            }
            ApplyStatusSnapshot(snapshot, true, false);
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

            // Once lifecycle initialization has completed, an explicit
            // Manager refresh joins the same query-first queue as automatic
            // observations. This prevents the view from launching a second
            // materializer beside a reconcile/reconnect pass. The legacy
            // async fallback remains only for the short pre-initialization
            // window where no lifecycle worker exists yet.
            if (AICodedbEditorLifecycle.IsLifecycleInitialized)
            {
                _transientStatusRefreshPending = true;
                _nextTransientStatusRefreshAt = EditorApplication.timeSinceStartup;
                AICodedbEditorLifecycle.RequestBackgroundStatusObservation(true);
                TryApplyCachedLifecycleStatus();
                return;
            }

            RefreshTransientHostStatusAsync();
        }

        private bool TryApplyCachedLifecycleStatus()
        {
            if (_hostStatusRefreshInFlight
                || IsPlayModeDisplaySuspended()
                || string.IsNullOrWhiteSpace(_executionContext.ProjectRoot))
                return false;

            AICodedbCommandResult cachedResult;
            long revision;
            if (!AICodedbEditorLifecycle.TryGetCachedHostStatusResult(
                    out cachedResult,
                    out revision)
                || cachedResult == null
                || revision <= _cachedLifecycleStatusRevision)
                return false;

            _cachedLifecycleStatusRevision = revision;
            ApplyCachedLifecycleStatusAsync(cachedResult);
            return true;
        }

        private async void ApplyCachedLifecycleStatusAsync(
            AICodedbCommandResult cachedResult)
        {
            if (_hostStatusRefreshInFlight || cachedResult == null)
                return;

            _hostStatusRefreshInFlight = true;
            var playModeStatusGeneration = _playModeStatusGeneration;
            try
            {
                var snapshot = await AICodedbStatusSnapshot.RefreshAsync(
                    _executionContext,
                    cachedResult);
                if (this == null
                    || !ShouldApplyStatusRefreshResult(
                        playModeStatusGeneration,
                        _playModeStatusGeneration,
                        IsPlayModeDisplaySuspended()))
                    return;

                ApplyStatusSnapshot(snapshot, true, false);
                _transientStatusRefreshPending = false;
                _transientStatusRefreshAttempts = 0;
                Repaint();
            }
            catch (Exception exception)
            {
                if (this != null)
                    Debug.LogWarning("CodeDB Manager cached status refresh failed: " + exception.Message);
            }
            finally
            {
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
                    return TryGetCachedReadySnapshot(_executionContext.ProjectRoot)
                           ?? AICodedbStatusSnapshot.CreateCachedReady(_executionContext.ProjectDisplayName);
                case AICodedbProductState.MissingPrerequisite:
                    return AICodedbStatusSnapshot.CreateCachedMissingPrerequisite(
                        _executionContext.ProjectDisplayName);
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
            snapshot = snapshot ?? TryGetCachedReadySnapshot(_executionContext.ProjectRoot);
            if (snapshot == null)
                return false;

            if (snapshot.ProductStatus.State != AICodedbProductState.Ready
                && snapshot.ProductStatus.State != AICodedbProductState.MissingPrerequisite)
                return false;

            _statusSnapshot = snapshot;
            CacheReadySnapshot(_executionContext.ProjectRoot, snapshot);
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

        private static AICodedbStatusSnapshot TryGetCachedReadySnapshot(string projectRoot)
        {
            if (_lastKnownReadySnapshot == null
                || _lastKnownReadySnapshot.ProductStatus.State != AICodedbProductState.Ready
                || string.IsNullOrWhiteSpace(projectRoot)
                || !string.Equals(
                    AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\'),
                    _lastKnownReadyProjectRoot,
                    StringComparison.OrdinalIgnoreCase)
                || DateTime.UtcNow - _lastKnownReadyAtUtc > TimeSpan.FromSeconds(ReadySnapshotCacheSeconds))
            {
                return null;
            }

            return _lastKnownReadySnapshot;
        }

        private static void CacheReadySnapshot(string projectRoot, AICodedbStatusSnapshot snapshot)
        {
            if (snapshot == null || snapshot.ProductStatus.State != AICodedbProductState.Ready)
                return;

            _lastKnownReadySnapshot = snapshot;
            _lastKnownReadyProjectRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\');
            _lastKnownReadyAtUtc = DateTime.UtcNow;
            AICodedbEditorLifecycle.RecordVerifiedReadyForCurrentPackage(projectRoot);
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
                    AICodedbManagerStyles.GetStateDotStyle(_statusSnapshot.OverallState),
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
            if (!_statusSnapshot.IsProjectUninstalled)
            {
                menu.AddSeparator(string.Empty);
                menu.AddItem(
                    new GUIContent("Uninstall CodeDB from Project"),
                    false,
                    RunUninstallCodeDBWithConfirmation);
            }
            menu.ShowAsContext();
        }

        private void DrawTabBar()
        {
            EditorGUILayout.Space(4f);
            var nextTab = GUILayout.Toolbar(_selectedTab, TabNames, GUILayout.Height(28f));
            if (nextTab != _selectedTab)
            {
                _selectedTab = nextTab;
                _scrollPosition = Vector2.zero;
                if (_selectedTab == (int)AICodedbManagerTab.Index && !_watcherStatusLoaded)
                    ScheduleWatcherStatusRefresh();
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
            var reinstallAvailable = IsReinstallCodeDBAvailable(
                _statusSnapshot.HostGenerationSelection.State,
                _statusSnapshot.HostPayloadStatus.State,
                _statusSnapshot.HostUpgradeStatus.Phase);
            var primaryAction = ResolvePrimaryAction(
                _statusSnapshot.ProductStatus.State,
                reinstallAvailable,
                _userActionInFlight)
                    || ResolveProviderInstallAction(
                        _statusSnapshot.ProductStatus,
                        _userActionInFlight)
                    ? (Action)RunPrimaryAction
                    : null;
            AICodedbSectionView.DrawBanner(
                GetOverviewStatusTitle(),
                GetOverviewStatusDescription(),
                _statusSnapshot.OverallState,
                GetPrimaryActionLabel(),
                primaryAction);

            _showOverviewDetails = AICodedbSectionView.DrawDisclosure(
                _showOverviewDetails,
                "Diagnostics",
                "Optional technical details",
                DrawOverviewTechnicalDetails);
        }

        private void DrawOverviewTechnicalDetails()
        {
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostPayload);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.CurrentInstance);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostGeneration);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProviderExecutable);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProjectMcpConfig);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.McpAvailability);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.Cleanup);
            });
        }

        private void DrawSetupTab()
        {
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
                    progressLine => AICodedbActions.RunInstallProviderAsync(progressLine)))
                : null;
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
                    AICodedbProjectSettings.CurrentGenerationId)
                ? (Action)(() => RunAction("Host Payload Upgrade", AICodedbActions.RunHostPayloadUpgrade))
                : null;
            var redeployAction = _statusSnapshot.HostPayloadStatus.CanRedeploy
                ? (Action)RunHostPayloadRedeployWithConfirmation
                : null;
            var updateLabel = IsCurrentHostUpgradeInProgress(
                _statusSnapshot.HostUpgradeStatus,
                AICodedbProjectSettings.CurrentGenerationId)
                    ? "Update in progress"
                    : GetHostUpgradeActionLabel(
                        _statusSnapshot.HostUpgradeStatus,
                        AICodedbProjectSettings.CurrentGenerationId);
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
                GetHostAction(() => RunAction("Refresh If Stale", AICodedbActions.RunRefreshIfStale)));

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
                    EditorGUILayout.HelpBox("Lifecycle controls require the current selected instance. Return to Overview and use Reinstall CodeDB.", MessageType.Info);

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
                AICodedbActionButton.Create("Refresh index", GetHostAction(() => RunAction("Refresh Index", AICodedbActions.RunRefreshIndex))),
                AICodedbActionButton.Create("Build shader", GetHostAction(() => RunAction("Build Shader Adapter", AICodedbActions.RunBuildShaderAdapter))),
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
                "当前项目的客户端注册",
                "Verify registration",
                GetHostAction(() => RunAction("Project Config Validation", AICodedbActions.RunRegistrationValidation)));

            var mcpState = _statusSnapshot.GetMcpState();
            AICodedbSectionView.DrawBanner(
                mcpState == AICodedbStatusState.Ok
                    ? "Project registration is current"
                    : "Project registration needs attention",
                AICodedbProjectSettings.ProjectMcpConfigRelativePath + " · " + AICodedbProjectSettings.ProviderSlug,
                mcpState,
                "Copy snippet",
                CopyMcpSnippet);

            AICodedbSectionView.DrawStatusGroup("Registration", string.Empty, null, () =>
            {
                AICodedbSectionView.DrawStatusRow(
                    "Scope",
                    "Workspace / project level",
                    AICodedbStatusState.Ok,
                    "Project-owned");
                AICodedbSectionView.DrawStatusRow(
                    "Server",
                    AICodedbProjectSettings.ProviderSlug,
                    mcpState,
                    GetStateLabel(mcpState, "Configured"));
                var runtimeState = _statusSnapshot.GetRuntimeState();
                AICodedbSectionView.DrawStatusRow(
                    "Runtime root",
                    "Relative to the Unity project",
                    runtimeState,
                    GetStateLabel(runtimeState, "Valid"));
            });

            _showMcpSnippet = AICodedbSectionView.DrawDisclosure(
                _showMcpSnippet,
                "Registration snippet",
                "Copy-only",
                DrawMcpProjectSnippetSection);
            _showMcpPolicy = AICodedbSectionView.DrawDisclosure(
                _showMcpPolicy,
                "Registration policy",
                "Global config is fallback-only",
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
                AICodedbDetailRowView.DrawValue("Registration", "Scope", "Workspace-local/project-level first");
                AICodedbDetailRowView.DrawValue("Registration", "Target", AICodedbProjectSettings.ProjectMcpConfigRelativePath);
                AICodedbDetailRowView.DrawValue("Server", "Name", AICodedbProjectSettings.ProviderSlug);
                AICodedbDetailRowView.DrawValue("Global config", "Fallback only", "User/global registration is temporary smoke fallback only.");
            });
            EditorGUILayout.HelpBox(
                "The Manager validates project registration material and never writes MCP client configuration.",
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
                    RunAction("Language Custom Probe", RunLanguageCustomProbe);
                }
            }
        }

        private string GetPrimaryActionLabel()
        {
            if (_statusSnapshot == null)
                return string.Empty;
            if (_userActionInFlight)
                return GetUserActionPresentation().ButtonLabel;
            switch (_statusSnapshot.ProductStatus.State)
            {
                case AICodedbProductState.Uninstalled:
                    return "Install CodeDB";
                case AICodedbProductState.NeedsAttention:
                    return "Reinstall CodeDB";
                case AICodedbProductState.MissingPrerequisite:
                    return IsProviderInstallAvailable(_statusSnapshot.ProductStatus)
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
                    progressLine => AICodedbActions.RunInstallProviderAsync(progressLine));
                return;
            }

            if (_statusSnapshot != null && _statusSnapshot.IsProjectUninstalled)
                RunInstallCodeDBWithConfirmation();
            else
                RunReinstallCodeDBWithConfirmation();
        }

        private void RunReinstallCodeDBWithConfirmation()
        {
            ConfirmAndRunReinstallCodeDB(
                () => EditorUtility.DisplayDialog(
                    ReinstallCodeDBConfirmationTitle,
                    ReinstallCodeDBConfirmationMessage,
                    "Reinstall CodeDB",
                    "Cancel"),
                () => RunUserActionAsync("Reinstall CodeDB", AICodedbActions.RunReinstallCodeDBAsync));
        }

        internal static bool ConfirmAndRunReinstallCodeDB(Func<bool> confirm, Action reinstall)
        {
            if (confirm == null)
                throw new ArgumentNullException(nameof(confirm));
            if (reinstall == null)
                throw new ArgumentNullException(nameof(reinstall));
            if (!confirm())
                return false;

            reinstall();
            return true;
        }

        private void RunUninstallCodeDBWithConfirmation()
        {
            ConfirmAndRunUninstallCodeDB(
                () => EditorUtility.DisplayDialog(
                    UninstallCodeDBConfirmationTitle,
                    UninstallCodeDBConfirmationMessage,
                    "Uninstall CodeDB",
                    "Cancel"),
                () => RunUserActionAsync("Uninstall CodeDB from Project", AICodedbActions.RunUninstallCodeDBAsync));
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

        internal static bool IsReinstallCodeDBAvailable(
            AICodedbHostGenerationState generationState,
            AICodedbHostPayloadState payloadState,
            AICodedbHostUpgradePhase upgradePhase)
        {
            // Reinstall provisions a disjoint Package-owned candidate and
            // performs its own fail-closed preflight, so historical Host
            // readiness never disables this recovery entry point.
            return Enum.IsDefined(typeof(AICodedbHostGenerationState), generationState)
                   && Enum.IsDefined(typeof(AICodedbHostPayloadState), payloadState)
                   && Enum.IsDefined(typeof(AICodedbHostUpgradePhase), upgradePhase);
        }

        internal static bool ResolvePrimaryAction(
            AICodedbProductState productState,
            bool reinstallAvailable,
            bool actionInFlight)
        {
            if (actionInFlight)
                return false;
            if (productState == AICodedbProductState.Uninstalled)
                return true;
            return productState == AICodedbProductState.NeedsAttention && reinstallAvailable;
        }

        internal static bool ResolveProviderInstallAction(
            AICodedbProductStatus productStatus,
            bool actionInFlight)
        {
            return !actionInFlight && IsProviderInstallAvailable(productStatus);
        }

        internal static bool ShouldShowPersistentDependencyAction(AICodedbProductStatus productStatus)
        {
            return productStatus.State == AICodedbProductState.NeedsAttention;
        }

        internal static bool ShouldOfferConfigureDependencies(AICodedbProductStatus productStatus)
        {
            return ShouldShowPersistentDependencyAction(productStatus)
                   || IsProviderInstallAvailable(productStatus);
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

            RunAction("Clean Index", AICodedbActions.RunCleanIndex);
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

            RunAction("Rebuild Index", AICodedbActions.RunRebuildIndex);
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

        private void RunHostPayloadRedeployWithConfirmation()
        {
            var preflightResult = AICodedbActions.RunHostPayloadDryRun();
            RefreshStatus(preflightResult);
            if (!preflightResult.Succeeded)
            {
                _lastResultTitle = "Host Payload Redeploy Preflight";
                _lastResult = preflightResult;
                GetActivityPanel().ResetForNewResult(_lastResult, _lastResultTitle);
                Repaint();
                return;
            }

            var hostPayload = _statusSnapshot.HostPayloadStatus;
            if (!hostPayload.CanRedeploy)
            {
                EditorUtility.DisplayDialog(
                    "Redeploy status changed",
                    "The Manager refreshed CodeDB status and Redeploy is no longer available. Review the updated Host status before continuing.",
                    "OK");
                Repaint();
                return;
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
                return;
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
                return;
            }

            RunAction("Host Payload Redeploy", () => AICodedbActions.RunHostPayloadRedeploy(true));
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

        private AICodedbCommandResult RunLanguageCustomProbe()
        {
            var query = (_customProbeQuery ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(query))
                return new AICodedbCommandResult(-1, string.Empty, "Language Custom Probe text is empty.", false);

            var language = CustomProbeLanguageValues[Mathf.Clamp(
                _customProbeLanguageIndex,
                0,
                CustomProbeLanguageValues.Length - 1)];
            if (string.Equals(language, "ShaderHlsl", StringComparison.Ordinal))
                return AICodedbActions.RunShaderAdapterSearch(query);
            return AICodedbActions.RunProviderCustomProbe(language, query);
        }

        private void RunAction(string title, Func<AICodedbCommandResult> action)
        {
            if (_userActionInFlight || action == null)
                return;

            _lastResultTitle = title;
            _lastResult = action();
            if (AICodedbWatcherStatusBuilder.IsWatcherActivity(title, _lastResult.StandardOutput))
            {
                _watcherStatus = AICodedbWatcherStatusBuilder.Build(_lastResult);
                _watcherStatusLoaded = true;
                ApplyWatcherDisclosurePolicy();
            }

            GetActivityPanel().ResetForNewResult(_lastResult, _lastResultTitle);
            RefreshStatus();
            BeginStatusRefresh();
            Repaint();
        }

        private void RunUserActionAsync(
            string title,
            Func<Task<AICodedbCommandResult>> action)
        {
            if (action == null)
                return;

            RunUserActionAsync(title, progressLine => action());
        }

        private async void RunUserActionAsync(
            string title,
            Func<Action<string>, Task<AICodedbCommandResult>> action)
        {
            if (_userActionInFlight || action == null)
                return;

            InvalidateReadySnapshot(_executionContext.ProjectRoot);
            _transientStatusRefreshAttempts = 0;
            _transientStatusRefreshPending = false;
            _userActionInFlight = true;
            _nextUserActionRepaintAt = EditorApplication.timeSinceStartup;
            var actionStatus = GetUserActionStatus();
            actionStatus.Start(title, EditorApplication.timeSinceStartup);
            _lastResultTitle = title;
            GetActivityPanel().ResetForRunningAction();
            ShowUserActionNotification(actionStatus.BuildPresentation(EditorApplication.timeSinceStartup));
            RefreshStatus();
            Repaint();
            AICodedbCommandResult result;
            try
            {
                result = await action(line => { actionStatus.UpdateProgressLine(line); });
            }
            catch (Exception exception)
            {
                result = new AICodedbCommandResult(
                    -1,
                    string.Empty,
                    exception.Message,
                    false);
            }
            if (this == null)
                return;
            _lastResult = result;
            GetActivityPanel().ResetForNewResult(_lastResult, _lastResultTitle);
            var statusRefreshSucceeded = true;
            if (title.IndexOf("Dependencies", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                actionStatus.SetProgress(6, 6, "Rechecking CodeDB readiness");
                Repaint();
            }
            try
            {
                await RefreshStatusAsync(_lastResult);
            }
            catch (Exception exception)
            {
                statusRefreshSucceeded = false;
                Debug.LogWarning("CodeDB Manager status refresh after action failed: " + exception.Message);
            }

            actionStatus.Complete(
                _lastResult,
                _statusSnapshot == null ? AICodedbProductState.Starting : _statusSnapshot.ProductStatus.State,
                statusRefreshSucceeded,
                EditorApplication.timeSinceStartup);
            _userActionInFlight = false;
            ShowUserActionNotification(actionStatus.BuildPresentation(EditorApplication.timeSinceStartup));
            AICodedbEditorLifecycle.RequestReconcile();
            Repaint();
        }

        private void DrawActivityPanel(AICodedbManagerLayoutMetrics layout)
        {
            if (GetActivityPanel().Draw(
                    _lastResult,
                    _lastResultTitle,
                    GetUserActionPresentation(),
                    layout))
            {
                _lastResult = null;
                _lastResultTitle = string.Empty;
                GetUserActionStatus().Clear();
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
            _selectedTab = (int)tab;
            _scrollPosition = Vector2.zero;
            if (tab == AICodedbManagerTab.Index && !_watcherStatusLoaded)
                ScheduleWatcherStatusRefresh();
            Repaint();
        }

        private string GetHeaderTitle()
        {
            return _statusSnapshot.OverallTitle;
        }

        private string GetHeaderDescription()
        {
            return _statusSnapshot.OverallDescription;
        }

        private string GetOverviewStatusTitle()
        {
            switch (_statusSnapshot.ProductStatus.State)
            {
                case AICodedbProductState.Ready:
                    return "CodeDB is ready";
                case AICodedbProductState.Starting:
                    return "CodeDB is starting";
                case AICodedbProductState.Uninstalled:
                    return "CodeDB is uninstalled";
                case AICodedbProductState.MissingPrerequisite:
                    return "CodeDB needs a prerequisite";
                default:
                    return "CodeDB needs attention";
            }
        }

        private string GetOverviewStatusDescription()
        {
            return _statusSnapshot.OverallDescription;
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

    internal enum AICodedbManagerTab
    {
        Overview = 0,
        Setup = 1,
        Index = 2,
        Mcp = 3,
        Policy = 4
    }
}
