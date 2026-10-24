# S29 Instance Manifest Delivery And Retained-Candidate Assessment

Date: 2026-10-07. Planner execution after explicit human approval of
INSTANCE-MANIFEST-DELIVERY-PLAN.md. The human additionally requested continuing
necessary pre-human-validation preparation without repeated approval questions.

Status: DELIVERY_COMPLETE / RETAINED_CANDIDATE_ADMISSION_BLOCKED / S29_PARTIAL.
Source repair ACCEPT and F-IMC-01 / P3 DEFER remain unchanged.

## Commit And Preservation

- Commit: 13bf5fd16c15c42e1379ce35a06e49c20753195f.
- Parent: 70f33f7e9f7b39b63aaf9c1d4eedba122f67799a.
- Branch: codex/v0.3.0-legacy-workflow.
- Message: fix(host): close instance manifest consumers in poc.40.
- Scope: exactly 47 paths: 39 accepted product/tool/test paths, six named
  bounded handoff records, and only the approved sections in two documents.
- Frozen 39-path identity:
  c4a1cfe61877dfce0bd81759840f4b64fd08d1c987b5e9bb76ea1b13be4dba0d.
- All accepted source hashes and frozen RESULT/VERIFICATION matched before
  staging. Protected old generations: 332 files and original aggregate
  502bf6d2e3bbc697ed1d5927deb16274cbbb6ecb76c729b6838af71217c32dc9.
- The main index was empty on admission. Exact raw blobs were staged with
  hash-object/update-index to preserve accepted payload bytes despite local
  core.autocrlf=true. Every staged blob was compared with its intended bytes.
- Both documentation blobs were built from HEAD plus only their approved
  sections. Working files and all unrelated inherited edits remain intact.
- Standard staged diff-check reported two EOF blank-line notices in the new
  canonical and poc.40 codedb-strict-json.ps1 copies, line 225. This is not
  recorded as an unqualified diff-check PASS. No accepted bytes were changed;
  the check with only blank-at-eof disabled passed. No whitespace configuration
  was persisted. These formatting notices do not affect runtime acceptance.
- Index is empty after commit. Unrelated dirty/untracked state remains; no
  clean-worktree claim. These post-delivery records are not in that commit.

## Exact Local Artifact Evidence

Root: .artifacts/0.3.0-preview.5-s29-instance-contract-poc40.
Before export, the root was absent and ancestors were checked for reparse
escapes. The exporter matched the committed source. One invocation used only
the new exact commit, with no repair or successor-generation options.

ZIP: com.rice.ai-codedb.zip, 2367078 bytes.
SHA256: 04de09be852f870b001f703310889d77aba2acf16a5a6cdebae9b6cf299336ee.
Package files/ZIP entries: 513 / 513; extracted content bytes: 10564597.
Package version: 0.3.0-preview.5; generation poc.40; sequence 40.

Exact reviewed Package entry:
G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-instance-contract-poc40/review/com.rice.ai-codedb/package.json

| Evidence | Result |
| --- | --- |
| Commit-staged byte closure | PASS, source_count=52, mismatch_count=0. |
| Exact ZIP extracted byte closure | PASS, source_count=52, mismatch_count=0. |
| Accepted source -> extracted Package equality | PASS, all 39 file hashes match. |
| Exact extracted InstanceManifestContractOnly | PASS, PS 45 assertions; Node 26 cases / 52 helper decodes; two real Node caller bindings. |
| Execution boundary | One test-owned Node child, zero service children; elapsed_ms=4312. |

The focused command was run from the exact extracted Package's Tests~ directory
by absolute script path; its own PSScriptRoot selected the extracted production
writer/readers. No worktree helper substitution, extra closure, nearest-regression
replay or Unity test rerun occurred. Export and focused scenario both succeeded
on their first invocation. No new generation/hash repair was needed.

## Read-Only Candidate Observation

Project: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.
Only bounded directory metadata and the one immediate instance manifest were
read. Ancestors and immediate entries were checked for reparse points. No
product/runtime scripts were invoked to obtain status.

- AIWork/.runtime/codedb/control is absent at observation; therefore no current,
  LKG, desired-state, operation, retirement or removal-intent record exists in
  that namespace to bind this instance.
- AIWork/.runtime/codedb/instances contains one immediate candidate directory:
  330b7a972a7649259409fbce4de8ca56.
- Its instance.json is 1234 bytes; SHA256
  13cb910b889aa671024ad97a70e69601289be8892b4613b8494cdedcd526aeec.
- Manifest declares managed_by=com.rice.ai-codedb, PROVISIONING,
  Package 0.3.0-preview.5 / poc.39, created 2026-10-07T07:06:02.6300411Z,
  empty verified_at_utc, and project identity
  sha256:a31d47273d22f34d00000fc234ff1b7dcc5afac6079b4e459935838d94c07c66.
- Origin declares INSTALL; both action_id and operation_id are
  73c9d6a0a8ba4df0898721265ec515d6.
- Immediate child names: adapter, config, index, leases, logs, tmp, watch,
  instance.json. Subtree contents and process/lease liveness were not read or
  probed. Directory presence is not evidence of active or inactive processes.

The declared origin differs from the human-reported Manager Action ID
d8c736504562495dbafdd673c6851efb. Do not infer corruption or a second user action:
the source convergence path can generate a backend operation ID when incoming
origin IDs are absent. That possible explanation is not a proved receipt mapping.
Because unique binding to the reported action is unresolved, no further runtime
paths were followed, and no candidate was selected, moved, adopted or deleted.

## Why A New Install Is Not Yet Ready

Existing source Test-InstanceFirstInstall rejects retained instance/runtime
evidence. Assert-InstanceNextChangeAdmission binds candidates through selected,
retirement, removal or activation records before allowing another project
change. With this control namespace absent, the observed instance has no such
binding. Both convergence and normal uninstall enter that admission check.
Therefore replacing the Package or clicking Uninstall is not a proved route
out of this state. This is source/disk evidence, not an executed product probe.

The original candidate failure path invokes its generation-owned watch Stop
before removal; observed poc.39 has the old parser. It must not be patched in
place or bypassed by deleting directories. New poc.40 decoding PASS does not
prove the old candidate's effects are inert or grant adoption/cleanup.

## Concrete Next Handling Recommendation

Preserve the exact candidate above and the exported artifact. First correlate
the Manager terminal receipt with backend origin 73c9d6a0a8ba4df0898721265ec515d6
and determine which owned effects were reached. Do not widen this into a machine
process inventory or historical-action sweep. Then use an existing authenticated
failed-candidate finalization route if one covers those facts; otherwise bring
back one bounded same-S29 recovery-contract gap, not an ad hoc directory delete.

Any eventual mutation proposal must name the exact candidate and only its
proven owned side effects, establish holder/effect safety and record a terminal
result before a new Install. Merely moving the candidate to .backups would
remove admission evidence without proving its effects inert, so it is not an
authorized or recommended shortcut now.

No human Install checklist was activated because admission cannot yet be
truthfully described as ready. No new project was requested. Human Unity closure
and prior 18-group/48-case PASS remain preserved; no repeat human run is needed
at this point.

## Execution Accounting And Handoff

No source edits, product repair, commit amendment, push, tag, publication,
remote task write, consumer manifest/lock edit, Unity/MCP/CUA/BatchMode,
Provider/process probe, runtime write or candidate cleanup occurred. One
diagnostic source-output batch was tool-truncated; required source definitions
were subsequently read in smaller bounded slices. This is disclosed, not a
claim of fully compliant earlier output. No tests were repeated as a result.

Local staging helper: .artifacts/s29-delivery-tools/prepare-commit.cjs, ignored
and outside the exported Package. It does not run during product use.

The added human instruction grants continuity for ordinary required preparation
without per-command/per-phase approval prompts. It does not turn unresolved
candidate identity into deletion authority. Continue safe preparation within
that instruction; present any real candidate mutation with exact targets and
effects. Current result is delivery PASS plus an explicit candidate-admission
blocker, not whole S29/release acceptance.

## Continued Prerequisite: Exact Manager Receipt Correlation

Under the human's additional continuous-preparation instruction, the Planner
continued read-only correlation against this project's exact reported Manager
action. The preceding observation-only stop is preserved as chronological
evidence; no real mutation or process probe followed it.

Source AICodedbPaths and invoke-codedb-manager-action.ps1 derive receipt storage
from the full normalized project SHA256 and the first 24 hex characters as the
physical directory key. The bounded read targeted only:

C:/Users/admin/AppData/Local/Rice/CodeDB/manager-actions/a31d47273d22f34d00000fc2

The resolved-action-d8c736504562495dbafdd673c6851efb.json record names this exact
project and the old 70f33f7 compile-fix Package. Its disposition CommandTerminal
means the Manager command reached a terminal result; it does not prove candidate
cleanup or authenticated logical Uninstalled.

Under Package key 484a0de012a134f1eec7c80f and that exact action ID, three stages
have admitted and terminal receipts. Full project/action keys were checked;
reads were bounded to <=64 KiB per file with reparse checks. No unrelated
project/action record content was inspected and no receipt was changed.

| Stage action | Terminal UTC / result | Declared effects |
| --- | --- | --- |
| Install | 07:06:04.495457Z; exit 6; BLOCKED / CANDIDATE / INSTANCE_CANDIDATE_FAILED | host_runtime, instance_candidate; cleanup PENDING. |
| DryRun | 07:06:07.1954356Z; exit 0 | Observation receipt; not candidate recovery. |
| Upgrade | 07:06:10.1747866Z; exit 6; BLOCKED / PREFLIGHT / INSTANCE_CONVERGENCE_FAILED | No mutated scopes; refuses unbound or ambiguous candidate execution. |

All three receipts report timeout=false, overflow=false and
output_drain_incomplete=false. These are historical receipt fields, not a
current process-liveness assertion. The Upgrade receipt's cleanup COMPLETE
applies to that non-mutating attempt and cannot overwrite the earlier Install
PENDING or the currently retained PROVISIONING manifest.

Install admitted arguments contain no OriginatingActionId/OriginatingOperationId.
The existing backend source generates an operation GUID and uses it as action
ID when those values are missing. This explains a permitted namespace mismatch;
neither terminal output contains backend ID 73c9d6a0a8ba4df0898721265ec515d6 or
candidate ID 330b7a972a7649259409fbce4de8ca56. Timing (candidate created at
07:06:02.6300411Z) and failure shape are consistent, but do not establish a
durable direct identity link or sufficient cleanup authority.

Receipt hashes for reproducible bounded follow-up:
- Install admitted: fe3171876821e511b7347e49ab0578b2eee945271356ad5345f4f0c61120c599.
- Install terminal: b03ebbb90521b5b0c4d1352c3bc1b424994bcebf780bc1e23dd94d5b5dae5748.
- DryRun terminal: 6e9c24ec18bc25568979e4c2f8340bd0b9537e0f4c3b89deef79a4ab62430feb.
- Upgrade terminal: dfdc36ad718ccd627f3003d82f528fb60868f5c7505e18223d2a44b54de47bb1.

Final assessment: the next-change refusal is now directly corroborated by the
historical Upgrade receipt, not only predicted from source. Complete the
failed-candidate terminalization/recovery contract before activating another
human Install. Keep the delivery artifact frozen; do not re-export unchanged
source, request another empty Unity project, or use a manual move/delete to
manufacture first-install eligibility. Any recovery implementation is a new
scoped product change, and any cleanup must first prove its exact ownership and
effect boundary. Neither is implicitly executed as artifact preparation.
