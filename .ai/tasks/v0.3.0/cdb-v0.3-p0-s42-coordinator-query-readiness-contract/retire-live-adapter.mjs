// Preparation only until a later explicit human runtime grant. No default mode.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import net from 'node:net';
import vm from 'node:vm';
import {execFile} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {retireOnce} from './retire-once.mjs';
const task=path.dirname(fileURLToPath(import.meta.url));
const repo=path.resolve(task,'../../../..');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const equal=(a,b)=>typeof a==='string'&&typeof b==='string'&&path.resolve(a).replaceAll('\\','/').toLowerCase()===path.resolve(b).replaceAll('\\','/').toLowerCase();
const check=(v,c)=>{if(!v)throw new Error(c);};
const safeCode=v=>typeof v==='string'&&/^[A-Z0-9_]{1,100}$/.test(v)?v:'VALIDATION_OR_TRANSPORT_FAILURE';
const json=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
check(process.argv[2]==='--execute-approved'&&process.argv.length===4,'EXPLICIT_APPROVAL_FILE_REQUIRED');
// Human approval is recorded by the development session; this file is a binding,
// not an alternate way for the script to obtain authorization from disk.
const grant=json(path.resolve(process.argv[3]));
check(grant.action==='S42_ONE_OWNED_STOP'&&grant.human_authorized===true,'WRONG_APPROVAL_ACTION');
check(Date.now()-Date.parse(grant.approved_at_utc)>=0&&Date.now()-Date.parse(grant.approved_at_utc)<15*60*1000,'APPROVAL_EXPIRED');
for(const name of ['retire-once.mjs','retire-live-adapter.mjs'])check(hash(fs.readFileSync(path.join(task,name)))===grant.scripts?.[name],'APPROVED_SCRIPT_DRIFT');
const target=path.resolve(grant.project_root);
check(path.basename(target)==='CodedbTest_2'&&equal(fs.realpathSync(target),target),'WRONG_TARGET');
const pointerPath=path.join(target,'AIWork/.runtime/codedb/control/current-instance.json');
const runtime=path.join(target,'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor');
const coordinatorPath=path.join(target,'AIWork/.runtime/codedb/instances',grant.instance_id,'watch/coordinator/coordinator-state.json');
const outputRoot=path.join(repo,'.artifacts/tests/s42-retirement');fs.mkdirSync(outputRoot,{recursive:true});
check(equal(fs.realpathSync(outputRoot),outputRoot),'OUTPUT_REDIRECTED');
const output=path.join(outputRoot,new Date().toISOString().replace(/[:.]/g,'-')+'-'+crypto.randomBytes(3).toString('hex'));
fs.mkdirSync(output);fs.writeFileSync(path.join(output,'approval.json'),JSON.stringify(grant,null,2)+'\n',{flag:'wx'});
let api,state,coord,context,stopWrites=0,inspectionStatusWrites=0,operationWrites=0,processProbes=0;
const trace=[];
const receipt=value=>fs.writeFileSync(path.join(output,'receipt.json'),JSON.stringify(value,null,2)+'\n');
const assertSelection=()=>{
  const b=fs.readFileSync(pointerPath);check(hash(b)===grant.pointer_sha256,'SELECTION_CHANGED');
  const p=JSON.parse(b);check(p.instance_id===grant.instance_id&&p.activation_epoch===grant.activation_epoch
    &&p.project_identity===grant.project_identity,'SELECTED_IDENTITY_CHANGED');
};
const io={newId:()=>crypto.randomUUID().replaceAll('-',''),now:()=>Date.now(),pause:ms=>new Promise(r=>setTimeout(r,ms)),safeCode,assertSelection,
  async inspect(){
    assertSelection();
    const reference=json(path.join(target,'Packages/manifest.json')).dependencies?.['com.rice.ai-codedb'];
    check(reference===grant.old_package_reference&&reference==='file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb','PACKAGE_REFERENCE_CHANGED');
    check(json(path.join(target,'Packages/packages-lock.json')).dependencies?.['com.rice.ai-codedb']?.version===reference,'LOCK_REFERENCE_CHANGED');
    const packageRoot=path.resolve(target,'Packages',reference.slice(5));check(equal(fs.realpathSync(packageRoot),packageRoot),'PACKAGE_REDIRECTED');
    const script=path.join(packageRoot,'Tools~/codedb-project-supervisor.mjs');const bytes=fs.readFileSync(script);
    check(hash(bytes)==='6a076ce6cfbf73c87f271ad42db85657d6793352f366b0adc2da63ad1ad122d8','INSTALLED_SOURCE_CHANGED');
    state=json(path.join(runtime,'supervisor-state.json'));coord=json(coordinatorPath);
    check(state.owner_epoch===grant.supervisor_owner_epoch&&state.lifecycle_id===grant.supervisor_lifecycle_id,'SUPERVISOR_OWNER_CHANGED');
    check(coord.coordinator_pid===grant.coordinator_pid&&coord.lifecycle_id===grant.coordinator_lifecycle_id,'COORDINATOR_OWNER_CHANGED');
    const readFs=Object.fromEntries(['existsSync','statSync','lstatSync','realpathSync','readFileSync','readdirSync','readlinkSync'].map(k=>[k,fs[k].bind(fs)]));
    const guardedFs=new Proxy(readFs,{get:(o,k)=>k in o?o[k]:(()=>{throw new Error('PRODUCT_FILESYSTEM_MUTATION_BLOCKED');})});
    const guardedNet={createConnection(pipe){
      check(pipe===state.pipe_name||pipe===coord.pipe_name,'PIPE_NOT_REVIEWED');
      const socket=net.createConnection(pipe),write=socket.write.bind(socket);
      socket.write=(line,...args)=>{
        const r=JSON.parse(String(line));
        if(r.command==='watcher') {
          check(pipe===state.pipe_name&&r.action==='Stop'&&r.expected_lifecycle_id===grant.coordinator_lifecycle_id,'UNBOUND_STOP_BLOCKED');
          check(++stopWrites===1,'STOP_REPLAY_BLOCKED');
        }else if(r.command==='operation'){check(pipe===state.pipe_name&&++operationWrites<=90,'OPERATION_BUDGET');}
        else{check(r.command==='status'&&++inspectionStatusWrites<=2,'UNREVIEWED_IPC_BLOCKED');}
        trace.push({command:r.command,action:r.action??null,expected_lifecycle_id:r.expected_lifecycle_id??null,at_utc:new Date().toISOString()});
        // Journal before dispatch: loss of reply must never cause replay.
        receipt({state:'IN_PROGRESS',stop_writes:stopWrites,operation_reads:operationWrites,trace});
        return write(line,...args);
      };return socket;
    }};
    const guardedExec=(command,args,options,cb)=>{
      check(command==='powershell.exe'&&args.includes('-EncodedCommand')&&++processProbes<=3,'PROCESS_PROBE_BUDGET');
      return execFile(command,args,options,cb);
    };
    let code=bytes.toString('utf8').replace(/^#!.*\r?\n/,'').replace(/^import .*;\r?\n/gm,'')
      .replace('const { command, options } = parseArgs(process.argv.slice(2));','const command="";const options={};')
      .replaceAll('import.meta.url',JSON.stringify(pathToFileURL(script).href));
    check(/await main\(\);\s*$/.test(code),'ENTRY_POINT_DRIFT');
    code=code.replace(/await main\(\);\s*$/,'')+'\n({buildContext,inspectExistingSupervisor,requestCoordinatorStatus,getProcessEvidence,requestPipe,authenticatedStatusMatches,stableSupervisorIdentityMatches,normalizeProcessArgv,pathsEqual})';
    api=vm.runInNewContext(code,{fs:guardedFs,path,crypto,net:guardedNet,execFile:guardedExec,spawn:()=>{throw new Error('CLIENT_SPAWN_BLOCKED');},
      fileURLToPath,Buffer,TextDecoder,URL,setTimeout,clearTimeout,process:{platform:process.platform,execPath:process.execPath,pid:process.pid}},{timeout:3000});
    context=api.buildContext({root:target,runtime,packageRoot,provider:coord.provider_executable,lifecycleId:state.lifecycle_id,supervisorId:state.supervisor_id,ownerEpoch:state.owner_epoch});
    const inspected=await api.inspectExistingSupervisor(context);
    check(['LIVE_AUTHENTICATED','TRANSITIONAL_AUTHENTICATED'].includes(inspected.classification)&&inspected.response?.ok,'SUPERVISOR_AUTHENTICATION_FAILED');
    const processEvidence=await api.getProcessEvidence(coord.coordinator_pid);
    check(processEvidence.available&&processEvidence.exists&&processEvidence.processStartIdentity===grant.coordinator_process_start_identity,'COORDINATOR_PROCESS_CHANGED');
    const argv=processEvidence.normalizedArgv??[],values=Object.fromEntries(Array.from({length:Math.floor((argv.length-2)/2)},(_,i)=>argv.slice(2+i*2,4+i*2)));
    check(api.pathsEqual(processEvidence.executablePath,process.execPath)&&argv[0]===api.normalizeProcessArgv([context.coordinatorScript])[0]&&argv[1]==='daemon'
      &&api.pathsEqual(values['--root'],target)&&api.pathsEqual(values['--runtime'],context.coordinatorRuntime)
      &&api.pathsEqual(values['--provider'],coord.provider_executable)&&api.pathsEqual(values['--config'],coord.provider_config)
      &&values['--generation-id']===context.generationId&&values['--lifecycle-id']===coord.lifecycle_id,'COORDINATOR_INVOCATION_CHANGED');
    const status=await api.requestCoordinatorStatus(context);
    check(status&&status.coordinator_pid===coord.coordinator_pid&&status.lifecycle_id===coord.lifecycle_id&&status.generation_id===context.generationId
      &&api.pathsEqual(status.root,target)&&api.pathsEqual(status.runtime,context.coordinatorRuntime)
      &&api.pathsEqual(status.provider_executable,coord.provider_executable)&&api.pathsEqual(status.provider_config,coord.provider_config),'COORDINATOR_AUTHENTICATION_FAILED');
    assertSelection();
    return {coordinatorLifecycle:status.lifecycle_id,ownerEpoch:state.owner_epoch,identity:{instance_id:grant.instance_id,
      activation_epoch:grant.activation_epoch,supervisor_owner_epoch:state.owner_epoch,coordinator_pid:coord.coordinator_pid,coordinator_lifecycle_id:status.lifecycle_id}};
  },
  request:r=>api.requestPipe(state,r,1500),
  validateOwner:status=>check(api.stableSupervisorIdentityMatches(state,status),'RESPONSE_OWNER_CHANGED'),
  async verifyStopped(){
    const p=await api.getProcessEvidence(coord.coordinator_pid);
    const manual=path.join(path.dirname(path.dirname(coordinatorPath)),'lifecycle/manual-runtime.json');
    let manualStopped=false;try{manualStopped=json(manual).mode==='stopped';}catch{}
    return {recorded_process_absent:p.available===true&&p.exists===false,coordinator_state_absent:!fs.existsSync(coordinatorPath),manual_stopped:manualStopped};
  }};
const result=await retireOnce(io,grant);
receipt({...result,trace,stop_writes:stopWrites,operation_reads:operationWrites,process_probes:processProbes,ended_at_utc:new Date().toISOString()});
console.log(JSON.stringify({status:result.status,stop_code:result.stop_code??null,receipt:path.relative(repo,path.join(output,'receipt.json')).replaceAll('\\','/')}));
if(result.status!=='OWNED_STOP_CONFIRMED')process.exitCode=1;
