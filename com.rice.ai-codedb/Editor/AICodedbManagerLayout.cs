using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbManagerLayoutMode
    {
        Wide,
        Compact
    }

    internal readonly struct AICodedbManagerLayoutMetrics
    {
        internal AICodedbManagerLayoutMode Mode { get; }
        internal float AvailableWidth { get; }
        internal float MainContentWidth { get; }
        internal float ActivityWidth { get; }
        internal float ActivityHeight { get; }
        internal float SplitterWidth { get; }
        internal bool IsWide => Mode == AICodedbManagerLayoutMode.Wide;

        internal AICodedbManagerLayoutMetrics(
            AICodedbManagerLayoutMode mode,
            float availableWidth,
            float mainContentWidth,
            float activityWidth,
            float activityHeight,
            float splitterWidth)
        {
            Mode = mode;
            AvailableWidth = Mathf.Max(0f, availableWidth);
            MainContentWidth = Mathf.Max(0f, mainContentWidth);
            ActivityWidth = Mathf.Max(0f, activityWidth);
            ActivityHeight = Mathf.Max(0f, activityHeight);
            SplitterWidth = Mathf.Max(0f, splitterWidth);
        }
    }

    internal static class AICodedbManagerLayout
    {
        internal const float MainContentMinWidth = 560f;
        internal const float ActivityDefaultWidth = 340f;
        internal const float ActivityMinWidth = 280f;
        internal const float ActivityMaxWidth = 720f;
        internal const float SplitterWidth = 6f;
        internal const float CompactActivityMinHeight = 220f;
        internal const float CompactActivityMaxHeight = 360f;
        internal const float CompactActivityHeightRatio = 0.4f;
        internal const float WideLayoutMinWidth = MainContentMinWidth + ActivityMinWidth + SplitterWidth;

        internal static AICodedbManagerLayoutMetrics Resolve(float width, float height, float preferredActivityWidth)
        {
            return Resolve(width, height, preferredActivityWidth, 0f);
        }

        internal static AICodedbManagerLayoutMetrics Resolve(
            float width,
            float height,
            float preferredActivityWidth,
            float panelHorizontalMargin)
        {
            var availableWidth = NormalizeDimension(width);
            var availableHeight = NormalizeDimension(height);
            var normalizedPanelMargin = NormalizeDimension(panelHorizontalMargin);
            var widePanelMargins = normalizedPanelMargin * 2f;
            if (availableWidth >= WideLayoutMinWidth + widePanelMargins)
            {
                var wideUsableWidth = Mathf.Max(0f, availableWidth - widePanelMargins);
                var activityWidth = ClampActivityWidth(preferredActivityWidth, wideUsableWidth);
                var mainWidth = wideUsableWidth - SplitterWidth - activityWidth;
                return new AICodedbManagerLayoutMetrics(
                    AICodedbManagerLayoutMode.Wide,
                    wideUsableWidth,
                    mainWidth,
                    activityWidth,
                    availableHeight,
                    SplitterWidth);
            }

            var compactUsableWidth = Mathf.Max(0f, availableWidth - normalizedPanelMargin);
            var compactActivityHeight = Mathf.Min(
                Mathf.Clamp(
                    availableHeight * CompactActivityHeightRatio,
                    CompactActivityMinHeight,
                    CompactActivityMaxHeight),
                availableHeight);
            return new AICodedbManagerLayoutMetrics(
                AICodedbManagerLayoutMode.Compact,
                compactUsableWidth,
                compactUsableWidth,
                compactUsableWidth,
                compactActivityHeight,
                0f);
        }

        internal static float ClampActivityWidth(float width, float availableWidth)
        {
            availableWidth = NormalizeDimension(availableWidth);
            var maxWidthByMainContent = availableWidth - MainContentMinWidth - SplitterWidth;
            var maxWidth = Mathf.Max(ActivityMinWidth, Mathf.Min(ActivityMaxWidth, maxWidthByMainContent));
            var normalizedWidth = float.IsNaN(width) || float.IsInfinity(width) ? ActivityDefaultWidth : width;
            return Mathf.Clamp(normalizedWidth, ActivityMinWidth, maxWidth);
        }

        private static float NormalizeDimension(float value)
        {
            return float.IsNaN(value) || float.IsInfinity(value) ? 0f : Mathf.Max(0f, value);
        }
    }
}
