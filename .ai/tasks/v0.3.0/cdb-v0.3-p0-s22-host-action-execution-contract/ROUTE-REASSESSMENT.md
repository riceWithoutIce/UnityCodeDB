# Route Reassessment: cdb-v0.3-p0-s22-host-action-execution-contract

## Trigger

- Blocked acceptance path: a Manager action whose Editor command result is
  lost across Domain Reload remains in Recovery and rejects later actions.
- Repair iterations: 1/2 (FIX 01); consecutive diagnostic-only checkpoints:
  0/3. The immediate structural gate applies without consuming either quota.
- Structural signal: the Manager's session marker and the Editor-owned process
  result have different lifetimes. The marker survives reload; the result and
  process-output observer do not. Another UI branch cannot establish whether
  an external effect finished or who owns it.
- `verifications/VERIFICATION-02.md` withdrew the original P1-01, closed
  unsafe re-admission in P1-02, and retained this adjacent P1 recovery-liveness
  finding. No new verifier pass is inferred.

## Frozen State

- Branch: `codex/v0.3.0-legacy-workflow`; HEAD:
  `6b64f27adb51eeab8394aac6bca722117ac6863c`.
- Ordered six-path binary diff identity, using the path order in `RESULT.md`:
  `7607e335771d0bfe6cbaa01991fa80d4644a3713`.
- Last acceptance state: S22 FIX 01 source review `FAIL/P1` for recovery
  liveness. Focused syntax, Package boundary/release closure, and scoped diff
  checks passed as recorded in `RESULT.md`; Editor tests, semantic compile,
  EditMode, Unity, real Provider/project mutations, and release remain NOT RUN.
- Preserve all six uncommitted Package source/test paths, unrelated S18 work,
  `UnityValidationProject`, selected instance, generation, journals, Provider
  installation, MCP clients, and external processes. No cleanup or retry is
  authorized by this record.

## Causal Summary

- `Editor/AICodedbManagerWindow.cs` persists only action ID, title, and Package
  root in `SessionState`; restored Recovery has no durable result locator.
- `Editor/AICodedbProcessRunner.cs` observes stdout/stderr and exit inside the
  Editor domain. Its async PowerShell path currently cancels the parent on
  Domain Reload. Whether a child effect completed cannot be inferred from the
  lost managed result, a cancelled parent, or a later product status alone.
- Supervisor has operation lookup by operation ID, but the Manager action ID is
  not uniformly bound to it. Provider installation and direct PowerShell
  actions are outside that operation ledger. Configure Dependencies and
  Redeploy can have multiple stages with different authorities.
- A fresh status snapshot describes current product state, not the terminal
  result of the earlier command. Clearing Recovery from status, timeout, or a
  user acknowledgment would restore unsafe admission.

## Candidate Screening

Baseline: Editor-owned process result plus `SessionState` marker, with existing
Supervisor operation evidence for the subset it owns. Evidence sources are the
S22 contract, Manager, ProcessRunner, Actions, SupervisorBridge, the focused
verification, current Package distribution, and the validation-project
ignore file. No external dependency is proposed.

| Candidate | Boundary and advantage | Distribution/data boundary | Decision |
| --- | --- | --- | --- |
| Keep current UI/status and add manual acknowledgment | No new component; cannot prove command completion or safe readmission | Existing Editor state only | Reject |
| Make Supervisor the executor for every action | Durable lookup exists for Supervisor work, but Provider/bootstrap and direct scripts would gain a new execution authority | Requires a broader Supervisor lifecycle and migration contract | Defer; not an S22-local shortcut |
| Use existing Supervisor operation evidence where owned, plus a bounded Package-owned durable command receipt for direct actions | A result writer independent of Editor reload could bind admission, process termination, and a later Manager observation without granting mutation authority | Package-distributed one-shot writer and per-project receipt under user-local application data | Selected design; implementation gated |

Hard gates for the preferred hypothesis:

| Gate | Result | Evidence or required proof |
| --- | --- | --- |
| Target environment support | PASS at design boundary | Existing Package targets Windows Editor and invokes Windows PowerShell. The one-shot writer is an OS process outside Unity's managed domain; its actual reload survival remains an acceptance test, not a claimed runtime PASS. |
| Supported distribution/build path | PASS at design boundary | The writer is a Package-owned `Tools~` PowerShell script, shipped by the existing UPM path; no downloaded dependency or new service installation. |
| Scoped disposable generated data | PASS at design boundary | Use `%LOCALAPPDATA%/Rice/CodeDB/manager-actions/<project-key>/<package-key>/<action-id>/`, with validated keys, bounded output/retention, and exact-record cleanup only after terminal evidence. No receipt goes under the project or Provider installation tree. |
| Ignore/isolation in arbitrary consumer projects | PASS at design boundary | Generated receipts are outside every consumer project checkout, so their `.gitignore` is not an assumption. The existing Supervisor runtime remains under its separately reviewed project-local boundary. |
| Security, filesystem, and credentials | UNKNOWN | Define receipt integrity, path containment, identity binding, redaction, and who can create/finalize it. No new machine-global daemon or mutation authority. |
| Repeatable setup/validation/removal | UNKNOWN | Specify launch, recovery query, expiry, cleanup, and refusal for incomplete or conflicting records. |
| Integration boundary | PARTIAL | Supervisor authority stays with Supervisor; the direct writer records command evidence only. A durable request-to-operation association and multistage correlation still require implementation proof. |
| Advantage over baseline | PLAUSIBLE | Independent terminal evidence could release ordinary reload Recovery without guessing from product status; focused proof is still required. |

The four early gates pass for this Windows-only design and storage selection,
not for a running implementation. The remaining gates are explicit
implementation acceptance criteria. No POC, source implementation, or runtime
write follows from this screening without separate authorization.

## Frozen Design Boundary

- Direct PowerShell actions use one Package-owned, one-shot writer process, not
  a resident machine service. The Editor records admission first, then starts
  the writer with an immutable command descriptor. The writer validates the
  Package script path and arguments, claims the action before any effect,
  starts only its owned command child, enforces the existing action timeout,
  and atomically publishes a terminal receipt. Domain Reload must not cancel
  this writer merely because its Editor waiter disappeared. Unity shutdown
  must not stop unrelated processes.
- The receipt root is derived from the current user's LocalApplicationData,
  never from a hard-coded machine path or a consumer project's ignore rules.
  `<project-key>` binds a canonical project identity; `<package-key>` binds
  Package identity; `<action-id>` is a validated opaque ID. No absolute user
  path, auth token, or credential is serialized into task documents. At
  runtime, reject reparse traversal, conflicting directories, mismatched
  identities, and files outside the exact scoped root.
- An admitted record, a writer claim/start record, and a terminal result are
  distinct atomic states. Terminal evidence binds action ID, project/Package
  identity, effect and authority classification, command identity, writer and
  child process identity, actual exit/timeout, elapsed time, and bounded
  stdout/stderr with an explicit overflow error. A same-user receipt is not
  cryptographic authorization; backend checks remain mandatory.
- A normal reload reattaches by the persisted action ID. Matching terminal
  command evidence closes command Recovery; product readiness is observed
  separately. An admitted-but-unclaimed handoff, missing terminal record,
  stale writer, conflicting receipt, or uncertain child remains fail-closed
  with a bounded diagnostic and no automatic replay or manual Acknowledge
  shortcut. Expiry is a diagnostic, never proof that an effect stopped.
- Supervisor-routed actions retain Supervisor execution authority. Before
  dispatch, bind the Manager action ID as a request correlation ID; the
  Supervisor must durably associate it with the accepted operation before
  effect, and expose a read-only exact lookup after reload. Coalescing with
  another owner's operation cannot masquerade as this action's result.
  Recovery must survive a later unrelated operation and Supervisor restart;
  otherwise it remains blocked. Fallback to direct materializer execution
  must create its own bound receipt and preserve the fallback admission proof.
- Multistage actions retain stage identities in one action record. Configure
  Dependencies separates Provider command completion from later Host
  admission/reconcile; Redeploy separates preflight, confirmation, and
  mutation. A status snapshot alone never fills a missing command stage.

This freezes the contract, not implementation details such as helper function
names or JSON field spelling. If the one-shot writer cannot survive the
current reload cancellation path or Supervisor cannot provide exact durable
request lookup within the frozen boundary, stop and reassess before a local
workaround.

## Coherent Target Contract

1. Capture immutable project, Package, action, effect, authorization, and
   backend operation identities before dispatch. Persist a correlation record
   before the effect starts; a created-but-not-started record must be
   distinguishable from a started process. Never replay automatically.
2. For Supervisor-owned work, query its existing operation authority. For
   direct commands, only an independently surviving, authenticated writer may
   finalize a bounded receipt containing actual exit/timeout and output
   provenance. The receipt is evidence, not permission to mutate.
3. Across Manager close, compilation, reload, and normal shutdown, observation
   may recover a matching terminal result, then separately refresh product
   readiness. Missing, conflicting, partial, or mismatched evidence remains
   Needs Attention with explicit diagnostics and blocks a second owner.
4. Normal completed commands must terminalize after reload without manual
   acknowledgment. Abnormal loss of the writer/receipt must have a bounded
   diagnostic and separately reviewed recovery route; a timeout or status
   refresh alone must not claim quiescence or clear admission.
5. Provider, materializer, activation, and Supervisor mutation/admission
   checks remain authoritative. Do not stop child or unrelated processes,
   alter external Provider state, or broaden deletion authority for UI recovery.

## Human Decision And Frozen Envelope

- Disposition: `REDESIGN`, selected by the user on 2026-09-24. Keep one
  continuous S22 vertical task from admission through visible terminal state;
  do not create a microtask per button, script, or symptom.
- The user authorized freezing this design on 2026-09-24 and subsequently
  authorized one continuous implementation on this exact envelope. Focused
  non-Unity tests below are included. Unity, real Provider/project actions,
  Verifier routing, commit, and publication still require separate approval.
- Exact potential edit allowlist for one continuous S22 implementation:
  `Editor/AICodedbManagerWindow.cs`, `Editor/AICodedbActivityPanel.cs`,
  `Editor/AICodedbActions.cs`, `Editor/AICodedbPaths.cs`,
  `Editor/AICodedbProcessRunner.cs`, `Editor/AICodedbEditorLifecycle.cs`,
  `Editor/AICodedbSupervisorBridge.cs`,
  `Editor/AICodedbHostPayloadMaterializer.cs`,
  `Tools~/invoke-codedb-manager-action.ps1` (new),
  `Tools~/codedb-project-supervisor.mjs`,
  `Tests/Editor/AICodedbManagerUiTests.cs`,
  `Tests/Editor/AICodedbEditorLifecycleTests.cs`,
  `Tests~/test-codedb-project-supervisor.mjs`, and
  `Tests~/test-codedb-package-boundary.ps1`, all under
  `com.rice.ai-codedb/`. `TASK.md` and this route record remain Planner-owned;
  Coder may append only its `RESULT.md` for implementation evidence.
- Provider installer policy, materializer mutation scripts, Supervisor
  scheduling/authority, instance engine, immutable generations, Package
  metadata, `UnityValidationProject`, and unrelated worktree paths remain
  outside the edit boundary. If an in-scope proof needs any of these, stop
  before editing and return to Planner/User.
- One authorized implementation evidence envelope: bounded
  action-route/static contract inventory; one focused one-shot-writer and
  exact receipt-recovery L0 batch; one focused Supervisor request-correlation
  L0 batch; one focused Manager Editor test batch for reload, reentry,
  multistage result, and conflicting evidence; at most one same-cause
  correction per batch; final scoped diff check, Package boundary, and
  Package release closure. No automatic full regression or real Provider
  installation. C# compile/EditMode and human-owned Unity acceptance of a
  commit-derived Package remain separately authorized gates.
- First acceptance proof must cover no-effect handoff, reload during an active
  direct command, terminal result after reload, missing/invalid receipt,
  Supervisor acceptance-response loss, unrelated later operation, fallback,
  timeout, and writer crash. Any path that permits second-owner admission
  without matching authoritative terminal evidence is a stop condition.

## Handoff

- Current task: `cdb-v0.3-p0-s22-host-action-execution-contract`.
- Current status: `WRITER_CONTINUATION_01_AUTHORIZED / CODER_DISPATCH_PENDING`.
- Next notification: `v0.3.coder.deep`.
- Next action: execute Writer Continuation 01 below and append bounded
  evidence to `RESULT.md`. Return to Planner/User at the first stop condition.
  Do not route Verifier or treat existing focused evidence as Unity PASS.

## Writer Continuation 01 (2026-09-24)

- Input: the REDESIGN checkpoint in `RESULT.md` is BLOCKED. Writer L0 attempt
  1 stopped at harness `NativeCommandError`; the single corrected attempt
  reached the first `success` fixture but observed writer exit 1, without
  emitting captured stderr. Prior writer L0 2/2 and corrected retry 1/1 remain
  consumed; this is a new, separately authorized continuation, not a reset.
- Frozen continuation admission: branch `codex/v0.3.0-legacy-workflow`, HEAD
  `6b64f27adb51eeab8394aac6bca722117ac6863c`; tracked 13-path ordered
  binary-diff blob `88788079aa8faf6174bc8739c61e78e0852d7c36`, writer
  blob `5c12fa8d0b7bb38cc9314c0841853acde5e15d57`, composite SHA-256
  `ace4be86a1ca3b49892b2eb3528dd9e1c91e421ca25b79eba09cf31dd285441d`.
- First, change only the focused harness's failure reporting as needed to
  expose the actual writer stderr/stdout and admitted/claim/terminal state;
  make exactly one evidence-only writer diagnostic invocation. Do not infer a
  writer defect from the exit code alone. If this cannot identify one direct
  cause, stop with BLOCKED and preserve evidence.
- If the observed cause is directly within the frozen writer or its focused
  fixture, make one bounded correction limited to
  `Tools~/invoke-codedb-manager-action.ps1` and/or
  `Tests~/test-codedb-package-boundary.ps1`, then run one corrected focused
  writer L0. No further writer retry is authorized. A cause in C# routing,
  Supervisor authority, or another file returns to Planner before editing.
- Only after writer L0 passes, consume the original unused Supervisor
  correlation L0, Manager Editor batch, Package-boundary, release closure,
  final scoped diff-check and identity checks within their existing budget.
  Stop at the first new independent failure; do not convert it into a local
  patch loop. Append one consolidated outcome to `RESULT.md` with all attempts,
  identities, PASS/NOT RUN boundaries, and next actor.
- No Unity/Unity MCP, real Provider or consumer-project action, external
  process termination, protected runtime read/write, Verifier contact,
  commit, push, export, or publication. Preserve unrelated S18 and validation
  project dirty content exactly.

## Closure Evidence Recapture 01 (2026-09-24)

- Input: Writer Continuation 01 in `RESULT.md` is BLOCKED. Writer L0,
  Supervisor correlation L0, Manager source/syntax batch, and Package-boundary
  L0 passed. The only release-closure invocation stopped at its line-5
  parameter default because `$PSScriptRoot` was empty; no closure content
  comparison occurred. Final scoped diff-check was not run.
- Frozen admission: branch `codex/v0.3.0-legacy-workflow`, HEAD
  `6b64f27adb51eeab8394aac6bca722117ac6863c`; tracked 13-path ordered
  binary-diff blob `5867991f75878ea932e67b0a264aa0267faf2750`, writer
  blob `1072cb06b529fc47271c51a39025076252c5ab1e`, composite SHA-256
  `a296d312f676664947660a91493d92e84313c30ba2a770f39afbc364f4a8b43c`.
- User authorization: evidence-only recapture in this same S22 task. Do not
  edit source, tests, Package metadata, or protected runtime. Resolve the
  Package root from the workspace at invocation time and pass it explicitly
  as `-PackageRoot` to `Tests~/test-codedb-package-release-closure.ps1`, with
  no repair switch. One corrected closure invocation only. Record exact
  exit/output/wall time and whether content comparison was reached.
- Only if closure passes, run one exact 13-tracked-path scoped
  `git diff --check` plus one read-only trailing-whitespace/newline check
  of the untracked new writer, then recompute the same
  tracked-diff/writer-blob composite identity. Do not run any other static,
  focused L0/L1, C# compile, EditMode, Unity, or external action. A new
  closure content failure, identity drift, diff-check failure, or required
  scope expansion is an immediate BLOCKED handoff with no local fix/retry.
- Append the outcome to the existing `RESULT.md` with this checkpoint's
  1/1 closure and conditional 1/1 diff-check/identity budgets. Verifier
  routing, commit, export, push, and publication remain separate decisions.

## Guarded Source Verification Route (2026-09-24)

- Closure Evidence Recapture 01 in `RESULT.md` is COMPLETE: explicit
  `-PackageRoot` release closure compared 46 sources with 0 mismatches;
  13-path scoped diff-check, untracked writer whitespace check, and final
  identity passed. Historical BLOCKED attempts remain recorded, not erased.
- The user authorized one independent, read-only GUARDED review of this
  unchanged S22 source snapshot. HEAD is
  `6b64f27adb51eeab8394aac6bca722117ac6863c`; tracked diff blob
  `5867991f75878ea932e67b0a264aa0267faf2750`; writer blob
  `1072cb06b529fc47271c51a39025076252c5ab1e`; composite SHA-256
  `a296d312f676664947660a91493d92e84313c30ba2a770f39afbc364f4a8b43c`.
- Verifier output is only `verifications/VERIFICATION-03.md`. Review the
  original adjacent recovery-liveness P1 and redesigned Manager action
  admission/reentry, direct writer claim/terminal receipt binding and
  fail-closed uncertainty, exact Supervisor request-operation correlation
  through lost response/later operation/restart, fallback and multistage
  provenance, and command result versus product readiness. The accepted S21
  partial-v1 presentation risk and unrelated work remain outside scope.
- Reuse Coder's writer, Supervisor, Manager source/syntax, Package-boundary,
  release-closure, diff-check, and identity evidence. Do not rerun tests,
  compile C#, run EditMode/Unity/Unity MCP, probe real Provider/consumer state,
  read protected runtime, change production/test bytes, contact Coder,
  commit, push, export, or publish. Avoid full diff and repo-wide search;
  use targeted reads and one identity admission check. Drift stops review.
- Report PASS/FAIL, one-time findings with severity and source references,
  reused evidence, identity, explicit NOT RUN/DEFERRED boundaries, and next
  actor. Only original P1 and immediate redesign regressions may block this
  review. Do not infer live Domain Reload or Unity PASS from source evidence.

## GUARDED FIX 01 (2026-09-24)

- Finding: `VERIFICATION-03.md` P1-01. `ReadTerminalReceipt` validates core
  identities but does not require the full writer evidence envelope. Missing
  or altered admission/claim schema and state, writer start ticks, terminal
  child identity, completion time, or output-overflow evidence may still be
  accepted as authoritative terminal evidence.
- Human disposition: `FIX`, selected by the user on 2026-09-24.
- Frozen admission: branch `codex/v0.3.0-legacy-workflow`, HEAD
  `6b64f27adb51eeab8394aac6bca722117ac6863c`; tracked 13-path diff blob
  `5867991f75878ea932e67b0a264aa0267faf2750`; writer blob
  `1072cb06b529fc47271c51a39025076252c5ab1e`; composite SHA-256
  `a296d312f676664947660a91493d92e84313c30ba2a770f39afbc364f4a8b43c`.
- Editable correction boundary: `Editor/AICodedbProcessRunner.cs` and its
  direct `Tests/Editor/AICodedbManagerUiTests.cs` negative-recovery coverage
  only. `RESULT.md` may receive the Coder handoff. No other source/test,
  Supervisor, writer script, Package metadata, Provider, immutable generation,
  validation project, or protected runtime path may change.
- Required behavior: require and cross-check admission `schema_version`,
  `managed_by`, and `state`; claim `schema_version`, `managed_by`, `state`,
  `writer_start_utc_ticks`, and writer identity; terminal `schema_version`,
  `managed_by`, `state`, `child_pid`, `completed_at_utc`, and
  `output_overflow`, with valid values and consistency across records. Any
  missing, malformed, altered, or conflicting field must remain non-terminal
  and fail closed. Do not use current product status, receipt file presence,
  or a successful exit code as a substitute.
- Evidence budget: one bounded source correction; one focused direct negative
  receipt/recovery test or source assertion batch covering each missing-field
  class and the valid receipt; one final scoped diff-check and exact identity.
  At most one same-cause mechanical correction is allowed. Stop at the first
  independent failure, identity drift, allowlist need, or request to rerun
  Unity/Editor runtime tests. Preserve all earlier evidence and the accepted
  S21 risk.
- After a stable Coder handoff, Verifier may review only this P1 and its
  immediate regression. No automatic retry, broad audit, Unity, commit, push,
  export, or publication is included.
- Current status: `GUARDED_FIX_01_AUTHORIZED / CODER_DISPATCH_PENDING`.
- Next notification: `v0.3.coder.deep`.
- Next action: implement this bounded receipt-validation correction and append
  a truthful Coder result. Do not route Verifier until the new identity is
  stable and the focused evidence is complete.

## FIX 01 Completion / Re-review Pending (2026-09-24)

- Coder completed the authorized correction. Only
  `Editor/AICodedbProcessRunner.cs` and
  `Tests/Editor/AICodedbManagerUiTests.cs` changed; the writer, Supervisor,
  Provider, Package metadata, generation, and protected runtime were untouched.
- Final identity: HEAD `6b64f27adb51eeab8394aac6bca722117ac6863c`; tracked
  13-path blob `e1b89e07bcb70b159e53c7cb22e98da7b3a2c605`; writer blob
  `1072cb06b529fc47271c51a39025076252c5ab1e`; composite SHA-256
  `6255c7faa377a2beb203e6d30967db41c71118a029a01894424279019f302cb3`.
- Source/negative-recovery batch passed (two syntax trees, 15 missing-field
  cases plus valid/conflicting envelope assertions), and the ordered 13-path
  diff-check passed. Earlier writer, Supervisor, Manager source, boundary,
  release-closure, and writer-whitespace evidence is reused unchanged.
- Current status: `GUARDED_FIX_01_COMPLETE / VERIFIER_REVIEW_PENDING`.
  A future Verifier review must be read-only and limited to the original
  P1-01 receipt-envelope finding and its immediate negative recovery
  regression. No broad audit or runtime inference is permitted.

## FIX 01 Verifier Re-review (2026-09-24)

- User authorization: one independent, strictly read-only re-review of the
  original `VERIFICATION-03.md` P1-01 and its immediate negative recovery
  regression. The report target is `verifications/VERIFICATION-04.md`.
- Admission identity: HEAD `6b64f27adb51eeab8394aac6bca722117ac6863c`;
  tracked 13-path blob `e1b89e07bcb70b159e53c7cb22e98da7b3a2c605`; writer
  blob `1072cb06b529fc47271c51a39025076252c5ab1e`; composite SHA-256
  `6255c7faa377a2beb203e6d30967db41c71118a029a01894424279019f302cb3`.
- Reuse Coder's focused source/negative-recovery batch, ordered diff-check,
  and identity. Verify only that all required admission/claim/terminal fields
  are required, typed, cross-record consistent, and fail closed when missing,
  malformed, altered, timed, or overflowed; confirm the valid envelope still
  reaches terminal recovery. Do not rerun tests or compile, start Unity/MCP,
  inspect protected runtime, run real external actions, contact Coder, commit,
  push, export, or publish. Identity drift stops review.
- Report PASS/FAIL, one-time findings (explicitly `无` when none), reused
  evidence, identity, NOT RUN/DEFERRED boundaries, and next actor. Do not
  reopen other S22 or S21 findings.
- Current status: `GUARDED_FIX_01_COMPLETE / VERIFIER_REVIEW_IN_PROGRESS`.
