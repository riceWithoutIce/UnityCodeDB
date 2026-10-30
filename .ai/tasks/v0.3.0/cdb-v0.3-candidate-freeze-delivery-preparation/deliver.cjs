const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const root = process.cwd();
const testRootArgument = process.argv[2];
if (!testRootArgument || process.argv[3] !== '--editor-closed-confirmed') throw Error('Explicit test root and current human closed-Editor confirmation required');
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const assert = (ok, message) => { if (!ok) throw Error(message); };
const git = args => cp.execFileSync('git', args, { maxBuffer: 4 * 1024 * 1024 }).toString().trim();
const task = '.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation';
const testRoot = fs.realpathSync(testRootArgument);
const project = fs.realpathSync(path.join(testRoot, 'CodedbTest_2'));
const packageParent = fs.realpathSync(path.join(testRoot, 'Packages'));
const inside = (p, base) => p.toLowerCase().startsWith((base + path.sep).toLowerCase());
assert(inside(project, testRoot) && inside(packageParent, testRoot), 'External project/package parent escapes designated test root');
const relativeDestination = 'Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb';
const destinationParent = path.join(testRoot, 'Packages/1105696-v03-reviewed-candidate');
const destination = path.join(testRoot, relativeDestination);
assert(!fs.existsSync(destinationParent), 'Preserve existing candidate destination');
const sourceParent = path.join(root, task, 'export-1105696/review');
const source = path.join(sourceParent, 'com.rice.ai-codedb');
const evidence = JSON.parse(fs.readFileSync(path.join(root, task, 'export-1105696-evidence/verification.json')));
assert(evidence.outcome === 'EXPORT_BYTE_PROVENANCE_PASS', 'Export was not accepted');
const candidate = '11056964da1143955ed69a067361622799e3d6f2';
assert(evidence.candidate_commit === candidate && git(['rev-parse', 'HEAD']) === candidate, 'Candidate drift');
const zip = path.join(root, task, 'export-1105696/com.rice.ai-codedb.zip');
assert(sha(fs.readFileSync(zip)) === evidence.artifact_sha256, 'ZIP drift');
const manifest = JSON.parse(fs.readFileSync(path.join(root, task, 'export-1105696-evidence/artifact-file-manifest.json')));
const paths = manifest.files.map(f => {
  assert(f.path.startsWith('com.rice.ai-codedb/'), 'Unexpected manifest prefix');
  const relative = f.path.slice('com.rice.ai-codedb/'.length);
  assert(!relative.split('/').some(s => s === '..' || s === ''), 'Invalid artifact relative path');
  assert(inside(fs.realpathSync(path.join(source, relative)), fs.realpathSync(source)), 'Artifact source escapes Package');
  assert(sha(fs.readFileSync(path.join(source, relative))) === f.sha256, 'Artifact source drift: ' + relative);
  return { relative, sha256: f.sha256 };
});
// Count exact inventory independently; all required file paths/hashes checked above.
const countFiles = dir => fs.readdirSync(dir, { withFileTypes: true }).reduce((n, e) => {
  assert(!e.isSymbolicLink(), 'Unexpected Package link');
  return n + (e.isDirectory() ? countFiles(path.join(dir, e.name)) : 1);
}, 0);
assert(paths.length === 669 && countFiles(source) === 669, 'Artifact inventory differs');
const oldRef = 'file:../../Packages/fe08d6e-c-scheme-observation/com.rice.ai-codedb';
const newRef = 'file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb';
const references = ['Packages/manifest.json', 'Packages/packages-lock.json'].map(relative => {
  const absolute = path.join(project, relative);
  assert(inside(fs.realpathSync(absolute), project), 'Reference escapes target project');
  const before = fs.readFileSync(absolute), text = before.toString('utf8'), json = JSON.parse(text);
  const ref = relative.endsWith('manifest.json') ? json.dependencies['com.rice.ai-codedb'] : json.dependencies['com.rice.ai-codedb'].version;
  assert(ref === oldRef && text.split(oldRef).length === 2, 'Reference preimage drift: ' + relative);
  const proposed = Buffer.from(text.replace(oldRef, newRef), 'utf8');
  assert(Buffer.from(proposed.toString('utf8').replace(newRef, oldRef), 'utf8').equals(before), 'Unrelated JSON bytes changed');
  return { relative, absolute, before, proposed };
});
const protectedFiles = ['.codex/config.toml', 'AIWork/.runtime/codedb/control/current-instance.json', 'Assets/CodeDBValidation/CodeDBQueryProbe.cs', 'Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs'].map(relative => {
  const p = path.join(project, relative);
  return { relative, sha256: fs.existsSync(p) ? sha(fs.readFileSync(p)) : null };
});
const indexPath = git(['rev-parse', '--path-format=absolute', '--git-path', 'index']);
const indexHash = sha(fs.readFileSync(indexPath));
const run = path.join(root, task, 'delivery-1105696');
assert(!fs.existsSync(run), 'Preserve previous delivery evidence');
assert(inside(fs.realpathSync(path.dirname(run)), fs.realpathSync(root)), 'Evidence root escapes repository');
fs.mkdirSync(run);
const journal = { candidate_commit: candidate, started_utc: new Date().toISOString(), human_editor_closed: true, destination: '<external-test-root>/' + relativeDestination, steps: [] };
const save = () => fs.writeFileSync(path.join(run, 'journal.json'), JSON.stringify(journal, null, 2));
const step = (name, fields = {}) => { journal.steps.push({ at_utc: new Date().toISOString(), name, ...fields }); save(); };
const result = { outcome: 'RUNNING', candidate_commit: candidate, destination: journal.destination, old_reference: oldRef, new_reference: newRef, protected_files: protectedFiles };
save();
try {
  for (const f of references) {
    const backup = path.join(run, 'preimages', f.relative);
    fs.mkdirSync(path.dirname(backup), { recursive: true });
    fs.writeFileSync(backup, f.before, { flag: 'wx' });
  }
  step('reference_preimages_saved');
  fs.mkdirSync(destination, { recursive: true });
  assert(inside(fs.realpathSync(destination), packageParent), 'New destination escapes package parent');
  step('copy_started');
  for (const f of paths) {
    const target = path.join(destination, f.relative);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(path.join(source, f.relative), target, fs.constants.COPYFILE_EXCL);
    assert(sha(fs.readFileSync(target)) === f.sha256, 'Delivered file differs: ' + f.relative);
  }
  assert(countFiles(destination) === paths.length, 'Delivered inventory differs');
  step('all_669_delivered_file_hashes_pass');
  for (const f of references) assert(fs.readFileSync(f.absolute).equals(f.before), 'Reference changed during copy');
  for (const f of references) {
    step('reference_write_pending', { path: '<external-test-root>/CodedbTest_2/' + f.relative });
    fs.writeFileSync(f.absolute, f.proposed);
    assert(fs.readFileSync(f.absolute).equals(f.proposed), 'Reference write differs');
    const json = JSON.parse(fs.readFileSync(f.absolute, 'utf8'));
    const ref = f.relative.endsWith('manifest.json') ? json.dependencies['com.rice.ai-codedb'] : json.dependencies['com.rice.ai-codedb'].version;
    assert(ref === newRef && fs.realpathSync(path.resolve(path.dirname(f.absolute), ref.slice(5))) === fs.realpathSync(destination), 'Reference resolves incorrectly');
    step('reference_write_verified', { path: '<external-test-root>/CodedbTest_2/' + f.relative });
  }
  for (const f of protectedFiles) {
    const p = path.join(project, f.relative), actual = fs.existsSync(p) ? sha(fs.readFileSync(p)) : null;
    assert(actual === f.sha256, 'Protected consumer file changed: ' + f.relative);
  }
  assert(sha(fs.readFileSync(indexPath)) === indexHash && git(['rev-parse', 'HEAD']) === candidate, 'Source index/HEAD changed');
  result.outcome = 'DELIVERY_PASS'; result.file_count = paths.length; result.reference_writes = 2;
  result.reference_hashes = references.map(f => ({ path: f.relative, before_sha256: sha(f.before), after_sha256: sha(fs.readFileSync(f.absolute)) }));
  result.source_index_and_head_unchanged = true; result.protected_consumer_files_unchanged = true;
  step('delivery_pass');
} catch (error) {
  result.outcome = 'DELIVERY_FAILED_STOPPED'; result.error = error.message;
  step('failed_no_automatic_rollback', { error: error.message });
  process.exitCode = 1;
} finally {
  result.finished_utc = new Date().toISOString(); result.unity = 'NOT_RUN'; result.mcp = 'NOT_RUN'; result.install = 'NOT_RUN';
  fs.writeFileSync(path.join(run, 'receipt.json'), JSON.stringify(result, null, 2), { flag: 'wx' });
  console.log(JSON.stringify(result, null, 2));
}
