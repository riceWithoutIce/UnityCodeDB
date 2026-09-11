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
    /// Moves lifecycle intent off Unity callbacks and rejects results from an
    /// obsolete local lifetime. Runtime request ordering, keys, coalescing, and
    /// admission belong exclusively to the project Supervisor.
    /// </summary>
    internal sealed class AICodedbSupervisorIntentAdapter : IDisposable
    {
        private sealed class Entry
        {
            internal AICodedbSupervisorRequestKind Kind;
            internal long Sequence;
            internal int Generation;
            internal bool IsMaintenance;
            internal CancellationTokenSource Cancellation;
            internal TaskCompletionSource<object> Completion;
            internal Func<CancellationToken, Task<object>> Work;
        }

        private readonly object _gate = new object();
        private readonly HashSet<Entry> _active = new HashSet<Entry>();
        private bool _disposed;
        private bool _suspended;
        private int _generation;
        private long _sequence;

        internal AICodedbSupervisorQueueSnapshot Snapshot
        {
            get
            {
                lock (_gate)
                {
                    var active = FindOldestActiveLocked();
                    return new AICodedbSupervisorQueueSnapshot(
                        0,
                        active != null,
                        active == null
                            ? AICodedbSupervisorRequestKind.ObserveStatus
                            : active.Kind,
                        _sequence,
                        _generation,
                        _suspended);
                }
            }
        }

        internal Task<T> Dispatch<T>(
            AICodedbSupervisorRequestKind kind,
            Func<CancellationToken, Task<T>> work,
            bool isMaintenance)
        {
            if (work == null)
                throw new ArgumentNullException(nameof(work));

            Entry entry;
            Task<T> task;
            lock (_gate)
            {
                if (_disposed || (_suspended && isMaintenance))
                    return Task.FromCanceled<T>(new CancellationToken(true));

                var completion = new TaskCompletionSource<object>(
                    TaskCreationOptions.RunContinuationsAsynchronously);
                entry = new Entry
                {
                    Kind = kind,
                    Sequence = ++_sequence,
                    Generation = _generation,
                    IsMaintenance = isMaintenance,
                    Cancellation = new CancellationTokenSource(),
                    Completion = completion,
                    Work = async cancellationToken =>
                        (object)await work(cancellationToken).ConfigureAwait(false)
                };
                _active.Add(entry);
                task = CastCompletion<T>(completion.Task);
            }

            try
            {
                _ = Task.Run(() => RunAsync(entry));
            }
            catch (Exception exception)
            {
                lock (_gate)
                    _active.Remove(entry);
                entry.Completion.TrySetException(exception);
                entry.Cancellation.Dispose();
            }

            return task;
        }

        /// <summary>
        /// Cancels local maintenance intent at a Play/compile boundary. Query
        /// observations remain eligible to reach the Supervisor in the new
        /// local generation.
        /// </summary>
        internal void SetMaintenanceSuspended(bool suspended)
        {
            lock (_gate)
            {
                if (_disposed || _suspended == suspended)
                    return;

                _suspended = suspended;
                _generation++;
                if (!suspended)
                    return;

                foreach (var entry in _active)
                {
                    if (!entry.IsMaintenance)
                        continue;
                    CancelEntryLocked(entry);
                    entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                }
            }
        }

        /// <summary>
        /// Invalidates local waiters during Domain Reload. An already admitted
        /// external operation remains owned by the authenticated Supervisor.
        /// </summary>
        internal void Invalidate()
        {
            lock (_gate)
            {
                if (_disposed)
                    return;

                _generation++;
                foreach (var entry in _active)
                {
                    CancelEntryLocked(entry);
                    entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                }
            }
        }

        public void Dispose()
        {
            lock (_gate)
            {
                if (_disposed)
                    return;

                _disposed = true;
                _generation++;
                foreach (var entry in _active)
                {
                    CancelEntryLocked(entry);
                    entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                }
            }
        }

        private async Task RunAsync(Entry entry)
        {
            try
            {
                if (entry.Cancellation.IsCancellationRequested)
                {
                    entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                    return;
                }

                var result = await entry.Work(entry.Cancellation.Token).ConfigureAwait(false);
                lock (_gate)
                {
                    if (_disposed
                        || entry.Generation != _generation
                        || entry.Cancellation.IsCancellationRequested)
                    {
                        entry.Completion.TrySetCanceled(entry.Cancellation.Token);
                    }
                    else
                    {
                        entry.Completion.TrySetResult(result);
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
                    _active.Remove(entry);
                entry.Cancellation.Dispose();
            }
        }

        private Entry FindOldestActiveLocked()
        {
            Entry selected = null;
            foreach (var entry in _active)
            {
                if (selected == null || entry.Sequence < selected.Sequence)
                    selected = entry;
            }
            return selected;
        }

        private static void CancelEntryLocked(Entry entry)
        {
            try
            {
                entry.Cancellation.Cancel();
            }
            catch (ObjectDisposedException)
            {
                // The detached worker completed concurrently with the boundary.
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
