using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbManagerActionIndex
    {
        internal string ActionId { get; }
        internal string Title { get; }
        internal string EffectClass { get; }
        internal string AuthorizationSource { get; }
        internal AICodedbEditorExecutionContext Context { get; }

        internal AICodedbManagerActionIndex(string actionId, string title,
            string effectClass, string authorizationSource,
            AICodedbEditorExecutionContext context)
        {
            ActionId = actionId;
            Title = title;
            EffectClass = effectClass;
            AuthorizationSource = authorizationSource;
            Context = context;
        }
    }

    internal enum AICodedbManagerActionIndexState
    {
        Empty,
        Pending,
        Conflict
    }

    internal sealed class AICodedbManagerActionIndexRead
    {
        internal AICodedbManagerActionIndexState State { get; }
        internal AICodedbManagerActionIndex Index { get; }
        internal string Detail { get; }
        internal string ActionId { get; }
        internal bool IsLegacyReceipt { get; }

        internal AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState state,
            AICodedbManagerActionIndex index = null, string detail = null,
            string actionId = null, bool isLegacyReceipt = false)
        {
            State = state;
            Index = index;
            Detail = detail ?? string.Empty;
            ActionId = index?.ActionId ?? actionId ?? string.Empty;
            IsLegacyReceipt = isLegacyReceipt;
        }
    }

    // This index correlates human intent only. The writer or Supervisor remains
    // the sole authority for whether its command reached a terminal state.
    internal static class AICodedbManagerActionJournal
    {
        private const int MaximumBytes = 16384;
        private const int LegacyAdmissionMaximumBytes = 262144;
        private const string HistoricalActionId = "3049af7cfc9f4260928e3f89d18672c0";
        private const string HistoricalStageId = "b571e3a38c0f134306d1df4d412804de66048b32de371c95112d363e6b664b56";
        private static readonly UTF8Encoding Utf8 = new UTF8Encoding(false);

        private sealed class ResolvedMarker
        {
            internal string PackageKey;
            internal AICodedbManagerActionEvidenceKind Disposition;
            internal bool HistoricalUnknown;
            internal string StageId;
            internal string AdmissionSha256;
            internal string ClaimSha256;
            internal string CommandIdentitySha256;
            internal string ProjectProofSha256;
            internal int WriterPid;
            internal string WriterStartTicks;
        }

        internal static AICodedbManagerActionIndexRead Read(AICodedbEditorExecutionContext context)
        {
            var candidateId = string.Empty;
            try
            {
                var directory = AICodedbPaths.GetManagerActionIndexDirectory(context);
                AssertPath(directory);
                if (!Directory.Exists(directory))
                    return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Empty);
                var files = Directory.GetFiles(directory);
                var path = string.Empty;
                var resolved = new Dictionary<string, ResolvedMarker>(StringComparer.Ordinal);
                if (files.Length > 4098)
                    return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                        null, "The Manager action index exceeds its bounded record count.");
                foreach (var file in files)
                {
                    AssertPath(file);
                    var name = Path.GetFileName(file);
                    if (name == "index.lock") continue;
                    if (name.StartsWith("resolved-action-", StringComparison.Ordinal))
                    {
                        var resolvedId = ParseActionIdFromFilename(name, "resolved-action-");
                        resolved.Add(resolvedId, ReadResolvedMarker(context, file, resolvedId));
                        continue;
                    }
                    if (path.Length != 0 || !name.StartsWith("current-action-", StringComparison.Ordinal)
                        || !name.EndsWith(".json", StringComparison.Ordinal))
                        return new AICodedbManagerActionIndexRead(
                            AICodedbManagerActionIndexState.Conflict, null,
                            "The Manager action index contains conflicting or unexpected files.");
                    path = file;
                }
                if (path.Length == 0)
                    return ReadLegacyPending(context, directory, resolved);
                candidateId = ParseActionIdFromFilename(Path.GetFileName(path), "current-action-");
                var record = AICodedbStrictJson.ReadObject(path, MaximumBytes,
                    "CodeDB Manager action index");
                const string label = "CodeDB Manager action index";
                var actionId = AICodedbStrictJson.GetRequiredString(record, "action_id", label);
                var title = AICodedbStrictJson.GetRequiredString(record, "title", label);
                var projectRoot = AICodedbStrictJson.GetRequiredString(record, "project_root", label);
                var packageRoot = AICodedbStrictJson.GetRequiredString(record, "package_root", label);
                var effect = AICodedbStrictJson.GetRequiredString(record, "effect_class", label);
                var authority = AICodedbStrictJson.GetRequiredString(record, "authorization_source", label);
                var previousContext = new AICodedbEditorExecutionContext(
                    context.Platform, projectRoot, packageRoot, context.ProjectDisplayName);
                if (AICodedbStrictJson.GetRequiredInt32(record, "schema_version", label) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "managed_by", label),
                        "com.rice.ai-codedb", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "state", label),
                        "pending", StringComparison.Ordinal)
                    || !AICodedbSupervisorProtocol.IsManagerActionId(actionId)
                    || !string.Equals(actionId, candidateId, StringComparison.Ordinal)
                    || title.Length == 0 || title.Length > 128 || title.IndexOfAny(new[] { '\r', '\n', '|' }) >= 0
                    || !string.Equals(previousContext.ProjectRoot, context.ProjectRoot,
                        StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "project_key", label),
                        AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "package_key", label),
                        AICodedbPaths.GetManagerActionPackageKey(previousContext), StringComparison.Ordinal)
                    || !string.Equals(effect, AICodedbManagerActionSession.ClassifyEffect(title),
                        StringComparison.Ordinal)
                    || !string.Equals(authority, AICodedbManagerActionSession.ClassifyAuthority(title),
                        StringComparison.Ordinal)
                    || (resolved.TryGetValue(candidateId, out var closure)
                        && !string.Equals(closure.PackageKey,
                            AICodedbPaths.GetManagerActionPackageKey(previousContext), StringComparison.Ordinal)))
                {
                    return new AICodedbManagerActionIndexRead(
                        AICodedbManagerActionIndexState.Conflict, null,
                        "The project-stable Manager action index has conflicting identity or action metadata.",
                        candidateId);
                }
                return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Pending,
                    new AICodedbManagerActionIndex(actionId, title, effect, authority, previousContext));
            }
            catch (Exception exception)
            {
                return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                    null, "Manager action index validation failed: " + exception.Message,
                    candidateId);
            }
        }

        private static string ParseActionIdFromFilename(string name, string prefix)
        {
            if (!name.StartsWith(prefix, StringComparison.Ordinal)
                || name.Length != prefix.Length + 32 + ".json".Length
                || !name.EndsWith(".json", StringComparison.Ordinal))
                throw new InvalidOperationException("The Manager action index filename is invalid.");
            var id = name.Substring(prefix.Length, 32);
            if (!AICodedbSupervisorProtocol.IsManagerActionId(id))
                throw new InvalidOperationException("The Manager action index filename has an invalid action id.");
            return id;
        }

        private static ResolvedMarker ReadResolvedMarker(
            AICodedbEditorExecutionContext context, string path, string actionId)
        {
            const string label = "resolved Manager action index";
            var record = AICodedbStrictJson.ReadObject(path, MaximumBytes, label);
            var packageRoot = AICodedbStrictJson.GetRequiredString(record, "package_root", label);
            var previous = new AICodedbEditorExecutionContext(context.Platform,
                context.ProjectRoot, packageRoot, context.ProjectDisplayName);
            var dispositionText = AICodedbStrictJson.GetRequiredString(record, "disposition", label);
            var historicalUnknown = dispositionText == "HistoricalUnknownReconciled";
            var schemaVersion = AICodedbStrictJson.GetRequiredInt32(record, "schema_version", label);
            if (schemaVersion != (historicalUnknown ? 2 : 1)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "managed_by", label),
                    "com.rice.ai-codedb", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "state", label),
                    "resolved", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "action_id", label),
                    actionId, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "project_root", label),
                    context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "project_key", label),
                    AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "package_key", label),
                    AICodedbPaths.GetManagerActionPackageKey(previous), StringComparison.Ordinal)
                || (dispositionText != "CommandTerminal" && dispositionText != "PreEffectRefusal"
                    && !historicalUnknown))
                throw new InvalidOperationException("The resolved Manager action marker is invalid.");
            var stageId = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "stage_id", label) : string.Empty;
            var admissionSha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "admission_sha256", label) : string.Empty;
            var claimSha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "claim_sha256", label) : string.Empty;
            var commandIdentitySha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "command_identity_sha256", label) : string.Empty;
            var firstProcessSha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "process_observation_first_sha256", label) : string.Empty;
            var secondProcessSha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "process_observation_second_sha256", label) : string.Empty;
            var projectProofSha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "project_proof_sha256", label) : string.Empty;
            var proofSha256 = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "proof_sha256", label) : string.Empty;
            var writerPid = historicalUnknown
                ? AICodedbStrictJson.GetRequiredInt32(record, "writer_pid", label) : 0;
            var writerStartTicks = historicalUnknown
                ? AICodedbStrictJson.GetRequiredString(record, "writer_start_utc_ticks", label) : string.Empty;
            if (historicalUnknown && (!IsLowerHex64(stageId)
                || !IsLowerHex64(admissionSha256) || !IsLowerHex64(claimSha256)
                || !IsLowerHex64(commandIdentitySha256)
                || !IsLowerHex64(firstProcessSha256) || !IsLowerHex64(secondProcessSha256)
                || !IsLowerHex64(projectProofSha256) || !IsLowerHex64(proofSha256)
                || !string.Equals(actionId, HistoricalActionId, StringComparison.Ordinal)
                || !string.Equals(stageId, HistoricalStageId, StringComparison.Ordinal)
                || writerPid <= 0 || writerStartTicks.Length < 15 || writerStartTicks.Length > 20
                || !IsDigits(writerStartTicks)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "proof_source", label),
                    "S27_WIN32_PROCESS_AND_LOCKED_MATERIALIZER_AUTHORITY", StringComparison.Ordinal)
                || string.IsNullOrWhiteSpace(AICodedbStrictJson.GetRequiredString(record,
                    "observed_at_utc", label))
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "command_outcome", label),
                    "unknown", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(record, "project_state", label),
                    "INSTALLED", StringComparison.Ordinal)
                || !string.Equals(proofSha256, ComputeTextSha256(string.Join("\n", new[]
                    {
                        actionId, stageId, admissionSha256, claimSha256, commandIdentitySha256,
                        firstProcessSha256, secondProcessSha256, projectProofSha256, projectProofSha256
                    })), StringComparison.Ordinal)))
                throw new InvalidOperationException("The historical unknown-action marker is invalid.");
            return new ResolvedMarker
            {
                PackageKey = AICodedbPaths.GetManagerActionPackageKey(previous),
                Disposition = dispositionText == "CommandTerminal"
                    ? AICodedbManagerActionEvidenceKind.CommandTerminal
                    : historicalUnknown ? AICodedbManagerActionEvidenceKind.Indeterminate
                        : AICodedbManagerActionEvidenceKind.PreEffectRefusal,
                HistoricalUnknown = historicalUnknown,
                StageId = stageId,
                AdmissionSha256 = admissionSha256,
                ClaimSha256 = claimSha256,
                CommandIdentitySha256 = commandIdentitySha256,
                ProjectProofSha256 = projectProofSha256,
                WriterPid = writerPid,
                WriterStartTicks = writerStartTicks
            };
        }

        private static AICodedbManagerActionIndexRead ReadLegacyPending(
            AICodedbEditorExecutionContext context, string directory,
            Dictionary<string, ResolvedMarker> resolved)
        {
            AICodedbManagerActionIndex pending = null;
            var matchedHistorical = new HashSet<string>(StringComparer.Ordinal);
            var packageDirectories = Directory.GetDirectories(directory);
            if (packageDirectories.Length > 64)
                return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                    null, "The project has too many historical Manager action Package directories.");
            var actionsSeen = 0;
            foreach (var packageDirectory in packageDirectories)
            {
                AssertPath(packageDirectory);
                if (!IsPhysicalKey(Path.GetFileName(packageDirectory))
                    || Directory.GetFiles(packageDirectory).Length != 0)
                    return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                        null, "A historical Manager action Package directory is invalid.");
                foreach (var actionDirectory in Directory.GetDirectories(packageDirectory))
                {
                    AssertPath(actionDirectory);
                    var actionId = Path.GetFileName(actionDirectory);
                    if (++actionsSeen > 4096 || !AICodedbSupervisorProtocol.IsManagerActionId(actionId))
                        return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                            null, "Historical Manager action receipt enumeration is invalid or exceeds its bound.",
                            actionId);
                    if (resolved.TryGetValue(actionId, out var provenRefusal)
                        && provenRefusal.Disposition == AICodedbManagerActionEvidenceKind.PreEffectRefusal)
                    {
                        if (!string.Equals(Path.GetFileName(packageDirectory),
                                provenRefusal.PackageKey.Substring(0, 24), StringComparison.Ordinal))
                            return new AICodedbManagerActionIndexRead(
                                AICodedbManagerActionIndexState.Conflict, null,
                                "A resolved pre-effect marker conflicts with its Package directory.", actionId);
                        continue;
                    }
                    try
                    {
                        var stages = Directory.GetDirectories(actionDirectory);
                        if (stages.Length == 0 || stages.Length > 32)
                            throw new InvalidOperationException("The historical action has invalid stage cardinality.");
                        AssertPath(stages[0]);
                        var admitted = AICodedbStrictJson.ReadObject(
                            Path.Combine(stages[0], "admitted.json"), LegacyAdmissionMaximumBytes,
                            "historical Manager action admission");
                        const string label = "historical Manager action admission";
                        var packageRoot = AICodedbStrictJson.GetRequiredString(admitted, "package_root", label);
                        var original = new AICodedbEditorExecutionContext(context.Platform,
                            context.ProjectRoot, packageRoot, context.ProjectDisplayName);
                        if (!string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "action_id", label),
                                actionId, StringComparison.Ordinal)
                            || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_root", label),
                                context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                            || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "project_key", label),
                                AICodedbPaths.GetManagerActionProjectKey(context), StringComparison.Ordinal)
                            || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted, "package_key", label),
                                AICodedbPaths.GetManagerActionPackageKey(original), StringComparison.Ordinal)
                            || !string.Equals(Path.GetFileName(packageDirectory),
                                AICodedbPaths.GetManagerActionPackageKey(original).Substring(0, 24),
                                StringComparison.Ordinal))
                            throw new InvalidOperationException("The historical action identity is conflicting.");
                        var outcome = AICodedbProcessRunner.RecoverManagerAction(original, actionId);
                        if (resolved.TryGetValue(actionId, out var marker))
                        {
                            if (!string.Equals(marker.PackageKey,
                                    AICodedbPaths.GetManagerActionPackageKey(original), StringComparison.Ordinal)
                                || (marker.Disposition == AICodedbManagerActionEvidenceKind.CommandTerminal
                                    && outcome.State != AICodedbManagerActionRecoveryState.Terminal)
                                || (marker.HistoricalUnknown
                                    && (outcome.State != AICodedbManagerActionRecoveryState.Pending
                                        || stages.Length != 1
                                        || !string.Equals(Path.GetFileName(stages[0]), marker.StageId,
                                            StringComparison.Ordinal)
                                        || !string.Equals(GetFileSha256(Path.Combine(stages[0], "admitted.json")),
                                            marker.AdmissionSha256, StringComparison.Ordinal)
                                        || !string.Equals(GetFileSha256(Path.Combine(stages[0], "claim.json")),
                                            marker.ClaimSha256, StringComparison.Ordinal)
                                        || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted,
                                                "command_identity_sha256", label),
                                            marker.CommandIdentitySha256, StringComparison.Ordinal)
                                        || !string.Equals(AICodedbStrictJson.GetRequiredString(admitted,
                                                "writer_sha256", label),
                                            "d6fa8f5a828fcc823e54b44683903e0ec3173d23b1af64931324fa2093a039cf",
                                            StringComparison.Ordinal)
                                        || !MatchesHistoricalClaim(stages[0], marker))))
                                throw new InvalidOperationException(
                                    "A resolved action marker conflicts with its original receipt.");
                            if (marker.HistoricalUnknown)
                                matchedHistorical.Add(actionId);
                            continue;
                        }
                        if (outcome.State == AICodedbManagerActionRecoveryState.Terminal
                            || outcome.State == AICodedbManagerActionRecoveryState.PreEffectRefusal)
                            continue;
                        if (outcome.State != AICodedbManagerActionRecoveryState.Pending || pending != null)
                            throw new InvalidOperationException(
                                "Historical action evidence is conflicting or has multiple pending owners.");
                        pending = new AICodedbManagerActionIndex(actionId,
                            "Previous CodeDB action", "ExistingBackendEffect",
                            "ExistingActionSpecificBackend", original);
                    }
                    catch (Exception exception)
                    {
                        return new AICodedbManagerActionIndexRead(
                            AICodedbManagerActionIndexState.Conflict, null,
                            "Historical Manager action receipt validation failed: " + exception.Message,
                            actionId);
                    }
                }
            }
            foreach (var closure in resolved)
                if (closure.Value.HistoricalUnknown && !matchedHistorical.Contains(closure.Key))
                    return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                        null, "A historical unknown-action marker has no matching original receipt.",
                        closure.Key);
            return pending == null
                ? new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Empty)
                : new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Pending,
                    pending, isLegacyReceipt: true);
        }

        private static bool IsPhysicalKey(string value)
        {
            if (value == null || value.Length != 24) return false;
            foreach (var character in value)
                if (!((character >= '0' && character <= '9')
                      || (character >= 'a' && character <= 'f')))
                    return false;
            return true;
        }

        private static bool IsLowerHex64(string value)
        {
            if (value == null || value.Length != 64) return false;
            foreach (var character in value)
                if (!((character >= '0' && character <= '9')
                      || (character >= 'a' && character <= 'f')))
                    return false;
            return true;
        }

        private static bool IsDigits(string value)
        {
            foreach (var character in value)
                if (character < '0' || character > '9') return false;
            return true;
        }

        private static bool MatchesHistoricalClaim(string stageDirectory, ResolvedMarker marker)
        {
            const string label = "historical Manager action claim";
            var claim = AICodedbStrictJson.ReadObject(
                Path.Combine(stageDirectory, "claim.json"), 65536, label);
            return AICodedbStrictJson.GetRequiredInt32(claim, "writer_pid", label) == marker.WriterPid
                && string.Equals(AICodedbStrictJson.GetRequiredString(claim,
                        "writer_start_utc_ticks", label), marker.WriterStartTicks,
                    StringComparison.Ordinal);
        }

        private static string GetFileSha256(string path)
        {
            AssertPath(path);
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var algorithm = SHA256.Create())
            {
                if (stream.Length <= 0 || stream.Length > LegacyAdmissionMaximumBytes)
                    throw new InvalidOperationException("Historical action evidence exceeds its size bound.");
                return BitConverter.ToString(algorithm.ComputeHash(stream))
                    .Replace("-", string.Empty).ToLowerInvariant();
            }
        }

        private static string ComputeTextSha256(string value)
        {
            using (var algorithm = SHA256.Create())
                return BitConverter.ToString(algorithm.ComputeHash(Utf8.GetBytes(value)))
                    .Replace("-", string.Empty).ToLowerInvariant();
        }

        internal static bool TryAdmit(AICodedbManagerActionIndex index, out string detail)
        {
            detail = string.Empty;
            try
            {
                var path = AICodedbPaths.GetManagerActionIndexPath(index.Context, index.ActionId);
                var directory = AICodedbPaths.GetManagerActionIndexDirectory(index.Context);
                AssertPath(directory);
                Directory.CreateDirectory(directory);
                AssertPath(path);
                var lockPath = Path.Combine(directory, "index.lock");
                AssertPath(lockPath);
                using (new FileStream(lockPath,
                           FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None))
                {
                    var existing = Read(index.Context);
                    if (existing.State != AICodedbManagerActionIndexState.Empty)
                    {
                        detail = "A project-stable Manager action index already exists; a second owner was blocked.";
                        return false;
                    }
                    if (File.Exists(Path.Combine(directory,
                            "resolved-action-" + index.ActionId + ".json")))
                    {
                        detail = "The Manager action id was already closed and cannot be reused.";
                        return false;
                    }
                var json = "{\n  \"schema_version\": 1,\n  \"managed_by\": \"com.rice.ai-codedb\","
                    + "\n  \"state\": \"pending\","
                    + "\n  \"action_id\": \"" + Escape(index.ActionId) + "\","
                    + "\n  \"title\": \"" + Escape(index.Title) + "\","
                    + "\n  \"effect_class\": \"" + Escape(index.EffectClass) + "\","
                    + "\n  \"authorization_source\": \"" + Escape(index.AuthorizationSource) + "\","
                    + "\n  \"project_key\": \"" + AICodedbPaths.GetManagerActionProjectKey(index.Context) + "\","
                    + "\n  \"package_key\": \"" + AICodedbPaths.GetManagerActionPackageKey(index.Context) + "\","
                    + "\n  \"project_root\": \"" + Escape(index.Context.ProjectRoot) + "\","
                    + "\n  \"package_root\": \"" + Escape(index.Context.PackageRoot) + "\"\n}\n";
                var temp = Path.Combine(AICodedbPaths.GetManagerActionsRoot(),
                    "index-" + Guid.NewGuid().ToString("N") + ".tmp");
                AssertPath(temp);
                try
                {
                    using (var stream = new FileStream(temp, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                    {
                        var bytes = Utf8.GetBytes(json);
                        stream.Write(bytes, 0, bytes.Length);
                        stream.Flush(true);
                    }
                    File.Move(temp, path);
                }
                finally
                {
                    if (File.Exists(temp)) File.Delete(temp);
                }
                var read = Read(index.Context);
                if (read.State != AICodedbManagerActionIndexState.Pending
                    || !string.Equals(read.Index.ActionId, index.ActionId, StringComparison.Ordinal))
                    throw new InvalidOperationException("The published Manager action index failed identity verification.");
                return true;
                }
            }
            catch (Exception exception)
            {
                detail = "Manager action durable admission failed: " + exception.Message;
                return false;
            }
        }

        internal static bool TryRelease(AICodedbManagerActionIndex index,
            AICodedbManagerActionEvidenceKind disposition, out string detail)
        {
            detail = string.Empty;
            if (disposition != AICodedbManagerActionEvidenceKind.CommandTerminal
                && disposition != AICodedbManagerActionEvidenceKind.PreEffectRefusal)
            {
                detail = "An indeterminate action cannot release its durable index.";
                return false;
            }
            try
            {
                var path = AICodedbPaths.GetManagerActionIndexPath(index.Context, index.ActionId);
                AssertPath(path);
                var lockPath = Path.Combine(Path.GetDirectoryName(path), "index.lock");
                AssertPath(lockPath);
                using (new FileStream(lockPath,
                           FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None))
                {
                    var read = Read(index.Context);
                    if (read.State != AICodedbManagerActionIndexState.Pending
                        || !string.Equals(read.Index.ActionId, index.ActionId, StringComparison.Ordinal)
                        || !string.Equals(read.Index.Context.PackageRoot, index.Context.PackageRoot,
                            StringComparison.OrdinalIgnoreCase))
                    {
                        detail = "The Manager action index no longer matches the completed action.";
                        return false;
                    }
                    var resolvedPath = Path.Combine(Path.GetDirectoryName(path),
                        "resolved-action-" + index.ActionId + ".json");
                    AssertPath(resolvedPath);
                    var resolvedJson = "{\n  \"schema_version\": 1,"
                        + "\n  \"managed_by\": \"com.rice.ai-codedb\","
                        + "\n  \"state\": \"resolved\","
                        + "\n  \"action_id\": \"" + index.ActionId + "\","
                        + "\n  \"project_key\": \"" + AICodedbPaths.GetManagerActionProjectKey(index.Context) + "\","
                        + "\n  \"package_key\": \"" + AICodedbPaths.GetManagerActionPackageKey(index.Context) + "\","
                        + "\n  \"project_root\": \"" + Escape(index.Context.ProjectRoot) + "\","
                        + "\n  \"package_root\": \"" + Escape(index.Context.PackageRoot) + "\","
                        + "\n  \"disposition\": \"" + disposition + "\"\n}\n";
                    if (File.Exists(resolvedPath))
                    {
                        if (!string.Equals(File.ReadAllText(resolvedPath, Utf8),
                                resolvedJson, StringComparison.Ordinal))
                            throw new InvalidOperationException("The resolved action marker conflicts with this action.");
                    }
                    else
                    {
                        var temp = Path.Combine(AICodedbPaths.GetManagerActionsRoot(),
                            "index-" + Guid.NewGuid().ToString("N") + ".tmp");
                        AssertPath(temp);
                        try
                        {
                            using (var stream = new FileStream(temp, FileMode.CreateNew,
                                       FileAccess.Write, FileShare.None))
                            {
                                var bytes = Utf8.GetBytes(resolvedJson);
                                stream.Write(bytes, 0, bytes.Length);
                                stream.Flush(true);
                            }
                            File.Move(temp, resolvedPath);
                        }
                        finally
                        {
                            if (File.Exists(temp)) File.Delete(temp);
                        }
                    }
                    File.Delete(path);
                }
                return true;
            }
            catch (Exception exception)
            {
                detail = "Manager action index release failed: " + exception.Message;
                return false;
            }
        }

        private static void AssertPath(string path)
        {
            var root = AICodedbPaths.GetManagerActionsRoot().TrimEnd('/', '\\');
            var normalized = AICodedbPaths.NormalizePath(path);
            if (!normalized.StartsWith(root + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Manager action index escapes its user-local root.");
            var volume = Path.GetPathRoot(normalized);
            var current = volume;
            foreach (var segment in normalized.Substring(volume.Length).TrimStart('/', '\\')
                         .Split(new[] { '/', '\\' }, StringSplitOptions.RemoveEmptyEntries))
            {
                current = Path.Combine(current, segment);
                if (!File.Exists(current) && !Directory.Exists(current)) break;
                if ((File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
                    throw new InvalidOperationException("Manager action index traverses a reparse point.");
            }
        }

        private static string Escape(string value)
        {
            var builder = new StringBuilder();
            foreach (var character in value ?? string.Empty)
            {
                switch (character)
                {
                    case '\\': builder.Append("\\\\"); break;
                    case '"': builder.Append("\\\""); break;
                    case '\n': builder.Append("\\n"); break;
                    case '\r': builder.Append("\\r"); break;
                    case '\t': builder.Append("\\t"); break;
                    default:
                        if (character < 0x20)
                            builder.Append("\\u").Append(((int)character).ToString("x4"));
                        else builder.Append(character);
                        break;
                }
            }
            return builder.ToString();
        }
    }
}
