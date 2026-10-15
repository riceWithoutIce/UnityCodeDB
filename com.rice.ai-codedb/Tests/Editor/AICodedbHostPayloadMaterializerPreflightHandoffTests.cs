using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbHostPayloadMaterializerPreflightHandoffTests
    {
        [Test]
        public void UninstallPreflight_ConsumesIsolatedProductionOutput()
        {
            var root = TestContext.Parameters.Get("UninstallAdmissionFixtureRoot", string.Empty);
            if (string.IsNullOrEmpty(root)) Assert.Ignore("Requires the explicit isolated S30 uninstall admission fixture.");
            AssertProductionUninstallFixture(root);
        }

        internal static void AssertProductionUninstallFixture(string root)
        {
            Assert.That(System.IO.Path.GetFullPath(root).Replace('\\', '/'),
                Does.Contain("/.artifacts/tests/s30-uninstall-admission/"));
            var normal = new AICodedbCommandResult(0,
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "normal.stdout")), string.Empty, false);
            Assert.That(AICodedbHostPayloadMaterializer.HasUninstallPreflight(normal), Is.True);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(normal,
                AICodedbHostPayloadAction.UninstallPreflight), Is.True);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(normal,
                AICodedbHostPayloadAction.RemoveIntegrationPreflight), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(normal,
                AICodedbHostPayloadAction.Install), Is.False);
            AICodedbS29ExecutionContextTests.AssertUninstallPreflightProjection(root, normal, true, string.Empty);
            var blocked = new AICodedbCommandResult(4,
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "normal-blocked.stdout")),
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "normal-blocked.stderr")), false);
            AICodedbS29ExecutionContextTests.AssertUninstallPreflightProjection(root, blocked, false, "fixture ownership refused");
            var variants = new[] {
                new AICodedbCommandResult(0, normal.StandardOutput + normal.StandardOutput, string.Empty, false),
                new AICodedbCommandResult(0, normal.StandardOutput.Replace("AVAILABLE", "AVAILABLE extra"), string.Empty, false),
                new AICodedbCommandResult(0, normal.StandardOutput + "[REMOVAL_PREFLIGHT] BLOCKED\n", string.Empty, false),
                new AICodedbCommandResult(0, normal.StandardOutput, string.Empty, true),
                new AICodedbCommandResult(0, normal.StandardOutput, string.Empty, false, outputOverflow: true),
                new AICodedbCommandResult(0, normal.StandardOutput, string.Empty, false, outputDrainIncomplete: true),
                new AICodedbCommandResult(0, string.Empty, string.Empty, false)
            };
            foreach (var result in variants)
            {
                Assert.That(AICodedbHostPayloadMaterializer.HasUninstallPreflight(result), Is.False);
                AICodedbS29ExecutionContextTests.AssertUninstallPreflightProjection(root, result, false, string.Empty);
            }
            var recovery = new AICodedbCommandResult(0,
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "recovery.stdout")), string.Empty, false);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(recovery,
                AICodedbHostPayloadAction.RemoveIntegrationPreflight), Is.True);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(recovery,
                AICodedbHostPayloadAction.UninstallPreflight), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(new AICodedbCommandResult(0,
                recovery.StandardOutput.Replace("[REMOVAL_PREFLIGHT_HANDOFF] ", "[REMOVAL_PREFLIGHT_HANDOFF] invalid."),
                string.Empty, false), AICodedbHostPayloadAction.RemoveIntegrationPreflight), Is.False);
            var candidate = new AICodedbCommandResult(0,
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "candidate.stdout")), string.Empty, false);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(candidate,
                AICodedbHostPayloadAction.UninstallPreflight), Is.True);
            var candidateRefused = new AICodedbCommandResult(4,
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "candidate-blocked.stdout")),
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "candidate-blocked.stderr")), false);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(candidateRefused,
                AICodedbHostPayloadAction.UninstallPreflight), Is.False);
        }

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
                .Or.Contain("/.artifacts/tests/s29-removal-process-identity/")
                .Or.Contain("/.artifacts/tests/s29-removal-history-authority/"));
            var failure = new AICodedbCommandResult(4, "[REMOVAL_PREFLIGHT] BLOCKED\n",
                System.IO.File.ReadAllText(System.IO.Path.Combine(root, "preflight-blocked.stderr")), false);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(failure), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(failure), Is.False);
            Assert.That(AICodedbEditorLifecycle.GetRemovalPreflightDiagnostic(failure), Does.Contain("foreign.json"));
            AICodedbS29ExecutionContextTests.AssertCachedRemovalFailure(root, failure, "foreign.json");
            if (normalized.Contains("/.artifacts/tests/s29-removal-history-authority/"))
            {
                foreach (var role in new[] { "operation", "stale-owner", "current-owner" })
                {
                    var sourceFailure = new AICodedbCommandResult(4, "[REMOVAL_PREFLIGHT] BLOCKED\n",
                        System.IO.File.ReadAllText(System.IO.Path.Combine(root, "history-source-" + role + ".stderr")), false);
                    var reason = role == "operation" ? "runtime contract does not match a trusted history source"
                        : "target, runtime contract and disposition do not match one trusted history source";
                    Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(sourceFailure), Is.False);
                    Assert.That(AICodedbEditorLifecycle.IsRemovalPreflightAvailable(sourceFailure), Is.False);
                    var diagnostic = AICodedbEditorLifecycle.GetRemovalPreflightDiagnostic(sourceFailure);
                    Assert.That(diagnostic, Does.Contain(reason));
                    Assert.That(diagnostic, Does.Contain(role == "operation" ? new string('1', 32)
                        : role == "stale-owner" ? "stale Supervisor" : "Supervisor"));
                    Assert.That(diagnostic.Length, Is.LessThanOrEqualTo(900));
                    Assert.That(diagnostic, Does.Not.Contain("[REMOVAL_PREFLIGHT_HANDOFF]"));
                    AICodedbS29ExecutionContextTests.AssertCachedRemovalFailure(root, sourceFailure, reason);
                }
            }
            if (normalized.Contains("/.artifacts/tests/s29-removal-process-identity/")
                || normalized.Contains("/.artifacts/tests/s29-removal-history-authority/"))
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
