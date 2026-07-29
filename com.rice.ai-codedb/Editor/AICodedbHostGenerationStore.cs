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
        Current,
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
        internal bool IsUsable => State == AICodedbHostGenerationState.Current || State == AICodedbHostGenerationState.Legacy;

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
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var currentPath = AICodedbPaths.NormalizePath(Path.Combine(
                normalizedRoot,
                AICodedbProjectSettings.HostCurrentPointerRelativePath));

            if (File.Exists(currentPath))
                return ResolveCurrent(normalizedRoot, currentPath);

            return ResolveLegacy(normalizedRoot);
        }

        internal static string ResolveHostPath(
            string projectRoot,
            string generationRelativePath,
            string legacyProjectRelativePath)
        {
            var selection = Resolve(projectRoot);
            if (selection.State == AICodedbHostGenerationState.Current)
                return CombineInside(selection.RootPath, generationRelativePath, "generation path");

            if (selection.State == AICodedbHostGenerationState.Legacy)
                return CombineInside(projectRoot, legacyProjectRelativePath, "legacy host path");

            return CombineInside(
                projectRoot,
                AICodedbProjectSettings.HostUnavailableRelativePath + "/" + NormalizeRelativePath(generationRelativePath, "generation path"),
                "unavailable host path");
        }

        private static AICodedbHostGenerationSelection ResolveCurrent(string projectRoot, string currentPath)
        {
            try
            {
                AssertNoReparsePoints(projectRoot, currentPath, "current generation pointer");
                var pointer = JsonUtility.FromJson<CurrentPointerDocument>(ReadBoundedText(currentPath, PointerMaximumBytes, "current generation pointer"));
                if (pointer == null)
                    throw new InvalidOperationException("Current generation pointer is empty.");

                ValidateCurrentPointer(pointer);
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

                var manifest = JsonUtility.FromJson<GenerationManifestDocument>(ReadBoundedText(manifestPath, ManifestMaximumBytes, "generation manifest"));
                ValidateGenerationManifest(pointer, manifest, generationRoot);
                return new AICodedbHostGenerationSelection(
                    AICodedbHostGenerationState.Current,
                    pointer.generation_id,
                    pointer.package_version,
                    pointer.payload_version,
                    pointer.payload_sequence,
                    pointer.bootstrap_protocol,
                    generationRoot,
                    AICodedbPaths.ToProjectRelativeDisplayPath(currentPath));
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
                var marker = JsonUtility.FromJson<LegacyMarkerDocument>(ReadBoundedText(markerPath, ManifestMaximumBytes, "legacy marker"));
                if (marker == null
                    || marker.schema_version != 1
                    || !string.Equals(marker.managed_by, ManagedBy, StringComparison.Ordinal)
                    || !string.Equals(marker.package_version, AICodedbProjectSettings.LegacyPackageVersion, StringComparison.Ordinal)
                    || !string.Equals(marker.payload_version, AICodedbProjectSettings.LegacyPayloadVersion, StringComparison.Ordinal)
                    || marker.payload_sequence != AICodedbProjectSettings.LegacyPayloadSequence
                    || marker.host_use_gate_version < 1
                    || marker.files == null
                    || marker.files.Length == 0)
                {
                    throw new InvalidOperationException("Installed payload is not the recognized poc.21 legacy generation.");
                }

                var legacyRoot = CombineInside(projectRoot, AICodedbProjectSettings.LegacyHostRootRelativePath, "legacy host root");
                if (!Directory.Exists(legacyRoot))
                    throw new InvalidOperationException("Recognized legacy host root is missing.");
                AssertNoReparsePoints(projectRoot, legacyRoot, "legacy host root");

                var ownedPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var entry in marker.files)
                {
                    if (entry == null || !IsSha256(entry.installed_sha256))
                        throw new InvalidOperationException("Recognized legacy marker contains an invalid file entry.");
                    var relativePath = NormalizeRelativePath(entry.path, "legacy host file");
                    if (!relativePath.StartsWith(AICodedbProjectSettings.LegacyHostRootRelativePath + "/", StringComparison.OrdinalIgnoreCase)
                        || !ownedPaths.Add(relativePath))
                    {
                        throw new InvalidOperationException("Recognized legacy marker contains an invalid or duplicate path.");
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
                    AICodedbPaths.ToProjectRelativeDisplayPath(markerPath));
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

        private static void ValidateCurrentPointer(CurrentPointerDocument pointer)
        {
            if (pointer.schema_version != 1
                || !string.Equals(pointer.managed_by, ManagedBy, StringComparison.Ordinal)
                || !string.Equals(pointer.package_version, AICodedbProjectSettings.CurrentPackageVersion, StringComparison.Ordinal)
                || !string.Equals(pointer.payload_version, AICodedbProjectSettings.CurrentPayloadVersion, StringComparison.Ordinal)
                || pointer.payload_sequence != AICodedbProjectSettings.CurrentPayloadSequence
                || !string.Equals(pointer.generation_id, AICodedbProjectSettings.CurrentGenerationId, StringComparison.Ordinal)
                || pointer.bootstrap_protocol != AICodedbProjectSettings.CurrentBootstrapProtocol
                || !IsSha256(pointer.generation_manifest_sha256))
            {
                throw new InvalidOperationException("Current generation pointer identity, version, or protocol is invalid.");
            }
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
                if (!paths.Add(relativePath))
                    throw new InvalidOperationException("Selected generation manifest contains a duplicate file path.");

                var filePath = CombineInside(generationRoot, relativePath, "generation file");
                AssertNoReparsePoints(generationRoot, filePath, "generation file");
                if (!File.Exists(filePath)
                    || !string.Equals(GetFileSha256(filePath), entry.sha256, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Selected generation file is missing or has drifted: " + relativePath);
                }
            }
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

        private static string ReadBoundedText(string path, long maximumBytes, string label)
        {
            var length = new FileInfo(path).Length;
            if (length <= 0 || length > maximumBytes)
                throw new InvalidOperationException(label + " has an invalid size.");
            return File.ReadAllText(path);
        }

        private static void AssertNoReparsePoints(string root, string path, string label)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/');
            var current = AICodedbPaths.NormalizePath(path);
            while (!string.Equals(current, normalizedRoot, StringComparison.OrdinalIgnoreCase))
            {
                if (!current.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException(label + " escapes its root.");
                if (File.Exists(current) || Directory.Exists(current))
                {
                    var attributes = File.GetAttributes(current);
                    if ((attributes & FileAttributes.ReparsePoint) != 0)
                        throw new InvalidOperationException(label + " contains a reparse point.");
                }
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
            public int host_use_gate_version;
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
                if (fileInfo.Length <= 0 || fileInfo.Length > 64 * 1024)
                    throw new InvalidOperationException("Automatic host update policy has an invalid size.");
                if ((fileInfo.Attributes & FileAttributes.ReparsePoint) != 0)
                    throw new InvalidOperationException("Automatic host update policy cannot be a reparse point.");
                var document = JsonUtility.FromJson<HostUpdatePolicyDocument>(File.ReadAllText(path));
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
