using System;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbActivityPanel
    {
        private const int OutputItemsPerPage = 20;
        private const float ClearButtonWidth = 70f;
        private const float OutputViewportMinHeight = 24f;
        private const float OutputContentMinHeight = 100f;
        // Header, summary, disclosure chrome, footer, and IMGUI spacing stay outside the output viewport.
        private const float OutputChromeHeight = 210f;
        private Vector2 _resultScrollPosition;
        private int _itemsPage;
        private bool _showOutput;

        internal void ResetForNewResult(AICodedbCommandResult result, string actionTitle)
        {
            _resultScrollPosition = Vector2.zero;
            _itemsPage = 0;
            var summary = AICodedbActivitySummaryBuilder.Build(actionTitle, result);
            _showOutput = ShouldExpandOutput(summary.State);
        }

        internal static bool ShouldExpandOutput(AICodedbStatusState state)
        {
            return state == AICodedbStatusState.Warning || state == AICodedbStatusState.Error;
        }

        internal static float ResolveOutputViewportHeight(float activityHeight)
        {
            if (float.IsNaN(activityHeight) || float.IsInfinity(activityHeight))
                return OutputViewportMinHeight;
            return Mathf.Max(OutputViewportMinHeight, activityHeight - OutputChromeHeight);
        }

        internal bool Draw(AICodedbCommandResult result, string actionTitle, AICodedbManagerLayoutMetrics layout)
        {
            var layoutOptions = layout.IsWide
                ? new[] { GUILayout.Width(layout.ActivityWidth), GUILayout.ExpandHeight(true) }
                : new[] { GUILayout.Width(layout.ActivityWidth), GUILayout.Height(layout.ActivityHeight) };
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, layoutOptions))
            {
                var summary = AICodedbActivitySummaryBuilder.Build(actionTitle, result);
                DrawHeader(summary);
                AICodedbSectionView.DrawDivider();
                EditorGUILayout.Space(4f);

                if (result == null)
                {
                    EditorGUILayout.LabelField("No recent command.", EditorStyles.wordWrappedMiniLabel);
                    GUILayout.FlexibleSpace();
                    return false;
                }

                DrawSummary(result, summary);
                DrawOutputDisclosure(result, summary, layout.ActivityHeight);
                if (!_showOutput)
                    GUILayout.FlexibleSpace();
                return DrawFooter(result);
            }
        }

        private static void DrawHeader(AICodedbActivitySummary summary)
        {
            using (new EditorGUILayout.VerticalScope(GUILayout.Height(38f)))
            {
                EditorGUILayout.LabelField("Last activity", EditorStyles.boldLabel);
                EditorGUILayout.LabelField(summary.ActionTitle, EditorStyles.miniLabel);
            }
        }

        private static void DrawSummary(AICodedbCommandResult result, AICodedbActivitySummary summary)
        {
            using (new EditorGUILayout.VerticalScope(GUILayout.MinHeight(72f)))
            {
                using (new EditorGUILayout.HorizontalScope(GUILayout.Height(20f)))
                {
                    GUILayout.Label(
                        "\u25cf",
                        AICodedbManagerStyles.GetStateDotStyle(summary.State),
                        GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                        GUILayout.Height(20f));
                    EditorGUILayout.LabelField(summary.StatusLabel, EditorStyles.boldLabel);
                }

                if (!string.IsNullOrWhiteSpace(summary.Detail))
                    EditorGUILayout.LabelField(summary.Detail, EditorStyles.wordWrappedMiniLabel);

                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.LabelField("Exit " + result.ExitCode, EditorStyles.miniLabel);
                    GUILayout.FlexibleSpace();
                    EditorGUILayout.LabelField(summary.ElapsedText, AICodedbManagerStyles.DisclosureSummary, GUILayout.Width(72f));
                }

                if (summary.Items.Length > 0)
                    EditorGUILayout.LabelField($"{GetPluralItemLabel(summary.ItemsTitle)}: {summary.Items.Length}", EditorStyles.miniLabel);
            }

            EditorGUILayout.Space(4f);
        }

        private void DrawOutputDisclosure(
            AICodedbCommandResult result,
            AICodedbActivitySummary summary,
            float activityHeight)
        {
            var disclosureSummary = !_showOutput && !ShouldExpandOutput(summary.State)
                ? "Collapsed on success"
                : "Raw command output";
            _showOutput = AICodedbSectionView.DrawDisclosure(
                _showOutput,
                "Output details",
                disclosureSummary,
                () => DrawOutput(result, summary, activityHeight),
                true);
        }

        private bool DrawFooter(AICodedbCommandResult result)
        {
            using (new EditorGUILayout.HorizontalScope(GUILayout.Height(26f)))
            {
                if (GUILayout.Button("Copy output", GUILayout.Height(24f)))
                    EditorGUIUtility.systemCopyBuffer = result.GetDisplayText();

                if (GUILayout.Button("Clear", GUILayout.Width(ClearButtonWidth), GUILayout.Height(24f)))
                {
                    _resultScrollPosition = Vector2.zero;
                    _itemsPage = 0;
                    _showOutput = false;
                    return true;
                }
            }

            return false;
        }

        private void DrawOutput(
            AICodedbCommandResult result,
            AICodedbActivitySummary summary,
            float activityHeight)
        {
            var displayText = BuildPagedOutputText(result, summary, out var pageCount);
            if (pageCount > 1)
                DrawOutputPager(pageCount);

            var viewportRect = GUILayoutUtility.GetRect(
                GUIContent.none,
                GUIStyle.none,
                GUILayout.Height(ResolveOutputViewportHeight(activityHeight)),
                GUILayout.ExpandWidth(true),
                GUILayout.ExpandHeight(false));
            var style = AICodedbManagerStyles.OutputText;
            var content = new GUIContent(displayText);
            var viewportWidth = Mathf.Max(120f, viewportRect.width - 18f);
            var contentWidth = Mathf.Max(viewportWidth, style.CalcSize(content).x + 18f);
            var contentHeight = Mathf.Max(
                OutputContentMinHeight,
                viewportRect.height - 18f,
                style.CalcHeight(content, contentWidth) + 8f);
            var contentRect = new Rect(0f, 0f, contentWidth, contentHeight);

            _resultScrollPosition = GUI.BeginScrollView(
                viewportRect,
                _resultScrollPosition,
                contentRect,
                true,
                true);
            EditorGUI.SelectableLabel(
                contentRect,
                displayText,
                style);
            GUI.EndScrollView();
        }

        private void DrawOutputPager(int pageCount)
        {
            _itemsPage = Mathf.Clamp(_itemsPage, 0, pageCount - 1);
            using (new EditorGUILayout.HorizontalScope())
            {
                using (new EditorGUI.DisabledScope(_itemsPage <= 0))
                {
                    if (GUILayout.Button("Prev", GUILayout.Width(58f), GUILayout.Height(20f)))
                    {
                        _itemsPage--;
                        _resultScrollPosition = Vector2.zero;
                    }
                }

                GUILayout.FlexibleSpace();
                EditorGUILayout.LabelField($"Page {_itemsPage + 1} / {pageCount}", EditorStyles.miniLabel, GUILayout.Width(90f));
                GUILayout.FlexibleSpace();

                using (new EditorGUI.DisabledScope(_itemsPage >= pageCount - 1))
                {
                    if (GUILayout.Button("Next", GUILayout.Width(58f), GUILayout.Height(20f)))
                    {
                        _itemsPage++;
                        _resultScrollPosition = Vector2.zero;
                    }
                }
            }
        }

        private string BuildPagedOutputText(AICodedbCommandResult result, AICodedbActivitySummary summary, out int pageCount)
        {
            if (summary.Items.Length == 0)
            {
                pageCount = 1;
                _itemsPage = 0;
                return result.GetDisplayText();
            }

            pageCount = Mathf.Max(1, Mathf.CeilToInt(summary.Items.Length / (float)OutputItemsPerPage));
            _itemsPage = Mathf.Clamp(_itemsPage, 0, pageCount - 1);

            var builder = new StringBuilder();
            builder.AppendLine(result.GetSummary());
            builder.AppendLine();
            builder.AppendLine($"Exit Code: {result.ExitCode}");
            if (result.ElapsedMilliseconds > 0)
                builder.AppendLine($"Elapsed: {result.GetElapsedText()}");
            if (result.TimedOut)
                builder.AppendLine("Timed Out: True");

            builder.AppendLine();
            builder.AppendLine("Output:");
            AppendNonItemOutputLines(builder, result.StandardOutput);
            builder.AppendLine($"{GetPluralItemLabel(summary.ItemsTitle)}: {summary.Items.Length}");
            builder.AppendLine($"Page {_itemsPage + 1} / {pageCount}");

            var startIndex = _itemsPage * OutputItemsPerPage;
            var endIndex = Math.Min(startIndex + OutputItemsPerPage, summary.Items.Length);
            for (var index = startIndex; index < endIndex; index++)
                builder.AppendLine("[HIT] " + summary.Items[index]);

            if (!string.IsNullOrWhiteSpace(result.StandardError))
            {
                builder.AppendLine();
                builder.AppendLine("Error:");
                builder.AppendLine(result.StandardError.TrimEnd());
            }

            return builder.ToString();
        }

        private static void AppendNonItemOutputLines(StringBuilder builder, string output)
        {
            if (string.IsNullOrWhiteSpace(output))
                return;

            var appended = false;
            var lines = output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("[HIT]", StringComparison.OrdinalIgnoreCase))
                    continue;
                if (string.IsNullOrWhiteSpace(line) && !appended)
                    continue;

                builder.AppendLine(line);
                appended = true;
            }
        }

        private static string GetPluralItemLabel(string itemsTitle)
        {
            return string.IsNullOrWhiteSpace(itemsTitle) ? "Items" : itemsTitle;
        }
    }
}
