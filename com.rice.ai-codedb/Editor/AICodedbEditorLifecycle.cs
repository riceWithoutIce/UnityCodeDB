using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using UnityEditor;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    [InitializeOnLoad]
    internal static class AICodedbEditorLifecycle
    {
        internal const int LeaseSchemaVersion = 1;
        internal const double HeartbeatIntervalSeconds = 5d;

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

        private static void OnEditorUpdate()
        {
            if (!_initialized || _quitting || EditorApplication.timeSinceStartup < _nextHeartbeatAt)
                return;

            _nextHeartbeatAt = EditorApplication.timeSinceStartup + HeartbeatIntervalSeconds;
            PublishLease();
            if (EditorApplication.timeSinceStartup >= _nextReconcileAt && BackendNeedsReconcile())
                BeginReconcile();
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
            if (_quitting || Interlocked.CompareExchange(ref _reconcileInFlight, 1, 0) != 0)
                return;

            _nextReconcileAt = EditorApplication.timeSinceStartup + ReconcileRetrySeconds;
            try
            {
                var hostResult = await AICodedbHostPayloadMaterializer.ReadStatusAsync();
                if (_quitting)
                    return;

                var hostStatus = AICodedbHostPayloadStatusBuilder.Build(
                    File.Exists(AICodedbPaths.HostPayloadMarkerPath),
                    hostResult);
                if (!hostStatus.IsCurrent)
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
            var desired = ReadJson<DesiredStateDocument>(AICodedbPaths.WatchDesiredStatePath);
            if (desired != null && string.Equals(desired.desired_state, "disabled", StringComparison.Ordinal))
                return false;

            var state = ReadJson<CoordinatorStateDocument>(AICodedbPaths.WatchCoordinatorStatePath);
            if (state == null || state.coordinator_pid <= 0)
                return true;

            try
            {
                using (var process = Process.GetProcessById(state.coordinator_pid))
                    return process.HasExited;
            }
            catch
            {
                return true;
            }
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

        private static T ReadJson<T>(string path) where T : class
        {
            try
            {
                return File.Exists(path) ? JsonUtility.FromJson<T>(File.ReadAllText(path)) : null;
            }
            catch
            {
                return null;
            }
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
        private sealed class EditorLeaseDocument
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
            public string desired_state;
        }

        [Serializable]
        private sealed class CoordinatorStateDocument
        {
            public int coordinator_pid;
        }
    }
}
