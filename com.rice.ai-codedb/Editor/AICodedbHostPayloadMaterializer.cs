using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using UnityEditor;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbHostPayloadAction
    {
        DryRun,
        Verify,
        Sync,
        Remove
    }

    internal static class AICodedbHostPayloadMaterializer
    {
        private const int ReadTimeoutMilliseconds = 120000;
        private const int MutationTimeoutMilliseconds = 600000;

        internal static AICodedbCommandResult ReadStatus()
        {
            return Run(AICodedbHostPayloadAction.DryRun, string.Empty, false, false);
        }

        internal static Task<AICodedbCommandResult> ReadStatusAsync()
        {
            var scriptPath = AICodedbPaths.HostPayloadMaterializerScriptPath;
            var arguments = BuildScriptArguments(AICodedbHostPayloadAction.DryRun, string.Empty, false);
            return AICodedbProcessRunner.RunPowerShellScriptAsync(scriptPath, ReadTimeoutMilliseconds, arguments);
        }

        internal static AICodedbCommandResult RunDryRun()
        {
            return Run(AICodedbHostPayloadAction.DryRun, string.Empty, false, true);
        }

        internal static AICodedbCommandResult RunVerify()
        {
            return Run(AICodedbHostPayloadAction.Verify, string.Empty, false, true);
        }

        internal static AICodedbCommandResult RunSync(string authorizationPath, bool confirmLegacyMcpStopped)
        {
            return Run(AICodedbHostPayloadAction.Sync, authorizationPath, confirmLegacyMcpStopped, true);
        }

        internal static AICodedbCommandResult RunRemove(string authorizationPath, bool confirmLegacyMcpStopped)
        {
            return Run(AICodedbHostPayloadAction.Remove, authorizationPath, confirmLegacyMcpStopped, true);
        }

        internal static string[] BuildScriptArguments(
            AICodedbHostPayloadAction action,
            string authorizationPath,
            bool confirmLegacyMcpStopped)
        {
            var requiresAuthorization = RequiresAuthorization(action);
            if (requiresAuthorization && string.IsNullOrWhiteSpace(authorizationPath))
                throw new ArgumentException("Sync and Remove require an explicitly selected tracked-host authorization path.", nameof(authorizationPath));

            if (requiresAuthorization && !Path.IsPathRooted(authorizationPath.Trim()))
                throw new ArgumentException("Tracked-host authorization path must be absolute.", nameof(authorizationPath));

            if (!requiresAuthorization && !string.IsNullOrWhiteSpace(authorizationPath))
                throw new ArgumentException("DryRun and Verify do not accept tracked-host authorization.", nameof(authorizationPath));

            if (!requiresAuthorization && confirmLegacyMcpStopped)
                throw new ArgumentException("Legacy MCP confirmation is valid only for Sync or Remove.", nameof(confirmLegacyMcpStopped));

            var arguments = new List<string>
            {
                "-Action",
                action.ToString(),
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot
            };

            if (requiresAuthorization)
            {
                arguments.Add("-TrackedHostAuthorizationPath");
                arguments.Add(authorizationPath.Trim());
                if (confirmLegacyMcpStopped)
                    arguments.Add("-ConfirmLegacyMcpStopped");
            }

            return arguments.ToArray();
        }

        private static bool RequiresAuthorization(AICodedbHostPayloadAction action)
        {
            return action == AICodedbHostPayloadAction.Sync || action == AICodedbHostPayloadAction.Remove;
        }

        private static AICodedbCommandResult Run(
            AICodedbHostPayloadAction action,
            string authorizationPath,
            bool confirmLegacyMcpStopped,
            bool showProgress)
        {
            string[] arguments;
            try
            {
                arguments = BuildScriptArguments(action, authorizationPath, confirmLegacyMcpStopped);
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
                var timeout = RequiresAuthorization(action) ? MutationTimeoutMilliseconds : ReadTimeoutMilliseconds;
                return AICodedbProcessRunner.RunPowerShellScript(
                    AICodedbPaths.HostPayloadMaterializerScriptPath,
                    timeout,
                    arguments);
            }
            finally
            {
                if (showProgress)
                    EditorUtility.ClearProgressBar();
            }
        }
    }

    internal enum AICodedbHostPayloadState
    {
        Unknown,
        NotInstalled,
        Current,
        Stale,
        Conflict
    }

    internal readonly struct AICodedbHostPayloadStatus
    {
        internal AICodedbHostPayloadState State { get; }
        internal AICodedbStatusState DisplayState { get; }
        internal string Summary { get; }
        internal string Detail { get; }
        internal bool IsCurrent => State == AICodedbHostPayloadState.Current;

        internal AICodedbHostPayloadStatus(
            AICodedbHostPayloadState state,
            AICodedbStatusState displayState,
            string summary,
            string detail)
        {
            State = state;
            DisplayState = displayState;
            Summary = summary ?? string.Empty;
            Detail = detail ?? string.Empty;
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
        internal static AICodedbHostPayloadStatus Build(bool markerExists, AICodedbCommandResult result)
        {
            if (result == null)
                return Unknown("Materializer status has not been checked.");

            var output = result.StandardOutput ?? string.Empty;
            var error = result.StandardError ?? string.Empty;
            var combined = output + "\n" + error;

            if (Contains(combined, "[CONFLICT]") || Contains(combined, "Host payload has conflicts"))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Conflict,
                    AICodedbStatusState.Error,
                    markerExists ? "Installed / Conflict" : "Conflict",
                    FirstMatchingLine(combined, "[CONFLICT]", "Host payload has conflicts"));
            }

            if (result.TimedOut)
                return Unknown("Materializer DryRun timed out.");

            if (!result.Succeeded)
            {
                var detail = FirstNonEmptyLine(error);
                return Unknown(string.IsNullOrWhiteSpace(detail) ? result.GetSummary() : detail);
            }

            if (Contains(output, "[OK] Host payload is current.")
                || Contains(output, "[OK] Host payload marker and managed files are current."))
            {
                return new AICodedbHostPayloadStatus(
                    AICodedbHostPayloadState.Current,
                    AICodedbStatusState.Ok,
                    "Installed / Current",
                    AICodedbProjectSettings.HostPayloadMarkerRelativePath);
            }

            if (Contains(output, "[STALE] Host payload can be synchronized"))
            {
                return new AICodedbHostPayloadStatus(
                    markerExists ? AICodedbHostPayloadState.Stale : AICodedbHostPayloadState.NotInstalled,
                    AICodedbStatusState.Warning,
                    markerExists ? "Installed / Stale" : "Not Installed",
                    LastMarkedLine(output));
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
}
