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
    ["scripts/refresh-codedb-project-if-stale.ps1", "Write-Output '[PASS] synthetic RefreshIfStale'\r\nexit 0\r\n"],
    ["scripts/refresh-codedb-project.ps1", [
      "param([switch]$CleanFirst)",
      "if ($CleanFirst) { Write-Output '[PASS] synthetic RebuildIndex' } else { Write-Output '[PASS] synthetic RefreshIndex' }",
      "exit 0",
      ""
    ].join("\r\n")],
    ["scripts/build-codedb-project-text-adapter.ps1", "Write-Output '[PASS] synthetic BuildShaderAdapter'\r\nexit 0\r\n"],
    ["scripts/clear-codedb-project-index.ps1", "Write-Output '[PASS] synthetic CleanIndex'\r\nexit 0\r\n"],
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
    coordinatorStopRequested: false,
    coordinatorReadyPath: null,
    coordinatorStatusRequests: 0
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

function writeQueuedMaintenanceMaterializer(fixture, actionLogPath) {
  const quote = (value) => String(value).replace(/'/g, "''");
  write(fixture.materializerScript, [
    "param([string]$Action, [string]$ProjectRoot, [string]$PayloadRoot)",
    `  [IO.File]::AppendAllText('${quote(actionLogPath)}', $Action + [Environment]::NewLine)`,
    "if ($Action -eq 'Probe') { Start-Sleep -Milliseconds 2400 }",
    "Write-Output ('[PASS] synthetic queued materializer ' + $Action)",
    "exit 0",
    ""
  ].join("\r\n"));
}

function writeRecoveredOperationMaterializer(fixture, probeCounterPath, verifyCounterPath, verifySucceeds) {
  const quote = (value) => String(value).replace(/'/g, "''");
  write(fixture.materializerScript, [
    "param([string]$Action, [string]$ProjectRoot, [string]$PayloadRoot)",
    "if ($Action -eq 'Probe') {",
    `  [IO.File]::WriteAllText('${quote(probeCounterPath)}', 'unexpected')`,
    "  Write-Error 'Recovered operation launched a replacement Probe.'",
    "  exit 9",
    "}",
    "if ($Action -eq 'Verify') {",
    `  $counterPath = '${quote(verifyCounterPath)}'`,
    "  $count = if (Test-Path -LiteralPath $counterPath) { [int][IO.File]::ReadAllText($counterPath) } else { 0 }",
    "  [IO.File]::WriteAllText($counterPath, [string]($count + 1))",
    verifySucceeds
      ? "  Write-Output '[PASS] synthetic recovered operation verification'"
      : "  Write-Error 'synthetic recovered operation verification rejection'",
    `  exit ${verifySucceeds ? 0 : 7}`,
    "}",
    "Write-Error 'Unexpected recovered operation action.'",
    "exit 8",
    ""
  ].join("\r\n"));
}

function writeCoordinatorReadmissionFixture(fixture, startCounterPath, materializerCounterPath, failureGatePath) {
  const quote = (value) => String(value).replace(/'/g, "''");
  const scriptQuote = (value) => JSON.stringify(String(value));
  const coordinatorScriptContent = [
    "import fs from 'node:fs';",
    `const counterPath = ${scriptQuote(startCounterPath)};`,
    `const readyPath = ${scriptQuote(fixture.coordinatorReadyPath)};`,
    `const failureGatePath = ${scriptQuote(failureGatePath)};`,
    "const count = fs.existsSync(counterPath) ? Number(fs.readFileSync(counterPath, 'utf8')) : 0;",
    "fs.writeFileSync(counterPath, String(count + 1), 'utf8');",
    "if (fs.existsSync(failureGatePath)) {",
    "  fs.rmSync(failureGatePath, { force: true });",
    "  process.stderr.write('synthetic coordinator start failure');",
    "  process.exit(4);",
    "}",
    "fs.writeFileSync(readyPath, 'ready', 'utf8');",
    "process.stdout.write('[PASS] synthetic coordinator start\\n');",
    ""
  ].join("\r\n");
  write(fixture.coordinatorScript, coordinatorScriptContent);
  write(
    path.join(fixture.packageGenerationRoot, "coordinator", "codedb-watch-coordinator.mjs"),
    coordinatorScriptContent);
  for (const generationRoot of [fixture.packageGenerationRoot, fixture.projectGenerationRoot]) {
    const manifestPath = path.join(generationRoot, "generation-manifest.json");
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    const entry = manifest.files.find((value) => value.path === "coordinator/codedb-watch-coordinator.mjs");
    assert.ok(entry, "Synthetic coordinator manifest entry is missing.");
    entry.sha256 = hashFile(path.join(generationRoot, "coordinator", "codedb-watch-coordinator.mjs"));
    json(manifestPath, manifest);
  }
  const projectGenerationManifestPath = path.join(
    fixture.projectGenerationRoot,
    "generation-manifest.json");
  const instanceManifestPath = path.join(fixture.instanceRoot, "instance.json");
  const instanceManifest = JSON.parse(fs.readFileSync(instanceManifestPath, "utf8"));
  instanceManifest.generation_manifest_sha256 = hashFile(projectGenerationManifestPath);
  json(instanceManifestPath, instanceManifest);
  const selection = JSON.parse(fs.readFileSync(fixture.selectionPath, "utf8"));
  selection.instance_manifest_sha256 = hashFile(instanceManifestPath);
  json(fixture.selectionPath, selection);
  write(fixture.materializerScript, [
    "param([string]$Action, [string]$ProjectRoot, [string]$PayloadRoot)",
    `if ($Action -eq 'Probe' -or $Action -eq 'Upgrade') {`,
    "  if ([string]::IsNullOrWhiteSpace($env:RICE_CODEDB_SUPERVISOR_OPERATIONAL_READINESS)) {",
    "    Write-Error 'synthetic materializer received no Supervisor operational observation'",
    "    exit 10",
    "  }",
    "  $operational = $env:RICE_CODEDB_SUPERVISOR_OPERATIONAL_READINESS | ConvertFrom-Json",
    "  if ($operational.schema_version -ne 1 -or $operational.state -cne 'core_ready' -or $operational.coordinator_failure_category -cne 'NONE') {",
    "    Write-Error 'synthetic materializer received an invalid operational observation'",
    "    exit 11",
    "  }",
    `  if (-not (Test-Path -LiteralPath '${quote(fixture.coordinatorReadyPath)}')) {`,
    "    Write-Error 'synthetic coordinator was not ensured before materializer'",
    "    exit 9",
    "  }",
    `  $counterPath = '${quote(materializerCounterPath)}'`,
    "  $count = if (Test-Path -LiteralPath $counterPath) { [int][IO.File]::ReadAllText($counterPath) } else { 0 }",
    "  [IO.File]::WriteAllText($counterPath, [string]($count + 1))",
    "  Write-Output ('[OPERATIONAL_OBSERVATION] ' + ($operational | ConvertTo-Json -Depth 4 -Compress))",
    "}",
    "Write-Output '[PASS] synthetic readmission materializer'",
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
      if (request.command === "status") {
        fixture.coordinatorStatusRequests += 1;
        if (fixture.coordinatorReadyPath) {
          status.provider_state = fs.existsSync(fixture.coordinatorReadyPath) ? "ready" : "starting";
        }
      }
      if (request.command === "query" && fixture.coordinatorRequestLogPath) {
        fs.appendFileSync(fixture.coordinatorRequestLogPath, "query\n", "utf8");
      }
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
    assert.equal(supervisorState.supervisor_protocol_version, 3);
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
    assert.equal(status.status.operational_readiness.schema_version, 1);
    assert.equal(status.status.operational_readiness.state, "core_ready");
    assert.equal(status.status.operational_readiness.reason_code, "COORDINATOR_OPERATIONAL");
    assert.equal(status.status.operational_readiness.coordinator_failure_category, "NONE");
    assert.equal(status.status.operational_readiness.owner_epoch, supervisorState.owner_epoch);
    assert.equal(status.status.operational_readiness.supervisor_pid, supervisorState.supervisor_pid);
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

async function verifyQueryFirstBoundedMaintenanceQueue() {
  const fixture = createFixture(TARGET);
  const orderPath = path.join(fixture.root, "request-queue-order.txt");
  try {
    writeQueuedMaintenanceMaterializer(fixture, orderPath);
    await startCoordinator(fixture);
    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const supervisorState = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "supervisor-state.json"),
      "utf8"));
    fixture.coordinatorRequestLogPath = orderPath;

    const active = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "materialize", action: "Probe", request_id: "queue-active-probe" });
    assert.equal(active.ok, true, active.error || "Probe was not accepted by the Supervisor queue.");
    assert.equal(active.pending, true);
    assert.equal(await waitForCondition(() =>
      fs.existsSync(orderPath) && fs.readFileSync(orderPath, "utf8").includes("Probe")), true);

    const queued = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "materialize", action: "Verify", request_id: "queue-pending-verify-1" });
    assert.equal(queued.ok, true, queued.error || "Verify was not queued behind the active Probe.");
    assert.equal(queued.pending, true);
    assert.equal(queued.operation.state, "queued");
    assert.equal(queued.operation.owner_epoch, supervisorState.owner_epoch);
    assert.notEqual(queued.operation_id, active.operation_id);

    const duplicate = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "materialize", action: "Verify", request_id: "queue-pending-verify-2" });
    assert.equal(duplicate.ok, true);
    assert.equal(duplicate.reused, true);
    assert.equal(duplicate.operation_id, queued.operation_id);

    const overflow = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "reconcile", request_id: "queue-overflow-reconcile" });
    assert.equal(overflow.ok, false);
    assert.equal(overflow.accepted, false);
    assert.equal(overflow.error_code, "SUPERVISOR_QUEUE_FULL");

    const queriedAt = Date.now();
    const query = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "query", query: "queue-priority", request_id: "queue-priority-query" });
    assert.equal(query.ok, true, query.error || "Query was not served while maintenance was pending.");
    assert.deepEqual(query.result.hits, ["query-served"]);
    assert.ok(Date.now() - queriedAt < 1500, "Query waited for queued maintenance admission.");

    const queuedObservation = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "operation", operation_id: queued.operation_id });
    assert.equal(queuedObservation.pending, true);
    assert.equal(queuedObservation.operation.state, "queued");

    const activeResult = await waitForOperation(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      active.operation_id,
      15000);
    assert.equal(activeResult.ok, true, activeResult.error || "Active Probe failed.");
    const queuedResult = await waitForOperation(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      queued.operation_id,
      15000);
    assert.equal(queuedResult.ok, true, queuedResult.error || "Queued Verify failed.");

    const order = fs.readFileSync(orderPath, "utf8").trim().split(/\r?\n/);
    assert.deepEqual(
      order,
      ["Probe", "query", "Verify"],
      "Query did not run before the pending maintenance operation or queued work ran more than once.");

    const rejected = await requestPipe(
      supervisorState.pipe_name,
      supervisorState.auth_token,
      { command: "maintenance", action: "CallerProvidedScript", request_id: "maintenance-unsupported" });
    assert.equal(rejected.ok, false);
    assert.equal(rejected.error_code, "INVALID_ARGUMENT");

    for (const action of [
      "RefreshIfStale",
      "RefreshIndex",
      "BuildShaderAdapter",
      "CleanIndex",
      "RebuildIndex"
    ]) {
      const admitted = await requestPipe(
        supervisorState.pipe_name,
        supervisorState.auth_token,
        { command: "maintenance", action, request_id: `maintenance-${action}` });
      assert.equal(admitted.ok, true, admitted.error || `${action} was not admitted.`);
      assert.equal(admitted.pending, true);
      assert.equal(admitted.operation.name, `maintenance:${action}`);
      assert.equal(admitted.operation.lane, "maintenance");
      const completed = await waitForOperation(
        supervisorState.pipe_name,
        supervisorState.auth_token,
        admitted.operation_id);
      assert.equal(completed.ok, true, completed.error || `${action} failed.`);
      assert.match(completed.result.stdout, new RegExp(`synthetic ${action}`));
    }
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

async function verifyRecordedChildAlreadyAbsentFailsClosed() {
  const fixture = createFixture(TARGET);
  try {
    const counterPath = path.join(fixture.root, "absent-recorded-child-retry-count.txt");
    const verifyCounterPath = path.join(fixture.root, "absent-recorded-child-verify-count.txt");
    const operationId = crypto.randomUUID().replaceAll("-", "");
    const absentPid = 2147483647;
    assert.equal(
      isProcessAlive({ pid: absentPid, exitCode: null }),
      false,
      "The reserved fixture PID must be absent before recovery starts.");
    writeRecoveredOperationMaterializer(fixture, counterPath, verifyCounterPath, false);
    json(path.join(fixture.runtime, "operation.json"), {
      schema_version: 1,
      managed_by: "com.rice.ai-codedb",
      operation_id: operationId,
      key: JSON.stringify(["materialize:Probe", "Probe", false, "", false, false, "", 0, ""]),
      request_id: "recorded-child-already-absent",
      name: "materialize:Probe",
      lane: "maintenance",
      state: "running",
      phase: "child_running",
      owner_epoch: crypto.randomUUID().replaceAll("-", ""),
      project_identity: projectIdentity(fixture.root),
      root: fixture.root,
      runtime: fixture.runtime,
      selected_instance_id: fixture.instanceId,
      selected_generation_id: TARGET.generationId,
      runtime_contract_sha256: fixture.contractSha256,
      child: {
        schema_version: 1,
        pid: absentPid,
        process_start_identity: "1",
        executable_path: path.resolve(process.execPath),
        argv_sha256: "a".repeat(64),
        command_line_sha256: "b".repeat(64),
        command: process.execPath,
        normalized_argv: ["synthetic-absent-child"]
      },
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
    assert.match(
      terminal.error,
      /could not be verified/i);
    assert.equal(
      fs.existsSync(counterPath),
      false,
      "An absent recorded child must never launch a replacement materializer.");
    assert.equal(fs.readFileSync(verifyCounterPath, "utf8"), "1");
    assert.ok(
      fixture.coordinatorStatusRequests > 0,
      "Coordinator status must be established before persisted operation recovery.");
    const durable = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "operation.json"),
      "utf8"));
    assert.equal(durable.operation_id, operationId);
    assert.equal(durable.state, "failed");
    assert.match(
      durable.error,
      /could not be verified/i);
  } finally {
    await cleanupFixture(fixture);
  }
}

async function verifyRecordedChildAlreadyAbsentUsesAuthoritativeVerifier() {
  const fixture = createFixture(TARGET);
  try {
    const probeCounterPath = path.join(fixture.root, "verified-absent-child-probe-count.txt");
    const verifyCounterPath = path.join(fixture.root, "verified-absent-child-verify-count.txt");
    const operationId = crypto.randomUUID().replaceAll("-", "");
    const absentPid = 2147483647;
    assert.equal(
      isProcessAlive({ pid: absentPid, exitCode: null }),
      false,
      "The reserved fixture PID must be absent before recovery starts.");
    writeRecoveredOperationMaterializer(fixture, probeCounterPath, verifyCounterPath, true);
    json(path.join(fixture.runtime, "operation.json"), {
      schema_version: 1,
      managed_by: "com.rice.ai-codedb",
      operation_id: operationId,
      key: JSON.stringify(["materialize:Probe", "Probe", false, "", false, false, "", 0, ""]),
      request_id: "recorded-child-verified-after-exit",
      name: "materialize:Probe",
      lane: "maintenance",
      state: "running",
      phase: "child_running",
      owner_epoch: crypto.randomUUID().replaceAll("-", ""),
      project_identity: projectIdentity(fixture.root),
      root: fixture.root,
      runtime: fixture.runtime,
      selected_instance_id: fixture.instanceId,
      selected_generation_id: TARGET.generationId,
      runtime_contract_sha256: fixture.contractSha256,
      child: {
        schema_version: 1,
        pid: absentPid,
        process_start_identity: "1",
        executable_path: path.resolve(process.execPath),
        argv_sha256: "a".repeat(64),
        command_line_sha256: "b".repeat(64),
        command: process.execPath,
        normalized_argv: ["synthetic-verified-absent-child"]
      },
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
    assert.equal(terminal.ok, true, terminal.error || "Recovered operation verification failed.");
    assert.equal(fs.existsSync(probeCounterPath), false);
    assert.equal(fs.readFileSync(verifyCounterPath, "utf8"), "1");
    assert.ok(
      fixture.coordinatorStatusRequests > 0,
      "Coordinator status must be established before persisted operation recovery.");
    const durable = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "operation.json"),
      "utf8"));
    assert.equal(durable.operation_id, operationId);
    assert.equal(durable.state, "completed");
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

async function verifyCoordinatorReadmissionBeforeMaterializer() {
  const fixture = createFixture(TARGET);
  const startCounterPath = path.join(fixture.root, "coordinator-start-count.txt");
  const materializerCounterPath = path.join(fixture.root, "readmission-materializer-count.txt");
  const failureGatePath = path.join(fixture.root, "coordinator-failure-gate.txt");
  const initialSupervisorPid = { value: 0 };
  try {
    fixture.coordinatorReadyPath = path.join(fixture.root, "coordinator-ready.marker");
    write(failureGatePath, "fail-first\n");
    writeCoordinatorReadmissionFixture(
      fixture,
      startCounterPath,
      materializerCounterPath,
      failureGatePath);
    await startCoordinator(fixture);
    const coordinatorOwner = fixture.coordinatorServer;

    const started = await runSupervisor(fixture, "start");
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    const statePath = path.join(fixture.runtime, "supervisor-state.json");
    assert.equal(await waitForPath(statePath), true);
    assert.equal(await waitForCondition(() => {
      try {
        return JSON.parse(fs.readFileSync(statePath, "utf8")).coordinator_failure_category === "NONZERO_EXIT";
      } catch {
        return false;
      }
    }, 5000), true, "The startup failure category was not published.");
    const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
    initialSupervisorPid.value = state.supervisor_pid;
    assert.equal(isProcessAlive({ pid: state.supervisor_pid, exitCode: null }), true);
    assert.equal(fs.readFileSync(startCounterPath, "utf8"), "1");
    assert.equal(fs.existsSync(fixture.coordinatorReadyPath), false);
    assert.equal(state.coordinator_failure_category, "NONZERO_EXIT");
    assert.equal(state.operational_readiness.schema_version, 1);
    assert.equal(state.operational_readiness.state, "degraded");
    assert.equal(state.operational_readiness.reason_code, "COORDINATOR_START_FAILED");
    assert.equal(state.operational_readiness.coordinator_failure_category, "NONZERO_EXIT");
    const failedStatus = await requestPipe(
      state.pipe_name,
      state.auth_token,
      { command: "status" });
    assert.equal(failedStatus.status.provider_state, "starting");
    assert.equal(failedStatus.status.operational_readiness.state, "degraded");
    assert.equal(failedStatus.status.operational_readiness.reason_code, "COORDINATOR_START_FAILED");
    assert.equal(state.last_event, "coordinator_start_failed");
    assert.equal(state.last_event_detail, "NONZERO_EXIT");
    assert.doesNotMatch(
      JSON.stringify({
        coordinator_failure_category: state.coordinator_failure_category,
        last_event: state.last_event,
        last_event_detail: state.last_event_detail
      }),
      /synthetic coordinator start failure/);

    const probe = await requestPipe(
      state.pipe_name,
      state.auth_token,
      { command: "materialize", action: "Probe", request_id: "coordinator-readmission-probe" });
    assert.equal(probe.pending, true);
    const probeResult = await waitForOperation(state.pipe_name, state.auth_token, probe.operation_id);
    assert.equal(probeResult.ok, true, probeResult.error || "Probe re-admission failed.");
    assert.equal(probeResult.status.coordinator_failure_category, "NONE");
    assert.equal(probeResult.status.provider_state, "ready");
    assert.equal(probeResult.status.operational_readiness.state, "core_ready");
    assert.equal(probeResult.status.operational_readiness.reason_code, "COORDINATOR_OPERATIONAL");
    assert.equal(probeResult.status.operational_readiness.coordinator_failure_category, "NONE");
    const probeObservationLine = probeResult.result.stdout
      .split(/\r?\n/)
      .find((line) => line.startsWith("[OPERATIONAL_OBSERVATION] "));
    assert.ok(probeObservationLine, "Probe did not receive the Supervisor observation.");
    const probeObservation = JSON.parse(
      probeObservationLine.slice("[OPERATIONAL_OBSERVATION] ".length));
    assert.equal(
      probeResult.status.operational_readiness.observation_id,
      probeObservation.observation_id,
      "The terminal command status must identify the observation passed to PowerShell.");
    assert.equal(
      probeResult.status.operational_readiness.revision,
      probeObservation.revision,
      "The terminal command status must retain the PowerShell observation revision.");
    assert.equal(fs.readFileSync(startCounterPath, "utf8"), "2");
    assert.equal(fs.readFileSync(materializerCounterPath, "utf8"), "1");
    assert.equal(fs.existsSync(fixture.coordinatorReadyPath), true);
    assert.equal(fixture.coordinatorServer, coordinatorOwner);
    const durableProbe = JSON.parse(fs.readFileSync(
      path.join(fixture.runtime, "operation.json"),
      "utf8"));
    const probeActionIndex = durableProbe.child.normalized_argv.indexOf("-Action");
    assert.equal(probeActionIndex >= 0, true);
    assert.equal(durableProbe.child.normalized_argv[probeActionIndex + 1], "Probe");

    fs.rmSync(fixture.coordinatorReadyPath, { force: true });
    assert.equal(await waitForCondition(() => {
      try {
        const current = JSON.parse(fs.readFileSync(statePath, "utf8"));
        return current.coordinator_failure_category === "NONE"
          && current.operational_readiness.state === "starting"
          && current.operational_readiness.reason_code === "COORDINATOR_STARTING"
          && current.operational_readiness.coordinator_failure_category === "NONE";
      } catch {
        return false;
      }
    }, 5000), true, "A neutral startup category with a non-ready Coordinator must remain starting.");
    const neutralStartingStatus = await requestPipe(
      state.pipe_name,
      state.auth_token,
      { command: "status" });
    assert.equal(neutralStartingStatus.status.provider_state, "starting");
    assert.equal(neutralStartingStatus.status.coordinator_failure_category, "NONE");
    assert.equal(neutralStartingStatus.status.operational_readiness.state, "starting");
    const upgrade = await requestPipe(
      state.pipe_name,
      state.auth_token,
      { command: "materialize", action: "Upgrade", request_id: "coordinator-readmission-upgrade" });
    assert.equal(upgrade.pending, true);
    const upgradeResult = await waitForOperation(state.pipe_name, state.auth_token, upgrade.operation_id);
    assert.equal(upgradeResult.ok, true, upgradeResult.error || "Upgrade re-admission failed.");
    assert.equal(upgradeResult.status.operational_readiness.state, "core_ready");
    assert.equal(fs.readFileSync(startCounterPath, "utf8"), "3");
    assert.equal(fs.readFileSync(materializerCounterPath, "utf8"), "2");
    assert.equal(fs.existsSync(fixture.coordinatorReadyPath), true);
    assert.equal(fixture.coordinatorServer, coordinatorOwner);

    fs.rmSync(fixture.coordinatorReadyPath, { force: true });
    write(failureGatePath, "fail-next\n");
    const failedProbe = await requestPipe(
      state.pipe_name,
      state.auth_token,
      { command: "materialize", action: "Probe", request_id: "coordinator-readmission-failure" });
    assert.equal(failedProbe.pending, true);
    const failedResult = await waitForOperation(
      state.pipe_name,
      state.auth_token,
      failedProbe.operation_id);
    assert.equal(failedResult.ok, false);
    assert.match(failedResult.error, /synthetic coordinator start failure/);
    assert.equal(failedResult.status.coordinator_failure_category, "NONZERO_EXIT");
    assert.equal(failedResult.status.operational_readiness.state, "degraded");
    assert.equal(
      failedResult.status.operational_readiness.coordinator_failure_category,
      "NONZERO_EXIT");
    assert.doesNotMatch(
      JSON.stringify({
        coordinator_failure_category: failedResult.status.coordinator_failure_category,
        last_event: failedResult.status.last_event,
        last_event_detail: failedResult.status.last_event_detail
      }),
      /synthetic coordinator start failure/,
      "Authenticated status/event attribution must not expose the synthetic child stderr.");
    assert.equal(fs.readFileSync(startCounterPath, "utf8"), "4");
    assert.equal(fs.readFileSync(materializerCounterPath, "utf8"), "2");
    assert.equal(fixture.coordinatorServer, coordinatorOwner);
    assert.equal(
      JSON.parse(fs.readFileSync(statePath, "utf8")).supervisor_pid,
      initialSupervisorPid.value,
      "Coordinator re-admission must not create a duplicate outer Supervisor owner.");
    assert.ok(fixture.coordinatorStatusRequests >= 4, "Each re-admission must inspect coordinator status.");
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
  if (process.env.RICE_CODEDB_SUPERVISOR_TEST_FILTER === "request-queue") {
    await verifyQueryFirstBoundedMaintenanceQueue();
    console.log("[PASS] Supervisor query-first bounded maintenance queue owns priority, coalescing, admission, and owner-epoch binding.");
    return;
  }
  if (process.env.RICE_CODEDB_SUPERVISOR_TEST_FILTER === "coordinator-readmission") {
    await verifyCoordinatorReadmissionBeforeMaterializer();
    await verifyRecordedChildAlreadyAbsentUsesAuthoritativeVerifier();
    await verifyRecordedChildAlreadyAbsentFailsClosed();
    console.log("[PASS] Supervisor coordinator re-admission and persisted-child recovery preserve authoritative operation evidence.");
    return;
  }
  if (process.env.RICE_CODEDB_SUPERVISOR_TEST_FILTER === "recorded-child-absent") {
    await verifyRecordedChildAlreadyAbsentFailsClosed();
    console.log("[PASS] Supervisor fails closed when a durably recorded operation child is already absent.");
    return;
  }
  await verifyHappyPath(TARGET, "CURRENT");
  await verifyHappyPath(PREVIOUS, "TRUSTED_PREVIOUS");
  await verifyStableDefaultIdentity();
  await verifyLegacyAndMismatchedRuntimeRejectedWithoutMutation();
  await verifyOwnerEvidenceAndSingleStarter();
  await verifyProvenStaleOwnerTakeover();
  await verifyPidReuseIsAmbiguousAndNeverStopped();
  await verifyAsynchronousMaterializerOperation();
  await verifyQueryFirstBoundedMaintenanceQueue();
  await verifyOperationReattachesAfterSupervisorLoss();
  await verifyMissingChildEvidenceBlocksBlindRetry();
  await verifyRecordedChildAlreadyAbsentFailsClosed();
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
