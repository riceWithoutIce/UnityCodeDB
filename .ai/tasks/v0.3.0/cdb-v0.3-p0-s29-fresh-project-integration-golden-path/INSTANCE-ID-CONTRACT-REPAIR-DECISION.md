# S29 instance ID contract repair — User disposition

Date: 2026-10-12.
User decision: `ACCEPT_WITH_LIMITS`.
Direct user instruction: “同意 accept”.

## Accepted snapshot

The user accepts the source snapshot reviewed in
INSTANCE-ID-CONTRACT-REPAIR-VERIFICATION.md (`PASS_WITH_LIMITS`). The parent
rechecked both hashes against INSTANCE-ID-CONTRACT-REPAIR-SOURCE-SHA256.txt
before recording acceptance; both match.

- Base/HEAD: `9179d8a1a679056bef19b7e9246988510c3c9284`.
- Journal SHA256: `210f4b20ff948df31e9368adbfc06a428276865fd7123a360ef0b499559e1327`.
- Tests SHA256: `27e962563aef0eccf147945afd66e7b73ccdc6892d546cfa561d4f5c7896cc7b`.
- Working-tree-only; earlier history/producer slice changes remain included
  in these complete-file snapshots. The earlier Journal/test file hashes are
  superseded for any future delivery that includes this repair.

Accepted evidence is semantic compilation, nine focused standalone cases,
pre-fix comparison, source review and hash consistency. Independent Verifier
completed with no BLOCKER/P1/P2 in the agreed scope.

## Preserved limits

- Full PowerShell retained producer chain, Unity/NUnit runner, native UI and
  real-project validation of these bytes remain NOT_RUN.
- Historical orphan attribution (`73c9...`) remains User-DEFERRED and strict
  fail-closed. No promise that the existing S29 project immediately exposes Install.
- Multi-failure history admission/presentation remains a separate strategy task.
- Dirty worktree payload hash mismatch is unchanged; acceptance does not
  authorize rewriting manifests or exporting from the dirty payload state.
- S29 / release remain PARTIAL.

## Next boundary

Source review is closed for this snapshot. Next work is alignment of isolated
validation and delivery preparation, including the combined accepted source
set and a consistent committed payload baseline. This decision alone does not
authorize commit, export, project reference switching, real Install/Uninstall,
Unity launch, external publication or history cleanup.

The parent recorded this decision only; no product source or runtime state
was changed at acceptance.
