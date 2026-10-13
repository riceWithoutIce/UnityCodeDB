# S29 Upgrade call-site fix — exact delivery preparation

Date: 2026-10-13. Status: REFERENCE_SWITCH_COMPLETE / HUMAN_UNITY_PENDING.

User replied `批准` to the exact grouped delivery on 2026-10-13. The source
commit, exact export, reference switch and checklist preparation are complete.
See the delivery result for final hashes. No real Remove/Install or Unity
automation was authorized.

After the completed single-file repair and its focused evidence were returned,
the user replied `同意授权`. Record source acceptance and preparation authority
for this repaired snapshot. The previous response did not present a new exact
commit/export/reference-switch group for execution; that group is now frozen
below for a single human approval. Do not replay the d127a45 export or patch its
Package in place. No independent review is claimed or silently required here.

## Confirmed preparation state

- Base HEAD: `4b9beef8f435ed7b85e980f4a60cb01ae64e96b2`.
- Branch: `codex/v0.3.0-legacy-workflow`.
- Normal staged index: empty.
- Single product diff: RunUpgradeAsync explicitly supplies null to RunAsync.
- Accepted raw source SHA256:
  `6089ea99ff56690ad9055336ef28bfe77152705ffcd7eed7db8a5741e25efd1b`.
- Compiler evidence: repaired 30-source Editor assembly has zero errors;
  three inherited ManagerWindow warnings remain outside scope.
- The three unmodified handoff test methods compile and pass under Unity Mono.
- Both S29 reference hashes still match the failed d127a45 delivery:
  manifest `16978556a0816b9b58f731b84f6f63f1122335debc0d26ea2ba4be6bcf9fd759`;
  lock `0b5c064ec498d2123326b13c3254078d63c907d4389587ad13c34ffcb0918c0f`.
- Fresh read-only process check found only unrelated miniGame_int Unity and its
  two workers; no matching S29 Unity. Recheck immediately before switching.

## Exact source/evidence commit allowlist

Only product file:
`com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`.

Only these six task records under
`.ai/tasks/v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/`:

- `INSTALLED-GENERATION-ALIGNMENT-TASK.md`
- `INSTALLED-GENERATION-ALIGNMENT-FIX2-HUMAN-COMPILE-FAILURE.md`
- `INSTALLED-GENERATION-ALIGNMENT-FIX2-DELIVERY-RESULT.md`
- `INSTALLED-GENERATION-ALIGNMENT-FIX2-HUMAN-CHECKLIST.md`
- `INSTALLED-GENERATION-ALIGNMENT-UPGRADE-CALLSITE-FIX-RESULT.md`
- this `INSTALLED-GENERATION-ALIGNMENT-UPGRADE-CALLSITE-FIX-DELIVERY-PREPARATION.md`

Message: `Fix Upgrade async call after removal handoff extension`.
Build an isolated index from the exact base, stage only these seven files,
verify the raw product hash and single hunk, scope and whitespace. No product
projection or fixture staging is required: approved generation bytes are already
in HEAD. Preserve normal index state and all working Payload/fixture bytes,
including intentional absence of committed poc.43 files from the worktree.

## Proposed one-approval delivery group

1. Commit the seven exact paths above locally. No push.
2. Run the existing export script once against that exact new commit, into
   `.artifacts/s29-upgrade-callsite-fix-<source-short-sha>`. Preserve existing
   artifacts. Require existing commit-stage/exact-extraction byte closure,
   production admission and native VerifyOnly, without regenerating Payload.
3. Verify every stage/extraction file and the ZIP inventory. Compare to the
   frozen 617-file d127a45 inventory: exactly one product file differs and its
   raw hash must match the accepted repair; all other 616 files match. Require
   the original 63-file projection and frozen 30-file poc.42 predecessor
   unchanged. Record new ZIP SHA256 and full byte count. The post-human-import
   extra handoff-test `.cs.meta` in the old extraction is preserved but is not
   an accepted source change or part of this new ZIP baseline.
4. After fresh no-S29-Unity and reference-preimage checks, back up only the two
   S29 Package JSON files under `.backups/s29-upgrade-callsite-fix-<source-short-sha>`.
   Switch their single Package reference to the new exact review extraction.
   Require JSON parse, replacement count one each, complete text equivalence
   to backup with that replacement, and read-only protected-state checks.
5. Prepare a new exact-package human checklist: compilation, the same dedicated
   three handoff methods, Manager close/reopen/tabs/readiness reasons and normal
   Unity close. Human launches/runs Unity; no automated substitute.
6. Record completion in a second local evidence-only commit containing only
   this task's delivery result, checklist and relevant status/authorization
   updates. No product changes, project JSON staging, push or publication.

## Stop rules and remaining boundaries

Stop dependent work on unexpected source/HEAD/index drift, artifact differences
beyond the single accepted file, closure/export failure, protected-state drift,
active S29 Unity or mismatched reference preimages. Retain failed evidence; no
retry loop, cleanup or process termination is included. Use current preflight
baselines for any human-maintained runtime state; do not treat earlier receipt
bytes as permanently immutable across human Unity sessions.

Real Remove/Install/Uninstall, generation migration, shutdown repair, historical
cleanup and release acceptance remain outside this group. The current failed
Package and observed import metadata remain intact. A new reference switch
only selects the repaired Package; it does not alter installed poc.42 runtime
or require Ready/Install-button visibility. S29/release remain PARTIAL.
