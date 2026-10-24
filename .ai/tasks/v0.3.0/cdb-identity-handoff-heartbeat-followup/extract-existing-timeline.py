"""Read existing evidence once; never invoke CodeDB, IPC, or process APIs."""
import argparse
import collections
import datetime
import hashlib
import json
import pathlib
import re

parser = argparse.ArgumentParser()
parser.add_argument('--project', type=pathlib.Path, required=True)
parser.add_argument('--editor-log', type=pathlib.Path, required=True)
parser.add_argument('--output', type=pathlib.Path, required=True)
args = parser.parse_args()
LIMIT = 16 * 1024 * 1024
INSTANCE = 'a492a5e936c14e4da3ed7e4cc7c8c16c'
GENERATION = 'poc.44'
PROJECT = 'sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c'
sources = []
errors = []


def read(path, label):
    try:
        with path.open('rb') as stream:
            initial_size = path.stat().st_size
            data = stream.read(min(initial_size, LIMIT))
        sources.append(dict(source=label, initial_size=initial_size, read_bytes=len(data),
                            truncated=initial_size > LIMIT, sha256=hashlib.sha256(data).hexdigest()))
        return data
    except OSError as exc:
        errors.append(dict(source=label, error=type(exc).__name__))
        return None


def document(path, label):
    data = read(path, label)
    if data is None:
        return None
    try:
        return json.loads(data.decode('utf-8-sig'))
    except (ValueError, UnicodeError) as exc:
        errors.append(dict(source=label, error=type(exc).__name__))
        return None


def pick(value, keys):
    return {key: value[key] for key in keys if key in value}


start = datetime.datetime.now(datetime.timezone.utc).isoformat()
control = args.project / 'AIWork/.runtime/codedb/control'
supervisor = control / 'contracts/v0.3-control/v2/supervisor'
pointer_path = control / 'current-instance.json'
pointer_start = read(pointer_path, 'pointer:start')
data = read(args.editor_log, 'default-editor-log') or b''
lifecycle = []
decoder = json.JSONDecoder()
fields = ['checkpoint', 'reconcile_started_count', 'reconcile_completed_count',
          'last_product_state', 'materializer_command_count', 'supervisor_ensure_count',
          'supervisor_observation_count', 'supervisor_identity_change_count',
          'supervisor_pid', 'coordinator_pid', 'domain_reload_count', 'play_transition_count',
          'selected_instance_id', 'selected_generation_id', 'prerequisite_evidence_disposition',
          'coordinator_admission_disposition', 'post_admission_disposition',
          'post_admission_prerequisite_state', 'post_admission_installed_state',
          'post_admission_configured_state', 'post_admission_mcp_available_state',
          'current_instance_state', 'current_instance_convergence_plan',
          'manager_status_refresh_started_count', 'manager_status_refresh_completed_count',
          'manager_status_refresh_failed_count']
previous = None
for line_number, line in enumerate(data.decode('utf-8', errors='replace').splitlines(), 1):
    marker = 'CODEDB_S12_EVIDENCE '
    if marker not in line:
        continue
    try:
        value, _ = decoder.raw_decode(line.split(marker, 1)[1])
    except ValueError:
        continue
    if value.get('selected_instance_id') != INSTANCE or value.get('selected_generation_id') != GENERATION:
        continue
    row = dict(line=line_number, **pick(value, fields))
    if previous is not None:
        row['delta'] = {key: value[key] - previous[key] for key in fields
                        if isinstance(value.get(key), int) and isinstance(previous.get(key), int)}
    lifecycle.append(row)
    previous = value

events = []
event_data = read(supervisor / 'supervisor-events.jsonl', 'supervisor-events') or b''
for line_number, line in enumerate(event_data.decode('utf-8-sig', errors='replace').splitlines(), 1):
    try:
        value = json.loads(line)
    except ValueError:
        continue
    if str(value.get('detail', '')).startswith('materialize:'):
        events.append(dict(line=line_number, **pick(value, ['sequence', 'at_utc', 'event', 'detail'])))

operations = []
files = sorted((supervisor / 'operation-history').glob('*.json'))
for path in files[:512]:
    value = document(path, 'operation-history/' + path.name)
    if not isinstance(value, dict):
        continue
    if (value.get('selected_instance_id'), value.get('selected_generation_id'), value.get('project_identity')) != (INSTANCE, GENERATION, PROJECT):
        continue
    row = pick(value, ['operation_id', 'request_id', 'manager_action_id', 'name', 'state',
                       'phase', 'owner_epoch', 'selected_instance_id', 'selected_generation_id',
                       'started_at_utc', 'completed_at_utc'])
    result = value.get('result') or {}
    row['result'] = pick(result, ['exit_code', 'timed_out', 'output_overflow', 'output_drain_incomplete'])
    row['stderr_bytes'] = len(result.get('stderr', '').encode('utf-8'))
    for line in result.get('stdout', '').splitlines():
        match = re.match(r'^\[(COMMAND_RESULT|SUPERVISOR_OPERATIONAL_READINESS)\]\s+(.*)$', line.strip())
        if not match:
            continue
        try:
            marker = json.loads(match[2])
        except ValueError:
            continue
        if isinstance(marker, dict):
            row.setdefault('markers', []).append(dict(kind=match[1], **pick(marker, [
                'action', 'outcome', 'phase', 'reason_code', 'mutated_scopes', 'cleanup_state',
                'exit_code', 'observation_id', 'observation_revision', 'revision',
                'owner_epoch', 'state', 'observed_at_utc', 'supervisor_id', 'supervisor_pid'])))
    operations.append(row)

desired = document(control / 'desired-state.json', 'desired-state') or {}
intents = []
for path in sorted((control / 'removal-intents').glob('*.json'))[:64]:
    value = document(path, 'removal-intents/' + path.name)
    if isinstance(value, dict) and value.get('project_identity') == PROJECT:
        intents.append(dict(file=path.name, **pick(value, ['state_id', 'operation_id',
                            'retained_instance_id', 'retained_generation_id'])))
pointer_end = read(pointer_path, 'pointer:end')
report = dict(schema_version=1, scope='EXISTING_RECORDS_ONLY', started_at_utc=start,
              finished_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
              selected_instance_id=INSTANCE, selected_generation_id=GENERATION,
              pointer_bytes_equal=pointer_start is not None and pointer_start == pointer_end,
              editor_nul_byte_count=data.count(bytes([0])),
              lifecycle=lifecycle, lifecycle_state_counts=dict(collections.Counter(
                  row.get('last_product_state') for row in lifecycle)),
              events=events, operations=sorted(operations, key=lambda row:row.get('started_at_utc','')),
              enumerated_history_count=len(files), history_limit=512,
              desired=pick(desired, ['desired_state', 'cleanup_state', 'state_id', 'updated_at_utc']),
              removal_intents=intents, sources=sources, errors=errors,
              limitations=['No Lifecycle UTC or operation ID: no exact cross-stream join.',
                           'Rotating operation history is incomplete; missing files are not retried.',
                           'No historical holder/lease snapshots or cleanup progress fingerprint.',
                           'No UI capture, IPC, MCP, component launch, or process inspection.'])
args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open('x', encoding='utf-8', newline='\n') as stream:
    json.dump(report, stream, ensure_ascii=False, indent=2)
print(json.dumps(dict(output=args.output.name, lifecycle_count=len(lifecycle),
                      states=report['lifecycle_state_counts'], operations=len(operations),
                      errors=len(errors), pointer_bytes_equal=report['pointer_bytes_equal'])))
