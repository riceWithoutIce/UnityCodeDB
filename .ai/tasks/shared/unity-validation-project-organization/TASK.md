# Unity validation project organization

Date: 2026-10-19.
Status: COMPLETE / EVIDENCE_PRESERVED_AND_VERIFIED / THREE_AUTHORIZED_ROOTS_DELETED.
Workflow: codedb-workflow-v2 revision 2.6, safe-execution acceptance-project and
protected-retention rules. Owner: current parent. No subagent requested.

## Objective and current authorization

Keep a clear distinction between the fixed development EditMode project,
current real acceptance project and protected historical projects. Prevent
root-directory accumulation without erasing failed lifecycle evidence.

User accepts switching away from S33 and approves the subsequent retention
proposal: retain necessary issues/evidence, not unlimited complete projects;
default one fixed development project, one active acceptance project and at most
one complete historical sample. Record that policy in workflow and replace the
earlier complete-copy archival proposal. After reviewing the concrete three-root
proposal and recovery limits, user explicitly authorized deletion:
`同意授权删除`. Exactly those three roots have now been deleted.
The future acceptance-project layout still awaits alignment. No Unity project
creation/launch, Package-reference switch, Install/Uninstall, product source
change, commit or process control is included in this grant.

## Original read-only inventory and final disposition

All five roots were inside the repository, with no root reparse point or nested
.git observed. Each contains CodeDB runtime. No attributed Unity Editor process
for these five projects was observed; unrelated Unity processes stay untouched.
This does not certify absence of every historical runtime holder.

| Original root | Role and observed state before deletion | Final disposition |
| --- | --- | --- |
| UnityValidationProject | Fixed development EditMode project, 25 tracked files, Unity 2022.3.47f1, references historical S28 extraction | Retain at original tracked location. Do not repair or repoint it during organization. |
| UnityFreshInstallValidationProject | Historical fresh-install project, 0 tracked files, Unity 2022.3.62f3, references 91a295b package-stage export | DELETED after evidence preservation and explicit authorization; no complete lifecycle PASS inferred. |
| UnityFreshInstallValidationProjectS29 | S29 already logically archived / partial / not release accepted; 0 tracked files, references 5b52c01 extraction | DELETED; failure evidence and unresolved limitations retained independently. |
| UnityFreshLifecycleValidationProjectS30 | Historical acceptance, 0 tracked files, references b0462ed extraction; earlier blocked/historical route | DELETED; distinct uninstall/reinstall stages preserved. |
| UnityFreshLifecycleValidationProjectS33 | First Install/reopen/logical Uninstall passed; reinstall failed; S34 baseline smoke normal except force-ended CleanupMono; 0 tracked files, references d4a097d extraction | Logically archived as partial; proposed latest complete historical sample, with review at successor lifecycle completion or replacement of this failure sample. |

Manifest and lock references matched in each project. S33 UnityLockfile remained
after human force termination; do not delete it as part of this planning step.
Project age/count alone is not grounds for archival or evidence of complexity.
Do not infer test failure from the fixed development project's old reference.

## Proposed reusable layout

All locations are repository-relative; no drive/home/user path is policy.

- Fixed development project: `UnityValidationProject/` remains the default.
- New real acceptance projects: `.artifacts/unity-projects/<batch-id>/`.
  Example next batch: `.artifacts/unity-projects/s35/`, proposed, not created.
  A task number need not require a new project; one attributable project may
  cover a complete lifecycle batch. Never reuse an archived id for a clean run.
- Necessary raw evidence, proposed:
  `.artifacts/validation-evidence/<original-project-name>/`; reuse existing
  protected evidence where sufficient, rather than copying it again.
- Temporary complete copies, only when a concrete recovery purpose requires
  them: `.backups/unity-projects/<original-project-name>/`. Each needs an owner
  and review milestone; this is not an indefinite full-project archive store.
- Existing concise task results remain under `.ai/tasks/`; add a small project
  index at `.ai/validation-projects.md` linking their authoritative records.
  Do not duplicate version/hash/runtime contracts in that index.
- Existing package exports and their references remain in place. Archiving a
  project does not authorize deletion of its referenced extraction/ZIP.
- Approved retention default: one fixed development project, one active
  current-version lifecycle baseline and at most one complete historical sample.
  Additional complete retention or parallel acceptance needs an explicit purpose,
  owner and review milestone. Existing backlog is not deletion authorization.

New project source paths must be fixed before human Unity creation or Install.
Compute the actual new relative Package reference from Packages/, validate its
resolution and deepest required test/runtime path; do not copy the old project's
relative literal or introduce a new fixed path limit. No old Library, Assets,
Packages config or runtime is copied into a clean acceptance baseline.

## Evidence-first disposition, replacing the complete-copy proposal

The earlier four-project complete copy/verify/remove mapping is withdrawn.
Do not execute it or treat its proposed destinations as mandatory archives.

| Project | Completed evidence/deletion disposition |
| --- | --- |
| UnityFreshInstallValidationProject/ | Necessary evidence independently saved and checked; exact project root deleted with authorization. |
| UnityFreshInstallValidationProjectS29/ | Same; partial result and unresolved process-evidence limits retained. No silent closure of S29 issues. |
| UnityFreshLifecycleValidationProjectS30/ | Same; attributable failures and relevant original records retained. |
| UnityFreshLifecycleValidationProjectS33/ | Temporarily retain complete at original path as latest failure sample; owner current parent/task; review on successor corresponding lifecycle completion, or when choosing a newer complete failure sample. |

The bounded assessment found no declared unique full-project reproduction
dependency for the older three. Necessary evidence has been independently
preserved and verified; see [RESULT.md](RESULT.md). User subsequently approved
the exact three-root deletion, which completed after fresh checks. Do not expand
into historical repair to decide cleanup; return any new concrete retention
dependency with a bounded exception and review milestone.

Necessary evidence includes steps, expected/actual result, source/Package and
reference identities, relevant original logs/screenshots/runtime/config records,
issue disposition/owner and unfinished gates. Retain a checked path/hash inventory
and links to existing authoritative results. Preserve raw bytes and original
root mappings; do not rewrite operations or relative references. Summaries use
symbolic/repository-relative paths. Evidence-only archives are not runnable Unity
projects and do not promise full project restoration.

Library/Temp/Obj caches are normally omitted unless they contain required unique
failure/reproduction evidence. Caches inside the three authorized roots were
removed with those roots. Existing Package artifacts,
machine receipt stores, processes, shared state and the tracked development
project are outside the proposed project deletion scope.

## Completed preparation and execution boundaries

1. COMPLETE: approved retention policy recorded in the existing safe-execution
   module, linked from development-workflow.md. No physical action or tests.
2. COMPLETE: bounded read-only assessment and repository-local necessary-evidence
   copies for the three older candidates. Original/copy SHA-256 matched;
   package references and existing protected failure records were checked.
   Exact inventories, recommendations and recovery limits are in RESULT.md.
   No full runtime dump, historical recovery, process termination or new fixture.
3. COMPLETE: exact evidence/deletion roots and full-recovery limits presented;
   explicit user grant obtained for the three roots only. No prior protected
   artifact or external backup was added to the deletion scope.
4. COMPLETE: fresh containment, inventory, tracked-file, evidence/reference and
   bounded process checks passed. First execution stopped after one deletion
   on a transient process match; its receipt was preserved. After the match was
   no longer observable, the remaining two roots were independently revalidated
   and deleted under the same grant. No process control or repeated deletion.
5. COMPLETE: all three roots absent; 170 evidence copies and 13 protected external
   references rechecked. Development project and S33 retained. See RESULT.md
   and the independent completion receipt. No full-project backup was created.

## Forward acceptance and stop rules

After policy alignment, human creates the new project at the chosen fixed path.
Use the existing d4a097d artifact without re-export. Preparation/reference switch
and real actions retain their exact authorization boundaries. Complete first
Install -> Ready -> Uninstall -> same-version Install -> Ready. Preserve failures
and unfinished gates; clean first Install is not proof that reinstall passed.

At task completion or baseline replacement, update the project index and assess
evidence-first archival/deletion. Normally review deletion of the previous complete
sample when the successor completes the corresponding route; earlier deletion
is possible after verified independent evidence and no unique reproduction need.
Do not wait indefinitely for all historical issues or a successful successor;
review distinct sample value when replacing a failed baseline. Exceptions name
purpose, owner and next milestone. No scheduled, age-based or implicit deletion.

Current result: retention policy recorded; three older project roots permanently
deleted with authorization, necessary evidence preserved and verified.
See [project index](../../../validation-projects.md) and [result](RESULT.md).
Next action: align the successor acceptance-project location and the bounded
current-version lifecycle route; do not re-export or repair old project history.
No other project archival move, maintenance reset, source test or new Unity
project was performed. Omitted contents cannot be fully recovered from evidence.
