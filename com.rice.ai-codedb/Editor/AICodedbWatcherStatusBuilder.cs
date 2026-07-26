using System;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbWatcherState
    {
        Unknown,
        Disabled,
        Paused,
        Pending,
        Ready,
        Stale,
        DisabledRunning,
        Error
    }

    internal readonly struct AICodedbWatcherStatus
    {
        internal AICodedbWatcherState State { get; }
        internal AICodedbStatusState DisplayState { get; }
        internal string Label { get; }
        internal string Detail { get; }
        internal bool HasKnownOptIn { get; }
        internal bool IsOptInEnabled { get; }
        internal bool NeedsRepair => State == AICodedbWatcherState.Stale || State == AICodedbWatcherState.DisabledRunning;

        internal AICodedbWatcherStatus(
            AICodedbWatcherState state,
            AICodedbStatusState displayState,
            string label,
            string detail,
            bool hasKnownOptIn,
            bool isOptInEnabled)
        {
            State = state;
            DisplayState = displayState;
            Label = label ?? string.Empty;
            Detail = detail ?? string.Empty;
            HasKnownOptIn = hasKnownOptIn;
            IsOptInEnabled = isOptInEnabled;
        }

        internal static AICodedbWatcherStatus Unknown(string detail)
        {
            return new AICodedbWatcherStatus(
                AICodedbWatcherState.Unknown,
                AICodedbStatusState.Warning,
                "Unknown",
                detail,
                false,
                false);
        }
    }

    internal static class AICodedbWatcherStatusBuilder
    {
        internal static AICodedbWatcherStatus Build(AICodedbCommandResult result)
        {
            if (result == null)
                return AICodedbWatcherStatus.Unknown("Watcher status has not been checked yet.");

            if (result.TimedOut)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Error,
                    AICodedbStatusState.Error,
                    "Timed Out",
                    "Watcher status exceeded its timeout.",
                    false,
                    false);
            }

            if (!result.Succeeded)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Error,
                    AICodedbStatusState.Error,
                    "Error",
                    FirstNonEmpty(result.StandardError, result.GetSummary()),
                    false,
                    false);
            }

            var output = result.StandardOutput ?? string.Empty;
            var enabled = Contains(output, "Watch opt-in: ENABLED");
            var disabled = Contains(output, "Watch opt-in: DISABLED");
            var automaticPaused = Contains(output, "Automatic refresh: PAUSED");
            var automaticPending = Contains(output, "Automatic refresh: PENDING");
            var providerReady = Contains(output, "\"provider_state\":\"ready\"");
            var adapterOperational = Contains(output, "\"adapter_state\":\"watching\"")
                                     || Contains(output, "\"adapter_state\":\"pending\"")
                                     || Contains(output, "\"adapter_state\":\"building\"");
            var adapterFailed = Contains(output, "\"adapter_state\":\"failed\"")
                                || Contains(output, "adapter_build_failed")
                                || Contains(output, "adapter_watcher_failed");
            var ready = providerReady && adapterOperational;
            var running = providerReady || Contains(output, "watch coordinator running");
            var stopped = Contains(output, "watch coordinator stopped")
                          || Contains(output, "watch coordinator already_stopped");
            var stale = Contains(output, "[STALE]") || Contains(output, "\"action\":\"stale\"");
            var coordinatorStateReported = Contains(output, "\"provider_state\":")
                                           || Contains(output, "\"adapter_state\":")
                                           || Contains(output, "watch coordinator running")
                                           || stopped
                                           || stale;

            if (stale || adapterFailed || (enabled && coordinatorStateReported && !ready))
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Stale,
                    AICodedbStatusState.Warning,
                    "Enabled / Stale",
                    adapterFailed
                        ? "Automatic refresh is enabled, but the Shader adapter watcher failed."
                        : "Automatic refresh is enabled, but provider/adapter coordination is not ready.",
                    enabled,
                    enabled);
            }

            if (disabled && running)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.DisabledRunning,
                    AICodedbStatusState.Warning,
                    "Off / Running",
                    "Automatic refresh is off, but the coordinator is still running.",
                    true,
                    false);
            }

            if (automaticPaused && disabled && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Paused,
                    AICodedbStatusState.Inactive,
                    "Paused",
                    "Automatic refresh is paused for this project.",
                    true,
                    false);
            }

            if (automaticPending && disabled && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Pending,
                    AICodedbStatusState.Inactive,
                    "Automatic / Waiting",
                    "Automatic refresh will start when project Setup is complete.",
                    true,
                    true);
            }

            if (enabled && ready)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Ready,
                    AICodedbStatusState.Ok,
                    "Enabled / Ready",
                    "Automatic refresh is enabled and provider/adapter coordination is ready.",
                    true,
                    true);
            }

            if (disabled && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Disabled,
                    AICodedbStatusState.Inactive,
                    "Off",
                    "Automatic refresh is disabled and the coordinator is stopped.",
                    true,
                    false);
            }

            return AICodedbWatcherStatus.Unknown("Watcher state could not be determined from the command output.");
        }

        internal static bool IsWatcherActivity(string actionTitle, string output)
        {
            return Contains(actionTitle, "Watcher")
                   || Contains(output, "Watch opt-in:")
                   || Contains(output, "Automatic refresh:");
        }

        private static bool Contains(string text, string value)
        {
            return !string.IsNullOrWhiteSpace(text)
                   && text.IndexOf(value, StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static string FirstNonEmpty(string first, string second)
        {
            if (!string.IsNullOrWhiteSpace(first))
                return first.Trim();
            return string.IsNullOrWhiteSpace(second) ? "Watcher status failed." : second.Trim();
        }
    }
}
