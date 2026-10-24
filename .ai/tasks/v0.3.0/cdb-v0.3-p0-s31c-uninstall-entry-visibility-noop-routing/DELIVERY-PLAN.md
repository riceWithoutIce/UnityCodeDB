# S31-C bounded delivery proposal — 2026-10-17

Status: AUTHORIZED on 2026-10-17. User answered `同意 accept` to the combined
source-acceptance and steps 1–4 delivery question. Human Unity execution and
real Install/Uninstall remain excluded. A failed candidate/closure gate stops
dependent delivery without automatic repair or fallback to dirty bytes.

## Source And Target

- Source: HEAD `279b442c657676d1adbda7d15151a3770682a674` plus exactly the
  four final source/test files in the latest F1 section of SOURCE-SHA256.md.
- F1 source/component re-review: PASS WITH LIMITS; F2 stays FOLLOW-UP.
- Source commit scope: only `Editor/AICodedbManagerWindow.cs`,
  `Editor/AICodedbActions.cs`, `Tests/Editor/AICodedbManagerUiTests.cs`, and
  `Tests/Editor/AICodedbEditorLifecycleTests.cs` under `com.rice.ai-codedb/`.
- Proposed commit message: `fix: keep uninstall entry reachable and classify local no-op safely`.
- Excluded protected edits: ProcessRunner, OwnerIdentityV2Status, runtime
  scripts, Payload changes/deletions, workflow changes and other dirty files.
- HEAD Package identity: `0.3.0-preview.5 / poc.43`. The working-directory
  Payload currently selects poc.42; it is not the proposed delivery input.
  Do not repair, regenerate, stage or export these dirty Payload bytes.
- Consumer target: `<repository-root>/UnityFreshLifecycleValidationProjectS30`.
  Its manifest and lock currently agree on the previous exact S30 extraction
  `.artifacts/s30-current-version-lifecycle-ed97c38/review/com.rice.ai-codedb`.
- No UnityLockfile was present during preparation. This observation is not
  sufficient to authorize a live switch; recheck process/lock ownership at
  the actual switch boundary.

## Proposed Authorized Sequence

1. Before committing, bind a repository-local candidate to HEAD plus exactly
   the four source hashes above. Verify the original C# source/test compile
   for that candidate because prior compilation included the dirty tree.
   Preserve existing evidence and use existing local tools without downloads,
   Unity startup, native-reader retry or another isolation repair.
2. Commit exactly those four files after the candidate passes, preserving all
   unrelated worktree/index state. Stop for any unapproved overlapping index
   content. Record the exact new commit and its source hashes.
3. Use the existing exporter against that commit only, under a new
   `.artifacts/s31c-uninstall-entry-<commit-prefix>/` root. Require commit-stage
   and exact-ZIP byte closure plus production read-only payload admission.
   Verify the four source hashes and extracted path provenance, preserving
   previous packages. No generation migration is proposed.
4. Once closure passes and S30 is closed with attributable ownership, back up
   only its Packages/manifest.json and Packages/packages-lock.json under a new
   `.backups/s31c-uninstall-entry-<commit-prefix>/` root, then change only its
   CodeDB references to the new exact extraction. If Unity is open or ownership
   cannot be confirmed, stop the switch and hand close/open ownership to User.
5. Return the exact artifact/reference identity and a focused human checklist:
   compile/test the changed Editor boundary, Ready Overview uninstall label,
   menu entry and Manager reopen/tab behavior. A real uninstall click and
   transaction acceptance require their own bounded human-operation alignment;
   no agent executes it under this proposal.

## Preparation Evidence And Limits

- Four hashes still match the F1-reviewed snapshot; Git index was empty.
- Existing `Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`
  executed once on the current Package: PASS, exit 0; helper projections and
  decoder/caller bindings also passed. It neither exports nor installs.
- That worktree check does not establish the commit-derived candidate or ZIP
  closure. Those remain required in the proposed sequence.
- Prior evidence: compile PASS; initial 22 focused calls PASS before the native
  boundary, overall exit 1; F1 six component calls PASS. Native canonical
  reader/session, actual backend, real uninstall and Unity remain NOT RUN.
- No commits, exports, staging, runtime mutation, process control or reference
  switching were performed during preparation.

## Approval Boundary

User may accept the F1-reviewed source with its stated limits and authorize
steps 1–4 together. A failed exact-candidate/closure gate stops dependent
delivery without automatic repair, scope expansion or fallback to dirty bytes.
Human Unity execution, real Install/Uninstall, process termination, push and
release publication are excluded. Source acceptance alone authorizes none of
those actions.
