// Task-owned disk-only diagnostic. Does not import or execute product runtime.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');
const root = fs.realpathSync(process.argv[2]);
if (path.basename(root) !== 'CodedbTest_2') throw new Error('Wrong target project');
const runtime = path.join(root, 'AIWork/.runtime/codedb');
const now = () => new Date().toISOString();
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const inside = (p, base) => p === base || p.startsWith(base + path.sep);
const reads = [];
function read(relative) {
  const filename = path.resolve(root, relative);
  const entry = { record: relative.replaceAll('\\', '/'), read_at_utc: now() };
  reads.push(entry);
  try {
    if (!inside(filename, runtime) || !inside(fs.realpathSync(filename), fs.realpathSync(runtime))) {
      throw Object.assign(new Error(), { code: 'OUTSIDE_SCOPE' });
    }
    if (fs.statSync(filename).size > 1024 * 1024) {
      throw Object.assign(new Error(), { code: 'TOO_LARGE' });
    }
    const bytes = fs.readFileSync(filename);
    entry.sha256 = sha(bytes);
    const value = JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
    entry.status = 'READ';
    return value;
  } catch (e) {
    entry.status = e.code === 'ENOENT' ? 'MISSING' : 'UNREADABLE';
    entry.error_code = /^[A-Z_]+$/.test(e.code || '') ? e.code : 'PARSE_OR_READ_ERROR';
    return null;
  }
}
// Only small identifiers, enums, numbers and timestamps from named fields.
function pick(value, keys) {
  return Object.fromEntries(keys.map(k => {
    const v = value?.[k];
    return [k, v == null ? null : typeof v === 'boolean' || typeof v === 'number' ? v
      : typeof v === 'string' && /^[A-Za-z0-9_.:+ -]{0,160}$/.test(v) ? v : 'OMITTED'];
  }));
}
const age = t => Number.isFinite(Date.parse(t)) ? Date.now() - Date.parse(t) : null;
const equalPath = (v, p) => typeof v === 'string'
  && path.resolve(v).replaceAll('\\', '/').toLowerCase() === path.resolve(p).replaceAll('\\', '/').toLowerCase();
const pointerRel = 'AIWork/.runtime/codedb/control/current-instance.json';
const start = now();
const pointer = read(pointerRel);
if (pointer?.instance_id !== 'a492a5e936c14e4da3ed7e4cc7c8c16c'
    || pointer?.activation_epoch !== '063aa347f49a4b9f955a5447f293a0ac'
    || pointer?.generation_id !== 'poc.44'
    || pointer?.project_identity !== 'sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c'
    || pointer?.instance_relative_path !== `AIWork/.runtime/codedb/instances/${pointer.instance_id}`) {
  throw new Error('Selected binding differs; stop without rebaselining');
}
const instRel = pointer.instance_relative_path;
const instance = read(instRel + '/instance.json');
if (!instance || reads.at(-1).sha256 !== pointer.instance_manifest_sha256) {
  throw new Error('Instance manifest binding differs');
}
const policy = read(instRel + '/watch/lifecycle/desired-state.json');
const manual = read(instRel + '/watch/lifecycle/manual-runtime.json');
const leaseRel = instRel + '/watch/lifecycle/editor-leases';
let leaseNames = [];
let leaseDirectoryStatus = 'READ';
try {
  const leaseRoot = path.join(root, leaseRel);
  if (!inside(fs.realpathSync(leaseRoot), fs.realpathSync(runtime))) throw new Error();
  leaseNames = fs.readdirSync(leaseRoot).filter(n => /^[A-Za-z0-9._-]+\.json$/.test(n)).sort();
} catch { leaseDirectoryStatus = 'UNAVAILABLE'; }
const leases = leaseNames.slice(0, 8).map(n => {
  const lease = read(leaseRel + '/' + n);
  return {
    ...pick(lease, ['schema_version', 'managed_by', 'session_id', 'editor_pid', 'process_start_ticks',
      'project_identity', 'created_at_utc', 'heartbeat_at_utc']),
    heartbeat_age_ms_at_read: age(lease?.heartbeat_at_utc),
    project_root_matches: equalPath(lease?.project_root, root),
    filename_matches_session: n === `${lease?.session_id}.json`,
    process_liveness: 'NOT_PROBED'
  };
});
const coordRel = instRel + '/watch/coordinator/coordinator-state.json';
const coordinator = read(coordRel);
const coordFields = ['schema_version', 'generation_id', 'lifecycle_id', 'coordinator_pid',
  'provider_pid', 'provider_state', 'provider_start_phase', 'adapter_enabled', 'adapter_state',
  'adapter_worker_state', 'adapter_worker_pid', 'adapter_debounce_ms', 'desired_state', 'policy_state',
  'manual_mode', 'editor_demand', 'editor_session_count', 'last_lease_scan_at_utc', 'started_at_utc',
  'provider_ready_at_utc', 'last_event', 'adapter_last_event_at_utc', 'adapter_last_build_started_at_utc'];
const supervisorRel = 'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor';
const supervisor = read(supervisorRel + '/supervisor-state.json');
const operation = read(supervisorRel + '/operation.json');
const op = value => ({
  ...pick(value, ['operation_id', 'owner_epoch', 'name', 'state', 'phase', 'execution_disposition',
    'started_at_utc', 'completed_at_utc']),
  child_identity_present: value?.child != null,
  child: pick(value?.child, ['pid', 'process_start_identity']),
  exit_code: value?.result?.exit_code ?? null,
  error_present: Boolean(value?.error),
  known_unresolved_child_error: String(value?.error || '').includes('Prior child admission has unresolved identity')
});
const finalPointer = read(pointerRel);
const report = {
  evidence: 'CURRENT_SNAPSHOT; disk projections only; not authenticated RPC or S41 failure-time evidence',
  human_ui_at_capture: 'NOT_REPORTED', capture_start_utc: start, capture_end_utc: now(),
  pointer: pick(pointer, ['project_identity', 'instance_id', 'activation_epoch', 'generation_id']),
  pointer_bytes_stable: reads[0].sha256 === reads.at(-1).sha256 && finalPointer != null,
  instance: pick(instance, ['state', 'package_version', 'generation_id']),
  policy: pick(policy, ['schema_version', 'desired_state', 'project_identity']),
  manual: pick(manual, ['schema_version', 'mode']),
  leases: { directory_status: leaseDirectoryStatus, count: leaseNames.length, truncated: leaseNames.length > 8, entries: leases },
  coordinator: {
    ...pick(coordinator, coordFields),
    lease_scan_age_ms: age(coordinator?.last_lease_scan_at_utc),
    error_present: Boolean(coordinator?.last_error), adapter_error_present: Boolean(coordinator?.adapter_last_error),
    path_checks: Object.fromEntries([
      ['root', root], ['runtime', path.join(root, instRel, 'watch/coordinator')],
      ['provider_config', path.join(root, instRel, 'config/codedb-mcp.watch.toml')],
      ['adapter_manifest', path.join(root, instRel, 'adapter/text-index/manifest.json')]
    ].map(([k, p]) => [k, equalPath(coordinator?.[k], p)])),
    other_path_checks_and_process_liveness: 'NOT_VERIFIED'
  },
  supervisor: {
    ...pick(supervisor, ['schema_version', 'supervisor_pid', 'owner_epoch', 'selected_instance_id',
      'activation_epoch', 'generation_id', 'readiness_state', 'reason_code', 'coordinator_failure_category',
      'last_event', 'updated_at_utc', 'started_at_utc']),
    operational_readiness: { ...pick(supervisor?.operational_readiness, ['observation_id', 'revision',
      'observed_at_utc', 'state', 'reason_code', 'owner_epoch', 'selected_instance_id', 'activation_epoch']),
      age_ms: age(supervisor?.operational_readiness?.observed_at_utc) },
    operation: op(supervisor?.operation)
  },
  current_operation_record: op(operation), reads
};
const outputBase = path.join(repo, '.artifacts/tests/identity-handoff-heartbeat');
fs.mkdirSync(outputBase, { recursive: true });
if (!inside(fs.realpathSync(outputBase), fs.realpathSync(repo))) throw new Error('Output escaped repository');
const output = path.join(outputBase, 'current-snapshot-' + start.replace(/[:.]/g, '-') + '-' + crypto.randomBytes(3).toString('hex'));
fs.mkdirSync(output);
fs.writeFileSync(path.join(output, 'snapshot.json'), JSON.stringify(report, null, 2) + '\n', { flag: 'wx' });
console.log(JSON.stringify({ artifact: path.relative(repo, path.join(output, 'snapshot.json')).replaceAll('\\', '/'), report }));
