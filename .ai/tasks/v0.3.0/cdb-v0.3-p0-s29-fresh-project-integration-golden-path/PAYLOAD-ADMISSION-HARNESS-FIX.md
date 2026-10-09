# S29 F-PA01 harness directory correction

2026-10-09. FROZEN / FIX_AUTHORIZED by user `同意修复`.
FAST_SUBAGENT / STANDING_WORKFLOW ACTIVE; one stopped Coder reuse and then fresh
independent read-only Verifier. Base HEAD 97c46f577c17639af32579c41dbb832eacb9346b.

Finding: exact extracted harness uses PSScriptRoot/../.. as git archive -C root.
Git discovers the ancestor checkout, but relative com.rice.ai-codedb pathspec
then refers to the extracted review subdirectory, failing before regression
assertions. Prior export/admission PASS and failed delivery evidence are intact.

Only edit com.rice.ai-codedb/Tests~/test-codedb-payload-admission.ps1 and write
PAYLOAD-ADMISSION-HARNESS-FIX-RESULT.md. Parent owns this task/review/delivery docs.
Separate test-owned evidence base from actual Git root discovery before fixture
archive. Validate discovery failure clearly; no hardcoded developer path. Retain
existing evidence containment, six-target checks, production reader, source/hash
proof, negative layouts, no-write assertions and package-under-test overlays.
No production materializer/export/closure changes; all Payload/generations,
consumer state/history and unrelated dirty files are protected.

Evidence: PowerShell 5.1 parse, one source harness focused run and one extracted
layout run (script invoked below a review/com.rice.ai-codedb directory). Use
fresh .artifacts/tests/pa41-hf* evidence; directory-local extracted evidence is
permitted under the fixture review/.artifacts/tests. Prove actual Git root is
correct and production repair script overlays come from tested Package, not
worktree replacements. No Unity, daemon, install/configuration, full suite,
cleanup, external commands or repository-wide audit. Preserve failed old root.
Record changed script SHA256, compact commands/results and protected script
hashes; Coder stops at stable snapshot. No commits/push/nested agents/doc edits.

Fresh Verifier reviews only F-PA01 and nearby directory/attribution regression,
using saved evidence. Writes PAYLOAD-ADMISSION-HARNESS-FIX-VERIFICATION.md only.
All findings returned once to User; no Coder messages or new audit. Source PASS
allows Parent's already authorized scoped commit, fresh export, exact extracted
focused run and closed-project reference switch. First failed attempt stops;
user's authorization reopens this precise correction/new delivery route.

Target 20 minutes Coder / 15 minutes Verifier; tool output <=6 KiB per call and
documents <=8 KiB. S29 remains PARTIAL; no real recovery/install acceptance.
