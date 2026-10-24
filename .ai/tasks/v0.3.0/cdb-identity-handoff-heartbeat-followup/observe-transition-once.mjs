// Task-owned, read-only, event-triggered observer.
// It never calls MCP, starts/stops a product process, edits project state, or
// reads product logs. It captures one sanitized state tuple on the first
// backend readiness transition, or reports NO_WINDOW_OBSERVED on timeout.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');
const rootArg = process.argv[2];
const timeoutMs = Number(process.argv[3] ?? 120000);
if (!rootArg) throw new Error('Usage: node observe-transition-once.mjs <CodedbTest_2-root> [timeout-ms]');
if (!Number.isInteger(timeoutMs) || timeoutMs < 1000 || timeoutMs > 600000)
  throw new Error('timeout-ms must be an integer between 1000 and 600000');

const root = fs.realpathSync(path.resolve(rootArg));
if (path.basename(root) !== 'CodedbTest_2') throw new Error('Wrong target project');
const runtime = fs.realpathSync(path.join(root, 'AIWork/.runtime/codedb'));
const now = () => new Date().toISOString();
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const inside = (file, base) => file === base || file.startsWith(base + path.sep);
const rel = file => path.relative(root, file).replaceAll('\\', '/');
const pointerPath = path.join(runtime, 'control/current-instance.json');
const maxBytes = 1024 * 1024;
const readRecord = [];

function safePath(file, label) {
  const resolved = path.resolve(file);
  if (!inside(resolved, runtime)) throw new Error(`${label} escaped runtime scope`);
  const parent = fs.realpathSync(path.dirname(resolved));
  if (!inside(parent, runtime)) throw new Error(`${label} parent escaped runtime scope`);
  return resolved;
}

function readJson(file, label) {
  const resolved = safePath(file, label);
  const record = { file: rel(resolved), read_at_utc: now() };
  readRecord.push(record);
  try {
    const bytes = fs.readFileSync(resolved);
    if (bytes.length > maxBytes) throw Object.assign(new Error(), { code: 'TOO_LARGE' });
    record.sha256 = sha(bytes);
    record.status = 'READ';
    return JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
  } catch (error) {
    record.status = error?.code === 'ENOENT' ? 'MISSING' : 'UNREADABLE';
    record.error_code = /^[A-Z_]+$/.test(error?.code ?? '') ? error.code : 'READ_OR_PARSE_ERROR';
    return null;
  }
}

function pick(value, keys) {
  return Object.fromEntries(keys.map(key => {
    const item = value?.[key];
    if (item == null || typeof item === 'boolean' || typeof item === 'number') return [key, item ?? null];
    return [key, typeof item === 'string' && /^[A-Za-z0-9_.:+ -]{0,160}$/.test(item) ? item : 'OMITTED'];
  }));
}

function ageMs(value) {
  const parsed = Date.parse(value ?? '');
  return Number.isFinite(parsed) ? Date.now() - parsed : null;
}

function pathMatches(value, expected) {
  if (typeof value !== 'string') return false;
  return path.resolve(value).replaceAll('\\', '/').toLowerCase()
    === path.resolve(expected).replaceAll('\\', '/').toLowerCase();
}

const initialPointer = readJson(pointerPath, 'selected pointer');
if (!initialPointer?.instance_id || !initialPointer?.instance_relative_path
    || !initialPointer?.generation_id || !initialPointer?.project_identity) {
  throw new Error('Selected pointer is incomplete');
}
const instanceRoot = safePath(path.join(root, initialPointer.instance_relative_path), 'selected instance');
const supervisorRoot = safePath(path.join(runtime, 'control/contracts/v0.3-control/v2/supervisor'), 'Supervisor state root');
const coordinatorRoot = safePath(path.join(instanceRoot, 'watch/coordinator'), 'Coordinator state root');
const leaseRoot = safePath(path.join(instanceRoot, 'watch/lifecycle/editor-leases'), 'Editor lease root');
const paths = {
  pointer: pointerPath,
  instance: path.join(instanceRoot, 'instance.json'),
  supervisor: path.join(supervisorRoot, 'supervisor-state.json'),
  operation: path.join(supervisorRoot, 'operation.json'),
  coordinator: path.join(coordinatorRoot, 'coordinator-state.json'),
  supervisorRoot,
  coordinatorRoot,
  leaseRoot
};

function readLeases() {
  let names = [];
  try {
    names = fs.readdirSync(leaseRoot).filter(name => /^[A-Za-z0-9._-]+\.json$/.test(name)).sort();
  } catch { return { directory_status: 'UNAVAILABLE', count: 0, entries: [] }; }
  return {
    directory_status: 'READ',
    count: names.length,
    truncated: names.length > 8,
    entries: names.slice(0, 8).map(name => {
      const lease = readJson(path.join(leaseRoot, name), 'Editor lease');
      return {
        file: name,
        ...pick(lease, ['schema_version', 'managed_by', 'session_id', 'editor_pid',
          'process_start_ticks', 'project_identity', 'created_at_utc', 'heartbeat_at_utc']),
        heartbeat_age_ms: ageMs(lease?.heartbeat_at_utc),
        filename_matches_session: name === `${lease?.session_id}.json`,
        process_liveness: 'NOT_PROBED'
      };
    })
  };
}

function backendClassification(supervisor, coordinator) {
  const operational = supervisor?.operational_readiness;
  const backend = {
    supervisor_state: supervisor?.readiness_state ?? null,
    supervisor_reason: supervisor?.reason_code ?? null,
    operational_state: operational?.state ?? null,
    operational_reason: operational?.reason_code ?? null,
    provider_state: coordinator?.provider_state ?? null,
    adapter_state: coordinator?.adapter_state ?? null,
    adapter_worker_state: coordinator?.adapter_worker_state ?? null,
    desired_state: coordinator?.desired_state ?? null,
    editor_demand: coordinator?.editor_demand ?? null,
    editor_session_count: coordinator?.editor_session_count ?? null
  };
  const readyShape = backend.supervisor_state === 'core_ready'
    && backend.operational_state === 'core_ready'
    && backend.provider_state === 'ready'
    && ['watching', 'pending', 'building'].includes(backend.adapter_state)
    && backend.adapter_worker_state === 'ready'
    && backend.desired_state === 'enabled'
    && backend.editor_demand === 'online'
    && Number(backend.editor_session_count) > 0;
  return { backend, classification: readyShape ? 'BACKEND_READY' : 'BACKEND_TRANSITION_OR_DEGRADED' };
}

function readSnapshot(trigger) {
  const pointer = readJson(paths.pointer, 'selected pointer');
  const instance = readJson(paths.instance, 'selected instance');
  const supervisor = readJson(paths.supervisor, 'Supervisor state');
  const operation = readJson(paths.operation, 'Supervisor operation');
  const coordinator = readJson(paths.coordinator, 'Coordinator state');
  const leases = readLeases();
  const { backend, classification } = backendClassification(supervisor, coordinator);
  const operational = supervisor?.operational_readiness;
  return {
    captured_at_utc: now(),
    trigger,
    classification,
    backend,
    pointer: pick(pointer, ['project_identity', 'instance_id', 'activation_epoch', 'generation_id']),
    instance: pick(instance, ['state', 'package_version', 'generation_id']),
    supervisor: {
      ...pick(supervisor, ['readiness_state', 'reason_code', 'coordinator_failure_category',
        'updated_at_utc', 'last_event']),
      operational_readiness: {
        ...pick(operational, ['observation_id', 'revision', 'observed_at_utc', 'state',
          'reason_code', 'owner_epoch', 'selected_instance_id', 'activation_epoch']),
        age_ms: ageMs(operational?.observed_at_utc)
      }
    },
    operation: pick(operation, ['operation_id', 'owner_epoch', 'name', 'state', 'phase',
      'execution_disposition', 'started_at_utc', 'completed_at_utc']),
    coordinator: {
      ...pick(coordinator, ['schema_version', 'generation_id', 'lifecycle_id', 'provider_state',
        'provider_start_phase', 'adapter_enabled', 'adapter_state', 'adapter_worker_state',
        'adapter_debounce_ms', 'desired_state', 'policy_state', 'manual_mode', 'editor_demand',
        'editor_session_count', 'last_lease_scan_at_utc', 'started_at_utc', 'provider_ready_at_utc',
        'last_event', 'adapter_last_event_at_utc']),
      lease_scan_age_ms: ageMs(coordinator?.last_lease_scan_at_utc),
      path_checks: {
        runtime: pathMatches(coordinator?.runtime, coordinatorRoot),
        provider_config_present: fs.existsSync(path.join(instanceRoot, 'config/codedb-mcp.watch.toml')),
        adapter_manifest_present: fs.existsSync(path.join(instanceRoot, 'adapter/text-index/manifest.json'))
      }
    },
    leases
  };
}

const startedAt = now();
const baseline = readSnapshot('baseline');
const baselineClass = baseline.classification;
let finished = false;
const watchers = [];
let timer = null;
let classificationReads = 0;
let classificationReadScheduled = false;
const maxClassificationReads = 24;
const outputBase = path.join(repository, '.artifacts/tests/identity-handoff-heartbeat');

function closeAll() {
  for (const watcher of watchers) watcher.close();
  if (timer) clearTimeout(timer);
}

function writeResult(result) {
  if (finished) return;
  finished = true;
  closeAll();
  const endedAt = now();
  const finalPointer = readJson(paths.pointer, 'final selected pointer');
  const pointerStable = JSON.stringify(initialPointer) === JSON.stringify(finalPointer);
  const report = {
    evidence: 'ONE_SHOT_EVENT_TRIGGERED_DISK_PROJECTION',
    started_at_utc: startedAt,
    ended_at_utc: endedAt,
    timeout_ms: timeoutMs,
    human_ui_state: 'NOT_DIRECTLY_READ',
    ui_state_limit: 'Unconfirmed and some Needs attention presentations may be Manager cache/action overrides and are not inferred from backend files.',
    baseline,
    result,
    final_pointer_stable: pointerStable,
    final_pointer: pick(finalPointer, ['project_identity', 'instance_id', 'activation_epoch', 'generation_id']),
    reads: readRecord
  };
  fs.mkdirSync(outputBase, { recursive: true });
  const folder = path.join(outputBase, 'transition-observation-' + startedAt.replace(/[:.]/g, '-') + '-' + crypto.randomBytes(3).toString('hex'));
  fs.mkdirSync(folder);
  fs.writeFileSync(path.join(folder, 'result.json'), JSON.stringify(report, null, 2) + '\n', { flag: 'wx' });
  console.log(JSON.stringify({ status: result.status, artifact: rel(path.join(folder, 'result.json')), report }, null, 2));
}

function onChange(source, filename) {
  if (finished) return;
  const name = filename ? String(filename) : '';
  if (source === 'leases' && !/^[A-Za-z0-9._-]+\.json$/.test(name)) return;
  if (classificationReadScheduled) return;
  if (classificationReads >= maxClassificationReads) {
    writeResult({ status: 'OBSERVATION_READ_CAP_REACHED', source, file: name, snapshot: null });
    return;
  }
  classificationReadScheduled = true;
  // Atomic JSON writes can produce rename/change pairs. Coalesce them before
  // reading only the two small backend state files needed for classification.
  setTimeout(() => {
    classificationReadScheduled = false;
    if (finished) return;
    classificationReads += 1;
    const supervisor = readJson(paths.supervisor, 'Supervisor classification state');
    const coordinator = readJson(paths.coordinator, 'Coordinator classification state');
    const current = backendClassification(supervisor, coordinator);
    if (current.classification !== baselineClass && current.classification !== 'BACKEND_READY') {
      writeResult({
        status: 'TRANSITION_CAPTURED',
        source,
        file: name,
        snapshot: readSnapshot(`${source}:${name || 'directory-event'}`)
      });
    }
  }, 100);
}

if (baselineClass !== 'BACKEND_READY')
  writeResult({ status: 'ALREADY_IN_TRANSITION', source: 'baseline', file: null, snapshot: baseline });

for (const [source, directory] of [['supervisor', paths.supervisorRoot], ['coordinator', paths.coordinatorRoot], ['leases', paths.leaseRoot]]) {
  try {
    watchers.push(fs.watch(directory, { persistent: false }, filename => onChange(source, filename)));
  } catch (error) {
    writeResult({ status: 'WATCH_UNAVAILABLE', source, error_code: /^[A-Z_]+$/.test(error?.code ?? '') ? error.code : 'WATCH_ERROR' });
    process.exitCode = 2;
    break;
  }
}

if (!finished) {
  timer = setTimeout(() => writeResult({ status: 'NO_WINDOW_OBSERVED' }), timeoutMs);
}

await new Promise(resolve => {
  if (finished) return resolve();
  const interval = setInterval(() => {
    if (finished) { clearInterval(interval); resolve(); }
  }, 50);
});
