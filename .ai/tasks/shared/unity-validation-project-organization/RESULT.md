# Unity validation project organization result

Date: 2026-10-19.
Status: COMPLETE / EVIDENCE_VERIFIED / THREE_AUTHORIZED_ROOTS_DELETED.
Physical deletion: explicitly authorized by user `同意授权删除`, completed.
Owner: current parent / this organization task.

## Scope and result

Preparation before deletion authorization: user approved evidence-first retention
and requested organization. The older
three projects were inventoried without changing their contents. Selected
original configuration, runtime and failure records were copied to independent
repository-local evidence storage and SHA-256 verified against the originals.
No source edits, product commands, tests, Unity control, process termination,
package export, reference switching, commits or full-project backups occurred.

The fixed development project and S33 stay at their original roots. No successor
acceptance project was created. See [project index](../../../validation-projects.md).

## Exact roots and dispositions

| Repository-relative root | Original files / bytes | Final treatment |
| --- | --- | --- |
| `UnityFreshInstallValidationProject/` | 13,941 / 205,914,437 | DELETED after evidence verification and exact user grant. |
| `UnityFreshInstallValidationProjectS29/` | 15,159 / 215,167,114 | DELETED after evidence verification and exact user grant; earlier preserve-in-place decision superseded only for this exact root. |
| `UnityFreshLifecycleValidationProjectS30/` | 14,870 / 215,896,552 | DELETED; distinct uninstall/reinstall evidence remains protected. |
| `UnityValidationProject/` | Tracked development project | Retain unchanged; excluded from deletion. |
| `UnityFreshLifecycleValidationProjectS33/` | Latest complete historical sample | Retain unchanged, including post-force-end lock state. Owner current parent/S34; review at successor corresponding lifecycle completion or sample replacement. |

The deleted inventories total 43,970 files / 636,978,103 bytes (about 607.5 MiB).
Library accounted for 625,707,272 bytes. These are logical file byte counts,
not a measurement of actual free-volume change. Each had only default SampleScene
and its metadata under Assets (three files).
Recursive inventory found no reparse entries or nested Git state; no files in
these three roots are tracked. These are observations at preparation time.

## Preserved independent evidence

Base: `.artifacts/validation-evidence/project-retention-20261019/`.

- [Inventory summary](../../../../.artifacts/validation-evidence/project-retention-20261019/inventory/summary.json).
- `inventory/<project>-files.json`: all observed relative file paths, lengths and
  timestamps. Omitted file contents were not hashed or copied.
- `inventory/<project>-evidence.json`: exact original-to-copy mapping, lengths
  and SHA-256 values. Copies under `inventory/evidence/<project>/`.
- [Supplement manifest](../../../../.artifacts/validation-evidence/project-retention-20261019/supplement/evidence.json): small Logs files, S29's two old package-reference backups and each consumed package's package.json/payload-manifest.json. Original-to-copy mapping and hashes included.
- [Consumed package identities](../../../../.artifacts/validation-evidence/project-retention-20261019/supplement/packages.json).
- [Protected external references](../../../../.artifacts/validation-evidence/project-retention-20261019/supplement/protected-external.json): 13 existing package/screenshot/operation references hashed; eight compared with prior documented hashes, all matched. Others are newly indexed hashes, not a claim of a prior hash comparison.

| Evidence manifest | Copied files / bytes | Manifest SHA-256 |
| --- | --- | --- |
| `inventory/UnityFreshInstallValidationProject-evidence.json` | 35 / 77,594 | `69d04e275bdea9dae3597753d413b04a01d5d52dc6e2eb07d4949abc7986ac76` |
| `inventory/UnityFreshInstallValidationProjectS29-evidence.json` | 72 / 475,271 | `7344f1a9461586af3717a773511897a641e3ab49fffa59a39cc1bbf10c1509ce` |
| `inventory/UnityFreshLifecycleValidationProjectS30-evidence.json` | 47 / 301,680 | `6c4eb16818058cbb5b6ab74161c63edd8665de7de04385ce59694475f6c50cdd` |
| `supplement/evidence.json` | 16 / 246,839 | `f7824f39dac8b4dab61f5bd2aca7ac01debb234cdf4012697f9162b2d8d57914` |

Total: 170 copied files / 1,101,384 bytes, excluding inventory/manifest/script
storage. Source before/after and copied bytes matched during preservation.
Collector and supplement are task-owned preparation scripts, not product tests;
they reject reuse of existing outputs. Do not rerun to overwrite these snapshots.
Both parsed successfully and completed once. No raw configuration was printed.

Preserved selection includes complete small Assets/Packages/ProjectSettings and
existing .codex/.vscode, top control records, removal intents/operations,
activation/control-contract operations, canonical Supervisor records/events,
stale owner records, Manager action maps and their referenced operation history,
instance manifests/config/logs/lifecycle. S29 additionally includes the two
missing-child histories and twelve unknown-process histories named by its
existing diagnosis. Original bytes and project names are retained, not rewritten
to make old relative references runnable at the evidence location.

## Historical result attribution

### Initial unnumbered fresh-install project

Historical source `91a295b28969c8a0d0dc66b6c19581fcdc9f7f5f`; consumed extraction
`.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/package/com.rice.ai-codedb`.
Trigger was first-entry automatic preparation. Expected attributable installation;
actual candidate `fd14a3cfa964437d9192f787df68bcf3` retained PROVISIONING/poc.39
with unbound/ambiguous execution evidence and blocked subsequent change.
Startup ready log lines do not prove full integration or process termination.
No successful explicit Install or complete lifecycle is inferred. Exact original
prepare-failure observation was not recovered; do not invent it.
The candidate manifest/config/log evidence is preserved. Existing source record:
[S29 task, initial project stages](../../v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/TASK.md).
Disposition: historical partial sample, no new recovery; owner archived S29.

### S29

Consumed extraction `.artifacts/s29-removal-history-authority-5b52c01/review/com.rice.ai-codedb`.
Historical first Install/Ready and logical uninstall passed on earlier stages;
the latest-package continuous lifecycle never passed. Subsequent removal
preflight refused unresolved historical execution evidence. Two named histories
retain missing child identity; twelve process identities were unresolved by
the historical diagnosis. This does not establish current orphan liveness or
authorize PID termination. PID reuse, original process alive and identity
unknown stay distinct. Source, latest smoke and release acceptance stay distinct.

Authoritative [archive decision and linked result/diagnosis records](../../v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/ARCHIVE-DECISION-2026-10-15.md)
remain unchanged: ARCHIVED / PARTIAL / NOT_RELEASE_ACCEPTED. Disposition:
historical recovery deferred, no infinite fallback. Owner archived S29; reopening
needs a separate bounded objective. Existing latest package ZIP and Manager
screenshot remain outside deletion scope, with matching prior hashes indexed.

### S30

Current consumed extraction `.artifacts/s32-install-command-b0462ed/review/com.rice.ai-codedb`.
Do not apply this package identity retrospectively to earlier real actions.

First Install/Ready passed. The later confirmed uninstall action
`1e53bbcf798241c48f72b8bfa8ee2e30` completed backend operation
`36d0c70eacb7489c94d36b1b58ba1b50`, exit 0 / LOGICAL_UNINSTALL_COMPLETE,
cleanup PENDING. Supervisor retired before Manager result closure; Manager
retained a pending/unconfirmed session. Expected end-to-end closure was not met.
An explicitly authorized manual index archive later reset that baseline; this
was maintenance, not proof of automatic product recovery.

Subsequent confirmed Install action `6b9678672d3744f0ab052e521ae42ad6` on source
`97471f537749eba97171f6756a29112dd552a22b` failed SUPERVISOR_START_FAILED before
observed backend dispatch. Missing current selection conflicted with Supervisor
startup routing ahead of instance materialization. Later S32 source/package
smoke does not establish successful real reinstall on that final package.

Authoritative records, rather than stale early task headers:

- [Logical uninstall and Manager closure failure](../../v0.3.0/cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/UNINSTALL-ACCEPTANCE-RESULT-2026-10-17.md).
- [Manual baseline reset](../../v0.3.0/cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/BASELINE-RESET-RESULT-2026-10-17.md).
- [Subsequent real reinstall failure](../../v0.3.0/cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/REINSTALL-ACCEPTANCE-RESULT-2026-10-17.md).

Independent seven-file uninstall snapshot `.artifacts/s30-uninstall-20261017-1e53bbcf/`
and four-file reinstall snapshot `.artifacts/delivery/s30-reinstall-97471f5/attempt-a1/`
remain protected. Existing `.backups/s30-baseline-reset-20261017-1e53bbcf/` and
other previously protected backups are excluded from this deletion proposal.
No pending machine action index is cleared. Disposition: historical partial
route, no new recovery; owner archived S30 / successor lifecycle task for new
normal-path acceptance. Cross-version replacement and full lifecycle remain
unproven by organization.

## Reproduction and recovery limits

The bounded review of authoritative task records, complete path inventory,
default-only Assets and selected original records found no declared unique
need to keep these older three complete projects. This is a basis for the
conditional deletion recommendation, not exhaustive reproducibility proof.

Library consists primarily of cache/assemblies/import/build state; a targeted
filename review outside PackageCache/ScriptAssemblies/Bee found no CodeDB,
crash/dump, Editor log or test-result artifact. Small project Logs and internal
reference backups were preserved separately. No new crash forensics or full
cache-content audit was performed; CleanupMono remains deferred with S33 retained.

Omitted: Library/Temp/Obj, generated IDE files, UserSettings and unrelated runtime
payload/index/provider/history content beyond the declared evidence selection.
The archive explains observed issues; it cannot restore the full old project or
guarantee exact runtime reproduction. Omitted contents cannot be recovered
from this evidence set after the completed deletion. Existing package extractions,
ZIPs, task records, screenshots, prior evidence/backups and shared/machine state
stay outside the exact deletion roots and must remain protected.

## Preserved pre-deletion checks and execution boundaries

The prospective plan below was reviewed before the explicit deletion grant.
The completed execution is recorded in the following section; this is not a
standing grant to replay cleanup or delete other historical content.

Read-only preflight refreshed at 2026-10-19T04:24:49Z. All 43,970 file paths,
lengths and write timestamps still match the preserved inventories. The 170
source/copy pairs, four evidence manifests and 13 external references match
their recorded hashes. Exact-root containment passed; no reparse entries,
nested Git state or tracked files were found. No non-diagnostic process command
line explicitly referenced the three project names; relevant Unity/Node/shell
command lines were readable. This is a bounded command-line observation, not
an open-handle audit or proof about all historical processes.

Retained development/S33 package configuration and existing root .codex/.vscode
configuration had no matching reference to the three candidate names. A tracked
non-document text search returned only .gitignore, which is a retention pattern,
not a live consumer. No root JSON/TOML/PowerShell/workspace file was present to
add another consumer. Historical task/evidence references deliberately remain.
An initial timestamp comparison parsed ISO strings as DateTime automatically;
using string-preserving JSON parsing confirmed no actual timestamp drift.
No project data was changed during this diagnostic correction.

Only the three exact candidate roots in the first table are proposed, including
their contents and S29's small internal backups now independently preserved.
Do not delete parent directories, other projects, artifacts or external state.

Before any authorized deletion: re-resolve exact roots and containment, reject
reparse/nested Git changes, check tracked files and changed file inventories,
reverify preserved source/copy/manifest hashes and external dependencies, and
check current references and relevant live holders for these roots. Stop on
drift, a missing necessary record, an unsafe holder/ownership or new retention
dependency; no automatic process stop, historical repair or fallback deletion.
Prior bounded process observations are not an exhaustive current quiescence proof.

User review must cover the exact roots, preserved evidence and full-recovery
limits. After explicit authorization, fresh checks and deletion may be one
bounded group without repeated approvals. Report actual removed roots and
remaining evidence afterward. Preparation itself did not exercise deletion
authority; the separately approved execution follows.

## Authorized deletion completed

Completed at 2026-10-19T04:28:46Z under the user's exact three-root grant.
Fresh recursive metadata, containment/reparse/nested-Git, tracked-file,
preserved evidence, checked consumer and bounded command-line process checks
passed. No tracked project file was deleted.

The first execution removed only the unnumbered project, then stopped before
S29 on a new process-command-line match. No process was terminated. A subsequent
read-only observation found no matching process; its transient identity was not
captured and is not inferred. The STOPPED receipt remains unchanged. The two
remaining roots and their original evidence were fully revalidated; with no
matching process observed, deletion completed under the original exact grant.
No deleted root was retried and no additional path was added to scope.

Postchecks confirm all three authorized roots are absent, all 170 retained
evidence copies and 13 protected external references still match their hashes,
and both `UnityValidationProject/` and `UnityFreshLifecycleValidationProjectS33/`
remain present. Source/package/lifecycle acceptance statuses are unchanged.
No Unity operation, Install/Uninstall, source fix, export, reference switch,
commit, external-state cleanup or process control was performed.

Independent receipts under the evidence base:

- [Final completion receipt](../../../../.artifacts/validation-evidence/project-retention-20261019/deletion-completion.json), SHA-256 `1ded95366851d880da5d4d5a1c9a49673aced715c662fdeb935cd6cfc5c31740`.
- [Initial stopped execution](../../../../.artifacts/validation-evidence/project-retention-20261019/deletion-result.json).
- [Initial successful preflight](../../../../.artifacts/validation-evidence/project-retention-20261019/deletion-preflight.json).

Removal was permanent, not a move to recycle bin. Necessary evidence remains
usable independently; the omitted cache/runtime/IDE content is not restorable
from this archive. No complete backup or full recovery guarantee was created.
S33 is the only retained complete historical acceptance sample; its review
milestone remains successor corresponding lifecycle completion or replacement
by a more useful sample. The successor project has not been created/connected.
