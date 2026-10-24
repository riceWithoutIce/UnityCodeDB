import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
import {retireOnce} from './retire-once.mjs';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../../..');
const run=process.argv[2]??'s42retfixture-a';assert.match(run,/^s42retfixture-[a-z]$/);
const root=path.join(repo,'.artifacts/tests',run);
assert.equal(fs.existsSync(root),false,'Preserve earlier evidence');fs.mkdirSync(root,{recursive:true});
const cases=[];
const fresh=()=>{
  let time=0;const requests=[];let sequence=0;
  const owner={ownerEpoch:'epoch',coordinatorLifecycle:'expected-lifecycle',identity:{instance_id:'instance'}};
  let actionId;
  const response=(pending=true)=>({ok:true,accepted:true,pending,operation_id:'a'.repeat(32),status:{owner:'epoch'},
    operation:{operation_id:'a'.repeat(32),manager_action_id:actionId,name:'watcher:Stop',owner_epoch:'epoch',state:pending?'queued':'completed'},
    result:pending?null:{exit_code:0,timed_out:false,output_overflow:false,output_drain_incomplete:false}});
  const io={inspect:async()=>owner,newId:()=> (++sequence).toString(16).padStart(32,'0'),assertSelection:()=>{},now:()=>time,
    pause:async ms=>{time+=ms;},safeCode:s=>/^[A-Z_]+$/.test(s)?s:'ERROR',
    request:async r=>{requests.push(r);if(r.command==='watcher'){actionId=r.manager_action_id;return response();}return response(false);},
    validateOwner:s=>{if(s?.owner!=='epoch')throw new Error('OWNER_CHANGED');},
    verifyStopped:async()=>({recorded_process_absent:true,coordinator_state_absent:true,manual_stopped:true})};
  return {io,owner,requests,response,setAction:id=>{actionId=id;}};
};
{
 const f=fresh();const result=await retireOnce(f.io,{});
 assert.equal(result.status,'OWNED_STOP_CONFIRMED');assert.equal(result.stop_requests,1);assert.equal(result.operation_reads,1);
 assert.equal(f.requests[0].expected_lifecycle_id,'expected-lifecycle');assert.equal(f.requests[1].operation_id,'a'.repeat(32));
 cases.push('one explicit-lifecycle Stop, queued operation -> correlated terminal -> postcondition');
}
for(const scenario of ['reject','lost_reply','owner_change','operation_change','failed_terminal','selection_change','timeout','postcondition']) {
 const f=fresh();const normal=f.io.request;
 if(scenario==='selection_change')f.io.assertSelection=()=>{throw new Error('SELECTION_CHANGED');};
 else if(scenario==='reject')f.io.request=async r=>{f.requests.push(r);return {ok:false,accepted:false,status:{owner:'epoch'},error_code:'SUPERVISOR_QUEUE_FULL'};};
 else if(scenario==='lost_reply')f.io.request=async r=>{f.requests.push(r);return null;};
 else if(scenario==='postcondition')f.io.verifyStopped=async()=>({recorded_process_absent:false,coordinator_state_absent:false,manual_stopped:true});
 else f.io.request=async r=>{
   const response=await normal(r);
   if(scenario==='owner_change')response.status.owner='different';
   if(scenario==='operation_change'&&r.command==='operation')response.operation_id='b'.repeat(32);
   if(scenario==='failed_terminal'&&!response.pending)response.result.exit_code=1;
   if(scenario==='timeout'){response.pending=true;response.operation.state='queued';response.result=null;}
   return response;
 };
 const result=await retireOnce(f.io,{});assert.equal(result.status,'STOPPED_NO_REPLAY',scenario);
 assert.ok(f.requests.filter(r=>r.command==='watcher').length<=1,scenario);
 if(scenario==='timeout'){assert.equal(result.operation_reads,90);assert.equal(result.stop_code,'OBSERVATION_BUDGET_EXHAUSTED_NO_REPLAY');}
 cases.push(scenario+' stops without replay');
}
// Exercise original admission/forwarder functions rather than a copied queue.
const sourcePath=path.join(repo,'.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract/com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs');
const source=fs.readFileSync(sourcePath,'utf8');
const extract=name=>{const lines=source.split(/\r?\n/),start=lines.findIndex(l=>new RegExp(`^(?:async )?function ${name}\\(`).test(l));
 const end=lines.findIndex((l,i)=>i>start&&/^(?:async )?function |^await main\(/.test(l));assert.ok(start>=0&&end>start);return lines.slice(start,end).join('\n');};
const admit=source.slice(source.indexOf('  const admitMaintenance = ('),source.indexOf('  const dispatch = async'));
assert.ok(admit.length>1000);
const pending=[],scheduled=[],remembered=[],launches=[];
const active={operation_id:'c'.repeat(32),key:'probe',name:'materialize:Probe',state:'running'};
const context={ownerEpoch:'epoch',root:path.join(root,'project'),runtime:path.join(root,'project/runtime'),projectIdentity:'project',
  selectedInstance:{instanceId:'instance'},selectedGenerationId:'generation',runtimeContractSha256:'contract',
  watchManager:path.join(root,'generation/scripts/manage-codedb-project-watch.ps1'),lifecycleId:'supervisor-lifecycle'};
const scope={crypto,context,pendingMaintenance:pending,queuedMaintenanceByKey:new Map(),activeOperation:active,
 state:{},coordinatorStatus:null,statePublicationError:null,shuttingDown:false,retirementReason:'',MAX_PENDING_MAINTENANCE_REQUESTS:1,EVIDENCE_SCHEMA_VERSION:1,
 validId:v=>/^[A-Za-z0-9._-]+$/.test(v)?v:null,publicStatus:()=>({}),rememberOperation:v=>remembered.push(v),
 scheduleRequestQueue:()=>scheduled.push(true),operationResponse:v=>({accepted:true,pending:true,operation_id:v.operation_id,operation:v}),
 process:{platform:'win32'},prepareOperationChildEvidence:async()=>{},queueChildEvidenceCapture:()=>{},
 runChild:async(command,args)=>{launches.push({command,args});return {code:0};}};
const producer=vm.runInNewContext(extract('publicOperation')+'\n'+extract('maintenanceOperationKey')+'\n'+extract('runWatchManager')+'\n'+admit+'\n({admitMaintenance,runWatchManager})',scope);
const request={action:'Stop',expected_lifecycle_id:'expected-lifecycle',manager_action_id:'unique-action',request_id:'request'};
const admitted=producer.admitMaintenance('watcher:Stop',request,()=>{});
assert.equal(admitted.accepted,true);assert.equal(pending.length,1);assert.equal(active.state,'running');assert.equal(launches.length,0);
assert.equal(pending[0].value.state,'queued');assert.equal(remembered.length,1);assert.equal(scheduled.length,1);
const refused=producer.admitMaintenance('watcher:Start',{action:'Start'},()=>{});
assert.equal(refused.error_code,'SUPERVISOR_QUEUE_FULL');assert.equal(pending.length,1);
await producer.runWatchManager(context,'Stop',request,null);
assert.equal(launches.length,1);const args=launches[0].args;
assert.equal(args[args.indexOf('-ExpectedLifecycleId')+1],'expected-lifecycle');assert.equal(args.includes('-LifecycleId'),false);
cases.push('original admission queues behind Probe, refuses full queue, actual forwarder preserves expected lifecycle');
const result={evidence:'OFFLINE_CLIENT_AND_ORIGINAL_PRODUCER_HARNESS',cases,live_rpc:0,real_child_starts:0,
 source_sha256:crypto.createHash('sha256').update(source).digest('hex')};
fs.writeFileSync(path.join(root,'result.json'),JSON.stringify(result,null,2)+'\n');
console.log(`PASS ${cases.length} retirement-client groups; live RPC=0; original admission and forwarder exercised.`);
