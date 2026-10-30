// One bounded exact-action disk observation; no product code/RPC/process checks.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const [repo, project, pkg] = process.argv.slice(2).map(v => path.resolve(v));
const action = '93bb43c28f80423094b4fe344c7b1b0e';
const instance = 'bd0f2f01601b4b3990704ad9659f9348';
const sha = v => crypto.createHash('sha256').update(v).digest('hex');
const norm = v => path.resolve(v).replaceAll('\\','/').replace(/\/$/,'').toLowerCase();
const manager = path.join(process.env.LOCALAPPDATA, 'Rice/CodeDB/manager-actions');
const projectKey = sha(norm(project));
const records = {}; let count = 0;
function guard(file, root) {
  const full = path.resolve(file), rel = path.relative(path.resolve(root), full);
  if (rel.startsWith('..') || path.isAbsolute(rel)) throw Error('Evidence escaped named root');
  let cursor = path.parse(full).root;
  for (const part of full.slice(cursor.length).split(path.sep)) {
    cursor = path.join(cursor, part);
    try { if (fs.lstatSync(cursor).isSymbolicLink()) throw Error('Redirected evidence'); }
    catch (e) { if (e.code === 'ENOENT') break; throw e; }
  }
}
function read(label, file, root, {json = true, presence = false, max = 262144} = {}) {
  guard(file, root);
  if (++count > 16) throw Error('Record budget exceeded');
  const row = { observed_utc: new Date().toISOString() }; records[label] = row;
  let st;
  try { st = fs.statSync(file); } catch (e) { if (e.code !== 'ENOENT') throw e; row.exists = false; return null; }
  row.exists = true; row.bytes = st.size;
  if (!st.isFile() || st.size > max) throw Error('File size/type boundary');
  if (presence) { row.content_read = false; return null; }
  const bytes = fs.readFileSync(file); row.sha256 = sha(bytes);
  const text = bytes.toString('utf8').replace(/^\uFEFF/,'');
  const value = json ? JSON.parse(text) : text; row.value = value; return value;
}
const payload = read('package_payload', path.join(pkg,'Payload~/payload-manifest.json'), pkg);
const cc = payload.control_contract;
if (cc.id !== 'v0.3-control' || cc.version !== 2) throw Error('Unexpected contract');
const runtime = path.join(project,`AIWork/.runtime/codedb/control/contracts/${cc.id}/v${cc.version}/supervisor`);
const map = read('action_map', path.join(runtime,'manager-actions',action+'.json'),project);
let op = null;
if (map) {
  if (!Array.isArray(map.operation_ids) || map.operation_ids.length !== 1 || !/^[a-f0-9]{32}$/.test(map.operation_ids[0]) || map.latest_operation_id !== map.operation_ids[0]) throw Error('Ambiguous operation binding');
  op = read('operation', path.join(runtime,'operation-history',map.latest_operation_id+'.json'),project,{max:4194304});
}
read('action_manifest',path.join(manager,action,'action.json'),manager);
const indices = path.join(manager, projectKey.slice(0,24));
read('current_index',path.join(indices,'current-action-'+action+'.json'),manager);
read('resolved_index',path.join(indices,'resolved-action-'+action+'.json'),manager);
const desired = read('desired',path.join(project,'AIWork/.runtime/codedb/control/desired-state.json'),project);
if (desired) {
  if (!/^[a-f0-9]{32}$/.test(desired.state_id)) throw Error('Invalid removal state id');
  read('removal_intent',path.join(project,'AIWork/.runtime/codedb/control/removal-intents',desired.state_id+'.json'),project);
}
const config = read('project_config',path.join(project,'.codex/config.toml'),project,{json:false});
read('selected_pointer',path.join(project,'AIWork/.runtime/codedb/control/current-instance.json'),project,{presence:true});
read('supervisor_state_presence',path.join(runtime,'supervisor-state.json'),project,{presence:true});
read('supervisor_lock_presence',path.join(runtime,'supervisor.lock'),project,{presence:true});
const bindings = ['owner_epoch','request_id','selected_instance_id','selected_generation_id','runtime_contract_sha256'];
const common = v => v?.schema_version === 1 && v.managed_by === 'com.rice.ai-codedb' && v.manager_action_id === action && v.project_identity === 'sha256:'+projectKey && norm(v.root) === norm(project) && norm(v.runtime) === norm(runtime);
const checks = {
  map_common: !!common(map), operation_common: !!common(op),
  package_binding: !!map && norm(map.package_root) === norm(pkg),
  terminal_binding_schema: map?.terminal_binding_schema_version === 1,
  operation_binding: !!op && op.operation_id === map?.latest_operation_id && bindings.every(k=>map[k]===op[k]),
  uninstall_command: op?.name === 'materialize:Uninstall' && op?.lane === 'maintenance',
  selected_instance: op?.selected_instance_id === instance,
  terminal_success: op?.state === 'completed' && op?.phase === 'completed' && op?.result?.exit_code === 0,
  complete_output: !!op?.result && op.result.timed_out === false && op.result.output_overflow === false && op.result.output_drain_incomplete === false,
  child_close_observed: !!op?.child_execution?.close && op.child_execution.close.exit_code === 0,
  desired_uninstalled_pending: desired?.desired_state === 'UNINSTALLED' && desired?.cleanup_state === 'PENDING',
  selected_pointer_absent: records.selected_pointer.exists === false,
  registration_inert: typeof config === 'string' && config.split(/\r?\n/).filter(s=>s.includes('mcp_servers.codedb-codedbtest-3')).every(s=>s.startsWith('# rice-ai-codedb-uninstalled:'+desired.state_id+':')) && config.includes('[mcp_servers.codedb-codedbtest-3]')
};
function sanitize(v) {
  if (typeof v === 'string') {
    let s = v.replaceAll('\\','/');
    for (const [root,label] of [[pkg,'<candidate-package>'],[project,'<test-project-root>'],[manager,'<manager-actions-root>'],[repo,'<repository-root>']]) {
      const escaped = root.replaceAll('\\','/').replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
      s = s.replace(new RegExp(escaped,'gi'),label);
    }
    return s.replace(/\b[a-z]:\/[^\r\n"'<>]+/gi,'<machine-path>');
  }
  if (Array.isArray(v)) return v.map(sanitize);
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k,val])=>[k,/token|secret|password|credential/i.test(k)?'<redacted>':sanitize(val)]));
  return v;
}
const result = sanitize({completed_utc:new Date().toISOString(),atomic_snapshot:false,action_id:action,records_read:count,checks,records});
const text = JSON.stringify(result,null,2)+'\n';
const out = path.join(repo,'.artifacts/tests/cdb-v0.3-install-quarantine-admission/test3-uninstall-handoff-01');
guard(out,repo);
fs.mkdirSync(out,{recursive:false});
fs.writeFileSync(path.join(out,'snapshot.json'),text,{flag:'wx'});
console.log(JSON.stringify({artifact:path.relative(repo,out).replaceAll('\\','/')+'/snapshot.json',sha256:sha(text),checks,operation:op?{id:op.operation_id,state:op.state,handoff_queued:op.handoff_queued,handoff_reason:op.handoff_reason,started:op.started_at_utc,completed:op.completed_at_utc,stdout:sanitize(op.result?.stdout),error:op.error}:null,presence:Object.fromEntries(Object.entries(records).map(([k,v])=>[k,v.exists]))},null,2));
