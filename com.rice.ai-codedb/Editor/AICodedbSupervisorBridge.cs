using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Rice.AI.Codedb.Editor
{
    internal enum AICodedbSupervisorConnectionState
    {
        Disconnected,
        Connecting,
        Connected,
        Degraded
    }

    // Connection state answers whether the Bridge reached the project-local
    // process. Readiness is deliberately separate: an authenticated status
    // response can still describe a backend that is starting, rebuilding, or
    // stopped.
    internal enum AICodedbSupervisorReadinessState
    {
        Unknown,
        CoreReady,
        Starting,
        Maintenance,
        Degraded,
        Blocked,
        Stopping,
        Stopped
    }

    internal sealed class AICodedbSupervisorSnapshot
    {
        internal AICodedbSupervisorConnectionState ConnectionState { get; }
        internal int ProtocolVersion { get; }
        internal int CoordinatorSchemaVersion { get; }
        internal AICodedbSupervisorReadinessState ReadinessState { get; }
        internal string ReasonCode { get; }
        internal string Detail { get; }
        internal int CoordinatorProcessId { get; }
        internal string LifecycleId { get; }
        internal string RuntimePath { get; }
        internal string ProviderState { get; }
        internal string ProviderReadyAtUtc { get; }
        internal string AdapterState { get; }
        internal string AdapterWorkerState { get; }
        internal string DesiredState { get; }
        internal string EditorDemand { get; }
        internal string LastEvent { get; }
        internal DateTimeOffset ObservedAtUtc { get; }

        internal bool IsConnected => ConnectionState == AICodedbSupervisorConnectionState.Connected;
        internal bool IsConnecting => ConnectionState == AICodedbSupervisorConnectionState.Connecting;
        internal bool IsCoreReady => IsConnected
                                      && ReadinessState == AICodedbSupervisorReadinessState.CoreReady;
        internal AICodedbSupervisorReadinessState RuntimeState => ReadinessState;
        internal string ReadinessCode => AICodedbSupervisorProtocol.GetReadinessCode(ReadinessState);

        private AICodedbSupervisorSnapshot(
            AICodedbSupervisorConnectionState connectionState,
            int protocolVersion,
            int coordinatorSchemaVersion,
            AICodedbSupervisorReadinessState readinessState,
            string reasonCode,
            string detail,
            int coordinatorProcessId,
            string lifecycleId,
            string runtimePath,
            string providerState,
            string providerReadyAtUtc,
            string adapterState,
            string adapterWorkerState,
            string desiredState,
            string editorDemand,
            string lastEvent)
        {
            ConnectionState = connectionState;
            ProtocolVersion = protocolVersion;
            CoordinatorSchemaVersion = coordinatorSchemaVersion;
            ReadinessState = readinessState;
            ReasonCode = reasonCode ?? string.Empty;
            Detail = detail ?? string.Empty;
            CoordinatorProcessId = coordinatorProcessId;
            LifecycleId = lifecycleId ?? string.Empty;
            RuntimePath = runtimePath ?? string.Empty;
            ProviderState = providerState ?? string.Empty;
            ProviderReadyAtUtc = providerReadyAtUtc ?? string.Empty;
            AdapterState = adapterState ?? string.Empty;
            AdapterWorkerState = adapterWorkerState ?? string.Empty;
            DesiredState = desiredState ?? string.Empty;
            EditorDemand = editorDemand ?? string.Empty;
            LastEvent = lastEvent ?? string.Empty;
            ObservedAtUtc = DateTimeOffset.UtcNow;
        }

        internal static AICodedbSupervisorSnapshot Disconnected(string reasonCode, string detail)
        {
            return new AICodedbSupervisorSnapshot(
                AICodedbSupervisorConnectionState.Disconnected,
                AICodedbSupervisorProtocol.Version,
                0,
                AICodedbSupervisorReadinessState.Unknown,
                reasonCode,
                detail,
                0,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty);
        }

        internal static AICodedbSupervisorSnapshot Degraded(string reasonCode, string detail)
        {
            return new AICodedbSupervisorSnapshot(
                AICodedbSupervisorConnectionState.Degraded,
                AICodedbSupervisorProtocol.Version,
                0,
                AICodedbSupervisorReadinessState.Degraded,
                reasonCode,
                detail,
                0,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty);
        }

        internal static AICodedbSupervisorSnapshot Connecting(string detail)
        {
            return new AICodedbSupervisorSnapshot(
                AICodedbSupervisorConnectionState.Connecting,
                AICodedbSupervisorProtocol.Version,
                0,
                AICodedbSupervisorReadinessState.Starting,
                "SUPERVISOR_CONNECTING",
                detail,
                0,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty);
        }

        internal static AICodedbSupervisorSnapshot Blocked(string reasonCode, string detail)
        {
            return new AICodedbSupervisorSnapshot(
                AICodedbSupervisorConnectionState.Degraded,
                AICodedbSupervisorProtocol.Version,
                0,
                AICodedbSupervisorReadinessState.Blocked,
                reasonCode,
                detail,
                0,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty,
                string.Empty);
        }

        internal static AICodedbSupervisorSnapshot Connected(
            int coordinatorSchemaVersion,
            int coordinatorProcessId,
            string lifecycleId,
            string runtimePath,
            string providerState,
            string providerReadyAtUtc,
            string adapterState,
            string adapterWorkerState,
            string desiredState,
            string editorDemand,
            AICodedbSupervisorReadinessState readinessState,
            string reasonCode,
            string detail,
            string lastEvent)
        {
            return new AICodedbSupervisorSnapshot(
                AICodedbSupervisorConnectionState.Connected,
                AICodedbSupervisorProtocol.Version,
                coordinatorSchemaVersion,
                readinessState,
                reasonCode,
                detail,
                coordinatorProcessId,
                lifecycleId,
                runtimePath,
                providerState,
                providerReadyAtUtc,
                adapterState,
                adapterWorkerState,
                desiredState,
                editorDemand,
                lastEvent);
        }
    }

    internal static class AICodedbSupervisorProtocol
    {
        // The envelope and coordinator state schema form the minimum v0.3
        // handshake. The existing poc.33 coordinator is the project-local
        // Supervisor process; its schema-2 status is the compatibility proof
        // without changing the immutable generation bytes in this task.
        internal const int Version = 1;
        internal const int CoordinatorStateSchemaVersion = 2;
        internal const int MaximumMessageBytes = 64 * 1024;
        internal const int ConnectionTimeoutMilliseconds = 1500;
        internal const string ClientKind = "unity-bridge";
        internal const string SupervisorRole = "project-local-supervisor";

        internal static string GetReadinessCode(AICodedbSupervisorReadinessState state)
        {
            switch (state)
            {
                case AICodedbSupervisorReadinessState.CoreReady: return "CORE_READY";
                case AICodedbSupervisorReadinessState.Starting: return "STARTING";
                case AICodedbSupervisorReadinessState.Maintenance: return "MAINTENANCE";
                case AICodedbSupervisorReadinessState.Degraded: return "DEGRADED";
                case AICodedbSupervisorReadinessState.Blocked: return "BLOCKED";
                case AICodedbSupervisorReadinessState.Stopping: return "STOPPING";
                case AICodedbSupervisorReadinessState.Stopped: return "STOPPED";
                default: return "UNKNOWN";
            }
        }

        /// <summary>
        /// Reduces authenticated Supervisor status into a stable runtime state.
        /// Returning false means the evidence itself is invalid and must not be
        /// presented as a recoverable backend failure.
        /// </summary>
        internal static bool TryResolveReadiness(
            string desiredState,
            string editorDemand,
            string providerState,
            bool adapterEnabled,
            string adapterState,
            string adapterWorkerState,
            bool adapterWorkerConfigured,
            out AICodedbSupervisorReadinessState readiness,
            out string reasonCode,
            out string detail)
        {
            readiness = AICodedbSupervisorReadinessState.Blocked;
            reasonCode = "SUPERVISOR_BLOCKED";
            detail = "The Supervisor returned an unsupported readiness state.";

            if (!IsOneOf(desiredState, "enabled", "disabled")
                || !IsOneOf(editorDemand, "online", "offline")
                || !IsOneOf(
                    providerState,
                    "starting",
                    "ready",
                    "restarting",
                    "failed",
                    "exited",
                    "draining",
                    "stopping",
                    "stopped")
                || !IsOneOf(
                    adapterState,
                    "disabled",
                    "starting",
                    "watching",
                    "pending",
                    "building",
                    "restarting",
                    "failed",
                    "draining",
                    "stopping",
                    "stopped")
                || !IsOneOf(
                    adapterWorkerState,
                    "disabled",
                    "starting",
                    "ready",
                    "restarting",
                    "draining",
                    "stopping",
                    "failed",
                    "stopped"))
            {
                return false;
            }

            if (string.Equals(desiredState, "disabled", StringComparison.Ordinal)
                || string.Equals(editorDemand, "offline", StringComparison.Ordinal)
                || string.Equals(providerState, "stopped", StringComparison.Ordinal))
            {
                readiness = AICodedbSupervisorReadinessState.Stopped;
                reasonCode = "SUPERVISOR_STOPPED";
                detail = "The project Supervisor is not demanded by an active Editor session.";
                return true;
            }

            if (string.Equals(providerState, "failed", StringComparison.Ordinal)
                || string.Equals(providerState, "exited", StringComparison.Ordinal)
                || string.Equals(adapterState, "failed", StringComparison.Ordinal)
                || string.Equals(adapterWorkerState, "failed", StringComparison.Ordinal))
            {
                readiness = AICodedbSupervisorReadinessState.Degraded;
                reasonCode = "SUPERVISOR_DEGRADED";
                detail = "The project Supervisor or one of its owned workers reported a failure.";
                return true;
            }

            if (string.Equals(providerState, "draining", StringComparison.Ordinal)
                || string.Equals(providerState, "stopping", StringComparison.Ordinal)
                || string.Equals(adapterState, "draining", StringComparison.Ordinal)
                || string.Equals(adapterState, "stopping", StringComparison.Ordinal)
                || string.Equals(adapterWorkerState, "draining", StringComparison.Ordinal)
                || string.Equals(adapterWorkerState, "stopping", StringComparison.Ordinal))
            {
                readiness = AICodedbSupervisorReadinessState.Stopping;
                reasonCode = "SUPERVISOR_STOPPING";
                detail = "The project Supervisor is finishing an owned shutdown.";
                return true;
            }

            if (!string.Equals(providerState, "ready", StringComparison.Ordinal))
            {
                readiness = AICodedbSupervisorReadinessState.Starting;
                reasonCode = "SUPERVISOR_STARTING";
                detail = "The project Supervisor is starting or restarting its Provider.";
                return true;
            }

            if (!adapterEnabled)
            {
                if (!string.Equals(adapterState, "disabled", StringComparison.Ordinal)
                    || !string.Equals(adapterWorkerState, "disabled", StringComparison.Ordinal))
                    return false;

                readiness = AICodedbSupervisorReadinessState.CoreReady;
                reasonCode = "CORE_READY";
                detail = "The project Supervisor and Provider are ready.";
                return true;
            }

            if (string.Equals(adapterState, "disabled", StringComparison.Ordinal)
                || (!adapterWorkerConfigured
                    && !string.Equals(adapterWorkerState, "disabled", StringComparison.Ordinal)))
                return false;

            if (string.Equals(adapterState, "pending", StringComparison.Ordinal)
                || string.Equals(adapterState, "building", StringComparison.Ordinal)
                || string.Equals(adapterState, "starting", StringComparison.Ordinal)
                || string.Equals(adapterState, "restarting", StringComparison.Ordinal)
                || string.Equals(adapterWorkerState, "starting", StringComparison.Ordinal)
                || string.Equals(adapterWorkerState, "restarting", StringComparison.Ordinal))
            {
                readiness = AICodedbSupervisorReadinessState.Maintenance;
                reasonCode = "SUPERVISOR_MAINTENANCE";
                detail = "The Provider is ready while the project adapter is preparing.";
                return true;
            }

            if (!string.Equals(adapterState, "watching", StringComparison.Ordinal)
                || (adapterWorkerConfigured
                    && !string.Equals(adapterWorkerState, "ready", StringComparison.Ordinal)))
                return false;

            readiness = AICodedbSupervisorReadinessState.CoreReady;
            reasonCode = "CORE_READY";
            detail = "The project Supervisor, Provider, and enabled adapter are ready.";
            return true;
        }

        internal static bool ShouldReuseReconnect(bool force, bool inFlight)
        {
            return inFlight && !force;
        }

        private static bool IsOneOf(string value, params string[] allowed)
        {
            if (value == null)
                return false;
            foreach (var candidate in allowed)
            {
                if (string.Equals(value, candidate, StringComparison.Ordinal))
                    return true;
            }
            return false;
        }

        internal static string BuildStatusRequest(string authToken, string requestId)
        {
            if (string.IsNullOrWhiteSpace(authToken))
                throw new ArgumentException("An IPC auth token is required.", nameof(authToken));
            if (string.IsNullOrWhiteSpace(requestId))
                throw new ArgumentException("An IPC request id is required.", nameof(requestId));

            var request = "{\"auth_token\":\""
                   + EscapeJson(authToken)
                   + "\",\"command\":\"status\",\"protocol_version\":"
                   + Version.ToString(System.Globalization.CultureInfo.InvariantCulture)
                   + ",\"client_kind\":\""
                   + ClientKind
                   + "\",\"request_id\":\""
                   + EscapeJson(requestId)
                   + "\"}";
            if (Encoding.UTF8.GetByteCount(request) > MaximumMessageBytes)
                throw new ArgumentException("The Supervisor request exceeds the IPC message limit.", nameof(authToken));
            return request;
        }

        internal static bool TryGetWindowsPipeName(string value, out string pipeName)
        {
            pipeName = string.Empty;
            const string prefix = @"\\.\pipe\";
            if (string.IsNullOrWhiteSpace(value)
                || !value.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                return false;

            var candidate = value.Substring(prefix.Length);
            if (candidate.Length == 0
                || candidate.IndexOf('\\') >= 0
                || candidate.IndexOf('/') >= 0
                || candidate.IndexOf('\0') >= 0)
                return false;

            pipeName = candidate;
            return true;
        }

        internal static bool TryGetExpectedWindowsPipeName(
            string projectRoot,
            string runtime,
            out string pipeName)
        {
            pipeName = string.Empty;
            if (string.IsNullOrWhiteSpace(projectRoot) || string.IsNullOrWhiteSpace(runtime))
                return false;

            try
            {
                var input = AICodedbPaths.NormalizePath(projectRoot).ToLowerInvariant()
                            + "\n"
                            + AICodedbPaths.NormalizePath(runtime).ToLowerInvariant();
                byte[] digest;
                using (var sha256 = SHA256.Create())
                    digest = sha256.ComputeHash(Encoding.UTF8.GetBytes(input));

                var hex = new StringBuilder(digest.Length * 2);
                for (var index = 0; index < digest.Length; index++)
                    hex.Append(digest[index].ToString("x2", System.Globalization.CultureInfo.InvariantCulture));

                pipeName = "codedb-watch-" + hex.ToString().Substring(0, 20);
                return true;
            }
            catch
            {
                pipeName = string.Empty;
                return false;
            }
        }

        internal static bool PathsEqual(string left, string right)
        {
            if (string.IsNullOrWhiteSpace(left) || string.IsNullOrWhiteSpace(right))
                return false;

            try
            {
                return string.Equals(
                    AICodedbPaths.NormalizePath(left).TrimEnd('/', '\\'),
                    AICodedbPaths.NormalizePath(right).TrimEnd('/', '\\'),
                    StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        internal static bool IsInsideRoot(string root, string path)
        {
            if (string.IsNullOrWhiteSpace(root) || string.IsNullOrWhiteSpace(path))
                return false;

            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/', '\\');
                var normalizedPath = AICodedbPaths.NormalizePath(path);
                return string.Equals(normalizedRoot, normalizedPath, StringComparison.OrdinalIgnoreCase)
                       || normalizedPath.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        private static string EscapeJson(string value)
        {
            var builder = new StringBuilder(value.Length + 8);
            foreach (var character in value)
            {
                switch (character)
                {
                    case '\\': builder.Append("\\\\"); break;
                    case '"': builder.Append("\\\""); break;
                    case '\r': builder.Append("\\r"); break;
                    case '\n': builder.Append("\\n"); break;
                    case '\t': builder.Append("\\t"); break;
                    default: builder.Append(character); break;
                }
            }
            return builder.ToString();
        }
    }

    internal sealed class AICodedbSupervisorBridge : IDisposable
    {
        // A reconnect can overlap a domain reload. Keep cancellation ownership
        // explicit so the worker and the lifecycle callback cannot dispose the
        // same source twice.
        private sealed class WorkerCancellation : IDisposable
        {
            internal readonly CancellationTokenSource Source = new CancellationTokenSource();
            private int _disposed;

            internal void Cancel()
            {
                try
                {
                    Source.Cancel();
                }
                catch (ObjectDisposedException)
                {
                    // The worker may have completed and disposed the source.
                }
            }

            public void Dispose()
            {
                if (Interlocked.Exchange(ref _disposed, 1) != 0)
                    return;
                Source.Dispose();
            }
        }

        private sealed class SupervisorMessageTooLargeException : InvalidOperationException
        {
            internal SupervisorMessageTooLargeException()
                : base("The Supervisor response exceeds the IPC message limit.")
            {
            }
        }

        private const long CoordinatorStateMaximumBytes = 128 * 1024;
        private readonly object _gate = new object();
        private AICodedbSupervisorSnapshot _cachedSnapshot =
            AICodedbSupervisorSnapshot.Disconnected("NOT_CONNECTED", "The CodeDB Supervisor has not been contacted.");
        private Task<AICodedbSupervisorSnapshot> _inFlight;
        private WorkerCancellation _cancellation;
        private int _epoch;
        private bool _disposed;

        internal AICodedbSupervisorSnapshot CachedSnapshot
        {
            get
            {
                lock (_gate)
                    return _cachedSnapshot;
            }
        }

        internal Task<AICodedbSupervisorSnapshot> ReconnectAsync(string projectRoot, bool force = false)
        {
            if (string.IsNullOrWhiteSpace(projectRoot))
                return Task.FromResult(AICodedbSupervisorSnapshot.Degraded("INVALID_PROJECT_ROOT", "The Unity project root is empty."));

            lock (_gate)
            {
                if (_disposed)
                    return Task.FromResult(AICodedbSupervisorSnapshot.Disconnected("DISPOSED", "The Unity Editor lifecycle is closing."));
                if (AICodedbSupervisorProtocol.ShouldReuseReconnect(
                        force,
                        _inFlight != null && !_inFlight.IsCompleted))
                    return _inFlight;

                if (force && _cancellation != null)
                    _cancellation.Cancel();

                var cancellation = new WorkerCancellation();
                var epoch = ++_epoch;
                _cachedSnapshot = AICodedbSupervisorSnapshot.Connecting(
                    "The project-local Supervisor is being contacted asynchronously.");
                var worker = Task.Run(
                    () => ConnectWorker(projectRoot, cancellation.Source.Token),
                    cancellation.Source.Token);
                _cancellation = cancellation;
                _inFlight = ObserveWorkerAsync(worker, cancellation, epoch);
                return _inFlight;
            }
        }

        internal void Invalidate()
        {
            lock (_gate)
            {
                ++_epoch;
                if (_cancellation != null)
                    _cancellation.Cancel();
                _cachedSnapshot = AICodedbSupervisorSnapshot.Disconnected(
                    "RECONNECT_REQUIRED",
                    "The Unity domain was reloaded; the Supervisor connection will be re-established asynchronously.");
            }
        }

        public void Dispose()
        {
            lock (_gate)
            {
                if (_disposed)
                    return;
                _disposed = true;
                ++_epoch;
                if (_cancellation != null)
                    _cancellation.Cancel();
                _cachedSnapshot = AICodedbSupervisorSnapshot.Disconnected(
                    "DISPOSED",
                    "The Unity Editor lifecycle is closing.");
            }
        }

        private async Task<AICodedbSupervisorSnapshot> ObserveWorkerAsync(
            Task<AICodedbSupervisorSnapshot> worker,
            WorkerCancellation cancellation,
            int epoch)
        {
            AICodedbSupervisorSnapshot result;
            try
            {
                result = await worker.ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                result = AICodedbSupervisorSnapshot.Disconnected(
                    "CANCELLED",
                    "The previous Supervisor connection attempt was superseded.");
            }
            catch (SupervisorMessageTooLargeException)
            {
                result = AICodedbSupervisorSnapshot.Blocked(
                    "RESPONSE_TOO_LARGE",
                    "The Supervisor response exceeds the IPC message limit.");
            }
            catch (InvalidOperationException exception)
            {
                result = AICodedbSupervisorSnapshot.Blocked(
                    "INVALID_SUPERVISOR_EVIDENCE",
                    exception.Message);
            }
            catch (KeyNotFoundException exception)
            {
                result = AICodedbSupervisorSnapshot.Blocked(
                    "INVALID_SUPERVISOR_EVIDENCE",
                    exception.Message);
            }
            catch (DecoderFallbackException exception)
            {
                result = AICodedbSupervisorSnapshot.Blocked(
                    "INVALID_SUPERVISOR_EVIDENCE",
                    "The Supervisor response is not valid UTF-8. " + exception.Message);
            }
            catch (Exception exception)
            {
                result = AICodedbSupervisorSnapshot.Degraded("BRIDGE_ERROR", exception.Message);
            }

            lock (_gate)
            {
                if (epoch == _epoch && !_disposed)
                {
                    _cachedSnapshot = result;
                    _inFlight = null;
                }
            }
            cancellation.Dispose();
            return result;
        }

        private static AICodedbSupervisorSnapshot ConnectWorker(
            string projectRoot,
            CancellationToken cancellationToken)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\');
            AICodedbCurrentInstanceStatus currentInstance = AICodedbCurrentInstanceStore.Read(normalizedRoot);
            if (!currentInstance.Present || !currentInstance.IsCurrent || string.IsNullOrWhiteSpace(currentInstance.InstanceRoot))
            {
                return AICodedbSupervisorSnapshot.Disconnected(
                    "CURRENT_INSTANCE_UNAVAILABLE",
                    currentInstance.Detail);
            }

            var statePath = Path.Combine(
                currentInstance.InstanceRoot,
                "watch",
                "coordinator",
                "coordinator-state.json");
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, statePath);
            if (!File.Exists(statePath))
            {
                return AICodedbSupervisorSnapshot.Disconnected(
                    "SUPERVISOR_NOT_STARTED",
                    "The selected instance has no active Supervisor state yet.");
            }

            var state = AICodedbStrictJson.ReadObject(
                statePath,
                CoordinatorStateMaximumBytes,
                "CodeDB Supervisor state");
            var stateSchema = AICodedbStrictJson.GetRequiredInt32(
                state,
                "schema_version",
                "CodeDB Supervisor state");
            var stateProtocolVersion = AICodedbStrictJson.GetOptionalNullableInt32(
                state,
                "protocol_version",
                "CodeDB Supervisor state");
            var stateRole = AICodedbStrictJson.GetOptionalNullableString(
                state,
                "role",
                "CodeDB Supervisor state");
            if (stateProtocolVersion.HasValue
                && stateProtocolVersion.Value != AICodedbSupervisorProtocol.Version)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "PROTOCOL_MISMATCH",
                    "The selected Supervisor state advertises an unsupported Bridge protocol.");
            }
            if (stateRole != null
                && !string.Equals(
                    stateRole,
                    AICodedbSupervisorProtocol.SupervisorRole,
                    StringComparison.Ordinal))
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "SUPERVISOR_ROLE_MISMATCH",
                    "The selected runtime is not owned by the project-local CodeDB Supervisor.");
            }
            if (stateSchema != AICodedbSupervisorProtocol.CoordinatorStateSchemaVersion)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "PROTOCOL_MISMATCH",
                    "The selected Supervisor state schema is not supported by this Bridge.");
            }

            var stateRoot = AICodedbStrictJson.GetRequiredString(state, "root", "CodeDB Supervisor state");
            var generationId = AICodedbStrictJson.GetRequiredString(
                state,
                "generation_id",
                "CodeDB Supervisor state");
            var runtime = AICodedbStrictJson.GetRequiredString(state, "runtime", "CodeDB Supervisor state");
            var pipeValue = AICodedbStrictJson.GetRequiredString(state, "pipe_name", "CodeDB Supervisor state");
            var authToken = AICodedbStrictJson.GetRequiredString(state, "auth_token", "CodeDB Supervisor state");
            if (string.IsNullOrWhiteSpace(authToken))
                throw new InvalidOperationException("CodeDB Supervisor state contains an empty IPC auth token.");
            string expectedPipeName;
            var expectedRuntime = AICodedbPaths.NormalizePath(Path.Combine(
                currentInstance.InstanceRoot,
                "watch",
                "coordinator"));
            if (!AICodedbSupervisorProtocol.PathsEqual(normalizedRoot, stateRoot)
                || !string.Equals(
                    generationId,
                    AICodedbProjectSettings.CurrentGenerationId,
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(expectedRuntime, runtime)
                || !AICodedbSupervisorProtocol.TryGetWindowsPipeName(pipeValue, out var pipeName)
                || !AICodedbSupervisorProtocol.TryGetExpectedWindowsPipeName(
                    normalizedRoot,
                    runtime,
                    out expectedPipeName)
                || !string.Equals(pipeName, expectedPipeName, StringComparison.OrdinalIgnoreCase))
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "INVALID_SUPERVISOR_IDENTITY",
                    "The Supervisor state is outside the selected project or has an invalid pipe identity.");
            }

            cancellationToken.ThrowIfCancellationRequested();
            using (var pipe = new NamedPipeClientStream(
                       ".",
                       pipeName,
                       PipeDirection.InOut,
                       PipeOptions.None))
            {
                // NamedPipeClientStream.ConnectAsync can leave an underlying
                // overlapped connect alive after a domain reload on the Unity
                // Mono runtime. This worker is already off the Editor thread,
                // so use the platform hard timeout instead.
                pipe.Connect(AICodedbSupervisorProtocol.ConnectionTimeoutMilliseconds);
                pipe.ReadTimeout = AICodedbSupervisorProtocol.ConnectionTimeoutMilliseconds;
                pipe.WriteTimeout = AICodedbSupervisorProtocol.ConnectionTimeoutMilliseconds;
                cancellationToken.ThrowIfCancellationRequested();
                using (var reader = new StreamReader(
                           pipe,
                           new UTF8Encoding(false, true),
                           false,
                           4096,
                           true))
                using (var writer = new StreamWriter(
                           pipe,
                           new UTF8Encoding(false),
                           4096,
                           true))
                {
                    var requestId = Guid.NewGuid().ToString("N");
                    writer.WriteLine(AICodedbSupervisorProtocol.BuildStatusRequest(authToken, requestId));
                    writer.Flush();
                    cancellationToken.ThrowIfCancellationRequested();
                    var responseLine = ReadBoundedLine(reader, cancellationToken);
                    if (string.IsNullOrWhiteSpace(responseLine))
                    {
                        return AICodedbSupervisorSnapshot.Degraded(
                            "EMPTY_SUPERVISOR_RESPONSE",
                            "The Supervisor closed the Bridge request without a response.");
                    }
                    return ParseStatusResponse(
                        responseLine,
                        normalizedRoot,
                        AICodedbProjectSettings.CurrentGenerationId,
                        runtime);
                }
            }
        }

        internal static string ReadBoundedLine(TextReader reader, CancellationToken cancellationToken)
        {
            if (reader == null)
                throw new ArgumentNullException(nameof(reader));

            var builder = new StringBuilder();
            while (true)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var value = reader.Read();
                if (value < 0)
                    break;

                var character = (char)value;
                if (character == '\n')
                    break;
                if (character == '\r')
                {
                    if (reader.Peek() == '\n')
                        reader.Read();
                    break;
                }

                builder.Append(character);
                // Check periodically so a hostile response cannot force an
                // unbounded allocation, while preserving valid UTF-8 byte
                // limits for multibyte status text.
                if ((builder.Length & 1023) == 0
                    && Encoding.UTF8.GetByteCount(builder.ToString())
                        > AICodedbSupervisorProtocol.MaximumMessageBytes)
                    throw new SupervisorMessageTooLargeException();
            }

            if (Encoding.UTF8.GetByteCount(builder.ToString())
                > AICodedbSupervisorProtocol.MaximumMessageBytes)
                throw new SupervisorMessageTooLargeException();
            return builder.Length == 0 && reader.Peek() < 0
                ? null
                : builder.ToString();
        }

        internal static AICodedbSupervisorSnapshot ParseStatusResponse(
            string responseLine,
            string expectedRoot,
            string expectedGenerationId,
            string expectedRuntime)
        {
            var response = AICodedbStrictJson.ParseObject(responseLine, "CodeDB Supervisor response");
            if (!AICodedbStrictJson.GetRequiredBoolean(response, "ok", "CodeDB Supervisor response"))
            {
                var error = AICodedbStrictJson.GetOptionalNullableString(
                    response,
                    "error",
                    "CodeDB Supervisor response") ?? "The Supervisor refused the status request.";
                var errorCode = AICodedbStrictJson.GetOptionalNullableString(
                    response,
                    "error_code",
                    "CodeDB Supervisor response") ?? "SUPERVISOR_REQUEST_FAILED";
                return AICodedbSupervisorSnapshot.Degraded(errorCode, error);
            }

            var status = AICodedbStrictJson.RequireObject(
                response["status"],
                "CodeDB Supervisor status");
            var schema = AICodedbStrictJson.GetRequiredInt32(status, "schema_version", "CodeDB Supervisor status");
            var responseProtocolVersion = AICodedbStrictJson.GetOptionalNullableInt32(
                status,
                "protocol_version",
                "CodeDB Supervisor status");
            var responseRole = AICodedbStrictJson.GetOptionalNullableString(
                status,
                "role",
                "CodeDB Supervisor status");
            if (responseProtocolVersion.HasValue
                && responseProtocolVersion.Value != AICodedbSupervisorProtocol.Version)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "PROTOCOL_MISMATCH",
                    "The Supervisor returned an unsupported Bridge protocol.");
            }
            if (responseRole != null
                && !string.Equals(
                    responseRole,
                    AICodedbSupervisorProtocol.SupervisorRole,
                    StringComparison.Ordinal))
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "SUPERVISOR_ROLE_MISMATCH",
                    "The Supervisor response is not owned by the project-local CodeDB Supervisor.");
            }
            if (schema != AICodedbSupervisorProtocol.CoordinatorStateSchemaVersion)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "PROTOCOL_MISMATCH",
                    "The Supervisor returned an unsupported status schema.");
            }

            var root = AICodedbStrictJson.GetRequiredString(status, "root", "CodeDB Supervisor status");
            var generationId = AICodedbStrictJson.GetRequiredString(
                status,
                "generation_id",
                "CodeDB Supervisor status");
            var runtime = AICodedbStrictJson.GetRequiredString(status, "runtime", "CodeDB Supervisor status");
            if (!AICodedbSupervisorProtocol.PathsEqual(root, expectedRoot)
                || !string.Equals(generationId, expectedGenerationId, StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(runtime, expectedRuntime))
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "SUPERVISOR_IDENTITY_MISMATCH",
                    "The Supervisor status belongs to a different project, generation, or runtime path.");
            }

            var desiredState = AICodedbStrictJson.GetRequiredString(
                status,
                "desired_state",
                "CodeDB Supervisor status");
            var editorDemand = AICodedbStrictJson.GetRequiredString(
                status,
                "editor_demand",
                "CodeDB Supervisor status");
            var providerState = AICodedbStrictJson.GetRequiredString(
                status,
                "provider_state",
                "CodeDB Supervisor status");
            var providerReadyAtUtc = AICodedbStrictJson.GetRequiredNullableString(
                status,
                "provider_ready_at_utc",
                "CodeDB Supervisor status");
            if (string.Equals(providerState, "ready", StringComparison.Ordinal)
                && string.IsNullOrWhiteSpace(providerReadyAtUtc))
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "INVALID_PROVIDER_HANDSHAKE",
                    "The Supervisor reported a ready Provider without initialize/tools evidence.");
            }
            var adapterEnabled = AICodedbStrictJson.GetRequiredBoolean(
                status,
                "adapter_enabled",
                "CodeDB Supervisor status");
            var adapterState = AICodedbStrictJson.GetRequiredString(
                status,
                "adapter_state",
                "CodeDB Supervisor status");
            var adapterWorkerState = AICodedbStrictJson.GetRequiredString(
                status,
                "adapter_worker_state",
                "CodeDB Supervisor status");
            var adapterWorker = AICodedbStrictJson.GetRequiredNullableString(
                status,
                "adapter_worker",
                "CodeDB Supervisor status");
            AICodedbSupervisorReadinessState readiness;
            string reasonCode;
            string detail;
            if (!AICodedbSupervisorProtocol.TryResolveReadiness(
                    desiredState,
                    editorDemand,
                    providerState,
                    adapterEnabled,
                    adapterState,
                    adapterWorkerState,
                    !string.IsNullOrWhiteSpace(adapterWorker),
                    out readiness,
                    out reasonCode,
                    out detail))
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "INVALID_SUPERVISOR_READINESS",
                    "The Supervisor status contains an unsupported readiness combination.");
            }

            return AICodedbSupervisorSnapshot.Connected(
                schema,
                AICodedbStrictJson.GetOptionalNullableInt32(status, "coordinator_pid", "CodeDB Supervisor status") ?? 0,
                AICodedbStrictJson.GetOptionalNullableString(status, "lifecycle_id", "CodeDB Supervisor status"),
                runtime,
                providerState,
                providerReadyAtUtc,
                adapterState,
                adapterWorkerState,
                desiredState,
                editorDemand,
                readiness,
                reasonCode,
                detail,
                AICodedbStrictJson.GetOptionalNullableString(status, "last_event", "CodeDB Supervisor status"));
        }
    }
}
