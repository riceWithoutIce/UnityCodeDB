# S29 Accepted Instance Contract - Delivery Preparation Proposal

Date: 2026-10-07. Status: AUTHORIZED / DELIVERY_WINDOW_ACTIVE.
The human explicitly approved this complete preparation envelope after review.
This grant covers the scoped commit, local delivery and bounded read-only
candidate assessment below; candidate mutation remains separately gated.

## Accepted Input

- Branch: codex/v0.3.0-legacy-workflow.
- Base HEAD: 70f33f7e9f7b39b63aaf9c1d4eedba122f67799a.
- Human disposition: ACCEPT the bounded source repair; DEFER F-IMC-01 / P3.
- Frozen 39-path source identity:
  c4a1cfe61877dfce0bd81759840f4b64fd08d1c987b5e9bb76ea1b13be4dba0d.
- Source Package: 0.3.0-preview.5; successor poc.40, sequence 40.
- Independent targeted source review: PASS, zero blockers, one deferred
  pre-existing PS final-LF origin-ID format edge. No follow-up repair here.
- Preserve the original action d8c736504562495dbafdd673c6851efb, first Install
  exit 6 and cleanup PENDING. Human reports the S29 project normally closed.

## Proposed Single Commit

Message: fix(host): close instance manifest consumers in poc.40

The exact product/tool/test scope is the 39 rows in
INSTANCE-MANIFEST-CLOSURE-IDENTITY.txt, with bytes matching those hashes.
Add these six bounded task records, in this task directory:

- INSTANCE-MANIFEST-CLOSURE-PLAN.md
- INSTANCE-MANIFEST-CLOSURE-RESULT.md
- INSTANCE-MANIFEST-CLOSURE-IDENTITY.txt
- INSTANCE-MANIFEST-CLOSURE-REVIEW-PACKET.md
- INSTANCE-MANIFEST-CLOSURE-VERIFICATION.md
- INSTANCE-MANIFEST-DELIVERY-PLAN.md

Include only the named accepted contract sections from two documentation files:

- Documentation~/development-workflow.md: Record Contract Consumer Closure Gate.
- Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md:
  Instance Manifest Contract And Consumer Closure - 2026-10-07.

Documentation paths are relative to com.rice.ai-codedb. Stage those sections
against HEAD, preserving all other inherited edits in the working files; do not
stage either whole dirty document. This yields 47 changed paths. Use an isolated
index or equivalently precise staging, verify the staged scope and exact source
blob bytes, and preserve any existing staged state. The index was empty during
proposal preparation. Do not add the entire task directory or run git add -A.
The large cumulative TASK, unrelated roadmap/history, .gitignore and both local
Unity projects remain outside this commit. Do not reset or clean the worktree.

## Exact Commit-Derived Local Delivery

After that one authorized commit, freeze the resulting SHA as the only export
input. Reuse Tests~/export-codedb-package.ps1; it is unchanged from base HEAD.
Resolve the repository-local destination, validate ancestors/containment and
refuse collision or overwrite:

G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-instance-contract-poc40

This destination is absent and ignored at preparation. Existing artifacts stay
preserved. Invoke the committed exporter with -Commit <new exact SHA> and the
destination above. Its internal committed-staging and exact-ZIP extracted
closure validations are the required byte checks; do not repeat a third one.

On the exact extracted review/com.rice.ai-codedb Package, invoke its own
Tests~/test-codedb-host-payload-materializer.ps1 -InstanceManifestContractOnly
once. Its Package root derives from its own PSScriptRoot; do not substitute
worktree helpers. Expected evidence: PS 45 assertions and Node 26 cases / 52
decodes, with one test-owned Node runner and zero service children. Compare the
39 accepted source hashes against the extracted Package. Record the new commit,
ZIP hash, exact package.json path, byte closure and consumer closure separately.

This gate is new exact-artifact evidence required by the accepted consumer
closure workflow, not a repeat of source acceptance. Do not rerun the two
unchanged nearest regressions, source static batches or the 48 human EditMode
cases. No canonical metadata repair or further generation is part of delivery.

## Same-Window Read-Only Retained-Candidate Assessment

After delivery evidence passes, inventory only CodeDB-owned records in:
G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.

Read bounded control/operation/current/LKG/desired-state/retirement/removal-intent
records under AIWork/.runtime/codedb/control and immediate instance manifests
under AIWork/.runtime/codedb/instances. Follow only exact paths bound by these
records to the failed originating action. Inspect CodeDB's local ownership
marker and necessary referenced generation metadata if needed for that binding.
Reject traversal/reparse escapes; summarize unknown entries without recursively
reading unrelated project data. Do not execute product status or admission
scripts to obtain an inventory, since their transitive effects are not proved
read-only. No process, Provider, MCP, global configuration or editor probe.

Compare those records to the accepted source contract and existing admission /
uninstall routes. Existing Assert-InstanceNextChangeAdmission refuses unbound
or ambiguous candidates; the new parser alone cannot clear that refusal.
On-disk attribution alone does not prove no active effects or grant cleanup.

Return a concrete exact-target handling recommendation with evidence and any
unresolved ownership/effect facts. Never delete/move/adopt a candidate, fabricate
Uninstalled, rewrite generation bytes, reset control state, or retry Install
inside this preparation envelope. Real mutation requires the subsequent
reviewable exact-target decision; do not request broad cleanup authority now.

## Completion And Boundaries

One continuous preparation window, no per-command approvals. Recheck accepted
identity and scope at admission; use normal bounded V2 reads. Stop on identity
drift, target collision, substantive closure failure, ambiguous ownership or
unexpected scope. Allow up to two causally justified command-construction
corrections before side effects; no blind export/test replay or source fix.

Write one INSTANCE-MANIFEST-DELIVERY-RESULT.md (<=16 KiB), append the Planner
handoff to TASK.md, and prepare one human checklist only when candidate admission
can be truthfully described. These later delivery receipts are not silently
amended into the accepted source commit. Record any uncommitted follow-up docs.

No Unity open/close, consumer Package reference change, real Install/uninstall,
candidate mutation, push, tag, publication or remote task update. Unity remains
human-owned. Preparation completion is not whole S29/release PASS.

The human's explicit approval now grants the commit, local export/extracted
consumer evidence and bounded candidate-record reading described above. This
extends the earlier source-only grant for this exact preparation window.
Candidate mutation remains a later exact-target decision.
