# S29 Result - Stage A Preparation

Final task disposition, 2026-10-15: **ARCHIVED / PARTIAL / NOT_RELEASE_ACCEPTED**.
See [archive decision](ARCHIVE-DECISION-2026-10-15.md). The Stage A status and
instructions below are historical evidence, not the current execution state.

Task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Historical Stage A status: **PREPARATION_COMPLETE / AWAITING_HUMAN**
Evidence date: 2026-10-05. Stage A only; this is NOT integration, Unity or RELEASE PASS.

## Contract and input attribution

Executed TASK's "Preparation And Single Dispatch Grant - 2026-10-05" using the
existing v0.3.coder.deep / DURABLE_SESSION / REUSE_ONLY session. No model,
reasoning, profile, child/session or delegation override. Actual configured
model/reasoning identifiers are not exposed by the available task tools:
**unavailable**, not guessed.

Reused Planner's once-only admission: branch codex/v0.3.0-legacy-workflow,
document HEAD `b15292f8978272244e605805a9ec064049141ee2`, twelve source/test paths
clean, exact ZIP present, new project/artifact absent. No repeat whole-worktree,
staging, session, history or process scan. Existing dirty/untracked/staged state
was not cleaned or implicitly included.

Candidate source commit is `91a295b28969c8a0d0dc66b6c19581fcdc9f7f5f`,
NOT the later document HEAD. Source attribution additionally checked the
complete regular-file Package tree from that exact commit against every ZIP
member. Accepted S28 Window 02 and candidate provenance were read only in their
direct named sections; no old test/Unity scenario was replayed.

## Frozen ZIP and consumed Package evidence

- Reviewed ZIP:
  `G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s28-phase-c-91a295b/com.rice.ai-codedb.zip`.
- Actual ZIP SHA-256: `ca72ef948caddf7cffbe11a659d2a0dd9fec703cbd5cb695b50ef5a986123086`, exact expected match.
  ZIP bytes=2251473; entries=568; regular files=482;
  expanded file bytes=10016895.
- New owned artifact boundary:
  `G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/`.
- Exact extracted Package:
  `G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/package/com.rice.ai-codedb/`.
- Absolute human Add package from disk selection:
  `G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/package/com.rice.ai-codedb/package.json`.
- package.json SHA-256: `fcb67de746dd681b4194ac2003a867a7be69079d9027fe81a4743b475352402a`.
- Canonical metadata confirms com.rice.ai-codedb 0.3.0-preview.5, Unity support
  line 2022.3, generation poc.39. **Generation transition NONE.**

Before creation: absolute containment/absence and non-reparse ancestors checked;
single root, unique/case-safe names, traversal/device/ADS/ambiguous Windows names,
links/special modes and file/directory prefix collisions rejected. ZIP was held
read-only while hashing, attributing and extracting. No overwrite, re-export,
canonical repair, mutable-tree input or old artifact modification.

All **482/482** ZIP file bytes match their exact frozen Git blob hashes. All
**482/482** extracted file hashes match ZIP, missing/extra/mismatch=0.
Sorted ordinal Package-relative path + space + lowercase SHA-256 rows, UTF-8
LF/no-final-LF whole-Package digest:
`14eed019184e48e3f8b13f26231380c212f397326169e6f7c9cf0a44878ca293`.
It matches accepted S28 candidate identity and remains identical after closure.

## Exact extracted-Package closure and runtime bindings

Executed once, using the script INSIDE the admitted extracted Package:

`powershell -NoProfile -ExecutionPolicy Bypass -File G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/package/com.rice.ai-codedb/Tests~/test-codedb-package-release-closure.ps1 -PackageRoot G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/package/com.rice.ai-codedb`

No `-RepairCanonicalMetadata`. Exit **0**, tool wall **1.1929385s** for invocation
plus consumed-byte postguard. Terminal **PACKAGE_CLOSURE PASS**:
source_count=46 / mismatch_count=0.

All declared payload sources/hashes and all 22 generation file hashes were
checked. Pointer, generation metadata and runtime identity fixture cross-hashes:
- generation-manifest SHA-256:
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`;
- host-current SHA-256:
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`;
- payload/runtime-contract SHA-256:
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`;
- invoked closure script SHA-256:
  `c6524f111b90ed76443591715f0222659428b11e9b9250e816c56d18bbe24863`.

Preparation-only target cross-binding checked every declaration against the
canonical reader lanes: 22 flat source-equal targets, 23 generation targets,
one current pointer. All 22 generation entries also match the payload source
map/hash. Metadata roots/routes:
- generation: `AIWork/.runtime/codedb/host/generations/poc.39`;
- pointer: `AIWork/.runtime/codedb/host/current.json`;
- stable wrapper: `AIWork/codedb/wrapper/codedb-project-wrapper.mjs`;
- generation worker: `AIWork/.runtime/codedb/host/generations/poc.39/wrapper/codedb-project-instance-worker.mjs`;
- control contract v0.3-control / version 2 / schema 1, SHA-256
  `e535dd2ef7a120578178d8e8db608e765e29b0a09a619db31c4a39f53b9fcaf2`.

These are static Package bindings, NOT evidence of published project selection,
active Supervisor/Coordinator, project registration, real Ready or client tools.
No materializer/instance entry point or dependency/probe script was executed.

## Changed scope and human handoff

Writes were limited to:
1. exact ZIP extraction into the new S29 artifact boundary;
2. HUMAN-CHECKLIST.md preparation fields, actual absolute package.json/identities,
   closure facts, support line and explicit ungranted human-stage boundary;
3. this new RESULT.md (absent at the bounded record check; no prior result erased).

No TASK/Planner, production/test/metadata/generation, project manifest/lockfile,
validation-project or consumed candidate edits. No native process was stopped.
The confirmed new-project directory remains:
`G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProject`.
Its absence is REUSED Planner admission; Coder did not inspect/create/copy/open
that project or read any new/old real runtime, logs or global configuration.

Checklist retains one HUMAN-owned visible session after separate authorization:
fresh project/import/zero C# errors -> ordinary first Install 1/Ready ->
observational Manager -> confirmed Remove Integration 1/authenticated Uninstalled
-> Install/Reinstall 1/new committed activation/Ready -> normal exit.
Each transition <=300s; failure/unknown/timeout stops later mutations, no replay.
No fabricated prior removal intent, machine prerequisite install, Package removal,
global cleanup, copied old state or implicit Play/Domain Reload/full EditMode.
Optional client exposure requires separate authority; at most one human reconnect/
new task, otherwise DEFERRED. Owned preservation/activation facts must be proved,
not inferred from green UI or exit 0. Authenticated inert PENDING is distinct
from ambiguous/active incomplete removal.

## Actual command evidence and corrections

Tool wall seconds; terminal exits shown. Exact inline scripts/arguments remain
in Coder tool history, not copied here as transcripts.
- TASK complete bounded read in two parts: exit 0, 0.2605724 / 0.269929.
- Memory skill/registry/workflow marker read: exit 0, 0.2859969.
- Workflow budget/closure header read: exit 0, 0.2853075.
- Closure remainder/direct dependency markers: exit 0, 0.2881671.
- Accepted S28 provenance/reinstall contract: exit 0, 0.2696004.
- ZIP admission/source attribution/safe extraction:
  `git -c core.quotepath=false ls-tree -r --full-tree 91a295b28969c8a0d0dc66b6c19581fcdc9f7f5f -- com.rice.ai-codedb`
  inside the bounded inline archive scenario; exit 0, **3.1282649s**.
  Only counts/digests emitted; archive/file data remained internal to attribution.
- Extracted closure + consumed-byte postguard: exit 0, **1.1929385s**.
- Canonical target/read-boundary inspection: exit 0, 0.3183794.
- Direct authority/result read: exit **1**, 0.4012457. Concrete construction error:
  `Cannot overwrite variable Host because it is read-only or constant.`
  No writes, probe, test rerun or frozen-content correction.
- Same read's sole mechanical correction changed temporary variable
  `$host` to `$hostContract`: exit 0, 0.350879.
- Canonical metadata target cross-binding: exit 0, **0.3038172s**.

Single authorized Stage A scenario: initial **1/1**, semantic corrections
**0/2**, mechanical correction **1/2** (reserved variable only).
Closure invocations **1**; no other L0/L1/source or path-provenance gate.
Path provenance **NOT_APPLICABLE**: exact reused Package bytes, no text change.
Accepted S28 focused/source and HUMAN S28PhaseC **25 PASS / 0 FAIL / 606 unrun**
are **REUSED**, not fresh S29 evidence.

## Budget, limitations and terminal routing

DEEP_60M anchor 2026-10-05 10:51:45 UTC+08:00; documentation observation 2026-10-05 11:08:14 UTC+08:00;
anchored wall 16m29s. No human-wait interval or compaction observed in
this Stage A window; exact active-vs-orchestration split and historical cumulative
time unavailable. Existing settings retained, no replacement/child.

Shell stdout/stderr retained through the last required read/binding command:
**84180 UTF-8 bytes** across 12 chunks;
normal outputs <=32 KiB/200 lines and scoped rg <=16 KiB/50 matches.
No command timeout or output truncation. V2_DEFAULT window guard 128 KiB;
remaining documentation uses bounded size/summary only. RESULT guarded <=16 KiB
before write. New evidence/corrections do not reset prior S28 failures/ledgers.

**NOT RUN / NOT AUTHORIZED**: Stage B/C, new-project creation/open/import,
Unity/C# compile/EditMode/MCP/CUA/BatchMode, actual Install/Remove/Reinstall,
current Ready/activation/removal/registration/preservation observations,
client tools/query/rebind, live prerequisite checks/install, real/global runtime
or config reads, process control, independent review/Verifier dispatch,
commit/export/tag/push/publication/remote Project update.

Preparation PASS neither closes older S28/S25 legacy conflicts/unlock/Host/MCP
gates nor implies fresh-project product or RELEASE acceptance. S21 accepted risk,
cross-version upgrade, machine cleanup, full regression, Play/Domain Reload,
third-party distribution/performance and release promotion remain deferred.
No coupled reassessment required by Stage A; no independent product failure seen.
Coder returns this stable Package/checklist and stops writing.

Final task-record verification only: exit 0, tool wall 0.2714206s;
exact consumed path/status present, no unresolved preparation placeholder.
Observed checklist 8029 bytes and RESULT 10892 bytes before this closing note;
final RESULT remains under 16 KiB. No test or project/runtime access added.
Final retained shell-output total 84472 UTF-8 bytes / 13 chunks.
End observation 2026-10-05 11:10:04 UTC+08:00; anchored Stage A wall 18m19s.
No additional evidence retry or human stage; Coder stopped.


Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path
Current status: PREPARATION_COMPLETE / AWAITING_HUMAN
Next notification: Planner/User through this terminal in-chat handoff only
Next action: Planner reviews Stage A artifact/checklist and seeks the explicit human-owned Stage B/C grant
Human decision or authorization required: project creation/open/import and golden-path actions; later client evidence/Verifier/ACCEPT and Git/remote actions remain separate
