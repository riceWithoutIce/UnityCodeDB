const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = process.cwd();
const taskRelative = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s40-retained-mcp-install-admission';
const candidate = path.join(root,'.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission');
const output = path.join(root,'.artifacts/maintenance/s40-primary-source-integration-preparation-a');
const base = 'c848049d90fbdf618905be25225580642d98d987';
const accepted = '186aacf0371ba64e47114306170b449dbca261c9';
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function assert(ok, message) { if(!ok) throw Error(message); }
function git(cwd,args) {
  const result=spawnSync('git',['-C',cwd,...args],{encoding:null,maxBuffer:8*1024*1024});
  assert(result.status===0,'Git read failed: '+args.join(' ')); return result.stdout;
}
assert(!fs.existsSync(output),'Preserve existing preparation');
assert(git(candidate,['rev-parse','HEAD']).toString().trim()===accepted,'Accepted branch drift');
const snapshot=JSON.parse(fs.readFileSync(path.join(root,taskRelative,'SOURCE-SHA256.json')));
const index=git(root,['rev-parse','--path-format=absolute','--git-path','index']).toString().trim();
const indexBefore=sha(fs.readFileSync(index));
const plan=[];
for(const source of snapshot.sources) {
  const primaryPath=path.join(root,source.path);
  const incoming=git(candidate,['show',accepted+':'+source.path]);
  assert(sha(incoming)===source.sha256,'Accepted source drift');
  const before=fs.existsSync(primaryPath)?fs.readFileSync(primaryPath):null;
  let proposed=incoming;
  let strategy;
  if(source.path.endsWith('/codedb-instance-engine.ps1')) {
    const baseBytes=git(candidate,['show',base+':'+source.path]);
    assert(before&&before.equals(baseBytes),'Engine primary differs from accepted parent');
    strategy='replace exact parent bytes with accepted engine bytes';
  } else if(source.path.endsWith('.md')) {
    assert(before,'Missing local contract');
    const incomingText=incoming.toString('utf8');
    const paragraph=incomingText.match(/For same-Package reinstall,[\s\S]*?cleanup still requires all holders to drain\./);
    assert(paragraph,'Missing accepted contract paragraph');
    assert(!before.toString('utf8').includes('For same-Package reinstall,'),'Contract already integrated');
    const anchor=Buffer.from('The project-local MCP registration has a stable project entry and wrapper');
    const offset=before.indexOf(anchor);
    assert(offset>=0&&before.indexOf(anchor,offset+anchor.length)===-1,'Contract anchor missing or ambiguous');
    const eol=before.includes(Buffer.from('\r\n'))?'\r\n':'\n';
    const added=Buffer.from(paragraph[0].replace(/\r?\n/g,eol)+eol+eol);
    proposed=Buffer.concat([before.subarray(0,offset),added,before.subarray(offset)]);
    assert(Buffer.concat([proposed.subarray(0,offset),proposed.subarray(offset+added.length)]).equals(before),'Contract preimage preservation failed');
    strategy='insert only accepted same-Package paragraph; preserve every original local byte';
  } else {
    assert(before===null,'Focused test already exists; do not overwrite');
    strategy='add exact accepted focused test bytes';
  }
  plan.push({path:source.path,primary_exists:before!==null,before_sha256:before?sha(before):null,accepted_sha256:source.sha256,proposed_sha256:sha(proposed),strategy,before,proposed});
}
fs.mkdirSync(output,{recursive:true});
for(const item of plan) {
  const proposedPath=path.join(output,'proposed',item.path);
  fs.mkdirSync(path.dirname(proposedPath),{recursive:true}); fs.writeFileSync(proposedPath,item.proposed);
  if(item.before) {
    const backupPath=path.join(output,'preimages',item.path);
    fs.mkdirSync(path.dirname(backupPath),{recursive:true}); fs.writeFileSync(backupPath,item.before);
  }
  delete item.before; delete item.proposed;
}
assert(sha(fs.readFileSync(index))===indexBefore,'Primary index changed');
for(const item of plan) {
  const file=path.join(root,item.path);
  assert(item.primary_exists?sha(fs.readFileSync(file))===item.before_sha256:!fs.existsSync(file),'Primary source changed during preparation');
}
const receipt={state:'PREPARATION_ONLY_NO_PRIMARY_SOURCE_WRITES',captured_at:new Date().toISOString(),accepted_commit:accepted,parent:base,primary_head:git(root,['rev-parse','HEAD']).toString().trim(),primary_index_sha256:indexBefore,primary_source_unchanged:true,files:plan};
fs.writeFileSync(path.join(output,'plan.json'),JSON.stringify(receipt,null,2));
console.log(JSON.stringify(receipt,null,2));
