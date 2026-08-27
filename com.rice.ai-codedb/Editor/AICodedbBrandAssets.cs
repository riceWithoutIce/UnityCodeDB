using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbBrandAssets
    {
        internal const string IconAssetPath =
            "Packages/com.rice.ai-codedb/Editor/Icons/CodedbIcon.png";
        internal const string TabIconAssetPath =
            "Packages/com.rice.ai-codedb/Editor/Icons/CodedbTabIcon.png";

        private static Texture2D s_icon;
        private static Texture2D s_tabIcon;
        private static bool s_packageVersionResolved;
        private static string s_packageVersion = string.Empty;

        internal static string PackageVersion => ResolvePackageVersion();

        internal static Texture2D Icon
        {
            get
            {
                if (s_icon == null)
                    s_icon = AssetDatabase.LoadAssetAtPath<Texture2D>(IconAssetPath);
                return s_icon;
            }
        }

        internal static Texture2D TabIcon
        {
            get
            {
                if (s_tabIcon == null)
                    s_tabIcon = AssetDatabase.LoadAssetAtPath<Texture2D>(TabIconAssetPath);
                return s_tabIcon;
            }
        }

        internal static GUIContent CreateWindowTitleContent()
        {
            return CreateWindowTitleContent(ResolvePackageVersion());
        }

        internal static GUIContent CreateWindowTitleContent(string packageVersion)
        {
            var version = (packageVersion ?? string.Empty).Trim();
            var tooltip = string.IsNullOrWhiteSpace(version)
                ? "Rice AI CodeDB"
                : "Rice AI CodeDB v" + version;
            return new GUIContent("CodeDB Manager", TabIcon, tooltip);
        }

        internal static GUIContent CreatePackageVersionContent()
        {
            return CreatePackageVersionContent(ResolvePackageVersion());
        }

        internal static GUIContent CreatePackageVersionContent(string packageVersion)
        {
            var version = (packageVersion ?? string.Empty).Trim();
            return string.IsNullOrWhiteSpace(version)
                ? new GUIContent("Package version unavailable", "Unity Package Manager version is unavailable during package refresh.")
                : new GUIContent("Package v" + version, "Installed Unity Package Manager version");
        }

        private static string ResolvePackageVersion()
        {
            if (s_packageVersionResolved)
                return s_packageVersion;

            s_packageVersionResolved = true;
            try
            {
                var packageInfo = UnityEditor.PackageManager.PackageInfo.FindForAssembly(
                    typeof(AICodedbBrandAssets).Assembly);
                if (packageInfo != null && !string.IsNullOrWhiteSpace(packageInfo.version))
                {
                    s_packageVersion = packageInfo.version;
                    return s_packageVersion;
                }
            }
            catch
            {
                // Unity can briefly withhold package metadata during package refresh.
            }

            s_packageVersion = typeof(AICodedbBrandAssets).Assembly.GetName().Version?.ToString()
                               ?? string.Empty;
            return s_packageVersion;
        }
    }
}
