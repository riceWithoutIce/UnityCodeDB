using System;
using System.IO;
using System.Text;
using NUnit.Framework;
using UnityEditor.PackageManager;

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
            Assert.That(AICodedbProjectSettings.ProjectIntegrationStateRelativePath, Is.EqualTo("AIWork/.runtime/codedb/payload-materializer/integration-state.json"));
            Assert.That(AICodedbProjectSettings.McpAvailabilityStateRelativePath, Is.EqualTo("AIWork/.runtime/codedb/payload-materializer/mcp-availability.json"));
            Assert.That(AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath, Is.EqualTo("Tools~/materialize-codedb-host-payload.ps1"));
        }

        [Test]
        public void PackagePaths_UseUnityResolvedPackageLocation()
        {
            var packageInfo = PackageInfo.FindForAssembly(typeof(AICodedbPaths).Assembly);

            Assert.That(packageInfo, Is.Not.Null);
            Assert.That(packageInfo.name, Is.EqualTo(AICodedbProjectSettings.PackageName));
            Assert.That(packageInfo.resolvedPath, Is.Not.Empty);
            Assert.That(
                AICodedbPaths.PackageRootPath,
                Is.EqualTo(AICodedbPaths.NormalizePath(packageInfo.resolvedPath)));
            Assert.That(
                AICodedbPaths.HostPayloadMaterializerScriptPath,
                Is.EqualTo(AICodedbPaths.NormalizePath(Path.Combine(
                    packageInfo.resolvedPath,
                    AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath))));
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

    internal sealed class AICodedbProductStatusTests
    {
        private static readonly AICodedbProjectIntegrationStatus Installed =
            new AICodedbProjectIntegrationStatus(
                AICodedbProjectIntegrationState.Installed,
                AICodedbProjectCleanupState.None,
                string.Empty,
                "installed");

        [Test]
        public void Build_RequiresEveryProductLayerBeforeReady()
        {
            var result = Result(
                "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                "[PRODUCT_LAYER MCP_AVAILABLE] PENDING\n" +
                "[PRODUCT_STATE] READY\n");

            var status = AICodedbProductStatusBuilder.Build(Installed, result);

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.Starting));
            Assert.That(status.Installed, Is.EqualTo(AICodedbProductLayerState.Current));
            Assert.That(status.Configured, Is.EqualTo(AICodedbProductLayerState.Current));
            Assert.That(status.McpAvailable, Is.EqualTo(AICodedbProductLayerState.Pending));
            Assert.That(status.IsReady, Is.False);
        }

        [Test]
        public void CreateStarting_ManagerFirstFrameDoesNotRunOrClaimCompleteStatus()
        {
            var snapshot = AICodedbStatusSnapshot.CreateStarting("FixtureProject");

            Assert.That(snapshot.ProductStatus.State, Is.EqualTo(AICodedbProductState.Starting));
            Assert.That(snapshot.ProductStatus.IsReady, Is.False);
            Assert.That(snapshot.HostPayloadStatus.Summary, Is.EqualTo("Checking"));
            Assert.That(snapshot.OverallTitle, Is.EqualTo("FixtureProject · Starting"));
            Assert.That(snapshot.OverallDescription, Does.Contain("background"));
        }

        [Test]
        public void Build_MapsVerifiedPackageHandshakeToReady()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                Result(
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                    "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                    "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT\n" +
                    "[PRODUCT_STATE] READY\n"));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.Ready));
            Assert.That(status.IsReady, Is.True);
        }

        [Test]
        public void Build_FailedCommandCannotClaimReady()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                new AICodedbCommandResult(
                    8,
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                    "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                    "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT\n" +
                    "[PRODUCT_STATE] READY\n",
                    "probe failed",
                    false));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(status.IsReady, Is.False);
        }

        [Test]
        public void Build_UnavailableHandshakeNeedsAttention()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                Result(
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                    "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                    "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE - initialize failed\n" +
                    "[PRODUCT_STATE] NEEDS_ATTENTION\n"));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(status.McpAvailable, Is.EqualTo(AICodedbProductLayerState.Unavailable));
        }

        [TestCase(AICodedbProductState.Starting, true, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Ready, true, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.NeedsAttention, true, false, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NeedsAttention, false, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, false, false, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Uninstalled, true, true, ExpectedResult = false)]
        [TestCase(AICodedbProductState.MissingPrerequisite, true, false, ExpectedResult = false)]
        public bool ResolvePrimaryAction_ExposesOnlyOneContextualUserAction(
            AICodedbProductState state,
            bool reinstallAvailable,
            bool actionInFlight)
        {
            return AICodedbManagerWindow.ResolvePrimaryAction(
                state,
                reinstallAvailable,
                actionInFlight);
        }

        [Test]
        public void Build_CombinesValidatedCommandResultWithReadiness()
        {
            const string command =
                "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"action\":\"REPAIR\",\"outcome\":\"REPAIRED\",\"phase\":\"COMPLETE\",\"reason_code\":\"REPAIR_COMPLETE\",\"mutated_scopes\":[\"host_runtime\",\"mcp_registration\"],\"cleanup_state\":\"COMPLETE\",\"next_action\":\"Start a new Codex task.\",\"exit_code\":0,\"detail\":\"\"}";
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                Result(
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                    "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                    "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT\n" +
                    "[PRODUCT_STATE] READY\n" +
                    command));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.Ready));
            Assert.That(status.Command.Present, Is.True);
            Assert.That(status.Command.IsValid, Is.True);
            Assert.That(status.Command.Outcome, Is.EqualTo("REPAIRED"));
            Assert.That(status.Command.MutatedScopes, Is.EqualTo(new[] { "host_runtime", "mcp_registration" }));
        }

        [Test]
        public void Build_InvalidOrMismatchedCommandResultCannotClaimReady()
        {
            const string ready =
                "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT\n" +
                "[PRODUCT_STATE] READY\n";
            const string mismatched =
                "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"action\":\"REPAIR\",\"outcome\":\"REPAIRED\",\"phase\":\"COMPLETE\",\"reason_code\":\"REPAIR_COMPLETE\",\"mutated_scopes\":[],\"cleanup_state\":\"COMPLETE\",\"next_action\":\"No action required.\",\"exit_code\":4,\"detail\":\"\"}";

            var mismatchStatus = AICodedbProductStatusBuilder.Build(Installed, Result(ready + mismatched));
            var duplicateStatus = AICodedbProductStatusBuilder.Build(
                Installed,
                Result(ready + mismatched + "\n" + mismatched));

            Assert.That(mismatchStatus.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(duplicateStatus.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(duplicateStatus.Command.IsValid, Is.False);
        }

        [Test]
        public void Build_MissingPrerequisitePreservesOneGuidanceAndNoFixAction()
        {
            const string command =
                "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"action\":\"UPGRADE\",\"outcome\":\"BLOCKED\",\"phase\":\"PREFLIGHT\",\"reason_code\":\"PROVIDER_MISSING\",\"mutated_scopes\":[],\"cleanup_state\":\"COMPLETE\",\"next_action\":\"Install the reviewed machine Provider, then let Unity recheck automatically.\",\"exit_code\":4,\"detail\":\"Provider missing.\"}";
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                new AICodedbCommandResult(
                    4,
                    "[PRODUCT_LAYER PREREQUISITE] MISSING - Provider missing.\n" +
                    "[PRODUCT_STATE] MISSING_PREREQUISITE\n" +
                    command,
                    "Provider missing.",
                    false));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.MissingPrerequisite));
            Assert.That(status.Command.ReasonCode, Is.EqualTo("PROVIDER_MISSING"));
            Assert.That(status.Command.MutatedScopes, Is.Empty);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status.State, true, false), Is.False);
        }

        private static AICodedbCommandResult Result(string output)
        {
            return new AICodedbCommandResult(0, output, string.Empty, false);
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
            var content = AICodedbBrandAssets.CreatePackageVersionContent("0.2.4");

            Assert.That(content.text, Is.EqualTo("Package v0.2.4"));
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
                "poc.30",
                "CHECK_FAILED / poc.30",
                "fixture failure");
            var failedPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.29",
                "CHECK_FAILED / poc.29",
                "historical failure");
            var invalid = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Invalid,
                AICodedbStatusState.Error,
                string.Empty,
                "CHECK_FAILED",
                "invalid state");

            Assert.That(AICodedbManagerWindow.IsCurrentHostUpgradeFailure(failedCurrent, "poc.30"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeActionLabel(failedCurrent, "poc.30"), Is.EqualTo("Retry update"));
            Assert.That(AICodedbManagerWindow.IsCurrentHostUpgradeFailure(failedPrevious, "poc.30"), Is.False);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeActionLabel(failedPrevious, "poc.30"), Is.EqualTo("Update now"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(invalid, "poc.30"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeActionLabel(invalid, "poc.30"), Is.EqualTo("Retry update"));
        }

        [Test]
        public void ManagerPresentation_PrioritizesOnlyCurrentTransientUpgradePhases()
        {
            var installingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Installing,
                AICodedbStatusState.Warning,
                "poc.30",
                "INSTALLING / poc.30",
                "installing");
            var switchingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Switching,
                AICodedbStatusState.Warning,
                "poc.30",
                "SWITCHING / poc.30",
                "switching");
            var rollbackCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Rollback,
                AICodedbStatusState.Error,
                "poc.30",
                "ROLLBACK / poc.30",
                "rollback");
            var installingPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Installing,
                AICodedbStatusState.Warning,
                "poc.29",
                "INSTALLING / poc.29",
                "historical install");

            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(installingCurrent, "poc.30"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeStatusLabel(installingCurrent.Phase), Is.EqualTo("INSTALLING"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(switchingCurrent, "poc.30"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeStatusLabel(switchingCurrent.Phase), Is.EqualTo("SWITCHING"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(rollbackCurrent, "poc.30"), Is.True);
            Assert.That(AICodedbManagerWindow.GetHostUpgradeStatusLabel(rollbackCurrent.Phase), Is.EqualTo("ROLLBACK"));
            Assert.That(AICodedbManagerWindow.ShouldPrioritizeHostUpgradeStatus(installingPrevious, "poc.30"), Is.False);
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
        public void Build_MapsOwnedLegacyPayloadToRedeployRequired()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[REDEPLOY_READY] Owned payload poc.16 can redeploy to generation poc.30 after MCP and watcher owners stop.\n" +
                    "[STALE] Host payload requires a controlled legacy redeploy."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.RedeployRequired));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Warning));
            Assert.That(status.Summary, Is.EqualTo("REDEPLOY_REQUIRED"));
            Assert.That(status.CanRedeploy, Is.True);
        }

        [Test]
        public void Build_RetainsRedeployActionWhileLegacyOwnersBlockMutation()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[ACTIVE] mcp PID 101\n" +
                    "[ACTIVE] watcher PID 202\n" +
                    "[BLOCKED] Host payload Sync/Remove is blocked.\n" +
                    "[REDEPLOY_READY] Owned payload poc.16 can redeploy to generation poc.30 after MCP and watcher owners stop.\n" +
                    "[STALE] Host payload requires a controlled legacy redeploy."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Blocked));
            Assert.That(status.CanRedeploy, Is.True);
            Assert.That(status.LegacyMcpSessionCount, Is.EqualTo(1));
            Assert.That(status.ActiveMcpSessionCount, Is.EqualTo(1));
            Assert.That(status.LegacyWatcherCount, Is.EqualTo(1));
            Assert.That(status.HasOnlyLegacyWatcherOwners, Is.False);
            Assert.That(status.ActiveOwners.Length, Is.EqualTo(2));
        }

        [Test]
        public void Build_AllowsRedeployFlowToStopRecognizedLegacyWatcherOwner()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[ACTIVE] watcher PID 202\n" +
                    "[BLOCKED] Host payload Sync/Remove is blocked.\n" +
                    "[REDEPLOY_READY] Owned payload poc.16 can redeploy to generation poc.30 after MCP and watcher owners stop.\n" +
                    "[STALE] Host payload requires a controlled legacy redeploy."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Blocked));
            Assert.That(status.CanRedeploy, Is.True);
            Assert.That(status.ActiveMcpSessionCount, Is.Zero);
            Assert.That(status.LegacyWatcherCount, Is.EqualTo(1));
            Assert.That(status.HasOnlyLegacyWatcherOwners, Is.True);
        }

        [Test]
        public void Build_GenerationMcpOwnerRemainsExternalRedeployBlocker()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[ACTIVE] generation poc.29 mcp PID 303\n" +
                    "[BLOCKED] Host payload Sync/Remove is blocked.\n" +
                    "[REDEPLOY_READY] Owned payload poc.16 can redeploy to generation poc.30 after MCP and watcher owners stop."));

            Assert.That(status.CanRedeploy, Is.True);
            Assert.That(status.ActiveMcpSessionCount, Is.EqualTo(1));
            Assert.That(status.LegacyWatcherCount, Is.Zero);
            Assert.That(status.HasOnlyLegacyWatcherOwners, Is.False);
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
        [Test]
        public void PackageMaterializerAuthorization_AcceptsUnityResolvedExactScript()
        {
            string authorizedPath;
            string error;

            var authorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                AICodedbPaths.PackageRootPath,
                AICodedbPaths.HostPayloadMaterializerScriptPath,
                out authorizedPath,
                out error);

            Assert.That(authorized, Is.True, error);
            Assert.That(authorizedPath, Is.EqualTo(AICodedbPaths.HostPayloadMaterializerScriptPath));
        }

        [Test]
        public void PackageMaterializerAuthorization_AcceptsExactExternalLocalPackageScript()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                var scriptPath = CreateMaterializerScript(packageRoot);
                string authorizedPath;
                string error;

                Assert.That(AICodedbPaths.IsInsideProject(packageRoot), Is.False);
                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                    packageRoot,
                    scriptPath,
                    out authorizedPath,
                    out error);

                Assert.That(authorized, Is.True, error);
                Assert.That(authorizedPath, Is.EqualTo(AICodedbPaths.NormalizePath(scriptPath)));
            }
            finally
            {
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [Test]
        public void MaterializerStatusEntryPoints_StartTheUnityResolvedPackageScript()
        {
            TestContext.WriteLine(
                "Unity resolved Package root: " + AICodedbPaths.PackageRootPath
                + "; outside project: " + (!AICodedbPaths.IsInsideProject(AICodedbPaths.PackageRootPath)));

            var synchronousResult = AICodedbHostPayloadMaterializer.ReadStatus();
            AssertMaterializerProcessStarted(synchronousResult, "synchronous Status");

            var asynchronousResult = AICodedbHostPayloadMaterializer
                .ReadStatusAsync()
                .GetAwaiter()
                .GetResult();
            AssertMaterializerProcessStarted(asynchronousResult, "asynchronous Status");
        }

        [Test]
        public void PackageMaterializerAuthorization_RejectsAnyOtherExternalScript()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                CreateMaterializerScript(packageRoot);
                var otherScriptPath = Path.Combine(packageRoot, "Tools~", "other.ps1");
                File.WriteAllText(otherScriptPath, "Write-Output 'must not run'", Encoding.UTF8);
                string authorizedPath;
                string error;

                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                    packageRoot,
                    otherScriptPath,
                    out authorizedPath,
                    out error);

                Assert.That(authorized, Is.False);
                Assert.That(authorizedPath, Is.Empty);
                Assert.That(error, Does.Contain("other than the resolved CodeDB Package materializer"));
            }
            finally
            {
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [Test]
        public void PackageMaterializerAuthorization_RejectsExactLeafOutsideResolvedPackageRoot()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                CreateMaterializerScript(packageRoot);
                var outsidePackageRoot = Path.Combine(fixtureRoot, "outside-package");
                var outsideScriptPath = CreateMaterializerScript(outsidePackageRoot);
                string authorizedPath;
                string error;

                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                    packageRoot,
                    outsideScriptPath,
                    out authorizedPath,
                    out error);

                Assert.That(authorized, Is.False);
                Assert.That(authorizedPath, Is.Empty);
                Assert.That(error, Does.Contain("other than the resolved CodeDB Package materializer"));
            }
            finally
            {
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [Test]
        public void ProjectLocalRunner_StillRejectsExternalScriptsBeforeLaunch()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var scriptPath = Path.Combine(fixtureRoot, "must-not-run.ps1");
                File.WriteAllText(scriptPath, "throw 'external script executed'", Encoding.UTF8);

                var synchronousResult = AICodedbProcessRunner.RunPowerShellScript(scriptPath, 1000);
                var asynchronousResult = AICodedbProcessRunner
                    .RunPowerShellScriptAsync(scriptPath, 1000)
                    .GetAwaiter()
                    .GetResult();

                AssertProjectLocalRunnerRejectedExternalScript(synchronousResult, "synchronous Host runner");
                AssertProjectLocalRunnerRejectedExternalScript(asynchronousResult, "asynchronous Host runner");
            }
            finally
            {
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [Test]
        public void PackageMaterializerAuthorization_RejectsMissingOrWrongLeaf()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                Directory.CreateDirectory(Path.Combine(packageRoot, "Tools~"));
                string authorizedPath;
                string error;

                var missingAuthorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                    packageRoot,
                    Path.Combine(packageRoot, AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath),
                    out authorizedPath,
                    out error);

                Assert.That(missingAuthorized, Is.False);
                Assert.That(error, Does.Contain("materializer was not found"));

                Directory.CreateDirectory(Path.Combine(
                    packageRoot,
                    AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
                var directoryAuthorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                    packageRoot,
                    Path.Combine(packageRoot, AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath),
                    out authorizedPath,
                    out error);

                Assert.That(directoryAuthorized, Is.False);
                Assert.That(error, Does.Contain("materializer was not found"));
            }
            finally
            {
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [Test]
        public void PackageMaterializerAuthorization_RejectsReparsePointWithinPackagePath()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            var toolsJunction = string.Empty;
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                var externalToolsRoot = Path.Combine(fixtureRoot, "external-tools");
                Directory.CreateDirectory(packageRoot);
                Directory.CreateDirectory(externalToolsRoot);
                File.WriteAllText(
                    Path.Combine(externalToolsRoot, "materialize-codedb-host-payload.ps1"),
                    "Write-Output 'must not run'",
                    Encoding.UTF8);
                toolsJunction = Path.Combine(packageRoot, "Tools~");
                CreateDirectoryJunction(toolsJunction, externalToolsRoot);
                string authorizedPath;
                string error;

                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageMaterializerScriptPath(
                    packageRoot,
                    Path.Combine(toolsJunction, "materialize-codedb-host-payload.ps1"),
                    out authorizedPath,
                    out error);

                Assert.That(authorized, Is.False);
                Assert.That(authorizedPath, Is.Empty);
                Assert.That(error, Does.Contain("through a reparse point"));
            }
            finally
            {
                if (!string.IsNullOrWhiteSpace(toolsJunction) && Directory.Exists(toolsJunction))
                    Directory.Delete(toolsJunction);
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [TestCase(AICodedbHostPayloadAction.DryRun, false)]
        [TestCase(AICodedbHostPayloadAction.Probe, false)]
        [TestCase(AICodedbHostPayloadAction.Verify, false)]
        [TestCase(AICodedbHostPayloadAction.Upgrade, false)]
        [TestCase(AICodedbHostPayloadAction.Redeploy, true)]
        [TestCase(AICodedbHostPayloadAction.Repair, true)]
        [TestCase(AICodedbHostPayloadAction.Sync, true)]
        [TestCase(AICodedbHostPayloadAction.Remove, true)]
        [TestCase(AICodedbHostPayloadAction.Uninstall, true)]
        [TestCase(AICodedbHostPayloadAction.Install, true)]
        public void BuildScriptArguments_HaveNoVersionControlOrAuthorizationArguments(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation)
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                action,
                confirmedProjectMutation);

            Assert.That(arguments, Does.Contain("-ProjectRoot"));
            Assert.That(arguments, Does.Not.Contain("-TrackedHostAuthorizationPath"));
            Assert.That(arguments, Does.Not.Contain("-ConfirmLegacyMcpStopped"));
            Assert.That(arguments, Does.Not.Contain("-PocFixture"));
            Assert.That(arguments, Does.Not.Contain("-GitIndexFile"));
        }

        [TestCase(AICodedbHostPayloadAction.DryRun)]
        [TestCase(AICodedbHostPayloadAction.Probe)]
        [TestCase(AICodedbHostPayloadAction.Verify)]
        [TestCase(AICodedbHostPayloadAction.Upgrade)]
        public void BuildScriptArguments_PackageManagedActionsRejectProjectConfirmation(
            AICodedbHostPayloadAction action)
        {
            Assert.Throws<ArgumentException>(() =>
                AICodedbHostPayloadMaterializer.BuildScriptArguments(
                    action,
                    true));
        }

        [TestCase(AICodedbHostPayloadAction.Redeploy)]
        [TestCase(AICodedbHostPayloadAction.Repair)]
        [TestCase(AICodedbHostPayloadAction.Sync)]
        [TestCase(AICodedbHostPayloadAction.Remove)]
        [TestCase(AICodedbHostPayloadAction.Uninstall)]
        [TestCase(AICodedbHostPayloadAction.Install)]
        public void BuildScriptArguments_ProjectMutationsRequireConfirmation(
            AICodedbHostPayloadAction action)
        {
            Assert.Throws<ArgumentException>(() =>
                AICodedbHostPayloadMaterializer.BuildScriptArguments(
                    action,
                    false));
        }

        [Test]
        public void BuildScriptArguments_SyncUsesOnlyProjectConfirmation()
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Sync,
                true);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Sync",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot,
                "-ConfirmedProjectMutation"
            }));
        }

        [Test]
        public void BuildScriptArguments_UpgradeUsesExactActionAndProjectRoot()
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Upgrade,
                false);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Upgrade",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot
            }));
        }

        [Test]
        public void BuildScriptArguments_ProbeUsesExactPackageOwnedActionAndProjectRoot()
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Probe,
                false);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Probe",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot
            }));
        }

        [Test]
        public void BuildScriptArguments_RedeployUsesExactActionAndProjectRoot()
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Redeploy,
                true);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Redeploy",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot,
                "-ConfirmedProjectMutation"
            }));
        }

        [Test]
        public void RunRedeploy_RejectsMissingConfirmationBeforeLaunchingMaterializer()
        {
            var result = AICodedbHostPayloadMaterializer.RunRedeploy(false);

            Assert.That(result.Succeeded, Is.False);
            Assert.That(result.StandardError, Does.Contain("Redeploy, Repair, Sync, Remove, Uninstall, and Install require second-level project mutation confirmation."));
        }

        [Test]
        public void RunHostPayloadRedeploy_RejectsMissingConfirmationBeforePreflight()
        {
            var result = AICodedbActions.RunHostPayloadRedeploy(false);

            Assert.That(result.Succeeded, Is.False);
            Assert.That(result.StandardError, Does.Contain("Redeploy, Repair, Sync, Remove, Uninstall, and Install require second-level project mutation confirmation."));
        }

        [Test]
        public void BuildScriptArguments_RepairUsesExactPackageOwnedActionAndProjectRoot()
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.Repair,
                true);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                "Repair",
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot,
                "-ConfirmedProjectMutation"
            }));
        }

        [TestCase(AICodedbHostPayloadAction.Uninstall, "Uninstall")]
        [TestCase(AICodedbHostPayloadAction.Install, "Install")]
        public void BuildScriptArguments_ProjectIntegrationActionsUseExactConfirmedContract(
            AICodedbHostPayloadAction action,
            string actionName)
        {
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(action, true);

            Assert.That(arguments, Is.EqualTo(new[]
            {
                "-Action",
                actionName,
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot,
                "-ConfirmedProjectMutation"
            }));
        }

        private static string CreateExternalPackageFixture()
        {
            var fixtureRoot = Path.Combine(
                Path.GetTempPath(),
                "codedb-editor-package-runner-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(fixtureRoot);
            return fixtureRoot;
        }

        private static void AssertMaterializerProcessStarted(
            AICodedbCommandResult result,
            string label)
        {
            Assert.That(result.TimedOut, Is.False, label + " timed out.");
            Assert.That(
                result.Succeeded,
                Is.True,
                label + " did not complete through the Package-owned materializer." + Environment.NewLine + result.GetDisplayText());
            Assert.That(
                result.StandardError,
                Does.Not.Contain("Refusing to run a script outside the Unity project"),
                label + " used the project-local Host script boundary.");
        }

        private static void AssertProjectLocalRunnerRejectedExternalScript(
            AICodedbCommandResult result,
            string label)
        {
            Assert.That(result.Succeeded, Is.False, label);
            Assert.That(result.ExitCode, Is.EqualTo(-1), label);
            Assert.That(
                result.StandardError,
                Does.Contain("Refusing to run a script outside the Unity project"),
                label);
        }

        private static string CreateMaterializerScript(string packageRoot)
        {
            var scriptPath = Path.Combine(
                packageRoot,
                AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(scriptPath));
            File.WriteAllText(scriptPath, "Write-Output 'fixture materializer'", Encoding.UTF8);
            return scriptPath;
        }

        private static void CreateDirectoryJunction(string junctionPath, string targetPath)
        {
            var command = "New-Item -ItemType Junction -Path '"
                          + junctionPath.Replace("'", "''")
                          + "' -Target '"
                          + targetPath.Replace("'", "''")
                          + "' -ErrorAction Stop | Out-Null";
            var encodedCommand = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
            var startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " + encodedCommand,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using (var process = System.Diagnostics.Process.Start(startInfo))
            {
                Assert.That(process, Is.Not.Null);
                var standardOutput = process.StandardOutput.ReadToEnd();
                var standardError = process.StandardError.ReadToEnd();
                Assert.That(process.WaitForExit(10000), Is.True, "Timed out creating the reparse-point fixture.");
                Assert.That(process.ExitCode, Is.Zero, standardOutput + Environment.NewLine + standardError);
            }

            Assert.That(
                (File.GetAttributes(junctionPath) & FileAttributes.ReparsePoint) != 0,
                Is.True,
                "The fixture junction was not marked as a reparse point.");
        }

        private static void DeleteFixtureDirectory(string fixtureRoot)
        {
            if (!string.IsNullOrWhiteSpace(fixtureRoot) && Directory.Exists(fixtureRoot))
                Directory.Delete(fixtureRoot, true);
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
            Assert.That(status.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Complete));
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
        public void Parse_MapsPendingCleanupAndDefaultsLegacyFieldlessStateToComplete()
        {
            var projectRoot = AICodedbPaths.ProjectRoot;
            var pending = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson("CURRENT", projectRoot, "PENDING"),
                projectRoot,
                "upgrade-state.json");
            var fieldless = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson("CURRENT", projectRoot, null),
                projectRoot,
                "upgrade-state.json");

            Assert.That(pending.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Current));
            Assert.That(pending.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Pending));
            Assert.That(fieldless.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Current));
            Assert.That(fieldless.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Complete));
        }

        [TestCase("UNKNOWN")]
        [TestCase("pending")]
        public void Parse_FailsClosedForInvalidCleanupState(string cleanupState)
        {
            var projectRoot = AICodedbPaths.ProjectRoot;
            var status = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson("CURRENT", projectRoot, cleanupState),
                projectRoot,
                "upgrade-state.json");

            Assert.That(status.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Invalid));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(status.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Invalid));
        }

        [Test]
        public void Parse_FailsClosedForWrongTypeCleanupState()
        {
            var projectRoot = AICodedbPaths.ProjectRoot;
            var json = UpgradeStateJson("CURRENT", projectRoot)
                .Replace("\"cleanup_state\":\"COMPLETE\"", "\"cleanup_state\":true");
            var status = AICodedbHostUpgradeStatusStore.Parse(
                json,
                projectRoot,
                "upgrade-state.json");

            Assert.That(status.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Invalid));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(status.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Invalid));
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

        [Test]
        public void Parse_MarksOlderTargetStateHistoricalInsteadOfCurrentOrFailed()
        {
            var projectRoot = AICodedbPaths.ProjectRoot;
            var status = AICodedbHostUpgradeStatusStore.Parse(
                UpgradeStateJson("CURRENT", projectRoot),
                projectRoot,
                "upgrade-state.json",
                "poc.30");

            Assert.That(status.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Historical));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Inactive));
            Assert.That(status.Summary, Is.EqualTo("Historical CURRENT / poc.22"));
            Assert.That(status.Detail, Does.Contain("current target is poc.30"));
            Assert.That(status.ToStatusItem(true).State, Is.EqualTo(AICodedbStatusState.Inactive));
        }

        private static string UpgradeStateJson(
            string phase,
            string projectRoot,
            string cleanupState = "COMPLETE")
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot);
            return "{\"schema_version\":1," +
                   "\"managed_by\":\"com.rice.ai-codedb\"," +
                   "\"project_root\":\"" + normalizedRoot + "\"," +
                   "\"state\":\"" + phase + "\"," +
                   "\"generation_id\":\"poc.22\"," +
                   (cleanupState == null ? string.Empty : "\"cleanup_state\":\"" + cleanupState + "\",") +
                   "\"updated_at_utc\":\"" + DateTime.UtcNow.ToString("o") + "\"," +
                   "\"message\":\"upgrade detail\"}";
        }
    }

    internal sealed class AICodedbLifecycleControlTests
    {
        [TestCase(AICodedbHostGenerationState.Unavailable, AICodedbHostPayloadState.SetupRequired, AICodedbHostUpgradePhase.Unavailable)]
        [TestCase(AICodedbHostGenerationState.Previous, AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.Historical)]
        [TestCase(AICodedbHostGenerationState.Invalid, AICodedbHostPayloadState.Blocked, AICodedbHostUpgradePhase.Invalid)]
        [TestCase(AICodedbHostGenerationState.Invalid, AICodedbHostPayloadState.Conflict, AICodedbHostUpgradePhase.CheckFailed)]
        [TestCase(AICodedbHostGenerationState.Previous, AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.Rollback)]
        [TestCase(AICodedbHostGenerationState.Current, AICodedbHostPayloadState.Current, AICodedbHostUpgradePhase.Current)]
        public void ReinstallCodeDB_RemainsAvailableAcrossRecoveryStates(
            AICodedbHostGenerationState generationState,
            AICodedbHostPayloadState payloadState,
            AICodedbHostUpgradePhase upgradePhase)
        {
            Assert.That(
                AICodedbManagerWindow.IsReinstallCodeDBAvailable(generationState, payloadState, upgradePhase),
                Is.True);
        }

        [Test]
        public void ReinstallCodeDB_CancelDoesNotInvokeRecoveryAction()
        {
            var confirmationCount = 0;
            var reinstallCount = 0;

            var ran = AICodedbManagerWindow.ConfirmAndRunReinstallCodeDB(
                () =>
                {
                    confirmationCount++;
                    return false;
                },
                () => reinstallCount++);

            Assert.That(ran, Is.False);
            Assert.That(confirmationCount, Is.EqualTo(1));
            Assert.That(reinstallCount, Is.Zero);
        }

        [Test]
        public void ReinstallCodeDB_ConfirmationRunsExactlyOnePackageOwnedRecoveryAction()
        {
            var reinstallCount = 0;

            var ran = AICodedbManagerWindow.ConfirmAndRunReinstallCodeDB(
                () => true,
                () => reinstallCount++);

            Assert.That(ran, Is.True);
            Assert.That(reinstallCount, Is.EqualTo(1));
            Assert.That(AICodedbManagerWindow.ReinstallCodeDBConfirmationTitle, Is.EqualTo("Reinstall CodeDB"));
            Assert.That(AICodedbManagerWindow.ReinstallCodeDBConfirmationMessage, Does.Contain("fresh project-local instance"));
            Assert.That(AICodedbManagerWindow.ReinstallCodeDBConfirmationMessage, Does.Contain("unrelated MCP content"));
            Assert.That(AICodedbManagerWindow.ReinstallCodeDBConfirmationMessage, Does.Contain("External MCP clients and unrelated processes are never terminated"));
        }

        [TestCase(false)]
        [TestCase(true)]
        public void UninstallCodeDB_ConfirmationControlsExactlyOneProjectAction(bool confirmed)
        {
            var actionCount = 0;

            var ran = AICodedbManagerWindow.ConfirmAndRunUninstallCodeDB(
                () => confirmed,
                () => actionCount++);

            Assert.That(ran, Is.EqualTo(confirmed));
            Assert.That(actionCount, Is.EqualTo(confirmed ? 1 : 0));
            Assert.That(AICodedbManagerWindow.UninstallCodeDBConfirmationTitle, Is.EqualTo("Uninstall CodeDB from Project"));
            Assert.That(AICodedbManagerWindow.UninstallCodeDBConfirmationMessage, Does.Contain("Package remains installed"));
            Assert.That(AICodedbManagerWindow.UninstallCodeDBConfirmationMessage, Does.Contain("external processes are preserved"));
        }

        [TestCase(false)]
        [TestCase(true)]
        public void InstallCodeDB_ConfirmationControlsExactlyOneProjectAction(bool confirmed)
        {
            var actionCount = 0;

            var ran = AICodedbManagerWindow.ConfirmAndRunInstallCodeDB(
                () => confirmed,
                () => actionCount++);

            Assert.That(ran, Is.EqualTo(confirmed));
            Assert.That(actionCount, Is.EqualTo(confirmed ? 1 : 0));
            Assert.That(AICodedbManagerWindow.InstallCodeDBConfirmationTitle, Is.EqualTo("Install CodeDB"));
            Assert.That(AICodedbManagerWindow.InstallCodeDBConfirmationMessage, Does.Contain("clear the UNINSTALLED project state"));
        }

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

        [Test]
        public void HostCommandControls_AllowOnlyCurrentWithoutExecutingOlderHosts()
        {
            Assert.That(AICodedbManagerWindow.CanUseHostCommands(AICodedbHostGenerationState.Current), Is.True);
            Assert.That(AICodedbManagerWindow.CanUseHostCommands(AICodedbHostGenerationState.Previous), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseHostCommands(AICodedbHostGenerationState.Legacy), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseHostCommands(AICodedbHostGenerationState.Unavailable), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseHostCommands(AICodedbHostGenerationState.DowngradeReviewRequired), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseHostCommands(AICodedbHostGenerationState.Invalid), Is.False);
        }

        [Test]
        public void HostCommandReadiness_RejectsUnavailableGenerationBeforeProcessLaunch()
        {
            var unavailable = new AICodedbHostGenerationSelection(
                AICodedbHostGenerationState.Unavailable,
                string.Empty,
                string.Empty,
                string.Empty,
                0,
                0,
                string.Empty,
                "No selected generation.");

            var failure = AICodedbActions.GetHostCommandReadinessFailure(
                unavailable,
                Path.Combine(AICodedbPaths.ProjectRoot, "AIWork", ".runtime", "codedb", "host", "unavailable", "scripts", "fixture.ps1"));

            Assert.That(failure, Is.Not.Null);
            Assert.That(failure.ExitCode, Is.EqualTo(4));
            Assert.That(failure.StandardError, Does.Contain("generation state is Unavailable"));
        }

        [Test]
        public void HostCommandReadiness_RejectsPreviousGenerationBeforeProcessLaunch()
        {
            var previous = new AICodedbHostGenerationSelection(
                AICodedbHostGenerationState.Previous,
                "poc.29",
                "0.2.5-preview.2",
                "poc.29",
                29,
                1,
                Path.Combine(AICodedbPaths.ProjectRoot, "AIWork", ".runtime", "codedb", "host", "generations", "poc.29"),
                "Validated previous generation.");

            var failure = AICodedbActions.GetHostCommandReadinessFailure(
                previous,
                Path.Combine(previous.RootPath, "scripts", "verify-codedb-project.ps1"));

            Assert.That(failure, Is.Not.Null);
            Assert.That(failure.ExitCode, Is.EqualTo(4));
            Assert.That(failure.StandardError, Does.Contain("generation state is Previous"));
        }

        [Test]
        public void HostCommandReadiness_RejectsLegacyHostBeforeProcessLaunch()
        {
            var legacyRoot = Path.Combine(AICodedbPaths.ProjectRoot, "AIWork", "codedb");
            var legacy = new AICodedbHostGenerationSelection(
                AICodedbHostGenerationState.Legacy,
                "poc.20",
                "0.2.1",
                "poc.20",
                20,
                0,
                legacyRoot,
                "Validated legacy flat Host.");

            var failure = AICodedbActions.GetHostCommandReadinessFailure(
                legacy,
                Path.Combine(legacyRoot, "scripts", "verify-codedb-project.ps1"));

            Assert.That(failure, Is.Not.Null);
            Assert.That(failure.ExitCode, Is.EqualTo(4));
            Assert.That(failure.StandardError, Does.Contain("generation state is Legacy"));
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
