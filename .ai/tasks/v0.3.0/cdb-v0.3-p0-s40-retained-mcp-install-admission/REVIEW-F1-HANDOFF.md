# S40 F1 targeted repair review packet

Authorization: user accepted F1 FIX and its nearest regression tests after the
original VERIFICATION.md. Reuse the same stopped Verifier only after the new
stable source and RESULT-F1.md are available. Inherit model/reasoning settings.

Read the original F1 and only the repair delta from SOURCE-SHA256-02.json to
the new SOURCE-SHA256.json, plus RESULT-F1.md and the named new raw receipts.
The source checkout and base remain those in the original REVIEW-HANDOFF.md.
Task records and raw outputs use the same repository-local roots.

Scope: does each retained instance use its own validated normal removal intent,
while current desired-state/removal-intent and registration admission remain
intact? Do the new tests cover A's retained reader through B uninstall/C Install,
and wrong-instance/tampered older-intent rejection? Inspect the nearest effect on
failed-preparation/runtime writer refusal, cleanup accounting and old bytes.

No new comprehensive audit. Source/fixtures are read-only; no test reruns,
external operations, agents, developer messages, cleanup, commit or delivery.
The sole writable file for this turn is VERIFICATION-F1.md in this task folder;
preserve the original VERIFICATION.md. Return whether F1 is CLOSED or remains
open with concrete file/line evidence, and state the isolated evidence limits.
No repair dispatch. Stop after the original finding and nearest regression are
assessed. The parent's TASK.md records the user's FIX/re-review authorization.
