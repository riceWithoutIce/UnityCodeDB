// Read one known operation's persisted evidence; never import product code.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const task=path.dirname(fileURLToPath(import.meta.url));
const repo=path.resolve(task,'../../../..');
const target=path.resolve(process.argv[2]??'');
const check=(v,c)=>{if(!v)throw new Error(c);};
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const safe=v=>typeof v==='string'&&/^[a-zA-Z0-9_:.,-]{1,180}$/.test(v)?v:null;
check(process.argv.length===3&&path.basename(target)==='CodedbTest_2','WRONG_TARGET');
check(fs.realpathSync(target).toLowerCase()===target.toLowerCase(),'TARGET_REDIRECTED');
const runtime=path.join(target,'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor');
const pointerPath=path.join(target,'AIWork/.runtime/codedb/control/current-instance.json');
const pointerBefore=fs.readFileSync(pointerPath);
check(hash(pointerBefore)==='1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a','SELECTION_CHANGED');
const id='cbe070b2575946efb75ad8eaef555b61';
const operationPath=path.join(runtime,'operation-history',id+'.json');
const report={started_at_utc:new Date().toISOString(),kind:'PERSISTED_OPERATION_ONLY',operation_id:id,
  ipc_requests:0,process_probes:0,maintenance_requests:0};
check(fs.realpathSync(operationPath).toLowerCase()===operationPath.toLowerCase(),'OPERATION_REDIRECTED');
const bytes=fs.readFileSync(operationPath);check(bytes.length<1024*1024,'OPERATION_TOO_LARGE');
const op=JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''));
check(op.operation_id===id&&op.owner_epoch==='7960ba8ac54541dcb54a1d767ae2fd16'
  &&op.name==='watcher:Stop'&&op.selected_instance_id==='a492a5e936c14e4da3ed7e4cc7c8c16c'
  &&op.project_identity==='sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c','OPERATION_BINDING_CHANGED');
const sourcePath=path.resolve(target,'../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs');
const sourceBytes=fs.readFileSync(sourcePath);
check(hash(sourceBytes)==='6a076ce6cfbf73c87f271ad42db85657d6793352f366b0adc2da63ad1ad122d8','SOURCE_CHANGED');
const source=sourceBytes.toString('utf8');
const texts=[op.error,op.result?.stdout,op.result?.stderr].filter(v=>typeof v==='string');
const joined=texts.join('\n');
const matches=[];
for(const m of source.matchAll(/new Error\("([^"\r\n]{12,})"\)/g)){
  if(joined.includes(m[1]))matches.push({source_line:source.slice(0,m.index).split('\n').length,static_literal_sha256:hash(m[1])});
}
const diagnostic={
  static_supervisor_errors:matches,
  error_codes:[...new Set(joined.match(/\b[A-Z][A-Z0-9_]{5,90}\b/g)??[])].slice(0,30),
  powershell_fully_qualified_error_ids:[...joined.matchAll(/FullyQualifiedErrorId\s*:\s*([A-Za-z0-9_.-]+(?:,[A-Za-z0-9_.-]+)*)/g)].map(m=>m[1]),
  powershell_categories:[...joined.matchAll(/CategoryInfo\s*:\s*([A-Za-z]+)/g)].map(m=>m[1]),
  exception_types:[...new Set(joined.match(/\b[A-Za-z][A-Za-z0-9]*(?:Exception|Error)\b/g)??[])].slice(0,20),
  parameter_names:[...joined.matchAll(/(?:parameter(?: named)?|ParameterName)\s*[:=]?\s*['"]([A-Za-z][A-Za-z0-9_-]*)['"]/gi)].map(m=>m[1]),
  mentions_expected_lifecycle:joined.includes('ExpectedLifecycleId'),
  mentions_child_identity:/child identity/i.test(joined),
  stdout_bytes:Buffer.byteLength(op.result?.stdout??''),stderr_bytes:Buffer.byteLength(op.result?.stderr??''),
  stdout_sha256:hash(op.result?.stdout??''),stderr_sha256:hash(op.result?.stderr??''),error_sha256:hash(op.error??'')
};
report.operation_sha256=hash(bytes);
report.operation={};
for(const key of ['state','phase','execution_disposition','error_code','owner_epoch','manager_action_id','selected_instance_id','selected_generation_id','runtime_contract_sha256','created_at_utc','queued_at_utc','started_at_utc','completed_at_utc'])report.operation[key]=safe(op[key]);
report.result=op.result?{exit_code:op.result.exit_code,timed_out:op.result.timed_out,output_overflow:op.result.output_overflow,output_drain_incomplete:op.result.output_drain_incomplete}:null;
report.child=op.child?{pid:op.child.pid,process_start_identity:safe(op.child.process_start_identity),argv_sha256:safe(op.child.argv_sha256),command_line_sha256:safe(op.child.command_line_sha256)}:null;
report.diagnostic=diagnostic;
const pointerAfter=fs.readFileSync(pointerPath);
report.pointer_sha256_before=hash(pointerBefore);report.pointer_sha256_after=hash(pointerAfter);
check(pointerBefore.equals(pointerAfter),'SELECTION_CHANGED_DURING_READ');
report.ended_at_utc=new Date().toISOString();
const out=path.join(repo,'.artifacts/tests/s42-stop-diagnosis',new Date().toISOString().replace(/[:.]/g,'-'));
fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({report:path.relative(repo,path.join(out,'report.json')).replaceAll('\\','/'),...report},null,2));
