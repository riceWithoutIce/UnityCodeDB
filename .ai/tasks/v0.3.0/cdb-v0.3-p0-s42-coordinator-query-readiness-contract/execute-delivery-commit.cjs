const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = process.cwd();
const task = path.join(root, '.ai/tasks/v0.3.0/cdb-v0.3-p0-s42-coordinator-query-readiness-contract');
const candidate = path.join(root, '.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract');
const evidence = path.join(root, '.artifacts/tests/s42-commit-export/execution-a');
function assert(ok, message) { if (!ok) throw Error(message); }
function git(cwd, args) {
  const r = spawnSync('git', ['-C', cwd, ...args], {encoding:null});
  assert(r.status === 0, 'git failed: '+args.join(' ')+' '+r.stderr);
  return r.stdout;
}
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const snapshot = JSON.parse(fs.readFileSync(path.join(task, 'SOURCE-SHA256.json')));
assert(!fs.existsSync(evidence), 'Preserve existing execution evidence');
assert(git(candidate,['branch','--show-current']).toString().trim() === snapshot.branch, 'Branch drift');
assert(git(candidate,['rev-parse','HEAD']).toString().trim() === snapshot.base, 'Base drift');
assert(git(candidate,['diff','--cached','--name-only']).length === 0, 'Index not empty');
const changes = git(candidate,['status','--porcelain','--untracked-files=all']).toString().trimEnd().split(/\r?\n/).map(s=>s.slice(3)).sort();
assert(JSON.stringify(changes) === JSON.stringify(snapshot.sources.map(s=>s.path).sort()), 'Dirty scope drift');
for (const s of snapshot.sources) assert(hash(fs.readFileSync(path.join(candidate,s.path))) === s.sha256, 'Source drift: '+s.path);
const primaryIndex = git(root,['rev-parse','--path-format=absolute','--git-path','index']).toString().trim();
const primaryHash = hash(fs.readFileSync(primaryIndex));
fs.mkdirSync(evidence,{recursive:true});
fs.writeFileSync(path.join(evidence,'approval.json'), JSON.stringify({at:new Date().toISOString(),approval:'User explicitly approved COMMIT-EXPORT-PROPOSAL.md',primary_index_before:primaryHash,sources:snapshot.sources},null,2));
for (const s of snapshot.sources) {
  const blob = git(candidate,['hash-object','-w','--no-filters','--',path.join(candidate,s.path)]).toString().trim();
  git(candidate,['update-index','--add','--cacheinfo','100644,'+blob+','+s.path]);
  assert(hash(git(candidate,['cat-file','blob',':'+s.path])) === s.sha256,'Indexed bytes drift: '+s.path);
}
assert(JSON.stringify(git(candidate,['diff','--cached','--name-only']).toString().trim().split(/\r?\n/).sort()) === JSON.stringify(snapshot.sources.map(s=>s.path).sort()), 'Staged scope mismatch');
const tree = git(candidate,['write-tree']).toString().trim();
assert(tree === 'cf162955d6f3e89daa0bf32b3db8110219f161f6', 'Tree drift');
const output = git(candidate,['commit','-m','Fix Supervisor watch service startup and readiness contract']).toString();
fs.writeFileSync(path.join(evidence,'commit.log'),output);
const commit = git(candidate,['rev-parse','HEAD']).toString().trim();
assert(git(candidate,['rev-parse','HEAD^{tree}']).toString().trim() === tree, 'Commit tree mismatch');
assert(git(candidate,['rev-parse','HEAD^']).toString().trim() === snapshot.base, 'Commit parent mismatch');
assert(git(candidate,['diff','--cached','--name-only']).length===0,'Post-commit index dirty');
assert(git(candidate,['status','--porcelain','--untracked-files=all']).length===0,'Post-commit source dirty');
assert(hash(fs.readFileSync(primaryIndex)) === primaryHash, 'Primary index changed');
const receipt={commit,tree,branch:snapshot.branch,parent:snapshot.base,source_files:snapshot.sources,primary_index_before:primaryHash,primary_index_after:hash(fs.readFileSync(primaryIndex)),export_relative:'.artifacts/exports/s42-query-readiness-'+commit.slice(0,7)};
fs.writeFileSync(path.join(evidence,'commit.json'),JSON.stringify(receipt,null,2));
console.log(JSON.stringify(receipt,null,2));
