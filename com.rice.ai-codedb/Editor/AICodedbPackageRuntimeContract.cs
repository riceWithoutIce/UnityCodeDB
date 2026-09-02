using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbRuntimeGenerationDisposition
    {
        Current,
        TrustedPrevious,
        Newer,
        SequenceCollision,
        Invalid
    }

    internal readonly struct AICodedbRuntimeIdentity
    {
        internal string PackageVersion { get; }
        internal string PayloadVersion { get; }
        internal int PayloadSequence { get; }
        internal string GenerationId { get; }
        internal int BootstrapProtocol { get; }

        internal AICodedbRuntimeIdentity(
            string packageVersion,
            string payloadVersion,
            int payloadSequence,
            string generationId,
            int bootstrapProtocol)
        {
            PackageVersion = packageVersion ?? string.Empty;
            PayloadVersion = payloadVersion ?? string.Empty;
            PayloadSequence = payloadSequence;
            GenerationId = generationId ?? string.Empty;
            BootstrapProtocol = bootstrapProtocol;
        }

        internal string GetStableKey()
        {
            return string.Join(
                "\n",
                PackageVersion,
                PayloadVersion,
                PayloadSequence.ToString(CultureInfo.InvariantCulture),
                GenerationId,
                BootstrapProtocol.ToString(CultureInfo.InvariantCulture));
        }
    }

    /// <summary>
    /// The immutable source evidence for one Package-declared bootstrap
    /// transition.  Keeping the wrapper hash beside the identity prevents a
    /// caller from classifying a previous generation and then silently using
    /// the current launcher bytes.
    /// </summary>
    internal sealed class AICodedbRuntimeTransition
    {
        internal AICodedbRuntimeIdentity Identity { get; }
        internal string SourceTag { get; }
        internal int SourceMarkerSchemaVersion { get; }
        internal int SourceHostUseGateVersion { get; }
        internal int SourceGenerationLeaseVersion { get; }
        internal int SourceFlatFileCount { get; }
        internal string SourceFlatClosureSha256 { get; }
        internal string StableWrapperSha256 { get; }

        internal AICodedbRuntimeTransition(
            AICodedbRuntimeIdentity identity,
            string sourceTag,
            int sourceMarkerSchemaVersion,
            int sourceHostUseGateVersion,
            int sourceGenerationLeaseVersion,
            int sourceFlatFileCount,
            string sourceFlatClosureSha256,
            string stableWrapperSha256)
        {
            Identity = identity;
            SourceTag = sourceTag ?? string.Empty;
            SourceMarkerSchemaVersion = sourceMarkerSchemaVersion;
            SourceHostUseGateVersion = sourceHostUseGateVersion;
            SourceGenerationLeaseVersion = sourceGenerationLeaseVersion;
            SourceFlatFileCount = sourceFlatFileCount;
            SourceFlatClosureSha256 = sourceFlatClosureSha256 ?? string.Empty;
            StableWrapperSha256 = stableWrapperSha256 ?? string.Empty;
        }
    }

    internal sealed class AICodedbPackageRuntimeContract
    {
        private readonly Dictionary<string, AICodedbRuntimeTransition> _transitions;

        internal AICodedbRuntimeIdentity Target { get; }
        internal AICodedbControlContractIdentity ControlContract { get; }
        internal string TargetStableWrapperSha256 { get; }
        internal string Sha256 { get; }

        internal IEnumerable<AICodedbRuntimeTransition> Transitions => _transitions.Values;

        internal AICodedbPackageRuntimeContract(
            AICodedbRuntimeIdentity target,
            AICodedbControlContractIdentity controlContract,
            string sha256,
            string targetStableWrapperSha256,
            IEnumerable<AICodedbRuntimeTransition> transitions)
        {
            Target = target;
            ControlContract = controlContract;
            TargetStableWrapperSha256 = targetStableWrapperSha256 ?? string.Empty;
            Sha256 = sha256 ?? string.Empty;
            _transitions = new Dictionary<string, AICodedbRuntimeTransition>(StringComparer.Ordinal);
            foreach (var transition in transitions)
            {
                if (transition == null)
                    throw new InvalidOperationException("Package runtime contract contains a null transition.");
                var key = transition.Identity.GetStableKey();
                if (_transitions.ContainsKey(key))
                    throw new InvalidOperationException("Package runtime contract contains a duplicate transition.");
                _transitions.Add(key, transition);
            }
        }

        internal AICodedbRuntimeGenerationDisposition Classify(AICodedbRuntimeIdentity selected)
        {
            if (string.Equals(selected.GetStableKey(), Target.GetStableKey(), StringComparison.Ordinal))
                return AICodedbRuntimeGenerationDisposition.Current;
            if (selected.PayloadSequence > Target.PayloadSequence)
                return AICodedbRuntimeGenerationDisposition.Newer;
            if (selected.PayloadSequence == Target.PayloadSequence)
                return AICodedbRuntimeGenerationDisposition.SequenceCollision;
            return _transitions.ContainsKey(selected.GetStableKey())
                ? AICodedbRuntimeGenerationDisposition.TrustedPrevious
                : AICodedbRuntimeGenerationDisposition.Invalid;
        }

        internal bool TryGetTransition(
            AICodedbRuntimeIdentity selected,
            out AICodedbRuntimeTransition transition)
        {
            return _transitions.TryGetValue(selected.GetStableKey(), out transition);
        }

        internal string GetExpectedStableWrapperSha256(AICodedbRuntimeIdentity selected)
        {
            switch (Classify(selected))
            {
                case AICodedbRuntimeGenerationDisposition.Current:
                    return TargetStableWrapperSha256;
                case AICodedbRuntimeGenerationDisposition.TrustedPrevious:
                    AICodedbRuntimeTransition transition;
                    if (TryGetTransition(selected, out transition))
                        return transition.StableWrapperSha256;
                    break;
            }

            throw new InvalidOperationException(
                "Selected runtime identity has no Package-owned stable-wrapper identity.");
        }

    }

    internal static class AICodedbPackageRuntimeContractStore
    {
        private const string ManagedBy = "com.rice.ai-codedb";
        internal const string StableWrapperRelativePath = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs";
        private const long MaximumBytes = 4 * 1024 * 1024;

        internal static AICodedbPackageRuntimeContract Read(string packageRoot)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(packageRoot).TrimEnd('/');
            if (!Directory.Exists(normalizedRoot)
                || (File.GetAttributes(normalizedRoot) & FileAttributes.ReparsePoint) != 0)
                throw new InvalidOperationException("Resolved Package root is unavailable for runtime-contract validation.");

            var manifestPath = AICodedbPaths.NormalizePath(Path.Combine(
                normalizedRoot,
                "Payload~",
                "payload-manifest.json"));
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, manifestPath);
            var bytes = ReadBoundedBytes(manifestPath, MaximumBytes);
            string text;
            try
            {
                text = new UTF8Encoding(false, true).GetString(bytes);
            }
            catch (DecoderFallbackException exception)
            {
                throw new InvalidOperationException("Package runtime contract is not strict UTF-8.", exception);
            }
            if (bytes.Length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf)
                throw new InvalidOperationException("Package runtime contract must be UTF-8 without a byte-order mark.");

            const string label = "Package runtime contract";
            var document = AICodedbStrictJson.ParseObject(text, label);
            if (AICodedbStrictJson.GetRequiredInt32(document, "schema_version", label) != 1
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(document, "managed_by", label),
                    ManagedBy,
                    StringComparison.Ordinal))
                throw new InvalidOperationException("Package runtime contract schema or owner is invalid.");

            var controlContract = ReadControlContract(document, label);
            var target = ReadIdentity(document, string.Empty, label);
            ValidateIdentity(target, true, target.PayloadSequence);
            var targetStableWrapperSha256 = ReadTargetStableWrapperSha256(
                document,
                normalizedRoot,
                label);
            var transitions = new List<AICodedbRuntimeTransition>();
            foreach (var value in AICodedbStrictJson.GetRequiredArray(document, "bootstrap_transitions", label))
            {
                var transition = AICodedbStrictJson.RequireObject(value, "Package runtime transition");
                var identity = ReadIdentity(transition, "source_", "Package runtime transition");
                ValidateIdentity(identity, false, target.PayloadSequence);
                var sourceTag = AICodedbStrictJson.GetRequiredString(
                    transition,
                    "source_tag",
                    "Package runtime transition");
                var sourceMarkerSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                    transition,
                    "source_marker_schema_version",
                    "Package runtime transition");
                var sourceHostUseGateVersion = AICodedbStrictJson.GetRequiredInt32(
                    transition,
                    "source_host_use_gate_version",
                    "Package runtime transition");
                var sourceGenerationLeaseVersion = AICodedbStrictJson.GetRequiredInt32(
                    transition,
                    "source_generation_lease_version",
                    "Package runtime transition");
                var sourceFlatFileCount = AICodedbStrictJson.GetRequiredInt32(
                    transition,
                    "source_flat_file_count",
                    "Package runtime transition");
                var sourceFlatClosureSha256 = AICodedbStrictJson.GetRequiredString(
                    transition,
                    "source_flat_closure_sha256",
                    "Package runtime transition").ToLowerInvariant();
                if (sourceMarkerSchemaVersion < 1
                    || sourceHostUseGateVersion < 1
                    || sourceGenerationLeaseVersion < 2
                    || sourceFlatFileCount < 1
                    || !IsSourceTag(sourceTag))
                {
                    throw new InvalidOperationException("Package runtime transition metadata is invalid.");
                }
                ValidateSha256(sourceFlatClosureSha256, "Package runtime transition flat closure");
                var stableWrapperSha256 = AICodedbStrictJson.GetRequiredString(
                    transition,
                    "source_stable_wrapper_sha256",
                    "Package runtime transition").ToLowerInvariant();
                ValidateSha256(
                    stableWrapperSha256,
                    "Package runtime transition stable wrapper");
                transitions.Add(new AICodedbRuntimeTransition(
                    identity,
                    sourceTag,
                    sourceMarkerSchemaVersion,
                    sourceHostUseGateVersion,
                    sourceGenerationLeaseVersion,
                    sourceFlatFileCount,
                    sourceFlatClosureSha256,
                    stableWrapperSha256));
            }

            return new AICodedbPackageRuntimeContract(
                target,
                controlContract,
                GetSha256(bytes),
                targetStableWrapperSha256,
                transitions);
        }

        private static AICodedbControlContractIdentity ReadControlContract(
            Dictionary<string, object> document,
            string label)
        {
            object value;
            if (!document.TryGetValue("control_contract", out value))
                throw new InvalidOperationException(label + " is missing required property control_contract.");

            var controlDocument = AICodedbStrictJson.RequireObject(value, "Package control contract");
            var id = AICodedbStrictJson.GetRequiredString(
                controlDocument,
                "id",
                "Package control contract");
            var version = AICodedbStrictJson.GetRequiredInt32(
                controlDocument,
                "version",
                "Package control contract");
            var schemaVersion = AICodedbStrictJson.GetRequiredInt32(
                controlDocument,
                "schema_version",
                "Package control contract");
            var sha256 = AICodedbStrictJson.GetRequiredString(
                controlDocument,
                "sha256",
                "Package control contract").ToLowerInvariant();

            if (!AICodedbControlContract.IsValidId(id)
                || version <= 0
                || schemaVersion != AICodedbControlContractIdentity.CurrentSchemaVersion
                || !AICodedbControlContract.IsSha256(sha256))
            {
                throw new InvalidOperationException("Package control contract identity is invalid.");
            }

            var identity = new AICodedbControlContractIdentity(
                id,
                version,
                schemaVersion,
                sha256);
            if (!identity.IsValid)
                throw new InvalidOperationException("Package control contract identity hash is invalid.");
            return identity;
        }

        private static string ReadTargetStableWrapperSha256(
            Dictionary<string, object> document,
            string packageRoot,
            string label)
        {
            var files = AICodedbStrictJson.GetRequiredArray(document, "files", label);
            var seenTargets = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            string stableWrapperSha256 = null;
            foreach (var value in files)
            {
                var entry = AICodedbStrictJson.RequireObject(value, "Package runtime file");
                var source = AICodedbStrictJson.GetRequiredString(entry, "source", "Package runtime file");
                var target = AICodedbStrictJson.GetRequiredString(entry, "target", "Package runtime file");
                var hash = AICodedbStrictJson.GetRequiredString(entry, "sha256", "Package runtime file").ToLowerInvariant();
                ValidateSha256(hash, "Package runtime file");
                if (!seenTargets.Add(target))
                    throw new InvalidOperationException("Package runtime contract contains a duplicate target path.");
                if (!string.Equals(target, StableWrapperRelativePath, StringComparison.Ordinal))
                    continue;
                if (!string.Equals(source, StableWrapperRelativePath, StringComparison.Ordinal))
                    throw new InvalidOperationException("Package runtime stable-wrapper source path is invalid.");
                stableWrapperSha256 = hash;
            }

            if (string.IsNullOrEmpty(stableWrapperSha256))
                throw new InvalidOperationException("Package runtime contract does not declare the stable wrapper.");

            var wrapperPath = AICodedbPaths.NormalizePath(Path.Combine(
                packageRoot,
                "Payload~",
                StableWrapperRelativePath));
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(packageRoot, wrapperPath);
            if (!File.Exists(wrapperPath)
                || !string.Equals(GetSha256(wrapperPath), stableWrapperSha256, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Package runtime stable wrapper bytes do not match its manifest identity.");
            }
            return stableWrapperSha256;
        }

        private static AICodedbRuntimeIdentity ReadIdentity(
            Dictionary<string, object> document,
            string prefix,
            string label)
        {
            return new AICodedbRuntimeIdentity(
                AICodedbStrictJson.GetRequiredString(document, prefix + "package_version", label),
                AICodedbStrictJson.GetRequiredString(document, prefix + "payload_version", label),
                AICodedbStrictJson.GetRequiredInt32(document, prefix + "payload_sequence", label),
                AICodedbStrictJson.GetRequiredString(document, prefix + "generation_id", label),
                AICodedbStrictJson.GetRequiredInt32(document, prefix + "bootstrap_protocol", label));
        }

        private static void ValidateIdentity(
            AICodedbRuntimeIdentity identity,
            bool current,
            int currentSequence)
        {
            if (string.IsNullOrWhiteSpace(identity.PackageVersion)
                || string.IsNullOrWhiteSpace(identity.PayloadVersion)
                || !IsGenerationId(identity.GenerationId)
                || identity.PayloadSequence < 1
                || identity.BootstrapProtocol < 1
                || (!current && identity.PayloadSequence >= currentSequence))
                throw new InvalidOperationException("Package runtime contract contains an invalid runtime identity.");
        }

        private static bool IsGenerationId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 64)
                return false;
            foreach (var character in value)
            {
                if ((character >= 'A' && character <= 'Z')
                    || (character >= 'a' && character <= 'z')
                    || (character >= '0' && character <= '9')
                    || character == '.'
                    || character == '_'
                    || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        private static bool IsSourceTag(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 128 || value[0] != 'v')
                return false;
            for (var index = 1; index < value.Length; index++)
            {
                var character = value[index];
                if ((character >= 'A' && character <= 'Z')
                    || (character >= 'a' && character <= 'z')
                    || (character >= '0' && character <= '9')
                    || character == '.'
                    || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        internal static void ValidateProjectStableWrapper(
            string projectRoot,
            string expectedSha256)
        {
            ValidateSha256(expectedSha256, "Project stable wrapper");
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            var wrapperPath = AICodedbPaths.NormalizePath(Path.Combine(
                normalizedRoot,
                StableWrapperRelativePath));
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, wrapperPath);
            if (!File.Exists(wrapperPath)
                || !string.Equals(GetSha256(wrapperPath), expectedSha256, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    "Project stable wrapper bytes do not match the Package-owned runtime identity.");
            }
        }

        private static void ValidateSha256(string value, string label)
        {
            if (string.IsNullOrEmpty(value) || value.Length != 64)
                throw new InvalidOperationException(label + " SHA-256 is invalid.");
            foreach (var character in value)
            {
                if (!((character >= '0' && character <= '9')
                      || (character >= 'a' && character <= 'f')))
                    throw new InvalidOperationException(label + " SHA-256 is invalid.");
            }
        }

        private static byte[] ReadBoundedBytes(string path, long maximumBytes)
        {
            using (var stream = new FileStream(
                       path,
                       FileMode.Open,
                       FileAccess.Read,
                       FileShare.Read,
                       4096,
                       FileOptions.SequentialScan))
            {
                if (stream.Length <= 0 || stream.Length > maximumBytes || stream.Length > int.MaxValue)
                    throw new InvalidOperationException("Package runtime contract size is outside the accepted range.");
                var bytes = new byte[(int)stream.Length];
                var offset = 0;
                while (offset < bytes.Length)
                {
                    var count = stream.Read(bytes, offset, bytes.Length - offset);
                    if (count <= 0)
                        throw new InvalidOperationException("Package runtime contract could not be read completely.");
                    offset += count;
                }
                if (stream.ReadByte() != -1)
                    throw new InvalidOperationException("Package runtime contract changed while it was read.");
                return bytes;
            }
        }

        private static string GetSha256(byte[] bytes)
        {
            using (var algorithm = SHA256.Create())
            {
                var hash = algorithm.ComputeHash(bytes);
                var builder = new StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return builder.ToString();
            }
        }

        private static string GetSha256(string path)
        {
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var algorithm = SHA256.Create())
            {
                var hash = algorithm.ComputeHash(stream);
                var builder = new StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return builder.ToString();
            }
        }

    }
}
