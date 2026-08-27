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

    internal sealed class AICodedbPackageRuntimeContract
    {
        private readonly HashSet<string> _transitionKeys;

        internal AICodedbRuntimeIdentity Target { get; }
        internal string Sha256 { get; }

        internal AICodedbPackageRuntimeContract(
            AICodedbRuntimeIdentity target,
            string sha256,
            IEnumerable<AICodedbRuntimeIdentity> transitions)
        {
            Target = target;
            Sha256 = sha256 ?? string.Empty;
            _transitionKeys = new HashSet<string>(StringComparer.Ordinal);
            foreach (var transition in transitions)
            {
                if (!_transitionKeys.Add(transition.GetStableKey()))
                    throw new InvalidOperationException("Package runtime contract contains a duplicate transition.");
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
            return _transitionKeys.Contains(selected.GetStableKey())
                ? AICodedbRuntimeGenerationDisposition.TrustedPrevious
                : AICodedbRuntimeGenerationDisposition.Invalid;
        }
    }

    internal static class AICodedbPackageRuntimeContractStore
    {
        private const string ManagedBy = "com.rice.ai-codedb";
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

            var target = ReadIdentity(document, string.Empty, label);
            ValidateIdentity(target, true, target.PayloadSequence);
            var transitions = new List<AICodedbRuntimeIdentity>();
            foreach (var value in AICodedbStrictJson.GetRequiredArray(document, "bootstrap_transitions", label))
            {
                var transition = AICodedbStrictJson.RequireObject(value, "Package runtime transition");
                var identity = ReadIdentity(transition, "source_", "Package runtime transition");
                ValidateIdentity(identity, false, target.PayloadSequence);
                ValidateSha256(
                    AICodedbStrictJson.GetRequiredString(
                        transition,
                        "source_stable_wrapper_sha256",
                        "Package runtime transition"),
                    "Package runtime transition stable wrapper");
                transitions.Add(identity);
            }

            return new AICodedbPackageRuntimeContract(target, GetSha256(bytes), transitions);
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
    }
}
