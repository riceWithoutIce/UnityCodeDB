# S30 preparation result — 2026-10-15

Status: SOURCE_ACCEPTED / DELIVERY_REFERENCE_SWITCHED / HUMAN_REOPEN_BLOCKED. See the latest read-only diagnosis below; initial preparation/menu failure records are retained as historical evidence.

## Outcome and changes

Prepared TASK.md for one independent current-version lifecycle route. Created
only a task-owned extraction of the existing accepted ZIP at
`.artifacts/s30-current-version-lifecycle-5b52c01/review/com.rice.ai-codedb`;
no new Package was exported. Added a current-route pointer to the roadmap.
No source, old validation project or runtime state was modified.
After the combined grant, only the new S30 project's Package manifest and lock
were changed, as detailed below.

## Evidence

- HEAD is `5b52c017e8415bb061f33a8380b3dcec2916411a`.
- Existing ZIP SHA256 matches recorded delivery identity:
  `7e39a1ab41fbe5da5417cc73557ec8e7f4bc5837a52180ed40caaace35183d32`.
- ZIP contains 617 files. The old S29 extraction has all 617 matching files
  plus one generated `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta`;
  it was left untouched. The independent S30 extraction avoids inheriting this
  additional file and contains 617 files.
- Fresh S30 extraction verified against all 617 ZIP entries: 617 extracted
  files, zero missing or mismatched files. Task reference links and scoped
  roadmap whitespace checks passed; the index remains empty and the three
  latest accepted source/test files have no working-tree diff.
- Initial ZIP comparison used the Package directory against ZIP entries that
  already contained the Package-name prefix; its 617 missing-path results were
  a comparison-root error, not byte drift. Correcting the root yielded zero
  missing/mismatched ZIP files. No product operation was attempted.
- Exact package metadata: version `0.3.0-preview.5`, supported Unity line
  `2022.3`; host-current selects generation `poc.43`.
- At initial preparation, proposed `UnityFreshLifecycleValidationProjectS30`
  did not exist. No Unity project was created or opened by the agent and no
  Package reference was configured.

## Subsequent human creation and baseline check

User reported `UnityFreshLifecycleValidationProjectS30 已经创建`. Read-only
inspection confirms the exact proposed path, Assets/Packages/ProjectSettings
and Editor metadata `2022.3.62f3 (96770f904ca7)`. Manifest and lock contain no
`com.rice.ai-codedb` entry; AIWork and project-local .codex are absent. No
matching Unity.exe command line or Temp/UnityLockfile was observed. These are
point-in-time observations, not authority to edit or launch the project.

Initial Package file SHA256 values:

```text
5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1  Packages/manifest.json
2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6  Packages/packages-lock.json
```

The baseline is suitable for the declared first-install route. At this point,
operations awaited the combined grant; the human creation report alone was not
expanded into blanket authorization.

## Authorized Package reference configuration

User `同意授权` approved the proposed combined flow: parent configures the
exact Package and performs bounded status/query checks; human owns Unity and
first Install → Remove → reinstall; stop dependent steps on any failure.

Before editing, observed zero matching S30 Unity processes, zero Unity processes
with unreadable command lines, no UnityLockfile, unchanged initial manifest/lock
hashes and no AIWork or project-local .codex. Initial Package files were copied
to `.backups/s30-current-version-lifecycle-5b52c01/initial-package-config/`
and their hashes verified against the baseline.

Both manifest and lock now select:

```text
file:G:/RiceProgram/UnityCodeDB/.artifacts/s30-current-version-lifecycle-5b52c01/review/com.rice.ai-codedb
```

Lock entry is local, depth 0, dependencies empty, matching the Package's declared
dependencies. Both JSON files parse and all unrelated dependency entries retain
their original values. Comparing all 27 Assets/Packages/ProjectSettings files
before and after found exactly two changed files: manifest and lock, with no
other additions/deletions/byte changes. AIWork and UnityLockfile remain absent.

Post-configuration SHA256:

```text
74197d58458d8347e0a31a928c4c549e0b01a1913a332fa17408b773e8086463  Packages/manifest.json
97d6a9d4ecd24c02c0d12806f4163243f01994f0da58190d291363de65121e9c  Packages/packages-lock.json
```

Exact input recheck: original ZIP hash unchanged; S30 extraction has 617 files,
all 617 ZIP files match, zero missing/mismatched files. No Package re-export.

## First human checkpoint

Open only S30 with the human-selected compatible Editor; wait for import and
compilation. Open `Tools/Rice AI/Codedb/Manager` and report compilation, initial
status and available actions. If the supported `Install CodeDB` action is
offered, execute it once and report its outcome/Ready state. If startup already
performs installation and reaches Ready, report that observation without
repeating Install. If a prerequisite, compile error, absent expected action or
refusal blocks the route, preserve its displayed reason and stop there.

Allow at most the declared 10-minute wait per checkpoint. No Test Runner suite
is requested for this unchanged Package. Do not proceed to Remove or reinstall
until the parent verifies the first Ready/status/query checkpoint. Their
authorization remains valid; this is evidence ordering, not a new approval.

## Limits

The following preparation-stage limits are historical; the later authorized
first-install checkpoint below records the newly obtained real evidence.

No Unity/Test Runner, real lifecycle action, availability probe, new source
test, process control, cleanup, commit, push or release action was executed.
Exact extraction and planning are not lifecycle acceptance. S29 stays archived.

## First Install / Ready checkpoint — PASS

Human reported `ready了` with a Manager screenshot showing Ready and a
successful Install action. Human did not separately provide a compile-test
report; no Test Runner counts are claimed. Real installation is corroborated
by the terminal receipt, selected instance and committed activation, and by a
new parent availability invocation while Unity remains human-owned.

- Install action: `60ab77c35ab5428da4e2bc0ad4f26282`.
- Exact terminal: `cbd9f9ffe2e536da.terminal.json`, terminal_for_action true,
  matching S30 project identity and exact Package-path identity, exit 0,
  elapsed 17022 ms, no timeout/output overflow/incomplete drain.
- Result: `INSTALLED / COMPLETE / INSTANCE_ACTIVATED`, product Ready.
- Selected instance: `3d3c1c70c59a4268bd453a735b63ee2c`.
- Activation epoch: `26f187e4ea874164a103222905aada46`.
- Activation publication: `COMMITTED`; operation `ab871d2828474df59bb9989d80f04b03`.
- Instance JSON raw SHA256 `4b89517d74bd9d6f3e83a031d7668d9c54d3a4537029713d8b6b4cc7cc92a1f3`
  matches both current selection and activation. Instance state is READY and
  its originating action matches this Install action.
- Package version `0.3.0-preview.5`, generation `poc.43`; installed generation
  manifest raw SHA256 `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`
  matches the exact Package and instance reference.
- Desired state `INSTALLED`, state ID `ea3f02e409ef4dcd896613da01e75f4c`;
  cleanup PENDING is retained separately from logical installation success.
- Manifest/lock still select the S30 exact extraction.

Parent invoked the shipped Package-owned availability probe once with observed
Node `F:/Program/nodejs/node.exe` v24.14.1, exact S30 project, authenticated
instance root and generation worker path:

```text
probe-codedb-mcp-availability.mjs
  --project-root G:/RiceProgram/UnityCodeDB/UnityFreshLifecycleValidationProjectS30
  --wrapper AIWork/.runtime/codedb/host/generations/poc.43/wrapper/codedb-project-instance-worker.mjs
  --instance-root AIWork/.runtime/codedb/instances/3d3c1c70c59a4268bd453a735b63ee2c
```

Exit 0, `AVAILABLE`; MCP initialization, exact six-tool list, usable status
and bounded text query all succeeded. The probe validates current backend
Ready lines, not merely the cached Manager label. This is liveness/availability
evidence only, not semantic search accuracy or a real Codex Desktop session.

Evidence preserved under
`.artifacts/delivery/s30-current-version-lifecycle-5b52c01/first-install-a1/`:
Manager screenshot, Install terminal, selection, activation, desired state,
instance manifest, original availability record and fresh `parent-availability.json`.
Screenshot SHA256:
`75411409c43c9b213780101a4c097df95ee9263418dea0ac7d074a63f66853c3`.

Next is the already-authorized human logical uninstall. In this normal Ready
state the supported overflow-menu label is `Uninstall CodeDB from Project`;
`Remove CodeDB Integration` is reserved for RequiresReinstall presentation.
Do not require the alternate label or substitute Package Manager removal.
Obtain the uninstall result before reinstall; the overall S30 route is still
in progress and no complete lifecycle/release PASS is claimed.

## Normal uninstall menu blocker — read-only diagnosis

User reported `没有 uninstall 的选项`; the screenshot shows only Open and
Provider Guidance in the Ready Manager overflow menu. First Install remains
passed. No uninstall action was invoked, so uninstall and reinstall remain
unrun; stop dependent operations under the existing acceptance envelope.

The delivered exact Package contains a deterministic producer/consumer mismatch:

1. `AICodedbEditorLifecycle.WithRemovalPreflight` calls
   `ReadUninstallPreflight` for `currentIntegration=true` (lines 1639–1643),
   then passes the result to shared `IsRemovalPreflightAvailable`.
2. The shipped materializer's `UninstallPreflight` branch (line 12537)
   checks current removal authority and, when successful, emits only
   `[REMOVAL_PREFLIGHT] AVAILABLE`. It does not emit a handoff line.
3. `HasAuthenticatedRemovalPreflight` (line 197) requires one AVAILABLE line
   **and one handoff line**. `IsRemovalPreflightAvailable` (line 1667) also
   requires and validates that handoff payload. Thus a successful normal
   UninstallPreflight output cannot pass this shared validation.
4. `IsUninstallAvailable` (ManagerWindow line 2348) requires
   `RemovalPreflightPassed`; a false value removes the menu entry entirely.
   The separate RequiresReinstall removal path intentionally uses
   `RemoveIntegrationPreflight`, which does produce and consume a handoff.

This source contradiction is sufficient to explain why normal uninstall
cannot be admitted via this contract even if the backend preflight succeeds.
The live in-memory cached diagnostic was not extracted, and no direct
UninstallPreflight invocation was performed. Do not invent a live backend
AVAILABLE/refusal result or claim that this rules out every later runtime
blocker. The recorded selected desired state remains INSTALLED.

This is a current normal-route product defect, not a reason to recover S29 or
replace/reset the clean S30 project. A point-in-time bounded scan of this new
project's selected Supervisor namespace found 108 history files and zero null
children; it is not a process-liveness or universal history-safety verdict.

Proposed bounded repair, pending User approval: make preflight validation aware
of the action/route so normal UninstallPreflight is evaluated against its own
success contract while explicit recovery RemoveIntegration retains its exact
handoff requirement. Preserve backend authority checks, explicit confirmation
and execution-time admission. Do not set the availability flag unconditionally
or relax handoff validation globally. Add directly coupled producer-to-consumer
and menu regression coverage for normal success, normal refusal/malformed
output and recovery handoff-required behavior. Freeze the exact change/test
surface before implementation; no broad historical cleanup or source refactor.

Parent's previous menu instruction checked the label and predicate but missed
the full preflight producer/consumer chain. That instruction was premature;
this read-only diagnosis corrects it. No source change, test execution,
new Package export, reference switch, removal, reset or process control was
performed for this finding.

Evidence screenshot:
`.artifacts/delivery/s30-current-version-lifecycle-5b52c01/uninstall-menu-a1/manager-menu.png`.
SHA256: `3d7e99bb3d2d35c551b4d79638aa6d20fd97a487c16c4b3805fb198096a9778c`.

## Current handoff

- Current task: S30 current-version lifecycle acceptance.
- Current status: SOURCE_AND_ISOLATED_PASS / SOURCE_ACCEPTANCE_PENDING.
- Next notification: User.
- Next action: User decides ACCEPT, FIX, DEFER or STOP for the bounded source result; after ACCEPT, separately authorize commit/export/reference switch, then resume the original S30 uninstall/reinstall route.
- Human decision or authorization required: yes — source acceptance first; delivery and real lifecycle actions remain separate gates.

## Authorized source repair — stable Coder result, 2026-10-15

Status: SOURCE_AND_ISOLATED_PASS / STABLE_FOR_READ_ONLY_VERIFIER.
This section supersedes the earlier source-repair-decision-pending handoff only
for the approved source packet. Real uninstall/reinstall remain paused; first
Install remains passed and was not repeated. No source acceptance/delivery or
complete lifecycle PASS is claimed.

Route: existing historical_handoff_coder reused, no new child, model/settings
inherited unchanged. Actual model identifier is not queryable by this child;
the parent owns route metadata. Base HEAD remains
5b52c017e8415bb061f33a8380b3dcec2916411a; index remains empty.
Exactly the six allowlisted source/test files changed,258 insertions/20 deletions.

### Outcome and preserved authority

Normal UninstallPreflight has a dedicated complete-success classifier: exactly
one exact AVAILABLE marker; blocked, duplicate, malformed, missing, timeout,
overflow and incomplete output refuse. It rejects recovery handoff output rather
than guessing the route from token presence. Worker validation explicitly selects
the declared UninstallPreflight or RemoveIntegrationPreflight action. The original
recovery handoff parser, exact payload/hash validation and backend checks remain
unchanged. Normal diagnostics describe classification instead of claiming a
missing handoff. Existing failed-candidate worker/action attribution and backend
proof paths are unchanged.

Manager separates cached integration visibility from enabled admission. Ready,
known installed and explicit RequiresReinstall states retain the applicable
menu entry while pending/refused/busy; entry is disabled with a bounded reason
in both menu content and a visible header help row. Unknown/missing baseline
does not fabricate an installation or executable action. Ready stays Ready
when removal preflight refuses. Reasons consume only the lifecycle's redacted
cached preflight segment, with a900-character cap, or fixed explanatory text.
Menu/header add no filesystem, Node or PowerShell work.

True running actions and recovery inspection disable removal. An attributable
retained recovery session is not treated as a running action: the existing
confirmed failed-candidate Uninstall flow remains available only when its
preflight admits it, then follows the original proof path. Confirmation remains
mandatory; cancellation dispatches zero actions. Backend locking, authority,
ownership, preflight and transaction/handoff logic are untouched. Actions,
materializer PowerShell, instance engine, Payload and selected Package are equal
to the frozen input bytes.

### Fresh focused evidence

Evidence root:
G:/RiceProgram/UnityCodeDB/.artifacts/tests/s30-uninstall-admission/coder-a1/.
All paths below are relative to this root. EVIDENCE-SHA256.txt freezes original
logs, helpers, producer outputs and prior-attempt logs. No old test result is
reused as current PASS.

| Gate | Result | Evidence |
| --- | --- | --- |
| Scoped diff-check and Package PathProvenanceOnly | PASS | l0-a1.log; final l0-a2.log; path-final617.log |
| Original-byte Editor compile | PASS, exit0, three existing Manager warnings | Rice.AICodedb.Editor-compile-a1.log; .rsp; compile-exact.ps1 |
| Original-byte complete Editor.Tests compile | PASS, exit0 | Rice.AICodedb.Editor.Tests-compile-a1.log; .rsp; compile-tests.ps1 |
| Actual shipped preflight output branch/serializer fixture | PASS seven modes plus handoff/tamper validation; native_children=0 | producer-a1.log; producer-a2/*.stdout and *.stderr; run-producer.ps1 |
| Original C# action parser, cache projection, menu/reason/confirmation consumers | PASS, final34 exact source members | seam-run-a1.log; seam-compile-a1.log; exact-ast-binding.txt; extractor/Extract.cs; Runner.cs |
| Exact shipped617 inventory and six changed-file source binding | PASS, missing0/extra0/changed6 | source-overlay-check.log; verify-source.ps1 |
| Protected source/Package and targeted real-project boundaries | PASS1649 identical entries | protected-before.txt; protected-after.txt; protected-comparison.log; snapshot.ps1 |

The producer fixture executes exact original shipped UninstallPreflight and
RemoveIntegrationPreflight output clauses, not hand-built AVAILABLE strings.
Authority dependencies are explicit synthetic seams; it does not prove backend
ownership. Normal available/refused/no-authority and failed-candidate success,
process-proof refusal and originating-action mismatch are covered. Both original
candidate proof calls remain reached only in their original branch. The original
handoff serializer and PowerShell validator accept the fixture's valid recovery
receipt and reject tampering.

The C# fixture consumes those actual outputs through original compiled parsers,
then exact-source worker cache projection, menu predicates and disabled-reason
consumers. It covers normal success, seven malformed/failure/incomplete variants,
normal/recovery route distinction, recovery missing/invalid/valid handoff,
pending and refused visible entries, bounded backend cause, Ready preservation,
busy state and attributable retained recovery, no-integration non-actionability,
confirmation cancellation and exactly-one-action confirmation. Existing nearest
redaction/cache and recovery handoff assertions also execute. Cache restores in
finally. Only task-owned fixture paths are supplied; native/process calls are
not made by the C# seam.

Original changed Editor and full included Editor.Tests sources compile without
rewriting. S30 does not enable test assemblies and has no Editor.Tests response
file, so the successful test compile uses the prior reviewed response inputs
with every Package source/output rebound to this overlay and newly compiled
Editor. Framework dependency resolution uses existing read-only S29 caches.
This does not run S29 or its tests. The34-member exact seam executes only its
named assertions and pure/cache consumers; complete native Unity test methods,
workspace allocation, OnGUI/GenericMenu and real lifecycle are NOT_RUN. Actual
menu/header original entry consumers are source-hash bound and statically
checked for use of these predicates/reasons. No native GUI PASS is claimed.

### Attempts, original-byte inventory and limitations

First producer helper selected an earlier same-name action-policy switch,
emitted no marker and stopped at normal-blocked disposition. Its empty outputs
remain under producer-a1/. One AST-selection-only correction required the unique
actual AVAILABLE emitter; producer-a2 passed without product source changes.
Initial compiler helper compiled Editor then stopped at the missing S30 tests
response input. The explicit test-input rebinding helper passed. The same known
missing-input boundary occurred once more on the final Editor recompile before
the helper was restricted to Editor only; no failed product compile is hidden.

Before freezing, direct-consumer inspection found this repair's initial busy
guard conflated retained recovery with running. One same-cause source correction
and nearest assertions preserve retained recovery and real-running disablement.
Original first successful logs remain in attempt-a1-record/. Only affected
compilation/seam and L0 checks reran; actual producer outputs were unchanged and
reused. No second independent product cause was repaired.

The human-opened canonical S30 extraction now has618 files: accepted ZIP617 plus
Unity-generated Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta,
GUID a58d22f687287e34eaa604d5eac3c832, SHA256
9989e8abeb5126627bb7e8fed0de57126e33b49579b6da558ad136f354224f65.
Initial compiler/producer/seam used the618 tree. Final owned overlay omits only
that non-code directory-only file, preserving exactly617 shipped paths and all
other bytes except six authorized source changes. Canonical/ZIP remain untouched.
After correction only affected path/inventory gates ran; final source correction
compilation/seam ran on the617 tree. ZIP identity remains the frozen
7e39a1ab41fbe5da5417cc73557ec8e7f4bc5837a52180ed40caaace35183d32.

The first meta-hash check incorrectly expected S29's generated hash and refused;
Coder nevertheless issued the exact owned-overlay deletion, a command-sequencing
error. Follow-up established the S30 GUID/hash above; canonical retains the file
and recovery is available by copying it. First inventory refused the same wrong
expectation. The input-hash-only correction now binds all617 ZIP entries, sole
actual directory extra and exact six changed files. This failure is recorded
explicitly, not retrospectively counted as a first-pass check. No real project,
source or accepted artifact file was deleted. See attempt-notes.md.

Protected checks cover tracked source outside the six writes, exact S30 Package,
ZIP, HEAD/index and targeted S30/S29 Package/selection/activation boundaries.
No whole live-project/history census or external process inspection was performed.
No real preflight, uninstall, removal, install, probe, Unity/MCP/CUA/BatchMode,
process control, environment/configuration change, commit/export/reference switch,
cleanup or publication occurred. Human first-install runtime remains the later
delivery baseline; it was not reset or recreated.

### Frozen source SHA256 and terminal handoff

```text
86dc783bd612c35d6c973007e665688785b9465d479186398a268ca3865f71bf  Editor/AICodedbEditorLifecycle.cs
8c42c3f094b443245189487229f8f6effc7a461c93bea02b5d4068d09b93d1f5  Editor/AICodedbHostPayloadMaterializer.cs
a0e63aeb58b9960780a14d54c9226f311757f713e6c05c68db7e5b6d8a2e678c  Editor/AICodedbManagerWindow.cs
49612f1e4a4bcb80bce559c6ac86e612891307ad45726fe2206015497d8847d7  Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs
a95bea3e96c2d2931ae7da947b4df48b40ab7afc0ee7fc1032b0050e5577d13e  Tests/Editor/AICodedbManagerUiTests.cs
be61964b76445d442d5956e5f89d54c53bbaaf046e5088038cfc87a8db1395af  Tests/Editor/AICodedbEditorLifecycleTests.cs
```

Paths are relative to com.rice.ai-codedb. Parent may admit this stable snapshot
for the already-authorized independent read-only Verifier. User accepts source
after consolidated findings; delivery and resuming the paused real lifecycle
remain downstream gates. Coder stops writing at this terminal handoff.

## Delivery update — 2026-10-15

Source acceptance was authorized by the user (`同意 accept`). The six-file repair was committed as `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`, preserving unrelated working-tree changes. The standard exporter ran against that commit into `.artifacts/s30-current-version-lifecycle-ed97c38/` and reported 617 shipped entries, commit-staged and exact-ZIP byte closure PASS, production payload admission PASS, and native build/binary binding PASS.

ZIP SHA256: `78cc1bea38e9a9ca5f057a916b5ea78c9a4427905d682c242dce52e430cdb08c`; exact review tree count: 617; `package.json` SHA256: `fcb67de746dd681b4194ac2003a867a7be69079d9027fe81a4743b475352402a`.

Exact extracted Package `Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly` passed with exit 0. All 617 shipped paths were compared against the prior S30 extraction: exactly the six accepted source/test files changed. Manifest/lock comparisons against their backups found only the intended CodeDB path replacement. The Git index is empty after the commit.

S30's pre-switch manifest and lock were backed up under `.backups/s30-current-version-lifecycle-ed97c38/`. With no S30 Unity process or UnityLockfile present, both references were switched to `G:/RiceProgram/UnityCodeDB/.artifacts/s30-current-version-lifecycle-ed97c38/review/com.rice.ai-codedb`. The original first Install baseline remains intact and was not repeated. Human runtime validation is now pending: open S30, confirm `Uninstall CodeDB from Project` is visible, perform the logical uninstall, and report the result. Reinstall remains dependent on a successful uninstall.

## Post-switch reopening refusal — read-only diagnosis, 2026-10-15

User reported failure and confirmed it appears on opening the project/Manager,
before invoking uninstall; the uninstall entry is still absent. Screenshot:
`C:/Users/admin/AppData/Local/Temp/codex-clipboard-12ae1812-c785-4eeb-95bc-4238db4e8879.png`.
The displayed reason is `INVALID_OR_AMBIGUOUS: Supervisor process command identity is invalid.`
This is a failed reopening checkpoint, not an attempted or completed uninstall.

Direct, bounded read-only observations:

- Manifest selects the new `s30-current-version-lifecycle-ed97c38` Package.
- Supervisor lock/state record PID 39872, owner epoch
  `a16dfa524a0e4bf1963dc140bc0ff8e8`. That PID is alive, running `daemon`
  from the old `s30-current-version-lifecycle-5b52c01` Package.
- Observed process UTC start identity, executable and normalized command-line
  SHA256 match the recorded owner evidence. This is evidence for the recorded
  original process remaining alive, rather than PID reuse; the exact full argv
  fingerprint was not independently recomputed in this diagnosis.
- Old/new `Tools~/codedb-project-supervisor.mjs` SHA256 are identical:
  `e12dcf9c16e5e435b68da6a964aaa295a1fae0d55ffea5de6d8c8a0c41a451f5`.
- New Package Supervisor `inspectExistingSupervisor` calls
  `validateSupervisorInvocation` (line 567); the latter derives its expected
  script path from `import.meta.url` and rejects a different argv[0] at
  lines 2697–2699. The old process's script location therefore explains the
  reported refusal even though script bytes are equal.
- First-install selection and COMMITTED activation still reference instance
  `3d3c1c70c59a4268bd453a735b63ee2c` and activation
  `26f187e4ea874164a103222905aada46`. Instance raw SHA256 remains
  `4b89517d74bd9d6f3e83a031d7668d9c54d3a4537029713d8b6b4cc7cc92a1f3`.
  Desired state remains `INSTALLED` with original state ID
  `ea3f02e409ef4dcd896613da01e75f4c`.
- The current menu predicate needs Ready, installed-current, RequiresReinstall
  or its specific admitted Uninstalled case. The screenshot instead shows
  Not evaluated after authentication refusal. The bounded repair's real
  Ready-menu behavior therefore remains unverified; do not claim it passed.
- Old Supervisor state separately reports `COORDINATOR_START_FAILED`.
  That detail was not investigated in this bounded script-path diagnosis and
  is not claimed resolved by a future handoff.

Parent's delivery precheck covered Unity closure but missed a still-live
independent Supervisor from the previous Package. Do not loosen ownership
checks or add historical compatibility to conceal that missing handoff.
The existing old-Package `stop` entry authenticates the owner before requesting
shutdown; it was inspected as a possible next operation, not executed.
Any approved attempt must first close S30, freshly authenticate the exact old
owner, request graceful shutdown once, and verify actual exit rather than
treating a shutdown acknowledgement as exit. Stop on refusal/timeout; no kill,
manual lock deletion, state reset or fallback is authorized. Only then may a
human reopen under the new Package and report status/menu before uninstall.

No source/package/reference/runtime changes, process control, Unity automation,
live probe, preflight, uninstall, reinstall or test replay were performed in
this diagnosis. Only task/roadmap records were updated.
