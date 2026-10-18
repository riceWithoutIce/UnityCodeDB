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
    internal enum AICodedbManagerActionEvidenceKind
    {
        CommandTerminal,
        PreEffectRefusal,
        FailedCandidateEffectsRetained,
        Indeterminate
    }

    internal sealed class AICodedbCommandResult
    {
        internal int ExitCode { get; }
        internal string StandardOutput { get; }
        internal string StandardError { get; }
        internal bool TimedOut { get; }
        internal bool OutputOverflow { get; }
        internal bool OutputDrainIncomplete { get; }
        internal long ElapsedMilliseconds { get; }
        internal string ActionId { get; }
        internal bool HasAuthoritativeTerminalEvidence { get; }
        internal bool TerminalForManagerAction { get; }
        internal AICodedbManagerActionEvidenceKind ManagerActionEvidenceKind { get; }
        internal AICodedbSupervisorTerminalEvidence SupervisorTerminalEvidence { get; }
        internal bool SupervisorTerminalBindingRejected { get; }
        internal string SupervisorHandoffWarningCode { get; }
        internal string SupervisorHandoffWarningDetail { get; }
        internal bool FailedCandidateEffectsRetained =>
            ManagerActionEvidenceKind == AICodedbManagerActionEvidenceKind.FailedCandidateEffectsRetained;
        // Only the Supervisor Bridge may set this bit. It records a
        // read-only proof that the command is in the empty-runtime bootstrap
        // case; callers must never infer fallback permission from text output.
        internal bool OneShotFallbackAuthorized { get; }
        internal bool Succeeded => !TimedOut && !OutputOverflow && ExitCode == 0;

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
            bool? authoritativeTerminalEvidence = null,
            string actionId = null,
            bool terminalForManagerAction = true,
            AICodedbManagerActionEvidenceKind managerActionEvidenceKind =
                AICodedbManagerActionEvidenceKind.CommandTerminal,
            bool outputOverflow = false,
            bool outputDrainIncomplete = false,
            AICodedbSupervisorTerminalEvidence supervisorTerminalEvidence = null,
            bool supervisorTerminalBindingRejected = false,
            string supervisorHandoffWarningCode = null,
            string supervisorHandoffWarningDetail = null)
        {
            ExitCode = exitCode;
            StandardOutput = standardOutput ?? string.Empty;
            StandardError = standardError ?? string.Empty;
            TimedOut = timedOut;
            OutputOverflow = outputOverflow;
            OutputDrainIncomplete = outputDrainIncomplete;
            SupervisorTerminalEvidence = supervisorTerminalEvidence;
            SupervisorTerminalBindingRejected = supervisorTerminalBindingRejected;
            SupervisorHandoffWarningCode = supervisorHandoffWarningCode ?? string.Empty;
            SupervisorHandoffWarningDetail = supervisorHandoffWarningDetail ?? string.Empty;
            ElapsedMilliseconds = Math.Max(0, elapsedMilliseconds);
            ActionId = actionId ?? AICodedbPaths.CurrentActionId;
            OneShotFallbackAuthorized = oneShotFallbackAuthorized;
            var isManagerAction = AICodedbSupervisorProtocol.IsManagerActionId(ActionId);
            HasAuthoritativeTerminalEvidence = authoritativeTerminalEvidence ?? !isManagerAction;
            TerminalForManagerAction = terminalForManagerAction;
            ManagerActionEvidenceKind = !authoritativeTerminalEvidence.HasValue && isManagerAction
                ? AICodedbManagerActionEvidenceKind.Indeterminate
                : managerActionEvidenceKind;
        }

        internal AICodedbCommandResult WithSupervisorHandoffWarning(string code, string detail)
        {
            return new AICodedbCommandResult(ExitCode, StandardOutput, StandardError, TimedOut,
                ElapsedMilliseconds, OneShotFallbackAuthorized, HasAuthoritativeTerminalEvidence,
                ActionId, TerminalForManagerAction, ManagerActionEvidenceKind, OutputOverflow,
                OutputDrainIncomplete, SupervisorTerminalEvidence, SupervisorTerminalBindingRejected,
                code, detail);
        }

        internal string GetSupervisorHandoffWarningText()
        {
            return string.IsNullOrWhiteSpace(SupervisorHandoffWarningCode) ? string.Empty
                : "[" + SupervisorHandoffWarningCode + "] " + SupervisorHandoffWarningDetail;
        }

        /// <summary>
        /// Builds a compact status line suitable for Editor UI.
        /// </summary>
        internal string GetSummary()
        {
            if (ManagerActionEvidenceKind == AICodedbManagerActionEvidenceKind.PreEffectRefusal)
                return "Command did not start.";
            if (ManagerActionEvidenceKind == AICodedbManagerActionEvidenceKind.Indeterminate)
                return "Command outcome unconfirmed.";
            if (TimedOut)
                return "Command timed out.";
            if (OutputOverflow)
                return "Command output exceeded the receipt limit.";

            if (!Succeeded)
                return $"Command failed with exit code {ExitCode}.";

            if (!string.IsNullOrWhiteSpace(SupervisorHandoffWarningCode)
                || HasLeadingFreshnessWarningMarker(StandardOutput))
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
            if (OutputDrainIncomplete)
                builder.AppendLine("Output collection incomplete; project effects remain unproved.");

            AppendSection(builder, "Output", StandardOutput);
            AppendSection(builder, "Error", StandardError);
            AppendSection(builder, "Supervisor handoff warning", GetSupervisorHandoffWarningText());

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
        PreEffectRefusal,
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
        internal static AICodedbManagerActionRecoveryOutcome PreEffectRefusal(AICodedbCommandResult result) =>
            new AICodedbManagerActionRecoveryOutcome(
                AICodedbManagerActionRecoveryState.PreEffectRefusal, result, string.Empty);
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
                return AICodedbSupervisorProtocol.IsManagerActionId(AICodedbPaths.CurrentActionId)
                    ? PreEffectManagerActionResult(AICodedbPaths.CurrentActionId, authorizationError)
                    : new AICodedbCommandResult(-1, string.Empty, authorizationError, false);
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
                return PreEffectManagerActionResult(actionId, writerError);
            }

            var writerDispatched = false;
            string attemptedAdmissionPath = null;
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
                AICodedbPaths.ValidateManagerReceiptPaths(context, actionId, stageId);
                var owner = AICodedbManagerActionJournal.Read(context);
                if (owner.State != AICodedbManagerActionIndexState.Pending || owner.Index == null
                    || owner.Index.ActionId != actionId
                    || owner.Index.StorageLayout != AICodedbPaths.CompactReceiptLayout
                    || !string.Equals(owner.Index.Context.PackageRoot, context.PackageRoot, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("The compact action has no matching journal owner.");
                ValidateActionManifest(context, actionId);
                var admittedPath = AICodedbPaths.GetManagerStageReceiptPath(actionRoot, stageId, "admitted");
                attemptedAdmissionPath = admittedPath;
                if (File.Exists(admittedPath)
                    || File.Exists(ReceiptSibling(admittedPath, "claim"))
                    || File.Exists(ReceiptSibling(admittedPath, "terminal"))
                    || File.Exists(ReceiptSibling(admittedPath, "start-failure")))
                {
                    if (File.Exists(admittedPath))
                    {
                        try
                        {
                            var prior = AICodedbStrictJson.ReadObject(admittedPath, ManagerActionReceiptMaximumBytes,
                                "Existing Manager stage admission");
                            if (AICodedbStrictJson.GetRequiredString(prior, "stage_id", "Existing Manager stage admission") != stageId)
                                return UnconfirmedManagerActionResult(actionId,
                                    "Stage prefix collision: the existing admission has a different complete stage identity.");
                        }
                        catch (Exception exception)
                        {
                            return UnconfirmedManagerActionResult(actionId, "Existing stage evidence is conflicting: " + exception.Message);
                        }
                    }
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

                writerDispatched = true;
                AICodedbPaths.CurrentActionDispatchTracker?.MarkDirectWriterDispatchAttempted();
                var writerResult = RunProcess(
                    BuildPowerShellStartInfo(
                        context,
                        normalizedWriterPath,
                        null,
                        new[] { "-ReceiptPath", admittedPath }),
                    checked(timeoutMilliseconds + ManagerActionWriterGraceMilliseconds));
                var terminalPath = ReceiptSibling(admittedPath, "terminal");
                var startFailurePath = ReceiptSibling(admittedPath, "start-failure");
                if (File.Exists(startFailurePath))
                {
                    if (File.Exists(terminalPath))
                        return UnconfirmedManagerActionResult(actionId,
                            "Conflicting terminal and start-failure receipts exist for the same stage.");
                    var failure = ReadStartFailureReceipt(context, actionId, startFailurePath);
                    return failure.State == AICodedbManagerActionRecoveryState.PreEffectRefusal
                        ? failure.Result : UnconfirmedManagerActionResult(actionId, failure.Detail);
                }
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
                return writerDispatched || (attemptedAdmissionPath != null && File.Exists(attemptedAdmissionPath))
                    ? UnconfirmedManagerActionResult(actionId, exception.Message)
                    : PreEffectManagerActionResult(actionId, exception.Message);
            }
        }

        internal static AICodedbManagerActionRecoveryOutcome RecoverManagerAction(
            AICodedbEditorExecutionContext context,
            string actionId, string storageLayout = AICodedbPaths.CompactReceiptLayout)
        {
            if (!AICodedbSupervisorProtocol.IsManagerActionId(actionId))
                return AICodedbManagerActionRecoveryOutcome.Conflict("The persisted Manager action id is invalid.");
            try
            {
                var actionRoot = AICodedbPaths.GetManagerActionReceiptRoot(context, actionId, storageLayout);
                var otherRoot = AICodedbPaths.GetManagerActionReceiptRoot(context, actionId,
                    storageLayout == null ? AICodedbPaths.CompactReceiptLayout : null);
                if (Directory.Exists(otherRoot))
                    return AICodedbManagerActionRecoveryOutcome.Conflict("Conflicting old/new action locations exist.");
                if (!Directory.Exists(actionRoot))
                    return AICodedbManagerActionRecoveryOutcome.NotFound(
                        "No Package-owned direct-command receipt exists for this action.");
                AssertReceiptPath(context, actionRoot);
                var compact = storageLayout == AICodedbPaths.CompactReceiptLayout;
                if (compact) ValidateActionManifest(context, actionId);
                if (!compact && Directory.GetFiles(actionRoot).Length != 0)
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "Unexpected files exist at the Manager action receipt root.");
                var stageAdmissions = new List<string>();
                if (compact)
                {
                    if (Directory.GetDirectories(actionRoot).Length != 0)
                        throw new InvalidOperationException("Unexpected compact action subdirectory.");
                    var files = Directory.GetFiles(actionRoot);
                    if (files.Length > 129)
                        throw new InvalidOperationException("Compact action evidence exceeds its bounded record count.");
                    foreach (var file in files)
                    {
                        AssertReceiptPath(context, file);
                        var name = Path.GetFileName(file);
                        if (name == "action.json") continue;
                        if (name.Length < 22 || name[16] != '.' || !IsLowerHex(name.Substring(0, 16))
                            || (name.Substring(17) != "admitted.json"
                                && name.Substring(17) != "claim.json"
                                && name.Substring(17) != "terminal.json"
                                && name.Substring(17) != "start-failure.json"))
                            throw new InvalidOperationException("Unexpected compact action evidence file.");
                        var admissionPath = ReceiptSibling(file, "admitted");
                        if (!File.Exists(admissionPath))
                            throw new InvalidOperationException("Compact evidence has no admission record.");
                        if (!stageAdmissions.Contains(admissionPath)) stageAdmissions.Add(admissionPath);
                    }
                }
                else
                    foreach (var directory in Directory.GetDirectories(actionRoot))
                        stageAdmissions.Add(Path.Combine(directory, "admitted.json"));
                if (stageAdmissions.Count > 32)
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "The Manager action receipt contains too many stage entries.");

                var completedStages = new List<RecoveredManagerStage>();
                AICodedbCommandResult refusalResult = null;
                var evidenceObserved = false;
                var pendingObserved = false;
                foreach (var admittedPath in stageAdmissions)
                {
                    var stageDirectory = Path.GetDirectoryName(admittedPath);
                    AssertReceiptPath(context, stageDirectory);
                    if (Directory.GetDirectories(stageDirectory).Length != 0)
                        return AICodedbManagerActionRecoveryOutcome.Conflict(
                            "A Manager action stage contains an unexpected directory.");
                    foreach (var file in compact ? new string[0] : Directory.GetFiles(stageDirectory))
                    {
                        AssertReceiptPath(context, file);
                        var name = Path.GetFileName(file);
                        if (name != "admitted.json" && name != "claim.json"
                            && name != "terminal.json" && name != "start-failure.json")
                            return AICodedbManagerActionRecoveryOutcome.Conflict(
                                "An unexpected Manager action stage file exists.");
                    }
                    evidenceObserved = true;
                    if (!File.Exists(admittedPath))
                        return AICodedbManagerActionRecoveryOutcome.Conflict(
                            "A Manager action stage has no admission record.");
                    var terminalPath = ReceiptSibling(admittedPath, "terminal");
                    var startFailurePath = ReceiptSibling(admittedPath, "start-failure");
                    if (File.Exists(startFailurePath))
                    {
                        if (File.Exists(terminalPath) || refusalResult != null || completedStages.Count != 0)
                            return AICodedbManagerActionRecoveryOutcome.Conflict(
                                "Conflicting Manager action stage outcomes exist.");
                        var failure = ReadStartFailureReceipt(context, actionId, startFailurePath);
                        if (failure.State != AICodedbManagerActionRecoveryState.PreEffectRefusal)
                            return failure;
                        refusalResult = failure.Result;
                        continue;
                    }
                    if (!File.Exists(terminalPath))
                    {
                        var pending = ValidatePendingStage(context, actionId, admittedPath);
                        if (pending.State == AICodedbManagerActionRecoveryState.Conflict)
                            return pending;
                        pendingObserved = true;
                        continue;
                    }
                    var outcome = ReadTerminalReceipt(context, actionId, terminalPath, out var admission);
                    if (outcome.State == AICodedbManagerActionRecoveryState.Conflict)
                        return outcome;
                    if (outcome.State != AICodedbManagerActionRecoveryState.Terminal)
                        return outcome;
                    if (refusalResult != null)
                        return AICodedbManagerActionRecoveryOutcome.Conflict(
                            "Conflicting Manager action stage outcomes exist.");
                    completedStages.Add(new RecoveredManagerStage(admission, outcome.Result));
                }

                if (pendingObserved && (completedStages.Count != 0 || refusalResult != null))
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "A Manager action has both pending and terminal stage evidence.");
                if (TryRecoverDeclaredRedeploy(context, completedStages, out var redeploy))
                    return redeploy;
                if (completedStages.Count == 1 && completedStages[0].Result.TerminalForManagerAction)
                    return AICodedbManagerActionRecoveryOutcome.Terminal(completedStages[0].Result);
                if (completedStages.Count > 1)
                    return RecoverFailedInstallFollowUp(context, completedStages);
                if (refusalResult != null)
                    return AICodedbManagerActionRecoveryOutcome.PreEffectRefusal(refusalResult);
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

        private sealed class RecoveredManagerStage
        {
            internal readonly Dictionary<string, object> Admission;
            internal readonly AICodedbCommandResult Result;
            internal RecoveredManagerStage(Dictionary<string, object> admission, AICodedbCommandResult result)
            {
                Admission = admission;
                Result = result;
            }
        }

        private static bool TryRecoverDeclaredRedeploy(AICodedbEditorExecutionContext context,
            List<RecoveredManagerStage> stages, out AICodedbManagerActionRecoveryOutcome outcome)
        {
            outcome = null;
            var names = new[] { AICodedbActions.RedeployUiPreflightStage,
                AICodedbActions.RedeployWorkerPreflightStage, AICodedbActions.RedeployMutationStage,
                AICodedbActions.RedeployRuntimeConfigStage };
            var declared = new Dictionary<string, RecoveredManagerStage>(StringComparer.Ordinal);
            foreach (var stage in stages)
                foreach (var name in names)
                    if (ComputeSha256(stage.Result.ActionId + "\n" + name + "\n"
                            + AICodedbStrictJson.GetRequiredString(stage.Admission, "command_identity_sha256", "Redeploy admission"))
                        == AICodedbStrictJson.GetRequiredString(stage.Admission, "stage_id", "Redeploy admission"))
                    {
                        if (declared.ContainsKey(name))
                        {
                            outcome = AICodedbManagerActionRecoveryOutcome.Conflict("Duplicate declared Redeploy stage.");
                            return true;
                        }
                        declared.Add(name, stage);
                    }
            if (declared.Count == 0) return false;
            if (declared.Count != stages.Count)
            {
                outcome = AICodedbManagerActionRecoveryOutcome.Conflict("Redeploy has an undeclared additional stage.");
                return true;
            }
            var first = declared.ContainsKey(names[0]) ? 0 : 1;
            AICodedbCommandResult mutation = null;
            for (var index = first; index < names.Length; index++)
            {
                if (!declared.TryGetValue(names[index], out var stage))
                {
                    outcome = declared.Count == index - first
                        ? AICodedbManagerActionRecoveryOutcome.Pending("The declared Redeploy chain has no completed final stage; no success or replay was inferred.")
                        : AICodedbManagerActionRecoveryOutcome.Conflict("The declared Redeploy chain has a missing predecessor.");
                    return true;
                }
                var result = stage.Result;
                var final = index == 3;
                if (result.TerminalForManagerAction != final)
                {
                    outcome = AICodedbManagerActionRecoveryOutcome.Conflict("Redeploy stage terminal attribution is inconsistent.");
                    return true;
                }
                if (result.TimedOut || result.OutputOverflow || result.OutputDrainIncomplete)
                {
                    outcome = AICodedbManagerActionRecoveryOutcome.Pending("Redeploy stage execution or output is incomplete; its effects remain unproved.");
                    return true;
                }
                if (final)
                {
                    var command = AICodedbStrictJson.RequireObject(stage.Admission["command"], "Redeploy config command");
                    var path = AICodedbStrictJson.GetRequiredString(command, "script_path", "Redeploy config command");
                    var arguments = ReadBoundCommandArguments(stage, path);
                    if (!IsDeclaredRedeployConfigPath(context, path) || arguments.Length != 1 || arguments[0] != "-Force"
                        || AICodedbMaterializerCommandStatusParser.Parse(result.StandardOutput).Present)
                        throw new InvalidOperationException("Redeploy runtime-config command is not the declared project script.");
                    // Include the original mutation output even if config failed.
                    // Config completion cannot erase mutation scopes or cleanup state.
                    outcome = AICodedbManagerActionRecoveryOutcome.Terminal(BuildRedeployActionResult(mutation, result));
                    return true;
                }
                var action = ReadAuthenticatedMaterializerAction(context, stage, true);
                var status = AICodedbMaterializerCommandStatusParser.Parse(result.StandardOutput);
                if (index < 2)
                {
                    if (action != "DryRun" || status.Present)
                        throw new InvalidOperationException("Redeploy preflight is not a read-only DryRun.");
                    if (result.Succeeded && !AICodedbHostPayloadStatusBuilder.Build(true, result).CanRedeploy)
                    {
                        outcome = declared.Count == index - first + 1
                            ? AICodedbManagerActionRecoveryOutcome.Pending("Redeploy preflight did not admit mutation; the Manager decision is not recorded here.")
                            : AICodedbManagerActionRecoveryOutcome.Conflict("Redeploy continued after a refusing preflight.");
                        return true;
                    }
                }
                else
                {
                    if (action != "Redeploy" || !status.Present || !status.IsValid
                        || status.Action != "REDEPLOY" || status.ExitCode != result.ExitCode
                        || (result.Succeeded && (status.Outcome != "CONVERGED" || status.CleanupState != "COMPLETE"))
                        || (!result.Succeeded && status.Outcome != "BLOCKED" && status.Outcome != "FAILED"))
                        throw new InvalidOperationException("Redeploy mutation result is not an authenticated completed command result.");
                    mutation = result;
                }
                if (!result.Succeeded)
                {
                    outcome = declared.Count == index - first + 1
                        ? AICodedbManagerActionRecoveryOutcome.Terminal(BuildRedeployActionResult(null, result))
                        : AICodedbManagerActionRecoveryOutcome.Conflict("Redeploy continued after a failed stage.");
                    return true;
                }
            }
            throw new InvalidOperationException("Redeploy chain classification did not terminate.");
        }

        private static AICodedbCommandResult BuildRedeployActionResult(
            AICodedbCommandResult mutation, AICodedbCommandResult last)
        {
            return new AICodedbCommandResult(last.ExitCode,
                mutation == null ? last.StandardOutput : mutation.StandardOutput + Environment.NewLine + last.StandardOutput,
                mutation == null ? last.StandardError : mutation.StandardError + Environment.NewLine + last.StandardError,
                false, (mutation?.ElapsedMilliseconds ?? 0) + last.ElapsedMilliseconds,
                false, true, last.ActionId, true);
        }

        private static bool IsDeclaredRedeployConfigPath(AICodedbEditorExecutionContext context, string path)
        {
            if (!string.Equals(path, AICodedbPaths.NormalizePath(Path.GetFullPath(path)), StringComparison.OrdinalIgnoreCase))
                return false;
            var legacy = AICodedbPaths.NormalizePath(Path.Combine(context.ProjectRoot,
                AICodedbProjectSettings.PrepareRuntimeScriptRelativePath));
            if (string.Equals(path, legacy, StringComparison.OrdinalIgnoreCase)) return true;
            var prefix = AICodedbPaths.NormalizePath(Path.Combine(context.ProjectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath)).TrimEnd('/') + "/";
            const string suffix = "/scripts/prepare-codedb-project-runtime.ps1";
            if (!path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                || !path.EndsWith(suffix, StringComparison.OrdinalIgnoreCase)) return false;
            var generation = path.Substring(prefix.Length, path.Length - prefix.Length - suffix.Length);
            if (generation.Length == 0 || generation.Length > 64 || generation == "." || generation == "..") return false;
            foreach (var character in generation)
                if (!((character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z')
                    || (character >= '0' && character <= '9') || character == '.' || character == '_' || character == '-'))
                    return false;
            return true;
        }

        private static AICodedbManagerActionRecoveryOutcome RecoverFailedInstallFollowUp(
            AICodedbEditorExecutionContext context, List<RecoveredManagerStage> stages)
        {
            const string conflict = "Completed Manager stages do not prove the bounded failed INSTALL follow-up shape.";
            if (stages.Count != 3)
                return AICodedbManagerActionRecoveryOutcome.Conflict(conflict);
            AICodedbCommandResult install = null;
            var observed = false;
            var refusedUpgrade = false;
            foreach (var stage in stages)
            {
                var result = stage.Result;
                if (!result.TerminalForManagerAction || result.TimedOut
                    || result.OutputOverflow || result.OutputDrainIncomplete)
                    return AICodedbManagerActionRecoveryOutcome.Conflict(conflict);
                var action = ReadAuthenticatedMaterializerAction(context, stage);
                var command = AICodedbMaterializerCommandStatusParser.Parse(result.StandardOutput);
                if (action == "Install" && install == null
                    && AICodedbActions.HasFailedInstallPendingEffects(result))
                    install = result;
                else if (action == "DryRun" && !observed && result.Succeeded && !command.Present
                    && AICodedbHostPayloadStatusBuilder.Build(true, result).State != AICodedbHostPayloadState.Unknown)
                    observed = true;
                else if (action == "Upgrade" && !refusedUpgrade
                    && AICodedbMaterializerCommandSemantics.ClassifyHistoricalNonSuccess(result)
                        == AICodedbHistoricalNonSuccess.UpgradeRefusedWithoutEffects)
                    refusedUpgrade = true;
                else
                    return AICodedbManagerActionRecoveryOutcome.Conflict(conflict);
            }
            // Return the original object and output. A follow-up's COMPLETE is
            // local to that attempt and cannot clear INSTALL's mutations/PENDING.
            return install != null && observed && refusedUpgrade
                ? AICodedbManagerActionRecoveryOutcome.Terminal(install)
                : AICodedbManagerActionRecoveryOutcome.Conflict(conflict);
        }

        private static string[] ReadBoundCommandArguments(RecoveredManagerStage stage, string expectedScriptPath)
        {
            const string label = "historical materializer command";
            var admission = stage.Admission;
            var command = AICodedbStrictJson.RequireObject(admission["command"], label);
            var arguments = AICodedbStrictJson.GetRequiredStringArray(command, "arguments", label);
            var argumentHash = ComputeSha256(string.Join("\n", arguments));
            var scriptHash = AICodedbStrictJson.GetRequiredString(command, "script_sha256", label);
            var timeout = AICodedbStrictJson.GetRequiredInt32(command, "timeout_ms", label);
            var scriptPath = AICodedbStrictJson.GetRequiredString(command, "script_path", label);
            if (scriptHash.Length != 64 || !IsLowerHex(scriptHash)
                || !string.Equals(scriptPath, expectedScriptPath, StringComparison.OrdinalIgnoreCase)
                || argumentHash != AICodedbStrictJson.GetRequiredString(command, "arguments_sha256", label)
                || ComputeSha256(scriptHash + "\n" + argumentHash + "\n"
                    + timeout.ToString(CultureInfo.InvariantCulture))
                    != AICodedbStrictJson.GetRequiredString(admission, "command_identity_sha256", label)
                || AICodedbStrictJson.GetRequiredString(admission, "effect_class", label) != "ConfirmedProjectMutation"
                || AICodedbStrictJson.GetRequiredString(admission, "authorization_source", label)
                    != AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB"))
                throw new InvalidOperationException("Historical materializer command identity is inconsistent.");
            return arguments;
        }

        private static string ReadAuthenticatedMaterializerAction(
            AICodedbEditorExecutionContext context, RecoveredManagerStage stage, bool allowRedeploy = false)
        {
            var arguments = ReadBoundCommandArguments(stage, AICodedbPaths.NormalizePath(Path.Combine(context.PackageRoot,
                AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath)));
            var options = new Dictionary<string, string>(StringComparer.Ordinal);
            foreach (var argument in arguments)
                if (argument == null || argument.IndexOfAny(new[] { '\r', '\n' }) >= 0)
                    throw new InvalidOperationException("Historical command argument is invalid.");
            for (var index = 0; index < arguments.Length; index++)
            {
                var name = arguments[index];
                if (name == "-ConfirmedProjectMutation")
                    options.Add(name, "true");
                else if (name == "-Action" || name == "-ProjectRoot" || name == "-OriginatingActionId"
                    || name == "-OriginatingOperationId" || name == "-EditorSessionId"
                    || name == "-EditorProcessId" || name == "-EditorProcessStartTicks")
                {
                    if (++index >= arguments.Length || string.IsNullOrEmpty(arguments[index]))
                        throw new InvalidOperationException("Historical command option has no value.");
                    options.Add(name, arguments[index]);
                }
                else
                    throw new InvalidOperationException("Historical command option is unclassified.");
            }
            if (!options.TryGetValue("-Action", out var action)
                || !options.TryGetValue("-ProjectRoot", out var project)
                || !string.Equals(project, context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                || options.ContainsKey("-ConfirmedProjectMutation") != (action == "Install" || (allowRedeploy && action == "Redeploy"))
                || (options.TryGetValue("-OriginatingActionId", out var originatingAction)
                    && originatingAction != stage.Result.ActionId))
                throw new InvalidOperationException("Historical command action binding is inconsistent.");
            return action;
        }

        private static AICodedbManagerActionRecoveryOutcome ReadTerminalReceipt(
            AICodedbEditorExecutionContext context,
            string actionId,
            string terminalPath)
        {
            return ReadTerminalReceipt(context, actionId, terminalPath, out _);
        }

        private static AICodedbManagerActionRecoveryOutcome ReadTerminalReceipt(
            AICodedbEditorExecutionContext context, string actionId, string terminalPath,
            out Dictionary<string, object> admitted)
        {
            AssertReceiptPath(context, terminalPath);
            admitted = AICodedbStrictJson.ReadObject(
                ReceiptSibling(terminalPath, "admitted"),
                ManagerActionReceiptMaximumBytes,
                "CodeDB Manager action admission");
            var claim = AICodedbStrictJson.ReadObject(
                ReceiptSibling(terminalPath, "claim"),
                ManagerActionReceiptMaximumBytes,
                "CodeDB Manager action writer claim");
            var receipt = AICodedbStrictJson.ReadObject(
                terminalPath,
                ManagerActionReceiptMaximumBytes,
                "CodeDB Manager action terminal receipt");
            var stageId = ValidateReceiptLocation(context, actionId, terminalPath, "terminal", admitted, claim, receipt);
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
                    receipt, "terminal_for_action", "CodeDB Manager action terminal receipt"),
                AICodedbManagerActionEvidenceKind.CommandTerminal,
                AICodedbStrictJson.GetRequiredBoolean(receipt, "output_overflow", "CodeDB Manager action terminal receipt"),
                AICodedbStrictJson.GetRequiredBoolean(receipt, "output_drain_incomplete", "CodeDB Manager action terminal receipt"));
            return AICodedbManagerActionRecoveryOutcome.Terminal(result);
        }

        private static AICodedbManagerActionRecoveryOutcome ValidatePendingStage(
            AICodedbEditorExecutionContext context, string actionId, string admittedPath)
        {
            try
            {
                const string admissionLabel = "CodeDB Manager action admission";
                const string claimLabel = "CodeDB Manager action writer claim";
                var admitted = AICodedbStrictJson.ReadObject(admittedPath,
                    ManagerActionReceiptMaximumBytes, admissionLabel);
                var stageId = ValidateReceiptLocation(context, actionId, admittedPath, "admitted", admitted);
                if (stageId.Length != 64 || !IsLowerHex(stageId)
                    || AICodedbStrictJson.GetRequiredInt32(admitted, "schema_version", admissionLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "managed_by", admissionLabel),
                        "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "state", admissionLabel),
                        "admitted", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "action_id", admissionLabel),
                        actionId, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "stage_id", admissionLabel),
                        stageId, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_key", admissionLabel),
                        AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "package_key", admissionLabel),
                        AICodedbPaths.GetManagerActionPackageKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_identity", admissionLabel),
                        "sha256:" + AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "package_identity", admissionLabel),
                        "sha256:" + AICodedbPaths.GetManagerActionPackageKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_root", admissionLabel),
                        context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "package_root", admissionLabel),
                        context.PackageRoot, StringComparison.OrdinalIgnoreCase))
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "A pending Manager action stage has conflicting admission identity.");
                var claimPath = ReceiptSibling(admittedPath, "claim");
                if (File.Exists(claimPath))
                {
                    var claim = AICodedbStrictJson.ReadObject(claimPath,
                        ManagerActionReceiptMaximumBytes, claimLabel);
                    ValidateReceiptLocation(context, actionId, claimPath, "claim", admitted, claim);
                    if (AICodedbStrictJson.GetRequiredInt32(claim, "schema_version", claimLabel) != 1
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "managed_by", claimLabel),
                            "com.rice.ai-codedb", StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "state", claimLabel),
                            "claimed", StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "action_id", claimLabel),
                            actionId, StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "stage_id", claimLabel),
                            stageId, StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "project_key", claimLabel),
                            AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "package_key", claimLabel),
                            AICodedbPaths.GetManagerActionPackageKey(context), StringComparison.Ordinal)
                        || AICodedbStrictJson.GetRequiredInt32(claim, "writer_pid", claimLabel) <= 0)
                        return AICodedbManagerActionRecoveryOutcome.Conflict(
                            "A pending Manager action stage has conflicting writer claim.");
                }
                return AICodedbManagerActionRecoveryOutcome.Pending(
                    "The original Manager action has no authenticated command terminal; no replay was attempted.");
            }
            catch (Exception exception)
            {
                return AICodedbManagerActionRecoveryOutcome.Conflict(
                    "Pending Manager action stage validation failed: " + exception.Message);
            }
        }

        private static AICodedbManagerActionRecoveryOutcome ReadStartFailureReceipt(
            AICodedbEditorExecutionContext context, string actionId, string path)
        {
            try
            {
                AssertReceiptPath(context, path);
                const string admissionLabel = "CodeDB Manager action admission";
                const string claimLabel = "CodeDB Manager action writer claim";
                const string failureLabel = "CodeDB Manager action start failure";
                var admitted = AICodedbStrictJson.ReadObject(ReceiptSibling(path, "admitted"),
                    ManagerActionReceiptMaximumBytes, admissionLabel);
                var claim = AICodedbStrictJson.ReadObject(ReceiptSibling(path, "claim"),
                    ManagerActionReceiptMaximumBytes, claimLabel);
                var failure = AICodedbStrictJson.ReadObject(path,
                    ManagerActionReceiptMaximumBytes, failureLabel);
                var stageId = ValidateReceiptLocation(context, actionId, path, "start-failure", admitted, claim, failure);
                var writerTicksText = AICodedbStrictJson.GetRequiredString(
                    claim, "writer_start_utc_ticks", claimLabel);
                var completedText = AICodedbStrictJson.GetRequiredString(
                    failure, "completed_at_utc", failureLabel);
                var reason = AICodedbStrictJson.GetRequiredString(failure, "reason", failureLabel);
                if (stageId.Length != 64 || !IsLowerHex(stageId)
                    || AICodedbStrictJson.GetRequiredInt32(admitted, "schema_version", admissionLabel) != 1
                    || AICodedbStrictJson.GetRequiredInt32(claim, "schema_version", claimLabel) != 1
                    || AICodedbStrictJson.GetRequiredInt32(failure, "schema_version", failureLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "state", admissionLabel), "admitted", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "state", claimLabel), "claimed", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(failure, "state", failureLabel), "start_failed", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "managed_by", admissionLabel), "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, "managed_by", claimLabel), "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(failure, "managed_by", failureLabel), "com.rice.ai-codedb", StringComparison.Ordinal)
                    || (reason != "CHILD_START_FAILED" && reason != "CHILD_START_RETURNED_FALSE")
                    || !long.TryParse(writerTicksText, NumberStyles.None, CultureInfo.InvariantCulture, out var writerTicks)
                    || writerTicks <= DateTime.MinValue.Ticks || writerTicks > DateTime.MaxValue.Ticks
                    || !completedText.EndsWith("Z", StringComparison.Ordinal)
                    || !DateTime.TryParseExact(completedText, "O", CultureInfo.InvariantCulture,
                        DateTimeStyles.RoundtripKind, out var completed)
                    || completed.Kind != DateTimeKind.Utc || completed.Ticks < writerTicks
                    || AICodedbStrictJson.GetRequiredInt32(claim, "writer_pid", claimLabel) <= 0
                    || AICodedbStrictJson.GetRequiredInt32(claim, "writer_pid", claimLabel)
                       != AICodedbStrictJson.GetRequiredInt32(failure, "writer_pid", failureLabel))
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "The Manager action start-failure envelope is invalid.");

                foreach (var key in new[] { "action_id", "stage_id", "project_key", "package_key" })
                {
                    var expected = key == "action_id" ? actionId
                        : key == "stage_id" ? stageId
                        : key == "project_key" ? AICodedbPaths.GetManagerActionProjectKey(context)
                        : AICodedbPaths.GetManagerActionPackageKey(context);
                    if (!string.Equals(AICodedbStrictJson.GetRequiredString(admitted, key, admissionLabel), expected, StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(claim, key, claimLabel), expected, StringComparison.Ordinal)
                        || !string.Equals(AICodedbStrictJson.GetRequiredString(failure, key, failureLabel), expected, StringComparison.Ordinal))
                        return AICodedbManagerActionRecoveryOutcome.Conflict(
                            "The Manager action start-failure identity does not match its admission.");
                }
                if (!string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_root", admissionLabel),
                        context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "package_root", admissionLabel),
                        context.PackageRoot, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_identity", admissionLabel),
                        "sha256:" + AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "package_identity", admissionLabel),
                        "sha256:" + AICodedbPaths.GetManagerActionPackageKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "command_identity_sha256", admissionLabel),
                        AICodedbStrictJson.GetRequiredString(failure, "command_identity_sha256", failureLabel),
                        StringComparison.Ordinal))
                    return AICodedbManagerActionRecoveryOutcome.Conflict(
                        "The Manager action start-failure command identity is invalid.");
                return AICodedbManagerActionRecoveryOutcome.PreEffectRefusal(
                    PreEffectManagerActionResult(actionId,
                        "The one-shot writer proved that the business child did not start (" + reason + ")."));
            }
            catch (Exception exception)
            {
                return AICodedbManagerActionRecoveryOutcome.Conflict(
                    "Manager action start-failure validation failed: " + exception.Message);
            }
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
                actionId,
                false,
                AICodedbManagerActionEvidenceKind.Indeterminate);
        }

        private static AICodedbCommandResult PreEffectManagerActionResult(string actionId, string detail)
        {
            return new AICodedbCommandResult(4, string.Empty, detail, false, 0,
                false, false, actionId, false,
                AICodedbManagerActionEvidenceKind.PreEffectRefusal);
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
                .Append("\n  \"storage_layout\": \"compact-v1\",")
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

        private static string ReceiptSibling(string path, string kind)
        {
            var name = Path.GetFileName(path);
            var prefix = name.Length > 17 && name[16] == '.' ? name.Substring(0, 17) : string.Empty;
            return Path.Combine(Path.GetDirectoryName(path), prefix + kind + ".json");
        }

        private static string ValidateReceiptLocation(AICodedbEditorExecutionContext context,
            string actionId, string path, string kind, params Dictionary<string, object>[] records)
        {
            var compact = Path.GetFileName(path) != kind + ".json";
            var layout = compact ? AICodedbPaths.CompactReceiptLayout : null;
            var stageId = AICodedbStrictJson.GetRequiredString(records[0], "stage_id", "Manager admission");
            var expected = AICodedbPaths.GetManagerStageReceiptPath(
                AICodedbPaths.GetManagerActionReceiptRoot(context, actionId, layout), stageId, kind, layout);
            if (!string.Equals(AICodedbPaths.NormalizePath(path), expected, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Manager stage locator conflicts with its full identity.");
            foreach (var record in records)
                if (AICodedbPaths.ReadReceiptStorageLayout(record) != layout)
                    throw new InvalidOperationException("Manager receipt storage layout is missing or conflicting.");
            return stageId;
        }

        internal static void PublishActionManifest(AICodedbManagerActionIndex index)
        {
            var context = index.Context;
            var root = AICodedbPaths.GetManagerActionReceiptRoot(context, index.ActionId);
            AssertReceiptPath(context, root);
            if (Directory.Exists(root))
                throw new InvalidOperationException("Manager action locator is already reserved; no adoption or replay is allowed.");
            Directory.CreateDirectory(root);
            AssertReceiptPath(context, root);
            var json = "{\"schema_version\":1,\"storage_layout\":\"compact-v1\",\"managed_by\":\"com.rice.ai-codedb\","
                + "\"action_id\":\"" + index.ActionId + "\",\"project_key\":\""
                + AICodedbPaths.GetManagerActionProjectKey(context) + "\",\"package_key\":\""
                + AICodedbPaths.GetManagerActionPackageKey(context) + "\",\"project_root\":\""
                + EscapeJson(context.ProjectRoot) + "\",\"package_root\":\"" + EscapeJson(context.PackageRoot) + "\""
                + (string.IsNullOrEmpty(index.ExecutionRoute) ? string.Empty
                    : ",\"execution_route\":\"" + EscapeJson(index.ExecutionRoute) + "\"") + "}";
            WriteNewUtf8FileAtomic(Path.Combine(root, "action.json"), json);
            ValidateActionManifest(context, index.ActionId);
        }

        internal static void ValidateActionManifest(AICodedbEditorExecutionContext context, string actionId)
        {
            var path = Path.Combine(AICodedbPaths.GetManagerActionReceiptRoot(context, actionId), "action.json");
            AssertReceiptPath(context, path);
            var record = AICodedbStrictJson.ReadObject(path, 16384, "Manager action identity manifest");
            const string label = "Manager action identity manifest";
            if (AICodedbPaths.ReadReceiptStorageLayout(record) != AICodedbPaths.CompactReceiptLayout
                || AICodedbStrictJson.GetRequiredInt32(record, "schema_version", label) != 1
                || AICodedbStrictJson.GetRequiredString(record, "managed_by", label) != "com.rice.ai-codedb"
                || AICodedbStrictJson.GetRequiredString(record, "action_id", label) != actionId
                || AICodedbStrictJson.GetRequiredString(record, "project_key", label) != AICodedbPaths.GetManagerActionProjectKey(context)
                || AICodedbStrictJson.GetRequiredString(record, "package_key", label) != AICodedbPaths.GetManagerActionPackageKey(context)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "project_root", label), context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "package_root", label), context.PackageRoot, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Manager action locator conflicts with its complete identity.");
            AICodedbInstallAdmission.ValidateRoute(context, actionId, record);
        }

        private static void AssertReceiptPath(
            AICodedbEditorExecutionContext context,
            string path)
        {
            var root = AICodedbPaths.GetManagerActionsRoot().TrimEnd('/');
            var normalized = AICodedbPaths.NormalizePath(path);
            if (!normalized.StartsWith(root + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Manager action receipt path escapes its scoped root.");
            var volume = Path.GetPathRoot(normalized);
            var current = volume;
            var relative = normalized.Substring(volume.Length).TrimStart('/');
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
                using (var stream = new FileStream(temp, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    var bytes = new UTF8Encoding(false).GetBytes(value);
                    stream.Write(bytes, 0, bytes.Length);
                    stream.Flush(true);
                }
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
            if (AICodedbSupervisorProtocol.IsManagerActionId(AICodedbPaths.CurrentActionId))
                return PreEffectManagerActionResult(AICodedbPaths.CurrentActionId,
                    "PowerShell codedb scripts are currently supported only in the Windows Editor.");
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
