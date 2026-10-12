# S29 HISTORY-AGGREGATE-REPAIR — Verifier result

## Verdict

`PASS_WITH_LIMITS` — the original P1 is closed in the final allowlisted
snapshot. Unity/runtime/release gates remain outside this source review, and
the retained-closure regression does not synthesize the complete producer
marker/effects chain.

This is a strictly read-only review of Base
`9179d8a1a679056bef19b7e9246988510c3c9284`. No source, runtime, receipt,
marker, package, Unity project, or external process was modified.

## Snapshot / manifest

The three allowlisted files match
`HISTORY-AGGREGATE-REPAIR-SOURCE-SHA256.txt`:

```text
878fc673f814e9f209d56ecd50c19fb810fcda59f159d24dca35132520efc040  com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
e5a43316fb801b9e10f83a0141d441ca6a6006d119e60d88232b71a668ced5ca  com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
fbd6cf784764b60cb4ef81eddaddad627e7b795ebff1342ee1b9749c6a157aec  com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
```

`git diff --check` is clean for the three touched files. The Coder reports
Roslyn semantic compilation with `SEMANTIC errors=0`.

## Original P1 re-review — fixed

The current-action plus retained-closure branch now calls
`FindUnownedProvisioningCandidate` before returning the retained result. If an
unowned `PROVISIONING` INSTALL candidate is found, it returns `Conflict` with
the ownership-ambiguity detail while preserving the retained result only as
diagnostic context. With no orphan, the branch returns the retained result as
`Empty` exactly as before. Thus f14-style retained history cannot bypass the
orphan conflict through the early return.

The non-retained current-index path still calls `ReadLegacyPending` and
propagates its `Conflict` result instead of downgrading it to a warning.
`ReadLegacyPending` aggregates action ids from resolved markers and
authenticated legacy action directories, then rejects unowned provisioning
INSTALL candidates. Candidate directory validation uses the restored
24-character lower-hex physical-key rule; malformed or non-physical
candidate directories fail closed.

The new tests cover the orphan legacy-layout path and a current-index orphan
path, plus durable retained history replacing a stale non-running recovering
SessionState action for the same project. The current-index test does not build
the full producer retained marker/effects chain; the retained early-return
guard is directly present in the reviewed source and was included in the
Coder's semantic compilation. This is a test-depth limitation, not an
unresolved source finding.

## Evidence limits

The Coder's standalone runtime harness was attempted against existing S29
runtime evidence. The real project contains the intentionally unowned `poc.39`
candidate (`330b...`, origin `73c9...`), so the real reader returns
`state=Conflict`; this is the expected strict fail-closed result, not a Unity
test pass. The source-of-truth break is outside the three-file allowlist and
the repair intentionally does not infer ownership by time or generation.

Unity EditMode, runtime/IPC, device, and release gates were **NOT RUN**. No
Install, Uninstall, Remove Integration, commit, export, or reference switch
was performed.

## Priority summary

- BLOCKER: none.
- P1: none after re-review; the retained-closure orphan bypass is fixed.
- P2/FOLLOW-UP: full producer retained-marker/effects fixture coverage would
  strengthen regression depth but does not block this source review.
