const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const root=process.cwd();
const evidence=path.join(root,'.artifacts/tests/s42-context-commit-export/execution-a');
const commit=JSON.parse(fs.readFileSync(path.join(evidence,'commit.json')));
const output=path.join(root,commit.export_relative);
const stage=path.join(output,'package/com.rice.ai-codedb');
const exact=path.join(output,'review/com.rice.ai-codedb');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const assert=(v,m)=>{if(!v)throw new Error(m);};
function inventory(base){
 const out=[];
 function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){
  const file=path.join(dir,e.name);assert(!e.isSymbolicLink(),'Unexpected symlink');
  if(e.isDirectory())walk(file);else if(e.isFile())out.push({path:path.relative(base,file).replaceAll('\\','/'),sha256:sha(fs.readFileSync(file))});
 }}walk(base);return out.sort((a,b)=>a.path.localeCompare(b.path));
}
const staged=inventory(stage),extracted=inventory(exact);
assert(staged.length===666&&JSON.stringify(staged)===JSON.stringify(extracted),'Full inventory differs');
for(const source of commit.source_files)assert(sha(fs.readFileSync(path.join(output,'review',source.path)))===source.sha256,'Exported source drift');
fs.writeFileSync(path.join(evidence,'staged-inventory.json'),JSON.stringify(staged,null,2)+'\n',{flag:'wx'});
fs.writeFileSync(path.join(evidence,'exact-inventory.json'),JSON.stringify(extracted,null,2)+'\n',{flag:'wx'});
const tests=[];
for(const [flag,run,log] of [
 ['--watch-manager-context-fixture','s42-instance-context/exact-'+commit.commit.slice(0,7)+'-a','exact-context.log'],
 ['--query-readiness-contract-fixture','s42-readiness/exact-'+commit.commit.slice(0,7)+'-a','exact-readiness.log'],
 ['--s32-disposition-fixture','s32-install/exact-'+commit.commit.slice(0,7)+'-a','exact-disposition.log']]){
 const result=spawnSync(process.execPath,[path.join(exact,'Tests~/test-codedb-project-supervisor.mjs'),flag,path.join(output,'review/.artifacts/tests',run)],{encoding:'utf8',windowsHide:true});
 fs.writeFileSync(path.join(evidence,log),(result.stdout||'')+(result.stderr||''),{flag:'wx'});
 assert(result.status===0,'Exact fixture failed: '+flag);
 tests.push({flag,exit_code:result.status,log});process.stdout.write(result.stdout);
}
function git(cwd,args){const r=spawnSync('git',['-C',cwd,...args],{encoding:'utf8',windowsHide:true});assert(r.status===0,'Git check failed');return r.stdout.trim();}
const candidate=path.join(root,'.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract');
assert(git(candidate,['status','--porcelain','--untracked-files=all'])==='','Candidate no longer clean');
assert(git(candidate,['rev-parse','HEAD'])===commit.commit,'Candidate commit changed');
assert(git(candidate,['rev-parse','HEAD^{tree}'])===commit.tree,'Candidate tree changed');
const primaryIndex=git(root,['rev-parse','--path-format=absolute','--git-path','index']);
const primaryHash=sha(fs.readFileSync(primaryIndex));
assert(primaryHash===commit.primary_index_before,'Primary index changed');
const archive=path.join(output,'com.rice.ai-codedb.zip');
const receipt={status:'EXACT_COMMIT_EXPORT_PASS_NOT_CONSUMER_DELIVERED',commit:commit.commit,parent:commit.parent,tree:commit.tree,
 artifact:path.relative(root,archive).replaceAll('\\','/'),artifact_sha256:sha(fs.readFileSync(archive)),files:extracted.length,
 byte_closure:'PASS',production_admission:'PASS',full_inventory_match:true,source_files:commit.source_files,tests,
 candidate_clean:true,primary_index_before:commit.primary_index_before,primary_index_after:primaryHash,
 consumer_reads:0,consumer_mutations:0,live_rpc:0,finished_at_utc:new Date().toISOString()};
fs.writeFileSync(path.join(evidence,'export-result.json'),JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify(receipt,null,2));
