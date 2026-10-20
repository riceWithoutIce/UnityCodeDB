import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';

const [container, packageRoot] = process.argv.slice(2);
const fixture = JSON.parse(fs.readFileSync(path.join(container, 'fixture.json'), 'utf8'));
const {project, generation} = fixture;
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const record = (file, value) => fs.writeFileSync(file, JSON.stringify(value));
// Run unmodified production reader/function bodies without the daemon entry or
// any process/network APIs. Imports are supplied as explicit read-only boundaries.
const supervisorPath=path.join(packageRoot,'Tools~/codedb-project-supervisor.mjs');
let supervisor=fs.readFileSync(supervisorPath,'utf8');
assert.equal((supervisor.match(/^await main\(\);\r?$/gm)??[]).length,1);
supervisor=supervisor.replace(/^#![^\n]*\n/,'').replace(/^import .*;\r?\n/gm,'')
 .replace(/^await main\(\);\r?$/m,'').replaceAll('import.meta.url',JSON.stringify(pathToFileURL(supervisorPath).href));
const readers=vm.runInNewContext(supervisor+'\n;({readPackageRuntimeContract,readSelectedInstance})',{
 crypto,fs,path,Buffer,TextDecoder,process:{argv:[],platform:process.platform},URL
},{timeout:3000});
const contract=readers.readPackageRuntimeContract(fixture.payload);
readers.readSelectedInstance(project,contract);
const installedDependency=path.join(project,'AIWork/codedb/shared/codedb-instance-manifest-contract.mjs');
const dependencyBytes=fs.readFileSync(installedDependency);
try {
 fs.unlinkSync(installedDependency);
 assert.throws(()=>readers.readSelectedInstance(project,contract),/bootstrap dependency/);
 fs.writeFileSync(installedDependency,'tampered');
 assert.throws(()=>readers.readSelectedInstance(project,contract),/bootstrap dependency/);
} finally {fs.writeFileSync(installedDependency,dependencyBytes);}
console.log('[PASS] Supervisor production selected reader accepts closure and refuses missing/drifted dependency; no daemon/process APIs');
// Only fixture-owned generation bytes change; no production payload is rewritten.
const worker = path.join(generation, 'wrapper/codedb-project-instance-worker.mjs');
const fakeWorker = `import readline from 'node:readline';
const names=['codedb_context','codedb_find','codedb_read','codedb_search','codedb_status','codedb_text_search'];
for await (const line of readline.createInterface({input:process.stdin})) {
 const m=JSON.parse(line); if(m.id===undefined) continue;
 let result;
 if(m.method==='initialize') result={protocolVersion:'2025-06-18',serverInfo:{name:'codedb-project-wrapper',version:'fixture'},capabilities:{tools:{}}};
 else if(m.method==='tools/list') result={tools:names.map(name=>({name,annotations:{readOnlyHint:true,destructiveHint:false,idempotentHint:true,openWorldHint:false}}))};
 else result={content:[{type:'text',text:m.params.name==='codedb_status'?'Editor demand: online\\nAutomatic refresh: active\\nLifecycle reason: READY\\nWatch coordinator: ready':'S39 synthetic bounded query'}]};
 process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:m.id,result})+'\\n');
}`;
fs.writeFileSync(worker, fakeWorker);
const generationManifestPath=path.join(generation,'generation-manifest.json');
const gen=JSON.parse(fs.readFileSync(generationManifestPath,'utf8'));
gen.files.find(file=>file.path==='wrapper/codedb-project-instance-worker.mjs').sha256=hash(fakeWorker);
record(generationManifestPath,gen);
const selectionPath=path.join(project,'AIWork/.runtime/codedb/control/current-instance.json');
const selected=JSON.parse(fs.readFileSync(selectionPath,'utf8'));
const instancePath=path.join(project,selected.instance_relative_path,'instance.json');
const instance=JSON.parse(fs.readFileSync(instancePath,'utf8'));
instance.worker_sha256=hash(fakeWorker);
instance.generation_manifest_sha256=hash(fs.readFileSync(generationManifestPath));
record(instancePath,instance);
selected.instance_manifest_sha256=hash(fs.readFileSync(instancePath));
record(selectionPath,selected);
const probe=()=>spawnSync(process.execPath,[path.join(packageRoot,'Tools~/probe-codedb-mcp-availability.mjs'),'--project-root',project],{
 encoding:'utf8',timeout:25000,windowsHide:true,maxBuffer:1024*1024
});
let result=probe();
fs.writeFileSync(path.join(container,'stable-entry-success.json'),result.stdout);
assert.equal(result.status,0,result.stderr);
let evidence=JSON.parse(result.stdout);
assert.equal(evidence.availability,'AVAILABLE');
assert.equal(evidence.wrapper_initialize_callable,true);
assert.equal(evidence.codedb_text_search_callable,true);
console.log('[PASS] actual stable wrapper + shared decoder + synthetic worker: initialize/tools/status/query');
const dependency=path.join(project,'AIWork/codedb/shared/codedb-instance-manifest-contract.mjs');
fs.renameSync(dependency,dependency+'.fixture-backup');
try {
 result=probe();
 fs.writeFileSync(path.join(container,'stable-entry-missing.json'),result.stdout);
 assert.equal(result.status,1);
 evidence=JSON.parse(result.stdout);
 assert.equal(evidence.availability,'UNAVAILABLE');
 assert.equal(evidence.wrapper_initialize_callable,false);
 console.log('[PASS] missing shared decoder reproduces pre-initialize stable-entry failure');
} finally {fs.renameSync(dependency+'.fixture-backup',dependency);}
console.log('[PASS] S39 real stable-entry protocol fixture; synthetic backend; no real Provider/Codex acceptance');
