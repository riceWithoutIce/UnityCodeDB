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

    internal enum AICodedbCurrentInstanceState
    {
        Missing,
        Current,
        TrustedPrevious,
        Invalid
    }

    internal readonly struct AICodedbCurrentInstanceStatus
    {
        internal AICodedbCurrentInstanceState State { get; }
        internal bool Present => State != AICodedbCurrentInstanceState.Missing;
        internal bool IsCurrent => State == AICodedbCurrentInstanceState.Current;
        internal bool IsTrustedPrevious => State == AICodedbCurrentInstanceState.TrustedPrevious;
        internal bool CanPublishEditorLease => IsCurrent || IsTrustedPrevious;
        internal string InstanceId { get; }
        internal string InstanceRelativePath { get; }
        internal string InstanceRoot { get; }
        internal string GenerationRoot { get; }
        internal string GenerationId { get; }
        internal string PackageVersion { get; }
        internal string PayloadVersion { get; }
        internal int PayloadSequence { get; }
        internal int BootstrapProtocol { get; }
        internal string EditorLeaseRelativePath => CanPublishEditorLease
            ? InstanceRelativePath + "/watch/lifecycle/editor-leases"
            : string.Empty;
        internal string Detail { get; }

        internal AICodedbCurrentInstanceStatus(
            AICodedbCurrentInstanceState state,
            string instanceId,
            string instanceRelativePath,
            string instanceRoot,
            string generationRoot,
            string generationId,
            string packageVersion,
            string payloadVersion,
            int payloadSequence,
            int bootstrapProtocol,
            string detail)
        {
            State = state;
            InstanceId = instanceId ?? string.Empty;
            InstanceRelativePath = instanceRelativePath ?? string.Empty;
            InstanceRoot = instanceRoot ?? string.Empty;
            GenerationRoot = generationRoot ?? string.Empty;
            GenerationId = generationId ?? string.Empty;
            PackageVersion = packageVersion ?? string.Empty;
            PayloadVersion = payloadVersion ?? string.Empty;
            PayloadSequence = payloadSequence;
            BootstrapProtocol = bootstrapProtocol;
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
            return Read(projectRoot, AICodedbPaths.PackageRootPath);
        }

        internal static AICodedbCurrentInstanceStatus Read(string projectRoot, string packageRoot)
        {
            var hasValidatedSelection = false;
            var validatedSelection = default(AICodedbCurrentInstanceStatus);
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
                        AICodedbCurrentInstanceState.Missing,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        0,
                        0,
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
                var pointerGenerationId = AICodedbStrictJson.GetRequiredString(
                    pointer,
                    "generation_id",
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
                    || !IsGenerationId(pointerGenerationId)
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
                var packageVersion = AICodedbStrictJson.GetRequiredString(manifest, "package_version", manifestLabel);
                var payloadVersion = AICodedbStrictJson.GetRequiredString(manifest, "payload_version", manifestLabel);
                var payloadSequence = AICodedbStrictJson.GetRequiredInt32(manifest, "payload_sequence", manifestLabel);
                var manifestGenerationId = AICodedbStrictJson.GetRequiredString(manifest, "generation_id", manifestLabel);
                var bootstrapProtocol = AICodedbStrictJson.GetRequiredInt32(manifest, "bootstrap_protocol", manifestLabel);
                var expectedGenerationRelativePath =
                    AICodedbProjectSettings.HostGenerationsRelativePath + "/" + manifestGenerationId;
                if (AICodedbStrictJson.GetRequiredInt32(manifest, "schema_version", manifestLabel) != 1
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "managed_by", manifestLabel), ManagedBy, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "project_identity", manifestLabel), AICodedbEditorLifecycle.CreateProjectIdentity(root), StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "instance_id", manifestLabel), instanceId, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "instance_relative_path", manifestLabel), instanceRelativePath, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(manifest, "state", manifestLabel), "READY", StringComparison.Ordinal)
                    || !string.Equals(pointerGenerationId, manifestGenerationId, StringComparison.Ordinal)
                    || !IsGenerationId(manifestGenerationId)
                    || string.IsNullOrWhiteSpace(packageVersion)
                    || string.IsNullOrWhiteSpace(payloadVersion)
                    || payloadSequence < 1
                    || !string.Equals(generationRelativePath, expectedGenerationRelativePath, StringComparison.Ordinal)
                    || !IsSha256(generationManifestHash)
                    || bootstrapProtocol < 1
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

                var runtimeContract = AICodedbPackageRuntimeContractStore.Read(packageRoot);
                var selectedIdentity = new AICodedbRuntimeIdentity(
                    packageVersion,
                    payloadVersion,
                    payloadSequence,
                    manifestGenerationId,
                    bootstrapProtocol);
                var disposition = runtimeContract.Classify(selectedIdentity);

                // Preserve the identity after the project-owned instance and
                // its immutable generation closure have passed structural
                // validation. Later authentication failures must remain
                // unusable, but retaining this evidence keeps INVALID status
                // diagnostics tied to the selection that was actually read.
                validatedSelection = new AICodedbCurrentInstanceStatus(
                    AICodedbCurrentInstanceState.Invalid,
                    instanceId,
                    instanceRelativePath,
                    instanceRoot,
                    generationRoot,
                    manifestGenerationId,
                    packageVersion,
                    payloadVersion,
                    payloadSequence,
                    bootstrapProtocol,
                    string.Empty);
                hasValidatedSelection = true;

                // Authenticate the stable router before the more involved
                // previous-generation transition checks so wrapper drift is
                // reported directly and cannot be obscured by a later
                // validation summary.
                if (disposition == AICodedbRuntimeGenerationDisposition.Current
                    || disposition == AICodedbRuntimeGenerationDisposition.TrustedPrevious)
                {
                    AICodedbPackageRuntimeContractStore.ValidateProjectStableWrapper(
                        root,
                        runtimeContract.GetExpectedStableWrapperSha256(selectedIdentity));
                }

                AICodedbCurrentInstanceState state;
                if (disposition == AICodedbRuntimeGenerationDisposition.Current)
                {
                    state = AICodedbCurrentInstanceState.Current;
                }
                else if (disposition == AICodedbRuntimeGenerationDisposition.TrustedPrevious)
                {
                    state = ValidateTrustedPreviousIdentity(
                        root,
                        packageRoot,
                        runtimeContract,
                        selectedIdentity,
                        packageVersion,
                        payloadVersion,
                        payloadSequence,
                        manifestGenerationId,
                        generationManifestHash,
                        workerRelativePath,
                        workerHash,
                        bootstrapProtocol,
                        generationRoot);
                }
                else
                {
                    throw new InvalidOperationException(
                        "Selected CodeDB instance generation disposition is " + disposition + ".");
                }

                return new AICodedbCurrentInstanceStatus(
                    state,
                    instanceId,
                    instanceRelativePath,
                    instanceRoot,
                    generationRoot,
                    manifestGenerationId,
                    packageVersion,
                    payloadVersion,
                    payloadSequence,
                    bootstrapProtocol,
                    state == AICodedbCurrentInstanceState.Current
                        ? "The selected CodeDB instance identity and generation closure are current."
                        : "The selected CodeDB instance is an exact Package-declared previous generation and is ready for automatic handoff.");
            }
            catch (Exception exception)
            {
                if (hasValidatedSelection)
                {
                    return new AICodedbCurrentInstanceStatus(
                        AICodedbCurrentInstanceState.Invalid,
                        validatedSelection.InstanceId,
                        validatedSelection.InstanceRelativePath,
                        validatedSelection.InstanceRoot,
                        validatedSelection.GenerationRoot,
                        validatedSelection.GenerationId,
                        validatedSelection.PackageVersion,
                        validatedSelection.PayloadVersion,
                        validatedSelection.PayloadSequence,
                        validatedSelection.BootstrapProtocol,
                        exception.Message);
                }

                return new AICodedbCurrentInstanceStatus(
                    AICodedbCurrentInstanceState.Invalid,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    0,
                    0,
                    exception.Message);
            }
        }

        private static AICodedbCurrentInstanceState ValidateTrustedPreviousIdentity(
            string projectRoot,
            string packageRoot,
            AICodedbPackageRuntimeContract runtimeContract,
            AICodedbRuntimeIdentity selectedIdentity,
            string packageVersion,
            string payloadVersion,
            int payloadSequence,
            string generationId,
            string generationManifestHash,
            string workerRelativePath,
            string workerHash,
            int bootstrapProtocol,
            string generationRoot)
        {
            if (runtimeContract.Classify(selectedIdentity)
                != AICodedbRuntimeGenerationDisposition.TrustedPrevious)
            {
                throw new InvalidOperationException(
                    "Selected CodeDB instance is not an exact Package-declared transition.");
            }

            var normalizedPackageRoot = AICodedbPaths.NormalizePath(packageRoot).TrimEnd('/');
            if (!Directory.Exists(normalizedPackageRoot)
                || (File.GetAttributes(normalizedPackageRoot) & FileAttributes.ReparsePoint) != 0)
            {
                throw new InvalidOperationException("Resolved Package root is unavailable or untrusted for previous-instance authentication.");
            }

            var packageGenerationRoot = CombineInside(
                normalizedPackageRoot,
                "Payload~/Generations/" + generationId,
                "Package previous generation");
            var packageGenerationManifestPath = CombineInside(
                packageGenerationRoot,
                "generation-manifest.json",
                "Package previous generation manifest");
            var packageWorkerPath = CombineInside(
                packageGenerationRoot,
                workerRelativePath,
                "Package previous generation worker");
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedPackageRoot, packageGenerationRoot);
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedPackageRoot, packageGenerationManifestPath);
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedPackageRoot, packageWorkerPath);
            if (!string.Equals(HashFile(packageGenerationManifestPath, GenerationManifestMaximumBytes), generationManifestHash, StringComparison.OrdinalIgnoreCase)
                || !string.Equals(HashFile(packageWorkerPath, WorkerMaximumBytes), workerHash, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Selected previous instance does not match the Package-preserved generation bytes.");
            }

            var packageGenerationManifest = AICodedbStrictJson.ReadObject(
                packageGenerationManifestPath,
                GenerationManifestMaximumBytes,
                "Package previous generation manifest");
            if (AICodedbStrictJson.GetRequiredInt32(packageGenerationManifest, "schema_version", "Package previous generation manifest") != 1
                || !string.Equals(AICodedbStrictJson.GetRequiredString(packageGenerationManifest, "managed_by", "Package previous generation manifest"), ManagedBy, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(packageGenerationManifest, "package_version", "Package previous generation manifest"), packageVersion, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(packageGenerationManifest, "payload_version", "Package previous generation manifest"), payloadVersion, StringComparison.Ordinal)
                || AICodedbStrictJson.GetRequiredInt32(packageGenerationManifest, "payload_sequence", "Package previous generation manifest") != payloadSequence
                || !string.Equals(AICodedbStrictJson.GetRequiredString(packageGenerationManifest, "generation_id", "Package previous generation manifest"), generationId, StringComparison.Ordinal)
                || AICodedbStrictJson.GetRequiredInt32(packageGenerationManifest, "bootstrap_protocol", "Package previous generation manifest") != bootstrapProtocol)
            {
                throw new InvalidOperationException("Package-preserved previous generation identity is invalid.");
            }

            var hostPointerPath = AICodedbPaths.NormalizePath(Path.Combine(
                projectRoot,
                AICodedbProjectSettings.HostCurrentPointerRelativePath));
            var generationSelection = AICodedbHostGenerationStore.ResolvePointer(
                projectRoot,
                hostPointerPath,
                normalizedPackageRoot);
            if (generationSelection.State != AICodedbHostGenerationState.Previous
                || !string.Equals(generationSelection.GenerationId, generationId, StringComparison.Ordinal)
                || !string.Equals(generationSelection.PackageVersion, packageVersion, StringComparison.Ordinal)
                || !string.Equals(generationSelection.PayloadVersion, payloadVersion, StringComparison.Ordinal)
                || generationSelection.PayloadSequence != payloadSequence
                || generationSelection.BootstrapProtocol != bootstrapProtocol
                || !string.Equals(
                    AICodedbPaths.NormalizePath(generationSelection.RootPath).TrimEnd('/'),
                    AICodedbPaths.NormalizePath(generationRoot).TrimEnd('/'),
                    StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Selected previous instance generation closure is not a validated upgrade source.");
            }

            return AICodedbCurrentInstanceState.TrustedPrevious;
        }

        private static string CombineInside(string root, string relativePath, string label)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/');
            var normalizedRelativePath = NormalizeRelativePath(relativePath);
            var combined = AICodedbPaths.NormalizePath(Path.Combine(normalizedRoot, normalizedRelativePath));
            if (!combined.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException(label + " escapes its reviewed root.");
            return combined;
        }

        private static bool IsGenerationId(string value)
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
