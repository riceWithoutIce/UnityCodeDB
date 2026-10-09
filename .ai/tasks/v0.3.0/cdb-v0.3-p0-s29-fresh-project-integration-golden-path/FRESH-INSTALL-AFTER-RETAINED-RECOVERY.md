# One Manager fresh Install after authentic retained recovery

2026-10-09. PRE_HUMAN_READY / HUMAN_MANAGER_INSTALL_PENDING. S29 PARTIAL.
Human attempt blocked before dispatch: Install entry absent; Manager reports
unrecorded effect. Read-only diagnosis proves C# treats absent optional
AIWork/codedb as an unknown entry, unlike the existing PS producer. Native
recovery remains accepted; Manager retained-reader gate is BLOCKED. See
RETAINED-OPTIONAL-BOOTSTRAP-DIAGNOSIS.md. No fresh Install executed.
User requested continuation from successful real retained-effect disposition to
the distinct fresh Install gate. Parent completed read-only prerequisites; no
new Install, Unity launch, test rerun or process termination executed by Parent.

## Scope and admission

Target UnityFreshInstallValidationProjectS29, existing Package reference
`.artifacts/s29-original-root-poc42/review/com.rice.ai-codedb`.
Package0.3.0-preview.5, current generationpoc.42. Exact accepted source commit
12b3582;38extracted source hashes0drift. Manifest and lock both point to this
Package. Desired UNINSTALLED/PENDING, state13852a6e3cd84136985bd25f7e61a563.
Original recovery disposition/current desired/new intent hashes still match.
Original two candidate IDs unchanged;9original/history/new-link files captured
as baseline in `.artifacts/delivery/s29-original-root/fresh-install-readiness.json`.
No second export or package switch required. No unchanged test suite rerun.

This gate uses the actual Unity Manager Install action. RunInstallCodeDBAsync
uses the normal supervisor/fallback path and post-command classification.
RunDurableManagerAction requires a matching new compact journal owner and action
manifest before it produces admitted evidence and dispatches the Package writer.
The writer consumes that admission; it is not a standalone Install API. A direct
backend CLI would test the engine only and would not validate this Manager
producer/session/receipt/progress flow. Parent will not synthesize real Manager
admissions from test fixtures or replace the agreed human Editor interaction.

## Minimal human procedure

1. Open this S29 Unity project; wait for compilation. Confirm no C# error.
2. Open CodeDB Manager. If Install CodeDB is visible, click it once and confirm.
   If unavailable or blocked before dispatch, stop and report the displayed state.
3. During the same attempt, check whether progress is visible; at completion send
   the full Command result including Action ID and any warning/error. Do not
   repeat Install on failure or manually execute PowerShell.

This gate does not require reopening Codex, Windows restart, changing MCP client
binding, a second Unity project or rerunning unchanged EditMode suites. Keep the
Editor open for the result report; do not request another close/open cycle until
a concrete subsequent file switch or operation requires it.

## Parent read-only follow-up

After the human result, inspect only this new action's producer receipts, native
command outcome/output completeness, current selected candidate/readiness,
generation identity and desired/control/registration linkage. Require distinct
action/operation/candidate identities from f14c0524.../5acbabf.../5a6ff715....
Track progress presentation separately from backend result; UI success alone is
not MCP readiness. INSTALLED with historical cleanupPENDING may be legitimate;
do not treat PENDING alone as failure or relabel original failed/unknown as PASS.
Compare original receipt/intent/disposition baseline; if normal Package cleanup
changes owned candidate effects, attribute it to its actual authenticated cleanup
result rather than assuming fresh Install permits arbitrary deletion.

One confirmed human Install only; failure stops replay and produces one bounded
diagnostic decision. No manual physical cleanup, external process kill or global
Codex configuration rewrite. Overall S29 and release remain PARTIAL until their
separate actual evidence gates pass.
