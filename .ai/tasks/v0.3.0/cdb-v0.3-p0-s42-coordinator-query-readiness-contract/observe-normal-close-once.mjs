// One disk/process snapshot. No service RPC, starts, kills, locks or consumer writes.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../../..');
const target=path.resolve(process.argv[2]??'');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const norm=s=>String(s??'').replaceAll('\\','/').toLowerCase().replace(/\/$/,'');
const eq=(a,b)=>typeof a==='string'&&typeof b==='string'&&norm(path.resolve(a))===norm(path.resolve(b));
const inside=(p,r)=>{const x=path.relative(r,p);return x===''||(!x.startsWith('..')&&!path.isAbsolute(x));};
const check=(v,c)=>{if(!v)throw Error(c);};
const safe=v=>v==null?null:typeof v==='boolean'||typeof v==='number'?v:typeof v==='string'&&/^[A-Za-z0-9_.:+ -]{0,180}$/.test(v)?v:'OMITTED';
const pick=(v,keys)=>Object.fromEntries(keys.map(k=>[k,safe(v?.[k])]));
const start=Date.now();
const report={kind:'ONE_NORMAL_CLOSE_DISK_PROCESS_SNAPSHOT',human_unity:'CLOSED_CONFIRMED',started_at_utc:new Date(start).toISOString(),
 counts:{process_inventory:0,individual_process_probes:0,service_rpc:0,maintenance:0,codedb:0,consumer_writes:0},reads:[]};
let before,packageRoot;
const deadline=()=>check(Date.now()-start<30000,'OBSERVATION_BUDGET_EXHAUSTED');
function noRedirect(p,root){check(inside(p,root),'PATH_OUTSIDE_READ_SCOPE');
 for(let q=p;;q=path.dirname(q)){if(fs.existsSync(q))check(!fs.lstatSync(q).isSymbolicLink(),'READ_REDIRECTED');if(eq(q,root))break;check(inside(q,root)&&path.dirname(q)!==q,'INVALID_READ_ANCESTRY');}}
function read(p,label,optional=false){deadline();const boundary=inside(p,target)?target:packageRoot;check(boundary&&inside(p,boundary),'UNREVIEWED_READ');noRedirect(p,boundary);
 let bytes;try{const stat=fs.statSync(p);check(stat.isFile()&&stat.size<=1024*1024,'INVALID_RECORD_SIZE_OR_TYPE');bytes=fs.readFileSync(p);}catch(e){if(optional&&e.code==='ENOENT'){report.reads.push({record:label,status:'MISSING'});return null;}throw e;}
 report.reads.push({record:label,status:'READ',sha256:hash(bytes)});return {bytes,value:JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''))};}
const references=[];
function add(role,pid,startIdentity=null){if(Number.isSafeInteger(pid)&&pid>0)references.push({role,pid,start_identity:safe(startIdentity)});}
function operation(v,label){if(!v)return null;add(label+'_child',v.child?.pid,v.child?.process_start_identity);
 return {...pick(v,['operation_id','name','state','phase','owner_epoch','execution_disposition','selected_instance_id','selected_generation_id']),
  child:pick(v.child,['pid','process_start_identity']),exit_code:v.result?.exit_code??null};}
try{
 check(process.argv.length===3&&path.basename(target)==='CodedbTest_2'&&eq(fs.realpathSync(target),target),'WRONG_TARGET');
 const runtime=path.join(target,'AIWork/.runtime/codedb');
 const pointerPath=path.join(runtime,'control/current-instance.json');
 const pointer=read(pointerPath,'selected-pointer');before=pointer.bytes;
 check(hash(before)==='1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a','POINTER_DRIFT');
 const p=pointer.value;
 check(p.project_identity==='sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c'
  &&p.instance_id==='a492a5e936c14e4da3ed7e4cc7c8c16c'&&p.activation_epoch==='063aa347f49a4b9f955a5447f293a0ac'
  &&p.generation_id==='poc.44'&&p.instance_relative_path===`AIWork/.runtime/codedb/instances/${p.instance_id}`,'POINTER_IDENTITY_DRIFT');
 report.pointer=pick(p,['project_identity','instance_id','activation_epoch','generation_id']);
 const manifest=read(path.join(target,'Packages/manifest.json'),'manifest');const lock=read(path.join(target,'Packages/packages-lock.json'),'packages-lock');
 const reference='file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb';
 check(manifest.value.dependencies?.['com.rice.ai-codedb']===reference&&lock.value.dependencies?.['com.rice.ai-codedb']?.version===reference,'REFERENCE_DRIFT');
 packageRoot=path.resolve(target,'Packages',reference.slice(5));check(eq(fs.realpathSync(packageRoot),packageRoot),'PACKAGE_REDIRECTED');
 const instanceRoot=path.join(target,p.instance_relative_path);
 const instance=read(path.join(instanceRoot,'instance.json'),'instance-manifest');check(hash(instance.bytes)===p.instance_manifest_sha256,'INSTANCE_HASH_CHANGED');
 check(instance.value.project_identity===p.project_identity&&instance.value.instance_id===p.instance_id&&instance.value.generation_id===p.generation_id,'INSTANCE_IDENTITY_CHANGED');
 const control=path.join(runtime,'control/contracts/v0.3-control/v2/supervisor');
 const state=read(path.join(control,'supervisor-state.json'),'supervisor-state',true)?.value;
 const lockState=read(path.join(control,'supervisor.lock'),'supervisor-lock',true)?.value;
 const current=read(path.join(control,'operation.json'),'current-operation',true)?.value;
 const failed=read(path.join(control,'operation-history/cbe070b2575946efb75ad8eaef555b61.json'),'known-failed-stop')?.value;
 check(failed.operation_id==='cbe070b2575946efb75ad8eaef555b61'&&failed.name==='watcher:Stop'&&failed.selected_instance_id===p.instance_id&&failed.project_identity===p.project_identity,'FAILED_STOP_BINDING_CHANGED');
 const coord=read(path.join(instanceRoot,'watch/coordinator/coordinator-state.json'),'coordinator-state',true)?.value;
 const policy=read(path.join(instanceRoot,'watch/lifecycle/desired-state.json'),'desired-state',true)?.value;
 const manual=read(path.join(instanceRoot,'watch/lifecycle/manual-runtime.json'),'manual-runtime',true)?.value;
 const unityLock=path.join(target,'Temp/UnityLockfile');noRedirect(unityLock,target);report.unity_lock_present=fs.existsSync(unityLock);
 for(const [label,v] of [['supervisor-state',state],['supervisor-lock',lockState]]){if(!v)continue;
  check(eq(v.root,target)&&eq(v.runtime,control)&&v.project_identity===p.project_identity,'SUPERVISOR_RECORD_BINDING_CHANGED');
  if(v.selected_instance_id!=null)check(v.selected_instance_id===p.instance_id,'SUPERVISOR_SELECTION_CHANGED');
  add(label,v.supervisor_pid,v.process_evidence?.process_start_identity??v.process_start_identity);}
 if(current)check(current.project_identity===p.project_identity&&eq(current.root,target)&&eq(current.runtime,control),'CURRENT_OPERATION_BINDING_CHANGED');
 if(coord){check(eq(coord.root,target)&&eq(coord.runtime,path.join(instanceRoot,'watch/coordinator'))&&coord.generation_id===p.generation_id,'COORDINATOR_RECORD_BINDING_CHANGED');
  add('current_coordinator',coord.coordinator_pid);add('current_provider',coord.provider_pid);add('current_adapter_worker',coord.adapter_worker_pid);}
 report.disk={supervisor:state?pick(state,['supervisor_pid','owner_epoch','lifecycle_id','readiness_state','reason_code']):null,
  supervisor_lock_present:Boolean(lockState),coordinator:coord?pick(coord,['coordinator_pid','provider_pid','adapter_worker_pid','lifecycle_id','provider_state','adapter_state']):null,
  current_operation:operation(current,'current_operation'),failed_stop:operation(failed,'known_failed_stop'),
  desired_state:safe(policy?.desired_state),manual_mode:safe(manual?.mode)};
 // Historical identities locate candidates only; they never authorize control.
 const historical=JSON.parse(fs.readFileSync(path.join(repo,'.artifacts/tests/s42-ownership/2026-10-22T03-55-40-920Z-88d5b5/report.json'),'utf8'));
 add('historical_supervisor',historical.disk.supervisor.supervisor_pid);
 add('historical_coordinator',historical.disk.coordinator.coordinator_pid);
 add('historical_provider',historical.disk.coordinator.provider_pid);
 add('historical_adapter_worker',historical.disk.coordinator.adapter_worker_pid);
 add('historical_probe_child',historical.disk.current_operation.child?.pid,historical.disk.current_operation.child?.process_start_identity);
 // Query all process metadata once. Raw paths/argv stay in this process only.
 const script="$ErrorActionPreference='Stop';$rows=@(Get-CimInstance Win32_Process -OperationTimeoutSec 7 -ErrorAction Stop | ForEach-Object {[pscustomobject]@{pid=[int]$_.ProcessId;parent_pid=[int]$_.ParentProcessId;name=[string]$_.Name;executable=[string]$_.ExecutablePath;command_line=[string]$_.CommandLine}});ConvertTo-Json -InputObject $rows -Depth 3 -Compress";
 deadline();report.counts.process_inventory++;
 let inventory;
 try{inventory=JSON.parse(execFileSync('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',Buffer.from(script,'utf16le').toString('base64')],{encoding:'utf8',timeout:10000,maxBuffer:16*1024*1024,windowsHide:true,stdio:['ignore','pipe','pipe']}));}
 catch{throw Error('PROCESS_INVENTORY_UNAVAILABLE');}
 deadline();check(Array.isArray(inventory),'INVALID_PROCESS_INVENTORY');
 const byPid=new Map(inventory.map(x=>[x.pid,x]));
 const observerPids=new Set([process.pid]);let ancestor=process.ppid;
 for(let i=0;i<12&&ancestor;i++){observerPids.add(ancestor);ancestor=byPid.get(ancestor)?.parent_pid;}
 report.recorded_candidates=references.map(r=>({...r,observed:byPid.has(r.pid)?'PID_PRESENT_REQUIRES_ATTRIBUTION':'ABSENT_IN_CURRENT_INVENTORY'}));
 const related=[],unattributed=[];
 const containsTarget=value=>{const s=norm(value);return s.includes(norm(target)+'/')||s.includes(norm(target)+'"')||s.includes(norm(target)+"'")||s.endsWith(norm(target))||s.includes(norm(target)+' ');};
 for(const row of inventory){if(observerPids.has(row.pid))continue;
  const command=norm(row.command_line);const executable=norm(row.executable);
  const known=references.some(r=>r.pid===row.pid);
  const targetPath=containsTarget(command)||containsTarget(executable);
  const backendSignature=/codedb-project-supervisor|codedb-watch-coordinator|text-adapter-worker|manage-codedb-project-watch|materialize-codedb-host-payload/.test(command);
  const unity=/^unity\.exe$/i.test(row.name);
  const relevantName=/^(?:node|unity|powershell|pwsh|codedb)(?:\.exe)?$/i.test(row.name)||/codedb/i.test(row.name)||known;
  if(targetPath){const role=unity?'unity':/wrapper|instance-worker/.test(command)?'mcp_client':backendSignature?'backend_or_maintenance':/codedb/.test(executable)?'provider':'target_related';
   related.push({pid:row.pid,parent_pid:row.parent_pid,role,executable_visible:Boolean(row.executable),invocation_visible:Boolean(row.command_line),historically_recorded_pid:known});}
  else if(known||(relevantName&&!row.command_line)||(backendSignature&&!/--root ["']?[a-z]:\//.test(command))){unattributed.push({pid:row.pid,reason:known?'RECORDED_PID_PRESENT_WITHOUT_TARGET_ATTRIBUTION':!row.command_line?'RELEVANT_PROCESS_INVOCATION_UNAVAILABLE':'BACKEND_WITHOUT_ABSOLUTE_ROOT'});}
 }
 // Include direct descendants of any target backend/maintenance process.
 const targetPids=new Set(related.filter(x=>x.role!=='mcp_client').map(x=>x.pid));
 for(let pass=0;pass<8;pass++){let added=false;for(const row of inventory){if(targetPids.has(row.parent_pid)&&!targetPids.has(row.pid)&&!observerPids.has(row.pid)){targetPids.add(row.pid);related.push({pid:row.pid,parent_pid:row.parent_pid,role:'target_process_descendant',executable_visible:Boolean(row.executable),invocation_visible:Boolean(row.command_line)});added=true;}}if(!added)break;}
 report.process_observation={scope:'ONE_COMPLETE_WIN32_PROCESS_METADATA_INVENTORY',target_related:related,unattributed_candidates:unattributed};
 const live=related.filter(x=>x.role!=='mcp_client');
 report.blockers=[];
 if(report.unity_lock_present)report.blockers.push('UNITY_LOCKFILE_PRESENT');
 if(live.length)report.blockers.push('TARGET_PROCESS_REMAINS');
 if(unattributed.length)report.blockers.push('PROCESS_ATTRIBUTION_NOT_ESTABLISHED');
 if(state||lockState||coord)report.blockers.push('RUNTIME_OWNER_RECORDS_REMAIN');
 if(current&&['running','queued'].includes(current.state))report.blockers.push('RECORDED_OPERATION_NOT_TERMINAL');
 if(current?.execution_disposition==='UNKNOWN')report.blockers.push('CURRENT_CHILD_DISPOSITION_UNKNOWN');
 report.status=live.length?'RESIDUAL_LIVE':report.blockers.length?'NOT_ESTABLISHED':'OBSERVED_RETIRED';
 report.stage='COMPLETE';
}catch(e){report.status='NOT_ESTABLISHED';report.stop_code=/^[A-Z0-9_]+$/.test(e.message)?e.message:'READ_OR_VALIDATION_FAILURE';report.error_sha256=hash(String(e.message));}
finally{
 try{if(before){const end=read(path.join(target,'AIWork/.runtime/codedb/control/current-instance.json'),'selected-pointer-final');report.pointer_bytes_stable=before.equals(end.bytes);check(report.pointer_bytes_stable,'POINTER_CHANGED');}}
 catch{report.pointer_bytes_stable=false;report.status='NOT_ESTABLISHED';report.stop_code='FINAL_POINTER_OR_BUDGET_CHECK_FAILED';}
 report.elapsed_ms=Date.now()-start;report.ended_at_utc=new Date().toISOString();
 const parent=path.join(repo,'.artifacts/tests/s42-normal-close');noRedirect(parent,repo);fs.mkdirSync(parent,{recursive:true});
 const output=path.join(parent,report.started_at_utc.replace(/[:.]/g,'-')+'-'+crypto.randomBytes(3).toString('hex'));fs.mkdirSync(output);
 const file=path.join(output,'report.json');fs.writeFileSync(file,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
 console.log(JSON.stringify({artifact:path.relative(repo,file).replaceAll('\\','/'),sha256:hash(fs.readFileSync(file)),report},null,2));
}
