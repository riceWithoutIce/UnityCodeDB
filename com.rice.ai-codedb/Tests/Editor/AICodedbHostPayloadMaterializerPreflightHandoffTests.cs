using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbHostPayloadMaterializerPreflightHandoffTests
    {
        [Test]
        public void RemovalPreflight_LifecycleRefusesIncompleteAndMalformedPermits()
        {
            const string malformed = "[REMOVAL_PREFLIGHT] AVAILABLE\n[REMOVAL_PREFLIGHT_HANDOFF] abc.def\n";
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(new AICodedbCommandResult(
                0, malformed, string.Empty, false)), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(new AICodedbCommandResult(
                0, malformed, string.Empty, false, outputDrainIncomplete: true)), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(new AICodedbCommandResult(
                0, malformed, string.Empty, true)), Is.False);
        }

        [Test]
        public void RemovalPreflight_ConsumesIsolatedProductionNamespaceRefusal()
        {
            var root = TestContext.Parameters.Get("RemovalNamespaceFixtureRoot", string.Empty);
            if (string.IsNullOrEmpty(root)) Assert.Ignore("Requires the explicit isolated RemovalNamespaceOnly fixture.");
            AssertProductionNamespaceFixture(root);
        }

        internal static void AssertProductionNamespaceFixture(string root)
        {
            var normalized = System.IO.Path.GetFullPath(root).Replace('\\', '/');
            Assert.That(normalized, Does.Contain("/.artifacts/tests/s29-removal-namespace/")
                .Or.Contain("/.artifacts/tests/s29-removal-process-identity/"));
            var failure = new AICodedbCommandResult(4, "[REMOVAL_PREFLIGHT] BLOCKED\n",
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "preflight-blocked.stderr")), false);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(failure), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(failure), Is.False);
            Assert.That(AICodedbEditorLifecycle.GetRemovalPreflightDiagnostic(failure), Does.Contain("foreign.json"));
            AICodedbS29ExecutionContextTests.AssertCachedRemovalFailure(root, failure, "foreign.json");
            if (normalized.Contains("/.artifacts/tests/s29-removal-process-identity/"))
            {
            foreach (var role in new[] { "child", "stale-owner", "current-owner" })
            {
                foreach (var mode in new[] { "live", "unknown" })
                {
                    var reason = mode == "live" ? "original process is still alive" : "process identity is unavailable";
                    var processFailure = new AICodedbCommandResult(4, "[REMOVAL_PREFLIGHT] BLOCKED\n",
                        System.IO.File.ReadAllText(System.IO.Path.Combine(root, "process-" + role + "-" + mode + ".stderr")), false);
                    Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(processFailure), Is.False);
                    Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(processFailure), Is.False);
                    var diagnostic = AICodedbEditorLifecycle.GetRemovalPreflightDiagnostic(processFailure);
                    Assert.That(diagnostic, Does.Contain(reason));
                    Assert.That(diagnostic, Does.Contain(role == "child" ? new string('1', 32) : role == "stale-owner" ? "Stale Supervisor owner" : "Current Supervisor owner"));
                    Assert.That(diagnostic.Length, Is.LessThanOrEqualTo(900));
                    Assert.That(diagnostic, Does.Not.Contain("[REMOVAL_PREFLIGHT_HANDOFF]"));
                    AICodedbS29ExecutionContextTests.AssertCachedRemovalFailure(root, processFailure, reason);
                }
            }
            var missingChild = new AICodedbCommandResult(4, "[REMOVAL_PREFLIGHT] BLOCKED\n",
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "process-child-missing.stderr")), false);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(missingChild), Is.False);
            AICodedbS29ExecutionContextTests.AssertCachedRemovalFailure(root, missingChild, "child evidence is missing");
            }
            var success = new AICodedbCommandResult(0,
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "preflight-available.stdout")), string.Empty, false);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(success), Is.True);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(new AICodedbCommandResult(
                0, success.StandardOutput, string.Empty, false, outputDrainIncomplete: true)), Is.False);
        }

        [Test]
        public void RemovalPreflight_RequiresOneAvailableLineAndHandoff()
        {
            var result = new AICodedbCommandResult(
                0,
                "[REMOVAL_PREFLIGHT] AVAILABLE\n[REMOVAL_PREFLIGHT_HANDOFF] abc.def\n",
                string.Empty,
                false);

            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(result), Is.True);
            Assert.That(AICodedbHostPayloadMaterializer.ReadRemovalPreflightHandoff(result), Is.EqualTo("abc.def"));
        }

        [Test]
        public void RemovalPreflight_RejectsMissingOrDuplicateHandoff()
        {
            var missing = new AICodedbCommandResult(0, "[REMOVAL_PREFLIGHT] AVAILABLE\n", string.Empty, false);
            var duplicate = new AICodedbCommandResult(
                0,
                "[REMOVAL_PREFLIGHT] AVAILABLE\n[REMOVAL_PREFLIGHT_HANDOFF] a.b\n[REMOVAL_PREFLIGHT_HANDOFF] c.d\n",
                string.Empty,
                false);

            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(missing), Is.False);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(duplicate), Is.False);
            Assert.That(AICodedbHostPayloadMaterializer.ReadRemovalPreflightHandoff(missing), Is.Null);
            Assert.That(AICodedbHostPayloadMaterializer.ReadRemovalPreflightHandoff(duplicate), Is.Null);
        }

        [Test]
        public void RemovalIntegrationArguments_RequireHandoff()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                Assert.Throws<System.ArgumentException>(() =>
                    AICodedbHostPayloadMaterializer.BuildRuntimeScriptArguments(
                        AICodedbHostPayloadAction.RemoveIntegration,
                        true,
                        workspace.ProjectRoot));
            });
        }
    }
}
