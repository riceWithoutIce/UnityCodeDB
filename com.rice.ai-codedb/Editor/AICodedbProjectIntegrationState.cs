using System;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbProjectIntegrationState
    {
        Installed,
        Uninstalled,
        Invalid
    }

    internal enum AICodedbProjectCleanupState
    {
        None,
        Pending,
        Complete,
        Invalid
    }

    internal readonly struct AICodedbProjectIntegrationStatus
    {
        internal AICodedbProjectIntegrationState State { get; }
        internal AICodedbProjectCleanupState CleanupState { get; }
        internal string StateId { get; }
        internal string Detail { get; }
        internal bool IsUninstalled => State == AICodedbProjectIntegrationState.Uninstalled;
        internal bool IsValid => State != AICodedbProjectIntegrationState.Invalid;

        internal AICodedbProjectIntegrationStatus(
            AICodedbProjectIntegrationState state,
            AICodedbProjectCleanupState cleanupState,
            string stateId,
            string detail)
        {
            State = state;
            CleanupState = cleanupState;
            StateId = stateId ?? string.Empty;
            Detail = detail ?? string.Empty;
        }
    }

    internal static class AICodedbProjectIntegrationStateStore
    {
        private const int SchemaVersion = 1;
        private const string ManagedBy = "com.rice.ai-codedb";
        private const long MaximumBytes = 64 * 1024;

        internal static AICodedbProjectIntegrationStatus Read(string projectRoot)
        {
            var currentStatePath = Path.Combine(
                projectRoot,
                AICodedbProjectSettings.InstanceDesiredStateRelativePath);
            var legacyStatePath = Path.Combine(
                projectRoot,
                AICodedbProjectSettings.ProjectIntegrationStateRelativePath);
            var statePath = File.Exists(currentStatePath) || Directory.Exists(currentStatePath)
                ? currentStatePath
                : legacyStatePath;
            return Read(projectRoot, statePath);
        }

        internal static AICodedbProjectIntegrationStatus Read(string projectRoot, string statePath)
        {
            try
            {
                var expectedRoot = AICodedbEditorLifecycle.ValidateProjectRoot(projectRoot);
                var expectedLegacyPath = AICodedbPaths.NormalizePath(Path.Combine(
                    expectedRoot,
                    AICodedbProjectSettings.ProjectIntegrationStateRelativePath));
                var expectedCurrentPath = AICodedbPaths.NormalizePath(Path.Combine(
                    expectedRoot,
                    AICodedbProjectSettings.InstanceDesiredStateRelativePath));
                var actualPath = AICodedbPaths.NormalizePath(statePath);
                if (!string.Equals(actualPath, expectedLegacyPath, StringComparison.OrdinalIgnoreCase)
                    && !string.Equals(actualPath, expectedCurrentPath, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Project integration desired state path is outside its reviewed location.");

                AssertNoReparsePoint(expectedRoot, actualPath);
                if (!File.Exists(actualPath))
                {
                    if (Directory.Exists(actualPath))
                        throw new InvalidOperationException("Project integration desired state is not a regular file.");
                    return new AICodedbProjectIntegrationStatus(
                        AICodedbProjectIntegrationState.Installed,
                        AICodedbProjectCleanupState.None,
                        string.Empty,
                        "No UNINSTALLED project desired state is present.");
                }

                var document = AICodedbStrictJson.ReadObject(
                    actualPath,
                    MaximumBytes,
                    "CodeDB project integration desired state");
                var recordedRoot = AICodedbPaths.NormalizePath(AICodedbStrictJson.GetRequiredString(
                    document,
                    "project_root",
                    "CodeDB project integration desired state")).TrimEnd('/');
                var updatedAtText = AICodedbStrictJson.GetRequiredString(
                    document,
                    "updated_at_utc",
                    "CodeDB project integration desired state");
                var stateId = AICodedbStrictJson.GetRequiredString(
                    document,
                    "state_id",
                    "CodeDB project integration desired state");
                var cleanupStateText = AICodedbStrictJson.GetRequiredString(
                    document,
                    "cleanup_state",
                    "CodeDB project integration desired state");
                var cleanupState = string.Equals(cleanupStateText, "PENDING", StringComparison.Ordinal)
                    ? AICodedbProjectCleanupState.Pending
                    : string.Equals(cleanupStateText, "COMPLETE", StringComparison.Ordinal)
                        ? AICodedbProjectCleanupState.Complete
                        : AICodedbProjectCleanupState.Invalid;
                var desiredState = AICodedbStrictJson.GetRequiredString(
                    document,
                    "desired_state",
                    "CodeDB project integration desired state");
                DateTimeOffset updatedAt;
                if (AICodedbStrictJson.GetRequiredInt32(
                        document,
                        "schema_version",
                        "CodeDB project integration desired state") != SchemaVersion
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(
                            document,
                            "managed_by",
                            "CodeDB project integration desired state"), ManagedBy, StringComparison.Ordinal)
                    || (!string.Equals(desiredState, "INSTALLED", StringComparison.Ordinal)
                        && !string.Equals(desiredState, "UNINSTALLED", StringComparison.Ordinal))
                    || !string.Equals(recordedRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(
                            document,
                            "project_identity",
                            "CodeDB project integration desired state"),
                        AICodedbEditorLifecycle.CreateProjectIdentity(expectedRoot),
                        StringComparison.Ordinal)
                    || stateId.Length != 32
                    || !Guid.TryParseExact(stateId, "N", out _)
                    || !string.Equals(stateId, stateId.ToLowerInvariant(), StringComparison.Ordinal)
                    || cleanupState == AICodedbProjectCleanupState.Invalid
                    || !DateTimeOffset.TryParse(
                        updatedAtText,
                        CultureInfo.InvariantCulture,
                        DateTimeStyles.RoundtripKind,
                        out updatedAt))
                {
                    throw new InvalidOperationException("Project integration desired state identity or schema is invalid.");
                }

                var uninstalled = string.Equals(desiredState, "UNINSTALLED", StringComparison.Ordinal);
                return new AICodedbProjectIntegrationStatus(
                    uninstalled
                        ? AICodedbProjectIntegrationState.Uninstalled
                        : AICodedbProjectIntegrationState.Installed,
                    cleanupState,
                    stateId,
                    uninstalled
                        ? cleanupState == AICodedbProjectCleanupState.Pending
                            ? "Project integration is explicitly UNINSTALLED; owned cleanup remains pending."
                            : "Project integration is explicitly UNINSTALLED; owned cleanup is complete."
                        : cleanupState == AICodedbProjectCleanupState.Pending
                            ? "Project integration is installed; retired instance cleanup remains pending."
                            : "Project integration is installed and retired instance cleanup is complete.");
            }
            catch (Exception exception)
            {
                return new AICodedbProjectIntegrationStatus(
                    AICodedbProjectIntegrationState.Invalid,
                    AICodedbProjectCleanupState.Invalid,
                    string.Empty,
                    exception.Message);
            }
        }

        internal static void AssertNoReparsePoint(string projectRoot, string path)
        {
            var root = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var candidate = AICodedbPaths.NormalizePath(path);
            var rootPrefix = root + "/";
            if (!candidate.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Project integration desired state escapes the Unity project root.");

            var current = candidate;
            while (!string.Equals(current, root, StringComparison.OrdinalIgnoreCase))
            {
                if (File.Exists(current) || Directory.Exists(current))
                {
                    var attributes = File.GetAttributes(current);
                    if ((attributes & FileAttributes.ReparsePoint) != 0)
                        throw new InvalidOperationException("Project integration desired state traverses a reparse point.");
                }
                current = AICodedbPaths.NormalizePath(Path.GetDirectoryName(current));
                if (string.IsNullOrWhiteSpace(current)
                    || (!string.Equals(current, root, StringComparison.OrdinalIgnoreCase)
                        && !current.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase)))
                {
                    throw new InvalidOperationException("Project integration desired state escapes the Unity project root.");
                }
            }
        }
    }

    internal readonly struct AICodedbCurrentInstanceStatus
    {
        internal bool Present { get; }
        internal bool IsCurrent { get; }
        internal string InstanceId { get; }
        internal string InstanceRelativePath { get; }
        internal string InstanceRoot { get; }
        internal string GenerationRoot { get; }
        internal string EditorLeaseRelativePath => IsCurrent
            ? InstanceRelativePath + "/watch/lifecycle/editor-leases"
            : string.Empty;
        internal string Detail { get; }

        internal AICodedbCurrentInstanceStatus(
            bool present,
            bool isCurrent,
            string instanceId,
            string instanceRelativePath,
            string instanceRoot,
            string generationRoot,
            string detail)
        {
            Present = present;
            IsCurrent = isCurrent;
            InstanceId = instanceId ?? string.Empty;
            InstanceRelativePath = instanceRelativePath ?? string.Empty;
            InstanceRoot = instanceRoot ?? string.Empty;
            GenerationRoot = generationRoot ?? string.Empty;
            Detail = detail ?? string.Empty;
        }
    }

    internal static class AICodedbCurrentInstanceStore
    {
        private const string ManagedBy = "com.rice.ai-codedb";
        private const long PointerMaximumBytes = 64 * 1024;
        private const long ManifestMaximumBytes = 128 * 1024;
        private const long GenerationManifestMaximumBytes = 1024 * 1024;
        private const long WorkerMaximumBytes = 4 * 1024 * 1024;

        internal static AICodedbCurrentInstanceStatus Read(string projectRoot)
        {
            try
            {
                var root = AICodedbEditorLifecycle.ValidateProjectRoot(projectRoot);
                var pointerPath = AICodedbPaths.NormalizePath(Path.Combine(
                    root,
                    AICodedbProjectSettings.InstanceCurrentRelativePath));
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(root, pointerPath);
                if (!File.Exists(pointerPath))
                {
                    if (Directory.Exists(pointerPath))
                        throw new InvalidOperationException("Current CodeDB instance selection is not a regular file.");
                    return new AICodedbCurrentInstanceStatus(
                        false,
                        false,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        "No current CodeDB instance is selected.");
                }

                const string pointerLabel = "Current CodeDB instance selection";
                var pointer = AICodedbStrictJson.ReadObject(pointerPath, PointerMaximumBytes, pointerLabel);
                var instanceId = AICodedbStrictJson.GetRequiredString(pointer, "instance_id", pointerLabel);
                var instanceRelativePath = NormalizeRelativePath(
                    AICodedbStrictJson.GetRequiredString(pointer, "instance_relative_path", pointerLabel));
                var expectedInstanceRelativePath = AICodedbProjectSettings.InstancesRelativePath + "/" + instanceId;
                var manifestHash = AICodedbStrictJson.GetRequiredString(
                    pointer,
                    "instance_manifest_sha256",
                    pointerLabel);
                var activatedAtText = AICodedbStrictJson.GetRequiredString(pointer, "activated_at_utc", pointerLabel);
                DateTimeOffset activatedAt;
                Guid parsedInstanceId;
                if (AICodedbStrictJson.GetRequiredInt32(pointer, "schema_version", pointerLabel) != 1
                    || !string.Equals(
                        AICodedbStrictJson.GetRequiredString(pointer, "managed_by", pointerLabel),
                        ManagedBy,
                        StringComparison.Ordinal)
                    || !string.Equals(
                        AICodedbStrictJson.GetRequiredString(pointer, "project_identity", pointerLabel),
                        AICodedbEditorLifecycle.CreateProjectIdentity(root),
                        StringComparison.Ordinal)
                    || !Guid.TryParseExact(instanceId, "N", out parsedInstanceId)
                    || !string.Equals(instanceId, instanceId.ToLowerInvariant(), StringComparison.Ordinal)
                    || !string.Equals(instanceRelativePath, expectedInstanceRelativePath, StringComparison.Ordinal)
                    || !IsSha256(manifestHash)
                    || !string.Equals(
                        AICodedbStrictJson.GetRequiredString(pointer, "generation_id", pointerLabel),
                        AICodedbProjectSettings.CurrentGenerationId,
                        StringComparison.Ordinal)
                    || !DateTimeOffset.TryParse(
                        activatedAtText,
                        CultureInfo.InvariantCulture,
                        DateTimeStyles.RoundtripKind,
                        out activatedAt))
                {
                    throw new InvalidOperationException("Current CodeDB instance selection identity or schema is invalid.");
                }

                var instanceRoot = AICodedbPaths.NormalizePath(Path.Combine(root, instanceRelativePath));
                var instancesRoot = AICodedbPaths.NormalizePath(Path.Combine(
                    root,
                    AICodedbProjectSettings.InstancesRelativePath)).TrimEnd('/');
                if (!instanceRoot.StartsWith(instancesRoot + "/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Current CodeDB instance root escapes the reviewed instances directory.");
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(root, instanceRoot);
                if (!Directory.Exists(instanceRoot))
                    throw new InvalidOperationException("Current CodeDB instance root is missing.");

                var manifestPath = AICodedbPaths.NormalizePath(Path.Combine(instanceRoot, "instance.json"));
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(root, manifestPath);
                if (!string.Equals(HashFile(manifestPath, ManifestMaximumBytes), manifestHash, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Current CodeDB instance manifest hash is invalid.");

                const string manifestLabel = "Current CodeDB instance manifest";
                var manifest = AICodedbStrictJson.ReadObject(manifestPath, ManifestMaximumBytes, manifestLabel);
                var generationRelativePath = NormalizeRelativePath(
                    AICodedbStrictJson.GetRequiredString(manifest, "generation_relative_path", manifestLabel));
                var generationManifestHash = AICodedbStrictJson.GetRequiredString(
                    manifest,
                    "generation_manifest_sha256",
                    manifestLabel);
                var workerRelativePath = NormalizeRelativePath(
                    AICodedbStrictJson.GetRequiredString(manifest, "worker_relative_path", manifestLabel));
                var workerHash = AICodedbStrictJson.GetRequiredString(manifest, "worker_sha256", manifestLabel);
                var expectedGenerationRelativePath =
                    AICodedbProjectSettings.HostGenerationsRelativePath + "/" + AICodedbProjectSettings.CurrentGenerationId;
                if (AICodedbStrictJson.GetRequiredInt32(manifest, "schema_version", manifestLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "managed_by", manifestLabel), ManagedBy, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "project_identity", manifestLabel), AICodedbEditorLifecycle.CreateProjectIdentity(root), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "instance_id", manifestLabel), instanceId, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "instance_relative_path", manifestLabel), instanceRelativePath, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "state", manifestLabel), "READY", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "package_version", manifestLabel), AICodedbProjectSettings.CurrentPackageVersion, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "payload_version", manifestLabel), AICodedbProjectSettings.CurrentPayloadVersion, StringComparison.Ordinal)
                    || AICodedbStrictJson.GetRequiredInt32(manifest, "payload_sequence", manifestLabel) != AICodedbProjectSettings.CurrentPayloadSequence
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "generation_id", manifestLabel), AICodedbProjectSettings.CurrentGenerationId, StringComparison.Ordinal)
                    || !string.Equals(generationRelativePath, expectedGenerationRelativePath, StringComparison.Ordinal)
                    || !IsSha256(generationManifestHash)
                    || AICodedbStrictJson.GetRequiredInt32(manifest, "bootstrap_protocol", manifestLabel) != AICodedbProjectSettings.CurrentBootstrapProtocol
                    || !string.Equals(workerRelativePath, "wrapper/codedb-project-instance-worker.mjs", StringComparison.Ordinal)
                    || !IsSha256(workerHash))
                {
                    throw new InvalidOperationException("Current CodeDB instance manifest identity or schema is invalid.");
                }

                var generationRoot = AICodedbPaths.NormalizePath(Path.Combine(root, generationRelativePath));
                var generationManifestPath = AICodedbPaths.NormalizePath(Path.Combine(generationRoot, "generation-manifest.json"));
                var workerPath = AICodedbPaths.NormalizePath(Path.Combine(generationRoot, workerRelativePath));
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(root, generationManifestPath);
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(root, workerPath);
                if (!string.Equals(HashFile(generationManifestPath, GenerationManifestMaximumBytes), generationManifestHash, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(HashFile(workerPath, WorkerMaximumBytes), workerHash, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Current CodeDB instance generation closure does not match its manifest.");
                }

                return new AICodedbCurrentInstanceStatus(
                    true,
                    true,
                    instanceId,
                    instanceRelativePath,
                    instanceRoot,
                    generationRoot,
                    "The selected CodeDB instance identity and generation closure are current.");
            }
            catch (Exception exception)
            {
                return new AICodedbCurrentInstanceStatus(
                    true,
                    false,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    exception.Message);
            }
        }

        private static string NormalizeRelativePath(string value)
        {
            var normalized = (value ?? string.Empty).Replace('\\', '/').Trim('/');
            if (string.IsNullOrWhiteSpace(normalized)
                || Path.IsPathRooted(normalized)
                || normalized.IndexOf(':') >= 0
                || normalized.Split('/').Any(segment => segment.Length == 0 || segment == "." || segment == ".."))
            {
                throw new InvalidOperationException("Current CodeDB instance contains an unsafe relative path.");
            }
            return normalized;
        }

        private static bool IsSha256(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length != 64)
                return false;
            for (var index = 0; index < value.Length; index++)
            {
                var character = value[index];
                if (!((character >= '0' && character <= '9') || (character >= 'a' && character <= 'f')))
                    return false;
            }
            return true;
        }

        private static string HashFile(string path, long maximumBytes)
        {
            if (!File.Exists(path))
                throw new InvalidOperationException("Current CodeDB instance closure file is missing: " + path);
            var file = new FileInfo(path);
            if (file.Length <= 0 || file.Length > maximumBytes)
                throw new InvalidOperationException("Current CodeDB instance closure file has an invalid size: " + path);
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var sha256 = SHA256.Create())
            {
                var hash = sha256.ComputeHash(stream);
                var builder = new System.Text.StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return builder.ToString();
            }
        }
    }
}
