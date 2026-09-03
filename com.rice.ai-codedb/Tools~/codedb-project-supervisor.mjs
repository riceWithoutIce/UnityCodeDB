#!/usr/bin/env node

// Project-local v0.3 Supervisor.  The immutable Host generation remains the
// coordinator/Provider implementation; this process owns admission, command
// serialization, cached status, and the Bridge-facing IPC boundary.
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const PROTOCOL_VERSION = 1;
const LEGACY_SUPERVISOR_PROTOCOL_VERSION = 1;
const SUPERVISOR_PROTOCOL_VERSION = 2;
const STATE_SCHEMA_VERSION = 3;
const EVIDENCE_SCHEMA_VERSION = 1;
const MAX_MESSAGE_BYTES = 64 * 1024;
const MAX_RUNTIME_CONTRACT_BYTES = 4 * 1024 * 1024;
const MAX_INSTANCE_SELECTION_BYTES = 64 * 1024;
const MAX_INSTANCE_MANIFEST_BYTES = 128 * 1024;
const MAX_GENERATION_MANIFEST_BYTES = 1024 * 1024;
const MAX_INSTANCE_WORKER_BYTES = 4 * 1024 * 1024;
const MAX_GENERATION_FILE_BYTES = 16 * 1024 * 1024;
const MAX_GENERATION_TOTAL_BYTES = 64 * 1024 * 1024;
const MAX_STATE_BYTES = 256 * 1024;
const IPC_TIMEOUT_MS = 1500;
const START_TIMEOUT_MS = 30000;
const POLL_INTERVAL_MS = 1000;
const COORDINATOR_OFFLINE_RETIRE_MS = 5000;
const HANDOFF_OBSERVATION_GRACE_MS = 1000;
const OPERATION_RETENTION_LIMIT = 16;
const LOCK_NAME = "supervisor.lock";
const STATE_NAME = "supervisor-state.json";
const OPERATION_NAME = "operation.json";
const TAKEOVER_CLAIM_NAME = "supervisor-takeover.claim";
const EVENT_NAME = "supervisor-events.jsonl";
const ERROR_NAME = "supervisor-error.json";
const OWNER_STARTUP_GRACE_MS = 5000;
const PROCESS_QUERY_TIMEOUT_MS = 5000;
const CHILD_EVIDENCE_CAPTURE_DELAY_MS = 50;
const MAX_START_CLAIM_RETRIES = 16;
const ATOMIC_RENAME_RETRY_DELAYS_MS = [10, 25, 50, 100, 250, 500];
const ATOMIC_RENAME_RETRYABLE_CODES = new Set(["EACCES", "EBUSY", "EPERM", "EEXIST"]);
const STABLE_WRAPPER_RELATIVE_PATH = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs";

const { command, options } = parseArgs(process.argv.slice(2));
let validatedDaemonContext = null;

async function main() {
  try {
    if (command === "start") {
      await runStart(options);
      return;
    }
    if (command === "daemon") {
      await runDaemon(options);
      return;
    }
    if (command === "status") {
      await runStatus(options);
      return;
    }
    if (command === "stop") {
      await runStop(options);
      return;
    }
    throw new Error("Usage: codedb-project-supervisor.mjs <start|daemon|status|stop> --root <path> --runtime <path> ...");
  } catch (error) {
    if (command === "daemon" && validatedDaemonContext) {
      try {
        writeJson(validatedDaemonContext.errorPath, {
          schema_version: 1,
          created_at_utc: new Date().toISOString(),
          message: error instanceof Error ? error.message : String(error)
        });
      } catch {
        // Preserve the original process error on stderr.
      }
    }
    process.stderr.write(`[ERROR] ${error instanceof Error ? error.message : String(error)}\n`);
    process.exitCode = 1;
  }
}

function parseArgs(args) {
  const parsed = { command: args[0] ?? "", options: {} };
  for (let index = 1; index < args.length; index += 1) {
    const argument = args[index];
    if (!argument.startsWith("--")) {
      throw new Error(`Unexpected argument: ${argument}`);
    }
    const key = argument.slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
    const value = args[index + 1];
    if (value === undefined || value.startsWith("--")) {
      throw new Error(`Missing value for ${argument}`);
    }
    parsed.options[key] = value;
    index += 1;
  }
  return parsed;
}

function getSupervisorRuntimePath(projectRoot, controlContract) {
  if (!controlContract
      || !/^[A-Za-z0-9._-]{1,64}$/.test(controlContract.id)
      || !Number.isSafeInteger(controlContract.version)
      || controlContract.version <= 0) {
    throw new Error("Package control contract identity is invalid.");
  }
  return path.join(
    projectRoot,
    "AIWork",
    ".runtime",
    "codedb",
    "control",
    "contracts",
    controlContract.id,
    `v${controlContract.version}`,
    "supervisor");
}

function readControlContract(manifest, label) {
  const controlContract = manifest.control_contract;
  requireObject(controlContract, `${label}.control_contract`);
  const id = requiredString(controlContract, "id", "Package control contract");
  const version = requiredInteger(controlContract, "version", "Package control contract");
  const schemaVersion = requiredInteger(
    controlContract,
    "schema_version",
    "Package control contract");
  const sha256 = requiredHash(controlContract, "sha256", "Package control contract");
  if (!/^[A-Za-z0-9._-]{1,64}$/.test(id)
      || version <= 0
      || schemaVersion !== 1) {
    throw new Error("Package control contract identity is invalid.");
  }
  const canonicalIdentity = [
    "com.rice.ai-codedb",
    "control-contract",
    id,
    String(version),
    String(schemaVersion)
  ].join("\n");
  if (hashBytes(Buffer.from(canonicalIdentity, "utf8")) !== sha256)
    throw new Error("Package control contract identity hash is invalid.");
  return { id, version, schemaVersion, sha256 };
}

function buildContext(raw) {
  for (const key of ["root", "runtime", "packageRoot"]) {
    if (!raw[key]) {
      throw new Error(`--${key.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`)} is required.`);
    }
  }
  const root = realDirectory(raw.root, "project root");
  const runtime = path.resolve(raw.runtime);
  const packageRoot = realDirectory(raw.packageRoot, "Package root");
  const payloadRoot = path.join(packageRoot, "Payload~");
  assertReviewedPath(packageRoot, payloadRoot, "Package payload root", "directory");
  const runtimeContract = readPackageRuntimeContract(payloadRoot);
  const controlNamespace = getSupervisorRuntimePath(root, runtimeContract.controlContract);
  if (!pathsEqual(runtime, controlNamespace))
    throw new Error("Supervisor runtime does not match the Package-derived control namespace.");
  assertNoRedirectedAncestors(root, runtime, "Supervisor runtime");
  const materializerScript = path.join(packageRoot, "Tools~", "materialize-codedb-host-payload.ps1");
  assertReviewedPath(packageRoot, materializerScript, "Package materializer script", "file");
  const provider = raw.provider ? path.resolve(raw.provider) : "";
  if (provider && !isFile(provider)) throw new Error("Provider executable was not found.");
  const identity = createProjectIdentity(root);
  const selectedInstance = readSelectedInstance(root, runtimeContract);
  const coordinatorScript = path.join(selectedInstance.generationRoot, "coordinator", "codedb-watch-coordinator.mjs");
  const watchManager = path.join(selectedInstance.generationRoot, "scripts", "manage-codedb-project-watch.ps1");
  const coordinatorRuntime = path.join(selectedInstance.instanceRoot, "watch", "coordinator");
  const providerConfig = path.join(selectedInstance.instanceRoot, "config", "codedb-mcp.toml");
  assertReviewedPath(selectedInstance.generationRoot, coordinatorScript, "selected coordinator script", "file");
  assertReviewedPath(selectedInstance.generationRoot, watchManager, "selected watch manager", "file");
  assertNoRedirectedAncestors(selectedInstance.instanceRoot, coordinatorRuntime, "selected coordinator runtime");
  assertReviewedPath(selectedInstance.instanceRoot, providerConfig, "selected Provider config", "file");

  const optionalPathAssertions = {
    coordinatorScript,
    coordinatorRuntime,
    materializerScript,
    payloadRoot,
    watchManager,
    providerConfig
  };
  for (const [name, expected] of Object.entries(optionalPathAssertions)) {
    if (raw[name] && !pathsEqual(path.resolve(raw[name]), expected))
      throw new Error(`--${name.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`)} does not match the Package-derived runtime path.`);
  }
  // CLI diagnostics may omit an explicit identity. Derive a stable project
  // default so status/stop can reconnect to the same owner; Bridge callers
  // still pass their reviewed unity-bridge identity explicitly.
  const supervisorId = validId(raw.supervisorId) || `supervisor-${hash(identity).slice(0, 24)}`;
  const ownerEpoch = validId(raw.ownerEpoch) || crypto.randomUUID().replaceAll("-", "");
  const pipeIdentity = `${canonicalPipeIdentityPath(root)}\n${canonicalPipeIdentityPath(runtime)}`;
  const pipeName = raw.pipeName || `\\\\.\\pipe\\codedb-supervisor-${hash(pipeIdentity).slice(0, 20)}`;
  if (!/^\\\\\.\\pipe\\[^\\/]+$/.test(pipeName)) throw new Error("Supervisor pipe identity is invalid.");
  return {
    root,
    runtime,
    statePath: path.join(runtime, STATE_NAME),
    lockPath: path.join(runtime, LOCK_NAME),
    operationPath: path.join(runtime, OPERATION_NAME),
    takeoverClaimPath: path.join(runtime, TAKEOVER_CLAIM_NAME),
    eventPath: path.join(runtime, EVENT_NAME),
    errorPath: path.join(runtime, ERROR_NAME),
    packageRoot,
    controlContract: runtimeContract.controlContract,
    controlNamespace,
    coordinatorScript,
    coordinatorRuntime,
    materializerScript,
    payloadRoot,
    watchManager,
    provider,
    providerConfig,
    projectIdentity: identity,
    runtimeContract,
    selectedInstance,
    supervisorId,
    ownerEpoch,
    pipeName,
    generationId: selectedInstance.generationId,
    targetGenerationId: runtimeContract.generationId,
    selectedGenerationId: selectedInstance.generationId,
    runtimeContractSha256: runtimeContract.sha256,
    generationDisposition: selectedInstance.disposition,
    lifecycleId: validId(raw.lifecycleId) || supervisorId,
    startupTimeoutMs: positiveInt(raw.startupTimeoutMs, START_TIMEOUT_MS)
  };
}

function buildDaemonArguments(context, ownerEpoch = context.ownerEpoch) {
  const args = [
    fileURLToPath(import.meta.url),
    "daemon",
    "--root", context.root,
    "--runtime", context.runtime,
    "--package-root", context.packageRoot,
    "--lifecycle-id", context.lifecycleId,
    "--supervisor-id", context.supervisorId,
    "--owner-epoch", ownerEpoch,
    "--startup-timeout-ms", String(context.startupTimeoutMs)
  ];
  if (context.provider) args.push("--provider", context.provider);
  if (context.providerConfig) args.push("--provider-config", context.providerConfig);
  return args;
}

async function prepareSupervisorStart(context) {
  const deadline = Date.now() + context.startupTimeoutMs;
  let takeoverObserved = false;
  while (Date.now() < deadline) {
    const inspection = await inspectExistingSupervisor(context);
    if (inspection.classification === "MISSING") {
      const claim = await acquireStartClaim(context);
      if (claim) return { classification: "MISSING", claim };
      await delay(50);
      continue;
    }
    if (inspection.classification === "INVALID_OR_AMBIGUOUS") {
      throw new Error(`Existing project Supervisor evidence is ${inspection.classification}: ${inspection.reason}`);
    }
    if (inspection.classification === "STALE_PROVED") {
      if (takeoverObserved) {
        await delay(50);
        continue;
      }
      takeoverObserved = true;
      const claimed = await takeoverStaleOwner(context, inspection);
      if (!claimed) {
        takeoverObserved = false;
        await delay(50);
        continue;
      }
      const claim = await acquireStartClaim(context);
      if (claim) return { classification: "MISSING", claim };
      await delay(50);
      continue;
    }

    if (inspection.response?.ok && authenticatedStatusMatches(inspection.state, inspection.response.status)) {
      return inspection;
    }
    // A state file can be durable before the named pipe is listening. Keep
    // classifying the same owner during the bounded startup window; never
    // launch a second daemon merely because transport is temporarily absent.
    await delay(100);
  }
  throw new Error("An authenticated project Supervisor owner is present but did not become reachable within the bounded startup window.");
}

async function acquireStartClaim(context, retryCount = 0) {
  if (retryCount >= MAX_START_CLAIM_RETRIES) return null;
  const claimant = getCurrentProcessEvidence(context, "start");
  const claimId = crypto.randomUUID().replaceAll("-", "");
  const claim = {
    schema_version: EVIDENCE_SCHEMA_VERSION,
    managed_by: "com.rice.ai-codedb",
    purpose: "supervisor-start",
    claim_id: claimId,
    project_identity: context.projectIdentity,
    root: context.root,
    runtime: context.runtime,
    claimant_pid: claimant.pid,
    claimant_evidence: publicProcessEvidence(claimant),
    claimed_at_utc: new Date().toISOString()
  };
  let claimFd;
  let created = false;
  try {
    claimFd = fs.openSync(context.takeoverClaimPath, "wx");
    created = true;
    writeFdJson(claimFd, claim);
    fs.closeSync(claimFd);
    claimFd = undefined;
    return { claimId, claimant };
  } catch (error) {
    if (claimFd !== undefined) {
      try { fs.closeSync(claimFd); } catch { /* best effort */ }
    }
    if (created) {
      // A partially written claim is not safe to reinterpret as missing. If
      // it is readable and still carries our id, remove only that claim;
      // otherwise leave the evidence for fail-closed classification.
      try {
        const current = readStartClaim(context);
        if (current?.purpose === claim.purpose && current.claim_id === claim.claim_id)
          fs.rmSync(context.takeoverClaimPath, { force: true });
      } catch { /* preserve malformed evidence for the next classifier */ }
      throw error;
    }
    if (error?.code !== "EEXIST") throw error;
    const claim = readStartClaim(context);
    if (!claim) return null;
    const expected = claim.purpose === "supervisor-start"
      ? validateStartClaim(context, claim)
      : validateTakeoverClaim(context, claim);
    const actual = getProcessEvidenceSync(expected.pid);
    if (!actual.available) throw new Error(actual.error || "Supervisor start claimant identity is unavailable.");
    if (actual.exists && processEvidenceMatches(expected, actual)) return null;
    if (actual.exists) throw new Error("Supervisor start claim is live but its process identity does not match.");
    const owner = await inspectExistingSupervisor(context);
    if (owner.classification !== "MISSING") return null;
    if (!removeClaimIfMatches(context, claim)) return null;
    return acquireStartClaim(context, retryCount + 1);
  }
}

function removeClaimIfMatches(context, expected) {
  try {
    const current = readStartClaim(context);
    if (!current
        || current.purpose !== expected.purpose
        || current.claim_id !== expected.claim_id
        || current.claimant_pid !== expected.claimant_pid
        || (Object.hasOwn(expected, "target_owner_epoch")
            && current.target_owner_epoch !== expected.target_owner_epoch))
      return false;
    fs.rmSync(context.takeoverClaimPath, { force: true });
    return !fs.existsSync(context.takeoverClaimPath);
  } catch {
    return false;
  }
}

function readStartClaim(context) {
  if (!fs.existsSync(context.takeoverClaimPath)) return null;
  try {
    assertReviewedPath(context.runtime, context.takeoverClaimPath, "Supervisor start claim", "file");
    return readRequiredJson(context.takeoverClaimPath, MAX_STATE_BYTES, "Supervisor start claim").value;
  } catch (error) {
    throw new Error(`Supervisor start claim is invalid: ${error.message}`);
  }
}

function validateStartClaim(context, claim) {
  requireObject(claim, "Supervisor start claim");
  if (claim.schema_version !== EVIDENCE_SCHEMA_VERSION
      || claim.managed_by !== "com.rice.ai-codedb"
      || claim.purpose !== "supervisor-start"
      || !validId(claim.claim_id)
      || claim.project_identity !== context.projectIdentity
      || !pathsEqual(claim.root, context.root)
      || !pathsEqual(claim.runtime, context.runtime))
    throw new Error("Supervisor start claim identity does not match the reviewed project runtime.");
  const evidence = validateProcessEvidenceShape(claim.claimant_evidence, "Supervisor start claimant evidence");
  if (evidence.pid !== claim.claimant_pid) throw new Error("Supervisor start claimant PID does not match its evidence.");
  return evidence;
}

function releaseStartClaim(context, claim) {
  if (!claim || !fs.existsSync(context.takeoverClaimPath)) return;
  removeClaimIfMatches(context, {
    purpose: "supervisor-start",
    claim_id: claim.claimId,
    claimant_pid: claim.claimant.pid
  });
}

async function inspectExistingSupervisor(context) {
  const stateExists = fs.existsSync(context.statePath);
  const lockExists = fs.existsSync(context.lockPath);
  if (!stateExists && !lockExists) return { classification: "MISSING", state: null, response: null };

  let state = null;
  let stateError = null;
  if (stateExists) {
    try {
      assertReviewedPath(context.runtime, context.statePath, "Supervisor state", "file");
      state = readRequiredJson(context.statePath, MAX_STATE_BYTES, "Supervisor state").value;
      validateSupervisorState(context, state);
    } catch (error) {
      stateError = error instanceof Error ? error.message : String(error);
    }
  }

  let lock = null;
  let lockError = null;
  if (lockExists) {
    try {
      assertReviewedPath(context.runtime, context.lockPath, "Supervisor lock", "file");
      lock = readRequiredJson(context.lockPath, MAX_STATE_BYTES, "Supervisor lock").value;
      validateSupervisorOwnerRecord(context, lock, "Supervisor lock");
    } catch (error) {
      lockError = error instanceof Error ? error.message : String(error);
    }
  }

  if (stateError || lockError) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response: null,
      reason: stateError || lockError
    };
  }
  const evidenceState = state || lock;
  if (!evidenceState) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response: null,
      reason: lockError || "Supervisor owner evidence is missing."
    };
  }

  let expectedEvidence;
  try {
    expectedEvidence = validateSupervisorOwnerRecord(context, evidenceState, "Supervisor owner evidence");
    if (state && lock && ownerRecordFingerprint(state) !== ownerRecordFingerprint(lock))
      throw new Error("Supervisor state and lock identify different owners.");
  } catch (error) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response: null,
      reason: error instanceof Error ? error.message : String(error)
    };
  }

  const actualEvidence = getProcessEvidenceSync(expectedEvidence.pid);
  if (!actualEvidence.available) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response: null,
      reason: actualEvidence.error || "Supervisor process identity is unavailable."
    };
  }
  if (!actualEvidence.exists) {
    return { classification: "STALE_PROVED", state, lock, response: null, reason: "Recorded Supervisor process is no longer present." };
  }
  if (!processEvidenceMatches(expectedEvidence, actualEvidence)) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response: null,
      reason: "Recorded Supervisor PID is live but its start identity, executable, or argv does not match."
    };
  }
  try {
    if (!pathsEqual(actualEvidence.executablePath, process.execPath))
      throw new Error("Supervisor owner executable is not the reviewed Node runtime.");
    validateSupervisorInvocation(
      context,
      actualEvidence.normalizedArgv,
      "daemon",
      evidenceState.owner_epoch,
      evidenceState.supervisor_protocol_version === LEGACY_SUPERVISOR_PROTOCOL_VERSION);
  } catch (error) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response: null,
      reason: error instanceof Error ? error.message : String(error)
    };
  }

  const response = state?.pipe_name
    ? await requestPipe(state, { command: "status" }, IPC_TIMEOUT_MS)
    : null;
  if (response?.ok && !authenticatedStatusMatches(state, response.status)) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response,
      reason: "Supervisor pipe responded with a different owner identity."
    };
  }
  const publicationAge = Date.now() - parseTimestamp(evidenceState.owner_started_at_utc || evidenceState.updated_at_utc);
  const starting = !response?.ok
    && ["starting", "state_published"].includes(evidenceState.publication_phase)
    && publicationAge >= 0
    && publicationAge <= OWNER_STARTUP_GRACE_MS;
  if (!response?.ok && !starting) {
    return {
      classification: "INVALID_OR_AMBIGUOUS",
      state,
      lock,
      response,
      reason: "Authenticated Supervisor process is live but its published pipe is unavailable outside the startup window."
    };
  }
  return {
    classification: starting ? "STARTING_OWNED" : "LIVE_AUTHENTICATED",
    state,
    lock,
    response,
    reason: response?.ok ? "Authenticated Supervisor pipe is reachable." : "Authenticated Supervisor process is live; pipe is not yet reachable."
  };
}

function ownerRecordFingerprint(value) {
  return hash(JSON.stringify([
    value.owner_epoch,
    value.supervisor_pid,
    value.owner_evidence?.process_start_identity,
    String(value.owner_evidence?.executable_path || "").toLowerCase(),
    value.owner_evidence?.argv_sha256,
    value.owner_evidence?.command_line_sha256,
    value.pipe_name,
    value.control_contract_id,
    value.control_contract_version,
    value.control_contract_schema_version,
    value.control_contract_sha256,
    value.control_namespace,
    value.selected_instance_id,
    value.selected_generation_id,
    value.runtime_contract_sha256
  ]));
}


async function takeoverStaleOwner(context, observed) {
  let claimFd;
  let ownsClaim = false;
  const claimId = crypto.randomUUID().replaceAll("-", "");
  const claimantCommand = process.argv.includes("daemon") ? "daemon" : "start";
  const claimant = getCurrentProcessEvidence(context, claimantCommand);
  try {
    try {
      claimFd = fs.openSync(context.takeoverClaimPath, "wx");
      ownsClaim = true;
    } catch (error) {
      if (error?.code !== "EEXIST") throw error;
      const existingClaim = readStartClaim(context);
      const existingEvidence = validateTakeoverClaim(context, existingClaim);
      const actual = getProcessEvidenceSync(existingEvidence.pid);
      if (!actual.available)
        throw new Error(actual.error || "Supervisor takeover claimant identity is unavailable.");
      if (actual.exists && processEvidenceMatches(existingEvidence, actual)) return false;
      if (actual.exists)
        throw new Error("Supervisor takeover claim is live but its process identity does not match.");
      // The previous claimant is proven dead. Leave the owner evidence in
      // place for the caller to reclassify; only remove this stale claim.
      try { fs.rmSync(context.takeoverClaimPath, { force: true }); } catch { /* retry on the next bounded pass */ }
      return false;
    }
    const claim = {
      schema_version: EVIDENCE_SCHEMA_VERSION,
      managed_by: "com.rice.ai-codedb",
      purpose: "supervisor-takeover",
      claim_id: claimId,
      project_identity: context.projectIdentity,
      root: context.root,
      runtime: context.runtime,
      claimant_pid: claimant.pid,
      claimant_evidence: publicProcessEvidence(claimant),
      target_owner_epoch: observed.state?.owner_epoch || observed.lock?.owner_epoch || null,
      claimed_at_utc: new Date().toISOString()
    };
    writeFdJson(claimFd, claim);
    fs.closeSync(claimFd);
    claimFd = undefined;

    const recheck = await inspectExistingSupervisor(context);
    if (recheck.classification !== "STALE_PROVED") return false;
    // Re-read the claim immediately before quarantining owner evidence. A
    // well-behaved concurrent starter must never have its newer claim removed
    // by a stale-takeover race.
    if (!claimStillOwned(context, claimId, claimant.pid, claim.target_owner_epoch)) return false;
    const suffix = `.stale.${Date.now()}.${crypto.randomUUID().replaceAll("-", "")}`;
    // operation.json is deliberately retained across a stale Supervisor
    // takeover. A new owner must be able to reattach an exactly authenticated
    // child instead of silently discarding an admitted mutation.
    for (const target of [context.statePath, context.lockPath]) {
      if (!claimStillOwned(context, claimId, claimant.pid, claim.target_owner_epoch)) return false;
      if (!fs.existsSync(target)) continue;
      const quarantined = `${target}${suffix}`;
      renameWithRetry(target, quarantined);
    }
    return true;
  } finally {
    if (claimFd !== undefined) {
      try { fs.closeSync(claimFd); } catch { /* best effort */ }
    }
    if (ownsClaim) {
      removeClaimIfMatches(context, {
        purpose: "supervisor-takeover",
        claim_id: claimId,
        claimant_pid: claimant.pid,
        target_owner_epoch: observed.state?.owner_epoch || observed.lock?.owner_epoch || null
      });
    }
  }
}

function claimStillOwned(context, claimId, claimantPid, targetOwnerEpoch) {
  try {
    const current = readStartClaim(context);
    return current?.purpose === "supervisor-takeover"
      && current.claim_id === claimId
      && current.claimant_pid === claimantPid
      && current.target_owner_epoch === targetOwnerEpoch;
  } catch {
    return false;
  }
}

function validateTakeoverClaim(context, claim) {
  requireObject(claim, "Supervisor takeover claim");
  if (claim.schema_version !== EVIDENCE_SCHEMA_VERSION
      || claim.managed_by !== "com.rice.ai-codedb"
      || claim.purpose !== "supervisor-takeover"
      || !validId(claim.claim_id)
      || !validId(claim.target_owner_epoch)
      || claim.project_identity !== context.projectIdentity
      || !pathsEqual(claim.root, context.root)
      || !pathsEqual(claim.runtime, context.runtime))
    throw new Error("Supervisor takeover claim identity does not match the reviewed runtime.");
  const evidence = validateProcessEvidenceShape(claim.claimant_evidence, "Supervisor takeover claimant evidence");
  if (evidence.pid !== claim.claimant_pid)
    throw new Error("Supervisor takeover claimant PID does not match its evidence.");
  return evidence;
}

async function acquireSupervisorLock(context, ownerEvidence) {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    let lockFd;
    try {
      lockFd = fs.openSync(context.lockPath, "wx");
      writeFdJson(lockFd, createOwnerLockRecord(context, ownerEvidence));
      fs.closeSync(lockFd);
      lockFd = undefined;
      return { acquired: true };
    } catch (error) {
      if (lockFd !== undefined) {
        try { fs.closeSync(lockFd); } catch { /* best effort */ }
      }
      if (error?.code !== "EEXIST") throw error;
      const inspection = await inspectExistingSupervisor(context);
      if (inspection.classification === "MISSING") continue;
      if (inspection.classification === "STALE_PROVED") {
        if (await takeoverStaleOwner(context, inspection)) continue;
      }
      return { acquired: false, fd: undefined };
    }
  }
  return { acquired: false, fd: undefined };
}

function createOwnerLockRecord(context, evidence) {
  return {
    schema_version: STATE_SCHEMA_VERSION,
    evidence_schema_version: EVIDENCE_SCHEMA_VERSION,
    managed_by: "com.rice.ai-codedb",
    role: "project-local-supervisor",
    root: context.root,
    project_identity: context.projectIdentity,
    runtime: context.runtime,
    control_contract_id: context.controlContract.id,
    control_contract_version: context.controlContract.version,
    control_contract_schema_version: context.controlContract.schemaVersion,
    control_contract_sha256: context.controlContract.sha256,
    control_namespace: context.controlNamespace,
    pipe_name: context.pipeName,
    generation_id: context.selectedGenerationId,
    target_generation_id: context.targetGenerationId,
    selected_generation_id: context.selectedGenerationId,
    selected_instance_id: context.selectedInstance.instanceId,
    runtime_contract_sha256: context.runtimeContractSha256,
    supervisor_protocol_version: SUPERVISOR_PROTOCOL_VERSION,
    generation_disposition: context.generationDisposition,
    lifecycle_id: context.lifecycleId,
    supervisor_id: context.supervisorId,
    owner_epoch: context.ownerEpoch,
    owner_evidence: publicProcessEvidence(evidence),
    supervisor_pid: evidence.pid,
    publication_phase: "state_published",
    owner_started_at_utc: new Date().toISOString()
  };
}

function validateSupervisorOwnerRecord(context, value, label) {
  requireObject(value, label);
  if (value.schema_version !== STATE_SCHEMA_VERSION
      || value.evidence_schema_version !== EVIDENCE_SCHEMA_VERSION
      || value.managed_by !== "com.rice.ai-codedb"
      || value.role !== "project-local-supervisor"
      || !pathsEqual(value.root, context.root)
      || value.project_identity !== context.projectIdentity
      || !pathsEqual(value.runtime, context.runtime)
      || value.control_contract_id !== context.controlContract.id
      || value.control_contract_version !== context.controlContract.version
      || value.control_contract_schema_version !== context.controlContract.schemaVersion
      || value.control_contract_sha256 !== context.controlContract.sha256
      || !pathsEqual(value.control_namespace, context.controlNamespace)
      || value.pipe_name !== context.pipeName
      || value.generation_id !== context.selectedGenerationId
      || value.target_generation_id !== context.targetGenerationId
      || value.selected_generation_id !== context.selectedGenerationId
      || value.selected_instance_id !== context.selectedInstance.instanceId
      || value.runtime_contract_sha256 !== context.runtimeContractSha256
      || (value.supervisor_protocol_version !== SUPERVISOR_PROTOCOL_VERSION
          && value.supervisor_protocol_version !== LEGACY_SUPERVISOR_PROTOCOL_VERSION)
      || value.generation_disposition !== context.generationDisposition
      || value.lifecycle_id !== context.lifecycleId
      || value.supervisor_id !== context.supervisorId)
    throw new Error(`${label} identity does not match the reviewed project runtime.`);
  if (!validId(value.owner_epoch)) throw new Error(`${label} owner epoch is invalid.`);
  if (!Number.isSafeInteger(value.supervisor_pid) || value.supervisor_pid <= 0)
    throw new Error(`${label} Supervisor PID is invalid.`);
  const evidence = value.owner_evidence;
  const parsed = validateProcessEvidenceShape(evidence, `${label} process evidence`);
  if (parsed.pid !== value.supervisor_pid)
    throw new Error(`${label} process evidence PID does not match the owner PID.`);
  if (!/^\\\\\.\\pipe\\[^\\/]+$/.test(String(value.pipe_name || "")))
    throw new Error(`${label} pipe identity is invalid.`);
  return parsed;
}

function parseTimestamp(value) {
  const parsed = Date.parse(String(value || ""));
  return Number.isFinite(parsed) ? parsed : Date.now();
}

function writeFdJson(fd, value) {
  const bytes = Buffer.from(`${JSON.stringify(value, null, 2)}\n`, "utf8");
  fs.writeSync(fd, bytes, 0, bytes.length, 0);
  fs.fsyncSync(fd);
}

function renameWithRetry(source, target) {
  let lastError;
  for (let attempt = 0; attempt <= ATOMIC_RENAME_RETRY_DELAYS_MS.length; attempt += 1) {
    try {
      fs.renameSync(source, target);
      return;
    } catch (error) {
      lastError = error;
      if (!ATOMIC_RENAME_RETRYABLE_CODES.has(error?.code) || attempt === ATOMIC_RENAME_RETRY_DELAYS_MS.length)
        throw error;
      sleepSync(ATOMIC_RENAME_RETRY_DELAYS_MS[attempt]);
    }
  }
  throw lastError;
}

function sleepSync(milliseconds) {
  const wait = new Int32Array(new SharedArrayBuffer(4));
  Atomics.wait(wait, 0, 0, milliseconds);
}

function removeOwnedRuntimeEvidence(context, target, ownerEpoch) {
  if (!fs.existsSync(target)) return;
  try {
    assertReviewedPath(context.runtime, target, "Supervisor runtime evidence", "file");
    const value = readRequiredJson(target, MAX_STATE_BYTES, "Supervisor runtime evidence").value;
    if (value.owner_epoch !== ownerEpoch) return;
    fs.rmSync(target, { force: true });
  } catch {
    // Never remove malformed or redirected evidence during shutdown. Leaving
    // it allows the next start to classify it and fail closed.
  }
}

async function runStart(raw) {
  const context = buildContext(raw);
  fs.mkdirSync(context.runtime, { recursive: true });
  const preparation = await prepareSupervisorStart(context);
  const startClaim = preparation?.claim;
  if (preparation?.classification === "LIVE_AUTHENTICATED") {
    print("ATTACHED", { action: "attached", status: preparation.response.status });
    return;
  }

  fs.mkdirSync(context.runtime, { recursive: true });
  const args = buildDaemonArguments(context);
  const daemon = spawn(process.execPath, args, {
    cwd: context.root,
    detached: true,
    stdio: "ignore",
    windowsHide: true,
    env: { ...process.env, RICE_CODEDB_UNITY_ROOT: context.root }
  });
  daemon.unref();
  const started = Date.now();
  try {
    while (Date.now() - started < context.startupTimeoutMs) {
      const state = readOptionalJson(context.statePath, MAX_STATE_BYTES, "Supervisor state");
      if (state?.pipe_name && state.auth_token) {
        validateSupervisorState(context, state);
        const response = await requestPipe(state, { command: "status" }, IPC_TIMEOUT_MS);
        if (response?.ok && authenticatedStatusMatches(state, response.status)) {
          print("STARTED", { action: "started", status: response.status });
          return;
        }
      }
      const error = readOptionalJson(context.errorPath, MAX_STATE_BYTES, "Supervisor error state");
      if (error?.message) throw new Error(`Supervisor daemon failed: ${error.message}`);
      await delay(100);
    }
    throw new Error(`Timed out after ${context.startupTimeoutMs} ms waiting for the project Supervisor.`);
  } finally {
    releaseStartClaim(context, startClaim);
  }
}

async function runStatus(raw) {
  const context = buildContext(raw);
  const inspection = await inspectExistingSupervisor(context);
  if (inspection.classification === "LIVE_AUTHENTICATED" && inspection.response?.ok) {
    print("OK", { action: "running", owner_classification: inspection.classification, ...inspection.response.status });
    return;
  }
  if (inspection.classification === "STARTING_OWNED") {
    print("STARTING", {
      action: "starting",
      owner_classification: inspection.classification,
      reason_code: "SUPERVISOR_STARTING",
      status: inspection.state ? publicStatus(inspection.state, null) : null
    });
    return;
  }
  if (inspection.classification === "INVALID_OR_AMBIGUOUS")
    throw new Error(`Supervisor owner evidence is invalid or ambiguous: ${inspection.reason}`);
  print("STOPPED", {
    action: inspection.classification === "STALE_PROVED" ? "stale" : "stopped",
    owner_classification: inspection.classification,
    schema_version: STATE_SCHEMA_VERSION,
    protocol_version: PROTOCOL_VERSION,
    root: context.root,
    project_identity: context.projectIdentity,
    runtime: context.runtime,
    control_contract_id: context.controlContract.id,
    control_contract_version: context.controlContract.version,
    control_contract_schema_version: context.controlContract.schemaVersion,
    control_contract_sha256: context.controlContract.sha256,
    control_namespace: context.controlNamespace,
    target_generation_id: context.targetGenerationId,
    selected_generation_id: context.selectedGenerationId,
    runtime_contract_sha256: context.runtimeContractSha256,
    supervisor_protocol_version: SUPERVISOR_PROTOCOL_VERSION,
    generation_disposition: context.generationDisposition,
    reason_code: inspection.classification === "STALE_PROVED" ? "SUPERVISOR_STALE_PROVED" : "SUPERVISOR_NOT_STARTED"
  });
}

async function runStop(raw) {
  const context = buildContext(raw);
  const state = readOptionalJson(context.statePath, MAX_STATE_BYTES, "Supervisor state");
  if (!state?.pipe_name) {
    print("STOPPED", { action: "already_stopped", runtime: context.runtime });
    return;
  }
  const inspection = await inspectExistingSupervisor(context);
  if (inspection.classification !== "LIVE_AUTHENTICATED"
      || !inspection.response?.ok) {
    throw new Error(`Supervisor shutdown requires a live authenticated owner; observed ${inspection.classification}.`);
  }
  const response = await requestPipe(inspection.state, { command: "shutdown" }, IPC_TIMEOUT_MS);
  if (response && !response.ok) throw new Error(response.error || "Supervisor refused shutdown.");
  print("STOPPED", {
    action: "stopped",
    runtime: context.runtime,
    control_contract_id: context.controlContract.id,
    control_contract_version: context.controlContract.version,
    control_contract_schema_version: context.controlContract.schemaVersion,
    control_contract_sha256: context.controlContract.sha256,
    control_namespace: context.controlNamespace
  });
}

async function runDaemon(raw) {
  const context = buildContext(raw);
  validatedDaemonContext = context;
  fs.mkdirSync(context.runtime, { recursive: true });
  const ownerEvidence = getCurrentProcessEvidence(context, "daemon");
  const lock = await acquireSupervisorLock(context, ownerEvidence);
  if (!lock.acquired) return;

  const state = createInitialState(context, ownerEvidence);
  let server;
  let shuttingDown = false;
  let coordinatorStatus = null;
  let coordinatorObserved = false;
  let coordinatorUnavailableSince = 0;
  let pollTimer = null;
  let queryTail = Promise.resolve();
  let activeOperation = null;
  const operations = new Map();
  let latestOperation = readPersistedOperation(context);
  if (latestOperation) {
    operations.set(latestOperation.operation_id, latestOperation);
    if (latestOperation.state === "running") activeOperation = latestOperation;
  }
  let retirementReason = "";
  let handoffTimer = null;
  let eventSequence = 0;
  let statePublicationError = "";

  const persist = () => {
    state.operation = publicOperation(latestOperation);
    return writeJson(context.statePath, {
    ...state,
    event_sequence: eventSequence,
    coordinator_status: coordinatorStatus ? sanitizeCoordinatorStatus(coordinatorStatus) : null,
    updated_at_utc: new Date().toISOString()
    });
  };
  const emit = (event, detail = "") => {
    eventSequence += 1;
    state.last_event = event;
    state.last_event_detail = String(detail || "");
    appendLine(context.eventPath, JSON.stringify({
      schema_version: 1,
      sequence: eventSequence,
      at_utc: new Date().toISOString(),
      event,
      detail: state.last_event_detail
    }));
    persist();
  };
  const emitSafely = (event, detail = "") => {
    if (statePublicationError) return false;
    try {
      emit(event, detail);
      return true;
    } catch (error) {
      statePublicationError = error instanceof Error ? error.message : String(error);
      state.readiness_state = "degraded";
      state.reason_code = "SUPERVISOR_STATE_PUBLISH_FAILED";
      state.detail = "The project Supervisor could not durably publish its state; maintenance is blocked.";
      // Do not call emit or persist again here. The original publication
      // failure is terminal for this owner epoch; report it without creating
      // an unhandled rejection from a timer or operation callback.
      try {
        process.stderr.write(`[ERROR] Supervisor state publication failed: ${statePublicationError}\n`);
      } catch { /* stderr may already be closed during process shutdown */ }
      return false;
    }
  };
  const beginRetirement = (reason) => {
    if (shuttingDown) return;
    shuttingDown = true;
    if (handoffTimer) {
      clearTimeout(handoffTimer);
      handoffTimer = null;
    }
    state.readiness_state = "stopping";
    state.reason_code = "SUPERVISOR_STOPPING";
    state.detail = "The project Supervisor is retiring its authenticated runtime.";
    emitSafely("supervisor_retiring", reason);
    setTimeout(() => void shutdown(), 10);
  };
  const queueRetirement = (reason) => {
    if (shuttingDown) return;
    if (activeOperation?.state === "running") {
      if (!retirementReason) {
        retirementReason = reason;
        emitSafely("supervisor_retirement_deferred", reason);
      }
      return;
    }
    beginRetirement(reason);
  };
  const refresh = async () => {
    if (statePublicationError) return publicStatus(state, coordinatorStatus);
    const rawStatus = await requestCoordinatorStatus(context);
    if (rawStatus) {
      coordinatorStatus = rawStatus;
      coordinatorObserved = true;
      coordinatorUnavailableSince = 0;
      state.editor_demand = rawStatus.editor_demand ?? state.editor_demand;
    } else {
      coordinatorStatus = null;
      if (coordinatorObserved && coordinatorUnavailableSince === 0)
        coordinatorUnavailableSince = Date.now();
    }
    updateReadiness(state, coordinatorStatus, activeOperation);
    persist();
    if (coordinatorObserved
        && coordinatorUnavailableSince > 0
        && Date.now() - coordinatorUnavailableSince >= COORDINATOR_OFFLINE_RETIRE_MS
        && !activeOperation) {
      queueRetirement("coordinator_offline");
    }
    return publicStatus(state, coordinatorStatus);
  };
  const rememberOperation = (value) => {
    operations.set(value.operation_id, value);
    latestOperation = value;
    persistOperation(context, value);
    while (operations.size > OPERATION_RETENTION_LIMIT) {
      const oldest = operations.keys().next().value;
      if (oldest === activeOperation?.operation_id) break;
      operations.delete(oldest);
    }
  };
  const operationResponse = (value, reused = false) => {
    const pending = value.state === "running";
    const exitCode = pending ? 0 : commandExitCode(value.result);
    const succeeded = pending || (value.state === "completed" && exitCode === 0);
    return {
      ok: succeeded,
      accepted: true,
      reused,
      pending,
      operation_id: value.operation_id,
      error_code: succeeded ? null : "SUPERVISOR_COMMAND_FAILED",
      error: succeeded ? null : (value.error || value.result?.stderr || value.result?.stdout || "Supervisor command failed."),
      result: pending ? null : value.result,
      operation: publicOperation(value),
      status: publicStatus(state, coordinatorStatus),
      handoff_queued: value.handoff_queued === true,
      handoff_reason: value.handoff_reason ?? null
    };
  };
  const finishOperation = async (value, result, error = null) => {
    value.completed_at_utc = new Date().toISOString();
    value.result = error
      ? { exit_code: 1, stdout: "", stderr: String(error.message || error), timed_out: false }
      : compactResult(result);
    const exitCode = commandExitCode(value.result);
    value.state = !error && exitCode === 0 ? "completed" : "failed";
    value.phase = value.state === "completed" ? "completed" : "failed";
    if (error) value.error = String(error.message || error);
    else if (exitCode !== 0) value.error = value.result?.stderr || value.result?.stdout || "Supervisor command failed.";
    if (value.name.startsWith("materialize:")
        && value.state === "completed"
        && selectedInstanceChanged(context)) {
      value.handoff_queued = true;
      value.handoff_reason = "selected_instance_changed";
    }
    if (activeOperation?.operation_id === value.operation_id)
      activeOperation = null;
    rememberOperation(value);
    updateReadiness(state, coordinatorStatus, activeOperation);
    emitSafely(value.state === "completed" ? "operation_completed" : "operation_failed", value.name);
    try { await refresh(); } catch (refreshError) { emitSafely("status_error", refreshError.message); }
    if (retirementReason) {
      const reason = retirementReason;
      retirementReason = "";
      beginRetirement(reason);
      return;
    }
    if (value.handoff_queued === true && !shuttingDown) {
      handoffTimer = setTimeout(
        () => queueRetirement("selected_instance_changed_unobserved"),
        HANDOFF_OBSERVATION_GRACE_MS);
    }
  };
  const admitMaintenance = (name, request, fn) => {
    if (statePublicationError) {
      return {
        ok: false,
        error_code: "SUPERVISOR_STATE_PUBLISH_FAILED",
        error: state.detail,
        status: publicStatus(state, coordinatorStatus)
      };
    }
    if (shuttingDown || retirementReason) {
      return {
        ok: false,
        error_code: "SUPERVISOR_STOPPING",
        error: "The project Supervisor is retiring and cannot admit another maintenance operation.",
        status: publicStatus(state, coordinatorStatus)
      };
    }
    const key = maintenanceOperationKey(name, request);
    if (activeOperation?.state === "running") {
      if (activeOperation.key === key)
        return operationResponse(activeOperation, true);
      return {
        ok: false,
        error_code: "SUPERVISOR_BUSY",
        error: `Supervisor operation ${activeOperation.name} is already running.`,
        pending: true,
        operation_id: activeOperation.operation_id,
        operation: publicOperation(activeOperation),
        status: publicStatus(state, coordinatorStatus)
      };
    }

    const value = {
      schema_version: EVIDENCE_SCHEMA_VERSION,
      managed_by: "com.rice.ai-codedb",
      operation_id: crypto.randomUUID().replaceAll("-", ""),
      key,
      request_id: typeof request.request_id === "string" ? request.request_id : "",
      name,
      lane: "maintenance",
      state: "running",
      phase: "admitted",
      owner_epoch: context.ownerEpoch,
      project_identity: context.projectIdentity,
      root: context.root,
      runtime: context.runtime,
      selected_instance_id: context.selectedInstance.instanceId,
      selected_generation_id: context.selectedGenerationId,
      runtime_contract_sha256: context.runtimeContractSha256,
      child: null,
      started_at_utc: new Date().toISOString()
    };
    activeOperation = value;
    try {
      rememberOperation(value);
    } catch (error) {
      activeOperation = null;
      return {
        ok: false,
        error_code: "SUPERVISOR_STATE_PUBLISH_FAILED",
        error: error instanceof Error ? error.message : String(error),
        status: publicStatus(state, coordinatorStatus)
      };
    }
    updateReadiness(state, coordinatorStatus, activeOperation);
    if (!emitSafely("operation_started", name)) {
      activeOperation = null;
      return {
        ok: false,
        error_code: "SUPERVISOR_STATE_PUBLISH_FAILED",
        error: state.detail,
        status: publicStatus(state, coordinatorStatus)
      };
    }
    Promise.resolve()
      .then(() => fn(value))
      .then(
        (result) => void finishOperation(value, result)
          .catch((error) => emitSafely("operation_state_error", error.message)),
        (error) => void finishOperation(value, null, error)
          .catch((stateError) => emitSafely("operation_state_error", stateError.message)));
    return operationResponse(value);
  };
  const queueQuery = (fn) => {
    // Queries are kept on a separate tail and are never blocked by a pending
    // maintenance admission. The coordinator itself serializes Provider RPC.
    const run = queryTail.then(fn, fn);
    queryTail = run.then(() => undefined, () => undefined);
    return run;
  };

  const dispatch = async (request) => {
    const name = String(request.command || "");
    if (name === "status") {
      void refresh().catch((error) => emitSafely("status_error", error.message));
      return { ok: true, status: publicStatus(state, coordinatorStatus) };
    }
    if (name === "operation") {
      const operationId = String(request.operation_id || "");
      const selected = operations.get(operationId);
      if (!selected) {
        return {
          ok: false,
          error_code: "OPERATION_NOT_FOUND",
          error: "The requested Supervisor operation is unavailable.",
          pending: false,
          operation_id: operationId,
          status: publicStatus(state, coordinatorStatus)
        };
      }
      const response = operationResponse(selected);
      if (!response.pending && response.handoff_queued && !shuttingDown)
        queueRetirement("selected_instance_changed_observed");
      return response;
    }
    if (name === "query") return queueQuery(() => requestCoordinator(context, "query", IPC_TIMEOUT_MS, request));
    if (name === "reconcile" || name === "ensure") {
      return admitMaintenance(name, request, (value) => ensureCoordinator(context, value));
    }
    if (name === "watcher") {
      const action = String(request.action || "");
      if (!["Ensure", "Enable", "Disable", "Start", "Status", "Pause", "Stop", "Restart"].includes(action)) {
        return { ok: false, error_code: "INVALID_ARGUMENT", error: "Unsupported watcher action." };
      }
      if (action === "Status") return resultResponse(await queueQuery(() => requestCoordinator(context, "status", IPC_TIMEOUT_MS)));
      return admitMaintenance(
        `watcher:${action}`,
        request,
        (value) => runWatchManager(context, action, request, value));
    }
    if (name === "materialize") {
      const action = String(request.action || "");
      if (!["DryRun", "Probe", "Verify", "Upgrade", "Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install"].includes(action)) {
        return { ok: false, error_code: "INVALID_ARGUMENT", error: "Unsupported materializer action." };
      }
      return admitMaintenance(
        `materialize:${action}`,
        request,
        (value) => runMaterializer(context, action, request, value));
    }
    if (name === "shutdown") {
      if (shuttingDown) return { ok: true, status: publicStatus(state, coordinatorStatus) };
      if (request.expected_lifecycle_id
          && String(request.expected_lifecycle_id) !== state.lifecycle_id) {
        return {
          ok: false,
          error_code: "LIFECYCLE_MISMATCH",
          error: "Supervisor lifecycle identity does not match the shutdown request."
        };
      }
      queueRetirement("authenticated_shutdown");
      return { ok: true, status: publicStatus(state, coordinatorStatus), result: { exit_code: 0, action: "shutdown_queued" } };
    }
    return { ok: false, error_code: "UNSUPPORTED_COMMAND", error: `Unsupported Supervisor command: ${name}` };
  };

  const shutdown = async () => {
    if (pollTimer) clearInterval(pollTimer);
    if (handoffTimer) clearTimeout(handoffTimer);
    try {
      if (server) await new Promise((resolve) => server.close(resolve));
    } catch { /* best effort */ }
    try {
      await requestCoordinator(context, "stop", IPC_TIMEOUT_MS, { expected_lifecycle_id: context.lifecycleId });
    } catch { /* never terminate an unverified process */ }
    removeOwnedRuntimeEvidence(context, context.statePath, context.ownerEpoch);
    removeOwnedRuntimeEvidence(context, context.lockPath, context.ownerEpoch);
    process.exit(0);
  };

  try {
    state.auth_token = crypto.randomBytes(32).toString("hex");
    writeJson(context.statePath, state);
    server = net.createServer((socket) => handleClient(socket, state.auth_token, dispatch));
    const listenDelayMs = positiveInt(process.env.RICE_CODEDB_SUPERVISOR_LISTEN_DELAY_MS, 0);
    if (listenDelayMs > 0) await delay(Math.min(listenDelayMs, OWNER_STARTUP_GRACE_MS));
    await listen(server, context.pipeName);
    state.publication_phase = "listening";
    state.started_at_utc = new Date().toISOString();
    emit("supervisor_started", context.root);
    pollTimer = setInterval(() => { void refresh().catch((error) => emitSafely("status_error", error.message)); }, POLL_INTERVAL_MS);
    await refresh();
    await ensureCoordinator(context).catch((error) => emitSafely("coordinator_start_failed", error.message));
    await refresh();
    if (activeOperation) {
      void recoverPersistedOperation(activeOperation, context, finishOperation)
        .catch((error) => emitSafely("operation_recovery_error", error.message));
    }
    await new Promise((resolve) => server.once("close", resolve));
  } finally {
    if (!shuttingDown) {
      removeOwnedRuntimeEvidence(context, context.statePath, context.ownerEpoch);
      removeOwnedRuntimeEvidence(context, context.lockPath, context.ownerEpoch);
    }
  }
}

function createInitialState(context, ownerEvidence) {
  return {
    schema_version: STATE_SCHEMA_VERSION,
    evidence_schema_version: EVIDENCE_SCHEMA_VERSION,
    protocol_version: PROTOCOL_VERSION,
    role: "project-local-supervisor",
    managed_by: "com.rice.ai-codedb",
    root: context.root,
    project_identity: context.projectIdentity,
    runtime: context.runtime,
    control_contract_id: context.controlContract.id,
    control_contract_version: context.controlContract.version,
    control_contract_schema_version: context.controlContract.schemaVersion,
    control_contract_sha256: context.controlContract.sha256,
    control_namespace: context.controlNamespace,
    pipe_name: context.pipeName,
    generation_id: context.selectedGenerationId,
    target_generation_id: context.targetGenerationId,
    selected_generation_id: context.selectedGenerationId,
    selected_instance_id: context.selectedInstance.instanceId,
    runtime_contract_sha256: context.runtimeContractSha256,
    supervisor_protocol_version: SUPERVISOR_PROTOCOL_VERSION,
    generation_disposition: context.generationDisposition,
    lifecycle_id: context.lifecycleId,
    supervisor_id: context.supervisorId,
    owner_epoch: context.ownerEpoch,
    owner_evidence: publicProcessEvidence(ownerEvidence),
    supervisor_pid: ownerEvidence.pid,
    publication_phase: "state_published",
    owner_started_at_utc: new Date().toISOString(),
    desired_state: "enabled",
    editor_demand: "online",
    readiness_state: "starting",
    reason_code: "SUPERVISOR_STARTING",
    detail: "The project Supervisor is starting.",
    last_event: "",
    last_event_detail: ""
  };
}

function publicStatus(state, coordinatorStatus) {
  return {
    // Keep the Bridge-facing status shape compatible with the reviewed
    // coordinator status contract while the durable Supervisor state has its
    // own schema and lives under the Package-derived control namespace.
    schema_version: 2,
    supervisor_schema_version: STATE_SCHEMA_VERSION,
    protocol_version: PROTOCOL_VERSION,
    role: state.role,
    root: state.root,
    project_identity: state.project_identity,
    runtime: state.runtime,
    control_contract_id: state.control_contract_id,
    control_contract_version: state.control_contract_version,
    control_contract_schema_version: state.control_contract_schema_version,
    control_contract_sha256: state.control_contract_sha256,
    control_namespace: state.control_namespace,
    pipe_name: state.pipe_name,
    generation_id: state.generation_id,
    target_generation_id: state.target_generation_id,
    selected_generation_id: state.selected_generation_id,
    selected_instance_id: state.selected_instance_id,
    runtime_contract_sha256: state.runtime_contract_sha256,
    supervisor_protocol_version: state.supervisor_protocol_version,
    generation_disposition: state.generation_disposition,
    supervisor_pid: state.supervisor_pid,
    supervisor_id: state.supervisor_id,
    owner_epoch: state.owner_epoch,
    publication_phase: state.publication_phase,
    process_start_identity: state.owner_evidence?.process_start_identity ?? null,
    executable_path: state.owner_evidence?.executable_path ?? null,
    argv_sha256: state.owner_evidence?.argv_sha256 ?? null,
    lifecycle_id: state.lifecycle_id,
    desired_state: state.desired_state,
    editor_demand: state.editor_demand,
    readiness_state: state.readiness_state,
    reason_code: state.reason_code,
    detail: state.detail,
    provider_state: coordinatorStatus?.provider_state ?? "starting",
    provider_ready_at_utc: coordinatorStatus?.provider_ready_at_utc ?? null,
    adapter_enabled: coordinatorStatus?.adapter_enabled === true,
    adapter_state: coordinatorStatus?.adapter_state ?? "disabled",
    adapter_worker_state: coordinatorStatus?.adapter_worker_state ?? "disabled",
    adapter_worker: coordinatorStatus?.adapter_worker ?? null,
    coordinator_pid: coordinatorStatus?.coordinator_pid ?? null,
    coordinator_schema_version: coordinatorStatus?.schema_version ?? 2,
    coordinator_runtime: coordinatorStatus?.runtime ?? null,
    operation: state.operation ?? null,
    event_sequence: state.event_sequence ?? 0,
    last_event: state.last_event,
    last_event_detail: state.last_event_detail,
    updated_at_utc: state.updated_at_utc
  };
}

function updateReadiness(state, coordinatorStatus, operation) {
  if (operation?.state === "running") {
    state.readiness_state = "maintenance";
    state.reason_code = "SUPERVISOR_MAINTENANCE";
    state.detail = `Supervisor operation ${operation.name} is running.`;
    return;
  }
  if (!coordinatorStatus) {
    state.readiness_state = "starting";
    state.reason_code = "SUPERVISOR_STARTING";
    state.detail = "The project Supervisor is starting or reconnecting to its coordinator.";
    return;
  }
  const provider = coordinatorStatus.provider_state;
  const adapter = coordinatorStatus.adapter_state;
  const worker = coordinatorStatus.adapter_worker_state;
  if (["failed", "exited"].includes(provider) || ["failed"].includes(adapter) || ["failed"].includes(worker)) {
    state.readiness_state = "degraded";
    state.reason_code = "SUPERVISOR_DEGRADED";
    state.detail = "The project Supervisor or an owned worker reported a failure.";
    return;
  }
  if (provider !== "ready" || ["starting", "pending", "building", "restarting"].includes(adapter) || ["starting", "restarting"].includes(worker)) {
    state.readiness_state = "starting";
    state.reason_code = "SUPERVISOR_STARTING";
    state.detail = "The project Supervisor is starting its Provider or adapter.";
    return;
  }
  state.readiness_state = "core_ready";
  state.reason_code = "CORE_READY";
  state.detail = "The project Supervisor and Provider are ready.";
}

async function ensureCoordinator(context, operation = null) {
  const existing = await requestCoordinatorStatus(context);
  if (existing?.provider_state === "ready") return { exit_code: 0, action: "attached", status: existing };
  const args = [
    context.coordinatorScript,
    "start",
    "--generation-id", context.generationId,
    "--root", context.root,
    "--provider", context.provider,
    "--config", context.providerConfig,
    "--runtime", context.coordinatorRuntime,
    "--lifecycle-id", context.lifecycleId,
    "--exclusive-lifecycle", "false",
    "--startup-timeout-ms", String(context.startupTimeoutMs)
  ];
  const result = await runChild(
    process.execPath,
    args,
    context.root,
    context.startupTimeoutMs + 5000,
    (child) => queueChildEvidenceCapture(context, operation, process.execPath, args, child));
  if (result.code !== 0) throw new Error(result.stderr || result.stdout || `Coordinator start failed with exit code ${result.code}.`);
  return { exit_code: 0, action: "started", output: result.stdout };
}

async function runWatchManager(context, action, request, operation = null) {
  const args = ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", context.watchManager, "-Action", action];
  if (["Ensure", "Enable", "Start", "Restart"].includes(action)) {
    args.push("-LifecycleId", context.lifecycleId);
  }
  if (request.expected_lifecycle_id) args.push("-ExpectedLifecycleId", String(request.expected_lifecycle_id));
  if (request.require_new_owner === true) args.push("-RequireNewOwner");
  if (request.exclusive_owner === true) args.push("-ExclusiveOwner");
  const command = process.platform === "win32" ? "powershell.exe" : "pwsh";
  return runChild(
    command,
    args,
    context.root,
    120000,
    (child) => queueChildEvidenceCapture(context, operation, command, args, child));
}

async function runMaterializer(context, action, request, operation = null) {
  const args = ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", context.materializerScript, "-Action", action, "-ProjectRoot", context.root, "-PayloadRoot", context.payloadRoot];
  if (request.confirmed_project_mutation === true) args.push("-ConfirmedProjectMutation");
  if (request.editor_session_id) args.push("-EditorSessionId", String(request.editor_session_id));
  if (Number.isInteger(request.editor_process_id) && request.editor_process_id > 0) args.push("-EditorProcessId", String(request.editor_process_id));
  if (request.editor_process_start_ticks) args.push("-EditorProcessStartTicks", String(request.editor_process_start_ticks));
  const command = process.platform === "win32" ? "powershell.exe" : "pwsh";
  return runChild(
    command,
    args,
    context.root,
    15 * 60 * 1000,
    (child) => queueChildEvidenceCapture(context, operation, command, args, child));
}

function resultResponse(result) {
  const exitCode = commandExitCode(result);
  return {
    ok: exitCode === 0,
    error_code: exitCode === 0 ? null : "SUPERVISOR_COMMAND_FAILED",
    error: exitCode === 0 ? null : (result?.stderr || result?.stdout || result?.error || "Supervisor command failed."),
    result: compactResult(result)
  };
}

function compactResult(result) {
  if (!result) return null;
  return {
    exit_code: commandExitCode(result),
    stdout: truncate(result.stdout),
    stderr: truncate(result.stderr),
    timed_out: result.timedOut === true
  };
}

function publicOperation(value) {
  if (!value) return null;
  return {
    schema_version: value.schema_version ?? EVIDENCE_SCHEMA_VERSION,
    operation_id: value.operation_id,
    request_id: value.request_id || null,
    name: value.name,
    lane: value.lane,
    state: value.state,
    phase: value.phase ?? null,
    owner_epoch: value.owner_epoch ?? null,
    child_pid: value.child?.pid ?? null,
    started_at_utc: value.started_at_utc,
    completed_at_utc: value.completed_at_utc ?? null,
    result: value.state === "running" ? null : value.result ?? null,
    error: value.error ?? null,
    handoff_queued: value.handoff_queued === true,
    handoff_reason: value.handoff_reason ?? null
  };
}

function maintenanceOperationKey(name, request) {
  return JSON.stringify([
    name,
    String(request.action || ""),
    request.confirmed_project_mutation === true,
    String(request.expected_lifecycle_id || ""),
    request.require_new_owner === true,
    request.exclusive_owner === true,
    String(request.editor_session_id || ""),
    Number.isInteger(request.editor_process_id) ? request.editor_process_id : 0,
    String(request.editor_process_start_ticks || "")
  ]);
}

function commandExitCode(result) {
  if (Number.isInteger(result?.code)) return result.code;
  if (Number.isInteger(result?.exit_code)) return result.exit_code;
  return 1;
}

function readPersistedOperation(context) {
  if (!fs.existsSync(context.operationPath)) return null;
  assertReviewedPath(context.runtime, context.operationPath, "Supervisor operation", "file");
  const operation = readRequiredJson(
    context.operationPath,
    MAX_STATE_BYTES,
    "Supervisor operation").value;
  validatePersistedOperation(context, operation);
  return operation;
}

function persistOperation(context, operation) {
  writeJson(context.operationPath, operation);
}

function validatePersistedOperation(context, operation) {
  requireObject(operation, "Supervisor operation");
  if (operation.schema_version !== EVIDENCE_SCHEMA_VERSION
      || operation.managed_by !== "com.rice.ai-codedb"
      || !validId(operation.operation_id)
      || !validId(operation.owner_epoch)
      || operation.project_identity !== context.projectIdentity
      || !pathsEqual(operation.root, context.root)
      || !pathsEqual(operation.runtime, context.runtime)
      || !["running", "completed", "failed"].includes(operation.state)
      || typeof operation.name !== "string"
      || operation.name.length === 0
      || typeof operation.key !== "string") {
    throw new Error("Supervisor operation identity is invalid.");
  }
  if (operation.state === "running"
      && (operation.selected_instance_id !== context.selectedInstance.instanceId
          || operation.selected_generation_id !== context.selectedGenerationId
          || operation.runtime_contract_sha256 !== context.runtimeContractSha256))
    throw new Error("Running Supervisor operation targets a different selected instance.");
  if (operation.state === "running" && operation.child !== null && operation.child !== undefined)
    validatePersistedChild(operation.child);
}

function validatePersistedChild(child) {
  requireObject(child, "Supervisor operation child evidence");
  validateProcessEvidenceShape(child, "Supervisor operation child evidence");
  if (typeof child.command !== "string" || child.command.length === 0
      || !Array.isArray(child.normalized_argv)
      || child.normalized_argv.length === 0)
    throw new Error("Supervisor operation child command identity is invalid.");
}

async function recoverPersistedOperation(operation, context, finish) {
  if (!operation || operation.state !== "running") return;
  if (!operation.child) {
    await finish(operation, null, new Error("Supervisor operation was interrupted before its child identity was durably recorded."));
    return;
  }
  const expected = {
    pid: operation.child.pid,
    startIdentity: operation.child.process_start_identity,
    executablePath: operation.child.executable_path,
    argvSha256: operation.child.argv_sha256,
    commandLineSha256: operation.child.command_line_sha256
  };
  const initial = getProcessEvidenceSync(expected.pid);
  if (!initial.available) {
    await finish(operation, null, new Error("Supervisor operation child identity is unavailable; retry was blocked."));
    return;
  }
  if (!initial.exists) {
    await finish(operation, null, new Error("Supervisor operation child is no longer present and its result could not be authenticated."));
    return;
  }
  if (!processEvidenceMatches(expected, initial)) {
    await finish(operation, null, new Error("Supervisor operation PID was reused by a different executable or argv; retry was blocked."));
    return;
  }
  operation.phase = "reattached";
  persistOperation(context, operation);
  while (true) {
    await delay(100);
    const current = getProcessEvidenceSync(expected.pid);
    if (!current.available) {
      await finish(operation, null, new Error("Supervisor operation child identity became unavailable during recovery."));
      return;
    }
    if (!current.exists) {
      // A child exit is only an observation. Ask the authoritative coordinator
      // or materializer verifier before recording success; never infer a
      // successful mutation from process disappearance alone.
      const verification = await verifyRecoveredOperation(context, operation);
      if (!verification.ok) {
        await finish(operation, null, new Error(verification.error || "Recovered operation verification failed."));
        return;
      }
      await finish(operation, verification.result || { code: 0, stdout: "", stderr: "", timedOut: false });
      return;
    }
    if (!processEvidenceMatches(expected, current)) {
      await finish(operation, null, new Error("Supervisor operation child identity changed during recovery."));
      return;
    }
  }
}

async function verifyRecoveredOperation(context, operation) {
  if (operation.name.startsWith("materialize:")) {
    const action = operation.name.slice("materialize:".length);
    const result = await runChild(
      process.platform === "win32" ? "powershell.exe" : "pwsh",
      ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", context.materializerScript,
        "-Action", "Verify", "-ProjectRoot", context.root, "-PayloadRoot", context.payloadRoot],
      context.root,
      120000);
    return {
      ok: result.code === 0,
      result,
      error: result.code === 0 ? "" : `Recovered ${action} operation could not be verified.`
    };
  }
  const status = await requestCoordinatorStatus(context);
  return status
    ? { ok: true, result: { code: 0, stdout: "recovered coordinator state verified", stderr: "", timedOut: false } }
    : { ok: false, error: "Recovered operation coordinator state is unavailable." };
}

function recordChildEvidence(context, operation, commandName, args, child) {
  if (!operation) return;
  const actual = getProcessEvidenceSync(child.pid);
  if (!actual.available || !actual.exists)
    throw new Error(`The admitted child process identity could not be read: ${actual.error || `exists=${actual.exists}`}`);
  const expectedArgv = normalizeProcessArgv(args);
  const expectedHash = hashArgv(expectedArgv);
  const expectedExecutable = resolveCommandExecutable(commandName);
  if (actual.argvSha256 !== expectedHash
      || !expectedExecutable
      || !pathsEqual(actual.executablePath, expectedExecutable))
    throw new Error("The admitted child process executable or argv does not match the requested command.");
  operation.phase = "child_running";
  operation.child = {
    schema_version: EVIDENCE_SCHEMA_VERSION,
    pid: actual.pid,
    process_start_identity: actual.processStartIdentity,
    executable_path: actual.executablePath,
    argv_sha256: actual.argvSha256,
    command_line_sha256: actual.commandLineSha256,
    command: normalizeExecutable(expectedExecutable),
    normalized_argv: expectedArgv
  };
  persistOperation(context, operation);
}

function queueChildEvidenceCapture(context, operation, commandName, args, child) {
  if (!operation) return Promise.resolve();
  // Process inspection can invoke PowerShell on Windows. Defer it until after
  // the IPC admission response has been produced so a long-running child can
  // never turn an asynchronous command into a synchronous request.
  return new Promise((resolve, reject) => {
    let attempt = 0;
    const capture = () => {
      if (operation.state !== "running" || operation.child) {
        resolve();
        return;
      }
      try {
        recordChildEvidence(context, operation, commandName, args, child);
        resolve();
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        if ((child.exitCode !== null || child.signalCode !== null)
            && /exists=false/i.test(detail)) {
          // The owning Supervisor observed this exact ChildProcess exit. A
          // very short command can finish before Windows publishes queryable
          // process evidence; in that case the close handler remains the
          // authoritative result. A crash before terminal persistence still
          // leaves the operation without child evidence and therefore blocks
          // retry rather than guessing success.
          operation.phase = "child_exited_before_identity_capture";
          persistOperation(context, operation);
          resolve();
          return;
        }
        attempt += 1;
        if (attempt >= 4) {
          operation.phase = "child_identity_unavailable";
          operation.error = detail;
          persistOperation(context, operation);
          reject(error);
          return;
        }
        setTimeout(capture, CHILD_EVIDENCE_CAPTURE_DELAY_MS * attempt);
      }
    };
    setTimeout(capture, CHILD_EVIDENCE_CAPTURE_DELAY_MS);
  });
}

function normalizeExecutable(value) {
  const resolved = path.resolve(String(value));
  return process.platform === "win32" ? resolved.replace(/\\/g, "/").toLowerCase() : resolved;
}

function resolveCommandExecutable(commandName) {
  const value = String(commandName || "");
  if (path.isAbsolute(value)) return realFile(value, "child executable");
  if (process.platform === "win32" && value.toLowerCase() === "powershell.exe") {
    const systemRoot = process.env.SystemRoot
      || process.env.WINDIR
      || path.join(path.parse(process.execPath).root, "Windows");
    const candidate = path.join(systemRoot, "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
    if (isFile(candidate)) return realFile(candidate, "child executable");
  }
  try {
    const output = execFileSync(
      process.platform === "win32" ? "where.exe" : "which",
      [value],
      { encoding: "utf8", timeout: PROCESS_QUERY_TIMEOUT_MS, windowsHide: true });
    const first = String(output).split(/\r?\n/).map((line) => line.trim()).find(Boolean);
    if (first && isFile(first)) return realFile(first, "child executable");
  } catch { /* unavailable executable identity is fail-closed */ }
  return null;
}

async function requestCoordinatorStatus(context) {
  const state = readOptionalJson(
    path.join(context.coordinatorRuntime, "coordinator-state.json"),
    MAX_STATE_BYTES,
    "coordinator state");
  if (!state?.pipe_name || !state.auth_token) return null;
  const response = await requestPipe(state, { command: "status" }, IPC_TIMEOUT_MS);
  return response?.ok ? response.status : null;
}

async function requestCoordinator(context, commandName, timeoutMs, request = {}) {
  const state = readOptionalJson(
    path.join(context.coordinatorRuntime, "coordinator-state.json"),
    MAX_STATE_BYTES,
    "coordinator state");
  if (!state?.pipe_name || !state.auth_token) return { ok: false, error_code: "COORDINATOR_UNAVAILABLE", error: "Coordinator is not running." };
  // The outer Supervisor auth token authenticates the Bridge request only. It
  // must never be forwarded to the coordinator, whose pipe has an independent
  // token and ownership boundary.
  const { auth_token: _ignoredAuthToken, ...forwarded } = request || {};
  return requestPipe(state, { ...forwarded, command: commandName }, timeoutMs);
}

function requestPipe(state, request, timeoutMs) {
  return new Promise((resolve) => {
    const socket = net.createConnection(state.pipe_name);
    let settled = false;
    let buffer = "";
    const finish = (value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      socket.destroy();
      resolve(value);
    };
    const timer = setTimeout(() => finish(null), timeoutMs);
    socket.setEncoding("utf8");
    socket.on("connect", () => socket.write(`${JSON.stringify({ auth_token: state.auth_token, ...request })}\n`));
    socket.on("data", (chunk) => {
      buffer += chunk;
      if (Buffer.byteLength(buffer, "utf8") > MAX_MESSAGE_BYTES) return finish({ ok: false, error_code: "RESPONSE_TOO_LARGE", error: "IPC response exceeds 64 KiB." });
      const newline = buffer.indexOf("\n");
      if (newline < 0) return;
      try { finish(JSON.parse(buffer.slice(0, newline))); } catch { finish(null); }
    });
    socket.on("end", () => { if (!settled && buffer.trim()) { try { finish(JSON.parse(buffer.trim())); } catch { finish(null); } } });
    socket.on("error", () => finish(null));
  });
}

function publicProcessEvidence(evidence, includeArgv = false) {
  const result = {
    schema_version: EVIDENCE_SCHEMA_VERSION,
    pid: evidence.pid,
    process_start_identity: evidence.processStartIdentity,
    executable_path: evidence.executablePath,
    argv_sha256: evidence.argvSha256,
    command_line_sha256: evidence.commandLineSha256
  };
  if (includeArgv) result.normalized_argv = evidence.normalizedArgv;
  return result;
}

function getCurrentProcessEvidence(context, commandName) {
  const evidence = getProcessEvidenceSync(process.pid);
  if (!evidence.available || !evidence.exists)
    throw new Error(`The ${commandName} process identity could not be read; ownership was not published.`);
  validateSupervisorInvocation(context, evidence.normalizedArgv, commandName, context.ownerEpoch);
  if (!pathsEqual(evidence.executablePath, process.execPath))
    throw new Error(`The ${commandName} executable identity does not match the reviewed Node runtime.`);
  return evidence;
}

function getProcessEvidenceSync(pid) {
  if (!Number.isSafeInteger(pid) || pid <= 0)
    return { available: false, exists: null, error: "Process id is invalid." };
  if (process.platform === "win32") return getWindowsProcessEvidenceSync(pid);
  return getProcProcessEvidenceSync(pid);
}

function getWindowsProcessEvidenceSync(pid) {
  const wmi = getWindowsWmiProcessEvidenceSync(pid);
  if (wmi) return wmi;
  const script = [
    "[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)",
    `$p = Get-CimInstance Win32_Process -Filter \"ProcessId = ${pid}\" -ErrorAction Stop`,
    "if ($null -eq $p) { [Console]::Write('{\"exists\":false}'); exit 0 }",
    "$ticks = ([DateTime]$p.CreationDate).ToUniversalTime().Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)",
    "$result = [ordered]@{ exists = $true; process_start_identity = $ticks; executable_path = [string]$p.ExecutablePath; command_line = [string]$p.CommandLine }",
    "[Console]::Write(($result | ConvertTo-Json -Compress))"
  ].join("\r\n");
  try {
    const encoded = Buffer.from(script, "utf16le").toString("base64");
    const bytes = execFileSync(
      "powershell.exe",
      ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-EncodedCommand", encoded],
      { encoding: "buffer", timeout: PROCESS_QUERY_TIMEOUT_MS, windowsHide: true, stdio: ["ignore", "pipe", "pipe"] });
    const text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
    const value = JSON.parse(text);
    if (value?.exists === false) return { available: true, exists: false, pid };
    if (value?.exists !== true
        || typeof value.process_start_identity !== "string"
        || !/^\d{1,32}$/.test(value.process_start_identity)
        || typeof value.executable_path !== "string"
        || value.executable_path.length === 0
        || typeof value.command_line !== "string"
        || value.command_line.length === 0) {
      return { available: false, exists: true, pid, error: "Windows returned incomplete process identity." };
    }
    const argv = parseWindowsCommandLine(value.command_line);
    if (argv.length < 2)
      return { available: false, exists: true, pid, error: "Windows returned an invalid process command line." };
    const normalizedArgv = normalizeProcessArgv(argv.slice(1));
    return {
      available: true,
      exists: true,
      pid,
      processStartIdentity: value.process_start_identity,
      executablePath: path.resolve(value.executable_path),
      normalizedArgv,
      argvSha256: hashArgv(normalizedArgv),
      commandLineSha256: hash(normalizeCommandLine(value.command_line))
    };
  } catch (error) {
    return { available: false, exists: null, pid, error: error instanceof Error ? error.message : String(error) };
  }
}

function getWindowsWmiProcessEvidenceSync(pid) {
  try {
    const output = execFileSync(
      "wmic.exe",
      ["process", "where", `ProcessId=${pid}`, "get", "CreationDate,ExecutablePath,CommandLine", "/format:list"],
      { encoding: "utf8", timeout: PROCESS_QUERY_TIMEOUT_MS, windowsHide: true, stdio: ["ignore", "pipe", "pipe"] });
    const fields = Object.create(null);
    for (const line of String(output).split(/\r?\n/)) {
      const separator = line.indexOf("=");
      if (separator <= 0) continue;
      fields[line.slice(0, separator).trim().toLowerCase()] = line.slice(separator + 1).trim();
    }
    if (!fields.creationdate && !fields.executablepath && !fields.commandline)
      return { available: true, exists: false, pid };
    if (!fields.creationdate || !fields.executablepath || !fields.commandline)
      return { available: false, exists: true, pid, error: "WMIC returned incomplete process identity." };
    const argv = parseWindowsCommandLine(fields.commandline);
    if (argv.length < 2)
      return { available: false, exists: true, pid, error: "WMIC returned an invalid process command line." };
    const normalizedArgv = normalizeProcessArgv(argv.slice(1));
    const processStartIdentity = normalizeStartIdentity(fields.creationdate);
    if (!/^\d{1,32}$/.test(processStartIdentity))
      return { available: false, exists: true, pid, error: "WMIC returned an invalid process start identity." };
    return {
      available: true,
      exists: true,
      pid,
      processStartIdentity,
      executablePath: path.resolve(fields.executablepath),
      normalizedArgv,
      argvSha256: hashArgv(normalizedArgv),
      commandLineSha256: hash(normalizeCommandLine(fields.commandline))
    };
  } catch {
    return null;
  }
}

function normalizeStartIdentity(value) {
  const normalized = String(value || "").replace(/[^0-9]/g, "");
  return normalized;
}

function getProcProcessEvidenceSync(pid) {
  const base = `/proc/${pid}`;
  if (!fs.existsSync(base)) return { available: true, exists: false, pid };
  try {
    const stat = fs.readFileSync(path.join(base, "stat"), "utf8");
    const closingName = stat.lastIndexOf(") ");
    if (closingName < 0) throw new Error("Process stat identity is invalid.");
    const fields = stat.slice(closingName + 2).trim().split(/\s+/);
    const startIdentity = fields[19];
    const executablePath = fs.realpathSync(path.join(base, "exe"));
    const commandLine = fs.readFileSync(path.join(base, "cmdline"));
    const argv = commandLine.toString("utf8").split("\0").filter((value) => value.length > 0);
    if (!/^\d+$/.test(startIdentity) || argv.length < 2)
      throw new Error("Process identity is incomplete.");
    const normalizedArgv = normalizeProcessArgv(argv.slice(1));
    return {
      available: true,
      exists: true,
      pid,
      processStartIdentity: startIdentity,
      executablePath,
      normalizedArgv,
      argvSha256: hashArgv(normalizedArgv),
      commandLineSha256: hashArgv(normalizeProcessArgv(argv))
    };
  } catch (error) {
    return { available: false, exists: true, pid, error: error instanceof Error ? error.message : String(error) };
  }
}

function parseWindowsCommandLine(commandLine) {
  const args = [];
  let index = 0;
  while (index < commandLine.length) {
    while (index < commandLine.length && /\s/.test(commandLine[index])) index += 1;
    if (index >= commandLine.length) break;
    let value = "";
    let quoted = false;
    while (index < commandLine.length) {
      let backslashes = 0;
      while (commandLine[index] === "\\") {
        backslashes += 1;
        index += 1;
      }
      if (commandLine[index] === '"') {
        value += "\\".repeat(Math.floor(backslashes / 2));
        if (backslashes % 2 === 0) {
          if (quoted && commandLine[index + 1] === '"') {
            value += '"';
            index += 1;
          } else {
            quoted = !quoted;
          }
        } else {
          value += '"';
        }
        index += 1;
        continue;
      }
      value += "\\".repeat(backslashes);
      if (index >= commandLine.length || (!quoted && /\s/.test(commandLine[index]))) break;
      value += commandLine[index++];
    }
    args.push(value);
    while (index < commandLine.length && /\s/.test(commandLine[index])) index += 1;
  }
  return args;
}

function normalizeProcessArgv(argv) {
  return argv.map((argument) => {
    let value = String(argument).normalize("NFC");
    if (process.platform === "win32" && (/^[A-Za-z]:[\\/]/.test(value) || /^\\\\/.test(value)))
      value = path.win32.normalize(value).replace(/\\/g, "/").toLowerCase();
    return value;
  });
}

function normalizeCommandLine(value) {
  return String(value).normalize("NFC").replace(/\r\n?/g, "\n").trim();
}

function hashArgv(argv) {
  return hash(JSON.stringify(argv));
}

function validateSupervisorInvocation(
  context,
  normalizedArgv,
  commandName,
  ownerEpoch = "",
  allowLegacyRouting = false) {
  if (!Array.isArray(normalizedArgv) || normalizedArgv.length < 2)
    throw new Error("Supervisor process argv evidence is incomplete.");
  const expectedScript = normalizeProcessArgv([fileURLToPath(import.meta.url)])[0];
  if (normalizedArgv[0] !== expectedScript || normalizedArgv[1] !== commandName)
    throw new Error("Supervisor process command identity is invalid.");
  const values = Object.create(null);
  for (let index = 2; index < normalizedArgv.length; index += 2) {
    const name = normalizedArgv[index];
    const value = normalizedArgv[index + 1];
    if (!/^--[a-z0-9-]+$/.test(name) || value === undefined || Object.hasOwn(values, name))
      throw new Error("Supervisor process argv contains an invalid or duplicate option.");
    values[name] = value;
  }
  const expectedPaths = {
    "--root": context.root,
    "--runtime": context.runtime
  };
  if (Object.hasOwn(values, "--package-root")) {
    expectedPaths["--package-root"] = context.packageRoot;
  } else if (!allowLegacyRouting
      || commandName !== "daemon"
      || !Object.hasOwn(values, "--payload-root")) {
    throw new Error("Supervisor process argv must declare --package-root or the legacy --payload-root identity.");
  }
  if (context.provider) expectedPaths["--provider"] = context.provider;
  for (const [name, expected] of Object.entries(expectedPaths)) {
    const normalizedExpected = normalizeProcessArgv([expected])[0];
    if (values[name] !== normalizedExpected)
      throw new Error(`Supervisor process argv ${name} does not match the reviewed runtime.`);
  }
  if (!expectedPaths["--provider"] && Object.hasOwn(values, "--provider")) {
    throw new Error("Supervisor process argv contains unexpected option --provider.");
  }
  const optionalDerivedPaths = {
    "--coordinator-script": context.coordinatorScript,
    "--coordinator-runtime": context.coordinatorRuntime,
    "--materializer-script": context.materializerScript,
    "--payload-root": context.payloadRoot,
    "--watch-manager": context.watchManager,
    "--provider-config": context.providerConfig
  };
  for (const [name, expected] of Object.entries(optionalDerivedPaths)) {
    if (!Object.hasOwn(values, name)) continue;
    const normalizedExpected = normalizeProcessArgv([expected])[0];
    if (values[name] !== normalizedExpected)
      throw new Error(`Supervisor process argv ${name} does not match the Package-derived runtime.`);
  }
  const lifecycleProvided = Object.hasOwn(values, "--lifecycle-id");
  const supervisorProvided = Object.hasOwn(values, "--supervisor-id");
  const usesDerivedStartIdentity = commandName === "start"
    && !lifecycleProvided
    && !supervisorProvided;
  if (!usesDerivedStartIdentity
      && (values["--lifecycle-id"] !== context.lifecycleId
          || values["--supervisor-id"] !== context.supervisorId))
    throw new Error("Supervisor process lifecycle identity is invalid.");
  if (commandName === "daemon" && values["--owner-epoch"] !== ownerEpoch)
    throw new Error("Supervisor process owner epoch is invalid.");
  if (commandName === "start" && Object.hasOwn(values, "--owner-epoch"))
    throw new Error("Supervisor start process unexpectedly declares an owner epoch.");
  const accepted = new Set([
    "--root", "--runtime", "--package-root", "--coordinator-script", "--coordinator-runtime",
    "--materializer-script", "--payload-root", "--watch-manager", "--lifecycle-id",
    "--supervisor-id", "--startup-timeout-ms", "--provider", "--provider-config"
  ]);
  if (commandName === "daemon") accepted.add("--owner-epoch");
  for (const name of Object.keys(values)) {
    if (!accepted.has(name)) throw new Error(`Supervisor process argv contains unsupported option ${name}.`);
  }
  if (Object.hasOwn(values, "--startup-timeout-ms")
      && positiveInt(values["--startup-timeout-ms"], -1) !== context.startupTimeoutMs)
    throw new Error("Supervisor process startup timeout identity is invalid.");
}

function validateProcessEvidenceShape(value, label) {
  requireObject(value, label);
  const pid = requiredInteger(value, "pid", label);
  const startIdentity = requiredString(value, "process_start_identity", label);
  const executablePath = requiredString(value, "executable_path", label);
  const argvSha256 = requiredHash(value, "argv_sha256", label);
  const commandLineSha256 = requiredHash(value, "command_line_sha256", label);
  if (requiredInteger(value, "schema_version", label) !== EVIDENCE_SCHEMA_VERSION
      || pid <= 0
      || !/^\d{1,32}$/.test(startIdentity)
      || !path.isAbsolute(executablePath)) {
    throw new Error(`${label} identity is invalid.`);
  }
  return { pid, startIdentity, executablePath, argvSha256, commandLineSha256 };
}

function processEvidenceMatches(expected, actual) {
  return actual?.available === true
    && actual.exists === true
    && expected.pid === actual.pid
    && expected.startIdentity === actual.processStartIdentity
    && pathsEqual(expected.executablePath, actual.executablePath)
    && expected.argvSha256 === actual.argvSha256
    && expected.commandLineSha256 === actual.commandLineSha256;
}

function authenticatedStatusMatches(state, status) {
  return status
    && status.owner_epoch === state.owner_epoch
    && status.supervisor_pid === state.supervisor_pid
    && status.project_identity === state.project_identity
    && status.runtime === state.runtime
    && status.control_contract_id === state.control_contract_id
    && status.control_contract_version === state.control_contract_version
    && status.control_contract_schema_version === state.control_contract_schema_version
    && status.control_contract_sha256 === state.control_contract_sha256
    && status.control_namespace === state.control_namespace
    && status.selected_instance_id === state.selected_instance_id
    && status.selected_generation_id === state.selected_generation_id
    && status.runtime_contract_sha256 === state.runtime_contract_sha256
    && status.pipe_name === state.pipe_name;
}

function validateSupervisorState(context, state) {
  if (!state || typeof state !== "object")
    throw new Error("Supervisor state is missing or invalid.");
  if (state.schema_version !== STATE_SCHEMA_VERSION
      || state.evidence_schema_version !== EVIDENCE_SCHEMA_VERSION
      || state.protocol_version !== PROTOCOL_VERSION
      || state.managed_by !== "com.rice.ai-codedb"
      || state.role !== "project-local-supervisor"
      || !pathsEqual(state.root, context.root)
      || state.project_identity !== context.projectIdentity
      || !pathsEqual(state.runtime, context.runtime)
      || state.control_contract_id !== context.controlContract.id
      || state.control_contract_version !== context.controlContract.version
      || state.control_contract_schema_version !== context.controlContract.schemaVersion
      || state.control_contract_sha256 !== context.controlContract.sha256
      || !pathsEqual(state.control_namespace, context.controlNamespace)
      || state.generation_id !== context.selectedGenerationId
      || state.target_generation_id !== context.targetGenerationId
      || state.selected_generation_id !== context.selectedGenerationId
      || state.selected_instance_id !== context.selectedInstance.instanceId
      || state.runtime_contract_sha256 !== context.runtimeContractSha256
      || (state.supervisor_protocol_version !== SUPERVISOR_PROTOCOL_VERSION
          && state.supervisor_protocol_version !== LEGACY_SUPERVISOR_PROTOCOL_VERSION)
      || state.generation_disposition !== context.generationDisposition
      || state.lifecycle_id !== context.lifecycleId
      || state.pipe_name !== context.pipeName
      || typeof state.auth_token !== "string"
      || state.auth_token.length === 0) {
    throw new Error("Supervisor state identity does not match the selected project runtime.");
  }
  if (!validId(state.owner_epoch)
      || !validId(state.supervisor_id)
      || !["state_published", "listening", "retiring"].includes(state.publication_phase)
      || !Number.isSafeInteger(state.supervisor_pid)
      || state.supervisor_pid <= 0) {
    throw new Error("Supervisor state owner evidence is invalid.");
  }
  const ownerEvidence = validateSupervisorOwnerRecord(context, state, "Supervisor state");
  if (ownerEvidence.pid !== state.supervisor_pid)
    throw new Error("Supervisor state process evidence PID does not match the Supervisor PID.");
}

function pathsEqual(left, right) {
  if (typeof left !== "string" || typeof right !== "string") return false;
  const normalizedLeft = path.resolve(left);
  const normalizedRight = path.resolve(right);
  return process.platform === "win32"
    ? normalizedLeft.toLowerCase() === normalizedRight.toLowerCase()
    : normalizedLeft === normalizedRight;
}

function canonicalPipeIdentityPath(value) {
  return path.resolve(value).replace(/\\/g, "/").toLowerCase();
}

function selectedInstanceChanged(context) {
  const selectionPath = path.join(
    context.root,
    "AIWork",
    ".runtime",
    "codedb",
    "control",
    "current-instance.json");
  if (!isFile(selectionPath)) return true;
  const selected = readSelectedInstance(context.root, context.runtimeContract);
  return selected.instanceId !== context.selectedInstance.instanceId
    || selected.generationId !== context.selectedInstance.generationId;
}

function handleClient(socket, authToken, dispatch) {
  socket.setEncoding("utf8");
  socket.setTimeout(IPC_TIMEOUT_MS, () => socket.destroy());
  let buffer = "";
  let handled = false;
  socket.on("data", (chunk) => {
    if (handled) return;
    buffer += chunk;
    if (Buffer.byteLength(buffer, "utf8") > MAX_MESSAGE_BYTES) {
      handled = true;
      socket.end(`${JSON.stringify({ ok: false, error_code: "REQUEST_TOO_LARGE", error: "Supervisor request exceeds 64 KiB." })}\n`);
      return;
    }
    const newline = buffer.indexOf("\n");
    if (newline < 0) return;
    handled = true;
    socket.setTimeout(0);
    let request;
    try { request = JSON.parse(buffer.slice(0, newline)); } catch { socket.end(`${JSON.stringify({ ok: false, error_code: "INVALID_JSON", error: "Supervisor request is invalid JSON." })}\n`); return; }
    if (!timingSafeEqual(request.auth_token, authToken)) { socket.end(`${JSON.stringify({ ok: false, error_code: "UNAUTHORIZED", error: "Unauthorized Supervisor request." })}\n`); return; }
    Promise.resolve(dispatch(request)).then((response) => socket.end(`${JSON.stringify(response)}\n`)).catch((error) => socket.end(`${JSON.stringify({ ok: false, error_code: error.code || "SUPERVISOR_COMMAND_FAILED", error: error.message })}\n`));
  });
}

function timingSafeEqual(actual, expected) {
  const left = Buffer.from(String(actual ?? ""), "utf8");
  const right = Buffer.from(String(expected ?? ""), "utf8");
  return left.length > 0 && left.length === right.length && crypto.timingSafeEqual(left, right);
}

function sanitizeCoordinatorStatus(status) {
  return {
    schema_version: status.schema_version,
    generation_id: status.generation_id,
    coordinator_pid: status.coordinator_pid,
    lifecycle_id: status.lifecycle_id ?? null,
    root: status.root,
    runtime: status.runtime,
    provider_state: status.provider_state,
    provider_ready_at_utc: status.provider_ready_at_utc ?? null,
    adapter_enabled: status.adapter_enabled === true,
    adapter_state: status.adapter_state,
    adapter_worker_state: status.adapter_worker_state,
    adapter_worker: status.adapter_worker ?? null,
    last_event: status.last_event ?? null
  };
}

function runChild(commandName, args, cwd, timeoutMs, onSpawn = null) {
  return new Promise((resolve) => {
    const child = spawn(commandName, args, { cwd, windowsHide: true, stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    let timedOut = false;
    let settled = false;
    const finish = (value) => {
      if (settled) return;
      settled = true;
      resolve(value);
    };
    child.stdout.on("data", (chunk) => { stdout = `${stdout}${String(chunk)}`.slice(-32768); });
    child.stderr.on("data", (chunk) => { stderr = `${stderr}${String(chunk)}`.slice(-32768); });
    const timer = setTimeout(() => { timedOut = true; try { child.kill(); } catch { /* best effort */ } }, timeoutMs);
    child.once("error", (error) => {
      clearTimeout(timer);
      finish({ code: 1, stdout, stderr: error.message, timedOut });
    });
    let spawnEvidence = Promise.resolve();
    try {
      if (onSpawn) spawnEvidence = Promise.resolve(onSpawn(child));
    } catch (error) {
      try { child.kill(); } catch { /* only the just-admitted child */ }
      spawnEvidence = Promise.reject(error);
    }
    child.once("close", async (code, signal) => {
      clearTimeout(timer);
      let evidenceError = "";
      try { await spawnEvidence; } catch (error) { evidenceError = error instanceof Error ? error.message : String(error); }
      finish({
        code: evidenceError ? 1 : (timedOut ? 124 : (code ?? 1)),
        signal,
        stdout: stdout.trim(),
        stderr: [stderr.trim(), evidenceError].filter(Boolean).join("\n"),
        timedOut
      });
    });
  });
}

function listen(server, pipeName) {
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(pipeName, () => { server.off("error", reject); resolve(); });
  });
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const temp = `${filePath}.${process.pid}.${crypto.randomUUID()}.tmp`;
  const fd = fs.openSync(temp, "wx");
  try {
    writeFdJson(fd, value);
    fs.closeSync(fd);
    renameWithRetry(temp, filePath);
  } finally {
    try { fs.closeSync(fd); } catch { /* already closed */ }
    fs.rmSync(temp, { force: true });
  }
}

function appendLine(filePath, line) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.appendFileSync(filePath, `${line}\n`, "utf8");
}

function readPackageRuntimeContract(payloadRoot) {
  const manifestPath = path.join(payloadRoot, "payload-manifest.json");
  const { value, bytes } = readRequiredJson(manifestPath, MAX_RUNTIME_CONTRACT_BYTES, "Package runtime contract");
  const packageVersion = requiredString(value, "package_version", "Package runtime contract");
  const payloadVersion = requiredString(value, "payload_version", "Package runtime contract");
  const payloadSequence = requiredInteger(value, "payload_sequence", "Package runtime contract");
  const generationId = requiredGenerationId(value, "generation_id", "Package runtime contract");
  const bootstrapProtocol = requiredInteger(value, "bootstrap_protocol", "Package runtime contract");
  if (requiredInteger(value, "schema_version", "Package runtime contract") !== 1
      || requiredString(value, "managed_by", "Package runtime contract") !== "com.rice.ai-codedb"
      || payloadSequence < 1
      || bootstrapProtocol < 1) {
    throw new Error("Package runtime contract identity or protocol is invalid.");
  }
  const controlContract = readControlContract(value, "Package runtime contract");
  const packageFiles = requiredArray(value, "files", "Package runtime contract");
  const seenTargets = new Set();
  let stableWrapperSha256 = null;
  for (const document of packageFiles) {
    requireObject(document, "Package runtime file");
    const source = requiredString(document, "source", "Package runtime file");
    const target = requiredString(document, "target", "Package runtime file");
    const digest = requiredHash(document, "sha256", "Package runtime file");
    const targetKey = target.toLowerCase();
    if (seenTargets.has(targetKey))
      throw new Error("Package runtime contract contains a duplicate target path.");
    seenTargets.add(targetKey);
    if (target !== STABLE_WRAPPER_RELATIVE_PATH)
      continue;
    if (source !== STABLE_WRAPPER_RELATIVE_PATH)
      throw new Error("Package runtime stable-wrapper source path is invalid.");
    stableWrapperSha256 = digest;
  }
  if (!stableWrapperSha256)
    throw new Error("Package runtime contract does not declare the stable wrapper.");
  const packageWrapperPath = path.resolve(payloadRoot, STABLE_WRAPPER_RELATIVE_PATH.replace(/\//g, path.sep));
  assertReviewedPath(payloadRoot, packageWrapperPath, "Package stable wrapper", "file");
  if (hashBytes(readBoundedBytes(packageWrapperPath, MAX_INSTANCE_WORKER_BYTES, "Package stable wrapper")) !== stableWrapperSha256)
    throw new Error("Package runtime stable wrapper bytes do not match its manifest identity.");
  const transitionDocuments = requiredArray(value, "bootstrap_transitions", "Package runtime contract");
  const transitions = [];
  const seen = new Set();
  for (const document of transitionDocuments) {
    requireObject(document, "Package runtime transition");
    const transition = {
      sourceTag: requiredString(document, "source_tag", "Package runtime transition"),
      packageVersion: requiredString(document, "source_package_version", "Package runtime transition"),
      payloadVersion: requiredString(document, "source_payload_version", "Package runtime transition"),
      payloadSequence: requiredInteger(document, "source_payload_sequence", "Package runtime transition"),
      generationId: requiredGenerationId(document, "source_generation_id", "Package runtime transition"),
      bootstrapProtocol: requiredInteger(document, "source_bootstrap_protocol", "Package runtime transition"),
      sourceMarkerSchemaVersion: requiredInteger(document, "source_marker_schema_version", "Package runtime transition"),
      sourceHostUseGateVersion: requiredInteger(document, "source_host_use_gate_version", "Package runtime transition"),
      sourceGenerationLeaseVersion: requiredInteger(document, "source_generation_lease_version", "Package runtime transition"),
      sourceFlatFileCount: requiredInteger(document, "source_flat_file_count", "Package runtime transition"),
      sourceFlatClosureSha256: requiredHash(document, "source_flat_closure_sha256", "Package runtime transition"),
      stableWrapperSha256: requiredHash(document, "source_stable_wrapper_sha256", "Package runtime transition")
    };
    const key = `${transition.packageVersion}\n${transition.payloadVersion}\n${transition.payloadSequence}\n${transition.generationId}\n${transition.bootstrapProtocol}`;
    if (!/^v[A-Za-z0-9.-]{0,127}$/.test(transition.sourceTag)
        || transition.payloadSequence < 1
        || transition.payloadSequence >= payloadSequence
        || transition.bootstrapProtocol < 1
        || transition.sourceMarkerSchemaVersion < 1
        || transition.sourceHostUseGateVersion < 1
        || transition.sourceGenerationLeaseVersion < 2
        || transition.sourceFlatFileCount < 1
        || seen.has(key)) {
      throw new Error("Package runtime contract contains an invalid or duplicate transition.");
    }
    seen.add(key);
    transitions.push(transition);
  }
  return {
    manifestPath,
    sha256: hashBytes(bytes),
    packageVersion,
    payloadVersion,
    payloadSequence,
    generationId,
    bootstrapProtocol,
    controlContract,
    stableWrapperSha256,
    transitions
  };
}

function readSelectedInstance(root, contract) {
  const runtimeRoot = path.join(root, "AIWork", ".runtime", "codedb");
  const instancesRoot = path.join(runtimeRoot, "instances");
  const generationsRoot = path.join(runtimeRoot, "host", "generations");
  const selectionPath = path.join(runtimeRoot, "control", "current-instance.json");
  assertReviewedPath(runtimeRoot, selectionPath, "current instance selection", "file");
  const { value: selection } = readRequiredJson(selectionPath, MAX_INSTANCE_SELECTION_BYTES, "current instance selection");
  const instanceId = requiredString(selection, "instance_id", "current instance selection");
  const instanceRelativePath = normalizeRelativePath(requiredString(selection, "instance_relative_path", "current instance selection"));
  const selectedGenerationId = requiredGenerationId(selection, "generation_id", "current instance selection");
  const expectedProjectIdentity = createProjectIdentity(root);
  if (requiredInteger(selection, "schema_version", "current instance selection") !== 1
      || requiredString(selection, "managed_by", "current instance selection") !== "com.rice.ai-codedb"
      || requiredString(selection, "project_identity", "current instance selection") !== expectedProjectIdentity
      || !/^[0-9a-f]{32}$/.test(instanceId)
      || instanceRelativePath !== `AIWork/.runtime/codedb/instances/${instanceId}`) {
    throw new Error("Current instance selection identity is invalid.");
  }

  const instanceRoot = path.resolve(root, instanceRelativePath.replace(/\//g, path.sep));
  assertInside(instanceRoot, instancesRoot, "selected instance");
  assertReviewedPath(instancesRoot, instanceRoot, "selected instance", "directory");
  const instanceManifestPath = path.join(instanceRoot, "instance.json");
  assertReviewedPath(instanceRoot, instanceManifestPath, "selected instance manifest", "file");
  const { value: instance, bytes: instanceBytes } = readRequiredJson(
    instanceManifestPath,
    MAX_INSTANCE_MANIFEST_BYTES,
    "selected instance manifest");
  if (hashBytes(instanceBytes) !== requiredHash(selection, "instance_manifest_sha256", "current instance selection")) {
    throw new Error("Selected instance manifest hash does not match current-instance.json.");
  }

  const generationId = requiredGenerationId(instance, "generation_id", "selected instance manifest");
  const packageVersion = requiredString(instance, "package_version", "selected instance manifest");
  const payloadVersion = requiredString(instance, "payload_version", "selected instance manifest");
  const payloadSequence = requiredInteger(instance, "payload_sequence", "selected instance manifest");
  const bootstrapProtocol = requiredInteger(instance, "bootstrap_protocol", "selected instance manifest");
  const generationRelativePath = normalizeRelativePath(requiredString(instance, "generation_relative_path", "selected instance manifest"));
  const workerRelativePath = normalizeRelativePath(requiredString(instance, "worker_relative_path", "selected instance manifest"));
  if (requiredInteger(instance, "schema_version", "selected instance manifest") !== 1
      || requiredString(instance, "managed_by", "selected instance manifest") !== "com.rice.ai-codedb"
      || requiredString(instance, "project_identity", "selected instance manifest") !== expectedProjectIdentity
      || requiredString(instance, "instance_id", "selected instance manifest") !== instanceId
      || normalizeRelativePath(requiredString(instance, "instance_relative_path", "selected instance manifest")) !== instanceRelativePath
      || requiredString(instance, "state", "selected instance manifest") !== "READY"
      || generationId !== selectedGenerationId
      || generationRelativePath !== `AIWork/.runtime/codedb/host/generations/${generationId}`
      || workerRelativePath !== "wrapper/codedb-project-instance-worker.mjs") {
    throw new Error("Selected instance manifest identity is invalid.");
  }

  const selectedIdentity = {
    packageVersion,
    payloadVersion,
    payloadSequence,
    generationId,
    bootstrapProtocol
  };
  const disposition = classifySelectedGeneration(contract, selectedIdentity);
  const expectedStableWrapperSha256 = getExpectedStableWrapperSha256(
    contract,
    selectedIdentity,
    disposition);
  const stableWrapperPath = path.resolve(
    root,
    STABLE_WRAPPER_RELATIVE_PATH.replace(/\//g, path.sep));
  assertReviewedPath(root, stableWrapperPath, "selected stable wrapper", "file");
  if (hashBytes(readBoundedBytes(
    stableWrapperPath,
    MAX_INSTANCE_WORKER_BYTES,
    "selected stable wrapper")) !== expectedStableWrapperSha256) {
    throw new Error("Selected stable wrapper does not match the Package-declared runtime identity.");
  }
  const generationRoot = path.resolve(root, generationRelativePath.replace(/\//g, path.sep));
  assertInside(generationRoot, generationsRoot, "selected generation");
  assertReviewedPath(root, generationRoot, "selected generation", "directory");
  const packageGenerationsRoot = path.join(path.dirname(contract.manifestPath), "Generations");
  const packageGenerationRoot = path.resolve(packageGenerationsRoot, generationId);
  assertInside(packageGenerationRoot, packageGenerationsRoot, "Package generation");
  assertReviewedPath(path.dirname(contract.manifestPath), packageGenerationRoot, "Package generation", "directory");
  const closure = validateGenerationClosure({
    projectGenerationRoot: generationRoot,
    packageGenerationRoot,
    identity: { packageVersion, payloadVersion, payloadSequence, generationId, bootstrapProtocol },
    workerRelativePath
  });
  const generationManifestHash = closure.generationManifestHash;
  const workerHash = closure.workerHash;
  if (generationManifestHash !== requiredHash(instance, "generation_manifest_sha256", "selected instance manifest")
      || workerHash !== requiredHash(instance, "worker_sha256", "selected instance manifest")) {
    throw new Error("Selected instance does not match the Package-owned immutable generation closure.");
  }
  return {
    instanceId,
    instanceRoot,
    generationId,
    generationRoot,
    disposition,
    stableWrapperPath,
    stableWrapperSha256: expectedStableWrapperSha256
  };
}

function validateGenerationClosure({
  projectGenerationRoot,
  packageGenerationRoot,
  identity,
  workerRelativePath
}) {
  assertReviewedPath(path.dirname(projectGenerationRoot), projectGenerationRoot, "selected generation", "directory");
  assertReviewedPath(path.dirname(packageGenerationRoot), packageGenerationRoot, "Package generation", "directory");
  const projectManifestPath = path.join(projectGenerationRoot, "generation-manifest.json");
  const packageManifestPath = path.join(packageGenerationRoot, "generation-manifest.json");
  assertReviewedPath(projectGenerationRoot, projectManifestPath, "selected generation manifest", "file");
  assertReviewedPath(packageGenerationRoot, packageManifestPath, "Package generation manifest", "file");
  const projectManifest = readRequiredJson(
    projectManifestPath,
    MAX_GENERATION_MANIFEST_BYTES,
    "selected generation manifest");
  const packageManifest = readRequiredJson(
    packageManifestPath,
    MAX_GENERATION_MANIFEST_BYTES,
    "Package generation manifest");
  const generationManifestHash = hashBytes(projectManifest.bytes);
  if (generationManifestHash !== hashBytes(packageManifest.bytes)) {
    throw new Error("Selected generation manifest does not match the Package generation manifest.");
  }

  const manifest = projectManifest.value;
  if (requiredInteger(manifest, "schema_version", "selected generation manifest") !== 1
      || requiredString(manifest, "managed_by", "selected generation manifest") !== "com.rice.ai-codedb"
      || requiredGenerationId(manifest, "generation_id", "selected generation manifest") !== identity.generationId
      || requiredString(manifest, "package_version", "selected generation manifest") !== identity.packageVersion
      || requiredString(manifest, "payload_version", "selected generation manifest") !== identity.payloadVersion
      || requiredInteger(manifest, "payload_sequence", "selected generation manifest") !== identity.payloadSequence
      || requiredInteger(manifest, "bootstrap_protocol", "selected generation manifest") !== identity.bootstrapProtocol) {
    throw new Error("Selected generation manifest identity is invalid.");
  }

  const entries = requiredArray(manifest, "files", "selected generation manifest");
  if (entries.length === 0) throw new Error("Selected generation manifest contains no files.");
  const expectedFiles = new Map();
  let totalBytes = projectManifest.bytes.length;
  for (const entry of entries) {
    requireObject(entry, "selected generation file");
    const relativePath = normalizeRelativePath(requiredString(entry, "path", "selected generation file"));
    const key = pathKey(relativePath);
    if (relativePath === "generation-manifest.json" || expectedFiles.has(key)) {
      throw new Error("Selected generation manifest contains a duplicate or reserved file path.");
    }
    expectedFiles.set(key, { relativePath, sha256: requiredHash(entry, "sha256", "selected generation file") });
  }

  for (const { relativePath, sha256 } of expectedFiles.values()) {
    const projectPath = path.resolve(projectGenerationRoot, relativePath.replace(/\//g, path.sep));
    const packagePath = path.resolve(packageGenerationRoot, relativePath.replace(/\//g, path.sep));
    assertReviewedPath(projectGenerationRoot, projectPath, `selected generation file ${relativePath}`, "file");
    assertReviewedPath(packageGenerationRoot, packagePath, `Package generation file ${relativePath}`, "file");
    const projectBytes = readBoundedBytes(
      projectPath,
      MAX_GENERATION_FILE_BYTES,
      `selected generation file ${relativePath}`);
    const packageBytes = readBoundedBytes(
      packagePath,
      MAX_GENERATION_FILE_BYTES,
      `Package generation file ${relativePath}`);
    totalBytes += projectBytes.length;
    if (totalBytes > MAX_GENERATION_TOTAL_BYTES
        || hashBytes(projectBytes) !== sha256
        || hashBytes(packageBytes) !== sha256) {
      throw new Error(`Selected generation file is missing, oversized, or drifted: ${relativePath}`);
    }
  }

  const closureFiles = new Map(expectedFiles);
  closureFiles.set(pathKey("generation-manifest.json"), {
    relativePath: "generation-manifest.json",
    sha256: generationManifestHash
  });
  assertFilesystemClosure(projectGenerationRoot, closureFiles, "selected immutable generation");
  assertFilesystemClosure(packageGenerationRoot, closureFiles, "Package immutable generation");

  const workerEntry = closureFiles.get(pathKey(workerRelativePath));
  if (!workerEntry) throw new Error("Selected generation manifest does not declare the instance worker.");
  return { generationManifestHash, workerHash: workerEntry.sha256 };
}

function assertFilesystemClosure(root, expectedFiles, label) {
  const allowedDirectories = new Set([pathKey("")]);
  for (const { relativePath } of expectedFiles.values()) {
    let directory = path.posix.dirname(relativePath);
    while (directory !== ".") {
      allowedDirectories.add(pathKey(directory));
      directory = path.posix.dirname(directory);
    }
  }
  const visit = (directory, relativeDirectory) => {
    const entries = fs.readdirSync(directory, { withFileTypes: true });
    for (const entry of entries) {
      const relativePath = relativeDirectory
        ? `${relativeDirectory}/${entry.name}`
        : entry.name;
      const fullPath = path.join(directory, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`${label} traverses a symbolic link or junction: ${relativePath}`);
      if (entry.isDirectory()) {
        if (!allowedDirectories.has(pathKey(relativePath)))
          throw new Error(`${label} contains an undeclared directory: ${relativePath}`);
        assertReviewedPath(root, fullPath, `${label} directory ${relativePath}`, "directory");
        visit(fullPath, relativePath);
        continue;
      }
      if (!entry.isFile() || !expectedFiles.has(pathKey(relativePath)))
        throw new Error(`${label} contains an undeclared filesystem entry: ${relativePath}`);
      assertReviewedPath(root, fullPath, `${label} file ${relativePath}`, "file");
    }
  };
  visit(root, "");
}

function classifySelectedGeneration(contract, selected) {
  const current = selected.packageVersion === contract.packageVersion
    && selected.payloadVersion === contract.payloadVersion
    && selected.payloadSequence === contract.payloadSequence
    && selected.generationId === contract.generationId
    && selected.bootstrapProtocol === contract.bootstrapProtocol;
  if (current) return "CURRENT";
  if (selected.payloadSequence > contract.payloadSequence) return failDisposition("NEWER");
  if (selected.payloadSequence === contract.payloadSequence) return failDisposition("SEQUENCE_COLLISION");
  const matches = contract.transitions.filter((transition) =>
    transition.packageVersion === selected.packageVersion
    && transition.payloadVersion === selected.payloadVersion
    && transition.payloadSequence === selected.payloadSequence
    && transition.generationId === selected.generationId
    && transition.bootstrapProtocol === selected.bootstrapProtocol);
  if (matches.length !== 1) return failDisposition("INVALID");
  return "TRUSTED_PREVIOUS";
}

function getExpectedStableWrapperSha256(contract, selected, disposition) {
  if (disposition === "CURRENT") return contract.stableWrapperSha256;
  if (disposition === "TRUSTED_PREVIOUS") {
    const matches = contract.transitions.filter((transition) =>
      transition.packageVersion === selected.packageVersion
      && transition.payloadVersion === selected.payloadVersion
      && transition.payloadSequence === selected.payloadSequence
      && transition.generationId === selected.generationId
      && transition.bootstrapProtocol === selected.bootstrapProtocol);
    if (matches.length === 1) return matches[0].stableWrapperSha256;
  }
  throw new Error(`Selected instance generation disposition is ${disposition}.`);
}

function failDisposition(disposition) {
  throw new Error(`Selected instance generation disposition is ${disposition}.`);
}

function readRequiredJson(filePath, maximumBytes, label) {
  const bytes = readBoundedBytes(filePath, maximumBytes, label);
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf)
    throw new Error(`${label} must be UTF-8 without a byte-order mark.`);
  let text;
  try { text = new TextDecoder("utf-8", { fatal: true }).decode(bytes); }
  catch (error) { throw new Error(`${label} is not strict UTF-8: ${error.message}`); }
  let value;
  try { value = parseStrictJson(text, label); }
  catch (error) { throw new Error(`${label} is invalid JSON: ${error.message}`); }
  requireObject(value, label);
  return { value, bytes };
}

function readBoundedBytes(filePath, maximumBytes, label) {
  const resolved = realFile(filePath, label);
  const bytes = fs.readFileSync(resolved);
  if (bytes.length === 0 || bytes.length > maximumBytes)
    throw new Error(`${label} size is outside the accepted range.`);
  return bytes;
}

function requireObject(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error(`${label} must be a JSON object.`);
  return value;
}

function requiredArray(value, name, label) {
  if (!Array.isArray(value[name])) throw new Error(`${label}.${name} must be an array.`);
  return value[name];
}

function requiredString(value, name, label) {
  if (typeof value[name] !== "string" || value[name].length === 0)
    throw new Error(`${label}.${name} must be a non-empty string.`);
  return value[name];
}

function requiredInteger(value, name, label) {
  if (!Number.isSafeInteger(value[name])) throw new Error(`${label}.${name} must be an integer.`);
  return value[name];
}

function requiredGenerationId(value, name, label) {
  const generationId = requiredString(value, name, label);
  if (!/^[A-Za-z0-9._-]{1,64}$/.test(generationId)) throw new Error(`${label}.${name} is invalid.`);
  return generationId;
}

function requiredHash(value, name, label) {
  const digest = requiredString(value, name, label);
  if (!/^[0-9a-f]{64}$/.test(digest)) throw new Error(`${label}.${name} must be a lowercase SHA-256.`);
  return digest;
}

function normalizeRelativePath(value) {
  const normalized = String(value).replace(/\\/g, "/");
  if (!normalized || path.posix.isAbsolute(normalized) || normalized.includes("\0"))
    throw new Error(`Relative path is invalid: ${normalized}`);
  const collapsed = path.posix.normalize(normalized);
  if (collapsed === "."
      || collapsed === ".."
      || collapsed.startsWith("../")
      || collapsed !== normalized)
    throw new Error(`Relative path escapes its reviewed root: ${normalized}`);
  return collapsed;
}

function readOptionalJson(filePath, maximumBytes, label) {
  if (!fs.existsSync(filePath)) return null;
  try {
    return readRequiredJson(filePath, maximumBytes, label).value;
  } catch (error) {
    // Windows replacement can expose a narrow remove/rename gap after the
    // existence check. Only that observed absence is optional; malformed,
    // redirected, oversized, or invalid UTF-8 evidence still fails closed.
    if (!fs.existsSync(filePath)) return null;
    throw error;
  }
}

function parseStrictJson(text, label) {
  let index = 0;
  let depth = 0;
  const fail = (detail) => { throw new Error(`${label} ${detail}`); };
  const skipWhitespace = () => {
    while (index < text.length && [" ", "\t", "\r", "\n"].includes(text[index])) index += 1;
  };
  const readString = () => {
    if (text[index] !== '"') fail(`expected a JSON string at character ${index}.`);
    const start = index++;
    let escaped = false;
    while (index < text.length) {
      const character = text[index++];
      if (character.charCodeAt(0) < 0x20) fail("contains an unescaped JSON control character.");
      if (escaped) {
        escaped = false;
        continue;
      }
      if (character === "\\") {
        escaped = true;
        continue;
      }
      if (character !== '"') continue;
      let result;
      try { result = JSON.parse(text.slice(start, index)); }
      catch (error) { fail(`contains an invalid JSON string: ${error.message}`); }
      for (let offset = 0; offset < result.length; offset += 1) {
        const code = result.charCodeAt(offset);
        if (code >= 0xd800 && code <= 0xdbff) {
          if (offset + 1 >= result.length) fail("contains an unpaired high surrogate.");
          const low = result.charCodeAt(++offset);
          if (low < 0xdc00 || low > 0xdfff) fail("contains an unpaired high surrogate.");
        } else if (code >= 0xdc00 && code <= 0xdfff) {
          fail("contains an unpaired low surrogate.");
        }
      }
      return result;
    }
    fail("contains an unclosed JSON string.");
  };
  const parseValue = () => {
    skipWhitespace();
    if (index >= text.length) fail("contains an incomplete JSON value.");
    depth += 1;
    if (depth > 64) fail("exceeds the accepted nesting depth.");
    try {
      if (text[index] === "{") return parseObject();
      if (text[index] === "[") return parseArray();
      if (text[index] === '"') return readString();
      for (const [literal, value] of [["true", true], ["false", false], ["null", null]]) {
        if (text.startsWith(literal, index)) {
          index += literal.length;
          return value;
        }
      }
      const match = text.slice(index).match(/^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/);
      if (!match) fail(`contains an unsupported JSON token at character ${index}.`);
      index += match[0].length;
      const number = Number(match[0]);
      if (!Number.isFinite(number)) fail("contains a non-finite or out-of-range JSON number.");
      return number;
    } finally {
      depth -= 1;
    }
  };
  const parseObject = () => {
    index += 1;
    const result = Object.create(null);
    const names = new Set();
    skipWhitespace();
    if (text[index] === "}") { index += 1; return result; }
    while (index < text.length) {
      const name = readString();
      const nameKey = name.toLowerCase();
      if (names.has(nameKey)) fail(`contains a duplicate or case-ambiguous JSON property: ${name}.`);
      names.add(nameKey);
      skipWhitespace();
      if (text[index++] !== ":") fail(`expected : after JSON property ${name}.`);
      result[name] = parseValue();
      skipWhitespace();
      if (text[index] === "}") { index += 1; return result; }
      if (text[index++] !== ",") fail("expected , between JSON object properties.");
      skipWhitespace();
    }
    fail("contains an unclosed JSON object.");
  };
  const parseArray = () => {
    index += 1;
    const result = [];
    skipWhitespace();
    if (text[index] === "]") { index += 1; return result; }
    while (index < text.length) {
      result.push(parseValue());
      skipWhitespace();
      if (text[index] === "]") { index += 1; return result; }
      if (text[index++] !== ",") fail("expected , between JSON array values.");
      skipWhitespace();
    }
    fail("contains an unclosed JSON array.");
  };
  const result = parseValue();
  skipWhitespace();
  if (index !== text.length) fail(`contains trailing content at character ${index}.`);
  return result;
}

function realDirectory(value, label) {
  const resolved = path.resolve(value);
  if (!isDirectory(resolved)) throw new Error(`${label} was not found: ${resolved}`);
  return fs.realpathSync(resolved);
}

function realFile(value, label) {
  const resolved = path.resolve(value);
  if (!isFile(resolved)) throw new Error(`${label} was not found: ${resolved}`);
  return fs.realpathSync(resolved);
}

function isDirectory(value) { try { return fs.statSync(value).isDirectory(); } catch { return false; } }
function isFile(value) { try { return fs.statSync(value).isFile(); } catch { return false; } }
function assertInside(target, root, label) { if (!isPathInside(target, root)) throw new Error(`${label} escapes its reviewed root.`); }
function isPathInside(target, root) { const relative = path.relative(path.resolve(root), path.resolve(target)); return relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative)); }
function assertReviewedPath(root, target, label, expectedType) {
  const reviewedRoot = path.resolve(root);
  const reviewedTarget = path.resolve(target);
  assertInside(reviewedTarget, reviewedRoot, label);
  assertNoRedirectedAncestors(reviewedRoot, reviewedTarget, label);
  if (!fs.existsSync(reviewedTarget)) throw new Error(`${label} was not found: ${reviewedTarget}`);
  const finalStat = fs.lstatSync(reviewedTarget);
  if ((expectedType === "file" && !finalStat.isFile())
      || (expectedType === "directory" && !finalStat.isDirectory())) {
    throw new Error(`${label} has the wrong filesystem type.`);
  }
}
function assertNoRedirectedAncestors(root, target, label) {
  const reviewedRoot = path.resolve(root);
  const reviewedTarget = path.resolve(target);
  assertInside(reviewedTarget, reviewedRoot, label);
  const relative = path.relative(reviewedRoot, reviewedTarget);
  let current = reviewedRoot;
  if (relative) {
    for (const component of relative.split(path.sep)) {
      current = path.join(current, component);
      if (!fs.existsSync(current)) break;
      const stat = fs.lstatSync(current);
      if (stat.isSymbolicLink()) throw new Error(`${label} traverses a symbolic link or junction: ${current}`);
      if (!pathsEqual(fs.realpathSync(current), current))
        throw new Error(`${label} traverses a redirected filesystem entry: ${current}`);
    }
  }
}
function pathKey(value) { return process.platform === "win32" ? String(value).toLowerCase() : String(value); }
function createProjectIdentity(root) { return `sha256:${hash(root.toLowerCase().replace(/\\/g, "/"))}`; }
function hash(value) { return crypto.createHash("sha256").update(String(value), "utf8").digest("hex"); }
function hashBytes(value) { return crypto.createHash("sha256").update(value).digest("hex"); }
function validId(value) { return value && /^[A-Za-z0-9._-]{1,128}$/.test(String(value)) ? String(value) : null; }
function positiveInt(value, fallback) { const number = Number(value); return Number.isInteger(number) && number > 0 ? number : fallback; }
function truncate(value) { return String(value ?? "").slice(-32768); }
function delay(milliseconds) { return new Promise((resolve) => setTimeout(resolve, milliseconds)); }
function print(marker, value) { process.stdout.write(`[${marker}] codedb project supervisor ${value.action || "status"}.\n${JSON.stringify(value)}\n`); }

await main();
