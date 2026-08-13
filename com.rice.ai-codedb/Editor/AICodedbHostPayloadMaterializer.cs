using System;
using System.Collections.Generic;
using System.Globalization;
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
        Redeploy,
        Repair,
        Sync,
        Remove
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
            var arguments = BuildScriptArguments(AICodedbHostPayloadAction.DryRun, false);
            return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScriptAsync(
                ReadTimeoutMilliseconds,
                arguments);
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
            var arguments = BuildScriptArguments(AICodedbHostPayloadAction.Upgrade, false);
            return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScriptAsync(
                MutationTimeoutMilliseconds,
                arguments);
        }

        internal static AICodedbCommandResult RunRedeploy(bool confirmedProjectMutation)
        {
            return Run(AICodedbHostPayloadAction.Redeploy, confirmedProjectMutation, true);
        }

        internal static AICodedbCommandResult RunRepair()
        {
            return Run(AICodedbHostPayloadAction.Repair, true, true);
        }

        internal static AICodedbCommandResult RunSync()
        {
            return Run(AICodedbHostPayloadAction.Sync, true, true);
        }

        internal static AICodedbCommandResult RunRemove()
        {
            return Run(AICodedbHostPayloadAction.Remove, true, true);
        }

        internal static string[] BuildScriptArguments(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation)
        {
            var requiresConfirmation = RequiresConfirmation(action);
            if (requiresConfirmation != confirmedProjectMutation)
                throw new ArgumentException(
                    requiresConfirmation
                        ? "Redeploy, Repair, Sync, and Remove require second-level project mutation confirmation."
                        : "DryRun, Verify, and Upgrade do not accept project mutation confirmation.",
                    nameof(confirmedProjectMutation));

            var arguments = new List<string>
            {
                "-Action",
                action.ToString(),
                "-ProjectRoot",
                AICodedbPaths.ProjectRoot
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
                   || action == AICodedbHostPayloadAction.Remove;
        }

        private static bool IsMutation(AICodedbHostPayloadAction action)
        {
            return action == AICodedbHostPayloadAction.Upgrade
                   || action == AICodedbHostPayloadAction.Redeploy
                   || action == AICodedbHostPayloadAction.Repair
                   || action == AICodedbHostPayloadAction.Sync
                   || action == AICodedbHostPayloadAction.Remove;
        }

        private static AICodedbCommandResult Run(
            AICodedbHostPayloadAction action,
            bool confirmedProjectMutation,
            bool showProgress)
        {
            string[] arguments;
            try
            {
                arguments = BuildScriptArguments(action, confirmedProjectMutation);
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
                return AICodedbProcessRunner.RunResolvedPackageMaterializerPowerShellScript(
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
                    "Recorded for a previous target generation; current target is " + expectedGenerationId + ". " + detail);
            }
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
