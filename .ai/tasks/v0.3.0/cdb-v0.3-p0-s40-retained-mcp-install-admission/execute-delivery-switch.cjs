const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = process.cwd();
const task = path.join(root,'.ai/tasks/v0.3.0/cdb-v0.3-p0-s40-retained-mcp-install-admission');
const evidence = path.join(root,'.artifacts/tests/s40-retained-mcp-install/delivery-execution-a');
const read = p => JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const fileHash = p => sha(fs.readFileSync(p));
function assert(ok,msg) { if (!ok) throw Error(msg); }
const commit = read(path.join(evidence,'commit.json'));
const baseline = read(path.join(root,'.artifacts/tests/s40-retained-mcp-install/delivery-preflight-a/consumer-baseline.json'));
const project = baseline.project;
const short = commit.commit.slice(0,7);
const exportRoot = path.join(root,commit.export_relative);
const source = path.join(exportRoot,'review/com.rice.ai-codedb');
const freshParent = path.join(path.dirname(project),'Packages',short+'-s40-codedbtest2');
const destination = path.join(freshParent,'com.rice.ai-codedb');
const oldReference = 'file:../../Packages/c848049-codedbtest2/com.rice.ai-codedb';
const newReference = 'file:../../Packages/'+short+'-s40-codedbtest2/com.rice.ai-codedb';
const changedPaths = ['Packages/manifest.json','Packages/packages-lock.json'];
const pointer = path.join(project,'AIWork/.runtime/codedb/control/current-instance.json');
const journalPath = path.join(evidence,'switch-journal.json');
assert(!fs.existsSync(journalPath),'Preserve prior switch attempt');
const journal = {started_at:new Date().toISOString(),commit:commit.commit,project,source,destination,oldReference,newReference,steps:[]};
const save = () => fs.writeFileSync(journalPath,JSON.stringify(journal,null,2));
function step(name,details={}) { journal.steps.push({at:new Date().toISOString(),name,...details}); save(); }
function noRedirect(p) {
  for(let cursor=path.resolve(p);;cursor=path.dirname(cursor)) {
    if(fs.existsSync(cursor)) assert(!fs.lstatSync(cursor).isSymbolicLink(),'Redirected path: '+cursor);
    if(path.dirname(cursor)===cursor) break;
  }
}
function inventory(dir) {
  const rows=[];
  function visit(relative) {
    const absolute=path.join(dir,relative);
    const st=fs.lstatSync(absolute);
    assert(!st.isSymbolicLink(),'Redirected package file');
    if(st.isDirectory()) for(const name of fs.readdirSync(absolute).sort()) visit(path.join(relative,name));
    else { assert(st.isFile(),'Non-regular Package input'); rows.push({path:relative.split(path.sep).join('/'),bytes:st.size,sha256:fileHash(absolute)}); }
  }
  visit(''); return rows.sort((a,b)=>a.path.localeCompare(b.path,'en'));
}
function closedUnity(label) {
  const command = "$ErrorActionPreference='Stop'; $rows=@(Get-CimInstance -ClassName Win32_Process -Filter \"Name='Unity.exe'\" -ErrorAction Stop | Select-Object ProcessId,ExecutablePath,CommandLine); ConvertTo-Json -InputObject $rows -Compress";
  const result=spawnSync('powershell.exe',['-NoProfile','-Command',command],{encoding:'utf8'});
  assert(result.status===0,'Unreadable Unity process inventory: '+result.stderr);
  const processes=JSON.parse(result.stdout.replace(/^\uFEFF/,'').trim());
  fs.writeFileSync(path.join(evidence,label+'-unity.json'),JSON.stringify({at:new Date().toISOString(),processes,stderr:result.stderr,lock_present:fs.existsSync(path.join(project,'Temp/UnityLockfile'))},null,2));
  assert(Array.isArray(processes)&&processes.length===0,'Unity is running');
  assert(!fs.existsSync(path.join(project,'Temp/UnityLockfile')),'Unity lock present');
}
function checkBaseline(includeReferences) {
  for(const input of baseline.inputs) {
    if(!includeReferences&&changedPaths.includes(input.relative_path)) continue;
    noRedirect(path.join(project,input.relative_path));
    assert(fileHash(path.join(project,input.relative_path))===input.sha256,'Consumer baseline drift: '+input.relative_path);
  }
  assert(!fs.existsSync(pointer),'Selected pointer appeared');
}
try {
  noRedirect(source); noRedirect(freshParent); noRedirect(project);
  const result=read(path.join(root,'.artifacts/tests/s40-retained-mcp-install/delivery-exact-ps51-'+short+'/result.json'));
  assert(result.state==='PASS'&&result.cases===46&&result.provider_execution===0&&result.external_client_calls===0,'Exact artifact fixture gate failed');
  const log=fs.readFileSync(path.join(evidence,'export.log'),'utf8');
  assert(log.includes('[PACKAGE_EXPORT] PASS commit='+commit.commit)&&log.includes('PASS package=Exact ZIP'),'Exact export gate missing');
  const zipHash=fileHash(path.join(exportRoot,'com.rice.ai-codedb.zip'));
  assert(log.includes('artifact_sha256='+zipHash),'ZIP hash drift');
  for(const s of commit.source_files) assert(fileHash(path.join(exportRoot,'review',s.path))===s.sha256,'Export source drift');
  const files=inventory(source);
  assert(files.length===666,'Package inventory changed');
  assert(JSON.stringify(files)===JSON.stringify(inventory(path.join(exportRoot,'package/com.rice.ai-codedb'))),'Stage/exact ZIP inventory mismatch');
  fs.writeFileSync(path.join(evidence,'source-inventory.json'),JSON.stringify(files,null,2));
  assert(!fs.existsSync(freshParent),'Fresh destination already exists');
  closedUnity('before-copy'); checkBaseline(true);
  step('preflight_pass',{zip_sha256:zipHash,files:files.length});
  const backup=path.join(evidence,'consumer-preimages');
  fs.mkdirSync(backup);
  const originals={}; const replacements={};
  for(const relative of changedPaths) {
    const bytes=fs.readFileSync(path.join(project,relative));
    originals[relative]=bytes;
    fs.writeFileSync(path.join(backup,path.basename(relative)),bytes,{flag:'wx'});
    const old=Buffer.from(oldReference); const offset=bytes.indexOf(old);
    assert(offset>=0&&bytes.indexOf(old,offset+old.length)===-1,'Expected one CodeDB reference: '+relative);
    replacements[relative]=Buffer.concat([bytes.subarray(0,offset),Buffer.from(newReference),bytes.subarray(offset+old.length)]);
    const doc=JSON.parse(replacements[relative].toString('utf8').replace(/^\uFEFF/,''));
    assert((relative.endsWith('packages-lock.json')?doc.dependencies['com.rice.ai-codedb'].version:doc.dependencies['com.rice.ai-codedb'])===newReference,'Replacement parse failed');
  }
  step('exact_preimages_backed_up');
  fs.mkdirSync(freshParent);
  fs.cpSync(source,destination,{recursive:true,force:false,errorOnExist:true});
  step('fresh_package_copied');
  const copied=inventory(destination);
  fs.writeFileSync(path.join(evidence,'copied-inventory.json'),JSON.stringify(copied,null,2));
  assert(JSON.stringify(copied)===JSON.stringify(files),'Copied inventory mismatch');
  step('copied_inventory_pass',{files:copied.length});
  closedUnity('before-reference-switch'); checkBaseline(true);
  for(const relative of changedPaths) {
    assert(fs.readFileSync(path.join(project,relative)).equals(originals[relative]),'Reference preimage drift');
    fs.writeFileSync(path.join(project,relative),replacements[relative]);
    assert(fs.readFileSync(path.join(project,relative)).equals(replacements[relative]),'Reference write mismatch');
    step('reference_replaced',{path:relative,before:sha(originals[relative]),after:sha(replacements[relative]),replacement_only:true});
  }
  checkBaseline(false);
  closedUnity('after-reference-switch');
  const protectedInputs=baseline.inputs.filter(s=>!changedPaths.includes(s.relative_path)).map(s=>({path:s.relative_path,sha256:fileHash(path.join(project,s.relative_path)),unchanged:true}));
  const receipt={state:'DELIVERY_PASS',commit:commit.commit,tree:commit.tree,zip_sha256:zipHash,export_gates:'PASS: commit-stage and exact-ZIP closure/admission',focused_harness:result,project,destination,files:files.length,old_reference:oldReference,new_reference:newReference,references:changedPaths.map(p=>({path:p,before:sha(originals[p]),after:fileHash(path.join(project,p)),replacement_only:true})),protected_inputs:protectedInputs,selected_pointer_present:fs.existsSync(pointer),unity_closed:true,real_install_calls:0,real_mcp_calls:0};
  fs.writeFileSync(path.join(evidence,'delivery.json'),JSON.stringify(receipt,null,2));
  step('delivery_pass'); console.log(JSON.stringify(receipt,null,2));
} catch(error) {
  journal.failure=String(error.stack||error); journal.stopped_at=new Date().toISOString(); save(); throw error;
}
