using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
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

        [TestCase(AICodedbProductState.Ready, ExpectedResult = true)]
        [TestCase(AICodedbProductState.Starting, ExpectedResult = false)]
        [TestCase(AICodedbProductState.NeedsAttention, ExpectedResult = false)]
        public bool ReadyPlayResume_RequestsAnInPlaceAvailabilityPass(
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
        public void ReadyCurrentInstance_WithPendingCleanup_DoesNotRunFullConvergence()
        {
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    true,
                    true,
                    AICodedbProductState.Ready,
                    AICodedbProjectCleanupState.Pending),
                Is.False,
                "Retired cleanup must not redeploy an otherwise Ready current instance.");
            Assert.That(
                AICodedbEditorLifecycle.ShouldRunInstalledInstanceConvergence(
                    true,
                    true,
                    AICodedbProductState.Ready,
                    AICodedbProjectCleanupState.Complete),
                Is.False);
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
