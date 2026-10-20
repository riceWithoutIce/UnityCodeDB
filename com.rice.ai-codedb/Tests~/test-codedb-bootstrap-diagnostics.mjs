#!/usr/bin/env node
// Production stable entry/probe with fixture-owned workers. No Provider or MCP host.
import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const packageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
assert(args.length === 0 || (args.length === 2 && args[0] === "--repository-root"),
  "Expected only an explicit enclosing --repository-root for candidate verification.");
const repository = args.length ? fs.realpathSync(path.resolve(args[1])) : path.dirname(packageRoot);
assert(fs.existsSync(path.join(repository, ".git")), "Run this harness from its source checkout.");
const parent = path.join(repository, ".artifacts", "tests", "s39-bootstrap-diagnostics");
const runId = crypto.randomUUID();
const runRoot = path.join(parent, `r-${runId}`);
function inside(candidate, root) {
  const relative = path.relative(root, candidate);
  assert(relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative), "Fixture escaped owner.");
}
function noLinks(candidate, root) {
  inside(candidate, root);
  for (let current = candidate; ; current = path.dirname(current)) {
    try { assert(!fs.lstatSync(current).isSymbolicLink(), `Reparse fixture ancestor: ${current}`); }
    catch (error) { if (error.code !== "ENOENT") throw error; }
    if (current === root) return;
  }
}
inside(packageRoot, repository);
noLinks(packageRoot, repository);
noLinks(parent, repository);
fs.mkdirSync(parent, { recursive: true });
fs.mkdirSync(runRoot); // Create-only allocation, never reuse another run.
noLinks(runRoot, repository);
const ownership = path.join(runRoot, "owner.json");
fs.writeFileSync(ownership, JSON.stringify({ run_id: runId, task: "s39-bootstrap-diagnostics" }), { flag: "wx" });
const ioProbe = path.join(runRoot, "io-probe.txt");
fs.writeFileSync(ioProbe, runId, { flag: "wx" });
assert.equal(fs.readFileSync(ioProbe, "utf8"), runId);
fs.unlinkSync(ioProbe);

const wrapperSource = path.join(packageRoot, "Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs");
const decoderSource = path.join(packageRoot, "Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.mjs");
const probeSource = path.join(packageRoot, "Tools~/probe-codedb-mcp-availability.mjs");
const wrapperRelative = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs";
const instanceId = "1234567890abcdef1234567890abcdef";
const epoch = "abcdef1234567890abcdef1234567890";
const generationId = "poc.43";
const hash = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const projectIdentity = (root) => `sha256:${hash(path.resolve(root).replace(/^\\\\\?\\/, "").replace(/\\/g, "/").replace(/\/+$/, "").toLowerCase())}`;
function write(target, bytes) {
  noLinks(target, runRoot);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, bytes);
}
function json(target, value) { write(target, `${JSON.stringify(value, null, 2)}\n`); }
function fixture(name, workerCode) {
  const root = path.join(runRoot, name);
  for (const marker of ["Assets", "Packages", "ProjectSettings"]) fs.mkdirSync(path.join(root, marker), { recursive: true });
  const wrapper = path.join(root, wrapperRelative);
  write(wrapper, fs.readFileSync(wrapperSource));
  write(path.join(root, "AIWork/codedb/shared/codedb-instance-manifest-contract.mjs"), fs.readFileSync(decoderSource));
  const generationRelative = `AIWork/.runtime/codedb/host/generations/${generationId}`;
  const worker = path.join(root, generationRelative, "wrapper/codedb-project-instance-worker.mjs");
  write(worker, workerCode);
  const generationManifest = path.join(root, generationRelative, "generation-manifest.json");
  json(generationManifest, { schema_version: 1, generation_id: generationId, fixture: true });
  const instanceRelative = `AIWork/.runtime/codedb/instances/${instanceId}`;
  const instancePath = path.join(root, instanceRelative, "instance.json");
  json(instancePath, {
    schema_version: 1, managed_by: "com.rice.ai-codedb", project_identity: projectIdentity(root),
    instance_id: instanceId, instance_relative_path: instanceRelative, state: "READY",
    package_version: "0.3.0-preview.5", payload_version: generationId, payload_sequence: 43,
    generation_id: generationId, generation_relative_path: generationRelative, bootstrap_protocol: 1,
    generation_manifest_sha256: hash(fs.readFileSync(generationManifest)),
    worker_relative_path: "wrapper/codedb-project-instance-worker.mjs", worker_sha256: hash(workerCode),
    created_at_utc: new Date().toISOString(), verified_at_utc: new Date().toISOString()
  });
  const pointer = path.join(root, "AIWork/.runtime/codedb/control/current-instance.json");
  json(pointer, {
    schema_version: 1, managed_by: "com.rice.ai-codedb", project_identity: projectIdentity(root),
    instance_id: instanceId, instance_relative_path: instanceRelative, generation_id: generationId,
    instance_manifest_sha256: hash(fs.readFileSync(instancePath)), activation_epoch: epoch
  });
  return { root, wrapper, worker, pointer, instanceRelative,
    diagnostics: path.join(root, "AIWork/.runtime/codedb/diagnostics/bootstrap") };
}
function run(item, options = {}) {
  const result = spawnSync(process.execPath, [item.wrapper, "--root", "."], {
    cwd: item.root, input: "", encoding: "utf8", timeout: 15000, maxBuffer: 1024 * 1024,
    windowsHide: true, ...options
  });
  assert.ifError(result.error);
  return result;
}
function records(item) {
  const names = fs.readdirSync(item.diagnostics);
  assert(names.every((name) => /^\d+-[a-f0-9-]+\.json$/.test(name)), "Unexpected diagnostic artifact.");
  return names.map((name) => JSON.parse(fs.readFileSync(path.join(item.diagnostics, name), "utf8")));
}
function one(item) {
  const found = records(item);
  assert.equal(found.length, 1, "Exactly one terminal record per launch.");
  const record = found[0];
  assert.equal(record.schema_version, 1);
  assert.equal(record.startup_cwd.toLowerCase(), item.root.toLowerCase());
  assert.equal(record.node_executable, process.execPath);
  assert.equal(record.node_version, process.versions.node);
  assert(Number.isInteger(record.pid));
  assert(!Object.hasOwn(record, "environment") && !Object.hasOwn(record, "argv"));
  assert(!/handshake|initialize.*success|query.*success/i.test(JSON.stringify(record)));
  return record;
}
const passes = [];
function passed(name) { passes.push(name); console.log(`[PASS] ${name}`); }
const nonzero = `process.stderr.write("FIXTURE_NONZERO\\n"); process.exit(7);`;
const successWorker = `
import readline from 'node:readline';
const names=['codedb_context','codedb_find','codedb_read','codedb_search','codedb_status','codedb_text_search'];
for await (const line of readline.createInterface({input:process.stdin})) {
 const m=JSON.parse(line); if(m.id===undefined) continue;
 let result;
 if(m.method==='initialize') result={protocolVersion:m.params.protocolVersion,serverInfo:{name:'codedb-project-wrapper',version:'fixture'},capabilities:{tools:{}}};
 else if(m.method==='tools/list') result={tools:names.map(name=>({name,annotations:{readOnlyHint:true,destructiveHint:false,idempotentHint:true,openWorldHint:false}}))};
 else result={content:[{type:'text',text:m.params.name==='codedb_status'?'Editor demand: online\\nAutomatic refresh: active\\nLifecycle reason: READY\\nWatch coordinator: ready':'synthetic bounded query'}]};
 process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:m.id,result})+'\\n');
}`;
function probe(item, extra = []) {
  const result = spawnSync(process.execPath, [probeSource, "--project-root", item.root, ...extra], {
    cwd: runRoot, encoding: "utf8", timeout: 20000, maxBuffer: 1024 * 1024, windowsHide: true
  });
  assert.ifError(result.error);
  const evidence = JSON.parse(result.stdout);
  json(path.join(item.root, "probe-observation.json"), { status: result.status, stderr: result.stderr, evidence });
  return { result, evidence };
}

try {
  const forwarded = fixture("forwarding", `
import fs from 'node:fs'; import path from 'node:path';
if(fs.existsSync(path.join(process.cwd(),'AIWork/.runtime/codedb/diagnostics'))) throw new Error('Unexpected startup write');
process.stdout.write(' \\t{"forwarded":true}\\n');
process.stdin.resume(); process.stdin.on('end',()=>process.exit(0));
`);
  let result = run(forwarded, { input: '{"opaque":"passed through"}\n', env: { ...process.env, LOCALAPPDATA: "", S39_UNRELATED_SECRET: "not-for-record" } });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, ' \t{"forwarded":true}\n');
  assert.equal(result.stderr, "");
  let record = one(forwarded);
  assert.equal(record.event, "worker_exit");
  assert.equal(record.last_completed_stage, "worker_created");
  assert.equal(record.worker_exit_code, 0);
  assert.equal(record.wrapper_exit_code_requested, 0);
  assert.equal(record.error, null);
  assert.deepEqual(record.localappdata, { present: false, absolute: false });
  assert.equal(record.selected_identity.instance_id, instanceId);
  assert.equal(record.selected_identity.activation_epoch, epoch);
  assert(!JSON.stringify(record).includes("not-for-record"));
  passed("exact stdout forwarding; no startup write; zero exit is neutral; bounded environment facts");

  const broken = fixture("worker-error", `throw new Error('FIXTURE_THROW auth_token=fixture-sensitive');`);
  result = run(broken);
  assert.equal(result.status, 1);
  assert.equal(result.stdout, "");
  assert.match(result.stderr, /FIXTURE_THROW/);
  record = one(broken);
  assert.equal(record.worker_exit_code, 1);
  assert.match(record.error.message, /auth_token=\[REDACTED\]/);
  assert(!record.error.message.includes("fixture-sensitive"));
  passed("worker error plus exit produces one record and preserves stderr/exit");

  const badSelection = fixture("selection-error", nonzero);
  const pointer = JSON.parse(fs.readFileSync(badSelection.pointer, "utf8"));
  pointer.instance_manifest_sha256 = "0".repeat(64); json(badSelection.pointer, pointer);
  result = run(badSelection);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /manifest hash/);
  record = one(badSelection);
  assert.equal(record.event, "wrapper_error");
  assert.equal(record.last_completed_stage, "project_root_validated");
  assert.equal(record.selected_identity, null);
  assert.equal(record.worker_exit_code, null);
  passed("selection failure records only completed validation and no selected identity");

  const blocked = fixture("log-blocked", nonzero);
  const blocker = path.dirname(blocked.diagnostics); write(blocker, "protected-fixture-file");
  result = run(blocked);
  assert.equal(result.status, 7);
  assert.equal(result.stdout, "");
  assert.equal(result.stderr, "FIXTURE_NONZERO\n");
  assert.equal(fs.readFileSync(blocker, "utf8"), "protected-fixture-file");
  passed("unwritable diagnostic path cannot change stderr or exit code");

  const junction = fixture("log-junction", nonzero);
  const outside = path.join(runRoot, "junction-destination"); fs.mkdirSync(outside);
  fs.symlinkSync(outside, path.dirname(junction.diagnostics), process.platform === "win32" ? "junction" : "dir");
  result = run(junction);
  assert.equal(result.status, 7);
  assert.equal(result.stderr, "FIXTURE_NONZERO\n");
  assert.deepEqual(fs.readdirSync(outside), []);
  passed("diagnostic ancestor junction is refused without writing through it");

  const invalidRoot = fixture("invalid-root", nonzero);
  fs.rmdirSync(path.join(invalidRoot.root, "Assets"));
  result = run(invalidRoot);
  assert.equal(result.status, 1);
  assert(!fs.existsSync(invalidRoot.diagnostics));
  passed("unvalidated project root receives no diagnostic writes");

  const missingImport = fixture("missing-import", nonzero);
  fs.unlinkSync(path.join(missingImport.root, "AIWork/codedb/shared/codedb-instance-manifest-contract.mjs"));
  result = run(missingImport);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /ERR_MODULE_NOT_FOUND/);
  assert(!fs.existsSync(missingImport.diagnostics));
  passed("static import failure remains stderr-only, declared diagnostic coverage limit");

  const concurrent = fixture("concurrent", nonzero);
  const outcomes = await Promise.all([1, 2].map(() => new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [concurrent.wrapper, "--root", "."], { cwd: concurrent.root, stdio: ["ignore", "pipe", "pipe"], windowsHide: true });
    let stderr = ""; child.stdout.resume(); child.stderr.on("data", (chunk) => { stderr += chunk; });
    const timer = setTimeout(() => { child.kill(); reject(new Error("Owned fixture child timeout")); }, 15000);
    child.once("error", (error) => { clearTimeout(timer); reject(error); });
    child.once("close", (code) => { clearTimeout(timer); resolve({ code, stderr }); });
  })));
  assert(outcomes.every(({ code, stderr }) => code === 7 && stderr === "FIXTURE_NONZERO\n"));
  const concurrentRecords = records(concurrent);
  assert.equal(concurrentRecords.length, 2);
  assert.equal(new Set(concurrentRecords.map((entry) => entry.correlation_id)).size, 2);
  passed("concurrent exits retain separate create-only records");

  const failure = fixture("probe-failure", nonzero);
  const failedPointer = JSON.parse(fs.readFileSync(failure.pointer, "utf8"));
  failedPointer.instance_manifest_sha256 = "0".repeat(64); json(failure.pointer, failedPointer);
  let observed = probe(failure);
  assert.equal(observed.result.status, 1);
  assert.equal(observed.evidence.wrapper_initialize_callable, false);
  assert.equal(observed.evidence.child_exit_code, 1);
  assert.equal(observed.evidence.child_exit_observed, true);
  assert.equal(observed.evidence.child_termination_requested, false);
  assert.match(observed.evidence.child_stderr, /manifest hash/);
  assert.match(observed.evidence.detail, /Child stderr:\n.*manifest hash/);
  passed("production probe retains initialize-failure stderr and natural exit code");

  const verbose = fixture("probe-bounded", `process.stderr.write('X'.repeat(70000),()=>process.exit(9));`);
  // A fixture-owned direct entry exits naturally without the stable launcher's
  // stdin pipe. Only this owned test file is replaced, never production source.
  write(verbose.wrapper, `process.stderr.write('X'.repeat(70000),()=>process.exit(9));`);
  observed = probe(verbose);
  assert.equal(observed.result.status, 1);
  assert.equal(observed.evidence.child_exit_code, 9);
  assert.equal(observed.evidence.child_stderr.length, 64 * 1024);
  assert.equal(observed.evidence.child_stderr_truncated, true);
  passed("probe stderr capture remains bounded with explicit truncation");

  const zero = fixture("probe-zero", "process.exit(0);");
  write(zero.wrapper, "process.exit(0);");
  observed = probe(zero);
  assert.equal(observed.result.status, 1);
  assert.equal(observed.evidence.child_exit_code, 0);
  assert.equal(observed.evidence.availability, "UNAVAILABLE");
  assert.equal(observed.evidence.wrapper_initialize_callable, false);
  passed("zero child exit before initialize is not availability success");

  const protocolFailure = fixture("probe-termination", `process.stderr.write('PROTOCOL_FIXTURE_STDERR\\n'); process.stdout.write('invalid-json\\n'); process.stdin.resume();`);
  observed = probe(protocolFailure);
  assert.equal(observed.result.status, 1);
  assert.equal(observed.evidence.child_termination_requested, true);
  assert.equal(observed.evidence.child_exit_observed, true);
  assert.match(observed.evidence.child_stderr, /PROTOCOL_FIXTURE_STDERR/);
  assert.match(observed.evidence.detail, /invalid JSON-RPC/);
  passed("probe-requested termination is attributed and stderr drains before failure output");

  const candidate = fixture("candidate-error", `throw new Error('CANDIDATE_FIXTURE_THROW');`);
  const candidatePackage = path.join(runRoot, "candidate-package");
  const candidateProbe = path.join(candidatePackage, "Tools~/probe-codedb-mcp-availability.mjs");
  write(candidateProbe, fs.readFileSync(probeSource));
  write(path.join(candidatePackage, "Payload~/Generations/poc.43/wrapper/codedb-project-instance-worker.mjs"), fs.readFileSync(candidate.worker));
  const candidateResult = spawnSync(process.execPath, [candidateProbe, "--project-root", candidate.root,
    "--wrapper", path.relative(candidate.root, candidate.worker), "--instance-root", candidate.instanceRelative],
    { encoding: "utf8", timeout: 20000, maxBuffer: 1024 * 1024, windowsHide: true });
  assert.ifError(candidateResult.error);
  assert.equal(candidateResult.status, 1);
  assert.match(JSON.parse(candidateResult.stdout).detail, /CANDIDATE_FIXTURE_THROW/);
  passed("candidate Worker probe preserves its original error path");

  const candidateProtocol = fixture("candidate-protocol", `process.stderr.write('CANDIDATE_PROTOCOL_STDERR\\n'); process.stdout.write('invalid-json\\n'); process.stdin.resume();`);
  write(path.join(candidatePackage, "Payload~/Generations/poc.43/wrapper/codedb-project-instance-worker.mjs"), fs.readFileSync(candidateProtocol.worker));
  const candidateStopped = spawnSync(process.execPath, [candidateProbe, "--project-root", candidateProtocol.root,
    "--wrapper", path.relative(candidateProtocol.root, candidateProtocol.worker), "--instance-root", candidateProtocol.instanceRelative],
    { encoding: "utf8", timeout: 20000, maxBuffer: 1024 * 1024, windowsHide: true });
  assert.ifError(candidateStopped.error);
  assert.equal(candidateStopped.status, 1);
  const candidateEvidence = JSON.parse(candidateStopped.stdout);
  assert.equal(candidateEvidence.child_termination_requested, true);
  assert.equal(candidateEvidence.child_exit_observed, true);
  assert.match(candidateEvidence.child_stderr, /CANDIDATE_PROTOCOL_STDERR/);
  passed("candidate Worker termination is also attributed with retained stderr");

  const healthy = fixture("probe-success", successWorker);
  observed = probe(healthy);
  assert.equal(observed.result.status, 0, observed.result.stderr);
  assert.equal(observed.evidence.availability, "AVAILABLE");
  assert.equal(observed.evidence.codedb_text_search_callable, true);
  assert.equal(observed.evidence.child_exit_code, 0);
  assert.equal(one(healthy).error, null);
  passed("production stable-entry probe still initializes/lists/status/queries with synthetic backend");

  json(path.join(runRoot, "result.json"), { status: "SOURCE_FOCUSED_PASS", cases: passes, run_id: runId,
    source_sha256: { wrapper: hash(fs.readFileSync(wrapperSource)), probe: hash(fs.readFileSync(probeSource)) },
    limitations: "Synthetic workers only; no Provider, Unity, Codex MCP, clean Install or release acceptance." });
  console.log(`[PASS] ${passes.length} scenarios; evidence=${path.relative(repository, runRoot).replace(/\\/g, "/")}`);
} catch (error) {
  json(path.join(runRoot, "result.json"), { status: "FAIL", completed_cases: passes, error: String(error.stack ?? error) });
  throw error;
}
