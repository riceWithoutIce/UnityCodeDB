using System;
using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbSectionView
    {
        private const float StatusValueWidth = 112f;

        internal static void DrawPageHeader(
            string title,
            string subtitle,
            string actionLabel,
            Action action,
            bool emphasizeAction = true)
        {
            using (new EditorGUILayout.HorizontalScope(GUILayout.Height(AICodedbManagerStyles.PageHeaderHeight)))
            {
                using (new EditorGUILayout.VerticalScope())
                {
                    EditorGUILayout.LabelField(title, AICodedbManagerStyles.PageTitle);
                    EditorGUILayout.LabelField(subtitle, AICodedbManagerStyles.PageSubtitle);
                }

                GUILayout.FlexibleSpace();
                if (!string.IsNullOrWhiteSpace(actionLabel))
                    DrawCommandButton(actionLabel, action, emphasizeAction);
            }

            EditorGUILayout.Space(AICodedbManagerStyles.SectionGap);
        }

        internal static void DrawBanner(
            string title,
            string description,
            AICodedbStatusState state,
            string actionLabel,
            Action action)
        {
            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox, GUILayout.MinHeight(58f)))
            {
                DrawStateDot(state, 24f);
                using (new EditorGUILayout.VerticalScope())
                {
                    EditorGUILayout.LabelField(title, AICodedbManagerStyles.RowTitle);
                    EditorGUILayout.LabelField(description, AICodedbManagerStyles.RowDescription);
                }

                GUILayout.FlexibleSpace();
                if (!string.IsNullOrWhiteSpace(actionLabel))
                    DrawCommandButton(actionLabel, action, false);
            }

            EditorGUILayout.Space(AICodedbManagerStyles.SectionGap);
        }

        internal static void DrawStatusGroup(string title, string actionLabel, Action action, Action drawRows)
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                using (new EditorGUILayout.HorizontalScope(GUILayout.Height(AICodedbActionGridView.ButtonHeight)))
                {
                    EditorGUILayout.LabelField(title, AICodedbManagerStyles.SectionTitle);
                    GUILayout.FlexibleSpace();
                    if (!string.IsNullOrWhiteSpace(actionLabel))
                        DrawCommandButton(actionLabel, action, false);
                }

                EditorGUILayout.Space(2f);
                drawRows?.Invoke();
            }

            EditorGUILayout.Space(AICodedbManagerStyles.SectionGap);
        }

        internal static void DrawStatusRow(
            string label,
            string description,
            AICodedbStatusState state,
            string statusLabel)
        {
            DrawStatusRow(label, description, state, statusLabel, string.Empty, null);
        }

        internal static void DrawStatusRow(
            string label,
            string description,
            AICodedbStatusState state,
            string statusLabel,
            string actionLabel,
            Action action)
        {
            using (new EditorGUILayout.HorizontalScope(GUILayout.MinHeight(AICodedbManagerStyles.StatusRowHeight)))
            {
                DrawStateDot(state, AICodedbManagerStyles.StatusRowHeight);
                using (new EditorGUILayout.VerticalScope())
                {
                    GUILayout.Space(3f);
                    EditorGUILayout.LabelField(label, AICodedbManagerStyles.RowTitle);
                    EditorGUILayout.LabelField(description, AICodedbManagerStyles.RowDescription);
                }

                GUILayout.FlexibleSpace();
                EditorGUILayout.LabelField(
                    statusLabel,
                    AICodedbManagerStyles.GetStateValueStyle(state),
                    GUILayout.Width(StatusValueWidth),
                    GUILayout.Height(AICodedbManagerStyles.StatusRowHeight));

                if (!string.IsNullOrWhiteSpace(actionLabel))
                {
                    GUILayout.Space(AICodedbActionGridView.Gap);
                    using (new EditorGUILayout.VerticalScope(GUILayout.Width(AICodedbActionGridView.GetButtonWidth(actionLabel))))
                    {
                        GUILayout.Space(9f);
                        DrawCommandButton(actionLabel, action, false);
                    }
                }
            }

            DrawDivider();
        }

        internal static bool DrawDisclosure(
            bool expanded,
            string title,
            string summary,
            Action drawContent,
            bool fillAvailableHeight = false)
        {
            var layoutOptions = fillAvailableHeight && expanded
                ? new[] { GUILayout.ExpandHeight(true) }
                : Array.Empty<GUILayoutOption>();
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, layoutOptions))
            {
                var headerRect = EditorGUILayout.GetControlRect(false, 26f);
                var summaryWidth = Mathf.Clamp(headerRect.width * 0.38f, 120f, 260f);
                var foldoutRect = new Rect(headerRect.x, headerRect.y, Mathf.Max(0f, headerRect.width - summaryWidth - 8f), headerRect.height);
                var summaryRect = new Rect(foldoutRect.xMax + 8f, headerRect.y, summaryWidth, headerRect.height);

                expanded = EditorGUI.Foldout(foldoutRect, expanded, title, true);
                if (!string.IsNullOrWhiteSpace(summary))
                    GUI.Label(summaryRect, summary, AICodedbManagerStyles.DisclosureSummary);

                if (expanded)
                {
                    EditorGUILayout.Space(4f);
                    drawContent?.Invoke();
                }
            }

            EditorGUILayout.Space(AICodedbManagerStyles.SectionGap);
            return expanded;
        }

        internal static void DrawCapabilityLabel(string label, AICodedbStatusState state)
        {
            var oldColor = GUI.contentColor;
            GUI.contentColor = AICodedbManagerStyles.GetStateColor(state);
            GUILayout.Label(label, AICodedbManagerStyles.CapabilityLabel, GUILayout.MinWidth(62f), GUILayout.Height(22f));
            GUI.contentColor = oldColor;
        }

        internal static void DrawNeutralCapability(string label)
        {
            using (new EditorGUILayout.HorizontalScope(GUILayout.Height(22f)))
            {
                DrawStateDot(AICodedbStatusState.Inactive, 22f);
                EditorGUILayout.LabelField(label, EditorStyles.label);
                GUILayout.FlexibleSpace();
                EditorGUILayout.LabelField("Restricted", AICodedbManagerStyles.GetStateValueStyle(AICodedbStatusState.Inactive), GUILayout.Width(StatusValueWidth));
            }
        }

        internal static bool DrawCommandButton(string label, Action action, bool primary)
        {
            var oldBackgroundColor = GUI.backgroundColor;
            if (primary)
                GUI.backgroundColor = EditorGUIUtility.isProSkin ? new Color(0.55f, 0.72f, 0.92f) : new Color(0.62f, 0.78f, 0.96f);

            var clicked = false;
            using (new EditorGUI.DisabledScope(action == null))
            {
                clicked = GUILayout.Button(
                    label,
                    GUI.skin.button,
                    GUILayout.Width(AICodedbActionGridView.GetButtonWidth(label)),
                    GUILayout.Height(AICodedbActionGridView.ButtonHeight));
            }

            GUI.backgroundColor = oldBackgroundColor;
            if (clicked)
                action?.Invoke();
            return clicked;
        }

        internal static void DrawDivider()
        {
            var rect = GUILayoutUtility.GetRect(GUIContent.none, GUIStyle.none, GUILayout.Height(1f), GUILayout.ExpandWidth(true));
            var color = EditorGUIUtility.isProSkin
                ? new Color(0.45f, 0.45f, 0.45f, 0.32f)
                : new Color(0.35f, 0.35f, 0.35f, 0.22f);
            EditorGUI.DrawRect(rect, color);
        }

        private static void DrawStateDot(AICodedbStatusState state, float height)
        {
            GUILayout.Label(
                "\u25cf",
                AICodedbManagerStyles.GetStateDotStyle(state),
                GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                GUILayout.Height(height));
        }
    }
}
