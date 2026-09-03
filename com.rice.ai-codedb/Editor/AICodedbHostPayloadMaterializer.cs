using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using UnityEditor;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbHostPayloadAction
    {
        DryRun,
        Probe,
        Verify,
        Upgrade,
        Redeploy,
        Repair,
        Sync,
        Remove,
        Uninstall,
        Install,
        Reinstall
    }

    internal static class AICodedbHostPayloadMaterializer
    {
        private const int ReadTimeoutMilliseconds = 120000;
        private const int MutationTimeoutMilliseconds = 600000;

        internal static AICodedbCommandResult ReadStatus()
        {
            return Run(AICodedbHostPayloadAction.DryRun, false, false);
        }

        internal static Task<AICodedbCommandResult> ReadStatusAsync()
        {
            return ReadStatusAsync(AICodedbPaths.CaptureExecutionContext());
        }

        internal static Task<AICodedbCommandResult> ReadStatusAsync(AICodedbEditorExecutionContext context)
        {
            var arguments = BuildScriptArguments(AICodedbHostPayloadAction.DryRun, false, context.ProjectRoot);
            return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScriptAsync(
                context,
                ReadTimeoutMilliseconds,
                arguments);
        }

        internal static AICodedbCommandResult ReadStatus(AICodedbEditorExecutionContext context)
        {
            return Run(context, AICodedbHostPayloadAction.DryRun, false);
        }

        internal static AICodedbCommandResult ReadStatus(
            AICodedbEditorExecutionContext context,
            CancellationToken cancellationToken)
        {
            return Run(
                context,
                AICodedbHostPayloadAction.DryRun,
                false,
                false,
                cancellationToken);
        }

        internal static Task<AICodedbCommandResult> RunProbeAsync()
        {
            return RunAsync(AICodedbHostPayloadAction.Probe, false, ReadTimeoutMilliseconds);
        }

        internal static AICodedbCommandResult RunProbe(AICodedbEditorExecutionContext context)
        {
            return Run(context, AICodedbHostPayloadAction.Probe, false);
        }

        internal static AICodedbCommandResult RunProbe(
            AICodedbEditorExecutionContext context,
            CancellationToken cancellationToken)
        {
            return Run(
                context,
                AICodedbHostPayloadAction.Probe,
                false,
                false,
                cancellationToken);
        }

        internal static AICodedbCommandResult RunDryRun()
        {
            return Run(AICodedbHostPayloadAction.DryRun, false, true);
        }

        internal static AICodedbCommandResult RunVerify()
        {
            return Run(AICodedbHostPayloadAction.Verify, false, true);
        }

        internal static AICodedbCommandResult RunUpgrade()
        {
            return Run(AICodedbHostPayloadAction.Upgrade, false, true);
        }

        internal static Task<AICodedbCommandResult> RunUpgradeAsync()
        {
            return RunAsync(
                AICodedbPaths.CaptureExecutionContext(),
                AICodedbHostPayloadAction.Upgrade,
                false,
                MutationTimeoutMilliseconds);
        }

        internal static AICodedbCommandResult RunUpgrade(AICodedbEditorExecutionContext context)
        {
            return Run(context, AICodedbHostPayloadAction.Upgrade, false);
        }

        internal static AICodedbCommandResult RunUpgrade(
            AICodedbEditorExecutionContext context,
            CancellationToken cancellationToken)
        {
            return Run(
                context,
                AICodedbHostPayloadAction.Upgrade,
                false,
                false,
                cancellationToken);
        }

        internal static AICodedbCommandResult RunRedeploy(bool confirmedProjectMutation)
        {
            return Run(AICodedbHostPayloadAction.Redeploy, confirmedProjectMutation, true);
        }

        internal static AICodedbCommandResult RunRepair()
        {
            return Run(AICodedbHostPayloadAction.Repair, true, true);
        }

        internal static Task<AICodedbCommandResult> RunRepairAsync()
        {
            return RunAsync(AICodedbHostPayloadAction.Repair, true, MutationTimeoutMilliseconds);
        }

        internal static AICodedbCommandResult RunSync()
        {
            return Run(AICodedbHostPayloadAction.Sync, true, true);
        }

        internal static AICodedbCommandResult RunRemove()
        {
            return Run(AICodedbHostPayloadAction.Remove, true, true);
        }

        internal static AICodedbCommandResult RunUninstall()
        {
            return Run(AICodedbHostPayloadAction.Uninstall, true, true);
        }

        internal static Task<AICodedbCommandResult> RunUninstallAsync()
        {
            return RunAsync(AICodedbHostPayloadAction.Uninstall, true, MutationTimeoutMilliseconds);
        }

        internal static AICodedbCommandResult RunInstall()
        {
            return Run(AICodedbHostPayloadAction.Install, true, true);
        }

        internal static Task<AICodedbCommandResult> RunInstallAsync()
        {
            return RunAsync(AICodedbHostPayloadAction.Install, true, MutationTimeoutMilliseconds);
        }

        internal static AICodedbCommandResult RunReinstall()
        {
            return Run(AICodedbHostPayloadAction.Reinstall, true, true);
        }

        internal static Task<AICodedbCommandResult> RunReinstallAsync()
        {
            return RunAsync(AICodedbHostPayloadAction.Reinstall, true, MutationTimeoutMilliseconds);
        }

        internal static string[] BuildScriptArguments(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation)
        {
            return BuildScriptArguments(action, confirmedProjectMutation, AICodedbPaths.ProjectRoot);
        }

        internal static string[] BuildScriptArguments(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            string projectRoot)
        {
            var requiresConfirmation = RequiresConfirmation(action);
            if (requiresConfirmation != confirmedProjectMutation)
                throw new ArgumentException(
                    requiresConfirmation
                         ? "Redeploy, Repair, Sync, Remove, Uninstall, Install, and Reinstall require second-level project mutation confirmation."
                        : "DryRun, Probe, Verify, and Upgrade do not accept project mutation confirmation.",
                    nameof(confirmedProjectMutation));

            var arguments = new List<string>
            {
                "-Action",
                action.ToString(),
                "-ProjectRoot",
                projectRoot
            };

            if (requiresConfirmation)
                arguments.Add("-ConfirmedProjectMutation");

            return arguments.ToArray();
        }

        private static bool RequiresConfirmation(AICodedbHostPayloadAction action)
        {
            return action == AICodedbHostPayloadAction.Redeploy
                   || action == AICodedbHostPayloadAction.Repair
                   || action == AICodedbHostPayloadAction.Sync
                   || action == AICodedbHostPayloadAction.Remove
                   || action == AICodedbHostPayloadAction.Uninstall
                   || action == AICodedbHostPayloadAction.Install
                   || action == AICodedbHostPayloadAction.Reinstall;
        }

        private static bool IsMutation(AICodedbHostPayloadAction action)
        {
            return action == AICodedbHostPayloadAction.Upgrade
                   || action == AICodedbHostPayloadAction.Probe
                   || action == AICodedbHostPayloadAction.Redeploy
                   || action == AICodedbHostPayloadAction.Repair
                   || action == AICodedbHostPayloadAction.Sync
                   || action == AICodedbHostPayloadAction.Remove
                   || action == AICodedbHostPayloadAction.Uninstall
                   || action == AICodedbHostPayloadAction.Install
                   || action == AICodedbHostPayloadAction.Reinstall;
        }

        private static bool RequiresCandidateLeaseHandoff(AICodedbHostPayloadAction action)
        {
            return action == AICodedbHostPayloadAction.Upgrade
                   || action == AICodedbHostPayloadAction.Install
                   || action == AICodedbHostPayloadAction.Reinstall;
        }

        private static string[] BuildRuntimeScriptArguments(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            string projectRoot)
        {
            var arguments = new List<string>(
                BuildScriptArguments(action, confirmedProjectMutation, projectRoot));
            if (RequiresCandidateLeaseHandoff(action)
                && AICodedbEditorLifecycle.TryGetCurrentEditorLeaseIdentity(
                    out var sessionId,
                    out var processId,
                    out var processStartTicks))
            {
                arguments.Add("-EditorSessionId");
                arguments.Add(sessionId);
                arguments.Add("-EditorProcessId");
                arguments.Add(processId.ToString(CultureInfo.InvariantCulture));
                arguments.Add("-EditorProcessStartTicks");
                arguments.Add(processStartTicks);
            }
            return arguments.ToArray();
        }

        private static AICodedbCommandResult Run(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            bool showProgress)
        {
            return Run(
                AICodedbPaths.CaptureExecutionContext(),
                action,
                confirmedProjectMutation,
                showProgress);
        }

        private static AICodedbCommandResult Run(
            AICodedbEditorExecutionContext context,
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            bool showProgress = false)
        {
            return Run(
                context,
                action,
                confirmedProjectMutation,
                showProgress,
                CancellationToken.None);
        }

        private static AICodedbCommandResult Run(
            AICodedbEditorExecutionContext context,
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            bool showProgress,
            CancellationToken cancellationToken)
        {
            string[] arguments;
            try
            {
                arguments = BuildRuntimeScriptArguments(action, confirmedProjectMutation, context.ProjectRoot);
            }
            catch (ArgumentException exception)
            {
                return new AICodedbCommandResult(-1, string.Empty, exception.Message, false);
            }

            if (showProgress)
            {
                EditorUtility.DisplayProgressBar(
                    AICodedbProjectSettings.DisplayName,
                    $"Running {Path.GetFileName(AICodedbPaths.HostPayloadMaterializerScriptPath)} ({action})",
                    0.5f);
            }

            try
            {
                var timeout = IsMutation(action) ? MutationTimeoutMilliseconds : ReadTimeoutMilliseconds;
                if (cancellationToken != CancellationToken.None)
                {
                    return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScript(
                        context,
                        timeout,
                        cancellationToken,
                        arguments);
                }

                return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScript(
                    context,
                    timeout,
                    arguments);
            }
            finally
            {
                if (showProgress)
                    EditorUtility.ClearProgressBar();
            }
        }

        private static Task<AICodedbCommandResult> RunAsync(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            int timeoutMilliseconds)
        {
            return RunAsync(
                AICodedbPaths.CaptureExecutionContext(),
                action,
                confirmedProjectMutation,
                timeoutMilliseconds);
        }

        private static Task<AICodedbCommandResult> RunAsync(
            AICodedbEditorExecutionContext context,
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            int timeoutMilliseconds)
        {
            string[] arguments;
            try
            {
                arguments = BuildRuntimeScriptArguments(action, confirmedProjectMutation, context.ProjectRoot);
            }
            catch (ArgumentException exception)
            {
                return Task.FromResult(new AICodedbCommandResult(
                    -1,
                    string.Empty,
                    exception.Message,
                    false));
            }

            return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScriptAsync(
                context,
                timeoutMilliseconds,
                arguments);
        }
    }

    internal enum AICodedbProductLayerState
    {
        Unknown,
        Pending,
        Current,
        Missing,
        Blocked,
        Unavailable
    }

    internal enum AICodedbProductState
    {
        Starting,
        Ready,
        NeedsAttention,
        Uninstalled,
        MissingPrerequisite
    }

    internal enum AICodedbProductAttentionReason
    {
        None,
        ControlContractReinstallRequired,
        ControlContractInvalidOrAmbiguous
    }

    internal readonly struct AICodedbMaterializerCommandStatus
    {
        internal bool Present { get; }
        internal bool IsValid { get; }
        internal string Action { get; }
        internal string Outcome { get; }
        internal string Phase { get; }
        internal string ReasonCode { get; }
        internal string[] MutatedScopes { get; }
        internal string CleanupState { get; }
        internal string NextAction { get; }
        internal int ExitCode { get; }
        internal string Detail { get; }

        internal AICodedbMaterializerCommandStatus(
            bool present,
            bool isValid,
            string action,
            string outcome,
            string phase,
            string reasonCode,
            string[] mutatedScopes,
            string cleanupState,
            string nextAction,
            int exitCode,
            string detail)
        {
            Present = present;
            IsValid = isValid;
            Action = action ?? string.Empty;
            Outcome = outcome ?? string.Empty;
            Phase = phase ?? string.Empty;
            ReasonCode = reasonCode ?? string.Empty;
            MutatedScopes = mutatedScopes ?? Array.Empty<string>();
            CleanupState = cleanupState ?? string.Empty;
            NextAction = nextAction ?? string.Empty;
            ExitCode = exitCode;
            Detail = detail ?? string.Empty;
        }
    }

    internal static class AICodedbMaterializerCommandStatusParser
    {
        private const string Prefix = "[COMMAND_RESULT]";
        private const string ManagedBy = "com.rice.ai-codedb";
        private static readonly Regex IdentifierPattern =
            new Regex("^[A-Z][A-Z0-9_]{0,63}$", RegexOptions.CultureInvariant);
        private static readonly Regex ScopePattern =
            new Regex("^[a-z][a-z0-9_]{0,63}$", RegexOptions.CultureInvariant);
        private static readonly HashSet<string> Actions = new HashSet<string>(StringComparer.Ordinal)
        {
            "UPGRADE", "REDEPLOY", "SYNC", "REMOVE", "REPAIR", "UNINSTALL", "INSTALL", "REINSTALL"
        };
        private static readonly HashSet<string> Properties = new HashSet<string>(StringComparer.Ordinal)
        {
            "schema_version", "managed_by", "action", "outcome", "phase", "reason_code",
            "mutated_scopes", "cleanup_state", "next_action", "exit_code", "detail"
        };

        internal static AICodedbMaterializerCommandStatus Parse(string output)
        {
            string json = null;
            var count = 0;
            foreach (var line in SplitLines(output))
            {
                var trimmed = line.Trim();
                if (!trimmed.StartsWith(Prefix, StringComparison.Ordinal))
                    continue;
                count++;
                json = trimmed.Substring(Prefix.Length).Trim();
            }
            if (count == 0)
                return default(AICodedbMaterializerCommandStatus);
            if (count != 1 || string.IsNullOrWhiteSpace(json))
                return Invalid("Materializer output must contain exactly one non-empty versioned command result.");

            try
            {
                var value = AICodedbStrictJson.ParseObject(json, "Materializer command result");
                if (value.Count != Properties.Count)
                    throw new InvalidOperationException("Materializer command result properties do not match schema 1.");
                foreach (var name in value.Keys)
                {
                    if (!Properties.Contains(name))
                        throw new InvalidOperationException("Materializer command result contains an unsupported property: " + name + ".");
                }

                var action = AICodedbStrictJson.GetRequiredString(value, "action", "Materializer command result");
                var outcome = AICodedbStrictJson.GetRequiredString(value, "outcome", "Materializer command result");
                var phase = AICodedbStrictJson.GetRequiredString(value, "phase", "Materializer command result");
                var reasonCode = AICodedbStrictJson.GetRequiredString(value, "reason_code", "Materializer command result");
                var scopes = AICodedbStrictJson.GetRequiredStringArray(value, "mutated_scopes", "Materializer command result");
                var cleanupState = AICodedbStrictJson.GetRequiredString(value, "cleanup_state", "Materializer command result");
                var nextAction = AICodedbStrictJson.GetRequiredString(value, "next_action", "Materializer command result");
                var detail = AICodedbStrictJson.GetRequiredString(value, "detail", "Materializer command result");
                var exitCode = AICodedbStrictJson.GetRequiredInt32(value, "exit_code", "Materializer command result");
                if (AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "Materializer command result") != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(value, "managed_by", "Materializer command result"), ManagedBy, StringComparison.Ordinal)
                    || !Actions.Contains(action)
                    || !IdentifierPattern.IsMatch(outcome)
                    || !IdentifierPattern.IsMatch(phase)
                    || !IdentifierPattern.IsMatch(reasonCode)
                    || (!string.Equals(cleanupState, "COMPLETE", StringComparison.Ordinal)
                        && !string.Equals(cleanupState, "PENDING", StringComparison.Ordinal))
                    || string.IsNullOrWhiteSpace(nextAction))
                {
                    throw new InvalidOperationException("Materializer command result identity or values are invalid.");
                }
                var uniqueScopes = new HashSet<string>(StringComparer.Ordinal);
                foreach (var scope in scopes)
                {
                    if (!ScopePattern.IsMatch(scope) || !uniqueScopes.Add(scope))
                        throw new InvalidOperationException("Materializer command result contains an invalid or duplicate mutation scope.");
                }

                return new AICodedbMaterializerCommandStatus(
                    true,
                    true,
                    action,
                    outcome,
                    phase,
                    reasonCode,
                    scopes,
                    cleanupState,
                    nextAction,
                    exitCode,
                    detail);
            }
            catch (Exception exception)
            {
                return Invalid(exception.Message);
            }
        }

        private static AICodedbMaterializerCommandStatus Invalid(string detail)
        {
            return new AICodedbMaterializerCommandStatus(
                true,
                false,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                Array.Empty<string>(),
                string.Empty,
                string.Empty,
                0,
                detail);
        }

        private static string[] SplitLines(string text)
        {
            return (text ?? string.Empty).Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
        }
    }

    internal readonly struct AICodedbProductStatus
    {
        internal AICodedbProductState State { get; }
        internal AICodedbProductLayerState Prerequisite { get; }
        internal AICodedbProductLayerState Installed { get; }
        internal AICodedbProductLayerState Configured { get; }
        internal AICodedbProductLayerState McpAvailable { get; }
        internal AICodedbMaterializerCommandStatus Command { get; }
        internal string Detail { get; }
        internal string DiagnosticDetail { get; }
        internal AICodedbProductAttentionReason AttentionReason { get; }
        internal bool IsReady => State == AICodedbProductState.Ready;
        internal bool RequiresReinstall =>
            State == AICodedbProductState.NeedsAttention
            && AttentionReason == AICodedbProductAttentionReason.ControlContractReinstallRequired;

        internal AICodedbProductStatus(
            AICodedbProductState state,
            AICodedbProductLayerState installed,
            AICodedbProductLayerState configured,
            AICodedbProductLayerState mcpAvailable,
            string detail,
            AICodedbMaterializerCommandStatus command = default(AICodedbMaterializerCommandStatus),
            AICodedbProductAttentionReason attentionReason = AICodedbProductAttentionReason.None,
            string diagnosticDetail = "")
            : this(
                state,
                AICodedbProductLayerState.Unknown,
                installed,
                configured,
                mcpAvailable,
                detail,
                command,
                attentionReason,
                diagnosticDetail)
        {
        }

        internal AICodedbProductStatus(
            AICodedbProductState state,
            AICodedbProductLayerState prerequisite,
            AICodedbProductLayerState installed,
            AICodedbProductLayerState configured,
            AICodedbProductLayerState mcpAvailable,
            string detail,
            AICodedbMaterializerCommandStatus command = default(AICodedbMaterializerCommandStatus),
            AICodedbProductAttentionReason attentionReason = AICodedbProductAttentionReason.None,
            string diagnosticDetail = "")
        {
            State = state;
            Prerequisite = prerequisite;
            Installed = installed;
            Configured = configured;
            McpAvailable = mcpAvailable;
            Command = command;
            Detail = detail ?? string.Empty;
            DiagnosticDetail = diagnosticDetail ?? string.Empty;
            AttentionReason = attentionReason;
        }
    }

    internal static class AICodedbProductStatusBuilder
    {
        private const string PrerequisitePrefix = "[PRODUCT_LAYER PREREQUISITE]";
        private const string InstalledPrefix = "[PRODUCT_LAYER INSTALLED]";
        private const string ConfiguredPrefix = "[PRODUCT_LAYER CONFIGURED]";
        private const string McpAvailablePrefix = "[PRODUCT_LAYER MCP_AVAILABLE]";
        private const string ProductStatePrefix = "[PRODUCT_STATE]";

        internal static AICodedbProductStatus Build(
            AICodedbProjectIntegrationStatus integrationStatus,
            AICodedbCommandResult result)
        {
            if (integrationStatus.IsUninstalled)
            {
                return new AICodedbProductStatus(
                    AICodedbProductState.Uninstalled,
                    AICodedbProductLayerState.Unknown,
                    AICodedbProductLayerState.Unknown,
                    AICodedbProductLayerState.Unknown,
                    integrationStatus.Detail);
            }
            if (!integrationStatus.IsValid)
            {
                return new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    integrationStatus.Detail);
            }
            if (result == null)
                return Starting("CodeDB is checking the project integration in the background.");

            var output = result.StandardOutput ?? string.Empty;
            var command = AICodedbMaterializerCommandStatusParser.Parse(output);
            if (command.Present && (!command.IsValid || command.ExitCode != result.ExitCode))
            {
                var commandDetail = command.IsValid
                    ? "Materializer command result exit code does not match the process exit code."
                    : command.Detail;
                return new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    AICodedbProductLayerState.Blocked,
                    commandDetail,
                    command);
            }
            var prerequisite = ParseLayer(output, PrerequisitePrefix);
            var installed = ParseLayer(output, InstalledPrefix);
            var configured = ParseLayer(output, ConfiguredPrefix);
            var mcpAvailable = ParseLayer(output, McpAvailablePrefix);
            var declaredState = ReadMarkerValue(output, ProductStatePrefix);
            if (prerequisite == AICodedbProductLayerState.Missing
                || string.Equals(declaredState, "MISSING_PREREQUISITE", StringComparison.Ordinal))
            {
                var prerequisiteDetail = FirstMarkedDetail(output);
                if (string.IsNullOrWhiteSpace(prerequisiteDetail))
                    prerequisiteDetail = FirstNonEmptyLine(result.StandardError);
                return new AICodedbProductStatus(
                    AICodedbProductState.MissingPrerequisite,
                    AICodedbProductLayerState.Missing,
                    installed,
                    configured,
                    mcpAvailable,
                    prerequisiteDetail,
                    command);
            }

            var allCurrent = prerequisite == AICodedbProductLayerState.Current
                             && installed == AICodedbProductLayerState.Current
                             && configured == AICodedbProductLayerState.Current
                             && mcpAvailable == AICodedbProductLayerState.Current;

            if (result.Succeeded
                && allCurrent
                && string.Equals(declaredState, "READY", StringComparison.Ordinal))
            {
                return new AICodedbProductStatus(
                    AICodedbProductState.Ready,
                    prerequisite,
                    installed,
                    configured,
                    mcpAvailable,
                    "The Package-owned Host, project registration, and MCP handshake are current.",
                    command);
            }

            var blocked = prerequisite == AICodedbProductLayerState.Blocked
                          || prerequisite == AICodedbProductLayerState.Unavailable
                          || installed == AICodedbProductLayerState.Blocked
                          || configured == AICodedbProductLayerState.Blocked
                          || mcpAvailable == AICodedbProductLayerState.Blocked
                          || mcpAvailable == AICodedbProductLayerState.Unavailable;
            if (!result.Succeeded
                || result.TimedOut
                || blocked
                || string.Equals(declaredState, "NEEDS_ATTENTION", StringComparison.Ordinal))
            {
                var detail = FirstNonEmptyLine(result.StandardError);
                if (string.IsNullOrWhiteSpace(detail))
                    detail = FirstMarkedDetail(output);
                if (string.IsNullOrWhiteSpace(detail))
                    detail = result.GetSummary();
                if (command.Present && command.IsValid && !string.IsNullOrWhiteSpace(command.NextAction))
                    detail = detail + " Next: " + command.NextAction;
                return new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention,
                    prerequisite,
                    installed,
                    configured,
                    mcpAvailable,
                    detail,
                    command);
            }

            return new AICodedbProductStatus(
                AICodedbProductState.Starting,
                prerequisite,
                installed,
                configured,
                mcpAvailable,
                "CodeDB is converging the Package-owned Host, registration, and MCP handshake.",
                command);
        }

        private static AICodedbProductStatus Starting(string detail)
        {
            return new AICodedbProductStatus(
                AICodedbProductState.Starting,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                detail);
        }

        private static AICodedbProductLayerState ParseLayer(string output, string prefix)
        {
            var value = ReadMarkerValue(output, prefix);
            if (value.StartsWith("CURRENT", StringComparison.Ordinal))
                return AICodedbProductLayerState.Current;
            if (value.StartsWith("MISSING", StringComparison.Ordinal))
                return AICodedbProductLayerState.Missing;
            if (value.StartsWith("PENDING", StringComparison.Ordinal))
                return AICodedbProductLayerState.Pending;
            if (value.StartsWith("BLOCKED", StringComparison.Ordinal))
                return AICodedbProductLayerState.Blocked;
            if (value.StartsWith("UNAVAILABLE", StringComparison.Ordinal))
                return AICodedbProductLayerState.Unavailable;
            return AICodedbProductLayerState.Unknown;
        }

        private static string ReadMarkerValue(string output, string prefix)
        {
            var value = string.Empty;
            foreach (var line in SplitLines(output))
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith(prefix, StringComparison.Ordinal))
                    value = trimmed.Substring(prefix.Length).Trim();
            }
            return value;
        }

        private static string FirstMarkedDetail(string output)
        {
            // Product-layer markers describe state, not the user-facing
            // reason. Prefer the explicit prerequisite/detail lines and only
            // fall back to a layer marker when an older producer omitted them.
            foreach (var line in SplitLines(output))
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("[PREREQUISITE]", StringComparison.Ordinal)
                    || trimmed.StartsWith("[DETAIL]", StringComparison.Ordinal))
                {
                    return trimmed;
                }
            }
            foreach (var line in SplitLines(output))
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith(PrerequisitePrefix, StringComparison.Ordinal)
                    || trimmed.StartsWith(InstalledPrefix, StringComparison.Ordinal)
                    || trimmed.StartsWith(ConfiguredPrefix, StringComparison.Ordinal)
                    || trimmed.StartsWith(McpAvailablePrefix, StringComparison.Ordinal))
                {
                    return trimmed;
                }
            }
            return string.Empty;
        }

        private static string FirstNonEmptyLine(string text)
        {
            foreach (var line in SplitLines(text))
            {
                var trimmed = line.Trim();
                if (!string.IsNullOrWhiteSpace(trimmed))
                    return trimmed;
            }
            return string.Empty;
        }

        private static string[] SplitLines(string text)
        {
            return (text ?? string.Empty).Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
        }
    }

    internal enum AICodedbHostPayloadState
    {
        Unknown,
        SetupRequired,
        Current,
        Draining,
        UpgradeReady,
        RedeployRequired,
        UpdateRequired,
        Conflict,
        Blocked
    }

    internal readonly struct AICodedbHostPayloadStatus
    {
        internal AICodedbHostPayloadState State { get; }
        internal AICodedbStatusState DisplayState { get; }
        internal string Summary { get; }
        internal string Detail { get; }
        internal string[] ActiveOwners { get; }
        internal int LegacyMcpSessionCount { get; }
        internal int ActiveMcpSessionCount => AICodedbHostPayloadStatusBuilder.CountActiveMcpSessions(ActiveOwners);
        internal int LegacyWatcherCount => AICodedbHostPayloadStatusBuilder.CountLegacyWatchers(ActiveOwners);
        internal bool HasOnlyLegacyWatcherOwners => ActiveOwners.Length > 0 && LegacyWatcherCount == ActiveOwners.Length;
        internal bool IsCurrent => State == AICodedbHostPayloadState.Current || State == AICodedbHostPayloadState.Draining;
        internal bool IsDraining => State == AICodedbHostPayloadState.Draining;
        internal bool CanUpgradeAutomatically => State == AICodedbHostPayloadState.UpgradeReady;
        internal bool CanRedeploy { get; }

        internal AICodedbHostPayloadStatus(
            AICodedbHostPayloadState state,
            AICodedbStatusState displayState,
            string summary,
            string detail,
            string[] activeOwners = null,
            int legacyMcpSessionCount = 0,
            bool canRedeploy = false)
        {
            State = state;
            DisplayState = displayState;
            Summary = summary ?? string.Empty;
            Detail = detail ?? string.Empty;
            ActiveOwners = activeOwners ?? Array.Empty<string>();
            LegacyMcpSessionCount = Math.Max(0, legacyMcpSessionCount);
            CanRedeploy = canRedeploy;
        }

        internal AICodedbStatusItem ToStatusItem()
        {
            switch (DisplayState)
            {
                case AICodedbStatusState.Ok:
                    return AICodedbStatusItem.Ok("Host payload", Summary, Detail);
                case AICodedbStatusState.Warning:
                    return AICodedbStatusItem.Warning("Host payload", Summary, Detail);
                default:
                    return AICodedbStatusItem.Error("Host payload", Summary, Detail);
            }
        }
    }

    internal static class AICodedbHostPayloadStatusBuilder
    {
        private static readonly Regex GenerationOwnerPattern = new Regex(
            @"^\[ACTIVE\]\s+generation\s+([A-Za-z0-9._-]{1,64})\s+(mcp|watcher)\s+PID\s+[0-9]+\s*$",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        private static readonly Regex LegacyOwnerPattern = new Regex(
            @"^\[ACTIVE\]\s+(mcp|watcher)\s+PID\s+[0-9]+\s*$",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

        internal static AICodedbHostPayloadStatus Build(
            bool markerExists,
            AICodedbCommandResult result,
            string currentGenerationId = "")
        {
            if (result == null)
                return Unknown("Materializer status has not been checked.");

            var output = result.StandardOutput ?? string.Empty;
            var error = result.StandardError ?? string.Empty;
            var combined = output + "\n" + error;
            var activeOwners = MatchingLines(combined, "[ACTIVE]");
            var legacyMcpSessionCount = CountLegacyMcpSessions(activeOwners);
            var canRedeploy = Contains(output, "[REDEPLOY_READY]");

            if (Contains(combined, "[CONFLICT]") || Contains(combined, "Host payload has conflicts"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Conflict,
                    AICodedbStatusState.Error,
                    "CONFLICT",
                    FirstMatchingLine(combined, "[CONFLICT]", "Host payload has conflicts"));
            }

            if (result.TimedOut)
                return Unknown("Materializer DryRun timed out.");

            if (!result.Succeeded)
            {
                var detail = FirstNonEmptyLine(error);
                return Unknown(string.IsNullOrWhiteSpace(detail) ? result.GetSummary() : detail);
            }

            // The immutable-instance engine reports layered readiness instead
            // of the historical "[OK] Host payload" marker. Treat only the
            // complete READY tuple as a current Host result; wrapper startup
            // or a partial layer must remain non-current.
            if (Contains(output, "[PRODUCT_STATE] READY")
                && Contains(output, "[PRODUCT_LAYER INSTALLED] CURRENT")
                && Contains(output, "[PRODUCT_LAYER CONFIGURED] CURRENT")
                && Contains(output, "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Current,
                    AICodedbStatusState.Ok,
                    "CURRENT",
                    "The selected immutable CodeDB instance passed its readiness handshake.",
                    activeOwners,
                    legacyMcpSessionCount);
            }

            if (Contains(output, "[OK] Host payload is current.")
                || Contains(output, "[OK] Host payload marker and managed files are current."))
            {
                var draining = HasDrainingOwners(activeOwners, currentGenerationId);
                return new AICodedbHostPayloadStatus(
                    draining ? AICodedbHostPayloadState.Draining : AICodedbHostPayloadState.Current,
                    AICodedbStatusState.Ok,
                    draining ? "CURRENT / DRAINING" : "CURRENT",
                    draining
                        ? "The current generation is ready while legacy or previous-generation sessions finish naturally; no action is required."
                        : AICodedbProjectSettings.HostPayloadMarkerRelativePath,
                    activeOwners,
                    legacyMcpSessionCount);
            }

            if (Contains(output, "[UPGRADE_READY]"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.UpgradeReady,
                    AICodedbStatusState.Warning,
                    "UPGRADE_READY",
                    FirstMatchingLine(output, "[UPGRADE_READY]"),
                    activeOwners,
                    legacyMcpSessionCount);
            }

            if (Contains(output, "[BLOCKED]"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Blocked,
                    AICodedbStatusState.Error,
                    markerExists ? "UPDATE_REQUIRED / BLOCKED" : "SETUP_REQUIRED / BLOCKED",
                    activeOwners.Length > 0
                        ? string.Join("\n", activeOwners)
                        : FirstMatchingLine(output, "[BLOCKED]"),
                    activeOwners,
                    legacyMcpSessionCount,
                    canRedeploy);
            }

            if (canRedeploy)
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.RedeployRequired,
                    AICodedbStatusState.Warning,
                    "REDEPLOY_REQUIRED",
                    FirstMatchingLine(output, "[REDEPLOY_READY]"),
                    activeOwners,
                    legacyMcpSessionCount,
                    true);
            }

            if (Contains(output, "[PRODUCT_STATE] MISSING_PREREQUISITE"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.SetupRequired,
                    AICodedbStatusState.Warning,
                    "MISSING_PREREQUISITE",
                    FirstMatchingLine(output, "[PREREQUISITE]", "[DETAIL]", "[PRODUCT_STATE] MISSING_PREREQUISITE"),
                    activeOwners,
                    legacyMcpSessionCount,
                    canRedeploy);
            }

            // The immutable-instance status path reports a structured product
            // state even when a coordinator is temporarily unavailable. Keep
            // that state and its diagnostic visible instead of falling through
            // to the misleading "unrecognized result" status.
            if (Contains(output, "[PRODUCT_STATE] NEEDS_ATTENTION"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Blocked,
                    AICodedbStatusState.Error,
                    "NEEDS_ATTENTION",
                    FirstMatchingLine(output, "[DETAIL]", "[PRODUCT_STATE] NEEDS_ATTENTION"),
                    activeOwners,
                    legacyMcpSessionCount,
                    canRedeploy);
            }

            if (Contains(output, "[PRODUCT_STATE] STARTING"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Unknown,
                    AICodedbStatusState.Warning,
                    "STARTING",
                    FirstMatchingLine(output, "[DETAIL]", "[PRODUCT_STATE] STARTING"),
                    activeOwners,
                    legacyMcpSessionCount,
                    canRedeploy);
            }

            if (Contains(output, "[STALE] Host payload can be synchronized"))
            {
                return new AICodedbHostPayloadStatus(
                    markerExists ? AICodedbHostPayloadState.UpdateRequired : AICodedbHostPayloadState.SetupRequired,
                    AICodedbStatusState.Warning,
                    markerExists ? "UPDATE_REQUIRED" : "SETUP_REQUIRED",
                    LastMarkedLine(output),
                    activeOwners,
                    legacyMcpSessionCount);
            }

            return Unknown("Materializer DryRun returned an unrecognized result.");
        }

        private static AICodedbHostPayloadStatus Unknown(string detail)
        {
            return new AICodedbHostPayloadStatus(
                AICodedbHostPayloadState.Unknown,
                AICodedbStatusState.Error,
                "Check Failed",
                detail);
        }

        private static string FirstMatchingLine(string text, params string[] values)
        {
            foreach (var line in SplitLines(text))
            {
                foreach (var value in values)
                {
                    if (Contains(line, value))
                        return line.Trim();
                }
            }

            return FirstNonEmptyLine(text);
        }

        private static string[] MatchingLines(string text, string value)
        {
            var matches = new List<string>();
            foreach (var line in SplitLines(text))
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith(value, StringComparison.OrdinalIgnoreCase))
                    matches.Add(trimmed);
            }
            return matches.ToArray();
        }

        private static bool HasDrainingOwners(string[] activeOwners, string currentGenerationId)
        {
            foreach (var owner in activeOwners)
            {
                var generationMatch = GenerationOwnerPattern.Match(owner);
                if (generationMatch.Success)
                {
                    if (!string.Equals(generationMatch.Groups[1].Value, currentGenerationId, StringComparison.Ordinal))
                        return true;
                    continue;
                }

                // Legacy host-use leases do not carry a generation. Unknown owner syntax
                // also fails closed so a changed materializer contract remains visible.
                return true;
            }
            return false;
        }

        private static int CountLegacyMcpSessions(string[] activeOwners)
        {
            return CountOwners(activeOwners, "mcp", true);
        }

        internal static int CountActiveMcpSessions(string[] activeOwners)
        {
            return CountOwners(activeOwners, "mcp", false);
        }

        internal static int CountLegacyWatchers(string[] activeOwners)
        {
            return CountOwners(activeOwners, "watcher", true);
        }

        private static int CountOwners(string[] activeOwners, string expectedKind, bool legacyOnly)
        {
            var count = 0;
            foreach (var owner in activeOwners ?? Array.Empty<string>())
            {
                var legacyMatch = LegacyOwnerPattern.Match(owner ?? string.Empty);
                if (legacyMatch.Success)
                {
                    if (string.Equals(legacyMatch.Groups[1].Value, expectedKind, StringComparison.OrdinalIgnoreCase))
                        count++;
                    continue;
                }

                if (legacyOnly)
                    continue;

                var generationMatch = GenerationOwnerPattern.Match(owner ?? string.Empty);
                if (generationMatch.Success
                    && string.Equals(generationMatch.Groups[2].Value, expectedKind, StringComparison.OrdinalIgnoreCase))
                    count++;
            }
            return count;
        }

        private static string LastMarkedLine(string text)
        {
            var match = string.Empty;
            foreach (var line in SplitLines(text))
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("[OK]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[STALE]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[CONFLICT]", StringComparison.OrdinalIgnoreCase))
                    match = trimmed;
            }

            return match;
        }

        private static string FirstNonEmptyLine(string text)
        {
            foreach (var line in SplitLines(text))
            {
                var trimmed = line.Trim();
                if (!string.IsNullOrWhiteSpace(trimmed))
                    return trimmed;
            }

            return string.Empty;
        }

        private static string[] SplitLines(string text)
        {
            return (text ?? string.Empty).Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
        }

        private static bool Contains(string text, string value)
        {
            return !string.IsNullOrWhiteSpace(text)
                   && text.IndexOf(value, StringComparison.OrdinalIgnoreCase) >= 0;
        }
    }

    internal enum AICodedbHostUpgradePhase
    {
        Unavailable,
        Installing,
        Switching,
        Rollback,
        Current,
        CheckFailed,
        Historical,
        Invalid
    }

    internal readonly struct AICodedbHostUpgradeStatus
    {
        internal AICodedbHostUpgradePhase Phase { get; }
        internal AICodedbStatusState DisplayState { get; }
        internal string GenerationId { get; }
        internal AICodedbProjectCleanupState CleanupState { get; }
        internal string Summary { get; }
        internal string Detail { get; }

        internal AICodedbHostUpgradeStatus(
            AICodedbHostUpgradePhase phase,
            AICodedbStatusState displayState,
            string generationId,
            string summary,
            string detail,
            AICodedbProjectCleanupState cleanupState = AICodedbProjectCleanupState.Complete)
        {
            Phase = phase;
            DisplayState = displayState;
            GenerationId = generationId ?? string.Empty;
            CleanupState = cleanupState;
            Summary = summary ?? string.Empty;
            Detail = detail ?? string.Empty;
        }

        internal AICodedbStatusItem ToStatusItem(bool hostPayloadMarkerExists)
        {
            if (Phase == AICodedbHostUpgradePhase.Historical)
                return AICodedbStatusItem.Inactive("Host upgrade", Summary, Detail);
            if (!hostPayloadMarkerExists
                && Phase != AICodedbHostUpgradePhase.Unavailable
                && Phase != AICodedbHostUpgradePhase.Invalid)
            {
                return AICodedbStatusItem.Inactive(
                    "Host upgrade",
                    "Historical " + Summary,
                    "No installed host payload marker exists. " + Detail);
            }
            switch (DisplayState)
            {
                case AICodedbStatusState.Ok:
                    return AICodedbStatusItem.Ok("Host upgrade", Summary, Detail);
                case AICodedbStatusState.Inactive:
                    return AICodedbStatusItem.Inactive("Host upgrade", Summary, Detail);
                case AICodedbStatusState.Warning:
                    return AICodedbStatusItem.Warning("Host upgrade", Summary, Detail);
                default:
                    return AICodedbStatusItem.Error("Host upgrade", Summary, Detail);
            }
        }
    }

    internal static class AICodedbHostUpgradeStatusStore
    {
        private const string ManagedBy = "com.rice.ai-codedb";

        internal static AICodedbHostUpgradeStatus Read(string projectRoot)
        {
            return Read(projectRoot, string.Empty);
        }

        internal static AICodedbHostUpgradeStatus Read(string projectRoot, string expectedGenerationId)
        {
            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
                var path = AICodedbPaths.NormalizePath(Path.Combine(
                    normalizedRoot,
                    AICodedbProjectSettings.HostPayloadUpgradeStateRelativePath));
                AssertSafeStatePath(normalizedRoot, path);
                if (!File.Exists(path))
                {
                    return new AICodedbHostUpgradeStatus(
                        AICodedbHostUpgradePhase.Unavailable,
                        AICodedbStatusState.Inactive,
                        string.Empty,
                        "No recorded upgrade",
                        AICodedbProjectSettings.HostPayloadUpgradeStateRelativePath);
                }

                var value = AICodedbStrictJson.ReadObject(path, 64 * 1024, "Host upgrade state");
                return ParseDocument(value, normalizedRoot, path, expectedGenerationId);
            }
            catch (Exception exception)
            {
                return Invalid(exception.Message);
            }
        }

        internal static AICodedbHostUpgradeStatus Parse(
            string json,
            string projectRoot,
            string detailPath)
        {
            return Parse(json, projectRoot, detailPath, string.Empty);
        }

        internal static AICodedbHostUpgradeStatus Parse(
            string json,
            string projectRoot,
            string detailPath,
            string expectedGenerationId)
        {
            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
                var value = AICodedbStrictJson.ParseObject(json, "Host upgrade state");
                return ParseDocument(value, normalizedRoot, detailPath, expectedGenerationId);
            }
            catch (Exception exception)
            {
                return Invalid(exception.Message);
            }
        }

        private static AICodedbHostUpgradeStatus ParseDocument(
            Dictionary<string, object> value,
            string normalizedRoot,
            string detailPath,
            string expectedGenerationId)
        {
            var document = new HostUpgradeStateDocument
            {
                schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "Host upgrade state"),
                managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "Host upgrade state"),
                project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "Host upgrade state"),
                state = AICodedbStrictJson.GetRequiredString(value, "state", "Host upgrade state"),
                generation_id = AICodedbStrictJson.GetRequiredString(value, "generation_id", "Host upgrade state"),
                updated_at_utc = AICodedbStrictJson.GetRequiredString(value, "updated_at_utc", "Host upgrade state"),
                message = AICodedbStrictJson.GetRequiredNullableString(value, "message", "Host upgrade state")
            };
            var cleanupState = AICodedbProjectCleanupState.Complete;
            object cleanupStateValue;
            if (value.TryGetValue("cleanup_state", out cleanupStateValue))
            {
                var cleanupStateText = cleanupStateValue as string;
                if (string.Equals(cleanupStateText, "PENDING", StringComparison.Ordinal))
                    cleanupState = AICodedbProjectCleanupState.Pending;
                else if (!string.Equals(cleanupStateText, "COMPLETE", StringComparison.Ordinal))
                    throw new InvalidOperationException("Host upgrade state has an invalid cleanup_state.");
            }
            DateTime updatedAt;
            if (document.schema_version != 1
                    || !string.Equals(document.managed_by, ManagedBy, StringComparison.Ordinal)
                    || !string.Equals(
                        AICodedbPaths.NormalizePath(document.project_root).TrimEnd('/'),
                        normalizedRoot,
                        StringComparison.OrdinalIgnoreCase)
                    || !IsValidGenerationId(document.generation_id)
                    || !DateTime.TryParse(
                        document.updated_at_utc,
                        CultureInfo.InvariantCulture,
                        DateTimeStyles.RoundtripKind,
                        out updatedAt)
                    || (document.message != null && document.message.Length > 512))
                throw new InvalidOperationException("Host upgrade state has invalid identity or schema.");

            var detail = string.IsNullOrWhiteSpace(document.message)
                ? (detailPath ?? string.Empty)
                : document.message.Trim();
            if (document.state != "INSTALLING"
                && document.state != "SWITCHING"
                && document.state != "ROLLBACK"
                && document.state != "CURRENT"
                && document.state != "CHECK_FAILED")
                throw new InvalidOperationException("Host upgrade state has an unsupported phase.");
            if (!string.IsNullOrWhiteSpace(expectedGenerationId)
                && !string.Equals(document.generation_id, expectedGenerationId, StringComparison.Ordinal))
            {
                return new AICodedbHostUpgradeStatus(
                    AICodedbHostUpgradePhase.Historical,
                    AICodedbStatusState.Inactive,
                    document.generation_id,
                    "Historical " + document.state + " / " + document.generation_id,
                    "Recorded for a previous target generation; current target is " + expectedGenerationId + ". " + detail,
                    cleanupState);
            }
            switch (document.state)
            {
                case "INSTALLING":
                    return Create(AICodedbHostUpgradePhase.Installing, AICodedbStatusState.Warning, document, detail, cleanupState);
                case "SWITCHING":
                    return Create(AICodedbHostUpgradePhase.Switching, AICodedbStatusState.Warning, document, detail, cleanupState);
                case "ROLLBACK":
                    return Create(AICodedbHostUpgradePhase.Rollback, AICodedbStatusState.Error, document, detail, cleanupState);
                case "CURRENT":
                    return Create(AICodedbHostUpgradePhase.Current, AICodedbStatusState.Ok, document, detail, cleanupState);
                case "CHECK_FAILED":
                    return Create(AICodedbHostUpgradePhase.CheckFailed, AICodedbStatusState.Error, document, detail, cleanupState);
                default:
                    throw new InvalidOperationException("Host upgrade state has an unsupported phase.");
            }
        }

        private static AICodedbHostUpgradeStatus Create(
            AICodedbHostUpgradePhase phase,
            AICodedbStatusState displayState,
            HostUpgradeStateDocument document,
            string detail,
            AICodedbProjectCleanupState cleanupState)
        {
            return new AICodedbHostUpgradeStatus(
                phase,
                displayState,
                document.generation_id,
                document.state + " / " + document.generation_id,
                detail,
                cleanupState);
        }

        private static AICodedbHostUpgradeStatus Invalid(string detail)
        {
            return new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Invalid,
                AICodedbStatusState.Error,
                string.Empty,
                "CHECK_FAILED",
                detail);
        }

        private static bool IsValidGenerationId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 64)
                return false;
            foreach (var character in value)
            {
                if ((character < 'A' || character > 'Z')
                    && (character < 'a' || character > 'z')
                    && (character < '0' || character > '9')
                    && character != '.'
                    && character != '_'
                    && character != '-')
                    return false;
            }
            return true;
        }

        private static void AssertSafeStatePath(string projectRoot, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var current = AICodedbPaths.NormalizePath(path).TrimEnd('/');
            if (!current.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Host upgrade state escapes the Unity project.");

            while (!string.Equals(current, normalizedRoot, StringComparison.OrdinalIgnoreCase))
            {
                if (File.Exists(current) || Directory.Exists(current))
                {
                    var attributes = File.GetAttributes(current);
                    if ((attributes & FileAttributes.ReparsePoint) != 0)
                        throw new InvalidOperationException("Host upgrade state contains a reparse point.");
                }
                var parent = Path.GetDirectoryName(current);
                if (string.IsNullOrWhiteSpace(parent))
                    throw new InvalidOperationException("Host upgrade state has no valid parent.");
                current = AICodedbPaths.NormalizePath(parent).TrimEnd('/');
            }
        }

        [Serializable]
        private sealed class HostUpgradeStateDocument
        {
            public int schema_version;
            public string managed_by;
            public string project_root;
            public string state;
            public string generation_id;
            public string updated_at_utc;
            public string message;
        }
    }
}
