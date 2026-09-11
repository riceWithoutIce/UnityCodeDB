using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbEditorLifecycleTests
    {
        private const string Poc33WrapperSourceRevision = "d1313efa540f5fc805d83a830951afdb8cd2b256";
        private const string Poc33WrapperSourcePath = "com.rice.ai-codedb/Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs";
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
        public void ProjectIntegrationState_AbsentKeepsLifecycleInstalled()
        {
            var status = AICodedbProjectIntegrationStateStore.Read(_projectRoot);

            Assert.That(status.State, Is.EqualTo(AICodedbProjectIntegrationState.Installed));
            Assert.That(status.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.None));
            Assert.That(AICodedbEditorLifecycle.ShouldPublishEditorLease(status), Is.True);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticUninstallCleanup(status), Is.False);
        }

        [Test]
        public void EditorLeaseHeartbeatContinuesDuringReconcileAndPlaySuspension()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldRefreshEditorLease(true, true, false),
                Is.True,
                "A long-running reconcile must not make the interactive Editor lease stale.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRefreshEditorLease(true, false, false),
                Is.True);
            Assert.That(
                AICodedbEditorLifecycle.ShouldRefreshEditorLease(false, true, false),
                Is.False,
                "Missing prerequisites must continue to suppress lease publication.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRefreshEditorLease(true, true, true),
                Is.False,
                "A quitting Editor must not publish a new heartbeat.");
        }

        [TestCase(false, false, false, ExpectedResult = true)]
        [TestCase(true, true, true, ExpectedResult = true)]
        [TestCase(true, true, false, ExpectedResult = false)]
        [TestCase(true, false, true, ExpectedResult = false)]
        public bool CoordinatorAdmission_RequiresCurrentPrerequisiteAndPublishedLease(
            bool independentPrerequisiteRead,
            bool prerequisiteCurrent,
            bool editorLeasePublished)
        {
            return AICodedbEditorLifecycle.ShouldAttemptCoordinatorAdmission(
                independentPrerequisiteRead,
                prerequisiteCurrent,
                editorLeasePublished);
        }

        [TestCase(
            false,
            true,
            true,
            false,
            "[PRODUCT_LAYER PREREQUISITE] BROKEN",
            AICodedbProductLayerState.Current,
            AICodedbProductLayerState.Unknown,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.ResultAbsent)]
        [TestCase(
            true,
            true,
            true,
            false,
            "[PRODUCT_LAYER PREREQUISITE] BROKEN",
            AICodedbProductLayerState.Current,
            AICodedbProductLayerState.Unknown,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.CommandTimedOut)]
        [TestCase(
            true,
            false,
            true,
            false,
            "no prerequisite marker",
            AICodedbProductLayerState.Current,
            AICodedbProductLayerState.Unknown,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.CommandEnvelopeInvalid)]
        [TestCase(
            true,
            false,
            false,
            false,
            "[PRODUCT_LAYER PREREQUISITE] CURRENT\n[PRODUCT_LAYER PREREQUISITE] MISSING",
            AICodedbProductLayerState.Current,
            AICodedbProductLayerState.Unknown,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.MarkerCardinalityInvalid)]
        [TestCase(
            true,
            false,
            false,
            false,
            "[PRODUCT_LAYER PREREQUISITE] PARTIAL",
            AICodedbProductLayerState.Current,
            AICodedbProductLayerState.Unknown,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.MarkerMalformed)]
        [TestCase(
            true,
            false,
            false,
            false,
            "[PRODUCT_LAYER PREREQUISITE] CURRENT",
            AICodedbProductLayerState.Missing,
            AICodedbProductLayerState.Current,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.MarkerProductStatusMismatch)]
        [TestCase(
            true,
            false,
            false,
            false,
            "[PRODUCT_LAYER PREREQUISITE] CURRENT - sanitized detail",
            AICodedbProductLayerState.Current,
            AICodedbProductLayerState.Current,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.TrustworthyCurrent)]
        [TestCase(
            true,
            false,
            false,
            false,
            "[PRODUCT_LAYER PREREQUISITE] MISSING - sanitized detail",
            AICodedbProductLayerState.Missing,
            AICodedbProductLayerState.Missing,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.TrustworthyMissing)]
        public AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition PrerequisiteEvidence_ClassifiesSanitizedReasonWithoutChangingAdmission(
            bool resultPresent,
            bool timedOut,
            bool commandEnvelopePresent,
            bool commandEnvelopeValid,
            string standardOutput,
            AICodedbProductLayerState productStatusPrerequisite,
            AICodedbProductLayerState expectedPrerequisite)
        {
            AICodedbProductLayerState prerequisite;
            var disposition = AICodedbEditorLifecycle.ClassifyIndependentPrerequisiteEvidence(
                resultPresent,
                timedOut,
                commandEnvelopePresent,
                commandEnvelopeValid,
                standardOutput,
                productStatusPrerequisite,
                out prerequisite);

            Assert.That(prerequisite, Is.EqualTo(expectedPrerequisite));
            var prerequisiteCurrent =
                disposition == AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.TrustworthyCurrent;
            Assert.That(
                AICodedbEditorLifecycle.ShouldAttemptCoordinatorAdmission(
                    true,
                    prerequisiteCurrent,
                    true),
                Is.EqualTo(prerequisiteCurrent),
                "Every untrustworthy or missing prerequisite classification must remain fail-closed.");
            return disposition;
        }

        [Test]
        public void PrerequisiteEvidence_PersistsOnlySanitizedDispositionCode()
        {
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);

            evidence.RecordPrerequisiteEvidenceDisposition(
                AICodedbEditorLifecycle.AICodedbPrerequisiteEvidenceDisposition.MarkerMalformed);
            var document = evidence.Capture("prerequisite_attribution");

            Assert.That(document.prerequisite_evidence_disposition, Is.EqualTo("MarkerMalformed"));
            Assert.That(document.prerequisite_evidence_disposition, Does.Not.Contain("PRODUCT_LAYER"));
            Assert.That(document.prerequisite_evidence_disposition, Does.Not.Contain("\\"));
            Assert.That(document.prerequisite_evidence_disposition, Does.Not.Contain("/"));
        }

        [TestCase(
            AICodedbProjectIntegrationState.Installed,
            AICodedbCurrentInstanceState.Current,
            true,
            true,
            true,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.EditorLeasePublished)]
        [TestCase(
            AICodedbProjectIntegrationState.Installed,
            AICodedbCurrentInstanceState.TrustedPrevious,
            true,
            true,
            true,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.EditorLeasePublished)]
        [TestCase(
            AICodedbProjectIntegrationState.Installed,
            AICodedbCurrentInstanceState.Current,
            true,
            true,
            false,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.LeasePublicationFailed)]
        [TestCase(
            AICodedbProjectIntegrationState.Installed,
            AICodedbCurrentInstanceState.Missing,
            false,
            false,
            false,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.CurrentInstanceMissing)]
        [TestCase(
            AICodedbProjectIntegrationState.Installed,
            AICodedbCurrentInstanceState.Invalid,
            true,
            false,
            false,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.CurrentInstanceInvalid)]
        [TestCase(
            AICodedbProjectIntegrationState.Installed,
            AICodedbCurrentInstanceState.Current,
            true,
            false,
            false,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.CurrentInstanceIneligible)]
        [TestCase(
            AICodedbProjectIntegrationState.Uninstalled,
            AICodedbCurrentInstanceState.Current,
            true,
            true,
            false,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.IntegrationNotEligible)]
        [TestCase(
            AICodedbProjectIntegrationState.Invalid,
            AICodedbCurrentInstanceState.Current,
            true,
            true,
            false,
            ExpectedResult = AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition.IntegrationNotEligible)]
        public AICodedbEditorLifecycle.AICodedbCoordinatorAdmissionDisposition CoordinatorAdmission_ClassifiesLeaseTargetBeforePublication(
            AICodedbProjectIntegrationState integrationState,
            AICodedbCurrentInstanceState currentInstanceState,
            bool currentInstancePresent,
            bool canPublishEditorLease,
            bool leasePublished)
        {
            return AICodedbEditorLifecycle.ClassifyEditorLeasePublication(
                integrationState,
                currentInstanceState,
                currentInstancePresent,
                canPublishEditorLease,
                leasePublished);
        }

        [Test]
        public void LifecycleInitialization_DoesNotRequirePreselectedLeasePath()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldInitializeLifecycle(false),
                Is.True,
                "The instance lease path is selected by the background reconcile after initialization.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldInitializeLifecycle(true),
                Is.False,
                "A quitting editor must not start new lifecycle work.");
        }

        [Test]
        public void EditorQuitLeaseHandoff_UsesAtomicTakeWithoutFilesystemWork()
        {
            var leasePath = "fixture-lease.json";

            var taken = AICodedbEditorLifecycle.TakeEditorLeasePathForDeletion(ref leasePath);

            Assert.That(taken, Is.EqualTo("fixture-lease.json"));
            Assert.That(leasePath, Is.Empty);
        }

        [TestCase(false, false, false, false, ExpectedResult = false)]
        [TestCase(true, false, false, false, ExpectedResult = true)]
        [TestCase(false, true, false, false, ExpectedResult = true)]
        [TestCase(false, false, true, false, ExpectedResult = true)]
        [TestCase(false, false, false, true, ExpectedResult = false)]
        [TestCase(false, false, true, true, ExpectedResult = false)]
        public bool LifecycleInitialization_DefersDuringUnityTransition(
            bool isCompiling,
            bool isUpdating,
            bool isPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return AICodedbEditorLifecycle.ShouldDeferLifecycleInitialization(
                isCompiling,
                isUpdating,
                isPlayingOrWillChangePlaymode,
                applicationPlaying);
        }

        [TestCase(false, false, false, false, ExpectedResult = false)]
        [TestCase(false, false, true, false, ExpectedResult = true)]
        [TestCase(false, false, true, true, ExpectedResult = false)]
        [TestCase(true, false, true, true, ExpectedResult = true)]
        public bool SupervisorReconnect_DefersOnlyForUnsafeUnityTransitions(
            bool isCompiling,
            bool isUpdating,
            bool isPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return AICodedbEditorLifecycle.ShouldDeferSupervisorReconnect(
                isCompiling,
                isUpdating,
                isPlayingOrWillChangePlaymode,
                applicationPlaying);
        }

        [TestCase(true, false, ExpectedResult = true)]
        [TestCase(true, true, ExpectedResult = false)]
        [TestCase(false, false, ExpectedResult = false)]
        public bool DomainReload_RestoresOnlyCurrentPackageLeasePrerequisite(
            bool persistedPrerequisiteCurrent,
            bool packageFingerprintChanged)
        {
            return AICodedbEditorLifecycle.ShouldRestoreLeasePrerequisite(
                persistedPrerequisiteCurrent,
                packageFingerprintChanged);
        }

        [Test]
        public void SupervisorProtocol_StatusRequestUsesVersionedBridgeEnvelope()
        {
            var request = AICodedbSupervisorProtocol.BuildStatusRequest("token", "request-1");
            var document = AICodedbStrictJson.ParseObject(request, "Supervisor request");

            Assert.That(
                AICodedbStrictJson.GetRequiredInt32(document, "protocol_version", "Supervisor request"),
                Is.EqualTo(AICodedbSupervisorProtocol.Version));
            Assert.That(
                AICodedbStrictJson.GetRequiredString(document, "client_kind", "Supervisor request"),
                Is.EqualTo(AICodedbSupervisorProtocol.ClientKind));
            Assert.That(
                AICodedbStrictJson.GetRequiredString(document, "command", "Supervisor request"),
                Is.EqualTo("status"));
            Assert.That(
                AICodedbStrictJson.GetRequiredString(document, "request_id", "Supervisor request"),
                Is.EqualTo("request-1"));
        }

        [Test]
        public void SupervisorProtocol_OperationRequestUsesShortPollingEnvelope()
        {
            const string operationId = "0123456789abcdef0123456789abcdef";
            var request = AICodedbSupervisorProtocol.BuildOperationRequest(
                "token",
                "request-operation",
                operationId);
            var document = AICodedbStrictJson.ParseObject(request, "Supervisor operation request");

            Assert.That(
                AICodedbStrictJson.GetRequiredString(
                    document,
                    "command",
                    "Supervisor operation request"),
                Is.EqualTo("operation"));
            Assert.That(
                AICodedbStrictJson.GetRequiredString(
                    document,
                    "operation_id",
                    "Supervisor operation request"),
                Is.EqualTo(operationId));
            Assert.That(
                AICodedbStrictJson.GetRequiredInt32(
                    document,
                    "protocol_version",
                    "Supervisor operation request"),
                Is.EqualTo(AICodedbSupervisorProtocol.Version));
        }

        [Test]
        public void SupervisorProtocol_RoundTripsNestedOperationStatus()
        {
            var envelope = AICodedbStrictJson.ParseObject(
                "{\"status\":{\"readiness_state\":\"maintenance\","
                + "\"operation\":{\"operation_id\":\"0123456789abcdef0123456789abcdef\","
                + "\"state\":\"running\",\"result\":null},\"event_sequence\":7}}",
                "Supervisor operation envelope");
            var status = AICodedbStrictJson.RequireObject(
                envelope["status"],
                "Supervisor operation status");

            var serialized = AICodedbSupervisorBridge.SerializeJsonObject(status);
            var roundTrip = AICodedbStrictJson.ParseObject(
                serialized,
                "Round-tripped Supervisor operation status");
            var operation = AICodedbStrictJson.RequireObject(
                roundTrip["operation"],
                "Round-tripped Supervisor operation");

            Assert.That(
                AICodedbStrictJson.GetRequiredString(
                    operation,
                    "state",
                    "Round-tripped Supervisor operation"),
                Is.EqualTo("running"));
            Assert.That(
                AICodedbStrictJson.GetRequiredInt32(
                    roundTrip,
                    "event_sequence",
                    "Round-tripped Supervisor operation status"),
                Is.EqualTo(7));
        }

        [Test]
        public void SupervisorProtocol_FinalShutdownBindsExpectedLifecycle()
        {
            var request = AICodedbSupervisorProtocol.BuildCommandRequest(
                "token",
                "request-final-shutdown",
                "shutdown",
                null,
                "unity-bridge",
                false);
            var document = AICodedbStrictJson.ParseObject(request, "Supervisor shutdown request");

            Assert.That(
                AICodedbStrictJson.GetRequiredString(
                    document,
                    "command",
                    "Supervisor shutdown request"),
                Is.EqualTo("shutdown"));
            Assert.That(
                AICodedbStrictJson.GetRequiredString(
                    document,
                    "expected_lifecycle_id",
                    "Supervisor shutdown request"),
                Is.EqualTo("unity-bridge"));
        }

        [Test]
        public void SupervisorProtocol_ReinstallSerializesOnlyExplicitMutationConfirmation()
        {
            var unconfirmed = AICodedbSupervisorProtocol.BuildCommandRequest(
                "token",
                "request-reinstall-unconfirmed",
                "materialize",
                "Reinstall",
                null,
                false);
            var confirmed = AICodedbSupervisorProtocol.BuildCommandRequest(
                "token",
                "request-reinstall-confirmed",
                "materialize",
                "Reinstall",
                null,
                true);

            Assert.That(unconfirmed, Does.Not.Contain("confirmed_project_mutation"));
            Assert.That(confirmed, Does.Contain("\"confirmed_project_mutation\":true"));
        }

        [Test]
        public void LifecycleMaintenanceCommand_SourceUsesIntentAdapterAndDefersCachePublication()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbEditorLifecycle.cs"));
            var start = source.IndexOf(
                "RunSupervisorMaintenanceCommandAsync(",
                StringComparison.Ordinal);
            var end = source.IndexOf(
                "private static void RememberSupervisorSnapshot",
                start,
                StringComparison.Ordinal);
            Assert.That(start, Is.GreaterThanOrEqualTo(0));
            Assert.That(end, Is.GreaterThan(start));
            var body = source.Substring(start, end - start);

            Assert.That(body, Does.Contain("SupervisorIntentAdapter.Dispatch("));
            Assert.That(body, Does.Contain("AICodedbSupervisorRequestKind.Maintenance"));
            Assert.That(body, Does.Contain("SupervisorBridge.SendCommandAsync("));
            Assert.That(body, Does.Contain("\"maintenance\""));
            Assert.That(body, Does.Contain("AICodedbLifecycleEvidence.RecordSupervisorObservation"));
            Assert.That(body, Does.Not.Contain("RememberSupervisorSnapshot("));
        }

        [Test]
        public void SupervisorProtocol_RejectsUnsafeOrNonWindowsPipeIdentities()
        {
            string pipeName;
            Assert.That(
                AICodedbSupervisorProtocol.TryGetWindowsPipeName(
                    @"\\.\pipe\codedb-watch-test",
                    out pipeName),
                Is.True);
            Assert.That(pipeName, Is.EqualTo("codedb-watch-test"));
            Assert.That(
                AICodedbSupervisorProtocol.TryGetWindowsPipeName(
                    @"\\.\pipe\codedb-watch\nested",
                    out pipeName),
                Is.False);
            Assert.That(
                AICodedbSupervisorProtocol.TryGetWindowsPipeName(
                    "/tmp/coordinator.sock",
                    out pipeName),
                Is.False);
        }

        [Test]
        public void SupervisorProtocol_DerivesPipeIdentityFromProjectAndRuntime()
        {
            var root = Path.Combine(Path.GetTempPath(), "codedb-bridge-root");
            var runtime = Path.Combine(root, "instances", "current", "watch", "coordinator");
            string expected;
            Assert.That(
                AICodedbSupervisorProtocol.TryGetExpectedWindowsPipeName(root, runtime, out expected),
                Is.True);
            Assert.That(expected, Does.StartWith("codedb-watch-"));
            Assert.That(expected, Has.Length.EqualTo("codedb-watch-".Length + 20));

            string parsed;
            Assert.That(
                AICodedbSupervisorProtocol.TryGetWindowsPipeName(
                    @"\\.\pipe\" + expected,
                    out parsed),
                Is.True);
            Assert.That(parsed, Is.EqualTo(expected));
        }

        [Test]
        public void SupervisorProtocol_UsesCanonicalPipeIdentityAndRecognizesExactV1Handoff()
        {
            var root = "G" + @":\RiceProgram\Test\Test";
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);

            Assert.That(
                AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                    root,
                    runtime,
                    out var canonical),
                Is.True);
            Assert.That(canonical, Is.EqualTo("codedb-supervisor-8ef262de0ef456d71b2b"));
            Assert.That(
                AICodedbSupervisorProtocol.TryGetLegacySupervisorPipeName(
                    root,
                    runtime,
                    out var legacy),
                Is.True);
            Assert.That(legacy, Is.EqualTo("codedb-supervisor-928a30ffe326434cc56f"));
            Assert.That(
                AICodedbSupervisorProtocol.IsExpectedSupervisorPipeName(
                    canonical,
                    root,
                    runtime,
                    root,
                    runtime),
                Is.True);
            Assert.That(
                AICodedbSupervisorProtocol.IsExpectedSupervisorPipeName(
                    legacy,
                    root,
                    runtime,
                    root,
                    runtime),
                Is.True);
            Assert.That(
                AICodedbSupervisorProtocol.IsExpectedSupervisorPipeName(
                    "codedb-supervisor-00000000000000000000",
                    root,
                    runtime,
                    root,
                    runtime),
                Is.False);
        }

        [TestCase(
            "enabled",
            "online",
            "ready",
            false,
            "disabled",
            "disabled",
            false,
            AICodedbSupervisorReadinessState.CoreReady,
            "CORE_READY")]
        [TestCase(
            "enabled",
            "online",
            "starting",
            false,
            "disabled",
            "disabled",
            false,
            AICodedbSupervisorReadinessState.Starting,
            "SUPERVISOR_STARTING")]
        [TestCase(
            "enabled",
            "online",
            "ready",
            true,
            "building",
            "ready",
            true,
            AICodedbSupervisorReadinessState.Maintenance,
            "SUPERVISOR_MAINTENANCE")]
        [TestCase(
            "enabled",
            "online",
            "failed",
            false,
            "disabled",
            "disabled",
            false,
            AICodedbSupervisorReadinessState.Degraded,
            "SUPERVISOR_DEGRADED")]
        [TestCase(
            "disabled",
            "offline",
            "stopped",
            false,
            "disabled",
            "disabled",
            false,
            AICodedbSupervisorReadinessState.Stopped,
            "SUPERVISOR_STOPPED")]
        public void SupervisorProtocol_ReducesAuthenticatedRuntimeReadiness(
            string desiredState,
            string editorDemand,
            string providerState,
            bool adapterEnabled,
            string adapterState,
            string adapterWorkerState,
            bool adapterWorkerConfigured,
            AICodedbSupervisorReadinessState expectedState,
            string expectedReasonCode)
        {
            AICodedbSupervisorReadinessState readiness;
            string reasonCode;
            string detail;
            Assert.That(
                AICodedbSupervisorProtocol.TryResolveReadiness(
                    desiredState,
                    editorDemand,
                    providerState,
                    adapterEnabled,
                    adapterState,
                    adapterWorkerState,
                    adapterWorkerConfigured,
                    out readiness,
                    out reasonCode,
                    out detail),
                Is.True);
            Assert.That(readiness, Is.EqualTo(expectedState));
            Assert.That(reasonCode, Is.EqualTo(expectedReasonCode));
            Assert.That(detail, Is.Not.Empty);
            Assert.That(
                AICodedbSupervisorProtocol.GetReadinessCode(readiness),
                Is.EqualTo(expectedState == AICodedbSupervisorReadinessState.CoreReady
                    ? "CORE_READY"
                    : expectedState == AICodedbSupervisorReadinessState.Starting
                        ? "STARTING"
                        : expectedState == AICodedbSupervisorReadinessState.Maintenance
                            ? "MAINTENANCE"
                            : expectedState == AICodedbSupervisorReadinessState.Degraded
                                ? "DEGRADED"
                                : expectedState == AICodedbSupervisorReadinessState.Stopped
                                    ? "STOPPED"
                                    : "UNKNOWN"));
        }

        [Test]
        public void SupervisorProtocol_RejectsInvalidReadinessEvidenceAsBlocked()
        {
            AICodedbSupervisorReadinessState readiness;
            string reasonCode;
            string detail;
            Assert.That(
                AICodedbSupervisorProtocol.TryResolveReadiness(
                    "enabled",
                    "online",
                    "ready",
                    true,
                    "watching",
                    "starting",
                    false,
                    out readiness,
                    out reasonCode,
                    out detail),
                Is.False);
            Assert.That(readiness, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
            Assert.That(reasonCode, Is.EqualTo("SUPERVISOR_BLOCKED"));
            Assert.That(detail, Is.Not.Empty);
        }

        [Test]
        public void SupervisorProtocol_CoreReadyRequiresProviderAndConfiguredAdapterEvidence()
        {
            AICodedbSupervisorReadinessState readiness;
            string reasonCode;
            string detail;
            Assert.That(
                AICodedbSupervisorProtocol.TryResolveReadiness(
                    "enabled",
                    "online",
                    "ready",
                    true,
                    "watching",
                    "ready",
                    false,
                    out readiness,
                    out reasonCode,
                    out detail),
                Is.False,
                "An adapter worker status cannot be accepted as ready when its executable is not identified.");
            Assert.That(readiness, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
        }

        [Test]
        public void SupervisorProtocol_StatusHandshakeRequiresIdentityAndReportsCoreReady()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(
                root,
                runtime,
                contract,
                "2026-08-25T00:00:00.0000000Z");

            var snapshot = AICodedbSupervisorBridge.ParseStatusResponse(
                response,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(snapshot.ConnectionState, Is.EqualTo(AICodedbSupervisorConnectionState.Connected));
            Assert.That(snapshot.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.CoreReady));
            Assert.That(snapshot.IsCoreReady, Is.True);
            Assert.That(snapshot.ReadinessCode, Is.EqualTo("CORE_READY"));
            Assert.That(snapshot.ProviderState, Is.EqualTo("ready"));
            Assert.That(snapshot.DesiredState, Is.EqualTo("enabled"));
            Assert.That(snapshot.EditorDemand, Is.EqualTo("online"));
            Assert.That(snapshot.SupervisorSchemaVersion, Is.EqualTo(3));
            Assert.That(snapshot.SupervisorProcessId, Is.EqualTo(1234));
            Assert.That(snapshot.SelectedInstanceId, Is.EqualTo("0123456789abcdef0123456789abcdef"));
            Assert.That(snapshot.TargetGenerationId, Is.EqualTo(contract.Target.GenerationId));
            Assert.That(snapshot.SelectedGenerationId, Is.EqualTo(contract.Target.GenerationId));
            Assert.That(snapshot.RuntimeContractSha256, Is.EqualTo(contract.Sha256));
            Assert.That(snapshot.GenerationDisposition, Is.EqualTo("CURRENT"));
            Assert.That(snapshot.OperationalObservationSchemaVersion, Is.EqualTo(1));
            Assert.That(snapshot.OperationalObservationId, Is.EqualTo("11111111111111111111111111111111"));
            Assert.That(snapshot.OperationalObservationRevision, Is.EqualTo(7));
            Assert.That(snapshot.OwnerEpoch, Is.EqualTo("abcdefabcdefabcdefabcdefabcdefab"));

            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);
            evidence.RecordSupervisorObservation(snapshot);
            evidence.RecordSupervisorObservation(snapshot);
            var continuity = evidence.Capture("same_supervisor");
            Assert.That(continuity.supervisor_observation_count, Is.EqualTo(2));
            Assert.That(continuity.supervisor_identity_change_count, Is.EqualTo(0));
            Assert.That(continuity.supervisor_pid, Is.EqualTo(1234));
            Assert.That(continuity.selected_instance_id, Is.EqualTo("0123456789abcdef0123456789abcdef"));
        }

        [Test]
        public void SupervisorProtocol_CoordinatorFailureCategoryUsesFixedVocabulary()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(
                root,
                runtime,
                contract,
                "2026-08-25T00:00:00.0000000Z");

            var nonzeroExit = AICodedbSupervisorBridge.ParseStatusResponse(
                response
                    .Replace(
                        "\"coordinator_failure_category\":\"NONE\"",
                        "\"coordinator_failure_category\":\"NONZERO_EXIT\"")
                    .Replace("\"state\":\"core_ready\"", "\"state\":\"degraded\"")
                    .Replace(
                        "\"reason_code\":\"COORDINATOR_OPERATIONAL\"",
                        "\"reason_code\":\"COORDINATOR_START_FAILED\""),
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);
            var unknown = AICodedbSupervisorBridge.ParseStatusResponse(
                response.Replace(
                    "\"coordinator_failure_category\":\"NONE\"",
                    "\"coordinator_failure_category\":\"FUTURE_VALID_FAILURE\""),
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(
                nonzeroExit.CoordinatorFailureCategory,
                Is.EqualTo(AICodedbCoordinatorFailureCategory.NonzeroExit));
            Assert.That(nonzeroExit.CoordinatorFailureCode, Is.EqualTo("NONZERO_EXIT"));
            Assert.That(
                unknown.CoordinatorFailureCategory,
                Is.EqualTo(AICodedbCoordinatorFailureCategory.NotEvaluated));
            Assert.That(unknown.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
            Assert.That(unknown.ReasonCode, Is.EqualTo("INVALID_OPERATIONAL_READINESS"));
        }

        [Test]
        public void SupervisorProtocol_RejectsMalformedOrMismatchedOperationalAuthority()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(root, runtime, contract, null);
            var malformedResponse = response.Replace(
                "\"supervisor_pid\":1234},",
                "\"supervisor_pid\":1234,\"unexpected\":true},");
            var mismatchedResponse = response.Replace(
                "\"selected_instance_id\":\"0123456789abcdef0123456789abcdef\",\"selected_generation_id\"",
                "\"selected_instance_id\":\"ffffffffffffffffffffffffffffffff\",\"selected_generation_id\"");

            var malformed = AICodedbSupervisorBridge.ParseStatusResponse(
                malformedResponse,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);
            var mismatched = AICodedbSupervisorBridge.ParseStatusResponse(
                mismatchedResponse,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(malformed.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
            Assert.That(malformed.ReasonCode, Is.EqualTo("INVALID_OPERATIONAL_READINESS"));
            Assert.That(mismatched.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
            Assert.That(mismatched.ReasonCode, Is.EqualTo("INVALID_OPERATIONAL_READINESS"));
        }

        [Test]
        public void LifecycleStatusBinding_RequiresSameOperationalObservationRevision()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(root, runtime, contract, null);
            var snapshot = AICodedbSupervisorBridge.ParseStatusResponse(
                response,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);
            var envelope = AICodedbStrictJson.ParseObject(response, "fixture Supervisor response");
            var status = AICodedbStrictJson.RequireObject(
                envelope["status"],
                "fixture Supervisor status");
            var observation = AICodedbStrictJson.RequireObject(
                status["operational_readiness"],
                "fixture Supervisor operational readiness");
            var ready = new AICodedbProductStatus(
                AICodedbProductState.Ready,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                "CodeDB is ready.");
            var matchingResult = new AICodedbCommandResult(
                0,
                "[SUPERVISOR_OPERATIONAL_READINESS] "
                + AICodedbSupervisorBridge.SerializeJsonObject(observation),
                string.Empty,
                false);

            AICodedbSupervisorSnapshot boundSnapshot;
            var bound = AICodedbEditorLifecycle.BindProductStatusToSupervisorObservation(
                ready,
                matchingResult,
                snapshot,
                out boundSnapshot);

            Assert.That(bound.State, Is.EqualTo(AICodedbProductState.Ready));
            Assert.That(boundSnapshot, Is.SameAs(snapshot));

            observation["revision"] = snapshot.OperationalObservationRevision + 1;
            var mismatchedResult = new AICodedbCommandResult(
                0,
                "[SUPERVISOR_OPERATIONAL_READINESS] "
                + AICodedbSupervisorBridge.SerializeJsonObject(observation),
                string.Empty,
                false);
            var rejected = AICodedbEditorLifecycle.BindProductStatusToSupervisorObservation(
                ready,
                mismatchedResult,
                snapshot,
                out boundSnapshot);

            Assert.That(rejected.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(rejected.Detail, Does.Contain("same revision"));
            Assert.That(boundSnapshot, Is.Null);
        }

        [Test]
        public void SupervisorReconnect_InFlightSnapshotDoesNotEraseAttemptClassification()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(
                root,
                runtime,
                contract,
                "2026-08-25T00:00:00.0000000Z");
            var missingField = AICodedbSupervisorBridge.ParseStatusResponse(
                response.Replace(
                    "\"coordinator_failure_category\":\"NONE\",",
                    string.Empty),
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);
            var notEvaluated = AICodedbSupervisorBridge.ParseStatusResponse(
                response.Replace(
                    "\"coordinator_failure_category\":\"NONE\"",
                    "\"coordinator_failure_category\":\"NOT_EVALUATED\""),
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);
            var failedAttempt = AICodedbSupervisorBridge.ParseStatusResponse(
                response
                    .Replace(
                        "\"coordinator_failure_category\":\"NONE\"",
                        "\"coordinator_failure_category\":\"NONZERO_EXIT\"")
                    .Replace("\"state\":\"core_ready\"", "\"state\":\"degraded\"")
                    .Replace(
                        "\"reason_code\":\"COORDINATOR_OPERATIONAL\"",
                        "\"reason_code\":\"COORDINATOR_START_FAILED\""),
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            var noPriorSnapshot =
                AICodedbSupervisorBridge.CreateReconnectInFlightSnapshot(null);
            var legacyReconnect =
                AICodedbSupervisorBridge.CreateReconnectInFlightSnapshot(missingField);
            var unevaluatedReconnect =
                AICodedbSupervisorBridge.CreateReconnectInFlightSnapshot(notEvaluated);
            var failedReconnect =
                AICodedbSupervisorBridge.CreateReconnectInFlightSnapshot(failedAttempt);

            Assert.That(
                noPriorSnapshot.CoordinatorFailureCategory,
                Is.EqualTo(AICodedbCoordinatorFailureCategory.NotEvaluated));
            Assert.That(
                legacyReconnect.CoordinatorFailureCategory,
                Is.EqualTo(AICodedbCoordinatorFailureCategory.NotEvaluated));
            Assert.That(
                unevaluatedReconnect.CoordinatorFailureCategory,
                Is.EqualTo(AICodedbCoordinatorFailureCategory.NotEvaluated));
            Assert.That(
                failedReconnect.ConnectionState,
                Is.EqualTo(AICodedbSupervisorConnectionState.Connecting));
            Assert.That(
                failedReconnect.CoordinatorFailureCategory,
                Is.EqualTo(AICodedbCoordinatorFailureCategory.NonzeroExit));
            Assert.That(failedReconnect.CoordinatorFailureCode, Is.EqualTo("NONZERO_EXIT"));
            Assert.That(
                failedReconnect.OperationalObservationId,
                Is.EqualTo(failedAttempt.OperationalObservationId));
            Assert.That(
                failedReconnect.OperationalObservationRevision,
                Is.EqualTo(failedAttempt.OperationalObservationRevision));
        }

        [Test]
        public void SupervisorProtocol_StatusHandshakeBlocksWrongProjectIdentity()
        {
            var root = _projectRoot;
            var wrongRoot = Path.Combine(_projectRoot, "OtherProject");
            Directory.CreateDirectory(Path.Combine(wrongRoot, "Assets"));
            Directory.CreateDirectory(Path.Combine(wrongRoot, "Packages"));
            Directory.CreateDirectory(Path.Combine(wrongRoot, "ProjectSettings"));
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var wrongRuntime = AICodedbControlContract.GetSupervisorRuntimePath(
                wrongRoot,
                contract.ControlContract);
            var response = SupervisorStatusResponse(
                wrongRoot,
                wrongRuntime,
                contract,
                "2026-08-25T00:00:00.0000000Z");

            var snapshot = AICodedbSupervisorBridge.ParseStatusResponse(
                response,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(snapshot.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
            Assert.That(snapshot.IsCoreReady, Is.False);
            Assert.That(snapshot.ReasonCode, Is.EqualTo("SUPERVISOR_IDENTITY_MISMATCH"));
        }

        [Test]
        public void LifecycleEvidence_CapturesBoundedCallbacksWorkAndContinuityFields()
        {
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);
            evidence.RecordCallback(AICodedbLifecycleCallbackKind.ManagerGui, 1);
            evidence.RecordWork(AICodedbLifecycleWorkKind.FileSystem, Thread.CurrentThread.ManagedThreadId);
            evidence.RecordDomainReload();
            evidence.RecordPlayTransition();
            evidence.RecordManagerObservation(AICodedbManagerObservationKind.CacheRead);

            var document = evidence.Capture("cold_start");

            Assert.That(document.schema_version, Is.EqualTo(1));
            Assert.That(document.callback_names, Does.Contain("ManagerGui"));
            Assert.That(document.callback_counts[(int)AICodedbLifecycleCallbackKind.ManagerGui], Is.EqualTo(1));
            Assert.That(document.main_thread_work_counts[(int)AICodedbLifecycleWorkKind.FileSystem], Is.EqualTo(1));
            Assert.That(document.domain_reload_count, Is.EqualTo(1));
            Assert.That(document.play_transition_count, Is.EqualTo(1));
            Assert.That(document.manager_cache_read_count, Is.EqualTo(1));
            Assert.That(document.checkpoint, Is.EqualTo("cold_start"));
        }

        [Test]
        public void LifecycleEvidence_CapturesManagerCloseAndQuittingTaskStateWithoutRawData()
        {
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);
            var entryQueue = new AICodedbSupervisorQueueSnapshot(
                2,
                true,
                AICodedbSupervisorRequestKind.Reconcile,
                7,
                3,
                false);
            var returnQueue = new AICodedbSupervisorQueueSnapshot(
                0,
                false,
                AICodedbSupervisorRequestKind.ObserveStatus,
                7,
                4,
                true);

            evidence.RecordManagerStatusRefreshStarted();
            evidence.RecordManagerClosed();
            evidence.RecordEditorQuittingBoundary(true, true, entryQueue);
            evidence.RecordManagerStatusRefreshFinished(
                AICodedbManagerStatusRefreshDisposition.Cancelled);
            evidence.RecordEditorQuittingBoundary(false, false, returnQueue);

            var document = evidence.Capture("quitting_boundary");

            Assert.That(document.manager_close_count, Is.EqualTo(1));
            Assert.That(document.manager_close_with_refresh_in_flight_count, Is.EqualTo(1));
            Assert.That(document.manager_status_refresh_started_count, Is.EqualTo(1));
            Assert.That(document.manager_status_refresh_completed_count, Is.EqualTo(0));
            Assert.That(document.manager_status_refresh_cancelled_count, Is.EqualTo(1));
            Assert.That(document.manager_status_refresh_failed_count, Is.EqualTo(0));
            Assert.That(document.manager_status_refresh_in_flight_count, Is.EqualTo(0));
            Assert.That(document.manager_status_refresh_max_in_flight_count, Is.EqualTo(1));
            Assert.That(document.editor_quitting_entry_count, Is.EqualTo(1));
            Assert.That(document.editor_quitting_return_count, Is.EqualTo(1));
            Assert.That(document.editor_quitting_entry_reconcile_in_flight, Is.EqualTo(1));
            Assert.That(document.editor_quitting_entry_manager_refresh_in_flight_count, Is.EqualTo(1));
            Assert.That(document.editor_quitting_entry_queue_pending_count, Is.EqualTo(2));
            Assert.That(document.editor_quitting_entry_queue_active, Is.EqualTo(1));
            Assert.That(document.editor_quitting_return_reconcile_in_flight, Is.EqualTo(0));
            Assert.That(document.editor_quitting_return_manager_refresh_in_flight_count, Is.EqualTo(0));
            Assert.That(document.editor_quitting_return_queue_pending_count, Is.EqualTo(0));
            Assert.That(document.editor_quitting_return_queue_active, Is.EqualTo(0));

            var restored = new AICodedbLifecycleEvidenceCounter(
                Thread.CurrentThread.ManagedThreadId);
            restored.Restore(document);
            var restoredDocument = restored.Capture("restored");
            Assert.That(restoredDocument.manager_close_count, Is.EqualTo(1));
            Assert.That(restoredDocument.manager_status_refresh_cancelled_count, Is.EqualTo(1));
            Assert.That(
                restoredDocument.manager_status_refresh_in_flight_count,
                Is.EqualTo(0),
                "A Domain Reload must not restore an in-memory Manager task as live.");
            Assert.That(restoredDocument.editor_quitting_entry_queue_pending_count, Is.EqualTo(2));
            Assert.That(restoredDocument.editor_quitting_return_queue_active, Is.EqualTo(0));
        }

        [Test]
        public void LifecycleEvidence_ShutdownDispositionUsesFixedVocabularyAndPreservesSnapshotObservation()
        {
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);
            Assert.That(evidence.Capture("initial").shutdown_disposition, Is.EqualTo("NOT_EVALUATED"));

            evidence.RecordShutdownDisposition(null);
            Assert.That(evidence.Capture("no_response").shutdown_disposition, Is.EqualTo("NO_RESPONSE"));

            evidence.RecordShutdownDisposition(CreateShutdownResponse(true, string.Empty));
            Assert.That(evidence.Capture("succeeded").shutdown_disposition, Is.EqualTo("SUCCEEDED"));

            evidence.RecordShutdownDisposition(CreateShutdownResponse(false, string.Empty));
            Assert.That(evidence.Capture("failed").shutdown_disposition, Is.EqualTo("FAILED"));

            var snapshot = AICodedbSupervisorSnapshot.Connected(
                2,
                123,
                "unity-bridge",
                "runtime",
                "ready",
                string.Empty,
                "ready",
                "ready",
                "RUNNING",
                "ONLINE",
                AICodedbSupervisorReadinessState.CoreReady,
                "READY",
                "fixture",
                "fixture_event",
                AICodedbSupervisorProtocol.SupervisorStateSchemaVersion,
                "poc.34",
                "poc.34",
                new string('a', 64),
                "CURRENT",
                456,
                "0123456789abcdef0123456789abcdef");
            evidence.RecordShutdownDisposition(
                CreateShutdownResponse(true, "FUTURE_VALID_SUPERVISOR_ERROR", snapshot));
            var supervisorError = evidence.Capture("supervisor_error");

            Assert.That(supervisorError.shutdown_disposition, Is.EqualTo("SUPERVISOR_ERROR"));
            Assert.That(supervisorError.supervisor_observation_count, Is.EqualTo(1));
            Assert.That(supervisorError.supervisor_pid, Is.EqualTo(456));
        }

        [TestCase("NOT_EVALUATED")]
        [TestCase("NO_RESPONSE")]
        [TestCase("SUCCEEDED")]
        [TestCase("FAILED")]
        [TestCase("SUPERVISOR_ERROR")]
        public void LifecycleEvidence_ShutdownDispositionRoundTripsFixedVocabulary(string disposition)
        {
            var document = new AICodedbLifecycleEvidenceDocument
            {
                shutdown_disposition = disposition
            };
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);

            evidence.Restore(document);

            Assert.That(evidence.Capture("restored").shutdown_disposition, Is.EqualTo(disposition));
        }

        [Test]
        public void LifecycleEvidence_ShutdownDispositionRestoreRejectsUnknownBoundedCode()
        {
            var document = new AICodedbLifecycleEvidenceDocument
            {
                shutdown_disposition = "FUTURE_VALID_SUPERVISOR_ERROR"
            };
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);

            evidence.Restore(document);

            Assert.That(
                evidence.Capture("restored").shutdown_disposition,
                Is.EqualTo("NOT_EVALUATED"));
        }

        [Test]
        public void LifecycleEvidence_PostAdmissionFieldsAreEnumBoundedAndRestoreSafely()
        {
            var evidence = new AICodedbLifecycleEvidenceCounter(Thread.CurrentThread.ManagedThreadId);
            evidence.RecordPostAdmissionDisposition(
                AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.ConvergenceBlocked);
            evidence.RecordPostAdmissionProductLayers(
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Unavailable);
            evidence.RecordCurrentInstanceState(AICodedbCurrentInstanceState.Current);
            evidence.RecordCurrentInstanceConvergencePlan(
                AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked);

            var document = evidence.Capture("post_admission");

            Assert.That(document.post_admission_disposition, Is.EqualTo("ConvergenceBlocked"));
            Assert.That(document.post_admission_prerequisite_state, Is.EqualTo("Current"));
            Assert.That(document.post_admission_installed_state, Is.EqualTo("Current"));
            Assert.That(document.post_admission_configured_state, Is.EqualTo("Current"));
            Assert.That(document.post_admission_mcp_available_state, Is.EqualTo("Unavailable"));
            Assert.That(document.current_instance_state, Is.EqualTo("Current"));
            Assert.That(document.current_instance_convergence_plan, Is.EqualTo("Blocked"));

            var legacyEvidence = new AICodedbLifecycleEvidenceCounter(
                Thread.CurrentThread.ManagedThreadId);
            legacyEvidence.Restore(new AICodedbLifecycleEvidenceDocument());
            var legacyDocument = legacyEvidence.Capture("legacy");
            AssertPostAdmissionEvidenceNotEvaluated(legacyDocument);

            document.post_admission_disposition = "C:\\machine\\detail";
            document.post_admission_prerequisite_state = "raw detail";
            document.post_admission_installed_state = "stdout/stderr";
            document.post_admission_configured_state = "token=value";
            document.post_admission_mcp_available_state = "UNKNOWN_VALUE";
            document.current_instance_state = "project/path";
            document.current_instance_convergence_plan = "Deploy --force";
            evidence.Restore(document);
            AssertPostAdmissionEvidenceNotEvaluated(evidence.Capture("invalid"));
        }

        [TestCase(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Retire,
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.RetirementSelected)]
        [TestCase(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Deploy,
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.DeploymentSelected)]
        [TestCase(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability,
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.AvailabilityRecoverySelected)]
        [TestCase(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked,
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.ConvergenceBlocked)]
        [TestCase(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.None,
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition.ConvergenceComplete)]
        public void PostAdmissionConvergenceDisposition_MapsExistingPlanWithoutChangingIt(
            AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan plan,
            AICodedbEditorLifecycle.AICodedbPostAdmissionDisposition expected)
        {
            var originalPlan = plan;
            var actual = AICodedbEditorLifecycle.ResolvePostAdmissionConvergenceDisposition(plan);

            Assert.That(plan, Is.EqualTo(originalPlan));
            Assert.That(actual, Is.EqualTo(expected));
        }

        private static void AssertPostAdmissionEvidenceNotEvaluated(
            AICodedbLifecycleEvidenceDocument document)
        {
            Assert.That(document.post_admission_disposition, Is.EqualTo("NotEvaluated"));
            Assert.That(document.post_admission_prerequisite_state, Is.EqualTo("NotEvaluated"));
            Assert.That(document.post_admission_installed_state, Is.EqualTo("NotEvaluated"));
            Assert.That(document.post_admission_configured_state, Is.EqualTo("NotEvaluated"));
            Assert.That(document.post_admission_mcp_available_state, Is.EqualTo("NotEvaluated"));
            Assert.That(document.current_instance_state, Is.EqualTo("NotEvaluated"));
            Assert.That(document.current_instance_convergence_plan, Is.EqualTo("NotEvaluated"));
        }

        private static AICodedbSupervisorCommandResponse CreateShutdownResponse(
            bool succeeded,
            string errorCode,
            AICodedbSupervisorSnapshot snapshot = null)
        {
            return new AICodedbSupervisorCommandResponse(
                succeeded,
                succeeded ? 0 : 4,
                errorCode,
                string.Empty,
                string.Empty,
                string.Empty,
                snapshot,
                string.Empty,
                0);
        }

        [Test]
        public void SupervisorProtocol_ReadsBoundedUtf8StatusLines()
        {
            using (var reader = new StringReader("{\"ok\":true}\r\nnext"))
            {
                Assert.That(
                    AICodedbSupervisorBridge.ReadBoundedLine(
                        reader,
                        CancellationToken.None),
                    Is.EqualTo("{\"ok\":true}"));
            }

            var oversized = new string('x', AICodedbSupervisorProtocol.MaximumMessageBytes + 1);
            using (var reader = new StringReader(oversized))
            {
                Assert.That(
                    () => AICodedbSupervisorBridge.ReadBoundedLine(
                        reader,
                        CancellationToken.None),
                    Throws.InstanceOf<InvalidOperationException>());
            }
        }

        [Test]
        public void SupervisorBridge_ExchangesMessageWithoutStreamTimeoutProperties()
        {
            var pipeName = "codedb-supervisor-test-" + Guid.NewGuid().ToString("N");
            using (var server = new NamedPipeServerStream(
                       pipeName,
                       PipeDirection.InOut,
                       1,
                       PipeTransmissionMode.Byte,
                       PipeOptions.Asynchronous))
            {
                var serverTask = Task.Run(async () =>
                {
                    await server.WaitForConnectionAsync();
                    using (var reader = new StreamReader(
                               server,
                               new UTF8Encoding(false, true),
                               false,
                               4096,
                               true))
                    {
                        var request = await reader.ReadLineAsync();
                        Assert.That(request, Is.EqualTo("{\"command\":\"status\"}"));
                        var response = new UTF8Encoding(false).GetBytes("{\"ok\":true}\n");
                        await server.WriteAsync(response, 0, response.Length);
                        await server.FlushAsync();
                    }
                });

                var response = AICodedbSupervisorBridge.SendPipeRequest(
                    pipeName,
                    "{\"command\":\"status\"}",
                    CancellationToken.None);
                serverTask.GetAwaiter().GetResult();

                Assert.That(response, Is.EqualTo("{\"ok\":true}"));
            }
        }

        [Test]
        public void SupervisorProtocol_OperationalAuthorityDoesNotRecomputeProviderHandshake()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(root, runtime, contract, null);

            var snapshot = AICodedbSupervisorBridge.ParseStatusResponse(
                response,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(snapshot.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.CoreReady));
            Assert.That(snapshot.ReasonCode, Is.EqualTo("COORDINATOR_OPERATIONAL"));
            Assert.That(snapshot.IsCoreReady, Is.True);
        }

        [Test]
        public void SupervisorProtocol_MaintenanceLaneDoesNotReplaceOperationalAuthority()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(
                    root,
                    runtime,
                    contract,
                    "2026-08-26T00:00:00.0000000Z")
                .Replace(
                    "\"last_event\":\"provider_ready\"",
                    "\"readiness_state\":\"maintenance\","
                    + "\"reason_code\":\"SUPERVISOR_MAINTENANCE\","
                    + "\"detail\":\"Supervisor operation materialize:Probe is running.\","
                    + "\"last_event\":\"operation_started\"");

            var snapshot = AICodedbSupervisorBridge.ParseStatusResponse(
                response,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(snapshot.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.CoreReady));
            Assert.That(snapshot.IsCoreReady, Is.True);
            Assert.That(snapshot.ReasonCode, Is.EqualTo("COORDINATOR_OPERATIONAL"));
        }

        [Test]
        public void SupervisorProtocol_LegacyCommandModelCannotMasqueradeAsCurrent()
        {
            var root = _projectRoot;
            var contract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                root,
                contract.ControlContract);
            var response = SupervisorStatusResponse(
                    root,
                    runtime,
                    contract,
                    "2026-08-26T00:00:00.0000000Z")
                .Replace(
                    "\"supervisor_protocol_version\":" + AICodedbSupervisorProtocol.SupervisorVersion,
                    "\"supervisor_protocol_version\":" + AICodedbSupervisorProtocol.LegacySupervisorVersion);

            var snapshot = AICodedbSupervisorBridge.ParseStatusResponse(
                response,
                root,
                contract.Target.GenerationId,
                contract.Target.GenerationId,
                contract.Sha256,
                "CURRENT",
                runtime);

            Assert.That(snapshot.ReadinessState, Is.EqualTo(AICodedbSupervisorReadinessState.Blocked));
            Assert.That(snapshot.ReasonCode, Is.EqualTo("PROTOCOL_MISMATCH"));
        }

        [Test]
        public void SupervisorProtocol_LegacyHandoffWaitsForAdmittedMaintenance()
        {
            var legacyRuntime = AICodedbControlContract.GetLegacySupervisorRuntimePath(_projectRoot);
            var statePath = Path.Combine(
                legacyRuntime,
                "legacy-drain-state.json");
            Directory.CreateDirectory(Path.GetDirectoryName(statePath));
            WriteUtf8NoBom(
                statePath,
                "{\"operation\":{\"name\":\"materialize:Probe\",\"state\":\"running\"}}");

            Assert.That(
                AICodedbSupervisorBridge.WaitForLegacySupervisorIdle(
                    _projectRoot,
                    statePath,
                    0,
                    CancellationToken.None),
                Is.False,
                "Protocol handoff must not retire a Supervisor with admitted maintenance still running.");

            WriteUtf8NoBom(
                statePath,
                "{\"operation\":{\"name\":\"materialize:Probe\",\"state\":\"completed\"}}");
            Assert.That(
                AICodedbSupervisorBridge.WaitForLegacySupervisorIdle(
                    _projectRoot,
                    statePath,
                    0,
                    CancellationToken.None),
                Is.True);
        }

        [TestCase(false, true, ExpectedResult = true)]
        [TestCase(true, true, ExpectedResult = false)]
        [TestCase(false, false, ExpectedResult = false)]
        public bool SupervisorProtocol_ReconnectReusesOnlyNonForcedInFlightWork(
            bool force,
            bool inFlight)
        {
            return AICodedbSupervisorProtocol.ShouldReuseReconnect(force, inFlight);
        }

        [TestCase(true, false, ExpectedResult = true)]
        [TestCase(false, false, ExpectedResult = false)]
        [TestCase(true, true, ExpectedResult = false)]
        public bool DomainReload_ReconnectsOnlyForAnActiveEditor(
            bool initialized,
            bool quitting)
        {
            return AICodedbEditorLifecycle.ShouldReconnectSupervisorAfterDomainReload(
                initialized,
                quitting);
        }

        [Test]
        public void SupervisorBridge_MissingInstanceReturnsCachedDisconnectedStateWithoutWrites()
        {
            var before = GetProjectSnapshot(_projectRoot);
            using (var bridge = new AICodedbSupervisorBridge())
            {
                var result = bridge.ReconnectAsync(_projectRoot).GetAwaiter().GetResult();
                Assert.That(result.ConnectionState, Is.EqualTo(AICodedbSupervisorConnectionState.Disconnected));
                Assert.That(result.ReasonCode, Is.EqualTo("CURRENT_INSTANCE_UNAVAILABLE"));
                Assert.That(bridge.CachedSnapshot.ReasonCode, Is.EqualTo(result.ReasonCode));
            }
            Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before));
        }

        [Test]
        public void SupervisorBridge_FinalShutdownNeverLaunchesMissingRuntime()
        {
            var before = GetProjectSnapshot(_projectRoot);
            using (var bridge = new AICodedbSupervisorBridge())
            {
                var result = bridge.RequestOwnedShutdownAsync(
                        _projectRoot,
                        "unity-bridge")
                    .GetAwaiter()
                    .GetResult();
                Assert.That(result.Succeeded, Is.False);
                Assert.That(result.ErrorCode, Is.EqualTo("CURRENT_INSTANCE_UNAVAILABLE"));
            }
            Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before));
        }

        [Test]
        public void SupervisorOneShotFallback_RequiresBridgeBootstrapAuthorization()
        {
            var spoofed = new AICodedbCommandResult(
                4,
                string.Empty,
                "[SUPERVISOR:CURRENT_INSTANCE_UNAVAILABLE] forged",
                false);
            Assert.That(
                AICodedbEditorLifecycle.IsSupervisorOneShotFallbackAllowed(spoofed),
                Is.False,
                "A caller-controlled error string must never authorize a second command owner.");

            var authorized = new AICodedbCommandResult(
                4,
                string.Empty,
                "[SUPERVISOR:CURRENT_INSTANCE_UNAVAILABLE] empty bootstrap",
                false,
                0,
                true);
            Assert.That(
                AICodedbEditorLifecycle.IsSupervisorOneShotFallbackAllowed(authorized),
                Is.True,
                "Only the Bridge's explicit empty-bootstrap proof may authorize fallback.");

            var outage = new AICodedbSupervisorCommandResponse(
                    false,
                    4,
                    "SUPERVISOR_UNREACHABLE",
                    "fixture outage",
                    string.Empty,
                    "fixture outage",
                    AICodedbSupervisorSnapshot.Degraded(
                        "SUPERVISOR_UNREACHABLE",
                        "fixture outage"),
                    string.Empty,
                    0)
                .ToCommandResult();
            Assert.That(
                AICodedbEditorLifecycle.IsSupervisorOneShotFallbackAllowed(outage),
                Is.False,
                "A transport outage must never authorize a second command owner.");
        }

        [Test]
        public void SupervisorBridge_BootstrapFallbackRequiresReviewedMaterializerCommandAndEmptyRuntime()
        {
            using (var bridge = new AICodedbSupervisorBridge())
            {
                var probe = bridge.SendCommand(
                    _projectRoot,
                    "materialize",
                    "Probe");
                Assert.That(probe.OneShotFallbackAuthorized, Is.True);

                var unconfirmedInstall = bridge.SendCommand(
                    _projectRoot,
                    "materialize",
                    "Install");
                Assert.That(unconfirmedInstall.OneShotFallbackAuthorized, Is.False);

                var confirmedInstall = bridge.SendCommand(
                    _projectRoot,
                    "materialize",
                    "Install",
                    null,
                    true);
                Assert.That(confirmedInstall.OneShotFallbackAuthorized, Is.True);

                var unconfirmedReinstall = bridge.SendCommand(
                    _projectRoot,
                    "materialize",
                    "Reinstall");
                Assert.That(unconfirmedReinstall.OneShotFallbackAuthorized, Is.False);

                var confirmedReinstall = bridge.SendCommand(
                    _projectRoot,
                    "materialize",
                    "Reinstall",
                    null,
                    true);
                Assert.That(confirmedReinstall.OneShotFallbackAuthorized, Is.True);

                var watcher = bridge.SendCommand(
                    _projectRoot,
                    "watcher",
                    "Ensure");
                Assert.That(watcher.OneShotFallbackAuthorized, Is.False);

                var shutdown = bridge.RequestOwnedShutdownAsync(
                        _projectRoot,
                        "unity-bridge")
                    .GetAwaiter()
                    .GetResult();
                Assert.That(shutdown.OneShotFallbackAuthorized, Is.False);

                var runtime = AICodedbSupervisorLauncher.GetSupervisorRuntimePath(_projectRoot);
                Directory.CreateDirectory(runtime);
                Assert.That(
                    bridge.SendCommand(_projectRoot, "materialize", "Probe")
                        .OneShotFallbackAuthorized,
                    Is.True,
                    "An empty reviewed runtime remains a bootstrap case.");

                WriteUtf8NoBom(Path.Combine(runtime, "operation.json"), "{}");
                Assert.That(
                    bridge.SendCommand(_projectRoot, "materialize", "Probe")
                        .OneShotFallbackAuthorized,
                    Is.False,
                    "Any control evidence must close fallback until ownership is classified.");
            }
        }

        [Test]
        public void SupervisorLauncher_UsesProjectControlSupervisorRuntime()
        {
            var runtimeContract = ReadPackageRuntimeContract();
            Assert.That(
                AICodedbSupervisorLauncher.GetSupervisorStatePath(_projectRoot),
                Is.EqualTo(AICodedbPaths.NormalizePath(Path.Combine(
                    AICodedbControlContract.GetSupervisorRuntimePath(
                        _projectRoot,
                        runtimeContract.ControlContract),
                    "supervisor-state.json"))));
        }

        [Test]
        public void SupervisorLauncher_ValidatesExternalPackageAgainstItsOwnRoot()
        {
            var packageRoot = _projectRoot + "-package";
            var unrelatedRoot = _projectRoot + "-unrelated";
            var supervisorScript = Path.Combine(
                packageRoot,
                "Tools~",
                "codedb-project-supervisor.mjs");
            var unrelatedScript = Path.Combine(
                unrelatedRoot,
                "codedb-project-supervisor.mjs");
            var runtimeContract = ReadPackageRuntimeContract();
            var runtime = AICodedbControlContract.GetSupervisorRuntimePath(
                _projectRoot,
                runtimeContract.ControlContract);
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(supervisorScript));
                Directory.CreateDirectory(unrelatedRoot);
                File.WriteAllText(supervisorScript, "// fixture");
                File.WriteAllText(unrelatedScript, "// fixture");

                Assert.DoesNotThrow(() => AICodedbSupervisorLauncher.ValidateLaunchRoots(
                    _projectRoot,
                    packageRoot,
                    runtime,
                    supervisorScript));
                Assert.Throws<InvalidOperationException>(() =>
                    AICodedbSupervisorLauncher.ValidateLaunchRoots(
                        _projectRoot,
                        packageRoot,
                        runtime,
                        unrelatedScript));
            }
            finally
            {
                if (Directory.Exists(packageRoot))
                    Directory.Delete(packageRoot, true);
                if (Directory.Exists(unrelatedRoot))
                    Directory.Delete(unrelatedRoot, true);
            }
        }

        [Test]
        public void PlayModeHandoff_UsesExplicitProjectRootBeforeLifecycleIdentityIsReady()
        {
            AICodedbEditorLifecycle.ClearProductStateForPlayMode(_projectRoot);

            AICodedbEditorLifecycle.RecordProductStateForPlayMode(
                _projectRoot,
                AICodedbProductState.Ready);
            AICodedbEditorLifecycle.RecordVerifiedReadyForCurrentPackage(_projectRoot);

            AICodedbProductState state;
            Assert.That(
                AICodedbEditorLifecycle.TryGetProductStateForPlayMode(
                    _projectRoot,
                    out state),
                Is.True);
            Assert.That(state, Is.EqualTo(AICodedbProductState.Ready));
            Assert.That(
                AICodedbEditorLifecycle.HasVerifiedReadyForCurrentPackage(_projectRoot),
                Is.True);

            // A transient Starting callback must not overwrite stronger Ready
            // evidence immediately before a domain reload.
            AICodedbEditorLifecycle.RecordProductStateForPlayMode(
                _projectRoot,
                AICodedbProductState.Starting);
            Assert.That(
                AICodedbEditorLifecycle.TryGetProductStateForPlayMode(
                    _projectRoot,
                    out state),
                Is.True);
            Assert.That(state, Is.EqualTo(AICodedbProductState.Ready));

            AICodedbEditorLifecycle.ClearProductStateForPlayMode(_projectRoot);
            Assert.That(
                AICodedbEditorLifecycle.TryGetProductStateForPlayMode(
                    _projectRoot,
                    out state),
                Is.True,
                "Verified Ready evidence remains usable when the temporary Play handoff key is cleared.");
            Assert.That(state, Is.EqualTo(AICodedbProductState.Ready));
        }

        [Test]
        public void PersistedProductState_ProvidesDisplayOnlyReadyHint()
        {
            var publishedIdentity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            AICodedbEditorLifecycle.RecordVerifiedReadyForCurrentPackage(_projectRoot);

            AICodedbProductState state;
            Assert.That(
                AICodedbEditorLifecycle.TryGetPersistedProductState(
                    _projectRoot,
                    _projectRoot,
                    publishedIdentity,
                    out state),
                Is.True);
            Assert.That(state, Is.EqualTo(AICodedbProductState.Ready));
        }

        [Test]
        public void PersistedProductState_DisplayLookupRequiresPublishedMatchingIdentity()
        {
            var publishedIdentity = "sha256:" + new string('a', 64);
            string selectedIdentity;
            AICodedbProductState state;

            Assert.That(
                AICodedbEditorLifecycle.TryGetPersistedProductState(
                    _projectRoot,
                    _projectRoot,
                    string.Empty,
                    out state),
                Is.False,
                "Manager restoration must return a bounded miss until the worker publishes identity.");
            Assert.That(state, Is.EqualTo(AICodedbProductState.Starting));

            Assert.That(
                AICodedbEditorLifecycle.TryGetPublishedProjectIdentityForDisplay(
                    _projectRoot,
                    _projectRoot,
                    string.Empty,
                    out selectedIdentity),
                Is.False,
                "Manager restoration must return a cache miss until the worker publishes identity.");
            Assert.That(selectedIdentity, Is.Empty);

            Assert.That(
                AICodedbEditorLifecycle.TryGetPublishedProjectIdentityForDisplay(
                    _projectRoot,
                    Path.Combine(_projectRoot, "OtherProject"),
                    publishedIdentity,
                    out selectedIdentity),
                Is.False,
                "A published identity for another project must not be reused.");
            Assert.That(selectedIdentity, Is.Empty);

            Assert.That(
                AICodedbEditorLifecycle.TryGetPublishedProjectIdentityForDisplay(
                    _projectRoot + Path.DirectorySeparatorChar,
                    _projectRoot,
                    publishedIdentity,
                    out selectedIdentity),
                Is.True);
            Assert.That(selectedIdentity, Is.EqualTo(publishedIdentity));
        }

        [Test]
        public void PersistedProductState_SourceDoesNotDeriveIdentityForDisplayLookup()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbEditorLifecycle.cs"));
            var start = source.IndexOf(
                "internal static bool TryGetPersistedProductState(",
                StringComparison.Ordinal);
            var end = source.IndexOf(
                "private static AICodedbCommandResult RememberHostStatusResult(",
                start,
                StringComparison.Ordinal);

            Assert.That(start, Is.GreaterThanOrEqualTo(0));
            Assert.That(end, Is.GreaterThan(start));
            var body = source.Substring(start, end - start);
            Assert.That(body, Does.Contain("state = AICodedbProductState.Starting"));
            Assert.That(body, Does.Contain("TryGetPublishedProjectIdentityForDisplay("));
            Assert.That(body, Does.Contain("HasVerifiedReadyForPublishedProjectIdentity(projectIdentity)"));
            Assert.That(body, Does.Not.Contain("TryResolveProjectIdentity("));
            Assert.That(body, Does.Not.Contain("CreateProjectIdentity"));
            Assert.That(body, Does.Not.Contain("AICodedbLifecycleWorkKind.Hash"));
        }

        [TestCase("NODE_MISSING")]
        [TestCase("PROVIDER_MISSING")]
        [TestCase("PROVIDER_INVALID")]
        [TestCase("PROVIDER_HASH_MISMATCH")]
        public void MissingPrerequisite_InitializationAndHeartbeatPreserveWholeProject(
            string reasonCode)
        {
            var integrationStatus = AICodedbProjectIntegrationStateStore.Read(_projectRoot);
            var productStatus = new AICodedbProductStatus(
                AICodedbProductState.MissingPrerequisite,
                AICodedbProductLayerState.Missing,
                AICodedbProductLayerState.Unknown,
                AICodedbProductLayerState.Unknown,
                AICodedbProductLayerState.Unknown,
                reasonCode);
            var leasePath = Path.Combine(
                _projectRoot,
                "AIWork",
                ".runtime",
                "codedb",
                "fixture",
                "watch",
                "lifecycle",
                "editor-leases",
                "session.json");
            var before = GetProjectSnapshot(_projectRoot);
            var refreshCount = 0;

            for (var lifecyclePass = 0; lifecyclePass < 2; lifecyclePass++)
            {
                Assert.That(
                    AICodedbEditorLifecycle.ApplyPrerequisiteGatedLeaseRefresh(
                        integrationStatus,
                        productStatus,
                        () =>
                        {
                            refreshCount++;
                            Directory.CreateDirectory(Path.GetDirectoryName(leasePath));
                            File.WriteAllText(leasePath, "unexpected lease write");
                        }),
                    Is.False);
            }

            Assert.That(refreshCount, Is.Zero);
            Assert.That(File.Exists(leasePath), Is.False);
            Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before));
        }

        [TestCase("NODE_MISSING")]
        [TestCase("PROVIDER_MISSING")]
        [TestCase("PROVIDER_INVALID")]
        [TestCase("PROVIDER_HASH_MISMATCH")]
        public void MissingPrerequisite_RealEditorStatusPathRechecksOnceWithoutEarlyProjectWrites(
            string reasonCode)
        {
            WriteUtf8NoBom(
                Path.Combine(_projectRoot, "Packages", "manifest.json"),
                "{\"dependencies\":{}}\n");
            WriteUtf8NoBom(
                Path.Combine(_projectRoot, "ProjectSettings", "ProjectVersion.txt"),
                "m_EditorVersion: 2022.3.47f1\n"
                + "m_EditorVersionWithRevision: 2022.3.47f1 (88c277b85d21)\n");
            var originalPath = Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Process);
            var originalLocalAppData = Environment.GetEnvironmentVariable(
                "LOCALAPPDATA",
                EnvironmentVariableTarget.Process);
            var nodePath = FindExecutableOnPath("node.exe", originalPath);
            Assert.That(nodePath, Is.Not.Empty, "The lifecycle prerequisite fixture requires supported Node.js on PATH.");

            var machineRoot = Path.Combine(
                Path.GetTempPath(),
                "Rice-AICodedb-Prerequisite-Lifecycle-Tests",
                Guid.NewGuid().ToString("N"));
            var providerRoot = Path.Combine(machineRoot, "Rice", "CodeDB", "providers", "0.5.0-28e3912");
            var providerManifestPath = Path.Combine(providerRoot, "provider-manifest.json");
            var providerExecutablePath = Path.Combine(providerRoot, "codebase-mcp.exe");
            var windowsRoot = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            var pathWithoutNode = Path.Combine(
                                      windowsRoot,
                                      "System32",
                                      "WindowsPowerShell",
                                      "v1.0")
                                  + Path.PathSeparator
                                  + Environment.SystemDirectory;
            var leasePath = Path.Combine(
                _projectRoot,
                "AIWork",
                ".runtime",
                "codedb",
                "fixture",
                "watch",
                "lifecycle",
                "editor-leases",
                "session.json");

            try
            {
                Directory.CreateDirectory(machineRoot);
                Environment.SetEnvironmentVariable(
                    "LOCALAPPDATA",
                    machineRoot,
                    EnvironmentVariableTarget.Process);
                Environment.SetEnvironmentVariable(
                    "PATH",
                    string.Equals(reasonCode, "NODE_MISSING", StringComparison.Ordinal)
                        ? pathWithoutNode
                        : originalPath,
                    EnvironmentVariableTarget.Process);

                if (string.Equals(reasonCode, "NODE_MISSING", StringComparison.Ordinal))
                {
                    WriteProviderFixture(providerRoot, false, false);
                }
                else if (string.Equals(reasonCode, "PROVIDER_INVALID", StringComparison.Ordinal))
                {
                    WriteProviderFixture(providerRoot, true, false);
                }
                else if (string.Equals(reasonCode, "PROVIDER_HASH_MISMATCH", StringComparison.Ordinal))
                {
                    WriteProviderFixture(providerRoot, false, true);
                }

                var context = new AICodedbEditorExecutionContext(
                    UnityEngine.RuntimePlatform.WindowsEditor,
                    _projectRoot,
                    AICodedbPaths.PackageRootPath,
                    new DirectoryInfo(_projectRoot).Name);
                Assert.That(
                    AICodedbPaths.GetMachineProviderExecutablePath(),
                    Is.EqualTo(AICodedbPaths.NormalizePath(providerExecutablePath)),
                    "Editor prerequisite evidence must use the same %LOCALAPPDATA% Provider root as the materializer.");
                var integrationStatus = AICodedbProjectIntegrationStateStore.Read(_projectRoot);
                var initialFingerprint = AICodedbEditorLifecycle.CreateMachinePrerequisiteEvidenceFingerprint(
                    Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Process),
                    string.Empty,
                    string.Empty,
                    providerManifestPath,
                    providerExecutablePath);
                var before = GetProjectSnapshot(_projectRoot);

                var initialResult = AICodedbHostPayloadMaterializer.ReadStatus(context);
                Assert.That(initialResult.ExitCode, Is.Zero, initialResult.StandardError);
                Assert.That(initialResult.StandardOutput, Does.Contain("[REASON_CODE] " + reasonCode));
                var initialProductStatus = AICodedbProductStatusBuilder.Build(
                    integrationStatus,
                    initialResult);
                Assert.That(initialProductStatus.State, Is.EqualTo(AICodedbProductState.MissingPrerequisite));
                Assert.That(
                    AICodedbEditorLifecycle.ApplyPrerequisiteGatedLeaseRefresh(
                        integrationStatus,
                        initialProductStatus,
                        () => WriteUtf8NoBom(leasePath, "unexpected initialization lease write")),
                    Is.False);

                Assert.That(
                    AICodedbEditorLifecycle.ShouldRefreshEditorLease(false, false, false),
                    Is.False,
                    "The first missing-prerequisite heartbeat must not publish or refresh a lease.");
                Assert.That(
                    AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(
                        initialFingerprint,
                        initialFingerprint),
                    Is.False,
                    "Unchanged machine evidence must not start a periodic PowerShell retry loop.");
                Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before));

                Environment.SetEnvironmentVariable(
                    "PATH",
                    originalPath,
                    EnvironmentVariableTarget.Process);
                WriteProviderFixture(providerRoot, false, false);
                var suppliedFingerprint = AICodedbEditorLifecycle.CreateMachinePrerequisiteEvidenceFingerprint(
                    Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Process),
                    string.Empty,
                    string.Empty,
                    providerManifestPath,
                    providerExecutablePath);
                Assert.That(
                    AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(
                        initialFingerprint,
                        suppliedFingerprint),
                    Is.True);

                var recheckCount = 0;
                var suppliedResult = AICodedbHostPayloadMaterializer.ReadStatus(context);
                recheckCount++;
                Assert.That(suppliedResult.ExitCode, Is.Zero, suppliedResult.StandardError);
                var suppliedProductStatus = AICodedbProductStatusBuilder.Build(
                    integrationStatus,
                    suppliedResult);
                Assert.That(
                    suppliedProductStatus.Prerequisite,
                    Is.EqualTo(AICodedbProductLayerState.Current));
                Assert.That(
                    AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(
                        suppliedFingerprint,
                        suppliedFingerprint),
                    Is.False);

                var leaseRefreshCount = 0;
                Assert.That(
                    AICodedbEditorLifecycle.ApplyPrerequisiteGatedLeaseRefresh(
                        integrationStatus,
                        suppliedProductStatus,
                        () =>
                        {
                            leaseRefreshCount++;
                            Directory.CreateDirectory(Path.GetDirectoryName(leasePath));
                            WriteUtf8NoBom(leasePath, "fixture lease after prerequisite recovery");
                        }),
                    Is.True,
                    "Supplying the prerequisite must reopen the normal convergence lease gate.");
                Assert.That(recheckCount, Is.EqualTo(1));
                Assert.That(leaseRefreshCount, Is.EqualTo(1));
                Assert.That(File.Exists(leasePath), Is.True);
            }
            finally
            {
                Environment.SetEnvironmentVariable(
                    "PATH",
                    originalPath,
                    EnvironmentVariableTarget.Process);
                Environment.SetEnvironmentVariable(
                    "LOCALAPPDATA",
                    originalLocalAppData,
                    EnvironmentVariableTarget.Process);
                if (Directory.Exists(machineRoot))
                    Directory.Delete(machineRoot, true);
            }
        }

        [Test]
        public void CurrentPrerequisite_AllowsOneEditorLeaseRefresh()
        {
            var integrationStatus = AICodedbProjectIntegrationStateStore.Read(_projectRoot);
            var productStatus = new AICodedbProductStatus(
                AICodedbProductState.Starting,
                AICodedbProductLayerState.Current,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                "Prerequisites are current.");
            var refreshCount = 0;

            Assert.That(
                AICodedbEditorLifecycle.ApplyPrerequisiteGatedLeaseRefresh(
                    integrationStatus,
                    productStatus,
                    () => refreshCount++),
                Is.True);
            Assert.That(refreshCount, Is.EqualTo(1));
        }

        [Test]
        public void MissingPrerequisite_EvidenceChangeTriggersOneControlledRecheck()
        {
            var providerRoot = Path.Combine(_projectRoot, "machine-provider");
            var manifestPath = Path.Combine(providerRoot, "provider-manifest.json");
            var executablePath = Path.Combine(providerRoot, "codebase-mcp.exe");
            var missing = AICodedbEditorLifecycle.CreateMachinePrerequisiteEvidenceFingerprint(
                "process-path",
                "user-path",
                "machine-path",
                manifestPath,
                executablePath);
            var unchanged = AICodedbEditorLifecycle.CreateMachinePrerequisiteEvidenceFingerprint(
                "process-path",
                "user-path",
                "machine-path",
                manifestPath,
                executablePath);
            Assert.That(
                AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(missing, unchanged),
                Is.False);

            Directory.CreateDirectory(providerRoot);
            File.WriteAllText(manifestPath, "fixture manifest");
            File.WriteAllText(executablePath, "fixture executable");
            var supplied = AICodedbEditorLifecycle.CreateMachinePrerequisiteEvidenceFingerprint(
                "process-path",
                "user-path",
                "machine-path",
                manifestPath,
                executablePath);
            Assert.That(
                AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(missing, supplied),
                Is.True);
            Assert.That(
                AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(supplied, supplied),
                Is.False,
                "Unchanged machine evidence must not start a five-second PowerShell retry loop.");

            var syntheticWindowsPath = Path.Combine(
                "C:" + Path.DirectorySeparatorChar,
                "Windows",
                "System32");
            var syntheticNodePath = Path.Combine(
                "F:" + Path.DirectorySeparatorChar,
                "Program",
                "nodejs");
            var mergedPath = AICodedbEditorLifecycle.MergePrerequisitePathEvidence(
                syntheticWindowsPath,
                syntheticNodePath,
                syntheticWindowsPath + Path.PathSeparator + syntheticNodePath);
            Assert.That(
                mergedPath.Split(Path.PathSeparator),
                Is.EqualTo(new[] { syntheticWindowsPath, syntheticNodePath }),
                "The controlled recheck must merge newly installed Node PATH evidence without duplicates.");
        }

        [Test]
        public void ProjectIntegrationState_ValidUnicodeRootSuppressesLeaseAndRunsCleanup()
        {
            var unicodeRoot = Path.Combine(_projectRoot, "中文工程");
            Directory.CreateDirectory(Path.Combine(unicodeRoot, "Assets"));
            Directory.CreateDirectory(Path.Combine(unicodeRoot, "Packages"));
            Directory.CreateDirectory(Path.Combine(unicodeRoot, "ProjectSettings"));
            var statePath = Path.Combine(
                unicodeRoot,
                AICodedbProjectSettings.ProjectIntegrationStateRelativePath);
            WriteIntegrationState(unicodeRoot, statePath);

            var status = AICodedbProjectIntegrationStateStore.Read(unicodeRoot, statePath);

            Assert.That(status.State, Is.EqualTo(AICodedbProjectIntegrationState.Uninstalled));
            Assert.That(status.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Pending));
            Assert.That(AICodedbEditorLifecycle.ShouldPublishEditorLease(status), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticUninstallCleanup(status), Is.True);
        }

        [Test]
        public void ProjectIntegrationState_CompleteSuppressesLeaseAndAutomaticCleanup()
        {
            var statePath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.ProjectIntegrationStateRelativePath);
            WriteIntegrationState(_projectRoot, statePath, "COMPLETE");

            var status = AICodedbProjectIntegrationStateStore.Read(_projectRoot, statePath);

            Assert.That(status.State, Is.EqualTo(AICodedbProjectIntegrationState.Uninstalled));
            Assert.That(status.CleanupState, Is.EqualTo(AICodedbProjectCleanupState.Complete));
            Assert.That(AICodedbEditorLifecycle.ShouldPublishEditorLease(status), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticUninstallCleanup(status), Is.False);
        }

        [TestCase("duplicate")]
        [TestCase("wrong-token")]
        [TestCase("bom")]
        [TestCase("invalid-utf8")]
        public void ProjectIntegrationState_RejectsAmbiguousOrInvalidStrictJson(string invalidKind)
        {
            var statePath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.ProjectIntegrationStateRelativePath);
            var json = IntegrationStateJson(_projectRoot);
            WriteInvalidJsonEvidence(
                statePath,
                json,
                invalidKind,
                "\"schema_version\":1",
                "\"schema_version\":1,\"schema_version\":1",
                "\"schema_version\":1",
                "\"schema_version\":true");

            var status = AICodedbProjectIntegrationStateStore.Read(_projectRoot, statePath);

            Assert.That(status.State, Is.EqualTo(AICodedbProjectIntegrationState.Invalid));
            Assert.That(AICodedbEditorLifecycle.ShouldPublishEditorLease(status), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticUninstallCleanup(status), Is.False);
        }

        [Test]
        public void ProjectIntegrationState_RejectsMismatchedIdentityAndUnreviewedPath()
        {
            var statePath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.ProjectIntegrationStateRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(statePath));
            WriteUtf8NoBom(
                statePath,
                IntegrationStateJson(_projectRoot).Replace(
                    AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot),
                    "sha256:" + new string('0', 64)));

            var mismatched = AICodedbProjectIntegrationStateStore.Read(_projectRoot, statePath);
            var unreviewed = AICodedbProjectIntegrationStateStore.Read(
                _projectRoot,
                Path.Combine(_projectRoot, "integration-state.json"));

            Assert.That(mismatched.State, Is.EqualTo(AICodedbProjectIntegrationState.Invalid));
            Assert.That(unreviewed.State, Is.EqualTo(AICodedbProjectIntegrationState.Invalid));
        }

        [Test]
        public void HostGenerationStore_ResolvesValidCurrentGeneration()
        {
            var target = ReadPackageRuntimeContract().Target;
            InstallCurrentGeneration();

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Current));
            Assert.That(selection.GenerationId, Is.EqualTo(target.GenerationId));
            Assert.That(selection.PayloadSequence, Is.EqualTo(target.PayloadSequence));
            Assert.That(selection.BootstrapProtocol, Is.EqualTo(target.BootstrapProtocol));
            Assert.That(selection.RootPath, Does.EndWith("/host/generations/" + target.GenerationId));
        }

        [Test]
        public void HostGenerationStore_RejectsStableWrapperDrift()
        {
            var target = ReadPackageRuntimeContract().Target;
            InstallCurrentGeneration();
            var wrapperPath = Path.Combine(
                _projectRoot,
                AICodedbPackageRuntimeContractStore.StableWrapperRelativePath.Replace('/', Path.DirectorySeparatorChar));
            File.AppendAllText(wrapperPath, "\n// drift\n");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Invalid));
            Assert.That(selection.GenerationId, Is.EqualTo(target.GenerationId));
            Assert.That(selection.Detail, Does.Contain("stable wrapper"));
        }

        [Test]
        public void HostGenerationStore_RejectsSelfConsistentCurrentGenerationNotOwnedByPackage()
        {
            var target = ReadPackageRuntimeContract().Target;
            InstallGeneration(
                target.PackageVersion,
                target.PayloadVersion,
                target.PayloadSequence,
                target.GenerationId);

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
                InsertAfterRequiredJsonMatch(
                    pointer,
                    "\"schema_version\"\\s*:\\s*1",
                    ",\"schema_version\":1"));

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
                ReplaceRequiredJsonMatch(
                    pointer,
                    "\"schema_version\"\\s*:\\s*1",
                    "\"schema_version\":true"));

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
                InsertAfterRequiredJsonMatch(
                    manifest,
                    "\"schema_version\"\\s*:\\s*1",
                    ",\"SCHEMA_VERSION\":1"));
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
        public void CurrentInstanceStore_TrustedPoc33PlansAutomaticPoc34Handoff()
        {
            InstallPackageDeclaredPreviousInstance("poc.33");
            var before = GetProjectSnapshot(_projectRoot);

            var status = AICodedbCurrentInstanceStore.Read(
                _projectRoot,
                AICodedbPaths.PackageRootPath);
            var selection = AICodedbHostGenerationStore.Resolve(
                _projectRoot,
                AICodedbPaths.PackageRootPath);
            var plan = AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                status.State,
                new AICodedbProductStatus(
                    AICodedbProductState.NeedsAttention,
                    AICodedbProductLayerState.Current,
                    AICodedbProductLayerState.Unavailable,
                    AICodedbProductLayerState.Unavailable,
                    AICodedbProductLayerState.Unavailable,
                    "Previous generation is selected."));

            Assert.That(status.State, Is.EqualTo(AICodedbCurrentInstanceState.TrustedPrevious));
            Assert.That(status.IsTrustedPrevious, Is.True);
            Assert.That(status.CanPublishEditorLease, Is.True);
            Assert.That(
                status.EditorLeaseRelativePath,
                Is.EqualTo(status.InstanceRelativePath + "/watch/lifecycle/editor-leases"));
            Assert.That(
                AICodedbEditorLifecycle.ShouldPublishEditorLeaseForInstance(
                    AICodedbProjectIntegrationStateStore.Read(_projectRoot),
                    status),
                Is.True);
            Assert.That(status.GenerationId, Is.EqualTo("poc.33"));
            Assert.That(status.PayloadSequence, Is.EqualTo(33));
            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Previous));
            Assert.That(plan, Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Deploy));
            Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before), "Classification must be read-only.");
        }

        [Test]
        public void SupervisorBridge_HandoffsOnlyAfterSuccessfulSelectedInstanceChange()
        {
            Assert.That(
                AICodedbSupervisorBridge.ShouldHandoffAfterMaterializerCommand(
                    "materialize",
                    true,
                    true),
                Is.True);
            Assert.That(
                AICodedbSupervisorBridge.ShouldHandoffAfterMaterializerCommand(
                    "materialize",
                    true,
                    false),
                Is.False);
            Assert.That(
                AICodedbSupervisorBridge.ShouldHandoffAfterMaterializerCommand(
                    "materialize",
                    false,
                    true),
                Is.False);
            Assert.That(
                AICodedbSupervisorBridge.ShouldHandoffAfterMaterializerCommand(
                    "watcher",
                    true,
                    true),
                Is.False,
                "Only the Supervisor's authenticated handoff disposition can trigger retirement.");
        }

        [Test]
        public void CurrentInstanceStore_DriftedPoc33RemainsInvalidAndBlocked()
        {
            InstallPackageDeclaredPreviousInstance("poc.33");
            var workerPath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                "poc.33",
                "wrapper",
                "codedb-project-instance-worker.mjs");
            File.AppendAllText(workerPath, "\n// drift\n");
            var before = GetProjectSnapshot(_projectRoot);

            var status = AICodedbCurrentInstanceStore.Read(
                _projectRoot,
                AICodedbPaths.PackageRootPath);
            var plan = AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                status.State,
                default(AICodedbProductStatus));

            Assert.That(status.State, Is.EqualTo(AICodedbCurrentInstanceState.Invalid));
            Assert.That(status.IsTrustedPrevious, Is.False);
            Assert.That(status.Detail, Does.Contain("generation closure"));
            Assert.That(plan, Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked));
            Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before), "Rejected evidence must remain read-only.");
        }

        [Test]
        public void CurrentInstanceStore_DriftedStableWrapperRemainsInvalidAndBlocked()
        {
            InstallPackageDeclaredPreviousInstance("poc.33");
            var wrapperPath = Path.Combine(
                _projectRoot,
                AICodedbPackageRuntimeContractStore.StableWrapperRelativePath.Replace('/', Path.DirectorySeparatorChar));
            File.AppendAllText(wrapperPath, "\n// drift\n");
            var before = GetProjectSnapshot(_projectRoot);

            var status = AICodedbCurrentInstanceStore.Read(
                _projectRoot,
                AICodedbPaths.PackageRootPath);

            Assert.That(status.State, Is.EqualTo(AICodedbCurrentInstanceState.Invalid));
            Assert.That(status.Detail, Does.Contain("stable wrapper"));
            Assert.That(GetProjectSnapshot(_projectRoot), Is.EqualTo(before), "Rejected evidence must remain read-only.");
        }

        [Test]
        public void HostGenerationStore_ResolvesValidatedPreviousGenerationWithoutMarkingItInvalid()
        {
            InstallPackageDeclaredPreviousInstance("poc.33");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.Previous));
            Assert.That(selection.IsUsable, Is.False);
            Assert.That(selection.GenerationId, Is.EqualTo("poc.33"));
            Assert.That(selection.Detail, Does.Contain("Package-declared previous generation"));
            Assert.That(
                AICodedbHostGenerationStore.ResolveHostPath(
                    _projectRoot,
                    "scripts/manage-codedb-project-watch.ps1",
                    AICodedbProjectSettings.WatchManageScriptRelativePath),
                Does.EndWith("/host/generations/poc.33/scripts/manage-codedb-project-watch.ps1"));
        }

        [Test]
        public void HostGenerationStore_ResolvesValidatedNewerGenerationAsDowngradeReviewRequired()
        {
            var target = ReadPackageRuntimeContract().Target;
            InstallGeneration(
                "future-package",
                "future-payload",
                target.PayloadSequence + 1,
                "future-generation");

            var selection = AICodedbHostGenerationStore.Resolve(_projectRoot);

            Assert.That(selection.State, Is.EqualTo(AICodedbHostGenerationState.DowngradeReviewRequired));
            Assert.That(selection.GenerationId, Is.EqualTo("future-generation"));
            Assert.That(selection.Detail, Does.Contain("newer than the loaded Package"));
        }

        [Test]
        public void HostGenerationStore_TreatsTrackedAdoptionWithoutRuntimeAsUnavailable()
        {
            var target = ReadPackageRuntimeContract().Target;
            var trackedFile = Path.Combine(_projectRoot, "AIWork", "codedb", "scripts", "fixture.ps1");
            Directory.CreateDirectory(Path.GetDirectoryName(trackedFile));
            File.WriteAllText(trackedFile, "tracked");
            var markerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostPayloadMarkerRelativePath);
            File.WriteAllText(
                markerPath,
                "{\"schema_version\":2,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + target.PackageVersion + "\","
                + "\"payload_version\":\"" + target.PayloadVersion + "\","
                + "\"payload_sequence\":" + target.PayloadSequence + ","
                + "\"payload_content_sha256\":\"" + new string('a', 64) + "\","
                + "\"host_use_gate_version\":1,\"generation_lease_version\":2,"
                + "\"generation_id\":\"" + target.GenerationId + "\","
                + "\"bootstrap_protocol\":" + target.BootstrapProtocol + ","
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
            var target = ReadPackageRuntimeContract().Target;
            var markerPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostPayloadMarkerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(markerPath));
            File.WriteAllText(
                markerPath,
                "{\"schema_version\":2,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + target.PackageVersion + "\","
                + "\"payload_version\":\"" + target.PayloadVersion + "\","
                + "\"payload_sequence\":" + target.PayloadSequence + ","
                + "\"payload_content_sha256\":\"" + new string('a', 64) + "\","
                + "\"host_use_gate_version\":1,\"generation_lease_version\":2,"
                + "\"generation_id\":\"" + target.GenerationId + "\","
                + "\"bootstrap_protocol\":" + target.BootstrapProtocol + ","
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
            var target = ReadPackageRuntimeContract().Target;
            var statePath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostPayloadUpgradeStateRelativePath);
            var json = "{\"schema_version\":1,"
                       + "\"managed_by\":\"com.rice.ai-codedb\","
                       + "\"project_root\":\"" + JsonPath(_projectRoot) + "\","
                       + "\"state\":\"CURRENT\","
                       + "\"generation_id\":\"" + target.GenerationId + "\","
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
                target.GenerationId);

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
        public void SupervisorIntentAdapter_DispatchesIndependentIntentOffCallingThread()
        {
            var adapter = new AICodedbSupervisorIntentAdapter();
            var callerThreadId = Thread.CurrentThread.ManagedThreadId;
            var firstThreadId = 0;
            var secondThreadId = 0;
            using (var firstStarted = new ManualResetEventSlim(false))
            using (var secondStarted = new ManualResetEventSlim(false))
            using (var release = new ManualResetEventSlim(false))
            {
                var first = adapter.Dispatch(
                    AICodedbSupervisorRequestKind.Reconcile,
                    cancellationToken =>
                    {
                        firstThreadId = Thread.CurrentThread.ManagedThreadId;
                        firstStarted.Set();
                        release.Wait(TimeSpan.FromSeconds(5));
                        cancellationToken.ThrowIfCancellationRequested();
                        return Task.FromResult("first");
                    },
                    true);
                var second = adapter.Dispatch(
                    AICodedbSupervisorRequestKind.ObserveStatus,
                    cancellationToken =>
                    {
                        secondThreadId = Thread.CurrentThread.ManagedThreadId;
                        secondStarted.Set();
                        release.Wait(TimeSpan.FromSeconds(5));
                        cancellationToken.ThrowIfCancellationRequested();
                        return Task.FromResult("second");
                    },
                    false);

                Assert.That(firstStarted.Wait(TimeSpan.FromSeconds(5)), Is.True);
                Assert.That(secondStarted.Wait(TimeSpan.FromSeconds(5)), Is.True,
                    "The Unity adapter must not serialize runtime request admission.");
                Assert.That(firstThreadId, Is.Not.EqualTo(callerThreadId));
                Assert.That(secondThreadId, Is.Not.EqualTo(callerThreadId));
                Assert.That(adapter.Snapshot.PendingCount, Is.EqualTo(0));
                Assert.That(adapter.Snapshot.LastSequence, Is.EqualTo(2));

                release.Set();
                Assert.That(first.GetAwaiter().GetResult(), Is.EqualTo("first"));
                Assert.That(second.GetAwaiter().GetResult(), Is.EqualTo("second"));
            }
            adapter.Dispose();
        }

        [Test]
        public void SupervisorIntentAdapter_DoesNotCoalesceRuntimeOperationKeysLocally()
        {
            var adapter = new AICodedbSupervisorIntentAdapter();
            var executionCount = 0;
            Func<CancellationToken, Task<int>> work = cancellationToken =>
                Task.FromResult(Interlocked.Increment(ref executionCount));

            var first = adapter.Dispatch(
                AICodedbSupervisorRequestKind.ObserveStatus,
                work,
                false);
            var second = adapter.Dispatch(
                AICodedbSupervisorRequestKind.ObserveStatus,
                work,
                false);

            Assert.That(first.GetAwaiter().GetResult(), Is.GreaterThan(0));
            Assert.That(second.GetAwaiter().GetResult(), Is.GreaterThan(0));
            Assert.That(executionCount, Is.EqualTo(2),
                "Only the project Supervisor may coalesce runtime request keys.");
            adapter.Dispose();
        }

        [Test]
        public void SupervisorIntentAdapter_SuspendsMaintenanceButKeepsQueriesEligible()
        {
            var adapter = new AICodedbSupervisorIntentAdapter();
            adapter.SetMaintenanceSuspended(true);

            var maintenance = adapter.Dispatch(
                AICodedbSupervisorRequestKind.Reconcile,
                cancellationToken => Task.FromResult(true),
                true);
            var query = adapter.Dispatch(
                AICodedbSupervisorRequestKind.ObserveStatus,
                cancellationToken => Task.FromResult(true),
                false);

            Assert.Throws<TaskCanceledException>(() => maintenance.GetAwaiter().GetResult());
            Assert.That(query.GetAwaiter().GetResult(), Is.True);
            Assert.That(adapter.Snapshot.IsSuspended, Is.True);
            Assert.That(adapter.Snapshot.PendingCount, Is.EqualTo(0));
            adapter.Dispose();
        }

        [Test]
        public void SupervisorIntentAdapter_InvalidatesLateLocalResultAtGenerationBoundary()
        {
            var adapter = new AICodedbSupervisorIntentAdapter();
            using (var started = new ManualResetEventSlim(false))
            using (var release = new ManualResetEventSlim(false))
            {
                var task = adapter.Dispatch(
                    AICodedbSupervisorRequestKind.ObserveStatus,
                    cancellationToken =>
                    {
                        started.Set();
                        release.Wait(TimeSpan.FromSeconds(5));
                        return Task.FromResult(true);
                    },
                    false);
                Assert.That(started.Wait(TimeSpan.FromSeconds(5)), Is.True);

                adapter.Invalidate();
                release.Set();

                Assert.Throws<TaskCanceledException>(() => task.GetAwaiter().GetResult());
                Assert.That(adapter.Snapshot.Epoch, Is.EqualTo(1));
            }
            adapter.Dispose();
        }

        [Test]
        public void SupervisorIntentAdapter_MaintenanceSuspensionRejectsLateMaintenanceButKeepsQueriesEligible()
        {
            var adapter = new AICodedbSupervisorIntentAdapter();
            using (var started = new ManualResetEventSlim(false))
            using (var release = new ManualResetEventSlim(false))
            {
                var maintenance = adapter.Dispatch(
                    AICodedbSupervisorRequestKind.Maintenance,
                    cancellationToken =>
                    {
                        started.Set();
                        release.Wait(TimeSpan.FromSeconds(5));
                        return Task.FromResult("late-maintenance");
                    },
                    true);
                Assert.That(started.Wait(TimeSpan.FromSeconds(5)), Is.True);

                adapter.SetMaintenanceSuspended(true);
                var query = adapter.Dispatch(
                    AICodedbSupervisorRequestKind.ObserveStatus,
                    cancellationToken => Task.FromResult("query"),
                    false);
                release.Set();

                Assert.Throws<TaskCanceledException>(() => maintenance.GetAwaiter().GetResult());
                Assert.That(query.GetAwaiter().GetResult(), Is.EqualTo("query"));
                Assert.That(adapter.Snapshot.Epoch, Is.EqualTo(1));
            }
            adapter.Dispose();
        }

        [Test]
        public void SupervisorIntentAdapter_SourceDoesNotOwnRuntimeAdmissionPolicy()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbSupervisorRequestQueue.cs"));

            Assert.That(source, Does.Contain("AICodedbSupervisorIntentAdapter"));
            Assert.That(source, Does.Not.Contain("AICodedbSupervisorRequestPriority"));
            Assert.That(source, Does.Not.Contain("supersedeExisting"));
            Assert.That(source, Does.Not.Contain("TakeNextEntryLocked"));
            Assert.That(source, Does.Not.Contain("Dictionary<string, Entry>"));
        }

        [Test]
        public void BackgroundScheduler_RunsMaintenanceOffCallingThreadWithoutBlockingCaller()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            var callerThreadId = Thread.CurrentThread.ManagedThreadId;
            var workerThreadId = 0;
            using (var started = new ManualResetEventSlim(false))
            using (var release = new ManualResetEventSlim(false))
            {
                var task = scheduler.QueueMaintenance(canContinue =>
                {
                    workerThreadId = Thread.CurrentThread.ManagedThreadId;
                    started.Set();
                    release.Wait(TimeSpan.FromSeconds(5));
                    return canContinue();
                });

                Assert.That(started.Wait(TimeSpan.FromSeconds(5)), Is.True);
                Assert.That(task.IsCompleted, Is.False, "QueueMaintenance blocked the calling thread.");
                Assert.That(workerThreadId, Is.Not.EqualTo(callerThreadId));
                release.Set();
                Assert.That(task.GetAwaiter().GetResult(), Is.True);
            }
        }

        [Test]
        public void BackgroundScheduler_EnsuresWatcherBeforeAvailabilityProbeOnWorker()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            var callerThreadId = Thread.CurrentThread.ManagedThreadId;
            var phaseThreadId = 0;
            var phases = new List<string>();

            var task = scheduler.QueueMaintenance(canContinue =>
            {
                AICodedbCommandResult ensureResult;
                return AICodedbEditorLifecycle.RunWatcherThenAvailability(
                    canContinue,
                    () =>
                    {
                        phaseThreadId = Thread.CurrentThread.ManagedThreadId;
                        phases.Add("ensure");
                        return new AICodedbCommandResult(0, "watcher ready", string.Empty, false);
                    },
                    () =>
                    {
                        phases.Add("probe");
                        return new AICodedbCommandResult(0, "backend usable", string.Empty, false);
                    },
                    out ensureResult);
            });

            var result = task.GetAwaiter().GetResult();
            Assert.That(result, Is.Not.Null);
            Assert.That(result.Succeeded, Is.True);
            Assert.That(phases, Is.EqualTo(new[] { "ensure", "probe" }));
            Assert.That(phaseThreadId, Is.Not.EqualTo(callerThreadId));
        }

        [Test]
        public void BackgroundScheduler_PlayTransitionAfterWatcherEnsureSkipsAvailabilityProbe()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            var availabilityRan = false;
            var task = scheduler.QueueMaintenance(canContinue =>
            {
                AICodedbCommandResult ensureResult;
                return AICodedbEditorLifecycle.RunWatcherThenAvailability(
                    canContinue,
                    () =>
                    {
                        scheduler.SetMaintenanceSuspended(true);
                        return new AICodedbCommandResult(0, "watcher ready", string.Empty, false);
                    },
                    () =>
                    {
                        availabilityRan = true;
                        return new AICodedbCommandResult(0, "backend usable", string.Empty, false);
                    },
                    out ensureResult);
            });

            Assert.That(task.GetAwaiter().GetResult(), Is.Null);
            Assert.That(availabilityRan, Is.False);
        }

        [Test]
        public void ShouldRunAvailabilityConvergence_ReprobesRecordedReadyStateUnlessUpgradeAlreadyProvedIt()
        {
            var current = new AICodedbHostPayloadStatus(
                AICodedbHostPayloadState.Current,
                AICodedbStatusState.Ok,
                "CURRENT",
                string.Empty);
            var unavailable = new AICodedbHostPayloadStatus(
                AICodedbHostPayloadState.Unknown,
                AICodedbStatusState.Warning,
                "UNAVAILABLE",
                string.Empty);

            Assert.That(
                AICodedbEditorLifecycle.ShouldRunAvailabilityConvergence(current, false),
                Is.True,
                "A persisted Ready result must not suppress the live probe when reconcile was requested.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunAvailabilityConvergence(current, true),
                Is.False,
                "A successful Upgrade already completed the same watcher and availability convergence.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunAvailabilityConvergence(unavailable, false),
                Is.False);
        }

        [Test]
        public void BackgroundScheduler_PlayTransitionSkipsQueuedAndLaterMaintenancePhases()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            var secondPhaseRan = false;
            using (var firstPhase = new ManualResetEventSlim(false))
            using (var release = new ManualResetEventSlim(false))
            {
                var running = scheduler.QueueMaintenance(canContinue =>
                {
                    firstPhase.Set();
                    release.Wait(TimeSpan.FromSeconds(5));
                    if (!canContinue())
                        return false;
                    secondPhaseRan = true;
                    return true;
                });
                Assert.That(firstPhase.Wait(TimeSpan.FromSeconds(5)), Is.True);
                scheduler.SetMaintenanceSuspended(true);
                release.Set();
                Assert.That(running.GetAwaiter().GetResult(), Is.False);
                Assert.That(secondPhaseRan, Is.False);
            }

            var queuedPhaseRan = false;
            var queued = scheduler.QueueMaintenance(canContinue =>
            {
                queuedPhaseRan = true;
                return canContinue();
            });
            Assert.That(queued.GetAwaiter().GetResult(), Is.False);
            Assert.That(queuedPhaseRan, Is.False);
        }

        [Test]
        public void BackgroundScheduler_CancelsInFlightMaintenanceAtPlayBoundary()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            using (var started = new ManualResetEventSlim(false))
            {
                var running = scheduler.QueueMaintenance<bool>((canContinue, cancellationToken) =>
                {
                    started.Set();
                    while (canContinue())
                        Thread.Sleep(5);
                    return cancellationToken.IsCancellationRequested;
                });

                Assert.That(started.Wait(TimeSpan.FromSeconds(5)), Is.True);
                scheduler.SetMaintenanceSuspended(true);
                Assert.That(running.GetAwaiter().GetResult(), Is.True);
            }
        }

        [Test]
        public void BackgroundScheduler_CancelsAllInFlightMaintenanceAtPlayBoundary()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            using (var firstStarted = new ManualResetEventSlim(false))
            using (var secondStarted = new ManualResetEventSlim(false))
            {
                Func<Func<bool>, CancellationToken, bool> waitForCancellation =
                    (canContinue, cancellationToken) =>
                    {
                        while (canContinue())
                        {
                            Thread.Sleep(5);
                            if (cancellationToken.IsCancellationRequested)
                                break;
                        }
                        return cancellationToken.IsCancellationRequested;
                    };

                var first = scheduler.QueueMaintenance<bool>((canContinue, cancellationToken) =>
                {
                    firstStarted.Set();
                    return waitForCancellation(canContinue, cancellationToken);
                });
                var second = scheduler.QueueMaintenance<bool>((canContinue, cancellationToken) =>
                {
                    secondStarted.Set();
                    return waitForCancellation(canContinue, cancellationToken);
                });

                Assert.That(firstStarted.Wait(TimeSpan.FromSeconds(5)), Is.True);
                Assert.That(secondStarted.Wait(TimeSpan.FromSeconds(5)), Is.True);
                scheduler.SetMaintenanceSuspended(true);
                Assert.That(first.GetAwaiter().GetResult(), Is.True);
                Assert.That(second.GetAwaiter().GetResult(), Is.True);
            }
        }

        [Test]
        public void BackgroundScheduler_HasNoProcessCancellationOwner()
        {
            var delegateFields = typeof(AICodedbEditorBackgroundScheduler).GetFields(
                System.Reflection.BindingFlags.Instance
                | System.Reflection.BindingFlags.NonPublic
                | System.Reflection.BindingFlags.Public);
            Assert.That(
                Array.Exists(
                    delegateFields,
                    field => typeof(Delegate).IsAssignableFrom(field.FieldType)),
                Is.False,
                "A Play/Domain Reload scheduler must not retain a process-kill callback.");
        }

        [Test]
        public void LifecycleMaintenanceTimeout_IsBoundedForPlayTransitions()
        {
            Assert.That(
                AICodedbEditorLifecycle.LifecycleMaintenanceTimeoutMilliseconds,
                Is.GreaterThan(0).And.LessThanOrEqualTo(15000));
        }

        [Test]
        public void BackgroundScheduler_LeaseHeartbeatRemainsOnWorkerDuringPlaySuspension()
        {
            var scheduler = new AICodedbEditorBackgroundScheduler();
            scheduler.SetMaintenanceSuspended(true);
            var callerThreadId = Thread.CurrentThread.ManagedThreadId;
            var workerThreadId = 0;
            using (var started = new ManualResetEventSlim(false))
            using (var release = new ManualResetEventSlim(false))
            {
                var task = scheduler.QueueLease(() =>
                {
                    workerThreadId = Thread.CurrentThread.ManagedThreadId;
                    started.Set();
                    release.Wait(TimeSpan.FromSeconds(5));
                });

                Assert.That(started.Wait(TimeSpan.FromSeconds(5)), Is.True);
                Assert.That(task.IsCompleted, Is.False, "A durable lease write would block the caller here if it ran inline.");
                Assert.That(workerThreadId, Is.Not.EqualTo(callerThreadId));
                release.Set();
                task.GetAwaiter().GetResult();
            }
        }

        [Test]
        public void ShouldQueueScheduledReconcile_DoesNotInvokeBackendWorkOnMainThread()
        {
            var next = 0d;
            Assert.That(AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(1d, ref next, false), Is.True);
            Assert.That(next, Is.GreaterThan(1d));

            var suspendedNext = 0d;
            Assert.That(AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(1d, ref suspendedNext, true), Is.False);
            Assert.That(suspendedNext, Is.Zero);
        }

        [Test]
        public void ControlContractMigration_ConsecutiveScheduledTicksStayQuiescentButExplicitTriggerReadmits()
        {
            var next = 0d;
            var admissionCount = 1;
            const string recordedFingerprint = "unchanged-machine-evidence";

            if (AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(1d, ref next, false, true))
                admissionCount++;
            if (AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(
                    recordedFingerprint,
                    recordedFingerprint))
                admissionCount++;
            if (AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(31d, ref next, false, true))
                admissionCount++;
            if (AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(
                    recordedFingerprint,
                    recordedFingerprint))
                admissionCount++;

            Assert.That(admissionCount, Is.EqualTo(1));
            Assert.That(next, Is.Zero);
            if (AICodedbEditorLifecycle.ShouldAllowMigrationAdmissionTrigger(false, true))
                admissionCount++;
            Assert.That(admissionCount, Is.EqualTo(2));

            Assert.That(
                AICodedbEditorLifecycle.ShouldTriggerPrerequisiteRecheck(
                    recordedFingerprint,
                    "changed-machine-evidence"),
                Is.True,
                "A machine-evidence change must be able to request one explicit fresh admission.");
        }

        [Test]
        public void ControlContractMigration_ScheduledSuppressionDoesNotAffectOtherNeedsAttentionRecovery()
        {
            var next = 0d;

            Assert.That(
                AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(1d, ref next, false, false),
                Is.True);
            Assert.That(next, Is.GreaterThan(1d));
            Assert.That(
                AICodedbEditorLifecycle.ShouldAllowMigrationAdmissionTrigger(true, false),
                Is.True);
        }

        [TestCase(AICodedbControlContractMigrationState.Missing)]
        [TestCase(AICodedbControlContractMigrationState.Current)]
        [TestCase(AICodedbControlContractMigrationState.CompatibleStale)]
        public void ControlContractMigration_UsableStatesPreserveAutomaticConvergenceWithoutAdmissionDryRun(
            AICodedbControlContractMigrationState state)
        {
            var probeCount = 0;
            AICodedbProductStatus productStatus;
            AICodedbCommandResult admissionResult;
            var blocked = AICodedbEditorLifecycle.TryResolveControlContractMigrationBlock(
                CreateIntegrationStatus(AICodedbProjectIntegrationState.Installed),
                CreateMigrationStatus(state),
                () =>
                {
                    probeCount++;
                    return PrerequisiteResult("CURRENT");
                },
                out productStatus,
                out admissionResult);

            Assert.That(blocked, Is.False);
            Assert.That(probeCount, Is.Zero);
            Assert.That(admissionResult, Is.Null);
        }

        [TestCase(AICodedbControlContractMigrationState.ObsoleteReinstallRequired)]
        [TestCase(AICodedbControlContractMigrationState.InvalidOrAmbiguous)]
        public void ControlContractMigration_ColdStartMissingPrerequisiteTakesPriorityWithoutReinstall(
            AICodedbControlContractMigrationState state)
        {
            var probeCount = 0;
            AICodedbProductStatus productStatus;
            AICodedbCommandResult admissionResult;
            var blocked = AICodedbEditorLifecycle.TryResolveControlContractMigrationBlock(
                CreateIntegrationStatus(AICodedbProjectIntegrationState.Installed),
                CreateMigrationStatus(state),
                () =>
                {
                    probeCount++;
                    return PrerequisiteResult("MISSING");
                },
                out productStatus,
                out admissionResult);

            Assert.That(blocked, Is.True);
            Assert.That(probeCount, Is.EqualTo(1));
            Assert.That(admissionResult, Is.Not.Null);
            Assert.That(productStatus.State, Is.EqualTo(AICodedbProductState.MissingPrerequisite));
            Assert.That(productStatus.Prerequisite, Is.EqualTo(AICodedbProductLayerState.Missing));
            Assert.That(productStatus.AttentionReason, Is.EqualTo(AICodedbProductAttentionReason.None));
            Assert.That(productStatus.RequiresReinstall, Is.False);
            Assert.That(productStatus.Detail, Does.Contain("fixture prerequisite is missing"));
            Assert.That(productStatus.DiagnosticDetail, Is.EqualTo("migration diagnostic"));
        }

        [TestCase(
            AICodedbControlContractMigrationState.ObsoleteReinstallRequired,
            AICodedbProductAttentionReason.ControlContractReinstallRequired,
            true)]
        [TestCase(
            AICodedbControlContractMigrationState.InvalidOrAmbiguous,
            AICodedbProductAttentionReason.ControlContractInvalidOrAmbiguous,
            false)]
        public void ControlContractMigration_TrustedIndependentPrerequisiteMapsBlockedStateWithoutCoordinatorProbe(
            AICodedbControlContractMigrationState state,
            AICodedbProductAttentionReason expectedReason,
            bool expectedReinstall)
        {
            var probeCount = 0;
            var independentPrerequisiteResult = PrerequisiteResult("CURRENT");
            AICodedbProductStatus productStatus;
            AICodedbCommandResult admissionResult;
            var blocked = AICodedbEditorLifecycle.TryResolveControlContractMigrationBlock(
                CreateIntegrationStatus(AICodedbProjectIntegrationState.Installed),
                CreateMigrationStatus(state),
                independentPrerequisiteResult,
                () =>
                {
                    probeCount++;
                    return new AICodedbCommandResult(
                        4,
                        PrerequisiteOutput("CURRENT"),
                        "fixture coordinator probe must not run",
                        false);
                },
                out productStatus,
                out admissionResult);

            Assert.That(blocked, Is.True);
            Assert.That(probeCount, Is.Zero);
            Assert.That(admissionResult, Is.SameAs(independentPrerequisiteResult));
            Assert.That(productStatus.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(productStatus.Prerequisite, Is.EqualTo(AICodedbProductLayerState.Current));
            Assert.That(productStatus.AttentionReason, Is.EqualTo(expectedReason));
            Assert.That(productStatus.RequiresReinstall, Is.EqualTo(expectedReinstall));
            Assert.That(productStatus.Detail, Is.EqualTo("migration detail"));
            Assert.That(productStatus.DiagnosticDetail, Is.EqualTo("migration diagnostic"));
        }

        [Test]
        public void ControlContractMigration_UntrustworthyPrerequisiteEvidenceFailsClosedWithoutReinstall()
        {
            var cases = new[]
            {
                new KeyValuePair<string, AICodedbCommandResult>("null", null),
                new KeyValuePair<string, AICodedbCommandResult>(
                    "failed",
                    new AICodedbCommandResult(4, PrerequisiteOutput("CURRENT"), "fixture failure", false)),
                new KeyValuePair<string, AICodedbCommandResult>(
                    "timed-out",
                    new AICodedbCommandResult(0, PrerequisiteOutput("CURRENT"), string.Empty, true)),
                new KeyValuePair<string, AICodedbCommandResult>(
                    "malformed",
                    Result(PrerequisiteOutput("CURRENTLY"))),
                new KeyValuePair<string, AICodedbCommandResult>(
                    "malformed-command",
                    Result(PrerequisiteOutput("CURRENT") + "\n[COMMAND_RESULT] {not-json")),
                new KeyValuePair<string, AICodedbCommandResult>(
                    "unknown",
                    Result(PrerequisiteOutput("UNKNOWN"))),
                new KeyValuePair<string, AICodedbCommandResult>(
                    "ambiguous",
                    Result(PrerequisiteOutput("CURRENT")
                           + "\n[PRODUCT_LAYER PREREQUISITE] MISSING - conflicting fixture"))
            };

            foreach (var testCase in cases)
            {
                var probeCount = 0;
                AICodedbProductStatus productStatus;
                AICodedbCommandResult admissionResult;
                var blocked = AICodedbEditorLifecycle.TryResolveControlContractMigrationBlock(
                    CreateIntegrationStatus(AICodedbProjectIntegrationState.Installed),
                    CreateMigrationStatus(AICodedbControlContractMigrationState.ObsoleteReinstallRequired),
                    () =>
                    {
                        probeCount++;
                        return testCase.Value;
                    },
                    out productStatus,
                    out admissionResult);

                Assert.That(blocked, Is.True, testCase.Key);
                Assert.That(probeCount, Is.EqualTo(1), testCase.Key);
                Assert.That(productStatus.State, Is.EqualTo(AICodedbProductState.NeedsAttention), testCase.Key);
                Assert.That(productStatus.AttentionReason, Is.EqualTo(AICodedbProductAttentionReason.None), testCase.Key);
                Assert.That(productStatus.RequiresReinstall, Is.False, testCase.Key);
            }
        }

        [Test]
        public void ControlContractMigration_UninstalledKeepsInstallSemanticsWithoutAdmissionDryRun()
        {
            var probeCount = 0;
            AICodedbProductStatus productStatus;
            AICodedbCommandResult admissionResult;
            var blocked = AICodedbEditorLifecycle.TryResolveControlContractMigrationBlock(
                CreateIntegrationStatus(AICodedbProjectIntegrationState.Uninstalled),
                CreateMigrationStatus(AICodedbControlContractMigrationState.ObsoleteReinstallRequired),
                () =>
                {
                    probeCount++;
                    return PrerequisiteResult("CURRENT");
                },
                out productStatus,
                out admissionResult);

            Assert.That(blocked, Is.True);
            Assert.That(probeCount, Is.Zero);
            Assert.That(admissionResult, Is.Null);
            Assert.That(productStatus.State, Is.EqualTo(AICodedbProductState.Uninstalled));
            Assert.That(productStatus.RequiresReinstall, Is.False);
        }

        [Test]
        public void ControlContractMigration_InvalidIntegrationKeepsExistingAttentionWithoutAdmissionDryRun()
        {
            var probeCount = 0;
            AICodedbProductStatus productStatus;
            AICodedbCommandResult admissionResult;
            var blocked = AICodedbEditorLifecycle.TryResolveControlContractMigrationBlock(
                CreateIntegrationStatus(AICodedbProjectIntegrationState.Invalid),
                CreateMigrationStatus(AICodedbControlContractMigrationState.ObsoleteReinstallRequired),
                () =>
                {
                    probeCount++;
                    return PrerequisiteResult("CURRENT");
                },
                out productStatus,
                out admissionResult);

            Assert.That(blocked, Is.True);
            Assert.That(probeCount, Is.Zero);
            Assert.That(admissionResult, Is.Null);
            Assert.That(productStatus.State, Is.EqualTo(AICodedbProductState.NeedsAttention));
            Assert.That(productStatus.Detail, Is.EqualTo("invalid integration"));
            Assert.That(productStatus.RequiresReinstall, Is.False);
        }

        [Test]
        public void LifecycleSource_NeverIssuesAutomaticReinstall()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbEditorLifecycle.cs"));

            Assert.That(source, Does.Not.Contain("\"Reinstall\""));
        }

        private static AICodedbControlContractMigrationStatus CreateMigrationStatus(
            AICodedbControlContractMigrationState state)
        {
            return new AICodedbControlContractMigrationStatus(
                state,
                AICodedbControlContract.CreateDefaultIdentity(),
                "current-runtime",
                "legacy-runtime",
                "migration detail",
                "migration diagnostic");
        }

        private static AICodedbProjectIntegrationStatus CreateIntegrationStatus(
            AICodedbProjectIntegrationState state)
        {
            return new AICodedbProjectIntegrationStatus(
                state,
                state == AICodedbProjectIntegrationState.Invalid
                    ? AICodedbProjectCleanupState.Invalid
                    : AICodedbProjectCleanupState.Complete,
                string.Empty,
                state == AICodedbProjectIntegrationState.Invalid
                    ? "invalid integration"
                    : state == AICodedbProjectIntegrationState.Uninstalled
                        ? "uninstalled integration"
                        : "installed integration");
        }

        private static AICodedbCommandResult PrerequisiteResult(string state)
        {
            return Result(PrerequisiteOutput(state));
        }

        private static string PrerequisiteOutput(string state)
        {
            var missing = string.Equals(state, "MISSING", StringComparison.Ordinal);
            return "[PRODUCT_LAYER PREREQUISITE] " + state + " - "
                   + (missing ? "fixture prerequisite is missing" : "fixture prerequisite is current") + "\n"
                   + "[PRODUCT_LAYER INSTALLED] " + (missing ? "BLOCKED" : "CURRENT") + "\n"
                   + "[PRODUCT_LAYER CONFIGURED] " + (missing ? "BLOCKED" : "CURRENT") + "\n"
                   + "[PRODUCT_LAYER MCP_AVAILABLE] " + (missing ? "BLOCKED" : "CURRENT") + "\n"
                   + "[PRODUCT_STATE] " + (missing ? "MISSING_PREREQUISITE" : "READY") + "\n"
                   + "[PREREQUISITE] "
                   + (missing ? "fixture prerequisite is missing" : "fixture prerequisite is current");
        }

        [Test]
        public void MissingPrerequisite_DoesNotSchedulePeriodicBackendInspectionLoop()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldInspectBackendForScheduledReconcile(
                    AICodedbProductState.MissingPrerequisite),
                Is.False);
            Assert.That(
                AICodedbEditorLifecycle.ShouldInspectBackendForScheduledReconcile(
                    AICodedbProductState.Starting),
                Is.True);
            Assert.That(
                AICodedbEditorLifecycle.ShouldInspectBackendForScheduledReconcile(
                    AICodedbProductState.Ready),
                Is.True);
        }

        [TestCase(AICodedbProductState.Ready, ExpectedResult = false)]
        [TestCase(AICodedbProductState.MissingPrerequisite, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Starting, ExpectedResult = true)]
        [TestCase(AICodedbProductState.NeedsAttention, ExpectedResult = true)]
        public bool ShouldReconcileAfterPlayModeResume_OnlyRetriesNonTerminalStates(
            AICodedbProductState previousProductState)
        {
            return AICodedbEditorLifecycle.ShouldReconcileAfterPlayModeResume(previousProductState);
        }

        [TestCase(false, ExpectedResult = false)]
        [TestCase(true, ExpectedResult = true)]
        public bool ReadyPlayResume_ForcesReconcileOnlyForPendingPackageChange(
            bool packageFingerprintChanged)
        {
            return AICodedbEditorLifecycle.ShouldForceReconcileAfterPlayModeResume(
                packageFingerprintChanged);
        }

        [Test]
        public void ReadyPlayResume_SamePackageReconnectsWithoutReconcile()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldForceReconcileAfterPlayModeResume(false),
                Is.False);
            Assert.That(
                AICodedbEditorLifecycle.ShouldReconcileAfterPlayModeResume(
                    AICodedbProductState.Ready),
                Is.False);
        }

        [TestCase(true, false, ExpectedResult = true)]
        [TestCase(true, true, ExpectedResult = false)]
        [TestCase(false, false, ExpectedResult = false)]
        public bool PackageChangeSignal_IsClearedOnlyByCompletedReconcile(
            bool packageFingerprintChanged,
            bool reconcileCompleted)
        {
            return AICodedbEditorLifecycle.ShouldRetainPendingPackageChange(
                packageFingerprintChanged,
                reconcileCompleted);
        }

        [TestCase(AICodedbProductState.Ready, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Starting, ExpectedResult = false)]
        [TestCase(AICodedbProductState.NeedsAttention, ExpectedResult = false)]
        public bool ReadyPlayResume_DoesNotForceAvailabilityRecovery(
            AICodedbProductState previousProductState)
        {
            return AICodedbEditorLifecycle.ShouldForceAvailabilityReconcileAfterPlayModeResume(
                previousProductState);
        }

        [TestCase(AICodedbProductState.Ready, true, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Ready, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Starting, true, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Starting, false, ExpectedResult = false)]
        [TestCase(AICodedbProductState.NeedsAttention, true, ExpectedResult = false)]
        [TestCase(AICodedbProductState.MissingPrerequisite, true, ExpectedResult = false)]
        [TestCase(AICodedbProductState.Uninstalled, true, ExpectedResult = false)]
        public bool PersistedReadyDuringPlay_RequiresCurrentPackageFingerprint(
            AICodedbProductState lastProductState,
            bool packageFingerprintMatches)
        {
            return AICodedbEditorLifecycle.ShouldUsePersistedReadyStateDuringPlay(
                lastProductState,
                packageFingerprintMatches);
        }

        [TestCase(false, false, ExpectedResult = false)]
        [TestCase(true, false, ExpectedResult = true)]
        [TestCase(false, true, ExpectedResult = true)]
        [TestCase(true, true, ExpectedResult = true)]
        public bool PlayModeMaintenanceSuspension_UsesEitherUnitySignal(
            bool editorPlayingOrWillChangePlaymode,
            bool applicationPlaying)
        {
            return AICodedbEditorLifecycle.IsPlayModeMaintenanceSuspended(
                editorPlayingOrWillChangePlaymode,
                applicationPlaying);
        }

        [Test]
        public void ReadyCurrentInstance_WithPendingCleanup_SelectsThrottledRetirementOnly()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    true,
                    true,
                    AICodedbProductState.Ready,
                    AICodedbProjectCleanupState.Pending),
                Is.True,
                "Pending retirement must enter bounded convergence without redeploying current.");
            var ready = AICodedbProductStatusBuilder.Build(
                new AICodedbProjectIntegrationStatus(
                    AICodedbProjectIntegrationState.Installed,
                    AICodedbProjectCleanupState.Pending,
                    string.Empty,
                    "installed"),
                Result("[PRODUCT_LAYER PREREQUISITE] CURRENT\n"
                       + "[PRODUCT_LAYER INSTALLED] CURRENT\n"
                       + "[PRODUCT_LAYER CONFIGURED] CURRENT\n"
                       + "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT\n"
                       + "[PRODUCT_STATE] READY"));
            Assert.That(
                AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                    AICodedbCurrentInstanceState.Current,
                    ready,
                    AICodedbProjectCleanupState.Pending),
                Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Retire));

            var nextReconcileAt = 0d;
            Assert.That(
                AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(
                    30d,
                    ref nextReconcileAt,
                    false),
                Is.True);
            Assert.That(
                AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(
                    31d,
                    ref nextReconcileAt,
                    false),
                Is.False,
                "A pending retirement must not form an immediate reconcile loop.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(
                    60d,
                    ref nextReconcileAt,
                    false,
                    false,
                    true),
                Is.False,
                "An in-flight retirement must remain single-flight.");
            Assert.That(nextReconcileAt, Is.EqualTo(90d), "An in-flight retirement must retain periodic backoff.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    true,
                    true,
                    AICodedbProductState.Ready,
                    AICodedbProjectCleanupState.Complete),
                Is.False);
            Assert.That(
                AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                    AICodedbCurrentInstanceState.Current,
                    ready,
                    AICodedbProjectCleanupState.Complete),
                Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.None));
            Assert.That(
                AICodedbEditorLifecycle.ShouldQueueScheduledReconcile(
                    60d,
                    ref nextReconcileAt,
                    true),
                Is.False,
                "Play/compile/update maintenance boundaries must defer retirement scheduling.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldDeferReconcile(true, false, false),
                Is.True);
            Assert.That(
                AICodedbEditorLifecycle.ShouldDeferReconcile(false, true, false),
                Is.True);
            Assert.That(
                AICodedbEditorLifecycle.ShouldDeferReconcile(false, false, true),
                Is.True);
        }

        [Test]
        public void MissingOrUnavailableCurrentInstance_StillRunsFullConvergence()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    false,
                    false,
                    AICodedbProductState.Starting,
                    AICodedbProjectCleanupState.Pending),
                Is.True,
                "A missing current instance must still converge.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    true,
                    true,
                    AICodedbProductState.NeedsAttention,
                    AICodedbProjectCleanupState.Pending),
                Is.True,
                "A non-Ready current instance must still converge.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    true,
                    false,
                    AICodedbProductState.NeedsAttention,
                    AICodedbProjectCleanupState.Pending),
                Is.False,
                "An invalid selected instance remains fail-closed instead of being replaced automatically.");
            var blocked = AICodedbProductStatusBuilder.Build(
                new AICodedbProjectIntegrationStatus(
                    AICodedbProjectIntegrationState.Invalid,
                    AICodedbProjectCleanupState.Invalid,
                    string.Empty,
                    "invalid"),
                Result(string.Empty));
            Assert.That(
                AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                    AICodedbCurrentInstanceState.Invalid,
                    blocked,
                    AICodedbProjectCleanupState.Pending),
                Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked));
        }

        [Test]
        public void CurrentInstanceAvailabilityLoss_RecoversInPlaceInsteadOfDeployingReplacement()
        {
            var unavailable = AICodedbProductStatusBuilder.Build(
                new AICodedbProjectIntegrationStatus(
                    AICodedbProjectIntegrationState.Installed,
                    AICodedbProjectCleanupState.Complete,
                    string.Empty,
                    "installed"),
                new AICodedbCommandResult(
                    1,
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n"
                    + "[PRODUCT_LAYER INSTALLED] CURRENT\n"
                    + "[PRODUCT_LAYER CONFIGURED] CURRENT\n"
                    + "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE\n"
                    + "[PRODUCT_STATE] NEEDS_ATTENTION\n",
                    "Selected instance coordinator is not operational.",
                    false));

            Assert.That(
                AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                    true,
                    true,
                    unavailable),
                Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.RecoverAvailability));

            Assert.That(
                AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(
                    false,
                    false,
                    unavailable),
                Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Deploy));
        }

        [Test]
        public void CurrentInstanceMcpEvidenceBlocked_DoesNotTriggerReplacementDeployment()
        {
            var blocked = AICodedbProductStatusBuilder.Build(
                new AICodedbProjectIntegrationStatus(
                    AICodedbProjectIntegrationState.Installed,
                    AICodedbProjectCleanupState.Complete,
                    string.Empty,
                    "installed"),
                new AICodedbCommandResult(
                    4,
                    "[PRODUCT_LAYER PREREQUISITE] CURRENT\n"
                    + "[PRODUCT_LAYER INSTALLED] CURRENT\n"
                    + "[PRODUCT_LAYER CONFIGURED] CURRENT\n"
                    + "[PRODUCT_LAYER MCP_AVAILABLE] BLOCKED\n"
                    + "[PRODUCT_STATE] NEEDS_ATTENTION\n",
                    "MCP evidence is invalid.",
                    false));

            Assert.That(
                AICodedbEditorLifecycle.ResolveCurrentInstanceConvergencePlan(true, true, blocked),
                Is.EqualTo(AICodedbEditorLifecycle.AICodedbCurrentInstanceConvergencePlan.Blocked));
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

        [TestCase(false, false, false, ExpectedResult = false)]
        [TestCase(true, false, false, ExpectedResult = true)]
        [TestCase(false, true, false, ExpectedResult = true)]
        [TestCase(false, false, true, ExpectedResult = true)]
        public bool ShouldDeferReconcile_DoesNotStartMaintenanceDuringPlayTransition(
            bool isCompiling,
            bool isUpdating,
            bool isPlayingOrWillChangePlaymode)
        {
            return AICodedbEditorLifecycle.ShouldDeferReconcile(
                isCompiling,
                isUpdating,
                isPlayingOrWillChangePlaymode);
        }

        [TestCase(false, false, false, ExpectedResult = false)]
        [TestCase(true, false, false, ExpectedResult = true)]
        [TestCase(false, true, false, ExpectedResult = true)]
        [TestCase(false, false, true, ExpectedResult = true)]
        public bool ShouldSuspendMaintenance_CombinesCompileUpdateAndPlayBoundaries(
            bool isCompiling,
            bool isUpdating,
            bool isPlayModeMaintenanceSuspended)
        {
            return AICodedbEditorLifecycle.ShouldSuspendMaintenance(
                isCompiling,
                isUpdating,
                isPlayModeMaintenanceSuspended);
        }

        [Test]
        public void EditorUpdate_SourceObservesMaintenanceBoundaryBeforeHeartbeatThrottle()
        {
            var source = File.ReadAllText(Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Editor",
                "AICodedbEditorLifecycle.cs"));
            var start = source.IndexOf("private static void OnEditorUpdate()", StringComparison.Ordinal);
            var end = source.IndexOf("internal static bool ShouldRunScheduledReconcile", start, StringComparison.Ordinal);
            Assert.That(start, Is.GreaterThanOrEqualTo(0));
            Assert.That(end, Is.GreaterThan(start));
            var body = source.Substring(start, end - start);
            var boundary = body.IndexOf("ShouldSuspendMaintenance(", StringComparison.Ordinal);
            var throttle = body.IndexOf("EditorApplication.timeSinceStartup < _nextHeartbeatAt", StringComparison.Ordinal);

            Assert.That(body, Does.Contain("EditorApplication.isCompiling"));
            Assert.That(body, Does.Contain("EditorApplication.isUpdating"));
            Assert.That(body, Does.Contain("BackgroundScheduler.SetMaintenanceSuspended(maintenanceSuspended)"));
            Assert.That(body, Does.Contain("SupervisorIntentAdapter.SetMaintenanceSuspended(maintenanceSuspended)"));
            Assert.That(boundary, Is.GreaterThanOrEqualTo(0));
            Assert.That(throttle, Is.GreaterThan(boundary),
                "Compile and Asset Update transitions must invalidate maintenance without waiting for the heartbeat interval.");
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

        [Test]
        public void ShouldRunAutomaticGenerationCleanup_OnlySchedulesCurrentPendingState()
        {
            var pendingCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Current,
                AICodedbStatusState.Ok,
                "poc.31",
                "CURRENT / poc.31",
                string.Empty,
                AICodedbProjectCleanupState.Pending);
            var completeCurrent = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Current,
                AICodedbStatusState.Ok,
                "poc.31",
                "CURRENT / poc.31",
                string.Empty,
                AICodedbProjectCleanupState.Complete);
            var pendingHistorical = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Current,
                AICodedbStatusState.Ok,
                "poc.30",
                "CURRENT / poc.30",
                string.Empty,
                AICodedbProjectCleanupState.Pending);
            var pendingSwitch = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Switching,
                AICodedbStatusState.Warning,
                "poc.31",
                "SWITCHING / poc.31",
                string.Empty,
                AICodedbProjectCleanupState.Pending);

            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticGenerationCleanup(
                pendingCurrent,
                "poc.31"), Is.True);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticGenerationCleanup(
                completeCurrent,
                "poc.31"), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticGenerationCleanup(
                pendingHistorical,
                "poc.31"), Is.False);
            Assert.That(AICodedbEditorLifecycle.ShouldRunAutomaticGenerationCleanup(
                pendingSwitch,
                "poc.31"), Is.False);
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

        private static AICodedbPackageRuntimeContract ReadPackageRuntimeContract()
        {
            return AICodedbPackageRuntimeContractStore.Read(AICodedbPaths.PackageRootPath);
        }

        private static string SupervisorStatusResponse(
            string root,
            string runtime,
            AICodedbPackageRuntimeContract contract,
            string providerReadyAtUtc)
        {
            var target = contract.Target;
            var providerReadyValue = providerReadyAtUtc == null
                ? "null"
                : "\"" + providerReadyAtUtc + "\"";
            var observedAtUtc = DateTimeOffset.UtcNow.ToString("o");
            const string selectedInstanceId = "0123456789abcdef0123456789abcdef";
            const string lifecycleId = "lifecycle-test";
            const string supervisorId = "unity-bridge";
            const string ownerEpoch = "abcdefabcdefabcdefabcdefabcdefab";
            return "{\"ok\":true,\"status\":{"
                   + "\"schema_version\":" + AICodedbSupervisorProtocol.CoordinatorStateSchemaVersion + ","
                   + "\"supervisor_schema_version\":" + AICodedbSupervisorProtocol.SupervisorStateSchemaVersion + ","
                   + "\"protocol_version\":" + AICodedbSupervisorProtocol.Version + ","
                   + "\"supervisor_protocol_version\":" + AICodedbSupervisorProtocol.SupervisorVersion + ","
                   + "\"role\":\"" + AICodedbSupervisorProtocol.SupervisorRole + "\","
                   + "\"root\":\"" + JsonPath(root) + "\","
                   + "\"project_identity\":\"" + AICodedbEditorLifecycle.CreateProjectIdentity(root) + "\","
                   + "\"generation_id\":\"" + target.GenerationId + "\","
                   + "\"target_generation_id\":\"" + target.GenerationId + "\","
                   + "\"selected_generation_id\":\"" + target.GenerationId + "\","
                   + "\"runtime_contract_sha256\":\"" + contract.Sha256 + "\","
                   + "\"generation_disposition\":\"CURRENT\","
                   + "\"runtime\":\"" + JsonPath(runtime) + "\","
                   + "\"control_contract_id\":\"" + contract.ControlContract.Id + "\","
                   + "\"control_contract_version\":" + contract.ControlContract.Version + ","
                   + "\"control_contract_schema_version\":" + contract.ControlContract.SchemaVersion + ","
                   + "\"control_contract_sha256\":\"" + contract.ControlContract.Sha256 + "\","
                   + "\"control_namespace\":\"" + JsonPath(runtime) + "\","
                   + "\"supervisor_pid\":1234,"
                   + "\"selected_instance_id\":\"" + selectedInstanceId + "\","
                   + "\"coordinator_pid\":1234,"
                   + "\"lifecycle_id\":\"" + lifecycleId + "\","
                   + "\"supervisor_id\":\"" + supervisorId + "\","
                   + "\"owner_epoch\":\"" + ownerEpoch + "\","
                   + "\"desired_state\":\"enabled\","
                   + "\"editor_demand\":\"online\","
                   + "\"provider_state\":\"ready\","
                   + "\"provider_ready_at_utc\":" + providerReadyValue + ","
                   + "\"adapter_enabled\":false,"
                   + "\"adapter_state\":\"disabled\","
                   + "\"adapter_worker\":null,"
                   + "\"adapter_worker_state\":\"disabled\","
                   + "\"coordinator_failure_category\":\"NONE\","
                   + "\"operational_readiness\":{"
                   + "\"schema_version\":1,"
                   + "\"observation_id\":\"11111111111111111111111111111111\","
                   + "\"revision\":7,"
                   + "\"observed_at_utc\":\"" + observedAtUtc + "\","
                   + "\"state\":\"core_ready\","
                   + "\"reason_code\":\"COORDINATOR_OPERATIONAL\","
                   + "\"detail\":\"The selected instance Coordinator is operational.\","
                   + "\"coordinator_failure_category\":\"NONE\","
                   + "\"project_root\":\"" + JsonPath(root) + "\","
                   + "\"project_identity\":\"" + AICodedbEditorLifecycle.CreateProjectIdentity(root) + "\","
                   + "\"runtime\":\"" + JsonPath(runtime) + "\","
                   + "\"selected_instance_id\":\"" + selectedInstanceId + "\","
                   + "\"selected_generation_id\":\"" + target.GenerationId + "\","
                   + "\"target_generation_id\":\"" + target.GenerationId + "\","
                   + "\"runtime_contract_sha256\":\"" + contract.Sha256 + "\","
                   + "\"generation_disposition\":\"CURRENT\","
                   + "\"lifecycle_id\":\"" + lifecycleId + "\","
                   + "\"supervisor_id\":\"" + supervisorId + "\","
                   + "\"owner_epoch\":\"" + ownerEpoch + "\","
                   + "\"supervisor_pid\":1234},"
                   + "\"last_event\":\"provider_ready\"}}";
        }

        private static string IntegrationStateJson(string projectRoot)
        {
            return IntegrationStateJson(projectRoot, "PENDING");
        }

        private static string IntegrationStateJson(string projectRoot, string cleanupState)
        {
            return "{\"schema_version\":1,"
                   + "\"managed_by\":\"com.rice.ai-codedb\","
                   + "\"desired_state\":\"UNINSTALLED\","
                   + "\"state_id\":\"0123456789abcdef0123456789abcdef\","
                   + "\"cleanup_state\":\"" + cleanupState + "\","
                   + "\"project_root\":\"" + JsonPath(projectRoot) + "\","
                   + "\"project_identity\":\"" + AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot) + "\","
                   + "\"updated_at_utc\":\"2026-08-14T00:00:00.0000000Z\"}";
        }

        private static void WriteIntegrationState(string projectRoot, string statePath, string cleanupState = "PENDING")
        {
            Directory.CreateDirectory(Path.GetDirectoryName(statePath));
            WriteUtf8NoBom(statePath, IntegrationStateJson(projectRoot, cleanupState));
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
            var target = ReadPackageRuntimeContract().Target;
            var sourceRoot = Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Payload~",
                "Generations",
                target.GenerationId);
            var generationRoot = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                target.GenerationId);
            CopyDirectory(sourceRoot, generationRoot);

            var currentPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(currentPath));
            File.Copy(
                Path.Combine(AICodedbPaths.PackageRootPath, "Payload~", "host-current.json"),
                currentPath,
                true);
            var stableWrapperPath = Path.Combine(
                _projectRoot,
                AICodedbPackageRuntimeContractStore.StableWrapperRelativePath.Replace('/', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(Path.GetDirectoryName(stableWrapperPath));
            File.Copy(
                Path.Combine(
                    AICodedbPaths.PackageRootPath,
                    "Payload~",
                    AICodedbPackageRuntimeContractStore.StableWrapperRelativePath.Replace('/', Path.DirectorySeparatorChar)),
                stableWrapperPath,
                true);
            return Path.Combine(generationRoot, "scripts", "verify-codedb-project.ps1");
        }

        private string InstallPackageDeclaredPreviousInstance(string generationId)
        {
            var packageGenerationRoot = Path.Combine(
                AICodedbPaths.PackageRootPath,
                "Payload~",
                "Generations",
                generationId);
            var generationRoot = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostGenerationsRelativePath,
                generationId);
            CopyDirectory(packageGenerationRoot, generationRoot);

            var generationManifestPath = Path.Combine(generationRoot, "generation-manifest.json");
            var generationManifest = AICodedbStrictJson.ReadObject(
                generationManifestPath,
                1024 * 1024,
                "previous generation fixture manifest");
            var packageVersion = AICodedbStrictJson.GetRequiredString(
                generationManifest,
                "package_version",
                "previous generation fixture manifest");
            var payloadVersion = AICodedbStrictJson.GetRequiredString(
                generationManifest,
                "payload_version",
                "previous generation fixture manifest");
            var payloadSequence = AICodedbStrictJson.GetRequiredInt32(
                generationManifest,
                "payload_sequence",
                "previous generation fixture manifest");
            var bootstrapProtocol = AICodedbStrictJson.GetRequiredInt32(
                generationManifest,
                "bootstrap_protocol",
                "previous generation fixture manifest");
            var generationManifestHash = GetSha256(generationManifestPath);
            const string workerRelativePath = "wrapper/codedb-project-instance-worker.mjs";
            var workerHash = GetSha256(Path.Combine(
                generationRoot,
                workerRelativePath.Replace('/', Path.DirectorySeparatorChar)));
            var generationRelativePath = AICodedbProjectSettings.HostGenerationsRelativePath + "/" + generationId;

            var hostPointerPath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.HostCurrentPointerRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(hostPointerPath));
            WriteUtf8NoBom(
                hostPointerPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"package_version\":\"" + packageVersion + "\","
                + "\"payload_version\":\"" + payloadVersion + "\","
                + "\"payload_sequence\":" + payloadSequence + ","
                + "\"generation_id\":\"" + generationId + "\","
                + "\"generation_relative_path\":\"" + generationRelativePath + "\","
                + "\"generation_manifest_sha256\":\"" + generationManifestHash + "\","
                + "\"bootstrap_protocol\":" + bootstrapProtocol + "}");

            var instanceId = Guid.NewGuid().ToString("N");
            var instanceRelativePath = AICodedbProjectSettings.InstancesRelativePath + "/" + instanceId;
            var instanceRoot = Path.Combine(
                _projectRoot,
                instanceRelativePath.Replace('/', Path.DirectorySeparatorChar));
            foreach (var directory in new[] { "config", "index", "adapter", "watch", "leases", "logs", "tmp" })
                Directory.CreateDirectory(Path.Combine(instanceRoot, directory));
            var stableWrapperPath = Path.Combine(
                _projectRoot,
                AICodedbPackageRuntimeContractStore.StableWrapperRelativePath.Replace('/', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(Path.GetDirectoryName(stableWrapperPath));
            File.WriteAllBytes(
                stableWrapperPath,
                ReadImmutableGitBlob(Poc33WrapperSourceRevision, Poc33WrapperSourcePath));
            var transition = ReadPackageRuntimeContract().Transitions;
            var expectedWrapperHash = string.Empty;
            foreach (var candidate in transition)
            {
                if (string.Equals(candidate.Identity.GenerationId, generationId, StringComparison.Ordinal))
                {
                    expectedWrapperHash = candidate.StableWrapperSha256;
                    break;
                }
            }
            Assert.That(expectedWrapperHash, Is.Not.Empty, "Previous-generation fixture is not declared by the Package contract.");
            Assert.That(GetSha256(stableWrapperPath), Is.EqualTo(expectedWrapperHash));
            var projectIdentity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            var instanceManifestPath = Path.Combine(instanceRoot, "instance.json");
            WriteUtf8NoBom(
                instanceManifestPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"project_identity\":\"" + projectIdentity + "\","
                + "\"instance_id\":\"" + instanceId + "\","
                + "\"instance_relative_path\":\"" + instanceRelativePath + "\","
                + "\"state\":\"READY\","
                + "\"package_version\":\"" + packageVersion + "\","
                + "\"payload_version\":\"" + payloadVersion + "\","
                + "\"payload_sequence\":" + payloadSequence + ","
                + "\"generation_id\":\"" + generationId + "\","
                + "\"generation_relative_path\":\"" + generationRelativePath + "\","
                + "\"generation_manifest_sha256\":\"" + generationManifestHash + "\","
                + "\"bootstrap_protocol\":" + bootstrapProtocol + ","
                + "\"worker_relative_path\":\"" + workerRelativePath + "\","
                + "\"worker_sha256\":\"" + workerHash + "\","
                + "\"created_at_utc\":\"2026-08-26T00:00:00.0000000Z\","
                + "\"verified_at_utc\":\"2026-08-26T00:00:01.0000000Z\"}");

            var instancePointerPath = Path.Combine(
                _projectRoot,
                AICodedbProjectSettings.InstanceCurrentRelativePath);
            Directory.CreateDirectory(Path.GetDirectoryName(instancePointerPath));
            WriteUtf8NoBom(
                instancePointerPath,
                "{\"schema_version\":1,\"managed_by\":\"com.rice.ai-codedb\","
                + "\"project_identity\":\"" + projectIdentity + "\","
                + "\"instance_id\":\"" + instanceId + "\","
                + "\"instance_relative_path\":\"" + instanceRelativePath + "\","
                + "\"instance_manifest_sha256\":\"" + GetSha256(instanceManifestPath) + "\","
                + "\"generation_id\":\"" + generationId + "\","
                + "\"activated_at_utc\":\"2026-08-26T00:00:02.0000000Z\"}");
            return instanceRoot;
        }

        private string InstallGeneration(
            string packageVersion,
            string payloadVersion,
            int payloadSequence,
            string generationId)
        {
            var bootstrapProtocol = ReadPackageRuntimeContract().Target.BootstrapProtocol;
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
                + "\"bootstrap_protocol\":" + bootstrapProtocol + ","
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
                + "\"bootstrap_protocol\":" + bootstrapProtocol + "}");
            return generationFile;
        }

        private static string GetSha256(string path)
        {
            using (var stream = File.OpenRead(path))
            using (var sha256 = SHA256.Create())
                return BitConverter.ToString(sha256.ComputeHash(stream)).Replace("-", string.Empty).ToLowerInvariant();
        }

        private static byte[] ReadImmutableGitBlob(string revision, string relativePath)
        {
            var repositoryRoot = FindRepositoryRoot(AICodedbPaths.PackageRootPath);
            var startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "git.exe",
                Arguments = "cat-file blob " + revision + ":" + relativePath,
                WorkingDirectory = repositoryRoot,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            using (var process = System.Diagnostics.Process.Start(startInfo))
            {
                Assert.That(process, Is.Not.Null, "The immutable Git fixture process could not start.");
                using (var output = new MemoryStream())
                {
                    process.StandardOutput.BaseStream.CopyTo(output);
                    var error = process.StandardError.ReadToEnd();
                    Assert.That(process.WaitForExit(10000), Is.True, "The immutable Git fixture process timed out.");
                    Assert.That(process.ExitCode, Is.Zero, error);
                    return output.ToArray();
                }
            }
        }

        private static string FindRepositoryRoot(string startPath)
        {
            var directory = new DirectoryInfo(startPath);
            while (directory != null)
            {
                if (File.Exists(Path.Combine(directory.FullName, ".git"))
                    || Directory.Exists(Path.Combine(directory.FullName, ".git")))
                    return directory.FullName;
                directory = directory.Parent;
            }
            Assert.Fail("The Editor fixture requires the repository Git root to construct an immutable previous wrapper.");
            return string.Empty;
        }

        private static string GetProjectSnapshot(string root)
        {
            var lines = new List<string>();
            foreach (var directory in Directory.GetDirectories(root, "*", SearchOption.AllDirectories))
            {
                var info = new DirectoryInfo(directory);
                var relative = directory.Substring(root.Length)
                    .TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                    .Replace('\\', '/');
                lines.Add(
                    "D|" + relative + "|" + info.LastWriteTimeUtc.Ticks + "|" + (int)info.Attributes);
            }
            foreach (var file in Directory.GetFiles(root, "*", SearchOption.AllDirectories))
            {
                var info = new FileInfo(file);
                var relative = file.Substring(root.Length)
                    .TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                    .Replace('\\', '/');
                lines.Add(
                    "F|" + relative + "|" + info.Length + "|" + info.LastWriteTimeUtc.Ticks + "|"
                    + (int)info.Attributes + "|" + GetSha256(file));
            }
            lines.Sort(StringComparer.Ordinal);
            return string.Join("\n", lines.ToArray());
        }

        private static string FindExecutableOnPath(string executableName, string pathValue)
        {
            if (string.IsNullOrWhiteSpace(pathValue))
                return string.Empty;
            foreach (var entry in pathValue.Split(Path.PathSeparator))
            {
                var directory = Environment.ExpandEnvironmentVariables(entry.Trim().Trim('"'));
                if (string.IsNullOrWhiteSpace(directory))
                    continue;
                try
                {
                    var candidate = Path.GetFullPath(Path.Combine(directory, executableName));
                    if (File.Exists(candidate))
                        return candidate;
                }
                catch (Exception)
                {
                    // Ignore malformed unrelated PATH entries while locating the fixture runtime.
                }
            }
            return string.Empty;
        }

        private static void WriteProviderFixture(
            string providerRoot,
            bool invalidManifest,
            bool hashMismatch)
        {
            Directory.CreateDirectory(providerRoot);
            var executablePath = Path.Combine(providerRoot, "codebase-mcp.exe");
            var manifestPath = Path.Combine(providerRoot, "provider-manifest.json");
            WriteUtf8NoBom(executablePath, "fixture Provider bytes\n");
            if (invalidManifest)
            {
                WriteUtf8NoBom(manifestPath, "{\"schema_version\":1}\n");
                return;
            }

            var sha256 = hashMismatch ? new string('0', 64) : GetSha256(executablePath);
            var manifest = "{"
                           + "\"schema_version\":1,"
                           + "\"provider_id\":\"killop/codedb-mcp\","
                           + "\"version\":\"0.5.0-28e3912\","
                           + "\"commit\":\"28e3912d5cd67ff3499734984f3e3d626a204796\","
                           + "\"executable\":\"codebase-mcp.exe\","
                           + "\"sha256\":\"" + sha256 + "\","
                           + "\"protocol\":\"codedb-cli-v1\","
                           + "\"source\":\"https://github.com/killop/codedb-mcp\","
                           + "\"supported_package_min_inclusive\":\"0.2.5-preview.5\","
                           + "\"supported_package_max_exclusive\":\"0.2.6\"}"
                           + "\n";
            WriteUtf8NoBom(manifestPath, manifest);
        }

        private void RewriteCurrentPointerManifestHash(string manifestPath)
        {
            var currentPath = Path.Combine(_projectRoot, AICodedbProjectSettings.HostCurrentPointerRelativePath);
            var current = File.ReadAllText(currentPath);
            var expression = new Regex(
                "(?<prefix>\"generation_manifest_sha256\"\\s*:\\s*\")(?<sha>[0-9a-fA-F]{64})(?<suffix>\")",
                RegexOptions.CultureInvariant);
            var matches = expression.Matches(current);
            Assert.That(matches.Count, Is.EqualTo(1), "The Current pointer fixture must contain one manifest hash.");
            var rewritten = expression.Replace(
                current,
                match => match.Groups["prefix"].Value + GetSha256(manifestPath) + match.Groups["suffix"].Value,
                1);
            Assert.That(rewritten, Is.Not.EqualTo(current), "The Current pointer manifest hash must change.");
            File.WriteAllText(currentPath, rewritten);
        }

        private static string InsertAfterRequiredJsonMatch(string json, string pattern, string insertion)
        {
            var expression = new Regex(pattern, RegexOptions.CultureInvariant);
            var matches = expression.Matches(json);
            Assert.That(matches.Count, Is.EqualTo(1), "The JSON fixture mutation target must occur exactly once.");
            var mutated = expression.Replace(json, match => match.Value + insertion, 1);
            Assert.That(mutated, Is.Not.EqualTo(json), "The JSON fixture mutation must change the document.");
            return mutated;
        }

        private static string ReplaceRequiredJsonMatch(string json, string pattern, string replacement)
        {
            var expression = new Regex(pattern, RegexOptions.CultureInvariant);
            var matches = expression.Matches(json);
            Assert.That(matches.Count, Is.EqualTo(1), "The JSON fixture mutation target must occur exactly once.");
            var mutated = expression.Replace(json, replacement, 1);
            Assert.That(mutated, Is.Not.EqualTo(json), "The JSON fixture mutation must change the document.");
            return mutated;
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
