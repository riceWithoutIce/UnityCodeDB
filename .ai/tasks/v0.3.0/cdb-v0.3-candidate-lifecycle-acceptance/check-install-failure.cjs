// Exact failed action and two named quarantine files only. No product imports.
const fs=require('node:fs'), path=require('node:path'), crypto=require('node:crypto');
const action='1a02434fd5424d379508b338318c1b65';
const project='G:/RiceProgram/Test/CodedbTest/CodedbTest_2';
const pkg='G:/RiceProgram/Test/CodedbTest/Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb';
const manager=path.join(process.env.LOCALAPPDATA,'Rice/CodeDB/manager-actions');
const actionRoot=path.join(manager,action);
const runtime=path.join(project,'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor');
const sha=v=>crypto.createHash('sha256').update(v).digest('hex');
const norm=v=>path.resolve(v).replaceAll('\\','/').toLowerCase();
const out='.artifacts/tests/cdb-v0.3-candidate-lifecycle-acceptance/fresh-install-attempt-01';
function guard(file,root){
 const rel=path.relative(root,file); if(rel.startsWith('..')||path.isAbsolute(rel))throw Error('Evidence escaped root');
 let cursor=path.parse(file).root;
 for(const part of file.slice(cursor.length).split(path.sep)){
  cursor=path.join(cursor,part); if(!fs.existsSync(cursor))break;
  if(fs.lstatSync(cursor).isSymbolicLink())throw Error('Redirected evidence');
 }
}
const records={};
function read(label,root,name){
 const file=path.resolve(root,name);guard(file,path.resolve(root));
 if(!fs.existsSync(file)){records[label]={exists:false};return null;}
 const stat=fs.statSync(file);if(!stat.isFile()||stat.size>262144)throw Error('Record budget/type');
 const bytes=fs.readFileSync(file),value=JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''));
 records[label]={exists:true,bytes:bytes.length,sha256:sha(bytes),value};return value;
}
const manifest=read('action',actionRoot,'action.json');
const admitted=read('admitted',actionRoot,'e04a4a6deb4590c9.admitted.json');
const claim=read('claim',actionRoot,'e04a4a6deb4590c9.claim.json');
const terminal=read('terminal',actionRoot,'e04a4a6deb4590c9.terminal.json');
const suffix='.stale.1792636589842.21e4730684ce4af9ac62090523fa04dc';
const state=read('quarantined_state',runtime,'supervisor-state.json'+suffix);
const owner=read('quarantined_lock',runtime,'supervisor.lock'+suffix);
const entries=fs.readdirSync(runtime,{withFileTypes:true});if(entries.length>32)throw Error('Directory budget');
const inventory=entries.map(e=>({name:e.name,directory:e.isDirectory(),symbolic_link:e.isSymbolicLink()}));
const rejected=inventory.filter(e=>!(!e.directory&&['supervisor-events.jsonl','supervisor-error.json','operation.json'].includes(e.name))&&!(e.directory&&['operation-history','manager-actions'].includes(e.name)));
const checks={};
for(const [label,v] of Object.entries({action:manifest,admitted,claim,terminal})){
 checks[label+'_action']=v?.action_id===action;
 checks[label+'_project']=v?.project_key===sha(norm(project));
 checks[label+'_package']=v?.package_key===sha(norm(pkg));
}
checks.stage_binding=admitted?.stage_id===claim?.stage_id&&claim?.stage_id===terminal?.stage_id;
checks.quarantine_owner_epoch_equal=state?.owner_epoch===owner?.owner_epoch;
checks.quarantine_project_equal=state?.project_identity===owner?.project_identity&&state?.project_identity==='sha256:'+sha(norm(project));
function sanitize(v){
 if(typeof v==='string'){
  let s=v.replaceAll('\\','/');
  for(const [root,label]of [[pkg,'<candidate-package>'],[project,'<external-test-root>'],[manager,'<manager-actions-root>']])s=s.replace(new RegExp(root.replaceAll('\\','/').replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'gi'),label);
  return s.replace(/\b[a-z]:\/[^\r\n"'<>]+/gi,'<machine-path>');
 }
 if(Array.isArray(v))return v.map(sanitize);
 if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,/^(auth_token|access_token|password|secret)$/i.test(k)?'<redacted>':sanitize(x)]));
 return v;
}
const result=sanitize({observed_at_utc:new Date().toISOString(),action_id:action,checks,runtime_inventory:inventory,install_admission_rejected_entries:rejected,records});
const text=JSON.stringify(result,null,2)+'\n';if(/[a-z]:\//i.test(text))throw Error('Unredacted path');
if(fs.existsSync(out))throw Error('No overwrite/retry');fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'snapshot.json'),text);
console.log(JSON.stringify(sanitize({artifact:out+'/snapshot.json',sha256:sha(text),checks,rejected,terminal,quarantine:{state_keys:Object.keys(state),lock_keys:Object.keys(owner),owner_epoch:state.owner_epoch,project_identity:state.project_identity}}),null,2));
