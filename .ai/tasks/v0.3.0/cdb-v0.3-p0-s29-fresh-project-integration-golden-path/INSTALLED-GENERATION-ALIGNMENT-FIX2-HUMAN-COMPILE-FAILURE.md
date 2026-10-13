# S29 generation alignment FIX2 — human compile failure

Date: 2026-10-13. Status: HUMAN_COMPILE_FAILED / REPAIR_PROPOSED.

Continuation: user replied `同意授权` to the bounded proposal below. The
single-file repair and focused evidence are now complete; see
INSTALLED-GENERATION-ALIGNMENT-UPGRADE-CALLSITE-FIX-RESULT.md. Preserve this
original diagnosis/proposal as historical evidence. Source disposition and
new exact delivery remain pending; S29 still references the failed Package.

The human reported a compiler error in the exact d127a45 Package. Screenshot:
`C:/Users/admin/AppData/Local/Temp/codex-clipboard-6322f930-f293-413e-8909-99e06bb80b6e.png`.
Read-only inspection of Unity Editor.log confirms CS7036 at
`Editor/AICodedbHostPayloadMaterializer.cs(107,20)`: the required
`removalPreflightHandoff` argument is missing.

## Confirmed cause

The context-taking private RunAsync now requires five arguments, including the
removal handoff. RunUpgradeAsync still supplies the former four arguments.
Its Upgrade path does not require a removal handoff. The existing three-argument
RunAsync wrapper already forwards null for non-removal actions; the actual
RemoveIntegration entry explicitly forwards its authenticated handoff.
The source and exact extracted file both have SHA256
`c229d9778f07154d8dbb74ddf5e431ecf5fe82c29d8e5f7d0e4efea3dab70b3f`.
Both S29 Package references still select the exact d127a45 review extraction.
This is an accepted-source call-site omission, not an artifact/reference mismatch.

## Bounded proposed repair

Only change RunUpgradeAsync's call in
`com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs` to pass explicit
null after MutationTimeoutMilliseconds. Keep the five-argument signature and
RemoveIntegration handoff requirement intact; do not make handoff optional.
Verify compilation of the directly affected Editor source closure in isolation
and the existing three handoff tests, without launching Unity or executing
materializer actions. Then return the stable snapshot and evidence for source
disposition. A new accepted snapshot requires its own exact delivery grant;
do not modify the immutable exported Package in place.

This note proposes a repair; it does not implement or authorize it. No new
subagent was started, product source edited, export repeated, reference switched,
real operation executed or process controlled during diagnosis.

## Acceptance attribution

Human Unity compilation: FAIL. Focused EditMode/UI/normal-close acceptance:
NOT_CONFIRMED for this Package; stop dependent acceptance. The earlier exact
artifact closure and synthetic PASS remain valid within their stated limits
and do not prove C# compilation. Preserve the failed artifact and previous
records. The three compiler warnings visible in Editor.log are outside this
single-error repair proposal. S29/release remain PARTIAL.
