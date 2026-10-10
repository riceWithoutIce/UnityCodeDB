using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

namespace Rice.AI.Codedb.Editor
{
    /// <summary>
    /// The control-plane identity is separate from the payload generation. A
    /// payload can move from one generation to another without changing the
    /// namespace that owns its Supervisor state; an incompatible control
    /// contract gets a disjoint namespace instead.
    /// </summary>
    internal readonly struct AICodedbControlContractIdentity
    {
        internal const int CurrentSchemaVersion = 1;
        internal const string DefaultId = "v0.3-control";
        internal const int DefaultVersion = 2;

        internal string Id { get; }
        internal int Version { get; }
        internal int SchemaVersion { get; }
        internal string Sha256 { get; }
        internal bool IsDeclared { get; }

        internal AICodedbControlContractIdentity(
            string id,
            int version,
            int schemaVersion,
            string sha256,
            bool isDeclared = true)
        {
            Id = id ?? string.Empty;
            Version = version;
            SchemaVersion = schemaVersion;
            Sha256 = (sha256 ?? string.Empty).ToLowerInvariant();
            IsDeclared = isDeclared;
        }

        internal string CanonicalIdentity => AICodedbControlContract.BuildCanonicalIdentity(
            Id,
            Version,
            SchemaVersion);

        internal string NamespaceRelativePath => AICodedbControlContract.GetNamespaceRelativePath(
            Id,
            Version);

        internal bool IsValid
        {
            get
            {
                return AICodedbControlContract.IsValidId(Id)
                       && Version > 0
                       && SchemaVersion == CurrentSchemaVersion
                       && AICodedbControlContract.IsSha256(Sha256)
                       && string.Equals(
                           Sha256,
                           AICodedbControlContract.ComputeSha256(CanonicalIdentity),
                           StringComparison.OrdinalIgnoreCase);
            }
        }
    }

    internal static class AICodedbControlContract
    {
        internal const string LegacySupervisorRelativePath =
            "AIWork/.runtime/codedb/control/supervisor";
        internal const string NamespaceRootRelativePath =
            "AIWork/.runtime/codedb/control/contracts";

        internal static string BuildCanonicalIdentity(
            string id,
            int version,
            int schemaVersion)
        {
            return string.Join(
                "\n",
                "com.rice.ai-codedb",
                "control-contract",
                id ?? string.Empty,
                version.ToString(CultureInfo.InvariantCulture),
                schemaVersion.ToString(CultureInfo.InvariantCulture));
        }

        internal static string ComputeSha256(string value)
        {
            using (var algorithm = SHA256.Create())
            {
                var bytes = algorithm.ComputeHash(Encoding.UTF8.GetBytes(value ?? string.Empty));
                var builder = new StringBuilder(bytes.Length * 2);
                foreach (var valueByte in bytes)
                    builder.Append(valueByte.ToString("x2", CultureInfo.InvariantCulture));
                return builder.ToString();
            }
        }

        internal static string GetNamespaceRelativePath(string id, int version)
        {
            if (!IsValidId(id) || version <= 0)
                throw new InvalidOperationException("Control contract identity is invalid.");
            return NamespaceRootRelativePath
                   + "/"
                   + id
                   + "/v"
                   + version.ToString(CultureInfo.InvariantCulture)
                   + "/supervisor";
        }

        internal static string GetSupervisorRuntimePath(
            string projectRoot,
            AICodedbControlContractIdentity identity)
        {
            return AICodedbPaths.NormalizePath(Path.Combine(
                projectRoot,
                identity.NamespaceRelativePath));
        }

        internal static string GetLegacySupervisorRuntimePath(string projectRoot)
        {
            return AICodedbPaths.NormalizePath(Path.Combine(
                projectRoot,
                LegacySupervisorRelativePath));
        }

        internal static bool IsValidId(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length > 64)
                return false;
            foreach (var character in value)
            {
                if ((character >= 'A' && character <= 'Z')
                    || (character >= 'a' && character <= 'z')
                    || (character >= '0' && character <= '9')
                    || character == '.'
                    || character == '_'
                    || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        internal static bool IsSha256(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length != 64)
                return false;
            foreach (var character in value)
            {
                if ((character >= '0' && character <= '9')
                    || (character >= 'a' && character <= 'f')
                    || (character >= 'A' && character <= 'F'))
                    continue;
                return false;
            }
            return true;
        }

        internal static AICodedbControlContractIdentity CreateDefaultIdentity()
        {
            var canonical = BuildCanonicalIdentity(
                AICodedbControlContractIdentity.DefaultId,
                AICodedbControlContractIdentity.DefaultVersion,
                AICodedbControlContractIdentity.CurrentSchemaVersion);
            return new AICodedbControlContractIdentity(
                AICodedbControlContractIdentity.DefaultId,
                AICodedbControlContractIdentity.DefaultVersion,
                AICodedbControlContractIdentity.CurrentSchemaVersion,
                ComputeSha256(canonical),
                false);
        }
    }

    internal enum AICodedbControlContractMigrationState
    {
        Missing,
        Current,
        CompatibleStale,
        ObsoleteReinstallRequired,
        InvalidOrAmbiguous,
        TransientAuthenticationUnavailable
    }

    internal readonly struct AICodedbControlContractMigrationStatus
    {
        internal AICodedbControlContractMigrationState State { get; }
        internal AICodedbControlContractIdentity Contract { get; }
        internal string CurrentNamespacePath { get; }
        internal string LegacyNamespacePath { get; }
        internal string Detail { get; }
        internal string DiagnosticDetail { get; }

        internal bool RequiresReinstall =>
            State == AICodedbControlContractMigrationState.ObsoleteReinstallRequired;

        internal bool BlocksAutomaticStart =>
            State == AICodedbControlContractMigrationState.ObsoleteReinstallRequired
            || State == AICodedbControlContractMigrationState.InvalidOrAmbiguous
            || State == AICodedbControlContractMigrationState.TransientAuthenticationUnavailable;

        internal bool IsTransientAuthenticationFailure =>
            State == AICodedbControlContractMigrationState.TransientAuthenticationUnavailable;

        internal bool IsUsableForAutomaticStart =>
            State == AICodedbControlContractMigrationState.Missing
            || State == AICodedbControlContractMigrationState.Current
            || State == AICodedbControlContractMigrationState.CompatibleStale;

        internal AICodedbControlContractMigrationStatus(
            AICodedbControlContractMigrationState state,
            AICodedbControlContractIdentity contract,
            string currentNamespacePath,
            string legacyNamespacePath,
            string detail,
            string diagnosticDetail)
        {
            State = state;
            Contract = contract;
            CurrentNamespacePath = currentNamespacePath ?? string.Empty;
            LegacyNamespacePath = legacyNamespacePath ?? string.Empty;
            Detail = detail ?? string.Empty;
            DiagnosticDetail = diagnosticDetail ?? string.Empty;
        }
    }

    /// <summary>
    /// Read-only classifier for the persisted Supervisor control evidence.
    /// Classification deliberately never removes files, clears leases, or
    /// stops a process. The old fixed namespace is only inspected so it can be
    /// explained to the user and isolated from the new contract.
    /// </summary>
    internal static class AICodedbControlContractMigrationStore
    {
        internal static bool HasOnlyCurrentSupervisorNamespace(string projectRoot, AICodedbControlContractIdentity contract)
        {
            var path = Path.Combine(projectRoot, AICodedbProjectSettings.InstanceControlRelativePath);
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, path);
            if (!Directory.Exists(path)) return !File.Exists(path);
            var supervisorPath = AICodedbControlContract.GetSupervisorRuntimePath(projectRoot, contract);
            var contractPath = Path.GetDirectoryName(supervisorPath);
            foreach (var name in new[] { "contracts", Path.GetFileName(Path.GetDirectoryName(contractPath)),
                Path.GetFileName(contractPath), "supervisor" })
            {
                var entries = Directory.GetFileSystemEntries(path);
                if (entries.Length != 1 || !Directory.Exists(entries[0])
                    || !string.Equals(Path.GetFileName(entries[0]), name, StringComparison.Ordinal)) return false;
                path = entries[0];
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, path);
            }
            return true;
        }

        private const long MaximumEvidenceBytes = 256 * 1024;
        private const string ManagedBy = "com.rice.ai-codedb";
        private const int LegacySupervisorStateSchemaVersion = 3;
        private const int LegacySupervisorProtocolVersion = 2;
        private const int LegacySupervisorProtocolVersionV1 = 1;
        private const int VersionedV1ControlContractVersion = 1;

        // The pre-control-contract Supervisor wrote two different documents.
        // Keep the shared owner identity separate from the state-only fields so
        // a signature-only copy cannot be promoted to OBSOLETE.
        private static readonly string[] LegacyCommonRequiredFields =
        {
            "schema_version",
            "evidence_schema_version",
            "managed_by",
            "role",
            "root",
            "project_identity",
            "runtime",
            "pipe_name",
            "generation_id",
            "target_generation_id",
            "selected_generation_id",
            "selected_instance_id",
            "runtime_contract_sha256",
            "supervisor_protocol_version",
            "generation_disposition",
            "lifecycle_id",
            "supervisor_id",
            "owner_epoch",
            "owner_evidence",
            "supervisor_pid",
            "publication_phase"
        };

        private static readonly string[] LegacyStateRequiredFields =
        {
            // These fields are present only in the old state document. They
            // are the identifying evidence that distinguishes state from lock.
            "owner_started_at_utc",
            "protocol_version",
            "auth_token",
            "desired_state",
            "editor_demand",
            "readiness_state",
            "reason_code",
            "detail",
            "last_event",
            "last_event_detail"
        };

        private static readonly string[] LegacyStateOptionalFields =
        {
            // Added by the old Supervisor after its initial state publication.
            "started_at_utc",
            "operation",
            "event_sequence",
            "coordinator_status",
            "updated_at_utc"
        };

        private static readonly string[] LegacyLockRequiredFields =
        {
            // The lock has no state/readiness fields; this timestamp is part of
            // the createOwnerLockRecord shape.
            "owner_started_at_utc"
        };

        private static readonly string[] LegacyOwnerEvidenceRequiredFields =
        {
            "schema_version",
            "pid",
            "process_start_identity",
            "executable_path",
            "argv_sha256",
            "command_line_sha256"
        };

        internal static AICodedbControlContractMigrationStatus Read(
            string projectRoot,
            string packageRoot,
            Func<string, string, CancellationToken, string> sendPipeRequest = null)
        {
            AICodedbPackageRuntimeContract runtimeContract;
            AICodedbControlContractIdentity contract;
            try
            {
                runtimeContract = AICodedbPackageRuntimeContractStore.Read(packageRoot);
                contract = runtimeContract.ControlContract;
                if (!contract.IsValid)
                    throw new InvalidOperationException("Package control contract identity is invalid.");
            }
            catch (Exception exception)
            {
                return Invalid(
                    AICodedbControlContract.CreateDefaultIdentity(),
                    projectRoot,
                    exception.Message);
            }

            var currentPath = AICodedbControlContract.GetSupervisorRuntimePath(projectRoot, contract);
            var versionedV1Contract = CreateVersionedV1Identity();
            var versionedV1Path = AICodedbControlContract.GetSupervisorRuntimePath(
                projectRoot,
                versionedV1Contract);
            var legacyPath = AICodedbControlContract.GetLegacySupervisorRuntimePath(projectRoot);
            try
            {
                ValidateKnownContractNamespaces(
                    projectRoot,
                    contract,
                    versionedV1Contract);
                var current = InspectNamespace(
                    projectRoot,
                    packageRoot,
                    currentPath,
                    contract,
                    false,
                    runtimeContract,
                    sendPipeRequest);
                if (current.Kind == NamespaceEvidenceKind.Invalid)
                    return Invalid(contract, projectRoot, current.Diagnostic);

                var versionedV1 = InspectVersionedV1Namespace(
                    projectRoot,
                    packageRoot,
                    versionedV1Path,
                    versionedV1Contract);
                if (versionedV1.Kind == NamespaceEvidenceKind.Invalid)
                    return Invalid(contract, projectRoot, versionedV1.Diagnostic);

                var legacy = InspectLegacyNamespace(
                    projectRoot,
                    packageRoot,
                    legacyPath,
                    contract,
                    runtimeContract);
                if (legacy.Kind == NamespaceEvidenceKind.Invalid)
                    return Invalid(contract, projectRoot, legacy.Diagnostic);

                var olderAuthorityCount =
                    (versionedV1.Kind == NamespaceEvidenceKind.Obsolete ? 1 : 0)
                    + (legacy.Kind == NamespaceEvidenceKind.Obsolete ? 1 : 0);
                if (((current.Kind == NamespaceEvidenceKind.Current
                      || current.Kind == NamespaceEvidenceKind.TransientUnavailable) && olderAuthorityCount > 0)
                    || olderAuthorityCount > 1)
                {
                    return Invalid(
                        contract,
                        projectRoot,
                        "Multiple Supervisor control authorities are present; explicit removal cannot select one safely.");
                }

                if (current.Kind == NamespaceEvidenceKind.TransientUnavailable)
                {
                    return new AICodedbControlContractMigrationStatus(
                        AICodedbControlContractMigrationState.TransientAuthenticationUnavailable,
                        contract,
                        currentPath,
                        legacyPath,
                        "Live CodeDB Supervisor authentication is temporarily unavailable.",
                        current.Diagnostic);
                }

                if (current.Kind == NamespaceEvidenceKind.Current)
                {
                    return new AICodedbControlContractMigrationStatus(
                        current.OwnerAlive
                            ? AICodedbControlContractMigrationState.Current
                            : AICodedbControlContractMigrationState.CompatibleStale,
                        contract,
                        currentPath,
                        legacyPath,
                        current.OwnerAlive
                            ? "The current CodeDB control contract is active."
                            : "The current CodeDB control contract is valid and its previous owner has exited.",
                        current.Diagnostic);
                }

                if (versionedV1.Kind == NamespaceEvidenceKind.Obsolete
                    || legacy.Kind == NamespaceEvidenceKind.Obsolete)
                {
                    var obsolete = versionedV1.Kind == NamespaceEvidenceKind.Obsolete
                        ? versionedV1
                        : legacy;
                    return new AICodedbControlContractMigrationStatus(
                        AICodedbControlContractMigrationState.ObsoleteReinstallRequired,
                        contract,
                        currentPath,
                        legacyPath,
                        "This CodeDB installation uses Owner Identity v1. Remove CodeDB Integration explicitly before reinstalling the Package.",
                        obsolete.Diagnostic);
                }

                return new AICodedbControlContractMigrationStatus(
                    AICodedbControlContractMigrationState.Missing,
                    contract,
                    currentPath,
                    legacyPath,
                    "No Supervisor control evidence is present for the current contract.",
                    string.Empty);
            }
            catch (Exception exception)
            {
                return Invalid(contract, projectRoot, exception.Message);
            }
        }

        private static AICodedbControlContractIdentity CreateVersionedV1Identity()
        {
            var canonical = AICodedbControlContract.BuildCanonicalIdentity(
                AICodedbControlContractIdentity.DefaultId,
                VersionedV1ControlContractVersion,
                AICodedbControlContractIdentity.CurrentSchemaVersion);
            return new AICodedbControlContractIdentity(
                AICodedbControlContractIdentity.DefaultId,
                VersionedV1ControlContractVersion,
                AICodedbControlContractIdentity.CurrentSchemaVersion,
                AICodedbControlContract.ComputeSha256(canonical),
                false);
        }

        private static void ValidateKnownContractNamespaces(
            string projectRoot,
            AICodedbControlContractIdentity current,
            AICodedbControlContractIdentity versionedV1)
        {
            var contractsRoot = AICodedbPaths.NormalizePath(Path.Combine(
                projectRoot,
                AICodedbControlContract.NamespaceRootRelativePath));
            if (!Directory.Exists(contractsRoot))
            {
                if (File.Exists(contractsRoot))
                    throw new InvalidOperationException("The Supervisor contracts root is not a directory.");
                return;
            }

            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, contractsRoot);
            var expectedIdRoot = AICodedbPaths.NormalizePath(Path.Combine(
                contractsRoot,
                AICodedbControlContractIdentity.DefaultId));
            foreach (var entry in Directory.GetFileSystemEntries(contractsRoot))
            {
                if (!Directory.Exists(entry)
                    || !AICodedbSupervisorProtocol.PathsEqual(entry, expectedIdRoot))
                {
                    throw new InvalidOperationException(
                        "An unknown Supervisor control-contract authority is present.");
                }
            }

            if (!Directory.Exists(expectedIdRoot))
                return;
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, expectedIdRoot);
            var currentVersionRoot = Directory.GetParent(
                AICodedbControlContract.GetSupervisorRuntimePath(projectRoot, current)).FullName;
            var v1VersionRoot = Directory.GetParent(
                AICodedbControlContract.GetSupervisorRuntimePath(projectRoot, versionedV1)).FullName;
            foreach (var entry in Directory.GetFileSystemEntries(expectedIdRoot))
            {
                if (!Directory.Exists(entry)
                    || (!AICodedbSupervisorProtocol.PathsEqual(entry, currentVersionRoot)
                        && !AICodedbSupervisorProtocol.PathsEqual(entry, v1VersionRoot)))
                {
                    throw new InvalidOperationException(
                        "An unknown Supervisor control-contract version is present.");
                }
            }

            foreach (var versionRoot in new[] { currentVersionRoot, v1VersionRoot })
            {
                if (!Directory.Exists(versionRoot))
                    continue;
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, versionRoot);
                var expectedSupervisor = AICodedbPaths.NormalizePath(Path.Combine(versionRoot, "supervisor"));
                foreach (var entry in Directory.GetFileSystemEntries(versionRoot))
                {
                    var name = Path.GetFileName(entry);
                    var isSupervisor = Directory.Exists(entry)
                                       && AICodedbSupervisorProtocol.PathsEqual(entry, expectedSupervisor);
                    var isActivationFile = File.Exists(entry)
                                           && (string.Equals(name, "activation.json", StringComparison.Ordinal)
                                               || string.Equals(name, "operation.json", StringComparison.Ordinal));
                    var isActivationDirectory = Directory.Exists(entry)
                                                && (string.Equals(name, "operations", StringComparison.Ordinal)
                                                    || string.Equals(name, "retirements", StringComparison.Ordinal));
                    if (!isSupervisor && !isActivationFile && !isActivationDirectory)
                    {
                        throw new InvalidOperationException(
                            "A control-contract version contains an unknown authority entry.");
                    }
                }
            }
        }

        private static NamespaceEvidence InspectVersionedV1Namespace(
            string projectRoot,
            string packageRoot,
            string namespacePath,
            AICodedbControlContractIdentity contract)
        {
            var statePath = Path.Combine(namespacePath, "supervisor-state.json");
            var lockPath = Path.Combine(namespacePath, "supervisor.lock");
            var stateExists = File.Exists(statePath) || Directory.Exists(statePath);
            var lockExists = File.Exists(lockPath) || Directory.Exists(lockPath);
            if (!stateExists && !lockExists)
            {
                if (!Directory.Exists(namespacePath))
                    return new NamespaceEvidence(NamespaceEvidenceKind.Missing, false, string.Empty);
                try
                {
                    return InspectPartialVersionedV1Namespace(
                        projectRoot, packageRoot, namespacePath, contract);
                }
                catch (Exception exception)
                {
                    return new NamespaceEvidence(NamespaceEvidenceKind.Invalid, false, exception.Message);
                }
            }
            if (!stateExists || !lockExists)
            {
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.Invalid,
                    false,
                    "Owner Identity v1 must publish both state and lock evidence.");
            }

            try
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, namespacePath);
                var state = ReadEvidence(statePath, "Owner Identity v1 Supervisor state");
                var owner = ReadEvidence(lockPath, "Owner Identity v1 Supervisor lock");
                if (!SameOwner(state, owner))
                    throw new InvalidOperationException("Owner Identity v1 state and lock identify different owners.");
                ValidateVersionedV1Evidence(projectRoot, namespacePath, contract, state, true);
                ValidateVersionedV1Evidence(projectRoot, namespacePath, contract, owner, false);
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.Obsolete,
                    false,
                    "A complete Package-owned Owner Identity v1 pair is present in its versioned namespace.");
            }
            catch (Exception exception)
            {
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.Invalid,
                    false,
                    exception.Message);
            }
        }

        private static NamespaceEvidence InspectPartialVersionedV1Namespace(
            string projectRoot,
            string packageRoot,
            string namespacePath,
            AICodedbControlContractIdentity contract)
        {
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, namespacePath);
            var entries = Directory.GetFileSystemEntries(namespacePath);
            if (entries.Length == 0)
                return new NamespaceEvidence(NamespaceEvidenceKind.Missing, false, string.Empty);
            var operationPath = Path.Combine(namespacePath, "operation.json");
            var eventsPath = Path.Combine(namespacePath, "supervisor-events.jsonl");
            if (entries.Length != 2 || !File.Exists(operationPath) || !File.Exists(eventsPath))
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor evidence is incomplete or contains unknown entries.");
            foreach (var entry in entries)
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, entry);
                if (!AICodedbSupervisorProtocol.PathsEqual(entry, operationPath)
                    && !AICodedbSupervisorProtocol.PathsEqual(entry, eventsPath))
                    throw new InvalidOperationException("Partial Owner Identity v1 Supervisor evidence contains an unknown entry.");
            }

            var selection = AICodedbCurrentInstanceStore.Read(projectRoot, packageRoot);
            if (selection.State != AICodedbCurrentInstanceState.ObsoleteReinstallRequired)
                throw new InvalidOperationException("Partial Owner Identity v1 control has no authenticated obsolete selection.");
            var lastKnownGoodPath = Path.Combine(projectRoot, "AIWork", ".runtime", "codedb", "control",
                "last-known-good-instance.json");
            var hasLastKnownGood = File.Exists(lastKnownGoodPath) || Directory.Exists(lastKnownGoodPath);
            var selectedIdentity = new AICodedbRuntimeIdentity(
                selection.PackageVersion, selection.PayloadVersion, selection.PayloadSequence,
                selection.GenerationId, selection.BootstrapProtocol);
            if (AICodedbPackageRuntimeContractStore.Read(packageRoot).Classify(selectedIdentity)
                != AICodedbRuntimeGenerationDisposition.TrustedPrevious)
                throw new InvalidOperationException("Partial Owner Identity v1 control is not a Package-declared predecessor.");
            var selectionPath = Path.Combine(projectRoot, "AIWork", ".runtime", "codedb", "control", "current-instance.json");
            var pointer = ReadEvidence(selectionPath, "Owner Identity v1 selection");
            var instance = ReadEvidence(Path.Combine(selection.InstanceRoot, "instance.json"), "Owner Identity v1 instance");
            AICodedbCurrentInstanceStore.ValidateOriginatingAction(instance);
            var instanceHash = AICodedbStrictJson.GetRequiredString(pointer, "instance_manifest_sha256", "Owner Identity v1 selection");
            var generationHash = AICodedbStrictJson.GetRequiredString(instance, "generation_manifest_sha256", "Owner Identity v1 instance");
            var projectIdentity = AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot);

            var failed = ReadEvidence(operationPath, "partial Owner Identity v1 Supervisor operation");
            RequireExactFields(failed,
                new[] { "schema_version", "managed_by", "operation_id", "key", "request_id", "name", "lane", "state", "phase", "owner_epoch", "project_identity", "root", "runtime", "selected_instance_id", "selected_generation_id", "runtime_contract_sha256", "child", "started_at_utc", "completed_at_utc", "result" },
                new[] { "error", "error_code", "handoff_queued", "handoff_reason" },
                "partial Owner Identity v1 Supervisor operation");
            var runtimeHash = AICodedbStrictJson.GetRequiredString(failed, "runtime_contract_sha256", "partial Owner Identity v1 Supervisor operation");
            var failedName = AICodedbStrictJson.GetRequiredString(failed, "name", "partial Owner Identity v1 Supervisor operation");
            if (AICodedbStrictJson.GetRequiredInt32(failed, "schema_version", "partial Owner Identity v1 Supervisor operation") != 1
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "managed_by", "partial Owner Identity v1 Supervisor operation"), ManagedBy, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "state", "partial Owner Identity v1 Supervisor operation"), "failed", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "phase", "partial Owner Identity v1 Supervisor operation"), "failed", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "lane", "partial Owner Identity v1 Supervisor operation"), "maintenance", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "project_identity", "partial Owner Identity v1 Supervisor operation"), projectIdentity, StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(AICodedbStrictJson.GetRequiredString(failed, "root", "partial Owner Identity v1 Supervisor operation"), projectRoot)
                || !AICodedbSupervisorProtocol.PathsEqual(AICodedbStrictJson.GetRequiredString(failed, "runtime", "partial Owner Identity v1 Supervisor operation"), namespacePath)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "selected_instance_id", "partial Owner Identity v1 Supervisor operation"), selection.InstanceId, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(failed, "selected_generation_id", "partial Owner Identity v1 Supervisor operation"), selection.GenerationId, StringComparison.Ordinal)
                || !AICodedbControlContract.IsSha256(runtimeHash)
                || !IsLowercaseId(AICodedbStrictJson.GetRequiredString(failed, "operation_id", "partial Owner Identity v1 Supervisor operation"))
                || !IsLowercaseId(AICodedbStrictJson.GetRequiredString(failed, "owner_epoch", "partial Owner Identity v1 Supervisor operation"))
                || string.IsNullOrWhiteSpace(failedName))
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor operation does not bind the selected project instance.");
            object resultValue;
            if (!failed.TryGetValue("result", out resultValue))
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor result is missing.");
            var result = AICodedbStrictJson.RequireObject(resultValue, "partial Owner Identity v1 Supervisor result");
            if (result.ContainsKey("exit_code")
                ? AICodedbStrictJson.GetRequiredInt32(result, "exit_code", "partial Owner Identity v1 Supervisor result") == 0
                : AICodedbStrictJson.GetRequiredInt32(result, "code", "partial Owner Identity v1 Supervisor result") == 0)
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor operation is not failed.");

            var eventsInfo = new FileInfo(eventsPath);
            if (eventsInfo.Length <= 0 || eventsInfo.Length > 4 * 1024 * 1024)
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor events have an invalid size.");
            RequirePartialV1SupervisorFailureEvents(eventsPath, failed, failedName);

            var versionRoot = Directory.GetParent(namespacePath).FullName;
            var activation = ReadEvidence(Path.Combine(versionRoot, "activation.json"), "Owner Identity v1 activation");
            var journal = ReadEvidence(Path.Combine(versionRoot, "operation.json"), "Owner Identity v1 activation operation");
            var activationRuntimeHash = AICodedbStrictJson.GetRequiredString(
                activation, "runtime_contract_sha256", "Owner Identity v1 activation");
            RequireExactFields(activation,
                new[] { "schema_version", "managed_by", "control_contract", "runtime_contract_sha256", "project_root", "project_identity", "activation_epoch", "operation_id", "candidate", "current", "last_known_good", "publication_phase", "updated_at_utc" },
                Array.Empty<string>(), "Owner Identity v1 activation");
            if (journal.ContainsKey("retirement_intent_path") != journal.ContainsKey("retirement_intent_sha256"))
                throw new InvalidOperationException("Owner Identity v1 activation retirement reference is incomplete.");
            var journalFields = new List<string>
            {
                "schema_version", "managed_by", "control_contract", "runtime_contract_sha256",
                "project_root", "project_identity", "activation_epoch", "operation_id",
                "action", "candidate", "previous_activation_record_sha256", "phase",
                "updated_at_utc", "mutations"
            };
            if (journal.ContainsKey("retirement_intent_path"))
            {
                journalFields.Add("retirement_intent_path");
                journalFields.Add("retirement_intent_sha256");
            }
            RequireExactFields(journal, journalFields.ToArray(), Array.Empty<string>(),
                "Owner Identity v1 activation operation");
            var mutations = AICodedbStrictJson.GetRequiredArray(journal, "mutations", "Owner Identity v1 activation operation");
            var operationId = AICodedbStrictJson.GetRequiredString(journal, "operation_id", "Owner Identity v1 activation operation");
            var epoch = AICodedbStrictJson.GetRequiredString(journal, "activation_epoch", "Owner Identity v1 activation operation");
            if (!IsLowercaseId(operationId) || !IsLowercaseId(epoch)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(activation, "operation_id", "Owner Identity v1 activation"), operationId, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(activation, "activation_epoch", "Owner Identity v1 activation"), epoch, StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(activation, "publication_phase", "Owner Identity v1 activation"), "COMMITTED", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(journal, "phase", "Owner Identity v1 activation operation"), "COMMITTED", StringComparison.Ordinal)
                || !string.Equals(AICodedbStrictJson.GetRequiredString(journal, "action", "Owner Identity v1 activation operation"), "UPGRADE", StringComparison.Ordinal)
                || !AICodedbControlContract.IsSha256(activationRuntimeHash)
                || !MatchesPartialV1ActivationContext(activation, projectRoot, projectIdentity, contract, activationRuntimeHash)
                || !MatchesPartialV1ActivationContext(journal, projectRoot, projectIdentity, contract, activationRuntimeHash)
                || !MatchesPartialV1Candidate(activation, "candidate", selection, instanceHash, generationHash)
                || !MatchesPartialV1Candidate(activation, "current", selection, instanceHash, generationHash)
                || !MatchesPartialV1Candidate(journal, "candidate", selection, instanceHash, generationHash))
                throw new InvalidOperationException("Partial Owner Identity v1 activation evidence does not bind the selection.");
            if (hasLastKnownGood)
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, lastKnownGoodPath);
                if (!File.Exists(lastKnownGoodPath))
                    throw new InvalidOperationException("Partial Owner Identity v1 last-known-good selection is not a regular file.");
                var lastKnownGoodLength = new FileInfo(lastKnownGoodPath).Length;
                if (lastKnownGoodLength <= 0 || lastKnownGoodLength > 64 * 1024
                    || lastKnownGoodLength != new FileInfo(selectionPath).Length)
                    throw new InvalidOperationException("Partial Owner Identity v1 selections do not have identical bounded bytes.");
                var currentBytes = File.ReadAllBytes(selectionPath);
                var lastKnownGoodBytes = File.ReadAllBytes(lastKnownGoodPath);
                if (currentBytes.Length != lastKnownGoodBytes.Length)
                    throw new InvalidOperationException("Partial Owner Identity v1 selections do not have identical bytes.");
                for (var index = 0; index < currentBytes.Length; index++)
                    if (currentBytes[index] != lastKnownGoodBytes[index])
                        throw new InvalidOperationException("Partial Owner Identity v1 selections do not have identical bytes.");
                string selectionHash;
                using (var algorithm = SHA256.Create())
                    selectionHash = BitConverter.ToString(algorithm.ComputeHash(currentBytes)).Replace("-", string.Empty).ToLowerInvariant();
                RequirePartialV1SelectionMutation(mutations, AICodedbProjectSettings.InstanceCurrentRelativePath, selectionHash);
                RequirePartialV1SelectionMutation(mutations,
                    AICodedbProjectSettings.InstanceControlRelativePath + "/last-known-good-instance.json", selectionHash);
            }
            var operationDirectoryRoot = Path.Combine(versionRoot, "operations");
            if (Directory.Exists(operationDirectoryRoot))
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, operationDirectoryRoot);
                var directories = Directory.GetFileSystemEntries(operationDirectoryRoot);
                if (directories.Length == 1)
                    AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, directories[0]);
                if (directories.Length > 1 || (directories.Length == 1
                    && (!Directory.Exists(directories[0])
                        || !string.Equals(Path.GetFileName(directories[0]), operationId, StringComparison.Ordinal)
                        || Directory.GetFileSystemEntries(directories[0]).Length != 0)))
                    throw new InvalidOperationException("Partial Owner Identity v1 activation operation directory is ambiguous.");
            }
            var retirementsRoot = Path.Combine(versionRoot, "retirements");
            if (Directory.Exists(retirementsRoot))
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, retirementsRoot);
                if (Directory.GetFileSystemEntries(retirementsRoot).Length != 0)
                    throw new InvalidOperationException("Partial Owner Identity v1 retirement evidence is not in the reviewed closure.");
            }
            return new NamespaceEvidence(NamespaceEvidenceKind.Obsolete, false,
                "An authenticated partial Owner Identity v1 control state requires explicit integration removal.");
        }

        private static void RequirePartialV1SupervisorFailureEvents(
            string eventsPath, Dictionary<string, object> failed, string failedName)
        {
            const string label = "partial Owner Identity v1 Supervisor event";
            DateTimeOffset startedAt;
            DateTimeOffset completedAt;
            if (!DateTimeOffset.TryParse(AICodedbStrictJson.GetRequiredString(failed, "started_at_utc", label),
                    CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out startedAt)
                || !DateTimeOffset.TryParse(AICodedbStrictJson.GetRequiredString(failed, "completed_at_utc", label),
                    CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out completedAt)
                || startedAt.Offset != TimeSpan.Zero || completedAt.Offset != TimeSpan.Zero
                || completedAt < startedAt)
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor operation timestamps are invalid.");

            var sequence = 0;
            var matchingStarts = 0;
            var matchingFailures = 0;
            var interleavedOperation = false;
            var lastOperationEventMatches = false;
            DateTimeOffset? previousAt = null;
            foreach (var line in File.ReadAllLines(eventsPath))
            {
                var observed = AICodedbStrictJson.ParseObject(line, label);
                RequireExactFields(observed,
                    new[] { "schema_version", "sequence", "at_utc", "event", "detail" },
                    Array.Empty<string>(), label);
                var next = AICodedbStrictJson.GetRequiredInt32(observed, "sequence", label);
                var eventName = AICodedbStrictJson.GetRequiredString(observed, "event", label);
                var detail = AICodedbStrictJson.GetRequiredString(observed, "detail", label);
                DateTimeOffset at;
                if (!DateTimeOffset.TryParse(AICodedbStrictJson.GetRequiredString(observed, "at_utc", label),
                        CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out at)
                    || at.Offset != TimeSpan.Zero
                    || AICodedbStrictJson.GetRequiredInt32(observed, "schema_version", label) != 1)
                    throw new InvalidOperationException("Partial Owner Identity v1 Supervisor event identity or timestamp is invalid.");
                if (next == 1)
                {
                    if (!string.Equals(eventName, "supervisor_started", StringComparison.Ordinal))
                        throw new InvalidOperationException("Partial Owner Identity v1 Supervisor event reset has no session start.");
                    matchingStarts = 0;
                    matchingFailures = 0;
                    interleavedOperation = false;
                    lastOperationEventMatches = false;
                    previousAt = null;
                }
                else if (next != sequence + 1)
                    throw new InvalidOperationException("Partial Owner Identity v1 Supervisor session events are not contiguous.");
                if (previousAt.HasValue && at < previousAt.Value)
                    throw new InvalidOperationException("Partial Owner Identity v1 Supervisor session timestamps are not ordered.");
                sequence = next;
                previousAt = at;

                if (string.Equals(eventName, "operation_started", StringComparison.Ordinal))
                {
                    if (matchingStarts == 1 && matchingFailures == 0)
                        interleavedOperation = true;
                    lastOperationEventMatches = false;
                    if (string.Equals(detail, failedName, StringComparison.Ordinal)
                        && at >= startedAt && at <= completedAt)
                        matchingStarts++;
                }
                else if (string.Equals(eventName, "operation_failed", StringComparison.Ordinal)
                         || string.Equals(eventName, "operation_completed", StringComparison.Ordinal))
                {
                    var currentFailure = string.Equals(eventName, "operation_failed", StringComparison.Ordinal)
                        && string.Equals(detail, failedName, StringComparison.Ordinal)
                        && at >= completedAt && matchingStarts == 1;
                    if (matchingStarts == 1 && matchingFailures == 0 && !currentFailure)
                        interleavedOperation = true;
                    lastOperationEventMatches = false;
                    if (currentFailure)
                    {
                        matchingFailures++;
                        lastOperationEventMatches = true;
                    }
                }
            }
            if (matchingStarts != 1 || matchingFailures != 1 || interleavedOperation || !lastOperationEventMatches)
                throw new InvalidOperationException("Partial Owner Identity v1 Supervisor failure has no unique terminal-session event pair.");
        }

        private static void RequirePartialV1SelectionMutation(List<object> mutations, string target, string expectedHash)
        {
            var matches = 0;
            for (var index = 0; index < mutations.Count; index++)
            {
                var mutation = AICodedbStrictJson.RequireObject(mutations[index], "Owner Identity v1 activation mutation");
                if (!string.Equals(AICodedbStrictJson.GetRequiredString(mutation, "target", "Owner Identity v1 activation mutation"),
                        target, StringComparison.OrdinalIgnoreCase))
                    continue;
                matches++;
                RequireExactFields(mutation,
                    new[] { "index", "target", "mutation", "desired_sha256", "existed_before", "pre_image_sha256" },
                    Array.Empty<string>(), "Owner Identity v1 selection mutation");
                var existedBefore = AICodedbStrictJson.GetRequiredBoolean(mutation, "existed_before", "Owner Identity v1 selection mutation");
                var preImage = mutation["pre_image_sha256"] as string;
                if (AICodedbStrictJson.GetRequiredInt32(mutation, "index", "Owner Identity v1 selection mutation") != index
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(mutation, "target", "Owner Identity v1 selection mutation"), target, StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(mutation, "mutation", "Owner Identity v1 selection mutation"), "write", StringComparison.Ordinal)
                    || !string.Equals(AICodedbStrictJson.GetRequiredString(mutation, "desired_sha256", "Owner Identity v1 selection mutation"), expectedHash, StringComparison.Ordinal)
                    || (existedBefore ? !AICodedbControlContract.IsSha256(preImage) : mutation["pre_image_sha256"] != null))
                    throw new InvalidOperationException("Partial Owner Identity v1 selection mutation does not bind its bytes.");
            }
            if (matches != 1)
                throw new InvalidOperationException("Partial Owner Identity v1 selection mutation is missing or ambiguous.");
        }

        private static bool MatchesPartialV1ActivationContext(
            Dictionary<string, object> value, string projectRoot, string projectIdentity,
            AICodedbControlContractIdentity contract, string runtimeHash)
        {
            object contractValue;
            if (!value.TryGetValue("control_contract", out contractValue)) return false;
            var declared = AICodedbStrictJson.RequireObject(contractValue, "Owner Identity v1 control contract");
            RequireExactFields(declared, new[] { "id", "version", "schema_version", "sha256" },
                Array.Empty<string>(), "Owner Identity v1 control contract");
            return AICodedbStrictJson.GetRequiredInt32(value, "schema_version", "Owner Identity v1 activation") == 1
                && string.Equals(AICodedbStrictJson.GetRequiredString(value, "managed_by", "Owner Identity v1 activation"), ManagedBy, StringComparison.Ordinal)
                && AICodedbSupervisorProtocol.PathsEqual(AICodedbStrictJson.GetRequiredString(value, "project_root", "Owner Identity v1 activation"), projectRoot)
                && string.Equals(AICodedbStrictJson.GetRequiredString(value, "project_identity", "Owner Identity v1 activation"), projectIdentity, StringComparison.Ordinal)
                && string.Equals(AICodedbStrictJson.GetRequiredString(value, "runtime_contract_sha256", "Owner Identity v1 activation"), runtimeHash, StringComparison.Ordinal)
                && string.Equals(AICodedbStrictJson.GetRequiredString(declared, "id", "Owner Identity v1 control contract"), contract.Id, StringComparison.Ordinal)
                && AICodedbStrictJson.GetRequiredInt32(declared, "version", "Owner Identity v1 control contract") == contract.Version
                && AICodedbStrictJson.GetRequiredInt32(declared, "schema_version", "Owner Identity v1 control contract") == contract.SchemaVersion
                && string.Equals(AICodedbStrictJson.GetRequiredString(declared, "sha256", "Owner Identity v1 control contract"), contract.Sha256, StringComparison.Ordinal);
        }

        private static bool MatchesPartialV1Candidate(
            Dictionary<string, object> value, string name, AICodedbCurrentInstanceStatus selection,
            string instanceHash, string generationHash)
        {
            object candidateValue;
            if (!value.TryGetValue(name, out candidateValue)) return false;
            var candidate = AICodedbStrictJson.RequireObject(candidateValue, "Owner Identity v1 activation " + name);
            RequireExactFields(candidate,
                new[] { "instance_id", "generation_id", "instance_manifest_sha256", "generation_manifest_sha256", "generation_disposition" },
                Array.Empty<string>(), "Owner Identity v1 activation " + name);
            return string.Equals(AICodedbStrictJson.GetRequiredString(candidate, "instance_id", name), selection.InstanceId, StringComparison.Ordinal)
                && string.Equals(AICodedbStrictJson.GetRequiredString(candidate, "generation_id", name), selection.GenerationId, StringComparison.Ordinal)
                && string.Equals(AICodedbStrictJson.GetRequiredString(candidate, "instance_manifest_sha256", name), instanceHash, StringComparison.OrdinalIgnoreCase)
                && string.Equals(AICodedbStrictJson.GetRequiredString(candidate, "generation_manifest_sha256", name), generationHash, StringComparison.OrdinalIgnoreCase)
                && string.Equals(AICodedbStrictJson.GetRequiredString(candidate, "generation_disposition", name), "CURRENT", StringComparison.Ordinal);
        }

        private static bool IsLowercaseId(string value)
        {
            if (value == null || value.Length != 32) return false;
            foreach (var character in value)
                if (!((character >= '0' && character <= '9') || (character >= 'a' && character <= 'f')))
                    return false;
            return true;
        }

        private static void RequireExactFields(
            Dictionary<string, object> value, string[] required, string[] optional, string label)
        {
            var allowed = new HashSet<string>(required, StringComparer.Ordinal);
            foreach (var name in optional) allowed.Add(name);
            foreach (var name in required)
                if (!value.ContainsKey(name)) throw new InvalidOperationException(label + " is missing " + name + ".");
            foreach (var name in value.Keys)
                if (!allowed.Contains(name)) throw new InvalidOperationException(label + " contains unknown evidence.");
        }

        private static NamespaceEvidence InspectLegacyNamespace(
            string projectRoot,
            string packageRoot,
            string namespacePath,
            AICodedbControlContractIdentity contract,
            AICodedbPackageRuntimeContract runtimeContract)
        {
            try
            {
                return InspectNamespace(
                    projectRoot,
                    packageRoot,
                    namespacePath,
                    contract,
                    true,
                    runtimeContract);
            }
            catch (Exception exception)
            {
                // Legacy parsing is diagnostic-only when the current
                // namespace is authenticated. Preserve the fail-closed
                // classification for callers that have no current evidence.
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.Invalid,
                    false,
                    exception.Message);
            }
        }

        private static void ValidateVersionedV1Evidence(
            string projectRoot,
            string namespacePath,
            AICodedbControlContractIdentity contract,
            Dictionary<string, object> evidence,
            bool stateDocument)
        {
            var label = stateDocument
                ? "Owner Identity v1 Supervisor state"
                : "Owner Identity v1 Supervisor lock";
            if (evidence == null)
                throw new InvalidOperationException(label + " is missing.");
            if (evidence.ContainsKey("owner_identity_version")
                || evidence.ContainsKey("activation_epoch"))
            {
                throw new InvalidOperationException(
                    label + " mixes Owner Identity v1 with v2-only fields.");
            }
            if (!stateDocument
                && (evidence.ContainsKey("protocol_version")
                    || evidence.ContainsKey("auth_token")))
            {
                throw new InvalidOperationException(
                    "Owner Identity v1 lock evidence has the state-document shape.");
            }

            var schemaVersion = AICodedbStrictJson.GetRequiredInt32(evidence, "schema_version", label);
            var evidenceSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "evidence_schema_version",
                label);
            var managedBy = AICodedbStrictJson.GetRequiredString(evidence, "managed_by", label);
            var role = AICodedbStrictJson.GetRequiredString(evidence, "role", label);
            var root = AICodedbStrictJson.GetRequiredString(evidence, "root", label);
            var projectIdentity = AICodedbStrictJson.GetRequiredString(
                evidence,
                "project_identity",
                label);
            var runtime = AICodedbStrictJson.GetRequiredString(evidence, "runtime", label);
            var contractId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "control_contract_id",
                label);
            var contractVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "control_contract_version",
                label);
            var contractSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "control_contract_schema_version",
                label);
            var contractSha256 = AICodedbStrictJson.GetRequiredString(
                evidence,
                "control_contract_sha256",
                label);
            var controlNamespace = AICodedbStrictJson.GetRequiredString(
                evidence,
                "control_namespace",
                label);
            var pipeValue = AICodedbStrictJson.GetRequiredString(evidence, "pipe_name", label);
            var generationId = AICodedbStrictJson.GetRequiredString(evidence, "generation_id", label);
            var targetGenerationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "target_generation_id",
                label);
            var selectedGenerationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "selected_generation_id",
                label);
            var selectedInstanceId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "selected_instance_id",
                label);
            var runtimeContractSha256 = AICodedbStrictJson.GetRequiredString(
                evidence,
                "runtime_contract_sha256",
                label);
            var supervisorProtocol = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "supervisor_protocol_version",
                label);
            var generationDisposition = AICodedbStrictJson.GetRequiredString(
                evidence,
                "generation_disposition",
                label);
            var lifecycleId = AICodedbStrictJson.GetRequiredString(evidence, "lifecycle_id", label);
            var supervisorId = AICodedbStrictJson.GetRequiredString(evidence, "supervisor_id", label);
            var ownerEpoch = AICodedbStrictJson.GetRequiredString(evidence, "owner_epoch", label);
            var supervisorPid = AICodedbStrictJson.GetRequiredInt32(evidence, "supervisor_pid", label);
            var publicationPhase = AICodedbStrictJson.GetRequiredString(
                evidence,
                "publication_phase",
                label);
            AICodedbStrictJson.GetRequiredString(evidence, "owner_started_at_utc", label);
            if (!evidence.TryGetValue("owner_evidence", out var ownerEvidenceValue))
                throw new InvalidOperationException(label + " is missing owner evidence.");
            var ownerEvidence = AICodedbStrictJson.RequireObject(
                ownerEvidenceValue,
                label + " process evidence");
            ValidateLegacyOwnerEvidenceFieldSet(ownerEvidence, label + " process evidence");
            var ownerEvidenceSchema = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "schema_version",
                label + " process evidence");
            var evidencePid = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "pid",
                label + " process evidence");
            var processStartIdentity = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "process_start_identity",
                label + " process evidence");
            var executablePath = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "executable_path",
                label + " process evidence");
            var argvSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "argv_sha256",
                label + " process evidence");
            var commandLineSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "command_line_sha256",
                label + " process evidence");

            if (stateDocument)
            {
                var protocolVersion = AICodedbStrictJson.GetRequiredInt32(
                    evidence,
                    "protocol_version",
                    label);
                var authToken = AICodedbStrictJson.GetRequiredString(
                    evidence,
                    "auth_token",
                    label);
                AICodedbStrictJson.GetRequiredString(evidence, "desired_state", label);
                AICodedbStrictJson.GetRequiredString(evidence, "editor_demand", label);
                AICodedbStrictJson.GetRequiredString(evidence, "readiness_state", label);
                AICodedbStrictJson.GetRequiredString(evidence, "reason_code", label);
                AICodedbStrictJson.GetRequiredString(evidence, "detail", label);
                AICodedbStrictJson.GetRequiredString(evidence, "last_event", label);
                AICodedbStrictJson.GetRequiredString(evidence, "last_event_detail", label);
                if (protocolVersion != AICodedbSupervisorProtocol.Version
                    || !AICodedbControlContract.IsSha256(authToken))
                {
                    throw new InvalidOperationException(
                        "Owner Identity v1 state protocol or authentication evidence is invalid.");
                }
            }

            if (!AICodedbSupervisorProtocol.TryGetWindowsPipeName(pipeValue, out var pipeName)
                || !AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                    projectRoot,
                    namespacePath,
                    out var expectedPipe)
                || !string.Equals(pipeName, expectedPipe, StringComparison.OrdinalIgnoreCase)
                || schemaVersion != LegacySupervisorStateSchemaVersion
                || evidenceSchemaVersion != 1
                || !string.Equals(managedBy, ManagedBy, StringComparison.Ordinal)
                || !string.Equals(role, AICodedbSupervisorProtocol.SupervisorRole, StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(root, projectRoot)
                || !string.Equals(
                    projectIdentity,
                    AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot),
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(runtime, namespacePath)
                || !string.Equals(contractId, contract.Id, StringComparison.Ordinal)
                || contractVersion != contract.Version
                || contractSchemaVersion != contract.SchemaVersion
                || !string.Equals(contractSha256, contract.Sha256, StringComparison.OrdinalIgnoreCase)
                || !AICodedbSupervisorProtocol.PathsEqual(controlNamespace, namespacePath)
                || !IsBoundedId(generationId, 64)
                || !IsBoundedId(targetGenerationId, 64)
                || !string.Equals(generationId, selectedGenerationId, StringComparison.Ordinal)
                || !IsLowerHex(selectedInstanceId, 32)
                || !AICodedbControlContract.IsSha256(runtimeContractSha256)
                || (supervisorProtocol != AICodedbSupervisorProtocol.SupervisorVersion
                    && supervisorProtocol != LegacySupervisorProtocolVersion
                    && supervisorProtocol != LegacySupervisorProtocolVersionV1)
                || !IsOneOf(generationDisposition, "CURRENT", "TRUSTED_PREVIOUS")
                || (string.Equals(generationDisposition, "CURRENT", StringComparison.Ordinal)
                    ? !string.Equals(generationId, targetGenerationId, StringComparison.Ordinal)
                    : string.Equals(generationId, targetGenerationId, StringComparison.Ordinal))
                || !IsOwnerId(lifecycleId)
                || !IsOwnerId(supervisorId)
                || !IsOwnerId(ownerEpoch)
                || supervisorPid <= 0
                || !IsOneOf(publicationPhase, "state_published", "listening", "retiring")
                || ownerEvidenceSchema != 1
                || evidencePid != supervisorPid
                || !IsProcessStartIdentity(processStartIdentity)
                || !Path.IsPathRooted(executablePath)
                || !AICodedbControlContract.IsSha256(argvSha256)
                || !AICodedbControlContract.IsSha256(commandLineSha256))
            {
                throw new InvalidOperationException(
                    label + " does not match the reviewed Package-owned Owner Identity v1 contract.");
            }
        }

        private static AICodedbControlContractMigrationStatus Invalid(
            AICodedbControlContractIdentity contract,
            string projectRoot,
            string detail)
        {
            string currentPath;
            string legacyPath;
            try
            {
                currentPath = AICodedbControlContract.GetSupervisorRuntimePath(projectRoot, contract);
                legacyPath = AICodedbControlContract.GetLegacySupervisorRuntimePath(projectRoot);
            }
            catch
            {
                currentPath = string.Empty;
                legacyPath = string.Empty;
            }

            return new AICodedbControlContractMigrationStatus(
                AICodedbControlContractMigrationState.InvalidOrAmbiguous,
                contract,
                currentPath,
                legacyPath,
                "CodeDB could not safely identify its control state. No project changes were made.",
                detail);
        }

        private enum NamespaceEvidenceKind
        {
            Missing,
            Current,
            Obsolete,
            Invalid,
            TransientUnavailable
        }

        private sealed class ControlAuthenticationUnavailableException : Exception
        {
            internal ControlAuthenticationUnavailableException(string message) : base(message) { }
        }

        private readonly struct NamespaceEvidence
        {
            internal NamespaceEvidenceKind Kind { get; }
            internal bool OwnerAlive { get; }
            internal string Diagnostic { get; }

            internal NamespaceEvidence(
                NamespaceEvidenceKind kind,
                bool ownerAlive,
                string diagnostic)
            {
                Kind = kind;
                OwnerAlive = ownerAlive;
                Diagnostic = diagnostic ?? string.Empty;
            }
        }

        private static NamespaceEvidence InspectNamespace(
            string projectRoot,
            string packageRoot,
            string namespacePath,
            AICodedbControlContractIdentity contract,
            bool legacy,
            AICodedbPackageRuntimeContract runtimeContract,
            Func<string, string, CancellationToken, string> sendPipeRequest = null)
        {
            var statePath = Path.Combine(namespacePath, "supervisor-state.json");
            var lockPath = Path.Combine(namespacePath, "supervisor.lock");
            var stateExists = File.Exists(statePath) || Directory.Exists(statePath);
            var lockExists = File.Exists(lockPath) || Directory.Exists(lockPath);
            if (!stateExists && !lockExists)
                return new NamespaceEvidence(NamespaceEvidenceKind.Missing, false, string.Empty);

            if (!stateExists || !lockExists)
            {
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.Invalid,
                    false,
                    (legacy ? "Legacy" : "Current")
                    + " Supervisor namespace must publish both state and lock evidence.");
            }

            try
            {
                AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, namespacePath);
                var state = ReadEvidence(statePath, "Supervisor state");
                var owner = ReadEvidence(lockPath, "Supervisor lock");
                if (!SameOwner(state, owner))
                    throw new InvalidOperationException("Supervisor state and lock identify different owners.");

                // The fixed legacy path is diagnostic-only. Even a record that
                // copies the current contract fields into that path cannot
                // become the current namespace authority.
                if (legacy
                    && LooksLikeKnownLegacyEvidence(
                        projectRoot,
                        namespacePath,
                        state,
                        owner))
                {
                    return new NamespaceEvidence(
                        NamespaceEvidenceKind.Obsolete,
                        false,
                        "A known older Supervisor control contract remains under the legacy namespace.");
                }

                if (legacy)
                    throw new InvalidOperationException(
                        "Legacy Supervisor control evidence is not a recognized older contract.");

                if (MatchesCurrentContract(state, contract, namespacePath))
                {
                    var ownerAlive = ValidateCurrentNamespace(
                        projectRoot,
                        packageRoot,
                        namespacePath,
                        runtimeContract,
                        state,
                        owner,
                        sendPipeRequest);
                    return new NamespaceEvidence(
                        NamespaceEvidenceKind.Current,
                        ownerAlive,
                        ownerAlive
                            ? "Current Supervisor contract evidence and owner identity were authenticated."
                            : "Current Supervisor contract evidence is complete and its previous owner has exited.");
                }

                throw new InvalidOperationException(
                    "Supervisor control evidence does not identify the current Package contract.");
            }
            catch (ControlAuthenticationUnavailableException exception)
            {
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.TransientUnavailable,
                    false,
                    exception.Message);
            }
            catch (Exception exception)
            {
                return new NamespaceEvidence(
                    NamespaceEvidenceKind.Invalid,
                    false,
                    exception.Message);
            }
        }

        private static Dictionary<string, object> ReadEvidence(string path, string label)
        {
            if (!File.Exists(path) || (File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0)
                throw new InvalidOperationException(label + " is not a regular file.");
            return AICodedbStrictJson.ReadObject(path, MaximumEvidenceBytes, label);
        }

        private static bool ValidateCurrentNamespace(
            string projectRoot,
            string packageRoot,
            string namespacePath,
            AICodedbPackageRuntimeContract runtimeContract,
            Dictionary<string, object> state,
            Dictionary<string, object> owner,
            Func<string, string, CancellationToken, string> sendPipeRequest)
        {
            if (state == null || owner == null)
                throw new InvalidOperationException(
                    "Current Supervisor namespace must publish both state and lock evidence.");

            var selection = AICodedbCurrentInstanceStore.Read(projectRoot, packageRoot);
            if (!selection.IsCurrent && !selection.IsTrustedPrevious)
            {
                throw new InvalidOperationException(
                    "Current Supervisor evidence does not match a validated instance selection: "
                    + selection.Detail);
            }

            ValidateCurrentEvidence(
                projectRoot,
                namespacePath,
                runtimeContract,
                selection,
                state,
                true);
            ValidateCurrentEvidence(
                projectRoot,
                namespacePath,
                runtimeContract,
                selection,
                owner,
                false);

            // A live PID is not ownership proof by itself.  The recorded start
            // identity and executable must still describe the process that is
            // currently occupying that PID; otherwise the result is ambiguous.
            var ownerAlive = ValidateProcessIdentity(state);
            if (!ownerAlive)
                return false;

            // The canonical pipe is an authenticated second factor.  The
            // Supervisor status response repeats the owner, selection, and
            // process evidence so a forged pair of files cannot become CURRENT.
            ValidateAuthenticatedPipe(
                projectRoot,
                namespacePath,
                runtimeContract,
                selection,
                state,
                sendPipeRequest);
            return true;
        }

        private static void ValidateCurrentEvidence(
            string projectRoot,
            string namespacePath,
            AICodedbPackageRuntimeContract runtimeContract,
            AICodedbCurrentInstanceStatus selection,
            Dictionary<string, object> evidence,
            bool stateDocument)
        {
            var label = stateDocument ? "Supervisor state" : "Supervisor lock";
            if (evidence == null)
                throw new InvalidOperationException(label + " is missing.");

            var schemaVersion = AICodedbStrictJson.GetRequiredInt32(evidence, "schema_version", label);
            var evidenceSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "evidence_schema_version",
                label);
            var managedBy = AICodedbStrictJson.GetRequiredString(evidence, "managed_by", label);
            var role = AICodedbStrictJson.GetRequiredString(evidence, "role", label);
            var root = AICodedbStrictJson.GetRequiredString(evidence, "root", label);
            var projectIdentity = AICodedbStrictJson.GetRequiredString(
                evidence,
                "project_identity",
                label);
            var runtime = AICodedbStrictJson.GetRequiredString(evidence, "runtime", label);
            var contractId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "control_contract_id",
                label);
            var contractVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "control_contract_version",
                label);
            var contractSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "control_contract_schema_version",
                label);
            var contractSha256 = AICodedbStrictJson.GetRequiredString(
                evidence,
                "control_contract_sha256",
                label);
            var controlNamespace = AICodedbStrictJson.GetRequiredString(
                evidence,
                "control_namespace",
                label);
            var ownerIdentityVersion = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "owner_identity_version",
                label);
            var activationEpoch = AICodedbStrictJson.GetRequiredString(
                evidence,
                "activation_epoch",
                label);
            var pipeValue = AICodedbStrictJson.GetRequiredString(evidence, "pipe_name", label);
            var generationId = AICodedbStrictJson.GetRequiredString(evidence, "generation_id", label);
            var targetGenerationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "target_generation_id",
                label);
            var selectedGenerationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "selected_generation_id",
                label);
            var selectedInstanceId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "selected_instance_id",
                label);
            var runtimeContractSha256 = AICodedbStrictJson.GetRequiredString(
                evidence,
                "runtime_contract_sha256",
                label);
            var supervisorProtocol = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "supervisor_protocol_version",
                label);
            var generationDisposition = AICodedbStrictJson.GetRequiredString(
                evidence,
                "generation_disposition",
                label);
            var lifecycleId = AICodedbStrictJson.GetRequiredString(evidence, "lifecycle_id", label);
            var supervisorId = AICodedbStrictJson.GetRequiredString(evidence, "supervisor_id", label);
            var ownerEpoch = AICodedbStrictJson.GetRequiredString(evidence, "owner_epoch", label);
            var supervisorPid = AICodedbStrictJson.GetRequiredInt32(evidence, "supervisor_pid", label);
            var publicationPhase = AICodedbStrictJson.GetRequiredString(
                evidence,
                "publication_phase",
                label);

            object ownerEvidenceValue;
            if (!evidence.TryGetValue("owner_evidence", out ownerEvidenceValue))
                throw new InvalidOperationException(label + " is missing owner evidence.");
            var ownerEvidence = AICodedbStrictJson.RequireObject(
                ownerEvidenceValue,
                label + " process evidence");
            var ownerEvidenceSchemaVersion = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "schema_version",
                label + " process evidence");
            var evidencePid = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "pid",
                label + " process evidence");
            var processStartIdentity = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "process_start_identity",
                label + " process evidence");
            var executablePath = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "executable_path",
                label + " process evidence");
            var argvSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "argv_sha256",
                label + " process evidence");
            var commandLineSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "command_line_sha256",
                label + " process evidence");

            if (stateDocument
                && AICodedbStrictJson.GetRequiredInt32(evidence, "protocol_version", label)
                    != AICodedbSupervisorProtocol.Version)
            {
                throw new InvalidOperationException(label + " protocol version is unsupported.");
            }

            if (stateDocument)
            {
                var authToken = AICodedbStrictJson.GetRequiredString(evidence, "auth_token", label);
                if (!AICodedbControlContract.IsSha256(authToken))
                    throw new InvalidOperationException(label + " authentication token is invalid.");
            }

            var expectedDisposition = selection.IsCurrent ? "CURRENT" : "TRUSTED_PREVIOUS";
            string expectedPipe;
            string pipeName;
            if (!AICodedbSupervisorProtocol.TryGetWindowsPipeName(pipeValue, out pipeName)
                || !AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                    projectRoot,
                    namespacePath,
                    out expectedPipe)
                || !string.Equals(pipeName, expectedPipe, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(label + " pipe identity is not the canonical Package-derived pipe.");
            }

            if (schemaVersion != AICodedbSupervisorProtocol.SupervisorStateSchemaVersion
                || evidenceSchemaVersion != 1
                || !string.Equals(managedBy, ManagedBy, StringComparison.Ordinal)
                || !string.Equals(role, AICodedbSupervisorProtocol.SupervisorRole, StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(root, projectRoot)
                || !string.Equals(
                    projectIdentity,
                    AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot),
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(runtime, namespacePath)
                || !string.Equals(contractId, runtimeContract.ControlContract.Id, StringComparison.Ordinal)
                || contractVersion != runtimeContract.ControlContract.Version
                || contractSchemaVersion != runtimeContract.ControlContract.SchemaVersion
                || !string.Equals(
                    contractSha256,
                    runtimeContract.ControlContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || !AICodedbSupervisorProtocol.PathsEqual(controlNamespace, namespacePath)
                || ownerIdentityVersion != runtimeContract.OwnerIdentityVersion
                || ownerIdentityVersion != selection.OwnerIdentityVersion
                || !string.Equals(activationEpoch, selection.ActivationEpoch, StringComparison.Ordinal)
                || !IsActivationEpoch(activationEpoch)
                || !string.Equals(generationId, selection.GenerationId, StringComparison.Ordinal)
                || !string.Equals(targetGenerationId, runtimeContract.Target.GenerationId, StringComparison.Ordinal)
                || !string.Equals(selectedGenerationId, selection.GenerationId, StringComparison.Ordinal)
                || !string.Equals(selectedInstanceId, selection.InstanceId, StringComparison.Ordinal)
                || !string.Equals(runtimeContractSha256, runtimeContract.Sha256, StringComparison.OrdinalIgnoreCase)
                || supervisorProtocol != AICodedbSupervisorProtocol.SupervisorVersion
                || !string.Equals(generationDisposition, expectedDisposition, StringComparison.Ordinal)
                || !string.Equals(lifecycleId, AICodedbSupervisorProtocol.ClientKind, StringComparison.Ordinal)
                || !string.Equals(supervisorId, AICodedbSupervisorProtocol.ClientKind, StringComparison.Ordinal)
                || !IsOwnerId(ownerEpoch)
                || supervisorPid <= 0
                || evidencePid != supervisorPid
                || ownerEvidenceSchemaVersion != 1
                || !IsProcessStartIdentity(processStartIdentity)
                || !Path.IsPathRooted(executablePath)
                || !AICodedbControlContract.IsSha256(argvSha256)
                || !AICodedbControlContract.IsSha256(commandLineSha256)
                || !IsOneOf(
                    publicationPhase,
                    "state_published",
                    "listening",
                    "retiring"))
            {
                throw new InvalidOperationException(
                    label + " does not match the selected Package control contract and owner identity.");
            }
        }

        private static bool ValidateProcessIdentity(Dictionary<string, object> evidence)
        {
            var pid = GetPositivePid(evidence);
            if (pid <= 0)
                throw new InvalidOperationException("Supervisor process identity has an invalid PID.");

            var ownerEvidence = AICodedbStrictJson.RequireObject(
                evidence["owner_evidence"],
                "Supervisor process evidence");
            var expectedStartIdentity = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "process_start_identity",
                "Supervisor process evidence");
            var expectedExecutablePath = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "executable_path",
                "Supervisor process evidence");

            System.Diagnostics.Process process;
            try
            {
                process = System.Diagnostics.Process.GetProcessById(pid);
            }
            catch (ArgumentException)
            {
                return false;
            }

            using (process)
            {
                bool hasExited;
                try
                {
                    hasExited = process.HasExited;
                }
                catch (Exception exception)
                {
                    throw new InvalidOperationException(
                        "Supervisor process exit state could not be authenticated.",
                        exception);
                }
                if (hasExited)
                    return false;

                DateTime actualStartTime;
                string actualExecutablePath;
                try
                {
                    actualStartTime = process.StartTime.ToUniversalTime();
                    actualExecutablePath = process.MainModule == null
                        ? string.Empty
                        : process.MainModule.FileName;
                }
                catch (Exception exception)
                {
                    throw new InvalidOperationException(
                        "Supervisor process start or executable identity is unavailable.",
                        exception);
                }

                // Owner Identity v2 persists UTC DateTime ticks at the shared
                // 10-tick (microsecond) comparison boundary.
                var canonicalTicks = actualStartTime.Ticks / 10L * 10L;
                var actualStartIdentity = canonicalTicks.ToString(CultureInfo.InvariantCulture);
                if (!string.Equals(actualStartIdentity, expectedStartIdentity, StringComparison.Ordinal)
                    || !AICodedbSupervisorProtocol.PathsEqual(
                        actualExecutablePath,
                        expectedExecutablePath))
                {
                    throw new InvalidOperationException(
                        "Supervisor PID is live but its start or executable identity does not match.");
                }
            }

            return true;
        }

        private static void ValidateAuthenticatedPipe(
            string projectRoot,
            string namespacePath,
            AICodedbPackageRuntimeContract runtimeContract,
            AICodedbCurrentInstanceStatus selection,
            Dictionary<string, object> state,
            Func<string, string, CancellationToken, string> sendPipeRequest)
        {
            const string label = "Authenticated Supervisor status";
            var pipeValue = AICodedbStrictJson.GetRequiredString(state, "pipe_name", "Supervisor state");
            var authToken = AICodedbStrictJson.GetRequiredString(state, "auth_token", "Supervisor state");
            if (!AICodedbSupervisorProtocol.TryGetWindowsPipeName(pipeValue, out var pipeName)
                || !AICodedbSupervisorProtocol.TryGetExpectedSupervisorPipeName(
                    projectRoot,
                    namespacePath,
                    out var expectedPipe)
                || !string.Equals(pipeName, expectedPipe, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    "Supervisor pipe identity is not the canonical Package-derived pipe.");
            }

            string responseLine;
            try
            {
                responseLine = (sendPipeRequest ?? AICodedbSupervisorBridge.SendPipeRequest)(
                    pipeName,
                    AICodedbSupervisorProtocol.BuildStatusRequest(authToken, Guid.NewGuid().ToString("N")),
                    CancellationToken.None);
                if (string.IsNullOrWhiteSpace(responseLine))
                    throw new IOException("Authenticated Supervisor pipe returned no status.");
            }
            catch (Exception exception) when (exception is TimeoutException || exception is IOException)
            {
                // Only a transport failure after the disk/process/pipe checks is
                // transient. Malformed or foreign responses remain invalid.
                throw new ControlAuthenticationUnavailableException(exception.Message);
            }

            var response = AICodedbStrictJson.ParseObject(responseLine, label);
            if (!AICodedbStrictJson.GetRequiredBoolean(response, "ok", label))
            {
                var error = AICodedbStrictJson.GetOptionalNullableString(response, "error", label);
                throw new InvalidOperationException(
                    "Authenticated Supervisor status was refused: "
                    + (error ?? "unknown error") + ".");
            }

            object statusValue;
            if (!response.TryGetValue("status", out statusValue))
                throw new InvalidOperationException("Authenticated Supervisor status is missing.");
            var status = AICodedbStrictJson.RequireObject(statusValue, label);
            var expectedDisposition = selection.IsCurrent ? "CURRENT" : "TRUSTED_PREVIOUS";
            var ownerEvidence = AICodedbStrictJson.RequireObject(
                state["owner_evidence"],
                "Supervisor process evidence");

            if (AICodedbStrictJson.GetRequiredInt32(status, "schema_version", label)
                    != AICodedbSupervisorProtocol.CoordinatorStateSchemaVersion
                || AICodedbStrictJson.GetRequiredInt32(status, "supervisor_schema_version", label)
                    != AICodedbSupervisorProtocol.SupervisorStateSchemaVersion
                || AICodedbStrictJson.GetRequiredInt32(status, "protocol_version", label)
                    != AICodedbSupervisorProtocol.Version
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "role", label),
                    AICodedbSupervisorProtocol.SupervisorRole,
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(
                    AICodedbStrictJson.GetRequiredString(status, "root", label),
                    projectRoot)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "project_identity", label),
                    AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot),
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(
                    AICodedbStrictJson.GetRequiredString(status, "runtime", label),
                    namespacePath)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "control_contract_id", label),
                    runtimeContract.ControlContract.Id,
                    StringComparison.Ordinal)
                || AICodedbStrictJson.GetRequiredInt32(status, "control_contract_version", label)
                    != runtimeContract.ControlContract.Version
                || AICodedbStrictJson.GetRequiredInt32(status, "control_contract_schema_version", label)
                    != runtimeContract.ControlContract.SchemaVersion
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "control_contract_sha256", label),
                    runtimeContract.ControlContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || !AICodedbSupervisorProtocol.PathsEqual(
                    AICodedbStrictJson.GetRequiredString(status, "control_namespace", label),
                    namespacePath)
                || AICodedbStrictJson.GetRequiredInt32(status, "owner_identity_version", label)
                    != runtimeContract.OwnerIdentityVersion
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "activation_epoch", label),
                    selection.ActivationEpoch,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "generation_id", label),
                    selection.GenerationId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "target_generation_id", label),
                    runtimeContract.Target.GenerationId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "selected_generation_id", label),
                    selection.GenerationId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "selected_instance_id", label),
                    selection.InstanceId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "runtime_contract_sha256", label),
                    runtimeContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "generation_disposition", label),
                    expectedDisposition,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "pipe_name", label),
                    pipeValue,
                    StringComparison.OrdinalIgnoreCase)
                || AICodedbStrictJson.GetRequiredInt32(status, "supervisor_protocol_version", label)
                    != AICodedbStrictJson.GetRequiredInt32(
                        state,
                        "supervisor_protocol_version",
                        "Supervisor state")
                || AICodedbStrictJson.GetRequiredInt32(status, "supervisor_pid", label)
                    != AICodedbStrictJson.GetRequiredInt32(state, "supervisor_pid", "Supervisor state")
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "supervisor_id", label),
                    AICodedbStrictJson.GetRequiredString(state, "supervisor_id", "Supervisor state"),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "owner_epoch", label),
                    AICodedbStrictJson.GetRequiredString(state, "owner_epoch", "Supervisor state"),
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "lifecycle_id", label),
                    AICodedbStrictJson.GetRequiredString(state, "lifecycle_id", "Supervisor state"),
                    StringComparison.Ordinal)
                // publication_phase is mutable while the authenticated owner
                // transitions from state publication to listening/retirement.
                // Validate its domain, but do not compare two snapshots at an
                // exact lifecycle instant.
                || !IsOneOf(
                    AICodedbStrictJson.GetRequiredString(status, "publication_phase", label),
                    "state_published",
                    "listening",
                    "retiring")
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "process_start_identity", label),
                    AICodedbStrictJson.GetRequiredString(
                        ownerEvidence,
                        "process_start_identity",
                        "Supervisor process evidence"),
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(
                    AICodedbStrictJson.GetRequiredString(status, "executable_path", label),
                    AICodedbStrictJson.GetRequiredString(
                        ownerEvidence,
                        "executable_path",
                        "Supervisor process evidence"))
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "argv_sha256", label),
                    AICodedbStrictJson.GetRequiredString(
                        ownerEvidence,
                        "argv_sha256",
                        "Supervisor process evidence"),
                    StringComparison.OrdinalIgnoreCase)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(status, "command_line_sha256", label),
                    AICodedbStrictJson.GetRequiredString(
                        ownerEvidence,
                        "command_line_sha256",
                        "Supervisor process evidence"),
                    StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    "Authenticated Supervisor status does not match the current owner and selection evidence.");
            }

            ValidateCoreReadyObservation(
                projectRoot,
                namespacePath,
                runtimeContract,
                selection,
                state,
                status,
                label);
        }

        private static void ValidateCoreReadyObservation(
            string projectRoot,
            string namespacePath,
            AICodedbPackageRuntimeContract runtimeContract,
            AICodedbCurrentInstanceStatus selection,
            Dictionary<string, object> state,
            Dictionary<string, object> status,
            string label)
        {
            object value;
            if (!status.TryGetValue("operational_readiness", out value))
                throw new InvalidOperationException("Authenticated Supervisor status has no operational readiness.");
            var observation = AICodedbStrictJson.RequireObject(
                value,
                "Authenticated Supervisor operational readiness");
            if (!AICodedbSupervisorProtocol.HasExactOperationalReadinessFields(observation))
                throw new InvalidOperationException("Authenticated Supervisor operational readiness fields are invalid.");

            const string observationLabel = "Authenticated Supervisor operational readiness";
            if (AICodedbStrictJson.GetRequiredInt32(observation, "schema_version", observationLabel)
                    != AICodedbSupervisorProtocol.OperationalReadinessSchemaVersion
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "state", observationLabel),
                    "core_ready",
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "reason_code", observationLabel),
                    "COORDINATOR_OPERATIONAL",
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(
                        observation,
                        "coordinator_failure_category",
                        observationLabel),
                    "NONE",
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(
                    AICodedbStrictJson.GetRequiredString(observation, "project_root", observationLabel),
                    projectRoot)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "project_identity", observationLabel),
                    AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot),
                    StringComparison.Ordinal)
                || !AICodedbSupervisorProtocol.PathsEqual(
                    AICodedbStrictJson.GetRequiredString(observation, "runtime", observationLabel),
                    namespacePath)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "selected_instance_id", observationLabel),
                    selection.InstanceId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "selected_generation_id", observationLabel),
                    selection.GenerationId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "target_generation_id", observationLabel),
                    runtimeContract.Target.GenerationId,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "runtime_contract_sha256", observationLabel),
                    runtimeContract.Sha256,
                    StringComparison.OrdinalIgnoreCase)
                || AICodedbStrictJson.GetRequiredInt32(observation, "owner_identity_version", observationLabel)
                    != runtimeContract.OwnerIdentityVersion
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "activation_epoch", observationLabel),
                    selection.ActivationEpoch,
                    StringComparison.Ordinal)
                || !string.Equals(
                    AICodedbStrictJson.GetRequiredString(observation, "owner_epoch", observationLabel),
                    AICodedbStrictJson.GetRequiredString(state, "owner_epoch", "Supervisor state"),
                    StringComparison.Ordinal)
                || AICodedbStrictJson.GetRequiredInt32(observation, "supervisor_pid", observationLabel)
                    != AICodedbStrictJson.GetRequiredInt32(state, "supervisor_pid", "Supervisor state"))
            {
                throw new InvalidOperationException(
                    "Authenticated Supervisor status is not an owner-bound core_ready observation.");
            }
        }

        private static bool IsOneOf(string value, params string[] accepted)
        {
            if (accepted == null)
                return false;
            foreach (var candidate in accepted)
            {
                if (string.Equals(value, candidate, StringComparison.Ordinal))
                    return true;
            }
            return false;
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
                    || character == '.'
                    || character == '_'
                    || character == '-')
                    continue;
                return false;
            }
            return true;
        }

        private static bool IsActivationEpoch(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length != 32)
                return false;
            foreach (var character in value)
            {
                if ((character < '0' || character > '9')
                    && (character < 'a' || character > 'f'))
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

        private static bool SameOwner(
            Dictionary<string, object> left,
            Dictionary<string, object> right)
        {
            foreach (var field in new[]
                     {
                         "project_identity",
                         "generation_id",
                         "control_contract_id",
                         "control_contract_sha256",
                         "selected_instance_id",
                         "selected_generation_id",
                         "target_generation_id",
                         "runtime_contract_sha256",
                         "generation_disposition",
                         "activation_epoch",
                         "lifecycle_id",
                         "supervisor_id",
                         "owner_epoch"
                     })
            {
                var comparison = field.IndexOf("sha256", StringComparison.OrdinalIgnoreCase) >= 0
                    ? StringComparison.OrdinalIgnoreCase
                    : StringComparison.Ordinal;
                if (!string.Equals(OptionalString(left, field), OptionalString(right, field), comparison))
                    return false;
            }

            foreach (var field in new[] { "root", "runtime" })
            {
                if (!AICodedbSupervisorProtocol.PathsEqual(
                        OptionalString(left, field),
                        OptionalString(right, field)))
                    return false;
            }

            if (left.ContainsKey("control_namespace")
                || right.ContainsKey("control_namespace"))
            {
                if (!AICodedbSupervisorProtocol.PathsEqual(
                        OptionalString(left, "control_namespace"),
                        OptionalString(right, "control_namespace")))
                    return false;
            }

            foreach (var field in new[]
                     {
                         "control_contract_version",
                         "control_contract_schema_version",
                         "owner_identity_version",
                         "supervisor_protocol_version"
                     })
            {
                if (OptionalInt32(left, field) != OptionalInt32(right, field))
                    return false;
            }

            if (GetPositivePid(left) != GetPositivePid(right)
                || !string.Equals(
                    OptionalString(left, "pipe_name"),
                    OptionalString(right, "pipe_name"),
                    StringComparison.OrdinalIgnoreCase))
                return false;

            var leftEvidence = OptionalObject(left, "owner_evidence");
            var rightEvidence = OptionalObject(right, "owner_evidence");
            if (leftEvidence == null || rightEvidence == null)
                return false;
            foreach (var field in new[]
                     {
                         "process_start_identity",
                         "executable_path",
                         "argv_sha256",
                         "command_line_sha256"
                     })
            {
                var comparison = field == "executable_path"
                    ? StringComparison.OrdinalIgnoreCase
                    : StringComparison.Ordinal;
                if (field == "executable_path")
                {
                    if (!AICodedbSupervisorProtocol.PathsEqual(
                            OptionalString(leftEvidence, field),
                            OptionalString(rightEvidence, field)))
                        return false;
                }
                else if (!string.Equals(
                             OptionalString(leftEvidence, field),
                             OptionalString(rightEvidence, field),
                             comparison))
                {
                    return false;
                }
            }

            return OptionalInt32(leftEvidence, "schema_version")
                       == OptionalInt32(rightEvidence, "schema_version")
                   && OptionalInt32(leftEvidence, "pid")
                       == OptionalInt32(rightEvidence, "pid");
        }

        private static bool MatchesCurrentContract(
            Dictionary<string, object> evidence,
            AICodedbControlContractIdentity contract,
            string namespacePath)
        {
            var id = OptionalString(evidence, "control_contract_id");
            var version = OptionalInt32(evidence, "control_contract_version");
            var schema = OptionalInt32(evidence, "control_contract_schema_version");
            var hash = OptionalString(evidence, "control_contract_sha256");
            var expectedPath = AICodedbPaths.NormalizePath(namespacePath).TrimEnd('/');
            var recordedPath = OptionalString(evidence, "control_namespace");
            return !string.IsNullOrWhiteSpace(id)
                   && version.HasValue
                   && schema.HasValue
                   && !string.IsNullOrWhiteSpace(hash)
                   && string.Equals(id, contract.Id, StringComparison.Ordinal)
                   && version.Value == contract.Version
                   && schema.Value == contract.SchemaVersion
                   && string.Equals(hash, contract.Sha256, StringComparison.OrdinalIgnoreCase)
                   && !string.IsNullOrWhiteSpace(recordedPath)
                   && string.Equals(
                       AICodedbPaths.NormalizePath(recordedPath).TrimEnd('/'),
                       expectedPath,
                       StringComparison.OrdinalIgnoreCase);
        }

        private static bool LooksLikeKnownLegacyEvidence(
            string projectRoot,
            string namespacePath,
            Dictionary<string, object> state,
            Dictionary<string, object> owner)
        {
            if (state == null
                || owner == null
                || HasCurrentContractEvidence(state)
                || HasCurrentContractEvidence(owner)
                || !SameOwner(state, owner))
                return false;

            return IsCompleteKnownLegacyEvidence(
                       projectRoot,
                       namespacePath,
                       state,
                       true)
                   && IsCompleteKnownLegacyEvidence(
                       projectRoot,
                       namespacePath,
                       owner,
                       false);
        }

        private static bool IsCompleteKnownLegacyEvidence(
            string projectRoot,
            string namespacePath,
            Dictionary<string, object> evidence,
            bool stateDocument)
        {
            var label = stateDocument ? "Legacy Supervisor state" : "Legacy Supervisor lock";
            ValidateLegacyFieldSet(evidence, stateDocument, label);
            var schema = AICodedbStrictJson.GetRequiredInt32(evidence, "schema_version", label);
            var evidenceSchema = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "evidence_schema_version",
                label);
            var managedBy = AICodedbStrictJson.GetRequiredString(evidence, "managed_by", label);
            var role = AICodedbStrictJson.GetRequiredString(evidence, "role", label);
            var root = AICodedbStrictJson.GetRequiredString(evidence, "root", label);
            var projectIdentity = AICodedbStrictJson.GetRequiredString(
                evidence,
                "project_identity",
                label);
            var runtime = AICodedbStrictJson.GetRequiredString(evidence, "runtime", label);
            var pipeValue = AICodedbStrictJson.GetRequiredString(evidence, "pipe_name", label);
            var generationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "generation_id",
                label);
            var targetGenerationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "target_generation_id",
                label);
            var selectedGenerationId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "selected_generation_id",
                label);
            var selectedInstanceId = AICodedbStrictJson.GetRequiredString(
                evidence,
                "selected_instance_id",
                label);
            var runtimeContractSha256 = AICodedbStrictJson.GetRequiredString(
                evidence,
                "runtime_contract_sha256",
                label);
            var supervisorProtocol = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "supervisor_protocol_version",
                label);
            var generationDisposition = AICodedbStrictJson.GetRequiredString(
                evidence,
                "generation_disposition",
                label);
            var lifecycleId = AICodedbStrictJson.GetRequiredString(evidence, "lifecycle_id", label);
            var supervisorId = AICodedbStrictJson.GetRequiredString(evidence, "supervisor_id", label);
            var ownerEpoch = AICodedbStrictJson.GetRequiredString(evidence, "owner_epoch", label);
            var supervisorPid = AICodedbStrictJson.GetRequiredInt32(
                evidence,
                "supervisor_pid",
                label);
            var publicationPhase = AICodedbStrictJson.GetRequiredString(
                evidence,
                "publication_phase",
                label);
            AICodedbStrictJson.GetRequiredString(evidence, "owner_started_at_utc", label);

            if (!evidence.TryGetValue("owner_evidence", out var ownerEvidenceValue))
                throw new InvalidOperationException(label + " is missing owner evidence.");
            var ownerEvidence = AICodedbStrictJson.RequireObject(
                ownerEvidenceValue,
                label + " process evidence");
            ValidateLegacyOwnerEvidenceFieldSet(ownerEvidence, label + " process evidence");
            var ownerEvidenceSchema = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "schema_version",
                label + " process evidence");
            var evidencePid = AICodedbStrictJson.GetRequiredInt32(
                ownerEvidence,
                "pid",
                label + " process evidence");
            var processStartIdentity = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "process_start_identity",
                label + " process evidence");
            var executablePath = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "executable_path",
                label + " process evidence");
            var argvSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "argv_sha256",
                label + " process evidence");
            var commandLineSha256 = AICodedbStrictJson.GetRequiredString(
                ownerEvidence,
                "command_line_sha256",
                label + " process evidence");

            if (stateDocument)
            {
                var protocol = AICodedbStrictJson.GetRequiredInt32(
                    evidence,
                    "protocol_version",
                    label);
                var authToken = AICodedbStrictJson.GetRequiredString(evidence, "auth_token", label);
                AICodedbStrictJson.GetRequiredString(evidence, "desired_state", label);
                AICodedbStrictJson.GetRequiredString(evidence, "editor_demand", label);
                AICodedbStrictJson.GetRequiredString(evidence, "readiness_state", label);
                AICodedbStrictJson.GetRequiredString(evidence, "reason_code", label);
                AICodedbStrictJson.GetRequiredString(evidence, "detail", label);
                AICodedbStrictJson.GetRequiredString(evidence, "last_event", label);
                AICodedbStrictJson.GetRequiredString(evidence, "last_event_detail", label);
                ValidateLegacyStateOptionalFields(evidence, label);
                if (protocol != AICodedbSupervisorProtocol.Version
                    || !AICodedbControlContract.IsSha256(authToken))
                    return false;
            }

            if (!AICodedbSupervisorProtocol.TryGetWindowsPipeName(pipeValue, out var pipeName)
                || !AICodedbSupervisorProtocol.IsExpectedSupervisorPipeName(
                    pipeName,
                    projectRoot,
                    namespacePath,
                    root,
                    runtime))
                return false;

            return schema == LegacySupervisorStateSchemaVersion
                   && evidenceSchema == 1
                   && string.Equals(managedBy, ManagedBy, StringComparison.Ordinal)
                   && string.Equals(
                       role,
                       AICodedbSupervisorProtocol.SupervisorRole,
                       StringComparison.Ordinal)
                   && AICodedbSupervisorProtocol.PathsEqual(root, projectRoot)
                   && string.Equals(
                       projectIdentity,
                       AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot),
                       StringComparison.Ordinal)
                   && AICodedbSupervisorProtocol.PathsEqual(runtime, namespacePath)
                   && IsBoundedId(generationId, 64)
                   && IsBoundedId(targetGenerationId, 64)
                   && string.Equals(generationId, selectedGenerationId, StringComparison.Ordinal)
                   && IsLowerHex(selectedInstanceId, 32)
                   && AICodedbControlContract.IsSha256(runtimeContractSha256)
                   && (supervisorProtocol == LegacySupervisorProtocolVersion
                       || supervisorProtocol == LegacySupervisorProtocolVersionV1)
                   && IsOneOf(generationDisposition, "CURRENT", "TRUSTED_PREVIOUS")
                   && (string.Equals(generationDisposition, "CURRENT", StringComparison.Ordinal)
                       ? string.Equals(generationId, targetGenerationId, StringComparison.Ordinal)
                       : !string.Equals(generationId, targetGenerationId, StringComparison.Ordinal))
                   && IsOwnerId(lifecycleId)
                   && IsOwnerId(supervisorId)
                   && IsOwnerId(ownerEpoch)
                   && supervisorPid > 0
                   && IsOneOf(publicationPhase, "state_published", "listening", "retiring")
                   && ownerEvidenceSchema == 1
                   && evidencePid == supervisorPid
                   && IsProcessStartIdentity(processStartIdentity)
                   && Path.IsPathRooted(executablePath)
                   && AICodedbControlContract.IsSha256(argvSha256)
                   && AICodedbControlContract.IsSha256(commandLineSha256);
        }

        private static bool HasCurrentContractEvidence(Dictionary<string, object> evidence)
        {
            foreach (var field in new[]
                     {
                         "control_contract_id",
                         "control_contract_version",
                         "control_contract_schema_version",
                         "control_contract_sha256",
                         "control_namespace"
                     })
            {
                if (evidence.ContainsKey(field))
                    return true;
            }
            return false;
        }

        private static void ValidateLegacyFieldSet(
            Dictionary<string, object> evidence,
            bool stateDocument,
            string label)
        {
            if (evidence == null)
                throw new InvalidOperationException(label + " is missing.");

            foreach (var field in LegacyCommonRequiredFields)
            {
                if (!evidence.ContainsKey(field))
                    throw new InvalidOperationException(
                        label + " is missing required property " + field + ".");
            }

            var requiredFields = stateDocument
                ? LegacyStateRequiredFields
                : LegacyLockRequiredFields;
            foreach (var field in requiredFields)
            {
                if (!evidence.ContainsKey(field))
                    throw new InvalidOperationException(
                        label + " is missing required property " + field + ".");
            }

            foreach (var field in evidence.Keys)
            {
                if (!IsAllowedLegacyField(field, stateDocument))
                {
                    throw new InvalidOperationException(
                        label + " contains an unknown or conflicting property " + field + ".");
                }
            }
        }

        private static bool IsAllowedLegacyField(string field, bool stateDocument)
        {
            if (IsFieldIn(LegacyCommonRequiredFields, field)
                || IsFieldIn(
                    stateDocument ? LegacyStateRequiredFields : LegacyLockRequiredFields,
                    field))
                return true;

            return stateDocument && IsFieldIn(LegacyStateOptionalFields, field);
        }

        private static bool IsFieldIn(string[] fields, string field)
        {
            if (fields == null || field == null)
                return false;
            foreach (var candidate in fields)
            {
                if (string.Equals(candidate, field, StringComparison.Ordinal))
                    return true;
            }
            return false;
        }

        private static void ValidateLegacyOwnerEvidenceFieldSet(
            Dictionary<string, object> evidence,
            string label)
        {
            if (evidence == null)
                throw new InvalidOperationException(label + " is missing.");

            foreach (var field in LegacyOwnerEvidenceRequiredFields)
            {
                if (!evidence.ContainsKey(field))
                    throw new InvalidOperationException(
                        label + " is missing required property " + field + ".");
            }

            foreach (var field in evidence.Keys)
            {
                if (!IsFieldIn(LegacyOwnerEvidenceRequiredFields, field))
                {
                    throw new InvalidOperationException(
                        label + " contains an unknown property " + field + ".");
                }
            }
        }

        private static void ValidateLegacyStateOptionalFields(
            Dictionary<string, object> evidence,
            string label)
        {
            if (evidence.ContainsKey("started_at_utc"))
                AICodedbStrictJson.GetRequiredString(evidence, "started_at_utc", label);
            if (evidence.ContainsKey("operation")
                && evidence["operation"] != null)
            {
                AICodedbStrictJson.RequireObject(evidence["operation"], label + " operation");
            }
            if (evidence.ContainsKey("event_sequence"))
                AICodedbStrictJson.GetRequiredInt32(evidence, "event_sequence", label);
            if (evidence.ContainsKey("coordinator_status")
                && evidence["coordinator_status"] != null)
            {
                AICodedbStrictJson.RequireObject(
                    evidence["coordinator_status"],
                    label + " coordinator status");
            }
            if (evidence.ContainsKey("updated_at_utc"))
                AICodedbStrictJson.GetRequiredString(evidence, "updated_at_utc", label);
        }

        private static bool IsBoundedId(string value, int maximumLength)
        {
            if (string.IsNullOrEmpty(value) || value.Length > maximumLength)
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

        private static bool IsLowerHex(string value, int length)
        {
            if (string.IsNullOrEmpty(value) || value.Length != length)
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

        private static int GetPositivePid(Dictionary<string, object> evidence)
        {
            var pid = OptionalInt32(evidence, "supervisor_pid");
            if (!pid.HasValue)
                pid = OptionalInt32(evidence, "pid");
            return pid.GetValueOrDefault();
        }

        private static string OptionalString(
            Dictionary<string, object> document,
            string name)
        {
            return document != null && document.TryGetValue(name, out var value) && value is string
                ? (string)value
                : string.Empty;
        }

        private static int? OptionalInt32(
            Dictionary<string, object> document,
            string name)
        {
            if (document == null || !document.TryGetValue(name, out var value))
                return null;
            if (value is int)
                return (int)value;
            if (value is long && (long)value <= int.MaxValue && (long)value >= int.MinValue)
                return (int)(long)value;
            return null;
        }

        private static Dictionary<string, object> OptionalObject(
            Dictionary<string, object> document,
            string name)
        {
            return document != null
                   && document.TryGetValue(name, out var value)
                   && value is Dictionary<string, object>
                ? (Dictionary<string, object>)value
                : null;
        }

        private static string AppendDiagnostic(string primary, string additional)
        {
            if (string.IsNullOrWhiteSpace(additional))
                return primary ?? string.Empty;
            if (string.IsNullOrWhiteSpace(primary))
                return additional;
            return primary + " " + additional;
        }
    }
}
