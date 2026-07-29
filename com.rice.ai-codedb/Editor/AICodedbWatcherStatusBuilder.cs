using System;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbWatcherState
    {
        Unknown,
        Disabled,
        Paused,
        Pending,
        ManualStopped,
        EditorOffline,
        Starting,
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
        internal string ManualMode { get; }
        internal bool IsManualStopped => string.Equals(ManualMode, "stopped", StringComparison.Ordinal);
        internal bool IsManualStarted => string.Equals(ManualMode, "started", StringComparison.Ordinal);
        internal bool NeedsRepair => State == AICodedbWatcherState.Stale || State == AICodedbWatcherState.DisabledRunning;

        internal AICodedbWatcherStatus(
            AICodedbWatcherState state,
            AICodedbStatusState displayState,
            string label,
            string detail,
            bool hasKnownOptIn,
            bool isOptInEnabled)
            : this(state, displayState, label, detail, hasKnownOptIn, isOptInEnabled, "none")
        {
        }

        internal AICodedbWatcherStatus(
            AICodedbWatcherState state,
            AICodedbStatusState displayState,
            string label,
            string detail,
            bool hasKnownOptIn,
            bool isOptInEnabled,
            string manualMode)
        {
            State = state;
            DisplayState = displayState;
            Label = label ?? string.Empty;
            Detail = detail ?? string.Empty;
            HasKnownOptIn = hasKnownOptIn;
            IsOptInEnabled = isOptInEnabled;
            ManualMode = string.IsNullOrWhiteSpace(manualMode) ? "none" : manualMode;
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
            var enabled = Contains(output, "Start with Unity Editor: ENABLED")
                          || Contains(output, "Watch opt-in: ENABLED");
            var disabled = Contains(output, "Start with Unity Editor: DISABLED")
                           || Contains(output, "Watch opt-in: DISABLED");
            var manualStopped = Contains(output, "Manual runtime: STOPPED");
            var manualStarted = Contains(output, "Manual runtime: STARTED");
            var manualMode = manualStopped ? "stopped" : manualStarted ? "started" : "none";
            var automaticPaused = Contains(output, "Automatic refresh: PAUSED");
            var automaticPending = Contains(output, "Automatic refresh: PENDING");
            var automaticDisabled = Contains(output, "Automatic refresh: DISABLED");
            var automaticStarting = Contains(output, "Automatic refresh: STARTING");
            var automaticEditorOffline = Contains(output, "Automatic refresh: EDITOR_OFFLINE");
            var editorOnline = Contains(output, "Editor demand: ONLINE");
            var editorOffline = Contains(output, "Editor demand: OFFLINE");
            var providerReady = Contains(output, "\"provider_state\":\"ready\"");
            var adapterOperational = Contains(output, "\"adapter_state\":\"watching\"")
                                     || Contains(output, "\"adapter_state\":\"pending\"")
                                     || Contains(output, "\"adapter_state\":\"building\"");
            var adapterFailed = Contains(output, "\"adapter_state\":\"failed\"")
                                || Contains(output, "adapter_build_failed")
                                || Contains(output, "adapter_watcher_failed");
            var ready = providerReady && adapterOperational;
            var running = providerReady
                          || Contains(output, "watch coordinator running")
                          || Contains(output, "\"action\":\"running\"")
                          || Contains(output, "Watch coordinator: ready")
                          || Contains(output, "Watch coordinator: unreachable");
            var stopped = Contains(output, "watch coordinator stopped")
                          || Contains(output, "watch coordinator already_stopped")
                          || Contains(output, "Watch coordinator: stopped")
                          || Contains(output, "\"action\":\"stopped\"");
            var stale = Contains(output, "[STALE]") || Contains(output, "\"action\":\"stale\"");
            if (manualStopped && (running || stale))
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Stale,
                    AICodedbStatusState.Warning,
                    "Stop incomplete",
                    "The current Editor session requested Stop now, but the coordinator is still running.",
                    enabled || disabled,
                    enabled,
                    manualMode);
            }

            if (manualStopped && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.ManualStopped,
                    AICodedbStatusState.Inactive,
                    "Stopped now",
                    "CodeDB is suppressed for the current Editor session.",
                    enabled || disabled,
                    enabled,
                    manualMode);
            }

            if (enabled && editorOnline && automaticStarting && !adapterFailed && !stale)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Starting,
                    AICodedbStatusState.Inactive,
                    "Enabled / Starting",
                    "The Editor owns CodeDB demand and the backend is starting.",
                    true,
                    true);
            }

            if (stale || adapterFailed || ((enabled || manualStarted) && running && !ready))
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Stale,
                    AICodedbStatusState.Warning,
                    "Enabled / Stale",
                    adapterFailed
                        ? "Automatic refresh is enabled, but the Shader adapter watcher failed."
                        : "Automatic refresh is enabled, but provider/adapter coordination is not ready.",
                    enabled || disabled,
                    enabled,
                    manualMode);
            }

            if (manualStarted && ready)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Ready,
                    AICodedbStatusState.Ok,
                    "Started now / Ready",
                    "CodeDB is running for the current Editor session without changing persistent policy.",
                    enabled || disabled,
                    enabled,
                    manualMode);
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

            if ((automaticDisabled || disabled) && disabled && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Disabled,
                    AICodedbStatusState.Inactive,
                    "Off",
                    editorOnline
                        ? "CodeDB is disabled; this Editor session remains online."
                        : "CodeDB is disabled and the coordinator is stopped.",
                    true,
                    false);
            }

            if (enabled && (automaticEditorOffline || editorOffline) && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.EditorOffline,
                    AICodedbStatusState.Inactive,
                    "Enabled / Editor Offline",
                    "CodeDB will start when an interactive Unity Editor session is online.",
                    true,
                    true);
            }

            if (automaticPending && !enabled && !disabled && stopped)
            {
                return new AICodedbWatcherStatus(
                    AICodedbWatcherState.Pending,
                    AICodedbStatusState.Inactive,
                    "Setup Pending",
                    "Automatic refresh will initialize after project Setup is complete.",
                    false,
                    false);
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

            return AICodedbWatcherStatus.Unknown("Watcher state could not be determined from the command output.");
        }

        internal static bool IsWatcherActivity(string actionTitle, string output)
        {
            return Contains(actionTitle, "Watcher")
                   || Contains(output, "Watch opt-in:")
                   || Contains(output, "Start with Unity Editor:")
                   || Contains(output, "Manual runtime:")
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
