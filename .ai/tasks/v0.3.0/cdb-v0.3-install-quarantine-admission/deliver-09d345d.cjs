const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = process.cwd();
const externalRootArgument = process.argv[2];
if (!externalRootArgument || process.argv[3] !== '--editor-closed-confirmed') throw Error('Explicit test root and closed Editor confirmation required');
const externalRoot = fs.realpathSync(externalRootArgument);
const project = fs.realpathSync(path.join(externalRoot, 'CodedbTest_2'));
const packageParent = fs.realpathSync(path.join(externalRoot, 'Packages'));
const task = '.ai/tasks/v0.3.0/cdb-v0.3-install-quarantine-admission';
const exportRoot = path.join(root, '.artifacts/tests/cdb-v0.3-install-quarantine-admission/export-09d345d');
const source = path.join(exportRoot, 'review/com.rice.ai-codedb');
const verify = JSON.parse(fs.readFileSync(path.join(root, '.artifacts/tests/cdb-v0.3-install-quarantine-admission/export-09d345d-evidence/verification.json')));
const candidate = '09d345d96ec782be2ac101016d8b75b14bce6000';
const destinationRelative = 'Packages/09d345d-v03-quarantine-admission/com.rice.ai-codedb';
const destinationParent = path.join(externalRoot, 'Packages/09d345d-v03-quarantine-admission');
const destination = path.join(externalRoot, destinationRelative);
const deliveryRoot = path.join(root, '.artifacts/tests/cdb-v0.3-install-quarantine-admission/delivery-09d345d');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const inside = (value, base) => value.toLowerCase().startsWith((base + path.sep).toLowerCase());
const assert = (value, message) => { if (!value) throw Error(message); };
assert(verify.outcome === 'EXPORT_BYTE_PROVENANCE_PASS' && verify.candidate_commit === candidate, 'Export candidate evidence mismatch');
assert(!fs.existsSync(destinationParent), 'Preserve existing candidate destination');
assert(inside(destinationParent, packageParent), 'Destination escapes designated Packages root');
assert(!fs.existsSync(deliveryRoot), 'Preserve previous delivery evidence');
const refs = ['Packages/manifest.json', 'Packages/packages-lock.json'].map(relative => {
  const file = path.join(project, relative);
  const before = fs.readFileSync(file);
  const text = before.toString('utf8');
  const json = JSON.parse(text);
  const current = relative.endsWith('manifest.json') ? json.dependencies['com.rice.ai-codedb'] : json.dependencies['com.rice.ai-codedb'].version;
  assert(typeof current === 'string' && current.startsWith('file:../../Packages/'), 'Unexpected current CodeDB reference: ' + relative);
  assert(text.split(current).length === 2, 'Reference occurrence is ambiguous: ' + relative);
  const next = 'file:../../' + destinationRelative;
  const proposed = Buffer.from(text.replace(current, next), 'utf8');
  assert(Buffer.from(proposed.toString('utf8').replace(next, current), 'utf8').equals(before), 'Unrelated JSON bytes changed: ' + relative);
  return { relative, file, current, next, before, proposed };
});
const protectedFiles = ['.codex/config.toml', 'AIWork/.runtime/codedb/control/current-instance.json', 'Assets/CodeDBValidation/CodeDBQueryProbe.cs', 'Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs'].map(relative => {
  const file = path.join(project, relative);
  return { relative, sha256: fs.existsSync(file) ? sha(fs.readFileSync(file)) : null };
});
const journal = { outcome: 'RUNNING', candidate_commit: candidate, source: '<repository-root>/.artifacts/tests/cdb-v0.3-install-quarantine-admission/export-09d345d/review/com.rice.ai-codedb', destination: '<external-test-root>/' + destinationRelative, steps: [], editor_closed_confirmed: true };
fs.mkdirSync(deliveryRoot, { recursive: true });
const save = () => fs.writeFileSync(path.join(deliveryRoot, 'journal.json'), JSON.stringify(journal, null, 2) + '\n');
const step = (name, fields = {}) => { journal.steps.push({ at_utc: new Date().toISOString(), name, ...fields }); save(); };
const result = { outcome: 'RUNNING', candidate_commit: candidate, destination: journal.destination, reference_before: refs.map(r => ({ path: r.relative, value: r.current })), protected_files: protectedFiles };
save();
try {
  for (const ref of refs) { const backup = path.join(deliveryRoot, 'preimages', ref.relative); fs.mkdirSync(path.dirname(backup), { recursive: true }); fs.writeFileSync(backup, ref.before, { flag: 'wx' }); }
  step('reference_preimages_saved');
  fs.mkdirSync(destination, { recursive: true });
  assert(inside(fs.realpathSync(destination), packageParent), 'Resolved destination escapes Packages root');
  step('copy_started');
  for (const entry of verify.files) {
    assert(entry.path.startsWith('com.rice.ai-codedb/'), 'Unexpected artifact path');
    const relative = entry.path.slice('com.rice.ai-codedb/'.length);
    const from = path.join(source, relative);
    const to = path.join(destination, relative);
    assert(inside(fs.realpathSync(from), fs.realpathSync(source)), 'Source escapes candidate Package');
    assert(sha(fs.readFileSync(from)) === entry.sha256, 'Source artifact drift: ' + relative);
    fs.mkdirSync(path.dirname(to), { recursive: true });
    fs.copyFileSync(from, to, fs.constants.COPYFILE_EXCL);
    assert(sha(fs.readFileSync(to)) === entry.sha256, 'Delivered artifact drift: ' + relative);
  }
  assert(fs.readdirSync(destination, { withFileTypes: true }).length > 0, 'Destination is empty');
  step('all_exported_files_delivered');
  for (const ref of refs) assert(fs.readFileSync(ref.file).equals(ref.before), 'Reference changed during copy: ' + ref.relative);
  for (const ref of refs) {
    fs.writeFileSync(ref.file, ref.proposed);
    assert(fs.readFileSync(ref.file).equals(ref.proposed), 'Reference write differs: ' + ref.relative);
    const json = JSON.parse(fs.readFileSync(ref.file, 'utf8'));
    const value = ref.relative.endsWith('manifest.json') ? json.dependencies['com.rice.ai-codedb'] : json.dependencies['com.rice.ai-codedb'].version;
    assert(value === ref.next, 'Reference did not switch: ' + ref.relative);
    const resolved = path.resolve(path.dirname(ref.file), value.slice(5));
    assert(fs.realpathSync(resolved) === fs.realpathSync(destination), 'Reference resolves to wrong destination: ' + ref.relative);
    step('reference_write_verified', { path: '<external-test-root>/CodedbTest_2/' + ref.relative });
  }
  for (const protectedFile of protectedFiles) {
    const file = path.join(project, protectedFile.relative);
    assert((fs.existsSync(file) ? sha(fs.readFileSync(file)) : null) === protectedFile.sha256, 'Protected consumer file changed: ' + protectedFile.relative);
  }
  result.outcome = 'DELIVERY_PASS';
  result.file_count = verify.file_count;
  result.zip_sha256 = verify.zip_sha256;
  result.reference_after = refs.map(ref => ({ path: ref.relative, value: ref.next, before_sha256: sha(ref.before), after_sha256: sha(fs.readFileSync(ref.file)) }));
  result.protected_consumer_files_unchanged = true;
  step('delivery_pass');
} catch (error) {
  result.outcome = 'DELIVERY_FAILED_STOPPED';
  result.error = error.message;
  step('failed_no_automatic_rollback', { error: error.message });
  process.exitCode = 1;
} finally {
  result.finished_utc = new Date().toISOString();
  result.install = 'NOT_RUN';
  result.unity = 'HUMAN_CLOSED_BEFORE_DELIVERY';
  result.mcp = 'NOT_RUN';
  fs.writeFileSync(path.join(deliveryRoot, 'receipt.json'), JSON.stringify(result, null, 2) + '\n', { flag: 'wx' });
  console.log(JSON.stringify(result, null, 2));
}
