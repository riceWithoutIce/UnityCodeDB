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
        internal string StorageLayout { get; }

        internal AICodedbManagerActionIndex(string actionId, string title,
            string effectClass, string authorizationSource,
            AICodedbEditorExecutionContext context, string storageLayout = AICodedbPaths.CompactReceiptLayout)
        {
            ActionId = actionId;
            Title = title;
            EffectClass = effectClass;
            AuthorizationSource = authorizationSource;
            Context = context;
            StorageLayout = storageLayout;
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
        internal string HistoricalWarning { get; }
        internal AICodedbCommandResult HistoricalResult { get; }

        internal AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState state,
            AICodedbManagerActionIndex index = null, string detail = null,
            string actionId = null, bool isLegacyReceipt = false,
            string historicalWarning = null, AICodedbCommandResult historicalResult = null)
        {
            State = state;
            Index = index;
            Detail = detail ?? string.Empty;
            ActionId = index?.ActionId ?? actionId ?? string.Empty;
            IsLegacyReceipt = isLegacyReceipt;
            HistoricalWarning = historicalWarning ?? string.Empty;
            HistoricalResult = historicalResult;
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
            internal string StorageLayout;
            internal AICodedbEditorExecutionContext Context;
            internal string PackageKey;
            internal AICodedbManagerActionEvidenceKind Disposition;
            internal bool HistoricalUnknown;
            internal bool RetainedEffects;
            internal AICodedbCommandResult OriginalResult;
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
                    if (name.StartsWith("resolved-action-", StringComparison.Ordinal)
                        && name.EndsWith(".pending.json", StringComparison.Ordinal))
                    {
                        var pendingId = name.Substring("resolved-action-".Length,
                            name.Length - "resolved-action-".Length - ".pending.json".Length);
                        if (!AICodedbSupervisorProtocol.IsManagerActionId(pendingId))
                            throw new InvalidOperationException("Pending candidate disposition id is invalid.");
                        // Pending bytes are never closure authority. Authenticate
                        // the original current index below so explicit completion
                        // remains possible after reload; all mutations stay gated.
                        continue;
                    }
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
                var storageLayout = AICodedbPaths.ReadReceiptStorageLayout(record);
                var previousContext = new AICodedbEditorExecutionContext(
                    context.Platform, projectRoot, packageRoot, context.ProjectDisplayName);
                if (Directory.Exists(AICodedbPaths.GetManagerActionReceiptRoot(previousContext, actionId,
                        storageLayout == null ? AICodedbPaths.CompactReceiptLayout : null)))
                    throw new InvalidOperationException("Journal layout conflicts with another action location.");
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
                        && (closure.StorageLayout != storageLayout || !string.Equals(closure.PackageKey,
                            AICodedbPaths.GetManagerActionPackageKey(previousContext), StringComparison.Ordinal))))
                {
                    return new AICodedbManagerActionIndexRead(
                        AICodedbManagerActionIndexState.Conflict, null,
                        "The project-stable Manager action index has conflicting identity or action metadata.",
                        candidateId);
                }
                // Display history is independent of this current index. Reading it
                // never changes the disposition or permits a second owner.
                if (closure != null && closure.RetainedEffects)
                    return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Empty,
                        new AICodedbManagerActionIndex(actionId, title, effect, authority, previousContext, storageLayout),
                        historicalWarning: "Original INSTALL remains failed/unknown; its candidate effects are inert and retained.",
                        historicalResult: closure.OriginalResult);
                var history = ReadLegacyPending(context, directory, resolved);
                return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Pending,
                    new AICodedbManagerActionIndex(actionId, title, effect, authority, previousContext, storageLayout),
                    historicalWarning: history.State == AICodedbManagerActionIndexState.Conflict
                        ? "Retained action history could not be verified: " + history.Detail
                        : history.HistoricalWarning);
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
            if (dispositionText == "FailedCandidateEffectsRetained")
                return ReadRetainedEffectsMarker(context, previous, record, actionId);
            var historicalUnknown = dispositionText == "HistoricalUnknownReconciled";
            var storageLayout = AICodedbPaths.ReadReceiptStorageLayout(record);
            var schemaVersion = AICodedbStrictJson.GetRequiredInt32(record, "schema_version", label);
            if (Directory.Exists(AICodedbPaths.GetManagerActionReceiptRoot(previous, actionId,
                    storageLayout == null ? AICodedbPaths.CompactReceiptLayout : null)))
                throw new InvalidOperationException("Resolved marker layout conflicts with another action location.");
            if ((historicalUnknown && storageLayout != null) || schemaVersion != (historicalUnknown ? 2 : 1)
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
                StorageLayout = storageLayout,
                Context = previous,
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

        private static ResolvedMarker ReadRetainedEffectsMarker(
            AICodedbEditorExecutionContext current, AICodedbEditorExecutionContext original,
            Dictionary<string, object> marker, string actionId)
        {
            const string label = "failed candidate effects disposition";
            Func<Dictionary<string, object>, string, string> value =
                (record, field) => AICodedbStrictJson.GetRequiredString(record, field, label);
            var layout = AICodedbPaths.ReadReceiptStorageLayout(marker);
            var stageId = value(marker, "stage_id");
            var stateId = value(marker, "removal_state_id");
            var instanceId = value(marker, "retained_instance_id");
            if (AICodedbStrictJson.GetRequiredInt32(marker, "schema_version", label) != 2
                || value(marker, "managed_by") != "com.rice.ai-codedb" || value(marker, "state") != "resolved"
                || value(marker, "action_id") != actionId || !IsLowerHex64(stageId)
                || !AICodedbSupervisorProtocol.IsManagerActionId(stateId)
                || !AICodedbSupervisorProtocol.IsManagerActionId(instanceId)
                || !string.Equals(value(marker, "project_root"), current.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                || value(marker, "project_key") != AICodedbPaths.GetManagerActionProjectKey(current)
                || value(marker, "package_key") != AICodedbPaths.GetManagerActionPackageKey(original)
                || value(marker, "command_outcome") != "failed_or_unknown"
                || value(marker, "project_state") != "UNINSTALLED"
                || !IsLowerHex64(value(marker, "process_observation_first_sha256"))
                || !IsLowerHex64(value(marker, "process_observation_second_sha256")))
                throw new InvalidOperationException("Failed candidate disposition identity is invalid.");
            var actionRoot = AICodedbPaths.GetManagerActionReceiptRoot(original, actionId, layout);
            if (Directory.Exists(AICodedbPaths.GetManagerActionReceiptRoot(original, actionId,
                    layout == null ? AICodedbPaths.CompactReceiptLayout : null)))
                throw new InvalidOperationException("Failed candidate receipt layouts conflict.");
            var receipts = new Dictionary<string, Dictionary<string, object>>(StringComparer.Ordinal);
            foreach (var kind in new[] { "admitted", "claim", "terminal" })
            {
                var path = AICodedbPaths.GetManagerStageReceiptPath(actionRoot, stageId, kind, layout);
                AssertPath(path);
                var hashName = kind == "admitted" ? "admission_sha256" : kind + "_sha256";
                if (!IsLowerHex64(value(marker, hashName)) || GetFileSha256(path) != value(marker, hashName))
                    throw new InvalidOperationException("Failed candidate original receipt hash changed.");
                var receipt = AICodedbStrictJson.ReadObject(path, LegacyAdmissionMaximumBytes, label);
                if (AICodedbStrictJson.GetRequiredInt32(receipt, "schema_version", label) != 1
                    || value(receipt, "managed_by") != "com.rice.ai-codedb"
                    || value(receipt, "action_id") != actionId || value(receipt, "stage_id") != stageId
                    || value(receipt, "project_key") != value(marker, "project_key")
                    || value(receipt, "package_key") != value(marker, "package_key")
                    || AICodedbPaths.ReadReceiptStorageLayout(receipt) != layout)
                    throw new InvalidOperationException("Failed candidate original receipt identity changed.");
                receipts.Add(kind, receipt);
            }
            var admission = receipts["admitted"];
            var terminal = receipts["terminal"];
            if (value(admission, "state") != "admitted" || value(receipts["claim"], "state") != "claimed"
                || value(terminal, "state") != "terminal"
                || value(admission, "command_identity_sha256") != value(marker, "command_identity_sha256")
                || value(terminal, "command_identity_sha256") != value(marker, "command_identity_sha256")
                || !IsLowerHex64(value(marker, "command_identity_sha256"))
                || value(admission, "effect_class") != "ConfirmedProjectMutation"
                || value(admission, "authorization_source") != "UserConfirmationAndBackendAdmission"
                || !AICodedbStrictJson.GetRequiredBoolean(admission, "terminal_for_action", label)
                || !AICodedbStrictJson.GetRequiredBoolean(terminal, "terminal_for_action", label)
                || AICodedbStrictJson.GetRequiredInt32(terminal, "exit_code", label) == 0)
                throw new InvalidOperationException("Failed candidate original INSTALL outcome is invalid.");
            var intentRelative = "AIWork/.runtime/codedb/control/removal-intents/" + stateId + ".json";
            if (value(marker, "removal_intent_relative_path") != intentRelative)
                throw new InvalidOperationException("Failed candidate intent path is invalid.");
            var intentPath = RetainedProjectPath(current, intentRelative);
            if (!IsLowerHex64(value(marker, "removal_intent_sha256"))
                || RetainedFileHash(intentPath) != value(marker, "removal_intent_sha256"))
                throw new InvalidOperationException("Failed candidate intent hash changed.");
            var intent = AICodedbStrictJson.ReadObject(intentPath, 131072, label);
            if (AICodedbStrictJson.GetRequiredInt32(intent, "schema_version", label) != 2
                || value(intent, "managed_by") != "com.rice.ai-codedb"
                || value(intent, "authority_kind") != "FAILED_PREPARATION"
                || value(intent, "state_id") != stateId || value(intent, "operation_id") != stateId
                || value(intent, "retained_instance_id") != instanceId
                || value(intent, "retained_generation_id") != value(marker, "retained_generation_id")
                || value(intent, "project_identity") != "sha256:" + value(marker, "project_key")
                || !string.Equals(value(intent, "project_root"), current.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                || !IsLowerHex64(value(intent, "authority_fingerprint")))
                throw new InvalidOperationException("Failed candidate intent identity is invalid.");
            var instanceRelative = "AIWork/.runtime/codedb/instances/" + instanceId;
            var instancePath = RetainedProjectPath(current, instanceRelative + "/instance.json");
            if (RetainedFileHash(instancePath) != value(intent, "retained_instance_manifest_sha256"))
                throw new InvalidOperationException("Failed candidate instance hash changed.");
            var instance = AICodedbStrictJson.ReadObject(instancePath, 131072, label);
            var origin = AICodedbStrictJson.RequireObject(instance["originating_action"], label);
            if (value(instance, "state") != "PROVISIONING" || value(instance, "verified_at_utc") != string.Empty
                || value(instance, "instance_id") != instanceId
                || value(instance, "generation_id") != value(marker, "retained_generation_id")
                || value(instance, "project_identity") != value(intent, "project_identity")
                || value(origin, "action") != "INSTALL" || value(origin, "action_id") != actionId)
                throw new InvalidOperationException("Failed candidate original instance linkage changed.");
            var effects = AICodedbStrictJson.GetRequiredArray(intent, "retained_effects", label);
            if (effects.Count == 0 || effects.Count > 512)
                throw new InvalidOperationException("Failed candidate effect inventory is invalid.");
            var snapshot = new HashSet<string>(StringComparer.Ordinal);
            var previous = string.Empty;
            foreach (var raw in effects)
            {
                var effect = AICodedbStrictJson.RequireObject(raw, label);
                var relative = value(effect, "relative_path");
                var path = RetainedProjectPath(current, relative);
                var kind = value(effect, "kind");
                if (!snapshot.Add(relative) || string.CompareOrdinal(previous, relative) >= 0
                    || (kind != "FILE" && kind != "DIRECTORY")
                    || (kind == "FILE" && (!IsLowerHex64(value(effect, "sha256"))
                        || RetainedFileHash(path) != value(effect, "sha256")))
                    || (kind == "DIRECTORY" && (!Directory.Exists(path) || value(effect, "sha256") != string.Empty)))
                    throw new InvalidOperationException("Failed candidate retained effects changed.");
                previous = relative;
            }
            foreach (var root in new[] { instanceRelative,
                "AIWork/.runtime/codedb/host/generations/" + value(marker, "retained_generation_id"), "AIWork/codedb" })
            {
                var queue = new Queue<string>(); queue.Enqueue(root);
                var count = 0;
                while (queue.Count != 0)
                {
                    var relative = queue.Dequeue();
                    if (++count > 512) throw new InvalidOperationException("Failed candidate effect inventory exceeds bounds.");
                    var path = RetainedProjectPath(current, relative);
                    if (relative != "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
                        && !snapshot.Contains(relative)
                        && !((relative == "AIWork/codedb" || relative == "AIWork/codedb/wrapper") && Directory.Exists(path)))
                        throw new InvalidOperationException("Failed candidate contains an unrecorded effect.");
                    if (Directory.Exists(path))
                        foreach (var child in Directory.GetFileSystemEntries(path))
                            queue.Enqueue(relative + "/" + Path.GetFileName(child));
                }
            }
            ValidateRetainedCurrentState(current, marker, intent, instanceId);
            var result = new AICodedbCommandResult(
                AICodedbStrictJson.GetRequiredInt32(terminal, "exit_code", label),
                value(terminal, "stdout"), value(terminal, "stderr"),
                AICodedbStrictJson.GetRequiredBoolean(terminal, "timed_out", label),
                authoritativeTerminalEvidence: false, actionId: actionId,
                managerActionEvidenceKind: AICodedbManagerActionEvidenceKind.FailedCandidateEffectsRetained,
                outputOverflow: AICodedbStrictJson.GetRequiredBoolean(terminal, "output_overflow", label),
                outputDrainIncomplete: AICodedbStrictJson.GetRequiredBoolean(terminal, "output_drain_incomplete", label));
            return new ResolvedMarker { Context = original, PackageKey = value(marker, "package_key"),
                StorageLayout = layout, StageId = stageId, RetainedEffects = true, OriginalResult = result,
                Disposition = AICodedbManagerActionEvidenceKind.FailedCandidateEffectsRetained };
        }

        private static string RetainedProjectPath(AICodedbEditorExecutionContext context, string relative)
        {
            if (string.IsNullOrEmpty(relative) || relative.IndexOf('\\') >= 0 || relative.StartsWith("/", StringComparison.Ordinal))
                throw new InvalidOperationException("Retained project path is invalid.");
            foreach (var segment in relative.Split('/'))
                if (segment.Length == 0 || segment == "." || segment == ".." || segment.IndexOf(':') >= 0)
                    throw new InvalidOperationException("Retained project path is redirected.");
            var root = Path.GetFullPath(context.ProjectRoot).TrimEnd('/', '\\');
            var path = Path.GetFullPath(Path.Combine(root, relative));
            if (!path.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Retained project path escapes project.");
            for (var item = path; !string.Equals(item, root, StringComparison.OrdinalIgnoreCase); item = Path.GetDirectoryName(item))
                if ((File.Exists(item) || Directory.Exists(item)) && (File.GetAttributes(item) & FileAttributes.ReparsePoint) != 0)
                    throw new InvalidOperationException("Retained project path contains a redirect.");
            return path;
        }

        private static string RetainedFileHash(string path)
        {
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var algorithm = SHA256.Create())
                return BitConverter.ToString(algorithm.ComputeHash(stream)).Replace("-", string.Empty).ToLowerInvariant();
        }

        private static void ValidateRetainedCurrentState(AICodedbEditorExecutionContext context,
            Dictionary<string, object> marker, Dictionary<string, object> intent, string retainedId)
        {
            const string label = "retained candidate current state";
            Func<Dictionary<string, object>, string, string> text =
                (record, field) => AICodedbStrictJson.GetRequiredString(record, field, label);
            var desiredPath = RetainedProjectPath(context, "AIWork/.runtime/codedb/control/desired-state.json");
            var desired = AICodedbStrictJson.ReadObject(desiredPath, 32768, label);
            if (AICodedbStrictJson.GetRequiredInt32(desired, "schema_version", label) != 1
                || text(desired, "managed_by") != "com.rice.ai-codedb"
                || text(desired, "project_identity") != text(intent, "project_identity")
                || !string.Equals(text(desired, "project_root"), context.ProjectRoot, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Retained candidate desired state identity conflicts.");
            if (text(desired, "desired_state") == "UNINSTALLED")
            {
                if (text(desired, "state_id") != text(marker, "removal_state_id"))
                {
                    var nextState = text(desired, "state_id");
                    if (!AICodedbSupervisorProtocol.IsManagerActionId(nextState))
                        throw new InvalidOperationException("Retained candidate current removal state is invalid.");
                    var nextPath = RetainedProjectPath(context, "AIWork/.runtime/codedb/control/removal-intents/" + nextState + ".json");
                    var nextIntent = AICodedbStrictJson.ReadObject(nextPath, 131072, label);
                    var nextInstance = AICodedbStrictJson.ReadObject(RetainedProjectPath(context,
                        "AIWork/.runtime/codedb/instances/" + text(nextIntent, "retained_instance_id") + "/instance.json"), 131072, label);
                    var nextOrigin = AICodedbStrictJson.RequireObject(nextInstance["originating_action"], label);
                    var nextAction = text(nextOrigin, "action_id");
                    if (nextAction == text(marker, "action_id") || text(nextIntent, "retained_instance_id") == retainedId)
                        throw new InvalidOperationException("Retained candidate later removal conflicts with its original closure.");
                    var nextMarkerPath = Path.Combine(AICodedbPaths.GetManagerActionIndexDirectory(context),
                        "resolved-action-" + nextAction + ".json");
                    AssertPath(nextMarkerPath);
                    var nextMarker = AICodedbStrictJson.ReadObject(nextMarkerPath, MaximumBytes, label);
                    if (text(nextMarker, "disposition") != "FailedCandidateEffectsRetained"
                        || text(nextMarker, "removal_state_id") != nextState)
                        throw new InvalidOperationException("Retained candidate later removal has no matching effects disposition.");
                    var nextContext = new AICodedbEditorExecutionContext(context.Platform, context.ProjectRoot,
                        text(nextMarker, "package_root"), context.ProjectDisplayName);
                    ReadRetainedEffectsMarker(context, nextContext, nextMarker, nextAction);
                }
                else if (!IsLowerHex64(text(marker, "desired_state_sha256"))
                    || RetainedFileHash(desiredPath) != text(marker, "desired_state_sha256"))
                    throw new InvalidOperationException("Retained candidate current removal state changed.");
                foreach (var relative in new[] { "AIWork/.runtime/codedb/control/current-instance.json",
                    "AIWork/.runtime/codedb/control/last-known-good-instance.json",
                    "AIWork/.runtime/codedb/host/current.json", "AIWork/.runtime/codedb/host/last-known-good.json",
                    "AIWork/.runtime/codedb/control/contracts", "AIWork/.runtime/codedb/control/supervisor" })
                {
                    var path = RetainedProjectPath(context, relative);
                    if (File.Exists(path) || Directory.Exists(path))
                        throw new InvalidOperationException("Retained candidate current inactive authority conflicts.");
                }
                return;
            }
            // A subsequent explicit Install is a separate action. Preserve the
            // old failure only after authentic different READY/COMMITTED handoff.
            if (text(desired, "desired_state") != "INSTALLED")
                throw new InvalidOperationException("Retained candidate current disposition is unresolved.");
            var selected = AICodedbCurrentInstanceStore.Read(context.ProjectRoot, context.PackageRoot);
            if (!selected.CanPublishEditorLease || selected.InstanceId == retainedId)
                throw new InvalidOperationException("Retained candidate fresh selection is not authenticated.");
            var instancePath = RetainedProjectPath(context, selected.InstanceRelativePath + "/instance.json");
            var instance = AICodedbStrictJson.ReadObject(instancePath, 131072, label);
            var origin = AICodedbStrictJson.RequireObject(instance["originating_action"], label);
            var contract = AICodedbStrictJson.RequireObject(instance["control_contract"], label);
            var id = text(contract, "id");
            foreach (var character in id)
                if (!char.IsLetterOrDigit(character) && character != '-' && character != '_' && character != '.')
                    throw new InvalidOperationException("Retained candidate control contract path is invalid.");
            if (id.Length == 0 || id == "." || id == ".." || text(origin, "action") != "INSTALL"
                || text(instance, "state") != "READY" || text(origin, "action_id") == text(marker, "action_id"))
                throw new InvalidOperationException("Retained candidate fresh INSTALL origin is invalid.");
            var version = AICodedbStrictJson.GetRequiredInt32(contract, "version", label);
            var root = "AIWork/.runtime/codedb/control/contracts/" + id + "/v" + version.ToString(System.Globalization.CultureInfo.InvariantCulture);
            var activation = AICodedbStrictJson.ReadObject(RetainedProjectPath(context, root + "/activation.json"), 65536, label);
            var operation = AICodedbStrictJson.ReadObject(RetainedProjectPath(context, root + "/operation.json"), 1048576, label);
            if (text(activation, "publication_phase") != "COMMITTED" || text(operation, "phase") != "COMMITTED"
                || text(operation, "action") != "INSTALL"
                || text(activation, "operation_id") != text(operation, "operation_id")
                || text(activation, "activation_epoch") != selected.ActivationEpoch
                || text(operation, "activation_epoch") != selected.ActivationEpoch)
                throw new InvalidOperationException("Retained candidate fresh activation is not committed INSTALL authority.");
            foreach (var record in new[] { activation, operation })
                if (AICodedbStrictJson.GetRequiredInt32(record, "schema_version", label) != 1
                    || text(record, "managed_by") != "com.rice.ai-codedb"
                    || text(record, "project_identity") != text(intent, "project_identity")
                    || !string.Equals(text(record, "project_root"), context.ProjectRoot, StringComparison.OrdinalIgnoreCase)
                    || text(record, "runtime_contract_sha256") != text(instance, "runtime_contract_sha256"))
                    throw new InvalidOperationException("Retained candidate fresh activation context conflicts.");
            foreach (var evidence in new[] {
                AICodedbStrictJson.RequireObject(operation["candidate"], label),
                AICodedbStrictJson.RequireObject(activation["candidate"], label),
                AICodedbStrictJson.RequireObject(activation["current"], label) })
                if (text(evidence, "instance_id") != selected.InstanceId
                    || text(evidence, "generation_id") != selected.GenerationId
                    || text(evidence, "instance_manifest_sha256") != RetainedFileHash(instancePath)
                    || text(evidence, "generation_manifest_sha256") != text(instance, "generation_manifest_sha256"))
                    throw new InvalidOperationException("Retained candidate fresh activation selection conflicts.");
            var wrapperPath = RetainedProjectPath(context, "AIWork/codedb/wrapper/codedb-project-wrapper.mjs");
            var canonical = RetainedFileHash(RetainedProjectPath(context,
                "AIWork/.runtime/codedb/host/generations/" + selected.GenerationId + "/wrapper/codedb-project-wrapper.mjs"));
            if (RetainedFileHash(wrapperPath) != canonical)
                throw new InvalidOperationException("Retained candidate fresh wrapper handoff bytes conflict.");
            if (text(intent, "retained_wrapper_sha256") != canonical)
            {
                Dictionary<string, object> wrapperMutation = null;
                foreach (var raw in AICodedbStrictJson.GetRequiredArray(operation, "mutations", label))
                {
                    var mutation = AICodedbStrictJson.RequireObject(raw, label);
                    if (text(mutation, "target") != "AIWork/codedb/wrapper/codedb-project-wrapper.mjs") continue;
                    if (wrapperMutation != null) throw new InvalidOperationException("Duplicate retained wrapper handoff.");
                    wrapperMutation = mutation;
                }
                if (wrapperMutation == null || text(wrapperMutation, "mutation") != "write"
                    || text(wrapperMutation, "desired_sha256") != canonical
                    || text(wrapperMutation, "pre_image_sha256") != text(intent, "retained_wrapper_sha256")
                    || AICodedbStrictJson.GetRequiredBoolean(wrapperMutation, "existed_before", label)
                        != !string.IsNullOrEmpty(text(intent, "retained_wrapper_sha256")))
                    throw new InvalidOperationException("Retained candidate committed wrapper mutation is unbound.");
            }
        }

        private static AICodedbManagerActionIndexRead ReadLegacyPending(
            AICodedbEditorExecutionContext context, string directory,
            Dictionary<string, ResolvedMarker> resolved)
        {
            AICodedbManagerActionIndex pending = null;
            var matchedHistorical = new HashSet<string>(StringComparer.Ordinal);
            var retainedUnknown = new List<string>();
            AICodedbManagerActionIndex failedInstallIndex = null;
            AICodedbCommandResult failedInstallResult = null;
            var failedInstallCount = 0;
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
                    if (Directory.Exists(AICodedbPaths.GetManagerActionReceiptRoot(context, actionId)))
                        throw new InvalidOperationException("Conflicting compact and legacy action locations exist.");
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
                    AICodedbManagerActionIndex authenticatedOriginal = null;
                    if (resolved.TryGetValue(actionId, out var originalMarker)
                        && string.Equals(Path.GetFileName(packageDirectory),
                            originalMarker.PackageKey.Substring(0, 24), StringComparison.Ordinal))
                        authenticatedOriginal = new AICodedbManagerActionIndex(actionId,
                            "Previous CodeDB action", "ExistingBackendEffect",
                            "ExistingActionSpecificBackend", originalMarker.Context, null);
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
                        var outcome = AICodedbProcessRunner.RecoverManagerAction(original, actionId, null);
                        if (outcome.State != AICodedbManagerActionRecoveryState.Conflict)
                            authenticatedOriginal = new AICodedbManagerActionIndex(actionId,
                                "Previous CodeDB action", "ExistingBackendEffect",
                                "ExistingActionSpecificBackend", original, null);
                        if (resolved.TryGetValue(actionId, out var marker))
                        {
                            if (marker.RetainedEffects)
                            {
                                failedInstallCount++;
                                failedInstallIndex = new AICodedbManagerActionIndex(actionId, "Install CodeDB",
                                    "ConfirmedProjectMutation", AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB"),
                                    marker.Context, marker.StorageLayout);
                                failedInstallResult = marker.OriginalResult;
                                retainedUnknown.Add("Original INSTALL " + actionId + " remains failed/unknown; candidate effects are retained.");
                                continue;
                            }
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
                            {
                                matchedHistorical.Add(actionId);
                                retainedUnknown.Add("Historical action " + actionId
                                    + " (original Package " + original.PackageRoot
                                    + ") still has an unknown command outcome. Its historical reconciliation"
                                    + " is not a command terminal or authority for a new project change.");
                            }
                        }
                        if (outcome.State == AICodedbManagerActionRecoveryState.Terminal
                            && AICodedbActions.HasFailedInstallPendingEffects(outcome.Result))
                        {
                            failedInstallCount++;
                            failedInstallIndex = new AICodedbManagerActionIndex(actionId,
                                "Install CodeDB", "ConfirmedProjectMutation",
                                AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB"), original, null);
                            failedInstallResult = outcome.Result;
                            retainedUnknown.Add("Historical action " + actionId + " (original Package "
                                + original.PackageRoot + ") has a recorded failed INSTALL with PENDING cleanup."
                                + " Later completed stages do not clear its recorded effects."
                                + " Removal requires separate confirmation and the existing live safety check.");
                        }
                        if (resolved.ContainsKey(actionId))
                            continue;
                        if (outcome.State == AICodedbManagerActionRecoveryState.Terminal
                            || outcome.State == AICodedbManagerActionRecoveryState.PreEffectRefusal)
                            continue;
                        if (outcome.State != AICodedbManagerActionRecoveryState.Pending || pending != null)
                            throw new InvalidOperationException(
                                "Historical action evidence is conflicting or has multiple pending owners.");
                        pending = new AICodedbManagerActionIndex(actionId,
                            "Previous CodeDB action", "ExistingBackendEffect",
                            "ExistingActionSpecificBackend", original, null);
                    }
                    catch (Exception exception)
                    {
                        return new AICodedbManagerActionIndexRead(
                            AICodedbManagerActionIndexState.Conflict, authenticatedOriginal,
                            "Historical Manager action receipt validation failed: " + exception.Message,
                            actionId);
                    }
                }
            }
            foreach (var closure in resolved)
            {
                if (closure.Value.StorageLayout == AICodedbPaths.CompactReceiptLayout)
                {
                    var marker = closure.Value;
                    if (marker.RetainedEffects)
                    {
                        failedInstallCount++;
                        failedInstallIndex = new AICodedbManagerActionIndex(closure.Key, "Install CodeDB",
                            "ConfirmedProjectMutation", AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB"),
                            marker.Context, marker.StorageLayout);
                        failedInstallResult = marker.OriginalResult;
                        retainedUnknown.Add("Original INSTALL " + closure.Key + " remains failed/unknown; its candidate effects are retained.");
                        continue;
                    }
                    var outcome = AICodedbProcessRunner.RecoverManagerAction(marker.Context, closure.Key, marker.StorageLayout);
                    if (outcome.State == AICodedbManagerActionRecoveryState.Conflict
                        || (marker.Disposition == AICodedbManagerActionEvidenceKind.CommandTerminal
                            && outcome.State != AICodedbManagerActionRecoveryState.Terminal
                            && outcome.State != AICodedbManagerActionRecoveryState.NotFound)
                        || (marker.Disposition == AICodedbManagerActionEvidenceKind.PreEffectRefusal
                            && outcome.State == AICodedbManagerActionRecoveryState.Terminal))
                        return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                            new AICodedbManagerActionIndex(closure.Key, "Previous CodeDB action",
                                "ExistingBackendEffect", "ExistingActionSpecificBackend", marker.Context, marker.StorageLayout),
                            "Resolved compact action conflicts with its original receipt: " + outcome.Detail, closure.Key);
                    if (outcome.State == AICodedbManagerActionRecoveryState.Terminal
                        && AICodedbActions.HasFailedInstallPendingEffects(outcome.Result))
                    {
                        failedInstallCount++;
                        failedInstallIndex = new AICodedbManagerActionIndex(closure.Key, "Install CodeDB",
                            "ConfirmedProjectMutation", AICodedbManagerActionSession.ClassifyAuthority("Install CodeDB"),
                            marker.Context, marker.StorageLayout);
                        failedInstallResult = outcome.Result;
                        retainedUnknown.Add("Historical action " + closure.Key + " (original Package "
                            + marker.Context.PackageRoot + ") has a recorded failed INSTALL with PENDING cleanup."
                            + " Later completed stages do not clear its recorded effects."
                            + " Removal requires separate confirmation and the existing live safety check.");
                    }
                }
                if (closure.Value.HistoricalUnknown && !matchedHistorical.Contains(closure.Key))
                    return new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Conflict,
                        null, "A historical unknown-action marker has no matching original receipt.",
                        closure.Key);
            }
            var historicalWarning = string.Join("\n", retainedUnknown);
            return pending == null
                ? new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Empty,
                    failedInstallCount == 1 ? failedInstallIndex : null,
                    historicalWarning: historicalWarning,
                    historicalResult: failedInstallCount == 1 ? failedInstallResult : null)
                : new AICodedbManagerActionIndexRead(AICodedbManagerActionIndexState.Pending,
                    pending, isLegacyReceipt: true, historicalWarning: historicalWarning);
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
                if (index.StorageLayout != AICodedbPaths.CompactReceiptLayout)
                    throw new InvalidOperationException("New admission requires compact-v1 storage.");
                AICodedbPaths.ValidateManagerReceiptPaths(index.Context, index.ActionId, new string('0', 64));
                if (Directory.Exists(AICodedbPaths.GetManagerActionReceiptRoot(index.Context, index.ActionId))
                    || Directory.Exists(AICodedbPaths.GetManagerActionReceiptRoot(index.Context, index.ActionId, null)))
                    throw new InvalidOperationException("Action locator already has evidence; reuse was blocked.");
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
                    if (existing.Index != null && existing.HistoricalResult != null
                        && existing.HistoricalResult.FailedCandidateEffectsRetained)
                    {
                        var completedPath = AICodedbPaths.GetManagerActionIndexPath(existing.Index.Context, existing.Index.ActionId);
                        AssertPath(completedPath);
                        if (File.Exists(completedPath)) File.Delete(completedPath);
                    }
                    if (File.Exists(Path.Combine(directory,
                            "resolved-action-" + index.ActionId + ".json")))
                    {
                        detail = "The Manager action id was already closed and cannot be reused.";
                        return false;
                    }
                var json = "{\n  \"schema_version\": 1,\n  \"managed_by\": \"com.rice.ai-codedb\","
                    + "\n  \"storage_layout\": \"compact-v1\","
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
                AICodedbProcessRunner.PublishActionManifest(index);
                return true;
                }
            }
            catch (Exception exception)
            {
                detail = "Manager action durable admission failed: " + exception.Message;
                return false;
            }
        }

        internal static bool TryReleaseRetainedEffects(AICodedbManagerActionIndex index, out string detail)
        {
            detail = string.Empty;
            try
            {
                var path = AICodedbPaths.GetManagerActionIndexPath(index.Context, index.ActionId);
                AssertPath(path);
                var lockPath = Path.Combine(Path.GetDirectoryName(path), "index.lock");
                AssertPath(lockPath);
                using (new FileStream(lockPath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None))
                {
                    var read = Read(index.Context);
                    if (read.State != AICodedbManagerActionIndexState.Empty || read.Index == null
                        || read.Index.ActionId != index.ActionId || read.HistoricalResult == null
                        || !read.HistoricalResult.FailedCandidateEffectsRetained)
                        throw new InvalidOperationException("Retained candidate current-effects proof is incomplete.");
                    if (File.Exists(path)) File.Delete(path);
                }
                return true;
            }
            catch (Exception exception) { detail = exception.Message; return false; }
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
                            StringComparison.OrdinalIgnoreCase)
                        || read.Index.StorageLayout != index.StorageLayout)
                    {
                        detail = "The Manager action index no longer matches the completed action.";
                        return false;
                    }
                    var resolvedPath = Path.Combine(Path.GetDirectoryName(path),
                        "resolved-action-" + index.ActionId + ".json");
                    AssertPath(resolvedPath);
                    var resolvedJson = "{\n  \"schema_version\": 1,"
                        + (index.StorageLayout == null ? string.Empty : "\n  \"storage_layout\": \"compact-v1\",")
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
