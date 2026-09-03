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
        internal int SupervisorSchemaVersion { get; }
        internal string TargetGenerationId { get; }
        internal string SelectedGenerationId { get; }
        internal string RuntimeContractSha256 { get; }
        internal string GenerationDisposition { get; }
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
            string lastEvent,
            int supervisorSchemaVersion = 0,
            string targetGenerationId = "",
            string selectedGenerationId = "",
            string runtimeContractSha256 = "",
            string generationDisposition = "")
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
            SupervisorSchemaVersion = supervisorSchemaVersion;
            TargetGenerationId = targetGenerationId ?? string.Empty;
            SelectedGenerationId = selectedGenerationId ?? string.Empty;
            RuntimeContractSha256 = runtimeContractSha256 ?? string.Empty;
            GenerationDisposition = generationDisposition ?? string.Empty;
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
            string lastEvent,
            int supervisorSchemaVersion,
            string targetGenerationId,
            string selectedGenerationId,
            string runtimeContractSha256,
            string generationDisposition)
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
                lastEvent,
                supervisorSchemaVersion,
                targetGenerationId,
                selectedGenerationId,
                runtimeContractSha256,
                generationDisposition);
        }
    }

    /// <summary>
    /// A bounded command response returned by the project-local Supervisor.
    /// Status is always optional and is consumed through the Bridge cache;
    /// command output is retained only for the current asynchronous operation.
    /// </summary>
    internal sealed class AICodedbSupervisorCommandResponse
    {
        internal bool Succeeded { get; }
        internal int ExitCode { get; }
        internal string ErrorCode { get; }
        internal string Error { get; }
        internal string StandardOutput { get; }
        internal string StandardError { get; }
        internal AICodedbSupervisorSnapshot Snapshot { get; }
        internal string EventName { get; }
        internal long EventSequence { get; }
        internal bool OneShotFallbackAuthorized { get; }

        internal AICodedbSupervisorCommandResponse(
            bool succeeded,
            int exitCode,
            string errorCode,
            string error,
            string standardOutput,
            string standardError,
            AICodedbSupervisorSnapshot snapshot,
            string eventName,
            long eventSequence,
            bool oneShotFallbackAuthorized = false)
        {
            Succeeded = succeeded;
            ExitCode = exitCode;
            ErrorCode = errorCode ?? string.Empty;
            Error = error ?? string.Empty;
            StandardOutput = standardOutput ?? string.Empty;
            StandardError = standardError ?? string.Empty;
            Snapshot = snapshot;
            EventName = eventName ?? string.Empty;
            EventSequence = eventSequence;
            OneShotFallbackAuthorized = oneShotFallbackAuthorized;
        }

        internal AICodedbCommandResult ToCommandResult()
        {
            var error = string.IsNullOrWhiteSpace(StandardError) ? Error : StandardError;
            if (!Succeeded && !string.IsNullOrWhiteSpace(ErrorCode))
                error = "[SUPERVISOR:" + ErrorCode + "] " + error;
            return new AICodedbCommandResult(
                ExitCode,
                StandardOutput,
                error,
                false,
                0,
                OneShotFallbackAuthorized);
        }
    }

    internal static class AICodedbSupervisorProtocol
    {
        // The envelope and coordinator state schema form the minimum v0.3
        // handshake. The selected immutable coordinator is the project-local
        // Supervisor process; its schema-2 status is the compatibility proof
        // without changing the immutable generation bytes in this task.
        internal const int Version = 1;
        internal const int LegacySupervisorVersion = 1;
        internal const int SupervisorVersion = 2;
        internal const int SupervisorStateSchemaVersion = 3;
        internal const int CoordinatorStateSchemaVersion = 2;
        internal const int MaximumMessageBytes = 64 * 1024;
        internal const int ConnectionTimeoutMilliseconds = 1500;
        internal const int OperationPollIntervalMilliseconds = 100;
        internal const int OperationCompletionTimeoutMilliseconds = 16 * 60 * 1000;
        internal const int LegacySupervisorDrainTimeoutMilliseconds = 30000;
        internal const int HandoffTimeoutMilliseconds = 5000;
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

        internal static string BuildCommandRequest(
            string authToken,
            string requestId,
            string command,
            string action,
            string expectedLifecycleId,
            bool confirmedProjectMutation)
        {
            if (string.IsNullOrWhiteSpace(authToken))
                throw new ArgumentException("An IPC auth token is required.", nameof(authToken));
            if (string.IsNullOrWhiteSpace(requestId))
                throw new ArgumentException("An IPC request id is required.", nameof(requestId));
            if (string.IsNullOrWhiteSpace(command))
                throw new ArgumentException("A Supervisor command is required.", nameof(command));

            var builder = new StringBuilder();
            builder.Append("{\"auth_token\":\"")
                .Append(EscapeJson(authToken))
                .Append("\",\"command\":\"")
                .Append(EscapeJson(command))
                .Append("\",\"protocol_version\":")
                .Append(Version.ToString(System.Globalization.CultureInfo.InvariantCulture))
                .Append(",\"client_kind\":\"")
                .Append(ClientKind)
                .Append("\",\"request_id\":\"")
                .Append(EscapeJson(requestId))
                .Append("\"");
            if (!string.IsNullOrWhiteSpace(action))
                builder.Append(",\"action\":\"").Append(EscapeJson(action)).Append("\"");
            if (!string.IsNullOrWhiteSpace(expectedLifecycleId))
                builder.Append(",\"expected_lifecycle_id\":\"").Append(EscapeJson(expectedLifecycleId)).Append("\"");
            if (confirmedProjectMutation)
                builder.Append(",\"confirmed_project_mutation\":true");
            builder.Append('}');
            var request = builder.ToString();
            if (Encoding.UTF8.GetByteCount(request) > MaximumMessageBytes)
                throw new ArgumentException("The Supervisor request exceeds the IPC message limit.", nameof(command));
            return request;
        }

        internal static string BuildOperationRequest(
            string authToken,
            string requestId,
            string operationId)
        {
            if (string.IsNullOrWhiteSpace(authToken))
                throw new ArgumentException("An IPC auth token is required.", nameof(authToken));
            if (string.IsNullOrWhiteSpace(requestId))
                throw new ArgumentException("An IPC request id is required.", nameof(requestId));
            if (string.IsNullOrWhiteSpace(operationId))
                throw new ArgumentException("A Supervisor operation id is required.", nameof(operationId));

            var request = "{\"auth_token\":\""
                          + EscapeJson(authToken)
                          + "\",\"command\":\"operation\",\"operation_id\":\""
                          + EscapeJson(operationId)
                          + "\",\"protocol_version\":"
                          + Version.ToString(System.Globalization.CultureInfo.InvariantCulture)
                          + ",\"client_kind\":\""
                          + ClientKind
                          + "\",\"request_id\":\""
                          + EscapeJson(requestId)
                          + "\"}";
            if (Encoding.UTF8.GetByteCount(request) > MaximumMessageBytes)
                throw new ArgumentException("The Supervisor operation request exceeds the IPC message limit.", nameof(operationId));
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

        internal static bool TryGetLegacySupervisorPipeName(
            string serializedProjectRoot,
            string serializedRuntime,
            out string pipeName)
        {
            pipeName = string.Empty;
            if (string.IsNullOrWhiteSpace(serializedProjectRoot)
                || string.IsNullOrWhiteSpace(serializedRuntime))
                return false;

            try
            {
                var input = serializedProjectRoot + "\n" + serializedRuntime;
                byte[] digest;
                using (var sha256 = SHA256.Create())
                    digest = sha256.ComputeHash(Encoding.UTF8.GetBytes(input));

                var hex = new StringBuilder(digest.Length * 2);
                for (var index = 0; index < digest.Length; index++)
                    hex.Append(digest[index].ToString("x2", System.Globalization.CultureInfo.InvariantCulture));

                pipeName = "codedb-supervisor-" + hex.ToString().Substring(0, 20);
                return true;
            }
            catch
            {
                pipeName = string.Empty;
                return false;
            }
        }

        internal static bool TryGetExpectedSupervisorPipeName(
            string projectRoot,
            string runtime,
            out string pipeName)
        {
            pipeName = string.Empty;
            if (!TryGetExpectedWindowsPipeName(projectRoot, runtime, out var coordinatorName))
                return false;
            var suffix = coordinatorName.StartsWith("codedb-watch-", StringComparison.OrdinalIgnoreCase)
                ? coordinatorName.Substring("codedb-watch-".Length)
                : coordinatorName;
            pipeName = "codedb-supervisor-" + suffix;
            return true;
        }

        internal static bool IsExpectedSupervisorPipeName(
            string actualPipeName,
            string projectRoot,
            string runtime,
            string serializedProjectRoot,
            string serializedRuntime)
        {
            if (string.IsNullOrWhiteSpace(actualPipeName))
                return false;
            if (TryGetExpectedSupervisorPipeName(projectRoot, runtime, out var canonical)
                && string.Equals(actualPipeName, canonical, StringComparison.OrdinalIgnoreCase))
                return true;

            // Protocol v1 originally hashed the native serialized Windows
            // paths. Recognize that exact identity only long enough to request
            // an authenticated handoff to the canonical path derivation.
            return TryGetLegacySupervisorPipeName(
                       serializedProjectRoot,
                       serializedRuntime,
                       out var legacy)
                   && string.Equals(actualPipeName, legacy, StringComparison.OrdinalIgnoreCase);
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

        internal static string EscapeJson(string value)
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

        private readonly struct SupervisorRuntimeIdentity
        {
            internal string Runtime { get; }
            internal string PipeName { get; }
            internal string AuthToken { get; }
            internal string TargetGenerationId { get; }
            internal string SelectedGenerationId { get; }
            internal string RuntimeContractSha256 { get; }
            internal AICodedbControlContractIdentity ControlContract { get; }
            internal string GenerationDisposition { get; }
            internal int SupervisorProtocolVersion { get; }
            internal string OwnerEpoch { get; }
            internal int SupervisorProcessId { get; }
            internal string ProcessStartIdentity { get; }
            internal string ExecutablePath { get; }
            internal string ArgvSha256 { get; }

            internal SupervisorRuntimeIdentity(
                string runtime,
                string pipeName,
                string authToken,
                string targetGenerationId,
                string selectedGenerationId,
                string runtimeContractSha256,
                AICodedbControlContractIdentity controlContract,
                string generationDisposition,
                int supervisorProtocolVersion,
                string ownerEpoch,
                int supervisorProcessId,
                string processStartIdentity,
                string executablePath,
                string argvSha256)
            {
                Runtime = runtime;
                PipeName = pipeName;
                AuthToken = authToken;
                TargetGenerationId = targetGenerationId;
                SelectedGenerationId = selectedGenerationId;
                RuntimeContractSha256 = runtimeContractSha256;
                ControlContract = controlContract;
                GenerationDisposition = generationDisposition;
                SupervisorProtocolVersion = supervisorProtocolVersion;
                OwnerEpoch = ownerEpoch;
                SupervisorProcessId = supervisorProcessId;
                ProcessStartIdentity = processStartIdentity;
                ExecutablePath = executablePath;
                ArgvSha256 = argvSha256;
            }
        }

        private const long CoordinatorStateMaximumBytes = 128 * 1024;
        private const long SupervisorStateMaximumBytes = 128 * 1024;
        private readonly object _gate = new object();
        private AICodedbSupervisorSnapshot _cachedSnapshot =
            AICodedbSupervisorSnapshot.Disconnected("NOT_CONNECTED", "The CodeDB Supervisor has not been contacted.");
        private Task<AICodedbSupervisorSnapshot> _inFlight;
        private WorkerCancellation _cancellation;
        private int _epoch;
        private bool _disposed;
        private string _connectedStatePath = string.Empty;

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

        internal Task<AICodedbSupervisorCommandResponse> SendCommandAsync(
            string projectRoot,
            string command,
            string action = null,
            string expectedLifecycleId = null,
            bool confirmedProjectMutation = false)
        {
            if (string.IsNullOrWhiteSpace(projectRoot))
            {
                return Task.FromResult(new AICodedbSupervisorCommandResponse(
                    false,
                    4,
                    "INVALID_PROJECT_ROOT",
                    "The Unity project root is empty.",
                    string.Empty,
                    string.Empty,
                    CachedSnapshot,
                    string.Empty,
                    0));
            }

            return Task.Run(
                () => SendCommandWorker(
                    projectRoot,
                    command,
                    action,
                    expectedLifecycleId,
                    confirmedProjectMutation,
                    CancellationToken.None));
        }

        /// <summary>
        /// Requests final shutdown only when existing Supervisor evidence can
        /// be authenticated. This path never launches a missing Supervisor.
        /// </summary>
        internal Task<AICodedbSupervisorCommandResponse> RequestOwnedShutdownAsync(
            string projectRoot,
            string expectedLifecycleId)
        {
            if (string.IsNullOrWhiteSpace(projectRoot))
            {
                return Task.FromResult(new AICodedbSupervisorCommandResponse(
                    true,
                    0,
                    "SUPERVISOR_ALREADY_STOPPED",
                    string.Empty,
                    string.Empty,
                    string.Empty,
                    AICodedbSupervisorSnapshot.Disconnected(
                        "SUPERVISOR_ALREADY_STOPPED",
                        "No project Supervisor shutdown was required."),
                    string.Empty,
                    0));
            }

            return Task.Run(
                () => SendCommandWorker(
                    projectRoot,
                    "shutdown",
                    null,
                    expectedLifecycleId,
                    false,
                    CancellationToken.None,
                    false));
        }

        internal AICodedbSupervisorCommandResponse SendCommand(
            string projectRoot,
            string command,
            string action = null,
            string expectedLifecycleId = null,
            bool confirmedProjectMutation = false,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return SendCommandWorker(
                projectRoot,
                command,
                action,
                expectedLifecycleId,
                confirmedProjectMutation,
                cancellationToken);
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
            try
            {
                var context = AICodedbPaths.CaptureExecutionContext();
                var runtimeContract = AICodedbPackageRuntimeContractStore.Read(context.PackageRoot);
                var supervisorStatePath = AICodedbSupervisorLauncher.GetSupervisorStatePath(
                    normalizedRoot,
                    runtimeContract.ControlContract);
                var stateExistedBeforeLaunch = File.Exists(supervisorStatePath);
                if (!stateExistedBeforeLaunch && IsCurrentInstanceSelectionMissing(normalizedRoot))
                {
                    return AICodedbSupervisorSnapshot.Disconnected(
                        "CURRENT_INSTANCE_UNAVAILABLE",
                        "No current CodeDB instance is selected.");
                }

                var launch = AICodedbSupervisorLauncher.EnsureStartedAsync(
                        context,
                        cancellationToken)
                    .GetAwaiter()
                    .GetResult();
                if (!launch.Succeeded)
                {
                    // A new owner can publish between the initial state check
                    // and the launcher request. Authenticate that race-created
                    // state, but never bypass the launcher for state that was
                    // already present (it may require stale-owner takeover).
                    if (!stateExistedBeforeLaunch && File.Exists(supervisorStatePath))
                    {
                        return ConnectSupervisorWorker(
                            normalizedRoot,
                            supervisorStatePath,
                            runtimeContract,
                            cancellationToken);
                    }
                    return AICodedbSupervisorSnapshot.Degraded(
                        "SUPERVISOR_START_FAILED",
                        string.IsNullOrWhiteSpace(launch.StandardError)
                            ? launch.StandardOutput
                            : launch.StandardError);
                }
                return ConnectSupervisorWorker(
                    normalizedRoot,
                    supervisorStatePath,
                    runtimeContract,
                    cancellationToken);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception exception)
            {
                return AICodedbSupervisorSnapshot.Degraded("SUPERVISOR_START_FAILED", exception.Message);
            }
        }

        private static AICodedbSupervisorSnapshot ConnectSupervisorWorker(
            string normalizedRoot,
            string statePath,
            AICodedbPackageRuntimeContract runtimeContract,
            CancellationToken cancellationToken)
        {
            try
            {
                var observedIdentity = ReadSupervisorRuntimeIdentity(
                    normalizedRoot,
                    statePath,
                    runtimeContract);
                SupervisorRuntimeIdentity identity;
                if (!TryEnsureCurrentSupervisorProtocol(
                        normalizedRoot,
                        statePath,
                        observedIdentity,
                        runtimeContract,
                        cancellationToken,
                        out identity,
                        out var protocolError))
                {
                    return AICodedbSupervisorSnapshot.Blocked(
                        "SUPERVISOR_PROTOCOL_HANDOFF_FAILED",
                        protocolError);
                }

                cancellationToken.ThrowIfCancellationRequested();
                var responseLine = SendPipeRequest(
                    identity.PipeName,
                    AICodedbSupervisorProtocol.BuildStatusRequest(
                        identity.AuthToken,
                        Guid.NewGuid().ToString("N")),
                    cancellationToken);
                if (string.IsNullOrWhiteSpace(responseLine))
                {
                    return AICodedbSupervisorSnapshot.Degraded(
                        "SUPERVISOR_UNREACHABLE",
                        "The project Supervisor did not return a status response.");
                }
                return ParseStatusResponse(
                    responseLine,
                    normalizedRoot,
                    identity.SelectedGenerationId,
                    identity.TargetGenerationId,
                    identity.RuntimeContractSha256,
                    identity.GenerationDisposition,
                    identity.Runtime,
                    identity.ControlContract);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (InvalidOperationException exception)
            {
                return AICodedbSupervisorSnapshot.Blocked("INVALID_SUPERVISOR_STATE", exception.Message);
            }
            catch (Exception exception)
            {
                return AICodedbSupervisorSnapshot.Degraded("SUPERVISOR_BRIDGE_ERROR", exception.Message);
            }
        }

        private static bool TryEnsureCurrentSupervisorProtocol(
            string normalizedRoot,
            string statePath,
            SupervisorRuntimeIdentity observedIdentity,
            AICodedbPackageRuntimeContract runtimeContract,
            CancellationToken cancellationToken,
            out SupervisorRuntimeIdentity identity,
            out string error)
        {
            identity = observedIdentity;
            error = string.Empty;
            if (observedIdentity.SupervisorProtocolVersion == AICodedbSupervisorProtocol.SupervisorVersion)
                return true;
            if (observedIdentity.SupervisorProtocolVersion != AICodedbSupervisorProtocol.LegacySupervisorVersion)
            {
                error = "The running project Supervisor uses an unsupported command protocol.";
                return false;
            }

            try
            {
                if (!WaitForLegacySupervisorIdle(
                        normalizedRoot,
                        statePath,
                        AICodedbSupervisorProtocol.LegacySupervisorDrainTimeoutMilliseconds,
                        cancellationToken))
                {
                    error = "The legacy project Supervisor did not finish its admitted maintenance operation before protocol handoff.";
                    return false;
                }

                if (File.Exists(statePath))
                {
                    var shutdownLine = SendPipeRequest(
                        observedIdentity.PipeName,
                        AICodedbSupervisorProtocol.BuildCommandRequest(
                            observedIdentity.AuthToken,
                            Guid.NewGuid().ToString("N"),
                            "shutdown",
                            null,
                            null,
                            false),
                        cancellationToken);
                    if (string.IsNullOrWhiteSpace(shutdownLine))
                        throw new InvalidOperationException("The legacy Supervisor closed protocol handoff without a response.");
                    var shutdown = AICodedbStrictJson.ParseObject(
                        shutdownLine,
                        "CodeDB legacy Supervisor handoff response");
                    if (!AICodedbStrictJson.GetRequiredBoolean(
                            shutdown,
                            "ok",
                            "CodeDB legacy Supervisor handoff response"))
                    {
                        throw new InvalidOperationException(
                            AICodedbStrictJson.GetOptionalNullableString(
                                shutdown,
                                "error",
                                "CodeDB legacy Supervisor handoff response")
                            ?? "The legacy Supervisor refused protocol handoff.");
                    }
                }

                if (!WaitForSupervisorRetirement(
                        normalizedRoot,
                        statePath,
                        observedIdentity.Runtime,
                        AICodedbSupervisorProtocol.HandoffTimeoutMilliseconds,
                        cancellationToken))
                {
                    error = "The authenticated legacy Supervisor did not retire within the bounded protocol handoff window.";
                    return false;
                }

                var context = AICodedbPaths.CaptureExecutionContext();
                if (!AICodedbSupervisorProtocol.PathsEqual(context.ProjectRoot, normalizedRoot))
                {
                    error = "The Unity execution context changed during Supervisor protocol handoff.";
                    return false;
                }
                var launch = AICodedbSupervisorLauncher.EnsureStartedAsync(
                        context,
                        cancellationToken)
                    .GetAwaiter()
                    .GetResult();
                if (!launch.Succeeded)
                {
                    error = string.IsNullOrWhiteSpace(launch.StandardError)
                        ? launch.StandardOutput
                        : launch.StandardError;
                    return false;
                }

                identity = ReadSupervisorRuntimeIdentity(
                    normalizedRoot,
                    statePath,
                    runtimeContract);
                if (identity.SupervisorProtocolVersion != AICodedbSupervisorProtocol.SupervisorVersion)
                {
                    error = "The restarted project Supervisor did not publish the current operation protocol.";
                    return false;
                }
                return true;
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception exception)
            {
                error = exception.Message;
                return false;
            }
        }

        internal static bool WaitForLegacySupervisorIdle(
            string normalizedRoot,
            string statePath,
            int timeoutMilliseconds,
            CancellationToken cancellationToken)
        {
            var deadline = DateTime.UtcNow.AddMilliseconds(timeoutMilliseconds);
            while (File.Exists(statePath))
            {
                cancellationToken.ThrowIfCancellationRequested();
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, statePath);
                var state = AICodedbStrictJson.ReadObject(
                    statePath,
                    SupervisorStateMaximumBytes,
                    "CodeDB legacy Supervisor state");
                if (!state.ContainsKey("operation") || state["operation"] == null)
                    return true;
                var operation = AICodedbStrictJson.RequireObject(
                    state["operation"],
                    "CodeDB legacy Supervisor operation");
                var operationState = AICodedbStrictJson.GetRequiredString(
                    operation,
                    "state",
                    "CodeDB legacy Supervisor operation");
                if (!string.Equals(operationState, "running", StringComparison.Ordinal))
                    return true;
                if (DateTime.UtcNow >= deadline)
                    return false;
                Thread.Sleep(25);
            }
            return true;
        }

        private static SupervisorRuntimeIdentity ReadSupervisorRuntimeIdentity(
            string normalizedRoot,
            string statePath,
            AICodedbPackageRuntimeContract runtimeContract)
        {
            const string label = "CodeDB Supervisor state";
            if (runtimeContract == null || !runtimeContract.ControlContract.IsValid)
                throw new InvalidOperationException("Package control contract identity is invalid.");

            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, statePath);
            var state = AICodedbStrictJson.ReadObject(
                statePath,
                SupervisorStateMaximumBytes,
                label);
            var stateSchema = AICodedbStrictJson.GetRequiredInt32(state, "schema_version", label);
            var stateProtocol = AICodedbStrictJson.GetRequiredInt32(state, "protocol_version", label);
            var stateManagedBy = AICodedbStrictJson.GetRequiredString(state, "managed_by", label);
            var stateRole = AICodedbStrictJson.GetRequiredString(state, "role", label);
            var stateRoot = AICodedbStrictJson.GetRequiredString(state, "root", label);
            var stateProjectIdentity = AICodedbStrictJson.GetRequiredString(state, "project_identity", label);
            var controlContractId = AICodedbStrictJson.GetRequiredString(state, "control_contract_id", label);
            var controlContractVersion = AICodedbStrictJson.GetRequiredInt32(state, "control_contract_version", label);
            var controlContractSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                state,
                "control_contract_schema_version",
                label);
            var controlContractSha256 = AICodedbStrictJson.GetRequiredString(
                state,
                "control_contract_sha256",
                label);
            var controlNamespace = AICodedbStrictJson.GetRequiredString(state, "control_namespace", label);
            var stateGenerationId = AICodedbStrictJson.GetRequiredString(state, "generation_id", label);
            var targetGenerationId = AICodedbStrictJson.GetRequiredString(state, "target_generation_id", label);
            var selectedGenerationId = AICodedbStrictJson.GetRequiredString(state, "selected_generation_id", label);
            var selectedInstanceId = AICodedbStrictJson.GetOptionalNullableString(
                state,
                "selected_instance_id",
                label);
            var runtimeContractSha256 = AICodedbStrictJson.GetRequiredString(state, "runtime_contract_sha256", label);
            var supervisorProtocol = AICodedbStrictJson.GetRequiredInt32(state, "supervisor_protocol_version", label);
            var generationDisposition = AICodedbStrictJson.GetRequiredString(state, "generation_disposition", label);
            var stateRuntime = AICodedbStrictJson.GetRequiredString(state, "runtime", label);
            var authToken = AICodedbStrictJson.GetRequiredString(state, "auth_token", label);
            var pipeValue = AICodedbStrictJson.GetRequiredString(state, "pipe_name", label);
            var evidenceSchema = AICodedbStrictJson.GetRequiredInt32(state, "evidence_schema_version", label);
            var supervisorProcessId = AICodedbStrictJson.GetRequiredInt32(state, "supervisor_pid", label);
            var supervisorId = AICodedbStrictJson.GetRequiredString(state, "supervisor_id", label);
            var ownerEpoch = AICodedbStrictJson.GetRequiredString(state, "owner_epoch", label);
            var publicationPhase = AICodedbStrictJson.GetRequiredString(state, "publication_phase", label);
            var ownerEvidence = AICodedbStrictJson.RequireObject(
                state["owner_evidence"],
                "CodeDB Supervisor process evidence");
            var ownerEvidenceSchema = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "schema_version",
                "CodeDB Supervisor process evidence");
            var evidencePid = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "pid",
                "CodeDB Supervisor process evidence");
            var processStartIdentity = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "process_start_identity",
                "CodeDB Supervisor process evidence");
            var executablePath = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "executable_path",
                "CodeDB Supervisor process evidence");
            var argvSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "argv_sha256",
                "CodeDB Supervisor process evidence");
            var commandLineSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "command_line_sha256",
                "CodeDB Supervisor process evidence");
            var expectedRuntime = AICodedbSupervisorLauncher.GetSupervisorRuntimePath(
                normalizedRoot,
                runtimeContract.ControlContract);
            var parsedPipe = AICodedbSupervisorProtocol.TryGetWindowsPipeName(pipeValue, out var pipeName);
            var canonicalPipe = parsedPipe
                                && AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                                    normalizedRoot,
                                    expectedRuntime,
                                    out var expectedPipeName)
                                && string.Equals(pipeName, expectedPipeName, StringComparison.OrdinalIgnoreCase);
            var legacyPipe = parsedPipe
                             && AICodedbSupervisorProtocol.TryGetLegacySupervisorPipeName(
                                 stateRoot,
                                 stateRuntime,
                                 out var legacyPipeName)
                             && string.Equals(pipeName, legacyPipeName, StringComparison.OrdinalIgnoreCase);
            var dispositionIsCurrent = string.Equals(
                generationDisposition,
                "CURRENT",
                StringComparison.Ordinal);
            var dispositionIsPrevious = string.Equals(
                generationDisposition,
                "TRUSTED_PREVIOUS",
                StringComparison.Ordinal);
            if (stateSchema != AICodedbSupervisorProtocol.SupervisorStateSchemaVersion
                || evidenceSchema != 1
                || ownerEvidenceSchema != 1
                || stateProtocol != AICodedbSupervisorProtocol.Version
                || (supervisorProtocol != AICodedbSupervisorProtocol.SupervisorVersion
                    && supervisorProtocol != AICodedbSupervisorProtocol.LegacySupervisorVersion)
                || !string.Equals(stateManagedBy, "com.rice.ai-codedb", StringComparison.Ordinal)
                || !string.Equals(stateRole, AICodedbSupervisorProtocol.SupervisorRole, StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(stateRoot, normalizedRoot)
                || !string.Equals(
                    stateProjectIdentity,
                    AICodedbEditorLifecycle.CreateProjectIdentity(normalizedRoot),
                    StringComparison.Ordinal)
                || !string.Equals(
                    controlContractId,
                    runtimeContract.ControlContract.Id,
                    StringComparison.Ordinal)
                || controlContractVersion != runtimeContract.ControlContract.Version
                || controlContractSchemaVersion != runtimeContract.ControlContract.SchemaVersion
                || !string.Equals(
                    controlContractSha256,
                    runtimeContract.ControlContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || !AICodedbSupervisorProtocol.PathsEqual(controlNamespace, expectedRuntime)
                || !IsGenerationId(targetGenerationId)
                || !IsGenerationId(selectedGenerationId)
                || !string.Equals(stateGenerationId, selectedGenerationId, StringComparison.Ordinal)
                || (supervisorProtocol == AICodedbSupervisorProtocol.SupervisorVersion
                    && !IsInstanceId(selectedInstanceId))
                || (!string.IsNullOrWhiteSpace(selectedInstanceId)
                    && !IsInstanceId(selectedInstanceId))
                || !IsSha256(runtimeContractSha256)
                || !string.Equals(
                    runtimeContractSha256,
                    runtimeContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || (!dispositionIsCurrent && !dispositionIsPrevious)
                || (dispositionIsCurrent
                    && !string.Equals(targetGenerationId, selectedGenerationId, StringComparison.Ordinal))
                || !AICodedbSupervisorProtocol.PathsEqual(stateRuntime, expectedRuntime)
                || (!canonicalPipe && !legacyPipe)
                || string.IsNullOrWhiteSpace(authToken)
                || supervisorProcessId <= 0
                || evidencePid != supervisorProcessId
                || !string.Equals(supervisorId, "unity-bridge", StringComparison.Ordinal)
                || !IsOwnerId(ownerEpoch)
                || (!string.Equals(publicationPhase, "state_published", StringComparison.Ordinal)
                    && !string.Equals(publicationPhase, "listening", StringComparison.Ordinal)
                    && !string.Equals(publicationPhase, "retiring", StringComparison.Ordinal))
                || !IsProcessStartIdentity(processStartIdentity)
                || !Path.IsPathRooted(executablePath)
                || !IsSha256(argvSha256)
                || !IsSha256(commandLineSha256))
            {
                throw new InvalidOperationException(
                    "The project Supervisor state does not match the selected project runtime contract or pipe identity.");
            }

            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, stateRuntime);
            return new SupervisorRuntimeIdentity(
                stateRuntime,
                pipeName,
                authToken,
                targetGenerationId,
                selectedGenerationId,
                runtimeContractSha256,
                runtimeContract.ControlContract,
                generationDisposition,
                supervisorProtocol,
                ownerEpoch,
                supervisorProcessId,
                processStartIdentity,
                executablePath,
                argvSha256);
        }

        private static bool IsOwnerId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 128)
                return false;
            foreach (var character in value)
            {
                if ((character >= 'a' && character <= 'z')
                    || (character >= 'A' && character <= 'Z')
                    || (character >= '0' && character <= '9')
                    || character == '.' || character == '_' || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        private static bool IsInstanceId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length != 32)
                return false;
            foreach (var character in value)
            {
                if ((character >= '0' && character <= '9')
                    || (character >= 'a' && character <= 'f'))
                    continue;
                return false;
            }
            return true;
        }

        private static bool IsProcessStartIdentity(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 32)
                return false;
            foreach (var character in value)
            {
                if (character < '0' || character > '9')
                    return false;
            }
            return true;
        }

        private static bool IsGenerationId(string value)
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

        private static bool IsSha256(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length != 64)
                return false;
            foreach (var character in value)
            {
                if ((character >= '0' && character <= '9')
                    || (character >= 'a' && character <= 'f'))
                    continue;
                return false;
            }
            return true;
        }

        private AICodedbSupervisorCommandResponse SendCommandWorker(
            string projectRoot,
            string command,
            string action,
            string expectedLifecycleId,
            bool confirmedProjectMutation,
            CancellationToken cancellationToken,
            bool startIfMissing = true)
        {
            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/', '\\');
                var context = AICodedbPaths.CaptureExecutionContext();
                var runtimeContract = AICodedbPackageRuntimeContractStore.Read(context.PackageRoot);
                var statePath = AICodedbSupervisorLauncher.GetSupervisorStatePath(
                    normalizedRoot,
                    runtimeContract.ControlContract);
                if (!startIfMissing)
                {
                    if (!string.Equals(command, "shutdown", StringComparison.Ordinal))
                    {
                        return new AICodedbSupervisorCommandResponse(
                            false,
                            4,
                            "SUPERVISOR_START_DISABLED",
                            "The requested Supervisor command cannot start a missing project Supervisor.",
                            string.Empty,
                            string.Empty,
                            AICodedbSupervisorSnapshot.Disconnected(
                                "SUPERVISOR_START_DISABLED",
                                "The requested Supervisor command cannot start a missing project Supervisor."),
                            string.Empty,
                            0);
                    }
                }
                if (string.Equals(command, "shutdown", StringComparison.Ordinal))
                {
                    if (!File.Exists(statePath))
                    {
                        if (!startIfMissing && IsCurrentInstanceSelectionMissing(normalizedRoot))
                        {
                            const string detail = "No current CodeDB instance is selected.";
                            return new AICodedbSupervisorCommandResponse(
                                false,
                                4,
                                "CURRENT_INSTANCE_UNAVAILABLE",
                                detail,
                                string.Empty,
                                detail,
                                AICodedbSupervisorSnapshot.Disconnected(
                                    "CURRENT_INSTANCE_UNAVAILABLE",
                                    detail),
                                string.Empty,
                                0);
                        }

                        return new AICodedbSupervisorCommandResponse(
                            true,
                            0,
                            "SUPERVISOR_ALREADY_STOPPED",
                            string.Empty,
                            string.Empty,
                            string.Empty,
                            AICodedbSupervisorSnapshot.Disconnected(
                                "SUPERVISOR_ALREADY_STOPPED",
                                "No running project Supervisor required shutdown."),
                            string.Empty,
                            0);
                    }

                }
                else if (startIfMissing)
                {
                    var stateExistedBeforeLaunch = File.Exists(statePath);
                    if (!stateExistedBeforeLaunch
                        && IsCurrentInstanceSelectionMissing(normalizedRoot))
                    {
                        const string detail = "No current CodeDB instance is selected.";
                        return new AICodedbSupervisorCommandResponse(
                            false,
                            4,
                            "CURRENT_INSTANCE_UNAVAILABLE",
                            detail,
                            string.Empty,
                            detail,
                            AICodedbSupervisorSnapshot.Disconnected("CURRENT_INSTANCE_UNAVAILABLE", detail),
                            string.Empty,
                            0,
                            IsProvenBootstrapFallback(
                                normalizedRoot,
                                AICodedbSupervisorLauncher.GetSupervisorRuntimePath(
                                    normalizedRoot,
                                    runtimeContract.ControlContract),
                                command,
                                action,
                                confirmedProjectMutation,
                                startIfMissing));
                    }

                    var launch = AICodedbSupervisorLauncher.EnsureStartedAsync(
                            context,
                            cancellationToken)
                        .GetAwaiter()
                        .GetResult();
                    if (!launch.Succeeded
                        && (stateExistedBeforeLaunch || !File.Exists(statePath)))
                    {
                        return new AICodedbSupervisorCommandResponse(
                            false,
                            launch.ExitCode,
                            "SUPERVISOR_START_FAILED",
                            launch.StandardError,
                            launch.StandardOutput,
                            launch.StandardError,
                            AICodedbSupervisorSnapshot.Degraded("SUPERVISOR_START_FAILED", launch.StandardError),
                            string.Empty,
                            0);
                    }
                }

                var observedIdentity = ReadSupervisorRuntimeIdentity(
                    normalizedRoot,
                    statePath,
                    runtimeContract);
                var identity = observedIdentity;
                if (!string.Equals(command, "shutdown", StringComparison.Ordinal)
                    && !TryEnsureCurrentSupervisorProtocol(
                        normalizedRoot,
                        statePath,
                        observedIdentity,
                        runtimeContract,
                        cancellationToken,
                        out identity,
                        out var protocolError))
                {
                    return new AICodedbSupervisorCommandResponse(
                        false,
                        4,
                        "SUPERVISOR_PROTOCOL_HANDOFF_FAILED",
                        protocolError,
                        string.Empty,
                        protocolError,
                        AICodedbSupervisorSnapshot.Blocked(
                            "SUPERVISOR_PROTOCOL_HANDOFF_FAILED",
                            protocolError),
                        string.Empty,
                        0);
                }

                var request = AICodedbSupervisorProtocol.BuildCommandRequest(
                    identity.AuthToken,
                    Guid.NewGuid().ToString("N"),
                    command,
                    action,
                    expectedLifecycleId,
                    confirmedProjectMutation);
                var responseLine = SendPipeRequest(identity.PipeName, request, cancellationToken);
                if (string.IsNullOrWhiteSpace(responseLine))
                    throw new InvalidOperationException("The project Supervisor closed the command without a response.");
                responseLine = WaitForAcceptedOperation(
                    responseLine,
                    normalizedRoot,
                    identity,
                    cancellationToken);

                var response = AICodedbStrictJson.ParseObject(responseLine, "CodeDB Supervisor command response");
                var succeeded = AICodedbStrictJson.GetRequiredBoolean(response, "ok", "CodeDB Supervisor command response");
                var errorCode = AICodedbStrictJson.GetOptionalNullableString(response, "error_code", "CodeDB Supervisor command response") ?? string.Empty;
                var error = AICodedbStrictJson.GetOptionalNullableString(response, "error", "CodeDB Supervisor command response") ?? string.Empty;
                var result = response.ContainsKey("result") && response["result"] != null
                    ? AICodedbStrictJson.RequireObject(response["result"], "CodeDB Supervisor command result")
                    : null;
                var exitCode = result == null
                    ? (succeeded ? 0 : 4)
                    : AICodedbStrictJson.GetOptionalNullableInt32(result, "exit_code", "CodeDB Supervisor command result") ?? (succeeded ? 0 : 4);
                var standardOutput = result == null
                    ? string.Empty
                    : AICodedbStrictJson.GetOptionalNullableString(result, "stdout", "CodeDB Supervisor command result") ?? string.Empty;
                var standardError = result == null
                    ? error
                    : AICodedbStrictJson.GetOptionalNullableString(result, "stderr", "CodeDB Supervisor command result") ?? error;
                AICodedbSupervisorSnapshot snapshot = null;
                string eventName = string.Empty;
                long eventSequence = 0;
                if (response.ContainsKey("status") && response["status"] != null)
                {
                    var status = AICodedbStrictJson.RequireObject(response["status"], "CodeDB Supervisor command status");
                    snapshot = ParseStatusResponse(
                        "{\"ok\":true,\"status\":" + SerializeJsonObject(status) + "}",
                        normalizedRoot,
                        identity.SelectedGenerationId,
                        identity.TargetGenerationId,
                        identity.RuntimeContractSha256,
                        identity.GenerationDisposition,
                        identity.Runtime,
                        identity.ControlContract);
                    eventName = AICodedbStrictJson.GetOptionalNullableString(status, "last_event", "CodeDB Supervisor command status") ?? string.Empty;
                    eventSequence = AICodedbStrictJson.GetOptionalNullableInt32(status, "event_sequence", "CodeDB Supervisor command status") ?? 0;
                }
                var commandSucceeded = succeeded && exitCode == 0;
                var handoffQueued = AICodedbStrictJson.GetOptionalBoolean(
                    response,
                    "handoff_queued",
                    "CodeDB Supervisor command response",
                    false);
                if (ShouldHandoffAfterMaterializerCommand(
                        command,
                        commandSucceeded,
                        handoffQueued))
                {
                    if (!CompleteSupervisorHandoff(
                            normalizedRoot,
                            statePath,
                            identity,
                            handoffQueued,
                            cancellationToken,
                            out var handoffError))
                    {
                        return new AICodedbSupervisorCommandResponse(
                            false,
                            4,
                            "SUPERVISOR_HANDOFF_FAILED",
                            handoffError,
                            standardOutput,
                            handoffError,
                            AICodedbSupervisorSnapshot.Blocked(
                                "SUPERVISOR_HANDOFF_FAILED",
                                handoffError),
                            eventName,
                            eventSequence);
                    }

                    Invalidate();
                    snapshot = AICodedbSupervisorSnapshot.Disconnected(
                        "SUPERVISOR_HANDOFF_COMPLETE",
                        "The previous Supervisor retired after atomic instance activation.");
                }
                return new AICodedbSupervisorCommandResponse(
                    succeeded && exitCode == 0,
                    exitCode,
                    errorCode,
                    error,
                    standardOutput,
                    standardError,
                    snapshot,
                    eventName,
                    eventSequence);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (InvalidOperationException exception)
            {
                return new AICodedbSupervisorCommandResponse(
                    false,
                    4,
                    "INVALID_SUPERVISOR_EVIDENCE",
                    exception.Message,
                    string.Empty,
                    exception.Message,
                    AICodedbSupervisorSnapshot.Blocked("INVALID_SUPERVISOR_EVIDENCE", exception.Message),
                    string.Empty,
                    0);
            }
            catch (Exception exception)
            {
                return new AICodedbSupervisorCommandResponse(
                    false,
                    4,
                    "SUPERVISOR_COMMAND_FAILED",
                    exception.Message,
                    string.Empty,
                    exception.Message,
                    AICodedbSupervisorSnapshot.Degraded("SUPERVISOR_COMMAND_FAILED", exception.Message),
                    string.Empty,
                    0);
            }
        }

        /// <summary>
        /// A one-shot materializer fallback is safe only for a true bootstrap:
        /// no selected instance exists and the project-local Supervisor control
        /// directory contains no owner, operation, or claim evidence. Any
        /// existing entry is treated as ambiguous and keeps the fallback closed.
        /// </summary>
        private static bool IsProvenBootstrapFallback(
            string normalizedRoot,
            string runtime,
            string command,
            string action,
            bool confirmedProjectMutation,
            bool startIfMissing)
        {
            if (!IsCurrentInstanceSelectionMissing(normalizedRoot)
                || !IsBootstrapFallbackCommandAllowed(
                    command,
                    action,
                    confirmedProjectMutation,
                    startIfMissing))
                return false;

            try
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, runtime);
                if (!Directory.Exists(runtime))
                    return true;

                // Do not whitelist individual filenames. A new control artifact
                // must close the bootstrap proof until its ownership semantics
                // are reviewed.
                return Directory.GetFileSystemEntries(runtime).Length == 0;
            }
            catch
            {
                return false;
            }
        }

        private static bool IsCurrentInstanceSelectionMissing(string normalizedRoot)
        {
            var selectionPath = AICodedbPaths.NormalizePath(Path.Combine(
                normalizedRoot,
                AICodedbProjectSettings.InstanceCurrentRelativePath));
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, selectionPath);
            return !File.Exists(selectionPath) && !Directory.Exists(selectionPath);
        }

        private static bool IsBootstrapFallbackCommandAllowed(
            string command,
            string action,
            bool confirmedProjectMutation,
            bool startIfMissing)
        {
            if (!startIfMissing
                || !string.Equals(command, "materialize", StringComparison.Ordinal))
                return false;

            if (string.Equals(action, "Probe", StringComparison.Ordinal)
                || string.Equals(action, "Upgrade", StringComparison.Ordinal))
                return !confirmedProjectMutation;

            return confirmedProjectMutation
                   && (string.Equals(action, "Install", StringComparison.Ordinal)
                       || string.Equals(action, "Reinstall", StringComparison.Ordinal)
                       || string.Equals(action, "Uninstall", StringComparison.Ordinal));
        }

        private string WaitForAcceptedOperation(
            string initialResponseLine,
            string normalizedRoot,
            SupervisorRuntimeIdentity identity,
            CancellationToken cancellationToken)
        {
            const string label = "CodeDB Supervisor operation response";
            var response = AICodedbStrictJson.ParseObject(initialResponseLine, label);
            CacheCommandStatus(response, normalizedRoot, identity);
            if (!AICodedbStrictJson.GetOptionalBoolean(response, "accepted", label, false)
                || !AICodedbStrictJson.GetOptionalBoolean(response, "pending", label, false))
                return initialResponseLine;

            var operationId = AICodedbStrictJson.GetRequiredString(response, "operation_id", label);
            if (!IsOperationId(operationId))
                throw new InvalidOperationException("The Supervisor returned an invalid operation id.");

            var deadline = DateTime.UtcNow.AddMilliseconds(
                AICodedbSupervisorProtocol.OperationCompletionTimeoutMilliseconds);
            while (true)
            {
                WaitForOperationPoll(deadline, cancellationToken);
                var responseLine = SendPipeRequest(
                    identity.PipeName,
                    AICodedbSupervisorProtocol.BuildOperationRequest(
                        identity.AuthToken,
                        Guid.NewGuid().ToString("N"),
                        operationId),
                    cancellationToken);
                if (string.IsNullOrWhiteSpace(responseLine))
                    throw new InvalidOperationException("The project Supervisor closed an operation query without a response.");

                response = AICodedbStrictJson.ParseObject(responseLine, label);
                var observedOperationId = AICodedbStrictJson.GetRequiredString(
                    response,
                    "operation_id",
                    label);
                if (!string.Equals(observedOperationId, operationId, StringComparison.Ordinal))
                    throw new InvalidOperationException("The Supervisor operation response changed identity.");

                CacheCommandStatus(response, normalizedRoot, identity);
                if (!AICodedbStrictJson.GetOptionalBoolean(response, "pending", label, false))
                    return responseLine;
            }
        }

        private void CacheCommandStatus(
            Dictionary<string, object> response,
            string normalizedRoot,
            SupervisorRuntimeIdentity identity)
        {
            if (!response.ContainsKey("status") || response["status"] == null)
                return;
            var status = AICodedbStrictJson.RequireObject(
                response["status"],
                "CodeDB Supervisor operation status");
            var snapshot = ParseStatusResponse(
                "{\"ok\":true,\"status\":" + SerializeJsonObject(status) + "}",
                normalizedRoot,
                identity.SelectedGenerationId,
                identity.TargetGenerationId,
                identity.RuntimeContractSha256,
                identity.GenerationDisposition,
                identity.Runtime,
                identity.ControlContract);
            lock (_gate)
            {
                if (!_disposed)
                    _cachedSnapshot = snapshot;
            }
        }

        private static void WaitForOperationPoll(
            DateTime deadline,
            CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var remaining = deadline - DateTime.UtcNow;
            if (remaining <= TimeSpan.Zero)
                throw new TimeoutException("The Supervisor operation did not reach a terminal state within its bounded execution window.");

            var delay = Math.Min(
                AICodedbSupervisorProtocol.OperationPollIntervalMilliseconds,
                Math.Max(1, (int)Math.Min(int.MaxValue, remaining.TotalMilliseconds)));
            for (var waited = 0; waited < delay; waited += 25)
            {
                cancellationToken.ThrowIfCancellationRequested();
                Thread.Sleep(Math.Min(25, delay - waited));
            }
        }

        private static bool IsOperationId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length != 32)
                return false;
            foreach (var character in value)
            {
                if ((character >= '0' && character <= '9')
                    || (character >= 'a' && character <= 'f'))
                    continue;
                return false;
            }
            return true;
        }

        internal static bool ShouldHandoffAfterMaterializerCommand(
            string command,
            bool commandSucceeded,
            bool handoffQueued)
        {
            return commandSucceeded
                   && handoffQueued
                   && string.Equals(command, "materialize", StringComparison.Ordinal);
        }

        private static bool CompleteSupervisorHandoff(
            string normalizedRoot,
            string statePath,
            SupervisorRuntimeIdentity identity,
            bool handoffAlreadyQueued,
            CancellationToken cancellationToken,
            out string error)
        {
            error = string.Empty;
            if (!handoffAlreadyQueued)
            {
                try
                {
                    var shutdownRequest = AICodedbSupervisorProtocol.BuildCommandRequest(
                        identity.AuthToken,
                        Guid.NewGuid().ToString("N"),
                        "shutdown",
                        null,
                        null,
                        false);
                    var shutdownLine = SendPipeRequest(
                        identity.PipeName,
                        shutdownRequest,
                        cancellationToken);
                    if (string.IsNullOrWhiteSpace(shutdownLine))
                        throw new InvalidOperationException(
                            "The previous Supervisor closed the handoff request without a response.");
                    var shutdown = AICodedbStrictJson.ParseObject(
                        shutdownLine,
                        "CodeDB Supervisor handoff response");
                    if (!AICodedbStrictJson.GetRequiredBoolean(
                            shutdown,
                            "ok",
                            "CodeDB Supervisor handoff response"))
                    {
                        throw new InvalidOperationException(
                            AICodedbStrictJson.GetOptionalNullableString(
                                shutdown,
                                "error",
                                "CodeDB Supervisor handoff response")
                            ?? "The previous Supervisor refused its authenticated handoff.");
                    }
                }
                catch (Exception exception) when (!(exception is OperationCanceledException))
                {
                    if (!WaitForSupervisorRetirement(
                            normalizedRoot,
                            statePath,
                            identity.Runtime,
                            250,
                            cancellationToken))
                    {
                        error = "The selected instance changed, but the authenticated previous Supervisor "
                                + "could not begin handoff: " + exception.Message;
                        return false;
                    }
                    return true;
                }
            }

            if (WaitForSupervisorRetirement(
                    normalizedRoot,
                    statePath,
                    identity.Runtime,
                    AICodedbSupervisorProtocol.HandoffTimeoutMilliseconds,
                    cancellationToken))
                return true;

            error = "The selected instance changed, but the authenticated previous Supervisor "
                    + "did not retire within the bounded handoff window.";
            return false;
        }

        private static bool WaitForSupervisorRetirement(
            string normalizedRoot,
            string statePath,
            string runtime,
            int timeoutMilliseconds,
            CancellationToken cancellationToken)
        {
            var lockPath = Path.Combine(runtime, "supervisor.lock");
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(normalizedRoot, runtime);
            var deadline = DateTime.UtcNow.AddMilliseconds(timeoutMilliseconds);
            while (File.Exists(statePath) || File.Exists(lockPath))
            {
                cancellationToken.ThrowIfCancellationRequested();
                if (DateTime.UtcNow >= deadline)
                    return false;
                Thread.Sleep(25);
            }
            return true;
        }

        internal static string SendPipeRequest(
            string pipeName,
            string request,
            CancellationToken cancellationToken)
        {
            using (var pipe = new NamedPipeClientStream(
                       ".",
                       pipeName,
                       PipeDirection.InOut,
                       PipeOptions.Asynchronous))
            {
                // Unity's Windows NamedPipeClientStream reports CanTimeout=false
                // and throws when ReadTimeout or WriteTimeout is assigned. Keep
                // the platform-bounded synchronous connect, then bound the
                // overlapped message exchange explicitly on this worker.
                cancellationToken.ThrowIfCancellationRequested();
                pipe.Connect(AICodedbSupervisorProtocol.ConnectionTimeoutMilliseconds);
                cancellationToken.ThrowIfCancellationRequested();
                var requestBytes = new UTF8Encoding(false, true).GetBytes(request + "\n");
                if (requestBytes.Length > AICodedbSupervisorProtocol.MaximumMessageBytes + 1)
                    throw new InvalidOperationException("The Supervisor request exceeds the IPC message limit.");

                var deadline = DateTime.UtcNow.AddMilliseconds(
                    AICodedbSupervisorProtocol.ConnectionTimeoutMilliseconds);
                WaitForPipeIo(
                    pipe.WriteAsync(requestBytes, 0, requestBytes.Length, CancellationToken.None),
                    pipe,
                    deadline,
                    cancellationToken);
                return ReadBoundedUtf8Line(pipe, deadline, cancellationToken);
            }
        }

        private static string ReadBoundedUtf8Line(
            PipeStream pipe,
            DateTime deadline,
            CancellationToken cancellationToken)
        {
            using (var response = new MemoryStream())
            {
                var reachedEndOfStream = false;
                var buffer = new byte[1];
                while (true)
                {
                    var count = WaitForPipeIo(
                        pipe.ReadAsync(buffer, 0, buffer.Length, CancellationToken.None),
                        pipe,
                        deadline,
                        cancellationToken);
                    if (count == 0)
                    {
                        reachedEndOfStream = true;
                        break;
                    }

                    if (buffer[0] == (byte)'\n' || buffer[0] == (byte)'\r')
                        break;
                    if (response.Length >= AICodedbSupervisorProtocol.MaximumMessageBytes)
                        throw new SupervisorMessageTooLargeException();
                    response.WriteByte(buffer[0]);
                }

                if (response.Length == 0 && reachedEndOfStream)
                    return null;
                return new UTF8Encoding(false, true).GetString(response.ToArray());
            }
        }

        private static void WaitForPipeIo(
            Task ioTask,
            PipeStream pipe,
            DateTime deadline,
            CancellationToken cancellationToken)
        {
            WaitForPipeIoCompletion(ioTask, pipe, deadline, cancellationToken);
            ioTask.GetAwaiter().GetResult();
        }

        private static T WaitForPipeIo<T>(
            Task<T> ioTask,
            PipeStream pipe,
            DateTime deadline,
            CancellationToken cancellationToken)
        {
            WaitForPipeIoCompletion(ioTask, pipe, deadline, cancellationToken);
            return ioTask.GetAwaiter().GetResult();
        }

        private static void WaitForPipeIoCompletion(
            Task ioTask,
            PipeStream pipe,
            DateTime deadline,
            CancellationToken cancellationToken)
        {
            if (ioTask.IsCompleted)
                return;

            var remaining = deadline - DateTime.UtcNow;
            if (remaining <= TimeSpan.Zero)
            {
                AbandonPipeIo(ioTask, pipe);
                cancellationToken.ThrowIfCancellationRequested();
                throw new TimeoutException("The Supervisor IPC request timed out.");
            }

            using (var cancellation = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
            {
                var timeout = Task.Delay(remaining, cancellation.Token);
                var completed = Task.WhenAny(ioTask, timeout).GetAwaiter().GetResult();
                if (ReferenceEquals(completed, ioTask))
                {
                    cancellation.Cancel();
                    return;
                }
            }

            AbandonPipeIo(ioTask, pipe);
            cancellationToken.ThrowIfCancellationRequested();
            throw new TimeoutException("The Supervisor IPC request timed out.");
        }

        private static void AbandonPipeIo(Task ioTask, PipeStream pipe)
        {
            try
            {
                pipe.Dispose();
            }
            catch
            {
                // The caller is already leaving a timed-out/canceled request.
            }

            _ = ioTask.ContinueWith(
                completed => { _ = completed.Exception; },
                CancellationToken.None,
                TaskContinuationOptions.OnlyOnFaulted | TaskContinuationOptions.ExecuteSynchronously,
                TaskScheduler.Default);
        }

        internal static string SerializeJsonObject(Dictionary<string, object> value)
        {
            // Status fields originate from the strict parser and are only
            // re-embedded to reuse the existing readiness reducer. Escaping is
            // deliberately delegated to the framework JSON serializer used by
            // the package's bounded evidence path.
            var builder = new StringBuilder("{");
            var first = true;
            foreach (var pair in value)
            {
                if (!first)
                    builder.Append(',');
                first = false;
                builder.Append('"').Append(AICodedbSupervisorProtocol.EscapeJson(pair.Key)).Append("\":");
                AppendJsonValue(builder, pair.Value);
            }
            builder.Append('}');
            return builder.ToString();
        }

        private static void AppendJsonValue(StringBuilder builder, object value)
        {
            if (value == null)
            {
                builder.Append("null");
                return;
            }
            if (value is string text)
            {
                builder.Append('"').Append(AICodedbSupervisorProtocol.EscapeJson(text)).Append('"');
                return;
            }
            if (value is bool boolean)
            {
                builder.Append(boolean ? "true" : "false");
                return;
            }
            if (value is Dictionary<string, object> document)
            {
                builder.Append(SerializeJsonObject(document));
                return;
            }
            if (value is IList<object> values)
            {
                builder.Append('[');
                for (var index = 0; index < values.Count; index++)
                {
                    if (index > 0)
                        builder.Append(',');
                    AppendJsonValue(builder, values[index]);
                }
                builder.Append(']');
                return;
            }
            if (value is byte
                || value is sbyte
                || value is short
                || value is ushort
                || value is int
                || value is uint
                || value is long
                || value is ulong
                || value is float
                || value is double
                || value is decimal)
            {
                builder.Append(Convert.ToString(value, System.Globalization.CultureInfo.InvariantCulture));
                return;
            }
            throw new InvalidOperationException("The Supervisor response contains an unsupported JSON value.");
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
            string expectedSelectedGenerationId,
            string expectedTargetGenerationId,
            string expectedRuntimeContractSha256,
            string expectedGenerationDisposition,
            string expectedRuntime)
        {
            return ParseStatusResponse(
                responseLine,
                expectedRoot,
                expectedSelectedGenerationId,
                expectedTargetGenerationId,
                expectedRuntimeContractSha256,
                expectedGenerationDisposition,
                expectedRuntime,
                AICodedbControlContract.CreateDefaultIdentity());
        }

        internal static AICodedbSupervisorSnapshot ParseStatusResponse(
            string responseLine,
            string expectedRoot,
            string expectedSelectedGenerationId,
            string expectedTargetGenerationId,
            string expectedRuntimeContractSha256,
            string expectedGenerationDisposition,
            string expectedRuntime,
            AICodedbControlContractIdentity expectedControlContract)
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
            var supervisorSchema = AICodedbStrictJson.GetRequiredInt32(
                status,
                "supervisor_schema_version",
                "CodeDB Supervisor status");
            var responseProtocolVersion = AICodedbStrictJson.GetRequiredInt32(
                status,
                "protocol_version",
                "CodeDB Supervisor status");
            var responseSupervisorProtocol = AICodedbStrictJson.GetRequiredInt32(
                status,
                "supervisor_protocol_version",
                "CodeDB Supervisor status");
            var responseRole = AICodedbStrictJson.GetRequiredString(
                status,
                "role",
                "CodeDB Supervisor status");
            if (responseProtocolVersion != AICodedbSupervisorProtocol.Version
                || responseSupervisorProtocol != AICodedbSupervisorProtocol.SupervisorVersion
                || supervisorSchema != AICodedbSupervisorProtocol.SupervisorStateSchemaVersion)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "PROTOCOL_MISMATCH",
                    "The Supervisor returned an unsupported Bridge protocol.");
            }
            if (!string.Equals(
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

            if (!expectedControlContract.IsValid)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "SUPERVISOR_IDENTITY_MISMATCH",
                    "The Package control contract identity is invalid.");
            }

            var root = AICodedbStrictJson.GetRequiredString(status, "root", "CodeDB Supervisor status");
            var projectIdentity = AICodedbStrictJson.GetRequiredString(
                status,
                "project_identity",
                "CodeDB Supervisor status");
            var generationId = AICodedbStrictJson.GetRequiredString(
                status,
                "generation_id",
                "CodeDB Supervisor status");
            var targetGenerationId = AICodedbStrictJson.GetRequiredString(
                status,
                "target_generation_id",
                "CodeDB Supervisor status");
            var selectedGenerationId = AICodedbStrictJson.GetRequiredString(
                status,
                "selected_generation_id",
                "CodeDB Supervisor status");
            var runtimeContractSha256 = AICodedbStrictJson.GetRequiredString(
                status,
                "runtime_contract_sha256",
                "CodeDB Supervisor status");
            var generationDisposition = AICodedbStrictJson.GetRequiredString(
                status,
                "generation_disposition",
                "CodeDB Supervisor status");
            var runtime = AICodedbStrictJson.GetRequiredString(status, "runtime", "CodeDB Supervisor status");
            var controlContractId = AICodedbStrictJson.GetRequiredString(
                status,
                "control_contract_id",
                "CodeDB Supervisor status");
            var controlContractVersion = AICodedbStrictJson.GetRequiredInt32(
                status,
                "control_contract_version",
                "CodeDB Supervisor status");
            var controlContractSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                status,
                "control_contract_schema_version",
                "CodeDB Supervisor status");
            var controlContractSha256 = AICodedbStrictJson.GetRequiredString(
                status,
                "control_contract_sha256",
                "CodeDB Supervisor status");
            var controlNamespace = AICodedbStrictJson.GetRequiredString(
                status,
                "control_namespace",
                "CodeDB Supervisor status");
            string expectedControlNamespace;
            try
            {
                expectedControlNamespace = AICodedbControlContract.GetSupervisorRuntimePath(
                    expectedRoot,
                    expectedControlContract);
            }
            catch (Exception exception)
            {
                return AICodedbSupervisorSnapshot.Blocked(
                    "SUPERVISOR_IDENTITY_MISMATCH",
                    exception.Message);
            }
            if (!AICodedbSupervisorProtocol.PathsEqual(root, expectedRoot)
                || !string.Equals(
                    projectIdentity,
                    AICodedbEditorLifecycle.CreateProjectIdentity(expectedRoot),
                    StringComparison.Ordinal)
                || !string.Equals(generationId, selectedGenerationId, StringComparison.Ordinal)
                || !string.Equals(selectedGenerationId, expectedSelectedGenerationId, StringComparison.Ordinal)
                || !string.Equals(targetGenerationId, expectedTargetGenerationId, StringComparison.Ordinal)
                || !string.Equals(runtimeContractSha256, expectedRuntimeContractSha256, StringComparison.Ordinal)
                || !string.Equals(generationDisposition, expectedGenerationDisposition, StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(runtime, expectedRuntime)
                || !AICodedbSupervisorProtocol.PathsEqual(expectedRuntime, expectedControlNamespace)
                || !string.Equals(controlContractId, expectedControlContract.Id, StringComparison.Ordinal)
                || controlContractVersion != expectedControlContract.Version
                || controlContractSchemaVersion != expectedControlContract.SchemaVersion
                || !string.Equals(
                    controlContractSha256,
                    expectedControlContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || !AICodedbSupervisorProtocol.PathsEqual(controlNamespace, expectedControlNamespace))
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

            var reportedReadiness = AICodedbStrictJson.GetOptionalNullableString(
                status,
                "readiness_state",
                "CodeDB Supervisor status");
            if (!string.IsNullOrWhiteSpace(reportedReadiness))
            {
                var reportedReason = AICodedbStrictJson.GetOptionalNullableString(
                    status,
                    "reason_code",
                    "CodeDB Supervisor status");
                var reportedDetail = AICodedbStrictJson.GetOptionalNullableString(
                    status,
                    "detail",
                    "CodeDB Supervisor status");
                switch (reportedReadiness)
                {
                    case "core_ready":
                        // Never let the outer state promote a coordinator that
                        // has not independently satisfied the readiness gate.
                        break;
                    case "starting":
                        readiness = AICodedbSupervisorReadinessState.Starting;
                        reasonCode = reportedReason ?? "SUPERVISOR_STARTING";
                        detail = reportedDetail ?? "The project Supervisor is starting.";
                        break;
                    case "maintenance":
                        readiness = AICodedbSupervisorReadinessState.Maintenance;
                        reasonCode = reportedReason ?? "SUPERVISOR_MAINTENANCE";
                        detail = reportedDetail ?? "The project Supervisor is running maintenance.";
                        break;
                    case "degraded":
                        readiness = AICodedbSupervisorReadinessState.Degraded;
                        reasonCode = reportedReason ?? "SUPERVISOR_DEGRADED";
                        detail = reportedDetail ?? "The project Supervisor reported a degraded runtime.";
                        break;
                    case "blocked":
                        readiness = AICodedbSupervisorReadinessState.Blocked;
                        reasonCode = reportedReason ?? "SUPERVISOR_BLOCKED";
                        detail = reportedDetail ?? "The project Supervisor blocked the requested operation.";
                        break;
                    case "stopping":
                        readiness = AICodedbSupervisorReadinessState.Stopping;
                        reasonCode = reportedReason ?? "SUPERVISOR_STOPPING";
                        detail = reportedDetail ?? "The project Supervisor is stopping.";
                        break;
                    case "stopped":
                        readiness = AICodedbSupervisorReadinessState.Stopped;
                        reasonCode = reportedReason ?? "SUPERVISOR_STOPPED";
                        detail = reportedDetail ?? "The project Supervisor is stopped.";
                        break;
                    default:
                        return AICodedbSupervisorSnapshot.Blocked(
                            "INVALID_SUPERVISOR_READINESS",
                            "The Supervisor status contains an unsupported outer readiness state.");
                }
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
                AICodedbStrictJson.GetOptionalNullableString(status, "last_event", "CodeDB Supervisor status"),
                supervisorSchema,
                targetGenerationId,
                selectedGenerationId,
                runtimeContractSha256,
                generationDisposition);
        }
    }
}
