# Real S29 recovery read-only preflight

2026-10-09. READ_ONLY_PREFLIGHT_BLOCKED / ENTRY_DISPATCH_DEFECT.
Following the scoped human gate PASS, user approved continuation of read-only
preflight and operation-scope alignment. No real recovery mutation authorized.
Human Unity remains open; no reference switch, Editor control or process kill.

## Current topology and original evidence

Manifest selects .artifacts/s29-retained-path-poc42/review/com.rice.ai-codedb,
commit a06944c; actual generation stays poc.41. Desired state remains
UNINSTALLED/PENDING, state35db5b76947741278dceeef1d98990c7.

Two PROVISIONING candidates:
- 330b7a972a7649259409fbce4de8ca56 / poc.39, action73c9d6a0a8ba4df0898721265ec515d6,
  bound to the existing removal intent (46retained effects).
- 5a6ff71560234b558e1a42148b680a77 / poc.40, INSTALLf14c0524af324b7a802335a393483fa0,
  operation5acbabf5705f48208d7d57882702d14d; no new retention intent.

Both instance manifest hashes and four original f14c action/admission/claim/
terminal hashes match RETAINED-CANDIDATE-RECOVERY-DIAGNOSIS.md exactly.
Existing removal intent SHA256:
aa6dfb83231fadfc8fc6d1d1ecc963c4053414ede28bacb8bcfb3d810c7c8039.
This confirms retained identities, not current holder/process safety.

## One actual read-only entry attempt

Windows PowerShell invoked the exact extracted materializer with:
-Action UninstallPreflight
-ProjectRoot G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29
-RetainedCandidateActionId f14c0524af324b7a802335a393483fa0.

Exit1 after2.55s:
[RESULT] BLOCKED
[NEXT] Use Install CodeDB to restore this project's integration.
UninstallPreflight cannot reinstall a project whose desired state is UNINSTALLED.

No confirmed mutation switch, fixture fault or fallback direct function call.
No new attempt after refusal. Source inspection shows the early UNINSTALLED
switch11930ff routes preflight into its default refusal, before the dedicated
UninstallPreflight branch12125ff. The latter's actual candidate/action/process
checks therefore never run. This error is not evidence that a live holder was
found and is not permission to call the mutating Uninstall route instead.

## Scope gap and proposed coherent correction

The earlier PS41/39 fixtures import production function bodies; the extracted
C#32reader harness covers record consumption. The authored worker-presentation
test uses bounded service seams. None proved the full materializer CLI preflight
dispatch for UNINSTALLED. All those PASS results remain valid within declared
scope; they did not close this top-level entry. Prior tests must not be relabeled
as failing or as proof of real preflight safety.

Proposed next repair: let the read-only retained-candidate UninstallPreflight
reach its existing dedicated validator when desired state is UNINSTALLED,
without routing to Install or weakening other action admission. Add one full
CLI dispatch regression in a repository-local synthetic retained topology,
including an action mismatch/unknown-candidate refusal. Check whether the
existing confirmed Uninstall top-level route preserves the action/intent/marker
bindings in the same topology; no whole-Host audit or unrelated warning cleanup.
Use actual entry dispatch, not another direct-function-only PASS.

Next scope needs user disposition before implementation under the existing
Coder/independent Verifier workflow. Preserve both real candidates, existing
intent and original failed/incomplete receipts. Real recovery execution stays
separate, pending successful preflight including current process/holder checks.
No product/source edit, install/uninstall/recovery, cleanup, registration change,
remote write or publication occurred. Only this diagnosis/status was written.
