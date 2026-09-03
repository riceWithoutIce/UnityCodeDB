#!/usr/bin/env node

// Narrow Supervisor contract harness. Every process and filesystem mutation is
// isolated to a temporary synthetic Unity project.
import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

if (process.platform !== "win32") {
  console.log("[DEFERRED] Supervisor named-pipe harness requires Windows.");
  process.exit(0);
}

const supervisorScript = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "Tools~",
  "codedb-project-supervisor.mjs");
const TARGET = Object.freeze({
  packageVersion: "0.2.5-preview.5",
  payloadVersion: "poc.34",
  payloadSequence: 34,
  generationId: "poc.34",
  bootstrapProtocol: 1
});
const PREVIOUS = Object.freeze({
  packageVersion: "0.2.5-preview.5",
  payloadVersion: "poc.33",
  payloadSequence: 33,
  generationId: "poc.33",
  bootstrapProtocol: 1
});
const SYNTHETIC_BUMP_TARGET = Object.freeze({
  packageVersion: "0.2.5-preview.6",
  payloadVersion: "poc.35",
  payloadSequence: 35,
  generationId: "poc.35",
  bootstrapProtocol: 1
});
const STABLE_WRAPPER_RELATIVE_PATH = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs";
const TARGET_STABLE_WRAPPER_CONTENT = "// synthetic Package-owned current stable wrapper\n";
const PREVIOUS_STABLE_WRAPPER_CONTENT = "// synthetic Package-owned previous stable wrapper\n";
const TARGET_STABLE_WRAPPER_SHA256 = hashBytes(Buffer.from(TARGET_STABLE_WRAPPER_CONTENT, "utf8"));
const PREVIOUS_STABLE_WRAPPER_SHA256 = hashBytes(Buffer.from(PREVIOUS_STABLE_WRAPPER_CONTENT, "utf8"));
const CONTROL_CONTRACT = Object.freeze({
  id: "v0.3-control",
  version: 1,
  schemaVersion: 1,
  sha256: hashBytes(Buffer.from([
    "com.rice.ai-codedb",
    "control-contract",
    "v0.3-control",
    "1",
    "1"
  ].join("\n"), "utf8"))
});
const CONTROL_NAMESPACE_RELATIVE_PATH = [
  "AIWork",
  ".runtime",
  "codedb",
  "control",
  "contracts",
  CONTROL_CONTRACT.id,
  `v${CONTROL_CONTRACT.version}`,
  "supervisor"
].join("/");

function mkdir(directory) { fs.mkdirSync(directory, { recursive: true }); }
function write(file, text) { mkdir(path.dirname(file)); fs.writeFileSync(file, text, "utf8"); }
function jsonText(value) { return `${JSON.stringify(value, null, 2)}\n`; }
function json(file, value) { write(file, jsonText(value)); }
function hashBytes(value) { return crypto.createHash("sha256").update(value).digest("hex"); }
function hashFile(file) { return hashBytes(fs.readFileSync(file)); }
function projectIdentity(projectRoot) {
  return `sha256:${hashBytes(Buffer.from(projectRoot.toLowerCase().replace(/\\/g, "/"), "utf8"))}`;
}
function canonicalPipeIdentityPath(value) {
  return path.resolve(value).replace(/\\/g, "/").toLowerCase();
}
function expectedSupervisorPipe(projectRoot, runtime) {
  const identity = `${canonicalPipeIdentityPath(projectRoot)}\n${canonicalPipeIdentityPath(runtime)}`;
  return `\\\\.\\pipe\\codedb-supervisor-${hashBytes(Buffer.from(identity, "utf8")).slice(0, 20)}`;
}

function createFixture(selected = TARGET) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "codedb-supervisor-contract-"));
  const runtimeRoot = path.join(root, "AIWork", ".runtime", "codedb");
  const runtime = path.join(root, ...CONTROL_NAMESPACE_RELATIVE_PATH.split("/"));
  const legacyRuntime = path.join(runtimeRoot, "control", "supervisor");
  const packageRoot = path.join(root, "synthetic-package");
  const payloadRoot = path.join(packageRoot, "Payload~");
  const packageGenerationRoot = path.join(payloadRoot, "Generations", selected.generationId);
  const projectGenerationRoot = path.join(runtimeRoot, "host", "generations", selected.generationId);
  const instanceId = crypto.randomBytes(16).toString("hex");
  const instanceRelativePath = `AIWork/.runtime/codedb/instances/${instanceId}`;
  const instanceRoot = path.join(runtimeRoot, "instances", instanceId);
  const coordinatorRuntime = path.join(instanceRoot, "watch", "coordinator");
  const coordinatorScript = path.join(projectGenerationRoot, "coordinator", "codedb-watch-coordinator.mjs");
  const watchManager = path.join(projectGenerationRoot, "scripts", "manage-codedb-project-watch.ps1");
  const workerRelativePath = "wrapper/codedb-project-instance-worker.mjs";
  const workerPath = path.join(projectGenerationRoot, ...workerRelativePath.split("/"));
  const materializerScript = path.join(packageRoot, "Tools~", "materialize-codedb-host-payload.ps1");
  const coordinatorPipe = `\\\\.\\pipe\\codedb-supervisor-fixture-${process.pid}-${crypto.randomBytes(6).toString("hex")}`;
  const coordinatorToken = crypto.randomBytes(24).toString("hex");
  const lifecycleId = `fixture-${crypto.randomBytes(8).toString("hex")}`;

  for (const marker of ["Assets", "Packages", "ProjectSettings"]) mkdir(path.join(root, marker));
  for (const directory of ["config", "index", "adapter", "watch", "leases", "logs", "tmp"])
    mkdir(path.join(instanceRoot, directory));
  write(path.join(instanceRoot, "config", "codedb-mcp.toml"), "# synthetic selected Provider config\n");
  write(materializerScript, "# synthetic materializer path identity\n");
  const packageWrapperPath = path.join(payloadRoot, ...STABLE_WRAPPER_RELATIVE_PATH.split("/"));
  const stableWrapperPath = path.join(root, ...STABLE_WRAPPER_RELATIVE_PATH.split("/"));
  write(packageWrapperPath, TARGET_STABLE_WRAPPER_CONTENT);
  write(
    stableWrapperPath,
    selected.generationId === TARGET.generationId
      ? TARGET_STABLE_WRAPPER_CONTENT
      : PREVIOUS_STABLE_WRAPPER_CONTENT);

  const generationFiles = new Map([
    ["coordinator/codedb-watch-coordinator.mjs", "// synthetic coordinator path identity\n"],
    ["scripts/manage-codedb-project-watch.ps1", "# synthetic watch manager path identity\n"],
    [workerRelativePath, "// synthetic immutable instance worker\n"]
  ]);
  const generationEntries = [];
  for (const [relativePath, content] of generationFiles) {
    const digest = hashBytes(Buffer.from(content, "utf8"));
    generationEntries.push({ path: relativePath, sha256: digest });
    write(path.join(packageGenerationRoot, ...relativePath.split("/")), content);
    write(path.join(projectGenerationRoot, ...relativePath.split("/")), content);
  }
  const generationManifest = {
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    generation_id: selected.generationId,
    package_version: selected.packageVersion,
    payload_version: selected.payloadVersion,
    payload_sequence: selected.payloadSequence,
    bootstrap_protocol: selected.bootstrapProtocol,
    files: generationEntries
  };
  const generationManifestText = jsonText(generationManifest);
  const packageGenerationManifest = path.join(packageGenerationRoot, "generation-manifest.json");
  const projectGenerationManifest = path.join(projectGenerationRoot, "generation-manifest.json");
  write(packageGenerationManifest, generationManifestText);
  write(projectGenerationManifest, generationManifestText);

  const contract = {
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    control_contract: {
      id: CONTROL_CONTRACT.id,
      version: CONTROL_CONTRACT.version,
      schema_version: CONTROL_CONTRACT.schemaVersion,
      sha256: CONTROL_CONTRACT.sha256
    },
    package_version: TARGET.packageVersion,
    payload_version: TARGET.payloadVersion,
    payload_sequence: TARGET.payloadSequence,
    generation_id: TARGET.generationId,
    bootstrap_protocol: TARGET.bootstrapProtocol,
    bootstrap_transitions: [{
      source_tag: "v0.2.5-preview.5",
      source_package_version: PREVIOUS.packageVersion,
      source_payload_version: PREVIOUS.payloadVersion,
      source_payload_sequence: PREVIOUS.payloadSequence,
      source_generation_id: PREVIOUS.generationId,
      source_bootstrap_protocol: PREVIOUS.bootstrapProtocol,
      source_marker_schema_version: 2,
      source_host_use_gate_version: 1,
      source_generation_lease_version: 2,
      source_flat_file_count: 22,
      source_flat_closure_sha256: "a".repeat(64),
      source_stable_wrapper_sha256: PREVIOUS_STABLE_WRAPPER_SHA256
    }],
    files: [{
      source: STABLE_WRAPPER_RELATIVE_PATH,
      target: STABLE_WRAPPER_RELATIVE_PATH,
      sha256: TARGET_STABLE_WRAPPER_SHA256
    }]
  };
  const contractPath = path.join(payloadRoot, "payload-manifest.json");
  json(contractPath, contract);

  const identity = projectIdentity(root);
  const instanceManifestPath = path.join(instanceRoot, "instance.json");
  json(instanceManifestPath, {
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    project_identity: identity,
    instance_id: instanceId,
    instance_relative_path: instanceRelativePath,
    state: "READY",
    package_version: selected.packageVersion,
    payload_version: selected.payloadVersion,
    payload_sequence: selected.payloadSequence,
    generation_id: selected.generationId,
    generation_relative_path: `AIWork/.runtime/codedb/host/generations/${selected.generationId}`,
    generation_manifest_sha256: hashFile(projectGenerationManifest),
    bootstrap_protocol: selected.bootstrapProtocol,
    worker_relative_path: workerRelativePath,
    worker_sha256: hashFile(workerPath),
    created_at_utc: new Date().toISOString(),
    verified_at_utc: new Date().toISOString()
  });
  const selectionPath = path.join(runtimeRoot, "control", "current-instance.json");
  json(selectionPath, {
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    project_identity: identity,
    instance_id: instanceId,
    instance_relative_path: instanceRelativePath,
    instance_manifest_sha256: hashFile(instanceManifestPath),
    generation_id: selected.generationId,
    activated_at_utc: new Date().toISOString()
  });

  const coordinatorStatePath = path.join(coordinatorRuntime, "coordinator-state.json");
  json(coordinatorStatePath, {
    schema_version: 2,
    managed_by: "com.rice.ai-codedb",
    pipe_name: coordinatorPipe,
    auth_token: coordinatorToken,
    root,
    runtime: coordinatorRuntime,
    generation_id: selected.generationId,
    lifecycle_id: lifecycleId,
    provider_state: "ready",
    provider_ready_at_utc: new Date().toISOString(),
    adapter_enabled: false,
    adapter_state: "disabled",
    adapter_worker_state: "disabled",
    adapter_worker: null,
    coordinator_pid: process.pid
  });

  return {
    root,
    runtime,
    legacyRuntime,
    packageRoot,
    payloadRoot,
    packageGenerationRoot,
    projectGenerationRoot,
    instanceId,
    instanceRoot,
    coordinatorRuntime,
    coordinatorScript,
    coordinatorStatePath,
    coordinatorPipe,
    coordinatorToken,
    watchManager,
    workerPath,
    stableWrapperPath,
    packageWrapperPath,
    targetStableWrapperSha256: TARGET_STABLE_WRAPPER_SHA256,
    previousStableWrapperSha256: PREVIOUS_STABLE_WRAPPER_SHA256,
    materializerScript,
    contractPath,
    contractSha256: hashFile(contractPath),
    selectionPath,
    lifecycleId,
    selected,
    coordinatorServer: null,
    coordinatorStopRequested: false
  };
}

function installAdditionalFixtureInstance(fixture, identity) {
  const runtimeRoot = path.join(fixture.root, "AIWork", ".runtime", "codedb");
  const packageGenerationRoot = path.join(fixture.payloadRoot, "Generations", identity.generationId);
  const projectGenerationRoot = path.join(runtimeRoot, "host", "generations", identity.generationId);
  const workerRelativePath = "wrapper/codedb-project-instance-worker.mjs";
  const generationFiles = new Map([
    ["coordinator/codedb-watch-coordinator.mjs", "// synthetic coordinator path identity\n"],
    ["scripts/manage-codedb-project-watch.ps1", "# synthetic watch manager path identity\n"],
    [workerRelativePath, "// synthetic immutable instance worker\n"]
  ]);
  const generationEntries = [];
  for (const [relativePath, content] of generationFiles) {
    const digest = hashBytes(Buffer.from(content, "utf8"));
    generationEntries.push({ path: relativePath, sha256: digest });
    write(path.join(packageGenerationRoot, ...relativePath.split("/")), content);
    write(path.join(projectGenerationRoot, ...relativePath.split("/")), content);
  }
  const generationManifestText = jsonText({
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    generation_id: identity.generationId,
    package_version: identity.packageVersion,
    payload_version: identity.payloadVersion,
    payload_sequence: identity.payloadSequence,
    bootstrap_protocol: identity.bootstrapProtocol,
    files: generationEntries
  });
  const packageGenerationManifest = path.join(packageGenerationRoot, "generation-manifest.json");
  const projectGenerationManifest = path.join(projectGenerationRoot, "generation-manifest.json");
  write(packageGenerationManifest, generationManifestText);
  write(projectGenerationManifest, generationManifestText);

  const instanceId = crypto.randomBytes(16).toString("hex");
  const instanceRelativePath = `AIWork/.runtime/codedb/instances/${instanceId}`;
  const instanceRoot = path.join(runtimeRoot, "instances", instanceId);
  for (const directory of ["config", "index", "adapter", "watch", "leases", "logs", "tmp"])
    mkdir(path.join(instanceRoot, directory));
  write(path.join(instanceRoot, "config", "codedb-mcp.toml"), "# synthetic selected Provider config\n");
  const workerPath = path.join(projectGenerationRoot, ...workerRelativePath.split("/"));
  const instanceManifestPath = path.join(instanceRoot, "instance.json");
  json(instanceManifestPath, {
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    project_identity: projectIdentity(fixture.root),
    instance_id: instanceId,
    instance_relative_path: instanceRelativePath,
    state: "READY",
    package_version: identity.packageVersion,
    payload_version: identity.payloadVersion,
    payload_sequence: identity.payloadSequence,
    generation_id: identity.generationId,
    generation_relative_path: `AIWork/.runtime/codedb/host/generations/${identity.generationId}`,
    generation_manifest_sha256: hashFile(projectGenerationManifest),
    bootstrap_protocol: identity.bootstrapProtocol,
    worker_relative_path: workerRelativePath,
    worker_sha256: hashFile(workerPath),
    created_at_utc: new Date().toISOString(),
    verified_at_utc: new Date().toISOString()
  });
  const selection = {
    schema_version: 1,
    managed_by: "com.rice.ai-codedb",
    project_identity: projectIdentity(fixture.root),
    instance_id: instanceId,
    instance_relative_path: instanceRelativePath,
    instance_manifest_sha256: hashFile(instanceManifestPath),
    generation_id: identity.generationId,
    activated_at_utc: new Date().toISOString()
  };
  const stagedSelectionPath = path.join(runtimeRoot, "control", `staged-${instanceId}.json`);
  json(stagedSelectionPath, selection);

  const coordinatorRuntime = path.join(instanceRoot, "watch", "coordinator");
  const coordinatorStatePath = path.join(coordinatorRuntime, "coordinator-state.json");
  json(coordinatorStatePath, {
    schema_version: 2,
    managed_by: "com.rice.ai-codedb",
    pipe_name: fixture.coordinatorPipe,
    auth_token: fixture.coordinatorToken,
    root: fixture.root,
    runtime: coordinatorRuntime,
    generation_id: identity.generationId,
    lifecycle_id: fixture.lifecycleId,
    provider_state: "ready",
    provider_ready_at_utc: new Date().toISOString(),
    adapter_enabled: false,
    adapter_state: "disabled",
    adapter_worker_state: "disabled",
    adapter_worker: null,
    coordinator_pid: process.pid
  });

  return {
    instanceId,
    instanceRoot,
    projectGenerationRoot,
    coordinatorRuntime,
    coordinatorStatePath,
    coordinatorScript: path.join(projectGenerationRoot, "coordinator", "codedb-watch-coordinator.mjs"),
    watchManager: path.join(projectGenerationRoot, "scripts", "manage-codedb-project-watch.ps1"),
    stagedSelectionPath
  };
}

function writeUpgradeMaterializer(fixture, stagedSelectionPath) {
  const quote = (value) => String(value).replace(/'/g, "''");
  write(fixture.materializerScript, [
    "param([string]$Action, [string]$ProjectRoot, [string]$PayloadRoot)",
    "if ($Action -eq 'Upgrade') {",
    `  [IO.File]::WriteAllBytes('${quote(fixture.stableWrapperPath)}', [IO.File]::ReadAllBytes('${quote(fixture.packageWrapperPath)}'))`,
    `  [IO.File]::WriteAllBytes('${quote(fixture.selectionPath)}', [IO.File]::ReadAllBytes('${quote(stagedSelectionPath)}'))`,
    "}",
    "Write-Output '[PASS] synthetic materializer'",
    "exit 0",
    ""
  ].join("\r\n"));
}

function rewriteContractForSyntheticTarget(fixture, target, source) {
  const contract = JSON.parse(fs.readFileSync(fixture.contractPath, "utf8"));
  contract.package_version = target.packageVersion;
  contract.payload_version = target.payloadVersion;
  contract.payload_sequence = target.payloadSequence;
  contract.generation_id = target.generationId;
  contract.bootstrap_protocol = target.bootstrapProtocol;
  contract.bootstrap_transitions = [{
    source_tag: "v0.2.5-preview.6",
    source_package_version: source.packageVersion,
    source_payload_version: source.payloadVersion,
    source_payload_sequence: source.payloadSequence,
    source_generation_id: source.generationId,
    source_bootstrap_protocol: source.bootstrapProtocol,
    source_marker_schema_version: 2,
    source_host_use_gate_version: 1,
    source_generation_lease_version: 2,
    source_flat_file_count: 22,
    source_flat_closure_sha256: "a".repeat(64),
    source_stable_wrapper_sha256: TARGET_STABLE_WRAPPER_SHA256
  }];
  json(fixture.contractPath, contract);
  fixture.contractSha256 = hashFile(fixture.contractPath);
}

function writeSlowProbeMaterializer(fixture, counterPath) {
  const quote = (value) => String(value).replace(/'/g, "''");
  write(fixture.materializerScript, [
    "param([string]$Action, [string]$ProjectRoot, [string]$PayloadRoot)",
    "if ($Action -eq 'Probe') {",
    `  $counterPath = '${quote(counterPath)}'`,
    "  $count = if (Test-Path -LiteralPath $counterPath) { [int][IO.File]::ReadAllText($counterPath) } else { 0 }",
    "  [IO.File]::WriteAllText($counterPath, [string]($count + 1))",
    "  Start-Sleep -Milliseconds 2400",
    "}",
    "Write-Output '[PASS] synthetic slow materializer'",
    "exit 0",
    ""
  ].join("\r\n"));
}

function runSupervisor(fixture, command, extraEnv = {}, includeIdentity = true, additionalArguments = []) {
  const args = [
    supervisorScript,
    command,
    "--root", fixture.root,
    "--runtime", fixture.runtime,
    "--package-root", fixture.packageRoot
  ];
  args.push(...additionalArguments);
  if (includeIdentity) {
    args.push("--lifecycle-id", fixture.lifecycleId, "--supervisor-id", "harness");
  }
  return new Promise((resolve) => {
    const child = spawn(process.execPath, args, {
      cwd: fixture.root,
      stdio: ["ignore", "pipe", "pipe"],
      windowsHide: true,
      env: { ...process.env, ...extraEnv }
    });
    let stdout = "";
    let stderr = "";
    let timedOut = false;
    child.stdout.on("data", (chunk) => { stdout += String(chunk); });
    child.stderr.on("data", (chunk) => { stderr += String(chunk); });
    const timer = setTimeout(() => {
      timedOut = true;
      try { child.kill(); } catch { /* test child only */ }
    }, 45000);
    child.once("error", (error) => {
      clearTimeout(timer);
      resolve({ status: 1, stdout, stderr: `${stderr}${error.message}`, timedOut });
    });
    child.once("close", (status) => {
      clearTimeout(timer);
      resolve({ status: timedOut ? 124 : (status ?? 1), stdout, stderr, timedOut });
    });
  });
}

async function verifyStableDefaultIdentity() {
  const fixture = createFixture(TARGET);
  try {
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start", {}, false);
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const status = await runSupervisor(fixture, "status", {}, false);
    assert.equal(status.status, 0, `${status.stdout}\n${status.stderr}`);
    assert.match(status.stdout, /\[OK\]/);
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyLegacyAndMismatchedRuntimeRejectedWithoutMutation() {
  const fixture = createFixture(TARGET);
  try {
    const legacy = await runSupervisor(
      fixture,
      "status",
      {},
      true,
      ["--runtime", fixture.legacyRuntime]);
    assert.notEqual(legacy.status, 0);
    assert.match(legacy.stderr, /Package-derived control namespace|control namespace/i);
    assert.equal(fs.existsSync(fixture.runtime), false);
    assert.equal(fs.existsSync(fixture.legacyRuntime), false);

    const mismatchedRuntime = path.join(
      fixture.root,
      "AIWork",
      ".runtime",
      "codedb",
      "control",
      "contracts",
      "other-contract",
      "v1",
      "supervisor");
    const mismatched = await runSupervisor(
      fixture,
      "status",
      {},
      true,
      ["--runtime", mismatchedRuntime]);
    assert.notEqual(mismatched.status, 0);
    assert.match(mismatched.stderr, /Package-derived control namespace|control namespace/i);
    assert.equal(fs.existsSync(mismatchedRuntime), false);

    // Daemon validation must fail before its error-evidence writer is allowed
    // to touch the caller-supplied legacy path.
    const daemon = await runSupervisor(
      fixture,
      "daemon",
      {},
      true,
      ["--runtime", fixture.legacyRuntime]);
    assert.notEqual(daemon.status, 0);
    assert.match(daemon.stderr, /Package-derived control namespace|control namespace/i);
    assert.equal(
      fs.existsSync(path.join(fixture.legacyRuntime, "supervisor-error.json")),
      false);
  } finally {
    await cleanupFixture(fixture);
  }
}

function requestPipe(pipeName, authToken, request) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection(pipeName);
    let buffer = "";
    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error("IPC request timed out."));
    }, 5000);
    const finish = (callback, value) => {
      clearTimeout(timer);
      socket.destroy();
      callback(value);
    };
    socket.setEncoding("utf8");
    socket.on("connect", () => socket.write(`${JSON.stringify({ auth_token: authToken, ...request })}\n`));
    socket.on("data", (chunk) => {
      buffer += chunk;
      const newline = buffer.indexOf("\n");
      if (newline >= 0) {
        try { finish(resolve, JSON.parse(buffer.slice(0, newline))); }
        catch (error) { finish(reject, error); }
      }
    });
    socket.on("error", (error) => finish(reject, error));
  });
}

async function waitForOperation(pipeName, authToken, operationId, timeoutMilliseconds = 15000) {
  const deadline = Date.now() + timeoutMilliseconds;
  while (Date.now() < deadline) {
    const response = await requestPipe(
      pipeName,
      authToken,
      { command: "operation", operation_id: operationId });
    assert.equal(response.operation_id, operationId, "Supervisor operation identity changed while polling.");
    if (response.pending !== true) return response;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error(`Supervisor operation ${operationId} did not reach a terminal state.`);
}

async function startCoordinator(fixture) {
  fixture.coordinatorServer = net.createServer((socket) => {
    socket.setEncoding("utf8");
    let buffer = "";
    socket.on("data", (chunk) => {
      buffer += chunk;
      const newline = buffer.indexOf("\n");
      if (newline < 0) return;
      let request;
      try { request = JSON.parse(buffer.slice(0, newline)); }
      catch { socket.end(`${JSON.stringify({ ok: false, error_code: "INVALID_JSON" })}\n`); return; }
      if (request.auth_token !== fixture.coordinatorToken) {
        socket.end(`${JSON.stringify({ ok: false, error_code: "UNAUTHORIZED" })}\n`);
        return;
      }
      if (request.command === "stop") fixture.coordinatorStopRequested = true;
      const status = JSON.parse(fs.readFileSync(fixture.coordinatorStatePath, "utf8"));
      socket.end(`${JSON.stringify({
        ok: true,
        status,
        result: request.command === "query" ? { hits: ["query-served"] } : undefined
      })}\n`);
    });
  });
  await new Promise((resolve, reject) => {
    fixture.coordinatorServer.once("error", reject);
    fixture.coordinatorServer.listen(fixture.coordinatorPipe, resolve);
  });
}

async function waitForSupervisorExit(fixture, timeoutMilliseconds = 5000) {
  const statePath = path.join(fixture.runtime, "supervisor-state.json");
  const lockPath = path.join(fixture.runtime, "supervisor.lock");
  const deadline = Date.now() + timeoutMilliseconds;
  while (Date.now() < deadline) {
    if (!fs.existsSync(statePath) && !fs.existsSync(lockPath)) return true;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  return !fs.existsSync(statePath) && !fs.existsSync(lockPath);
}

async function waitForPath(filePath, timeoutMilliseconds = 5000) {
  const deadline = Date.now() + timeoutMilliseconds;
  while (Date.now() < deadline) {
    if (fs.existsSync(filePath)) return true;
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
  return fs.existsSync(filePath);
}

async function waitForCondition(predicate, timeoutMilliseconds = 5000) {
  const deadline = Date.now() + timeoutMilliseconds;
  while (Date.now() < deadline) {
    if (predicate()) return true;
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
  return predicate();
}

function terminateFixtureSupervisor(state) {
  if (!Number.isInteger(state?.supervisor_pid) || state.supervisor_pid <= 0) return;
  try { process.kill(state.supervisor_pid); } catch { /* already gone */ }
}

async function stopFixtureCoordinator(fixture) {
  if (!fixture.coordinatorServer) return;
  const server = fixture.coordinatorServer;
  fixture.coordinatorServer = null;
  await new Promise((resolve) => server.close(resolve));
}

function isProcessAlive(child) {
  if (!child || !Number.isInteger(child.pid) || child.pid <= 0 || child.exitCode !== null)
    return false;
  try {
    process.kill(child.pid, 0);
    return true;
  } catch {
    return false;
  }
}

async function stopTestProcess(child) {
  if (!isProcessAlive(child)) return;
  const closed = new Promise((resolve) => child.once("close", resolve));
  try { child.kill(); } catch { return; }
  await Promise.race([
    closed,
    new Promise((resolve) => setTimeout(resolve, 2000))
  ]);
}

async function removeFixtureRoot(root) {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    try { fs.rmSync(root, { recursive: true, force: true }); } catch { /* retry transient Windows handles */ }
    if (!fs.existsSync(root)) return;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
}

async function cleanupFixture(fixture) {
  try {
    if (fs.existsSync(path.join(fixture.runtime, "supervisor-state.json")))
      await runSupervisor(fixture, "stop");
  } catch { /* best effort for an intentionally invalid fixture */ }
  try { await waitForSupervisorExit(fixture); } catch { /* best effort */ }
  try {
    await stopFixtureCoordinator(fixture);
  } catch { /* best effort */ }
  await removeFixtureRoot(fixture.root);
}

async function verifyHappyPath(selected, expectedDisposition) {
  const fixture = createFixture(selected);
  let externalSentinel = null;
  try {
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    assert.match(started.stdout, /STARTED|ATTACHED/);

    const supervisorState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(supervisorState.schema_version, 3);
    assert.equal(supervisorState.protocol_version, 1);
    assert.equal(supervisorState.project_identity, projectIdentity(fixture.root));
    assert.equal(supervisorState.control_contract_id, CONTROL_CONTRACT.id);
    assert.equal(supervisorState.control_contract_version, CONTROL_CONTRACT.version);
    assert.equal(supervisorState.control_contract_schema_version, CONTROL_CONTRACT.schemaVersion);
    assert.equal(supervisorState.control_contract_sha256, CONTROL_CONTRACT.sha256);
    assert.equal(supervisorState.control_namespace, fixture.runtime);
    assert.equal(supervisorState.runtime, fixture.runtime);
    assert.equal(supervisorState.target_generation_id, TARGET.generationId);
    assert.equal(supervisorState.selected_generation_id, selected.generationId);
    assert.equal(supervisorState.selected_instance_id, fixture.instanceId);
    assert.equal(supervisorState.generation_id, selected.generationId);
    assert.equal(supervisorState.runtime_contract_sha256, fixture.contractSha256);
    assert.equal(supervisorState.supervisor_protocol_version, 2);
    assert.equal(supervisorState.generation_disposition, expectedDisposition);
    assert.equal(supervisorState.pipe_name, expectedSupervisorPipe(fixture.root, fixture.runtime));

    const reattached = await runSupervisor(fixture, "start");
    assert.equal(reattached.status, 0, `${reattached.stdout}\n${reattached.stderr}`);
    assert.match(reattached.stdout, /ATTACHED/);
    const reattachedState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(
      reattachedState.supervisor_pid,
      supervisorState.supervisor_pid,
      "Domain-reload-style reconnect must preserve the healthy Supervisor PID.");

    const status = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "status" });
    assert.equal(status.ok, true);
    assert.equal(status.status.readiness_state, "core_ready");
    assert.equal(status.status.supervisor_schema_version, 3);
    assert.equal(status.status.generation_disposition, expectedDisposition);
    assert.equal(status.status.control_namespace, fixture.runtime);

    const query = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "query", query: "status" });
    assert.equal(query.ok, true);
    assert.deepEqual(query.result.hits, ["query-served"]);

    const [first, second] = await Promise.all([
      requestPipe(supervisorState.pipe_name, supervisorState.auth_token, { command: "reconcile" }),
      requestPipe(supervisorState.pipe_name, supervisorState.auth_token, { command: "reconcile" })
    ]);
    assert.equal(first.ok, true);
    assert.equal(second.ok, true);
    assert.equal(first.accepted, true);
    assert.equal(first.pending, true);
    assert.equal(second.operation_id, first.operation_id);
    assert.equal(second.reused, true);
    const reconciled = await waitForOperation(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      first.operation_id);
    assert.equal(reconciled.ok, true, reconciled.error || "Reconcile operation failed.");
    assert.equal(reconciled.pending, false);

    const unauthorized = await requestPipe(
      supervisorState.pipe_name,
      "wrong-token",
      { command: "status" });
    assert.equal(unauthorized.ok, false);
    assert.equal(unauthorized.error_code, "UNAUTHORIZED");

    const unauthorizedShutdown = await requestPipe(
      supervisorState.pipe_name,
      "wrong-token",
      { command: "shutdown", expected_lifecycle_id: fixture.lifecycleId });
    assert.equal(unauthorizedShutdown.ok, false);
    assert.equal(unauthorizedShutdown.error_code, "UNAUTHORIZED");
    assert.equal(fs.existsSync(path.join(fixture.runtime, "supervisor-state.json")), true);

    const wrongLifecycleShutdown = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "shutdown", expected_lifecycle_id: `${fixture.lifecycleId}-wrong` });
    assert.equal(wrongLifecycleShutdown.ok, false);
    assert.equal(wrongLifecycleShutdown.error_code, "LIFECYCLE_MISMATCH");
    assert.equal(fixture.coordinatorStopRequested, false);

    externalSentinel = spawn(
      process.execPath,
      ["-e", "setInterval(() => {}, 1000)"],
      { cwd: fixture.root, stdio: "ignore", windowsHide: true });
    assert.equal(isProcessAlive(externalSentinel), true);

    const stopped = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "shutdown", expected_lifecycle_id: fixture.lifecycleId });
    assert.equal(stopped.ok, true, stopped.error || "Authenticated final shutdown failed.");
    assert.equal(await waitForSupervisorExit(fixture), true);
    assert.equal(fixture.coordinatorStopRequested, true);
    assert.equal(isProcessAlive(externalSentinel), true, "Supervisor shutdown signalled an unrelated process.");
  } finally {
    await stopTestProcess(externalSentinel);
    await cleanupFixture(fixture);
  }
}

async function verifyAsynchronousMaterializerOperation() {
  const fixture = createFixture(TARGET);
  const counterPath = path.join(fixture.root, "slow-probe-count.txt");
  try {
    writeSlowProbeMaterializer(fixture, counterPath);
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const supervisorState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));

    const admittedAt = Date.now();
    const accepted = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "materialize", action: "Probe", request_id: "slow-probe-1" });
    const admissionMilliseconds = Date.now() - admittedAt;
    assert.equal(accepted.ok, true, accepted.error || "Slow Probe was not admitted.");
    assert.equal(accepted.accepted, true);
    assert.equal(accepted.pending, true);
    assert.ok(
      admissionMilliseconds < 1500,
      `Slow Probe held the IPC request for ${admissionMilliseconds} ms.`);

    const reattached = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "materialize", action: "Probe", request_id: "slow-probe-2" });
    assert.equal(reattached.ok, true);
    assert.equal(reattached.reused, true);
    assert.equal(reattached.operation_id, accepted.operation_id);

    const completed = await waitForOperation(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      accepted.operation_id);
    assert.equal(completed.ok, true, completed.error || "Slow Probe failed.");
    assert.equal(completed.pending, false);
    assert.equal(completed.result.exit_code, 0);
    assert.match(completed.result.stdout, /synthetic slow materializer/);
    assert.equal(fs.readFileSync(counterPath, "utf8"), "1");

    const persisted = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(persisted.operation.operation_id, accepted.operation_id);
    assert.equal(persisted.operation.state, "completed");
    const durableOperation = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "operation.json"),
      "utf8"));
    assert.equal(durableOperation.operation_id, accepted.operation_id);
    assert.equal(durableOperation.state, "completed");

    write(fixture.materializerScript, [
      "param([string]$Action, [string]$ProjectRoot, [string]$PayloadRoot)",
      "Write-Error 'synthetic terminal failure'",
      "exit 4",
      ""
    ].join("\r\n"));
    const failedAdmission = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "materialize", action: "Verify", request_id: "failed-verify" });
    assert.equal(failedAdmission.ok, true);
    assert.equal(failedAdmission.pending, true);
    const failed = await waitForOperation(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      failedAdmission.operation_id);
    assert.equal(failed.ok, false);
    assert.equal(failed.pending, false);
    assert.equal(failed.error_code, "SUPERVISOR_COMMAND_FAILED");
    assert.equal(failed.result.exit_code, 4);
    assert.match(failed.error, /synthetic terminal failure/);
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyOwnerEvidenceAndSingleStarter() {
  const fixture = createFixture(TARGET);
  try {
    await startCoordinator(fixture);
    const [first, second] = await Promise.all([
      runSupervisor(fixture, "start", { RICE_CODEDB_SUPERVISOR_LISTEN_DELAY_MS: "1200" }),
      new Promise((resolve) => setTimeout(
        () => resolve(runSupervisor(fixture, "start")),
        150))
    ]);
    assert.equal(first.status, 0, `${first.stdout}\n${first.stderr}`);
    assert.equal(second.status, 0, `${second.stdout}\n${second.stderr}`);
    assert.match(first.stdout + second.stdout, /STARTED|ATTACHED/);
    const state = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(state.schema_version, 3);
    assert.equal(state.evidence_schema_version, 1);
    assert.equal(state.publication_phase, "listening");
    assert.equal(typeof state.owner_epoch, "string");
    assert.equal(state.owner_evidence.pid, state.supervisor_pid);
    assert.match(state.owner_evidence.process_start_identity, /^\d+$/);
    assert.match(state.owner_evidence.argv_sha256, /^[0-9a-f]{64}$/);
    assert.match(state.owner_evidence.command_line_sha256, /^[0-9a-f]{64}$/);
    assert.equal(
      [first.stdout, second.stdout].filter((output) => output.includes("STARTED")).length,
      1,
      "Concurrent starters must converge on one daemon rather than publish two STARTED owners.");
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyProvenStaleOwnerTakeover() {
  const fixture = createFixture(TARGET);
  try {
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const statePath = path.join(fixture.runtime, "supervisor-state.json");
    const lockPath = path.join(fixture.runtime, "supervisor.lock");
    const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
    try { process.kill(state.supervisor_pid); } catch { /* fixture owner may already have exited */ }
    assert.equal(await waitForCondition(
      () => !isProcessAlive({ pid: state.supervisor_pid, exitCode: null }),
      5000), true);
    const deadPid = 999999;
    state.supervisor_pid = deadPid;
    state.owner_evidence.pid = deadPid;
    fs.writeFileSync(statePath, jsonText(state), "utf8");
    const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));
    lock.supervisor_pid = deadPid;
    lock.owner_evidence.pid = deadPid;
    fs.writeFileSync(lockPath, jsonText(lock), "utf8");

    assert.equal(state.owner_epoch, lock.owner_epoch);
    assert.equal(state.owner_evidence.process_start_identity, lock.owner_evidence.process_start_identity);
    assert.equal(state.owner_evidence.executable_path.toLowerCase(), lock.owner_evidence.executable_path.toLowerCase());
    assert.equal(state.owner_evidence.argv_sha256, lock.owner_evidence.argv_sha256);
    assert.equal(state.owner_evidence.command_line_sha256, lock.owner_evidence.command_line_sha256);
    assert.equal(state.pipe_name, lock.pipe_name);
    assert.equal(state.selected_instance_id, lock.selected_instance_id);
    assert.equal(state.selected_generation_id, lock.selected_generation_id);
    assert.equal(state.runtime_contract_sha256, lock.runtime_contract_sha256);

    const recovered = await runSupervisor(fixture, "start");
    assert.equal(recovered.status, 0, `${recovered.stdout}\n${recovered.stderr}`);
    const current = JSON.parse(fs.readFileSync(statePath, "utf8"));
    assert.notEqual(current.supervisor_pid, deadPid);
    assert.notEqual(current.owner_epoch, state.owner_epoch);
    assert.ok(
      fs.readdirSync(fixture.runtime).some((name) => name.startsWith("supervisor-state.json.stale.")),
      "Stale state must be quarantined instead of deleted in place.");
    assert.ok(
      fs.readdirSync(fixture.runtime).some((name) => name.startsWith("supervisor.lock.stale.")),
      "Stale lock must be quarantined instead of silently removed.");
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyPidReuseIsAmbiguousAndNeverStopped() {
  const fixture = createFixture(TARGET);
  let sentinel = null;
  try {
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const statePath = path.join(fixture.runtime, "supervisor-state.json");
    const lockPath = path.join(fixture.runtime, "supervisor.lock");
    const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
    try { process.kill(state.supervisor_pid); } catch { /* fixture owner may already have exited */ }
    assert.equal(await waitForCondition(
      () => !isProcessAlive({ pid: state.supervisor_pid, exitCode: null }),
      5000), true);
    sentinel = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], {
      cwd: fixture.root,
      stdio: "ignore",
      windowsHide: true
    });
    assert.equal(isProcessAlive(sentinel), true);
    state.supervisor_pid = sentinel.pid;
    state.owner_evidence.pid = sentinel.pid;
    fs.writeFileSync(statePath, jsonText(state), "utf8");
    const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));
    lock.supervisor_pid = sentinel.pid;
    lock.owner_evidence.pid = sentinel.pid;
    fs.writeFileSync(lockPath, jsonText(lock), "utf8");

    const blocked = await runSupervisor(fixture, "start");
    assert.notEqual(blocked.status, 0, `${blocked.stdout}\n${blocked.stderr}`);
    assert.match(blocked.stderr, /live but its start identity|invalid|ambiguous/i);
    assert.equal(isProcessAlive(sentinel), true, "PID-reused unrelated process must remain alive.");
    const unchanged = JSON.parse(fs.readFileSync(statePath, "utf8"));
    assert.equal(unchanged.supervisor_pid, sentinel.pid);

    // An empty Windows process-start identity is not evidence of a stale
    // owner. It must remain invalid/ambiguous and must not permit takeover.
    state.owner_evidence.process_start_identity = "";
    fs.writeFileSync(statePath, jsonText(state), "utf8");
    lock.owner_evidence.process_start_identity = "";
    fs.writeFileSync(lockPath, jsonText(lock), "utf8");
    const emptyIdentity = await runSupervisor(fixture, "status");
    assert.notEqual(emptyIdentity.status, 0);
    assert.match(emptyIdentity.stderr, /invalid|ambiguous|identity/i);
    assert.equal(isProcessAlive(sentinel), true, "Invalid empty process identity must not stop the sentinel.");
  } finally {
    await stopTestProcess(sentinel);
    await cleanupFixture(fixture);
  }
}

async function verifyOperationReattachesAfterSupervisorLoss() {
  const fixture = createFixture(TARGET);
  try {
    const counterPath = path.join(fixture.root, "crash-recovery-probe-count.txt");
    writeSlowProbeMaterializer(fixture, counterPath);
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const statePath = path.join(fixture.runtime, "supervisor-state.json");
    const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
    const accepted = await requestPipe(
      state.pipe_name,
      state.auth_token,
      { command: "materialize", action: "Probe", request_id: "crash-recovery-1" });
    assert.equal(accepted.pending, true);
    const operationPath = path.join(fixture.runtime, "operation.json");
    assert.equal(await waitForPath(operationPath), true);
    assert.equal(await waitForCondition(() => {
      try { return JSON.parse(fs.readFileSync(operationPath, "utf8")).child?.pid > 0; }
      catch { return false; }
    }), true, fs.readFileSync(operationPath, "utf8"));
    try { process.kill(state.supervisor_pid); } catch { /* fixture owner may already have exited */ }
    assert.equal(await waitForCondition(() => !isProcessAlive({ pid: state.supervisor_pid, exitCode: null }), 5000), true);

    const restarted = await runSupervisor(fixture, "start");
    assert.equal(restarted.status, 0, `${restarted.stdout}\n${restarted.stderr}`);
    const current = JSON.parse(fs.readFileSync(statePath, "utf8"));
    const completed = await waitForOperation(current.pipe_name, current.auth_token, accepted.operation_id, 15000);
    assert.equal(completed.operation_id, accepted.operation_id);
    assert.equal(completed.pending, false);
    assert.equal(fs.readFileSync(counterPath, "utf8"), "1", "Recovery must not launch a second materializer child.");
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyMissingChildEvidenceBlocksBlindRetry() {
  const fixture = createFixture(TARGET);
  try {
    const counterPath = path.join(fixture.root, "missing-child-retry-count.txt");
    writeSlowProbeMaterializer(fixture, counterPath);
    const operationId = crypto.randomUUID().replaceAll("-", "");
    json(path.join(fixture.runtime, "operation.json"), {
      schema_version: 1,
      managed_by: "com.rice.ai-codedb",
      operation_id: operationId,
      key: JSON.stringify(["materialize:Probe", "Probe", false, "", false, false, "", 0, ""]),
      request_id: "crash-before-child-evidence",
      name: "materialize:Probe",
      lane: "maintenance",
      state: "running",
      phase: "admitted",
      owner_epoch: crypto.randomUUID().replaceAll("-", ""),
      project_identity: projectIdentity(fixture.root),
      root: fixture.root,
      runtime: fixture.runtime,
      selected_instance_id: fixture.instanceId,
      selected_generation_id: TARGET.generationId,
      runtime_contract_sha256: fixture.contractSha256,
      child: null,
      started_at_utc: new Date().toISOString()
    });

    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const state = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    const terminal = await waitForOperation(
      state.pipe_name,
      state.auth_token,
      operationId);
    assert.equal(terminal.pending, false);
    assert.equal(terminal.ok, false);
    assert.match(terminal.error, /before its child identity was durably recorded/i);
    assert.equal(
      fs.existsSync(counterPath),
      false,
      "A recovered operation without child identity must never launch a replacement materializer.");
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyCoordinatorOfflineRetirement() {
  const fixture = createFixture(TARGET);
  try {
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    await stopFixtureCoordinator(fixture);
    fs.rmSync(fixture.coordinatorStatePath, { force: true });

    assert.equal(
      await waitForSupervisorExit(fixture, 12000),
      true,
      "A Supervisor whose previously healthy coordinator is gone must retire without another Unity callback.");
    assert.equal(fixture.coordinatorStopRequested, false);
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyActivationHandoff() {
  const fixture = createFixture(PREVIOUS);
  try {
    const target = installAdditionalFixtureInstance(fixture, TARGET);
    writeUpgradeMaterializer(fixture, target.stagedSelectionPath);
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const previousState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(previousState.generation_disposition, "TRUSTED_PREVIOUS");

    const accepted = await requestPipe(
      previousState.pipe_name,
      previousState.auth_token,
      { command: "materialize", action: "Upgrade" });
    assert.equal(accepted.ok, true, accepted.error || "Upgrade was not admitted.");
    assert.equal(accepted.accepted, true);
    assert.equal(accepted.pending, true);
    const upgraded = await waitForOperation(
      previousState.pipe_name,
      previousState.auth_token,
      accepted.operation_id);
    assert.equal(upgraded.ok, true, upgraded.error || "Upgrade failed.");
    assert.equal(upgraded.pending, false);
    assert.equal(upgraded.handoff_queued, true);
    assert.equal(upgraded.handoff_reason, "selected_instance_changed");
    assert.equal(await waitForSupervisorExit(fixture), true);
    assert.equal(fixture.coordinatorStopRequested, true);

    const selection = JSON.parse(fs.readFileSync(fixture.selectionPath, "utf8"));
    assert.equal(selection.instance_id, target.instanceId);
    assert.equal(selection.generation_id, TARGET.generationId);

    fixture.instanceId = target.instanceId;
    fixture.instanceRoot = target.instanceRoot;
    fixture.projectGenerationRoot = target.projectGenerationRoot;
    fixture.coordinatorRuntime = target.coordinatorRuntime;
    fixture.coordinatorStatePath = target.coordinatorStatePath;
    fixture.coordinatorScript = target.coordinatorScript;
    fixture.watchManager = target.watchManager;
    fixture.selected = TARGET;
    write(fixture.stableWrapperPath, TARGET_STABLE_WRAPPER_CONTENT);
    fixture.coordinatorStopRequested = false;

    const restarted = await runSupervisor(fixture, "start");
    assert.equal(restarted.status, 0, `${restarted.stdout}\n${restarted.stderr}`);
    const currentState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(currentState.selected_generation_id, TARGET.generationId);
    assert.equal(currentState.selected_instance_id, target.instanceId);
    assert.equal(currentState.generation_disposition, "CURRENT");
    assert.equal(currentState.pipe_name, expectedSupervisorPipe(fixture.root, fixture.runtime));
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifySyntheticContractTargetBump() {
  const fixture = createFixture(TARGET);
  const target = installAdditionalFixtureInstance(fixture, SYNTHETIC_BUMP_TARGET);
  try {
    rewriteContractForSyntheticTarget(fixture, SYNTHETIC_BUMP_TARGET, TARGET);
    writeUpgradeMaterializer(fixture, target.stagedSelectionPath);
    await startCoordinator(fixture);

    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const previousState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(previousState.target_generation_id, SYNTHETIC_BUMP_TARGET.generationId);
    assert.equal(previousState.selected_generation_id, TARGET.generationId);
    assert.equal(previousState.generation_disposition, "TRUSTED_PREVIOUS");

    const accepted = await requestPipe(
      previousState.pipe_name,
      previousState.auth_token,
      { command: "materialize", action: "Upgrade" });
    assert.equal(accepted.ok, true, accepted.error || "Synthetic target upgrade was not admitted.");
    const upgraded = await waitForOperation(
      previousState.pipe_name,
      previousState.auth_token,
      accepted.operation_id);
    assert.equal(upgraded.ok, true, upgraded.error || "Synthetic target upgrade failed.");
    assert.equal(upgraded.handoff_queued, true);
    assert.equal(await waitForSupervisorExit(fixture, 15000), true);

    const selection = JSON.parse(fs.readFileSync(fixture.selectionPath, "utf8"));
    assert.equal(selection.instance_id, target.instanceId);
    assert.equal(selection.generation_id, SYNTHETIC_BUMP_TARGET.generationId);
    assert.equal(
      hashFile(fixture.stableWrapperPath),
      TARGET_STABLE_WRAPPER_SHA256,
      "Synthetic target activation must route through the Package-owned stable wrapper.");

    fixture.instanceId = target.instanceId;
    fixture.instanceRoot = target.instanceRoot;
    fixture.projectGenerationRoot = target.projectGenerationRoot;
    fixture.coordinatorRuntime = target.coordinatorRuntime;
    fixture.coordinatorStatePath = target.coordinatorStatePath;
    fixture.coordinatorScript = target.coordinatorScript;
    fixture.watchManager = target.watchManager;
    fixture.selected = SYNTHETIC_BUMP_TARGET;
    fixture.coordinatorStopRequested = false;

    const restarted = await runSupervisor(fixture, "start");
    assert.equal(restarted.status, 0, `${restarted.stdout}\n${restarted.stderr}`);
    const currentState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    assert.equal(currentState.target_generation_id, SYNTHETIC_BUMP_TARGET.generationId);
    assert.equal(currentState.selected_generation_id, SYNTHETIC_BUMP_TARGET.generationId);
    assert.equal(currentState.generation_disposition, "CURRENT");
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyRejected(label, selected, mutate, expectedError) {
  const fixture = createFixture(selected);
  try {
    mutate(fixture);
    const result = await runSupervisor(fixture, "status");
    assert.notEqual(result.status, 0, `${label} unexpectedly passed.\n${result.stdout}`);
    assert.match(result.stderr, expectedError, `${label} returned an unexpected error.`);
    assert.equal(
      fs.existsSync(fixture.runtime),
      false,
      `${label} wrote Supervisor runtime evidence before validation completed.`);
  } finally {
    await cleanupFixture(fixture);
  }
}

async function main() {
  assert.equal(
    expectedSupervisorPipe(
      ["G:", "RiceProgram", "Test", "Test"].join("\\"),
      ["G:", "RiceProgram", "Test", "Test", ...CONTROL_NAMESPACE_RELATIVE_PATH.split("/")].join("\\")),
    "\\\\.\\pipe\\codedb-supervisor-8ef262de0ef456d71b2b");
  await verifyHappyPath(TARGET, "CURRENT");
  await verifyHappyPath(PREVIOUS, "TRUSTED_PREVIOUS");
  await verifyStableDefaultIdentity();
  await verifyLegacyAndMismatchedRuntimeRejectedWithoutMutation();
  await verifyOwnerEvidenceAndSingleStarter();
  await verifyProvenStaleOwnerTakeover();
  await verifyPidReuseIsAmbiguousAndNeverStopped();
  await verifyAsynchronousMaterializerOperation();
  await verifyOperationReattachesAfterSupervisorLoss();
  await verifyMissingChildEvidenceBlocksBlindRetry();
  await verifyCoordinatorOfflineRetirement();
  await verifyActivationHandoff();
  await verifySyntheticContractTargetBump();

  await verifyRejected("duplicate runtime-contract key", TARGET, (fixture) => {
    const source = fs.readFileSync(fixture.contractPath, "utf8");
    fs.writeFileSync(
      fixture.contractPath,
      source.replace(
        '"generation_id": "poc.34",',
        '"generation_id": "poc.34",\n  "generation_id": "poc.34",'),
      "utf8");
  }, /duplicate|case-ambiguous/i);

  await verifyRejected("tampered selected file", TARGET, (fixture) => {
    fs.appendFileSync(fixture.workerPath, "// tampered\n", "utf8");
  }, /hash|bytes|closure|drifted/i);

  await verifyRejected("wrong current stable wrapper", TARGET, (fixture) => {
    write(fixture.stableWrapperPath, PREVIOUS_STABLE_WRAPPER_CONTENT);
  }, /stable wrapper|runtime identity|hash|bytes/i);

  await verifyRejected("wrong previous stable wrapper", PREVIOUS, (fixture) => {
    write(fixture.stableWrapperPath, TARGET_STABLE_WRAPPER_CONTENT);
  }, /stable wrapper|runtime identity|hash|bytes/i);

  await verifyRejected("missing stable wrapper", TARGET, (fixture) => {
    fs.rmSync(fixture.stableWrapperPath, { force: true });
  }, /stable wrapper|missing|file/i);

  await verifyRejected("Package stable wrapper drift", TARGET, (fixture) => {
    write(fixture.packageWrapperPath, "// drifted Package wrapper\n");
  }, /stable wrapper|identity|hash|bytes/i);

  await verifyRejected("extra selected file", TARGET, (fixture) => {
    write(path.join(fixture.projectGenerationRoot, "extra.txt"), "extra\n");
  }, /undeclared filesystem entry/i);

  await verifyRejected("extra selected empty directory", TARGET, (fixture) => {
    mkdir(path.join(fixture.projectGenerationRoot, "empty-extra"));
  }, /undeclared (?:filesystem entry|directory)/i);

  await verifyRejected("selected path escape", TARGET, (fixture) => {
    const selection = JSON.parse(fs.readFileSync(fixture.selectionPath, "utf8"));
    selection.instance_relative_path = "AIWork/.runtime/codedb/instances/../escaped";
    json(fixture.selectionPath, selection);
  }, /identity is invalid|path/i);

  await verifyRejected("selected generation junction", TARGET, (fixture) => {
    const target = path.join(fixture.root, "junction-target");
    mkdir(target);
    fs.symlinkSync(target, path.join(fixture.projectGenerationRoot, "redirected"), "junction");
  }, /undeclared filesystem entry|symbolic link|junction|redirected/i);

  await verifyRejected("newer selected generation", {
    ...TARGET,
    packageVersion: "future-package",
    payloadVersion: "poc.35",
    payloadSequence: 35,
    generationId: "poc.35"
  }, () => {}, /NEWER/);

  await verifyRejected("same-sequence collision", {
    ...TARGET,
    payloadVersion: "collision",
    generationId: "poc.34-collision"
  }, () => {}, /SEQUENCE_COLLISION/);

  await verifyRejected("undeclared previous generation", {
    ...TARGET,
    payloadVersion: "poc.31",
    payloadSequence: 31,
    generationId: "poc.31"
  }, () => {}, /INVALID/);

  const callerPathOverride = createFixture(TARGET);
  try {
    const mismatched = await runSupervisor(
      callerPathOverride,
      "status",
      {},
      true,
      ["--payload-root", path.join(callerPathOverride.root, "caller-selected-payload")]);
    assert.notEqual(mismatched.status, 0);
    assert.match(mismatched.stderr, /Package-derived runtime path|payload root/i);
  } finally {
    await cleanupFixture(callerPathOverride);
  }

  const forged = createFixture(TARGET);
  try {
    await startCoordinator(forged);
    json(path.join(forged.runtime, "supervisor-state.json"), {
      schema_version: 2,
      protocol_version: 1,
      role: "project-local-supervisor",
      managed_by: "com.rice.ai-codedb",
      root: forged.root,
      project_identity: projectIdentity(forged.root),
      runtime: forged.runtime,
      pipe_name: "\\\\.\\pipe\\codedb-forged-supervisor",
      generation_id: TARGET.generationId,
      target_generation_id: TARGET.generationId,
      selected_generation_id: TARGET.generationId,
      runtime_contract_sha256: forged.contractSha256,
      supervisor_protocol_version: 1,
      generation_disposition: "CURRENT",
      lifecycle_id: forged.lifecycleId,
      auth_token: crypto.randomBytes(24).toString("hex")
    });
    const forgedStop = await runSupervisor(forged, "stop");
    assert.notEqual(forgedStop.status, 0);
    assert.equal(forged.coordinatorStopRequested, false);
  } finally {
    await cleanupFixture(forged);
  }

  console.log("[PASS] Supervisor Package-root routing, runtime contract, asynchronous operation polling, single-flight reuse, terminal failure, reconnect continuity, authenticated shutdown, offline retirement, activation handoff, strict evidence, and immutable closure boundaries.");
}

await main();
