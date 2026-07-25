using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbDetailRowView
    {
        private const float HeaderHeight = 18f;
        private const float IconWidth = 18f;
        private const float LabelWidth = 150f;
        private const float StateWidth = 96f;
        private const float SummaryWidth = 120f;
        private const float CopyButtonWidth = 54f;
        private const float RowVerticalPadding = 2f;
        private const int MaxDisplayDetailLength = 72;
        private static GUIStyle s_detailStyle;

        /// <summary>
        /// Draws the column labels for a technical details group.
        /// </summary>
        internal static void DrawHeader()
        {
            using (new EditorGUILayout.HorizontalScope(GUILayout.Height(HeaderHeight)))
            {
                GUILayout.Space(IconWidth);
                EditorGUILayout.LabelField("Check", EditorStyles.miniBoldLabel, GUILayout.Width(LabelWidth));
                EditorGUILayout.LabelField("State", EditorStyles.miniBoldLabel, GUILayout.Width(StateWidth));
                EditorGUILayout.LabelField("Summary", EditorStyles.miniBoldLabel, GUILayout.Width(SummaryWidth));
                GUILayout.Space(CopyButtonWidth);
                EditorGUILayout.LabelField("Detail", EditorStyles.miniBoldLabel);
            }
        }

        /// <summary>
        /// Draws a status row with state, summary, compact detail, and copy action.
        /// </summary>
        /// <param name="item">Status item to draw.</param>
        internal static void DrawStatus(AICodedbStatusItem item)
        {
            DrawRow(item.Label, AICodedbStatusSnapshot.GetStateLabel(item.State), item.Summary, item.Detail, AICodedbStatusTileView.GetIconContent(item.State));
        }

        /// <summary>
        /// Draws a read-only value row without a status severity.
        /// </summary>
        /// <param name="label">Row label.</param>
        /// <param name="summary">Short summary.</param>
        /// <param name="detail">Full detail value copied by the row action.</param>
        internal static void DrawValue(string label, string summary, string detail)
        {
            DrawRow(label, "Info", summary, detail, EditorGUIUtility.IconContent("console.infoicon"));
        }

        /// <summary>
        /// Draws a status-like row with stable columns.
        /// </summary>
        /// <param name="label">Row label.</param>
        /// <param name="stateLabel">Display state text.</param>
        /// <param name="summary">Short status summary.</param>
        /// <param name="detail">Full detail value.</param>
        /// <param name="icon">Row icon.</param>
        private static void DrawRow(string label, string stateLabel, string summary, string detail, GUIContent icon)
        {
            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUILayout.VerticalScope(GUILayout.Width(IconWidth)))
                {
                    GUILayout.Space(RowVerticalPadding);
                    GUILayout.Label(icon, GUILayout.Width(IconWidth), GUILayout.Height(IconWidth));
                }

                EditorGUILayout.LabelField(label, EditorStyles.boldLabel, GUILayout.Width(LabelWidth));
                EditorGUILayout.LabelField(stateLabel, GUILayout.Width(StateWidth));
                EditorGUILayout.SelectableLabel(summary, EditorStyles.textField, GUILayout.Width(SummaryWidth), GUILayout.Height(EditorGUIUtility.singleLineHeight));

                if (GUILayout.Button("Copy", GUILayout.Width(CopyButtonWidth), GUILayout.Height(22f)))
                    EditorGUIUtility.systemCopyBuffer = detail;

                EditorGUILayout.LabelField(ShortenDetail(detail), GetDetailStyle());
            }
        }

        /// <summary>
        /// Shortens long detail text while keeping the most useful path suffix visible.
        /// </summary>
        /// <param name="detail">Detail text.</param>
        private static string ShortenDetail(string detail)
        {
            if (string.IsNullOrWhiteSpace(detail) || detail.Length <= MaxDisplayDetailLength)
                return detail;

            return "..." + detail.Substring(detail.Length - MaxDisplayDetailLength);
        }

        /// <summary>
        /// Returns the shared wrapping style for detail values.
        /// </summary>
        private static GUIStyle GetDetailStyle()
        {
            if (s_detailStyle == null)
            {
                s_detailStyle = new GUIStyle(EditorStyles.wordWrappedMiniLabel)
                {
                    alignment = TextAnchor.MiddleLeft
                };
            }

            return s_detailStyle;
        }
    }
}
