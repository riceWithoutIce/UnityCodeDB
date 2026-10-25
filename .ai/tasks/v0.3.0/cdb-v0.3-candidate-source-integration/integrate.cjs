const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const root = process.cwd();
const baseline = 'fe08d6e0961189cedd467487675062564c470644';
const wt = path.join(root, '.worktrees/cdb-identity-handoff-heartbeat-followup');
const prefix = 'com.rice.ai-codedb/';
const evidence = prefix + 'Editor/AICodedbLifecycleEvidence.cs';
const allowed = [
  'Editor/AICodedbEditorLifecycle.cs', 'Editor/AICodedbHostPayloadMaterializer.cs',
  'Editor/AICodedbLifecycleEvidence.cs', 'Editor/AICodedbManagerTransitionEvidence.cs',
  'Editor/AICodedbManagerTransitionEvidence.cs.meta', 'Editor/AICodedbManagerWindow.cs',
  'Editor/AICodedbSupervisorBridge.cs', 'Tests/Editor/AICodedbEditorLifecycleTests.cs',
  'Tests/Editor/AICodedbManagerUiTests.cs', 'Tests~/test-codedb-project-supervisor.mjs',
  'Tests~/test-codedb-supervisor-ipc-diagnostics.ps1', 'Tools~/codedb-instance-engine.ps1',
  'Tools~/codedb-project-supervisor.mjs'
].map(p => prefix + p);
const docs = [
  'v0.3.0-p0-codedb-responsibility-contract.md', 'v0.3.0-p0-host-action-execution.md',
  'v0.3.0-p0-project-integration-reinstall-contract.md', 'v0.3.0-roadmap.md',
  'workflow/safe-execution.md'
].map(p => prefix + 'Documentation~/' + p);
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const blob = b => crypto.createHash('sha1').update(Buffer.from('blob ' + b.length + '\0')).update(b).digest('hex');
const git = (args, cwd = root) => cp.execFileSync('git', args, { cwd, maxBuffer: 16 * 1024 * 1024 });
const assert = (ok, message) => { if (!ok) throw Error(message); };
const read = (p, cwd = root) => fs.existsSync(path.join(cwd, p)) ? fs.readFileSync(path.join(cwd, p)) : null;
const entries = git(['ls-tree', '-r', '-z', baseline, '--', prefix]).toString().split('\0').filter(Boolean).map(s => {
  const [meta, p] = s.split('\t'); return { path: p, blob: meta.split(' ')[2] };
});
const batch = cp.execFileSync('git', ['cat-file', '--batch'], { cwd: root, input: entries.map(e => e.blob).join('\n') + '\n', maxBuffer: 64 * 1024 * 1024 });
const baselineBytes = new Map();
let offset = 0;
for (const e of entries) {
  const newline = batch.indexOf(10, offset);
  const header = batch.subarray(offset, newline).toString().split(' ');
  assert(header[0] === e.blob && header[1] === 'blob', 'Unexpected cat-file response');
  const size = Number(header[2]);
  baselineBytes.set(e.path, batch.subarray(newline + 1, newline + 1 + size));
  offset = newline + 1 + size + 1;
}
const equivalent = (p, bytes) => {
  const original = baselineBytes.get(p);
  return bytes && (bytes.equals(original) || (!bytes.includes(0) && !original.includes(0)
    && bytes.toString('utf8').replaceAll('\r\n', '\n') === original.toString('utf8').replaceAll('\r\n', '\n')));
};
const index = git(['rev-parse', '--path-format=absolute', '--git-path', 'index']).toString().trim();
const dirty = git(['status', '--porcelain=v1', '-z'], wt).toString().split('\0').filter(Boolean).map(s => s.slice(3));
const isolation = dirty.map(p => ({ path: p, sha256: sha(read(p, wt)) }));
const inputs = new Map();
for (const p of allowed) inputs.set(p, p === evidence ? read(p, wt) : git(['show', baseline + ':' + p]));
assert(sha(inputs.get(evidence)) === 'e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e', 'F01 source drift');
const primary = entries.map(e => {
  const bytes = read(e.path);
  if (!allowed.includes(e.path) && !docs.includes(e.path)) assert(equivalent(e.path, bytes), 'Unplanned primary content difference: ' + e.path);
  return { ...e, sha256: bytes ? sha(bytes) : null };
});
const tracked = git(['ls-files', '-z', '--', prefix]).toString().split('\0').filter(Boolean);
assert(tracked.every(p => entries.some(e => e.path === p)), 'Unexpected primary-only tracked Package file');
const untracked = git(['ls-files', '--others', '--exclude-standard', '-z', '--', prefix]).toString().split('\0').filter(Boolean);
assert(untracked.length === 0, 'Unexpected primary untracked Package file');
const run = path.join(root, '.artifacts/tests/cdb-v0.3-candidate-source-integration', crypto.randomUUID());
fs.mkdirSync(run, { recursive: true });
const plan = {
  baseline, started_utc: new Date().toISOString(), primary_head: git(['rev-parse', 'HEAD']).toString().trim(),
  index_sha256: sha(fs.readFileSync(index)), isolation_dirty: isolation,
  files: allowed.map(p => ({ path: p, before_sha256: primary.find(e => e.path === p).sha256, proposed_sha256: sha(inputs.get(p)) })),
  preserved_docs: docs, primary_preimages: primary
};
const save = (name, data) => fs.writeFileSync(path.join(run, name), JSON.stringify(data, null, 2), { flag: 'wx' });
save('plan.json', plan);
for (const f of plan.files) {
  const bytes = read(f.path);
  assert((bytes ? sha(bytes) : null) === f.before_sha256, 'Preimage drift: ' + f.path);
  if (bytes) {
    const destination = path.join(run, 'preimages', f.path);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, bytes, { flag: 'wx' });
  }
}
const steps = [];
for (const f of plan.files) {
  const bytes = read(f.path);
  assert((bytes ? sha(bytes) : null) === f.before_sha256, 'Pre-write drift: ' + f.path);
  fs.writeFileSync(path.join(root, f.path), inputs.get(f.path), { flag: bytes ? 'w' : 'wx' });
  assert(sha(read(f.path)) === f.proposed_sha256, 'Write verification failed');
  steps.push(f.path);
  fs.writeFileSync(path.join(run, 'journal.json'), JSON.stringify(steps, null, 2));
}
const manifest = entries.map(e => {
  const bytes = read(e.path);
  if (allowed.includes(e.path)) assert(bytes.equals(inputs.get(e.path)), 'Integrated byte mismatch: ' + e.path);
  else assert(sha(bytes) === primary.find(p => p.path === e.path).sha256, 'Protected file changed: ' + e.path);
  return { path: e.path, sha256: sha(bytes), differs_from_baseline: blob(bytes) !== e.blob, content_differs_from_baseline: !equivalent(e.path, bytes) };
});
assert(manifest.filter(e => e.content_differs_from_baseline).map(e => e.path).sort().join('\n') === [...docs, evidence].sort().join('\n'), 'Final candidate content difference set mismatch');
for (const f of isolation) assert(sha(read(f.path, wt)) === f.sha256, 'Isolation dirty file changed');
assert(sha(fs.readFileSync(index)) === plan.index_sha256, 'Index changed');
assert(git(['rev-parse', 'HEAD']).toString().trim() === plan.primary_head, 'HEAD changed');
const canonical = manifest.map(e => e.path + '\t' + e.sha256 + '\n').join('');
save('candidate-source-manifest.json', { schema_version: 1, baseline, source_manifest_sha256: sha(Buffer.from(canonical)), files: manifest });
save('integration-receipt.json', { outcome: 'SOURCE_INTEGRATION_PASS', completed_utc: new Date().toISOString(), changed_files: allowed.length, package_files: manifest.length, preserved_eol_only_files: manifest.filter(e => e.differs_from_baseline && !e.content_differs_from_baseline).length, source_manifest_sha256: sha(Buffer.from(canonical)), index_unchanged: true, isolation_dirty_preserved: true, protected_primary_preserved: true });
console.log(JSON.stringify({ run: path.relative(root, run).replaceAll('\\', '/'), changed_files: allowed.length, package_files: manifest.length, source_manifest_sha256: sha(Buffer.from(canonical)), outcome: 'SOURCE_INTEGRATION_PASS' }, null, 2));
