using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbHostGenerationState
    {
        Unavailable,
        Legacy,
        Previous,
        Current,
        DowngradeReviewRequired,
        Invalid
    }

    internal readonly struct AICodedbHostGenerationSelection
    {
        internal AICodedbHostGenerationState State { get; }
        internal string GenerationId { get; }
        internal string PackageVersion { get; }
        internal string PayloadVersion { get; }
        internal int PayloadSequence { get; }
        internal int BootstrapProtocol { get; }
        internal string RootPath { get; }
        internal string Detail { get; }
        internal bool IsUsable => State == AICodedbHostGenerationState.Current;

        internal AICodedbHostGenerationSelection(
            AICodedbHostGenerationState state,
            string generationId,
            string packageVersion,
            string payloadVersion,
            int payloadSequence,
            int bootstrapProtocol,
            string rootPath,
            string detail)
        {
            State = state;
            GenerationId = generationId ?? string.Empty;
            PackageVersion = packageVersion ?? string.Empty;
            PayloadVersion = payloadVersion ?? string.Empty;
            PayloadSequence = payloadSequence;
            BootstrapProtocol = bootstrapProtocol;
            RootPath = rootPath ?? string.Empty;
            Detail = detail ?? string.Empty;
        }
    }

    internal static class AICodedbHostGenerationStore
    {
        private const string ManagedBy = "com.rice.ai-codedb";
        private const long PointerMaximumBytes = 64 * 1024;
        private const long ManifestMaximumBytes = 1024 * 1024;

        internal static AICodedbHostGenerationSelection Resolve(string projectRoot)
        {
            return Resolve(projectRoot, AICodedbPaths.PackageRootPath);
        }

        internal static AICodedbHostGenerationSelection Resolve(string projectRoot, string packageRoot)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var normalizedPackageRoot = AICodedbPaths.NormalizePath(packageRoot).TrimEnd('/');
            var currentInstance = AICodedbCurrentInstanceStore.Read(normalizedRoot, normalizedPackageRoot);
            if (currentInstance.Present)
            {
                if (currentInstance.IsTrustedPrevious)
                {
                    return new AICodedbHostGenerationSelection(
                        AICodedbHostGenerationState.Previous,
                        currentInstance.GenerationId,
                        currentInstance.PackageVersion,
                        currentInstance.PayloadVersion,
                        currentInstance.PayloadSequence,
                        currentInstance.BootstrapProtocol,
                        currentInstance.GenerationRoot,
                        currentInstance.Detail);
                }
                if (!currentInstance.IsCurrent)
                {
                    return new AICodedbHostGenerationSelection(
                        AICodedbHostGenerationState.Invalid,
                        currentInstance.GenerationId,
                        currentInstance.PackageVersion,
                        currentInstance.PayloadVersion,
                        currentInstance.PayloadSequence,
                        currentInstance.BootstrapProtocol,
                        currentInstance.GenerationRoot,
                        currentInstance.Detail);
                }
                return ResolveSelectedInstanceGeneration(
                    normalizedRoot,
                    normalizedPackageRoot,
                    currentInstance.GenerationRoot,
                    currentInstance.GenerationId);
            }

            var currentPath = AICodedbPaths.NormalizePath(Path.Combine(
                normalizedRoot,
                AICodedbProjectSettings.HostCurrentPointerRelativePath));

            if (File.Exists(currentPath))
                return ResolveCurrent(normalizedRoot, normalizedPackageRoot, currentPath);

            return ResolveLegacy(normalizedRoot);
        }

        private static AICodedbHostGenerationSelection ResolveSelectedInstanceGeneration(
            string projectRoot,
            string packageRoot,
            string generationRoot,
            string generationId)
        {
            try
            {
                var runtimeContract = AICodedbPackageRuntimeContractStore.Read(packageRoot);
                var expectedGenerationRoot = CombineInside(
                    projectRoot,
                    AICodedbProjectSettings.HostGenerationsRelativePath + "/" + generationId,
                    "selected instance generation");
                if (!string.Equals(
                        AICodedbPaths.NormalizePath(generationRoot).TrimEnd('/'),
                        AICodedbPaths.NormalizePath(expectedGenerationRoot).TrimEnd('/'),
                        StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Selected instance generation targets an unexpected directory.");
                }

                var packagePointerPath = CombineInside(packageRoot, "Payload~/host-current.json", "Package Current pointer");
                var installedManifestPath = CombineInside(generationRoot, "generation-manifest.json", "selected instance generation manifest");
                AssertNoReparsePoints(projectRoot, generationRoot, "selected instance generation");
                AssertNoReparsePoints(projectRoot, installedManifestPath, "selected instance generation manifest");
                var packagePointer = ReadCurrentPointer(packagePointerPath, "Package Current pointer");
                ValidatePointer(packagePointer);
                if (ClassifyValidatedPointer(packagePointer, runtimeContract) != AICodedbHostGenerationState.Current)
                    throw new InvalidOperationException("Package Current pointer does not identify the loaded instance generation.");
                if (!string.Equals(
                        GetFileSha256(installedManifestPath),
                        packagePointer.generation_manifest_sha256,
                        StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Selected instance generation manifest does not match the Package pointer.");
                }
                var installedManifest = ReadGenerationManifest(installedManifestPath, "selected instance generation manifest");
                ValidateGenerationManifest(packagePointer, installedManifest, generationRoot);
                AICodedbPackageRuntimeContractStore.ValidateProjectStableWrapper(
                    projectRoot,
                    runtimeContract.GetExpectedStableWrapperSha256(new AICodedbRuntimeIdentity(
                        packagePointer.package_version,
                        packagePointer.payload_version,
                        packagePointer.payload_sequence,
                        packagePointer.generation_id,
                        packagePointer.bootstrap_protocol)));
                ValidatePackageOwnedCurrentGeneration(
                    packagePointer,
                    installedManifestPath,
                    generationRoot,
                    packageRoot,
                    runtimeContract);
                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Current,
                    packagePointer.generation_id,
                    packagePointer.package_version,
                    packagePointer.payload_version,
                    packagePointer.payload_sequence,
                    packagePointer.bootstrap_protocol,
                    generationRoot,
                    "Package-owned generation selected by control/current-instance.json.");
            }
            catch (Exception exception)
            {
                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Invalid,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    0,
                    0,
                    string.Empty,
                    exception.Message);
            }
        }

        internal static string ResolveHostPath(
            string projectRoot,
            string generationRelativePath,
            string legacyProjectRelativePath)
        {
            var selection = Resolve(projectRoot);
            if (selection.State == AICodedbHostGenerationState.Current
                || selection.State == AICodedbHostGenerationState.Previous
                || selection.State == AICodedbHostGenerationState.DowngradeReviewRequired)
                return CombineInside(selection.RootPath, generationRelativePath, "generation path");

            if (selection.State == AICodedbHostGenerationState.Legacy)
                return CombineInside(projectRoot, legacyProjectRelativePath, "legacy host path");

            return CombineInside(
                projectRoot,
                AICodedbProjectSettings.HostUnavailableRelativePath + "/" + NormalizeRelativePath(generationRelativePath, "generation path"),
                "unavailable host path");
        }

        internal static AICodedbHostGenerationSelection ResolvePointer(string projectRoot, string pointerPath)
        {
            return ResolvePointer(projectRoot, pointerPath, AICodedbPaths.PackageRootPath);
        }

        internal static AICodedbHostGenerationSelection ResolvePointer(
            string projectRoot,
            string pointerPath,
            string packageRoot)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var normalizedPointerPath = AICodedbPaths.NormalizePath(pointerPath);
            if (!File.Exists(normalizedPointerPath))
            {
                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Unavailable,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    0,
                    0,
                    string.Empty,
                    "Generation pointer is not installed.");
            }
            return ResolveCurrent(
                normalizedRoot,
                AICodedbPaths.NormalizePath(packageRoot).TrimEnd('/'),
                normalizedPointerPath);
        }

        private static AICodedbHostGenerationSelection ResolveCurrent(
            string projectRoot,
            string packageRoot,
            string currentPath)
        {
            var hasValidatedPointer = false;
            var validatedPointer = default(CurrentPointerDocument);
            var validatedGenerationRoot = string.Empty;
            try
            {
                AssertNoReparsePoints(projectRoot, currentPath, "current generation pointer");
                var pointer = ReadCurrentPointer(currentPath, "current generation pointer");
                var runtimeContract = AICodedbPackageRuntimeContractStore.Read(packageRoot);

                ValidatePointer(pointer);
                var expectedGenerationRelativePath = AICodedbProjectSettings.HostGenerationsRelativePath + "/" + pointer.generation_id;
                var actualGenerationRelativePath = NormalizeRelativePath(pointer.generation_relative_path, "generation root");
                if (!string.Equals(actualGenerationRelativePath, expectedGenerationRelativePath, StringComparison.Ordinal))
                    throw new InvalidOperationException("Current generation pointer targets an unexpected directory.");

                var generationRoot = CombineInside(projectRoot, actualGenerationRelativePath, "generation root");
                var manifestPath = CombineInside(generationRoot, "generation-manifest.json", "generation manifest");
                if (!Directory.Exists(generationRoot) || !File.Exists(manifestPath))
                    throw new InvalidOperationException("Selected generation or its manifest is missing.");
                AssertNoReparsePoints(projectRoot, generationRoot, "generation root");
                AssertNoReparsePoints(projectRoot, manifestPath, "generation manifest");

                var manifestHash = GetFileSha256(manifestPath);
                if (!string.Equals(manifestHash, pointer.generation_manifest_sha256, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Selected generation manifest hash does not match current.json.");

                var manifest = ReadGenerationManifest(manifestPath, "generation manifest");
                ValidateGenerationManifest(pointer, manifest, generationRoot);
                // Keep the authenticated pointer identity available for an
                // INVALID result when a later Package/router check fails.
                validatedPointer = pointer;
                validatedGenerationRoot = generationRoot;
                hasValidatedPointer = true;
                var state = ClassifyValidatedPointer(pointer, runtimeContract);
                if (state == AICodedbHostGenerationState.Current
                    || state == AICodedbHostGenerationState.Previous)
                {
                    AICodedbPackageRuntimeContractStore.ValidateProjectStableWrapper(
                        projectRoot,
                        runtimeContract.GetExpectedStableWrapperSha256(new AICodedbRuntimeIdentity(
                            pointer.package_version,
                            pointer.payload_version,
                            pointer.payload_sequence,
                            pointer.generation_id,
                            pointer.bootstrap_protocol)));
                }
                if (state == AICodedbHostGenerationState.Current)
                    ValidatePackageOwnedCurrentGeneration(
                        pointer,
                        manifestPath,
                        generationRoot,
                        packageRoot,
                        runtimeContract);
                var detail = state == AICodedbHostGenerationState.Previous
                    ? "Validated compatible previous generation selected by " + ToProjectRelativeDisplayPath(projectRoot, currentPath) + ". Use Reinstall CodeDB before running Host commands."
                    : state == AICodedbHostGenerationState.DowngradeReviewRequired
                        ? "Validated generation " + pointer.generation_id + " is newer than the loaded Package and requires downgrade review. Host commands and automatic mutation are disabled."
                        : ToProjectRelativeDisplayPath(projectRoot, currentPath);
                return new AICodedbHostGenerationSelection(
                    state,
                    pointer.generation_id,
                    pointer.package_version,
                    pointer.payload_version,
                    pointer.payload_sequence,
                    pointer.bootstrap_protocol,
                    generationRoot,
                    detail);
            }
            catch (Exception exception)
            {
                if (hasValidatedPointer)
                {
                    return new AICodedbHostGenerationSelection(
                        AICodedbHostGenerationState.Invalid,
                        validatedPointer.generation_id,
                        validatedPointer.package_version,
                        validatedPointer.payload_version,
                        validatedPointer.payload_sequence,
                        validatedPointer.bootstrap_protocol,
                        validatedGenerationRoot,
                        exception.Message);
                }

                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Invalid,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    0,
                    0,
                    string.Empty,
                    exception.Message);
            }
        }

        private static AICodedbHostGenerationSelection ResolveLegacy(string projectRoot)
        {
            var markerPath = CombineInside(projectRoot, AICodedbProjectSettings.HostPayloadMarkerRelativePath, "legacy marker");
            if (!File.Exists(markerPath))
            {
                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Unavailable,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    0,
                    0,
                    string.Empty,
                    "No selected host generation is installed.");
            }

            try
            {
                AssertNoReparsePoints(projectRoot, markerPath, "legacy marker");
                var marker = ReadLegacyMarker(markerPath, "legacy marker");
                if ((marker.schema_version != 1 && marker.schema_version != 2)
                    || !string.Equals(marker.managed_by, ManagedBy, StringComparison.Ordinal)
                    || string.IsNullOrWhiteSpace(marker.package_version)
                    || string.IsNullOrWhiteSpace(marker.payload_version)
                    || marker.payload_sequence < 1
                    || marker.files == null
                    || marker.files.Length == 0)
                {
                    throw new InvalidOperationException("Installed payload marker identity or schema is invalid.");
                }

                if (marker.schema_version == 2
                    && (!IsSha256(marker.payload_content_sha256)
                        || marker.host_use_gate_version < 1
                        || marker.generation_lease_version < 2
                        || !IsGenerationId(marker.generation_id)
                        || marker.bootstrap_protocol < 1
                        || !string.Equals(
                            marker.current_pointer,
                            AICodedbProjectSettings.HostCurrentPointerRelativePath,
                            StringComparison.Ordinal)))
                {
                    throw new InvalidOperationException("Installed payload marker generation metadata is invalid.");
                }

                var ownedPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var entry in marker.files)
                {
                    if (entry == null || !IsSha256(entry.installed_sha256))
                        throw new InvalidOperationException("Installed payload marker contains an invalid file entry.");
                    var relativePath = NormalizeRelativePath(entry.path, "installed payload file");
                    if (!ownedPaths.Add(relativePath)
                        || (marker.schema_version == 2
                            && !relativePath.StartsWith(
                                AICodedbProjectSettings.LegacyHostRootRelativePath + "/",
                                StringComparison.OrdinalIgnoreCase)))
                    {
                        throw new InvalidOperationException("Installed payload marker contains an invalid or duplicate path.");
                    }
                }

                var isRecognizedLegacy = marker.schema_version == 1
                                         && string.Equals(marker.package_version, AICodedbProjectSettings.LegacyPackageVersion, StringComparison.Ordinal)
                                         && string.Equals(marker.payload_version, AICodedbProjectSettings.LegacyPayloadVersion, StringComparison.Ordinal)
                                         && marker.payload_sequence == AICodedbProjectSettings.LegacyPayloadSequence
                                         && marker.host_use_gate_version >= 1;
                if (!isRecognizedLegacy)
                {
                    return new AICodedbHostGenerationSelection(
                        AICodedbHostGenerationState.Unavailable,
                        string.Empty,
                        marker.package_version,
                        marker.payload_version,
                        marker.payload_sequence,
                        0,
                        string.Empty,
                        "The project is adopted but no runtime generation is selected on this machine.");
                }

                var legacyRoot = CombineInside(projectRoot, AICodedbProjectSettings.LegacyHostRootRelativePath, "legacy host root");
                if (!Directory.Exists(legacyRoot))
                    throw new InvalidOperationException("Recognized legacy host root is missing.");
                AssertNoReparsePoints(projectRoot, legacyRoot, "legacy host root");

                foreach (var entry in marker.files)
                {
                    var relativePath = NormalizeRelativePath(entry.path, "legacy host file");
                    if (!relativePath.StartsWith(AICodedbProjectSettings.LegacyHostRootRelativePath + "/", StringComparison.OrdinalIgnoreCase))
                    {
                        throw new InvalidOperationException("Recognized legacy marker contains a path outside the flat Host root.");
                    }

                    var filePath = CombineInside(projectRoot, relativePath, "legacy host file");
                    AssertNoReparsePoints(projectRoot, filePath, "legacy host file");
                    if (!File.Exists(filePath)
                        || !string.Equals(GetFileSha256(filePath), entry.installed_sha256, StringComparison.OrdinalIgnoreCase))
                    {
                        throw new InvalidOperationException("Recognized legacy host file is missing or has drifted: " + relativePath);
                    }
                }

                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Legacy,
                    AICodedbProjectSettings.LegacyPayloadVersion,
                    marker.package_version,
                    marker.payload_version,
                    marker.payload_sequence,
                    0,
                    legacyRoot,
                    "Validated legacy flat Host. Use Reinstall CodeDB before running Host commands. Marker: "
                    + ToProjectRelativeDisplayPath(projectRoot, markerPath));
            }
            catch (Exception exception)
            {
                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Invalid,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    0,
                    0,
                    string.Empty,
                    exception.Message);
            }
        }

        private static void ValidatePointer(CurrentPointerDocument pointer)
        {
            if (pointer.schema_version != 1
                || !string.Equals(pointer.managed_by, ManagedBy, StringComparison.Ordinal)
                || string.IsNullOrWhiteSpace(pointer.package_version)
                || string.IsNullOrWhiteSpace(pointer.payload_version)
                || pointer.payload_sequence < 1
                || !IsGenerationId(pointer.generation_id)
                || pointer.bootstrap_protocol < 1
                || !IsSha256(pointer.generation_manifest_sha256))
            {
                throw new InvalidOperationException("Generation pointer identity, version, or protocol is invalid.");
            }
        }

        private static AICodedbHostGenerationState ClassifyValidatedPointer(
            CurrentPointerDocument pointer,
            AICodedbPackageRuntimeContract runtimeContract)
        {
            var disposition = runtimeContract.Classify(new AICodedbRuntimeIdentity(
                pointer.package_version,
                pointer.payload_version,
                pointer.payload_sequence,
                pointer.generation_id,
                pointer.bootstrap_protocol));
            switch (disposition)
            {
                case AICodedbRuntimeGenerationDisposition.Current:
                    return AICodedbHostGenerationState.Current;
                case AICodedbRuntimeGenerationDisposition.TrustedPrevious:
                    return AICodedbHostGenerationState.Previous;
                case AICodedbRuntimeGenerationDisposition.Newer:
                    return AICodedbHostGenerationState.DowngradeReviewRequired;
                case AICodedbRuntimeGenerationDisposition.SequenceCollision:
                    throw new InvalidOperationException(
                        "Selected generation reuses the current payload sequence with a different identity.");
                default:
                    throw new InvalidOperationException(
                        "Selected generation is not current or an exact Package-declared transition.");
            }
        }

        private static void ValidatePackageOwnedCurrentGeneration(
            CurrentPointerDocument installedPointer,
            string installedManifestPath,
            string installedGenerationRoot,
            string packageRoot,
            AICodedbPackageRuntimeContract runtimeContract)
        {
            if (string.IsNullOrWhiteSpace(packageRoot) || !Directory.Exists(packageRoot))
                throw new InvalidOperationException("Resolved Package root is unavailable for Current generation authentication.");
            AssertNoReparsePoints(packageRoot, packageRoot, "resolved Package root");

            var packagePointerPath = CombineInside(packageRoot, "Payload~/host-current.json", "Package Current pointer");
            var packageGenerationRoot = CombineInside(
                packageRoot,
                "Payload~/Generations/" + runtimeContract.Target.GenerationId,
                "Package Current generation");
            var packageManifestPath = CombineInside(
                packageGenerationRoot,
                "generation-manifest.json",
                "Package Current generation manifest");
            if (!File.Exists(packagePointerPath)
                || !Directory.Exists(packageGenerationRoot)
                || !File.Exists(packageManifestPath))
            {
                throw new InvalidOperationException("Package-owned Current generation identity is incomplete.");
            }
            AssertNoReparsePoints(packageRoot, packagePointerPath, "Package Current pointer");
            AssertNoReparsePoints(packageRoot, packageGenerationRoot, "Package Current generation");
            AssertNoReparsePoints(packageGenerationRoot, packageManifestPath, "Package Current generation manifest");

            var packagePointer = ReadCurrentPointer(packagePointerPath, "Package Current pointer");
            ValidatePointer(packagePointer);
            if (ClassifyValidatedPointer(packagePointer, runtimeContract) != AICodedbHostGenerationState.Current
                || !PointersHaveSameIdentity(installedPointer, packagePointer))
            {
                throw new InvalidOperationException(
                    "Selected Current generation pointer does not match the Package-owned host-current identity.");
            }

            var packageManifestHash = GetFileSha256(packageManifestPath);
            if (!string.Equals(packageManifestHash, packagePointer.generation_manifest_sha256, StringComparison.OrdinalIgnoreCase)
                || !string.Equals(packageManifestHash, GetFileSha256(installedManifestPath), StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    "Selected Current generation manifest does not match the Package-owned manifest bytes.");
            }

            var packageManifest = ReadGenerationManifest(packageManifestPath, "Package Current generation manifest");
            ValidateGenerationManifest(packagePointer, packageManifest, packageGenerationRoot);
            if (!GenerationManifestsHaveSameIdentity(packageManifest, ReadGenerationManifest(
                    installedManifestPath,
                    "selected Current generation manifest")))
            {
                throw new InvalidOperationException(
                    "Selected Current generation manifest identity does not match the Package-owned manifest.");
            }

            // Both closures are validated against the same byte-identical manifest.
            AssertNoReparsePoints(installedGenerationRoot, installedGenerationRoot, "selected Current generation root");
        }

        private static bool PointersHaveSameIdentity(
            CurrentPointerDocument left,
            CurrentPointerDocument right)
        {
            return left.schema_version == right.schema_version
                   && string.Equals(left.managed_by, right.managed_by, StringComparison.Ordinal)
                   && string.Equals(left.package_version, right.package_version, StringComparison.Ordinal)
                   && string.Equals(left.payload_version, right.payload_version, StringComparison.Ordinal)
                   && left.payload_sequence == right.payload_sequence
                   && string.Equals(left.generation_id, right.generation_id, StringComparison.Ordinal)
                   && string.Equals(left.generation_relative_path, right.generation_relative_path, StringComparison.Ordinal)
                   && string.Equals(
                       left.generation_manifest_sha256,
                       right.generation_manifest_sha256,
                       StringComparison.OrdinalIgnoreCase)
                   && left.bootstrap_protocol == right.bootstrap_protocol;
        }

        private static bool GenerationManifestsHaveSameIdentity(
            GenerationManifestDocument left,
            GenerationManifestDocument right)
        {
            if (left.schema_version != right.schema_version
                || !string.Equals(left.managed_by, right.managed_by, StringComparison.Ordinal)
                || !string.Equals(left.generation_id, right.generation_id, StringComparison.Ordinal)
                || !string.Equals(left.package_version, right.package_version, StringComparison.Ordinal)
                || !string.Equals(left.payload_version, right.payload_version, StringComparison.Ordinal)
                || left.payload_sequence != right.payload_sequence
                || left.bootstrap_protocol != right.bootstrap_protocol
                || left.files == null
                || right.files == null
                || left.files.Length != right.files.Length)
            {
                return false;
            }

            var expected = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var entry in left.files)
                expected.Add(entry.path, entry.sha256);
            foreach (var entry in right.files)
            {
                string hash;
                if (!expected.TryGetValue(entry.path, out hash)
                    || !string.Equals(hash, entry.sha256, StringComparison.OrdinalIgnoreCase))
                    return false;
            }
            return true;
        }

        private static void ValidateGenerationManifest(
            CurrentPointerDocument pointer,
            GenerationManifestDocument manifest,
            string generationRoot)
        {
            if (manifest == null
                || manifest.schema_version != 1
                || !string.Equals(manifest.managed_by, ManagedBy, StringComparison.Ordinal)
                || !string.Equals(manifest.generation_id, pointer.generation_id, StringComparison.Ordinal)
                || !string.Equals(manifest.package_version, pointer.package_version, StringComparison.Ordinal)
                || !string.Equals(manifest.payload_version, pointer.payload_version, StringComparison.Ordinal)
                || manifest.payload_sequence != pointer.payload_sequence
                || manifest.bootstrap_protocol != pointer.bootstrap_protocol
                || manifest.files == null
                || manifest.files.Length == 0)
            {
                throw new InvalidOperationException("Selected generation manifest identity, version, or file list is invalid.");
            }

            var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var entry in manifest.files)
            {
                if (entry == null || !IsSha256(entry.sha256))
                    throw new InvalidOperationException("Selected generation manifest contains an invalid file entry.");

                var relativePath = NormalizeRelativePath(entry.path, "generation file");
                if (string.Equals(relativePath, "generation-manifest.json", StringComparison.OrdinalIgnoreCase)
                    || !paths.Add(relativePath))
                    throw new InvalidOperationException("Selected generation manifest contains a duplicate file path.");

                var filePath = CombineInside(generationRoot, relativePath, "generation file");
                AssertNoReparsePoints(generationRoot, filePath, "generation file");
                if (!File.Exists(filePath)
                    || !string.Equals(GetFileSha256(filePath), entry.sha256, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Selected generation file is missing or has drifted: " + relativePath);
                }
            }

            ValidateGenerationClosure(generationRoot, paths);
        }

        private static void ValidateGenerationClosure(string generationRoot, HashSet<string> manifestPaths)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(generationRoot).TrimEnd('/');
            var allowedDirectories = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var manifestPath in manifestPaths)
            {
                var separatorIndex = manifestPath.IndexOf('/');
                while (separatorIndex > 0)
                {
                    allowedDirectories.Add(manifestPath.Substring(0, separatorIndex));
                    separatorIndex = manifestPath.IndexOf('/', separatorIndex + 1);
                }
            }

            var pendingDirectories = new Stack<string>();
            pendingDirectories.Push(normalizedRoot);
            var actualFileCount = 0;
            while (pendingDirectories.Count > 0)
            {
                var directory = pendingDirectories.Pop();
                foreach (var path in Directory.GetFileSystemEntries(directory))
                {
                    AssertNoReparsePoints(normalizedRoot, path, "generation content");
                    var attributes = File.GetAttributes(path);
                    if ((attributes & FileAttributes.Directory) != 0)
                    {
                        var normalizedDirectory = AICodedbPaths.NormalizePath(path);
                        var relativeDirectory = normalizedDirectory.Substring(normalizedRoot.Length + 1);
                        if (!allowedDirectories.Contains(relativeDirectory))
                        {
                            throw new InvalidOperationException(
                                "Selected generation contains an unmanifested directory: " + relativeDirectory);
                        }
                        pendingDirectories.Push(path);
                        continue;
                    }

                    actualFileCount++;
                    var normalizedPath = AICodedbPaths.NormalizePath(path);
                    var relativePath = normalizedPath.Substring(normalizedRoot.Length + 1);
                    if (!string.Equals(relativePath, "generation-manifest.json", StringComparison.OrdinalIgnoreCase)
                        && !manifestPaths.Contains(relativePath))
                    {
                        throw new InvalidOperationException("Selected generation contains an unmanifested file: " + relativePath);
                    }
                }
            }

            if (actualFileCount != manifestPaths.Count + 1)
                throw new InvalidOperationException("Selected generation file closure is incomplete.");
        }

        private static string CombineInside(string root, string relativePath, string label)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/');
            var normalizedRelativePath = NormalizeRelativePath(relativePath, label);
            var combined = AICodedbPaths.NormalizePath(Path.Combine(normalizedRoot, normalizedRelativePath));
            if (!combined.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException(label + " escapes its root.");
            return combined;
        }

        private static string ToProjectRelativeDisplayPath(string projectRoot, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            var prefix = normalizedRoot + "/";
            return normalizedPath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                ? normalizedPath.Substring(prefix.Length)
                : normalizedPath;
        }

        private static string NormalizeRelativePath(string path, string label)
        {
            if (string.IsNullOrWhiteSpace(path) || Path.IsPathRooted(path))
                throw new InvalidOperationException(label + " must be a non-empty relative path.");

            var normalized = path.Replace('\\', '/').Trim('/');
            var segments = normalized.Split('/');
            foreach (var segment in segments)
            {
                if (string.IsNullOrWhiteSpace(segment) || segment == "." || segment == "..")
                    throw new InvalidOperationException(label + " contains an invalid path segment.");
            }
            return string.Join("/", segments);
        }

        private static bool IsSha256(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length != 64)
                return false;
            foreach (var character in value)
            {
                if (!Uri.IsHexDigit(character))
                    return false;
            }
            return true;
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

        private static string GetFileSha256(string path)
        {
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var sha256 = SHA256.Create())
            {
                var hash = sha256.ComputeHash(stream);
                var builder = new StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return builder.ToString();
            }
        }

        private static CurrentPointerDocument ReadCurrentPointer(string path, string label)
        {
            var value = AICodedbStrictJson.ReadObject(path, PointerMaximumBytes, label);
            return new CurrentPointerDocument
            {
                schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", label),
                managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", label),
                package_version = AICodedbStrictJson.GetRequiredString(value, "package_version", label),
                payload_version = AICodedbStrictJson.GetRequiredString(value, "payload_version", label),
                payload_sequence = AICodedbStrictJson.GetRequiredInt32(value, "payload_sequence", label),
                generation_id = AICodedbStrictJson.GetRequiredString(value, "generation_id", label),
                generation_relative_path = AICodedbStrictJson.GetRequiredString(value, "generation_relative_path", label),
                generation_manifest_sha256 = AICodedbStrictJson.GetRequiredString(value, "generation_manifest_sha256", label),
                bootstrap_protocol = AICodedbStrictJson.GetRequiredInt32(value, "bootstrap_protocol", label)
            };
        }

        private static GenerationManifestDocument ReadGenerationManifest(string path, string label)
        {
            var value = AICodedbStrictJson.ReadObject(path, ManifestMaximumBytes, label);
            var files = AICodedbStrictJson.GetRequiredArray(value, "files", label);
            var entries = new GenerationFileDocument[files.Count];
            for (var index = 0; index < files.Count; index++)
            {
                var entryLabel = label + " file entry";
                var entry = AICodedbStrictJson.RequireObject(files[index], entryLabel);
                entries[index] = new GenerationFileDocument
                {
                    path = AICodedbStrictJson.GetRequiredString(entry, "path", entryLabel),
                    sha256 = AICodedbStrictJson.GetRequiredString(entry, "sha256", entryLabel)
                };
            }
            return new GenerationManifestDocument
            {
                schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", label),
                managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", label),
                generation_id = AICodedbStrictJson.GetRequiredString(value, "generation_id", label),
                package_version = AICodedbStrictJson.GetRequiredString(value, "package_version", label),
                payload_version = AICodedbStrictJson.GetRequiredString(value, "payload_version", label),
                payload_sequence = AICodedbStrictJson.GetRequiredInt32(value, "payload_sequence", label),
                bootstrap_protocol = AICodedbStrictJson.GetRequiredInt32(value, "bootstrap_protocol", label),
                files = entries
            };
        }

        private static LegacyMarkerDocument ReadLegacyMarker(string path, string label)
        {
            var value = AICodedbStrictJson.ReadObject(path, ManifestMaximumBytes, label);
            var schemaVersion = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", label);
            var files = AICodedbStrictJson.GetRequiredArray(value, "files", label);
            var entries = new LegacyFileDocument[files.Count];
            for (var index = 0; index < files.Count; index++)
            {
                var entryLabel = label + " file entry";
                var entry = AICodedbStrictJson.RequireObject(files[index], entryLabel);
                entries[index] = new LegacyFileDocument
                {
                    path = AICodedbStrictJson.GetRequiredString(entry, "path", entryLabel),
                    installed_sha256 = AICodedbStrictJson.GetRequiredString(entry, "installed_sha256", entryLabel)
                };
            }

            var marker = new LegacyMarkerDocument
            {
                schema_version = schemaVersion,
                managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", label),
                package_version = AICodedbStrictJson.GetRequiredString(value, "package_version", label),
                payload_version = AICodedbStrictJson.GetRequiredString(value, "payload_version", label),
                payload_sequence = AICodedbStrictJson.GetRequiredInt32(value, "payload_sequence", label),
                host_use_gate_version = AICodedbStrictJson.GetRequiredInt32(value, "host_use_gate_version", label),
                files = entries
            };
            if (schemaVersion == 2)
            {
                marker.payload_content_sha256 = AICodedbStrictJson.GetRequiredString(value, "payload_content_sha256", label);
                marker.generation_lease_version = AICodedbStrictJson.GetRequiredInt32(value, "generation_lease_version", label);
                marker.generation_id = AICodedbStrictJson.GetRequiredString(value, "generation_id", label);
                marker.bootstrap_protocol = AICodedbStrictJson.GetRequiredInt32(value, "bootstrap_protocol", label);
                marker.current_pointer = AICodedbStrictJson.GetRequiredString(value, "current_pointer", label);
            }
            return marker;
        }

        private static void AssertNoReparsePoints(string root, string path, string label)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/');
            var current = AICodedbPaths.NormalizePath(path);
            while (true)
            {
                if (!current.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                {
                    if (!string.Equals(current, normalizedRoot, StringComparison.OrdinalIgnoreCase))
                        throw new InvalidOperationException(label + " escapes its root.");
                }
                if (File.Exists(current) || Directory.Exists(current))
                {
                    var attributes = File.GetAttributes(current);
                    if ((attributes & FileAttributes.ReparsePoint) != 0)
                        throw new InvalidOperationException(label + " contains a reparse point.");
                }
                if (string.Equals(current, normalizedRoot, StringComparison.OrdinalIgnoreCase))
                    break;
                var parent = Path.GetDirectoryName(current);
                if (string.IsNullOrWhiteSpace(parent))
                    throw new InvalidOperationException(label + " has no valid parent.");
                current = AICodedbPaths.NormalizePath(parent).TrimEnd('/');
            }
        }

        [Serializable]
        private sealed class CurrentPointerDocument
        {
            public int schema_version;
            public string managed_by;
            public string package_version;
            public string payload_version;
            public int payload_sequence;
            public string generation_id;
            public string generation_relative_path;
            public string generation_manifest_sha256;
            public int bootstrap_protocol;
        }

        [Serializable]
        private sealed class GenerationManifestDocument
        {
            public int schema_version;
            public string managed_by;
            public string generation_id;
            public string package_version;
            public string payload_version;
            public int payload_sequence;
            public int bootstrap_protocol;
            public GenerationFileDocument[] files;
        }

        [Serializable]
        private sealed class GenerationFileDocument
        {
            public string path;
            public string sha256;
        }

        [Serializable]
        private sealed class LegacyMarkerDocument
        {
            public int schema_version;
            public string managed_by;
            public string package_version;
            public string payload_version;
            public int payload_sequence;
            public string payload_content_sha256;
            public int host_use_gate_version;
            public int generation_lease_version;
            public string generation_id;
            public int bootstrap_protocol;
            public string current_pointer;
            public LegacyFileDocument[] files;
        }

        [Serializable]
        private sealed class LegacyFileDocument
        {
            public string path;
            public string installed_sha256;
        }
    }

    internal readonly struct AICodedbHostUpdatePolicy
    {
        internal bool IsValid { get; }
        internal bool IsEnabled { get; }
        internal bool IsDefault { get; }
        internal string Detail { get; }

        internal AICodedbHostUpdatePolicy(bool isValid, bool isEnabled, bool isDefault, string detail)
        {
            IsValid = isValid;
            IsEnabled = isEnabled;
            IsDefault = isDefault;
            Detail = detail ?? string.Empty;
        }
    }

    internal static class AICodedbHostUpdatePolicyStore
    {
        private const string ManagedBy = "com.rice.ai-codedb";

        internal static AICodedbHostUpdatePolicy Read(string projectRoot)
        {
            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
                var path = AICodedbPaths.NormalizePath(Path.Combine(
                    normalizedRoot,
                    AICodedbProjectSettings.HostUpdatePolicyRelativePath));
                AssertSafePolicyPath(normalizedRoot, path);
                if (!File.Exists(path))
                    return new AICodedbHostUpdatePolicy(true, true, true, "Enabled by default.");

                var fileInfo = new FileInfo(path);
                if ((fileInfo.Attributes & FileAttributes.ReparsePoint) != 0)
                    throw new InvalidOperationException("Automatic host update policy cannot be a reparse point.");
                var value = AICodedbStrictJson.ReadObject(path, 64 * 1024, "Automatic host update policy");
                var document = new HostUpdatePolicyDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(
                        value,
                        "schema_version",
                        "Automatic host update policy"),
                    managed_by = AICodedbStrictJson.GetRequiredString(
                        value,
                        "managed_by",
                        "Automatic host update policy"),
                    project_root = AICodedbStrictJson.GetRequiredString(
                        value,
                        "project_root",
                        "Automatic host update policy"),
                    automatic_updates = AICodedbStrictJson.GetRequiredBoolean(
                        value,
                        "automatic_updates",
                        "Automatic host update policy"),
                    updated_at_utc = AICodedbStrictJson.GetRequiredString(
                        value,
                        "updated_at_utc",
                        "Automatic host update policy")
                };
                DateTime updatedAt;
                if (document == null
                    || document.schema_version != 1
                    || !string.Equals(document.managed_by, ManagedBy, StringComparison.Ordinal)
                    || !string.Equals(
                        AICodedbPaths.NormalizePath(document.project_root).TrimEnd('/'),
                        normalizedRoot,
                        StringComparison.OrdinalIgnoreCase)
                    || !DateTime.TryParse(
                        document.updated_at_utc,
                        null,
                        DateTimeStyles.RoundtripKind,
                        out updatedAt))
                {
                    throw new InvalidOperationException("Automatic host update policy has invalid identity or schema.");
                }

                return new AICodedbHostUpdatePolicy(true, document.automatic_updates, false, path);
            }
            catch (Exception exception)
            {
                return new AICodedbHostUpdatePolicy(false, false, false, exception.Message);
            }
        }

        internal static void SetEnabled(string projectRoot, bool enabled)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var path = AICodedbPaths.NormalizePath(Path.Combine(
                normalizedRoot,
                AICodedbProjectSettings.HostUpdatePolicyRelativePath));
            if (!path.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Automatic host update policy escapes the Unity project.");
            AssertSafePolicyPath(normalizedRoot, Path.GetDirectoryName(path));
            var document = new HostUpdatePolicyDocument
            {
                schema_version = 1,
                managed_by = ManagedBy,
                project_root = normalizedRoot,
                automatic_updates = enabled,
                updated_at_utc = DateTime.UtcNow.ToString("o")
            };
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            AssertSafePolicyPath(normalizedRoot, path);
            WriteJsonAtomic(path, JsonUtility.ToJson(document, true) + "\n");
        }

        private static void AssertSafePolicyPath(string projectRoot, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var current = AICodedbPaths.NormalizePath(path).TrimEnd('/');
            if (!current.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Automatic host update policy escapes the Unity project.");

            while (!string.Equals(current, normalizedRoot, StringComparison.OrdinalIgnoreCase))
            {
                if (File.Exists(current) || Directory.Exists(current))
                {
                    var attributes = File.GetAttributes(current);
                    if ((attributes & FileAttributes.ReparsePoint) != 0)
                        throw new InvalidOperationException("Automatic host update policy contains a reparse point.");
                }
                var parent = Path.GetDirectoryName(current);
                if (string.IsNullOrWhiteSpace(parent))
                    throw new InvalidOperationException("Automatic host update policy has no valid parent.");
                current = AICodedbPaths.NormalizePath(parent).TrimEnd('/');
            }
        }

        private static void WriteJsonAtomic(string targetPath, string content)
        {
            var directory = Path.GetDirectoryName(targetPath);
            if (string.IsNullOrWhiteSpace(directory))
                throw new InvalidOperationException("Automatic host update policy has no parent directory.");

            Directory.CreateDirectory(directory);
            var temporaryPath = Path.Combine(directory, "." + Path.GetFileName(targetPath) + "." + Guid.NewGuid().ToString("N") + ".tmp");
            var backupPath = Path.Combine(directory, "." + Path.GetFileName(targetPath) + "." + Guid.NewGuid().ToString("N") + ".bak");
            try
            {
                using (var stream = new FileStream(temporaryPath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                using (var writer = new StreamWriter(stream, new UTF8Encoding(false)))
                {
                    writer.Write(content);
                    writer.Flush();
                    stream.Flush(true);
                }

                if (File.Exists(targetPath))
                {
                    File.Replace(temporaryPath, targetPath, backupPath);
                    File.Delete(backupPath);
                }
                else
                    File.Move(temporaryPath, targetPath);
            }
            finally
            {
                if (File.Exists(temporaryPath))
                    File.Delete(temporaryPath);
                if (File.Exists(backupPath))
                    File.Delete(backupPath);
            }
        }

        [Serializable]
        private sealed class HostUpdatePolicyDocument
        {
            public int schema_version;
            public string managed_by;
            public string project_root;
            public bool automatic_updates;
            public string updated_at_utc;
        }
    }
}
