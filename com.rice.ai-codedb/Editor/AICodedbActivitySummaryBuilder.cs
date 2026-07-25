using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbActivitySummaryBuilder
    {
        internal static AICodedbActivitySummary Build(string actionTitle, AICodedbCommandResult result)
        {
            if (result == null)
            {
                return new AICodedbActivitySummary(
                    AICodedbStatusState.Warning,
                    "Idle",
                    "No recent command.",
                    "No recent command.",
                    "n/a",
                    "Items",
                    Array.Empty<string>());
            }

            if (AICodedbWatcherStatusBuilder.IsWatcherActivity(actionTitle, result.StandardOutput))
            {
                var watcherStatus = AICodedbWatcherStatusBuilder.Build(result);
                return new AICodedbActivitySummary(
                    watcherStatus.DisplayState,
                    watcherStatus.Label,
                    actionTitle,
                    watcherStatus.Detail,
                    result.GetElapsedText(),
                    "Items",
                    Array.Empty<string>());
            }

            var markerLine = FindResultMarkerLine(result.StandardOutput);
            var items = ExtractItems(result.StandardOutput, markerLine, out var itemsTitle);
            return new AICodedbActivitySummary(
                GetState(result, markerLine),
                GetStatusLabel(result, markerLine, itemsTitle, items.Length),
                actionTitle,
                GetDetail(result, markerLine, items.Length),
                result.GetElapsedText(),
                itemsTitle,
                items);
        }

        private static string FindResultMarkerLine(string output)
        {
            if (string.IsNullOrWhiteSpace(output))
                return string.Empty;

            var lines = output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (ContainsMarker(trimmed, "[OK]")
                    || ContainsMarker(trimmed, "[STALE]")
                    || ContainsMarker(trimmed, "[UNKNOWN]")
                    || ContainsMarker(trimmed, "[NO HIT]")
                    || ContainsMarker(trimmed, "[SKIP]")
                    || ContainsMarker(trimmed, "[CONFLICT]")
                    || ContainsMarker(trimmed, "[FAIL]"))
                    return trimmed;
            }

            return string.Empty;
        }

        private static AICodedbStatusState GetState(AICodedbCommandResult result, string markerLine)
        {
            if (result.TimedOut || !result.Succeeded)
                return AICodedbStatusState.Error;

            if (ContainsMarker(markerLine, "[CONFLICT]"))
                return AICodedbStatusState.Error;

            if (ContainsMarker(markerLine, "[NO HIT]")
                || ContainsMarker(markerLine, "[SKIP]")
                || ContainsMarker(markerLine, "[STALE]")
                || ContainsMarker(markerLine, "[UNKNOWN]"))
                return AICodedbStatusState.Warning;

            return AICodedbStatusState.Ok;
        }

        private static string GetStatusLabel(AICodedbCommandResult result, string markerLine, string itemsTitle, int itemCount)
        {
            if (result.TimedOut)
                return "Timed Out";
            if (!result.Succeeded)
                return "Failed";
            if (ContainsMarker(markerLine, "[CONFLICT]"))
                return "Conflict";
            if (ContainsMarker(markerLine, "[NO HIT]"))
                return "No Hit";
            if (ContainsMarker(markerLine, "[SKIP]"))
                return "Skipped";
            if (ContainsMarker(markerLine, "[STALE]"))
                return "Stale";
            if (ContainsMarker(markerLine, "[UNKNOWN]"))
                return "Unknown";

            if (ContainsMarker(markerLine, "[OK]"))
            {
                if (itemCount == 1)
                    return "OK - 1 " + GetSingularItemLabel(itemsTitle);
                if (itemCount > 1)
                    return $"OK - {itemCount} {GetPluralItemLabel(itemsTitle)}";
                return "OK";
            }

            return "Completed";
        }

        private static string GetDetail(AICodedbCommandResult result, string markerLine, int itemCount)
        {
            if (!string.IsNullOrWhiteSpace(markerLine))
            {
                if (ContainsMarker(markerLine, "[OK]") && itemCount > 0)
                    return string.Empty;
                return StripResultMarker(markerLine);
            }

            if (result.TimedOut)
                return "The command exceeded its timeout.";

            if (!result.Succeeded)
            {
                var error = FirstNonEmptyLine(result.StandardError);
                if (!string.IsNullOrWhiteSpace(error))
                    return error;
            }

            return result.GetSummary();
        }

        private static string[] ExtractItems(string output, string markerLine, out string itemsTitle)
        {
            itemsTitle = "Items";
            var items = new List<string>();
            if (!string.IsNullOrWhiteSpace(output))
            {
                var lines = output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
                foreach (var line in lines)
                {
                    var trimmed = line.Trim();
                    if (!ContainsMarker(trimmed, "[HIT]"))
                        continue;

                    itemsTitle = "Hits";
                    var item = Regex.Replace(trimmed, @"^\[HIT\]\s*", string.Empty, RegexOptions.IgnoreCase).Trim();
                    if (!string.IsNullOrWhiteSpace(item))
                        items.Add(item);
                }
            }

            if (items.Count == 0)
            {
                var legacyHitLocation = ExtractHitLocation(markerLine);
                if (!string.IsNullOrWhiteSpace(legacyHitLocation))
                {
                    itemsTitle = "Hits";
                    items.Add(legacyHitLocation);
                }
            }

            return items.ToArray();
        }

        private static string GetSingularItemLabel(string itemsTitle)
        {
            if (string.Equals(itemsTitle, "Hits", StringComparison.OrdinalIgnoreCase))
                return "Hit";
            if (!string.IsNullOrWhiteSpace(itemsTitle) && itemsTitle.EndsWith("s", StringComparison.Ordinal))
                return itemsTitle.Substring(0, itemsTitle.Length - 1);
            return string.IsNullOrWhiteSpace(itemsTitle) ? "Item" : itemsTitle;
        }

        private static string GetPluralItemLabel(string itemsTitle)
        {
            return string.IsNullOrWhiteSpace(itemsTitle) ? "Items" : itemsTitle;
        }

        private static string ExtractHitLocation(string line)
        {
            if (!ContainsMarker(line, "[OK]"))
                return string.Empty;

            var lineMatch = Regex.Match(line, @"\bin\s+(.+?:\d+)\.?$", RegexOptions.IgnoreCase);
            if (lineMatch.Success)
                return lineMatch.Groups[1].Value.Trim();

            var pathMatch = Regex.Match(line, @"\bin\s+(.+?)\.?$", RegexOptions.IgnoreCase);
            return pathMatch.Success ? pathMatch.Groups[1].Value.Trim() : string.Empty;
        }

        private static string FirstNonEmptyLine(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return string.Empty;

            var lines = text.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (!string.IsNullOrWhiteSpace(trimmed))
                    return trimmed;
            }

            return string.Empty;
        }

        private static bool ContainsMarker(string line, string marker)
        {
            return !string.IsNullOrWhiteSpace(line) && line.StartsWith(marker, StringComparison.OrdinalIgnoreCase);
        }

        private static string StripResultMarker(string line)
        {
            return string.IsNullOrWhiteSpace(line)
                ? string.Empty
                : Regex.Replace(line, @"^\[(?:OK|STALE|UNKNOWN|NO HIT|SKIP|CONFLICT|FAIL)\]\s*", string.Empty, RegexOptions.IgnoreCase);
        }
    }

    internal readonly struct AICodedbActivitySummary
    {
        internal AICodedbStatusState State { get; }
        internal string StatusLabel { get; }
        internal string ActionTitle { get; }
        internal string Detail { get; }
        internal string ElapsedText { get; }
        internal string ItemsTitle { get; }
        internal string[] Items { get; }

        internal AICodedbActivitySummary(
            AICodedbStatusState state,
            string statusLabel,
            string actionTitle,
            string detail,
            string elapsedText,
            string itemsTitle,
            string[] items)
        {
            State = state;
            StatusLabel = statusLabel ?? string.Empty;
            ActionTitle = actionTitle ?? string.Empty;
            Detail = detail ?? string.Empty;
            ElapsedText = elapsedText ?? string.Empty;
            ItemsTitle = itemsTitle ?? string.Empty;
            Items = items ?? Array.Empty<string>();
        }
    }
}
