using System;
using System.IO;
using UnityEditor.PackageManager;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbPaths
    {
        internal static string ProjectRoot => NormalizePath(Path.Combine(Application.dataPath, ".."));
        internal static string PackageRootPath => ResolvePackageRootPath();
        internal static string HostPayloadMarkerPath => GetProjectPath(AICodedbProjectSettings.HostPayloadMarkerRelativePath);
        internal static string HostPayloadMaterializerRuntimePath => GetProjectPath(AICodedbProjectSettings.HostPayloadMaterializerRuntimeRelativePath);
        internal static string TrackedHostAuthorizationPath => GetProjectPath(AICodedbProjectSettings.TrackedHostAuthorizationRelativePath);
        internal static string HostPayloadMaterializerScriptPath => NormalizePath(Path.Combine(PackageRootPath, AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
        internal static string RuntimePath => GetProjectPath(AICodedbProjectSettings.RuntimeRelativePath);
        internal static string ProviderExecutablePath => GetProjectPath(AICodedbProjectSettings.ProviderExecutableRelativePath);
        internal static string ProviderConfigPath => GetProjectPath(AICodedbProjectSettings.ProviderConfigRelativePath);
        internal static string WatchConfigPath => GetProjectPath(AICodedbProjectSettings.WatchConfigRelativePath);
        internal static string WatchCoordinatorRuntimePath => GetProjectPath(AICodedbProjectSettings.WatchCoordinatorRuntimeRelativePath);
        internal static string WatchCoordinatorStatePath => Path.Combine(WatchCoordinatorRuntimePath, "coordinator-state.json");
        internal static string WatchEnabledMarkerPath => GetProjectPath(AICodedbProjectSettings.WatchEnabledMarkerRelativePath);
        internal static string IndexPath => GetProjectPath(AICodedbProjectSettings.IndexRelativePath);
        internal static string IndexManifestPath => GetProjectPath(AICodedbProjectSettings.IndexManifestRelativePath);
        internal static string TextAdapterPath => GetProjectPath(AICodedbProjectSettings.TextAdapterRelativePath);
        internal static string TextAdapterManifestPath => GetProjectPath(AICodedbProjectSettings.TextAdapterManifestRelativePath);
        internal static string ProjectMcpConfigPath => GetProjectPath(AICodedbProjectSettings.ProjectMcpConfigRelativePath);
        internal static string RuntimeConfigTemplatePath => GetProjectPath(AICodedbProjectSettings.RuntimeConfigTemplateRelativePath);
        internal static string RefreshScriptPath => GetProjectPath(AICodedbProjectSettings.RefreshScriptRelativePath);
        internal static string CleanIndexScriptPath => GetProjectPath(AICodedbProjectSettings.CleanIndexScriptRelativePath);
        internal static string PrepareRuntimeScriptPath => GetProjectPath(AICodedbProjectSettings.PrepareRuntimeScriptRelativePath);
        internal static string ProviderGuidanceScriptPath => GetProjectPath(AICodedbProjectSettings.ProviderGuidanceScriptRelativePath);
        internal static string VerifyScriptPath => GetProjectPath(AICodedbProjectSettings.VerifyScriptRelativePath);
        internal static string IndexProbeScriptPath => GetProjectPath(AICodedbProjectSettings.IndexProbeScriptRelativePath);
        internal static string FreshnessScriptPath => GetProjectPath(AICodedbProjectSettings.FreshnessScriptRelativePath);
        internal static string RefreshIfStaleScriptPath => GetProjectPath(AICodedbProjectSettings.RefreshIfStaleScriptRelativePath);
        internal static string WatchManageScriptPath => GetProjectPath(AICodedbProjectSettings.WatchManageScriptRelativePath);
        internal static string TextAdapterBuildScriptPath => GetProjectPath(AICodedbProjectSettings.TextAdapterBuildScriptRelativePath);
        internal static string TextAdapterProbeScriptPath => GetProjectPath(AICodedbProjectSettings.TextAdapterProbeScriptRelativePath);
        internal static string RegistrationDraftScriptPath => GetProjectPath(AICodedbProjectSettings.RegistrationDraftScriptRelativePath);
        internal static string RegistrationValidateScriptPath => GetProjectPath(AICodedbProjectSettings.RegistrationValidateScriptRelativePath);

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
        /// Resolves the physical package root for embedded and PackageCache installs.
        /// </summary>
        private static string ResolvePackageRootPath()
        {
            try
            {
                var packageInfo = PackageInfo.FindForAssembly(typeof(AICodedbPaths).Assembly);
                if (packageInfo != null && !string.IsNullOrWhiteSpace(packageInfo.resolvedPath))
                    return NormalizePath(packageInfo.resolvedPath);
            }
            catch
            {
                // Fall back to the embedded-package path while Unity refreshes package metadata.
            }

            return GetProjectPath(AICodedbProjectSettings.PackageProjectRelativePath);
        }
    }
}
