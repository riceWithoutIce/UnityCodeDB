using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using UnityEditor;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbHostPayloadAction
    {
        DryRun,
        Verify,
        Upgrade,
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

        internal static AICodedbCommandResult RunUpgrade()
        {
            return Run(AICodedbHostPayloadAction.Upgrade, string.Empty, false, true);
        }

        internal static Task<AICodedbCommandResult> RunUpgradeAsync()
        {
            var scriptPath = AICodedbPaths.HostPayloadMaterializerScriptPath;
            var arguments = BuildScriptArguments(AICodedbHostPayloadAction.Upgrade, string.Empty, false);
            return AICodedbProcessRunner.RunPowerShellScriptAsync(scriptPath, MutationTimeoutMilliseconds, arguments);
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
                throw new ArgumentException("DryRun, Verify, and Upgrade do not accept tracked-host authorization.", nameof(authorizationPath));

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

        private static bool IsMutation(AICodedbHostPayloadAction action)
        {
            return action == AICodedbHostPayloadAction.Upgrade || RequiresAuthorization(action);
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
                var timeout = IsMutation(action) ? MutationTimeoutMilliseconds : ReadTimeoutMilliseconds;
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
        SetupRequired,
        Current,
        Draining,
        UpgradeReady,
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
        internal bool IsCurrent => State == AICodedbHostPayloadState.Current || State == AICodedbHostPayloadState.Draining;
        internal bool IsDraining => State == AICodedbHostPayloadState.Draining;
        internal bool CanUpgradeAutomatically => State == AICodedbHostPayloadState.UpgradeReady;

        internal AICodedbHostPayloadStatus(
            AICodedbHostPayloadState state,
            AICodedbStatusState displayState,
            string summary,
            string detail,
            string[] activeOwners = null,
            int legacyMcpSessionCount = 0)
        {
            State = state;
            DisplayState = displayState;
            Summary = summary ?? string.Empty;
            Detail = detail ?? string.Empty;
            ActiveOwners = activeOwners ?? Array.Empty<string>();
            LegacyMcpSessionCount = Math.Max(0, legacyMcpSessionCount);
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
                    legacyMcpSessionCount);
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
            var count = 0;
            foreach (var owner in activeOwners)
            {
                var match = LegacyOwnerPattern.Match(owner);
                if (match.Success
                    && string.Equals(match.Groups[1].Value, "mcp", StringComparison.OrdinalIgnoreCase))
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
        Invalid
    }

    internal readonly struct AICodedbHostUpgradeStatus
    {
        internal AICodedbHostUpgradePhase Phase { get; }
        internal AICodedbStatusState DisplayState { get; }
        internal string GenerationId { get; }
        internal string Summary { get; }
        internal string Detail { get; }

        internal AICodedbHostUpgradeStatus(
            AICodedbHostUpgradePhase phase,
            AICodedbStatusState displayState,
            string generationId,
            string summary,
            string detail)
        {
            Phase = phase;
            DisplayState = displayState;
            GenerationId = generationId ?? string.Empty;
            Summary = summary ?? string.Empty;
            Detail = detail ?? string.Empty;
        }

        internal AICodedbStatusItem ToStatusItem(bool hostPayloadMarkerExists)
        {
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

                var fileInfo = new FileInfo(path);
                if (fileInfo.Length <= 0 || fileInfo.Length > 64 * 1024)
                    throw new InvalidOperationException("Host upgrade state has an invalid size.");
                return Parse(File.ReadAllText(path), normalizedRoot, path);
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
            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
                var document = UnityEngine.JsonUtility.FromJson<HostUpgradeStateDocument>(json);
                DateTime updatedAt;
                if (document == null
                    || document.schema_version != 1
                    || !string.Equals(document.managed_by, ManagedBy, StringComparison.Ordinal)
                    || !string.Equals(
                        AICodedbPaths.NormalizePath(document.project_root).TrimEnd('/'),
                        normalizedRoot,
                        StringComparison.OrdinalIgnoreCase)
                    || !IsValidGenerationId(document.generation_id)
                    || !DateTime.TryParse(document.updated_at_utc, out updatedAt)
                    || (document.message != null && document.message.Length > 512))
                    throw new InvalidOperationException("Host upgrade state has invalid identity or schema.");

                var detail = string.IsNullOrWhiteSpace(document.message)
                    ? (detailPath ?? string.Empty)
                    : document.message.Trim();
                switch (document.state)
                {
                    case "INSTALLING":
                        return Create(AICodedbHostUpgradePhase.Installing, AICodedbStatusState.Warning, document, detail);
                    case "SWITCHING":
                        return Create(AICodedbHostUpgradePhase.Switching, AICodedbStatusState.Warning, document, detail);
                    case "ROLLBACK":
                        return Create(AICodedbHostUpgradePhase.Rollback, AICodedbStatusState.Error, document, detail);
                    case "CURRENT":
                        return Create(AICodedbHostUpgradePhase.Current, AICodedbStatusState.Ok, document, detail);
                    case "CHECK_FAILED":
                        return Create(AICodedbHostUpgradePhase.CheckFailed, AICodedbStatusState.Error, document, detail);
                    default:
                        throw new InvalidOperationException("Host upgrade state has an unsupported phase.");
                }
            }
            catch (Exception exception)
            {
                return Invalid(exception.Message);
            }
        }

        private static AICodedbHostUpgradeStatus Create(
            AICodedbHostUpgradePhase phase,
            AICodedbStatusState displayState,
            HostUpgradeStateDocument document,
            string detail)
        {
            return new AICodedbHostUpgradeStatus(
                phase,
                displayState,
                document.generation_id,
                document.state + " / " + document.generation_id,
                detail);
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
