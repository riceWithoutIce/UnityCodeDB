const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = process.cwd();
const preparation = path.join(root,'.artifacts/maintenance/s40-primary-source-integration-preparation-a');
const output = path.join(root,'.artifacts/maintenance/s40-primary-source-integration-execution-a');
const candidate = path.join(root,'.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission');
const accepted = '186aacf0371ba64e47114306170b449dbca261c9';
const allowlist = [
  'com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1',
  'com.rice.ai-codedb/Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md',
  'com.rice.ai-codedb/Tests~/test-codedb-retained-mcp-install.ps1',
  'com.rice.ai-codedb/Tests~/test-codedb-retained-mcp-install.mjs'
];
const protectedPaths = [
  'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs',
  'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'
];
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function assert(ok, message) { if(!ok) throw Error(message); }
function git(cwd,args) {
  const r=spawnSync('git',['-C',cwd,...args],{encoding:null,maxBuffer:8*1024*1024});
  assert(r.status===0,'Git read failed: '+args.join(' ')); return r.stdout;
}
function checkPreimage(item) {
  const file=path.join(root,item.path);
  assert(item.primary_exists?fs.existsSync(file)&&sha(fs.readFileSync(file))===item.before_sha256:!fs.existsSync(file),'Primary preimage drift: '+item.path);
}
assert(!fs.existsSync(output),'Preserve previous execution');
const plan=JSON.parse(fs.readFileSync(path.join(preparation,'plan.json')));
assert(plan.accepted_commit===accepted,'Prepared commit drift');
assert(JSON.stringify(plan.files.map(f=>f.path).sort())===JSON.stringify([...allowlist].sort()),'Exact four-file allowlist mismatch');
assert(git(root,['rev-parse','HEAD']).toString().trim()===plan.primary_head,'Primary HEAD drift');
assert(git(root,['branch','--show-current']).toString().trim()==='codex/v0.3.0-legacy-workflow','Primary branch drift');
assert(git(candidate,['rev-parse','HEAD']).toString().trim()===accepted,'Accepted branch drift');
const index=git(root,['rev-parse','--path-format=absolute','--git-path','index']).toString().trim();
const indexBefore=sha(fs.readFileSync(index));
assert(indexBefore===plan.primary_index_sha256,'Primary index drift');
const protectedInputs=protectedPaths.map(relative=>({path:relative,before:sha(fs.readFileSync(path.join(root,relative)))}));
const inputs=new Map();
for(const item of plan.files) {
  checkPreimage(item);
  const proposed=fs.readFileSync(path.join(preparation,'proposed',item.path));
  assert(sha(proposed)===item.proposed_sha256,'Proposed bytes drift: '+item.path);
  const incoming=git(candidate,['show',accepted+':'+item.path]);
  assert(sha(incoming)===item.accepted_sha256,'Accepted bytes drift: '+item.path);
  if(item.path.endsWith('.md')) {
    const before=fs.readFileSync(path.join(root,item.path));
    const paragraph=incoming.toString('utf8').match(/For same-Package reinstall,[\s\S]*?cleanup still requires all holders to drain\./);
    assert(paragraph,'Accepted paragraph missing');
    const eol=before.includes(Buffer.from('\r\n'))?'\r\n':'\n';
    const added=Buffer.from(paragraph[0].replace(/\r?\n/g,eol)+eol+eol);
    const offset=proposed.indexOf(added);
    assert(offset>=0&&proposed.indexOf(added,offset+added.length)===-1,'Contract insertion is ambiguous');
    assert(Buffer.concat([proposed.subarray(0,offset),proposed.subarray(offset+added.length)]).equals(before),'Contract contains unapproved changes');
    const anchor=Buffer.from('The project-local MCP registration has a stable project entry and wrapper');
    assert(proposed.subarray(offset+added.length,offset+added.length+anchor.length).equals(anchor),'Contract insertion moved');
  } else {
    assert(proposed.equals(incoming),'Implementation/test differs from accepted bytes');
  }
  inputs.set(item.path,proposed);
}
fs.mkdirSync(output,{recursive:true});
const journal={approved_by:'User: 好的 同意, exact SOURCE-INTEGRATION-PLAN.md',started_at:new Date().toISOString(),accepted_commit:accepted,primary_head:plan.primary_head,index_before:indexBefore,protected_inputs:protectedInputs,steps:[]};
const save=()=>fs.writeFileSync(path.join(output,'journal.json'),JSON.stringify(journal,null,2));
function step(name,fields={}) { journal.steps.push({at:new Date().toISOString(),name,...fields});save(); }
save();
try {
  for(const item of plan.files) {
    if(!item.primary_exists) continue;
    const backup=path.join(output,'preimages',item.path);
    fs.mkdirSync(path.dirname(backup),{recursive:true});
    const before=fs.readFileSync(path.join(root,item.path));
    assert(sha(before)===item.before_sha256,'Pre-backup drift');
    fs.writeFileSync(backup,before,{flag:'wx'});
  }
  step('preimages_saved');
  for(const item of plan.files) {
    checkPreimage(item);
    step('write_pending',{path:item.path,expected_sha256:item.proposed_sha256});
    fs.writeFileSync(path.join(root,item.path),inputs.get(item.path),{flag:item.primary_exists?'w':'wx'});
    assert(sha(fs.readFileSync(path.join(root,item.path)))===item.proposed_sha256,'Written bytes mismatch: '+item.path);
    step('write_verified',{path:item.path,sha256:item.proposed_sha256});
  }
  assert(sha(fs.readFileSync(index))===indexBefore,'Primary index changed');
  const protectedResults=protectedInputs.map(input=>({...input,after:sha(fs.readFileSync(path.join(root,input.path)))}));
  assert(protectedResults.every(input=>input.before===input.after),'Protected WIP changed');
  for(const item of plan.files) assert(fs.readFileSync(path.join(root,item.path)).equals(inputs.get(item.path)),'Final file mismatch');
  const receipt={state:'PRIMARY_SOURCE_INTEGRATION_PASS',completed_at:new Date().toISOString(),accepted_commit:accepted,primary_head:plan.primary_head,source_scope:plan.files,contract_preimage_preserved:true,index_before:indexBefore,index_after:sha(fs.readFileSync(index)),protected_wip:protectedResults,runtime_operations:0,target_mcp_calls:0,tests_rerun:0,commits_created:0,consumer_writes:0,exact_delivery_artifact_unchanged:true,combined_primary_tree_is_not_the_exact_delivery_candidate:true};
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify(receipt,null,2));
  step('integration_pass');
  console.log(JSON.stringify({state:receipt.state,files:receipt.source_scope.length,contract_preimage_preserved:true,index_unchanged:true,protected_wip_unchanged:true,tests_rerun:0,runtime_operations:0},null,2));
} catch(error) {
  journal.failure=String(error.stack||error);journal.stopped_at=new Date().toISOString();save();throw error;
}
