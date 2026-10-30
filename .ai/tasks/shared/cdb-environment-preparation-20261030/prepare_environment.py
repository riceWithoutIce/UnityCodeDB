"""Task-owned preservation and inventory. No deletion, Git mutation or runtime calls."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import zipfile

REPO = Path('G:/RiceProgram/UnityCodeDB')
TEST = Path('G:/RiceProgram/Test/CodedbTest')
STAMP = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
OUT = REPO / '.artifacts/maintenance' / ('environment-preparation-' + STAMP)


def run(args, cwd=REPO):
    return subprocess.run(args, cwd=cwd, capture_output=True, check=True).stdout


def save_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def safe(path, root):
    path = Path(os.path.abspath(path))
    root = Path(os.path.abspath(root))
    if path != root and root not in path.parents:
        raise RuntimeError('outside root: ' + str(path))
    for p in (path, *path.parents):
        if p.exists() and p.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
            raise RuntimeError('reparse point: ' + str(p))
    return path


def walk(root):
    safe(root, root)
    for base, dirs, files in os.walk(root, followlinks=False):
        for n in dirs:
            safe(Path(base) / n, root)
        for n in sorted(files):
            yield safe(Path(base) / n, root)


def stats(root):
    entries = []
    for p in walk(root):
        s = p.stat()
        entries.append({'path': p.relative_to(root).as_posix(), 'bytes': s.st_size,
                        'mtime_ns': s.st_mtime_ns})
    return {'root': str(root), 'files': len(entries),
            'bytes': sum(e['bytes'] for e in entries), 'entries': entries}


def archive(destination, pairs):
    """Verify every archived file against both source reread and ZIP readback."""
    manifest = []
    names = set()
    with zipfile.ZipFile(destination, 'x', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p, name in pairs:
            if name in names:
                raise RuntimeError('duplicate ZIP name: ' + name)
            names.add(name)
            s1 = p.stat()
            raw = p.read_bytes()
            s2 = p.stat()
            if (s1.st_size, s1.st_mtime_ns) != (s2.st_size, s2.st_mtime_ns):
                raise RuntimeError('source changed during read: ' + str(p))
            z.writestr(name, raw)
            manifest.append({'source': str(p), 'entry': name, 'bytes': len(raw),
                             'sha256': digest(raw), 'mtime_ns': s2.st_mtime_ns})
    with zipfile.ZipFile(destination) as z:
        if len(z.infolist()) != len(manifest):
            raise RuntimeError('ZIP count mismatch')
        for e in manifest:
            if digest(z.read(e['entry'])) != e['sha256']:
                raise RuntimeError('ZIP content mismatch: ' + e['entry'])
            if digest(Path(e['source']).read_bytes()) != e['sha256']:
                raise RuntimeError('source changed after copy: ' + e['source'])
    result = {'archive': str(destination), 'archive_bytes': destination.stat().st_size,
              'archive_sha256': digest(destination.read_bytes()), 'files': len(manifest),
              'source_bytes': sum(e['bytes'] for e in manifest), 'entries': manifest,
              'verification': 'ALL_SOURCE_REREAD_AND_ZIP_CONTENT_SHA256_MATCH'}
    save_json(destination.with_suffix('.manifest.json'), result)
    return {k: v for k, v in result.items() if k != 'entries'}


def main():
    safe(REPO, REPO)
    safe(TEST, TEST)
    safe(OUT, REPO)
    OUT.mkdir(parents=True, exist_ok=False)
    result = {'status': 'IN_PROGRESS', 'storage': str(OUT),
              'started_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'worktrees': [], 'projects': [], 'cleanup_candidates': [],
              'execution': {'removed_paths': [], 'moved_paths': [], 'git_mutations': [],
                            'remote_writes': [], 'runtime_commands': []}}
    save_json(OUT / 'result.json', result)
    try:
        porcelain = run(['git', 'worktree', 'list', '--porcelain']).decode('utf-8')
        roots = [Path(x[9:]) for x in porcelain.splitlines() if x.startswith('worktree ')]
        for i, root in enumerate(roots):
            safe(root, REPO)
            dest = OUT / ('worktree-%02d' % i)
            dest.mkdir()
            before = run(['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all'], root)
            (dest / 'status-before.z').write_bytes(before)
            (dest / 'tracked-vs-HEAD.patch').write_bytes(run(['git', 'diff', '--binary', 'HEAD'], root))
            (dest / 'staged.patch').write_bytes(run(['git', 'diff', '--binary', '--cached'], root))
            (dest / 'unstaged.patch').write_bytes(run(['git', 'diff', '--binary'], root))
            index = Path(run(['git', 'rev-parse', '--path-format=absolute', '--git-path', 'index'], root).decode().strip())
            (dest / 'index.bin').write_bytes(index.read_bytes())
            tracked = run(['git', 'diff', '--name-only', '-z', 'HEAD'], root).split(b'\0')
            untracked = run(['git', 'ls-files', '--others', '--exclude-standard', '-z'], root).split(b'\0')
            paths = sorted({os.fsdecode(p) for p in tracked + untracked if p})
            pairs = []
            for rel in paths:
                p = safe(root / rel, root)
                if p.is_file():
                    pairs.append((p, rel.replace('\\', '/')))
            frozen = archive(dest / 'dirty-content.zip', pairs)
            after = run(['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all'], root)
            if before != after:
                raise RuntimeError('Git status changed during snapshot: ' + str(root))
            head = run(['git', 'rev-parse', 'HEAD'], root).decode().strip()
            result['worktrees'].append({'root': str(root), 'head': head,
                'branch': run(['git', 'branch', '--show-current'], root).decode().strip(),
                'dirty_path_count': len(paths), 'missing_paths': [p for p in paths if not (root / p).is_file()],
                'status_stable': True, 'preserved': frozen})
        bundle = OUT / 'repository-refs.bundle'
        (OUT / 'bundle-create.txt').write_bytes(run(['git', 'bundle', 'create', str(bundle), '--all']))
        verified = subprocess.run(['git', 'bundle', 'verify', str(bundle)], cwd=REPO, capture_output=True, check=True)
        (OUT / 'bundle-verify.txt').write_bytes(verified.stdout + verified.stderr)
        reachable = set(run(['git', 'rev-list', '--all']).decode().splitlines())
        if any(w['head'] not in reachable for w in result['worktrees']):
            raise RuntimeError('worktree HEAD not reachable from saved refs')
        result['bundle'] = {'path': str(bundle), 'bytes': bundle.stat().st_size,
                            'sha256': digest(bundle.read_bytes()), 'verify': 'PASS',
                            'all_six_worktree_heads_reachable': True}
        project_inventories = OUT / 'projects'
        project_inventories.mkdir()
        for i in range(9):
            root = safe(TEST / ('CodedbTest_' + str(i)), TEST)
            inventory = stats(root)
            save_json(project_inventories / (root.name + '-inventory.json'), inventory)
            obj = json.loads((root / 'Packages/manifest.json').read_text(encoding='utf-8-sig'))
            ref = obj['dependencies']['com.rice.ai-codedb']
            lock = json.loads((root / 'Packages/packages-lock.json').read_text(encoding='utf-8-sig'))
            if lock['dependencies']['com.rice.ai-codedb']['version'] != ref:
                raise RuntimeError('manifest/lock mismatch: ' + str(root))
            if not ref.startswith('file:'):
                raise RuntimeError('unexpected nonlocal package: ' + ref)
            package = safe(root / 'Packages' / ref[5:], TEST)
            project = {'root': str(root), 'files': inventory['files'], 'bytes': inventory['bytes'],
                       'reference': ref, 'package': str(package),
                       'role': 'CURRENT_HUMAN_BASELINE' if i == 8 else
                               'RETAIN_MIGRATION_REPRO' if i == 7 else 'HISTORICAL_ARCHIVE_CANDIDATE'}
            if i <= 6:
                pairs = []
                for p in walk(root):
                    rel = p.relative_to(root).as_posix()
                    # Library/CodeDB is evidence; the rest of Library is omitted from compact archive.
                    if rel.startswith('Library/') and not rel.startswith('Library/CodeDB/'):
                        continue
                    pairs.append((p, p.relative_to(TEST).as_posix()))
                pairs.extend((p, p.relative_to(TEST).as_posix()) for p in walk(package))
                project['preserved'] = archive(project_inventories / (root.name + '-compact.zip'), pairs)
                project['archive_limit'] = 'EVIDENCE_SNAPSHOT_NOT_FULL_LIBRARY_OR_VALIDATED_RUNTIME_REPLAY'
            result['projects'].append(project)
            if 2 <= i <= 6:
                for child in sorted((root / 'Library').iterdir()):
                    if child.name.casefold() == 'codedb':
                        continue
                    data = stats(child) if child.is_dir() else {'files': 1, 'bytes': child.stat().st_size}
                    result['cleanup_candidates'].append({'path': str(child), 'type': 'UNITY_GENERATED_LIBRARY_CHILD',
                        'files': data['files'], 'bytes': data['bytes'], 'authorized_for_removal': False,
                        'precondition': 'EXACT_LIST_APPROVAL_AND_FRESH_OCCUPANCY_SOURCE_RECHECK'})
        for rel in ['Temp/codedb-editor-compile/bin', 'Temp/codedb-editor-compile/obj',
                    'Temp/codedb-tests-compile/bin', 'Temp/codedb-tests-compile/obj']:
            root = safe(REPO / rel, REPO)
            if root.exists():
                d = stats(root)
                result['cleanup_candidates'].append({'path': str(root), 'type': 'COMPILE_OUTPUT',
                    'files': d['files'], 'bytes': d['bytes'], 'authorized_for_removal': False,
                    'precondition': 'EXACT_LIST_APPROVAL_AND_FRESH_OCCUPANCY_SOURCE_RECHECK'})
        result['project7'] = json.loads(run(['gh', 'project', 'view', '7', '--owner', 'riceWithoutIce', '--format', 'json']))
        save_json(OUT / 'project7-items-before.json', json.loads(run(['gh', 'project', 'item-list', '7', '--owner', 'riceWithoutIce', '--limit', '100', '--format', 'json'])))
        result['remote_refs'] = run(['git', 'ls-remote', 'origin', 'refs/heads/main',
            'refs/heads/codex/v0.3.0-legacy-workflow', 'refs/heads/codex/install-quarantine-admission']).decode()
        result['status'] = 'PRESERVATION_VERIFIED_EXACT_CANDIDATES_PREPARED_NO_DELETION'
        result['finished_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        save_json(OUT / 'result.json', result)
        print(json.dumps({'status': result['status'], 'storage': str(OUT),
            'worktrees': len(result['worktrees']), 'compact_archives': 7,
            'cleanup_targets': len(result['cleanup_candidates']),
            'candidate_bytes': sum(x['bytes'] for x in result['cleanup_candidates']),
            'archive_bytes': sum(p.get('preserved', {}).get('archive_bytes', 0) for p in result['projects'])}, ensure_ascii=False))
    except Exception as exc:
        result['status'] = 'STOPPED_PRESERVE_ORIGINALS'
        result['error'] = str(exc)
        save_json(OUT / 'result.json', result)
        raise


if __name__ == '__main__':
    main()
