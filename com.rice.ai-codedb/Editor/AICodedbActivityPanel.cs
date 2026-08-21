using System;
using System.Globalization;
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

        internal void ResetForRunningAction()
        {
            _resultScrollPosition = Vector2.zero;
            _itemsPage = 0;
            _showOutput = false;
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

        internal bool Draw(
            AICodedbCommandResult result,
            string actionTitle,
            AICodedbUserActionPresentation userAction,
            AICodedbManagerLayoutMetrics layout)
        {
            var layoutOptions = layout.IsWide
                ? new[] { GUILayout.Width(layout.ActivityWidth), GUILayout.ExpandHeight(true) }
                : new[] { GUILayout.Width(layout.ActivityWidth), GUILayout.Height(layout.ActivityHeight) };
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, layoutOptions))
            {
                var summary = AICodedbActivitySummaryBuilder.Build(actionTitle, result);
                DrawHeader(summary, actionTitle, userAction.IsRunning);
                AICodedbSectionView.DrawDivider();
                EditorGUILayout.Space(4f);

                if (userAction.IsRunning)
                {
                    DrawRunningSummary(userAction);
                    GUILayout.FlexibleSpace();
                    return false;
                }

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

        internal bool Draw(
            AICodedbCommandResult result,
            string actionTitle,
            AICodedbManagerLayoutMetrics layout)
        {
            return Draw(
                result,
                actionTitle,
                new AICodedbUserActionPresentation(
                    false,
                    false,
                    AICodedbStatusState.Inactive,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    string.Empty),
                layout);
        }

        private static void DrawHeader(AICodedbActivitySummary summary, string actionTitle, bool isRunning)
        {
            using (new EditorGUILayout.VerticalScope(GUILayout.Height(38f)))
            {
                EditorGUILayout.LabelField(isRunning ? "Current activity" : "Last activity", EditorStyles.boldLabel);
                EditorGUILayout.LabelField(isRunning ? actionTitle : summary.ActionTitle, EditorStyles.miniLabel);
            }
        }

        private static void DrawRunningSummary(AICodedbUserActionPresentation userAction)
        {
            using (new EditorGUILayout.VerticalScope(GUILayout.MinHeight(72f)))
            {
                using (new EditorGUILayout.HorizontalScope(GUILayout.Height(20f)))
                {
                    GUILayout.Label(
                        "\u25cf",
                        AICodedbManagerStyles.GetStateDotStyle(userAction.State),
                        GUILayout.Width(AICodedbManagerStyles.StatusDotWidth),
                        GUILayout.Height(20f));
                    EditorGUILayout.LabelField(userAction.StatusLabel, EditorStyles.boldLabel);
                }

                if (!userAction.HasProgress
                    || !string.Equals(userAction.Detail, userAction.ProgressLabel, StringComparison.Ordinal))
                {
                    EditorGUILayout.LabelField(userAction.Detail, EditorStyles.wordWrappedMiniLabel);
                }
                if (userAction.HasProgress)
                {
                    EditorGUILayout.LabelField(userAction.ProgressLabel, EditorStyles.miniLabel);
                    var progressRect = GUILayoutUtility.GetRect(
                        GUIContent.none,
                        GUIStyle.none,
                        GUILayout.Height(7f),
                        GUILayout.ExpandWidth(true));
                    EditorGUI.ProgressBar(progressRect, userAction.ProgressValue, string.Empty);
                }
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.LabelField("Running", EditorStyles.miniLabel);
                    GUILayout.FlexibleSpace();
                    EditorGUILayout.LabelField(
                        userAction.ElapsedText,
                        AICodedbManagerStyles.DisclosureSummary,
                        GUILayout.Width(72f));
                }
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
                    if (!IsUserFacingProjectAction(summary.ActionTitle))
                        EditorGUILayout.LabelField("Exit " + result.ExitCode, EditorStyles.miniLabel);
                    else
                        EditorGUILayout.LabelField(string.Empty, EditorStyles.miniLabel);
                    GUILayout.FlexibleSpace();
                    EditorGUILayout.LabelField(summary.ElapsedText, AICodedbManagerStyles.DisclosureSummary, GUILayout.Width(72f));
                }

                if (!IsUserFacingProjectAction(summary.ActionTitle) && summary.Items.Length > 0)
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

        private static bool IsUserFacingProjectAction(string actionTitle)
        {
            return string.Equals(actionTitle, "Install CodeDB", StringComparison.Ordinal)
                   || string.Equals(actionTitle, "Reinstall CodeDB", StringComparison.Ordinal)
                   || string.Equals(actionTitle, "Uninstall CodeDB", StringComparison.Ordinal)
                   || string.Equals(actionTitle, "Configure CodeDB Dependencies", StringComparison.Ordinal);
        }
    }

    internal enum AICodedbUserActionPhase
    {
        None,
        Running,
        Completed,
        Failed
    }

    internal readonly struct AICodedbUserActionPresentation
    {
        internal bool IsVisible { get; }
        internal bool IsRunning { get; }
        internal AICodedbStatusState State { get; }
        internal string StatusLabel { get; }
        internal string Detail { get; }
        internal string ElapsedText { get; }
        internal string ButtonLabel { get; }
        internal string NotificationText { get; }
        internal bool HasProgress { get; }
        internal float ProgressValue { get; }
        internal string ProgressLabel { get; }

        internal AICodedbUserActionPresentation(
            bool isVisible,
            bool isRunning,
            AICodedbStatusState state,
            string statusLabel,
            string detail,
            string elapsedText,
            string buttonLabel,
            string notificationText,
            bool hasProgress = false,
            float progressValue = 0f,
            string progressLabel = "")
        {
            IsVisible = isVisible;
            IsRunning = isRunning;
            State = state;
            StatusLabel = statusLabel ?? string.Empty;
            Detail = detail ?? string.Empty;
            ElapsedText = elapsedText ?? string.Empty;
            ButtonLabel = buttonLabel ?? string.Empty;
            NotificationText = notificationText ?? string.Empty;
            HasProgress = hasProgress;
            ProgressValue = Mathf.Clamp01(progressValue);
            ProgressLabel = progressLabel ?? string.Empty;
        }
    }

    internal sealed class AICodedbUserActionStatus
    {
        private const string ProviderStageMarker = "[PROVIDER_STAGE]";
        private double _startedAt;
        private double _completedAt;
        private bool _statusRefreshSucceeded;
        private AICodedbProductState _completedProductState;
        private readonly object _progressLock = new object();
        private bool _hasProgress;
        private int _progressStage;
        private int _progressTotal;
        private string _progressLabel = string.Empty;

        internal AICodedbUserActionPhase Phase { get; private set; }
        internal string Title { get; private set; } = string.Empty;
        private AICodedbCommandResult Result { get; set; }

        internal void Start(string title, double now)
        {
            Phase = AICodedbUserActionPhase.Running;
            Title = title ?? string.Empty;
            Result = null;
            _startedAt = SanitizeTime(now);
            _completedAt = _startedAt;
            _statusRefreshSucceeded = false;
            _completedProductState = AICodedbProductState.Starting;
            ClearProgress();
        }

        internal void Complete(
            AICodedbCommandResult result,
            AICodedbProductState productState,
            bool statusRefreshSucceeded,
            double now)
        {
            Result = result;
            Phase = result != null && result.Succeeded
                ? AICodedbUserActionPhase.Completed
                : AICodedbUserActionPhase.Failed;
            _completedProductState = productState;
            _statusRefreshSucceeded = statusRefreshSucceeded;
            _completedAt = Math.Max(_startedAt, SanitizeTime(now));
        }

        /// <summary>
        /// Applies a trusted Provider installer stage emitted on its stdout.
        /// This method may be called from the process output reader thread.
        /// </summary>
        internal bool UpdateProgressLine(string line)
        {
            if (string.IsNullOrWhiteSpace(line))
                return false;

            var trimmed = line.Trim();
            if (!trimmed.StartsWith(ProviderStageMarker, StringComparison.OrdinalIgnoreCase))
                return false;

            var payload = trimmed.Substring(ProviderStageMarker.Length).Trim();
            var separator = payload.IndexOf(' ');
            if (separator <= 0 || separator >= payload.Length - 1)
                return false;

            var stageToken = payload.Substring(0, separator);
            var slash = stageToken.IndexOf('/');
            if (slash <= 0 || slash >= stageToken.Length - 1)
                return false;

            int stage;
            int total;
            if (!int.TryParse(
                    stageToken.Substring(0, slash),
                    NumberStyles.Integer,
                    CultureInfo.InvariantCulture,
                    out stage)
                || !int.TryParse(
                    stageToken.Substring(slash + 1),
                    NumberStyles.Integer,
                    CultureInfo.InvariantCulture,
                    out total)
                || stage < 1
                || total < stage
                || total > 100)
            {
                return false;
            }

            var label = payload.Substring(separator + 1).Trim();
            if (string.IsNullOrWhiteSpace(label))
                return false;

            lock (_progressLock)
            {
                _hasProgress = true;
                _progressStage = stage;
                _progressTotal = total;
                _progressLabel = label;
            }
            return true;
        }

        internal void SetProgress(int stage, int total, string label)
        {
            if (stage < 1 || total < stage || total > 100 || string.IsNullOrWhiteSpace(label))
                return;

            lock (_progressLock)
            {
                _hasProgress = true;
                _progressStage = stage;
                _progressTotal = total;
                _progressLabel = label.Trim();
            }
        }

        internal void UpdateProductState(AICodedbProductState productState)
        {
            if (Phase == AICodedbUserActionPhase.Completed && _statusRefreshSucceeded)
                _completedProductState = productState;
        }

        internal void Clear()
        {
            Phase = AICodedbUserActionPhase.None;
            Title = string.Empty;
            Result = null;
            _startedAt = 0d;
            _completedAt = 0d;
            _statusRefreshSucceeded = false;
            _completedProductState = AICodedbProductState.Starting;
            ClearProgress();
        }

        internal AICodedbUserActionPresentation BuildPresentation(double now)
        {
            bool hasProgress;
            float progressValue;
            string progressLabel;
            GetProgress(out hasProgress, out progressValue, out progressLabel);
            switch (Phase)
            {
                case AICodedbUserActionPhase.Running:
                    return new AICodedbUserActionPresentation(
                        true,
                        true,
                        AICodedbStatusState.Warning,
                        "In progress",
                        hasProgress ? progressLabel : Title + " is running.",
                        FormatElapsedMilliseconds(GetElapsedMilliseconds(now)),
                        GetRunningButtonLabel(Title),
                        Title + " started.",
                        hasProgress,
                        progressValue,
                        progressLabel);
                case AICodedbUserActionPhase.Failed:
                    return new AICodedbUserActionPresentation(
                        true,
                        false,
                        AICodedbStatusState.Error,
                        "Failed",
                        GetFailureDetail(Result),
                        GetCompletedElapsedText(),
                        string.Empty,
                        Title + " failed. See Last activity for details.",
                        hasProgress,
                        progressValue,
                        progressLabel);
                case AICodedbUserActionPhase.Completed:
                    return BuildCompletedPresentation(hasProgress, progressValue, progressLabel);
                default:
                    return new AICodedbUserActionPresentation(
                        false,
                        false,
                        AICodedbStatusState.Inactive,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty,
                        string.Empty);
            }
        }

        private AICodedbUserActionPresentation BuildCompletedPresentation(
            bool hasProgress,
            float progressValue,
            string progressLabel)
        {
            var state = AICodedbStatusState.Ok;
            var statusLabel = "Completed";
            var detail = "The command completed successfully.";
            var notification = Title + " completed.";

            if (!_statusRefreshSucceeded)
            {
                state = AICodedbStatusState.Warning;
                statusLabel = "Completed - status unavailable";
                detail = "The command completed, but CodeDB status could not be refreshed.";
                notification = Title + " completed, but CodeDB status could not be refreshed.";
            }
            else
            {
                switch (_completedProductState)
                {
                    case AICodedbProductState.Ready:
                        detail = "The command completed and CodeDB is ready.";
                        notification = Title + " completed. CodeDB is ready.";
                        break;
                    case AICodedbProductState.Uninstalled:
                        detail = "The command completed and CodeDB is uninstalled from this project.";
                        notification = Title + " completed. CodeDB is uninstalled.";
                        break;
                    case AICodedbProductState.NeedsAttention:
                        state = AICodedbStatusState.Warning;
                        statusLabel = "Completed - needs attention";
                        detail = "The command completed, but CodeDB still needs attention.";
                        notification = Title + " completed, but CodeDB still needs attention.";
                        break;
                    case AICodedbProductState.MissingPrerequisite:
                        state = AICodedbStatusState.Warning;
                        statusLabel = "Completed - prerequisite missing";
                        detail = "The command completed, but a required dependency is still missing or invalid.";
                        notification = Title + " completed, but a required dependency is still missing or invalid.";
                        break;
                    default:
                        state = AICodedbStatusState.Warning;
                        statusLabel = "Completed - checking status";
                        detail = "The command completed. CodeDB status is still being checked.";
                        notification = Title + " completed. CodeDB status is still being checked.";
                        break;
                }
            }

            return new AICodedbUserActionPresentation(
                true,
                false,
                state,
                statusLabel,
                detail,
                GetCompletedElapsedText(),
                string.Empty,
                notification,
                hasProgress,
                progressValue,
                progressLabel);
        }

        private void GetProgress(out bool hasProgress, out float progressValue, out string progressLabel)
        {
            lock (_progressLock)
            {
                hasProgress = _hasProgress;
                progressValue = _hasProgress && _progressTotal > 0
                    ? Mathf.Clamp01((float)_progressStage / _progressTotal)
                    : 0f;
                progressLabel = _hasProgress
                    ? string.Format(
                        CultureInfo.InvariantCulture,
                        "Stage {0} of {1}: {2}",
                        _progressStage,
                        _progressTotal,
                        _progressLabel)
                    : string.Empty;
            }
        }

        private void ClearProgress()
        {
            lock (_progressLock)
            {
                _hasProgress = false;
                _progressStage = 0;
                _progressTotal = 0;
                _progressLabel = string.Empty;
            }
        }

        private long GetElapsedMilliseconds(double now)
        {
            var end = Phase == AICodedbUserActionPhase.Running
                ? Math.Max(_startedAt, SanitizeTime(now))
                : _completedAt;
            return (long)Math.Max(0d, Math.Round((end - _startedAt) * 1000d));
        }

        private string GetCompletedElapsedText()
        {
            if (Result != null && Result.ElapsedMilliseconds > 0)
                return Result.GetElapsedText();
            return FormatElapsedMilliseconds(GetElapsedMilliseconds(_completedAt));
        }

        internal static string FormatElapsedMilliseconds(long elapsedMilliseconds)
        {
            elapsedMilliseconds = Math.Max(0L, elapsedMilliseconds);
            if (elapsedMilliseconds < 1000L)
                return elapsedMilliseconds.ToString(CultureInfo.InvariantCulture) + " ms";

            var seconds = elapsedMilliseconds / 1000d;
            if (seconds < 60d)
                return seconds.ToString("0.0", CultureInfo.InvariantCulture) + " s";

            return (seconds / 60d).ToString("0.0", CultureInfo.InvariantCulture) + " min";
        }

        private static string GetRunningButtonLabel(string title)
        {
            if (title.IndexOf("Dependencies", StringComparison.OrdinalIgnoreCase) >= 0)
                return "Configuring...";
            if (title.IndexOf("Uninstall", StringComparison.OrdinalIgnoreCase) >= 0)
                return "Uninstalling...";
            if (title.IndexOf("Reinstall", StringComparison.OrdinalIgnoreCase) >= 0)
                return "Reinstalling...";
            if (title.IndexOf("Install", StringComparison.OrdinalIgnoreCase) >= 0)
                return "Installing...";
            return "Working...";
        }

        private static string GetFailureDetail(AICodedbCommandResult result)
        {
            if (result == null)
                return "The command did not return a result.";
            if (result.TimedOut)
                return "The command exceeded its timeout.";

            var error = FirstNonEmptyLine(result.StandardError);
            return string.IsNullOrWhiteSpace(error) ? result.GetSummary() : error;
        }

        private static string FirstNonEmptyLine(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return string.Empty;
            foreach (var line in text.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None))
            {
                if (!string.IsNullOrWhiteSpace(line))
                    return line.Trim();
            }
            return string.Empty;
        }

        private static double SanitizeTime(double value)
        {
            return double.IsNaN(value) || double.IsInfinity(value) ? 0d : Math.Max(0d, value);
        }
    }
}
