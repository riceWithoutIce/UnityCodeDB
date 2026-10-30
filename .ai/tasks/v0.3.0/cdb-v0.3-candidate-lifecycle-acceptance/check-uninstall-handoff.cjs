// One exact-action disk snapshot. No product helper is imported or executed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const repo = process.cwd();
const project = 'G:/RiceProgram/Test/CodedbTest/CodedbTest_2';
const pkg = 'G:/RiceProgram/Test/CodedbTest/Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb';
const action = 'ff2dc5eb61ad488186fd31a5556b5d40';
const manager = path.join(process.env.LOCALAPPDATA, 'Rice/CodeDB/manager-actions');
const out = path.join(repo, '.artifacts/tests/cdb-v0.3-candidate-lifecycle-acceptance/uninstall-handoff-check-01');
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const norm = value => path.resolve(value).replaceAll('\\', '/').replace(/\/$/, '').toLowerCase();
const projectKey = sha(norm(project));
const packageKey = sha(norm(pkg));
let reads = 0;
const records = {};
function guard(file, root) {
  const full = path.resolve(file), base = path.resolve(root);
  const rel = path.relative(base, full);
  if (rel.startsWith('..') || path.isAbsolute(rel)) throw Error('Path escaped named root');
  let cursor = path.parse(full).root;
  for (const part of full.slice(cursor.length).split(path.sep)) {
    cursor = path.join(cursor, part);
    if (!fs.existsSync(cursor)) break;
    if (fs.lstatSync(cursor).isSymbolicLink()) throw Error('Redirected evidence path');
  }
}
function read(label, file, root, maximum = 256 * 1024) {
  guard(file, root);
  if (++reads > 16) throw Error('Record budget exceeded');
  if (!fs.existsSync(file)) { records[label] = { exists: false }; return null; }
  const st = fs.statSync(file);
  if (!st.isFile() || st.size > maximum) throw Error('Record size/type boundary');
  const bytes = fs.readFileSync(file);
  const value = JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
  records[label] = { exists: true, bytes: bytes.length, sha256: sha(bytes), value };
  return value;
}
function presence(label, file) {
  guard(file, project);
  if (!fs.existsSync(file)) { records[label] = { exists: false }; return; }
  const st = fs.statSync(file);
  records[label] = { exists: true, bytes: st.size, last_write_utc: st.mtime.toISOString(), content_read: false };
}
const payload = read('package_payload', path.join(pkg, 'Payload~/payload-manifest.json'), pkg);
const cc = payload.control_contract;
if (cc.id !== 'v0.3-control' || cc.version !== 2) throw Error('Unexpected control contract');
const runtime = path.join(project, `AIWork/.runtime/codedb/control/contracts/${cc.id}/v${cc.version}/supervisor`);
const map = read('action_map', path.join(runtime, 'manager-actions', action + '.json'), project);
let op = null;
if (map) {
  if (!Array.isArray(map.operation_ids) || map.operation_ids.length !== 1 ||
      !/^[a-f0-9]{32}$/.test(map.operation_ids[0]) || map.latest_operation_id !== map.operation_ids[0])
    throw Error('Ambiguous operation binding');
  op = read('operation', path.join(runtime, 'operation-history', map.operation_ids[0] + '.json'), project);
}
const manifest = read('action_manifest', path.join(manager, action, 'action.json'), manager);
const indexRoot = path.join(manager, projectKey.slice(0, 24));
const current = read('current_index', path.join(indexRoot, 'current-action-' + action + '.json'), manager);
const resolved = read('resolved_index', path.join(indexRoot, 'resolved-action-' + action + '.json'), manager);
presence('supervisor_state', path.join(runtime, 'supervisor-state.json'));
presence('supervisor_lock', path.join(runtime, 'supervisor.lock'));
const eqPath = (a, b) => typeof a === 'string' && norm(a) === norm(b);
const common = v => v && v.schema_version === 1 && v.managed_by === 'com.rice.ai-codedb' &&
  v.manager_action_id === action && v.project_identity === 'sha256:' + projectKey &&
  eqPath(v.root, project) && eqPath(v.runtime, runtime);
const bindings = ['owner_epoch','request_id','selected_instance_id','selected_generation_id','runtime_contract_sha256'];
const checks = {
  map_common: !!common(map), operation_common: !!common(op),
  map_package: !!map && eqPath(map.package_root, pkg),
  map_terminal_binding_schema: map?.terminal_binding_schema_version === 1,
  operation_id: !!op && op.operation_id === map?.latest_operation_id,
  uninstall_maintenance: op?.name === 'materialize:Uninstall' && op?.lane === 'maintenance',
  original_binding_fields: !!op && bindings.every(k => op[k] === map[k]),
  selected_instance: op?.selected_instance_id === 'a492a5e936c14e4da3ed7e4cc7c8c16c',
  selected_generation: op?.selected_generation_id === 'poc.44',
  runtime_contract: op?.runtime_contract_sha256 === 'ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5',
  terminal_completed: op?.state === 'completed' && op?.phase === 'completed' && op?.result?.exit_code === 0,
  terminal_complete_output: !!op?.result && !op.result.timed_out && !op.result.output_overflow && !op.result.output_drain_incomplete
};
function sanitize(value) {
  if (typeof value === 'string') {
    let s = value.replaceAll('\\', '/');
    const roots = [[pkg,'<candidate-package>'],[project,'<external-test-root>'],[manager,'<manager-actions-root>'],[repo,'<repository-root>']];
    for (const [root, symbol] of roots) s = s.replace(new RegExp(root.replaceAll('\\','/').replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'gi'), symbol);
    return s.replace(/\b[a-z]:\/[^\r\n"'<>]+/gi, '<machine-path>');
  }
  if (Array.isArray(value)) return value.map(sanitize);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k,v]) => [k,sanitize(v)]));
  return value;
}
const result = sanitize({ observed_at_utc: new Date().toISOString(), action_id: action,
  project_key: projectKey, package_key: packageKey, records_read: reads, checks, records });
const serialized = JSON.stringify(result, null, 2) + '\n';
// Refuse persistence if an unexpected absolute machine path remains.
if (/[a-z]:\//i.test(serialized)) throw Error('Unredacted absolute path in snapshot');
if (fs.existsSync(out)) throw Error('Snapshot output already exists; no overwrite/retry');
fs.mkdirSync(out, { recursive: true });
fs.writeFileSync(path.join(out, 'snapshot.json'), serialized);
console.log(JSON.stringify(sanitize({ artifact: path.relative(repo, out).replaceAll('\\','/') + '/snapshot.json',
  sha256: sha(serialized), checks, records: Object.fromEntries(Object.entries(records).map(([k,v]) => [k,{ exists:v.exists,bytes:v.bytes,sha256:v.sha256 }])),
  operation: op ? {operation_id:op.operation_id,state:op.state,phase:op.phase,handoff_queued:op.handoff_queued,handoff_reason:op.handoff_reason,
    started_at_utc:op.started_at_utc,completed_at_utc:op.completed_at_utc,result:op.result} : null,
  action_manifest: manifest,current_index:current,resolved_index:resolved}), null, 2));
