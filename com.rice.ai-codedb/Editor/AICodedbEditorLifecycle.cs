using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    [InitializeOnLoad]
    internal static class AICodedbEditorLifecycle
    {
        internal const int LeaseSchemaVersion = 1;
        internal const double HeartbeatIntervalSeconds = 5d;
        internal const int ConcurrentUpgradeStatusReadAttempts = 12;
        internal const int ConcurrentUpgradeRetryDelayMilliseconds = 250;

        private const double ReconcileRetrySeconds = 30d;
        private const string ManagedBy = "com.rice.ai-codedb";
        private const string SessionIdKey = "Rice.AICodedb.EditorLifecycle.SessionId";
        private const string SessionCreatedAtKey = "Rice.AICodedb.EditorLifecycle.CreatedAtUtc";

        private static string _projectRoot;
        private static string _projectIdentity;
        private static string _sessionId;
        private static string _sessionCreatedAtUtc;
        private static string _leasePath;
        private static int _editorPid;
        private static string _processStartTicks;
        private static double _nextHeartbeatAt;
        private static double _nextReconcileAt;
        private static int _reconcileInFlight;
        private static bool _initialized;
        private static bool _quitting;

        static AICodedbEditorLifecycle()
        {
            if (Application.isBatchMode)
                return;

            try
            {
                _projectRoot = ValidateProjectRoot(AICodedbPaths.ProjectRoot);
                _projectIdentity = CreateProjectIdentity(_projectRoot);
                _sessionId = GetOrCreateSessionValue(SessionIdKey, () => Guid.NewGuid().ToString("N"));
                _sessionCreatedAtUtc = GetOrCreateSessionValue(SessionCreatedAtKey, () => DateTime.UtcNow.ToString("o"));
                _leasePath = Path.Combine(AICodedbPaths.WatchEditorLeasesPath, _sessionId + ".json");

                using (var process = Process.GetCurrentProcess())
                {
                    _editorPid = process.Id;
                    _processStartTicks = process.StartTime.ToUniversalTime().Ticks.ToString(CultureInfo.InvariantCulture);
                }

                EditorApplication.update -= OnEditorUpdate;
                EditorApplication.update += OnEditorUpdate;
                EditorApplication.quitting -= OnEditorQuitting;
                EditorApplication.quitting += OnEditorQuitting;
                EditorApplication.delayCall += Initialize;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"CodeDB Editor lifecycle initialization was skipped: {exception.Message}");
            }
        }

        private static void Initialize()
        {
            if (_quitting || string.IsNullOrWhiteSpace(_leasePath))
                return;

            _initialized = true;
            PublishLease();
            _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            BeginReconcile();
        }

        [DidReloadScripts]
        private static void OnScriptsReloaded()
        {
            EditorApplication.delayCall += RequestReconcile;
        }

        private static void OnEditorUpdate()
        {
            if (!_initialized || _quitting || EditorApplication.timeSinceStartup < _nextHeartbeatAt)
                return;

            _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            PublishLease();
            if (ShouldRunScheduledReconcile(
                EditorApplication.timeSinceStartup,
                ref _nextReconcileAt,
                BackendNeedsReconcile))
                BeginReconcile();
        }

        internal static bool ShouldRunScheduledReconcile(
            double now,
            ref double nextReconcileAt,
            Func<bool> backendNeedsReconcile)
        {
            if (now < nextReconcileAt)
                return false;

            nextReconcileAt = now + ReconcileRetrySeconds;
            return backendNeedsReconcile != null && backendNeedsReconcile();
        }

        private static void OnEditorQuitting()
        {
            _quitting = true;
            EditorApplication.update -= OnEditorUpdate;
            try
            {
                if (!string.IsNullOrWhiteSpace(_leasePath))
                    File.Delete(_leasePath);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"CodeDB could not remove its Editor lease during shutdown: {exception.Message}");
            }
        }

        private static async void BeginReconcile()
        {
            if (_quitting)
                return;
            if (ShouldDeferReconcile(EditorApplication.isCompiling, EditorApplication.isUpdating))
            {
                _nextReconcileAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
                return;
            }
            if (Interlocked.CompareExchange(ref _reconcileInFlight, 1, 0) != 0)
                return;

            _nextReconcileAt = EditorApplication.timeSinceStartup + ReconcileRetrySeconds;
            try
            {
                var hostResult = await AICodedbHostPayloadMaterializer.ReadStatusAsync();
                if (_quitting)
                    return;

                var hostStatus = BuildHostPayloadStatus(hostResult);
                if (hostStatus.CanUpgradeAutomatically)
                {
                    var updatePolicy = AICodedbHostUpdatePolicyStore.Read(AICodedbPaths.ProjectRoot);
                    if (!updatePolicy.IsValid)
                    {
                        Debug.LogWarning("CodeDB automatic host update policy is invalid: " + updatePolicy.Detail);
                    }
                    else if (updatePolicy.IsEnabled && !IsAutomaticHostUpgradeSuppressed(
                                 AICodedbHostUpgradeStatusStore.Read(
                                     _projectRoot,
                                     AICodedbProjectSettings.CurrentGenerationId),
                                 AICodedbProjectSettings.CurrentGenerationId))
                    {
                        var upgradeResult = await AICodedbHostPayloadMaterializer.RunUpgradeAsync();
                        if (_quitting)
                            return;
                        hostStatus = await ReadHostStatusAfterUpgradeAsync(
                            upgradeResult,
                            AICodedbHostPayloadMaterializer.ReadStatusAsync,
                            () => File.Exists(AICodedbPaths.HostPayloadMarkerPath),
                            GetCurrentHostGenerationId,
                            milliseconds => Task.Delay(milliseconds),
                            ConcurrentUpgradeStatusReadAttempts);
                        if (_quitting)
                            return;
                        if (!hostStatus.IsCurrent)
                        {
                            if (!IsConcurrentUpgrade(upgradeResult))
                                Debug.LogWarning($"CodeDB automatic host upgrade failed: {upgradeResult.GetSummary()} {upgradeResult.StandardError}".Trim());
                            else
                            {
                                _nextReconcileAt = Math.Min(_nextReconcileAt, EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds);
                                return;
                            }
                        }
                    }
                }
                if (!CanEnsureHostGeneration(hostStatus, AICodedbPaths.HostGeneration.State))
                    return;

                var result = await AICodedbActions.RunEnsureWatcherAsync();
                if (!result.Succeeded && !_quitting)
                    Debug.LogWarning($"CodeDB Editor lifecycle reconcile failed: {result.GetSummary()} {result.StandardError}".Trim());
            }
            catch (Exception exception)
            {
                if (!_quitting)
                    Debug.LogWarning($"CodeDB Editor lifecycle reconcile failed: {exception.Message}");
            }
            finally
            {
                Interlocked.Exchange(ref _reconcileInFlight, 0);
            }
        }

        private static bool BackendNeedsReconcile()
        {
            var generation = AICodedbPaths.HostGeneration;
            if (ShouldReconcileAutomaticHostUpgrade(
                    File.Exists(AICodedbPaths.HostPayloadMarkerPath),
                    File.Exists(AICodedbPaths.HostCurrentPointerPath),
                    generation.State,
                    AICodedbHostUpdatePolicyStore.Read(AICodedbPaths.ProjectRoot),
                    AICodedbHostUpgradeStatusStore.Read(
                        _projectRoot,
                        AICodedbProjectSettings.CurrentGenerationId),
                    AICodedbProjectSettings.CurrentGenerationId))
            {
                return true;
            }

            var manual = ReadManualRuntime(AICodedbPaths.WatchManualRuntimePath);
            var manualMode = GetApplicableManualMode(
                manual,
                GetActiveEditorSessionIds(),
                _projectRoot,
                _projectIdentity);
            if (string.Equals(manualMode, "stopped", StringComparison.Ordinal))
                return false;

            var desired = ReadDesiredState(
                AICodedbPaths.WatchDesiredStatePath,
                _projectRoot,
                _projectIdentity);
            if (desired != null
                && string.Equals(desired.desired_state, "disabled", StringComparison.Ordinal)
                && !string.Equals(manualMode, "started", StringComparison.Ordinal))
                return false;

            var state = ReadCoordinatorState(AICodedbPaths.WatchCoordinatorStatePath, _projectRoot);
            return ShouldReconcileCoordinator(
                File.Exists(AICodedbPaths.HostCurrentPointerPath),
                generation.State,
                generation.GenerationId,
                state == null ? 0 : state.coordinator_pid,
                state == null ? string.Empty : state.generation_id,
                IsProcessAlive);
        }

        internal static bool ShouldReconcileCoordinator(
            bool currentPointerExists,
            AICodedbHostGenerationState generationState,
            string selectedGenerationId,
            int coordinatorPid,
            string coordinatorGenerationId,
            Func<int, bool> processAliveProvider)
        {
            if (currentPointerExists
                && generationState != AICodedbHostGenerationState.Current
                && generationState != AICodedbHostGenerationState.Previous
                && generationState != AICodedbHostGenerationState.DowngradeReviewRequired)
                return true;
            if (coordinatorPid <= 0)
                return true;
            if ((generationState == AICodedbHostGenerationState.Current
                 || generationState == AICodedbHostGenerationState.Previous
                 || generationState == AICodedbHostGenerationState.DowngradeReviewRequired)
                && !string.Equals(coordinatorGenerationId, selectedGenerationId, StringComparison.Ordinal))
                return true;
            if (processAliveProvider == null)
                return true;
            return !processAliveProvider(coordinatorPid);
        }

        internal static bool CanEnsureHostGeneration(
            AICodedbHostPayloadStatus hostStatus,
            AICodedbHostGenerationState generationState)
        {
            return hostStatus.IsCurrent
                   || generationState == AICodedbHostGenerationState.Legacy;
        }

        internal static bool ShouldDeferReconcile(bool isCompiling, bool isUpdating)
        {
            return isCompiling || isUpdating;
        }

        internal static bool ShouldReconcileAutomaticHostUpgrade(
            bool markerExists,
            bool currentPointerExists,
            AICodedbHostGenerationState generationState,
            AICodedbHostUpdatePolicy updatePolicy,
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            if (!updatePolicy.IsValid || !updatePolicy.IsEnabled)
                return false;
            if (generationState == AICodedbHostGenerationState.DowngradeReviewRequired)
                return false;
            if (IsAutomaticHostUpgradeSuppressed(upgradeStatus, currentGenerationId))
                return false;
            if (!markerExists)
            {
                return !currentPointerExists
                       && generationState == AICodedbHostGenerationState.Unavailable;
            }
            if (generationState == AICodedbHostGenerationState.Legacy)
                return true;
            return generationState != AICodedbHostGenerationState.Current;
        }

        internal static bool IsAutomaticHostUpgradeSuppressed(
            AICodedbHostUpgradeStatus upgradeStatus,
            string currentGenerationId)
        {
            return upgradeStatus.Phase == AICodedbHostUpgradePhase.CheckFailed
                   && !string.IsNullOrWhiteSpace(currentGenerationId)
                   && string.Equals(
                       upgradeStatus.GenerationId,
                       currentGenerationId,
                       StringComparison.Ordinal);
        }

        private static bool IsProcessAlive(int processId)
        {
            try
            {
                using (var process = Process.GetProcessById(processId))
                    return !process.HasExited;
            }
            catch
            {
                return false;
            }
        }

        internal static void RequestReconcile()
        {
            _nextReconcileAt = 0d;
            if (_initialized && !_quitting)
                BeginReconcile();
        }

        internal static string GetApplicableManualMode(
            ManualRuntimeDocument manual,
            string[] activeEditorSessionIds,
            string projectRoot,
            string projectIdentity)
        {
            string manualRoot;
            string expectedRoot;
            if (manual == null
                || manual.schema_version != LeaseSchemaVersion
                || !string.Equals(manual.managed_by, ManagedBy, StringComparison.Ordinal)
                || !TryNormalizeRoot(manual.project_root, out manualRoot)
                || !TryNormalizeRoot(projectRoot, out expectedRoot)
                || !string.Equals(manualRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrWhiteSpace(projectIdentity)
                || !string.Equals(manual.project_identity, projectIdentity, StringComparison.Ordinal)
                || activeEditorSessionIds == null
                || manual.editor_session_ids == null
                || manual.editor_session_ids.Length == 0
                || (manual.mode != "started" && manual.mode != "stopped"))
                return "none";

            foreach (var sessionId in manual.editor_session_ids)
            {
                if (!IsValidSessionId(sessionId))
                    return "none";
            }

            foreach (var sessionId in manual.editor_session_ids)
            {
                foreach (var activeSessionId in activeEditorSessionIds)
                {
                    if (string.Equals(sessionId, activeSessionId, StringComparison.Ordinal))
                        return manual.mode;
                }
            }
            return "none";
        }

        private static string[] GetActiveEditorSessionIds()
        {
            var sessions = new HashSet<string>(StringComparer.Ordinal);
            try
            {
                if (!Directory.Exists(AICodedbPaths.WatchEditorLeasesPath))
                    return new string[0];

                var now = DateTime.UtcNow;
                foreach (var path in Directory.GetFiles(AICodedbPaths.WatchEditorLeasesPath, "*.json"))
                {
                    var lease = ReadEditorLease(path);
                    if (IsActiveEditorLease(
                            lease,
                            path,
                            _projectRoot,
                            _projectIdentity,
                            now,
                            GetProcessStartTicks))
                        sessions.Add(lease.session_id);
                }
            }
            catch
            {
                // The PowerShell coordinator remains authoritative for lease cleanup.
            }
            var result = new string[sessions.Count];
            sessions.CopyTo(result);
            return result;
        }

        internal static bool IsActiveEditorLease(
            EditorLeaseDocument lease,
            string leasePath,
            string projectRoot,
            string projectIdentity,
            DateTime nowUtc,
            Func<int, string> processStartTicksProvider)
        {
            try
            {
                DateTime createdAt;
                DateTime heartbeatAt;
                string leaseRoot;
                string expectedRoot;
                if (lease == null
                    || lease.schema_version != LeaseSchemaVersion
                    || !string.Equals(lease.managed_by, ManagedBy, StringComparison.Ordinal)
                    || !IsValidSessionId(lease.session_id)
                    || !string.Equals(Path.GetFileName(leasePath), lease.session_id + ".json", StringComparison.Ordinal)
                    || lease.editor_pid <= 0
                    || !IsUnsignedInteger(lease.process_start_ticks)
                    || !TryNormalizeRoot(lease.project_root, out leaseRoot)
                    || !TryNormalizeRoot(projectRoot, out expectedRoot)
                    || !string.Equals(leaseRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                    || string.IsNullOrWhiteSpace(projectIdentity)
                    || !string.Equals(lease.project_identity, projectIdentity, StringComparison.Ordinal)
                    || !DateTime.TryParse(lease.created_at_utc, null, DateTimeStyles.RoundtripKind, out createdAt)
                    || !DateTime.TryParse(lease.heartbeat_at_utc, null, DateTimeStyles.RoundtripKind, out heartbeatAt))
                    return false;

                var createdUtc = createdAt.ToUniversalTime();
                var heartbeatUtc = heartbeatAt.ToUniversalTime();
                var now = nowUtc.ToUniversalTime();
                if (createdUtc > heartbeatUtc
                    || heartbeatUtc < now.AddSeconds(-90)
                    || heartbeatUtc > now.AddSeconds(30)
                    || processStartTicksProvider == null)
                    return false;

                var actualStartTicks = processStartTicksProvider(lease.editor_pid);
                return string.Equals(actualStartTicks, lease.process_start_ticks, StringComparison.Ordinal);
            }
            catch
            {
                return false;
            }
        }

        internal static async Task<AICodedbHostPayloadStatus> ReadHostStatusAfterUpgradeAsync(
            AICodedbCommandResult upgradeResult,
            Func<Task<AICodedbCommandResult>> readStatusAsync,
            Func<bool> markerExists,
            Func<string> currentGenerationId,
            Func<int, Task> delayAsync,
            int concurrentReadAttempts)
        {
            if (readStatusAsync == null)
                throw new ArgumentNullException(nameof(readStatusAsync));
            if (markerExists == null)
                throw new ArgumentNullException(nameof(markerExists));
            if (currentGenerationId == null)
                throw new ArgumentNullException(nameof(currentGenerationId));
            if (delayAsync == null)
                throw new ArgumentNullException(nameof(delayAsync));
            if (concurrentReadAttempts <= 0)
                throw new ArgumentOutOfRangeException(nameof(concurrentReadAttempts));

            var attempts = IsConcurrentUpgrade(upgradeResult) ? concurrentReadAttempts : 1;
            AICodedbHostPayloadStatus status = default(AICodedbHostPayloadStatus);
            for (var attempt = 0; attempt < attempts; attempt++)
            {
                var result = await readStatusAsync();
                status = AICodedbHostPayloadStatusBuilder.Build(
                    markerExists(),
                    result,
                    currentGenerationId());
                if (status.IsCurrent || attempt + 1 >= attempts)
                    return status;
                await delayAsync(ConcurrentUpgradeRetryDelayMilliseconds);
            }
            return status;
        }

        internal static bool IsConcurrentUpgrade(AICodedbCommandResult result)
        {
            if (result == null || result.ExitCode != 4 || result.TimedOut)
                return false;
            var combined = (result.StandardOutput ?? string.Empty) + "\n" + (result.StandardError ?? string.Empty);
            return combined.IndexOf("Another payload materialization is active", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static AICodedbHostPayloadStatus BuildHostPayloadStatus(AICodedbCommandResult result)
        {
            return AICodedbHostPayloadStatusBuilder.Build(
                File.Exists(AICodedbPaths.HostPayloadMarkerPath),
                result,
                GetCurrentHostGenerationId());
        }

        private static string GetCurrentHostGenerationId()
        {
            var generation = AICodedbPaths.HostGeneration;
            return generation.State == AICodedbHostGenerationState.Current
                ? generation.GenerationId
                : string.Empty;
        }

        private static string GetProcessStartTicks(int processId)
        {
            try
            {
                using (var process = Process.GetProcessById(processId))
                {
                    if (process.HasExited)
                        return string.Empty;
                    return process.StartTime.ToUniversalTime().Ticks.ToString(CultureInfo.InvariantCulture);
                }
            }
            catch
            {
                return string.Empty;
            }
        }

        private static bool TryNormalizeRoot(string path, out string normalized)
        {
            normalized = string.Empty;
            try
            {
                normalized = AICodedbPaths.NormalizePath(path).TrimEnd('/');
                return !string.IsNullOrWhiteSpace(normalized);
            }
            catch
            {
                return false;
            }
        }

        private static bool IsValidSessionId(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 128)
                return false;
            foreach (var character in value)
            {
                if ((character < 'A' || character > 'Z')
                    && (character < 'a' || character > 'z')
                    && (character < '0' || character > '9')
                    && character != '.'
                    && character != '_'
                    && character != '-')
                    return false;
            }
            return true;
        }

        private static bool IsUnsignedInteger(string value)
        {
            if (string.IsNullOrEmpty(value))
                return false;
            foreach (var character in value)
            {
                if (character < '0' || character > '9')
                    return false;
            }
            return true;
        }

        private static void PublishLease()
        {
            try
            {
                Directory.CreateDirectory(AICodedbPaths.WatchEditorLeasesPath);
                var document = new EditorLeaseDocument
                {
                    schema_version = LeaseSchemaVersion,
                    managed_by = ManagedBy,
                    session_id = _sessionId,
                    editor_pid = _editorPid,
                    process_start_ticks = _processStartTicks,
                    project_root = _projectRoot,
                    project_identity = _projectIdentity,
                    created_at_utc = _sessionCreatedAtUtc,
                    heartbeat_at_utc = DateTime.UtcNow.ToString("o")
                };
                WriteJsonAtomic(_leasePath, JsonUtility.ToJson(document, true) + "\n");
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"CodeDB Editor lease heartbeat failed: {exception.Message}");
            }
        }

        internal static string ValidateProjectRoot(string projectRoot)
        {
            var root = AICodedbPaths.NormalizePath(projectRoot).TrimEnd('/');
            if (string.IsNullOrWhiteSpace(root) || !Directory.Exists(root))
                throw new InvalidOperationException("Unity project root does not exist.");

            foreach (var marker in new[] { "Assets", "Packages", "ProjectSettings" })
            {
                if (!Directory.Exists(Path.Combine(root, marker)))
                    throw new InvalidOperationException($"Unity project root is missing {marker}.");
            }

            return root;
        }

        internal static string CreateProjectIdentity(string projectRoot)
        {
            var canonical = ValidateProjectRoot(projectRoot).ToLowerInvariant();
            using (var sha256 = SHA256.Create())
            {
                var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(canonical));
                var builder = new StringBuilder(hash.Length * 2);
                foreach (var value in hash)
                    builder.Append(value.ToString("x2", CultureInfo.InvariantCulture));
                return "sha256:" + builder;
            }
        }

        private static string GetOrCreateSessionValue(string key, Func<string> factory)
        {
            var value = SessionState.GetString(key, string.Empty);
            if (!string.IsNullOrWhiteSpace(value))
                return value;

            value = factory();
            SessionState.SetString(key, value);
            return value;
        }

        internal static EditorLeaseDocument ReadEditorLease(string path)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB Editor lease");
                if (value == null)
                    return null;
                return new EditorLeaseDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB Editor lease"),
                    managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "CodeDB Editor lease"),
                    session_id = AICodedbStrictJson.GetRequiredString(value, "session_id", "CodeDB Editor lease"),
                    editor_pid = AICodedbStrictJson.GetRequiredInt32(value, "editor_pid", "CodeDB Editor lease"),
                    process_start_ticks = AICodedbStrictJson.GetRequiredString(value, "process_start_ticks", "CodeDB Editor lease"),
                    project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "CodeDB Editor lease"),
                    project_identity = AICodedbStrictJson.GetRequiredString(value, "project_identity", "CodeDB Editor lease"),
                    created_at_utc = AICodedbStrictJson.GetRequiredString(value, "created_at_utc", "CodeDB Editor lease"),
                    heartbeat_at_utc = AICodedbStrictJson.GetRequiredString(value, "heartbeat_at_utc", "CodeDB Editor lease")
                };
            }
            catch
            {
                return null;
            }
        }

        private static ManualRuntimeDocument ReadManualRuntime(string path)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB manual runtime state");
                if (value == null)
                    return null;
                return new ManualRuntimeDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB manual runtime state"),
                    managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "CodeDB manual runtime state"),
                    mode = AICodedbStrictJson.GetRequiredString(value, "mode", "CodeDB manual runtime state"),
                    project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "CodeDB manual runtime state"),
                    project_identity = AICodedbStrictJson.GetRequiredString(value, "project_identity", "CodeDB manual runtime state"),
                    editor_session_ids = AICodedbStrictJson.GetRequiredStringArray(
                        value,
                        "editor_session_ids",
                        "CodeDB manual runtime state")
                };
            }
            catch
            {
                return null;
            }
        }

        private static DesiredStateDocument ReadDesiredState(
            string path,
            string expectedProjectRoot,
            string expectedProjectIdentity)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB desired state");
                if (value == null)
                    return null;
                var document = new DesiredStateDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB desired state"),
                    managed_by = AICodedbStrictJson.GetRequiredString(value, "managed_by", "CodeDB desired state"),
                    desired_state = AICodedbStrictJson.GetRequiredString(value, "desired_state", "CodeDB desired state"),
                    project_root = AICodedbStrictJson.GetRequiredString(value, "project_root", "CodeDB desired state"),
                    project_identity = AICodedbStrictJson.GetRequiredString(value, "project_identity", "CodeDB desired state")
                };
                string actualRoot;
                string expectedRoot;
                if (document.schema_version != LeaseSchemaVersion
                    || !string.Equals(document.managed_by, ManagedBy, StringComparison.Ordinal)
                    || (document.desired_state != "enabled" && document.desired_state != "disabled")
                    || !TryNormalizeRoot(document.project_root, out actualRoot)
                    || !TryNormalizeRoot(expectedProjectRoot, out expectedRoot)
                    || !string.Equals(actualRoot, expectedRoot, StringComparison.OrdinalIgnoreCase)
                    || string.IsNullOrWhiteSpace(expectedProjectIdentity)
                    || !string.Equals(
                        document.project_identity,
                        expectedProjectIdentity,
                        StringComparison.Ordinal))
                    return null;
                return document;
            }
            catch
            {
                return null;
            }
        }

        private static CoordinatorStateDocument ReadCoordinatorState(string path, string expectedProjectRoot)
        {
            try
            {
                var value = ReadEvidenceObject(path, "CodeDB coordinator state");
                if (value == null)
                    return null;
                var document = new CoordinatorStateDocument
                {
                    schema_version = AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "CodeDB coordinator state"),
                    coordinator_pid = AICodedbStrictJson.GetRequiredInt32(value, "coordinator_pid", "CodeDB coordinator state"),
                    generation_id = AICodedbStrictJson.GetRequiredString(value, "generation_id", "CodeDB coordinator state"),
                    root = AICodedbStrictJson.GetRequiredString(value, "root", "CodeDB coordinator state")
                };
                string actualRoot;
                string expectedRoot;
                if (document.schema_version != 2
                    || document.coordinator_pid <= 0
                    || !TryNormalizeRoot(document.root, out actualRoot)
                    || !TryNormalizeRoot(expectedProjectRoot, out expectedRoot)
                    || !string.Equals(actualRoot, expectedRoot, StringComparison.OrdinalIgnoreCase))
                    return null;
                return document;
            }
            catch
            {
                return null;
            }
        }

        private static Dictionary<string, object> ReadEvidenceObject(string path, string label)
        {
            if (!File.Exists(path))
                return null;
            if ((File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0)
                throw new InvalidOperationException(label + " cannot be a reparse point.");
            return AICodedbStrictJson.ReadObject(path, 64 * 1024, label);
        }

        private static void WriteJsonAtomic(string targetPath, string content)
        {
            var directory = Path.GetDirectoryName(targetPath);
            if (string.IsNullOrWhiteSpace(directory))
                throw new InvalidOperationException("CodeDB lease path has no parent directory.");

            Directory.CreateDirectory(directory);
            var temporaryPath = Path.Combine(directory, "." + Path.GetFileName(targetPath) + "." + Guid.NewGuid().ToString("N") + ".tmp");
            var backupPath = Path.Combine(directory, "." + Path.GetFileName(targetPath) + "." + Guid.NewGuid().ToString("N") + ".bak");
            try
            {
                using (var stream = new FileStream(temporaryPath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                using (var writer = new StreamWriter(stream, new UTF8Encoding(false)))
                {
                    writer.Write(content);
                    writer.Flush();
                    stream.Flush(true);
                }

                if (File.Exists(targetPath))
                {
                    File.Replace(temporaryPath, targetPath, backupPath);
                    File.Delete(backupPath);
                }
                else
                    File.Move(temporaryPath, targetPath);
            }
            finally
            {
                if (File.Exists(temporaryPath))
                    File.Delete(temporaryPath);
                if (File.Exists(backupPath))
                    File.Delete(backupPath);
            }
        }

        [Serializable]
        internal sealed class EditorLeaseDocument
        {
            public int schema_version;
            public string managed_by;
            public string session_id;
            public int editor_pid;
            public string process_start_ticks;
            public string project_root;
            public string project_identity;
            public string created_at_utc;
            public string heartbeat_at_utc;
        }

        [Serializable]
        private sealed class DesiredStateDocument
        {
            public int schema_version;
            public string managed_by;
            public string desired_state;
            public string project_root;
            public string project_identity;
        }

        [Serializable]
        internal sealed class ManualRuntimeDocument
        {
            public int schema_version;
            public string managed_by;
            public string mode;
            public string project_root;
            public string project_identity;
            public string[] editor_session_ids;
        }

        [Serializable]
        private sealed class CoordinatorStateDocument
        {
            public int schema_version;
            public int coordinator_pid;
            public string generation_id;
            public string root;
        }
    }
}
