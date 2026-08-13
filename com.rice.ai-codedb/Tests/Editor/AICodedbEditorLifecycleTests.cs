using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;
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
        public void HostGenerationStore_RejectsSelfConsistentCurrentGenerationNotOwnedByPackage()
        {
            InstallGeneration(
                AICodedbProjectSettings.CurrentPackageVersion,
                AICodedbProjectSettings.CurrentPayloadVersion,
                AICodedbProjectSettings.CurrentPayloadSequence,
                AICodedbProjectSettings.CurrentGenerationId);

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.IsUsable, Is.False);
            Assert.That(selection.Detail, Does.Contain("Package-owned"));
        }

        [Test]
        public void HostGenerationStore_RejectsDuplicateCurrentPointerProperty()
        {
            InstallCurrentGeneration();
            var pointerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            var pointer = File.ReadAllText(pointerPath);
            File.WriteAllText(
                pointerPath,
                pointer.Replace(
                    "\"schema_version\": 1,",
                    "\"schema_version\": 1,\n  \"schema_version\": 1,"));

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.IsUsable, Is.False);
            Assert.That(selection.Detail, Does.Contain("duplicate"));
        }

        [Test]
        public void HostGenerationStore_RejectsWrongTokenTypeInCurrentPointer()
        {
            InstallCurrentGeneration();
            var pointerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            var pointer = File.ReadAllText(pointerPath);
            File.WriteAllText(
                pointerPath,
                pointer.Replace("\"schema_version\": 1", "\"schema_version\": true"));

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.IsUsable, Is.False);
            Assert.That(selection.Detail, Does.Contain("signed 32-bit JSON integer"));
        }

        [Test]
        public void HostGenerationStore_RejectsDuplicateGenerationManifestProperty()
        {
            var generationFile = InstallCurrentGeneration();
            var manifestPath = Path.Combine(
                Path.GetDirectoryName(Path.GetDirectoryName(generationFile)),
                "generation-manifest.json");
            var manifest = File.ReadAllText(manifestPath);
            File.WriteAllText(
                manifestPath,
                manifest.Replace(
                    "\"schema_version\": 1,",
                    "\"schema_version\": 1,\n  \"SCHEMA_VERSION\": 1,"));
            RewriteCurrentPointerManifestHash(manifestPath);

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.IsUsable, Is.False);
            Assert.That(selection.Detail, Does.Contain("case-ambiguous"));
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
        public void HostGenerationStore_FailsClosedForUnmanifestedGenerationFile()
        {
            var generationFile = InstallCurrentGeneration();
            File.WriteAllText(Path.Combine(Path.GetDirectoryName(generationFile), "unmanifested.ps1"), "extra");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.Detail, Does.Contain("unmanifested file"));
        }

        [Test]
        public void HostGenerationStore_FailsClosedForUnmanifestedEmptyDirectory()
        {
            var generationFile = InstallCurrentGeneration();
            var generationRoot = Path.GetDirectoryName(Path.GetDirectoryName(generationFile));
            Directory.CreateDirectory(Path.Combine(generationRoot, "unmanifested-empty"));

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.Detail, Does.Contain("unmanifested directory"));
        }

        [Test]
        public void HostGenerationStore_FailsClosedForGenerationDirectoryReparsePoint()
        {
            var generationFile = InstallCurrentGeneration();
            var generationRoot = Path.GetDirectoryName(Path.GetDirectoryName(generationFile));
            var externalRoot = Path.Combine(
                Path.GetTempPath(),
                "Rice-AICodedb-Generation-Reparse-Tests",
                Guid.NewGuid().ToString("N"));
            var junctionPath = Path.Combine(generationRoot, "unmanifested-junction");
            Directory.CreateDirectory(externalRoot);
            try
            {
                CreateDirectoryJunction(junctionPath, externalRoot);

                var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

                Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
                Assert.That(selection.Detail, Does.Contain("reparse point"));
            }
            finally
            {
                if (Directory.Exists(junctionPath))
                    Directory.Delete(junctionPath);
                if (Directory.Exists(externalRoot))
                    Directory.Delete(externalRoot, true);
            }
        }

        [Test]
        public void HostGenerationStore_ResolvesValidatedPreviousGenerationWithoutMarkingItInvalid()
        {
            InstallGeneration("0.2.5-preview.2", "poc.29", 29, "poc.29");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Previous));
            Assert.That(selection.IsUsable, Is.False);
            Assert.That(selection.GenerationId, Is.EqualTo("poc.29"));
            Assert.That(selection.Detail, Does.Contain("compatible previous generation"));
            Assert.That(
                AICodedbHostGenerationStore.ResolveHostPath(
                    _projectRoot,
                    "scripts/fixture.ps1",
                    AICodedbProjectSettings.WatchManageScriptRelativePath),
                Does.EndWith("/host/generations/poc.29/scripts/fixture.ps1"));
        }

        [Test]
        public void HostGenerationStore_ResolvesValidatedNewerGenerationAsDowngradeReviewRequired()
        {
            InstallGeneration("0.2.5-preview.4", "poc.31", 31, "poc.31");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.DowngradeReviewRequired));
            Assert.That(selection.GenerationId, Is.EqualTo("poc.31"));
            Assert.That(selection.Detail, Does.Contain("newer than the loaded Package"));
        }

        [Test]
        public void HostGenerationStore_TreatsTrackedAdoptionWithoutRuntimeAsUnavailable()
        {
            var trackedFile = Path.Combine(_projectRoot, "AIWork", "codedb", "scripts", "fixture.ps1");
            Directory.CreateDirectory(Path.GetDirectoryName(trackedFile));
            File.WriteAllText(trackedFile, "tracked");
            var markerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostPayloadMarkerRelativePath);
            File.WriteAllText(
                markerPath,
                "{\"schema_version\":2,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + AICodedbProjectSettings.CurrentPackageVersion + "\","
                + "\"payload_version\":\"" + AICodedbProjectSettings.CurrentPayloadVersion + "\","
                + "\"payload_sequence\":" + AICodedbProjectSettings.CurrentPayloadSequence + ","
                + "\"payload_content_sha256\":\"" + new string('a', 64) + "\","
                + "\"host_use_gate_version\":1,\"generation_lease_version\":2,"
                + "\"generation_id\":\"" + AICodedbProjectSettings.CurrentGenerationId + "\","
                + "\"bootstrap_protocol\":" + AICodedbProjectSettings.CurrentBootstrapProtocol + ","
                + "\"current_pointer\":\"" + AICodedbProjectSettings.HostCurrentPointerRelativePath + "\","
                + "\"files\":[{\"path\":\"AIWork/codedb/scripts/fixture.ps1\","
                + "\"installed_sha256\":\"" + GetSha256(trackedFile) + "\"}]}");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Unavailable));
            Assert.That(selection.Detail, Does.Contain("no runtime generation is selected"));
        }

        [Test]
        public void HostGenerationStore_RejectsSchemaTwoMarkerThatClaimsIgnoredRuntimeOwnership()
        {
            var markerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostPayloadMarkerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(markerPath));
            File.WriteAllText(
                markerPath,
                "{\"schema_version\":2,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + AICodedbProjectSettings.CurrentPackageVersion + "\","
                + "\"payload_version\":\"" + AICodedbProjectSettings.CurrentPayloadVersion + "\","
                + "\"payload_sequence\":" + AICodedbProjectSettings.CurrentPayloadSequence + ","
                + "\"payload_content_sha256\":\"" + new string('a', 64) + "\","
                + "\"host_use_gate_version\":1,\"generation_lease_version\":2,"
                + "\"generation_id\":\"" + AICodedbProjectSettings.CurrentGenerationId + "\","
                + "\"bootstrap_protocol\":" + AICodedbProjectSettings.CurrentBootstrapProtocol + ","
                + "\"current_pointer\":\"" + AICodedbProjectSettings.HostCurrentPointerRelativePath + "\","
                + "\"files\":[{\"path\":\"AIWork/.runtime/codedb/host/current.json\","
                + "\"installed_sha256\":\"" + new string('b', 64) + "\"}]}");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.Detail, Does.Contain("invalid or duplicate path"));
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

        [TestCase("duplicate")]
        [TestCase("wrong-token")]
        [TestCase("bom")]
        [TestCase("invalid-utf8")]
        public void EditorLeaseRead_RejectsAmbiguousOrInvalidStrictJson(string invalidKind)
        {
            var leasePath = Path.Combine(_projectRoot, "editor-lease.json");
            var json = "{\"schema_version\":1,"
                       + "\"managed_by\":\"com.rice.ai-codedb\","
                       + "\"session_id\":\"session-1\","
                       + "\"editor_pid\":4321,"
                       + "\"process_start_ticks\":\"638893440000000000\","
                       + "\"project_root\":\"" + JsonPath(_projectRoot) + "\","
                       + "\"project_identity\":\"" + AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot) + "\","
                       + "\"created_at_utc\":\"2026-08-13T00:00:00.0000000Z\","
                       + "\"heartbeat_at_utc\":\"2026-08-13T00:00:01.0000000Z\"}";
            WriteInvalidJsonEvidence(
                leasePath,
                json,
                invalidKind,
                "\"schema_version\":1",
                "\"schema_version\":1,\"schema_version\":1",
                "\"editor_pid\":4321",
                "\"editor_pid\":\"4321\"");

            Assert.That(AICodedbEditorLifecycle.ReadEditorLease(leasePath), Is.Null);
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

        [TestCase("duplicate")]
        [TestCase("wrong-token")]
        [TestCase("bom")]
        [TestCase("invalid-utf8")]
        public void HostUpdatePolicyStore_RejectsAmbiguousOrInvalidStrictJson(string invalidKind)
        {
            var policyPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostUpdatePolicyRelativePath);
            var json = "{\"schema_version\":1,"
                       + "\"managed_by\":\"com.rice.ai-codedb\","
                       + "\"project_root\":\"" + JsonPath(_projectRoot) + "\","
                       + "\"automatic_updates\":true,"
                       + "\"updated_at_utc\":\"2026-08-13T00:00:00.0000000Z\"}";
            WriteInvalidJsonEvidence(
                policyPath,
                json,
                invalidKind,
                "\"schema_version\":1",
                "\"schema_version\":1,\"SCHEMA_VERSION\":1",
                "\"automatic_updates\":true",
                "\"automatic_updates\":\"true\"");

            var policy = AICodedbHostUpdatePolicyStore.Read(_projectRoot);

            Assert.That(policy.IsValid, Is.False);
            Assert.That(policy.IsEnabled, Is.False);
        }

        [TestCase("duplicate")]
        [TestCase("wrong-token")]
        [TestCase("bom")]
        [TestCase("invalid-utf8")]
        public void HostUpgradeStateStore_RejectsAmbiguousOrInvalidStrictJson(string invalidKind)
        {
            var statePath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostPayloadUpgradeStateRelativePath);
            var json = "{\"schema_version\":1,"
                       + "\"managed_by\":\"com.rice.ai-codedb\","
                       + "\"project_root\":\"" + JsonPath(_projectRoot) + "\","
                       + "\"state\":\"CURRENT\","
                       + "\"generation_id\":\"" + AICodedbProjectSettings.CurrentGenerationId + "\","
                       + "\"updated_at_utc\":\"2026-08-13T00:00:00.0000000Z\","
                       + "\"message\":null}";
            WriteInvalidJsonEvidence(
                statePath,
                json,
                invalidKind,
                "\"schema_version\":1",
                "\"schema_version\":1,\"schema_version\":1",
                "\"schema_version\":1",
                "\"schema_version\":true");

            var status = AICodedbHostUpgradeStatusStore.Read(
                _projectRoot,
                AICodedbProjectSettings.CurrentGenerationId);

            Assert.That(status.Phase, Is.EqualTo(AICodedbHostUpgradePhase.Invalid));
            Assert.That(status.DisplayState, Is.EqualTo(AICodedbStatusState.Error));
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
            Assert.That(AICodedbEditorLifecycle.CanEnsureHostGeneration(
                upgradeReady,
                AICodedbHostGenerationState.Previous), Is.False);
            Assert.That(AICodedbEditorLifecycle.CanEnsureHostGeneration(
                upgradeReady,
                AICodedbHostGenerationState.DowngradeReviewRequired), Is.False);
        }

        [TestCase(false, false, ExpectedResult = false)]
        [TestCase(true, false, ExpectedResult = true)]
        [TestCase(false, true, ExpectedResult = true)]
        [TestCase(true, true, ExpectedResult = true)]
        public bool ShouldDeferReconcile_WaitsForUnityPackageAndCompilationWork(
            bool isCompiling,
            bool isUpdating)
        {
            return AICodedbEditorLifecycle.ShouldDeferReconcile(isCompiling, isUpdating);
        }

        [Test]
        public void ShouldReconcileAutomaticHostUpgrade_RecognizesLegacyAndPreviousGenerationPointers()
        {
            var enabled = new AICodedbHostUpdatePolicy(true, true, true, "default");
            var unavailable = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Unavailable,
                AICodedbStatusState.Inactive,
                string.Empty,
                "No recorded upgrade",
                string.Empty);

            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                false,
                AICodedbHostGenerationState.Legacy,
                enabled,
                unavailable,
                "poc.30"), Is.True);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                true,
                AICodedbHostGenerationState.Invalid,
                enabled,
                unavailable,
                "poc.30"), Is.True);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                true,
                AICodedbHostGenerationState.Current,
                enabled,
                unavailable,
                "poc.30"), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                false,
                AICodedbHostGenerationState.Unavailable,
                enabled,
                unavailable,
                "poc.30"), Is.True);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                false,
                false,
                AICodedbHostGenerationState.Unavailable,
                enabled,
                unavailable,
                "poc.30"), Is.True);
        }

        [Test]
        public void ShouldReconcileAutomaticHostUpgrade_RespectsOwnershipPolicyAndGenerationFailureBoundary()
        {
            var enabled = new AICodedbHostUpdatePolicy(true, true, true, "default");
            var disabled = new AICodedbHostUpdatePolicy(true, false, false, "disabled");
            var failedCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.30",
                "CHECK_FAILED / poc.30",
                "fixture failure");
            var failedPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.29",
                "CHECK_FAILED / poc.29",
                "fixture failure");

            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                false,
                true,
                AICodedbHostGenerationState.Invalid,
                enabled,
                failedPrevious,
                "poc.30"), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                true,
                AICodedbHostGenerationState.Invalid,
                disabled,
                failedPrevious,
                "poc.30"), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                true,
                AICodedbHostGenerationState.Invalid,
                enabled,
                failedCurrent,
                "poc.30"), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldReconcileAutomaticHostUpgrade(
                true,
                true,
                AICodedbHostGenerationState.Invalid,
                enabled,
                failedPrevious,
                "poc.30"), Is.True);
        }

        [Test]
        public void IsAutomaticHostUpgradeSuppressed_OnlyBlocksTheFailedCurrentGeneration()
        {
            var failedCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.30",
                "CHECK_FAILED / poc.30",
                "fixture failure");
            var failedPrevious = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.CheckFailed,
                AICodedbStatusState.Error,
                "poc.29",
                "CHECK_FAILED / poc.29",
                "fixture failure");
            var switchingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Switching,
                AICodedbStatusState.Warning,
                "poc.30",
                "SWITCHING / poc.30",
                string.Empty);

            Assert.That(AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                failedCurrent,
                "poc.30"), Is.True);
            Assert.That(AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                failedPrevious,
                "poc.30"), Is.False);
            Assert.That(AICodedbEditorLifecycle.IsAutomaticHostUpgradeSuppressed(
                switchingCurrent,
                "poc.30"), Is.False);
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

        private static string JsonPath(string path)
        {
            return AICodedbPaths.NormalizePath(path).Replace("\\", "\\\\").Replace("\"", "\\\"");
        }

        private static void WriteInvalidJsonEvidence(
            string path,
            string validJson,
            string invalidKind,
            string duplicateSource,
            string duplicateReplacement,
            string wrongTokenSource,
            string wrongTokenReplacement)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            switch (invalidKind)
            {
                case "duplicate":
                    WriteUtf8NoBom(path, validJson.Replace(duplicateSource, duplicateReplacement));
                    return;
                case "wrong-token":
                    WriteUtf8NoBom(path, validJson.Replace(wrongTokenSource, wrongTokenReplacement));
                    return;
                case "bom":
                    var payload = Encoding.UTF8.GetBytes(validJson);
                    var preamble = new UTF8Encoding(true).GetPreamble();
                    var bomBytes = new byte[preamble.Length + payload.Length];
                    Buffer.BlockCopy(preamble, 0, bomBytes, 0, preamble.Length);
                    Buffer.BlockCopy(payload, 0, bomBytes, preamble.Length, payload.Length);
                    File.WriteAllBytes(path, bomBytes);
                    return;
                case "invalid-utf8":
                    File.WriteAllBytes(path, new byte[] { (byte)'{', (byte)'\"', 0xc3, 0x28, (byte)'\"', (byte)':', (byte)'1', (byte)'}' });
                    return;
                default:
                    Assert.Fail("Unknown invalid JSON evidence kind: " + invalidKind);
                    return;
            }
        }

        private static void WriteUtf8NoBom(string path, string content)
        {
            File.WriteAllText(path, content, new UTF8Encoding(false));
        }

        private string InstallCurrentGeneration()
        {
            var sourceRoot = Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Payload~",
                "Generations",
                AICodedbProjectSettings.CurrentGenerationId);
            var generationRoot = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                AICodedbProjectSettings.CurrentGenerationId);
            CopyDirectory(sourceRoot, generationRoot);

            var currentPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(currentPath));
            File.Copy(
                Path.Combine(AICodedbPaths.PackageRootPath, "Payload~", "host-current.json"),
                currentPath,
                true);
            return Path.Combine(generationRoot, "scripts", "verify-codedb-project.ps1");
        }

        private string InstallGeneration(
            string packageVersion,
            string payloadVersion,
            int payloadSequence,
            string generationId)
        {
            var generationRoot = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                generationId);
            var generationFile = Path.Combine(generationRoot, "scripts", "fixture.ps1");
            Directory.CreateDirectory(Path.GetDirectoryName(generationFile));
            File.WriteAllText(generationFile, "current");

            var manifestPath = Path.Combine(generationRoot, "generation-manifest.json");
            File.WriteAllText(
                manifestPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"generation_id\":\"" + generationId + "\","
                + "\"package_version\":\"" + packageVersion + "\","
                + "\"payload_version\":\"" + payloadVersion + "\","
                + "\"payload_sequence\":" + payloadSequence + ","
                + "\"bootstrap_protocol\":" + AICodedbProjectSettings.CurrentBootstrapProtocol + ","
                + "\"files\":[{\"path\":\"scripts/fixture.ps1\","
                + "\"sha256\":\"" + GetSha256(generationFile) + "\"}]}");

            var currentPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(currentPath));
            File.WriteAllText(
                currentPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + packageVersion + "\","
                + "\"payload_version\":\"" + payloadVersion + "\","
                + "\"payload_sequence\":" + payloadSequence + ","
                + "\"generation_id\":\"" + generationId + "\","
                + "\"generation_relative_path\":\"" + AICodedbProjectSettings.HostGenerationsRelativePath
                + "/" + generationId + "\","
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

        private void RewriteCurrentPointerManifestHash(string manifestPath)
        {
            var currentPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            var current = File.ReadAllText(currentPath);
            var start = current.IndexOf("\"generation_manifest_sha256\": \"", StringComparison.Ordinal);
            Assert.That(start, Is.GreaterThanOrEqualTo(0));
            start += "\"generation_manifest_sha256\": \"".Length;
            var end = current.IndexOf('"', start);
            Assert.That(end, Is.GreaterThan(start));
            File.WriteAllText(currentPath, current.Substring(0, start) + GetSha256(manifestPath) + current.Substring(end));
        }

        private static void CopyDirectory(string sourceRoot, string targetRoot)
        {
            Assert.That(Directory.Exists(sourceRoot), Is.True, "Package-owned Current generation fixture is missing.");
            foreach (var sourceDirectory in Directory.GetDirectories(sourceRoot, "*", SearchOption.AllDirectories))
            {
                var relative = sourceDirectory.Substring(sourceRoot.Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                Directory.CreateDirectory(Path.Combine(targetRoot, relative));
            }
            Directory.CreateDirectory(targetRoot);
            foreach (var sourceFile in Directory.GetFiles(sourceRoot, "*", SearchOption.AllDirectories))
            {
                var relative = sourceFile.Substring(sourceRoot.Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                var targetFile = Path.Combine(targetRoot, relative);
                Directory.CreateDirectory(Path.GetDirectoryName(targetFile));
                File.Copy(sourceFile, targetFile, true);
            }
        }

        private static void CreateDirectoryJunction(string junctionPath, string targetPath)
        {
            var command = "New-Item -ItemType Junction -Path '"
                          + junctionPath.Replace("'", "''")
                          + "' -Target '"
                          + targetPath.Replace("'", "''")
                          + "' -ErrorAction Stop | Out-Null";
            var encodedCommand = Convert.ToBase64String(System.Text.Encoding.Unicode.GetBytes(command));
            var startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " + encodedCommand,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using (var process = System.Diagnostics.Process.Start(startInfo))
            {
                Assert.That(process, Is.Not.Null);
                var standardOutput = process.StandardOutput.ReadToEnd();
                var standardError = process.StandardError.ReadToEnd();
                Assert.That(process.WaitForExit(10000), Is.True, "Timed out creating the reparse-point fixture.");
                Assert.That(process.ExitCode, Is.Zero, standardOutput + Environment.NewLine + standardError);
            }

            Assert.That(
                (File.GetAttributes(junctionPath) & FileAttributes.ReparsePoint) != 0,
                Is.True,
                "The fixture junction was not marked as a reparse point.");
        }
    }
}
