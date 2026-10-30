const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const [repo, project] = process.argv.slice(2).map(v => path.resolve(v));
const ids = ['008607a4424644afab1a7955d5acc823','96aa2730203f42f4a143ed15bf44a972','b6a3302c24af43ef8ab4cfb3bf9ba1ed','fa7c329609a54c9f857db0d8438d098b'];
const history = path.join(project,'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor/operation-history');
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const records = ids.map(id => {
  const filename = path.join(history,id+'.json');
  let cursor = path.parse(filename).root;
  for (const part of filename.slice(cursor.length).split(path.sep)) {
    cursor = path.join(cursor,part);
    try {if (fs.lstatSync(cursor).isSymbolicLink()) throw Error('Redirected path');}
    catch(e) {if(e.code==='ENOENT')return {id,observed_utc:new Date().toISOString(),exists:false};throw e;}
  }
  const st = fs.statSync(filename);
  if (!st.isFile() || st.size > 262144) throw Error('Evidence size/type exceeded');
  const bytes = fs.readFileSync(filename), d = JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''));
  if (d.operation_id !== id || d.project_identity !== 'sha256:c2ad1085aca6ca5e8298cfe630b69c5b61242497f65c187eb08484f035ca6dd2') throw Error('Record identity conflict');
  return {id,observed_utc:new Date().toISOString(),exists:true,bytes:bytes.length,sha256:sha(bytes),name:d.name,state:d.state,phase:d.phase,
    execution_disposition:d.execution_disposition,child_null:d.child===null,child_execution_present:d.child_execution!==undefined,
    selected_instance_id:d.selected_instance_id,exit_code:d.result?.exit_code,
    expected_error:d.error==='Coordinator query service configuration mismatch: exclusive lifecycle; stop the existing owned coordinator before starting this configuration.'};
});
const result = {purpose:'Four exact previously identified UNKNOWN records only; no process or admission execution',atomic_snapshot:false,records};
const out = path.join(repo,'.artifacts/tests/cdb-v0.3-install-quarantine-admission/test3-post-uninstall-unknown-01');
const rel=path.relative(repo,out);if(rel.startsWith('..')||path.isAbsolute(rel))throw Error('Output escaped repository');
let cursor=path.parse(out).root;for(const part of out.slice(cursor.length).split(path.sep)){cursor=path.join(cursor,part);try{if(fs.lstatSync(cursor).isSymbolicLink())throw Error('Redirected output');}catch(e){if(e.code==='ENOENT')break;throw e;}}
fs.mkdirSync(out,{recursive:false});const text=JSON.stringify(result,null,2)+'\n';fs.writeFileSync(path.join(out,'snapshot.json'),text,{flag:'wx'});
console.log(JSON.stringify({artifact:rel.replaceAll('\\','/')+'/snapshot.json',sha256:sha(text),records},null,2));
