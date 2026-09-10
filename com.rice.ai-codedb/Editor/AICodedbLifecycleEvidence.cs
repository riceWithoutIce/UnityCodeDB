using System;
using System.Diagnostics;
using System.Threading;
using UnityEditor;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbLifecycleCallbackKind
    {
        InitializeOnLoad,
        DeferredInitialize,
        InitializationCompletion,
        Heartbeat,
        ScriptsReloaded,
        PlayModeTransition,
        BeforeAssemblyReload,
        EditorQuitting,
        ManagerOpen,
        ManagerEnable,
        ManagerGui,
        ManagerTabChanged
    }

    internal enum AICodedbLifecycleWorkKind
    {
        FileSystem,
        Hash,
        Process,
        BlockingLock,
        SynchronousIpc,
        PowerShellOrNode,
        Indexing,
        FullStatus
    }

    internal enum AICodedbManagerObservationKind
    {
        Open,
        Enable,
        Repaint,
        TabChange,
        CacheRead
    }

    internal enum AICodedbManagerStatusRefreshDisposition
    {
        Completed,
        Cancelled,
        Failed
    }

    internal enum AICodedbShutdownDisposition
    {
        NOT_EVALUATED,
        NO_RESPONSE,
        SUCCEEDED,
        FAILED,
        SUPERVISOR_ERROR
    }

    [Serializable]
    internal sealed class AICodedbLifecycleEvidenceDocument
    {
        public int schema_version = 1;
        public string checkpoint = string.Empty;
        public string[] callback_names = Array.Empty<string>();
        public int[] callback_counts = Array.Empty<int>();
        public long[] callback_max_microseconds = Array.Empty<long>();
        public string[] work_names = Array.Empty<string>();
        public int[] work_counts = Array.Empty<int>();
        public int[] main_thread_work_counts = Array.Empty<int>();
        public int domain_reload_count;
        public int play_transition_count;
        public int reconcile_started_count;
        public int reconcile_completed_count;
        public string last_product_state = string.Empty;
        public int manager_open_count;
        public int manager_enable_count;
        public int manager_repaint_count;
        public int manager_tab_change_count;
        public int manager_cache_read_count;
        public int manager_automatic_status_request_count;
        public int manager_explicit_status_request_count;
        public int manager_watcher_status_request_count;
        public int manager_close_count;
        public int manager_close_with_refresh_in_flight_count;
        public int manager_status_refresh_started_count;
        public int manager_status_refresh_completed_count;
        public int manager_status_refresh_cancelled_count;
        public int manager_status_refresh_failed_count;
        public int manager_status_refresh_in_flight_count;
        public int manager_status_refresh_max_in_flight_count;
        public int materializer_command_count;
        public int direct_materializer_fallback_count;
        public int supervisor_ensure_count;
        public int supervisor_missing_state_ensure_count;
        public int supervisor_observation_count;
        public int supervisor_identity_change_count;
        public int supervisor_pid;
        public int coordinator_pid;
        public string selected_instance_id = string.Empty;
        public string selected_generation_id = string.Empty;
        public string prerequisite_evidence_disposition = string.Empty;
        public string coordinator_admission_disposition = string.Empty;
        public string post_admission_disposition = string.Empty;
        public string post_admission_prerequisite_state = string.Empty;
        public string post_admission_installed_state = string.Empty;
        public string post_admission_configured_state = string.Empty;
        public string post_admission_mcp_available_state = string.Empty;
        public string current_instance_state = string.Empty;
        public string current_instance_convergence_plan = string.Empty;
        public int shutdown_request_count;
        public string shutdown_disposition = string.Empty;
        public int editor_quitting_entry_count;
        public int editor_quitting_return_count;
        public int editor_quitting_entry_reconcile_in_flight;
        public int editor_quitting_entry_manager_refresh_in_flight_count;
        public int editor_quitting_entry_queue_pending_count;
        public int editor_quitting_entry_queue_active;
        public int editor_quitting_return_reconcile_in_flight;
        public int editor_quitting_return_manager_refresh_in_flight_count;
        public int editor_quitting_return_queue_pending_count;
        public int editor_quitting_return_queue_active;
        public int main_thread_violation_count;
    }

    internal sealed class AICodedbLifecycleEvidenceCounter
    {
        private readonly int _mainThreadId;
        private readonly int[] _callbackCounts =
            new int[Enum.GetValues(typeof(AICodedbLifecycleCallbackKind)).Length];
        private readonly long[] _callbackMaximumTicks =
            new long[Enum.GetValues(typeof(AICodedbLifecycleCallbackKind)).Length];
        private readonly int[] _workCounts =
            new int[Enum.GetValues(typeof(AICodedbLifecycleWorkKind)).Length];
        private readonly int[] _mainThreadWorkCounts =
            new int[Enum.GetValues(typeof(AICodedbLifecycleWorkKind)).Length];
        private readonly int[] _managerObservationCounts =
            new int[Enum.GetValues(typeof(AICodedbManagerObservationKind)).Length];

        private int _domainReloadCount;
        private int _playTransitionCount;
        private int _reconcileStartedCount;
        private int _reconcileCompletedCount;
        private string _lastProductState = string.Empty;
        private int _managerAutomaticStatusRequestCount;
        private int _managerExplicitStatusRequestCount;
        private int _managerWatcherStatusRequestCount;
        private int _managerCloseCount;
        private int _managerCloseWithRefreshInFlightCount;
        private int _managerStatusRefreshStartedCount;
        private int _managerStatusRefreshCompletedCount;
        private int _managerStatusRefreshCancelledCount;
        private int _managerStatusRefreshFailedCount;
        private int _managerStatusRefreshInFlightCount;
        private int _managerStatusRefreshMaximumInFlightCount;
        private int _materializerCommandCount;
        private int _directMaterializerFallbackCount;
        private int _supervisorEnsureCount;
        private int _supervisorMissingStateEnsureCount;
        private int _supervisorObservationCount;
        private int _supervisorIdentityChangeCount;
        private int _supervisorPid;
        private int _coordinatorPid;
        private string _selectedInstanceId = string.Empty;
        private string _selectedGenerationId = string.Empty;
        private string _prerequisiteEvidenceDisposition = string.Empty;
        private string _coordinatorAdmissionDisposition = string.Empty;
        private string _postAdmissionDisposition = string.Empty;
        private string _postAdmissionPrerequisiteState = string.Empty;
        private string _postAdmissionInstalledState = string.Empty;
        private string _postAdmissionConfiguredState = string.Empty;
        private string _postAdmissionMcpAvailableState = string.Empty;
        private string _currentInstanceState = string.Empty;
        private string _currentInstanceConvergencePlan = string.Empty;
        private int _shutdownRequestCount;
        private string _shutdownDisposition = string.Empty;
        private int _editorQuittingEntryCount;
        private int _editorQuittingReturnCount;
        private int _editorQuittingEntryReconcileInFlight;
        private int _editorQuittingEntryManagerRefreshInFlightCount;
        private int _editorQuittingEntryQueuePendingCount;
        private int _editorQuittingEntryQueueActive;
        private int _editorQuittingReturnReconcileInFlight;
        private int _editorQuittingReturnManagerRefreshInFlightCount;
        private int _editorQuittingReturnQueuePendingCount;
        private int _editorQuittingReturnQueueActive;

        internal AICodedbLifecycleEvidenceCounter(int mainThreadId)
        {
            _mainThreadId = mainThreadId;
            _shutdownDisposition = AICodedbShutdownDisposition.NOT_EVALUATED.ToString();
            ResetPostAdmissionEvidence();
        }

        internal bool HasMainThreadIdentity => _mainThreadId != 0;

        internal void RecordCallback(AICodedbLifecycleCallbackKind kind, long elapsedTicks)
        {
            var index = (int)kind;
            Interlocked.Increment(ref _callbackCounts[index]);
            UpdateMaximum(ref _callbackMaximumTicks[index], Math.Max(0L, elapsedTicks));
        }

        internal void RecordWork(AICodedbLifecycleWorkKind kind, int threadId)
        {
            var index = (int)kind;
            Interlocked.Increment(ref _workCounts[index]);
            if (_mainThreadId != 0 && threadId == _mainThreadId)
                Interlocked.Increment(ref _mainThreadWorkCounts[index]);
        }

        internal void RecordDomainReload()
        {
            Interlocked.Increment(ref _domainReloadCount);
        }

        internal void RecordPlayTransition()
        {
            Interlocked.Increment(ref _playTransitionCount);
        }

        internal void RecordReconcileStarted()
        {
            Interlocked.Increment(ref _reconcileStartedCount);
        }

        internal void RecordReconcileCompleted(AICodedbProductState state)
        {
            Interlocked.Increment(ref _reconcileCompletedCount);
            Interlocked.Exchange(ref _lastProductState, state.ToString());
        }

        internal void RecordManagerObservation(AICodedbManagerObservationKind kind)
        {
            Interlocked.Increment(ref _managerObservationCounts[(int)kind]);
        }

        internal void RecordManagerStatusRequest(bool explicitRequest)
        {
            if (explicitRequest)
                Interlocked.Increment(ref _managerExplicitStatusRequestCount);
            else
                Interlocked.Increment(ref _managerAutomaticStatusRequestCount);
        }

        internal void RecordManagerWatcherStatusRequest()
        {
            Interlocked.Increment(ref _managerWatcherStatusRequestCount);
        }

        internal void RecordManagerClosed()
        {
            Interlocked.Increment(ref _managerCloseCount);
            if (Volatile.Read(ref _managerStatusRefreshInFlightCount) > 0)
                Interlocked.Increment(ref _managerCloseWithRefreshInFlightCount);
        }

        internal void RecordManagerStatusRefreshStarted()
        {
            Interlocked.Increment(ref _managerStatusRefreshStartedCount);
            var inFlight = Interlocked.Increment(ref _managerStatusRefreshInFlightCount);
            UpdateMaximum(ref _managerStatusRefreshMaximumInFlightCount, inFlight);
        }

        internal void RecordManagerStatusRefreshFinished(
            AICodedbManagerStatusRefreshDisposition disposition)
        {
            switch (disposition)
            {
                case AICodedbManagerStatusRefreshDisposition.Completed:
                    Interlocked.Increment(ref _managerStatusRefreshCompletedCount);
                    break;
                case AICodedbManagerStatusRefreshDisposition.Cancelled:
                    Interlocked.Increment(ref _managerStatusRefreshCancelledCount);
                    break;
                default:
                    Interlocked.Increment(ref _managerStatusRefreshFailedCount);
                    break;
            }

            if (Interlocked.Decrement(ref _managerStatusRefreshInFlightCount) < 0)
                Interlocked.Exchange(ref _managerStatusRefreshInFlightCount, 0);
        }

        internal void RecordMaterializerCommand(bool directFallback)
        {
            Interlocked.Increment(ref _materializerCommandCount);
            if (directFallback)
                Interlocked.Increment(ref _directMaterializerFallbackCount);
        }

        internal void RecordSupervisorEnsure(bool stateWasMissing)
        {
            Interlocked.Increment(ref _supervisorEnsureCount);
            if (stateWasMissing)
                Interlocked.Increment(ref _supervisorMissingStateEnsureCount);
        }

        internal void RecordSupervisorObservation(AICodedbSupervisorSnapshot snapshot)
        {
            if (snapshot == null
                || !snapshot.IsConnected
                || snapshot.SupervisorProcessId <= 0
                || !IsBoundedIdentifier(snapshot.SelectedInstanceId)
                || !IsBoundedIdentifier(snapshot.SelectedGenerationId))
                return;

            Interlocked.Increment(ref _supervisorObservationCount);
            var identityChanged = false;
            identityChanged |= TrackIdentity(ref _supervisorPid, snapshot.SupervisorProcessId);
            if (snapshot.CoordinatorProcessId > 0)
                identityChanged |= TrackIdentity(ref _coordinatorPid, snapshot.CoordinatorProcessId);
            identityChanged |= TrackIdentity(ref _selectedInstanceId, snapshot.SelectedInstanceId);
            identityChanged |= TrackIdentity(ref _selectedGenerationId, snapshot.SelectedGenerationId);
            if (identityChanged)
                Interlocked.Increment(ref _supervisorIdentityChangeCount);
        }

        internal void RecordCoordinatorAdmissionDisposition(
            AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition disposition)
        {
            Interlocked.Exchange(
                ref _coordinatorAdmissionDisposition,
                SanitizeCode(disposition.ToString()));
        }

        internal void RecordPrerequisiteEvidenceDisposition(
            AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition disposition)
        {
            Interlocked.Exchange(
                ref _prerequisiteEvidenceDisposition,
                SanitizeCode(disposition.ToString()));
        }

        internal void ResetPostAdmissionEvidence()
        {
            var notEvaluated = SanitizeCode(
                AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.NotEvaluated.ToString());
            Interlocked.Exchange(ref _postAdmissionDisposition, notEvaluated);
            Interlocked.Exchange(ref _postAdmissionPrerequisiteState, notEvaluated);
            Interlocked.Exchange(ref _postAdmissionInstalledState, notEvaluated);
            Interlocked.Exchange(ref _postAdmissionConfiguredState, notEvaluated);
            Interlocked.Exchange(ref _postAdmissionMcpAvailableState, notEvaluated);
            Interlocked.Exchange(ref _currentInstanceState, notEvaluated);
            Interlocked.Exchange(ref _currentInstanceConvergencePlan, notEvaluated);
        }

        internal void RecordPostAdmissionDisposition(
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition disposition)
        {
            Interlocked.Exchange(ref _postAdmissionDisposition, SanitizeCode(disposition.ToString()));
        }

        internal void RecordPostAdmissionProductLayers(
            AICodedbProductLayerState prerequisite,
            AICodedbProductLayerState installed,
            AICodedbProductLayerState configured,
            AICodedbProductLayerState mcpAvailable)
        {
            Interlocked.Exchange(ref _postAdmissionPrerequisiteState, SanitizeCode(prerequisite.ToString()));
            Interlocked.Exchange(ref _postAdmissionInstalledState, SanitizeCode(installed.ToString()));
            Interlocked.Exchange(ref _postAdmissionConfiguredState, SanitizeCode(configured.ToString()));
            Interlocked.Exchange(ref _postAdmissionMcpAvailableState, SanitizeCode(mcpAvailable.ToString()));
        }

        internal void RecordCurrentInstanceState(AICodedbCurrentInstanceState state)
        {
            Interlocked.Exchange(ref _currentInstanceState, SanitizeCode(state.ToString()));
        }

        internal void RecordCurrentInstanceConvergencePlan(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan plan)
        {
            Interlocked.Exchange(ref _currentInstanceConvergencePlan, SanitizeCode(plan.ToString()));
        }

        internal void RecordShutdownRequested()
        {
            Interlocked.Increment(ref _shutdownRequestCount);
        }

        internal void RecordShutdownDisposition(AICodedbSupervisorCommandResponse response)
        {
            var disposition = response == null
                ? AICodedbShutdownDisposition.NO_RESPONSE
                : !string.IsNullOrWhiteSpace(response.ErrorCode)
                    ? AICodedbShutdownDisposition.SUPERVISOR_ERROR
                    : response.Succeeded
                        ? AICodedbShutdownDisposition.SUCCEEDED
                        : AICodedbShutdownDisposition.FAILED;
            Interlocked.Exchange(ref _shutdownDisposition, disposition.ToString());
            if (response != null)
                RecordSupervisorObservation(response.Snapshot);
        }

        internal void RecordEditorQuittingBoundary(
            bool entering,
            bool reconcileInFlight,
            AICodedbSupervisorQueueSnapshot queueSnapshot)
        {
            if (entering)
            {
                Interlocked.Increment(ref _editorQuittingEntryCount);
                Interlocked.Exchange(ref _editorQuittingEntryReconcileInFlight, reconcileInFlight ? 1 : 0);
                Interlocked.Exchange(
                    ref _editorQuittingEntryManagerRefreshInFlightCount,
                    Math.Max(0, Volatile.Read(ref _managerStatusRefreshInFlightCount)));
                Interlocked.Exchange(
                    ref _editorQuittingEntryQueuePendingCount,
                    Math.Max(0, queueSnapshot.PendingCount));
                Interlocked.Exchange(
                    ref _editorQuittingEntryQueueActive,
                    queueSnapshot.HasActiveRequest ? 1 : 0);
                return;
            }

            Interlocked.Increment(ref _editorQuittingReturnCount);
            Interlocked.Exchange(ref _editorQuittingReturnReconcileInFlight, reconcileInFlight ? 1 : 0);
            Interlocked.Exchange(
                ref _editorQuittingReturnManagerRefreshInFlightCount,
                Math.Max(0, Volatile.Read(ref _managerStatusRefreshInFlightCount)));
            Interlocked.Exchange(
                ref _editorQuittingReturnQueuePendingCount,
                Math.Max(0, queueSnapshot.PendingCount));
            Interlocked.Exchange(
                ref _editorQuittingReturnQueueActive,
                queueSnapshot.HasActiveRequest ? 1 : 0);
        }

        private static string SanitizeEnumCode(Type enumType, string value, string fallback)
        {
            var sanitized = SanitizeCode(value);
            if (!string.Equals(value ?? string.Empty, sanitized, StringComparison.Ordinal))
                return fallback;

            try
            {
                var parsed = Enum.Parse(enumType, sanitized, false);
                if (!Enum.IsDefined(enumType, parsed))
                    return fallback;
                var canonical = SanitizeCode(parsed.ToString());
                return string.Equals(canonical, sanitized, StringComparison.Ordinal)
                    ? canonical
                    : fallback;
            }
            catch (ArgumentException)
            {
                return fallback;
            }
            catch (OverflowException)
            {
                return fallback;
            }
        }

        internal AICodedbLifecycleEvidenceDocument Capture(string checkpoint)
        {
            var callbackCounts = Snapshot(_callbackCounts);
            var callbackMaximumTicks = Snapshot(_callbackMaximumTicks);
            var callbackMaximumMicroseconds = new long[callbackMaximumTicks.Length];
            for (var index = 0; index < callbackMaximumTicks.Length; index++)
            {
                callbackMaximumMicroseconds[index] = Stopwatch.Frequency <= 0
                    ? 0L
                    : callbackMaximumTicks[index] * 1000000L / Stopwatch.Frequency;
            }

            var mainThreadWorkCounts = Snapshot(_mainThreadWorkCounts);
            var mainThreadViolationCount = 0;
            foreach (var count in mainThreadWorkCounts)
                mainThreadViolationCount += count;

            return new AICodedbLifecycleEvidenceDocument
            {
                checkpoint = SanitizeCode(checkpoint),
                callback_names = Enum.GetNames(typeof(AICodedbLifecycleCallbackKind)),
                callback_counts = callbackCounts,
                callback_max_microseconds = callbackMaximumMicroseconds,
                work_names = Enum.GetNames(typeof(AICodedbLifecycleWorkKind)),
                work_counts = Snapshot(_workCounts),
                main_thread_work_counts = mainThreadWorkCounts,
                domain_reload_count = Volatile.Read(ref _domainReloadCount),
                play_transition_count = Volatile.Read(ref _playTransitionCount),
                reconcile_started_count = Volatile.Read(ref _reconcileStartedCount),
                reconcile_completed_count = Volatile.Read(ref _reconcileCompletedCount),
                last_product_state = SanitizeCode(Volatile.Read(ref _lastProductState)),
                manager_open_count = Volatile.Read(ref _managerObservationCounts[(int)AICodedbManagerObservationKind.Open]),
                manager_enable_count = Volatile.Read(ref _managerObservationCounts[(int)AICodedbManagerObservationKind.Enable]),
                manager_repaint_count = Volatile.Read(ref _managerObservationCounts[(int)AICodedbManagerObservationKind.Repaint]),
                manager_tab_change_count = Volatile.Read(ref _managerObservationCounts[(int)AICodedbManagerObservationKind.TabChange]),
                manager_cache_read_count = Volatile.Read(ref _managerObservationCounts[(int)AICodedbManagerObservationKind.CacheRead]),
                manager_automatic_status_request_count = Volatile.Read(ref _managerAutomaticStatusRequestCount),
                manager_explicit_status_request_count = Volatile.Read(ref _managerExplicitStatusRequestCount),
                manager_watcher_status_request_count = Volatile.Read(ref _managerWatcherStatusRequestCount),
                manager_close_count = Volatile.Read(ref _managerCloseCount),
                manager_close_with_refresh_in_flight_count = Volatile.Read(
                    ref _managerCloseWithRefreshInFlightCount),
                manager_status_refresh_started_count = Volatile.Read(ref _managerStatusRefreshStartedCount),
                manager_status_refresh_completed_count = Volatile.Read(ref _managerStatusRefreshCompletedCount),
                manager_status_refresh_cancelled_count = Volatile.Read(ref _managerStatusRefreshCancelledCount),
                manager_status_refresh_failed_count = Volatile.Read(ref _managerStatusRefreshFailedCount),
                manager_status_refresh_in_flight_count = Math.Max(
                    0,
                    Volatile.Read(ref _managerStatusRefreshInFlightCount)),
                manager_status_refresh_max_in_flight_count = Volatile.Read(
                    ref _managerStatusRefreshMaximumInFlightCount),
                materializer_command_count = Volatile.Read(ref _materializerCommandCount),
                direct_materializer_fallback_count = Volatile.Read(ref _directMaterializerFallbackCount),
                supervisor_ensure_count = Volatile.Read(ref _supervisorEnsureCount),
                supervisor_missing_state_ensure_count = Volatile.Read(ref _supervisorMissingStateEnsureCount),
                supervisor_observation_count = Volatile.Read(ref _supervisorObservationCount),
                supervisor_identity_change_count = Volatile.Read(ref _supervisorIdentityChangeCount),
                supervisor_pid = Volatile.Read(ref _supervisorPid),
                coordinator_pid = Volatile.Read(ref _coordinatorPid),
                selected_instance_id = Volatile.Read(ref _selectedInstanceId) ?? string.Empty,
                selected_generation_id = Volatile.Read(ref _selectedGenerationId) ?? string.Empty,
                prerequisite_evidence_disposition = SanitizeCode(
                    Volatile.Read(ref _prerequisiteEvidenceDisposition)),
                coordinator_admission_disposition = SanitizeCode(
                    Volatile.Read(ref _coordinatorAdmissionDisposition)),
                post_admission_disposition = SanitizeCode(Volatile.Read(ref _postAdmissionDisposition)),
                post_admission_prerequisite_state = SanitizeCode(
                    Volatile.Read(ref _postAdmissionPrerequisiteState)),
                post_admission_installed_state = SanitizeCode(
                    Volatile.Read(ref _postAdmissionInstalledState)),
                post_admission_configured_state = SanitizeCode(
                    Volatile.Read(ref _postAdmissionConfiguredState)),
                post_admission_mcp_available_state = SanitizeCode(
                    Volatile.Read(ref _postAdmissionMcpAvailableState)),
                current_instance_state = SanitizeCode(Volatile.Read(ref _currentInstanceState)),
                current_instance_convergence_plan = SanitizeCode(
                    Volatile.Read(ref _currentInstanceConvergencePlan)),
                shutdown_request_count = Volatile.Read(ref _shutdownRequestCount),
                shutdown_disposition = SanitizeEnumCode(
                    typeof(AICodedbShutdownDisposition),
                    Volatile.Read(ref _shutdownDisposition),
                    AICodedbShutdownDisposition.NOT_EVALUATED.ToString()),
                editor_quitting_entry_count = Volatile.Read(ref _editorQuittingEntryCount),
                editor_quitting_return_count = Volatile.Read(ref _editorQuittingReturnCount),
                editor_quitting_entry_reconcile_in_flight = Volatile.Read(
                    ref _editorQuittingEntryReconcileInFlight),
                editor_quitting_entry_manager_refresh_in_flight_count = Volatile.Read(
                    ref _editorQuittingEntryManagerRefreshInFlightCount),
                editor_quitting_entry_queue_pending_count = Volatile.Read(
                    ref _editorQuittingEntryQueuePendingCount),
                editor_quitting_entry_queue_active = Volatile.Read(ref _editorQuittingEntryQueueActive),
                editor_quitting_return_reconcile_in_flight = Volatile.Read(
                    ref _editorQuittingReturnReconcileInFlight),
                editor_quitting_return_manager_refresh_in_flight_count = Volatile.Read(
                    ref _editorQuittingReturnManagerRefreshInFlightCount),
                editor_quitting_return_queue_pending_count = Volatile.Read(
                    ref _editorQuittingReturnQueuePendingCount),
                editor_quitting_return_queue_active = Volatile.Read(ref _editorQuittingReturnQueueActive),
                main_thread_violation_count = mainThreadViolationCount
            };
        }

        internal void Restore(AICodedbLifecycleEvidenceDocument document)
        {
            if (document == null || document.schema_version != 1)
                return;

            Restore(_callbackCounts, document.callback_counts);
            RestoreMicroseconds(_callbackMaximumTicks, document.callback_max_microseconds);
            Restore(_workCounts, document.work_counts);
            Restore(_mainThreadWorkCounts, document.main_thread_work_counts);
            Interlocked.Exchange(ref _domainReloadCount, Math.Max(0, document.domain_reload_count));
            Interlocked.Exchange(ref _playTransitionCount, Math.Max(0, document.play_transition_count));
            Interlocked.Exchange(ref _reconcileStartedCount, Math.Max(0, document.reconcile_started_count));
            Interlocked.Exchange(ref _reconcileCompletedCount, Math.Max(0, document.reconcile_completed_count));
            Interlocked.Exchange(ref _lastProductState, SanitizeCode(document.last_product_state));
            RestoreManagerObservation(AICodedbManagerObservationKind.Open, document.manager_open_count);
            RestoreManagerObservation(AICodedbManagerObservationKind.Enable, document.manager_enable_count);
            RestoreManagerObservation(AICodedbManagerObservationKind.Repaint, document.manager_repaint_count);
            RestoreManagerObservation(AICodedbManagerObservationKind.TabChange, document.manager_tab_change_count);
            RestoreManagerObservation(AICodedbManagerObservationKind.CacheRead, document.manager_cache_read_count);
            Interlocked.Exchange(ref _managerAutomaticStatusRequestCount, Math.Max(0, document.manager_automatic_status_request_count));
            Interlocked.Exchange(ref _managerExplicitStatusRequestCount, Math.Max(0, document.manager_explicit_status_request_count));
            Interlocked.Exchange(ref _managerWatcherStatusRequestCount, Math.Max(0, document.manager_watcher_status_request_count));
            Interlocked.Exchange(ref _managerCloseCount, Math.Max(0, document.manager_close_count));
            Interlocked.Exchange(
                ref _managerCloseWithRefreshInFlightCount,
                Math.Max(0, document.manager_close_with_refresh_in_flight_count));
            Interlocked.Exchange(
                ref _managerStatusRefreshStartedCount,
                Math.Max(0, document.manager_status_refresh_started_count));
            Interlocked.Exchange(
                ref _managerStatusRefreshCompletedCount,
                Math.Max(0, document.manager_status_refresh_completed_count));
            Interlocked.Exchange(
                ref _managerStatusRefreshCancelledCount,
                Math.Max(0, document.manager_status_refresh_cancelled_count));
            Interlocked.Exchange(
                ref _managerStatusRefreshFailedCount,
                Math.Max(0, document.manager_status_refresh_failed_count));
            Interlocked.Exchange(ref _managerStatusRefreshInFlightCount, 0);
            Interlocked.Exchange(
                ref _managerStatusRefreshMaximumInFlightCount,
                Math.Max(0, document.manager_status_refresh_max_in_flight_count));
            Interlocked.Exchange(ref _materializerCommandCount, Math.Max(0, document.materializer_command_count));
            Interlocked.Exchange(ref _directMaterializerFallbackCount, Math.Max(0, document.direct_materializer_fallback_count));
            Interlocked.Exchange(ref _supervisorEnsureCount, Math.Max(0, document.supervisor_ensure_count));
            Interlocked.Exchange(ref _supervisorMissingStateEnsureCount, Math.Max(0, document.supervisor_missing_state_ensure_count));
            Interlocked.Exchange(ref _supervisorObservationCount, Math.Max(0, document.supervisor_observation_count));
            Interlocked.Exchange(ref _supervisorIdentityChangeCount, Math.Max(0, document.supervisor_identity_change_count));
            Interlocked.Exchange(ref _supervisorPid, Math.Max(0, document.supervisor_pid));
            Interlocked.Exchange(ref _coordinatorPid, Math.Max(0, document.coordinator_pid));
            Interlocked.Exchange(ref _selectedInstanceId, SanitizeIdentifier(document.selected_instance_id));
            Interlocked.Exchange(ref _selectedGenerationId, SanitizeIdentifier(document.selected_generation_id));
            Interlocked.Exchange(
                ref _prerequisiteEvidenceDisposition,
                SanitizeCode(document.prerequisite_evidence_disposition));
            Interlocked.Exchange(
                ref _coordinatorAdmissionDisposition,
                SanitizeCode(document.coordinator_admission_disposition));
            var notEvaluated = SanitizeCode(
                AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.NotEvaluated.ToString());
            Interlocked.Exchange(
                ref _postAdmissionDisposition,
                SanitizeEnumCode(
                    typeof(AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition),
                    document.post_admission_disposition,
                    notEvaluated));
            Interlocked.Exchange(
                ref _postAdmissionPrerequisiteState,
                SanitizeEnumCode(
                    typeof(AICodedbProductLayerState),
                    document.post_admission_prerequisite_state,
                    notEvaluated));
            Interlocked.Exchange(
                ref _postAdmissionInstalledState,
                SanitizeEnumCode(
                    typeof(AICodedbProductLayerState),
                    document.post_admission_installed_state,
                    notEvaluated));
            Interlocked.Exchange(
                ref _postAdmissionConfiguredState,
                SanitizeEnumCode(
                    typeof(AICodedbProductLayerState),
                    document.post_admission_configured_state,
                    notEvaluated));
            Interlocked.Exchange(
                ref _postAdmissionMcpAvailableState,
                SanitizeEnumCode(
                    typeof(AICodedbProductLayerState),
                    document.post_admission_mcp_available_state,
                    notEvaluated));
            Interlocked.Exchange(
                ref _currentInstanceState,
                SanitizeEnumCode(
                    typeof(AICodedbCurrentInstanceState),
                    document.current_instance_state,
                    notEvaluated));
            Interlocked.Exchange(
                ref _currentInstanceConvergencePlan,
                SanitizeEnumCode(
                    typeof(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan),
                    document.current_instance_convergence_plan,
                    notEvaluated));
            Interlocked.Exchange(ref _shutdownRequestCount, Math.Max(0, document.shutdown_request_count));
            Interlocked.Exchange(
                ref _shutdownDisposition,
                SanitizeEnumCode(
                    typeof(AICodedbShutdownDisposition),
                    document.shutdown_disposition,
                    AICodedbShutdownDisposition.NOT_EVALUATED.ToString()));
            Interlocked.Exchange(
                ref _editorQuittingEntryCount,
                Math.Max(0, document.editor_quitting_entry_count));
            Interlocked.Exchange(
                ref _editorQuittingReturnCount,
                Math.Max(0, document.editor_quitting_return_count));
            Interlocked.Exchange(
                ref _editorQuittingEntryReconcileInFlight,
                document.editor_quitting_entry_reconcile_in_flight > 0 ? 1 : 0);
            Interlocked.Exchange(
                ref _editorQuittingEntryManagerRefreshInFlightCount,
                Math.Max(0, document.editor_quitting_entry_manager_refresh_in_flight_count));
            Interlocked.Exchange(
                ref _editorQuittingEntryQueuePendingCount,
                Math.Max(0, document.editor_quitting_entry_queue_pending_count));
            Interlocked.Exchange(
                ref _editorQuittingEntryQueueActive,
                document.editor_quitting_entry_queue_active > 0 ? 1 : 0);
            Interlocked.Exchange(
                ref _editorQuittingReturnReconcileInFlight,
                document.editor_quitting_return_reconcile_in_flight > 0 ? 1 : 0);
            Interlocked.Exchange(
                ref _editorQuittingReturnManagerRefreshInFlightCount,
                Math.Max(0, document.editor_quitting_return_manager_refresh_in_flight_count));
            Interlocked.Exchange(
                ref _editorQuittingReturnQueuePendingCount,
                Math.Max(0, document.editor_quitting_return_queue_pending_count));
            Interlocked.Exchange(
                ref _editorQuittingReturnQueueActive,
                document.editor_quitting_return_queue_active > 0 ? 1 : 0);
        }

        private void RestoreManagerObservation(AICodedbManagerObservationKind kind, int value)
        {
            Interlocked.Exchange(ref _managerObservationCounts[(int)kind], Math.Max(0, value));
        }

        private static void UpdateMaximum(ref int location, int value)
        {
            var observed = Volatile.Read(ref location);
            while (value > observed)
            {
                var previous = Interlocked.CompareExchange(ref location, value, observed);
                if (previous == observed)
                    return;
                observed = previous;
            }
        }

        private static void UpdateMaximum(ref long location, long value)
        {
            var observed = Volatile.Read(ref location);
            while (value > observed)
            {
                var previous = Interlocked.CompareExchange(ref location, value, observed);
                if (previous == observed)
                    return;
                observed = previous;
            }
        }

        private static bool TrackIdentity(ref int location, int value)
        {
            var observed = Volatile.Read(ref location);
            if (observed == 0)
            {
                observed = Interlocked.CompareExchange(ref location, value, 0);
                if (observed == 0)
                    return false;
            }
            return observed != value;
        }

        private static bool TrackIdentity(ref string location, string value)
        {
            var observed = Volatile.Read(ref location);
            if (string.IsNullOrEmpty(observed))
            {
                observed = Interlocked.CompareExchange(ref location, value, string.Empty);
                if (string.IsNullOrEmpty(observed))
                    return false;
            }
            return !string.Equals(observed, value, StringComparison.Ordinal);
        }

        private static bool IsBoundedIdentifier(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 64)
                return false;
            foreach (var character in value)
            {
                if ((character >= 'a' && character <= 'z')
                    || (character >= 'A' && character <= 'Z')
                    || (character >= '0' && character <= '9')
                    || character == '.'
                    || character == '_'
                    || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        private static string SanitizeIdentifier(string value)
        {
            return IsBoundedIdentifier(value) ? value : string.Empty;
        }

        private static string SanitizeCode(string value)
        {
            return IsBoundedIdentifier(value) ? value : string.Empty;
        }

        private static int[] Snapshot(int[] values)
        {
            var snapshot = new int[values.Length];
            for (var index = 0; index < values.Length; index++)
                snapshot[index] = Volatile.Read(ref values[index]);
            return snapshot;
        }

        private static long[] Snapshot(long[] values)
        {
            var snapshot = new long[values.Length];
            for (var index = 0; index < values.Length; index++)
                snapshot[index] = Volatile.Read(ref values[index]);
            return snapshot;
        }

        private static void Restore(int[] target, int[] source)
        {
            if (source == null || source.Length != target.Length)
                return;
            for (var index = 0; index < target.Length; index++)
                Interlocked.Exchange(ref target[index], Math.Max(0, source[index]));
        }

        private static void RestoreMicroseconds(long[] target, long[] source)
        {
            if (source == null || source.Length != target.Length || Stopwatch.Frequency <= 0)
                return;
            for (var index = 0; index < target.Length; index++)
            {
                var ticks = Math.Max(0L, source[index]) * Stopwatch.Frequency / 1000000L;
                Interlocked.Exchange(ref target[index], ticks);
            }
        }
    }

    internal struct AICodedbLifecycleEvidenceScope : IDisposable
    {
        private readonly AICodedbLifecycleEvidenceCounter _counter;
        private readonly AICodedbLifecycleCallbackKind _kind;
        private readonly long _startedAt;

        internal AICodedbLifecycleEvidenceScope(
            AICodedbLifecycleEvidenceCounter counter,
            AICodedbLifecycleCallbackKind kind)
        {
            _counter = counter;
            _kind = kind;
            _startedAt = Stopwatch.GetTimestamp();
        }

        public void Dispose()
        {
            if (_counter != null)
                _counter.RecordCallback(_kind, Stopwatch.GetTimestamp() - _startedAt);
        }
    }

    internal static class AICodedbLifecycleEvidence
    {
        internal const string LogPrefix = "CODEDB_S12_EVIDENCE ";

        private const string SessionStateKey = "Rice.AICodedb.S12.LifecycleEvidence";
        private static AICodedbLifecycleEvidenceCounter _counter;

        internal static void InitializeMainThread()
        {
            var existing = Volatile.Read(ref _counter);
            if (existing != null && existing.HasMainThreadIdentity)
                return;

            var counter = new AICodedbLifecycleEvidenceCounter(
                Thread.CurrentThread.ManagedThreadId);
            var persisted = existing == null
                ? SessionState.GetString(SessionStateKey, string.Empty)
                : JsonUtility.ToJson(existing.Capture("thread_identity"));
            if (!string.IsNullOrWhiteSpace(persisted))
            {
                try
                {
                    counter.Restore(JsonUtility.FromJson<AICodedbLifecycleEvidenceDocument>(persisted));
                }
                catch
                {
                    // Invalid prior-session diagnostics are ignored. They are
                    // observations only and never influence lifecycle behavior.
                }
            }
            Interlocked.Exchange(ref _counter, counter);
        }

        internal static AICodedbLifecycleEvidenceScope BeginCallback(
            AICodedbLifecycleCallbackKind kind)
        {
            return new AICodedbLifecycleEvidenceScope(GetCounter(), kind);
        }

        internal static void RecordWork(AICodedbLifecycleWorkKind kind)
        {
            GetCounter().RecordWork(kind, Thread.CurrentThread.ManagedThreadId);
        }

        internal static void RecordDomainReload()
        {
            GetCounter().RecordDomainReload();
        }

        internal static void RecordPlayTransition()
        {
            GetCounter().RecordPlayTransition();
        }

        internal static void RecordReconcileStarted()
        {
            GetCounter().RecordReconcileStarted();
        }

        internal static void RecordReconcileCompleted(AICodedbProductState state)
        {
            GetCounter().RecordReconcileCompleted(state);
        }

        internal static void RecordManagerObservation(AICodedbManagerObservationKind kind)
        {
            GetCounter().RecordManagerObservation(kind);
        }

        internal static void RecordManagerStatusRequest(bool explicitRequest)
        {
            GetCounter().RecordManagerStatusRequest(explicitRequest);
        }

        internal static void RecordManagerWatcherStatusRequest()
        {
            GetCounter().RecordManagerWatcherStatusRequest();
        }

        internal static void RecordManagerClosed()
        {
            GetCounter().RecordManagerClosed();
            EmitWorkerCheckpoint("manager_closed");
        }

        internal static void RecordManagerStatusRefreshStarted()
        {
            GetCounter().RecordManagerStatusRefreshStarted();
        }

        internal static void RecordManagerStatusRefreshFinished(
            AICodedbManagerStatusRefreshDisposition disposition)
        {
            GetCounter().RecordManagerStatusRefreshFinished(disposition);
        }

        internal static void RecordMainThreadWork(AICodedbLifecycleWorkKind kind)
        {
            GetCounter().RecordWork(kind, Thread.CurrentThread.ManagedThreadId);
        }

        internal static void RecordMaterializerCommand(bool directFallback)
        {
            GetCounter().RecordMaterializerCommand(directFallback);
        }

        internal static void RecordSupervisorEnsure(bool stateWasMissing)
        {
            GetCounter().RecordSupervisorEnsure(stateWasMissing);
        }

        internal static void RecordSupervisorObservation(AICodedbSupervisorSnapshot snapshot)
        {
            GetCounter().RecordSupervisorObservation(snapshot);
        }

        internal static void RecordCoordinatorAdmissionDisposition(
            AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition disposition)
        {
            GetCounter().RecordCoordinatorAdmissionDisposition(disposition);
        }

        internal static void RecordPrerequisiteEvidenceDisposition(
            AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition disposition)
        {
            GetCounter().RecordPrerequisiteEvidenceDisposition(disposition);
        }

        internal static void ResetPostAdmissionEvidence()
        {
            GetCounter().ResetPostAdmissionEvidence();
        }

        internal static void RecordPostAdmissionDisposition(
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition disposition)
        {
            GetCounter().RecordPostAdmissionDisposition(disposition);
        }

        internal static void RecordPostAdmissionProductLayers(AICodedbProductStatus status)
        {
            GetCounter().RecordPostAdmissionProductLayers(
                status.Prerequisite,
                status.Installed,
                status.Configured,
                status.McpAvailable);
        }

        internal static void RecordCurrentInstanceState(AICodedbCurrentInstanceState state)
        {
            GetCounter().RecordCurrentInstanceState(state);
        }

        internal static void RecordCurrentInstanceConvergencePlan(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan plan)
        {
            GetCounter().RecordCurrentInstanceConvergencePlan(plan);
        }

        internal static void RecordShutdownRequested()
        {
            GetCounter().RecordShutdownRequested();
        }

        internal static void RecordShutdownDisposition(AICodedbSupervisorCommandResponse response)
        {
            GetCounter().RecordShutdownDisposition(response);
            EmitWorkerCheckpoint("shutdown_completed");
        }

        internal static void RecordEditorQuittingBoundary(
            bool entering,
            bool reconcileInFlight,
            AICodedbSupervisorQueueSnapshot queueSnapshot)
        {
            GetCounter().RecordEditorQuittingBoundary(
                entering,
                reconcileInFlight,
                queueSnapshot);
            EmitWorkerCheckpoint(entering
                ? "editor_quitting_entry"
                : "editor_quitting_return");
        }

        internal static void PersistAndEmit(string checkpoint)
        {
            var document = GetCounter().Capture(checkpoint);
            SessionState.SetString(SessionStateKey, JsonUtility.ToJson(document));
            Debug.Log(LogPrefix + JsonUtility.ToJson(document));
        }

        private static void EmitWorkerCheckpoint(string checkpoint)
        {
            Debug.Log(LogPrefix + JsonUtility.ToJson(GetCounter().Capture(checkpoint)));
        }

        private static AICodedbLifecycleEvidenceCounter GetCounter()
        {
            var counter = Volatile.Read(ref _counter);
            if (counter != null)
                return counter;

            var created = new AICodedbLifecycleEvidenceCounter(0);
            return Interlocked.CompareExchange(ref _counter, created, null) ?? created;
        }
    }
}
