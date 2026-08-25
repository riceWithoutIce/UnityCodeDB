using System.IO;
using System.Security.Cryptography;
using System.Text;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbProjectSettings
    {
        internal const string PackageName = "com.rice.ai-codedb";
        internal const string DisplayName = "Rice AI Codedb";
        internal const string MenuRoot = "Tools/Rice AI/Codedb/";
        internal const string DefaultToolProfile = "Discover Read";
        internal const string CurrentPackageVersion = "0.2.5-preview.5";
        internal const string CurrentPayloadVersion = "poc.33";
        internal const string CurrentGenerationId = "poc.33";
        internal const int CurrentPayloadSequence = 33;
        internal const int CurrentBootstrapProtocol = 1;
        internal const string MachineProviderVersion = "0.5.0-28e3912";
        internal const string LegacyPackageVersion = "0.2.2";
        internal const string LegacyPayloadVersion = "poc.21";
        internal const int LegacyPayloadSequence = 21;

        internal static string ProjectDisplayName => GetUnityProjectName();
        internal static string ProjectSlug => CreateSlug(ProjectDisplayName);
        internal static string ProviderSlug => "codedb-" + ProjectSlug;

        internal static string RuntimeRelativePath => "AIWork/.runtime/codedb/" + ProviderSlug;
        internal static string ScriptRootRelativePath => "AIWork/codedb/scripts";
        internal static string LegacyHostRootRelativePath => "AIWork/codedb";
        internal static string HostPayloadMarkerRelativePath => "AIWork/codedb/.rice-ai-codedb-payload.json";
        internal static string HostRuntimeRelativePath => "AIWork/.runtime/codedb/host";
        internal static string HostGenerationsRelativePath => HostRuntimeRelativePath + "/generations";
        internal static string HostCurrentPointerRelativePath => HostRuntimeRelativePath + "/current.json";
        internal static string HostLastKnownGoodPointerRelativePath => HostRuntimeRelativePath + "/last-known-good.json";
        internal static string HostUpdatePolicyRelativePath => HostRuntimeRelativePath + "/update-policy.json";
        internal static string HostUnavailableRelativePath => HostRuntimeRelativePath + "/unavailable";
        internal static string HostPayloadMaterializerRuntimeRelativePath => "AIWork/.runtime/codedb/payload-materializer";
        internal static string HostPayloadUpgradeStateRelativePath => HostPayloadMaterializerRuntimeRelativePath + "/upgrade-state.json";
        internal static string ProjectIntegrationStateRelativePath => HostPayloadMaterializerRuntimeRelativePath + "/integration-state.json";
        internal static string McpAvailabilityStateRelativePath => HostPayloadMaterializerRuntimeRelativePath + "/mcp-availability.json";
        internal static string InstanceControlRelativePath => "AIWork/.runtime/codedb/control";
        internal static string InstanceDesiredStateRelativePath => InstanceControlRelativePath + "/desired-state.json";
        internal static string InstanceCurrentRelativePath => InstanceControlRelativePath + "/current-instance.json";
        internal static string InstancesRelativePath => "AIWork/.runtime/codedb/instances";
        internal static string HostPayloadMaterializerScriptPackageRelativePath => "Tools~/materialize-codedb-host-payload.ps1";
        internal static string ProviderInstallerScriptPackageRelativePath => "Tools~/install-codedb-provider.ps1";
        internal static string ProviderDistributionManifestPackageRelativePath => "Tools~/codedb-provider-distribution.json";
        internal static string ProviderConfigRelativePath => RuntimeRelativePath + "/config/codedb-mcp.toml";
        internal static string WatchConfigRelativePath => RuntimeRelativePath + "/config/codedb-mcp.watch.toml";
        internal static string WatchRuntimeRelativePath => RuntimeRelativePath + "/watch";
        internal static string WatchCoordinatorRuntimeRelativePath => WatchRuntimeRelativePath + "/coordinator";
        internal static string WatchLifecycleRelativePath => WatchRuntimeRelativePath + "/lifecycle";
        internal static string WatchDesiredStateRelativePath => WatchLifecycleRelativePath + "/desired-state.json";
        internal static string WatchEditorLeasesRelativePath => WatchLifecycleRelativePath + "/editor-leases";
        internal static string WatchEnabledMarkerRelativePath => WatchRuntimeRelativePath + "/auto-start.json";
        internal static string WatchPausedMarkerRelativePath => WatchRuntimeRelativePath + "/automatic-refresh-paused.json";
        internal static string IndexRelativePath => RuntimeRelativePath + "/index";
        internal static string IndexManifestRelativePath => IndexRelativePath + "/manifest.json";
        internal static string TextAdapterRelativePath => RuntimeRelativePath + "/adapter/text-index";
        internal static string TextAdapterManifestRelativePath => TextAdapterRelativePath + "/manifest.json";
        internal static string McpWrapperScriptRelativePath => "AIWork/codedb/wrapper/codedb-project-wrapper.mjs";
        internal static string ProjectMcpConfigRelativePath => ".codex/config.toml";
        internal static string RuntimeConfigTemplateRelativePath => "AIWork/codedb/codedb-mcp.runtime.example.toml";
        internal static string RefreshScriptRelativePath => "AIWork/codedb/scripts/refresh-codedb-project.ps1";
        internal static string CleanIndexScriptRelativePath => "AIWork/codedb/scripts/clear-codedb-project-index.ps1";
        internal static string PrepareRuntimeScriptRelativePath => "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1";
        internal static string ProviderGuidanceScriptRelativePath => "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1";
        internal static string VerifyScriptRelativePath => "AIWork/codedb/scripts/verify-codedb-project.ps1";
        internal static string IndexProbeScriptRelativePath => "AIWork/codedb/scripts/probe-codedb-project-index.ps1";
        internal static string FreshnessScriptRelativePath => "AIWork/codedb/scripts/check-codedb-project-freshness.ps1";
        internal static string RefreshIfStaleScriptRelativePath => "AIWork/codedb/scripts/refresh-codedb-project-if-stale.ps1";
        internal static string WatchManageScriptRelativePath => "AIWork/codedb/scripts/manage-codedb-project-watch.ps1";
        internal static string TextAdapterBuildScriptRelativePath => "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1";
        internal static string TextAdapterProbeScriptRelativePath => "AIWork/codedb/scripts/probe-codedb-project-text-adapter.ps1";
        internal static string RegistrationDraftScriptRelativePath => "AIWork/codedb/scripts/emit-codedb-mcp-registration-draft.ps1";
        internal static string RegistrationValidateScriptRelativePath => "AIWork/codedb/scripts/validate-codedb-mcp-project-config.ps1";

        /// <summary>
        /// Builds the reviewed project-level Codex MCP registration snippet.
        /// </summary>
        internal static string BuildProjectMcpRegistrationSnippet()
        {
            var builder = new StringBuilder();
            builder.AppendLine("[mcp_servers." + ProviderSlug + "]");
            builder.AppendLine("command = \"node\"");
            builder.AppendLine("cwd = \".\"");
            builder.AppendLine("args = [\"" + McpWrapperScriptRelativePath + "\", \"--root\", \".\"]");
            builder.Append("startup_timeout_sec = 120");
            return builder.ToString();
        }

        private static string GetUnityProjectName()
        {
            var projectRoot = Path.GetFullPath(Path.Combine(Application.dataPath, ".."));
            // Project settings are also read while a background status
            // snapshot is assembled. Derive the display name from the path so
            // this helper does not perform directory metadata I/O.
            var projectName = Path.GetFileName(projectRoot.TrimEnd('/', '\\'));
            return string.IsNullOrWhiteSpace(projectName) ? "UnityProject" : projectName;
        }

        internal static string CreateSlug(string value)
        {
            var normalizedValue = (value ?? string.Empty).Normalize(NormalizationForm.FormC);
            var builder = new StringBuilder();
            var previousWasSeparator = false;
            var containsNonAscii = false;

            foreach (var character in normalizedValue)
            {
                if (character > 0x7f)
                    containsNonAscii = true;

                if ((character >= 'A' && character <= 'Z')
                    || (character >= 'a' && character <= 'z')
                    || (character >= '0' && character <= '9'))
                {
                    builder.Append(char.ToLowerInvariant(character));
                    previousWasSeparator = false;
                    continue;
                }

                if (previousWasSeparator || builder.Length == 0)
                    continue;

                builder.Append('-');
                previousWasSeparator = true;
            }

            while (builder.Length > 0 && builder[builder.Length - 1] == '-')
                builder.Length--;

            var result = builder.Length == 0 ? "unity-project" : builder.ToString();
            var requiresHash = containsNonAscii;
            if (result.Length > 96)
            {
                result = result.Substring(0, 96).TrimEnd('-');
                requiresHash = true;
            }

            if (!requiresHash)
                return result;

            using (var sha256 = SHA256.Create())
            {
                var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(normalizedValue));
                var hashBuilder = new StringBuilder(12);
                for (var index = 0; index < 6; index++)
                    hashBuilder.Append(hash[index].ToString("x2"));
                return result + "-" + hashBuilder;
            }
        }
    }
}
