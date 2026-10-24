// Executes only after explicit human copy/switch approval. No service commands.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const repo=process.cwd(),task=path.join(repo,'.ai/tasks/v0.3.0/cdb-v0.3-p0-s42-coordinator-query-readiness-contract');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const check=(v,c)=>{if(!v)throw Error(c);};
const read=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
const fileHash=p=>sha(fs.readFileSync(p));
check(process.argv[2]==='--execute-approved'&&process.argv.length===4,'APPROVAL_REQUIRED');
const grant=read(path.resolve(process.argv[3]));
check(grant.action==='S42_CONTEXT_CONSUMER_SWITCH'&&grant.human_authorized===true,'WRONG_GRANT');
check(Date.now()-Date.parse(grant.approved_at_utc)>=0&&Date.now()-Date.parse(grant.approved_at_utc)<900000,'EXPIRED_GRANT');
const project=path.resolve(grant.project_root);
check(path.basename(project)==='CodedbTest_2','WRONG_PROJECT');
const externalPackages=path.resolve(project,'../Packages');
const fresh=path.join(externalPackages,'4589249-s42-codedbtest2');
const destination=path.join(fresh,'com.rice.ai-codedb');
const oldRef='file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb';
const newRef='file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb';
const exported=path.join(repo,'.artifacts/exports/s42-instance-context-4589249');
const source=path.join(exported,'review/com.rice.ai-codedb');
const evidence=path.join(repo,'.artifacts/tests/s42-consumer-switch/execution-a');
const backups=path.join(repo,'.backups/s42-consumer-switch-4589249');
function noRedirect(p){for(let q=path.resolve(p);;q=path.dirname(q)){if(fs.existsSync(q))check(!fs.lstatSync(q).isSymbolicLink(),'PATH_REDIRECTED');if(path.dirname(q)===q)break;}}
for(const p of [repo,project,source,externalPackages,fresh,evidence,backups])noRedirect(p);
check(path.dirname(fresh)===externalPackages&&path.dirname(destination)===fresh,'DESTINATION_ESCAPED');
check(!fs.existsSync(fresh)&&!fs.existsSync(evidence)&&!fs.existsSync(backups),'OUTPUT_ALREADY_EXISTS');
fs.mkdirSync(evidence,{recursive:true});
const journal={started_at_utc:new Date().toISOString(),state:'IN_PROGRESS',project,destination,steps:[]};
function step(name,details={}){journal.steps.push({at_utc:new Date().toISOString(),name,...details});fs.writeFileSync(path.join(evidence,'journal.json'),JSON.stringify(journal,null,2)+'\n');}
function inventory(root){const rows=[];function visit(relative){const p=path.join(root,relative),s=fs.lstatSync(p);check(!s.isSymbolicLink(),'PACKAGE_REDIRECTED');
 if(s.isDirectory())for(const n of fs.readdirSync(p))visit(path.join(relative,n));else{check(s.isFile(),'PACKAGE_ENTRY_NOT_REGULAR');rows.push({path:relative.replaceAll('\\','/'),sha256:fileHash(p)});}}
 visit('');return rows.sort((a,b)=>a.path.localeCompare(b.path));}
const protectedPaths=['.codex/config.toml','AIWork/.runtime/codedb/control/current-instance.json',
 'AIWork/.runtime/codedb/instances/a492a5e936c14e4da3ed7e4cc7c8c16c/instance.json',
 'AIWork/codedb/wrapper/codedb-project-wrapper.mjs',
 'Assets/CodeDBValidation/CodeDBQueryProbe.cs','Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs',
 'Assets/CodeDBValidation/CodeDBQueryProbe.cs.meta','Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs.meta'];
const changedPaths=['Packages/manifest.json','Packages/packages-lock.json'];
let baseline;
function snapshotProtected(){return protectedPaths.map(relative=>{const p=path.join(project,relative);noRedirect(p);return {path:relative,sha256:fs.existsSync(p)?fileHash(p):null};});}
function checkProtected(){check(JSON.stringify(snapshotProtected())===JSON.stringify(baseline),'PROTECTED_INPUT_CHANGED');}
function observe(label){
 const r=spawnSync(process.execPath,[path.join(task,'observe-normal-close-once.mjs'),project],{encoding:'utf8',timeout:35000,maxBuffer:2*1024*1024,windowsHide:true});
 check(r.status===0,'RETIREMENT_OBSERVER_FAILED');let parsed;try{parsed=JSON.parse(r.stdout);}catch{throw Error('RETIREMENT_REPORT_UNREADABLE');}
 fs.writeFileSync(path.join(evidence,label+'.json'),JSON.stringify(parsed,null,2)+'\n',{flag:'wx'});
 check(parsed.report.status==='OBSERVED_RETIRED'&&parsed.report.pointer_bytes_stable===true,'RETIREMENT_NOT_ESTABLISHED');
 step(label,{receipt:parsed.artifact,sha256:parsed.sha256});
}
try{
 const closure=read(path.join(repo,'.artifacts/tests/s42-context-commit-export/execution-a/export-result.json'));
 check(closure.status==='EXACT_COMMIT_EXPORT_PASS_NOT_CONSUMER_DELIVERED'&&closure.commit==='4589249564c7affb541634d61656c0cc895ca9d4'
  &&closure.byte_closure==='PASS'&&closure.production_admission==='PASS'&&closure.tests.length===3&&closure.tests.every(t=>t.exit_code===0),'ARTIFACT_GATE_FAILED');
 check(fileHash(path.join(exported,'com.rice.ai-codedb.zip'))==='71bf71b09a7f71f0754f04564f16b2cca4f99e23ce45ffa5f2cbfa6858641cc8','ZIP_CHANGED');
 const expected=read(path.join(repo,'.artifacts/tests/s42-context-commit-export/execution-a/exact-inventory.json'));
 check(expected.length===666&&JSON.stringify(inventory(source))===JSON.stringify(expected),'SOURCE_INVENTORY_CHANGED');
 observe('before-copy');
 baseline=snapshotProtected();
 check(baseline.find(x=>x.path.endsWith('current-instance.json')).sha256==='1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a','POINTER_CHANGED');
 const originals={},replacements={};
 const expectedHashes=['ea79c33e16767692fc3cb14cc92145e97705c42353e84e7955da539164da4485','183766b27213ff3a0bc1b604785661d5e39372c4918ef7c5b9bc9e947da2298d'];
 for(const [i,relative] of changedPaths.entries()){
  const p=path.join(project,relative);noRedirect(p);const bytes=fs.readFileSync(p);check(sha(bytes)===expectedHashes[i],'REFERENCE_PREIMAGE_CHANGED');
  const old=Buffer.from(oldRef),at=bytes.indexOf(old);check(at>=0&&bytes.indexOf(old,at+old.length)===-1,'REFERENCE_NOT_UNIQUE');
  originals[relative]=bytes;const replacement=Buffer.concat([bytes.subarray(0,at),Buffer.from(newRef),bytes.subarray(at+old.length)]);
  const doc=JSON.parse(replacement.toString('utf8').replace(/^\uFEFF/,''));check((i===0?doc.dependencies['com.rice.ai-codedb']:doc.dependencies['com.rice.ai-codedb'].version)===newRef,'REPLACEMENT_INVALID');replacements[relative]=replacement;
 }
 fs.mkdirSync(backups,{recursive:true});
 for(const relative of changedPaths)fs.writeFileSync(path.join(backups,path.basename(relative)),originals[relative],{flag:'wx'});
 fs.writeFileSync(path.join(evidence,'protected-before.json'),JSON.stringify(baseline,null,2)+'\n',{flag:'wx'});step('exact_preimages_backed_up');
 fs.mkdirSync(fresh);fs.cpSync(source,destination,{recursive:true,force:false,errorOnExist:true});step('package_copied');
 const copied=inventory(destination);fs.writeFileSync(path.join(evidence,'copied-inventory.json'),JSON.stringify(copied,null,2)+'\n',{flag:'wx'});
 check(JSON.stringify(copied)===JSON.stringify(expected),'COPIED_INVENTORY_MISMATCH');step('copied_inventory_verified',{files:copied.length});
 observe('before-reference-switch');checkProtected();
 for(const relative of changedPaths)check(fs.readFileSync(path.join(project,relative)).equals(originals[relative]),'REFERENCE_PREIMAGE_DRIFT');
 for(const relative of changedPaths){step('reference_write_intent',{path:relative});fs.writeFileSync(path.join(project,relative),replacements[relative]);check(fs.readFileSync(path.join(project,relative)).equals(replacements[relative]),'REFERENCE_WRITE_MISMATCH');step('reference_written',{path:relative});}
 checkProtected();check(!fs.existsSync(path.join(project,'Temp/UnityLockfile')),'UNITY_LOCK_APPEARED');
 const result={status:'CONSUMER_REFERENCE_SWITCH_PASS_NOT_REOPENED',commit:closure.commit,zip_sha256:closure.artifact_sha256,
  destination,old_reference:oldRef,new_reference:newRef,files:copied.length,
  references:changedPaths.map(relative=>({path:relative,before:sha(originals[relative]),after:fileHash(path.join(project,relative)),replacement_only:true})),
  protected_inputs:baseline,process_snapshots:2,service_rpc:0,install_calls:0,codedb_calls:0,ended_at_utc:new Date().toISOString()};
 fs.writeFileSync(path.join(evidence,'result.json'),JSON.stringify(result,null,2)+'\n',{flag:'wx'});journal.state='PASS';step('complete');console.log(JSON.stringify(result,null,2));
}catch(e){journal.state='STOPPED_NO_REPLAY';journal.stop_code=/^[A-Z0-9_]+$/.test(e.message)?e.message:'EXECUTION_FAILURE';step('stopped');console.log(JSON.stringify({status:journal.state,stop_code:journal.stop_code,journal:path.relative(repo,path.join(evidence,'journal.json'))}));process.exitCode=1;}
