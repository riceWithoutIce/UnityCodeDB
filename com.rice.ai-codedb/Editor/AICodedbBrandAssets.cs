using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbBrandAssets
    {
        internal const string IconAssetPath =
            "Packages/com.rice.ai-codedb/Editor/Icons/CodedbIcon.png";

        private static Texture2D s_icon;

        internal static Texture2D Icon
        {
            get
            {
                if (s_icon == null)
                    s_icon = AssetDatabase.LoadAssetAtPath<Texture2D>(IconAssetPath);
                return s_icon;
            }
        }

        internal static GUIContent CreateWindowTitleContent()
        {
            return new GUIContent("Codedb Manager", Icon, "Rice AI CodeDB");
        }
    }
}
