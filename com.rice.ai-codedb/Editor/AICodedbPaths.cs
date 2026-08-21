using System;
using System.IO;
using UnityEditor.PackageManager;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal readonly struct AICodedbEditorExecutionContext
    {
        internal RuntimePlatform Platform { get; }
        internal string ProjectRoot { get; }
        internal string PackageRoot { get; }
        internal string ProjectDisplayName { get; }
        internal string ProviderSlug { get; }

        internal AICodedbEditorExecutionContext(
            RuntimePlatform platform,
            string projectRoot,
            string packageRoot,
            string projectDisplayName)
        {
            Platform = platform;
            ProjectRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\');
            PackageRoot = AICodedbPaths.NormalizePath(packageRoot).TrimEnd('/', '\\');
            ProjectDisplayName = string.IsNullOrWhiteSpace(projectDisplayName)
                ? "UnityProject"
                : projectDisplayName;
            ProviderSlug = "codedb-" + AICodedbProjectSettings.CreateSlug(ProjectDisplayName);
        }

        internal string RuntimeRelativePath => "AIWork/.runtime/codedb/" + ProviderSlug;
        internal string InstanceDesiredStateRelativePath => AICodedbProjectSettings.InstanceDesiredStateRelativePath;
        internal string InstanceCurrentRelativePath => AICodedbProjectSettings.InstanceCurrentRelativePath;
        internal string MachineProviderExecutablePath => AICodedbPaths.GetMachineProviderExecutablePath();
        internal string ProviderConfigRelativePath => RuntimeRelativePath + "/config/codedb-mcp.toml";
        internal string WatchCoordinatorRuntimeRelativePath => RuntimeRelativePath + "/watch/coordinator";
        internal string WatchLifecycleRelativePath => RuntimeRelativePath + "/watch/lifecycle";
        internal string WatchDesiredStateRelativePath => WatchLifecycleRelativePath + "/desired-state.json";
        internal string WatchEditorLeasesRelativePath => WatchLifecycleRelativePath + "/editor-leases";
        internal string IndexRelativePath => RuntimeRelativePath + "/index";
        internal string IndexManifestRelativePath => IndexRelativePath + "/manifest.json";
        internal string TextAdapterRelativePath => RuntimeRelativePath + "/adapter/text-index";
        internal string TextAdapterManifestRelativePath => TextAdapterRelativePath + "/manifest.json";

        internal string GetProjectPath(string relativePath)
        {
            return string.IsNullOrWhiteSpace(relativePath)
                ? ProjectRoot
                : AICodedbPaths.NormalizePath(Path.Combine(ProjectRoot, relativePath));
        }
    }

    internal static class AICodedbPaths
    {
        internal static string ProjectRoot => NormalizePath(Path.Combine(Application.dataPath, ".."));
        internal static string PackageRootPath => ResolvePackageRootPath();
        internal static string HostPayloadMarkerPath => GetProjectPath(AICodedbProjectSettings.HostPayloadMarkerRelativePath);
        internal static string HostCurrentPointerPath => GetProjectPath(AICodedbProjectSettings.HostCurrentPointerRelativePath);
        internal static string HostLastKnownGoodPointerPath => GetProjectPath(AICodedbProjectSettings.HostLastKnownGoodPointerRelativePath);
        internal static string HostUpdatePolicyPath => GetProjectPath(AICodedbProjectSettings.HostUpdatePolicyRelativePath);
        internal static string HostPayloadMaterializerRuntimePath => GetProjectPath(AICodedbProjectSettings.HostPayloadMaterializerRuntimeRelativePath);
        internal static string HostPayloadUpgradeStatePath => GetProjectPath(AICodedbProjectSettings.HostPayloadUpgradeStateRelativePath);
        internal static string ProjectIntegrationStatePath => GetProjectPath(AICodedbProjectSettings.ProjectIntegrationStateRelativePath);
        internal static string InstanceDesiredStatePath => GetProjectPath(AICodedbProjectSettings.InstanceDesiredStateRelativePath);
        internal static string InstanceCurrentPath => GetProjectPath(AICodedbProjectSettings.InstanceCurrentRelativePath);
        internal static string McpAvailabilityStatePath => GetProjectPath(AICodedbProjectSettings.McpAvailabilityStateRelativePath);
        internal static string HostPayloadMaterializerScriptPath => NormalizePath(Path.Combine(PackageRootPath, AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
        internal static string ProviderInstallerScriptPath => NormalizePath(Path.Combine(PackageRootPath, AICodedbProjectSettings.ProviderInstallerScriptPackageRelativePath));
        internal static string ProviderDistributionManifestPath => NormalizePath(Path.Combine(PackageRootPath, AICodedbProjectSettings.ProviderDistributionManifestPackageRelativePath));
        internal static string RuntimePath => GetProjectPath(AICodedbProjectSettings.RuntimeRelativePath);
        internal static string ProviderExecutablePath => GetMachineProviderExecutablePath();
        internal static string ProviderConfigPath => GetProjectPath(AICodedbProjectSettings.ProviderConfigRelativePath);
        internal static string WatchConfigPath => GetProjectPath(AICodedbProjectSettings.WatchConfigRelativePath);
        internal static string WatchCoordinatorRuntimePath => GetProjectPath(AICodedbProjectSettings.WatchCoordinatorRuntimeRelativePath);
        internal static string WatchCoordinatorStatePath => Path.Combine(WatchCoordinatorRuntimePath, "coordinator-state.json");
        internal static string WatchLifecyclePath => GetProjectPath(AICodedbProjectSettings.WatchLifecycleRelativePath);
        internal static string WatchDesiredStatePath => GetProjectPath(AICodedbProjectSettings.WatchDesiredStateRelativePath);
        internal static string WatchManualRuntimePath => Path.Combine(WatchLifecyclePath, "manual-runtime.json");
        internal static string WatchEditorLeasesPath => GetProjectPath(AICodedbProjectSettings.WatchEditorLeasesRelativePath);
        internal static string WatchEnabledMarkerPath => GetProjectPath(AICodedbProjectSettings.WatchEnabledMarkerRelativePath);
        internal static string WatchPausedMarkerPath => GetProjectPath(AICodedbProjectSettings.WatchPausedMarkerRelativePath);
        internal static string IndexPath => GetProjectPath(AICodedbProjectSettings.IndexRelativePath);
        internal static string IndexManifestPath => GetProjectPath(AICodedbProjectSettings.IndexManifestRelativePath);
        internal static string TextAdapterPath => GetProjectPath(AICodedbProjectSettings.TextAdapterRelativePath);
        internal static string TextAdapterManifestPath => GetProjectPath(AICodedbProjectSettings.TextAdapterManifestRelativePath);
        internal static string ProjectMcpConfigPath => GetProjectPath(AICodedbProjectSettings.ProjectMcpConfigRelativePath);
        internal static string RuntimeConfigTemplatePath => GetHostPath("codedb-mcp.runtime.example.toml", AICodedbProjectSettings.RuntimeConfigTemplateRelativePath);
        internal static string RefreshScriptPath => GetHostPath("scripts/refresh-codedb-project.ps1", AICodedbProjectSettings.RefreshScriptRelativePath);
        internal static string CleanIndexScriptPath => GetHostPath("scripts/clear-codedb-project-index.ps1", AICodedbProjectSettings.CleanIndexScriptRelativePath);
        internal static string PrepareRuntimeScriptPath => GetHostPath("scripts/prepare-codedb-project-runtime.ps1", AICodedbProjectSettings.PrepareRuntimeScriptRelativePath);
        internal static string ProviderGuidanceScriptPath => GetHostPath("scripts/show-codedb-project-provider-guidance.ps1", AICodedbProjectSettings.ProviderGuidanceScriptRelativePath);
        internal static string VerifyScriptPath => GetHostPath("scripts/verify-codedb-project.ps1", AICodedbProjectSettings.VerifyScriptRelativePath);
        internal static string IndexProbeScriptPath => GetHostPath("scripts/probe-codedb-project-index.ps1", AICodedbProjectSettings.IndexProbeScriptRelativePath);
        internal static string FreshnessScriptPath => GetHostPath("scripts/check-codedb-project-freshness.ps1", AICodedbProjectSettings.FreshnessScriptRelativePath);
        internal static string RefreshIfStaleScriptPath => GetHostPath("scripts/refresh-codedb-project-if-stale.ps1", AICodedbProjectSettings.RefreshIfStaleScriptRelativePath);
        internal static string WatchManageScriptPath => GetHostPath("scripts/manage-codedb-project-watch.ps1", AICodedbProjectSettings.WatchManageScriptRelativePath);
        internal static string TextAdapterBuildScriptPath => GetHostPath("scripts/build-codedb-project-text-adapter.ps1", AICodedbProjectSettings.TextAdapterBuildScriptRelativePath);
        internal static string TextAdapterProbeScriptPath => GetHostPath("scripts/probe-codedb-project-text-adapter.ps1", AICodedbProjectSettings.TextAdapterProbeScriptRelativePath);
        internal static string RegistrationDraftScriptPath => GetHostPath("scripts/emit-codedb-mcp-registration-draft.ps1", AICodedbProjectSettings.RegistrationDraftScriptRelativePath);
        internal static string RegistrationValidateScriptPath => GetHostPath("scripts/validate-codedb-mcp-project-config.ps1", AICodedbProjectSettings.RegistrationValidateScriptRelativePath);

        internal static AICodedbHostGenerationSelection HostGeneration => AICodedbHostGenerationStore.Resolve(ProjectRoot);

        internal static AICodedbEditorExecutionContext CaptureExecutionContext()
        {
            var projectRoot = ProjectRoot;
            var projectName = new DirectoryInfo(projectRoot).Name;
            return new AICodedbEditorExecutionContext(
                Application.platform,
                projectRoot,
                PackageRootPath,
                projectName);
        }

        /// <summary>
        /// Converts a Unity-project-relative path into a normalized absolute path.
        /// </summary>
        /// <param name="relativePath">Unity-project-relative path.</param>
        internal static string GetProjectPath(string relativePath)
        {
            if (string.IsNullOrWhiteSpace(relativePath))
                return ProjectRoot;

            return NormalizePath(Path.Combine(ProjectRoot, relativePath));
        }

        internal static string GetMachineProviderExecutablePath()
        {
            var localAppData = Environment.GetEnvironmentVariable(
                "LOCALAPPDATA",
                EnvironmentVariableTarget.Process);
            if (string.IsNullOrWhiteSpace(localAppData))
                localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            if (string.IsNullOrWhiteSpace(localAppData))
                return string.Empty;
            return NormalizePath(Path.Combine(
                localAppData,
                "Rice",
                "CodeDB",
                "providers",
                AICodedbProjectSettings.MachineProviderVersion,
                "codebase-mcp.exe"));
        }

        private static string GetHostPath(string generationRelativePath, string legacyRelativePath)
        {
            return AICodedbHostGenerationStore.ResolveHostPath(ProjectRoot, generationRelativePath, legacyRelativePath);
        }

        /// <summary>
        /// Returns whether an absolute path stays inside the Unity project root.
        /// </summary>
        /// <param name="absolutePath">Absolute path to validate.</param>
        internal static bool IsInsideProject(string absolutePath)
        {
            if (string.IsNullOrWhiteSpace(absolutePath))
                return false;

            var normalizedPath = NormalizePath(absolutePath);
            var normalizedRoot = ProjectRoot.TrimEnd('/', '\\');
            var rootPrefix = normalizedRoot + "/";

            return string.Equals(normalizedPath, normalizedRoot, StringComparison.OrdinalIgnoreCase)
                   || normalizedPath.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Converts a path to project-relative display text when possible.
        /// </summary>
        /// <param name="path">Path to convert.</param>
        internal static string ToProjectRelativeDisplayPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return string.Empty;

            var normalizedPath = NormalizePath(path);
            var normalizedRoot = ProjectRoot.TrimEnd('/', '\\');
            var rootPrefix = normalizedRoot + "/";

            if (normalizedPath.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase))
                return normalizedPath.Substring(rootPrefix.Length);

            return normalizedPath;
        }

        /// <summary>
        /// Normalizes a path into a full path with forward slashes for comparison.
        /// </summary>
        /// <param name="path">Path to normalize.</param>
        internal static string NormalizePath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return string.Empty;

            return Path.GetFullPath(path).Replace('\\', '/');
        }

        /// <summary>
        /// Resolves the physical package root selected by Unity Package Manager.
        /// </summary>
        private static string ResolvePackageRootPath()
        {
            var packageInfo = PackageInfo.FindForAssembly(typeof(AICodedbPaths).Assembly);
            if (packageInfo == null
                || !string.Equals(packageInfo.name, AICodedbProjectSettings.PackageName, StringComparison.Ordinal)
                || string.IsNullOrWhiteSpace(packageInfo.resolvedPath)
                || !Path.IsPathRooted(packageInfo.resolvedPath))
                throw new InvalidOperationException(
                    "Unity Package Manager did not provide the expected resolved CodeDB Package identity and path.");

            return NormalizePath(packageInfo.resolvedPath);
        }
    }
}
