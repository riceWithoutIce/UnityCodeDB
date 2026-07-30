using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbManagerStyles
    {
        internal const float HeaderHeight = 58f;
        internal const float PageHeaderHeight = 48f;
        internal const float StatusRowHeight = 48f;
        internal const float SectionGap = 8f;
        internal const float IconButtonSize = 28f;
        internal const float StatusDotWidth = 14f;

        private static bool s_initialized;
        private static bool s_proSkin;
        private static GUIStyle s_headerTitle;
        private static GUIStyle s_headerSubtitle;
        private static GUIStyle s_headerPackageVersion;
        private static GUIStyle s_pageTitle;
        private static GUIStyle s_pageSubtitle;
        private static GUIStyle s_sectionTitle;
        private static GUIStyle s_rowTitle;
        private static GUIStyle s_rowDescription;
        private static GUIStyle s_stateValue;
        private static GUIStyle s_disclosureSummary;
        private static GUIStyle s_capabilityLabel;
        private static GUIStyle s_outputText;

        internal static GUIStyle HeaderTitle
        {
            get
            {
                EnsureInitialized();
                return s_headerTitle;
            }
        }

        internal static GUIStyle HeaderSubtitle
        {
            get
            {
                EnsureInitialized();
                return s_headerSubtitle;
            }
        }

        internal static GUIStyle HeaderPackageVersion
        {
            get
            {
                EnsureInitialized();
                return s_headerPackageVersion;
            }
        }

        internal static GUIStyle PageTitle
        {
            get
            {
                EnsureInitialized();
                return s_pageTitle;
            }
        }

        internal static GUIStyle PageSubtitle
        {
            get
            {
                EnsureInitialized();
                return s_pageSubtitle;
            }
        }

        internal static GUIStyle SectionTitle
        {
            get
            {
                EnsureInitialized();
                return s_sectionTitle;
            }
        }

        internal static GUIStyle RowTitle
        {
            get
            {
                EnsureInitialized();
                return s_rowTitle;
            }
        }

        internal static GUIStyle RowDescription
        {
            get
            {
                EnsureInitialized();
                return s_rowDescription;
            }
        }

        internal static GUIStyle DisclosureSummary
        {
            get
            {
                EnsureInitialized();
                return s_disclosureSummary;
            }
        }

        internal static GUIStyle CapabilityLabel
        {
            get
            {
                EnsureInitialized();
                return s_capabilityLabel;
            }
        }

        internal static GUIStyle OutputText
        {
            get
            {
                EnsureInitialized();
                return s_outputText;
            }
        }

        internal static GUIStyle GetStateValueStyle(AICodedbStatusState state)
        {
            EnsureInitialized();
            var style = new GUIStyle(s_stateValue);
            style.normal.textColor = GetStateColor(state);
            return style;
        }

        internal static GUIStyle GetStateDotStyle(AICodedbStatusState state)
        {
            EnsureInitialized();
            var style = new GUIStyle(EditorStyles.label)
            {
                alignment = TextAnchor.MiddleCenter,
                fontSize = 11
            };
            style.normal.textColor = GetStateColor(state);
            return style;
        }

        internal static Color GetStateColor(AICodedbStatusState state)
        {
            var proSkin = EditorGUIUtility.isProSkin;
            switch (state)
            {
                case AICodedbStatusState.Ok:
                    return proSkin ? new Color(0.34f, 0.82f, 0.48f) : new Color(0.08f, 0.48f, 0.20f);
                case AICodedbStatusState.Warning:
                    return proSkin ? new Color(0.94f, 0.72f, 0.30f) : new Color(0.62f, 0.38f, 0.04f);
                case AICodedbStatusState.Error:
                    return proSkin ? new Color(0.96f, 0.42f, 0.40f) : new Color(0.68f, 0.12f, 0.10f);
                default:
                    return proSkin ? new Color(0.66f, 0.68f, 0.70f) : new Color(0.38f, 0.40f, 0.42f);
            }
        }

        private static void EnsureInitialized()
        {
            if (s_initialized && s_proSkin == EditorGUIUtility.isProSkin)
                return;

            s_initialized = true;
            s_proSkin = EditorGUIUtility.isProSkin;
            s_headerTitle = new GUIStyle(EditorStyles.boldLabel)
            {
                fontSize = 12,
                alignment = TextAnchor.MiddleLeft
            };
            s_headerSubtitle = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleLeft
            };
            s_headerPackageVersion = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleRight
            };
            s_pageTitle = new GUIStyle(EditorStyles.boldLabel)
            {
                fontSize = 14,
                alignment = TextAnchor.MiddleLeft
            };
            s_pageSubtitle = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleLeft
            };
            s_sectionTitle = new GUIStyle(EditorStyles.boldLabel)
            {
                alignment = TextAnchor.MiddleLeft
            };
            s_rowTitle = new GUIStyle(EditorStyles.boldLabel)
            {
                alignment = TextAnchor.MiddleLeft
            };
            s_rowDescription = new GUIStyle(EditorStyles.wordWrappedMiniLabel)
            {
                alignment = TextAnchor.UpperLeft
            };
            s_stateValue = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleRight
            };
            s_disclosureSummary = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleRight
            };
            s_capabilityLabel = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleCenter,
                padding = new RectOffset(6, 6, 2, 2)
            };
            s_outputText = new GUIStyle(EditorStyles.textArea)
            {
                wordWrap = false
            };
        }
    }
}
