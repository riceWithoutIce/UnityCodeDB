using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Threading.Tasks;
using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbEditorLifecycleTests
    {
        private string _projectRoot;

        [SetUp]
        public void SetUp()
        {
            _projectRoot = Path.Combine(
                Path.GetTempPath(),
                "Rice-AICodedb-Lifecycle-Tests",
                Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Assets"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Packages"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "ProjectSettings"));
        }

        [TearDown]
        public void TearDown()
        {
            if (Directory.Exists(_projectRoot))
                Directory.Delete(_projectRoot, true);
        }

        [Test]
        public void ValidateProjectRoot_AcceptsOnlyUnityProjectMarkers()
        {
            var validated = AICodedbEditorLifecycle.ValidateProjectRoot(_projectRoot);
            Assert.That(validated, Is.EqualTo(AICodedbPaths.NormalizePath(_projectRoot).TrimEnd('/')));

            Directory.Delete(Path.Combine(_projectRoot, "ProjectSettings"));
            var exception = Assert.Throws<InvalidOperationException>(
                () => AICodedbEditorLifecycle.ValidateProjectRoot(_projectRoot));
            Assert.That(exception.Message, Does.Contain("ProjectSettings"));
        }

        [Test]
        public void HostGenerationStore_ResolvesValidCurrentGeneration()
        {
            InstallCurrentGeneration();

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Current));
            Assert.That(selection.GenerationId, Is.EqualTo(AICodedbProjectSettings.CurrentGenerationId));
            Assert.That(selection.PayloadSequence, Is.EqualTo(AICodedbProjectSettings.CurrentPayloadSequence));
            Assert.That(selection.BootstrapProtocol, Is.EqualTo(AICodedbProjectSettings.CurrentBootstrapProtocol));
            Assert.That(selection.RootPath, Does.EndWith("/host/generations/" + AICodedbProjectSettings.CurrentGenerationId));
        }

        [Test]
        public void HostGenerationStore_FailsClosedAfterSelectedFileDrifts()
        {
            var generationFile = InstallCurrentGeneration();
            File.AppendAllText(generationFile, "drift");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.Detail, Does.Contain("drifted"));
        }

        [Test]
        public void HostGenerationStore_ResolvesRecognizedLegacyPayloadWithoutCurrentPointer()
        {
            var legacyFile = Path.Combine(_projectRoot, "AIWork", "codedb", "scripts", "fixture.ps1");
            Directory.CreateDirectory(Path.GetDirectoryName(legacyFile));
            File.WriteAllText(legacyFile, "legacy");
            var markerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostPayloadMarkerRelativePath);
            File.WriteAllText(
                markerPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + AICodedbProjectSettings.LegacyPackageVersion + "\","
                + "\"payload_version\":\"" + AICodedbProjectSettings.LegacyPayloadVersion + "\","
                + "\"payload_sequence\":" + AICodedbProjectSettings.LegacyPayloadSequence + ","
                + "\"host_use_gate_version\":1,\"files\":[{"
                + "\"path\":\"AIWork/codedb/scripts/fixture.ps1\","
                + "\"installed_sha256\":\"" + GetSha256(legacyFile) + "\"}]}");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Legacy));
            Assert.That(selection.PackageVersion, Is.EqualTo(AICodedbProjectSettings.LegacyPackageVersion));
            Assert.That(selection.GenerationId, Is.EqualTo(AICodedbProjectSettings.LegacyPayloadVersion));
        }

        [Test]
        public void CreateProjectIdentity_IsCanonicalAndStable()
        {
            var identity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            var equivalentPath = Path.Combine(_projectRoot, ".");

            Assert.That(identity, Does.Match("^sha256:[0-9a-f]{64}$"));
            Assert.That(AICodedbEditorLifecycle.CreateProjectIdentity(equivalentPath), Is.EqualTo(identity));
        }

        [Test]
        public void GetApplicableManualMode_AppliesWhenAnyRecordedSessionIsActive()
        {
            var manual = CreateManualRuntime("stopped", "closed-session", "active-session");

            var mode = AICodedbEditorLifecycle.GetApplicableManualMode(
                manual,
                new[] { "other-session", "active-session" },
                _projectRoot,
                AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot));

            Assert.That(mode, Is.EqualTo("stopped"));
        }

        [Test]
        public void GetApplicableManualMode_ReturnsNoneWithoutActiveSessionIntersection()
        {
            var manual = CreateManualRuntime("started", "closed-session");

            var mode = AICodedbEditorLifecycle.GetApplicableManualMode(
                manual,
                new[] { "other-session" },
                _projectRoot,
                AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot));

            Assert.That(mode, Is.EqualTo("none"));
        }

        [Test]
        public void GetApplicableManualMode_FailsClosedForMalformedOrMismatchedDocuments()
        {
            var identity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            var active = new[] { "active-session" };
            var manual = CreateManualRuntime("started", "active-session");

            manual.schema_version = 2;
            Assert.That(AICodedbEditorLifecycle.GetApplicableManualMode(manual, active, _projectRoot, identity), Is.EqualTo("none"));

            manual.schema_version = 1;
            manual.project_root = Path.Combine(_projectRoot, "other");
            Assert.That(AICodedbEditorLifecycle.GetApplicableManualMode(manual, active, _projectRoot, identity), Is.EqualTo("none"));

            manual.project_root = "\0";
            Assert.DoesNotThrow(() => AICodedbEditorLifecycle.GetApplicableManualMode(manual, active, _projectRoot, identity));
            Assert.That(AICodedbEditorLifecycle.GetApplicableManualMode(manual, active, _projectRoot, identity), Is.EqualTo("none"));

            manual.project_root = _projectRoot;
            manual.project_identity = "sha256:wrong";
            Assert.That(AICodedbEditorLifecycle.GetApplicableManualMode(manual, active, _projectRoot, identity), Is.EqualTo("none"));

            manual.project_identity = identity;
            manual.editor_session_ids = new[] { "active-session", "invalid session" };
            Assert.That(AICodedbEditorLifecycle.GetApplicableManualMode(manual, active, _projectRoot, identity), Is.EqualTo("none"));
        }

        [Test]
        public void IsActiveEditorLease_ValidatesSessionProcessAndHeartbeatIdentity()
        {
            var now = new DateTime(2026, 7, 29, 8, 0, 0, DateTimeKind.Utc);
            var identity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            var lease = new AICodedbEditorLifecycle.EditorLeaseDocument
            {
                schema_version = AICodedbEditorLifecycle.LeaseSchemaVersion,
                managed_by = "com.rice.ai-codedb",
                session_id = "session-1",
                editor_pid = 4321,
                process_start_ticks = "638893440000000000",
                project_root = _projectRoot,
                project_identity = identity,
                created_at_utc = now.AddMinutes(-1).ToString("o"),
                heartbeat_at_utc = now.ToString("o")
            };
            var leasePath = Path.Combine(_projectRoot, "session-1.json");

            Assert.That(AICodedbEditorLifecycle.IsActiveEditorLease(
                lease,
                leasePath,
                _projectRoot,
                identity,
                now,
                _ => lease.process_start_ticks), Is.True);

            Assert.That(AICodedbEditorLifecycle.IsActiveEditorLease(
                lease,
                leasePath,
                _projectRoot,
                identity,
                now,
                _ => "638893440000000001"), Is.False);

            lease.heartbeat_at_utc = now.AddSeconds(-91).ToString("o");
            Assert.That(AICodedbEditorLifecycle.IsActiveEditorLease(
                lease,
                leasePath,
                _projectRoot,
                identity,
                now,
                _ => lease.process_start_ticks), Is.False);
        }

        [Test]
        public void ReadHostStatusAfterUpgradeAsync_ConcurrentExitFourWaitsUntilCurrent()
        {
            var results = new Queue<AICodedbCommandResult>(new[]
            {
                Result("[UPGRADE_READY] Another Editor is upgrading the host payload."),
                Result("[OK] Host payload is current.")
            });
            var delayCount = 0;

            var status = AICodedbEditorLifecycle.ReadHostStatusAfterUpgradeAsync(
                ConcurrentUpgradeResult(),
                () => Task.FromResult(results.Dequeue()),
                () => true,
                () => "poc.22",
                _ =>
                {
                    delayCount++;
                    return Task.CompletedTask;
                },
                4).GetAwaiter().GetResult();

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.Current));
            Assert.That(results.Count, Is.Zero);
            Assert.That(delayCount, Is.EqualTo(1));
        }

        [Test]
        public void ReadHostStatusAfterUpgradeAsync_ConcurrentExitFourHasBoundedRetries()
        {
            var readCount = 0;
            var delayCount = 0;

            var status = AICodedbEditorLifecycle.ReadHostStatusAfterUpgradeAsync(
                ConcurrentUpgradeResult(),
                () =>
                {
                    readCount++;
                    return Task.FromResult(Result("[UPGRADE_READY] Another Editor is upgrading the host payload."));
                },
                () => true,
                () => "poc.22",
                _ =>
                {
                    delayCount++;
                    return Task.CompletedTask;
                },
                3).GetAwaiter().GetResult();

            Assert.That(status.State, Is.EqualTo(AICodedbHostPayloadState.UpgradeReady));
            Assert.That(readCount, Is.EqualTo(3));
            Assert.That(delayCount, Is.EqualTo(2));
        }

        [Test]
        public void HostUpdatePolicyRead_MalformedRootReturnsInvalidInsteadOfThrowing()
        {
            AICodedbHostUpdatePolicy policy = default(AICodedbHostUpdatePolicy);
            Assert.DoesNotThrow(() => policy = AICodedbHostUpdatePolicyStore.Read("\0"));
            Assert.That(policy.IsValid, Is.False);
        }

        [Test]
        public void HostUpdatePolicyStore_RoundTripsExplicitSetting()
        {
            AICodedbHostUpdatePolicyStore.SetEnabled(_projectRoot, false);
            var disabled = AICodedbHostUpdatePolicyStore.Read(_projectRoot);
            Assert.That(disabled.IsValid, Is.True);
            Assert.That(disabled.IsEnabled, Is.False);
            Assert.That(disabled.IsDefault, Is.False);

            AICodedbHostUpdatePolicyStore.SetEnabled(_projectRoot, true);
            var enabled = AICodedbHostUpdatePolicyStore.Read(_projectRoot);
            Assert.That(enabled.IsValid, Is.True);
            Assert.That(enabled.IsEnabled, Is.True);
            Assert.That(enabled.IsDefault, Is.False);
        }

        [Test]
        public void HostUpdatePolicyStore_RejectsIncompleteDocument()
        {
            var policyPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostUpdatePolicyRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(policyPath));
            File.WriteAllText(
                policyPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"project_root\":\"" + _projectRoot.Replace("\\", "\\\\") + "\","
                + "\"automatic_updates\":false}");

            var policy = AICodedbHostUpdatePolicyStore.Read(_projectRoot);

            Assert.That(policy.IsValid, Is.False);
        }

        [Test]
        public void ShouldReconcileCoordinator_OldGenerationPointerWinsOverLiveCoordinator()
        {
            var processProbeCount = 0;

            var shouldReconcile = AICodedbEditorLifecycle.ShouldReconcileCoordinator(
                true,
                AICodedbHostGenerationState.Invalid,
                string.Empty,
                4321,
                "poc.21",
                _ =>
                {
                    processProbeCount++;
                    return true;
                });

            Assert.That(shouldReconcile, Is.True);
            Assert.That(processProbeCount, Is.Zero);
        }

        [Test]
        public void ShouldReconcileCoordinator_PreservesUnconfiguredLegacyAndCurrentBehavior()
        {
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileCoordinator(
                false,
                AICodedbHostGenerationState.Unavailable,
                string.Empty,
                4321,
                string.Empty,
                _ => true), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileCoordinator(
                false,
                AICodedbHostGenerationState.Legacy,
                "poc.21",
                4321,
                string.Empty,
                _ => true), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileCoordinator(
                true,
                AICodedbHostGenerationState.Current,
                "poc.22",
                4321,
                "poc.22",
                _ => true), Is.False);
        }

        [Test]
        public void ShouldRunScheduledReconcile_AdvancesDeadlineWhenBackendIsHealthy()
        {
            var nextReconcileAt = 10d;
            var probeCount = 0;

            Assert.That(AICodedbEditorLifecycle.ShouldRunScheduledReconcile(
                10d,
                ref nextReconcileAt,
                () =>
                {
                    probeCount++;
                    return false;
                }), Is.False);
            Assert.That(nextReconcileAt, Is.EqualTo(40d));
            Assert.That(probeCount, Is.EqualTo(1));

            Assert.That(AICodedbEditorLifecycle.ShouldRunScheduledReconcile(
                15d,
                ref nextReconcileAt,
                () =>
                {
                    probeCount++;
                    return true;
                }), Is.False);
            Assert.That(nextReconcileAt, Is.EqualTo(40d));
            Assert.That(probeCount, Is.EqualTo(1));
        }

        [Test]
        public void CanEnsureHostGeneration_KeepsLegacyRuntimeIndependentFromUpgradePolicy()
        {
            var upgradeReady = new AICodedbHostPayloadStatus(
                AICodedbHostPayloadState.UpgradeReady,
                AICodedbStatusState.Warning,
                "UPGRADE_READY",
                string.Empty);

            Assert.That(AICodedbEditorLifecycle.CanEnsureHostGeneration(
                upgradeReady,
                AICodedbHostGenerationState.Legacy), Is.True);
            Assert.That(AICodedbEditorLifecycle.CanEnsureHostGeneration(
                upgradeReady,
                AICodedbHostGenerationState.Invalid), Is.False);
        }

        [Test]
        public void IsAutomaticHostUpgradeSuppressed_OnlyBlocksTheFailedCurrentGeneration()
        {
            var failedCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.23",
                "CHECK_FAILED / poc.23",
                "fixture failure");
            var failedPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.22",
                "CHECK_FAILED / poc.22",
                "fixture failure");
            var switchingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Switching,
                AICodedbStatusState.Warning,
                "poc.23",
                "SWITCHING / poc.23",
                string.Empty);

            Assert.That(AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                failedCurrent,
                "poc.23"), Is.True);
            Assert.That(AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                failedPrevious,
                "poc.23"), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                switchingCurrent,
                "poc.23"), Is.False);
        }

        private AICodedbEditorLifecycle.ManualRuntimeDocument CreateManualRuntime(string mode, params string[] sessionIds)
        {
            return new AICodedbEditorLifecycle.ManualRuntimeDocument
            {
                schema_version = AICodedbEditorLifecycle.LeaseSchemaVersion,
                managed_by = "com.rice.ai-codedb",
                mode = mode,
                project_root = _projectRoot,
                project_identity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot),
                editor_session_ids = sessionIds
            };
        }

        private static AICodedbCommandResult ConcurrentUpgradeResult()
        {
            return new AICodedbCommandResult(
                4,
                string.Empty,
                "Another payload materialization is active for this Unity project.",
                false);
        }

        private static AICodedbCommandResult Result(string output)
        {
            return new AICodedbCommandResult(0, output, string.Empty, false);
        }

        private string InstallCurrentGeneration()
        {
            var generationRoot = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                AICodedbProjectSettings.CurrentGenerationId);
            var generationFile = Path.Combine(generationRoot, "scripts", "fixture.ps1");
            Directory.CreateDirectory(Path.GetDirectoryName(generationFile));
            File.WriteAllText(generationFile, "current");

            var manifestPath = Path.Combine(generationRoot, "generation-manifest.json");
            File.WriteAllText(
                manifestPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"generation_id\":\"" + AICodedbProjectSettings.CurrentGenerationId + "\","
                + "\"package_version\":\"" + AICodedbProjectSettings.CurrentPackageVersion + "\","
                + "\"payload_version\":\"" + AICodedbProjectSettings.CurrentPayloadVersion + "\","
                + "\"payload_sequence\":" + AICodedbProjectSettings.CurrentPayloadSequence + ","
                + "\"bootstrap_protocol\":" + AICodedbProjectSettings.CurrentBootstrapProtocol + ","
                + "\"files\":[{\"path\":\"scripts/fixture.ps1\","
                + "\"sha256\":\"" + GetSha256(generationFile) + "\"}]}");

            var currentPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(currentPath));
            File.WriteAllText(
                currentPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + AICodedbProjectSettings.CurrentPackageVersion + "\","
                + "\"payload_version\":\"" + AICodedbProjectSettings.CurrentPayloadVersion + "\","
                + "\"payload_sequence\":" + AICodedbProjectSettings.CurrentPayloadSequence + ","
                + "\"generation_id\":\"" + AICodedbProjectSettings.CurrentGenerationId + "\","
                + "\"generation_relative_path\":\"" + AICodedbProjectSettings.HostGenerationsRelativePath
                + "/" + AICodedbProjectSettings.CurrentGenerationId + "\","
                + "\"generation_manifest_sha256\":\"" + GetSha256(manifestPath) + "\","
                + "\"bootstrap_protocol\":" + AICodedbProjectSettings.CurrentBootstrapProtocol + "}");
            return generationFile;
        }

        private static string GetSha256(string path)
        {
            using (var stream = File.OpenRead(path))
            using (var sha256 = SHA256.Create())
                return BitConverter.ToString(sha256.ComputeHash(stream)).Replace("-", string.Empty).ToLowerInvariant();
        }
    }
}
