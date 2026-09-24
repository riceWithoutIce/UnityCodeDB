using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.IO;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbCommandResult
    {
        internal int ExitCode { get; }
        internal string StandardOutput { get; }
        internal string StandardError { get; }
        internal bool TimedOut { get; }
        internal long ElapsedMilliseconds { get; }
        internal string ActionId { get; }
        internal bool HasAuthoritativeTerminalEvidence { get; }
        internal bool TerminalForManagerAction { get; }
        // Only the Supervisor Bridge may set this bit. It records a
        // read-only proof that the command is in the empty-runtime bootstrap
        // case; callers must never infer fallback permission from text output.
        internal bool OneShotFallbackAuthorized { get; }
        internal bool Succeeded => !TimedOut && ExitCode == 0;

        /// <summary>
        /// Creates a command result captured from a local process run.
        /// </summary>
        /// <param name="exitCode">Process exit code.</param>
        /// <param name="standardOutput">Captured stdout text.</param>
        /// <param name="standardError">Captured stderr text.</param>
        /// <param name="timedOut">Whether the process exceeded the timeout.</param>
        /// <param name="elapsedMilliseconds">Elapsed wall-clock time for the command.</param>
        internal AICodedbCommandResult(
            int exitCode,
            string standardOutput,
            string standardError,
            bool timedOut,
            long elapsedMilliseconds = 0,
            bool oneShotFallbackAuthorized = false,
            bool authoritativeTerminalEvidence = true,
            string actionId = null,
            bool terminalForManagerAction = true)
        {
            ExitCode = exitCode;
            StandardOutput = standardOutput ?? string.Empty;
            StandardError = standardError ?? string.Empty;
            TimedOut = timedOut;
            ElapsedMilliseconds = Math.Max(0, elapsedMilliseconds);
            ActionId = actionId ?? AICodedbPaths.CurrentActionId;
            OneShotFallbackAuthorized = oneShotFallbackAuthorized;
            HasAuthoritativeTerminalEvidence = authoritativeTerminalEvidence;
            TerminalForManagerAction = terminalForManagerAction;
        }

        /// <summary>
        /// Builds a compact status line suitable for Editor UI.
        /// </summary>
        internal string GetSummary()
        {
            if (TimedOut)
                return "Command timed out.";

            if (!Succeeded)
                return $"Command failed with exit code {ExitCode}.";

            if (HasLeadingFreshnessWarningMarker(StandardOutput))
                return "Command completed with warning.";

            return "Command completed successfully.";
        }

        /// <summary>
        /// Builds a readable command output block for the result window.
        /// </summary>
        internal string GetDisplayText()
        {
            var builder = new StringBuilder();
            builder.AppendLine(GetSummary());
            builder.AppendLine();
            builder.AppendLine($"Exit Code: {ExitCode}");
            if (ElapsedMilliseconds > 0)
                builder.AppendLine($"Elapsed: {GetElapsedText()}");
            if (!string.IsNullOrWhiteSpace(ActionId))
                builder.AppendLine("Action ID: " + ActionId);

            if (TimedOut)
                builder.AppendLine("Timed Out: True");

            AppendSection(builder, "Output", StandardOutput);
            AppendSection(builder, "Error", StandardError);

            return builder.ToString();
        }

        /// <summary>
        /// Returns a compact elapsed-time label for Editor UI.
        /// </summary>
        internal string GetElapsedText()
        {
            if (ElapsedMilliseconds <= 0)
                return "n/a";

            if (ElapsedMilliseconds < 1000)
                return ElapsedMilliseconds.ToString(CultureInfo.InvariantCulture) + " ms";

            var seconds = ElapsedMilliseconds / 1000d;
            if (seconds < 60d)
                return seconds.ToString("0.00", CultureInfo.InvariantCulture) + " s";

            var minutes = seconds / 60d;
            return minutes.ToString("0.0", CultureInfo.InvariantCulture) + " min";
        }

        /// <summary>
        /// Appends a named output section when it has content.
        /// </summary>
        /// <param name="builder">String builder receiving the section.</param>
        /// <param name="title">Section title.</param>
        /// <param name="content">Section body.</param>
        private static void AppendSection(StringBuilder builder, string title, string content)
        {
            if (string.IsNullOrWhiteSpace(content))
                return;

            builder.AppendLine();
            builder.AppendLine(title + ":");
            builder.AppendLine(content.TrimEnd());
        }

        /// <summary>
        /// Returns whether the first structured output marker reports stale or unknown freshness.
        /// </summary>
        /// <param name="output">Captured standard output.</param>
        private static bool HasLeadingFreshnessWarningMarker(string output)
        {
            if (string.IsNullOrWhiteSpace(output))
                return false;

            var lines = output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("[STALE]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[UNKNOWN]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[CONFLICT]", StringComparison.OrdinalIgnoreCase))
                    return true;

                if (trimmed.StartsWith("[OK]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[NO HIT]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[SKIP]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[FAIL]", StringComparison.OrdinalIgnoreCase))
                    return false;
            }

            return false;
        }
    }

    internal enum AICodedbManagerActionRecoveryState
    {
        NotFound,
        Pending,
        Terminal,
        Conflict
    }

    internal sealed class AICodedbManagerActionRecoveryOutcome
    {
        internal AICodedbManagerActionRecoveryState State { get; }
        internal AICodedbCommandResult Result { get; }
        internal string Detail { get; }

        private AICodedbManagerActionRecoveryOutcome(
            AICodedbManagerActionRecoveryState state,
            AICodedbCommandResult result,
            string detail)
        {
            State = state;
            Result = result;
            Detail = detail ?? string.Empty;
        }

        internal static AICodedbManagerActionRecoveryOutcome NotFound(string detail) =>
            new AICodedbManagerActionRecoveryOutcome(
                AICodedbManagerActionRecoveryState.NotFound, null, detail);
        internal static AICodedbManagerActionRecoveryOutcome Pending(string detail) =>
            new AICodedbManagerActionRecoveryOutcome(
                AICodedbManagerActionRecoveryState.Pending, null, detail);
        internal static AICodedbManagerActionRecoveryOutcome Terminal(AICodedbCommandResult result) =>
            new AICodedbManagerActionRecoveryOutcome(
                AICodedbManagerActionRecoveryState.Terminal, result, string.Empty);
        internal static AICodedbManagerActionRecoveryOutcome Conflict(string detail) =>
            new AICodedbManagerActionRecoveryOutcome(
                AICodedbManagerActionRecoveryState.Conflict, null, detail);
    }

    internal static class AICodedbProcessRunner
    {
        private const int DefaultTimeoutMilliseconds = 120000;
        private const int OutputDrainTimeoutMilliseconds = 1000;
        private const int ManagerActionReceiptMaximumBytes = 4 * 1024 * 1024;
        private const int ManagerActionWriterGraceMilliseconds = 30000;
        private static readonly object ActiveProcessLock = new object();
        private static readonly List<Process> ActiveBackgroundProcesses = new List<Process>();

        private enum PowerShellScriptPathPolicy
        {
            ProjectLocal,
            ResolvedPackageMaterializer,
            ResolvedPackageProviderInstaller
        }

        /// <summary>
        /// Runs a project-local PowerShell script and captures its output.
        /// </summary>
        /// <param name="scriptPath">Absolute path to a script under the Unity project root.</param>
        internal static AICodedbCommandResult RunPowerShellScript(string scriptPath)
        {
            return RunPowerShellScript(scriptPath, DefaultTimeoutMilliseconds);
        }

        /// <summary>
        /// Runs a project-local PowerShell script with a timeout and captures its output.
        /// </summary>
        /// <param name="scriptPath">Absolute path to a script under the Unity project root.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the PowerShell script.</param>
        internal static AICodedbCommandResult RunPowerShellScript(string scriptPath, int timeoutMilliseconds, params string[] scriptArguments)
        {
            return RunPowerShellScript(
                AICodedbPaths.CaptureExecutionContext(),
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        internal static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        /// <summary>
        /// Runs a project-local script with the validated immutable instance
        /// root supplied to generation-aware scripts through their normal
        /// runtime environment contract.
        /// </summary>
        internal static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            string instanceRoot,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                null,
                instanceRoot,
                CancellationToken.None,
                false,
                scriptArguments);
        }

        /// <summary>
        /// Runs a project watcher command that belongs to an interruptible
        /// lifecycle maintenance pass. The cancellation token only stops the
        /// Package-owned PowerShell parent; it never targets its external
        /// Provider/MCP children.
        /// </summary>
        internal static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            string instanceRoot,
            CancellationToken cancellationToken,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                null,
                instanceRoot,
                cancellationToken,
                true,
                scriptArguments);
        }

        /// <summary>
        /// Runs only the materializer script owned by the CodeDB Package resolved for this assembly.
        /// </summary>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the materializer.</param>
        internal static AICodedbCommandResult RunResolvedPackageMaterializerPowerShellScript(
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                AICodedbPaths.CaptureExecutionContext(),
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        internal static AICodedbCommandResult RunResolvedPackageMaterializerPowerShellScript(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        internal static AICodedbCommandResult RunResolvedPackageMaterializerPowerShellScript(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            CancellationToken cancellationToken,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                null,
                null,
                cancellationToken,
                true,
                scriptArguments);
        }

        /// <summary>
        /// Runs only the Package-owned Provider installer resolved for this assembly.
        /// </summary>
        internal static AICodedbCommandResult RunResolvedPackageProviderInstallerPowerShellScript(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageProviderInstaller,
                scriptArguments);
        }

        /// <summary>
        /// Runs a project-local PowerShell script on a worker thread so Editor initialization stays responsive.
        /// </summary>
        /// <param name="scriptPath">Absolute path to a script under the Unity project root.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the PowerShell script.</param>
        internal static Task<AICodedbCommandResult> RunPowerShellScriptAsync(
            string scriptPath,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                AICodedbPaths.CaptureExecutionContext(),
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        internal static Task<AICodedbCommandResult> RunPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                context,
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        /// <summary>
        /// Runs the resolved Package-owned materializer on a worker thread.
        /// </summary>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the materializer.</param>
        internal static Task<AICodedbCommandResult> RunResolvedPackageMaterializerPowerShellScriptAsync(
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                AICodedbPaths.CaptureExecutionContext(),
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        internal static Task<AICodedbCommandResult> RunResolvedPackageMaterializerPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        /// <summary>
        /// Runs the Package-owned Provider installer on a worker thread.
        /// </summary>
        internal static Task<AICodedbCommandResult> RunResolvedPackageProviderInstallerPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageProviderInstaller,
                scriptArguments);
        }

        /// <summary>
        /// Runs the Package-owned Provider installer and forwards trusted stdout
        /// stage lines while the process is still running.
        /// </summary>
        /// <param name="context">Captured Editor execution context.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="outputLine">Callback invoked from the process output reader thread.</param>
        /// <param name="scriptArguments">Optional arguments passed to the installer.</param>
        internal static Task<AICodedbCommandResult> RunResolvedPackageProviderInstallerPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            Action<string> outputLine,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageProviderInstaller,
                outputLine,
                scriptArguments);
        }

        private static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            PowerShellScriptPathPolicy pathPolicy,
            string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                scriptPath,
                timeoutMilliseconds,
                pathPolicy,
                null,
                null,
                CancellationToken.None,
                false,
                scriptArguments);
        }

        private static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            PowerShellScriptPathPolicy pathPolicy,
            Action<string> outputLine,
            string instanceRoot,
            CancellationToken cancellationToken,
            bool cancelOnDomainReload,
            string[] scriptArguments)
        {
            if (context.Platform != RuntimePlatform.WindowsEditor)
                return UnsupportedPlatformResult();

            if (timeoutMilliseconds <= 0)
                timeoutMilliseconds = DefaultTimeoutMilliseconds;

            string normalizedScriptPath;
            string authorizationError;
            if (!TryAuthorizePowerShellScriptPath(
                    pathPolicy,
                    context,
                    scriptPath,
                    out normalizedScriptPath,
                    out authorizationError))
            {
                return new AICodedbCommandResult(-1, string.Empty, authorizationError, false);
            }

            if (AICodedbSupervisorProtocol.IsManagerActionId(AICodedbPaths.CurrentActionId))
            {
                return RunDurableManagerAction(
                    context,
                    normalizedScriptPath,
                    timeoutMilliseconds,
                    scriptArguments);
            }

            return RunProcess(
                BuildPowerShellStartInfo(context, normalizedScriptPath, instanceRoot, scriptArguments),
                timeoutMilliseconds,
                outputLine,
                cancellationToken,
                cancelOnDomainReload);
        }

        private static Task<AICodedbCommandResult> RunPowerShellScriptAsyncCore(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            PowerShellScriptPathPolicy pathPolicy,
            string[] scriptArguments)
        {
            return RunPowerShellScriptAsyncCore(
                context,
                scriptPath,
                timeoutMilliseconds,
                pathPolicy,
                null,
                scriptArguments);
        }

        private static Task<AICodedbCommandResult> RunPowerShellScriptAsyncCore(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            PowerShellScriptPathPolicy pathPolicy,
            Action<string> outputLine,
            string[] scriptArguments)
        {
            if (context.Platform != RuntimePlatform.WindowsEditor)
                return Task.FromResult(UnsupportedPlatformResult());

            if (timeoutMilliseconds <= 0)
                timeoutMilliseconds = DefaultTimeoutMilliseconds;

            var effectiveTimeout = timeoutMilliseconds;
            return Task.Run(() => RunPowerShellScript(
                context,
                scriptPath,
                effectiveTimeout,
                pathPolicy,
                outputLine,
                null,
                CancellationToken.None,
                true,
                scriptArguments));
        }

        /// <summary>
        /// Cancels Package-owned background process parents before Unity starts
        /// unloading the managed domain. Child Provider/MCP processes are not
        /// enumerated or terminated here.
        /// </summary>
        internal static void CancelBackgroundProcesses()
        {
            Process[] processes;
            lock (ActiveProcessLock)
                processes = ActiveBackgroundProcesses.ToArray();

            foreach (var process in processes)
                TryKillProcess(process);
        }

        private static AICodedbCommandResult RunDurableManagerAction(
            AICodedbEditorExecutionContext context,
            string normalizedScriptPath,
            int timeoutMilliseconds,
            string[] scriptArguments)
        {
            var actionId = AICodedbPaths.CurrentActionId;
            var writerPath = AICodedbPaths.NormalizePath(Path.Combine(
                context.PackageRoot,
                "Tools~/invoke-codedb-manager-action.ps1"));
            if (!TryValidateResolvedPackageOwnedScriptPath(
                    context.PackageRoot,
                    writerPath,
                    "Tools~/invoke-codedb-manager-action.ps1",
                    "CodeDB Package Manager action writer",
                    out var normalizedWriterPath,
                    out var writerError))
            {
                return UnconfirmedManagerActionResult(actionId, writerError);
            }

            try
            {
                var arguments = scriptArguments ?? new string[0];
                var scriptSha256 = GetFileSha256(normalizedScriptPath);
                var argumentSha256 = ComputeSha256(string.Join("\n", arguments));
                var commandIdentity = ComputeSha256(
                    scriptSha256 + "\n" + argumentSha256 + "\n"
                    + timeoutMilliseconds.ToString(CultureInfo.InvariantCulture));
                var stageName = string.IsNullOrWhiteSpace(AICodedbPaths.CurrentActionStage)
                    ? Path.GetFileName(normalizedScriptPath) + ":" + argumentSha256.Substring(0, 16)
                    : AICodedbPaths.CurrentActionStage;
                var stageId = ComputeSha256(actionId + "\n" + stageName + "\n" + commandIdentity);
                var actionRoot = AICodedbPaths.GetManagerActionReceiptRoot(context, actionId);
                var stageRoot = AICodedbPaths.NormalizePath(Path.Combine(actionRoot, stageId));
                EnsureReceiptDirectory(context, actionRoot, stageRoot);
                var admittedPath = Path.Combine(stageRoot, "admitted.json");
                if (File.Exists(admittedPath)
                    || File.Exists(Path.Combine(stageRoot, "claim.json"))
                    || File.Exists(Path.Combine(stageRoot, "terminal.json")))
                {
                    return UnconfirmedManagerActionResult(
                        actionId,
                        "The Manager action stage already has durable evidence; automatic replay was blocked.");
                }

                var admitted = BuildManagerActionAdmissionJson(
                    context,
                    actionId,
                    stageId,
                    normalizedWriterPath,
                    normalizedScriptPath,
                    scriptSha256,
                    argumentSha256,
                    commandIdentity,
                    timeoutMilliseconds,
                    arguments);
                WriteNewUtf8FileAtomic(admittedPath, admitted);

                var writerResult = RunProcess(
                    BuildPowerShellStartInfo(
                        context,
                        normalizedWriterPath,
                        null,
                        new[] { "-ReceiptPath", stageRoot }),
                    checked(timeoutMilliseconds + ManagerActionWriterGraceMilliseconds));
                var terminalPath = Path.Combine(stageRoot, "terminal.json");
                if (!File.Exists(terminalPath))
                {
                    var detail = writerResult.TimedOut
                        ? "The one-shot Manager action writer exceeded its bounded handoff window."
                        : "The one-shot Manager action writer exited without a terminal receipt.";
                    if (!string.IsNullOrWhiteSpace(writerResult.StandardError))
                        detail += " " + writerResult.StandardError.Trim();
                    return UnconfirmedManagerActionResult(actionId, detail);
                }

                var outcome = ReadTerminalReceipt(context, actionId, terminalPath);
                return outcome.State == AICodedbManagerActionRecoveryState.Terminal
                    ? outcome.Result
                    : UnconfirmedManagerActionResult(actionId, outcome.Detail);
            }
            catch (Exception exception)
            {
                return UnconfirmedManagerActionResult(actionId, exception.Message);
            }
        }

        internal static AICodedbManagerActionRecoveryOutcome RecoverManagerAction(
            AICodedbEditorExecutionContext context,
            string actionId)
        {
            if (!AICodedbSupervisorProtocol.IsManagerActionId(actionId))
                return AICodedbManagerActionRecoveryOutcome.Conflict("The persisted Manager action id is invalid.");
            try
            {
                var actionRoot = AICodedbPaths.GetManagerActionReceiptRoot(context, actionId);
                if (!Directory.Exists(actionRoot))
                    return AICodedbManagerActionRecoveryOutcome.NotFound(
                        "No Package-owned direct-command receipt exists for this action.");
                AssertReceiptPath(context, actionRoot);
                var stageDirectories = Directory.GetDirectories(actionRoot);
                if (stageDirectories.Length > 32)
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "The Manager action receipt contains too many stage entries.");

                AICodedbCommandResult terminalResult = null;
                var evidenceObserved = false;
                foreach (var stageDirectory in stageDirectories)
                {
                    AssertReceiptPath(context, stageDirectory);
                    evidenceObserved = true;
                    var terminalPath = Path.Combine(stageDirectory, "terminal.json");
                    if (!File.Exists(terminalPath))
                        continue;
                    var outcome = ReadTerminalReceipt(context, actionId, terminalPath);
                    if (outcome.State == AICodedbManagerActionRecoveryState.Conflict)
                        return outcome;
                    if (outcome.State != AICodedbManagerActionRecoveryState.Terminal)
                        continue;
                    if (!outcome.Result.TerminalForManagerAction)
                        continue;
                    if (terminalResult != null)
                        return AICodedbManagerActionRecoveryOutcome.Conflict(
                            "Multiple terminal stages claim the same Manager action.");
                    terminalResult = outcome.Result;
                }

                if (terminalResult != null)
                    return AICodedbManagerActionRecoveryOutcome.Terminal(terminalResult);
                return evidenceObserved
                    ? AICodedbManagerActionRecoveryOutcome.Pending(
                        "The direct command has admitted or claimed evidence but no matching terminal receipt; no replay was attempted.")
                    : AICodedbManagerActionRecoveryOutcome.NotFound(
                        "No Package-owned direct-command stage exists for this action.");
            }
            catch (Exception exception)
            {
                return AICodedbManagerActionRecoveryOutcome.Conflict(
                    "Manager action receipt validation failed: " + exception.Message);
            }
        }

        private static AICodedbManagerActionRecoveryOutcome ReadTerminalReceipt(
            AICodedbEditorExecutionContext context,
            string actionId,
            string terminalPath)
        {
            AssertReceiptPath(context, terminalPath);
            var stageRoot = Path.GetDirectoryName(terminalPath);
            var stageId = Path.GetFileName(stageRoot);
            var admitted = AICodedbStrictJson.ReadObject(
                Path.Combine(stageRoot, "admitted.json"),
                ManagerActionReceiptMaximumBytes,
                "CodeDB Manager action admission");
            var claim = AICodedbStrictJson.ReadObject(
                Path.Combine(stageRoot, "claim.json"),
                ManagerActionReceiptMaximumBytes,
                "CodeDB Manager action writer claim");
            var receipt = AICodedbStrictJson.ReadObject(
                terminalPath,
                ManagerActionReceiptMaximumBytes,
                "CodeDB Manager action terminal receipt");
            if (!HasValidManagerActionReceiptEnvelope(admitted, claim, receipt)
                || stageId.Length != 64 || !IsLowerHex(stageId)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "action_id", "CodeDB Manager action admission"),
                    actionId, StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "stage_id", "CodeDB Manager action admission"),
                    stageId, StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(claim, "action_id", "CodeDB Manager action writer claim"),
                    actionId, StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(claim, "stage_id", "CodeDB Manager action writer claim"),
                    stageId, StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "project_key", "CodeDB Manager action admission"),
                    AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "package_key", "CodeDB Manager action admission"),
                    AICodedbPaths.GetManagerActionPackageKey(context), StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(claim, "project_key", "CodeDB Manager action writer claim"),
                    AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(claim, "package_key", "CodeDB Manager action writer claim"),
                    AICodedbPaths.GetManagerActionPackageKey(context), StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(receipt, "stage_id", "CodeDB Manager action terminal receipt"),
                    stageId, StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "project_root", "CodeDB Manager action admission"),
                    context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "package_root", "CodeDB Manager action admission"),
                    context.PackageRoot, StringComparison.OrdinalIgnoreCase)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "command_identity_sha256", "CodeDB Manager action admission"),
                    AICodedbStrictJson.GetRequiredString(receipt, "command_identity_sha256", "CodeDB Manager action terminal receipt"),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "effect_class", "CodeDB Manager action admission"),
                    AICodedbStrictJson.GetRequiredString(receipt, "effect_class", "CodeDB Manager action terminal receipt"),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "authorization_source", "CodeDB Manager action admission"),
                    AICodedbStrictJson.GetRequiredString(receipt, "authorization_source", "CodeDB Manager action terminal receipt"),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "project_identity", "CodeDB Manager action admission"),
                    AICodedbStrictJson.GetRequiredString(receipt, "project_identity", "CodeDB Manager action terminal receipt"),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(admitted, "package_identity", "CodeDB Manager action admission"),
                    AICodedbStrictJson.GetRequiredString(receipt, "package_identity", "CodeDB Manager action terminal receipt"),
                    StringComparison.Ordinal)
                || AICodedbStrictJson.GetRequiredInt32(claim, "writer_pid", "CodeDB Manager action writer claim")
                   != AICodedbStrictJson.GetRequiredInt32(receipt, "writer_pid", "CodeDB Manager action terminal receipt")
                || AICodedbStrictJson.GetRequiredBoolean(admitted, "terminal_for_action", "CodeDB Manager action admission")
                   != AICodedbStrictJson.GetRequiredBoolean(receipt, "terminal_for_action", "CodeDB Manager action terminal receipt")
                || AICodedbStrictJson.GetRequiredInt32(
                    receipt,
                    "schema_version",
                    "CodeDB Manager action terminal receipt") != 1
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(receipt, "managed_by", "CodeDB Manager action terminal receipt"),
                    "com.rice.ai-codedb",
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(receipt, "state", "CodeDB Manager action terminal receipt"),
                    "terminal",
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(receipt, "action_id", "CodeDB Manager action terminal receipt"),
                    actionId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(receipt, "project_key", "CodeDB Manager action terminal receipt"),
                    AICodedbPaths.GetManagerActionProjectKey(context),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(receipt, "package_key", "CodeDB Manager action terminal receipt"),
                    AICodedbPaths.GetManagerActionPackageKey(context),
                    StringComparison.Ordinal))
            {
                return AICodedbManagerActionRecoveryOutcome.Conflict(
                    "The Manager action terminal receipt identity does not match the current project and Package.");
            }
            var result = new AICodedbCommandResult(
                AICodedbStrictJson.GetRequiredInt32(receipt, "exit_code", "CodeDB Manager action terminal receipt"),
                AICodedbStrictJson.GetRequiredString(receipt, "stdout", "CodeDB Manager action terminal receipt"),
                AICodedbStrictJson.GetRequiredString(receipt, "stderr", "CodeDB Manager action terminal receipt"),
                AICodedbStrictJson.GetRequiredBoolean(receipt, "timed_out", "CodeDB Manager action terminal receipt"),
                AICodedbStrictJson.GetRequiredInt32(receipt, "elapsed_milliseconds", "CodeDB Manager action terminal receipt"),
                false,
                true,
                actionId,
                AICodedbStrictJson.GetRequiredBoolean(
                    receipt, "terminal_for_action", "CodeDB Manager action terminal receipt"));
            return AICodedbManagerActionRecoveryOutcome.Terminal(result);
        }

        internal static bool HasValidManagerActionReceiptEnvelope(
            Dictionary<string, object> admitted,
            Dictionary<string, object> claim,
            Dictionary<string, object> terminal)
        {
            if (admitted == null || claim == null || terminal == null)
                return false;

            const string admissionLabel = "CodeDB Manager action admission";
            const string claimLabel = "CodeDB Manager action writer claim";
            const string terminalLabel = "CodeDB Manager action terminal receipt";
            try
            {
                if (AICodedbStrictJson.GetRequiredInt32(admitted, "schema_version", admissionLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "managed_by", admissionLabel),
                        "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "state", admissionLabel),
                        "admitted", StringComparison.Ordinal)
                    || AICodedbStrictJson.GetRequiredInt32(claim, "schema_version", claimLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "managed_by", claimLabel),
                        "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "state", claimLabel),
                        "claimed", StringComparison.Ordinal)
                    || AICodedbStrictJson.GetRequiredInt32(terminal, "schema_version", terminalLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(terminal, "managed_by", terminalLabel),
                        "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(terminal, "state", terminalLabel),
                        "terminal", StringComparison.Ordinal))
                    return false;

                var writerPid = AICodedbStrictJson.GetRequiredInt32(claim, "writer_pid", claimLabel);
                var terminalWriterPid = AICodedbStrictJson.GetRequiredInt32(terminal, "writer_pid", terminalLabel);
                var childPid = AICodedbStrictJson.GetRequiredInt32(terminal, "child_pid", terminalLabel);
                var ticksText = AICodedbStrictJson.GetRequiredString(claim, "writer_start_utc_ticks", claimLabel);
                if (!long.TryParse(ticksText, NumberStyles.None, CultureInfo.InvariantCulture,
                        out var writerStartTicks)
                    || writerStartTicks <= DateTime.MinValue.Ticks
                    || writerStartTicks > DateTime.MaxValue.Ticks
                    || writerPid <= 0 || terminalWriterPid != writerPid
                    || childPid <= 0 || childPid == writerPid)
                    return false;

                var completedText = AICodedbStrictJson.GetRequiredString(
                    terminal, "completed_at_utc", terminalLabel);
                if (!completedText.EndsWith("Z", StringComparison.Ordinal)
                    || !DateTime.TryParseExact(completedText, "O", CultureInfo.InvariantCulture,
                        DateTimeStyles.RoundtripKind, out var completedAt)
                    || completedAt.Kind != DateTimeKind.Utc
                    || completedAt.Ticks < writerStartTicks)
                    return false;

                var overflow = AICodedbStrictJson.GetRequiredBoolean(
                    terminal, "output_overflow", terminalLabel);
                var timedOut = AICodedbStrictJson.GetRequiredBoolean(
                    terminal, "timed_out", terminalLabel);
                var exitCode = AICodedbStrictJson.GetRequiredInt32(
                    terminal, "exit_code", terminalLabel);
                var elapsed = AICodedbStrictJson.GetRequiredInt32(
                    terminal, "elapsed_milliseconds", terminalLabel);
                if (!admitted.TryGetValue("command", out var commandValue))
                    return false;
                var command = AICodedbStrictJson.RequireObject(commandValue, admissionLabel + " command");
                var timeout = AICodedbStrictJson.GetRequiredInt32(command, "timeout_ms", admissionLabel + " command");
                return timeout >= 1 && timeout <= 1800000
                    && elapsed >= 0 && (!timedOut || elapsed >= timeout)
                    && ((!overflow && !timedOut) || exitCode == 4);
            }
            catch (InvalidOperationException)
            {
                return false;
            }
        }

        private static AICodedbCommandResult UnconfirmedManagerActionResult(
            string actionId,
            string detail)
        {
            return new AICodedbCommandResult(
                4,
                string.Empty,
                string.IsNullOrWhiteSpace(detail)
                    ? "The Manager action has no authoritative terminal receipt."
                    : detail,
                false,
                0,
                false,
                false,
                actionId);
        }

        private static string BuildManagerActionAdmissionJson(
            AICodedbEditorExecutionContext context,
            string actionId,
            string stageId,
            string writerPath,
            string scriptPath,
            string scriptSha256,
            string argumentSha256,
            string commandIdentity,
            int timeoutMilliseconds,
            string[] arguments)
        {
            var projectKey = AICodedbPaths.GetManagerActionProjectKey(context);
            var packageKey = AICodedbPaths.GetManagerActionPackageKey(context);
            var builder = new StringBuilder();
            builder.Append("{\n  \"schema_version\": 1,\n  \"managed_by\": \"com.rice.ai-codedb\",\n  \"state\": \"admitted\",")
                .Append("\n  \"action_id\": \"").Append(EscapeJson(actionId)).Append("\",")
                .Append("\n  \"stage_id\": \"").Append(EscapeJson(stageId)).Append("\",")
                .Append("\n  \"terminal_for_action\": ").Append(AICodedbPaths.CurrentActionStageIsTerminal ? "true" : "false").Append(',')
                .Append("\n  \"project_key\": \"").Append(projectKey).Append("\",")
                .Append("\n  \"package_key\": \"").Append(packageKey).Append("\",")
                .Append("\n  \"project_identity\": \"sha256:").Append(projectKey).Append("\",")
                .Append("\n  \"package_identity\": \"sha256:").Append(packageKey).Append("\",")
                .Append("\n  \"effect_class\": \"").Append(EscapeJson(AICodedbPaths.CurrentActionEffect)).Append("\",")
                .Append("\n  \"authorization_source\": \"").Append(EscapeJson(AICodedbPaths.CurrentActionAuthority)).Append("\",")
                .Append("\n  \"command_identity_sha256\": \"").Append(commandIdentity).Append("\",")
                .Append("\n  \"writer_sha256\": \"").Append(GetFileSha256(writerPath)).Append("\",")
                .Append("\n  \"project_root\": \"").Append(EscapeJson(context.ProjectRoot)).Append("\",")
                .Append("\n  \"package_root\": \"").Append(EscapeJson(context.PackageRoot)).Append("\",")
                .Append("\n  \"command\": {\n    \"script_path\": \"").Append(EscapeJson(scriptPath)).Append("\",")
                .Append("\n    \"script_sha256\": \"").Append(scriptSha256).Append("\",")
                .Append("\n    \"arguments_sha256\": \"").Append(argumentSha256).Append("\",")
                .Append("\n    \"timeout_ms\": ").Append(timeoutMilliseconds.ToString(CultureInfo.InvariantCulture)).Append(',')
                .Append("\n    \"arguments\": [");
            for (var index = 0; index < arguments.Length; index++)
            {
                if (index > 0)
                    builder.Append(',');
                builder.Append("\n      \"").Append(EscapeJson(arguments[index])).Append('"');
            }
            if (arguments.Length > 0)
                builder.Append('\n').Append("    ");
            builder.Append("]\n  }\n}\n");
            return builder.ToString();
        }

        private static void EnsureReceiptDirectory(
            AICodedbEditorExecutionContext context,
            string actionRoot,
            string stageRoot)
        {
            Directory.CreateDirectory(stageRoot);
            AssertReceiptPath(context, actionRoot);
            AssertReceiptPath(context, stageRoot);
        }

        private static void AssertReceiptPath(
            AICodedbEditorExecutionContext context,
            string path)
        {
            var root = AICodedbPaths.GetManagerActionsRoot().TrimEnd('/');
            var normalized = AICodedbPaths.NormalizePath(path);
            if (!normalized.StartsWith(root + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Manager action receipt path escapes its scoped root.");
            var current = root;
            var relative = normalized.Substring(root.Length).TrimStart('/');
            foreach (var segment in relative.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries))
            {
                current = Path.Combine(current, segment);
                if (!Directory.Exists(current) && !File.Exists(current))
                    break;
                if ((File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
                    throw new InvalidOperationException("Manager action receipt path traverses a reparse point.");
            }
        }

        private static bool IsLowerHex(string value)
        {
            foreach (var character in value)
            {
                if (!((character >= '0' && character <= '9')
                      || (character >= 'a' && character <= 'f')))
                    return false;
            }
            return true;
        }

        private static void WriteNewUtf8FileAtomic(string path, string value)
        {
            var temp = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
            try
            {
                File.WriteAllText(temp, value, new UTF8Encoding(false));
                if (File.Exists(path))
                    throw new InvalidOperationException("Manager action admission evidence already exists.");
                File.Move(temp, path);
            }
            finally
            {
                if (File.Exists(temp))
                    File.Delete(temp);
            }
        }

        private static string GetFileSha256(string path)
        {
            using (var stream = File.OpenRead(path))
            using (var algorithm = SHA256.Create())
                return ToHex(algorithm.ComputeHash(stream));
        }

        private static string ComputeSha256(string value)
        {
            using (var algorithm = SHA256.Create())
                return ToHex(algorithm.ComputeHash(Encoding.UTF8.GetBytes(value ?? string.Empty)));
        }

        private static string ToHex(byte[] value)
        {
            var builder = new StringBuilder(value.Length * 2);
            foreach (var item in value)
                builder.Append(item.ToString("x2", CultureInfo.InvariantCulture));
            return builder.ToString();
        }

        private static string EscapeJson(string value)
        {
            if (value == null)
                return string.Empty;
            var builder = new StringBuilder(value.Length + 16);
            foreach (var character in value)
            {
                switch (character)
                {
                    case '\\': builder.Append("\\\\"); break;
                    case '"': builder.Append("\\\""); break;
                    case '\r': builder.Append("\\r"); break;
                    case '\n': builder.Append("\\n"); break;
                    case '\t': builder.Append("\\t"); break;
                    default:
                        if (character < 0x20)
                            builder.Append("\\u").Append(((int)character).ToString("x4", CultureInfo.InvariantCulture));
                        else
                            builder.Append(character);
                        break;
                }
            }
            return builder.ToString();
        }

        private static AICodedbCommandResult UnsupportedPlatformResult()
        {
            return new AICodedbCommandResult(
                -1,
                string.Empty,
                "PowerShell codedb scripts are currently supported only in the Windows Editor.",
                false);
        }

        private static bool TryAuthorizePowerShellScriptPath(
            PowerShellScriptPathPolicy pathPolicy,
            AICodedbEditorExecutionContext context,
            string scriptPath,
            out string normalizedScriptPath,
            out string error)
        {
            normalizedScriptPath = string.Empty;
            error = string.Empty;

            try
            {
                if (pathPolicy == PowerShellScriptPathPolicy.ResolvedPackageMaterializer)
                {
                    var resolvedPackageRoot = context.PackageRoot;
                    var materializerPath = AICodedbPaths.NormalizePath(Path.Combine(
                        resolvedPackageRoot,
                        AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
                    return TryValidateResolvedPackageMaterializerScriptPath(
                        resolvedPackageRoot,
                        materializerPath,
                        out normalizedScriptPath,
                        out error);
                }

                if (pathPolicy == PowerShellScriptPathPolicy.ResolvedPackageProviderInstaller)
                {
                    var resolvedPackageRoot = context.PackageRoot;
                    var installerPath = AICodedbPaths.NormalizePath(Path.Combine(
                        resolvedPackageRoot,
                        AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath));
                    return TryValidateResolvedPackageProviderInstallerScriptPath(
                        resolvedPackageRoot,
                        installerPath,
                        out normalizedScriptPath,
                        out error);
                }

                normalizedScriptPath = AICodedbPaths.NormalizePath(scriptPath);
                if (!IsInsideRoot(context.ProjectRoot, normalizedScriptPath))
                {
                    error = $"Refusing to run a script outside the Unity project: {normalizedScriptPath}";
                    normalizedScriptPath = string.Empty;
                    return false;
                }

                if (!File.Exists(normalizedScriptPath))
                {
                    error = $"Script not found: {ToRootRelativeDisplayPath(context.ProjectRoot, normalizedScriptPath)}";
                    normalizedScriptPath = string.Empty;
                    return false;
                }

                return true;
            }
            catch (Exception exception)
            {
                normalizedScriptPath = string.Empty;
                error = "Refusing to run a PowerShell script because its path could not be validated: "
                        + exception.Message;
                return false;
            }
        }

        /// <summary>
        /// Validates the one Package-owned script that may execute outside the Unity project.
        /// </summary>
        internal static bool TryValidateResolvedPackageMaterializerScriptPath(
            string resolvedPackageRoot,
            string scriptPath,
            out string normalizedScriptPath,
            out string error)
        {
            normalizedScriptPath = string.Empty;
            error = string.Empty;

            try
            {
                if (string.IsNullOrWhiteSpace(resolvedPackageRoot)
                    || !Path.IsPathRooted(resolvedPackageRoot))
                {
                    error = "Resolved CodeDB Package root must be an absolute path.";
                    return false;
                }

                if (string.IsNullOrWhiteSpace(scriptPath) || !Path.IsPathRooted(scriptPath))
                {
                    error = "Resolved CodeDB Package materializer path must be absolute.";
                    return false;
                }

                var normalizedPackageRoot = AICodedbPaths.NormalizePath(resolvedPackageRoot).TrimEnd('/', '\\');
                var requestedScriptPath = AICodedbPaths.NormalizePath(scriptPath);
                var expectedScriptPath = AICodedbPaths.NormalizePath(Path.Combine(
                    normalizedPackageRoot,
                    AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
                var packagePrefix = normalizedPackageRoot + "/";

                if (!expectedScriptPath.StartsWith(packagePrefix, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(requestedScriptPath, expectedScriptPath, StringComparison.OrdinalIgnoreCase))
                {
                    error = "Refusing to run a script other than the resolved CodeDB Package materializer: "
                            + requestedScriptPath;
                    return false;
                }

                if (!Directory.Exists(normalizedPackageRoot))
                {
                    error = "Resolved CodeDB Package root was not found: " + normalizedPackageRoot;
                    return false;
                }

                if (!TryValidatePackageMaterializerPathNodes(
                        normalizedPackageRoot,
                        out error))
                    return false;

                normalizedScriptPath = expectedScriptPath;
                return true;
            }
            catch (Exception exception)
            {
                error = "Refusing to run the resolved CodeDB Package materializer because its path could not be validated: "
                        + exception.Message;
                return false;
            }
        }

        /// <summary>
        /// Validates the one Package-owned Provider installer that may execute outside the project.
        /// </summary>
        internal static bool TryValidateResolvedPackageProviderInstallerScriptPath(
            string resolvedPackageRoot,
            string scriptPath,
            out string normalizedScriptPath,
            out string error)
        {
            return TryValidateResolvedPackageOwnedScriptPath(
                resolvedPackageRoot,
                scriptPath,
                AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath,
                "CodeDB Package Provider installer",
                out normalizedScriptPath,
                out error);
        }

        private static bool TryValidateResolvedPackageOwnedScriptPath(
            string resolvedPackageRoot,
            string scriptPath,
            string packageRelativePath,
            string displayName,
            out string normalizedScriptPath,
            out string error)
        {
            normalizedScriptPath = string.Empty;
            error = string.Empty;

            try
            {
                if (string.IsNullOrWhiteSpace(resolvedPackageRoot)
                    || !Path.IsPathRooted(resolvedPackageRoot))
                {
                    error = "Resolved CodeDB Package root must be an absolute path.";
                    return false;
                }

                if (string.IsNullOrWhiteSpace(scriptPath) || !Path.IsPathRooted(scriptPath))
                {
                    error = "Resolved CodeDB Package script path must be absolute.";
                    return false;
                }

                var normalizedPackageRoot = AICodedbPaths.NormalizePath(resolvedPackageRoot).TrimEnd('/', '\\');
                var requestedScriptPath = AICodedbPaths.NormalizePath(scriptPath);
                var expectedScriptPath = AICodedbPaths.NormalizePath(Path.Combine(
                    normalizedPackageRoot,
                    packageRelativePath));
                var packagePrefix = normalizedPackageRoot + "/";

                if (!expectedScriptPath.StartsWith(packagePrefix, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(requestedScriptPath, expectedScriptPath, StringComparison.OrdinalIgnoreCase))
                {
                    error = "Refusing to run a script other than the resolved " + displayName + ": " + requestedScriptPath;
                    return false;
                }

                if (!Directory.Exists(normalizedPackageRoot))
                {
                    error = "Resolved CodeDB Package root was not found: " + normalizedPackageRoot;
                    return false;
                }

                if (!TryValidatePackageOwnedScriptPathNodes(
                        normalizedPackageRoot,
                        packageRelativePath,
                        displayName,
                        out error))
                    return false;

                normalizedScriptPath = expectedScriptPath;
                return true;
            }
            catch (Exception exception)
            {
                error = "Refusing to run the resolved " + displayName + " because its path could not be validated: "
                        + exception.Message;
                return false;
            }
        }

        private static bool TryValidatePackageOwnedScriptPathNodes(
            string normalizedPackageRoot,
            string packageRelativePath,
            string displayName,
            out string error)
        {
            error = string.Empty;
            var current = normalizedPackageRoot;
            var relativeSegments = packageRelativePath
                .Replace('\\', '/')
                .Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);

            if (!TryValidatePathNode(current, true, out error))
            {
                error = "Resolved " + displayName + " path validation failed: " + error;
                return false;
            }

            for (var index = 0; index < relativeSegments.Length; index++)
            {
                current = AICodedbPaths.NormalizePath(Path.Combine(current, relativeSegments[index]));
                var expectDirectory = index < relativeSegments.Length - 1;
                if (TryValidatePathNode(current, expectDirectory, out error))
                    continue;
                error = "Resolved " + displayName + " path validation failed: " + error;
                return false;
            }

            return true;
        }

        private static bool TryValidatePackageMaterializerPathNodes(
            string normalizedPackageRoot,
            out string error)
        {
            error = string.Empty;

            var current = normalizedPackageRoot;
            var relativeSegments = AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath
                .Replace('\\', '/')
                .Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);

            if (!TryValidatePathNode(current, true, out error))
                return false;

            for (var index = 0; index < relativeSegments.Length; index++)
            {
                current = AICodedbPaths.NormalizePath(Path.Combine(current, relativeSegments[index]));
                var expectDirectory = index < relativeSegments.Length - 1;
                if (TryValidatePathNode(current, expectDirectory, out error))
                    continue;

                return false;
            }

            return true;
        }

        private static bool TryValidatePathNode(string path, bool expectDirectory, out string error)
        {
            error = string.Empty;
            if (expectDirectory ? !Directory.Exists(path) : !File.Exists(path))
            {
                error = expectDirectory
                    ? "Resolved CodeDB Package directory was not found: " + path
                    : "Resolved CodeDB Package materializer was not found: " + path;
                return false;
            }

            var attributes = File.GetAttributes(path);
            if ((attributes & FileAttributes.ReparsePoint) == 0)
                return true;

            error = "Refusing to run the resolved CodeDB Package materializer through a reparse point: " + path;
            return false;
        }

        private static ProcessStartInfo BuildPowerShellStartInfo(
            AICodedbEditorExecutionContext context,
            string normalizedScriptPath,
            string instanceRoot,
            string[] scriptArguments)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = BuildPowerShellArguments(normalizedScriptPath, scriptArguments),
                WorkingDirectory = context.ProjectRoot,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };
            startInfo.EnvironmentVariables["RICE_CODEDB_UNITY_ROOT"] = context.ProjectRoot;
            if (!string.IsNullOrWhiteSpace(instanceRoot))
                startInfo.EnvironmentVariables["RICE_CODEDB_INSTANCE_ROOT"] = instanceRoot;
            return startInfo;
        }

        private static bool IsInsideRoot(string root, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/', '\\');
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            return string.Equals(normalizedRoot, normalizedPath, StringComparison.OrdinalIgnoreCase)
                   || normalizedPath.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase);
        }

        private static string ToRootRelativeDisplayPath(string root, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/', '\\');
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            var prefix = normalizedRoot + "/";
            return normalizedPath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                ? normalizedPath.Substring(prefix.Length)
                : normalizedPath;
        }

        /// <summary>
        /// Builds the PowerShell command line used to run a project script.
        /// </summary>
        /// <param name="scriptPath">Absolute script path.</param>
        /// <param name="scriptArguments">Optional script arguments.</param>
        private static string BuildPowerShellArguments(string scriptPath, string[] scriptArguments)
        {
            var builder = new StringBuilder();
            AppendArgument(builder, "-NoProfile");
            AppendArgument(builder, "-ExecutionPolicy");
            AppendArgument(builder, "Bypass");
            AppendArgument(builder, "-File");
            AppendArgument(builder, scriptPath);

            if (scriptArguments == null)
                return builder.ToString();

            foreach (var argument in scriptArguments)
                AppendArgument(builder, argument);

            return builder.ToString();
        }

        /// <summary>
        /// Appends one quoted process argument to the command-line builder.
        /// </summary>
        /// <param name="builder">Command-line builder.</param>
        /// <param name="argument">Argument to append.</param>
        private static void AppendArgument(StringBuilder builder, string argument)
        {
            if (builder.Length > 0)
                builder.Append(' ');

            builder.Append(QuoteWindowsArgument(argument));
        }

        /// <summary>
        /// Runs a process and captures stdout and stderr for the Editor result window.
        /// </summary>
        /// <param name="startInfo">Process start information.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        private static AICodedbCommandResult RunProcess(
            ProcessStartInfo startInfo,
            int timeoutMilliseconds,
            Action<string> outputLine = null,
            CancellationToken cancellationToken = default(CancellationToken),
            bool cancelOnDomainReload = false)
        {
            var output = new StringBuilder();
            var error = new StringBuilder();
            var outputLock = new object();
            var errorLock = new object();
            var outputCompleted = new TaskCompletionSource<bool>();
            var errorCompleted = new TaskCompletionSource<bool>();
            var stopwatch = Stopwatch.StartNew();
            Process activeProcess = null;

            try
            {
                using (var process = new Process())
                {
                    activeProcess = process;
                    process.StartInfo = startInfo;
                    process.OutputDataReceived += (sender, args) =>
                    {
                        if (args.Data == null)
                        {
                            outputCompleted.TrySetResult(true);
                            return;
                        }

                        lock (outputLock)
                            output.AppendLine(args.Data);
                        NotifyOutputLine(outputLine, args.Data);
                    };
                    process.ErrorDataReceived += (sender, args) =>
                    {
                        if (args.Data == null)
                        {
                            errorCompleted.TrySetResult(true);
                            return;
                        }

                        lock (errorLock)
                            error.AppendLine(args.Data);
                    };

                    if (!process.Start())
                        return new AICodedbCommandResult(-1, string.Empty, "Failed to start process.", false, GetElapsedMilliseconds(stopwatch));

                    if (cancelOnDomainReload)
                    {
                        lock (ActiveProcessLock)
                            ActiveBackgroundProcesses.Add(process);
                    }

                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();

                    var deadline = stopwatch.ElapsedMilliseconds + Math.Max(1, timeoutMilliseconds);
                    while (!process.HasExited)
                    {
                        if (cancellationToken.IsCancellationRequested)
                        {
                            TryKillProcess(process);
                            WaitForOutputDrain(outputCompleted.Task, errorCompleted.Task, true);
                            return new AICodedbCommandResult(
                                -1,
                                GetCapturedText(output, outputLock),
                                "CodeDB background process was cancelled before domain reload.",
                                true,
                                GetElapsedMilliseconds(stopwatch));
                        }

                        var remaining = deadline - stopwatch.ElapsedMilliseconds;
                        if (remaining <= 0)
                        {
                            TryKillProcess(process);
                            WaitForOutputDrain(outputCompleted.Task, errorCompleted.Task);
                            return new AICodedbCommandResult(-1, GetCapturedText(output, outputLock), GetCapturedText(error, errorLock), true, GetElapsedMilliseconds(stopwatch));
                        }

                        process.WaitForExit((int)Math.Min(100, remaining));
                    }

                    WaitForOutputDrain(outputCompleted.Task, errorCompleted.Task);
                    return new AICodedbCommandResult(process.ExitCode, GetCapturedText(output, outputLock), GetCapturedText(error, errorLock), false, GetElapsedMilliseconds(stopwatch));
                }
            }
            catch (Exception exception)
            {
                Debug.LogException(exception);
                var errorText = GetCapturedText(error, errorLock);
                if (!string.IsNullOrWhiteSpace(errorText))
                    errorText = errorText.TrimEnd() + Environment.NewLine;

                return new AICodedbCommandResult(-1, GetCapturedText(output, outputLock), errorText + exception.Message, false, GetElapsedMilliseconds(stopwatch));
            }
            finally
            {
                if (cancelOnDomainReload)
                {
                    lock (ActiveProcessLock)
                        ActiveBackgroundProcesses.RemoveAll(process => object.ReferenceEquals(process, activeProcess));
                }
            }
        }

        /// <summary>
        /// Forwards a process output line without allowing UI progress handling
        /// to affect process lifetime or output capture.
        /// </summary>
        private static void NotifyOutputLine(Action<string> outputLine, string line)
        {
            if (outputLine == null || line == null)
                return;

            try
            {
                outputLine(line);
            }
            catch
            {
                // Progress observers are advisory and must never fail a command.
            }
        }

        /// <summary>
        /// Gives asynchronous stdout and stderr readers a bounded chance to deliver their final lines.
        /// </summary>
        private static void WaitForOutputDrain(
            Task outputCompleted,
            Task errorCompleted,
            bool suppressWarning = false)
        {
            if (!Task.WaitAll(new[] { outputCompleted, errorCompleted }, OutputDrainTimeoutMilliseconds))
            {
                if (!suppressWarning)
                    Debug.LogWarning("Codedb process exited while redirected output remained open; continuing with the output captured so far.");
            }
        }

        /// <summary>
        /// Takes a thread-safe snapshot of asynchronously captured process output.
        /// </summary>
        private static string GetCapturedText(StringBuilder builder, object syncRoot)
        {
            lock (syncRoot)
                return builder.ToString();
        }

        /// <summary>
        /// Gets elapsed milliseconds while preserving visibly non-zero fast runs.
        /// </summary>
        /// <param name="stopwatch">Running stopwatch.</param>
        private static long GetElapsedMilliseconds(Stopwatch stopwatch)
        {
            if (stopwatch == null)
                return 0;

            if (stopwatch.ElapsedMilliseconds > 0)
                return stopwatch.ElapsedMilliseconds;

            return stopwatch.ElapsedTicks > 0 ? 1 : 0;
        }

        /// <summary>
        /// Terminates a process after a timeout without surfacing cleanup failures.
        /// </summary>
        /// <param name="process">Process to terminate.</param>
        private static void TryKillProcess(Process process)
        {
            try
            {
                if (!process.HasExited)
                    process.Kill();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Failed to kill timed-out codedb process: {exception.Message}");
            }
        }

        /// <summary>
        /// Quotes a Windows command-line argument for ProcessStartInfo.Arguments.
        /// </summary>
        /// <param name="argument">Argument to quote.</param>
        private static string QuoteWindowsArgument(string argument)
        {
            if (string.IsNullOrEmpty(argument))
                return "\"\"";

            var builder = new StringBuilder();
            builder.Append('"');

            var backslashes = 0;
            foreach (var character in argument)
            {
                if (character == '\\')
                {
                    backslashes++;
                    continue;
                }

                if (character == '"')
                {
                    builder.Append('\\', backslashes * 2 + 1);
                    builder.Append('"');
                    backslashes = 0;
                    continue;
                }

                if (backslashes > 0)
                {
                    builder.Append('\\', backslashes);
                    backslashes = 0;
                }

                builder.Append(character);
            }

            if (backslashes > 0)
                builder.Append('\\', backslashes * 2);

            builder.Append('"');
            return builder.ToString();
        }
    }
}
