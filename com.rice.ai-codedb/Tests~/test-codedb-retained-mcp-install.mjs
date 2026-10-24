// Original worker functions with fixture-only machine/process boundaries.
// This is request-binding evidence, not a running Provider or Codex client.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import { AsyncLocalStorage } from 'node:async_hooks';
import { performance } from 'node:perf_hooks';
import { pathToFileURL } from 'node:url';

const run = fs.realpathSync(process.argv[2]);
const owner = JSON.parse(fs.readFileSync(path.join(run, 'manifest.json'), 'utf8'));
assert.equal(owner.network, 'none');
assert.equal(fs.realpathSync(owner.run), run);
const fixture = JSON.parse(fs.readFileSync(path.join(run, 'worker-fixture.json'), 'utf8'));
for (const owned of [fixture.root, fixture.generation]) {
  const relative = path.relative(run, fs.realpathSync(owned));
  assert(relative && !relative.startsWith('..') && !path.isAbsolute(relative));
}
const workerPath = path.join(fixture.generation, 'wrapper/codedb-project-instance-worker.mjs');
const worker = fs.readFileSync(workerPath, 'utf8');
const decoder = await import(pathToFileURL(path.join(fixture.generation, 'shared/codedb-instance-manifest-contract.mjs')).href);
const manifest = JSON.parse(fs.readFileSync(path.join(fixture.generation, 'generation-manifest.json'), 'utf8'));
const contract = { packageVersion: manifest.package_version, payloadVersion: manifest.payload_version,
  payloadSequence: manifest.payload_sequence, generationId: manifest.generation_id, bootstrapProtocol: manifest.bootstrap_protocol };
const declarations = worker.slice(worker.indexOf('const ADAPTER_EXTENSIONS'), worker.indexOf('let generationCache'));
const functions = worker.slice(worker.indexOf('function createSearchSchema()'));
assert(declarations.includes('const REQUIRED_PROVIDER'));
assert(functions.includes('function callTool('));
const currentPointer = path.join(fixture.root, 'AIWork/.runtime/codedb/control/current-instance.json');
const newPointerBytes = fs.readFileSync(currentPointer);
const currentPointerDocument = JSON.parse(newPointerBytes);
const oldRoot = path.join(fixture.root, 'AIWork/.runtime/codedb/instances', fixture.old);
const freshRoot = path.join(fixture.root, 'AIWork/.runtime/codedb/instances', fixture.fresh);
const oldManifestPath = path.join(oldRoot, 'instance.json');
const oldBytes = fs.readFileSync(oldManifestPath);
const oldManifest = JSON.parse(oldBytes);
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const oldPointer = {...currentPointerDocument, instance_id: fixture.old,
  instance_relative_path: oldManifest.instance_relative_path, instance_manifest_sha256: digest(oldBytes)};
const calls = [];
function workerFunctions(instanceId) {
  const boundaryProcess = { env: { LOCALAPPDATA: path.join(run, 'local') }, pid: process.pid,
    platform: process.platform, versions: process.versions, uptime: () => process.uptime(), cwd: () => fixture.root,
    stdout: {write() {throw Error('No MCP transport in function harness');}}, stderr: {write() {}},
    once() {}, kill() {throw Error('Process control forbidden');} };
  const context = {fs, path, crypto, Buffer, TextDecoder, AsyncLocalStorage, performance,
    GENERATION_CONTRACT: contract, parseCodedbInstanceManifest: decoder.parseCodedbInstanceManifest,
    process: boundaryProcess, setInterval, clearInterval, setTimeout, clearTimeout,
    execFile() {throw Error('Native child forbidden');},
    net: { createConnection(pipe) {calls.push(pipe);throw Error('Network forbidden');} },
    instanceRelative: `AIWork/.runtime/codedb/instances/${instanceId}`};
  return vm.runInNewContext(declarations + functions + `
    // Only the external machine-provider lookup is replaced, never routing.
    function resolveMachineProvider() {return {executablePath:${JSON.stringify(path.join(run, 'unavailable-provider.exe'))},manifestPath:${JSON.stringify(path.join(run, 'unavailable-provider.json'))}};}
    let generationCache = null;
    const baseContext = createContext(['--root','.', '--instance-root', instanceRelative]);
    const requestGenerationStorage = new AsyncLocalStorage();
    const context = new Proxy(baseContext,{get(target, property) {
      const generation = requestGenerationStorage.getStore();
      return generation && Object.prototype.hasOwnProperty.call(generation,property) ? generation[property] : target[property];
    }});
    ({baseContext, callTool, readWatchCoordinatorState, invokeProviderTool});`, context, {timeout:3000});
}
const marker = path.join(fixture.root, 'Assets/BindingProbe.cs');
fs.writeFileSync(marker, 'S40_SOURCE_READ\n');
let cases = 0;
function check(label) {cases++;console.log(`PASS ${label}`);}
try {
  fs.writeFileSync(currentPointer, JSON.stringify(oldPointer));
  const oldWorker = workerFunctions(fixture.old);
  const read = async worker => {
    const result = await worker.callTool({name:'codedb_read',arguments:{path:'Assets/BindingProbe.cs'}});
    assert(result.content[0].text.includes('S40_SOURCE_READ'));
  };
  await read(oldWorker);
  check('original worker request before logical removal');
  fs.unlinkSync(currentPointer);
  await read(oldWorker);
  assert.equal(oldWorker.baseContext.instanceRoot, oldRoot);
  check('connected worker remains bound after selection removal');
  fs.writeFileSync(currentPointer, newPointerBytes);
  const freshWorker = workerFunctions(fixture.fresh);
  await read(oldWorker);
  await read(freshWorker);
  assert.equal(oldWorker.baseContext.providerIndexRoot, path.join(oldRoot, 'index'));
  assert.equal(freshWorker.baseContext.providerIndexRoot, path.join(freshRoot, 'index'));
  assert.notEqual(oldWorker.baseContext.providerConfigPath, freshWorker.baseContext.providerConfigPath);
  assert.equal(oldWorker.baseContext.currentGenerationPointerPath, oldManifestPath);
  check('new selection does not rebind existing requests/config/index');
  const oldStatePath = path.join(oldRoot, 'watch/coordinator/coordinator-state.json');
  const freshStatePath = path.join(freshRoot, 'watch/coordinator/coordinator-state.json');
  fs.mkdirSync(path.dirname(oldStatePath), {recursive:true});
  fs.mkdirSync(path.dirname(freshStatePath), {recursive:true});
  fs.writeFileSync(oldStatePath, JSON.stringify({pipe_name:'old-fixture-endpoint'}));
  fs.writeFileSync(freshStatePath, JSON.stringify({pipe_name:'fresh-fixture-endpoint'}));
  try {
    assert.equal(oldWorker.readWatchCoordinatorState().pipe_name, 'old-fixture-endpoint');
    assert.equal(freshWorker.readWatchCoordinatorState().pipe_name, 'fresh-fixture-endpoint');
    check('coordinator discovery stays in the corresponding instance');
    await assert.rejects(oldWorker.invokeProviderTool('codedb_text_search', {query:'probe'}, {}));
    assert.equal(calls.length, 0);
    check('old unavailable runtime query never contacts the new coordinator');
  } finally {fs.unlinkSync(oldStatePath);fs.unlinkSync(freshStatePath);}
  assert.equal(digest(fs.readFileSync(oldManifestPath)), digest(oldBytes));
  assert.deepEqual(fs.readFileSync(currentPointer), newPointerBytes);
  const generationLeases = path.join(fixture.root, 'AIWork/.runtime/codedb/host/leases', manifest.generation_id);
  assert(!fs.existsSync(generationLeases) || fs.readdirSync(generationLeases).length === 0);
  check('request leases released; old manifest and new pointer preserved');
  fs.writeFileSync(path.join(run, 'worker-result.json'), JSON.stringify({state:'PASS',cases,
    evidence:'HARNESS: unmodified production worker functions; synthetic machine lookup; no MCP transport/Provider/IPC',
    node:{version:process.version,sha256:digest(fs.readFileSync(process.execPath))},
    worker_sha256:digest(worker), native_children:0, ipc_calls:calls.length},null,2));
} finally {fs.writeFileSync(currentPointer, newPointerBytes);}
