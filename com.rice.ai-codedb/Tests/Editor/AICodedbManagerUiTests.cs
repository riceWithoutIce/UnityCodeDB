using System;
using System.IO;
using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbProjectSettingsTests
    {
        /// <summary>
        /// Verifies that package-core actions use fixed project-neutral script entry points.
        /// </summary>
        [Test]
        public void ProductionScriptPaths_AreProjectNeutral()
        {
            Assert.That(AICodedbProjectSettings.RefreshScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/refresh-codedb-project.ps1"));
            Assert.That(AICodedbProjectSettings.CleanIndexScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/clear-codedb-project-index.ps1"));
            Assert.That(AICodedbProjectSettings.PrepareRuntimeScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1"));
            Assert.That(AICodedbProjectSettings.ProviderGuidanceScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1"));
            Assert.That(AICodedbProjectSettings.VerifyScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/verify-codedb-project.ps1"));
            Assert.That(AICodedbProjectSettings.IndexProbeScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/probe-codedb-project-index.ps1"));
            Assert.That(AICodedbProjectSettings.FreshnessScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/check-codedb-project-freshness.ps1"));
            Assert.That(AICodedbProjectSettings.RefreshIfStaleScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/refresh-codedb-project-if-stale.ps1"));
            Assert.That(AICodedbProjectSettings.WatchManageScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/manage-codedb-project-watch.ps1"));
            Assert.That(AICodedbProjectSettings.TextAdapterBuildScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1"));
            Assert.That(AICodedbProjectSettings.TextAdapterProbeScriptRelativePath, Is.EqualTo("AIWork/codedb/scripts/probe-codedb-project-text-adapter.ps1"));
            Assert.That(AICodedbProjectSettings.PackageName, Is.EqualTo("com.rice.ai-codedb"));
            Assert.That(AICodedbProjectSettings.HostPayloadMarkerRelativePath, Is.EqualTo("AIWork/codedb/.rice-ai-codedb-payload.json"));
            Assert.That(AICodedbProjectSettings.HostLastKnownGoodPointerRelativePath, Is.EqualTo("AIWork/.runtime/codedb/host/last-known-good.json"));
            Assert.That(AICodedbProjectSettings.HostPayloadUpgradeStateRelativePath, Is.EqualTo("AIWork/.runtime/codedb/payload-materializer/upgrade-state.json"));
            Assert.That(AICodedbProjectSettings.TrackedHostAuthorizationRelativePath, Is.EqualTo("AIWork/.runtime/codedb/payload-materializer/authorizations"));
            Assert.That(AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath, Is.EqualTo("Tools~/materialize-codedb-host-payload.ps1"));
        }

        [Test]
        public void ProjectMcpRegistrationSnippet_PinsUnityProjectWorkingDirectory()
        {
            var snippet = AICodedbProjectSettings.BuildProjectMcpRegistrationSnippet()
                .Replace("\r\n", "\n");

            Assert.That(
                snippet,
                Is.EqualTo(
                    "[mcp_servers." + AICodedbProjectSettings.ProviderSlug + "]\n" +
                    "command = \"node\"\n" +
                    "cwd = \".\"\n" +
                    "args = [\"AIWork/codedb/wrapper/codedb-project-wrapper.mjs\", \"--root\", \".\"]\n" +
                    "startup_timeout_sec = 120"));
        }
    }

    internal sealed class AICodedbHostManagementStatusTests
    {
        [TestCase(AICodedbStatusState.Ok, AICodedbStatusState.Ok)]
        [TestCase(AICodedbStatusState.Inactive, AICodedbStatusState.Ok)]
        [TestCase(AICodedbStatusState.Warning, AICodedbStatusState.Warning)]
        [TestCase(AICodedbStatusState.Error, AICodedbStatusState.Error)]
        public void GetHostManagementState_IncludesUpgradeSeverity(
            AICodedbStatusState upgradeState,
            AICodedbStatusState expected)
        {
            Assert.That(
                AICodedbStatusSnapshot.GetHostManagementState(
                    AICodedbStatusState.Ok,
                    AICodedbStatusState.Ok,
                    upgradeState,
                    AICodedbStatusState.Ok),
                Is.EqualTo(expected));
        }

        [Test]
        public void GetHostManagementState_IncludesInvalidUpdatePolicy()
        {
            Assert.That(
                AICodedbStatusSnapshot.GetHostManagementState(
                    AICodedbStatusState.Ok,
                    AICodedbStatusState.Ok,
                    AICodedbStatusState.Inactive,
                    AICodedbStatusState.Error),
                Is.EqualTo(AICodedbStatusState.Error));
        }
    }

    internal sealed class AICodedbBrandAssetsTests
    {
        [Test]
        public void Icon_IsPackagedForEditorUi()
        {
            Assert.That(
                AICodedbBrandAssets.IconAssetPath,
                Is.EqualTo("Packages/com.rice.ai-codedb/Editor/Icons/CodedbIcon.png"));

            var icon = AICodedbBrandAssets.Icon;
            Assert.That(icon, Is.Not.Null);
            Assert.That(icon.width, Is.EqualTo(48));
            Assert.That(icon.height, Is.EqualTo(48));

            Assert.That(
                AICodedbBrandAssets.TabIconAssetPath,
                Is.EqualTo("Packages/com.rice.ai-codedb/Editor/Icons/CodedbTabIcon.png"));
            var tabIcon = AICodedbBrandAssets.TabIcon;
            Assert.That(tabIcon, Is.Not.Null);
            Assert.That(tabIcon.width, Is.EqualTo(48));
            Assert.That(tabIcon.height, Is.EqualTo(48));
            Assert.That(tabIcon, Is.Not.SameAs(icon));
        }

        [Test]
        public void WindowTitleContent_KeepsStableTitleAndVersionTooltip()
        {
            var content = AICodedbBrandAssets.CreateWindowTitleContent("0.2.2");

            Assert.That(content.text, Is.EqualTo("CodeDB Manager"));
            Assert.That(content.tooltip, Is.EqualTo("Rice AI CodeDB v0.2.2"));
            Assert.That(content.image, Is.SameAs(AICodedbBrandAssets.TabIcon));
        }

        [Test]
        public void WindowTitleContent_FallsBackWithoutUnavailableVersion()
        {
            var content = AICodedbBrandAssets.CreateWindowTitleContent(string.Empty);

            Assert.That(content.text, Is.EqualTo("CodeDB Manager"));
            Assert.That(content.tooltip, Is.EqualTo("Rice AI CodeDB"));
        }

        [Test]
        public void PackageVersionContent_LabelsPackageIdentitySeparately()
        {
            var content = AICodedbBrandAssets.CreatePackageVersionContent("0.2.4-preview.4");

            Assert.That(content.text, Is.EqualTo("Package v0.2.4-preview.4"));
            Assert.That(content.tooltip, Is.EqualTo("Installed Unity Package Manager version"));
        }
    }

    internal sealed class AICodedbRuntimeConfigStatusTests
    {
        [TestCase("[logging]\nflush_interval_ms = 500", AICodedbStatusState.Ok, "Found")]
        [TestCase("[logging]\nflush_interval_ms = 100 # milliseconds", AICodedbStatusState.Ok, "Found")]
        [TestCase("[logging] # runtime logging\nflush_interval_ms = 500", AICodedbStatusState.Ok, "Found")]
        [TestCase("[logging]\nenabled = true", AICodedbStatusState.Warning, "Update Required")]
        [TestCase("[logging]\nflush_interval_ms = 0", AICodedbStatusState.Warning, "Update Required")]
        [TestCase("[logging]\nflush_interval_ms = 500\nflush_interval_ms = 100", AICodedbStatusState.Warning, "Update Required")]
        [TestCase("[other]\nflush_interval_ms = 500", AICodedbStatusState.Warning, "Update Required")]
        public void BuildProviderConfigStatus_ValidatesRequiredLoggingField(
            string config,
            AICodedbStatusState expectedState,
            string expectedSummary)
        {
            var status = AICodedbStatusSnapshot.BuildProviderConfigStatus(true, config, "runtime.toml");

            Assert.That(status.State, Is.EqualTo(expectedState));
            Assert.That(status.Summary, Is.EqualTo(expectedSummary));
        }
    }

    internal sealed class AICodedbActivitySummaryBuilderTests
    {
        [TestCase("[OK] Ready", AICodedbStatusState.Ok, "OK")]
        [TestCase("[STALE] Provider index", AICodedbStatusState.Warning, "Stale")]
        [TestCase("[UNKNOWN] Provider index", AICodedbStatusState.Warning, "Unknown")]
        [TestCase("[NO HIT] Missing", AICodedbStatusState.Warning, "No Hit")]
        [TestCase("[SKIP] Optional language", AICodedbStatusState.Warning, "Skipped")]
        [TestCase("[CONFLICT] ManagedDrift: AIWork/codedb/example.ps1", AICodedbStatusState.Error, "Conflict")]
        public void Build_MapsGenericMarkers(string output, AICodedbStatusState state, string label)
        {
            var summary = AICodedbActivitySummaryBuilder.Build("Probe", Result(output));
            Assert.That(summary.State, Is.EqualTo(state));
            Assert.That(summary.StatusLabel, Is.EqualTo(label));
        }

        [Test]
        public void Build_ExtractsHitItems()
        {
            var summary = AICodedbActivitySummaryBuilder.Build(
                "Probe",
                Result("[OK] Search completed.\n[HIT] Assets/A.cs:10\n[HIT] Assets/B.cs:20"));

            Assert.That(summary.State, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(summary.StatusLabel, Is.EqualTo("OK - 2 Hits"));
            Assert.That(summary.Items, Is.EqualTo(new[] { "Assets/A.cs:10", "Assets/B.cs:20" }));
        }

        [Test]
        public void Build_MapsFailureAndTimeout()
        {
            var failed = AICodedbActivitySummaryBuilder.Build("Probe", new AICodedbCommandResult(1, string.Empty, "boom", false));
            var timedOut = AICodedbActivitySummaryBuilder.Build("Probe", new AICodedbCommandResult(-1, string.Empty, string.Empty, true));

            Assert.That(failed.State, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(failed.StatusLabel, Is.EqualTo("Failed"));
            Assert.That(failed.Detail, Is.EqualTo("boom"));
            Assert.That(timedOut.State, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(timedOut.StatusLabel, Is.EqualTo("Timed Out"));
        }

        [Test]
        public void Build_HostUpgradeRetainsInstallingAndSwitchingStages()
        {
            var summary = AICodedbActivitySummaryBuilder.Build(
                "Host Payload Upgrade",
                Result(
                    "[INSTALLING] Published immutable generation poc.22.\n" +
                    "[INSTALLING] Retained generation poc.21 as last known good.\n" +
                    "[SWITCHING] Published current generation pointer for poc.22.\n" +
                    "[OK] Start with Unity Editor: ENABLED\n" +
                    "[OK] Host payload upgrade completed."));

            Assert.That(summary.State, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(summary.StatusLabel, Is.EqualTo("Switched"));
            Assert.That(summary.ItemsTitle, Is.EqualTo("Upgrade stages"));
            Assert.That(summary.Items, Has.Length.EqualTo(3));
            Assert.That(summary.Items[1], Does.Contain("last known good"));
        }

        [Test]
        public void Build_HostUpgradeSurfacesRollbackStage()
        {
            var summary = AICodedbActivitySummaryBuilder.Build(
                "Host Payload Upgrade",
                new AICodedbCommandResult(
                    6,
                    "[INSTALLING] Published immutable generation poc.22.\n" +
                    "[SWITCHING] Published current generation pointer for poc.22.\n" +
                    "[ROLLBACK] Restoring the previous watcher selection.",
                    "Upgrade failed and was rolled back.",
                    false));

            Assert.That(summary.State, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(summary.StatusLabel, Is.EqualTo("Rolled Back"));
            Assert.That(summary.Detail, Does.Contain("previous watcher selection"));
            Assert.That(summary.Items, Has.Length.EqualTo(3));
        }

        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"watching\"}", AICodedbStatusState.Ok, "Enabled / Ready")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"pending\"}", AICodedbStatusState.Ok, "Enabled / Ready")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"building\"}", AICodedbStatusState.Ok, "Enabled / Ready")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"failed\"}", AICodedbStatusState.Warning, "Enabled / Stale")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\"}", AICodedbStatusState.Warning, "Enabled / Stale")]
        [TestCase("[OK] Watch opt-in: DISABLED\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Off")]
        [TestCase("[OK] Watch opt-in: DISABLED\n[OK] Automatic refresh: PAUSED\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Paused")]
        [TestCase("[OK] Watch opt-in: DISABLED\n[OK] Automatic refresh: PENDING\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Automatic / Waiting")]
        [TestCase("[OK] Watch opt-in: ENABLED\n[STALE] codedb watch coordinator stale.", AICodedbStatusState.Warning, "Enabled / Stale")]
        [TestCase("[OK] Watch opt-in: DISABLED\n[OK] codedb watch coordinator running.", AICodedbStatusState.Warning, "Off / Running")]
        [TestCase("[OK] Watch opt-in: ENABLED\n[OK] Editor demand: ONLINE (1)\n[OK] Automatic refresh: STARTING\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Enabled / Starting")]
        [TestCase("[OK] Watch opt-in: ENABLED\n[OK] Editor demand: OFFLINE (0)\n[OK] Automatic refresh: EDITOR_OFFLINE\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Enabled / Editor Offline")]
        [TestCase("[OK] Watch opt-in: UNKNOWN\n[OK] Automatic refresh: PENDING\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Setup Pending")]
        [TestCase("[OK] Start with Unity Editor: ENABLED\n[OK] Manual runtime: STOPPED\n[OK] Automatic refresh: MANUAL_STOPPED\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Stopped now")]
        [TestCase("[OK] Watch command completed.", AICodedbStatusState.Warning, "Unknown")]
        [TestCase("[OK] Watch opt-in: ENABLED", AICodedbStatusState.Warning, "Unknown")]
        [TestCase("[OK] Watch opt-in: DISABLED", AICodedbStatusState.Warning, "Unknown")]
        public void Build_MapsWatcherStates(string output, AICodedbStatusState state, string label)
        {
            var summary = AICodedbActivitySummaryBuilder.Build("Watcher Status", Result(output));
            Assert.That(summary.State, Is.EqualTo(state));
            Assert.That(summary.StatusLabel, Is.EqualTo(label));
        }

        private static AICodedbCommandResult Result(string output)
        {
            return new AICodedbCommandResult(0, output, string.Empty, false, 10);
        }
    }

    internal sealed class AICodedbWatcherStatusBuilderTests
    {
        [TestCase(
            "[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"watching\"}",
            AICodedbWatcherState.Ready,
            AICodedbStatusState.Ok,
            true,
            true)]
        [TestCase(
            "[OK] Watch opt-in: DISABLED\n[STOPPED] codedb watch coordinator stopped.",
            AICodedbWatcherState.Disabled,
            AICodedbStatusState.Inactive,
            true,
            false)]
        [TestCase(
            "[OK] Watch opt-in: DISABLED\n[OK] Automatic refresh: PAUSED\n[STOPPED] codedb watch coordinator stopped.",
            AICodedbWatcherState.Paused,
            AICodedbStatusState.Inactive,
            true,
            false)]
        [TestCase(
            "[OK] Watch opt-in: DISABLED\n[OK] Automatic refresh: PENDING\n[STOPPED] codedb watch coordinator stopped.",
            AICodedbWatcherState.Pending,
            AICodedbStatusState.Inactive,
            true,
            true)]
        [TestCase(
            "[OK] Watch opt-in: ENABLED\n[STALE] codedb watch coordinator stale.",
            AICodedbWatcherState.Stale,
            AICodedbStatusState.Warning,
            true,
            true)]
        [TestCase(
            "[OK] Watch opt-in: DISABLED\n[OK] codedb watch coordinator running.",
            AICodedbWatcherState.DisabledRunning,
            AICodedbStatusState.Warning,
            true,
            false)]
        [TestCase(
            "[OK] Watch opt-in: ENABLED\n[OK] Editor demand: ONLINE (1)\n[OK] Automatic refresh: STARTING\n[STOPPED] codedb watch coordinator stopped.",
            AICodedbWatcherState.Starting,
            AICodedbStatusState.Inactive,
            true,
            true)]
        [TestCase(
            "[OK] Watch opt-in: ENABLED\n[OK] Editor demand: OFFLINE (0)\n[OK] Automatic refresh: EDITOR_OFFLINE\n[STOPPED] codedb watch coordinator stopped.",
            AICodedbWatcherState.EditorOffline,
            AICodedbStatusState.Inactive,
            true,
            true)]
        [TestCase(
            "[OK] Watch opt-in: UNKNOWN\n[OK] Automatic refresh: PENDING\n[STOPPED] codedb watch coordinator stopped.",
            AICodedbWatcherState.Pending,
            AICodedbStatusState.Inactive,
            false,
            false)]
        [TestCase(
            "[OK] Watch command completed.",
            AICodedbWatcherState.Unknown,
            AICodedbStatusState.Warning,
            false,
            false)]
        public void Build_MapsDesiredAndActualState(
            string output,
            AICodedbWatcherState expectedState,
            AICodedbStatusState expectedDisplayState,
            bool expectedKnownOptIn,
            bool expectedEnabled)
        {
            var status = AICodedbWatcherStatusBuilder.Build(Result(output));

            Assert.That(status.State, Is.EqualTo(expectedState));
            Assert.That(status.DisplayState, Is.EqualTo(expectedDisplayState));
            Assert.That(status.HasKnownOptIn, Is.EqualTo(expectedKnownOptIn));
            Assert.That(status.IsOptInEnabled, Is.EqualTo(expectedEnabled));
        }

        [Test]
        public void Build_MapsFailureAndTimeoutToError()
        {
            var failed = AICodedbWatcherStatusBuilder.Build(
                new AICodedbCommandResult(2, string.Empty, "watch failed", false));
            var timedOut = AICodedbWatcherStatusBuilder.Build(
                new AICodedbCommandResult(-1, string.Empty, string.Empty, true));

            Assert.That(failed.State, Is.EqualTo(AICodedbWatcherState.Error));
            Assert.That(failed.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(failed.Detail, Is.EqualTo("watch failed"));
            Assert.That(timedOut.State, Is.EqualTo(AICodedbWatcherState.Error));
            Assert.That(timedOut.Label, Is.EqualTo("Timed Out"));
        }

        [Test]
        public void Build_ManualStoppedRequiresStoppedCoordinator()
        {
            var stopped = AICodedbWatcherStatusBuilder.Build(Result(
                "[OK] Start with Unity Editor: ENABLED\n" +
                "[OK] Manual runtime: STOPPED\n" +
                "[OK] Automatic refresh: MANUAL_STOPPED\n" +
                "[STOPPED] codedb watch coordinator stopped."));
            var running = AICodedbWatcherStatusBuilder.Build(Result(
                "[OK] Start with Unity Editor: ENABLED\n" +
                "[OK] Manual runtime: STOPPED\n" +
                "[OK] Automatic refresh: MANUAL_STOPPED\n" +
                "{\"action\":\"running\",\"provider_state\":\"starting\"}"));

            Assert.That(stopped.State, Is.EqualTo(AICodedbWatcherState.ManualStopped));
            Assert.That(stopped.DisplayState, Is.EqualTo(AICodedbStatusState.Inactive));
            Assert.That(stopped.IsManualStopped, Is.True);
            Assert.That(running.State, Is.EqualTo(AICodedbWatcherState.Stale));
            Assert.That(running.DisplayState, Is.EqualTo(AICodedbStatusState.Warning));
        }

        private static AICodedbCommandResult Result(string output)
        {
            return new AICodedbCommandResult(0, output, string.Empty, false, 10);
        }
    }

    internal sealed class AICodedbActivityPanelTests
    {
        [TestCase(AICodedbStatusState.Ok, false)]
        [TestCase(AICodedbStatusState.Inactive, false)]
        [TestCase(AICodedbStatusState.Warning, true)]
        [TestCase(AICodedbStatusState.Error, true)]
        public void ShouldExpandOutput_UsesSeverity(AICodedbStatusState state, bool expected)
        {
            Assert.That(AICodedbActivityPanel.ShouldExpandOutput(state), Is.EqualTo(expected));
        }

        [TestCase(850f, 640f)]
        [TestCase(360f, 150f)]
        [TestCase(220f, 24f)]
        [TestCase(-1f, 24f)]
        [TestCase(float.NaN, 24f)]
        public void ResolveOutputViewportHeight_UsesAvailablePanelHeight(float activityHeight, float expected)
        {
            Assert.That(AICodedbActivityPanel.ResolveOutputViewportHeight(activityHeight), Is.EqualTo(expected));
        }
    }

    internal sealed class AICodedbHostPayloadStatusBuilderTests
    {
        [Test]
        public void Build_MapsCurrentPayload()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result("[PLAN] Current: AIWork/codedb/example.ps1\n[OK] Host payload is current."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Current));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(status.Summary, Is.EqualTo("CURRENT"));
            Assert.That(status.IsCurrent, Is.True);
        }

        [Test]
        public void Build_CurrentGenerationOwnersRemainCurrentAndAreAllRetained()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[ACTIVE] generation poc.22 mcp PID 101\n" +
                    "[ACTIVE] generation poc.22 watcher PID 202\n" +
                    "[BLOCKED] Host payload Sync/Remove is blocked.\n" +
                    "[OK] Host payload is current."),
                "poc.22");

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Current));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(status.ActiveOwners, Is.EqualTo(new[]
            {
                "[ACTIVE] generation poc.22 mcp PID 101",
                "[ACTIVE] generation poc.22 watcher PID 202"
            }));
            Assert.That(status.LegacyMcpSessionCount, Is.Zero);
        }

        [Test]
        public void Build_LegacyAndPreviousGenerationOwnersMapCurrentPayloadToDraining()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[ACTIVE] mcp PID 101\n" +
                    "[ACTIVE] watcher PID 202\n" +
                    "[ACTIVE] generation poc.21 mcp PID 303\n" +
                    "[ACTIVE] generation poc.22 watcher PID 404\n" +
                    "[OK] Host payload is current."),
                "poc.22");

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Draining));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(status.Summary, Is.EqualTo("CURRENT / DRAINING"));
            Assert.That(status.Detail, Does.Contain("no action is required"));
            Assert.That(status.IsCurrent, Is.True);
            Assert.That(status.ActiveOwners, Is.EqualTo(new[]
            {
                "[ACTIVE] mcp PID 101",
                "[ACTIVE] watcher PID 202",
                "[ACTIVE] generation poc.21 mcp PID 303",
                "[ACTIVE] generation poc.22 watcher PID 404"
            }));
            Assert.That(status.LegacyMcpSessionCount, Is.EqualTo(1));
        }

        [TestCase(AICodedbHostPayloadState.Draining, AICodedbHostUpgradePhase.Current, false, true, ExpectedResult = true)]
        [TestCase(AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.Unavailable, true, false, ExpectedResult = true)]
        [TestCase(AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.Unavailable, false, false, ExpectedResult = false)]
        [TestCase(AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.CheckFailed, true, true, ExpectedResult = false)]
        [TestCase(AICodedbHostPayloadState.Blocked, AICodedbHostUpgradePhase.Switching, true, false, ExpectedResult = true)]
        [TestCase(AICodedbHostPayloadState.Current, AICodedbHostUpgradePhase.Current, true, false, ExpectedResult = false)]
        public bool ShouldAutoObserveHostStatus_TracksOnlyAutomaticOrTransientStates(
            AICodedbHostPayloadState payloadState,
            AICodedbHostUpgradePhase upgradePhase,
            bool automaticUpdatesEnabled,
            bool automaticUpgradeSuppressed)
        {
            return AICodedbManagerWindow.ShouldAutoObserveHostStatus(
                payloadState,
                upgradePhase,
                automaticUpdatesEnabled,
                automaticUpgradeSuppressed);
        }

        [Test]
        public void ManagerPresentation_PrioritizesFailedCurrentGenerationAndOffersRetry()
        {
            var failedCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.26",
                "CHECK_FAILED / poc.26",
                "fixture failure");
            var failedPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.25",
                "CHECK_FAILED / poc.25",
                "historical failure");
            var invalid = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Invalid,
                AICodedbStatusState.Error,
                string.Empty,
                "CHECK_FAILED",
                "invalid state");

            Assert.That(AICodedbManagerWindow.IsCurrentHostUpgradeFailure(failedCurrent, "poc.26"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeActionLabel(failedCurrent, "poc.26"), Is.EqualTo("Retry update"));
            Assert.That(AICodedbManagerWindow.IsCurrentHostUpgradeFailure(failedPrevious, "poc.26"), Is.False);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeActionLabel(failedPrevious, "poc.26"), Is.EqualTo("Update now"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(invalid, "poc.26"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeActionLabel(invalid, "poc.26"), Is.EqualTo("Retry update"));
        }

        [Test]
        public void ManagerPresentation_PrioritizesOnlyCurrentTransientUpgradePhases()
        {
            var installingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Installing,
                AICodedbStatusState.Warning,
                "poc.26",
                "INSTALLING / poc.26",
                "installing");
            var switchingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Switching,
                AICodedbStatusState.Warning,
                "poc.26",
                "SWITCHING / poc.26",
                "switching");
            var rollbackCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Rollback,
                AICodedbStatusState.Error,
                "poc.26",
                "ROLLBACK / poc.26",
                "rollback");
            var installingPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Installing,
                AICodedbStatusState.Warning,
                "poc.25",
                "INSTALLING / poc.25",
                "historical install");

            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(installingCurrent, "poc.26"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeStatusLabel(installingCurrent.Phase), Is.EqualTo("INSTALLING"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(switchingCurrent, "poc.26"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeStatusLabel(switchingCurrent.Phase), Is.EqualTo("SWITCHING"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(rollbackCurrent, "poc.26"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeStatusLabel(rollbackCurrent.Phase), Is.EqualTo("ROLLBACK"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(installingPrevious, "poc.26"), Is.False);
        }

        [TestCase(false, AICodedbHostPayloadState.SetupRequired, "SETUP_REQUIRED")]
        [TestCase(true, AICodedbHostPayloadState.UpdateRequired, "UPDATE_REQUIRED")]
        public void Build_UsesMarkerToDistinguishMissingAndStale(
            bool markerExists,
            AICodedbHostPayloadState expectedState,
            string expectedSummary)
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                markerExists,
                Result("[PLAN] Missing: AIWork/codedb/example.ps1\n[STALE] Host payload can be synchronized without overwriting unowned changes."));

            Assert.That(status.State, Is.EqualTo(expectedState));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Warning));
            Assert.That(status.Summary, Is.EqualTo(expectedSummary));
        }

        [Test]
        public void Build_MapsConflictBeforeStaleSummary()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result("[CONFLICT] ManagedDrift: AIWork/codedb/example.ps1\n[STALE] Host payload has conflicts; Sync would be rejected."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Conflict));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(status.Summary, Is.EqualTo("CONFLICT"));
            Assert.That(status.Detail, Does.StartWith("[CONFLICT]"));
        }

        [Test]
        public void Build_MapsActiveLeaseToBlockedUpdate()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result("[PLAN] Upgradeable: AIWork/codedb/example.ps1\n[ACTIVE] watcher PID 1234\n[BLOCKED] Host payload Sync/Remove is blocked.\n[STALE] Host payload can be synchronized without overwriting unowned changes."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Blocked));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(status.Summary, Is.EqualTo("UPDATE_REQUIRED / BLOCKED"));
            Assert.That(status.Detail, Is.EqualTo("[ACTIVE] watcher PID 1234"));
        }

        [Test]
        public void Build_MapsFailedDryRunToUnknownError()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                new AICodedbCommandResult(2, string.Empty, "Installed payload marker is invalid.", false));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Unknown));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(status.Summary, Is.EqualTo("Check Failed"));
            Assert.That(status.Detail, Is.EqualTo("Installed payload marker is invalid."));
        }

        private static AICodedbCommandResult Result(string output)
        {
            return new AICodedbCommandResult(0, output, string.Empty, false, 10);
        }
    }

    internal sealed class AICodedbHostPayloadMaterializerTests
    {
        [TestCase(AICodedbHostPayloadAction.DryRun)]
        [TestCase(AICodedbHostPayloadAction.Verify)]
        [TestCase(AICodedbHostPayloadAction.Upgrade)]
        public void BuildScriptArguments_ReadOnlyActionsHaveNoAuthorization(
            AICodedbHostPayloadAction action)
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(action, string.Empty, false);

            Assert.That(arguments, Does.Contain("-ProjectRoot"));
            Assert.That(arguments, Does.Not.Contain("-TrackedHostAuthorizationPath"));
            Assert.That(arguments, Does.Not.Contain("-ConfirmLegacyMcpStopped"));
            Assert.That(arguments, Does.Not.Contain("-PocFixture"));
        }

        [Test]
        public void BuildScriptArguments_ReadOnlyActionsRejectAuthorization()
        {
            var authorizationPath = Path.Combine(AICodedbPaths.TrackedHostAuthorizationPath, "reviewed.json");
            Assert.Throws<ArgumentException>(() =>
                AICodedbHostPayloadMaterializer.BuildScriptArguments(
                    AICodedbHostPayloadAction.DryRun,
                    authorizationPath,
                    false));
        }

        [TestCase(AICodedbHostPayloadAction.Sync, "")]
        [TestCase(AICodedbHostPayloadAction.Sync, "relative.json")]
        [TestCase(AICodedbHostPayloadAction.Remove, "")]
        [TestCase(AICodedbHostPayloadAction.Remove, "relative.json")]
        public void BuildScriptArguments_MutationsRequireExplicitAbsoluteAuthorization(
            AICodedbHostPayloadAction action,
            string authorizationPath)
        {
            Assert.Throws<ArgumentException>(() =>
                AICodedbHostPayloadMaterializer.BuildScriptArguments(
                    action,
                    authorizationPath,
                    false));
        }

        [Test]
        public void BuildScriptArguments_SyncUsesOnlyReviewedAuthorizationAndConfirmation()
        {
            var authorizationPath = Path.Combine(AICodedbPaths.TrackedHostAuthorizationPath, "reviewed.json");
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Sync,
                authorizationPath,
                true);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Sync",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot,
                "-TrackedHostAuthorizationPath",
                authorizationPath,
                "-ConfirmLegacyMcpStopped"
            }));
        }

        [Test]
        public void BuildScriptArguments_UpgradeUsesExactActionAndProjectRoot()
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Upgrade,
                string.Empty,
                false);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Upgrade",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot
            }));
        }
    }

    internal sealed class AICodedbHostUpgradeStatusStoreTests
    {
        [TestCase("INSTALLING", AICodedbHostUpgradePhase.Installing, AICodedbStatusState.Warning)]
        [TestCase("SWITCHING", AICodedbHostUpgradePhase.Switching, AICodedbStatusState.Warning)]
        [TestCase("ROLLBACK", AICodedbHostUpgradePhase.Rollback, AICodedbStatusState.Error)]
        [TestCase("CURRENT", AICodedbHostUpgradePhase.Current, AICodedbStatusState.Ok)]
        [TestCase("CHECK_FAILED", AICodedbHostUpgradePhase.CheckFailed, AICodedbStatusState.Error)]
        public void Parse_MapsPersistedUpgradePhase(
            string phase,
            AICodedbHostUpgradePhase expectedPhase,
            AICodedbStatusState expectedState)
        {
            var projectRoot = AICodedbPaths.ProjectRoot;
            var status = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson(phase, projectRoot),
                projectRoot,
                "upgrade-state.json");

            Assert.That(status.Phase, Is.EqualTo(expectedPhase));
            Assert.That(status.DisplayState, Is.EqualTo(expectedState));
            Assert.That(status.GenerationId, Is.EqualTo("poc.22"));
            Assert.That(status.Summary, Is.EqualTo(phase + " / poc.22"));
            Assert.That(status.Detail, Is.EqualTo("upgrade detail"));
        }

        [Test]
        public void Parse_FailsClosedForWrongProjectIdentity()
        {
            var status = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson("CURRENT", Path.Combine(AICodedbPaths.ProjectRoot, "other")),
                AICodedbPaths.ProjectRoot,
                "upgrade-state.json");

            Assert.That(status.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Invalid));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
        }

        [Test]
        public void ToStatusItem_MarksPersistedCurrentAsHistoricalWithoutInstalledMarker()
        {
            var projectRoot = AICodedbPaths.ProjectRoot;
            var status = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson("CURRENT", projectRoot),
                projectRoot,
                "upgrade-state.json");

            var item = status.ToStatusItem(false);

            Assert.That(item.State, Is.EqualTo(AICodedbStatusState.Inactive));
            Assert.That(item.Summary, Is.EqualTo("Historical CURRENT / poc.22"));
            Assert.That(item.Detail, Does.StartWith("No installed host payload marker exists."));
        }

        private static string UpgradeStateJson(string phase, string projectRoot)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot);
            return "{\"schema_version\":1," +
                   "\"managed_by\":\"com.rice.ai-codedb\"," +
                   "\"project_root\":\"" + normalizedRoot + "\"," +
                   "\"state\":\"" + phase + "\"," +
                   "\"generation_id\":\"poc.22\"," +
                   "\"updated_at_utc\":\"" + DateTime.UtcNow.ToString("o") + "\"," +
                   "\"message\":\"upgrade detail\"}";
        }
    }

    internal sealed class AICodedbLifecycleControlTests
    {
        [TestCase("Enable")]
        [TestCase("Disable")]
        [TestCase("Start")]
        [TestCase("Stop")]
        [TestCase("Restart")]
        public void BuildWatcherScriptArguments_UsesExactAction(string action)
        {
            Assert.That(
                AICodedbActions.BuildWatcherScriptArguments(action),
                Is.EqualTo(new[] { "-Action", action }));
        }

        [Test]
        public void LegacyGenerationDisablesLifecycleAndRepairActions()
        {
            Assert.That(
                AICodedbManagerWindow.CanUseLifecycleControls(AICodedbHostGenerationState.Legacy),
                Is.False);
            Assert.That(
                AICodedbManagerWindow.ResolveWatcherRepairLabel(
                    AICodedbHostGenerationState.Legacy,
                    AICodedbWatcherState.Stale),
                Is.Empty);
            Assert.That(
                AICodedbManagerWindow.CanUseLifecycleControls(AICodedbHostGenerationState.Current),
                Is.True);
            Assert.That(
                AICodedbManagerWindow.ResolveWatcherRepairLabel(
                    AICodedbHostGenerationState.Current,
                    AICodedbWatcherState.Stale),
                Is.EqualTo("Repair watcher"));
        }
    }

    internal sealed class AICodedbManagerLayoutTests
    {
        private const float PanelHorizontalMargin = 8f;

        [Test]
        public void Resolve_WideLayoutAccountsForBothPanelMargins()
        {
            var layout = AICodedbManagerLayout.Resolve(1200f, 800f, 340f, PanelHorizontalMargin);
            Assert.That(layout.Mode, Is.EqualTo(AICodedbManagerLayoutMode.Wide));
            Assert.That(layout.MainContentWidth, Is.EqualTo(838f));
            Assert.That(layout.ActivityWidth, Is.EqualTo(340f));
            Assert.That(layout.ActivityHeight, Is.EqualTo(800f));
            Assert.That(
                layout.MainContentWidth
                + layout.ActivityWidth
                + layout.SplitterWidth
                + (PanelHorizontalMargin * 2f),
                Is.EqualTo(1200f));
        }

        [Test]
        public void Resolve_UsesWideModeAtDerivedBreakpoint()
        {
            var width = AICodedbManagerLayout.WideLayoutMinWidth + (PanelHorizontalMargin * 2f);
            var layout = AICodedbManagerLayout.Resolve(width, 800f, 0f, PanelHorizontalMargin);
            Assert.That(layout.IsWide, Is.True);
            Assert.That(layout.MainContentWidth, Is.EqualTo(AICodedbManagerLayout.MainContentMinWidth));
            Assert.That(layout.ActivityWidth, Is.EqualTo(AICodedbManagerLayout.ActivityMinWidth));
        }

        [Test]
        public void Resolve_CompactLayoutAccountsForOnePanelMargin()
        {
            var layout = AICodedbManagerLayout.Resolve(700f, 600f, 340f, PanelHorizontalMargin);
            Assert.That(layout.Mode, Is.EqualTo(AICodedbManagerLayoutMode.Compact));
            Assert.That(layout.MainContentWidth, Is.EqualTo(692f));
            Assert.That(layout.ActivityWidth + PanelHorizontalMargin, Is.EqualTo(700f));
            Assert.That(layout.ActivityHeight, Is.InRange(220f, 360f));
            Assert.That(layout.SplitterWidth, Is.Zero);
        }

        [Test]
        public void Resolve_ExtremeDimensionsRemainNonNegative()
        {
            var layout = AICodedbManagerLayout.Resolve(100f, 100f, float.NaN, 200f);
            Assert.That(layout.MainContentWidth, Is.Zero);
            Assert.That(layout.ActivityWidth, Is.Zero);
            Assert.That(layout.ActivityHeight, Is.EqualTo(100f));
        }

        [Test]
        public void Resolve_ClampsPreferredActivityWidth()
        {
            var low = AICodedbManagerLayout.Resolve(1400f, 800f, 10f, PanelHorizontalMargin);
            var high = AICodedbManagerLayout.Resolve(1400f, 800f, 2000f, PanelHorizontalMargin);
            Assert.That(low.ActivityWidth, Is.EqualTo(AICodedbManagerLayout.ActivityMinWidth));
            Assert.That(high.ActivityWidth, Is.EqualTo(AICodedbManagerLayout.ActivityMaxWidth));
        }

        [Test]
        public void Resolve_InvalidPanelMarginFallsBackToZero()
        {
            var layout = AICodedbManagerLayout.Resolve(1200f, 800f, 340f, float.NaN);
            Assert.That(layout.MainContentWidth + layout.ActivityWidth + layout.SplitterWidth, Is.EqualTo(1200f));
        }
    }

    internal sealed class AICodedbActionGridViewTests
    {
        [TestCase(656f, 5, 5, 5)]
        [TestCase(655f, 5, 5, 3)]
        [TestCase(392f, 3, 3, 3)]
        [TestCase(260f, 3, 3, 2)]
        [TestCase(127f, 3, 3, 1)]
        public void ResolveColumns_UsesStableFallbacks(float width, int preferred, int count, int expected)
        {
            Assert.That(AICodedbActionGridView.ResolveColumns(width, preferred, count), Is.EqualTo(expected));
        }
    }
}
