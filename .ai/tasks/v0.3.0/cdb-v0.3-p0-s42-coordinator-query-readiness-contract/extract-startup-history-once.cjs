const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const repo=process.cwd(),project=path.resolve(process.argv[2]??'');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const start=Date.now(),lo=Date.parse('2026-10-22T06:26:02.409Z'),hi=Date.parse('2026-10-22T06:33:53.622Z');
const report={status:'IN_PROGRESS',reads:[],window_utc:['2026-10-22T06:26:02.409Z','2026-10-22T06:33:53.622Z'],counts:{rpc:0,codedb:0,process_probes:0,consumer_writes:0},started_at_utc:new Date().toISOString()};
const check=(v,c)=>{if(!v)throw Error(c);};
const code=v=>typeof v==='string'&&/^[A-Za-z0-9_.:-]{1,100}$/.test(v)?v:null;
const id=v=>typeof v==='string'&&/^[a-f0-9]{32}$/i.test(v)?v:null;
const inWindow=v=>Number.isFinite(Date.parse(v))&&Date.parse(v)>=lo&&Date.parse(v)<=hi;
function budget(){check(Date.now()-start<20000,'TIME_BUDGET');}
function noRedirect(p){for(let q=path.resolve(p);;q=path.dirname(q)){if(fs.existsSync(q))check(!fs.lstatSync(q).isSymbolicLink(),'REDIRECTED_PATH');if(path.dirname(q)===q)break;}}
function read(p,label,max,optional=false){
 budget();noRedirect(p);let fd;
 try{fd=fs.openSync(p,'r');}catch(e){if(optional&&e.code==='ENOENT'){report.reads.push({record:label,status:'MISSING'});return null;}throw e;}
 try{const s=fs.fstatSync(fd);check(s.isFile()&&s.size<=max,'FILE_SIZE_OR_KIND');const b=Buffer.alloc(s.size);let n=0;
  while(n<b.length){budget();const k=fs.readSync(fd,b,n,b.length-n,n);check(k>0,'PREFIX_TRUNCATED');n+=k;}
  report.reads.push({record:label,status:'PREFIX_READ',bytes:b.length,sha256:sha(b)});return b;
 }finally{fs.closeSync(fd);}
}
function json(b){return JSON.parse(b.toString('utf8').replace(/^\uFEFF/,''));}
try{
 check(path.basename(project)==='CodedbTest_2'&&process.argv.length===3,'TARGET_ARGUMENT');noRedirect(project);
 const sup=path.join(project,'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor');
 const eventBytes=read(path.join(sup,'supervisor-events.jsonl'),'supervisor-events',1024*1024);
 const text=eventBytes.toString('utf8'),lines=text.split(/\r?\n/);check(lines.length<=10000,'EVENT_LINE_BUDGET');
 const incomplete=!text.endsWith('\n');if(incomplete)lines.pop();
 const events=lines.filter(Boolean).map(s=>JSON.parse(s)).filter(v=>inWindow(v.at_utc));check(events.length<=128,'MATCHING_EVENT_BUDGET');
 report.events={incomplete_final_line:incomplete,matched:events.map(v=>({sequence:v.sequence,at_utc:v.at_utc,event:code(v.event),
   operation_name:/^(materialize|watcher|maintenance):[A-Za-z]+$/.test(v.detail??'')?v.detail:null,
   detail_sha256:sha(String(v.detail??'')),detail_matches_target:String(v.detail??'').replaceAll('\\','/').toLowerCase()===project.replaceAll('\\','/').toLowerCase(),
   ipc_timeout_marker:/SUPERVISOR_IPC_TIMEOUT|Supervisor IPC request timed out/.test(v.detail??'')}))};
 const error=read(path.join(sup,'supervisor-error.json'),'supervisor-error',65536,true);
 if(error){const v=json(error);report.error={in_window:inWindow(v.created_at_utc),created_at_utc:v.created_at_utc,message_sha256:sha(String(v.message??'')),ipc_timeout_marker:/SUPERVISOR_IPC_TIMEOUT|Supervisor IPC request timed out/.test(v.message??'')};}
 const history=path.join(sup,'operation-history');noRedirect(history);const names=fs.readdirSync(history);check(names.length<=256,'HISTORY_FILE_BUDGET');
 const ops=[];let total=0;const allTimes=[];
 for(const name of names){check(/^[a-f0-9]{32}\.json$/i.test(name),'HISTORY_FILENAME');
  const bytes=read(path.join(history,name),'operation-history/'+name,256*1024);total+=bytes.length;check(total<=4*1024*1024,'HISTORY_BYTE_BUDGET');const v=json(bytes);
  if(v.started_at_utc)allTimes.push(v.started_at_utc);
  if(!inWindow(v.started_at_utc)&&!inWindow(v.completed_at_utc))continue;
  check(id(v.operation_id)===name.slice(0,-5)&&v.project_identity==='sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c'
   &&v.selected_instance_id==='a492a5e936c14e4da3ed7e4cc7c8c16c','HISTORY_BINDING');
  ops.push({operation_id:id(v.operation_id),request_id:id(v.request_id),owner_epoch:id(v.owner_epoch),name:code(v.name),state:code(v.state),phase:code(v.phase),
   started_at_utc:v.started_at_utc??null,completed_at_utc:v.completed_at_utc??null,error_code:code(v.error_code),execution_disposition:code(v.execution_disposition),
   exit_code:v.result?.exit_code??null,timed_out:v.result?.timed_out??null,child_pid:v.child?.pid??null,error_sha256:sha(String(v.error??'')),
   ipc_timeout_marker:/SUPERVISOR_IPC_TIMEOUT|Supervisor IPC request timed out/.test(String(v.error??'')+String(v.result?.stderr??''))});
 }
 check(ops.length<=64,'MATCHING_OPERATION_BUDGET');ops.sort((a,b)=>String(a.started_at_utc).localeCompare(String(b.started_at_utc)));allTimes.sort();
 report.operations={enumerated:names.length,total_bytes:total,earliest_retained_start:allTimes[0]??null,latest_retained_start:allTimes.at(-1)??null,matched:ops};
 check(Boolean(process.env.LOCALAPPDATA),'LOCALAPPDATA_MISSING');
 const editorBytes=read(path.join(process.env.LOCALAPPDATA,'Unity/Editor/Editor.log'),'Editor.log',8*1024*1024,true);
 if(editorBytes){const editorLines=editorBytes.toString('utf8').split(/\r?\n/);check(editorLines.length<=100000,'EDITOR_LINE_BUDGET');
  const targetPath=project.replaceAll('\\','/').toLowerCase(),pathLines=[],errors=[],transitions=[];let previousKey=null;
  for(let i=0;i<editorLines.length;i++){budget();const line=editorLines[i];if(line.replaceAll('\\','/').toLowerCase().includes(targetPath))pathLines.push(i+1);
   const matches=line.match(/SUPERVISOR_IPC_TIMEOUT|SUPERVISOR_OUTCOME_UNCONFIRMED|The Supervisor IPC request timed out\.|CodeDB Editor lifecycle reconcile failed/g);
   if(matches)errors.push({line:i+1,codes:[...new Set(matches)],line_sha256:sha(line),explicit_timestamp:line.match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z/)?.[0]??null});
   const at=line.indexOf('CODEDB_S12_EVIDENCE ');if(at<0)continue;const v=JSON.parse(line.slice(at+'CODEDB_S12_EVIDENCE '.length));
   if(v.selected_instance_id!=='a492a5e936c14e4da3ed7e4cc7c8c16c'&&v.supervisor_pid!==42020)continue;
   const key=[v.last_product_state,v.supervisor_pid,v.coordinator_pid].join(':');if(key===previousKey)continue;previousKey=key;
   if(transitions.length<64)transitions.push({line:i+1,checkpoint:code(v.checkpoint),product_state:code(v.last_product_state),supervisor_pid:v.supervisor_pid,coordinator_pid:v.coordinator_pid,
    reconcile_started_count:v.reconcile_started_count,reconcile_completed_count:v.reconcile_completed_count,supervisor_identity_change_count:v.supervisor_identity_change_count,
    post_admission_disposition:code(v.post_admission_disposition),line_sha256:sha(line)});
  }
  report.editor={line_count:editorLines.length,target_path_present:pathLines.length>0,target_path_first_line:pathLines[0]??null,target_path_matches:pathLines.length,
   matching_error_count:errors.length,errors:errors.length<=64?errors:[...errors.slice(0,32),...errors.slice(-32)],errors_truncated:errors.length>64,
   lifecycle_state_owner_transitions:transitions,time_attribution:'Only explicit timestamps can establish membership of the historical window; line order alone cannot.'};
 }
 budget();report.status='COMPLETE_HISTORICAL_EXTRACTION';
}catch(e){report.status='STOPPED_FIRST_ANOMALY';report.stop_code=/^[A-Z0-9_]+$/.test(e.message)?e.message:'READ_OR_PARSE_FAILURE';report.error_sha256=sha(String(e.message));}
report.ended_at_utc=new Date().toISOString();report.elapsed_ms=Date.now()-start;
const parent=path.join(repo,'.artifacts/tests/s42-startup-history');noRedirect(parent);fs.mkdirSync(parent,{recursive:true});
const out=fs.mkdtempSync(path.join(parent,'capture-'));const file=path.join(out,'report.json');fs.writeFileSync(file,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
// Detailed safe projections stay in the receipt; emit a compact inventory.
console.log(JSON.stringify({artifact:path.relative(repo,file).replaceAll('\\','/'),sha256:sha(fs.readFileSync(file)),status:report.status,stop_code:report.stop_code,
 events:report.events,operations:report.operations,editor:report.editor,error:report.error,elapsed_ms:report.elapsed_ms},null,2));
if(report.status!=='COMPLETE_HISTORICAL_EXTRACTION')process.exitCode=1;
