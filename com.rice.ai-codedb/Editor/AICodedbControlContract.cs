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
        internal const int DefaultVersion = 1;

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
        InvalidOrAmbiguous
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
            || State == AICodedbControlContractMigrationState.InvalidOrAmbiguous;

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
        private const long MaximumEvidenceBytes = 256 * 1024;
        private const string ManagedBy = "com.rice.ai-codedb";
        private const int LegacySupervisorStateSchemaVersion = 3;
        private const int LegacySupervisorProtocolVersion = 2;
        private const int LegacySupervisorProtocolVersionV1 = 1;

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
            string packageRoot)
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
            var legacyPath = AICodedbControlContract.GetLegacySupervisorRuntimePath(projectRoot);
            try
            {
                var current = InspectNamespace(
                    projectRoot,
                    packageRoot,
                    currentPath,
                    contract,
                    false,
                    runtimeContract);
                if (current.Kind == NamespaceEvidenceKind.Invalid)
                    return Invalid(contract, projectRoot, current.Diagnostic);

                if (current.Kind == NamespaceEvidenceKind.Current)
                {
                    // A valid current namespace is authoritative.  Legacy
                    // evidence is inspected only for diagnostics and can
                    // never downgrade the authenticated current result.
                    var legacyEvidence = InspectLegacyNamespace(
                        projectRoot,
                        packageRoot,
                        legacyPath,
                        contract,
                        runtimeContract);
                    var diagnostic = current.Diagnostic;
                    if (legacyEvidence.Kind == NamespaceEvidenceKind.Invalid
                        || legacyEvidence.Kind == NamespaceEvidenceKind.Obsolete)
                    {
                        diagnostic = AppendDiagnostic(
                            diagnostic,
                            "Legacy namespace evidence was retained for diagnostics and ignored: "
                            + legacyEvidence.Diagnostic);
                    }
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
                        diagnostic);
                }

                var legacy = InspectLegacyNamespace(
                    projectRoot,
                    packageRoot,
                    legacyPath,
                    contract,
                    runtimeContract);
                if (legacy.Kind == NamespaceEvidenceKind.Invalid)
                    return Invalid(contract, projectRoot, legacy.Diagnostic);

                if (legacy.Kind == NamespaceEvidenceKind.Obsolete)
                {
                    return new AICodedbControlContractMigrationStatus(
                        AICodedbControlContractMigrationState.ObsoleteReinstallRequired,
                        contract,
                        currentPath,
                        legacyPath,
                        "This CodeDB installation needs attention. Reinstall CodeDB once to continue.",
                        legacy.Diagnostic);
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
            Invalid
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
            AICodedbPackageRuntimeContract runtimeContract)
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
                        owner);
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
            Dictionary<string, object> owner)
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
                state);
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
                || !string.Equals(generationId, selection.GenerationId, StringComparison.Ordinal)
                || !string.Equals(targetGenerationId, runtimeContract.Target.GenerationId, StringComparison.Ordinal)
                || !string.Equals(selectedGenerationId, selection.GenerationId, StringComparison.Ordinal)
                || !string.Equals(selectedInstanceId, selection.InstanceId, StringComparison.Ordinal)
                || !string.Equals(runtimeContractSha256, runtimeContract.Sha256, StringComparison.OrdinalIgnoreCase)
                || (supervisorProtocol != AICodedbSupervisorProtocol.SupervisorVersion
                    && supervisorProtocol != AICodedbSupervisorProtocol.LegacySupervisorVersion)
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

                // WMIC exposes process creation time at microsecond precision;
                // keep the C# comparison at the same canonical granularity.
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
            Dictionary<string, object> state)
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

            var responseLine = AICodedbSupervisorBridge.SendPipeRequest(
                pipeName,
                AICodedbSupervisorProtocol.BuildStatusRequest(
                    authToken,
                    Guid.NewGuid().ToString("N")),
                CancellationToken.None);
            if (string.IsNullOrWhiteSpace(responseLine))
                throw new InvalidOperationException("Authenticated Supervisor pipe returned no status.");

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
