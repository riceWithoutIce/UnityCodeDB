# S29 Manager admission — combined delivery preparation plan

Date: 2026-10-12. Status: delivery stages 1–3 authorized by the user.
Direct user instruction: “同意授权”, following the parent proposal for scoped
commit, commit-derived export/verification and human checklist preparation.
Project reference switching remains separately gated.

## Proposed delivery

Combine the accepted history/session recovery, producer attribution and instance
ID contract repair snapshots into one local commit-derived package. Base:
`9179d8a1a679056bef19b7e9246988510c3c9284`, existing branch
`codex/v0.3.0-legacy-workflow`. No branch change, push, tag or publication.

The four product-source files are frozen in
MANAGER-ADMISSION-COMBINED-SOURCE-SHA256.txt. Journal and Tests use the latest
instance-ID repair hashes; Window and Materializer retain the earlier accepted
hashes. Older test manifests remain historical, not future delivery authority.

## Completed preparation evidence

- Four complete-file hashes match their accepted snapshots; staged index empty.
- Exporter, release-closure validator, materializer/fixture scripts and poc.42
  coordinator have no worktree modification at the checked paths.
- HEAD payload and generation manifests declare coordinator SHA256
  `928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09`, matching
  the current clean coordinator and the previously delivered extraction.
  This is a targeted hash check, not new full payload admission evidence.
- Dirty worktree manifests declare the older coordinator hash and remain
  protected. No payload/generation bump or hash rewrite is needed for this
  delivery proposal.
- The committed exporter uses git archive from a specified commit and runs
  `Tests~/test-codedb-package-release-closure.ps1` on both commit staging and
  exact ZIP extraction. It does not export the dirty worktree.
- No S29 Unity process was observed in this preparation check. Another Unity
  project was observed and is outside this task. This point-in-time observation
  does not substitute for user confirmation before reference switching.

## Proposed authorized stages

1. Recheck base, accepted hashes and empty index. Stage only the four source
   files and the explicit task records listed below; verify exact staged paths,
   byte hashes and diff-check. Create one local source/evidence commit.
2. Invoke the unchanged exporter once from that new commit to a new repository
   artifact directory named `.artifacts/s29-manager-admission-<short-commit>`.
   Destination must not already exist. Require commit-stage and exact-ZIP
   closure/admission PASS, accepted source hash equality and recorded ZIP hash.
   Existing validator-native VerifyOnly behavior is included in this export
   gate; no real-project Install/Uninstall is included.
3. Prepare a minimal human checklist and delivery record for the exact package.
   Stop on first failed gate, preserve evidence and return the specific failure;
   no automatic retry, payload regeneration or additional repair.

The user has granted these three stages. Project reference switching is
separate and requires the user's S29-closed confirmation and verified package.
Do not infer that consent from silence or from the process snapshot.

## Exact proposed commit allowlist

Product files:

- com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
- com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
- com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs
- com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs

Task records in the existing S29 task directory:

- HISTORY-AGGREGATE-REPAIR-RESULT.md
- HISTORY-AGGREGATE-REPAIR-SOURCE-SHA256.txt
- HISTORY-AGGREGATE-REPAIR-VERIFICATION.md
- PRODUCER-ATTRIBUTION-REPAIR-RESULT.md
- PRODUCER-ATTRIBUTION-REPAIR-SOURCE-SHA256.txt
- PRODUCER-ATTRIBUTION-REPAIR-VERIFICATION.md
- INSTANCE-ID-CONTRACT-REPAIR-RESULT.md
- INSTANCE-ID-CONTRACT-REPAIR-SOURCE-SHA256.txt
- INSTANCE-ID-CONTRACT-REPAIR-VERIFICATION.md
- INSTANCE-ID-CONTRACT-REPAIR-DECISION.md
- MANAGER-ACTION-ADMISSION-ALIGNMENT-2026-10-12.md
- MANAGER-ACTION-ADMISSION-DIAGNOSIS-2026-10-12.md
- MANAGER-ADMISSION-COMBINED-SOURCE-SHA256.txt
- MANAGER-ADMISSION-DELIVERY-PLAN.md

Historical verification records preserve the earlier evidence; the later
diagnosis corrects the earlier 24-character instance claim, and the accepted
instance-ID review closes it. Preserve this sequence rather than silently
rewriting prior conclusions. Delivery result/checklist are created after export
and remain uncommitted unless separately authorized.

No Payload, roadmap/workflow, other task or Unity project files enter the commit.
No whole-worktree staging, reset/clean, amend or unrelated edit.

## Validation limits and human handoff

Source acceptance covers semantic compilation and scoped standalone assertions;
the instance-ID review independently executed nine cases. Complete retained
PowerShell producer-chain and producer attribution fixture remain unrun/blocked
at their previously recorded boundaries.

This export grant does not replay those functional fixtures. After commit,
consistent isolated payload bytes make a later focused fixture possible, but
such execution needs its own frozen scope. Full test or real install acceptance
must not be inferred from package closure.

The later exact-package human gate should verify import/compile, focused Editor
tests as explicitly selected, Manager reopening and conflict explanation,
tab navigation and normal Unity shutdown. Historical orphan remains deferred;
the expected old-project result may be explicit conflict with Install hidden.
No real Install/retry is requested solely to obtain a button screenshot.

Reference switch and human gate do not close the continuous new-project
Install/removal/reinstall golden path. Multi-history admission strategy remains
separate; S29 / release stay PARTIAL throughout these preparation stages.
