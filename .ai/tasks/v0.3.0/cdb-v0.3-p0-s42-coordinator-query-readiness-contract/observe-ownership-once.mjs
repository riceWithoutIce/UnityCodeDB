// Task-owned, one-shot ownership diagnostic. Never import the runtime entry point.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import net from 'node:net';
import vm from 'node:vm';
import {execFile, execFileSync} from 'node:child_process';
import {fileURLToPath, pathToFileURL} from 'node:url';

const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../../..');
const target=path.resolve(process.argv[2]);
const runtime=path.join(target,'AIWork/.runtime/codedb');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const eq=(a,b)=>typeof a==='string'&&typeof b==='string'
  &&path.resolve(a).replaceAll('\\','/').toLowerCase()===path.resolve(b).replaceAll('\\','/').toLowerCase();
const inside=(p,r)=>{const v=path.relative(r,p);return v===''||(!v.startsWith('..')&&!path.isAbsolute(v));};
const started=new Date().toISOString();
const report={evidence:'ONE_SHOT_READ_ONLY_OWNERSHIP',started_at_utc:started,human_unity:'OPEN',human_manager:'NOT_REPORTED',
  counts:{supervisor_status:0,coordinator_status:0,process_identity_probes:0,maintenance:0,codedb:0},reads:[]};
const safe=v=>v==null?null:typeof v==='boolean'||typeof v==='number'?v:
  typeof v==='string'&&/^[A-Za-z0-9_.:+ -]{0,180}$/.test(v)?v:'OMITTED';
const pick=(v,keys)=>Object.fromEntries(keys.map(k=>[k,safe(v?.[k])]));
function read(p,label,optional=false){
  if(!inside(p,target)&&!inside(p,packageRoot??target))throw new Error('READ_OUTSIDE_SCOPE');
  let bytes;
  try{if(fs.statSync(p).size>1024*1024)throw new Error('RECORD_TOO_LARGE');bytes=fs.readFileSync(p);}
  catch(e){report.reads.push({record:label,status:e.code==='ENOENT'?'MISSING':'UNREADABLE'});if(optional&&e.code==='ENOENT')return null;throw e;}
  const hash=sha(bytes);report.reads.push({record:label,status:'READ',sha256:hash});
  return {bytes,hash,value:JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''))};
}
let packageRoot=null,pointerPath=null,initialPointer=null;
const operation=v=>({...pick(v,['operation_id','name','state','phase','owner_epoch','execution_disposition','started_at_utc','completed_at_utc','error_code']),
  child_present:v?.child!=null,child:pick(v?.child,['pid','process_start_identity']),exit_code:v?.result?.exit_code??null,
  error_present:Boolean(v?.error),unresolved_child_error:String(v?.error??'').includes('Prior child admission has unresolved identity')});
function check(value,label){if(!value)throw new Error(label);}
try{
  report.stage='DISK_BASELINE';
  check(path.basename(target)==='CodedbTest_2'&&eq(fs.realpathSync(target),target),'TARGET_ROOT_MISMATCH');
  const manifest=read(path.join(target,'Packages/manifest.json'),'manifest');
  const lock=read(path.join(target,'Packages/packages-lock.json'),'packages-lock');
  const ref=manifest.value.dependencies?.['com.rice.ai-codedb'];
  check(ref==='file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb','PACKAGE_REFERENCE_DRIFT');
  check(lock.value.dependencies?.['com.rice.ai-codedb']?.version===ref,'PACKAGE_LOCK_DRIFT');
  packageRoot=path.resolve(target,'Packages',ref.slice(5));
  check(eq(fs.realpathSync(packageRoot),packageRoot),'PACKAGE_REDIRECTED');
  const packageJson=read(path.join(packageRoot,'package.json'),'installed-package');
  check(packageJson.value.version==='0.3.0-preview.5','PACKAGE_VERSION_DRIFT');
  const script=path.join(packageRoot,'Tools~/codedb-project-supervisor.mjs');
  const sourceBytes=fs.readFileSync(script);
  const expectedBytes=execFileSync('git',['show','186aacf0371ba64e47114306170b449dbca261c9:com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs'],
    {cwd:repo,windowsHide:true,maxBuffer:1024*1024});
  report.package={reference_matches:true,version:packageJson.value.version,supervisor_sha256:sha(sourceBytes),accepted_source_match:sourceBytes.equals(expectedBytes)};
  check(report.package.accepted_source_match,'INSTALLED_SUPERVISOR_SOURCE_DRIFT');
  pointerPath=path.join(runtime,'control/current-instance.json');
  initialPointer=read(pointerPath,'selected-pointer');
  const pointer=initialPointer.value;
  check(pointer.project_identity==='sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c'
    &&pointer.instance_id==='a492a5e936c14e4da3ed7e4cc7c8c16c'
    &&pointer.activation_epoch==='063aa347f49a4b9f955a5447f293a0ac'&&pointer.generation_id==='poc.44'
    &&pointer.instance_relative_path===`AIWork/.runtime/codedb/instances/${pointer.instance_id}`,'SELECTED_BINDING_DRIFT');
  report.pointer=pick(pointer,['project_identity','instance_id','activation_epoch','generation_id']);
  const instanceRoot=path.join(target,pointer.instance_relative_path);
  const instance=read(path.join(instanceRoot,'instance.json'),'instance-manifest');
  check(instance.hash===pointer.instance_manifest_sha256,'INSTANCE_MANIFEST_HASH_MISMATCH');
  report.instance=pick(instance.value,['state','package_version','generation_id']);
  const controlRuntime=path.join(runtime,'control/contracts/v0.3-control/v2/supervisor');
  const stateRecord=read(path.join(controlRuntime,'supervisor-state.json'),'supervisor-state');
  const coordRecord=read(path.join(instanceRoot,'watch/coordinator/coordinator-state.json'),'coordinator-state');
  const state=stateRecord.value,coord=coordRecord.value;
  const currentOperation=read(path.join(controlRuntime,'operation.json'),'current-operation',true);
  const policy=read(path.join(instanceRoot,'watch/lifecycle/desired-state.json'),'desired-state',true);
  const manual=read(path.join(instanceRoot,'watch/lifecycle/manual-runtime.json'),'manual-runtime',true);
  report.lifecycle={policy:pick(policy?.value,['desired_state','project_identity']),manual:pick(manual?.value,['mode'])};
  report.disk={supervisor:{...pick(state,['supervisor_pid','supervisor_id','owner_epoch','lifecycle_id','selected_instance_id',
    'activation_epoch','readiness_state','reason_code','coordinator_failure_category']),operation:operation(state.operation)},
    current_operation:operation(currentOperation?.value),coordinator:pick(coord,['schema_version','generation_id','lifecycle_id',
      'coordinator_pid','provider_pid','provider_state','adapter_enabled','adapter_state','adapter_worker_state',
      'adapter_worker_pid','desired_state','editor_demand','editor_session_count','last_lease_scan_at_utc','started_at_utc','exclusive_lifecycle'])};
  // Original read-only validators, using the installed script's exact URL for
  // process invocation matching. File mutations are denied at the VM boundary.
  const fsNames=['existsSync','statSync','lstatSync','realpathSync','readFileSync','readdirSync','readlinkSync'];
  const readFs=Object.fromEntries(fsNames.map(k=>[k,fs[k].bind(fs)]));
  const guardedFs=new Proxy(readFs,{get:(obj,key)=>key in obj?obj[key]:(()=>{throw new Error('FS_MUTATION_OR_UNREVIEWED_ACCESS_BLOCKED');})});
  const allowedPipes=new Set([state.pipe_name,coord.pipe_name]);
  let phase='supervisor';
  const guardedNet={createConnection(pipe){
    check(allowedPipes.has(pipe),'UNREVIEWED_PIPE');
    const socket=net.createConnection(pipe),write=socket.write.bind(socket);
    socket.write=(line,...args)=>{
      const request=JSON.parse(String(line));check(request.command==='status','NON_STATUS_IPC_BLOCKED');
      const field=phase==='supervisor'?'supervisor_status':'coordinator_status';
      check(report.counts[field]===0,'STATUS_RETRY_BLOCKED');report.counts[field]++;
      return write(line,...args);
    };return socket;
  }};
  const guardedExec=(command,args,options,callback)=>{
    check(command==='powershell.exe'&&args.includes('-EncodedCommand'),'UNREVIEWED_PROCESS_PROBE');
    check(++report.counts.process_identity_probes<=2,'PROCESS_PROBE_BUDGET');
    return execFile(command,args,options,callback);
  };
  let code=sourceBytes.toString('utf8').replace(/^#!.*\r?\n/,'').replace(/^import .*;\r?\n/gm,'')
    .replace('const { command, options } = parseArgs(process.argv.slice(2));','const command=""; const options={};')
    .replaceAll('import.meta.url',JSON.stringify(pathToFileURL(script).href));
  check(/await main\(\);\s*$/.test(code),'UNREVIEWED_ENTRY_POINT');
  code=code.replace(/await main\(\);\s*$/,'')+'\n({buildContext,inspectExistingSupervisor,requestCoordinatorStatus,getProcessEvidence,pathsEqual,normalizeProcessArgv})';
  const api=vm.runInNewContext(code,{fs:guardedFs,path,crypto,net:guardedNet,execFile:guardedExec,
    spawn:()=>{throw new Error('SERVICE_START_BLOCKED');},fileURLToPath,Buffer,TextDecoder,URL,setTimeout,clearTimeout,
    process:{platform:process.platform,execPath:process.execPath,pid:process.pid}}, {timeout:3000});
  report.stage='ORIGINAL_CONTEXT_VALIDATION';
  const context=api.buildContext({root:target,runtime:controlRuntime,packageRoot,provider:coord.provider_executable,
    lifecycleId:state.lifecycle_id,supervisorId:state.supervisor_id,ownerEpoch:state.owner_epoch});
  report.stage='SUPERVISOR_OWNER_INSPECTION';
  const inspection=await api.inspectExistingSupervisor(context);
  report.supervisor_owner={classification:inspection.classification,
    authenticated_status:inspection.response?.ok===true,reason_sha256:inspection.reason?sha(Buffer.from(inspection.reason)):null,
    protocol_version:inspection.response?.status?.supervisor_protocol_version??null,
    status:pick(inspection.response?.status,['supervisor_pid','owner_epoch','lifecycle_id','selected_instance_id','activation_epoch','readiness_state','reason_code','coordinator_failure_category']),
    operational:pick(inspection.response?.status?.operational_readiness,['state','reason_code','observed_at_utc','revision']),
    operation:operation(inspection.response?.status?.operation)};
  check(['LIVE_AUTHENTICATED','TRANSITIONAL_AUTHENTICATED'].includes(inspection.classification)
    &&inspection.response?.ok===true,'SUPERVISOR_OWNER_NOT_ESTABLISHED');
  check(eq(coord.root,target)&&eq(coord.runtime,context.coordinatorRuntime)
    &&coord.generation_id===pointer.generation_id&&typeof coord.lifecycle_id==='string'
    &&/^\\\\\.\\pipe\\[^\\/]+$/.test(coord.pipe_name)&&/^[0-9a-f]{48}$/i.test(coord.auth_token),'COORDINATOR_DISK_BINDING_INVALID');
  report.stage='COORDINATOR_PROCESS_IDENTITY';
  const evidence=await api.getProcessEvidence(coord.coordinator_pid);
  const argv=evidence.normalizedArgv??[],values=Object.fromEntries(Array.from({length:Math.max(0,Math.floor((argv.length-2)/2))},(_,i)=>argv.slice(2+i*2,4+i*2)));
  const expectedScript=path.join(context.selectedInstance.generationRoot,'coordinator/codedb-watch-coordinator.mjs');
  const commandMatches=evidence.available&&evidence.exists&&api.pathsEqual(evidence.executablePath,process.execPath)
    &&argv[0]===api.normalizeProcessArgv([expectedScript])[0]&&argv[1]==='daemon'
    &&api.pathsEqual(values['--root'],target)&&api.pathsEqual(values['--runtime'],context.coordinatorRuntime)
    &&api.pathsEqual(values['--provider'],coord.provider_executable)&&api.pathsEqual(values['--config'],coord.provider_config)
    &&values['--generation-id']===coord.generation_id&&values['--lifecycle-id']===coord.lifecycle_id;
  report.coordinator_process={...pick(evidence,['available','exists','pid','processStartIdentity']),invocation_matches_disk:commandMatches};
  check(commandMatches,'COORDINATOR_PROCESS_BINDING_NOT_ESTABLISHED');
  phase='coordinator';
  report.stage='COORDINATOR_AUTHENTICATED_STATUS';
  const status=await api.requestCoordinatorStatus(context);
  check(status!=null,'COORDINATOR_AUTH_STATUS_UNAVAILABLE');
  const identityMatch=status.coordinator_pid===coord.coordinator_pid&&status.lifecycle_id===coord.lifecycle_id
    &&status.generation_id===coord.generation_id&&eq(status.root,target)&&eq(status.runtime,context.coordinatorRuntime)
    &&eq(status.provider_executable,coord.provider_executable)&&eq(status.provider_config,coord.provider_config);
  report.coordinator_authenticated={identity_matches_disk:identityMatch,
    status:pick(status,['coordinator_pid','generation_id','lifecycle_id','provider_state','adapter_enabled','adapter_state',
      'adapter_worker_state','adapter_worker_pid','desired_state','editor_demand','editor_session_count','exclusive_lifecycle']),
    query_shape:{watch_config:eq(status.provider_config,path.join(instanceRoot,'config/codedb-mcp.watch.toml')),
      adapter_manifest:eq(status.adapter_manifest,path.join(instanceRoot,'adapter/text-index/manifest.json'))}};
  check(identityMatch,'COORDINATOR_AUTH_IDENTITY_CONFLICT');
  const current=inspection.response.status.operation??currentOperation?.value;
  report.owner_preflight='ESTABLISHED_AT_CAPTURE';
  report.retirement_admission=current?.state==='running'||current?.state==='queued'?'BLOCKED_ACTIVE_OPERATION':
    current?.execution_disposition==='CHILD_ADMITTED'&&current?.child==null?'BLOCKED_UNRESOLVED_CHILD':
    'NO_RECORDED_ACTIVE_OPERATION; original admission must still recheck before any later mutation';
  report.status='COMPLETE_READ_ONLY';
  report.stage='COMPLETE';
}catch(e){
  report.status='STOPPED_FIRST_ANOMALY';
  const message=String(e?.message??e);report.stop_code=/^[A-Z0-9_]+$/.test(message)?message:'READ_OR_VALIDATION_FAILURE';
  report.error_type=e?.name??'Error';report.error_sha256=sha(Buffer.from(message));
}finally{
  if(initialPointer&&pointerPath){try{const end=read(pointerPath,'selected-pointer-final');report.pointer_bytes_stable=end.hash===initialPointer.hash;}
    catch{report.pointer_bytes_stable=false;}if(!report.pointer_bytes_stable){report.status='STOPPED_FIRST_ANOMALY';report.stop_code='POINTER_CHANGED_OR_UNAVAILABLE';}}
  report.ended_at_utc=new Date().toISOString();
  const parent=path.join(repo,'.artifacts/tests/s42-ownership');fs.mkdirSync(parent,{recursive:true});
  check(inside(fs.realpathSync(parent),fs.realpathSync(repo)),'OUTPUT_ESCAPED');
  const output=path.join(parent,started.replace(/[:.]/g,'-')+'-'+crypto.randomBytes(3).toString('hex'));
  fs.mkdirSync(output);const filename=path.join(output,'report.json');
  fs.writeFileSync(filename,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify({artifact:path.relative(repo,filename).replaceAll('\\','/'),sha256:sha(fs.readFileSync(filename)),report}));
}
