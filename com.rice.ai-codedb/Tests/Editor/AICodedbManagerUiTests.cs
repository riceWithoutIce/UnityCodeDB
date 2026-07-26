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
            Assert.That(AICodedbProjectSettings.TrackedHostAuthorizationRelativePath, Is.EqualTo("AIWork/.runtime/codedb/payload-materializer/authorizations"));
            Assert.That(AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath, Is.EqualTo("Tools~/materialize-codedb-host-payload.ps1"));
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
        }

        [Test]
        public void WindowTitleContent_UsesBrandIcon()
        {
            var content = AICodedbBrandAssets.CreateWindowTitleContent();

            Assert.That(content.text, Is.EqualTo("Codedb Manager"));
            Assert.That(content.tooltip, Is.EqualTo("Rice AI CodeDB"));
            Assert.That(content.image, Is.SameAs(AICodedbBrandAssets.Icon));
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

        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"watching\"}", AICodedbStatusState.Ok, "Enabled / Ready")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"pending\"}", AICodedbStatusState.Ok, "Enabled / Ready")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"building\"}", AICodedbStatusState.Ok, "Enabled / Ready")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\",\"adapter_state\":\"failed\"}", AICodedbStatusState.Warning, "Enabled / Stale")]
        [TestCase("[OK] Watch opt-in: ENABLED\n{\"provider_state\":\"ready\"}", AICodedbStatusState.Warning, "Enabled / Stale")]
        [TestCase("[OK] Watch opt-in: DISABLED\n[STOPPED] codedb watch coordinator stopped.", AICodedbStatusState.Inactive, "Off")]
        [TestCase("[OK] Watch opt-in: ENABLED\n[STALE] codedb watch coordinator stale.", AICodedbStatusState.Warning, "Enabled / Stale")]
        [TestCase("[OK] Watch opt-in: DISABLED\n[OK] codedb watch coordinator running.", AICodedbStatusState.Warning, "Off / Running")]
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
            Assert.That(status.Summary, Is.EqualTo("Installed / Current"));
            Assert.That(status.IsCurrent, Is.True);
        }

        [TestCase(false, AICodedbHostPayloadState.NotInstalled, "Not Installed")]
        [TestCase(true, AICodedbHostPayloadState.Stale, "Installed / Stale")]
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
            Assert.That(status.Summary, Is.EqualTo("Installed / Conflict"));
            Assert.That(status.Detail, Does.StartWith("[CONFLICT]"));
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
