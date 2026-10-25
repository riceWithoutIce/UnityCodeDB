const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const root = process.cwd();
const base = 'fe08d6e0961189cedd467487675062564c470644';
const git = (args, options = {}) => cp.execFileSync('git', args, { cwd: root, maxBuffer: 64 * 1024 * 1024, ...options });
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const assert = (ok, message) => { if (!ok) throw Error(message); };
const prior = path.join(root, '.artifacts/tests/cdb-v0.3-candidate-source-integration/207d4249-ded8-4f96-8744-4b03992e31dc');
const source = JSON.parse(fs.readFileSync(path.join(prior, 'candidate-source-manifest.json')));
const plan = JSON.parse(fs.readFileSync(path.join(prior, 'plan.json')));
assert(git(['rev-parse', 'HEAD']).toString().trim() === plan.primary_head, 'Parent drift');
assert(!git(['diff', '--cached', '--name-only']).toString().trim(), 'Existing staged changes');
for (const f of source.files) assert(sha(fs.readFileSync(f.path)) === f.sha256, 'Working source drift: ' + f.path);
const product = [...plan.files.map(f => f.path), 'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs', 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'];
const historical = ['Generations/poc.42/generation-manifest.json', ...['poc.42', 'poc.43', 'poc.44'].map(g => 'Generations/' + g + '/scripts/codedb-project-common.ps1')].map(p => 'com.rice.ai-codedb/Payload~/' + p);
const records = ['cdb-v0.3-candidate-residual-legacy-review', 'cdb-v0.3-candidate-source-integration', 'cdb-v0.3-candidate-freeze-delivery-preparation'].map(p => '.ai/tasks/v0.3.0/' + p);
const recordPaths = records.flatMap(dir => fs.readdirSync(dir).map(n => dir + '/' + n));
assert(recordPaths.every(p => fs.statSync(p).isFile()), 'Unexpected nested task record');
const run = path.join(root, '.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation', crypto.randomUUID());
fs.mkdirSync(run, { recursive: true });
const save = (name, data) => fs.writeFileSync(path.join(run, name), JSON.stringify(data, null, 2), { flag: 'wx' });
const journal = { parent: plan.primary_head, baseline: base, working_manifest: source.source_manifest_sha256, product, historical, records: recordPaths };
save('stage-plan.json', journal);
git(['add', '--', ...product, ...recordPaths]);
for (const p of historical) {
  const accepted = git(['show', base + ':' + p]);
  assert(accepted.equals(fs.readFileSync(p)), 'Historical canonical source drift');
  const blob = git(['rev-parse', base + ':' + p]).toString().trim();
  git(['update-index', '--cacheinfo', '100644,' + blob + ',' + p]);
}
const staged = git(['diff', '--cached', '--name-only', '-z']).toString().split('\0').filter(Boolean);
assert(staged.sort().join('\n') === [...product, ...historical, ...recordPaths].sort().join('\n'), 'Unexpected staged file set');
const entries = git(['ls-files', '--stage', '-z', '--', 'com.rice.ai-codedb/']).toString().split('\0').filter(Boolean).map(s => {
  const [meta, p] = s.split('\t'); const [mode, blob, stage] = meta.split(' ');
  assert(stage === '0', 'Unmerged entry'); return { path: p, mode, blob };
});
assert(entries.length === source.files.length, 'Staged Package file count differs');
const batch = git(['cat-file', '--batch'], { input: entries.map(e => e.blob).join('\n') + '\n' });
const bytesByPath = new Map(); let offset = 0;
for (const e of entries) {
  const newline = batch.indexOf(10, offset), header = batch.subarray(offset, newline).toString().split(' '), size = Number(header[2]);
  assert(header[0] === e.blob && header[1] === 'blob', 'Batch mismatch');
  bytesByPath.set(e.path, batch.subarray(newline + 1, newline + 1 + size)); offset = newline + 1 + size + 1;
}
const differences = [];
const manifest = source.files.map(f => {
  const bytes = bytesByPath.get(f.path), working = fs.readFileSync(f.path);
  assert(bytes, 'Staged path missing');
  if (!bytes.equals(working)) {
    assert(f.path === 'com.rice.ai-codedb/package.json' && bytes.toString().replaceAll('\r\n', '\n') === working.toString().replaceAll('\r\n', '\n'), 'Staging changed source bytes: ' + f.path);
    differences.push(f.path);
  }
  return { path: f.path, sha256: sha(bytes) };
});
const payloadPrefix = 'com.rice.ai-codedb/Payload~/';
const payload = JSON.parse(bytesByPath.get(payloadPrefix + 'payload-manifest.json'));
for (const f of payload.files) assert(sha(bytesByPath.get(payloadPrefix + f.source)) === f.sha256, 'Staged payload hash mismatch: ' + f.source);
const generationPrefix = payloadPrefix + 'Generations/' + payload.generation_id + '/';
const generationBytes = bytesByPath.get(generationPrefix + 'generation-manifest.json');
const generation = JSON.parse(generationBytes);
for (const f of generation.files) assert(sha(bytesByPath.get(generationPrefix + f.path)) === f.sha256, 'Staged generation hash mismatch: ' + f.path);
assert(sha(generationBytes) === 'f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb', 'Generation identity drift');
for (const f of plan.isolation_dirty) assert(sha(fs.readFileSync(path.join(root, '.worktrees/cdb-identity-handoff-heartbeat-followup', f.path))) === f.sha256, 'Isolation dirty drift');
for (const f of source.files) assert(sha(fs.readFileSync(f.path)) === f.sha256, 'Working source changed during staging');
git(['-c', 'core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol', 'diff', '--cached', '--check']);
const tree = git(['write-tree']).toString().trim();
const packageTree = git(['rev-parse', tree + ':com.rice.ai-codedb']).toString().trim();
const identity = sha(Buffer.from(manifest.map(f => f.path + '\t' + f.sha256 + '\n').join('')));
save('staged-source-manifest.json', { source_manifest_sha256: identity, files: manifest });
save('stage-receipt.json', { outcome: 'STAGED_CANDIDATE_PASS', parent: plan.primary_head, staged_paths: staged, root_tree: tree, package_tree: packageTree, staged_source_manifest_sha256: identity, package_files: manifest.length, working_staged_eol_only_differences: differences, historical_exact_blob_restorations: historical, working_source_unchanged: true, isolation_dirty_preserved: true });
console.log(JSON.stringify({ run: path.relative(root, run).replaceAll('\\', '/'), package_tree: packageTree, staged_files: staged.length, package_files: manifest.length, staged_source_manifest_sha256: identity, outcome: 'STAGED_CANDIDATE_PASS' }, null, 2));
