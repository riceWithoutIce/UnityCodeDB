// Preparation only: Git read commands and task-owned snapshot writes; no staging/commit/export.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const repo=process.cwd();
const task=path.join(repo,'.ai/tasks/v0.3.0/cdb-v0.3-p0-s42-coordinator-query-readiness-contract');
const candidate=path.join(repo,'.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract');
const check=(v,c)=>{if(!v)throw Error(c);};
const git=args=>{const r=spawnSync('git',['-C',candidate,...args]);check(r.status===0,'GIT_READ_FAILED');return r.stdout;};
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const object=(kind,bytes)=>crypto.createHash('sha1').update(Buffer.from(`${kind} ${bytes.length}\0`)).update(bytes).digest('hex');
check(git(['rev-parse','--show-object-format']).toString().trim()==='sha1','UNSUPPORTED_OBJECT_FORMAT');
const base=git(['rev-parse','HEAD']).toString().trim();check(base==='267b921dee0385962885e8e3142b4e4903ab711b','BASE_CHANGED');
const branch=git(['branch','--show-current']).toString().trim();check(branch==='codex/coordinator-query-readiness','BRANCH_CHANGED');
check(git(['diff','--cached','--name-only']).length===0,'INDEX_NOT_EMPTY');
const sources=[
 {path:'com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs',sha256:'50260e1a355907a163e7841dc7a076e1917c0cec1e4b0d3f4f6f4a7186e59aca'},
 {path:'com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs',sha256:'dcfb3008eac55880b0ba5eae26f7acb962dcb345b3d92cab467d279b02b41e06'}];
const dirty=git(['status','--porcelain','--untracked-files=all']).toString().trimEnd().split(/\r?\n/).map(s=>s.slice(3)).sort();
check(JSON.stringify(dirty)===JSON.stringify(sources.map(s=>s.path).sort()),'SOURCE_SCOPE_CHANGED');
for(const s of sources){const bytes=fs.readFileSync(path.join(candidate,s.path));check(sha(bytes)===s.sha256,'SOURCE_CHANGED');s.git_blob=object('blob',bytes);}
const leaves=git(['ls-tree','-r','-z','HEAD']).toString().split('\0').filter(Boolean).map(record=>{
 const m=/^(\d+) (blob|commit) ([a-f0-9]{40})\t(.+)$/.exec(record);check(m,'TREE_ENTRY_UNSUPPORTED');return {mode:m[1],oid:m[3],name:m[4]};});
function tree(overrides){
 const root=new Map();
 for(const entry of leaves){const parts=entry.name.split('/');let dir=root;
  for(const part of parts.slice(0,-1)){if(!dir.has(part))dir.set(part,new Map());dir=dir.get(part);}
  dir.set(parts.at(-1),{mode:entry.mode,oid:overrides.get(entry.name)??entry.oid});}
 const encode=dir=>{
  const rows=[...dir].map(([name,value])=>value instanceof Map?{name,mode:'40000',oid:encode(value),sort:name+'/'}:{name,...value,sort:name});
  rows.sort((a,b)=>Buffer.compare(Buffer.from(a.sort),Buffer.from(b.sort)));
  return object('tree',Buffer.concat(rows.map(r=>Buffer.concat([Buffer.from(`${r.mode} ${r.name}\0`),Buffer.from(r.oid,'hex')]))));};
 return encode(root);
}
check(tree(new Map())===git(['rev-parse','HEAD^{tree}']).toString().trim(),'TREE_ENCODER_BASELINE_FAILED');
const prepared_tree=tree(new Map(sources.map(s=>[s.path,s.git_blob])));
const snapshot={base,branch,prepared_tree,sources,title:'Bind watch manager child to selected instance context',
 evidence_relative:'.artifacts/tests/s42-context-commit-export/execution-a',export_prefix:'.artifacts/exports/s42-instance-context-',
 focused_source_receipt_sha256:'2a7d910f6472668a1204dc5e9e26e4e21f8e33117f7ed4c9ceb4df6a885eb123'};
check(sha(fs.readFileSync(path.join(candidate,'.artifacts/tests/s42-instance-context/repair-a/result.json')))===snapshot.focused_source_receipt_sha256,'FOCUSED_RECEIPT_CHANGED');
fs.writeFileSync(path.join(task,'INSTANCE-CONTEXT-DELIVERY-SNAPSHOT.json'),JSON.stringify(snapshot,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify(snapshot,null,2));
