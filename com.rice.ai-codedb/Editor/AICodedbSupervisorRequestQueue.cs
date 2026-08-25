using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbSupervisorRequestKind
    {
        ObserveStatus,
        Reconnect,
        Reconcile,
        Maintenance
    }

    internal enum AICodedbSupervisorRequestPriority
    {
        Query = 0,
        Maintenance = 1
    }

    internal readonly struct AICodedbSupervisorQueueSnapshot
    {
        internal int PendingCount { get; }
        internal bool HasActiveRequest { get; }
        internal AICodedbSupervisorRequestKind ActiveKind { get; }
        internal long LastSequence { get; }
        internal int Epoch { get; }
        internal bool IsSuspended { get; }

        internal AICodedbSupervisorQueueSnapshot(
            int pendingCount,
            bool hasActiveRequest,
            AICodedbSupervisorRequestKind activeKind,
            long lastSequence,
            int epoch,
            bool isSuspended)
        {
            PendingCount = pendingCount;
            HasActiveRequest = hasActiveRequest;
            ActiveKind = activeKind;
            LastSequence = lastSequence;
            Epoch = epoch;
            IsSuspended = isSuspended;
        }
    }

    /// <summary>
    /// Serializes lifecycle work before it reaches the project-local runtime.
    /// Query/status observations take priority over maintenance, duplicate
    /// requests coalesce by key, and an epoch boundary cancels stale work.
    /// The queue never performs work on the Unity callback thread.
    /// </summary>
    internal sealed class AICodedbSupervisorRequestQueue : IDisposable
    {
        private sealed class Entry
        {
            internal string Key;
            internal AICodedbSupervisorRequestKind Kind;
            internal AICodedbSupervisorRequestPriority Priority;
            internal long Sequence;
            internal int Epoch;
            internal bool IsMaintenance;
            internal CancellationTokenSource Cancellation;
            internal TaskCompletionSource<object> Completion;
            internal Func<CancellationToken, Task<object>> Work;
            internal bool Started;
        }

        private readonly object _gate = new object();
        private readonly List<Entry> _pending = new List<Entry>();
        private readonly Dictionary<string, Entry> _byKey =
            new Dictionary<string, Entry>(StringComparer.Ordinal);
        private Entry _active;
        private bool _workerScheduled;
        private bool _disposed;
        private bool _suspended;
        private int _epoch;
        private long _sequence;

        internal AICodedbSupervisorQueueSnapshot Snapshot
        {
            get
            {
                lock (_gate)
                {
                    return new AICodedbSupervisorQueueSnapshot(
                        _pending.Count,
                        _active != null,
                        _active == null
                            ? AICodedbSupervisorRequestKind.ObserveStatus
                            : _active.Kind,
                        _sequence,
                        _epoch,
                        _suspended);
                }
            }
        }

        internal Task<T> Enqueue<T>(
            AICodedbSupervisorRequestKind kind,
            AICodedbSupervisorRequestPriority priority,
            string key,
            Func<CancellationToken, Task<T>> work,
            bool isMaintenance,
            bool supersedeExisting = false)
        {
            if (string.IsNullOrWhiteSpace(key))
                throw new ArgumentException("A queue key is required.", nameof(key));
            if (work == null)
                throw new ArgumentNullException(nameof(work));

            Entry entry;
            Task<T> task;
            Entry superseded = null;
            lock (_gate)
            {
                if (_disposed)
                    return Task.FromCanceled<T>(new CancellationToken(true));

                if (_suspended && isMaintenance)
                    return Task.FromCanceled<T>(new CancellationToken(true));

                Entry existing;
                if (_byKey.TryGetValue(key, out existing))
                {
                    if (!supersedeExisting && existing.Epoch == _epoch)
                        return CastCompletion<T>(existing.Completion.Task);

                    CancelEntryLocked(existing);
                    // Superseding, including an entry from an older epoch, is
                    // terminal for the old caller even when its worker ignores
                    // cancellation briefly. Do this while holding the queue
                    // lock so a late result cannot win a same-key race.
                    existing.Completion.TrySetCanceled(existing.Cancellation.Token);
                    RemovePendingEntryLocked(existing);
                    _byKey.Remove(key);
                    superseded = existing;
                }

                var completion = new TaskCompletionSource<object>(
                    TaskCreationOptions.RunContinuationsAsynchronously);
                entry = new Entry
                {
                    Key = key,
                    Kind = kind,
                    Priority = priority,
                    Sequence = ++_sequence,
                    Epoch = _epoch,
                    IsMaintenance = isMaintenance,
                    Cancellation = new CancellationTokenSource(),
                    Completion = completion,
                    Work = async cancellationToken => (object)await work(cancellationToken).ConfigureAwait(false)
                };
                _pending.Add(entry);
                _byKey[key] = entry;
                task = CastCompletion<T>(completion.Task);
                ScheduleWorkerLocked();
            }

            if (superseded != null && !superseded.Started)
            {
                superseded.Cancellation.Dispose();
            }

            return task;
        }

        /// <summary>
        /// Cancels maintenance requests at a Play/compile boundary while
        /// leaving read-only observations eligible to refresh the cache.
        /// </summary>
        internal void SetMaintenanceSuspended(bool suspended)
        {
            List<Entry> cancelled = null;
            lock (_gate)
            {
                if (_disposed)
                    return;

                if (_suspended == suspended)
                    return;

                _suspended = suspended;
                if (!suspended)
                {
                    _epoch++;
                    return;
                }

                _epoch++;
                for (var index = _pending.Count - 1; index >= 0; index--)
                {
                    var entry = _pending[index];
                    if (!entry.IsMaintenance)
                        continue;
                    CancelEntryLocked(entry);
                    RemovePendingEntryLocked(entry);
                    if (cancelled == null)
                        cancelled = new List<Entry>();
                    cancelled.Add(entry);
                }

                if (_active != null && _active.IsMaintenance)
                {
                    CancelEntryLocked(_active);
                    _active.Completion.TrySetCanceled(_active.Cancellation.Token);
                    RemoveActiveMappingLocked(_active);
                }
            }

            CompleteCancelledEntries(cancelled);
        }

        /// <summary>
        /// Invalidates every queued request. Used for Domain Reload and
        /// shutdown so an old result cannot overwrite a newer epoch.
        /// </summary>
        internal void Invalidate()
        {
            List<Entry> cancelled;
            lock (_gate)
            {
                if (_disposed)
                    return;

                _epoch++;
                cancelled = new List<Entry>(_pending);
                _pending.Clear();
                foreach (var entry in cancelled)
                {
                    CancelEntryLocked(entry);
                    _byKey.Remove(entry.Key);
                }

                if (_active != null)
                {
                    CancelEntryLocked(_active);
                    _active.Completion.TrySetCanceled(_active.Cancellation.Token);
                    RemoveActiveMappingLocked(_active);
                }
            }

            CompleteCancelledEntries(cancelled);
        }

        public void Dispose()
        {
            List<Entry> cancelled;
            lock (_gate)
            {
                if (_disposed)
                    return;

                _disposed = true;
                _epoch++;
                cancelled = new List<Entry>(_pending);
                _pending.Clear();
                foreach (var entry in cancelled)
                {
                    CancelEntryLocked(entry);
                    _byKey.Remove(entry.Key);
                }

                if (_active != null)
                {
                    CancelEntryLocked(_active);
                    _active.Completion.TrySetCanceled(_active.Cancellation.Token);
                    RemoveActiveMappingLocked(_active);
                }
            }

            CompleteCancelledEntries(cancelled);
        }

        private void ScheduleWorkerLocked()
        {
            if (_workerScheduled)
                return;

            _workerScheduled = true;
            try
            {
                _ = Task.Run(DrainAsync);
            }
            catch (Exception exception)
            {
                _workerScheduled = false;
                FailPendingLocked(exception);
            }
        }

        private async Task DrainAsync()
        {
            while (true)
            {
                Entry entry;
                lock (_gate)
                {
                    if (_disposed || _pending.Count == 0)
                    {
                        _workerScheduled = false;
                        return;
                    }

                    entry = TakeNextEntryLocked();
                    entry.Started = true;
                    _active = entry;
                }

                try
                {
                    if (entry.Cancellation.IsCancellationRequested)
                    {
                        entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                    }
                    else
                    {
                        var result = await entry.Work(entry.Cancellation.Token).ConfigureAwait(false);
                        lock (_gate)
                        {
                            if (_disposed || entry.Epoch != _epoch)
                            {
                                entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                            }
                            else
                            {
                                entry.Completion.TrySetResult(result);
                            }
                        }
                    }
                }
                catch (OperationCanceledException)
                {
                    entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                }
                catch (Exception exception)
                {
                    entry.Completion.TrySetException(exception);
                }
                finally
                {
                    lock (_gate)
                    {
                        if (ReferenceEquals(_active, entry))
                            _active = null;
                        Entry mapped;
                        if (_byKey.TryGetValue(entry.Key, out mapped)
                            && ReferenceEquals(mapped, entry))
                            _byKey.Remove(entry.Key);
                    }
                    entry.Cancellation.Dispose();
                }
            }
        }

        private Entry TakeNextEntryLocked()
        {
            var selectedIndex = 0;
            for (var index = 1; index < _pending.Count; index++)
            {
                var candidate = _pending[index];
                var selected = _pending[selectedIndex];
                if (candidate.Priority < selected.Priority
                    || (candidate.Priority == selected.Priority
                        && candidate.Sequence < selected.Sequence))
                    selectedIndex = index;
            }

            var entry = _pending[selectedIndex];
            _pending.RemoveAt(selectedIndex);
            return entry;
        }

        private void CancelEntryLocked(Entry entry)
        {
            if (entry == null)
                return;

            try
            {
                entry.Cancellation.Cancel();
            }
            catch (ObjectDisposedException)
            {
                // The worker completed concurrently with the boundary.
            }
        }

        private void RemovePendingEntryLocked(Entry entry)
        {
            if (entry == null || entry.Started)
                return;

            _pending.Remove(entry);
            _byKey.Remove(entry.Key);
        }

        private void RemoveActiveMappingLocked(Entry entry)
        {
            if (entry == null)
                return;

            Entry mapped;
            if (_byKey.TryGetValue(entry.Key, out mapped)
                && ReferenceEquals(mapped, entry))
                _byKey.Remove(entry.Key);
        }

        private static void CompleteCancelledEntries(IEnumerable<Entry> entries)
        {
            if (entries == null)
                return;

            foreach (var entry in entries)
            {
                entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                entry.Cancellation.Dispose();
            }
        }

        private void FailPendingLocked(Exception exception)
        {
            var entries = new List<Entry>(_pending);
            _pending.Clear();
            foreach (var entry in entries)
            {
                _byKey.Remove(entry.Key);
                entry.Completion.TrySetException(exception);
                entry.Cancellation.Dispose();
            }
        }

        private static Task<T> CastCompletion<T>(Task<object> completion)
        {
            var forwarded = new TaskCompletionSource<T>(
                TaskCreationOptions.RunContinuationsAsynchronously);
            completion.ContinueWith(
                completed =>
                {
                    if (completed.IsCanceled)
                    {
                        forwarded.TrySetCanceled();
                        return;
                    }

                    if (completed.IsFaulted)
                    {
                        forwarded.TrySetException(completed.Exception.InnerExceptions);
                        return;
                    }

                    try
                    {
                        forwarded.TrySetResult((T)completed.Result);
                    }
                    catch (Exception exception)
                    {
                        forwarded.TrySetException(exception);
                    }
                },
                CancellationToken.None,
                TaskContinuationOptions.ExecuteSynchronously,
                TaskScheduler.Default);
            return forwarded.Task;
        }
    }
}
