using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using NUnit.Framework;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEngine;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbProjectSettingsTests
    {
        private sealed class ManagerReceiptFixture : IDisposable
        {
            private readonly string _root;
            private readonly IDisposable _scope;
            private readonly string _historicalOutcome;
            internal readonly AICodedbEditorExecutionContext Context;
            internal readonly string ActionId = Guid.NewGuid().ToString("N");
            internal string InstallOutput => HistoricalCommandOutput("INSTALL", _historicalOutcome);

            internal ManagerReceiptFixture(AICodedbTestWorkspace workspace, AICodedbEditorExecutionContext context, bool resolved,
                string title = "Install CodeDB", string historicalOutcome = "FAILED")
            {
                _historicalOutcome = historicalOutcome;
                Context = context;
                _root = workspace.Root;
                workspace.ValidateCleanupTarget(context.ProjectRoot);
                workspace.ValidateCleanupTarget(context.PackageRoot);
                var receiptScope = AICodedbPaths.UseManagerActionsRootForTests(_root);
                _scope = workspace.RegisterCleanup(receiptScope.Dispose);
                var index = new AICodedbManagerActionIndex(ActionId, title,
                    "ConfirmedProjectMutation", AICodedbManagerActionSession.ClassifyAuthority(title), context);
                Assert.That(AICodedbManagerActionJournal.TryAdmit(index, out var error), Is.True, error);
                if (resolved)
                    Assert.That(AICodedbManagerActionJournal.TryRelease(index,
                        AICodedbManagerActionEvidenceKind.CommandTerminal, out error), Is.True, error);
            }

            internal string Add(string action, string output, bool terminal = true, int exit = 6,
                string stageName = null, string scriptPath = null)
            {
                var records = CreateManagerActionReceiptEnvelope();
                var arguments = action == "RuntimeConfig" ? new[] { "-Force" }
                    : AICodedbHostPayloadMaterializer.BuildScriptArguments(
                        (AICodedbHostPayloadAction)Enum.Parse(typeof(AICodedbHostPayloadAction), action),
                        action == "Install" || action == "Redeploy", Context.ProjectRoot);
                var argumentHash = Hash(string.Join("\n", arguments));
                var scriptHash = new string('a', 64);
                var identity = Hash(scriptHash + "\n" + argumentHash + "\n120000");
                var stageId = Hash(ActionId + "\n" + (stageName ?? Guid.NewGuid().ToString("N")) + "\n" + identity);
                var actionRoot = AICodedbPaths.GetManagerActionReceiptRoot(Context, ActionId);
                var stagePrefix = Path.Combine(actionRoot, stageId.Substring(0, 16));
                foreach (var record in records)
                {
                    record["storage_layout"] = AICodedbPaths.CompactReceiptLayout;
                    record["action_id"] = ActionId;
                    record["stage_id"] = stageId;
                    record["project_key"] = AICodedbPaths.GetManagerActionProjectKey(Context);
                    record["package_key"] = AICodedbPaths.GetManagerActionPackageKey(Context);
                }
                foreach (var record in new[] { records[0], records[2] })
                {
                    record["project_identity"] = "sha256:" + records[0]["project_key"];
                    record["package_identity"] = "sha256:" + records[0]["package_key"];
                    record["effect_class"] = "ConfirmedProjectMutation";
                    record["authorization_source"] = AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB");
                    record["command_identity_sha256"] = identity;
                    record["terminal_for_action"] = terminal;
                }
                records[0]["project_root"] = Context.ProjectRoot;
                records[0]["package_root"] = Context.PackageRoot;
                records[0]["writer_sha256"] = new string('b', 64);
                records[0]["command"] = new Dictionary<string, object>
                {
                    ["script_path"] = scriptPath ?? AICodedbPaths.NormalizePath(Path.Combine(Context.PackageRoot,
                        AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath)),
                    ["script_sha256"] = scriptHash, ["arguments_sha256"] = argumentHash,
                    ["arguments"] = arguments, ["timeout_ms"] = 120000
                };
                records[2]["stdout"] = output;
                records[2]["stderr"] = string.Empty;
                records[2]["exit_code"] = exit;
                records[2]["output_drain_incomplete"] = false;
                var names = new[] { "admitted.json", "claim.json", "terminal.json" };
                for (var i = 0; i < names.Length; i++)
                    File.WriteAllText(AICodedbPaths.GetManagerStageReceiptPath(actionRoot, stageId,
                            names[i].Substring(0, names[i].Length - 5)),
                        AICodedbControlContractMigrationClassifierTests.SerializeObject(records[i]), new UTF8Encoding(false));
                return stagePrefix;
            }

            internal Dictionary<string, string> AddRedeploy(bool manager, string failedStage = null,
                string configPath = null)
            {
                var stages = new Dictionary<string, string>(StringComparer.Ordinal);
                if (manager)
                {
                    stages["ui"] = Add("DryRun", "[REDEPLOY_READY] Owned payload can redeploy.", false,
                        failedStage == "ui" ? 6 : 0, AICodedbActions.RedeployUiPreflightStage);
                    if (failedStage == "ui") return stages;
                }
                stages["worker"] = Add("DryRun", "[REDEPLOY_READY] Owned payload can redeploy.", false,
                    failedStage == "worker" ? 6 : 0, AICodedbActions.RedeployWorkerPreflightStage);
                if (failedStage == "worker") return stages;
                var mutation = failedStage == "mutation"
                    ? CommandOutput("REDEPLOY", "MUTATION", "PENDING", "host_runtime")
                    : CommandOutput("REDEPLOY", "COMPLETE", "COMPLETE", "host_runtime")
                        .Replace("\"FAILED\"", "\"CONVERGED\"").Replace("\"exit_code\":6", "\"exit_code\":0");
                stages["mutation"] = Add("Redeploy", mutation, false, failedStage == "mutation" ? 6 : 0,
                    AICodedbActions.RedeployMutationStage);
                if (failedStage == "mutation" || failedStage == "missing-config") return stages;
                stages["config"] = Add("RuntimeConfig", "Runtime config generated.", true,
                    failedStage == "config" ? 6 : 0, AICodedbActions.RedeployRuntimeConfigStage,
                    configPath ?? AICodedbPaths.NormalizePath(Path.Combine(Context.ProjectRoot,
                        AICodedbProjectSettings.HostGenerationsRelativePath, "fixture-generation",
                        "scripts/prepare-codedb-project-runtime.ps1")));
                return stages;
            }

            internal static void ChangeField(string stagePrefix, string filename, string field, object value)
            {
                var path = StagePath(stagePrefix, filename);
                Assert.That(File.Exists(path), Is.True, "Required fixture record is missing: " + path);
                var record = AICodedbStrictJson.ReadObject(path, 1048576, "fixture stage");
                record[field] = value;
                File.WriteAllText(path, AICodedbControlContractMigrationClassifierTests.SerializeObject(record), new UTF8Encoding(false));
            }

            internal static string StagePath(string stagePrefix, string filename) => stagePrefix + "." + filename;

            internal static void DeleteStage(AICodedbTestWorkspace workspace, string stagePrefix)
            {
                var names = new[] { "admitted.json", "claim.json", "terminal.json", "start-failure.json" };
                var paths = new string[names.Length];
                for (var i = 0; i < names.Length; i++)
                {
                    paths[i] = StagePath(stagePrefix, names[i]);
                    workspace.ValidateCleanupTarget(paths[i]);
                    if (i < 3)
                        Assert.That(File.Exists(paths[i]), Is.True, "Required predecessor record is missing: " + paths[i]);
                }
                foreach (var path in paths)
                {
                    workspace.ValidateCleanupTarget(path);
                    if (File.Exists(path)) File.Delete(path);
                    Assert.That(File.Exists(path), Is.False, "Predecessor record remains: " + path);
                }
            }

            internal void AddFollowUps(bool upgradeTerminal = true, string upgradeOutput = null)
            {
                Add("DryRun", HistoricalDryRunOutput, exit: 0);
                Add("Upgrade", upgradeOutput ?? HistoricalCommandOutput("UPGRADE", _historicalOutcome), upgradeTerminal);
            }

            // Sanitized real three-stage shape; never use machine journal identities.
            internal const string HistoricalDryRunOutput =
                "[PRODUCT_LAYER PREREQUISITE] CURRENT - Fixture prerequisites verified.\n"
                + "[PRODUCT_LAYER INSTALLED] MISSING\n[PRODUCT_LAYER CONFIGURED] MISSING\n"
                + "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE\n[PRODUCT_STATE] NEEDS_ATTENTION\n[INSTANCE] NONE\n";

            internal static string HistoricalCommandOutput(string action, string outcome = "BLOCKED")
            {
                var install = action == "INSTALL";
                return CommandOutput(action, install ? "CANDIDATE" : "PREFLIGHT", install ? "PENDING" : "COMPLETE",
                        install ? new[] { "host_runtime", "instance_candidate" } : Array.Empty<string>())
                    .Replace("\"FAILED\"", "\"" + outcome + "\"")
                    .Replace("\"FIXTURE\"", install ? "\"INSTANCE_CANDIDATE_FAILED\"" : "\"INSTANCE_CONVERGENCE_FAILED\"");
            }

            internal static string CommandOutput(string action, string phase, string cleanup, params string[] scopes)
            {
                return "[COMMAND_RESULT] " + AICodedbControlContractMigrationClassifierTests.SerializeObject(new Dictionary<string, object>
                {
                    ["schema_version"] = 1, ["managed_by"] = "com.rice.ai-codedb",
                    ["action"] = action, ["outcome"] = "FAILED", ["phase"] = phase,
                    ["reason_code"] = "FIXTURE", ["mutated_scopes"] = scopes,
                    ["cleanup_state"] = cleanup, ["next_action"] = "Review result",
                    ["exit_code"] = 6, ["detail"] = "fixture"
                });
            }

            private static string Hash(string value)
            {
                using (var sha = SHA256.Create())
                    return BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(value)))
                        .Replace("-", string.Empty).ToLowerInvariant();
            }

            public void Dispose()
            {
                _scope.Dispose();
            }
        }

        [TestCase(false, false)]
        [TestCase(false, true)]
        [TestCase(true, false)]
        [TestCase(true, true)]
        public void ManagerReceipt_DeclaredRedeployCompletesSessionAndResolvedHistory(bool manager, bool resolved)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, resolved, "Host Payload Redeploy");
                fixture.AddRedeploy(manager, configPath: resolved
                    ? AICodedbPaths.NormalizePath(Path.Combine(fixture.Context.ProjectRoot,
                        AICodedbProjectSettings.PrepareRuntimeScriptRelativePath)) : null);
                var records = new Dictionary<string, byte[]>();
                foreach (var path in Directory.GetFiles(AICodedbPaths.GetManagerActionReceiptRoot(fixture.Context, fixture.ActionId),
                    "*.json", SearchOption.AllDirectories)) records.Add(path, File.ReadAllBytes(path));
                var recovery = AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId);
                Assert.That(recovery.State, Is.EqualTo(AICodedbManagerActionRecoveryState.Terminal));
                Assert.That(recovery.Result.Succeeded, Is.True);
                Assert.That(recovery.Result.TerminalForManagerAction, Is.True);
                Assert.That(recovery.Result.StandardOutput, Does.Contain("REDEPLOY").And.Contain("Runtime config generated."));
                var command = AICodedbMaterializerCommandStatusParser.Parse(recovery.Result.StandardOutput);
                Assert.That(command.IsValid, Is.True);
                Assert.That(command.MutatedScopes, Is.EqualTo(new[] { "host_runtime" }));
                foreach (var record in records)
                    Assert.That(File.ReadAllBytes(record.Key), Is.EqualTo(record.Value), record.Key);
                var current = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                    fixture.Context.ProjectRoot, fixture.Context.PackageRoot + "-replacement", "fixture");
                var read = AICodedbManagerActionJournal.Read(current);
                Assert.That(read.State, Is.EqualTo(resolved ? AICodedbManagerActionIndexState.Empty : AICodedbManagerActionIndexState.Pending));
                if (!resolved)
                {
                    AICodedbManagerActionSession.RestoreDurable(current, read, 1d);
                    var session = AICodedbManagerActionSession.CurrentFor(current);
                    Assert.That(session.Context.PackageRoot, Is.EqualTo(fixture.Context.PackageRoot));
                    Assert.That(session.TryReleaseDurableIndex(recovery.Result, out var error), Is.True, error);
                    Assert.That(session.TryCompleteRecovery(recovery.Result, 2d), Is.True);
                    Assert.That(session.IsRecovering, Is.False);
                    Assert.That(session.Result.StandardOutput, Is.EqualTo(recovery.Result.StandardOutput));
                    Assert.That(AICodedbManagerActionJournal.Read(current).State, Is.EqualTo(AICodedbManagerActionIndexState.Empty));
                }
                Assert.That(AICodedbManagerActionSession.TryStart("Host Payload Verify", current, 3d, out var next), Is.True);
                Assert.That(next.ActionId, Is.Not.EqualTo(fixture.ActionId));
            });
        }

        [TestCase(true, "ui")]
        [TestCase(true, "worker")]
        [TestCase(false, "worker")]
        [TestCase(true, "mutation")]
        [TestCase(false, "mutation")]
        [TestCase(true, "config")]
        [TestCase(false, "config")]
        public void ManagerReceipt_DeclaredRedeployEarlyFailureRetainsFailureAndEffects(bool manager, string failedStage)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, false, "Host Payload Redeploy");
                var stages = fixture.AddRedeploy(manager, failedStage);
                var failurePath = ManagerReceiptFixture.StagePath(stages[failedStage], "terminal.json");
                var failureBytes = File.ReadAllBytes(failurePath);
                var recovery = AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId);
                Assert.That(recovery.State, Is.EqualTo(AICodedbManagerActionRecoveryState.Terminal));
                Assert.That(recovery.Result.Succeeded, Is.False);
                Assert.That(recovery.Result.ExitCode, Is.EqualTo(6));
                Assert.That(recovery.Result.HasAuthoritativeTerminalEvidence, Is.True);
                Assert.That(recovery.Result.TerminalForManagerAction, Is.True);
                Assert.That(File.ReadAllBytes(failurePath), Is.EqualTo(failureBytes));
                if (failedStage == "mutation" || failedStage == "config")
                {
                    var command = AICodedbMaterializerCommandStatusParser.Parse(recovery.Result.StandardOutput);
                    Assert.That(command.IsValid, Is.True);
                    Assert.That(command.Action, Is.EqualTo("REDEPLOY"));
                    Assert.That(command.MutatedScopes, Is.EqualTo(new[] { "host_runtime" }));
                    Assert.That(command.CleanupState, Is.EqualTo(failedStage == "mutation" ? "PENDING" : "COMPLETE"));
                }
                var read = AICodedbManagerActionJournal.Read(fixture.Context);
                AICodedbManagerActionSession.RestoreDurable(fixture.Context, read, 1d);
                var session = AICodedbManagerActionSession.CurrentFor(fixture.Context);
                Assert.That(session.TryReleaseDurableIndex(recovery.Result, out var error), Is.True, error);
                Assert.That(session.TryCompleteRecovery(recovery.Result, 2d), Is.True);
                Assert.That(session.Result.Succeeded, Is.False);
                Assert.That(AICodedbManagerActionJournal.Read(fixture.Context).State, Is.EqualTo(AICodedbManagerActionIndexState.Empty));
            });
        }

        [TestCase("extra-mutation")]
        [TestCase("unknown-name")]
        [TestCase("wrong-terminal")]
        [TestCase("malformed")]
        [TestCase("unbound-arguments")]
        [TestCase("wrong-script")]
        [TestCase("pending-stage")]
        [TestCase("missing-predecessor")]
        [TestCase("incomplete-output")]
        [TestCase("missing-config")]
        [TestCase("failure-with-successor")]
        public void ManagerReceipt_DeclaredRedeployRejectsUnknownOrIncompleteChain(string defect)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, true, "Host Payload Redeploy");
                var stages = fixture.AddRedeploy(true, defect == "missing-config" ? "missing-config" : null,
                    defect == "wrong-script" ? AICodedbPaths.NormalizePath(Path.Combine(fixture.Context.ProjectRoot, "unexpected.ps1")) : null);
                if (defect == "extra-mutation") fixture.Add("Install", fixture.InstallOutput, false);
                if (defect == "unknown-name")
                    fixture.Add("Redeploy", ManagerReceiptFixture.CommandOutput("REDEPLOY", "MUTATION", "PENDING", "host_runtime"), false,
                        stageName: "redeploy-undeclared-mutation");
                if (defect == "wrong-terminal")
                {
                    ManagerReceiptFixture.ChangeField(stages["mutation"], "admitted.json", "terminal_for_action", true);
                    ManagerReceiptFixture.ChangeField(stages["mutation"], "terminal.json", "terminal_for_action", true);
                }
                if (defect == "malformed")
                {
                    var path = ManagerReceiptFixture.StagePath(stages["worker"], "terminal.json");
                    Assert.That(File.Exists(path), Is.True, "Required fixture terminal is missing: " + path);
                    File.WriteAllText(path, "{}");
                }
                if (defect == "unbound-arguments")
                {
                    var path = ManagerReceiptFixture.StagePath(stages["worker"], "admitted.json");
                    Assert.That(File.Exists(path), Is.True, "Required fixture admission is missing: " + path);
                    File.WriteAllText(path, File.ReadAllText(path).Replace("-ProjectRoot", "-Unexpected"));
                }
                if (defect == "pending-stage")
                {
                    var path = ManagerReceiptFixture.StagePath(stages["config"], "terminal.json");
                    Assert.That(File.Exists(path), Is.True, "Required fixture terminal is missing: " + path);
                    File.Delete(path);
                }
                if (defect == "missing-predecessor") ManagerReceiptFixture.DeleteStage(workspace, stages["worker"]);
                if (defect == "incomplete-output")
                    ManagerReceiptFixture.ChangeField(stages["mutation"], "terminal.json", "output_drain_incomplete", true);
                if (defect == "failure-with-successor")
                {
                    ManagerReceiptFixture.ChangeField(stages["mutation"], "terminal.json", "exit_code", 6);
                    ManagerReceiptFixture.ChangeField(stages["mutation"], "terminal.json", "stdout",
                        ManagerReceiptFixture.CommandOutput("REDEPLOY", "MUTATION", "PENDING", "host_runtime"));
                }
                var recovery = AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId);
                Assert.That(recovery.State, Is.EqualTo(defect == "missing-config" || defect == "incomplete-output"
                    ? AICodedbManagerActionRecoveryState.Pending : AICodedbManagerActionRecoveryState.Conflict));
                var read = AICodedbManagerActionJournal.Read(fixture.Context);
                Assert.That(read.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                AICodedbManagerActionSession.RestoreDurable(fixture.Context, read, 1d);
                Assert.That(AICodedbManagerActionSession.TryStart("Host Payload Verify", fixture.Context, 2d, out _), Is.False);
            });
        }

        [TestCase(false, false, "FAILED")]
        [TestCase(false, true, "FAILED")]
        [TestCase(true, false, "FAILED")]
        [TestCase(true, true, "FAILED")]
        [TestCase(false, false, "BLOCKED")]
        [TestCase(false, true, "BLOCKED")]
        [TestCase(true, false, "BLOCKED")]
        [TestCase(true, true, "BLOCKED")]
        public void ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate(bool threeStages, bool resolved, string outcome)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, resolved, historicalOutcome: outcome);
                if (threeStages && resolved) fixture.AddFollowUps();
                fixture.Add("Install", fixture.InstallOutput);
                if (threeStages && !resolved) fixture.AddFollowUps();
                var replacement = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                    fixture.Context.ProjectRoot, fixture.Context.PackageRoot + "-replacement", "fixture");
                var before = new Dictionary<string, byte[]>();
                foreach (var file in Directory.GetFiles(AICodedbPaths.GetManagerActionIndexDirectory(fixture.Context), "*.json", SearchOption.AllDirectories))
                    before.Add(file, File.ReadAllBytes(file));
                var recovery = AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId);
                Assert.That(recovery.State, Is.EqualTo(AICodedbManagerActionRecoveryState.Terminal));
                Assert.That(recovery.Result.StandardOutput, Is.EqualTo(fixture.InstallOutput));
                Assert.That(recovery.Result.Succeeded, Is.False);
                Assert.That(AICodedbActions.HasFailedInstallPendingEffects(recovery.Result), Is.True);
                var read = AICodedbManagerActionJournal.Read(replacement);
                Assert.That(read.State, Is.EqualTo(resolved ? AICodedbManagerActionIndexState.Empty : AICodedbManagerActionIndexState.Pending));
                AICodedbManagerActionSession.RestoreDurable(replacement, read, 1d);
                var session = AICodedbManagerActionSession.CurrentFor(replacement);
                Assert.That(session.Context.PackageRoot, Is.EqualTo(fixture.Context.PackageRoot));
                if (!resolved)
                {
                    Assert.That(session.TryReleaseDurableIndex(recovery.Result, out var error), Is.True, error);
                    Assert.That(session.TryCompleteRecovery(recovery.Result, 2d), Is.True);
                }
                Assert.That(session.IsRecovering, Is.False);
                Assert.That(session.Result.StandardOutput, Is.EqualTo(fixture.InstallOutput));
                Assert.That(AICodedbActions.CanRequestInstallReconcile(session.Result), Is.False);
                Assert.That(AICodedbManagerActionJournal.Read(replacement).HistoricalWarning,
                    Does.Contain("PENDING").And.Contain(fixture.Context.PackageRoot));
                if (resolved)
                    foreach (var file in before)
                        Assert.That(File.ReadAllBytes(file.Key), Is.EqualTo(file.Value), file.Key);
                var command = AICodedbMaterializerCommandStatusParser.Parse(session.Result.StandardOutput);
                AICodedbProductStatus Status(bool safe) => new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention, AICodedbProductLayerState.Current,
                    AICodedbProductLayerState.Blocked, AICodedbProductLayerState.Blocked,
                    "", command, AICodedbProductAttentionReason.None, "", safe);
                Assert.That(AICodedbManagerWindow.IsUninstallAvailable(
                    AICodedbManagerWindow.ResolveRemovalPresentationStatus(Status(false), Status(true), true), false), Is.True);
                Assert.That(AICodedbManagerWindow.IsUninstallAvailable(Status(false), false), Is.False);
                var dispatched = false;
                Assert.That(AICodedbManagerWindow.ConfirmAndRunUninstallCodeDB(() => false, () => dispatched = true), Is.False);
                Assert.That(dispatched, Is.False);
                Assert.That(AICodedbManagerActionSession.TryStart("Uninstall CodeDB from Project", replacement, 3d, out _), Is.True);
            });
        }

        [Test]
        public void MaterializerResults_ProductionWriterFeedsHistoricalRecoveryAndSession()
        {
            // Resolve the actual installed Package before fixture scopes replace context.
            var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(AICodedbProjectSettingsTests).Assembly);
            Assert.That(package, Is.Not.Null);
            var script = Path.Combine(package.resolvedPath, "Tests~", "test-codedb-host-payload-materializer.ps1");
            Assert.That(File.Exists(script), Is.True, "The exact delivered Package must contain its writer harness.");
            AICodedbTestWorkspace.Run(workspace =>
            {
                var outputs = RunProductionCommandWriter(script, workspace);
                Assert.That(outputs.Count, Is.EqualTo(6));
                for (var i = 0; i < outputs.Count; i++)
                {
                    var command = AICodedbMaterializerCommandStatusParser.Parse(outputs[i]);
                    var install = i % 2 == 0;
                    Assert.That(command.IsValid, Is.True, command.Detail);
                    Assert.That(command.Action, Is.EqualTo(install ? "INSTALL" : "UPGRADE"));
                    Assert.That(command.Outcome, Is.EqualTo(i < 2 ? "BLOCKED" : i < 4 ? "FAILED" : install ? "INSTALLED" : "CONVERGED"));
                    Assert.That(command.ExitCode, Is.EqualTo(i < 4 ? 6 : 0));
                    Assert.That(command.CleanupState, Is.EqualTo(i < 4 && install ? "PENDING" : "COMPLETE"));
                    if (i < 4)
                        Assert.That(command.ReasonCode, Is.EqualTo(install ? "INSTANCE_CANDIDATE_FAILED" : "INSTANCE_CONVERGENCE_FAILED"));
                    var result = new AICodedbCommandResult(command.ExitCode, outputs[i], "", false,
                        authoritativeTerminalEvidence: true);
                    Assert.That(AICodedbMaterializerCommandSemantics.ClassifyHistoricalNonSuccess(result),
                        Is.EqualTo(i >= 4 ? AICodedbHistoricalNonSuccess.None : install
                            ? AICodedbHistoricalNonSuccess.InstallPendingEffects : AICodedbHistoricalNonSuccess.UpgradeRefusedWithoutEffects));
                    Assert.That(AICodedbActions.HasFailedInstallPendingEffects(result), Is.EqualTo(i < 4 && install));
                }
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, true);
                fixture.Add("Install", outputs[0]);
                fixture.Add("DryRun", ManagerReceiptFixture.HistoricalDryRunOutput, exit: 0);
                fixture.Add("Upgrade", outputs[1]);
                var recovery = AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId);
                Assert.That(recovery.State, Is.EqualTo(AICodedbManagerActionRecoveryState.Terminal));
                Assert.That(recovery.Result.StandardOutput, Is.EqualTo(outputs[0]));
                var read = AICodedbManagerActionJournal.Read(fixture.Context);
                Assert.That(read.State, Is.EqualTo(AICodedbManagerActionIndexState.Empty));
                Assert.That(read.HistoricalWarning, Does.Contain("PENDING"));
                AICodedbManagerActionSession.RestoreDurable(fixture.Context, read, 1d);
                var session = AICodedbManagerActionSession.CurrentFor(fixture.Context);
                Assert.That(session.Result.StandardOutput, Is.EqualTo(outputs[0]));
                Assert.That(session.Result.Succeeded, Is.False);
                Assert.That(AICodedbActions.CanRequestInstallReconcile(session.Result), Is.False);
            });
        }

        private static List<string> RunProductionCommandWriter(string script, AICodedbTestWorkspace workspace)
        {
            var start = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + script + "\" -CommandResultSemanticsOnly",
                WorkingDirectory = workspace.Root,
                UseShellExecute = false, CreateNoWindow = true,
                RedirectStandardOutput = true, RedirectStandardError = true,
                StandardOutputEncoding = new UTF8Encoding(false), StandardErrorEncoding = new UTF8Encoding(false)
            };
            start.EnvironmentVariables["TEMP"] = workspace.Root;
            start.EnvironmentVariables["TMP"] = workspace.Root;
            using var process = System.Diagnostics.Process.Start(start);
            Assert.That(process, Is.Not.Null);
            var stdout = process.StandardOutput.ReadToEndAsync();
            var stderr = process.StandardError.ReadToEndAsync();
            if (!process.WaitForExit(15000))
            {
                process.Kill(); // Only the fixture process created immediately above.
                process.WaitForExit(5000);
                Assert.Fail("Isolated command-result writer timed out.");
            }
            Assert.That(Task.WaitAll(new Task[] { stdout, stderr }, 5000), Is.True, "Writer output drain timed out.");
            Assert.That(process.ExitCode, Is.EqualTo(0), stderr.Result);
            Assert.That(stderr.Result, Is.Empty);
            Assert.That(stdout.Result.Length, Is.LessThan(16384), "Unexpected writer harness output.");
            var results = new List<string>();
            foreach (var line in stdout.Result.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
                if (line.StartsWith("[COMMAND_RESULT] ", StringComparison.Ordinal)) results.Add(line);
            Assert.That(stdout.Result, Does.Contain("[COMMAND_RESULT_SEMANTICS] 6/6"));
            return results;
        }

        [TestCase("INSTALL", "zero-exit")]
        [TestCase("UPGRADE", "zero-exit")]
        [TestCase("INSTALL", "exit-mismatch")]
        [TestCase("UPGRADE", "exit-mismatch")]
        [TestCase("INSTALL", "success-outcome")]
        [TestCase("UPGRADE", "success-outcome")]
        [TestCase("INSTALL", "unsupported-outcome")]
        [TestCase("UPGRADE", "unsupported-outcome")]
        [TestCase("INSTALL", "action")]
        [TestCase("UPGRADE", "action")]
        [TestCase("INSTALL", "phase")]
        [TestCase("UPGRADE", "phase")]
        [TestCase("INSTALL", "scopes")]
        [TestCase("UPGRADE", "scopes")]
        [TestCase("INSTALL", "cleanup")]
        [TestCase("UPGRADE", "cleanup")]
        [TestCase("INSTALL", "missing")]
        [TestCase("UPGRADE", "missing")]
        [TestCase("INSTALL", "malformed")]
        [TestCase("UPGRADE", "malformed")]
        public void MaterializerResults_UnsupportedShapeCannotResolveHistoricalChain(string action, string defect)
        {
            var install = action == "INSTALL";
            var output = ManagerReceiptFixture.HistoricalCommandOutput(action);
            var record = AICodedbStrictJson.ParseObject(output.Substring("[COMMAND_RESULT] ".Length), "fixture result");
            var exit = defect == "zero-exit" ? 0 : 6;
            if (defect == "zero-exit") record["exit_code"] = 0;
            if (defect == "exit-mismatch") record["exit_code"] = 7;
            if (defect == "success-outcome") record["outcome"] = install ? "INSTALLED" : "CONVERGED";
            if (defect == "unsupported-outcome") record["outcome"] = "UNKNOWN";
            if (defect == "action") record["action"] = "REMOVE";
            if (defect == "phase") record["phase"] = install ? "PREFLIGHT" : "CANDIDATE";
            if (defect == "scopes") record["mutated_scopes"] = install ? Array.Empty<string>() : new[] { "host_runtime" };
            if (defect == "cleanup") record["cleanup_state"] = install ? "COMPLETE" : "PENDING";
            output = defect == "missing" ? "No command result." : defect == "malformed" ? "[COMMAND_RESULT] {}"
                : "[COMMAND_RESULT] " + AICodedbControlContractMigrationClassifierTests.SerializeObject(record);
            Assert.That(AICodedbMaterializerCommandSemantics.ClassifyHistoricalNonSuccess(
                new AICodedbCommandResult(exit, output, "", false, authoritativeTerminalEvidence: true)),
                Is.EqualTo(AICodedbHistoricalNonSuccess.None));
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, true, historicalOutcome: "BLOCKED");
                fixture.Add("Install", install ? output : fixture.InstallOutput, exit: install ? exit : 6);
                fixture.Add("DryRun", ManagerReceiptFixture.HistoricalDryRunOutput, exit: 0);
                fixture.Add("Upgrade", install ? ManagerReceiptFixture.HistoricalCommandOutput("UPGRADE") : output, exit: install ? 6 : exit);
                Assert.That(AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId).State,
                    Is.EqualTo(AICodedbManagerActionRecoveryState.Conflict));
                Assert.That(AICodedbManagerActionJournal.Read(fixture.Context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
            });
        }

        [TestCase("INSTALL", "authority")]
        [TestCase("UPGRADE", "authority")]
        [TestCase("INSTALL", "timeout")]
        [TestCase("UPGRADE", "timeout")]
        [TestCase("INSTALL", "overflow")]
        [TestCase("UPGRADE", "overflow")]
        [TestCase("INSTALL", "drain")]
        [TestCase("UPGRADE", "drain")]
        public void MaterializerResults_IncompleteEvidenceIsNotKnownFailure(string action, string defect)
        {
            var result = new AICodedbCommandResult(6, ManagerReceiptFixture.HistoricalCommandOutput(action), "",
                defect == "timeout", authoritativeTerminalEvidence: defect != "authority",
                outputOverflow: defect == "overflow", outputDrainIncomplete: defect == "drain");
            Assert.That(AICodedbMaterializerCommandSemantics.ClassifyHistoricalNonSuccess(result),
                Is.EqualTo(AICodedbHistoricalNonSuccess.None));
            Assert.That(AICodedbActions.HasFailedInstallPendingEffects(result), Is.False);
        }

        [TestCase("pending")]
        [TestCase("malformed")]
        [TestCase("identity")]
        [TestCase("arguments")]
        [TestCase("extra-mutation")]
        [TestCase("nonterminal")]
        [TestCase("mutating-upgrade")]
        [TestCase("duplicate-install")]
        public void ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage(string defect)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, true);
                var installPrefix = fixture.Add("Install", fixture.InstallOutput);
                fixture.AddFollowUps(defect != "nonterminal", defect == "mutating-upgrade"
                    ? ManagerReceiptFixture.CommandOutput("UPGRADE", "PREFLIGHT", "COMPLETE", "host_runtime") : null);
                var terminalPath = ManagerReceiptFixture.StagePath(installPrefix, "terminal.json");
                Assert.That(File.Exists(terminalPath), Is.True, "Required fixture terminal is missing: " + terminalPath);
                if (defect == "pending") File.Delete(terminalPath);
                if (defect == "malformed") File.WriteAllText(terminalPath, "{}");
                if (defect == "identity") File.WriteAllText(terminalPath,
                    File.ReadAllText(terminalPath).Replace(fixture.ActionId, Guid.NewGuid().ToString("N")));
                if (defect == "arguments")
                {
                    var path = ManagerReceiptFixture.StagePath(installPrefix, "admitted.json");
                    Assert.That(File.Exists(path), Is.True, "Required fixture admission is missing: " + path);
                    File.WriteAllText(path, File.ReadAllText(path).Replace("-ProjectRoot", "-Unexpected"));
                }
                if (defect == "extra-mutation" || defect == "duplicate-install")
                    fixture.Add("Install", fixture.InstallOutput, defect != "extra-mutation");
                Assert.That(AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId).State,
                    Is.EqualTo(AICodedbManagerActionRecoveryState.Conflict));
                var current = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                    fixture.Context.ProjectRoot, fixture.Context.PackageRoot + "-new", "fixture");
                var read = AICodedbManagerActionJournal.Read(current);
                Assert.That(read.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                Assert.That(read.ActionId, Is.EqualTo(fixture.ActionId));
                Assert.That(read.Index, Is.Not.Null);
                Assert.That(read.Index.ActionId, Is.EqualTo(fixture.ActionId));
                Assert.That(read.Index.Context.ProjectRoot, Is.EqualTo(fixture.Context.ProjectRoot));
                Assert.That(read.Index.Context.PackageRoot, Is.EqualTo(fixture.Context.PackageRoot));
                Assert.That(read.Index.StorageLayout, Is.EqualTo(AICodedbPaths.CompactReceiptLayout));
                Assert.That(read.HistoricalResult, Is.Null);
                AICodedbManagerActionSession.RestoreDurable(current, read, 1d);
                var session = AICodedbManagerActionSession.CurrentFor(current);
                Assert.That(session.ActionId, Is.EqualTo(fixture.ActionId));
                Assert.That(session.HasOriginalContext, Is.True);
                Assert.That(session.IsEvidenceConflict, Is.True);
                Assert.That(session.Context.PackageRoot, Is.EqualTo(fixture.Context.PackageRoot));
                Assert.That(session.StorageLayout, Is.EqualTo(AICodedbPaths.CompactReceiptLayout));
                Assert.That(AICodedbManagerWindow.BuildHistoricalActionWarning(session, read.HistoricalWarning),
                    Does.Contain(fixture.Context.PackageRoot).And.Not.Contain(current.PackageRoot));
                Assert.That(AICodedbManagerActionSession.TryStart("Install CodeDB", current, 2d, out _), Is.False);
                Assert.That(AICodedbManagerActionJournal.TryAdmit(new AICodedbManagerActionIndex(
                    Guid.NewGuid().ToString("N"), "Host Payload Verify", "Observation", "PackageMaterializer", current), out _), Is.False);
            });
        }

        [Test]
        public void ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                AICodedbManagerActionSession.RestoreDurable(fixture.Context,
                    new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                        detail: "invalid identity", actionId: Guid.NewGuid().ToString("N")), 1d);
                var session = AICodedbManagerActionSession.CurrentFor(fixture.Context);
                Assert.That(AICodedbManagerWindow.BuildHistoricalActionWarning(session, ""),
                    Does.Contain("original Package unavailable").And.Not.Contain(fixture.Context.PackageRoot));
            });
        }

        [TestCase("terminal", AICodedbManagerActionRecoveryState.Terminal)]
        [TestCase("pending", AICodedbManagerActionRecoveryState.Pending)]
        [TestCase("nonterminal", AICodedbManagerActionRecoveryState.Pending)]
        public void ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown(
            string shape, AICodedbManagerActionRecoveryState expected)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var sessionFixture = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, sessionFixture.Context, false);
                var stage = fixture.Add("DryRun", "[UPGRADE_READY] Candidate generation is available.",
                    shape != "nonterminal", 0);
                if (shape == "pending")
                {
                    var path = ManagerReceiptFixture.StagePath(stage, "terminal.json");
                    Assert.That(File.Exists(path), Is.True, "Required fixture terminal is missing: " + path);
                    File.Delete(path);
                }
                var read = AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId);
                Assert.That(read.State, Is.EqualTo(expected));
                if (expected == AICodedbManagerActionRecoveryState.Terminal)
                    Assert.That(read.Result.Succeeded, Is.True);
            });
        }

        [Test]
        public void DirectInstallArguments_BindActualActionBeforeAdmission()
        {
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                Path.Combine(Path.GetTempPath(), "codedb-s29-identity"),
                Path.Combine(Path.GetTempPath(), "codedb-s29-package"), "s29");
            var actionId = Guid.NewGuid().ToString("N");
            using (AICodedbPaths.UseActionContext(context, actionId))
            {
                var arguments = AICodedbHostPayloadMaterializer.BuildRuntimeScriptArguments(
                    AICodedbHostPayloadAction.Install, true, context.ProjectRoot);
                Assert.That(arguments[Array.IndexOf(arguments, "-OriginatingActionId") + 1], Is.EqualTo(actionId));
                var operationId = arguments[Array.IndexOf(arguments, "-OriginatingOperationId") + 1];
                Assert.That(operationId, Does.Match("^[0-9a-f]{32}$"));
                Assert.That(operationId, Is.Not.EqualTo(actionId));
                Assert.That(Array.FindAll(arguments, value => value == "-OriginatingOperationId").Length, Is.EqualTo(1));
            }
        }

        [TestCase(1, "FAILED", "PENDING", true, false)]
        [TestCase(0, "UNKNOWN", "PENDING", true, false)]
        [TestCase(0, "INSTALLED", "PENDING", true, false)]
        [TestCase(0, "INSTALLED", "COMPLETE", false, false)]
        [TestCase(0, "INSTALLED", "COMPLETE", true, true)]
        public void InstallEntryAndManager_RequireConfirmedCompleteSuccess(
            int exitCode, string outcome, string cleanup, bool authoritative, bool expected)
        {
            var output = "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"action\":\"INSTALL\",\"outcome\":\"" + outcome + "\",\"phase\":\"COMPLETE\","
                + "\"reason_code\":\"FIXTURE\",\"mutated_scopes\":[],\"cleanup_state\":\"" + cleanup
                + "\",\"next_action\":\"Review result\",\"exit_code\":" + exitCode + ",\"detail\":\"fixture\"}";
            var result = new AICodedbCommandResult(exitCode, output, string.Empty, false,
                authoritativeTerminalEvidence: authoritative);
            Assert.That(AICodedbActions.CanRequestInstallReconcile(result), Is.EqualTo(expected));
            Assert.That(AICodedbManagerWindow.CanRequestActionReconcile("Install CodeDB", result), Is.EqualTo(expected));
        }

        [Test]
        public void InstallEntry_MissingOrMalformedResultDoesNotReconcile()
        {
            Assert.That(AICodedbActions.CanRequestInstallReconcile(null), Is.False);
            Assert.That(AICodedbActions.CanRequestInstallReconcile(new AICodedbCommandResult(0, "", "", false)), Is.False);
            Assert.That(AICodedbActions.CanRequestInstallReconcile(new AICodedbCommandResult(0, "[COMMAND_RESULT] {}", "", false)), Is.False);
        }

        // Synchronous, test-owned isolation only. Hold the production Gate so
        // other session callers cannot observe or replace the temporary owner.
        private sealed class ManagerActionSessionFixture : IDisposable
        {
            private const string MissingValue = "S28_FIXTURE_KEY_ABSENT";
            private static readonly object IsolationGate = new object();
            private static ManagerActionSessionFixture _active;
            private readonly object _sessionGate;
            private readonly System.Reflection.FieldInfo _currentField;
            private readonly AICodedbManagerActionSession _savedSession;
            private readonly int _ownerThread;
            private readonly AICodedbTestWorkspace _workspace;
            private bool _disposed;

            internal string Token { get; }
            internal AICodedbEditorExecutionContext Context { get; }
            internal string PendingKey { get; }
            internal bool OriginalRestored { get; private set; }
            internal bool OwnedKeyRemoved { get; private set; }

            internal ManagerActionSessionFixture(AICodedbTestWorkspace workspace)
            {
                _workspace = workspace;
                // Use the public BCL context boundary, not a version-specific
                // InternalEditorUtility API. Unknown contexts fail before isolation.
                var editorContext = SynchronizationContext.Current;
                if (editorContext == null || !string.Equals(editorContext.GetType().FullName,
                        "UnityEngine.UnitySynchronizationContext", StringComparison.Ordinal))
                    throw new InvalidOperationException("Session fixture requires a synchronous Editor-main-thread test.");
                if (!Monitor.TryEnter(IsolationGate, 0))
                    throw new InvalidOperationException("Concurrent session fixture isolation is not permitted.");
                var sessionGateHeld = false;
                var detached = false;
                try
                {
                    if (_active != null)
                        throw new InvalidOperationException("Nested session fixture isolation is not permitted.");
                    _ownerThread = Thread.CurrentThread.ManagedThreadId;
                    var flags = System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic;
                    var gateField = typeof(AICodedbManagerActionSession).GetField("Gate", flags);
                    _currentField = typeof(AICodedbManagerActionSession).GetField("_current", flags);
                    if (gateField == null || _currentField == null
                        || _currentField.FieldType != typeof(AICodedbManagerActionSession))
                        throw new InvalidOperationException("Reviewed session fixture boundary is unavailable.");
                    _sessionGate = gateField.GetValue(null);
                    if (_sessionGate == null || !Monitor.TryEnter(_sessionGate, 0))
                        throw new InvalidOperationException("Production session gate is already owned by another thread.");
                    sessionGateHeld = true;
                    _savedSession = (AICodedbManagerActionSession)_currentField.GetValue(null);
                    Token = Guid.NewGuid().ToString("N");
                    var root = workspace.Root;
                    Context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                        Path.Combine(root, "project"), Path.Combine(root, "package"), Token);
                    PendingKey = "Rice.AI.Codedb.Manager.PendingAction." + Context.ProjectRoot;
                    if (SessionState.GetString(PendingKey, MissingValue) != MissingValue)
                        throw new InvalidOperationException("Session fixture key is not exclusively absent.");
                    _currentField.SetValue(null, null);
                    detached = true;
                    _active = this;
                }
                catch
                {
                    if (detached) workspace.CaptureCleanup(() => _currentField.SetValue(null, _savedSession));
                    if (sessionGateHeld) workspace.CaptureCleanup(() => Monitor.Exit(_sessionGate));
                    workspace.CaptureCleanup(() => Monitor.Exit(IsolationGate));
                    throw;
                }
            }

            public void Dispose()
            {
                if (_disposed)
                    return;
                _workspace.CaptureCleanup(() =>
                {
                    if (Thread.CurrentThread.ManagedThreadId != _ownerThread || !ReferenceEquals(_active, this))
                        throw new InvalidOperationException("Only the active fixture's owning thread may restore it.");
                    // This GUID-derived key was absent at entry. Never inspect,
                    // erase or complete the saved session's pending state.
                    _workspace.CaptureCleanup(() =>
                    {
                        SessionState.EraseString(PendingKey);
                        OwnedKeyRemoved = SessionState.GetString(PendingKey, MissingValue) == MissingValue;
                        if (!OwnedKeyRemoved)
                            throw new InvalidOperationException("Owned fixture SessionState key was not removed: " + PendingKey);
                    });
                    _workspace.CaptureCleanup(() =>
                    {
                        _currentField.SetValue(null, _savedSession);
                        OriginalRestored = ReferenceEquals(_currentField.GetValue(null), _savedSession);
                        if (!OriginalRestored)
                            throw new InvalidOperationException("The original Manager session was not restored.");
                    });
                    _disposed = true;
                    _active = null;
                    _workspace.CaptureCleanup(() => Monitor.Exit(_sessionGate));
                    _workspace.CaptureCleanup(() => Monitor.Exit(IsolationGate));
                });
            }
        }

        [TestCase("Host Payload DryRun", "Observation", "PackageMaterializer")]
        [TestCase("Host Payload Verify", "Observation", "PackageMaterializer")]
        [TestCase("Host Payload Upgrade", "LifecycleMutation", "MaterializerAndInstanceAuthority")]
        [TestCase("Host Payload Redeploy", "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission")]
        [TestCase("Host Payload Sync", "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission")]
        [TestCase("Host Payload Remove", "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission")]
        [TestCase("Install CodeDB", "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission")]
        [TestCase("Uninstall CodeDB from Project", "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission")]
        [TestCase("Remove CodeDB Integration", "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission")]
        [TestCase("Configure CodeDB Dependencies", "ProviderInstallation", "ProviderInstallerAndLifecycle")]
        public void ManagerActionInventory_HasExplicitEffectAndAuthority(
            string title, string effect, string authority)
        {
            Assert.That(AICodedbManagerActionSession.ClassifyEffect(title), Is.EqualTo(effect));
            Assert.That(AICodedbManagerActionSession.ClassifyAuthority(title), Is.EqualTo(authority));
        }

        [Test]
        public void ActionContext_FlowsCapturedProjectAndPackageToWorker()
        {
            var context = new AICodedbEditorExecutionContext(
                RuntimePlatform.WindowsEditor,
                Path.Combine(Path.GetTempPath(), "codedb-action-project"),
                Path.Combine(Path.GetTempPath(), "codedb-action-package"),
                "codedb-action-project");

            using (AICodedbPaths.UseActionContext(
                       context, "test-action-id", "Observation", "PackageMaterializer"))
            {
                Assert.That(AICodedbPaths.CurrentActionEffect, Is.EqualTo("Observation"));
                Assert.That(AICodedbPaths.CurrentActionAuthority, Is.EqualTo("PackageMaterializer"));
                var dispatch = AICodedbPaths.CurrentActionDispatchTracker;
                Assert.That(dispatch.DirectWriterDispatchAttempted, Is.False);
                Task.Run(() => AICodedbPaths.CurrentActionDispatchTracker
                    .MarkDirectWriterDispatchAttempted()).GetAwaiter().GetResult();
                Assert.That(dispatch.DirectWriterDispatchAttempted, Is.True);
                using (AICodedbPaths.UseActionStage("preflight", false))
                {
                    Assert.That(Task.Run(() => AICodedbPaths.CurrentActionStage)
                        .GetAwaiter().GetResult(), Is.EqualTo("preflight"));
                    Assert.That(Task.Run(() => AICodedbPaths.CurrentActionStageIsTerminal)
                        .GetAwaiter().GetResult(), Is.False);
                }
                Assert.That(AICodedbPaths.CurrentActionStageIsTerminal, Is.True);
                var workerContext = Task.Run(() => AICodedbPaths.CaptureExecutionContext())
                    .GetAwaiter().GetResult();
                Assert.That(workerContext.ProjectRoot, Is.EqualTo(context.ProjectRoot));
                Assert.That(workerContext.PackageRoot, Is.EqualTo(context.PackageRoot));
                Assert.That(Task.Run(() => AICodedbPaths.ProjectRoot).GetAwaiter().GetResult(),
                    Is.EqualTo(context.ProjectRoot));
                Assert.That(Task.Run(() => AICodedbPaths.PackageRootPath).GetAwaiter().GetResult(),
                    Is.EqualTo(context.PackageRoot));
                Assert.That(Task.Run(() => AICodedbPaths.RuntimePath).GetAwaiter().GetResult(),
                    Is.EqualTo(context.GetProjectPath(context.RuntimeRelativePath)));
                Assert.That(Task.Run(() => AICodedbPaths.ProviderConfigPath).GetAwaiter().GetResult(),
                    Is.EqualTo(context.GetProjectPath(context.ProviderConfigRelativePath)));
                var result = Task.Run(() => new AICodedbCommandResult(
                    0, "worker output", string.Empty, false)).GetAwaiter().GetResult();
                Assert.That(result.ActionId, Is.EqualTo("test-action-id"));
                Assert.That(result.GetDisplayText(), Does.Contain("Action ID: test-action-id"));
            }
            Assert.That(AICodedbPaths.CurrentActionId, Is.Empty);
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_RejectsOverlapAndRetainsResultAcrossWindowInstances()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                AICodedbManagerActionSession.ClearCompleted();
                try
                {
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Upgrade", context, 10d, out var action), Is.True);
                    Assert.That(action.ActionId, Has.Length.EqualTo(32));
                    Assert.That(action.EffectClass, Is.EqualTo("LifecycleMutation"));
                    Assert.That(action.AuthorizationSource, Is.EqualTo("MaterializerAndInstanceAuthority"));
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Sync", context, 11d, out _), Is.False);
                    Assert.That(AICodedbManagerActionSession.CurrentFor(context), Is.SameAs(action));

                    var result = new AICodedbCommandResult(4, "original output", "backend refusal", false, 123);
                    action.Complete(result, AICodedbProductState.NeedsAttention, true, 12d);
                    Assert.That(action.IsRunning, Is.False);
                    Assert.That(AICodedbManagerActionSession.CurrentFor(context).Result, Is.SameAs(result));
                    Assert.That(action.Status.BuildPresentation(12d).StatusLabel, Is.EqualTo("Failed"));
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                    });
                }
            });
        }

        [TestCase(false, false, false, false)]
        [TestCase(true, false, false, true)]
        [TestCase(false, true, false, true)]
        [TestCase(false, false, true, true)]
        [Category("S28PhaseC")]
        public void ManagerCommandResult_RealFailureSurvivesUncertainEffects(
            bool timeout, bool overflow, bool incomplete, bool retained)
        {
            var failure = new AICodedbCommandResult(7, "actual-output", "actual-error", timeout,
                123, false, true, Guid.NewGuid().ToString("N"), true,
                AICodedbManagerActionEvidenceKind.CommandTerminal, overflow, incomplete);
            Assert.That(failure.ExitCode, Is.EqualTo(7));
            Assert.That(failure.StandardOutput, Is.EqualTo("actual-output"));
            Assert.That(failure.StandardError, Is.EqualTo("actual-error"));
            Assert.That(failure.ElapsedMilliseconds, Is.EqualTo(123));
            Assert.That(failure.HasAuthoritativeTerminalEvidence, Is.True);
            Assert.That(AICodedbManagerActionSession.RequiresRetainedAdmission(failure), Is.EqualTo(retained));
            Assert.That(failure.Succeeded, Is.False);
            Assert.That(AICodedbManagerActionSession.CanRequestPostCommandReconcile(failure), Is.False);
            var unknown = new AICodedbCommandResult(4, "", "admission unknown", false,
                0, false, false, failure.ActionId, false, AICodedbManagerActionEvidenceKind.Indeterminate);
            Assert.That(AICodedbManagerActionSession.SelectDisplayResult(unknown, failure), Is.SameAs(failure));
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerCommandResult_IncompleteSuccessIsNotNextChangePermission()
        {
            var result = new AICodedbCommandResult(0, "actual-output", "", false, 321,
                false, true, Guid.NewGuid().ToString("N"), true,
                AICodedbManagerActionEvidenceKind.CommandTerminal, false, true);
            Assert.That(result.ExitCode, Is.Zero);
            Assert.That(result.GetDisplayText(), Does.Contain("project effects remain unproved"));
            Assert.That(AICodedbManagerActionSession.RequiresRetainedAdmission(result), Is.True);
            Assert.That(AICodedbManagerActionSession.RequiresRetainedAdmission(null), Is.True);
            Assert.That(AICodedbManagerActionSession.CanRequestPostCommandReconcile(result), Is.False);
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_ReloadRestoresUnconfirmedOutcomeWithoutRetry()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                SessionState.SetString(key,
                    Guid.NewGuid().ToString("N") + "|Host Payload Sync|" + context.PackageRoot);
                try
                {
                    var recovered = AICodedbManagerActionSession.CurrentFor(context);
                    Assert.That(recovered.IsRecovering, Is.True);
                    Assert.That(recovered.IsRunning, Is.False);
                    Assert.That(recovered.Result, Is.Null);
                    Assert.That(recovered.Status.BuildPresentation(0d).StatusLabel,
                        Is.EqualTo("Outcome unconfirmed"));
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Sync", context, 1d, out _), Is.False);
                    Assert.That(AICodedbManagerActionSession.ClearCompleted(), Is.False);
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Not.Empty);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Sync", context, 2d, out _), Is.False);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }
            });
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_OnlyMatchingAuthoritativeRecoveryReleasesAdmission()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                var actionId = Guid.NewGuid().ToString("N");
                SessionState.SetString(key,
                    actionId + "|Host Payload Sync|" + context.PackageRoot);
                try
                {
                    var recovered = AICodedbManagerActionSession.CurrentFor(context);
                    var wrongAction = new AICodedbCommandResult(
                        0, "done", string.Empty, false, 1, false, true,
                        Guid.NewGuid().ToString("N"));
                    var unconfirmed = new AICodedbCommandResult(
                        4, string.Empty, "response lost", false, 1, false, false,
                        actionId);
                    Assert.That(recovered.TryCompleteRecovery(wrongAction, 1d), Is.False);
                    Assert.That(recovered.TryCompleteRecovery(unconfirmed, 1d), Is.False);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Verify", context, 2d, out _), Is.False);
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Not.Empty);

                    var terminal = new AICodedbCommandResult(
                        0, "done", string.Empty, false, 1, false, true, actionId);
                    Assert.That(recovered.TryCompleteRecovery(terminal, 3d), Is.True);
                    Assert.That(recovered.IsRecovering, Is.False);
                    Assert.That(recovered.Result, Is.SameAs(terminal));
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Empty);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Verify", context, 4d, out var next), Is.True);
                    next.Complete(new AICodedbCommandResult(0, string.Empty,
                        string.Empty, false), AICodedbProductState.Starting, false, 5d);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }
            });
        }

        [TestCase(AICodedbProductState.Ready)]
        [TestCase(AICodedbProductState.NeedsAttention)]
        [TestCase(AICodedbProductState.Uninstalled)]
        [TestCase(AICodedbProductState.NotIntegrated)]
        [TestCase(AICodedbProductState.MissingPrerequisite)]
        [Category("S28PhaseC")]
        public void ManagerHistory_UnknownDoesNotOverrideCurrentProductStateOrAdmitMutation(
            AICodedbProductState currentState)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var tag = fixture.Token;
                var context = fixture.Context;
                var actionId = Guid.NewGuid().ToString("N");
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                SessionState.SetString(key, actionId + "|Install CodeDB|" + context.PackageRoot);
                AICodedbManagerActionSession.ClearCompleted();
                try
                {
                    var session = AICodedbManagerActionSession.CurrentFor(context);
                    var snapshot = AICodedbStatusSnapshot.CreateCachedState(tag, currentState);
                    session.Status.UpdateProductState(snapshot.ProductStatus.State);
                    var presentation = session.Status.BuildPresentation(1d);
                    Assert.That(AICodedbManagerWindow.ShouldOverrideProductStatus(
                        session.Status.Phase, presentation, session.Status.HasFreshProductState), Is.False);
                    Assert.That(snapshot.ProductStatus.State, Is.EqualTo(currentState));
                    Assert.That(presentation.StatusLabel, Is.EqualTo("Outcome unconfirmed"));
                    Assert.That(session.Result, Is.Null);
                    Assert.That(session.IsRecovering, Is.True);
                    var warning = AICodedbManagerWindow.BuildHistoricalActionWarning(session, string.Empty);
                    Assert.That(warning, Does.Contain(actionId).And.Contain(context.PackageRoot));
                    Assert.That(warning, Does.Contain("unknown command outcome"));
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Install CodeDB", context, 2d, out _), Is.False);
                    Assert.That(session.TryReleaseDurableIndex(new AICodedbCommandResult(
                        4, string.Empty, "unknown", false, 0, false, false, actionId), out _), Is.False);
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Not.Empty);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }
            });
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence()
        {
            var tag = Guid.NewGuid().ToString("N");
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                Path.Combine(Path.GetTempPath(), "codedb-observation-project-" + tag),
                Path.Combine(Path.GetTempPath(), "codedb-observation-package-" + tag), tag);
            var foreign = new AICodedbEditorExecutionContext(context.Platform,
                context.ProjectRoot, context.PackageRoot + "-replacement", tag);
            var otherProject = new AICodedbEditorExecutionContext(context.Platform,
                context.ProjectRoot + "-foreign", context.PackageRoot, tag);
            var runtime = context.GetProjectPath("fixture-supervisor");
            var hash = new string('a', 64);
            var boundary = new AICodedbManagerStatusBoundary(context, "fixture-generation", hash, runtime);
            var now = DateTimeOffset.UtcNow;
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "fixture-generation",
                hash, true, now, now), Is.True);
            Assert.That(boundary.CanDisplayReadyEvidence(foreign, runtime, "fixture-generation",
                hash, true, now, now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(otherProject, runtime, "fixture-generation",
                hash, true, now, now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "fixture-generation",
                hash, true, now.AddSeconds(-31d), now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "fixture-generation",
                hash, true, now.AddSeconds(1d), now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "fixture-generation",
                hash, false, now, now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime + "-foreign", "fixture-generation",
                hash, true, now, now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "other-generation",
                hash, true, now, now), Is.False);
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "fixture-generation",
                new string('b', 64), true, now, now), Is.False);
            Assert.That(boundary.CanDisplay(context, AICodedbProductState.Ready, true, null, now), Is.False);
            Assert.That(boundary.CanDisplay(context, AICodedbProductState.NeedsAttention, true, null, now), Is.True);
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerReadyCache_IsProjectPackageAndTimeBoundWithoutRenewal()
        {
            var root = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"));
            var package = Path.Combine(root, "package");
            var now = DateTime.UtcNow;
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root, package, now.AddSeconds(-1d), now), Is.True);
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root, package + "-replacement", now, now), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root + "-foreign", package, now, now), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root, package, now.AddSeconds(-31d), now), Is.False);
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root, package, now.AddSeconds(1d), now), Is.False);
            var observedAt = now.AddSeconds(-1d);
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root, package, observedAt, observedAt.AddSeconds(30d)), Is.True);
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(
                root, package, root, package, observedAt, observedAt.AddSeconds(31d)), Is.False);
        }

        [TestCase(0d, true)]
        [TestCase(30d, true)]
        [TestCase(30.001d, false)]
        [TestCase(31d, false)]
        [TestCase(120d, false)]
        [TestCase(-1d, false)]
        [Category("S28PhaseC")]
        public void ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry(double ageSeconds, bool expectedFresh)
        {
            var tag = Guid.NewGuid().ToString("N");
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                Path.Combine(Path.GetTempPath(), "codedb-freshness-project-" + tag),
                Path.Combine(Path.GetTempPath(), "codedb-freshness-package-" + tag), tag);
            var runtime = context.GetProjectPath("fixture-supervisor");
            var hash = new string('a', 64);
            var boundary = new AICodedbManagerStatusBoundary(context, "fixture-generation", hash, runtime);
            var now = DateTimeOffset.UtcNow;
            var observedAt = now.AddSeconds(-ageSeconds);

            Assert.That(AICodedbManagerStatusBoundary.IsReadyObservationFresh(observedAt, now),
                Is.EqualTo(expectedFresh));
            Assert.That(boundary.CanDisplayReadyEvidence(context, runtime, "fixture-generation",
                hash, true, observedAt, now), Is.EqualTo(expectedFresh));
            Assert.That(AICodedbManagerWindow.CanUseCachedReadyObservation(context.ProjectRoot, context.PackageRoot,
                context.ProjectRoot, context.PackageRoot, observedAt.UtcDateTime, now.UtcDateTime),
                Is.EqualTo(expectedFresh));
            Assert.That(AICodedbManagerWindow.ShouldExpireDisplayedReady(AICodedbProductState.Ready,
                observedAt, now), Is.EqualTo(!expectedFresh));
            Assert.That(AICodedbManagerWindow.ShouldExpireDisplayedReady(AICodedbProductState.NeedsAttention,
                observedAt, now), Is.False);
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerReadyExpiry_PrecedesUnchangedLifecycleRevisionGate()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath, "Editor", "AICodedbManagerWindow.cs"));
            var applyStart = source.IndexOf("private bool TryApplyCachedLifecycleStatus()", StringComparison.Ordinal);
            Assert.That(applyStart, Is.GreaterThanOrEqualTo(0));
            var applyEnd = source.IndexOf("private async void ApplyCachedLifecycleStatusAsync",
                applyStart, StringComparison.Ordinal);
            Assert.That(applyEnd, Is.GreaterThan(applyStart));
            var applyBody = source.Substring(applyStart, applyEnd - applyStart);
            var expiry = applyBody.IndexOf("ShouldExpireDisplayedReady(", StringComparison.Ordinal);
            var revisionGate = applyBody.IndexOf("revision <= _cachedLifecycleStatusRevision", StringComparison.Ordinal);

            Assert.That(expiry, Is.GreaterThanOrEqualTo(0));
            Assert.That(revisionGate, Is.GreaterThan(expiry));
            Assert.That(applyBody.Substring(expiry, revisionGate - expiry),
                Does.Contain("ApplyStatusSnapshot(AICodedbStatusSnapshot.CreateStarting("));
        }

        [Test]
        public void ManagerStatusOverride_PreservesRunningAndTerminalPresentation()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Install CodeDB", 0d);
            Assert.That(AICodedbManagerWindow.ShouldOverrideProductStatus(status.Phase,
                status.BuildPresentation(1d), status.HasFreshProductState), Is.True);
            status.Complete(new AICodedbCommandResult(0, string.Empty, string.Empty, false),
                AICodedbProductState.NeedsAttention, true, 2d);
            Assert.That(AICodedbManagerWindow.ShouldOverrideProductStatus(status.Phase,
                status.BuildPresentation(2d), status.HasFreshProductState), Is.True);
            status.Complete(new AICodedbCommandResult(4, string.Empty, "failed", false),
                AICodedbProductState.Starting, false, 3d);
            Assert.That(AICodedbManagerWindow.ShouldOverrideProductStatus(status.Phase,
                status.BuildPresentation(3d), status.HasFreshProductState), Is.True);
        }

        [Test]
        public void ManagerActionJournal_RestoresOriginalIdAfterFullExitAndPackageReplacement()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
            using var sessionFixture = new ManagerActionSessionFixture(workspace);
            using var receiptScope = AICodedbPaths.UseManagerActionsRootForTests(workspace.Root);
            var tag = Guid.NewGuid().ToString("N");
            var project = workspace.GetPath("project");
            var original = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                project, workspace.GetPath("package"), tag);
            var replacement = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                project, workspace.GetPath("replacement"), tag);
            var actionId = Guid.NewGuid().ToString("N");
            var index = new AICodedbManagerActionIndex(actionId, "Host Payload Sync",
                "ConfirmedProjectMutation", "UserConfirmationAndBackendAdmission", original);
            var indexPath = AICodedbPaths.GetManagerActionIndexPath(original, actionId);
            try
            {
                Assert.That(AICodedbManagerActionJournal.TryAdmit(index, out var error),
                    Is.True, error);
                var read = AICodedbManagerActionJournal.Read(replacement);
                Assert.That(read.State, Is.EqualTo(AICodedbManagerActionIndexState.Pending));
                Assert.That(read.Index.ActionId, Is.EqualTo(actionId));
                Assert.That(read.Index.Context.PackageRoot, Is.EqualTo(original.PackageRoot));
                Assert.That(read.Index.StorageLayout, Is.EqualTo(AICodedbPaths.CompactReceiptLayout));
                AICodedbManagerActionSession.ClearCompleted();
                AICodedbManagerActionSession.RestoreDurable(replacement, read, 1d);
                var recovered = AICodedbManagerActionSession.CurrentFor(replacement);
                Assert.That(recovered.ActionId, Is.EqualTo(actionId));
                Assert.That(recovered.IsRecovering, Is.True);
                Assert.That(AICodedbManagerWindow.BuildHistoricalActionWarning(recovered, read.HistoricalWarning),
                    Does.Contain(actionId).And.Contain(original.PackageRoot));
                Assert.That(AICodedbManagerWindow.ShouldOverrideProductStatus(recovered.Status.Phase,
                    recovered.Status.BuildPresentation(1d), recovered.Status.HasFreshProductState), Is.False);
                Assert.That(AICodedbManagerActionSession.TryStart(
                    "Host Payload Verify", replacement, 2d, out _), Is.False);
                var second = new AICodedbManagerActionIndex(Guid.NewGuid().ToString("N"),
                    "Host Payload Verify", "Observation", "PackageMaterializer", replacement);
                Assert.That(AICodedbManagerActionJournal.TryAdmit(second, out _), Is.False);
                var terminal = new AICodedbCommandResult(0,
                    string.Empty, string.Empty, false, 1, false, true, actionId);
                Assert.That(recovered.TryReleaseDurableIndex(terminal, out error), Is.True, error);
                Assert.That(recovered.TryCompleteRecovery(terminal, 3d), Is.True);
                Assert.That(AICodedbManagerActionJournal.Read(replacement).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Empty));
            }
            finally
            {
                AICodedbManagerActionSession.ClearCompleted();
                var directory = Path.GetDirectoryName(indexPath);
                if (Directory.Exists(directory)
                    && Path.GetFileName(directory).Length == 24)
                    workspace.CaptureCleanup(() => workspace.DeleteOwnedTree(directory));
            }
            });
        }

        [Test]
        public void ManagerActionJournal_CorruptOrConflictingIndexFailsClosed()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
            using var receiptScope = AICodedbPaths.UseManagerActionsRootForTests(workspace.Root);
            var tag = Guid.NewGuid().ToString("N");
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                workspace.GetPath("project"), workspace.GetPath("package"), tag);
            var index = new AICodedbManagerActionIndex(Guid.NewGuid().ToString("N"),
                "Host Payload Verify", "Observation", "PackageMaterializer", context);
            var path = AICodedbPaths.GetManagerActionIndexPath(context, index.ActionId);
            try
            {
                Assert.That(AICodedbManagerActionJournal.TryAdmit(index, out var error),
                    Is.True, error);
                var changedPackage = new AICodedbManagerActionIndex(index.ActionId,
                    index.Title, index.EffectClass, index.AuthorizationSource,
                    new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                        context.ProjectRoot, context.PackageRoot + "-other", context.ProjectDisplayName));
                Assert.That(AICodedbManagerActionJournal.TryRelease(changedPackage,
                    AICodedbManagerActionEvidenceKind.CommandTerminal, out _), Is.False);
                File.WriteAllText(path, "{\"schema_version\":1,\"state\":\"pending\"}");
                var read = AICodedbManagerActionJournal.Read(context);
                Assert.That(read.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                Assert.That(read.ActionId, Is.EqualTo(index.ActionId));
                Assert.That(AICodedbManagerActionJournal.TryAdmit(index, out _), Is.False);
                Assert.That(AICodedbManagerActionJournal.TryRelease(index,
                    AICodedbManagerActionEvidenceKind.CommandTerminal, out _), Is.False);
            }
            finally
            {
                var directory = Path.GetDirectoryName(path);
                if (Directory.Exists(directory)
                    && Path.GetFileName(directory).Length == 24)
                    workspace.CaptureCleanup(() => workspace.DeleteOwnedTree(directory));
            }
            });
        }

        [Test]
        public void ManagerActionResult_SeparatesPreEffectAndIndeterminateFromCommandTerminal()
        {
            var refused = new AICodedbCommandResult(4, string.Empty, "No child started", false,
                0, false, false, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", false,
                AICodedbManagerActionEvidenceKind.PreEffectRefusal);
            var unknown = new AICodedbCommandResult(4, string.Empty, "Writer disappeared", false,
                0, false, false, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", false,
                AICodedbManagerActionEvidenceKind.Indeterminate);
            Assert.That(refused.GetSummary(), Is.EqualTo("Command did not start."));
            Assert.That(unknown.GetSummary(), Is.EqualTo("Command outcome unconfirmed."));
            Assert.That(refused.HasAuthoritativeTerminalEvidence, Is.False);
            Assert.That(unknown.HasAuthoritativeTerminalEvidence, Is.False);
        }

        [Test]
        public void ManagerActionRecovery_ClaimWithoutTerminalStaysUnknownAndStartFailureIsDistinct()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
            using var receiptScope = AICodedbPaths.UseManagerActionsRootForTests(workspace.Root);
            var tag = Guid.NewGuid().ToString("N");
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                workspace.GetPath("project"), workspace.GetPath("package"), tag);
            var actionId = Guid.NewGuid().ToString("N");
            var stageId = new string('a', 64);
            var projectKey = AICodedbPaths.GetManagerActionProjectKey(context);
            var packageKey = AICodedbPaths.GetManagerActionPackageKey(context);
            var commandIdentity = new string('b', 64);
            var actionRoot = AICodedbPaths.GetManagerActionReceiptRoot(context, actionId, null);
            var stageRoot = Path.Combine(actionRoot, stageId);
            var admittedPath = Path.Combine(stageRoot, "admitted.json");
            var claimPath = Path.Combine(stageRoot, "claim.json");
            var failurePath = Path.Combine(stageRoot, "start-failure.json");
            var writerTicks = DateTime.UtcNow.AddMinutes(-1).Ticks;
            try
            {
                Directory.CreateDirectory(stageRoot);
                File.WriteAllText(admittedPath,
                    "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"state\":\"admitted\","
                    + "\"action_id\":\"" + actionId + "\",\"stage_id\":\"" + stageId + "\","
                    + "\"project_key\":\"" + projectKey + "\",\"package_key\":\"" + packageKey + "\","
                    + "\"project_identity\":\"sha256:" + projectKey + "\","
                    + "\"package_identity\":\"sha256:" + packageKey + "\","
                    + "\"project_root\":\"" + context.ProjectRoot + "\","
                    + "\"package_root\":\"" + context.PackageRoot + "\","
                    + "\"command_identity_sha256\":\"" + commandIdentity + "\"}");
                var claim = "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                    + "\"state\":\"claimed\",\"action_id\":\"" + actionId + "\","
                    + "\"stage_id\":\"" + stageId + "\",\"project_key\":\"" + projectKey + "\","
                    + "\"package_key\":\"" + packageKey + "\",\"writer_pid\":4242,"
                    + "\"writer_start_utc_ticks\":\"" + writerTicks.ToString(CultureInfo.InvariantCulture) + "\"}";
                File.WriteAllText(claimPath, claim);
                Assert.That(AICodedbProcessRunner.RecoverManagerAction(context, actionId, null).State,
                    Is.EqualTo(AICodedbManagerActionRecoveryState.Pending));
                var legacy = AICodedbManagerActionJournal.Read(context);
                Assert.That(legacy.State, Is.EqualTo(AICodedbManagerActionIndexState.Pending));
                Assert.That(legacy.IsLegacyReceipt, Is.True);
                Assert.That(legacy.ActionId, Is.EqualTo(actionId));
                File.WriteAllText(claimPath, claim.Replace("\"writer_pid\":4242", "\"writer_pid\":0"));
                Assert.That(AICodedbProcessRunner.RecoverManagerAction(context, actionId, null).State,
                    Is.EqualTo(AICodedbManagerActionRecoveryState.Conflict));
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                File.WriteAllText(claimPath, claim);
                File.WriteAllText(failurePath,
                    "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                    + "\"state\":\"start_failed\",\"action_id\":\"" + actionId + "\","
                    + "\"stage_id\":\"" + stageId + "\",\"project_key\":\"" + projectKey + "\","
                    + "\"package_key\":\"" + packageKey + "\","
                    + "\"command_identity_sha256\":\"" + commandIdentity + "\","
                    + "\"writer_pid\":4242,\"reason\":\"CHILD_START_FAILED\","
                    + "\"completed_at_utc\":\"" + DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture) + "\"}");
                var recovery = AICodedbProcessRunner.RecoverManagerAction(context, actionId, null);
                Assert.That(recovery.State, Is.EqualTo(AICodedbManagerActionRecoveryState.PreEffectRefusal));
                Assert.That(recovery.Result.HasAuthoritativeTerminalEvidence, Is.False);
                Assert.That(recovery.Result.ActionId, Is.EqualTo(actionId));
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Empty));
            }
            finally
            {
                if (Directory.Exists(actionRoot)
                    && Path.GetFileName(actionRoot) == actionId
                    && actionRoot.StartsWith(AICodedbPaths.GetManagerActionsRoot() + "/",
                        StringComparison.OrdinalIgnoreCase))
                    workspace.CaptureCleanup(() => workspace.DeleteOwnedTree(actionRoot));
            }
            }, pathProfile: AICodedbTestPathProfile.CompactAndLegacy);
        }

        [Test]
        public void RetainedProjectRootIdentity_AcceptsOnlySameFullyQualifiedPlatformRoot()
        {
            if (Path.DirectorySeparatorChar != '\\')
            {
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot("/project", "/project/"), Is.True);
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot("/project", "/PROJECT"), Is.False);
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot("/project", "project"), Is.False);
                return;
            }
            const string root = "G:/RiceProject/Retained";
            foreach (var equivalent in new[] { "G:\\RiceProject\\Retained", "g:/riceproject/retained/",
                "G:\\RiceProject/Retained\\" })
            {
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot(root, equivalent), Is.True, equivalent);
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot(equivalent, root), Is.True, equivalent);
            }
            foreach (var refused in new[] { "G:/RiceProject/Different", "RiceProject/Retained",
                "G:RiceProject/Retained", "/RiceProject/Retained", "\\RiceProject\\Retained",
                "G::/RiceProject/Retained", "G:/RiceProject/Retained?", "\\\\server", "" })
            {
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot(root, refused), Is.False, refused);
                Assert.That(AICodedbPaths.AreSameAbsoluteProjectRoot(refused, root), Is.False, refused);
            }
        }

        [Test]
        public void ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession()
        {
            if (Application.platform != RuntimePlatform.WindowsEditor)
                Assert.Ignore("The actual retained producer requires Windows PowerShell.");
            var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(AICodedbProjectSettingsTests).Assembly);
            Assert.That(package, Is.Not.Null);
            var script = Path.Combine(package.resolvedPath, "Tests~", "test-codedb-host-payload-materializer.ps1");
            Assert.That(File.Exists(script), Is.True, "The delivered Package must contain its retained producer fixture.");
            AICodedbTestWorkspace.Run(workspace =>
            {
            // Generate actual production intent/disposition records before a fresh
            // Install creates the optional flat root. No manual env setup required.
            var proofPath = RunProductionOptionalFlatProof(script, workspace);
            var proof = AICodedbStrictJson.ReadObject(proofPath, 16384, "PS emitted retained effects test context");
            Func<string, string> field = name => AICodedbStrictJson.GetRequiredString(proof, name, "PS emitted context");
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                field("project_root"), field("package_root"), "PS emitted retained candidate");
            var flatRoot = Path.Combine(context.ProjectRoot, "AIWork/codedb");
            Assert.That(Directory.Exists(flatRoot) || File.Exists(flatRoot), Is.False);
            var managerRoot = Path.Combine(field("local_app_data"), "Rice/CodeDB/manager-actions");
            using var receiptScope = AICodedbPaths.UseManagerActionsRootForTests(managerRoot);
            var markerPath = field("marker_path");
            var terminalPath = field("terminal_path");
            var markerBytes = File.ReadAllBytes(markerPath);
            var terminalBytes = File.ReadAllBytes(terminalPath);
            AICodedbManagerActionSession.ClearCompleted();
            var read = AICodedbManagerActionJournal.Read(context);
            Assert.That(read.State, Is.EqualTo(AICodedbManagerActionIndexState.Empty), read.Detail);
            Assert.That(read.HistoricalResult, Is.Not.Null, read.HistoricalWarning);
            Assert.That(read.HistoricalResult.FailedCandidateEffectsRetained, Is.True);
            Assert.That(read.HistoricalResult.HasAuthoritativeTerminalEvidence, Is.False);
            Assert.That(read.HistoricalResult.ExitCode, Is.EqualTo(6));
            Assert.That(read.HistoricalResult.OutputDrainIncomplete, Is.True);
            Assert.That(read.HistoricalResult.StandardError, Is.EqualTo("original failure"));
            AICodedbManagerActionSession.RestoreDurable(context, read, 1d);
            var restored = AICodedbManagerActionSession.CurrentFor(context);
            Assert.That(restored, Is.Not.Null);
            Assert.That(restored.IsRecovering, Is.False);
            Assert.That(restored.Result.FailedCandidateEffectsRetained, Is.True);
            Assert.That(restored.Result.OutputDrainIncomplete, Is.True);
            // Exercise the actual emitted marker/intent/desired chain without
            // rewriting its authenticated bytes for representation differences.
            foreach (var root in new[] { field("project_root").Replace('/', '\\'),
                field("project_root").Replace('\\', '/').ToUpperInvariant() + "/",
                field("project_root").Replace('\\', '/') + "\\" })
            {
                var equivalent = new AICodedbEditorExecutionContext(context.Platform,
                    root, context.PackageRoot, context.ProjectDisplayName);
                var same = AICodedbManagerActionJournal.Read(equivalent);
                Assert.That(same.State, Is.EqualTo(AICodedbManagerActionIndexState.Empty), same.Detail);
                Assert.That(same.HistoricalResult.FailedCandidateEffectsRetained, Is.True);
            }
            var marker = AICodedbStrictJson.ParseObject(File.ReadAllText(markerPath), "actual emitted marker");
            var stateId = AICodedbStrictJson.GetRequiredString(marker, "removal_state_id", "actual emitted marker");
            var intentPath = Path.Combine(context.ProjectRoot,
                "AIWork/.runtime/codedb/control/removal-intents/" + stateId + ".json");
            var desiredPath = Path.Combine(context.ProjectRoot, "AIWork/.runtime/codedb/control/desired-state.json");
            var intentBytes = File.ReadAllBytes(intentPath);
            var desiredBytes = File.ReadAllBytes(desiredPath);
            try
            {
                var original = File.ReadAllText(markerPath);
                var intent = AICodedbStrictJson.ParseObject(File.ReadAllText(intentPath), "actual retained intent");
                var effects = AICodedbStrictJson.GetRequiredArray(intent, "retained_effects", "actual retained intent");
                string recordedDirectory = null;
                foreach (var raw in effects)
                {
                    var effect = AICodedbStrictJson.RequireObject(raw, "actual retained effect");
                    var relative = AICodedbStrictJson.GetRequiredString(effect, "relative_path", "actual retained effect");
                    Assert.That(relative, Is.Not.EqualTo("AIWork/codedb"));
                    if (recordedDirectory == null && relative.EndsWith("/logs", StringComparison.Ordinal))
                        recordedDirectory = Path.Combine(context.ProjectRoot, relative);
                }
                Assert.That(recordedDirectory, Is.Not.Null);
                var mandatoryGeneration = Path.Combine(context.ProjectRoot, "AIWork/.runtime/codedb/host/generations/"
                    + AICodedbStrictJson.GetRequiredString(marker, "retained_generation_id", "actual retained marker"));
                var mandatoryCandidate = Path.Combine(context.ProjectRoot, "AIWork/.runtime/codedb/instances/"
                    + AICodedbStrictJson.GetRequiredString(marker, "retained_instance_id", "actual retained marker"));
                foreach (var missing in new[] { recordedDirectory, mandatoryGeneration, mandatoryCandidate })
                {
                    var saved = workspace.GetPath("saved-effect");
                    Directory.Move(missing, saved);
                    try
                    {
                        Assert.That(AICodedbManagerActionJournal.Read(context).State,
                            Is.EqualTo(AICodedbManagerActionIndexState.Conflict), missing);
                    }
                    finally { Directory.Move(saved, missing); }
                }
                var recordedFile = Path.Combine(mandatoryCandidate, "config/codedb-mcp.toml");
                var recordedBytes = File.ReadAllBytes(recordedFile);
                try
                {
                    File.WriteAllText(recordedFile, "changed retained file");
                    Assert.That(AICodedbManagerActionJournal.Read(context).State,
                        Is.EqualTo(AICodedbManagerActionIndexState.Conflict), "recorded file hash drift");
                }
                finally { File.WriteAllBytes(recordedFile, recordedBytes); }
                foreach (var asFile in new[] { false, true })
                {
                    try
                    {
                        if (asFile) File.WriteAllText(flatRoot, "unexpected root file");
                        else
                        {
                            Directory.CreateDirectory(flatRoot);
                            File.WriteAllText(Path.Combine(flatRoot, "unknown.txt"), "unexpected descendant");
                        }
                        var refused = AICodedbManagerActionJournal.Read(context);
                        Assert.That(refused.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                        Assert.That(refused.Detail, Does.Contain(asFile ? "AIWork/codedb." : "AIWork/codedb/unknown.txt"));
                    }
                    finally
                    {
                        if (File.Exists(flatRoot)) File.Delete(flatRoot);
                        if (Directory.Exists(flatRoot)) workspace.DeleteOwnedTree(flatRoot);
                    }
                }
                // A recorded optional directory remains required. Reauthenticate
                // only this test fault's intent; the real emitted bytes are restored.
                var recordedFlat = new Dictionary<string, object>
                {
                    { "relative_path", "AIWork/codedb" }, { "kind", "DIRECTORY" }, { "sha256", "" }
                };
                effects.Add(recordedFlat);
                effects.Sort((a, b) => string.CompareOrdinal(
                    AICodedbStrictJson.GetRequiredString(AICodedbStrictJson.RequireObject(a, "effect"), "relative_path", "effect"),
                    AICodedbStrictJson.GetRequiredString(AICodedbStrictJson.RequireObject(b, "effect"), "relative_path", "effect")));
                try
                {
                    File.WriteAllText(intentPath, AICodedbControlContractMigrationClassifierTests.SerializeObject(intent));
                    using var sha = SHA256.Create();
                    var changedHash = BitConverter.ToString(sha.ComputeHash(File.ReadAllBytes(intentPath)))
                        .Replace("-", "").ToLowerInvariant();
                    var oldHash = AICodedbStrictJson.GetRequiredString(marker, "removal_intent_sha256", "marker");
                    File.WriteAllText(markerPath, original.Replace(oldHash, changedHash));
                    Assert.That(AICodedbManagerActionJournal.Read(context).State,
                        Is.EqualTo(AICodedbManagerActionIndexState.Conflict), "recorded optional root disappeared");
                }
                finally
                {
                    File.WriteAllBytes(intentPath, intentBytes);
                    File.WriteAllBytes(markerPath, markerBytes);
                }
                var redirectedTarget = workspace.GetPath("redirected-target");
                Directory.CreateDirectory(redirectedTarget);
                CreateDirectoryJunction(flatRoot, redirectedTarget);
                try
                {
                    var refused = AICodedbManagerActionJournal.Read(context);
                    Assert.That(refused.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                    Assert.That(refused.Detail, Does.Contain("redirect"));
                }
                finally { Directory.Delete(flatRoot); }
                foreach (var hashName in new[] { "admission_sha256", "terminal_sha256", "removal_intent_sha256" })
                {
                    var record = AICodedbStrictJson.ParseObject(original, "actual emitted marker");
                    var hash = AICodedbStrictJson.GetRequiredString(record, hashName, "actual emitted marker");
                    File.WriteAllText(markerPath, original.Replace(hash, new string('0', 64)));
                    var refused = AICodedbManagerActionJournal.Read(context);
                    Assert.That(refused.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict), hashName);
                    File.WriteAllBytes(markerPath, markerBytes);
                }
                foreach (var recordPath in new[] { markerPath, intentPath, desiredPath })
                foreach (var refusedRoot in new[] { context.ProjectRoot + "-different", "relative-project",
                    "G:relative-project", "\\current-drive-project" })
                {
                    var text = File.ReadAllText(recordPath);
                    var record = AICodedbStrictJson.ParseObject(text, "actual emitted root fault");
                    record["project_root"] = refusedRoot;
                    File.WriteAllText(recordPath, AICodedbControlContractMigrationClassifierTests.SerializeObject(record));
                    Assert.That(File.ReadAllText(recordPath), Is.Not.EqualTo(text), "root fault must change bytes");
                    if (recordPath != markerPath)
                    {
                        var hashName = recordPath == intentPath ? "removal_intent_sha256" : "desired_state_sha256";
                        var oldHash = AICodedbStrictJson.GetRequiredString(marker, hashName, "actual emitted marker");
                        using var sha = System.Security.Cryptography.SHA256.Create();
                        var newHash = BitConverter.ToString(sha.ComputeHash(File.ReadAllBytes(recordPath)))
                            .Replace("-", "").ToLowerInvariant();
                        File.WriteAllText(markerPath, original.Replace(oldHash, newHash));
                    }
                    var refused = AICodedbManagerActionJournal.Read(context);
                    Assert.That(refused.State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict),
                        recordPath + " / " + refusedRoot);
                    File.WriteAllBytes(markerPath, markerBytes);
                    File.WriteAllBytes(intentPath, intentBytes);
                    File.WriteAllBytes(desiredPath, desiredBytes);
                }
            }
            finally
            {
                File.WriteAllBytes(markerPath, markerBytes);
                File.WriteAllBytes(intentPath, intentBytes);
                File.WriteAllBytes(desiredPath, desiredBytes);
                Assert.That(File.ReadAllBytes(terminalPath), Is.EqualTo(terminalBytes));
                AICodedbManagerActionSession.ClearCompleted();
            }
            });
        }

        private static string RunProductionOptionalFlatProof(string script, AICodedbTestWorkspace workspace)
        {
            var start = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + script
                    + "\" -RetainedOptionalFlatOnly -RetainedFixtureRoot \"" + workspace.Root + "\"",
                WorkingDirectory = workspace.Root, UseShellExecute = false, CreateNoWindow = true,
                RedirectStandardOutput = true, RedirectStandardError = true,
                StandardOutputEncoding = new UTF8Encoding(false), StandardErrorEncoding = new UTF8Encoding(false)
            };
            start.EnvironmentVariables["TEMP"] = workspace.Root;
            start.EnvironmentVariables["TMP"] = workspace.Root;
            using var process = System.Diagnostics.Process.Start(start);
            Assert.That(process, Is.Not.Null);
            var stdout = process.StandardOutput.ReadToEndAsync();
            var stderr = process.StandardError.ReadToEndAsync();
            Assert.That(process.WaitForExit(180000), Is.True, "Isolated retained producer timed out; no retry was made.");
            Assert.That(Task.WaitAll(new Task[] { stdout, stderr }, 5000), Is.True, "Retained producer output drain timed out.");
            File.WriteAllText(workspace.GetPath("producer.stdout.log"), stdout.Result, new UTF8Encoding(false));
            File.WriteAllText(workspace.GetPath("producer.stderr.log"), stderr.Result, new UTF8Encoding(false));
            Assert.That(process.ExitCode, Is.Zero, stderr.Result);
            Assert.That(stdout.Result, Does.Contain("[PASS] FailedPreparationRecoveryOnly"));
            foreach (var line in stdout.Result.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
                if (line.StartsWith("[EMITTED_PROOF] ", StringComparison.Ordinal))
                {
                    var path = line.Substring("[EMITTED_PROOF] ".Length);
                    Assert.That(Path.GetFullPath(path).StartsWith(Path.GetFullPath(workspace.Root)
                        + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase), Is.True);
                    Assert.That(File.Exists(path), Is.True);
                    return path;
                }
            Assert.Fail("Actual production retained proof was not emitted.");
            return null;
        }

        [Test]
        public void ManagerActionJournal_HistoricalUnknownMarkerReleasesOnlyBoundPendingStage()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
            using var receiptScope = AICodedbPaths.UseManagerActionsRootForTests(workspace.Root);
            const string actionId = "3049af7cfc9f4260928e3f89d18672c0";
            const string stageId = "b571e3a38c0f134306d1df4d412804de66048b32de371c95112d363e6b664b56";
            const string writerSha = "d6fa8f5a828fcc823e54b44683903e0ec3173d23b1af64931324fa2093a039cf";
            var tag = Guid.NewGuid().ToString("N");
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                workspace.GetPath("project"), workspace.GetPath("package"), tag);
            var stageRoot = Path.Combine(AICodedbPaths.GetManagerActionReceiptRoot(context, actionId, null), stageId);
            var admissionPath = Path.Combine(stageRoot, "admitted.json");
            var claimPath = Path.Combine(stageRoot, "claim.json");
            var markerPath = Path.Combine(AICodedbPaths.GetManagerActionIndexDirectory(context),
                "resolved-action-" + actionId + ".json");
            var commandIdentity = new string('e', 64);
            var projectKey = AICodedbPaths.GetManagerActionProjectKey(context);
            var packageKey = AICodedbPaths.GetManagerActionPackageKey(context);
            const string writerTicks = "123456789012345678";
            Func<string, string> sha = value =>
            {
                using (var algorithm = SHA256.Create())
                    return BitConverter.ToString(algorithm.ComputeHash(Encoding.UTF8.GetBytes(value)))
                        .Replace("-", string.Empty).ToLowerInvariant();
            };
            Func<string, string> fileSha = path =>
            {
                using (var stream = File.OpenRead(path))
                using (var algorithm = SHA256.Create())
                    return BitConverter.ToString(algorithm.ComputeHash(stream))
                        .Replace("-", string.Empty).ToLowerInvariant();
            };
            try
            {
                Directory.CreateDirectory(stageRoot);
                File.WriteAllText(admissionPath,
                    "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"state\":\"admitted\","
                    + "\"action_id\":\"" + actionId + "\",\"stage_id\":\"" + stageId + "\","
                    + "\"project_key\":\"" + projectKey + "\",\"package_key\":\"" + packageKey + "\","
                    + "\"project_identity\":\"sha256:" + projectKey + "\","
                    + "\"package_identity\":\"sha256:" + packageKey + "\","
                    + "\"project_root\":\"" + context.ProjectRoot + "\","
                    + "\"package_root\":\"" + context.PackageRoot + "\","
                    + "\"command_identity_sha256\":\"" + commandIdentity + "\","
                    + "\"writer_sha256\":\"" + writerSha + "\"}");
                var originalAdmissionBytes = File.ReadAllBytes(admissionPath);
                var claim = "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                    + "\"state\":\"claimed\",\"action_id\":\"" + actionId + "\","
                    + "\"stage_id\":\"" + stageId + "\",\"project_key\":\"" + projectKey + "\","
                    + "\"package_key\":\"" + packageKey + "\",\"writer_pid\":4242,"
                    + "\"writer_start_utc_ticks\":\"" + writerTicks + "\"}";
                File.WriteAllText(claimPath, claim);
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Pending));
                var projectProof = new string('1', 64);
                var processProof = new string('f', 64);
                var proof = sha(string.Join("\n", new[] { actionId, stageId,
                    fileSha(admissionPath), fileSha(claimPath), commandIdentity,
                    processProof, processProof, projectProof, projectProof }));
                Directory.CreateDirectory(Path.GetDirectoryName(markerPath));
                var marker = "{\"schema_version\":2,\"managed_by\":\"com.rice.ai-codedb\","
                    + "\"state\":\"resolved\",\"action_id\":\"" + actionId + "\","
                    + "\"project_key\":\"" + projectKey + "\",\"package_key\":\"" + packageKey + "\","
                    + "\"project_root\":\"" + context.ProjectRoot + "\","
                    + "\"package_root\":\"" + context.PackageRoot + "\","
                    + "\"disposition\":\"HistoricalUnknownReconciled\",\"command_outcome\":\"unknown\","
                    + "\"project_state\":\"INSTALLED\",\"stage_id\":\"" + stageId + "\","
                    + "\"admission_sha256\":\"" + fileSha(admissionPath) + "\","
                    + "\"claim_sha256\":\"" + fileSha(claimPath) + "\","
                    + "\"command_identity_sha256\":\"" + commandIdentity + "\","
                    + "\"proof_source\":\"S27_WIN32_PROCESS_AND_LOCKED_MATERIALIZER_AUTHORITY\","
                    + "\"writer_pid\":4242,\"writer_start_utc_ticks\":\"" + writerTicks + "\","
                    + "\"process_observation_first_sha256\":\"" + processProof + "\","
                    + "\"process_observation_second_sha256\":\"" + processProof + "\","
                    + "\"project_proof_sha256\":\"" + projectProof + "\","
                    + "\"proof_sha256\":\"" + proof + "\",\"observed_at_utc\":\"2026-09-29T00:00:00Z\"}";
                File.WriteAllText(markerPath, marker);
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Empty));
                var history = AICodedbManagerActionJournal.Read(context);
                Assert.That(history.HistoricalWarning, Does.Contain(actionId).And.Contain("unknown command outcome"));
                Assert.That(AICodedbManagerWindow.BuildHistoricalActionWarning(null, history.HistoricalWarning),
                    Is.EqualTo(history.HistoricalWarning));
                Assert.That(File.ReadAllBytes(admissionPath), Is.EqualTo(originalAdmissionBytes));
                Assert.That(File.ReadAllText(claimPath), Is.EqualTo(claim));
                File.WriteAllText(Path.Combine(stageRoot, "terminal.json"), "{}");
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                File.Delete(Path.Combine(stageRoot, "terminal.json"));
                File.WriteAllText(claimPath, claim.Replace("4242", "4243"));
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                File.WriteAllText(claimPath, claim);
                File.WriteAllText(markerPath, marker.Replace(proof, new string('0', 64)));
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                File.WriteAllText(markerPath, marker);
                workspace.DeleteOwnedTree(stageRoot);
                Directory.Delete(Path.GetDirectoryName(stageRoot));
                Assert.That(AICodedbManagerActionJournal.Read(context).State,
                    Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
            }
            finally
            {
                var indexDirectory = Path.GetDirectoryName(markerPath);
                if (Directory.Exists(indexDirectory) && Path.GetFileName(indexDirectory).Length == 24)
                    workspace.CaptureCleanup(() => workspace.DeleteOwnedTree(indexDirectory));
            }
            }, pathProfile: AICodedbTestPathProfile.CompactAndLegacy);
        }

        [Test]
        public void ManagerActionReceipt_CompleteEnvelopeIsValid()
        {
            var records = CreateManagerActionReceiptEnvelope();
            Assert.That(AICodedbProcessRunner.HasValidManagerActionReceiptEnvelope(
                records[0], records[1], records[2]), Is.True);
        }

        [TestCase("admitted.json", false)]
        [TestCase("admitted.json", true)]
        [TestCase("claim.json", false)]
        [TestCase("claim.json", true)]
        [TestCase("terminal.json", false)]
        [TestCase("terminal.json", true)]
        public void ManagerReceipt_CompactMissingOrWrongLayoutIsConflict(string filename, bool wrong)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var session = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, session.Context, false);
                var stage = fixture.Add("Install", fixture.InstallOutput);
                var path = ManagerReceiptFixture.StagePath(stage, filename);
                var record = AICodedbStrictJson.ReadObject(path, 1048576, "layout fixture");
                if (wrong) record["storage_layout"] = "unknown";
                else record.Remove("storage_layout");
                File.WriteAllText(path, AICodedbControlContractMigrationClassifierTests.SerializeObject(record));
                Assert.That(AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId).State,
                    Is.EqualTo(AICodedbManagerActionRecoveryState.Conflict));
            });
        }

        [TestCase(false)]
        [TestCase(true)]
        public void ManagerReceipt_DuplicateOrPrefixCollisionCannotReplaceAdmission(bool prefixCollision)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var session = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, session.Context, false);
                var stage = fixture.Add("Install", fixture.InstallOutput);
                var path = ManagerReceiptFixture.StagePath(stage, "admitted.json");
                var before = File.ReadAllBytes(path);
                var record = AICodedbStrictJson.ReadObject(path, 1048576, "collision fixture");
                var stageId = (string)record["stage_id"];
                if (prefixCollision) record["stage_id"] = stageId.Substring(0, 16) + new string(stageId[16] == 'a' ? 'b' : 'a', 48);
                var method = typeof(AICodedbProcessRunner).GetMethod("WriteNewUtf8FileAtomic",
                    System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic);
                Assert.That(method, Is.Not.Null);
                Assert.Throws<System.Reflection.TargetInvocationException>(() => method.Invoke(null,
                    new object[] { path, AICodedbControlContractMigrationClassifierTests.SerializeObject(record) }));
                Assert.That(File.ReadAllBytes(path), Is.EqualTo(before));
                Assert.That(Directory.GetFiles(Path.GetDirectoryName(path), "*.tmp"), Is.Empty);
                Assert.That(AICodedbManagerActionJournal.TryAdmit(new AICodedbManagerActionIndex(
                    fixture.ActionId, "Install CodeDB", "ConfirmedProjectMutation",
                    AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB"), fixture.Context), out _), Is.False);
            });
        }

        [TestCase("manifest")]
        [TestCase("stage")]
        [TestCase("legacy-location")]
        [TestCase("journal-layout")]
        public void ManagerReceipt_CompactFullIdentityAndLocationsFailClosed(string defect)
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var session = new ManagerActionSessionFixture(workspace);
                using var fixture = new ManagerReceiptFixture(workspace, session.Context, false);
                var stage = fixture.Add("Install", fixture.InstallOutput);
                if (defect == "legacy-location")
                    Directory.CreateDirectory(AICodedbPaths.GetManagerActionReceiptRoot(fixture.Context, fixture.ActionId, null));
                else
                {
                    var path = defect == "manifest" ? Path.Combine(Path.GetDirectoryName(stage), "action.json")
                        : defect == "journal-layout" ? AICodedbPaths.GetManagerActionIndexPath(fixture.Context, fixture.ActionId)
                        : ManagerReceiptFixture.StagePath(stage, "terminal.json");
                    var record = AICodedbStrictJson.ReadObject(path, 1048576, "identity fixture");
                    if (defect == "manifest") record["project_key"] = new string('0', 64);
                    else if (defect == "journal-layout") record.Remove("storage_layout");
                    else
                    {
                        var id = (string)record["stage_id"];
                        record["stage_id"] = id.Substring(0, 16) + new string(id[16] == 'a' ? 'b' : 'a', 48);
                    }
                    File.WriteAllText(path, AICodedbControlContractMigrationClassifierTests.SerializeObject(record));
                }
                if (defect == "journal-layout")
                    Assert.That(AICodedbManagerActionJournal.Read(fixture.Context).State, Is.EqualTo(AICodedbManagerActionIndexState.Conflict));
                else
                    Assert.That(AICodedbProcessRunner.RecoverManagerAction(fixture.Context, fixture.ActionId).State,
                        Is.EqualTo(AICodedbManagerActionRecoveryState.Conflict));
            });
        }

        [TestCase(0, "schema_version")]
        [TestCase(0, "managed_by")]
        [TestCase(0, "state")]
        [TestCase(0, "command")]
        [TestCase(1, "schema_version")]
        [TestCase(1, "managed_by")]
        [TestCase(1, "state")]
        [TestCase(1, "writer_start_utc_ticks")]
        [TestCase(1, "writer_pid")]
        [TestCase(2, "schema_version")]
        [TestCase(2, "managed_by")]
        [TestCase(2, "state")]
        [TestCase(2, "writer_pid")]
        [TestCase(2, "child_pid")]
        [TestCase(2, "completed_at_utc")]
        [TestCase(2, "output_overflow")]
        public void ManagerActionReceipt_MissingEnvelopeFieldCannotBeTerminal(
            int recordIndex, string field)
        {
            var records = CreateManagerActionReceiptEnvelope();
            records[recordIndex].Remove(field);
            Assert.That(AICodedbProcessRunner.HasValidManagerActionReceiptEnvelope(
                records[0], records[1], records[2]), Is.False,
                recordIndex + ":" + field);
        }

        [Test]
        public void ManagerActionReceipt_AlteredWriterChildAndOutputEvidenceIsRejected()
        {
            var changes = new[]
            {
                new { Index = 0, Field = "state", Value = (object)"terminal" },
                new { Index = 0, Field = "schema_version", Value = (object)"1" },
                new { Index = 1, Field = "managed_by", Value = (object)"other" },
                new { Index = 1, Field = "writer_start_utc_ticks", Value = (object)"invalid" },
                new { Index = 1, Field = "writer_start_utc_ticks", Value = (object)"0" },
                new { Index = 1, Field = "writer_pid", Value = (object)33L },
                new { Index = 2, Field = "writer_pid", Value = (object)33L },
                new { Index = 2, Field = "child_pid", Value = (object)0L },
                new { Index = 2, Field = "child_pid", Value = (object)11L },
                new { Index = 2, Field = "completed_at_utc", Value = (object)"invalid" },
                new { Index = 2, Field = "output_overflow", Value = (object)"false" },
                new { Index = 2, Field = "output_overflow", Value = (object)true }
            };
            foreach (var change in changes)
            {
                var records = CreateManagerActionReceiptEnvelope();
                records[change.Index][change.Field] = change.Value;
                Assert.That(AICodedbProcessRunner.HasValidManagerActionReceiptEnvelope(
                    records[0], records[1], records[2]), Is.False,
                    change.Index + ":" + change.Field + "=" + change.Value);
            }
        }

        [Test]
        public void ManagerActionReceipt_TimeoutCannotPrecedeAdmittedDeadline()
        {
            var records = CreateManagerActionReceiptEnvelope();
            records[2]["timed_out"] = true;
            records[2]["exit_code"] = 4L;
            Assert.That(AICodedbProcessRunner.HasValidManagerActionReceiptEnvelope(
                records[0], records[1], records[2]), Is.False);

            records[2]["elapsed_milliseconds"] = 120000L;
            Assert.That(AICodedbProcessRunner.HasValidManagerActionReceiptEnvelope(
                records[0], records[1], records[2]), Is.True);

            var command = AICodedbStrictJson.RequireObject(records[0]["command"], "admission fixture command");
            command.Remove("timeout_ms");
            Assert.That(AICodedbProcessRunner.HasValidManagerActionReceiptEnvelope(
                records[0], records[1], records[2]), Is.False);
        }

        private static Dictionary<string, object>[] CreateManagerActionReceiptEnvelope()
        {
            return new[]
            {
                AICodedbStrictJson.ParseObject(
                    "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"state\":\"admitted\",\"command\":{\"timeout_ms\":120000}}",
                    "admission fixture"),
                AICodedbStrictJson.ParseObject(
                    "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"state\":\"claimed\",\"writer_pid\":11,\"writer_start_utc_ticks\":\"1\"}",
                    "claim fixture"),
                AICodedbStrictJson.ParseObject(
                    "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"state\":\"terminal\",\"writer_pid\":11,\"child_pid\":22,\"completed_at_utc\":\"2026-09-24T00:00:00.0000000Z\",\"output_overflow\":false,\"timed_out\":false,\"exit_code\":0,\"elapsed_milliseconds\":1}",
                    "terminal fixture")
            };
        }

        [Test]
        public void ManagerActionSession_ProviderSuccessKeepsCommandAndNeedsAttentionSeparate()
        {
            var context = new AICodedbEditorExecutionContext(
                RuntimePlatform.WindowsEditor,
                Path.Combine(Path.GetTempPath(), "codedb-provider-project"),
                Path.Combine(Path.GetTempPath(), "codedb-provider-package"),
                "codedb-provider-project");
            try
            {
                Assert.That(AICodedbManagerActionSession.TryStart(
                    "Configure CodeDB Dependencies", context, 1d, out var action), Is.True);
                var providerResult = new AICodedbCommandResult(
                    0, "provider installed", string.Empty, false, 234);
                action.RecordInitialCommandResult(providerResult);
                action.RecordPostOutcome(new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                    1,
                    AICodedbEditorLifecycle.AICodedbReconcileDisposition.NeedsAttention,
                    default(AICodedbProductStatus),
                    null,
                    1,
                    "Host admission still needs attention."));
                action.Complete(providerResult, AICodedbProductState.Starting, true, 2d);

                Assert.That(action.Result, Is.SameAs(providerResult));
                Assert.That(action.InitialCommandResult, Is.SameAs(providerResult));
                Assert.That(action.Status.BuildPresentation(2d).StatusLabel,
                    Is.EqualTo("Completed - needs attention"));
                Assert.That(action.Status.BuildPresentation(2d).Detail,
                    Is.EqualTo("Host admission still needs attention."));
            }
            finally
            {
                AICodedbManagerActionSession.ClearCompleted();
            }
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_WindowCloseWithCommandRetainsResultWithoutClaimingReady()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                try
                {
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Redeploy", context, 1d, out var action), Is.True);
                    var preflight = new AICodedbCommandResult(0, "preflight", string.Empty, false);
                    action.FinishAfterWindowClose(preflight, 2d);

                    Assert.That(action.Result, Is.SameAs(preflight));
                    Assert.That(action.IsRecovering, Is.False);
                    Assert.That(action.Status.BuildPresentation(2d).StatusLabel,
                        Is.EqualTo("Completed - status unavailable"));
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Empty);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Verify", context, 3d, out var next), Is.True);
                    next.Complete(new AICodedbCommandResult(0, string.Empty, string.Empty, false),
                        AICodedbProductState.Starting, false, 4d);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }
            });
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_WindowCloseWithoutCommandKeepsRecoveryAdmissionBlocked()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                try
                {
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Redeploy", context, 1d, out var action), Is.True);
                    action.FinishAfterWindowClose(null, 2d);

                    Assert.That(action.IsRecovering, Is.True);
                    Assert.That(AICodedbManagerActionSession.ClearCompleted(), Is.False);
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Not.Empty);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Redeploy", context, 3d, out _), Is.False);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }
            });
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_MissingCommandResultCannotReleaseAdmission()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                Assert.Throws<InvalidOperationException>(() =>
                {
                    using var nested = new ManagerActionSessionFixture(workspace);
                });
                try
                {
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Verify", context, 1d, out var action), Is.True);
                    action.Complete(null, AICodedbProductState.NeedsAttention, false, 2d);

                    Assert.That(action.IsRecovering, Is.True);
                    Assert.That(action.Status.BuildPresentation(2d).StatusLabel,
                        Is.EqualTo("Outcome unconfirmed"));
                    Assert.That(AICodedbManagerActionSession.ClearCompleted(), Is.False);
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Not.Empty);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Verify", context, 3d, out _), Is.False);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }

                fixture.Dispose();
                Assert.That(fixture.OriginalRestored, Is.True);
                Assert.That(fixture.OwnedKeyRemoved, Is.True);
                ManagerActionSessionFixture faultFixture = null;
                Assert.Throws<InvalidOperationException>(() =>
                {
                    using (faultFixture = new ManagerActionSessionFixture(workspace))
                    {
                        Assert.That(AICodedbManagerActionSession.TryStart(
                            "Host Payload Verify", faultFixture.Context, 4d, out _), Is.True);
                        throw new InvalidOperationException("Owned fixture exception-path check.");
                    }
                });
                Assert.That(faultFixture.OriginalRestored, Is.True);
                Assert.That(faultFixture.OwnedKeyRemoved, Is.True);
            });
        }

        [Test]
        [Category("S28PhaseC")]
        public void ManagerActionSession_UnconfirmedTransportFailureKeepsRecovery()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                using var fixture = new ManagerActionSessionFixture(workspace);
                var context = fixture.Context;
                var key = "Rice.AI.Codedb.Manager.PendingAction." + context.ProjectRoot;
                try
                {
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Sync", context, 1d, out var action), Is.True);
                    var lostResponse = new AICodedbCommandResult(
                        4, string.Empty, "response lost", false, 1, false, false,
                        action.ActionId);
                    action.Complete(lostResponse, AICodedbProductState.Ready, true, 2d);
                    Assert.That(action.IsRecovering, Is.True);
                    Assert.That(action.Status.BuildPresentation(2d).Detail,
                        Does.Contain("response lost"));
                    Assert.That(SessionState.GetString(key, string.Empty), Is.Not.Empty);
                    Assert.That(AICodedbManagerActionSession.TryStart(
                        "Host Payload Verify", context, 3d, out _), Is.False);
                }
                finally
                {
                    workspace.CaptureCleanup(() =>
                    {
                        AICodedbManagerActionSession.ClearCompleted();
                        SessionState.SetString(key, string.Empty);
                    });
                }
            });
        }

        [Test]
        public void ManagerOpenAndRefresh_DoNotCallSynchronousFullStatus()
        {
            var managerSource = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath, "Editor", "AICodedbManagerWindow.cs"));
            var activitySource = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath, "Editor", "AICodedbActivityPanel.cs"));

            Assert.That(managerSource, Does.Not.Contain("AICodedbStatusSnapshot.Refresh("));
            Assert.That(managerSource, Does.Not.Contain("RecordMainThreadWork("));
            Assert.That(managerSource, Does.Contain("AICodedbStatusSnapshot.RefreshAsync("));
            Assert.That(activitySource, Does.Not.Contain("GUILayout.Button(\"Acknowledge\""));
        }

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
            Assert.That(AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath, Is.EqualTo("Tools~/install-codedb-provider.ps1"));
            Assert.That(AICodedbProjectSettings.ProviderDistributionManifestPackageRelativePath, Is.EqualTo("Tools~/codedb-provider-distribution.json"));
        }

        [Test]
        public void PackagePaths_UseUnityResolvedPackageLocation()
        {
            var packageInfo = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(AICodedbPaths).Assembly);

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
            Assert.That(
                AICodedbPaths.ProviderInstallerScriptPath,
                Is.EqualTo(AICodedbPaths.NormalizePath(Path.Combine(
                    packageInfo.resolvedPath,
                    AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath))));
            Assert.That(
                AICodedbPaths.ProviderDistributionManifestPath,
                Is.EqualTo(AICodedbPaths.NormalizePath(Path.Combine(
                    packageInfo.resolvedPath,
                    AICodedbProjectSettings.ProviderDistributionManifestPackageRelativePath))));
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

        [Test]
        public void McpPresentation_DistinguishesConfigurationFromClientObservation()
        {
            Assert.That(
                AICodedbManagerWindow.McpConfigurationReadyMessage,
                Is.EqualTo("Project configuration is ready"));
            Assert.That(
                AICodedbManagerWindow.McpConfigurationAttentionMessage,
                Is.EqualTo("Project configuration needs attention"));
            Assert.That(
                AICodedbManagerWindow.McpClientUnobservedLabel,
                Is.EqualTo("Not observed"));
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
        public void ManagerSource_DoesNotOwnMigrationClassificationOrAdmissionDryRun()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbManagerWindow.cs"));

            Assert.That(source, Does.Not.Contain("AICodedbControlContractMigrationStore"));
            Assert.That(source, Does.Not.Contain("TryResolveControlContractMigrationBlock"));
            Assert.That(source, Does.Not.Contain("AICodedbHostPayloadMaterializer.ReadStatus("));
        }

        [Test]
        public void ManagerSource_DoesNotScheduleWatcherObservationFromOpenOrTabObservation()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbManagerWindow.cs"));
            var openStart = source.IndexOf("internal static void Open(AICodedbManagerTab tab)", StringComparison.Ordinal);
            var openEnd = source.IndexOf("private void OnEnable()", openStart, StringComparison.Ordinal);
            var drawStart = source.IndexOf("private void DrawTabBar()", StringComparison.Ordinal);
            var drawEnd = source.IndexOf("private void DrawMainContentArea", drawStart, StringComparison.Ordinal);
            var selectStart = source.IndexOf("private void SelectTab(AICodedbManagerTab tab)", StringComparison.Ordinal);
            var selectEnd = source.IndexOf("private string GetHeaderTitle()", selectStart, StringComparison.Ordinal);
            var observerStart = source.IndexOf("private void ObserveTransientHostStatus()", StringComparison.Ordinal);
            var observerEnd = source.IndexOf("private void ApplyStatusSnapshot(", observerStart, StringComparison.Ordinal);

            Assert.That(openStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(openEnd, Is.GreaterThan(openStart));
            Assert.That(drawStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(drawEnd, Is.GreaterThan(drawStart));
            Assert.That(selectStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(selectEnd, Is.GreaterThan(selectStart));
            Assert.That(observerStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(observerEnd, Is.GreaterThan(observerStart));
            Assert.That(source.Substring(openStart, openEnd - openStart), Does.Not.Contain("ScheduleWatcherStatusRefresh"));
            Assert.That(source.Substring(drawStart, drawEnd - drawStart), Does.Not.Contain("ScheduleWatcherStatusRefresh"));
            Assert.That(source.Substring(selectStart, selectEnd - selectStart), Does.Not.Contain("ScheduleWatcherStatusRefresh"));
            Assert.That(source.Substring(observerStart, observerEnd - observerStart), Does.Not.Contain("RequestBackgroundStatusObservation"));
            Assert.That(source, Does.Not.Contain("RefreshTransientHostStatusAsync"));
            Assert.That(source, Does.Not.Contain("AICodedbHostPayloadMaterializer.ReadStatusAsync"));

            var refreshStart = source.IndexOf("private void RefreshAllStatus()", StringComparison.Ordinal);
            var refreshEnd = source.IndexOf("private void DrawHeader()", refreshStart, StringComparison.Ordinal);
            Assert.That(refreshStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(refreshEnd, Is.GreaterThan(refreshStart));
            var refreshBody = source.Substring(refreshStart, refreshEnd - refreshStart);
            Assert.That(refreshBody, Does.Contain("ScheduleWatcherStatusRefresh"));
            Assert.That(refreshBody, Does.Contain("BeginStatusRefresh(true)"));

            var requestStart = source.IndexOf("private void BeginStatusRefresh(bool force = false)", StringComparison.Ordinal);
            var requestEnd = source.IndexOf("private bool TryApplyCachedLifecycleStatus()", requestStart, StringComparison.Ordinal);
            Assert.That(requestStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(requestEnd, Is.GreaterThan(requestStart));
            var requestBody = source.Substring(requestStart, requestEnd - requestStart);
            Assert.That(requestBody, Does.Contain("RequestBackgroundStatusObservation(true)"));
            Assert.That(requestBody, Does.Not.Contain("AICodedbStatusSnapshot.RefreshAsync"));
            Assert.That(requestBody, Does.Not.Contain("AICodedbHostPayloadMaterializer"));
        }

        [Test]
        public void ManagerMaintenanceSource_UsesSupervisorQueueAndCacheOnlyCompletion()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbManagerWindow.cs"));

            Assert.That(source, Does.Contain("RunSupervisorMaintenanceAction(\"Refresh If Stale\", \"RefreshIfStale\")"));
            Assert.That(source, Does.Contain("RunSupervisorMaintenanceAction(\"Refresh Index\", \"RefreshIndex\")"));
            Assert.That(source, Does.Contain("RunSupervisorMaintenanceAction(\"Build Shader Adapter\", \"BuildShaderAdapter\")"));
            Assert.That(source, Does.Contain("RunSupervisorMaintenanceAction(\"Clean Index\", \"CleanIndex\")"));
            Assert.That(source, Does.Contain("RunSupervisorMaintenanceAction(\"Rebuild Index\", \"RebuildIndex\")"));
            Assert.That(source, Does.Not.Contain("AICodedbActions.RunRefreshIfStale"));
            Assert.That(source, Does.Not.Contain("AICodedbActions.RunRefreshIndex"));
            Assert.That(source, Does.Not.Contain("AICodedbActions.RunBuildShaderAdapter"));
            Assert.That(source, Does.Not.Contain("AICodedbActions.RunCleanIndex"));
            Assert.That(source, Does.Not.Contain("AICodedbActions.RunRebuildIndex"));

            var helperStart = source.IndexOf(
                "private void RunSupervisorMaintenanceAction",
                StringComparison.Ordinal);
            var helperEnd = source.IndexOf(
                "private void RunUserActionAsync",
                helperStart,
                StringComparison.Ordinal);
            Assert.That(helperStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(helperEnd, Is.GreaterThan(helperStart));
            var helperBody = source.Substring(helperStart, helperEnd - helperStart);
            Assert.That(helperBody, Does.Contain("RunSupervisorMaintenanceCommandAsync(action)"));
            Assert.That(helperBody, Does.Contain("requestReconcileAfterAction: true"));
            Assert.That(helperBody, Does.Contain("refreshStatusAfterAction: false"));
            Assert.That(helperBody, Does.Not.Contain("Task.Run"));
            Assert.That(helperBody, Does.Not.Contain("RefreshStatusAsync"));

            var completionStart = source.IndexOf(
                "private async Task RunUserActionAsync",
                helperEnd,
                StringComparison.Ordinal);
            var completionEnd = source.IndexOf(
                "private void DrawActivityPanel",
                completionStart,
                StringComparison.Ordinal);
            Assert.That(completionStart, Is.GreaterThan(helperEnd));
            Assert.That(completionEnd, Is.GreaterThan(completionStart));
            var completionBody = source.Substring(completionStart, completionEnd - completionStart);
            Assert.That(completionBody, Does.Contain("if (refreshStatusAfterAction)"));
            Assert.That(completionBody, Does.Contain("await RefreshStatusAsync(_lastResult)"));
            Assert.That(completionBody, Does.Contain("AICodedbEditorLifecycle.RequestReconcile()"));
        }

        [Test]
        public void ManagerHostActions_KeepUnityProgressUiOutOfWorkerCommands()
        {
            var editorRoot = Path.Combine(AICodedbPaths.PackageRootPath, "Editor");
            var manager = File.ReadAllText(Path.Combine(editorRoot, "AICodedbManagerWindow.cs"));
            var actions = File.ReadAllText(Path.Combine(editorRoot, "AICodedbActions.cs"));
            var materializer = File.ReadAllText(Path.Combine(editorRoot, "AICodedbHostPayloadMaterializer.cs"));

            Assert.That(manager, Does.Contain("_ => Task.Run(action)"));
            Assert.That(manager, Does.Contain("GetActivityPanel().ResetForRunningAction()"));
            Assert.That(manager, Does.Contain("AICodedbActions.RunHostPayloadDryRun"));
            Assert.That(manager, Does.Contain("AICodedbActions.RunHostPayloadVerify"));
            Assert.That(manager, Does.Contain("AICodedbActions.RunHostPayloadSync"));
            Assert.That(manager, Does.Contain("AICodedbActions.RunHostPayloadRemove"));
            Assert.That(manager, Does.Contain("AICodedbActions.RunHostPayloadUpgrade"));
            Assert.That(manager, Does.Contain("AICodedbActions.RunHostPayloadRedeploy(true)"));
            Assert.That(manager, Does.Contain("GetDisplayedProductState()"));
            Assert.That(manager, Does.Contain("TryGetActionStatusOverride(out var presentation)"));

            Assert.That(actions, Does.Not.Contain("EditorUtility.DisplayProgressBar"));
            Assert.That(actions, Does.Not.Contain("EditorUtility.ClearProgressBar"));
            Assert.That(materializer, Does.Not.Contain("EditorUtility.DisplayProgressBar"));
            Assert.That(materializer, Does.Not.Contain("EditorUtility.ClearProgressBar"));
        }

        [Test]
        public void ConfigureDependenciesSource_RechecksHostAdmissionAfterProviderSuccess()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbManagerWindow.cs"));
            var actionsSource = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbActions.cs"));

            Assert.That(source, Does.Contain("RecheckHostPayloadAfterProviderAsync"));
            Assert.That(source, Does.Contain("RunHostAdmissionAfterProviderAsync(providerResult)"));
            Assert.That(source, Does.Contain("TryApplyCachedLifecycleStatus()"));
            Assert.That(source, Does.Not.Contain("AICodedbHostPayloadMaterializer.RunDryRun()"));
            Assert.That(actionsSource, Does.Contain("RequestPostProviderReconcileAsync"));
            var admissionStart = actionsSource.IndexOf(
                "RunHostAdmissionAfterProviderAsync(", StringComparison.Ordinal);
            var admissionEnd = actionsSource.IndexOf(
                "private static AICodedbCommandResult RunProviderInstaller(",
                admissionStart,
                StringComparison.Ordinal);
            Assert.That(admissionStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(admissionEnd, Is.GreaterThan(admissionStart));
            var admissionBody = actionsSource.Substring(admissionStart, admissionEnd - admissionStart);
            Assert.That(admissionBody, Does.Contain("RequestPostProviderReconcileAsync"));
            Assert.That(admissionBody, Does.Not.Contain("RunSupervisorCommandWithFallbackAsync"));
            Assert.That(admissionBody, Does.Not.Contain("RunProbeAsync"));
            Assert.That(admissionBody, Does.Not.Contain("RunInstallAsync"));
            Assert.That(admissionBody, Does.Not.Contain("MCP availability requires the current Package-owned Host runtime."));
        }

        [Test]
        public void ConfigureDependenciesAdmission_ProviderFailureDoesNotRequestReconcile()
        {
            var providerFailure = new AICodedbCommandResult(4, string.Empty, "provider failed", false);
            var reconcileCalls = 0;
            var result = AICodedbActions.RunHostAdmissionAfterProviderAsync(
                    providerFailure,
                    () =>
                    {
                        reconcileCalls++;
                        return Task.FromResult(new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                            1,
                            AICodedbEditorLifecycle.AICodedbReconcileDisposition.Ready,
                            default(AICodedbProductStatus),
                            null,
                            1,
                            "must not run"));
                    })
                .GetAwaiter()
                .GetResult();

            Assert.That(result.Disposition, Is.EqualTo(AICodedbEditorLifecycle.AICodedbReconcileDisposition.Deferred));
            Assert.That(reconcileCalls, Is.Zero);
        }

        [Test]
        public void ConfigureDependenciesAdmission_ProviderSuccessAwaitsLifecycleOutcome()
        {
            var providerSuccess = Result("provider installed");
            var reconcileCalls = 0;
            var failedProbeShape = new AICodedbCommandResult(
                4,
                "[PRODUCT_LAYER PREREQUISITE] CURRENT",
                "MCP availability requires the current Package-owned Host runtime.",
                false);
            var expected = new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                7,
                AICodedbEditorLifecycle.AICodedbReconcileDisposition.NeedsAttention,
                default(AICodedbProductStatus),
                failedProbeShape,
                19,
                "authoritative lifecycle result");

            var actual = AICodedbActions.RunHostAdmissionAfterProviderAsync(
                    providerSuccess,
                    () =>
                    {
                        reconcileCalls++;
                        return Task.FromResult(expected);
                    })
                .GetAwaiter()
                .GetResult();

            Assert.That(actual, Is.SameAs(expected));
            Assert.That(reconcileCalls, Is.EqualTo(1));
            Assert.That(actual.Epoch, Is.EqualTo(7));
            Assert.That(actual.CacheRevision, Is.EqualTo(19));
            Assert.That(actual.Disposition, Is.EqualTo(AICodedbEditorLifecycle.AICodedbReconcileDisposition.NeedsAttention));
            Assert.That(actual.LastCommandResult, Is.SameAs(failedProbeShape),
                "A nonzero Host result with prerequisite stdout and runtime stderr does not select an Actions mutation.");
        }

        [Test]
        public void PostProviderResult_FailingAuthoritativeResultIsPreservedExactly()
        {
            var authoritative = new AICodedbCommandResult(
                17,
                "authoritative stdout",
                "authoritative stderr",
                false,
                4321,
                true);
            var outcome = new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                8,
                AICodedbEditorLifecycle.AICodedbReconcileDisposition.NeedsAttention,
                default(AICodedbProductStatus),
                authoritative,
                20,
                "truncated terminal detail");

            var actual = AICodedbManagerWindow.ResolvePostProviderReconcileResult(
                new AICodedbCommandResult(0, "provider installed", string.Empty, false), outcome);

            Assert.That(actual, Is.SameAs(authoritative));
            Assert.That(actual.ExitCode, Is.EqualTo(17));
            Assert.That(actual.StandardOutput, Is.EqualTo("authoritative stdout"));
            Assert.That(actual.StandardError, Is.EqualTo("authoritative stderr"));
            Assert.That(actual.TimedOut, Is.False);
            Assert.That(actual.ElapsedMilliseconds, Is.EqualTo(4321));
            Assert.That(actual.OneShotFallbackAuthorized, Is.True);
        }

        [Test]
        public void PostProviderResult_SuccessfulCommandWithNonReadyOutcomeRetainsExitCode()
        {
            var authoritative = new AICodedbCommandResult(
                0,
                "successful command stdout",
                "successful command warning",
                false,
                876,
                true);
            var outcome = new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                9,
                AICodedbEditorLifecycle.AICodedbReconcileDisposition.Deferred,
                default(AICodedbProductStatus),
                authoritative,
                21,
                "Lifecycle remained deferred.");

            var actual = AICodedbManagerWindow.ResolvePostProviderReconcileResult(
                new AICodedbCommandResult(0, "provider installed", string.Empty, false), outcome);

            Assert.That(actual, Is.SameAs(authoritative));
            Assert.That(actual.ExitCode, Is.Zero);
            Assert.That(actual.StandardError, Is.EqualTo("successful command warning"));
        }

        [Test]
        public void PostProviderResult_ReadyOutcomeDoesNotReplaceFailedCommand()
        {
            var outcome = new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                10,
                AICodedbEditorLifecycle.AICodedbReconcileDisposition.Ready,
                default(AICodedbProductStatus),
                new AICodedbCommandResult(12, "ignored", "ignored", false, 123, true),
                22,
                "ready");

            var actual = AICodedbManagerWindow.ResolvePostProviderReconcileResult(
                new AICodedbCommandResult(0, "provider installed", string.Empty, false), outcome);

            Assert.That(actual.Succeeded, Is.False);
            Assert.That(actual.ExitCode, Is.EqualTo(12));
            Assert.That(actual.StandardOutput, Is.EqualTo("ignored"));
        }

        [Test]
        public void PostProviderResult_MissingHostCommandKeepsProviderEvidence()
        {
            var outcome = new AICodedbEditorLifecycle.AICodedbReconcileOutcome(
                11,
                AICodedbEditorLifecycle.AICodedbReconcileDisposition.NeedsAttention,
                default(AICodedbProductStatus),
                null,
                23,
                "No authoritative command was published.");

            var providerResult = new AICodedbCommandResult(
                0, "provider installed", string.Empty, false, 100);
            var missingCommand = AICodedbManagerWindow.ResolvePostProviderReconcileResult(
                providerResult, outcome);
            var missingOutcome = AICodedbManagerWindow.ResolvePostProviderReconcileResult(
                providerResult, null);

            Assert.That(missingCommand, Is.SameAs(providerResult));
            Assert.That(missingOutcome.Succeeded, Is.False);
            Assert.That(missingOutcome.ExitCode, Is.EqualTo(4));
            Assert.That(missingOutcome.StandardError,
                Is.EqualTo("Lifecycle did not return a post-Provider reconcile outcome."));
        }

        [Test]
        public void ActionsSource_DoesNotParseHostOutputOrSelectBootstrapMutation()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbActions.cs"));

            Assert.That(source, Does.Contain("RequestPostProviderReconcileAsync"));
            var admissionStart = source.IndexOf(
                "RunHostAdmissionAfterProviderAsync(", StringComparison.Ordinal);
            var admissionEnd = source.IndexOf(
                "private static AICodedbCommandResult RunProviderInstaller(",
                admissionStart,
                StringComparison.Ordinal);
            Assert.That(admissionStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(admissionEnd, Is.GreaterThan(admissionStart));
            var admissionBody = source.Substring(admissionStart, admissionEnd - admissionStart);
            Assert.That(admissionBody, Does.Not.Contain("MCP availability requires the current Package-owned Host runtime."));
            Assert.That(admissionBody, Does.Not.Contain("RunProbeAsync"));
            Assert.That(admissionBody, Does.Not.Contain("RunInstallAsync"));
            Assert.That(admissionBody, Does.Not.Contain("RunSupervisorCommandWithFallbackAsync"));
        }

        [Test]
        public void ActionsSource_RechecksCurrentRemoveIntegrationEvidenceOnAWorker()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbActions.cs"));
            var start = source.IndexOf(
                "RunRemoveIntegrationCodeDBAsync(",
                StringComparison.Ordinal);
            var end = source.IndexOf(
                "private static AICodedbCommandResult RemoveIntegrationAdmissionRejected(",
                start + 1,
                StringComparison.Ordinal);
            Assert.That(start, Is.GreaterThanOrEqualTo(0));
            Assert.That(end, Is.GreaterThan(start));
            var body = source.Substring(start, end - start);

            Assert.That(body, Does.Contain("await Task.Run("));
            Assert.That(body, Does.Contain("AICodedbProjectIntegrationStateStore.Read("));
            Assert.That(body, Does.Contain("AICodedbControlContractMigrationStore.Read("));
            Assert.That(body, Does.Not.Contain("AICodedbHostPayloadMaterializer.ReadStatus"));
        }

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
        public void CoordinatorFailurePresentation_IsFixedVocabularyAndCacheOnly()
        {
            var failed = AICodedbStatusSnapshot.CreateCoordinatorFailureStatus(
                AICodedbCoordinatorFailureCategory.NonzeroExit);
            var unknown = AICodedbStatusSnapshot.CreateCoordinatorFailureStatus(
                (AICodedbCoordinatorFailureCategory)int.MaxValue);
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbManagerWindow.cs"));
            var cacheStart = source.IndexOf(
                "private static AICodedbCoordinatorFailureCategory GetCachedCoordinatorFailureCategory()",
                StringComparison.Ordinal);
            var cacheEnd = source.IndexOf("private static void InvalidateReadySnapshot", cacheStart, StringComparison.Ordinal);
            var cacheBody = source.Substring(cacheStart, cacheEnd - cacheStart);
            var applyStart = source.IndexOf(
                "private bool TryApplyCachedLifecycleStatus()",
                StringComparison.Ordinal);
            var applyEnd = source.IndexOf(
                "private async void ApplyCachedLifecycleStatusAsync",
                applyStart,
                StringComparison.Ordinal);
            var applyBody = source.Substring(applyStart, applyEnd - applyStart);

            Assert.That(failed.Label, Is.EqualTo("Coordinator startup"));
            Assert.That(failed.Summary, Is.EqualTo("NONZERO_EXIT"));
            Assert.That(failed.Detail, Does.Not.Contain("stderr"));
            Assert.That(unknown.Summary, Is.EqualTo("UNKNOWN_FAILURE"));
            Assert.That(cacheStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(cacheEnd, Is.GreaterThan(cacheStart));
            Assert.That(applyStart, Is.GreaterThanOrEqualTo(0));
            Assert.That(applyEnd, Is.GreaterThan(applyStart));
            Assert.That(cacheBody, Does.Contain("GetCachedLifecycleSupervisorSnapshot"));
            Assert.That(cacheBody, Does.Not.Contain("GetCachedSupervisorSnapshot()"));
            Assert.That(cacheBody, Does.Not.Contain("File."));
            Assert.That(cacheBody, Does.Not.Contain("Process."));
            Assert.That(cacheBody, Does.Not.Contain("RequestBackgroundStatusObservation"));
            Assert.That(applyBody, Does.Contain("TryGetCachedLifecycleStatus"));
            Assert.That(applyBody, Does.Contain("cachedSupervisorSnapshot"));
            Assert.That(applyBody, Does.Not.Contain("GetCachedSupervisorSnapshot"));
            Assert.That(applyBody, Does.Not.Contain("SupervisorBridge"));
            Assert.That(
                source,
                Does.Contain("DrawStatus(_statusSnapshot.CoordinatorFailure)"));
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

        [TestCase(AICodedbProductState.Starting, AICodedbProductAttentionReason.None, true, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Ready, AICodedbProductAttentionReason.None, true, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.NeedsAttention, AICodedbProductAttentionReason.None, true, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.NeedsAttention, AICodedbProductAttentionReason.ControlContractReinstallRequired, true, false, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NeedsAttention, AICodedbProductAttentionReason.InstanceIdentityReinstallRequired, true, false, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NeedsAttention, AICodedbProductAttentionReason.ControlContractInvalidOrAmbiguous, true, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, AICodedbProductAttentionReason.None, false, false, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NotIntegrated, AICodedbProductAttentionReason.None, false, false, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NotIntegrated, AICodedbProductAttentionReason.None, false, true, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, AICodedbProductAttentionReason.None, true, true, ExpectedResult = false)]
        [TestCase(AICodedbProductState.MissingPrerequisite, AICodedbProductAttentionReason.ControlContractReinstallRequired, true, false, ExpectedResult = false)]
        public bool ResolvePrimaryAction_ExposesOnlyOneContextualUserAction(
            AICodedbProductState state,
            AICodedbProductAttentionReason attentionReason,
            bool reinstallAvailable,
            bool actionInFlight)
        {
            var status = new AICodedbProductStatus(
                state,
                AICodedbProductLayerState.Unknown,
                AICodedbProductLayerState.Unknown,
                AICodedbProductLayerState.Unknown,
                string.Empty,
                default(AICodedbMaterializerCommandStatus),
                attentionReason,
                string.Empty,
                reinstallAvailable && (attentionReason == AICodedbProductAttentionReason.ControlContractReinstallRequired
                                       || attentionReason == AICodedbProductAttentionReason.InstanceIdentityReinstallRequired));
            return AICodedbManagerWindow.ResolvePrimaryAction(
                status,
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
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status, true, false), Is.False);
        }

        [Test]
        public void MissingProviderPrerequisite_OffersOnlyConfigureDependenciesAction()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                new AICodedbCommandResult(
                    4,
                    "[PRODUCT_LAYER PREREQUISITE] MISSING - Provider missing.\n" +
                    "[PRODUCT_STATE] MISSING_PREREQUISITE\n" +
                    "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"action\":\"UPGRADE\",\"outcome\":\"BLOCKED\",\"phase\":\"PREFLIGHT\",\"reason_code\":\"PROVIDER_MISSING\",\"mutated_scopes\":[],\"cleanup_state\":\"COMPLETE\",\"next_action\":\"Configure Dependencies\",\"exit_code\":4,\"detail\":\"Provider missing.\"}",
                    "Provider missing.",
                    false));

            Assert.That(AICodedbManagerWindow.IsProviderInstallAvailable(status), Is.True);
            Assert.That(AICodedbManagerWindow.ResolveProviderInstallAction(status, false), Is.True);
            Assert.That(AICodedbManagerWindow.ResolveProviderInstallAction(status, true), Is.False);
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(status), Is.False);
            Assert.That(AICodedbManagerWindow.ShouldOfferConfigureDependencies(status), Is.True);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status, true, false), Is.False);
        }

        [Test]
        public void VerifiedProvider_KeepsSecondaryConfigureDependenciesActionAvailable()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                new AICodedbCommandResult(
                    8,
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT - Node.js v24.14.1 and CodeDB Provider 0.5.0-28e3912 are verified.\n" +
                    "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                    "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE - query failed\n" +
                    "[PRODUCT_STATE] NEEDS_ATTENTION\n",
                    "query failed",
                    false));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(AICodedbManagerWindow.IsProviderInstallAvailable(status), Is.False);
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(status), Is.False);
            Assert.That(AICodedbManagerWindow.ShouldOfferConfigureDependencies(status), Is.False);
            Assert.That(AICodedbManagerWindow.CanConfigureDependencies(false), Is.True);
            Assert.That(AICodedbManagerWindow.CanConfigureDependencies(true), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status, true, false), Is.False);
        }

        [Test]
        public void ReadyProvider_DoesNotKeepConfigureDependenciesOnOverview()
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
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(status), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status, true, false), Is.False);
            Assert.That(
                AICodedbStatusSnapshot.CreateOverallDescription(status),
                Is.EqualTo("CodeDB is ready for this project. New Codex tasks can use project status and search tools."));
        }

        [Test]
        public void GenericNeedsAttentionDescription_HidesInternalsAndDoesNotPrescribeReinstall()
        {
            var status = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Unavailable,
                "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE - internal pipe and lease detail");

            var description = AICodedbStatusSnapshot.CreateOverallDescription(status);

            Assert.That(description, Is.EqualTo(
                "CodeDB could not finish setup for this project. Review diagnostics before choosing a recovery action."));
            Assert.That(description, Does.Not.Contain("PRODUCT_LAYER"));
            Assert.That(description, Does.Not.Contain("pipe"));
            Assert.That(description, Does.Not.Contain("Reinstall"));
        }

        [Test]
        public void MissingProviderDescription_HidesRawPrerequisiteEvidence()
        {
            var status = new AICodedbProductStatus(
                AICodedbProductState.MissingPrerequisite,
                AICodedbProductLayerState.Missing,
                AICodedbProductLayerState.Unknown,
                AICodedbProductLayerState.Unknown,
                AICodedbProductLayerState.Unknown,
                "[PRODUCT_LAYER PREREQUISITE] MISSING - provider-manifest.json hash mismatch");

            var description = AICodedbStatusSnapshot.CreateOverallDescription(status);

            Assert.That(description, Is.EqualTo(
                "CodeDB dependencies are not configured. Use Configure Dependencies to continue."));
            Assert.That(description, Does.Not.Contain("manifest"));
            Assert.That(description, Does.Not.Contain("hash"));
        }

        [Test]
        public void MissingNodePrerequisite_DoesNotOfferProviderInstallAction()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                new AICodedbCommandResult(
                    4,
                    "[PRODUCT_LAYER PREREQUISITE] MISSING - Node.js missing.\n" +
                    "[PRODUCT_STATE] MISSING_PREREQUISITE\n" +
                    "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"action\":\"UPGRADE\",\"outcome\":\"BLOCKED\",\"phase\":\"PREFLIGHT\",\"reason_code\":\"NODE_MISSING\",\"mutated_scopes\":[],\"cleanup_state\":\"COMPLETE\",\"next_action\":\"Install Node.js\",\"exit_code\":4,\"detail\":\"Node.js missing.\"}",
                    "Node.js missing.",
                    false));

            Assert.That(AICodedbManagerWindow.IsProviderInstallAvailable(status), Is.False);
            Assert.That(AICodedbManagerWindow.ResolveProviderInstallAction(status, false), Is.False);
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(status), Is.False);
        }

        [Test]
        public void StartingState_DoesNotExposeDependencyMutationWhileChecking()
        {
            var status = AICodedbProductStatusBuilder.Build(
                Installed,
                new AICodedbCommandResult(
                    0,
                    "[PRODUCT_LAYER PREREQUISITE] PENDING\n" +
                    "[PRODUCT_STATE] STARTING\n",
                    string.Empty,
                    false));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.Starting));
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(status), Is.False);
            Assert.That(AICodedbManagerWindow.ShouldOfferConfigureDependencies(status), Is.False);
        }

        [TestCase(AICodedbProductState.Ready, true, false, 0, 3, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Starting, true, false, 2, 3, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Starting, true, false, 3, 3, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Starting, false, false, 0, 3, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Starting, true, true, 3, 3, ExpectedResult = true)]
        public bool TransientRefreshRetention_DoesNotReplaceStableStateImmediately(
            AICodedbProductState previousState,
            bool hasVerifiedReady,
            bool reconcileInFlight,
            int attempt,
            int maximumAttempts)
        {
            return AICodedbManagerWindow.ShouldPreserveReadyDuringTransientRefresh(
                previousState,
                AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability,
                hasVerifiedReady,
                reconcileInFlight,
                attempt,
                maximumAttempts);
        }

        [TestCase(AICodedbProductState.Starting, false, 0, 3, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NeedsAttention, true, 3, 3, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NeedsAttention, false, 3, 3, ExpectedResult = false)]
        [TestCase(AICodedbProductState.MissingPrerequisite, true, 0, 3, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, true, 0, 3, ExpectedResult = false)]
        public bool RecoverableAvailability_DoesNotImmediatelyExposeReinstall(
            AICodedbProductState previousState,
            bool reconcileInFlight,
            int attempt,
            int maximumAttempts)
        {
            return AICodedbManagerWindow.ShouldKeepRecoverableAvailabilityStarting(
                previousState,
                AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability,
                reconcileInFlight,
                attempt,
                maximumAttempts);
        }

        [TestCase(AICodedbProductState.NeedsAttention, true, 0, 3, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Starting, true, 0, 3, ExpectedResult = false)]
        [TestCase(AICodedbProductState.MissingPrerequisite, true, 0, 3, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, true, 0, 3, ExpectedResult = false)]
        public bool RecoverableAvailability_ReplacesStaleReinstallWithStartingOnly(
            AICodedbProductState previousState,
            bool reconcileInFlight,
            int attempt,
            int maximumAttempts)
        {
            return AICodedbManagerWindow.ShouldPresentRecoverableAvailabilityAsStarting(
                previousState,
                AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability,
                reconcileInFlight,
                attempt,
                maximumAttempts);
        }

        [Test]
        public void StructuralAvailabilityFailure_IsNotPresentedAsStarting()
        {
            Assert.That(
                AICodedbManagerWindow.ShouldKeepRecoverableAvailabilityStarting(
                    AICodedbProductState.NeedsAttention,
                    AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked,
                    true,
                    0,
                    3),
                Is.False);
        }

        [Test]
        public void StructuralRefreshFailure_IsNotRetainedAsATransientAvailabilityLoss()
        {
            Assert.That(
                AICodedbManagerWindow.ShouldPreserveReadyDuringTransientRefresh(
                    AICodedbProductState.Starting,
                    AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked,
                    true,
                    false,
                    0,
                    3),
                Is.False);
        }

        [TestCase(true, AICodedbProductState.Starting, true, ExpectedResult = true)]
        [TestCase(true, AICodedbProductState.NeedsAttention, true, ExpectedResult = true)]
        [TestCase(true, AICodedbProductState.Ready, true, ExpectedResult = false)]
        [TestCase(false, AICodedbProductState.Starting, true, ExpectedResult = false)]
        [TestCase(true, AICodedbProductState.MissingPrerequisite, false, ExpectedResult = false)]
        [TestCase(true, AICodedbProductState.Uninstalled, false, ExpectedResult = false)]
        public bool PlayModeReadyRestore_RequiresVerifiedPersistedReadyState(
            bool isPlayingOrWillChangePlaymode,
            AICodedbProductState currentState,
            bool canUsePersistedReadyState)
        {
            return AICodedbManagerWindow.ShouldRestoreReadyForPlayMode(
                isPlayingOrWillChangePlaymode,
                currentState,
                canUsePersistedReadyState);
        }

        [TestCase(0, 0, false, ExpectedResult = true)]
        [TestCase(0, 1, false, ExpectedResult = false)]
        [TestCase(0, 0, true, ExpectedResult = false)]
        public bool PlayModeStatusRefresh_DiscardsStaleOrSuspendedResults(
            int requestGeneration,
            int currentGeneration,
            bool isPlayingOrWillChangePlaymode)
        {
            return AICodedbManagerWindow.ShouldApplyStatusRefreshResult(
                requestGeneration,
                currentGeneration,
                isPlayingOrWillChangePlaymode);
        }

        [TestCase(4, 4, false, 2, 2, false, ExpectedResult = true)]
        [TestCase(4, 5, false, 2, 2, false, ExpectedResult = false)]
        [TestCase(4, 4, true, 2, 2, false, ExpectedResult = false)]
        [TestCase(4, 4, false, 2, 3, false, ExpectedResult = false)]
        [TestCase(4, 4, false, 2, 2, true, ExpectedResult = false)]
        public bool WindowStatusRefresh_RequiresCurrentUncancelledWindowAndPlayGeneration(
            int requestWindowGeneration,
            int currentWindowGeneration,
            bool cancellationRequested,
            int requestPlayModeGeneration,
            int currentPlayModeGeneration,
            bool isPlayingOrWillChangePlaymode)
        {
            return AICodedbManagerWindow.ShouldApplyStatusRefreshResult(
                requestWindowGeneration,
                currentWindowGeneration,
                cancellationRequested,
                requestPlayModeGeneration,
                currentPlayModeGeneration,
                isPlayingOrWillChangePlaymode);
        }

        [Test]
        public void StatusSnapshotRefresh_PreCancelledWindowTokenDoesNotStartWork()
        {
            using (var cancellation = new CancellationTokenSource())
            {
                cancellation.Cancel();
                var task = AICodedbStatusSnapshot.RefreshAsync(
                    default(AICodedbEditorExecutionContext),
                    null,
                    cancellation.Token);

                Assert.That(task.IsCanceled, Is.True);
            }
        }

        [TestCase(false, false, ExpectedResult = false)]
        [TestCase(true, false, ExpectedResult = true)]
        [TestCase(false, true, ExpectedResult = true)]
        [TestCase(true, true, ExpectedResult = true)]
        public bool PlayModeDisplaySuspension_UsesEitherUnitySignal(
            bool editorPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return AICodedbManagerWindow.IsPlayModeDisplaySuspended(
                editorPlayingOrWillChangePlaymode,
                applicationPlaying);
        }

        [Test]
        public void CachedReadySnapshot_IsDisplayOnlyAndKeepsReadySemantics()
        {
            var snapshot = AICodedbStatusSnapshot.CreateCachedReady("FixtureProject");

            Assert.That(snapshot.ProductStatus.State, Is.EqualTo(AICodedbProductState.Ready));
            Assert.That(snapshot.ProductStatus.Prerequisite, Is.EqualTo(AICodedbProductLayerState.Current));
            Assert.That(snapshot.HostPayloadStatus.State, Is.EqualTo(AICodedbHostPayloadState.Current));
            Assert.That(snapshot.HostGenerationSelection.State, Is.EqualTo(AICodedbHostGenerationState.Current));
            Assert.That(snapshot.OverallTitle, Is.EqualTo("FixtureProject · Ready"));
            Assert.That(snapshot.OverallDescription, Does.Contain("before Play mode"));
        }

        [Test]
        public void CachedMissingPrerequisiteSnapshot_KeepsExplicitUserStateDuringPlay()
        {
            var snapshot = AICodedbStatusSnapshot.CreateCachedMissingPrerequisite("FixtureProject");

            Assert.That(snapshot.ProductStatus.State, Is.EqualTo(AICodedbProductState.MissingPrerequisite));
            Assert.That(snapshot.ProductStatus.Prerequisite, Is.EqualTo(AICodedbProductLayerState.Missing));
            Assert.That(snapshot.OverallState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(snapshot.OverallTitle, Is.EqualTo("FixtureProject · Missing prerequisite"));
            Assert.That(snapshot.OverallDescription, Does.Contain("Configure Dependencies"));
        }

        [Test]
        public void CachedUninstalledSnapshot_PreservesInstallStateWithoutLiveScan()
        {
            var seededFailure = CreateTerminalFailure();
            var clearedFailure =
                AICodedbEditorLifecycle.ResolveTerminalConvergenceFailureForProductState(
                    seededFailure,
                    AICodedbProductState.Uninstalled);
            var snapshot = AICodedbStatusSnapshot.CreateCachedState(
                "FixtureProject",
                AICodedbProductState.Uninstalled,
                false,
                AICodedbCoordinatorFailureCategory.NotEvaluated,
                clearedFailure);

            Assert.That(snapshot.IsProjectUninstalled, Is.True);
            Assert.That(snapshot.ProductStatus.State, Is.EqualTo(AICodedbProductState.Uninstalled));
            Assert.That(snapshot.OverallState, Is.EqualTo(AICodedbStatusState.Inactive));
            Assert.That(snapshot.OverallTitle, Is.EqualTo("FixtureProject · Uninstalled"));
            Assert.That(clearedFailure, Is.Null);
            Assert.That(snapshot.TerminalConvergenceFailureEvidence, Is.Null);
            Assert.That(snapshot.TerminalConvergenceFailure.Summary, Is.EqualTo("Not retained"));
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(snapshot.ProductStatus), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(snapshot.ProductStatus, false, false), Is.True);
        }

        [Test]
        public void CachedNotIntegratedSnapshot_OffersInstallWithoutCheckingOrUninstallHistory()
        {
            var snapshot = AICodedbStatusSnapshot.CreateCachedState(
                "FixtureProject", AICodedbProductState.NotIntegrated, true);

            Assert.That(snapshot.IsProjectNotIntegrated, Is.True);
            Assert.That(snapshot.IsProjectUninstalled, Is.False);
            Assert.That(snapshot.ProjectIntegrationStatus.CanInstall, Is.True);
            Assert.That(snapshot.ProjectIntegrationStatus.StateId, Is.Empty);
            Assert.That(snapshot.ProductStatus.State, Is.EqualTo(AICodedbProductState.NotIntegrated));
            Assert.That(snapshot.OverallState, Is.EqualTo(AICodedbStatusState.Inactive));
            Assert.That(snapshot.OverallTitle, Does.Contain("Not installed"));
            Assert.That(snapshot.ProductStatus.Detail, Does.Contain("Install CodeDB"));
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(snapshot.ProductStatus), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(snapshot.ProductStatus, false, false), Is.True);
        }

        [Test]
        public void CachedNeedsAttentionSnapshotRetainsTerminalEvidenceAndDoesNotClaimChecking()
        {
            var terminalFailure = CreateTerminalFailure();
            var snapshot = AICodedbStatusSnapshot.CreateCachedState(
                "FixtureProject",
                AICodedbProductState.Starting,
                true,
                AICodedbCoordinatorFailureCategory.NotEvaluated,
                terminalFailure);

            Assert.That(snapshot.ProductStatus.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(snapshot.ProductStatus.IsReady, Is.False);
            Assert.That(snapshot.OverallState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(
                snapshot.TerminalConvergenceFailureEvidence,
                Is.SameAs(terminalFailure));
            Assert.That(snapshot.TerminalConvergenceFailure.Summary, Is.EqualTo("MCP_UNAVAILABLE"));
            Assert.That(snapshot.TerminalConvergenceFailure.Detail, Does.Contain("SupervisorOperationalReadiness"));
            Assert.That(snapshot.ProductStatus.Prerequisite, Is.EqualTo(terminalFailure.ProductStatus.Prerequisite));
            Assert.That(snapshot.ProductStatus.Installed, Is.EqualTo(terminalFailure.ProductStatus.Installed));
            Assert.That(snapshot.ProductStatus.Configured, Is.EqualTo(terminalFailure.ProductStatus.Configured));
            Assert.That(snapshot.ProductStatus.McpAvailable, Is.EqualTo(AICodedbProductLayerState.Unavailable));
            Assert.That(snapshot.McpAvailability.Summary, Is.EqualTo("Unavailable"));
            Assert.That(snapshot.ProjectMcpConfig.Summary, Is.EqualTo("Current"));
            Assert.That(snapshot.HostPayloadStatus.Summary, Is.EqualTo("Needs attention"));
            Assert.That(snapshot.OverallDescription, Does.Contain("MCP_UNAVAILABLE"));
            Assert.That(snapshot.OverallDescription, Does.Not.Contain("Checking"));
        }

        [Test]
        public void CachedStartingSnapshotUsesCheckingOnlyForActiveRefresh()
        {
            var idle = AICodedbStatusSnapshot.CreateCachedState(
                "FixtureProject",
                AICodedbProductState.Starting);
            var inFlight = AICodedbStatusSnapshot.CreateCachedState(
                "FixtureProject",
                AICodedbProductState.Starting,
                true);

            Assert.That(idle.HostPayloadStatus.Summary, Is.EqualTo("Not evaluated"));
            Assert.That(idle.CurrentInstance.Summary, Is.EqualTo("Not evaluated"));
            Assert.That(inFlight.HostPayloadStatus.Summary, Is.EqualTo("Checking"));
            Assert.That(inFlight.CurrentInstance.Summary, Is.EqualTo("Checking"));
            Assert.That(inFlight.ProviderExecutable.Summary, Is.EqualTo("Checking"));
        }

        [TestCase(
            AICodedbProductAttentionReason.ControlContractReinstallRequired,
            true,
            "Reinstall required")]
        [TestCase(
            AICodedbProductAttentionReason.ControlContractInvalidOrAmbiguous,
            false,
            "Review required")]
        public void CachedMigrationStatus_ControlsReinstallAndPreservesDiagnostics(
            AICodedbProductAttentionReason attentionReason,
            bool expectedReinstall,
            string expectedSummary)
        {
            var status = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                "migration detail",
                default(AICodedbMaterializerCommandStatus),
                attentionReason,
                "migration diagnostic",
                expectedReinstall);
            var snapshot = AICodedbStatusSnapshot.CreateCachedStatus("FixtureProject", status);

            Assert.That(snapshot.ProductStatus.AttentionReason, Is.EqualTo(attentionReason));
            Assert.That(snapshot.ControlContractMigration.Summary, Is.EqualTo(expectedSummary));
            Assert.That(snapshot.ControlContractMigration.Detail, Is.EqualTo("migration diagnostic"));
            Assert.That(
                AICodedbManagerWindow.ResolvePrimaryAction(snapshot.ProductStatus, true, false),
                Is.EqualTo(expectedReinstall));
        }

        [Test]
        public void UninstalledState_KeepsInstallAsTheOnlyProjectAction()
        {
            var status = AICodedbProductStatusBuilder.Build(
                new AICodedbProjectIntegrationStatus(
                    AICodedbProjectIntegrationState.Uninstalled,
                    AICodedbProjectCleanupState.Complete,
                    string.Empty,
                    "uninstalled"),
                new AICodedbCommandResult(
                    0,
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n" +
                    "[PRODUCT_STATE] UNINSTALLED\n",
                    string.Empty,
                    false));

            Assert.That(status.State, Is.EqualTo(AICodedbProductState.Uninstalled));
            Assert.That(AICodedbManagerWindow.ShouldShowPersistentDependencyAction(status), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status, false, false), Is.True);
        }

        private static AICodedbEditorLifecycle.AICodedbTerminalConvergenceFailure CreateTerminalFailure()
        {
            var root = AICodedbPaths.ProjectRoot;
            var contract = AICodedbPackageRuntimeContractStore.Read(AICodedbPaths.PackageRootPath);
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var supervisor = AICodedbSupervisorSnapshot.Connected(
                AICodedbSupervisorProtocol.CoordinatorStateSchemaVersion,
                1234,
                "manager-test",
                runtime,
                "ready",
                string.Empty,
                "disabled",
                "disabled",
                "enabled",
                "online",
                AICodedbSupervisorReadinessState.Degraded,
                "MCP_UNAVAILABLE",
                "sanitized terminal observation",
                "provider_ready",
                AICodedbSupervisorProtocol.SupervisorStateSchemaVersion,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                1234,
                "0123456789abcdef0123456789abcdef",
                AICodedbCoordinatorFailureCategory.None,
                1,
                "11111111111111111111111111111111",
                7,
                "manager-supervisor",
                "abcdefabcdefabcdefabcdefabcdefab");
            var status = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Unavailable,
                "MCP handshake unavailable.",
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.None,
                "MCP layer did not become current.");
            var result = new AICodedbCommandResult(
                4,
                "[COMMAND_RESULT] {\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\",\"action\":\"UPGRADE\",\"outcome\":\"BLOCKED\",\"phase\":\"VERIFY\",\"reason_code\":\"MCP_UNAVAILABLE\",\"mutated_scopes\":[],\"cleanup_state\":\"COMPLETE\",\"next_action\":\"Review the authenticated terminal evidence.\",\"exit_code\":4,\"detail\":\"MCP unavailable.\"}",
                "MCP unavailable.",
                false);
            AICodedbEditorLifecycle.AICodedbTerminalConvergenceFailure failure;
            Assert.That(
                AICodedbEditorLifecycle.TryCreateTerminalConvergenceFailure(
                    status,
                    result,
                    supervisor,
                    out failure),
                Is.True);
            return failure;
        }

        private static AICodedbCommandResult Result(string output)
        {
            return new AICodedbCommandResult(0, output, string.Empty, false);
        }
    }

    internal sealed class AICodedbControlContractMigrationClassifierTests
    {
        private static readonly AICodedbControlContractIdentity Contract =
            AICodedbControlContract.CreateDefaultIdentity();

        private string _projectRoot;
        private string _packageRoot;

        [SetUp]
        public void SetUp()
        {
            _projectRoot = Path.Combine(
                Path.GetTempPath(),
                "Rice-AICodedb-ControlContract-Tests",
                Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Assets"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Packages"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "ProjectSettings"));
            _packageRoot = AICodedbPaths.PackageRootPath;
        }

        [TearDown]
        public void TearDown()
        {
            if (Directory.Exists(_projectRoot))
                Directory.Delete(_projectRoot, true);
        }

        [Test]
        public void Read_RecognizesCompleteLegacyStateAndLock()
        {
            var fixture = CreateLegacyEvidence();
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            Assert.That(
                status.State,
                Is.EqualTo(AICodedbControlContractMigrationState.ObsoleteReinstallRequired));
            Assert.That(status.RequiresReinstall, Is.True);
            Assert.That(status.BlocksAutomaticStart, Is.True);
        }

        [Test]
        public void Read_RejectsSignatureOnlyLegacyEvidence()
        {
            var fixture = CreateLegacyEvidence();
            var signatureOnly = new Dictionary<string, object>(StringComparer.Ordinal)
            {
                { "schema_version", 3 },
                { "managed_by", "com.rice.ai-codedb" },
                { "role", "project-local-supervisor" },
                { "root", fixture.State["root"] },
                { "runtime", fixture.State["runtime"] },
                { "pipe_name", fixture.State["pipe_name"] }
            };
            fixture.State = CloneDocument(signatureOnly);
            fixture.Lock = CloneDocument(signatureOnly);
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsStateOnlyLegacyEvidence()
        {
            var fixture = CreateLegacyEvidence();
            PublishEvidence(fixture, true, false);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsLockOnlyLegacyEvidence()
        {
            var fixture = CreateLegacyEvidence();
            PublishEvidence(fixture, false, true);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsMissingStateOrLockSpecificFields()
        {
            var stateFixture = CreateLegacyEvidence();
            stateFixture.State.Remove("desired_state");
            PublishEvidence(stateFixture);
            AssertInvalid(
                AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot));

            TearDownFixtureRoot();
            CreateFixtureRoot();
            var lockFixture = CreateLegacyEvidence();
            lockFixture.Lock.Remove("owner_started_at_utc");
            PublishEvidence(lockFixture);
            AssertInvalid(
                AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot));
        }

        [Test]
        public void Read_RejectsWrongLegacyPathIdentity()
        {
            var fixture = CreateLegacyEvidence();
            var wrongRuntime = AICodedbPaths.NormalizePath(
                Path.Combine(_projectRoot, "AIWork", ".runtime", "codedb", "other-runtime"));
            fixture.State["runtime"] = wrongRuntime;
            fixture.Lock["runtime"] = wrongRuntime;
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsDirectoryInEvidencePath()
        {
            var fixture = CreateLegacyEvidence();
            Directory.CreateDirectory(fixture.RuntimePath);
            Directory.CreateDirectory(Path.Combine(fixture.RuntimePath, "supervisor-state.json"));
            WriteJson(
                Path.Combine(fixture.RuntimePath, "supervisor.lock"),
                fixture.Lock);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsMalformedLegacyJson()
        {
            var fixture = CreateLegacyEvidence();
            Directory.CreateDirectory(fixture.RuntimePath);
            WriteUtf8NoBom(
                Path.Combine(fixture.RuntimePath, "supervisor-state.json"),
                "{\"schema_version\":3");
            WriteJson(
                Path.Combine(fixture.RuntimePath, "supervisor.lock"),
                fixture.Lock);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsStateLockOwnerConflict()
        {
            var fixture = CreateLegacyEvidence();
            fixture.Lock["owner_epoch"] = "different-owner-epoch";
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsStateSpecificFieldOnLegacyLock()
        {
            var fixture = CreateLegacyEvidence();
            fixture.Lock["desired_state"] = "enabled";
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsUnknownLegacyFieldWithoutCurrentNamespace()
        {
            var fixture = CreateLegacyEvidence();
            fixture.State["unexpected_legacy_field"] = "must be rejected";
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsLegacyCurrentContractLookalike()
        {
            var fixture = CreateLegacyEvidence();
            foreach (var document in new[] { fixture.State, fixture.Lock })
            {
                document["control_contract_id"] = Contract.Id;
                document["control_contract_version"] = Contract.Version;
                document["control_contract_schema_version"] = Contract.SchemaVersion;
                document["control_contract_sha256"] = Contract.Sha256;
                document["control_namespace"] = fixture.RuntimePath;
            }
            PublishEvidence(fixture);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        [Test]
        public void Read_RejectsAuthenticatedCurrentResultWhenLegacyEvidenceIsMalformed()
        {
            var current = CreateCurrentEvidence();
            PublishEvidence(current);

            var legacy = CreateLegacyEvidence();
            legacy.State["unexpected_legacy_field"] = "must be rejected";
            PublishEvidence(legacy);

            var status = AICodedbControlContractMigrationStore.Read(_projectRoot, _packageRoot);

            AssertInvalid(status);
        }

        private sealed class EvidenceFixture
        {
            internal string RuntimePath;
            internal Dictionary<string, object> State;
            internal Dictionary<string, object> Lock;
        }

        private EvidenceFixture CreateLegacyEvidence()
        {
            var runtimePath = AICodedbControlContract.GetLegacySupervisorRuntimePath(_projectRoot);
            string pipeName;
            Assert.That(
                AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                    _projectRoot,
                    runtimePath,
                    out pipeName),
                Is.True);

            var root = AICodedbPaths.NormalizePath(_projectRoot).TrimEnd('/', '\\');
            var ownerEvidence = new Dictionary<string, object>(StringComparer.Ordinal)
            {
                { "schema_version", 1 },
                { "pid", 424242 },
                { "process_start_identity", "638000000000000000" },
                { "executable_path", Path.Combine(_projectRoot, "legacy-node.exe") },
                { "argv_sha256", new string('b', 64) },
                { "command_line_sha256", new string('c', 64) }
            };
            var common = new Dictionary<string, object>(StringComparer.Ordinal)
            {
                { "schema_version", 3 },
                { "evidence_schema_version", 1 },
                { "managed_by", "com.rice.ai-codedb" },
                { "role", "project-local-supervisor" },
                { "root", root },
                { "project_identity", AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot) },
                { "runtime", runtimePath },
                { "pipe_name", "\\\\.\\pipe\\" + pipeName },
                { "generation_id", "poc.34" },
                { "target_generation_id", "poc.34" },
                { "selected_generation_id", "poc.34" },
                { "selected_instance_id", "0123456789abcdef0123456789abcdef" },
                { "runtime_contract_sha256", new string('a', 64) },
                { "supervisor_protocol_version", 2 },
                { "generation_disposition", "CURRENT" },
                { "lifecycle_id", "legacy-lifecycle" },
                { "supervisor_id", "legacy-supervisor" },
                { "owner_epoch", "legacy-owner-epoch" },
                { "owner_evidence", ownerEvidence },
                { "supervisor_pid", 424242 },
                { "publication_phase", "listening" },
                { "owner_started_at_utc", "2026-08-31T00:00:00.0000000Z" }
            };
            var state = CloneDocument(common);
            state.Add("protocol_version", 1);
            state.Add("auth_token", new string('d', 64));
            state.Add("desired_state", "enabled");
            state.Add("editor_demand", "online");
            state.Add("readiness_state", "starting");
            state.Add("reason_code", "SUPERVISOR_STARTING");
            state.Add("detail", "synthetic legacy state");
            state.Add("last_event", "");
            state.Add("last_event_detail", "");
            state.Add("started_at_utc", "2026-08-31T00:00:01.0000000Z");
            state.Add("operation", null);
            state.Add("event_sequence", 0);
            state.Add("coordinator_status", null);
            state.Add("updated_at_utc", "2026-08-31T00:00:01.0000000Z");

            return new EvidenceFixture
            {
                RuntimePath = runtimePath,
                State = state,
                Lock = CloneDocument(common)
            };
        }

        private EvidenceFixture CreateCurrentEvidence()
        {
            var runtimeContract = AICodedbPackageRuntimeContractStore.Read(_packageRoot);
            var target = runtimeContract.Target;
            var packageGenerationRoot = Path.Combine(
                _packageRoot,
                "Payload~",
                "Generations",
                target.GenerationId);
            var generationRoot = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                target.GenerationId);
            CopyDirectory(packageGenerationRoot, generationRoot);

            var wrapperRelativePath = AICodedbPackageRuntimeContractStore.StableWrapperRelativePath
                .Replace('/', Path.DirectorySeparatorChar);
            var sourceWrapper = Path.Combine(_packageRoot, "Payload~", wrapperRelativePath);
            var targetWrapper = Path.Combine(_projectRoot, wrapperRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(targetWrapper));
            File.Copy(sourceWrapper, targetWrapper, true);

            var instanceId = "fedcba98765432100123456789abcdef";
            var instanceRelativePath = AICodedbProjectSettings.InstancesRelativePath + "/" + instanceId;
            var instanceRoot = Path.Combine(
                _projectRoot,
                instanceRelativePath.Replace('/', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(instanceRoot);

            var generationRelativePath = AICodedbProjectSettings.HostGenerationsRelativePath
                                         + "/"
                                         + target.GenerationId;
            var generationManifestPath = Path.Combine(generationRoot, "generation-manifest.json");
            var workerRelativePath = "wrapper/codedb-project-instance-worker.mjs";
            var workerPath = Path.Combine(
                generationRoot,
                workerRelativePath.Replace('/', Path.DirectorySeparatorChar));
            var generationManifestHash = HashFile(generationManifestPath);
            var workerHash = HashFile(workerPath);
            var projectIdentity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            var instanceManifestPath = Path.Combine(instanceRoot, "instance.json");
            const string activationEpoch = "0123456789abcdef0123456789abcdef";
            WriteJson(
                instanceManifestPath,
                new Dictionary<string, object>(StringComparer.Ordinal)
                {
                    { "schema_version", 1 },
                    { "managed_by", "com.rice.ai-codedb" },
                    { "project_identity", projectIdentity },
                    { "instance_id", instanceId },
                    { "instance_relative_path", instanceRelativePath },
                    { "state", "READY" },
                    { "package_version", target.PackageVersion },
                    { "payload_version", target.PayloadVersion },
                    { "payload_sequence", target.PayloadSequence },
                    { "generation_id", target.GenerationId },
                    { "generation_relative_path", generationRelativePath },
                    { "generation_manifest_sha256", generationManifestHash },
                    { "bootstrap_protocol", target.BootstrapProtocol },
                    { "worker_relative_path", workerRelativePath },
                    { "worker_sha256", workerHash },
                    { "created_at_utc", "2026-08-31T00:00:00.0000000Z" },
                    { "verified_at_utc", "2026-08-31T00:00:01.0000000Z" }
                });
            var instancePointerPath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.InstanceCurrentRelativePath.Replace('/', Path.DirectorySeparatorChar));
            WriteJson(
                instancePointerPath,
                new Dictionary<string, object>(StringComparer.Ordinal)
                {
                    { "schema_version", 1 },
                    { "managed_by", "com.rice.ai-codedb" },
                    { "project_identity", projectIdentity },
                    { "instance_id", instanceId },
                    { "instance_relative_path", instanceRelativePath },
                    { "instance_manifest_sha256", HashFile(instanceManifestPath) },
                    { "generation_id", target.GenerationId },
                    { "owner_identity_version", AICodedbPackageRuntimeContract.CurrentOwnerIdentityVersion },
                    { "activation_epoch", activationEpoch },
                    { "activated_at_utc", "2026-08-31T00:00:02.0000000Z" }
                });

            var runtimePath = AICodedbControlContract.GetSupervisorRuntimePath(
                _projectRoot,
                runtimeContract.ControlContract);
            string pipeName;
            Assert.That(
                AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                    _projectRoot,
                    runtimePath,
                    out pipeName),
                Is.True);
            var ownerEvidence = new Dictionary<string, object>(StringComparer.Ordinal)
            {
                { "schema_version", 1 },
                { "pid", int.MaxValue },
                { "process_start_identity", "638000000000000001" },
                { "executable_path", Path.Combine(_projectRoot, "current-node.exe") },
                { "argv_sha256", new string('e', 64) },
                { "command_line_sha256", new string('f', 64) }
            };
            var common = new Dictionary<string, object>(StringComparer.Ordinal)
            {
                { "schema_version", 3 },
                { "evidence_schema_version", 1 },
                { "protocol_version", 1 },
                { "role", "project-local-supervisor" },
                { "managed_by", "com.rice.ai-codedb" },
                { "root", AICodedbPaths.NormalizePath(_projectRoot).TrimEnd('/', '\\') },
                { "project_identity", projectIdentity },
                { "runtime", runtimePath },
                { "control_contract_id", runtimeContract.ControlContract.Id },
                { "control_contract_version", runtimeContract.ControlContract.Version },
                { "control_contract_schema_version", runtimeContract.ControlContract.SchemaVersion },
                { "control_contract_sha256", runtimeContract.ControlContract.Sha256 },
                { "control_namespace", runtimePath },
                { "owner_identity_version", AICodedbPackageRuntimeContract.CurrentOwnerIdentityVersion },
                { "activation_epoch", activationEpoch },
                { "pipe_name", "\\\\.\\pipe\\" + pipeName },
                { "generation_id", target.GenerationId },
                { "target_generation_id", target.GenerationId },
                { "selected_generation_id", target.GenerationId },
                { "selected_instance_id", instanceId },
                { "runtime_contract_sha256", runtimeContract.Sha256 },
                { "supervisor_protocol_version", AICodedbSupervisorProtocol.SupervisorVersion },
                { "generation_disposition", "CURRENT" },
                { "lifecycle_id", "unity-bridge" },
                { "supervisor_id", "unity-bridge" },
                { "owner_epoch", "current-owner-epoch" },
                { "owner_evidence", ownerEvidence },
                { "supervisor_pid", int.MaxValue },
                { "publication_phase", "listening" },
                { "owner_started_at_utc", "2026-08-31T00:00:00.0000000Z" }
            };
            var state = CloneDocument(common);
            state["auth_token"] = new string('1', 64);
            state["desired_state"] = "enabled";
            state["editor_demand"] = "online";
            state["readiness_state"] = "starting";
            state["reason_code"] = "SUPERVISOR_STARTING";
            state["detail"] = "synthetic current state";
            state["last_event"] = "";
            state["last_event_detail"] = "";

            return new EvidenceFixture
            {
                RuntimePath = runtimePath,
                State = state,
                Lock = CloneDocument(common)
            };
        }

        private void PublishEvidence(
            EvidenceFixture fixture,
            bool writeState = true,
            bool writeLock = true)
        {
            Directory.CreateDirectory(fixture.RuntimePath);
            if (writeState)
                WriteJson(
                    Path.Combine(fixture.RuntimePath, "supervisor-state.json"),
                    fixture.State);
            if (writeLock)
                WriteJson(
                    Path.Combine(fixture.RuntimePath, "supervisor.lock"),
                    fixture.Lock);
        }

        private void CreateFixtureRoot()
        {
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Assets"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Packages"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "ProjectSettings"));
        }

        private void TearDownFixtureRoot()
        {
            if (Directory.Exists(_projectRoot))
                Directory.Delete(_projectRoot, true);
        }

        private static void AssertInvalid(AICodedbControlContractMigrationStatus status)
        {
            Assert.That(
                status.State,
                Is.EqualTo(AICodedbControlContractMigrationState.InvalidOrAmbiguous));
        }

        private static Dictionary<string, object> CloneDocument(
            Dictionary<string, object> source)
        {
            var result = new Dictionary<string, object>(StringComparer.Ordinal);
            foreach (var pair in source)
            {
                var nested = pair.Value as Dictionary<string, object>;
                result.Add(
                    pair.Key,
                    nested == null ? pair.Value : CloneDocument(nested));
            }
            return result;
        }

        private static void CopyDirectory(string sourceRoot, string targetRoot)
        {
            Assert.That(Directory.Exists(sourceRoot), Is.True, sourceRoot);
            Directory.CreateDirectory(targetRoot);
            foreach (var sourceDirectory in Directory.GetDirectories(
                         sourceRoot,
                         "*",
                         SearchOption.AllDirectories))
            {
                var relative = sourceDirectory.Substring(sourceRoot.Length).TrimStart(
                    Path.DirectorySeparatorChar,
                    Path.AltDirectorySeparatorChar);
                Directory.CreateDirectory(Path.Combine(targetRoot, relative));
            }
            foreach (var sourceFile in Directory.GetFiles(
                         sourceRoot,
                         "*",
                         SearchOption.AllDirectories))
            {
                var relative = sourceFile.Substring(sourceRoot.Length).TrimStart(
                    Path.DirectorySeparatorChar,
                    Path.AltDirectorySeparatorChar);
                var targetFile = Path.Combine(targetRoot, relative);
                Directory.CreateDirectory(Path.GetDirectoryName(targetFile));
                File.Copy(sourceFile, targetFile, true);
            }
        }

        private static string HashFile(string path)
        {
            using (var stream = File.OpenRead(path))
            using (var sha256 = SHA256.Create())
            {
                return BitConverter.ToString(sha256.ComputeHash(stream))
                    .Replace("-", string.Empty)
                    .ToLowerInvariant();
            }
        }

        private static void WriteJson(string path, Dictionary<string, object> value)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            WriteUtf8NoBom(path, SerializeObject(value) + "\n");
        }

        private static void WriteUtf8NoBom(string path, string value)
        {
            File.WriteAllText(path, value, new UTF8Encoding(false));
        }

        internal static string SerializeObject(Dictionary<string, object> value)
        {
            var keys = new List<string>(value.Keys);
            keys.Sort(StringComparer.Ordinal);
            var builder = new StringBuilder("{");
            for (var index = 0; index < keys.Count; index++)
            {
                if (index > 0)
                    builder.Append(',');
                var key = keys[index];
                builder.Append('"').Append(EscapeJson(key)).Append("\":");
                builder.Append(SerializeValue(value[key]));
            }
            return builder.Append('}').ToString();
        }

        private static string SerializeValue(object value)
        {
            if (value == null)
                return "null";
            var text = value as string;
            if (text != null)
                return "\"" + EscapeJson(text) + "\"";
            if (value is bool)
                return (bool)value ? "true" : "false";
            if (value is int || value is long)
                return Convert.ToString(value, CultureInfo.InvariantCulture);
            if (value is string[] strings)
                return "[" + string.Join(",", Array.ConvertAll(strings, item => SerializeValue(item))) + "]";
            if (value is List<object> items)
                return "[" + string.Join(",", items.ConvertAll(SerializeValue)) + "]";
            var objectValue = value as Dictionary<string, object>;
            if (objectValue != null)
                return SerializeObject(objectValue);
            throw new InvalidOperationException("Unsupported fixture JSON value: " + value.GetType());
        }

        private static string EscapeJson(string value)
        {
            var builder = new StringBuilder(value.Length);
            foreach (var character in value)
            {
                switch (character)
                {
                    case '"': builder.Append("\\\""); break;
                    case '\\': builder.Append("\\\\"); break;
                    case '\b': builder.Append("\\b"); break;
                    case '\f': builder.Append("\\f"); break;
                    case '\n': builder.Append("\\n"); break;
                    case '\r': builder.Append("\\r"); break;
                    case '\t': builder.Append("\\t"); break;
                    default:
                        if (character < 0x20)
                        {
                            builder.Append("\\u").Append(
                                ((int)character).ToString("x4", CultureInfo.InvariantCulture));
                        }
                        else
                        {
                            builder.Append(character);
                        }
                        break;
                }
            }
            return builder.ToString();
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

        [Test]
        public void UserActionStatus_KeepsRunningActionInActivityPanelAndOutOfHeader()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Configure CodeDB Dependencies", 10d);

            var presentation = status.BuildPresentation(13.25d);

            Assert.That(presentation.IsVisible, Is.False,
                "Running progress belongs in the Last activity panel, not the full-width Manager header.");
            Assert.That(presentation.IsRunning, Is.True);
            Assert.That(presentation.StatusLabel, Is.EqualTo("In progress"));
            Assert.That(presentation.Detail, Does.Contain("Configure CodeDB Dependencies is running"));
            Assert.That(presentation.ElapsedText, Is.EqualTo("3.3 s"));
            Assert.That(presentation.ButtonLabel, Is.EqualTo("Configuring..."));
        }

        [Test]
        public void UserActionStatus_RepeatedViewRendersDoNotResetRunningAction()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Configure CodeDB Dependencies", 10d);

            var beforeViewChange = status.BuildPresentation(11d);
            var afterViewChange = status.BuildPresentation(12d);

            Assert.That(status.Phase, Is.EqualTo(AICodedbUserActionPhase.Running));
            Assert.That(status.Title, Is.EqualTo("Configure CodeDB Dependencies"));
            Assert.That(beforeViewChange.StatusLabel, Is.EqualTo(afterViewChange.StatusLabel));
            Assert.That(afterViewChange.ElapsedText, Is.EqualTo("2.0 s"));
        }

        [Test]
        public void UserActionStatus_TracksProviderStageProgressAcrossRenders()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Configure CodeDB Dependencies", 10d);

            Assert.That(status.UpdateProgressLine("[PROVIDER_STAGE] 2/6 Downloading the Provider package and signature"), Is.True);
            var presentation = status.BuildPresentation(11d);

            Assert.That(presentation.HasProgress, Is.True);
            Assert.That(presentation.ProgressValue, Is.EqualTo(1f / 3f).Within(0.0001f));
            Assert.That(presentation.ProgressLabel, Is.EqualTo("Stage 2 of 6: Downloading the Provider package and signature"));
            Assert.That(presentation.Detail, Is.EqualTo(presentation.ProgressLabel));
            Assert.That(status.UpdateProgressLine("[PROVIDER_STAGE] invalid"), Is.False);
            Assert.That(status.BuildPresentation(12d).ProgressLabel, Is.EqualTo(presentation.ProgressLabel));
        }

        [Test]
        public void UserActionStatus_DistinguishesCompletedCommandFromNeedsAttentionProduct()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Configure CodeDB Dependencies", 10d);
            status.SetProgress(6, 6, "Rechecking CodeDB readiness");
            status.Complete(
                new AICodedbCommandResult(0, string.Empty, string.Empty, false, 1250),
                AICodedbProductState.NeedsAttention,
                true,
                11.25d);

            var presentation = status.BuildPresentation(11.25d);

            Assert.That(presentation.IsVisible, Is.False,
                "Completed actions stay in Last activity instead of occupying the live Header status row.");
            Assert.That(presentation.HasProgress, Is.False,
                "Terminal completion must not retain a completed progress bar.");
            Assert.That(presentation.IsRunning, Is.False);
            Assert.That(presentation.State, Is.EqualTo(AICodedbStatusState.Warning));
            Assert.That(presentation.StatusLabel, Is.EqualTo("Completed - needs attention"));
            Assert.That(presentation.Detail, Does.Contain("still needs attention"));
            Assert.That(presentation.NotificationText, Does.Contain("still needs attention"));

            status.UpdateProductState(AICodedbProductState.Ready);
            var converged = status.BuildPresentation(12d);
            Assert.That(converged.State, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(converged.StatusLabel, Is.EqualTo("Completed"));
            Assert.That(converged.Detail, Does.Contain("CodeDB is ready"));
        }

        [Test]
        public void UserActionStatus_LaterAuthoritativeObservationClearsStatusUnavailable()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Refresh Index", 1d);
            status.Complete(new AICodedbCommandResult(0, "done", string.Empty, false),
                AICodedbProductState.Starting, false, 2d);
            Assert.That(status.BuildPresentation(2d).StatusLabel,
                Is.EqualTo("Completed - status unavailable"));

            status.UpdateProductState(AICodedbProductState.Ready);
            Assert.That(status.BuildPresentation(3d).StatusLabel, Is.EqualTo("Completed"));
            Assert.That(status.BuildPresentation(3d).Detail, Does.Contain("CodeDB is ready"));
        }

        [Test]
        public void UserActionStatus_FailedActionRetainsFailureAndClearHidesIt()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Install CodeDB", 4d);
            status.SetProgress(6, 6, "Rechecking CodeDB readiness");
            status.Complete(
                new AICodedbCommandResult(7, string.Empty, "provider unavailable", false),
                AICodedbProductState.NeedsAttention,
                true,
                5d);

            var failed = status.BuildPresentation(5d);
            Assert.That(failed.IsVisible, Is.False,
                "Failed actions stay in Last activity instead of looking active in the Header.");
            Assert.That(failed.HasProgress, Is.False,
                "Terminal failures must not retain a completed progress bar.");
            Assert.That(failed.State, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(failed.StatusLabel, Is.EqualTo("Failed"));
            Assert.That(failed.Detail, Is.EqualTo("provider unavailable"));

            status.Clear();
            var cleared = status.BuildPresentation(6d);
            Assert.That(cleared.IsVisible, Is.False);
        }

        [Test]
        public void UserActionStatus_MissingCommandResultIsVisibleAsFailure()
        {
            var status = new AICodedbUserActionStatus();
            status.Start("Host Payload Verify", 1d);
            status.Complete(null, AICodedbProductState.NeedsAttention, false, 2d);

            var presentation = status.BuildPresentation(2d);
            Assert.That(presentation.State, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(presentation.Detail, Is.EqualTo("The command did not return a result."));
            var panelSource = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath, "Editor", "AICodedbActivityPanel.cs"));
            Assert.That(panelSource, Does.Contain("else if (userAction.State == AICodedbStatusState.Error)"));
        }

        [Test]
        public void UserFacingReinstallActivity_HidesGenerationAndExitDetails()
        {
            var summary = AICodedbActivitySummaryBuilder.Build(
                "Reinstall CodeDB",
                new AICodedbCommandResult(
                    0,
                    "[INSTALLING] Published immutable generation poc.33.\n" +
                    "[PRODUCT_STATE] READY\n" +
                    "[COMMAND_RESULT] {\"schema_version\":1}",
                    string.Empty,
                    false,
                    11140));

            Assert.That(summary.State, Is.EqualTo(AICodedbStatusState.Ok));
            Assert.That(summary.StatusLabel, Is.EqualTo("Ready"));
            Assert.That(summary.Detail, Is.EqualTo("CodeDB is ready for this project."));
            Assert.That(summary.Detail, Does.Not.Contain("poc.33"));
            Assert.That(summary.Detail, Does.Not.Contain("COMMAND_RESULT"));
        }

        [Test]
        public void UserFacingActivity_ReducesNeedsAttentionToOneNextStep()
        {
            var summary = AICodedbActivitySummaryBuilder.Build(
                "Reinstall CodeDB",
                new AICodedbCommandResult(
                    0,
                    "[PRODUCT_STATE] NEEDS_ATTENTION\n[COMMAND_RESULT] {\"detail\":\"internal\"}",
                    string.Empty,
                    false));

            Assert.That(summary.State, Is.EqualTo(AICodedbStatusState.Warning));
            Assert.That(summary.StatusLabel, Is.EqualTo("Needs attention"));
            Assert.That(summary.Detail, Is.EqualTo(
                "CodeDB needs attention. Use Reinstall CodeDB to try again."));
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

        [Test]
        public void Build_MapsLayeredNeedsAttentionInsteadOfUnrecognizedResult()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                true,
                Result(
                    "[PRODUCT_LAYER INSTALLED] CURRENT\n" +
                    "[PRODUCT_LAYER CONFIGURED] CURRENT\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE\n" +
                    "[PRODUCT_STATE] NEEDS_ATTENTION\n" +
                    "[DETAIL] Selected instance coordinator is not operational.\n" +
                    "[INSTANCE] fixture-instance\n" +
                    "[CLEANUP_STATE] PENDING"));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Blocked));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
            Assert.That(status.Summary, Is.EqualTo("NEEDS_ATTENTION"));
            Assert.That(status.Detail, Is.EqualTo("[DETAIL] Selected instance coordinator is not operational."));
        }

        [Test]
        public void Build_MapsLayeredMissingPrerequisiteClearly()
        {
            var status = AICodedbHostPayloadStatusBuilder.Build(
                false,
                Result(
                    "[PRODUCT_LAYER PREREQUISITE] MISSING\n" +
                    "[PRODUCT_LAYER INSTALLED] MISSING\n" +
                    "[PRODUCT_LAYER CONFIGURED] MISSING\n" +
                    "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE\n" +
                    "[PRODUCT_STATE] MISSING_PREREQUISITE\n" +
                    "[PREREQUISITE] CodeDB Provider is missing."));

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.SetupRequired));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Warning));
            Assert.That(status.Summary, Is.EqualTo("MISSING_PREREQUISITE"));
            Assert.That(status.Detail, Is.EqualTo("[PREREQUISITE] CodeDB Provider is missing."));
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
        public void PackageProviderInstallerAuthorization_AcceptsExactExternalLocalPackageScript()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                Directory.CreateDirectory(Path.Combine(packageRoot, "Tools~"));
                var scriptPath = Path.Combine(packageRoot, AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath);
                File.WriteAllText(scriptPath, "Write-Output 'fixture'", Encoding.UTF8);
                string authorizedPath;
                string error;

                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageProviderInstallerScriptPath(
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
        public void PackageProviderInstallerAuthorization_RejectsOtherExternalScript()
        {
            var fixtureRoot = CreateExternalPackageFixture();
            try
            {
                var packageRoot = Path.Combine(fixtureRoot, "com.rice.ai-codedb");
                Directory.CreateDirectory(Path.Combine(packageRoot, "Tools~"));
                var installerPath = Path.Combine(packageRoot, AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath);
                var otherPath = Path.Combine(packageRoot, "Tools~", "other-provider.ps1");
                File.WriteAllText(installerPath, "Write-Output 'fixture'", Encoding.UTF8);
                File.WriteAllText(otherPath, "throw 'must not run'", Encoding.UTF8);
                string authorizedPath;
                string error;

                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageProviderInstallerScriptPath(
                    packageRoot,
                    otherPath,
                    out authorizedPath,
                    out error);

                Assert.That(authorized, Is.False);
                Assert.That(authorizedPath, Is.Empty);
                Assert.That(error, Does.Contain("other than the resolved CodeDB Package Provider installer"));
            }
            finally
            {
                DeleteFixtureDirectory(fixtureRoot);
            }
        }

        [Test]
        public void PackageProviderInstallerAuthorization_RejectsReparseToolsDirectory()
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
                    Path.Combine(externalToolsRoot, "install-codedb-provider.ps1"),
                    "Write-Output 'must not run'",
                    Encoding.UTF8);
                toolsJunction = Path.Combine(packageRoot, "Tools~");
                CreateDirectoryJunction(toolsJunction, externalToolsRoot);
                string authorizedPath;
                string error;

                var authorized = AICodedbProcessRunner.TryValidateResolvedPackageProviderInstallerScriptPath(
                    packageRoot,
                    Path.Combine(toolsJunction, "install-codedb-provider.ps1"),
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
        [TestCase(AICodedbHostPayloadAction.Reinstall, true)]
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
        [TestCase(AICodedbHostPayloadAction.Reinstall)]
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
            Assert.That(result.StandardError, Does.Contain("Redeploy, Repair, Sync, Remove, Uninstall, Install, and Reinstall require second-level project mutation confirmation."));
        }

        [Test]
        public void RunHostPayloadRedeploy_RejectsMissingConfirmationBeforePreflight()
        {
            var result = AICodedbActions.RunHostPayloadRedeploy(false);

            Assert.That(result.Succeeded, Is.False);
            Assert.That(result.StandardError, Does.Contain("Redeploy, Repair, Sync, Remove, Uninstall, Install, and Reinstall require second-level project mutation confirmation."));
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
        [TestCase(AICodedbHostPayloadAction.Reinstall, "Reinstall")]
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
        [Test]
        public void MissingRemovalStatus_DoesNotOfferProjectMutation()
        {
            var status = default(AICodedbProductStatus);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(status, false), Is.False);
            Assert.That(AICodedbManagerWindow.IsRemoveIntegrationMenuAvailable(status), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(status, false, false), Is.False);
        }

        [Test]
        public void RemoveIntegrationPreflight_RequiresOneSuccessfulExactMarker()
        {
            var projectRoot = Path.Combine(Path.GetTempPath(), "codedb-preflight-" + Guid.NewGuid().ToString("N"));
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.RemoveIntegrationPreflight, false, projectRoot);
            Assert.That(arguments, Is.EqualTo(new[] { "-Action", "RemoveIntegrationPreflight", "-ProjectRoot", projectRoot }));
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(
                new AICodedbCommandResult(0, "[REMOVAL_PREFLIGHT] AVAILABLE\n", string.Empty, false)), Is.True);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(
                new AICodedbCommandResult(4, "[REMOVAL_PREFLIGHT] AVAILABLE\n", "blocked", false)), Is.False);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(
                new AICodedbCommandResult(0, "[REMOVAL_PREFLIGHT] AVAILABLE\n[REMOVAL_PREFLIGHT] AVAILABLE\n", string.Empty, false)), Is.False);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(
                new AICodedbCommandResult(0, "[REMOVAL_PREFLIGHT] BLOCKED\n", string.Empty, false)), Is.False);
        }

        [Test]
        public void UninstallPreflight_UsesReadOnlyActionAndGatesIndependentAdmission()
        {
            var projectRoot = Path.Combine(Path.GetTempPath(), "codedb-preflight-" + Guid.NewGuid().ToString("N"));
            var arguments = AICodedbHostPayloadMaterializer.BuildScriptArguments(
                AICodedbHostPayloadAction.UninstallPreflight, false, projectRoot);
            Assert.That(arguments, Is.EqualTo(new[] { "-Action", "UninstallPreflight", "-ProjectRoot", projectRoot }));

            AICodedbProductStatus Status(bool available) => new AICodedbProductStatus(
                AICodedbProductState.Ready,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                string.Empty,
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.None,
                string.Empty,
                available);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(Status(true), false), Is.True);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(Status(false), false), Is.False);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(Status(true), true), Is.False);
            Assert.That(AICodedbManagerWindow.IsRemoveIntegrationMenuAvailable(Status(true)), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(Status(true), true, false), Is.False);

            var needsAttention = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                string.Empty,
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.None,
                string.Empty,
                true);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(needsAttention, false), Is.True);
            Assert.That(AICodedbManagerWindow.IsRemoveIntegrationMenuAvailable(needsAttention), Is.False);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(needsAttention, true, false), Is.True);

            var needsReinstall = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                string.Empty,
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.InstanceIdentityReinstallRequired,
                string.Empty,
                true);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(needsReinstall, false), Is.False);
            Assert.That(AICodedbManagerWindow.IsRemoveIntegrationMenuAvailable(needsReinstall), Is.True);
            Assert.That(AICodedbManagerWindow.ResolvePrimaryAction(needsReinstall, true, false), Is.True);

            var ambiguous = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                string.Empty,
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.ControlContractInvalidOrAmbiguous,
                string.Empty,
                true);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(ambiguous, false), Is.False);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(
                AICodedbManagerWindow.ResolveRemovalPresentationStatus(Status(false), Status(true), true), false), Is.True);
            Assert.That(AICodedbManagerWindow.IsUninstallAvailable(
                AICodedbManagerWindow.ResolveRemovalPresentationStatus(Status(false), Status(true), false), false), Is.False);
        }

        [TestCase(AICodedbHostGenerationState.Unavailable, AICodedbHostPayloadState.SetupRequired, AICodedbHostUpgradePhase.Unavailable)]
        [TestCase(AICodedbHostGenerationState.Previous, AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.Historical)]
        [TestCase(AICodedbHostGenerationState.Invalid, AICodedbHostPayloadState.Blocked, AICodedbHostUpgradePhase.Invalid)]
        [TestCase(AICodedbHostGenerationState.Invalid, AICodedbHostPayloadState.Conflict, AICodedbHostUpgradePhase.CheckFailed)]
        [TestCase(AICodedbHostGenerationState.Previous, AICodedbHostPayloadState.UpgradeReady, AICodedbHostUpgradePhase.Rollback)]
        [TestCase(AICodedbHostGenerationState.Current, AICodedbHostPayloadState.Current, AICodedbHostUpgradePhase.Current)]
        public void RemoveIntegration_RequiresCachedPreflightAcrossRecoveryStates(
            AICodedbHostGenerationState generationState,
            AICodedbHostPayloadState payloadState,
            AICodedbHostUpgradePhase upgradePhase)
        {
            Assert.That(
                AICodedbManagerWindow.IsRemoveIntegrationAvailable(generationState, payloadState, upgradePhase, true),
                Is.True);
            Assert.That(
                AICodedbManagerWindow.IsRemoveIntegrationAvailable(generationState, payloadState, upgradePhase, false),
                Is.False);
        }

        [Test]
        public void RemoveIntegration_CancelDoesNotInvokeRecoveryAction()
        {
            var confirmationCount = 0;
            var removeCount = 0;
            var confirmedProjectMutation = false;

            var ran = AICodedbManagerWindow.ConfirmAndRunRemoveIntegration(
                () =>
                {
                    confirmationCount++;
                    return false;
                },
                confirmed =>
                {
                    removeCount++;
                    confirmedProjectMutation = confirmed;
                });

            Assert.That(ran, Is.False);
            Assert.That(confirmationCount, Is.EqualTo(1));
            Assert.That(removeCount, Is.Zero);
            Assert.That(confirmedProjectMutation, Is.False);
        }

        [Test]
        public void RemoveIntegration_ConfirmationRunsExactlyOnePackageOwnedRecoveryAction()
        {
            var removeCount = 0;
            var confirmedProjectMutation = false;

            var ran = AICodedbManagerWindow.ConfirmAndRunRemoveIntegration(
                () => true,
                confirmed =>
                {
                    removeCount++;
                    confirmedProjectMutation = confirmed;
                });

            Assert.That(ran, Is.True);
            Assert.That(removeCount, Is.EqualTo(1));
            Assert.That(confirmedProjectMutation, Is.True);
            Assert.That(AICodedbManagerWindow.RemoveIntegrationConfirmationTitle, Is.EqualTo("Remove CodeDB Integration"));
            Assert.That(AICodedbManagerWindow.RemoveIntegrationConfirmationMessage, Does.Contain("fresh integration"));
            Assert.That(AICodedbManagerWindow.RemoveIntegrationConfirmationMessage, Does.Contain("unrelated MCP content"));
            Assert.That(AICodedbManagerWindow.RemoveIntegrationConfirmationMessage, Does.Contain("external processes"));
        }

        [Test]
        public void RemoveIntegration_AdmissionRequiresExactCachedAndCurrentEvidence()
        {
            var cached = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                "obsolete",
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.ControlContractReinstallRequired,
                string.Empty,
                true);
            var installed = new AICodedbProjectIntegrationStatus(
                AICodedbProjectIntegrationState.Installed,
                AICodedbProjectCleanupState.None,
                string.Empty,
                "installed");
            var uninstalled = new AICodedbProjectIntegrationStatus(
                AICodedbProjectIntegrationState.Uninstalled,
                AICodedbProjectCleanupState.Complete,
                "uninstalled-state",
                "uninstalled");
            var invalidIntegration = new AICodedbProjectIntegrationStatus(
                AICodedbProjectIntegrationState.Invalid,
                AICodedbProjectCleanupState.Invalid,
                string.Empty,
                "invalid");
            var obsolete = new AICodedbControlContractMigrationStatus(
                AICodedbControlContractMigrationState.ObsoleteReinstallRequired,
                AICodedbControlContract.CreateDefaultIdentity(),
                "current",
                "legacy",
                "obsolete",
                "authenticated");
            var ambiguous = new AICodedbControlContractMigrationStatus(
                AICodedbControlContractMigrationState.InvalidOrAmbiguous,
                AICodedbControlContract.CreateDefaultIdentity(),
                "current",
                "legacy",
                "ambiguous",
                "invalid");
            var missingMigration = new AICodedbControlContractMigrationStatus(
                AICodedbControlContractMigrationState.Missing,
                AICodedbControlContract.CreateDefaultIdentity(),
                "current",
                "legacy",
                "missing",
                string.Empty);
            var legacyInstance = new AICodedbCurrentInstanceStatus(
                AICodedbCurrentInstanceState.ObsoleteReinstallRequired,
                "0123456789abcdef0123456789abcdef",
                "AIWork/.runtime/codedb/instances/0123456789abcdef0123456789abcdef",
                string.Empty,
                string.Empty,
                "poc.33",
                "legacy-package",
                "legacy-payload",
                33,
                1,
                "obsolete",
                1);
            var invalidInstance = new AICodedbCurrentInstanceStatus(
                AICodedbCurrentInstanceState.Invalid,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                0,
                0,
                "invalid");
            var instanceCached = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                "obsolete instance",
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.InstanceIdentityReinstallRequired,
                string.Empty,
                true);
            var missingPrerequisite = new AICodedbProductStatus(
                AICodedbProductState.MissingPrerequisite,
                AICodedbProductLayerState.Missing,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                "missing",
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.ControlContractReinstallRequired);
            var genericAttention = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                "attention");
            var unverifiedCached = new AICodedbProductStatus(
                AICodedbProductState.NeedsAttention,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                AICodedbProductLayerState.Blocked,
                "obsolete",
                default(AICodedbMaterializerCommandStatus),
                AICodedbProductAttentionReason.ControlContractReinstallRequired);

            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    unverifiedCached, installed, obsolete, invalidInstance, true),
                Is.False,
                "A reinstall reason alone cannot authorize project integration removal.");

            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    cached,
                    installed,
                    obsolete,
                    invalidInstance,
                    true),
                Is.True);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    cached,
                    installed,
                    obsolete,
                    invalidInstance,
                    false),
                Is.False,
                "Confirmation must not be inferred from the cached reason.");
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    missingPrerequisite,
                    installed,
                    obsolete,
                    invalidInstance,
                    true),
                Is.False);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    genericAttention,
                    installed,
                    obsolete,
                    invalidInstance,
                    true),
                Is.False);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    cached,
                    uninstalled,
                    obsolete,
                    invalidInstance,
                    true),
                Is.False);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    cached,
                    invalidIntegration,
                    obsolete,
                    invalidInstance,
                    true),
                Is.False);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    cached,
                    installed,
                    ambiguous,
                    invalidInstance,
                    true),
                Is.False);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    instanceCached,
                    installed,
                    missingMigration,
                    legacyInstance,
                    true),
                Is.True);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    instanceCached,
                    installed,
                    missingMigration,
                    invalidInstance,
                    true),
                Is.False);
            Assert.That(
                AICodedbActions.IsExplicitRemoveIntegrationAdmissionAllowed(
                    instanceCached,
                    installed,
                    ambiguous,
                    legacyInstance,
                    true),
                Is.False);
        }

        [Test]
        public void HostPayloadRedeploy_CancelAfterPreflightReturnsExplicitFailure()
        {
            var preflight = new AICodedbCommandResult(
                0,
                "dry-run output",
                string.Empty,
                false,
                17);

            var result = AICodedbManagerWindow.BuildCancelledHostPayloadRedeployResult(preflight);

            Assert.That(result.Succeeded, Is.False);
            Assert.That(result.ExitCode, Is.EqualTo(1));
            Assert.That(result.StandardOutput, Is.EqualTo("dry-run output"));
            Assert.That(result.StandardError, Is.EqualTo("Host Payload Redeploy was cancelled by the user."));
            Assert.That(result.ElapsedMilliseconds, Is.EqualTo(17));
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
            Assert.That(AICodedbManagerWindow.InstallCodeDBConfirmationMessage, Does.Contain("fresh project-local instance"));
            Assert.That(AICodedbManagerWindow.InstallCodeDBConfirmationMessage, Does.Contain("atomically publish INSTALLED"));
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

        [TestCase("Enable", true)]
        [TestCase("Disable", false)]
        [TestCase("Start", true)]
        [TestCase("Status", false)]
        [TestCase("Stop", true)]
        [TestCase("Restart", true)]
        public void WatcherActionLeaseBoundary_IsExplicit(string action, bool requiresLease)
        {
            Assert.That(
                AICodedbActions.WatcherActionRequiresEditorLease(action),
                Is.EqualTo(requiresLease));
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
        [Test]
        public void ResolveButtonWidth_ExpandsForLongContent()
        {
            Assert.That(
                AICodedbActionGridView.ResolveButtonWidth(150f),
                Is.EqualTo(166f));
        }

        [Test]
        public void ResolveButtonWidth_PreservesMinimumForShortContent()
        {
            Assert.That(
                AICodedbActionGridView.ResolveButtonWidth(40f),
                Is.EqualTo(AICodedbActionGridView.ButtonWidth));
        }

        [Test]
        public void ResolveColumns_AccountsForExpandedButtonWidth()
        {
            Assert.That(AICodedbActionGridView.ResolveColumns(392f, 3, 3, 160f), Is.EqualTo(2));
        }

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
