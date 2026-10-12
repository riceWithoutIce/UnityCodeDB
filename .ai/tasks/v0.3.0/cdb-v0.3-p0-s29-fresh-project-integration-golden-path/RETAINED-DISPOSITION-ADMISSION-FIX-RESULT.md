# S29 retained disposition F1/F2 FIX Coder result

Date: 2026-10-12.
Status: STABLE_CODER_FIX_SNAPSHOT / PASS_WITH_LIMITS.
Authorization: user's latest approved F1/F2 three-file FIX; no delivery authority.
Base: b76957a9dbcae9b00eff73775a97c4e8f33ae785 plus frozen original refactor.

## F1 correction and exact-release authority

- Actual `TryAdmit` carries its freshly obtained backend effects observation
  through the mandatory post-publication identity reread. The index lock,
  exact pending action identity and publication of its action manifest remain.
  New dispatch still obtains fresh backend DryRun observation; it never receives
  the Window's cached classification as a reusable permit.
- Public `Read` continues to inspect candidate effects and defaults fail closed
  when the independently validated absent-origin classification is unavailable.
- Private `ReadCore(..., inspectCandidateEffects: false)` is used only by the
  two exact-release methods. `TryRelease` authenticates exact current action,
  original journal history, package and storage before publishing terminal or
  pre-effect-refusal closure. `TryReleaseRetainedEffects` still requires its
  existing validated complete matching retained-effects marker/reader.
- Exact command release does not decide current resource eligibility: it can
  release an authenticated completed action while an unrelated candidate blocks
  the next operation. It does not remove candidate/history or manufacture a
  resource permit. Subsequent `TryAdmit` still authenticates current history and
  independently observed resources. Foreign action release remains rejected.

## F2 correction and Window projection

- Window tracks the actual attached session. If that same-project historical
  session disappears, the null attachment clears only its stale in-flight/status
  projection. Running or foreign session state remains untouched; displayed
  original results remain intact. Repeated null attachment is stable.
- The existing Overview callback-choice expression was extracted unchanged into
  the private instance `GetPrimaryActionCallback` so the actual Window consumer
  can be exercised without executing a confirmed command or rendering GUI.

## Focused evidence

- Harness: `.artifacts/tests/s29-retained-disposition-fix/compile/Focused.csproj`.
  It was copied into this fresh evidence root from the reviewed scoped harness;
  runner has no real-history read path. Its synthetic workspace entry is
  `.artifacts/tests/s29-retained-disposition-fix/unity/Assets`.
- Original production owner fixture reused read-only:
  `.artifacts/tests/s29-retained-disposition/r-e40e4566`, with its original
  `safe-observation.json` and `observation-context.json`. No backend suite rerun,
  old output overwrite, package regeneration or actual project query occurred.
- C# semantic compile against installed Unity managed metadata: **errors=0**.
- Standalone focused managed consumer: **15 cases PASS**. Three newly added
  cases cover F1/F2; twelve immediate previous cases remain passing.
- `ManagerRetainedDisposition_ActualAdmissionPublishesExactOwnerAndRelease`
  (terminal and pre-effect refusal): actual admission with production SAFE and
  absent-origin candidate -> published exact index -> action-manifest validation
  -> exact pending reread -> refuses second owner/foreign release -> session exact
  release -> marker published/current index absent -> unresolved and foreign
  new admission still refused. No backend command is executed.
- `ManagerRetainedDisposition_WindowAttachmentClearsOnlyHistoricalProjection`:
  actual recovering attachment -> attributable SAFE aggregate -> actual null
  attachment -> current Install label and usable nonnull production callback,
  in-flight false, original result unchanged; repeated attachment stable;
  running and unrelated recovering owner remain blocked and unchanged.
- Twelve adjacent cases: two-failure aggregate; durable stale result/reload;
  valid current/legacy instance IDs; orphan conflict/current index conflict;
  invalid instance-directory fail closed.
- Scoped changed diff check: PASS. Unchanged backend PowerShell parse: errors=0.
- One harness compatibility correction: the net35 NUnit `Is.TypeOf<Action>`
  constraint touches unavailable .NET remoting under standalone net10; use a
  nonnull assertion for the already typed production callback instead. The
  production semantic compile and all fifteen managed cases then pass.

## Limits and terminal handoff

- Standalone Window allocation uses managed uninitialized allocation/reflection.
  Native ScriptableObject allocation, Unity OnEnable/rendering/confirmation and
  actual callback execution are **NOT_RUN**. Actual attachment/label/callback
  selection bodies execute; static SessionState/session owner is isolated and
  restored by the existing session fixture. No Unity launch/MCP/CUA/BatchMode.
- New tests exercise exact terminal/refusal release. Retained-effects release
  uses the same private identity/history mode and preserves its existing proof
  reader; this fix does not newly produce another retained-effects marker.
- Original backend forty-seven checks are unchanged and were not rerun. Current
  actual S29 installed-generation mismatch stays deferred, not an Install grant.
- Only Journal, Window and ManagerUiTests changed during FIX. All eight complete
  snapshot hashes are in `RETAINED-DISPOSITION-ADMISSION-FIX-SOURCE-SHA256.txt`.
  Original RESULT, VERIFICATION and SOURCE-SHA256 records are preserved.
- Coder terminal: **PASS_WITH_LIMITS**, no known source blocker; frozen for the
  parent-authorized independent F1/F2 repair review. Source acceptance, Unity,
  package/runtime/release gates remain separate; no commit/export/reference
  switch, protected history/candidate mutation or process control occurred.
