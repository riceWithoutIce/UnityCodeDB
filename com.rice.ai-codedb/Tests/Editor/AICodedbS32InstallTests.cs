using System;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using NUnit.Framework;
using UnityEngine;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbS32InstallTests
    {
        [Test]
        public void ProjectInstall_OriginalWriterFailureAndOfflineRecovery()
        {
            var root = TestContext.Parameters.Get("S32InstallFixtureRoot", string.Empty);
            if (string.IsNullOrEmpty(root))
                Assert.Ignore("Requires the explicit S32 child-local receipt/temp environment; use run-focused.ps1.");
            AssertOriginalWriter(root, AICodedbPaths.PackageRootPath);
        }

        // This executes the original writer/materializer's real missing-payload
        // refusal. It never fabricates a successful installation or runs Provider.
        internal static void AssertOriginalWriter(string root, string sourcePackage)
        {
            var run = Path.GetDirectoryName(Path.GetFullPath(root));
            var expected = Path.GetFullPath(Path.Combine(sourcePackage, "..", ".artifacts/tests/s32-install"))
                .TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            Assert.That(run.StartsWith(expected, StringComparison.OrdinalIgnoreCase), Is.True,
                "Writer fixtures must remain under the declared repository-local task root.");
            Assert.That(Path.GetFullPath(Environment.GetEnvironmentVariable("LOCALAPPDATA")),
                Is.EqualTo(Path.Combine(run, "local")));
            Assert.That(Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar),
                Is.EqualTo(Path.Combine(run, "tmp")));
            var package = Path.Combine(root, "package");
            foreach (var relative in new[] {
                "Tools~/invoke-codedb-manager-action.ps1", "Tools~/materialize-codedb-host-payload.ps1",
                "Tools~/codedb-instance-engine.ps1", "Payload~/payload-manifest.json",
                "Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1",
                "Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1",
                "Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs" })
            {
                var target = Path.Combine(package, relative);
                Directory.CreateDirectory(Path.GetDirectoryName(target));
                File.Copy(Path.Combine(sourcePackage, relative), target);
            }
            foreach (var topology in new[] { "first", "retained" })
            {
                var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                    Path.Combine(root, topology), package, "S32 controlled refusal");
                foreach (var name in new[] { "Assets", "Packages", "ProjectSettings" })
                    Directory.CreateDirectory(Path.Combine(context.ProjectRoot, name));
                var runtime = AICodedbSupervisorLauncher.GetSupervisorRuntimePath(context.ProjectRoot,
                    AICodedbPackageRuntimeContractStore.Read(package).ControlContract);
                if (topology == "retained")
                {
                    Directory.CreateDirectory(Path.Combine(runtime, "operation-history"));
                    Directory.CreateDirectory(Path.Combine(runtime, "manager-actions"));
                    // Presence topology only, not installation/terminal authority.
                    File.WriteAllText(Path.Combine(runtime, "operation.json"), "{\"manager_action_id\":\"" + new string('a', 32) + "\"}");
                }
                var actionId = Guid.NewGuid().ToString("N");
                var index = new AICodedbManagerActionIndex(actionId, "Install CodeDB",
                    "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission", context,
                    executionRoute: AICodedbInstallAdmission.ProjectInstallRoute);
                Assert.That(AICodedbManagerActionJournal.TryAdmit(index, out var detail), Is.True, detail);
                Assert.That(AICodedbManagerActionJournal.TryAdmit(new AICodedbManagerActionIndex(
                    Guid.NewGuid().ToString("N"), index.Title, index.EffectClass, index.AuthorizationSource,
                    context, executionRoute: index.ExecutionRoute), out _), Is.False);
                AICodedbCommandResult result;
                using (AICodedbPaths.UseActionContext(context, actionId, index.EffectClass, index.AuthorizationSource))
                    result = AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScriptAsync(context,
                        30000, "-Action", "Install", "-ProjectRoot", context.ProjectRoot,
                        "-ConfirmedProjectMutation", "-OriginatingActionId", actionId,
                        "-OriginatingOperationId", Guid.NewGuid().ToString("N")).GetAwaiter().GetResult();
                Assert.That(result.HasAuthoritativeTerminalEvidence, Is.True, result.StandardError);
                Assert.That(result.Succeeded, Is.False, "Incomplete fixture must not install anything.");
                Assert.That(File.Exists(Path.Combine(runtime, "supervisor-state.json")), Is.False);
                var session = Reopen(context);
                Assert.That(session.ExecutionRoute, Is.EqualTo(index.ExecutionRoute));
                var recovered = AICodedbManagerWindow.ResolveActionEvidenceAsync(session, result).GetAwaiter().GetResult();
                Assert.That(recovered.HasAuthoritativeTerminalEvidence, Is.True, recovered.StandardError);
                Assert.That(recovered.ExitCode, Is.EqualTo(result.ExitCode));
                var receiptRoot = AICodedbPaths.GetManagerActionReceiptRoot(context, actionId);
                var terminal = Directory.GetFiles(receiptRoot, "*.terminal.json")[0];
                var terminalBytes = File.ReadAllBytes(terminal);
                File.Move(terminal, terminal + ".saved");
                var unknown = AICodedbManagerWindow.ResolveActionEvidenceAsync(session, result).GetAwaiter().GetResult();
                Assert.That(unknown.HasAuthoritativeTerminalEvidence, Is.False);
                Assert.That(session.TryReleaseDurableIndex(unknown, out _), Is.False);
                File.Move(terminal + ".saved", terminal);
                Directory.CreateDirectory(Path.Combine(runtime, "manager-actions"));
                var map = Path.Combine(runtime, "manager-actions", actionId + ".json");
                File.WriteAllText(map, "{}");
                var conflict = AICodedbManagerWindow.ResolveActionEvidenceAsync(session, result).GetAwaiter().GetResult();
                Assert.That(conflict.HasAuthoritativeTerminalEvidence, Is.False);
                Assert.That(conflict.StandardError, Does.Contain("Supervisor claim"));
                File.Delete(map);
                Assert.That(File.ReadAllBytes(terminal), Is.EqualTo(terminalBytes), "Reopen must not replay or rewrite terminal.");
                recovered = AICodedbManagerWindow.ResolveActionEvidenceAsync(session, null).GetAwaiter().GetResult();
                Assert.That(recovered.HasAuthoritativeTerminalEvidence, Is.True, recovered.StandardError);
                Assert.That(session.TryReleaseDurableIndex(recovered, out detail), Is.True, detail);
            }
            var refusedContext = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                Path.Combine(root, "pre-effect"), package, "S32 no writer dispatch");
            Directory.CreateDirectory(refusedContext.ProjectRoot);
            var refusedId = Guid.NewGuid().ToString("N");
            var refusedIndex = new AICodedbManagerActionIndex(refusedId, "Install CodeDB",
                "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission", refusedContext,
                executionRoute: AICodedbInstallAdmission.ProjectInstallRoute);
            Assert.That(AICodedbManagerActionJournal.TryAdmit(refusedIndex, out var refusalDetail), Is.True, refusalDetail);
            var writerPath = Path.Combine(package, "Tools~/invoke-codedb-manager-action.ps1");
            File.Move(writerPath, writerPath + ".saved");
            try
            {
                AICodedbCommandResult refused;
                using (AICodedbPaths.UseActionContext(refusedContext, refusedId,
                    refusedIndex.EffectClass, refusedIndex.AuthorizationSource))
                    refused = AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScriptAsync(
                        refusedContext, 30000, "-Action", "Install", "-ProjectRoot", refusedContext.ProjectRoot)
                        .GetAwaiter().GetResult();
                Assert.That(refused.ManagerActionEvidenceKind, Is.EqualTo(AICodedbManagerActionEvidenceKind.PreEffectRefusal));
                var session = Reopen(refusedContext);
                var result = AICodedbManagerWindow.ResolveActionEvidenceAsync(session, refused).GetAwaiter().GetResult();
                Assert.That(result.ManagerActionEvidenceKind, Is.EqualTo(AICodedbManagerActionEvidenceKind.PreEffectRefusal));
                Assert.That(session.TryReleaseDurableIndex(result, out refusalDetail), Is.True, refusalDetail);
            }
            finally { File.Move(writerPath + ".saved", writerPath); }
        }

        private static AICodedbManagerActionSession Reopen(AICodedbEditorExecutionContext context)
        {
            var current = typeof(AICodedbManagerActionSession).GetField("_current", BindingFlags.Static | BindingFlags.NonPublic);
            current.SetValue(null, null);
            AICodedbManagerActionSession.RestoreDurable(context, AICodedbManagerActionJournal.Read(context), 1);
            return (AICodedbManagerActionSession)current.GetValue(null);
        }
    }
}
