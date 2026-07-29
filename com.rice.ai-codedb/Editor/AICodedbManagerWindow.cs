using System;
using System.IO;
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
        private const double TransientStatusRefreshSeconds = 5d;
        private const float CustomProbeSingleRowMinWidth =
            CustomProbeLanguageLabelWidth
            + CustomProbeLanguageWidth
            + CustomProbeQueryLabelWidth
            + CustomProbeQueryMinWidth
            + AICodedbActionGridView.Gap
            + AICodedbActionGridView.ButtonWidth;

        private static string ActivitySidebarWidthPrefsKey =>
            "Rice.AI.Codedb.Manager.ActivitySidebarWidth." + AICodedbProjectSettings.ProjectSlug;

        private Vector2 _scrollPosition;
        private AICodedbStatusSnapshot _statusSnapshot;
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
        private double _nextHostStatusRefreshAt;
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
        private string _trackedHostAuthorizationPath = string.Empty;
        private bool _confirmLegacyMcpStopped;

        internal static void Open()
        {
            Open(AICodedbManagerTab.Overview);
        }

        internal static void Open(AICodedbManagerTab tab)
        {
            var window = GetWindow<AICodedbManagerWindow>(false, "Codedb Manager");
            window.ApplyWindowTitle();
            window.minSize = new Vector2(900f, 460f);
            window._selectedTab = (int)tab;
            window.Show();
            window.RefreshStatus();
            window.ScheduleWatcherStatusRefresh();
            window.Repaint();
        }

        private void OnEnable()
        {
            ApplyWindowTitle();
            _activitySidebarWidth = EditorPrefs.GetFloat(
                ActivitySidebarWidthPrefsKey,
                AICodedbManagerLayout.ActivityDefaultWidth);
            _activityPanel = new AICodedbActivityPanel();
            _watcherStatus = AICodedbWatcherStatusBuilder.Build(null);
            _watcherStatusLoaded = false;
            EditorApplication.update -= ObserveTransientHostStatus;
            EditorApplication.update += ObserveTransientHostStatus;
            RefreshStatus();
            _nextHostStatusRefreshAt = EditorApplication.timeSinceStartup + 1d;
            ScheduleWatcherStatusRefresh();
        }

        private void OnDisable()
        {
            EditorApplication.update -= ObserveTransientHostStatus;
            if (_watcherRefreshScheduled)
                EditorApplication.delayCall -= RefreshWatcherStatusDelayed;
            _watcherRefreshScheduled = false;
        }

        private void OnGUI()
        {
            if (_statusSnapshot == null)
                RefreshStatus();

            DrawHeader();
            DrawBodyLayout();
        }

        private void DrawBodyLayout()
        {
            var panelHorizontalMargin = Mathf.Max(0f, EditorStyles.helpBox.margin.horizontal);
            var bodyHeight = Mathf.Max(
                0f,
                position.height - AICodedbManagerStyles.HeaderHeight - BodyVerticalSpacing);
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
            var initializeDisclosures = _statusSnapshot == null;
            _statusSnapshot = AICodedbStatusSnapshot.Refresh();
            ApplyDisclosurePolicy(initializeDisclosures);
        }

        private void RefreshStatus(AICodedbCommandResult hostPayloadResult)
        {
            var initializeDisclosures = _statusSnapshot == null;
            _statusSnapshot = AICodedbStatusSnapshot.Refresh(hostPayloadResult);
            ApplyDisclosurePolicy(initializeDisclosures);
        }

        private void ObserveTransientHostStatus()
        {
            if (_statusSnapshot == null || _hostStatusRefreshInFlight)
                return;
            if (EditorApplication.isCompiling || EditorApplication.isUpdating)
                return;

            var suppressed = AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                _statusSnapshot.HostUpgradeStatus,
                AICodedbProjectSettings.CurrentGenerationId);
            if (!ShouldAutoObserveHostStatus(
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
            RefreshTransientHostStatusAsync();
        }

        private async void RefreshTransientHostStatusAsync()
        {
            if (_hostStatusRefreshInFlight)
                return;
            _hostStatusRefreshInFlight = true;
            try
            {
                var result = await AICodedbHostPayloadMaterializer.ReadStatusAsync();
                if (this == null)
                    return;
                RefreshStatus(result);
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

        private void RefreshAllStatus()
        {
            RefreshStatus();
            RefreshWatcherStatusSilently();
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
            menu.AddItem(
                new GUIContent("Provider Guidance"),
                false,
                () => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance));
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
            AICodedbSectionView.DrawPageHeader("Overview", "项目状态与建议操作", string.Empty, null);
            AICodedbSectionView.DrawBanner(
                GetOverviewStatusTitle(),
                GetOverviewStatusDescription(),
                _statusSnapshot.OverallState,
                GetPrimaryActionLabel(),
                RunPrimaryAction);

            AICodedbSectionView.DrawStatusGroup("Components", string.Empty, null, () =>
            {
                AICodedbSectionView.DrawStatusRow(
                    "Host files",
                    "Package-managed project files",
                    _statusSnapshot.GetHostPayloadState(),
                    GetHostPayloadLabel());
                AICodedbSectionView.DrawStatusRow(
                    "Provider",
                    "External codebase-mcp executable",
                    _statusSnapshot.GetProviderState(),
                    GetStateLabel(_statusSnapshot.GetProviderState(), "Ready"));
                AICodedbSectionView.DrawStatusRow(
                    "Project index",
                    "C#, Lua and JavaScript discovery",
                    _statusSnapshot.GetIndexState(),
                    GetStateLabel(_statusSnapshot.GetIndexState(), "Current"));
                AICodedbSectionView.DrawStatusRow(
                    "Shader / HLSL",
                    "Shader, HLSL, Compute and CGINC adapter",
                    _statusSnapshot.GetTextAdapterState(),
                    GetStateLabel(_statusSnapshot.GetTextAdapterState(), "Current"));
                AICodedbSectionView.DrawStatusRow(
                    "MCP registration",
                    "Project-level client configuration",
                    _statusSnapshot.GetMcpState(),
                    GetStateLabel(_statusSnapshot.GetMcpState(), "Configured"));
            });

            _showOverviewDetails = AICodedbSectionView.DrawDisclosure(
                _showOverviewDetails,
                "Technical details",
                "Paths, manifests, versions",
                DrawOverviewTechnicalDetails);
        }

        private void DrawOverviewTechnicalDetails()
        {
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostPayload);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostGeneration);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostLastKnownGood);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostUpgrade);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.HostUpdatePolicy);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProviderExecutable);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProviderConfig);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.RuntimeConfigTemplate);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.RuntimeDirectory);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.RuntimeGitIgnored);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.IndexManifest);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.TextAdapterManifest);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.ProjectMcpConfig);
            });
        }

        private void DrawSetupTab()
        {
            AICodedbSectionView.DrawPageHeader(
                "Setup",
                "Provider、配置与项目本地运行时",
                "Verify runtime",
                () => RunAction("Verify Runtime", AICodedbActions.RunVerifyRuntime));

            AICodedbSectionView.DrawStatusGroup("Environment", string.Empty, null, () =>
            {
                var providerState = _statusSnapshot.GetProviderState();
                AICodedbSectionView.DrawStatusRow(
                    "Provider",
                    "External executable",
                    providerState,
                    GetStateLabel(providerState, "Ready"),
                    providerState == AICodedbStatusState.Ok ? "Open" : "Guidance",
                    providerState == AICodedbStatusState.Ok
                        ? (Action)AICodedbActions.OpenProviderFolder
                        : () => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance));

                var runtimeState = _statusSnapshot.GetRuntimeState();
                AICodedbSectionView.DrawStatusRow(
                    "Runtime",
                    "Project-local and ignored by Git",
                    runtimeState,
                    GetStateLabel(runtimeState, "Ready"),
                    runtimeState == AICodedbStatusState.Ok ? "Open" : "Prepare",
                    runtimeState == AICodedbStatusState.Ok
                        ? (Action)AICodedbActions.OpenRuntimeFolder
                        : () => RunAction("Prepare Runtime", AICodedbActions.RunPrepareRuntime));

                var configState = _statusSnapshot.GetConfigState();
                AICodedbSectionView.DrawStatusRow(
                    "Configuration",
                    "Provider config and runtime template",
                    configState,
                    GetStateLabel(configState, "Current"),
                    "Regenerate",
                    () => RunAction("Regenerate Runtime Config", AICodedbActions.RunRegenerateRuntimeConfig));
            });

            _showProviderGuidance = AICodedbSectionView.DrawDisclosure(
                _showProviderGuidance,
                "Provider guidance",
                "Install or update",
                () => DrawActionGrid(
                    AICodedbActionButton.Create("Show guidance", () => RunAction("Provider Guidance", AICodedbActions.RunProviderGuidance)),
                    AICodedbActionButton.Create("Open provider", AICodedbActions.OpenProviderFolder),
                    AICodedbActionButton.Create("Open config", AICodedbActions.OpenConfigFolder)));

            _showAdvancedHostFiles = AICodedbSectionView.DrawDisclosure(
                _showAdvancedHostFiles,
                "Advanced host files",
                GetHostPayloadSummary(),
                DrawAdvancedHostFiles);
        }

        private void DrawAdvancedHostFiles()
        {
            DrawHostPayloadAuthorizationControls();
            EditorGUILayout.Space(6f);
            var hasAuthorization = !string.IsNullOrWhiteSpace(_trackedHostAuthorizationPath);
            var updateAction = _statusSnapshot.HostPayloadStatus.CanUpgradeAutomatically
                ? (Action)(() => RunAction("Host Payload Upgrade", AICodedbActions.RunHostPayloadUpgrade))
                : null;
            DrawActionGrid(2,
                AICodedbActionButton.Create("Inspect host files", () => RunAction("Host Payload DryRun", AICodedbActions.RunHostPayloadDryRun)),
                AICodedbActionButton.Create("Verify host files", () => RunAction("Host Payload Verify", AICodedbActions.RunHostPayloadVerify)),
                AICodedbActionButton.Create("Update now", updateAction),
                AICodedbActionButton.Create("Sync host files", hasAuthorization ? (Action)RunHostPayloadSyncWithConfirmation : null),
                AICodedbActionButton.Create("Remove host files", hasAuthorization ? (Action)RunHostPayloadRemoveWithConfirmation : null));
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
                AICodedbDetailRowView.DrawValue("Authorization", "Ignored runtime", AICodedbProjectSettings.TrackedHostAuthorizationRelativePath);
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
                () => RunAction("Refresh If Stale", AICodedbActions.RunRefreshIfStale));

            DrawAutomaticRefresh();
            AICodedbSectionView.DrawStatusGroup(
                "Discovery data",
                "Check freshness",
                () => RunAction("Check Freshness", AICodedbActions.RunFreshnessCheck),
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
                    EditorGUILayout.HelpBox("Lifecycle controls require the current host generation. Use Update now first.", MessageType.Info);

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
                AICodedbActionButton.Create("Check freshness", () => RunAction("Check Freshness", AICodedbActions.RunFreshnessCheck)),
                AICodedbActionButton.Create("Watcher status", () => RunAction("Watcher Status", AICodedbActions.RunWatcherStatus)),
                AICodedbActionButton.Create("Runtime health", () => RunAction("Runtime Health", AICodedbActions.RunRuntimeHealth)),
                AICodedbActionButton.Create("Unity smoke", () => RunAction("Unity Project Smoke", AICodedbActions.RunUnityProjectSmoke)),
                AICodedbActionButton.Create("Language probe", () => RunAction("Language Probe", AICodedbActions.RunLanguageProbe)),
                AICodedbActionButton.Create("C# probe", () => RunAction("C# Probe", AICodedbActions.RunCSharpProbe)),
                AICodedbActionButton.Create("Shader probe", () => RunAction("Shader Adapter Probe", AICodedbActions.RunShaderAdapterProbe)));
            EditorGUILayout.Space(6f);
            EditorGUILayout.LabelField("Custom probe", EditorStyles.miniBoldLabel);
            DrawCustomProbeSection();
        }

        private void DrawIndexMaintenance()
        {
            DrawActionGrid(
                AICodedbActionButton.Create("Refresh index", () => RunAction("Refresh Index", AICodedbActions.RunRefreshIndex)),
                AICodedbActionButton.Create("Build shader", () => RunAction("Build Shader Adapter", AICodedbActions.RunBuildShaderAdapter)),
                AICodedbActionButton.Create("Open runtime", AICodedbActions.OpenRuntimeFolder),
                AICodedbActionButton.Create("Clean index", RunCleanIndexWithConfirmation),
                AICodedbActionButton.Create("Rebuild index", RunRebuildIndexWithConfirmation));
            EditorGUILayout.Space(6f);
            DrawDetailsPanel(() =>
            {
                AICodedbDetailRowView.DrawValue("Index", "Relative path", AICodedbProjectSettings.IndexRelativePath);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.IndexManifest);
                AICodedbDetailRowView.DrawValue("Shader adapter", "Relative path", AICodedbProjectSettings.TextAdapterRelativePath);
                AICodedbDetailRowView.DrawStatus(_statusSnapshot.TextAdapterManifest);
                AICodedbDetailRowView.DrawValue("Watcher", "Watch config", AICodedbProjectSettings.WatchConfigRelativePath);
                AICodedbDetailRowView.DrawValue("Watcher", "Opt-in marker", AICodedbProjectSettings.WatchEnabledMarkerRelativePath);
                AICodedbDetailRowView.DrawValue("Watcher", "Coordinator", AICodedbProjectSettings.WatchCoordinatorRuntimeRelativePath);
            });
        }

        private void DrawMcpTab()
        {
            AICodedbSectionView.DrawPageHeader(
                "MCP",
                "当前项目的客户端注册",
                "Verify registration",
                () => RunAction("Project Config Validation", AICodedbActions.RunRegistrationValidation));

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
                AICodedbActionButton.Create("Show draft", () => RunAction("Registration Draft", AICodedbActions.RunRegistrationDraft)),
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

        private void DrawHostPayloadAuthorizationControls()
        {
            EditorGUILayout.LabelField("Tracked-host authorization", EditorStyles.miniBoldLabel);
            using (new EditorGUILayout.HorizontalScope())
            {
                _trackedHostAuthorizationPath = EditorGUILayout.TextField(
                    _trackedHostAuthorizationPath ?? string.Empty,
                    GUILayout.ExpandWidth(true));

                if (GUILayout.Button("Browse...", GUILayout.Width(76f), GUILayout.Height(22f)))
                    SelectTrackedHostAuthorization();

                using (new EditorGUI.DisabledScope(string.IsNullOrWhiteSpace(_trackedHostAuthorizationPath)))
                {
                    if (GUILayout.Button("Clear", GUILayout.Width(54f), GUILayout.Height(22f)))
                        ClearTrackedHostAuthorization();
                }
            }

            _confirmLegacyMcpStopped = EditorGUILayout.ToggleLeft(
                "Confirm all legacy MCP sessions are stopped (initial adoption only)",
                _confirmLegacyMcpStopped);
            if (_statusSnapshot.HostPayloadStatus.State == AICodedbHostPayloadState.Blocked)
                EditorGUILayout.HelpBox(_statusSnapshot.HostPayloadStatus.Detail, MessageType.Warning);
            EditorGUILayout.HelpBox(
                "DryRun and Verify are read-only. Sync and Remove require a reviewed ignored/untracked authorization file, no active project MCP session, and a paused watcher. The Manager never creates or deletes authorization files.",
                MessageType.Info);
        }

        private void SelectTrackedHostAuthorization()
        {
            var initialDirectory = Directory.Exists(AICodedbPaths.TrackedHostAuthorizationPath)
                ? AICodedbPaths.TrackedHostAuthorizationPath
                : AICodedbPaths.ProjectRoot;
            var selectedPath = EditorUtility.OpenFilePanel(
                "Select tracked-host mutation authorization",
                initialDirectory,
                "json");
            if (!string.IsNullOrWhiteSpace(selectedPath))
                _trackedHostAuthorizationPath = AICodedbPaths.NormalizePath(selectedPath);
        }

        private void ClearTrackedHostAuthorization()
        {
            _trackedHostAuthorizationPath = string.Empty;
            _confirmLegacyMcpStopped = false;
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
            using (new EditorGUI.DisabledScope(string.IsNullOrWhiteSpace(_customProbeQuery)))
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
            if (_statusSnapshot.HostPayloadStatus.CanUpgradeAutomatically)
                return "Update now";
            if (!_statusSnapshot.IsHostPayloadCurrent())
                return "Inspect host files";
            if (_statusSnapshot.IsReady())
                return "Refresh if stale";
            return "Verify runtime";
        }

        private void RunPrimaryAction()
        {
            if (_statusSnapshot.HostPayloadStatus.CanUpgradeAutomatically)
                RunAction("Host Payload Upgrade", AICodedbActions.RunHostPayloadUpgrade);
            else if (!_statusSnapshot.IsHostPayloadCurrent())
                RunAction("Host Payload DryRun", AICodedbActions.RunHostPayloadDryRun);
            else if (_statusSnapshot.IsReady())
                RunAction("Refresh If Stale", AICodedbActions.RunRefreshIfStale);
            else
                RunAction("Verify Runtime", AICodedbActions.RunVerifyRuntime);
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
            var authorizationPath = (_trackedHostAuthorizationPath ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(authorizationPath))
                return;

            var displayPath = GetTrackedHostAuthorizationDisplayPath(authorizationPath);
            if (!EditorUtility.DisplayDialog(
                    "Sync package-managed host files",
                    "Authorization:\n" + displayPath
                    + "\n\nSynchronize only the audited CodeDB host payload and ownership marker? "
                    + "The materializer will reject a mismatched project, Git HEAD, action, payload, target count, staged ownership path, or live host-use lease.",
                    "Sync Host Files",
                    "Cancel"))
            {
                return;
            }

            var confirmLegacyMcpStopped = _confirmLegacyMcpStopped;
            try
            {
                RunAction(
                    "Host Payload Sync",
                    () => AICodedbActions.RunHostPayloadSync(authorizationPath, confirmLegacyMcpStopped));
            }
            finally
            {
                ClearTrackedHostAuthorization();
            }
        }

        private void RunHostPayloadRemoveWithConfirmation()
        {
            var authorizationPath = (_trackedHostAuthorizationPath ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(authorizationPath))
                return;

            var displayPath = GetTrackedHostAuthorizationDisplayPath(authorizationPath);
            if (!EditorUtility.DisplayDialog(
                    "Remove package-managed host files",
                    "Authorization:\n" + displayPath
                    + "\n\nRemove only files owned by the installed CodeDB payload and its ownership marker? "
                    + "Provider data, MCP client configuration, business Assets, unrelated host files, and Git staging are outside this action.",
                    "Remove Host Files",
                    "Cancel"))
            {
                return;
            }

            var confirmLegacyMcpStopped = _confirmLegacyMcpStopped;
            try
            {
                RunAction(
                    "Host Payload Remove",
                    () => AICodedbActions.RunHostPayloadRemove(authorizationPath, confirmLegacyMcpStopped));
            }
            finally
            {
                ClearTrackedHostAuthorization();
            }
        }

        private static string GetTrackedHostAuthorizationDisplayPath(string authorizationPath)
        {
            try
            {
                return AICodedbPaths.ToProjectRelativeDisplayPath(authorizationPath);
            }
            catch (Exception)
            {
                return authorizationPath;
            }
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
            Repaint();
        }

        private void DrawActivityPanel(AICodedbManagerLayoutMetrics layout)
        {
            if (GetActivityPanel().Draw(_lastResult, _lastResultTitle, layout))
            {
                _lastResult = null;
                _lastResultTitle = string.Empty;
            }
        }

        private AICodedbActivityPanel GetActivityPanel()
        {
            return _activityPanel ?? (_activityPanel = new AICodedbActivityPanel());
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
            RefreshWatcherStatusSilently();
        }

        private void RefreshWatcherStatusSilently()
        {
            var result = AICodedbActions.RunWatcherStatus();
            _watcherStatus = AICodedbWatcherStatusBuilder.Build(result);
            _watcherStatusLoaded = true;
            ApplyWatcherDisclosurePolicy();
            Repaint();
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

            if (_statusSnapshot.GetProviderState() != AICodedbStatusState.Ok)
                _showProviderGuidance = true;
            if (AICodedbStatusSnapshot.GetHostManagementState(
                    _statusSnapshot.HostPayload.State,
                    _statusSnapshot.HostGeneration.State,
                    _statusSnapshot.HostUpgrade.State,
                    _statusSnapshot.HostUpdatePolicy.State) != AICodedbStatusState.Ok)
                _showAdvancedHostFiles = true;
            if (_statusSnapshot.GetIndexState() != AICodedbStatusState.Ok
                || _statusSnapshot.GetTextAdapterState() != AICodedbStatusState.Ok)
            {
                _showIndexDiagnostics = true;
            }
            if (_statusSnapshot.GetMcpState() != AICodedbStatusState.Ok)
                _showMcpSnippet = true;
            if (_statusSnapshot.GetPolicyState() != AICodedbStatusState.Ok)
                _showPolicyDetails = true;
        }

        private void ApplyWatcherDisclosurePolicy()
        {
            if (_watcherStatus.DisplayState == AICodedbStatusState.Warning
                || _watcherStatus.DisplayState == AICodedbStatusState.Error)
            {
                _showIndexDiagnostics = true;
            }
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
            if (!_statusSnapshot.IsHostPayloadCurrent())
                return AICodedbProjectSettings.ProjectDisplayName + " · " + GetHostPayloadLabel();

            var state = _statusSnapshot.OverallState;
            var label = state == AICodedbStatusState.Ok
                ? "Ready"
                : state == AICodedbStatusState.Warning
                    ? "Needs setup"
                    : "Blocked";
            return AICodedbProjectSettings.ProjectDisplayName + " · " + label;
        }

        private string GetHeaderDescription()
        {
            switch (_statusSnapshot.OverallState)
            {
                case AICodedbStatusState.Ok:
                    return "Provider、运行时和索引均可用";
                case AICodedbStatusState.Warning:
                    return "存在需要处理的本地配置或索引状态";
                default:
                    return "存在阻塞 CodeDB 使用的问题";
            }
        }

        private string GetOverviewStatusTitle()
        {
            switch (_statusSnapshot.HostPayloadStatus.State)
            {
                case AICodedbHostPayloadState.SetupRequired:
                    return "SETUP_REQUIRED";
                case AICodedbHostPayloadState.UpgradeReady:
                    return "UPGRADE_READY";
                case AICodedbHostPayloadState.Draining:
                    return "READY / DRAINING";
                case AICodedbHostPayloadState.UpdateRequired:
                    return "UPDATE_REQUIRED";
                case AICodedbHostPayloadState.Conflict:
                    return "HOST FILE CONFLICT";
                case AICodedbHostPayloadState.Blocked:
                    return "HOST UPDATE BLOCKED";
            }

            switch (_statusSnapshot.OverallState)
            {
                case AICodedbStatusState.Ok:
                    return "CodeDB is ready";
                case AICodedbStatusState.Warning:
                    return "Setup requires attention";
                default:
                    return "CodeDB is blocked";
            }
        }

        private string GetOverviewStatusDescription()
        {
            switch (_statusSnapshot.HostPayloadStatus.State)
            {
                case AICodedbHostPayloadState.SetupRequired:
                    return "Install the package-managed host files before relying on discovery.";
                case AICodedbHostPayloadState.UpgradeReady:
                    return "The owned poc.21 host payload can migrate without stopping active CodeDB sessions.";
                case AICodedbHostPayloadState.Draining:
                    return "CodeDB is ready. Older sessions remain compatible on their original generation and finish naturally; no action is required.";
                case AICodedbHostPayloadState.UpdateRequired:
                    return "Update the installed host files to match this package.";
                case AICodedbHostPayloadState.Conflict:
                    return "Review the reported host-file conflict before attempting Sync.";
                case AICodedbHostPayloadState.Blocked:
                    return _statusSnapshot.HostPayloadStatus.Detail;
            }
            if (_statusSnapshot.IsReady())
                return "All discovery backends are current.";
            return "Verify the project-local runtime and resolve the reported status.";
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
