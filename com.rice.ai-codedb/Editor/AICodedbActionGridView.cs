using System;
using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbActionGridView
    {
        internal const int DefaultColumns = 3;
        internal const int HealthCheckColumns = 5;
        internal const float ButtonWidth = 128f;
        internal const float ButtonHorizontalPadding = 16f;
        internal const float ButtonHeight = 28f;
        internal const float RowHeight = 30f;
        internal const float Gap = 4f;
        internal const float ContainerHorizontalPadding = 18f;

        internal static int ResolveColumns(float availableWidth, int preferredColumns, int buttonCount)
        {
            return ResolveColumns(availableWidth, preferredColumns, buttonCount, ButtonWidth);
        }

        internal static int ResolveColumns(float availableWidth, int preferredColumns, int buttonCount, float buttonWidth)
        {
            preferredColumns = Math.Max(1, preferredColumns);
            if (buttonCount <= 0)
                return 0;

            buttonWidth = Mathf.Max(ButtonWidth, buttonWidth);
            var fitColumns = Mathf.Max(1, Mathf.FloorToInt((Mathf.Max(0f, availableWidth) + Gap) / (buttonWidth + Gap)));
            var maxColumns = Math.Min(buttonCount, Math.Min(preferredColumns, fitColumns));

            if (preferredColumns >= HealthCheckColumns && maxColumns < HealthCheckColumns && fitColumns >= DefaultColumns)
                return Math.Min(DefaultColumns, buttonCount);

            return Math.Max(1, maxColumns);
        }

        internal static float GetButtonWidth(string label)
        {
            var contentWidth = string.IsNullOrEmpty(label)
                ? 0f
                : GUI.skin.button.CalcSize(new GUIContent(label)).x;
            return ResolveButtonWidth(contentWidth);
        }

        internal static float ResolveButtonWidth(float contentWidth)
        {
            return Mathf.Max(ButtonWidth, Mathf.Ceil(contentWidth + ButtonHorizontalPadding));
        }

        internal static void Draw(float availableWidth, int preferredColumns, params AICodedbActionButton[] buttons)
        {
            if (buttons == null || buttons.Length == 0)
                return;

            var widestButton = ButtonWidth;
            for (var index = 0; index < buttons.Length; index++)
                widestButton = Mathf.Max(widestButton, GetButtonWidth(buttons[index].Label));
            var columns = ResolveColumns(availableWidth, preferredColumns, buttons.Length, widestButton);
            for (var startIndex = 0; startIndex < buttons.Length; startIndex += columns)
            {
                using (new EditorGUILayout.HorizontalScope(GUILayout.Height(RowHeight)))
                {
                    var endIndex = Math.Min(startIndex + columns, buttons.Length);
                    for (var index = startIndex; index < endIndex; index++)
                    {
                        if (index > startIndex)
                            GUILayout.Space(Gap);

                        DrawButton(buttons[index]);
                    }

                    GUILayout.FlexibleSpace();
                }
            }
        }

        private static void DrawButton(AICodedbActionButton button)
        {
            using (new EditorGUI.DisabledScope(button.Action == null))
            {
                if (GUILayout.Button(button.Label, GUI.skin.button, GUILayout.Width(GetButtonWidth(button.Label)), GUILayout.Height(ButtonHeight)))
                    button.Action?.Invoke();
            }
        }
    }

    internal readonly struct AICodedbActionButton
    {
        internal string Label { get; }
        internal Action Action { get; }

        private AICodedbActionButton(string label, Action action)
        {
            Label = label;
            Action = action;
        }

        internal static AICodedbActionButton Create(string label, Action action)
        {
            return new AICodedbActionButton(label, action);
        }
    }
}
