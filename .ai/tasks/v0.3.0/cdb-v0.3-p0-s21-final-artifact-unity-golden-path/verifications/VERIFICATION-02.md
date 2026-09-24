# Verification 02: S21 FIX 04 Partial V1 Control Recovery

## Outcome

- Verdict: `FAIL`.
- Review date: `2026-09-24`.
- Mode: `GUARDED`, targeted, read-only except for this report.
- Scope: FIX 04 partial Owner Identity v1 explicit-removal recovery and its
  directly adjacent v1/v2 removal regression only.
- Findings: one `P1`; no `BLOCKER`, `P2`, or `FOLLOW-UP` finding.

## Frozen Admission

- Expected and observed HEAD:
  `6cf673db600c02061a12684374d428d56e9cb5b3`.
- The ordered seven-file command was run exactly as authorized:
  `git diff HEAD --binary -- <seven paths> | git hash-object --stdin`.
- Expected and observed identity:
  `c21502eb7d31bc3c2a058a53ef6e8198dcdbc9d8`.
- Admission result: `PASS`; semantic review continued on the frozen snapshot.

## Finding

### P1-01: Editor recovery admission is broader than backend mutation authority

The new Editor classifier can return
`ObsoleteReinstallRequired`, which is the recovery/display state for explicit
`Remove CodeDB Integration`, for durable evidence that the PowerShell mutation
authority must reject.

Two directly adjacent gaps demonstrate the mismatch:

1. `AICodedbControlContract.cs:681-683` verifies only that the historical
   journal's `mutations` value is an array. It does not validate each mutation's
   exact schema, index continuity, target, or uniqueness. In contrast,
   `codedb-instance-engine.ps1:731-739` parses every mutation with its expected
   index and rejects duplicate targets before the explicit-removal authority
   can be returned. A syntactically valid array containing an invalid,
   duplicate, non-contiguous, or unreviewed mutation can therefore produce an
   Editor reinstall-required state while backend removal is guaranteed to
   fail closed.

2. `AICodedbControlContract.cs:593-595` rejects a second selection only when
   `File.Exists(last-known-good-instance.json)` is true. A directory or other
   non-regular entry at that authority path is not rejected by this check. The
   backend first applies the no-reparse boundary and then requires any present
   last-known-good selection to be a regular file
   (`materialize-codedb-host-payload.ps1:10361-10369`).

The direct C# regression at
`AICodedbEditorLifecycleTests.cs:3559-3578` proves the valid classification,
selected-generation mismatch, a non-array `mutations` value, and an unknown
Supervisor entry. It does not exercise a well-formed array with invalid
mutation contents or a non-regular/second selection. The focused PowerShell
fixture proves the backend remains fail-closed, but it cannot close the Editor
display-admission contract.

Impact: malformed or ambiguous partial-v1 evidence can expose the destructive
recovery action in the Editor even though the actual backend correctly refuses
mutation. This does not create deletion authority or prove data loss, so it is
not a BLOCKER. It does leave the explicit FIX 04 requirement that Editor
display permission not exceed backend mutation authority, and its direct C#
rejection coverage, unclosed.

No additional finding was identified within the authorized scope.

## Criterion Results

1. **Exact partial-v1 identity and immutable closure: `PASS` for backend
   authority.** The removal path requires a complete v1 current selection,
   Package-owned instance/generation closure, a `TRUSTED_PREVIOUS`
   disposition, and no valid last-known-good selection. Instance and generation
   bytes are not transaction targets.

2. **Failed Supervisor operation/events and COMMITTED UPGRADE binding: `PASS`
   for backend authority.** The partial namespace must contain exactly one
   bounded failed operation and its contiguous events stream; project,
   namespace, selected instance/generation, runtime hash, and matching failure
   event are bound. Activation and operation must share a valid epoch/operation
   pair, be `COMMITTED`, use `UPGRADE`, and bind candidate/current to the
   selected immutable closure.

3. **Historical journal exception: `PASS`.** Missing
   `retirement_intent_path` and `retirement_intent_sha256` is admitted only
   when the explicit switch is supplied for a v1 `COMMITTED` journal. Ordinary
   activation reading does not pass that switch and remains rejecting. Partial
   intent-field presence remains invalid.

4. **Fail-closed backend boundaries: `PASS`.** Multiple authorities, a second
   selection, invalid/unknown namespace entries, mismatched identity, reparse
   boundaries, incomplete state/lock evidence, a live or ambiguous child or
   selected-instance holder, ambiguous operation directories, retirement
   evidence outside the reviewed closure, and a present but drifted stable
   wrapper are rejected. A missing wrapper is tolerated only in the obsolete
   v1 classification/removal route; ordinary generation resolution remains
   invalid.

5. **Mutation scope and revalidation: `PASS`.** The transaction is built only
   from reviewed integration/control/selection targets. It preserves the
   selected instance, immutable generation, generation lease, and external
   process state. The authority fingerprint includes selection, closure,
   activation/operation, and Supervisor evidence hashes and is recomputed
   immediately before mutation; completion is checked again before commit.

6. **Adjacent original removal behavior: `PASS` on reused evidence.** Existing
   authenticated v2 and orphaned-v1 removal behavior remains covered by the
   final `-OwnerIdentityRemovalOnly` PASS. The partial route does not replace
   state/lock authority or the orphaned-v1 route.

7. **Editor display parity and direct C# rejection coverage: `FAIL`.** The
   backend remains the sole mutation authority, but the Editor durable-evidence
   classifier is broader as described in P1-01, and the new C# test does not
   cover those corresponding refusal cases.

## Reused Coder Evidence

- Final focused `-PartialV1RemovalOnly`: `PASS`, exit `0`, about `30 s`;
  historical journal shape, live-holder/mismatch/unknown/missing/state-only
  rejection, ordinary-read rejection, exact removal, and preserved
  instance/generation evidence. RESULT records the corrected final scenario as
  passing twice after the initial fixture-only transaction-global error.
- Adjacent `-OwnerIdentityRemovalOnly`: `PASS`, exit `0`, about `117 s`,
  covering existing v2 and orphaned-v1 removal behavior.
- Final AST parse of the three changed PowerShell files: `PASS`.
- Exact seven-file scoped `git diff --check`: `PASS`, exit `0`, no output.
- These results were reused as recorded; Verifier did not rerun them.

## NOT RUN / DEFERRED

- PowerShell L0, AST/static/source checks, diff-check, C# compile, EditMode,
  Unity, Unity MCP, BatchMode, other L0/L1, real-project removal, process
  operations, full regression, broad diff, and repository-wide search:
  `NOT RUN` by Verifier.
- Commit, push, Package export, publication, and another visible Unity golden
  path: `DEFERRED`; this report authorizes none of them.
- Production and test files remained read-only. No Coder contact or repair
  dispatch occurred.

## Handoff

Current task: `cdb-v0.3-p0-s21-final-artifact-unity-golden-path`  
Current status: `FAIL / EDITOR_REMOVAL_ADMISSION_EXCEEDS_BACKEND_AUTHORITY`  
Next actor: `UnityCodeDB v0.3 Planner / User`  
Next action: decide `ACCEPT / FIX / DEFER / STOP`. The Verifier does not route
another role or dispatch repair work.  

当前 S21 FIX 04 定向验收已完成；下一步通知 Planner，由用户决定
`ACCEPT / FIX / DEFER / STOP`。
