using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Rice.AI.Codedb.Editor
{
    // Provenance is minted only by the common exact-action history reader.
    // Supervisor history owns the result; the Manager journal still owns release.
    internal sealed class AICodedbSupervisorTerminalEvidence
    {
        private readonly string _actionId;
        private readonly string _projectKey;
        private readonly string _packageKey;
        internal string OperationId { get; }

        private AICodedbSupervisorTerminalEvidence(AICodedbEditorExecutionContext context,
            string actionId, string operationId)
        {
            _actionId = actionId;
            _projectKey = AICodedbPaths.GetManagerActionProjectKey(context);
            _packageKey = AICodedbPaths.GetManagerActionPackageKey(context);
            OperationId = operationId;
        }

        internal bool Matches(AICodedbEditorExecutionContext context, string actionId)
        {
            return _actionId == actionId
                && _projectKey == AICodedbPaths.GetManagerActionProjectKey(context)
                && _packageKey == AICodedbPaths.GetManagerActionPackageKey(context);
        }

        internal static AICodedbManagerActionRecoveryOutcome Read(
            AICodedbEditorExecutionContext context, string actionId,
            string expectedOperationId = null, string expectedOwnerEpoch = null,
            string expectedRequestId = null, string expectedInstanceId = null,
            string expectedGenerationId = null, string expectedContractHash = null)
        {
            try
            {
                Need(AICodedbSupervisorProtocol.IsManagerActionId(actionId), "Invalid action id.");
                AICodedbProcessRunner.ValidateActionManifest(context, actionId);
                var indexPath = AICodedbPaths.GetManagerActionIndexPath(context, actionId);
                AssertPath(indexPath);
                var admission = AICodedbStrictJson.ReadObject(indexPath, 16384, "Manager action index");
                Need(S(admission, "title") == "Uninstall CodeDB from Project"
                    && S(admission, "state") == "pending" && S(admission, "action_id") == actionId
                    && S(admission, "project_key") == AICodedbPaths.GetManagerActionProjectKey(context)
                    && S(admission, "package_key") == AICodedbPaths.GetManagerActionPackageKey(context)
                    && PathEquals(S(admission, "project_root"), context.ProjectRoot)
                    && PathEquals(S(admission, "package_root"), context.PackageRoot), "Not the admitted current uninstall action.");
                var contract = AICodedbPackageRuntimeContractStore.Read(context.PackageRoot);
                var runtime = AICodedbSupervisorLauncher.GetSupervisorRuntimePath(context.ProjectRoot, contract.ControlContract);
                var mapPath = Path.Combine(runtime, "manager-actions", actionId + ".json");
                AssertPath(mapPath);
                if (!File.Exists(mapPath))
                    return AICodedbManagerActionRecoveryOutcome.NotFound("No exact Supervisor action map exists.");
                var map = AICodedbStrictJson.ReadObject(mapPath, 256 * 1024, "Supervisor action map");
                Common(map, context, runtime, actionId);
                Need(AICodedbStrictJson.GetRequiredInt32(map, "terminal_binding_schema_version", "Supervisor action map") == 1,
                    "The original record lacks terminal binding evidence.");
                Need(PathEquals(S(map, "package_root"), context.PackageRoot), "Package binding differs.");
                var ids = AICodedbStrictJson.GetRequiredStringArray(map, "operation_ids", "Supervisor action map");
                Need(ids.Length == 1 && Id(ids[0]) && S(map, "latest_operation_id") == ids[0], "Ambiguous operation binding.");
                var operationId = ids[0];
                Need(expectedOperationId == null || operationId == expectedOperationId, "Returned operation differs.");
                var operationPath = Path.Combine(runtime, "operation-history", operationId + ".json");
                AssertPath(operationPath);
                if (!File.Exists(operationPath))
                    return AICodedbManagerActionRecoveryOutcome.Pending("The exact operation history is missing.");
                var operation = AICodedbStrictJson.ReadObject(operationPath, 256 * 1024, "Supervisor operation");
                Common(operation, context, runtime, actionId);
                Need(S(operation, "operation_id") == operationId, "Operation filename and identity differ.");
                Need(S(operation, "name") == "materialize:Uninstall" && S(operation, "lane") == "maintenance",
                    "The operation is not Uninstall.");
                Need(S(operation, "key") == "[\"materialize:Uninstall\",\"Uninstall\",true,\"\",false,false,\"\",0,\"\"]",
                    "The admitted command differs.");
                foreach (var field in new[] { "owner_epoch", "request_id", "selected_instance_id", "selected_generation_id", "runtime_contract_sha256" })
                    Need(S(map, field) == S(operation, field), "Original execution binding differs: " + field);
                Need(Id(S(operation, "owner_epoch")) && Id(S(operation, "request_id"))
                    && Id(S(operation, "selected_instance_id")) && Hash(S(operation, "runtime_contract_sha256"))
                    && !string.IsNullOrWhiteSpace(S(operation, "selected_generation_id")), "Invalid original execution identity.");
                Match(operation, "owner_epoch", expectedOwnerEpoch);
                Match(operation, "request_id", expectedRequestId);
                Match(operation, "selected_instance_id", expectedInstanceId);
                Match(operation, "selected_generation_id", expectedGenerationId);
                Match(operation, "runtime_contract_sha256", expectedContractHash);
                if (S(operation, "state") == "queued" || S(operation, "state") == "running")
                    return AICodedbManagerActionRecoveryOutcome.Pending("The original operation is still pending.");
                var state = S(operation, "state");
                Need((state == "completed" || state == "failed") && S(operation, "phase") == state,
                    "The operation is not a confirmed terminal.");
                DateTimeOffset started, completed;
                Need(DateTimeOffset.TryParse(S(operation, "started_at_utc"), CultureInfo.InvariantCulture,
                        DateTimeStyles.None, out started)
                    && DateTimeOffset.TryParse(S(operation, "completed_at_utc"), CultureInfo.InvariantCulture,
                        DateTimeStyles.None, out completed) && completed >= started, "Invalid terminal timestamps.");
                var child = AICodedbStrictJson.RequireObject(operation["child"], "Supervisor child");
                var argv = AICodedbStrictJson.GetRequiredStringArray(child, "normalized_argv", "Supervisor child");
                var expectedArgv = new[] { "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File",
                    NormalizeArgument(Path.Combine(context.PackageRoot, "Tools~", "materialize-codedb-host-payload.ps1")),
                    "-Action", "Uninstall", "-ProjectRoot", NormalizeArgument(context.ProjectRoot),
                    "-PayloadRoot", NormalizeArgument(Path.Combine(context.PackageRoot, "Payload~")),
                    "-OriginatingOperationId", operationId, "-OriginatingActionId", actionId, "-ConfirmedProjectMutation" };
                Need(argv.Length == expectedArgv.Length, "The captured invocation has additional/missing arguments.");
                for (var i = 0; i < argv.Length; i++)
                    Need(argv[i] == expectedArgv[i], "The captured invocation differs at argument " + i + ".");
                var json = new StringBuilder("[");
                for (var i = 0; i < argv.Length; i++)
                {
                    if (i != 0) json.Append(',');
                    json.Append('"').Append(Escape(argv[i])).Append('"');
                }
                json.Append(']');
                using (var sha = SHA256.Create())
                    Need(BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(json.ToString())))
                        .Replace("-", "").ToLowerInvariant() == S(child, "argv_sha256"), "Captured argv hash differs.");
                var result = AICodedbStrictJson.RequireObject(operation["result"], "Supervisor terminal");
                Need(!B(result, "timed_out") && !B(result, "output_overflow") && !B(result, "output_drain_incomplete"),
                    "Terminal execution/output observation is incomplete.");
                var exitCode = AICodedbStrictJson.GetRequiredInt32(result, "exit_code", "Supervisor terminal");
                Need((state == "completed") == (exitCode == 0), "Terminal state and exit code conflict.");
                return AICodedbManagerActionRecoveryOutcome.Terminal(new AICodedbCommandResult(exitCode,
                    S(result, "stdout"), S(result, "stderr"), false, authoritativeTerminalEvidence: true,
                    actionId: actionId, supervisorTerminalEvidence: new AICodedbSupervisorTerminalEvidence(context, actionId, operationId),
                    supervisorHandoffWarningCode: exitCode == 0 ? "SUPERVISOR_HANDOFF_UNCONFIRMED" : null,
                    supervisorHandoffWarningDetail: exitCode == 0
                        ? "The uninstall command completed, but this recovered backend terminal does not confirm Supervisor handoff. "
                          + "A later action must pass its own ownership and admission checks."
                        : null));
            }
            catch (Exception exception) when (exception is InvalidOperationException || exception is IOException
                || exception is UnauthorizedAccessException || exception is ArgumentException || exception is KeyNotFoundException)
            {
                return AICodedbManagerActionRecoveryOutcome.Conflict("Exact Supervisor terminal unavailable: " + exception.Message);
            }
        }

        private static void Common(Dictionary<string, object> record, AICodedbEditorExecutionContext context,
            string runtime, string actionId)
        {
            Need(AICodedbStrictJson.GetRequiredInt32(record, "schema_version", "Supervisor evidence") == 1
                && S(record, "managed_by") == "com.rice.ai-codedb" && S(record, "manager_action_id") == actionId
                && S(record, "project_identity") == "sha256:" + AICodedbPaths.GetManagerActionProjectKey(context)
                && PathEquals(S(record, "root"), context.ProjectRoot) && PathEquals(S(record, "runtime"), runtime),
                "Supervisor action/project/runtime identity differs.");
        }

        private static void Match(Dictionary<string, object> record, string field, string expected)
        { Need(expected == null || S(record, field) == expected, "Authenticated original " + field + " differs."); }
        private static string S(Dictionary<string, object> record, string field)
        { return AICodedbStrictJson.GetRequiredString(record, field, "Supervisor terminal evidence"); }
        private static bool B(Dictionary<string, object> record, string field)
        { return AICodedbStrictJson.GetRequiredBoolean(record, field, "Supervisor terminal evidence"); }
        private static void Need(bool condition, string detail)
        { if (!condition) throw new InvalidOperationException(detail); }
        private static bool Id(string value)
        { return value != null && value.Length == 32 && Hex(value); }
        private static bool Hash(string value)
        { return value != null && value.Length == 64 && Hex(value); }
        private static bool Hex(string value)
        { foreach (var c in value) if (!(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f')) return false; return true; }
        private static bool PathEquals(string left, string right)
        { return string.Equals(AICodedbPaths.NormalizePath(left).TrimEnd('/'), AICodedbPaths.NormalizePath(right).TrimEnd('/'), StringComparison.OrdinalIgnoreCase); }
        private static string NormalizeArgument(string value)
        { return Path.GetFullPath(value).Replace('\\', '/').ToLowerInvariant().Normalize(NormalizationForm.FormC); }
        private static string Escape(string value)
        {
            var result = new StringBuilder();
            foreach (var c in value)
            {
                if (c == '"' || c == '\\') result.Append('\\').Append(c);
                else if (c < 32) result.Append("\\u").Append(((int)c).ToString("x4"));
                else result.Append(c);
            }
            return result.ToString();
        }
        private static void AssertPath(string path)
        {
            var full = Path.GetFullPath(path);
            var current = Path.GetPathRoot(full);
            foreach (var part in full.Substring(current.Length).Split(new[] { '/', '\\' }, StringSplitOptions.RemoveEmptyEntries))
            {
                current = Path.Combine(current, part);
                if (!File.Exists(current) && !Directory.Exists(current)) break;
                Need((File.GetAttributes(current) & FileAttributes.ReparsePoint) == 0, "Supervisor evidence traverses a redirected path.");
            }
        }
    }
}
