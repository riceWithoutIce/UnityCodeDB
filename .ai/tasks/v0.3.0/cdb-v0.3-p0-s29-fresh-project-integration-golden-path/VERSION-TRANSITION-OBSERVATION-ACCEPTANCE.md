# S29 version-transition observation — source acceptance

Date: 2026-10-14, Asia/Shanghai.
Disposition: SOURCE_ACCEPTED_WITH_DECLARED_LIMITS / DELIVERY_NOT_AUTHORIZED.

Human replied `同意 accept` to the consolidated four-file source result and
independent scoped review. This accepts the frozen source snapshot and retains
the disclosed follow-up and unresolved removal-preflight cause. It does not
turn incomplete execution evidence into PASS or close S29/release acceptance.

## Accepted snapshot

Base/current HEAD: c6c2f036aa3c5d08a2334118d9049eff9dd3b875.
Branch: codex/v0.3.0-legacy-workflow. Accepted changes remain uncommitted.
At acceptance, all four worktree hashes matched the stable Coder snapshot;
staged index remained empty and HEAD unchanged.

| File under com.rice.ai-codedb | SHA256 |
| --- | --- |
| Tools~/codedb-instance-engine.ps1 | 9b44744eba5f9e987e49eaa6f4b46c07f070b2d03952a03bfddfd2f520fed957 |
| Editor/AICodedbManagerActionJournal.cs | 6d2937b3df6e9d5aebd454e4971200c1bace52c0c107216f8c9af7a3a1aa2090 |
| Tests~/test-codedb-host-payload-materializer.ps1 | fa180901ea1f10c4d7d1db899f1531698c03a62206cbbc6f204bf67f891012bb |
| Tests/Editor/AICodedbManagerUiTests.cs | cc9e994996a4a38a78f3ec51928bd6e8e9d6bbdc08298ab45f51ea13c963aaab |

## Accepted behavior and evidence

Retained observation uses existing Package-bound historical v2 authority for an
authenticated TrustedPrevious selection. Ordinary CURRENT/Ready and next-change
admission remain strict; historical ownership grants no Install/removal/Ready
permission. Journal projects the actual blocked safety reason.

Independent review: SCOPED_SOURCE_REVIEW_PASS_WITH_LIMITS, no source BLOCKER.
Final isolated PowerShell fixture records 24 synthetic Check assertions PASS;
original-byte C# compilation and path-provenance checks passed within their
documented evidence limits. Both authorized children completed. The prior
captured 2845-entry protected comparison was unchanged; no new live-state audit
or unchanged test rerun was performed merely for acceptance.

## Retained limits and next gate

The complete blocked Journal -> Session -> UI consumer chain has no attributable
execution PASS. Partial consumer assertion success and the later internal-call
failure remain Coder declarations without a preserved final raw runtime log;
the retained-current-index projection has static review only. The authored test
is available for a separately authorized human Unity gate.

The previously photographed removal-preflight exit 4 remains an independently
unresolved cause. This source acceptance does not claim real recovery/removal,
sustained Ready, S29 completion or release approval. CleanupMono remains deferred
observation under the prior user decision.

Next independent stage: prepare the exact accepted-source delivery proposal;
commit, export, project reference switching and human Unity acceptance require
their explicit bounded delivery grant. No Install/Remove/Upgrade, history/index
cleanup, process control, Unity automation, commit/export/reference switch,
push or publication was performed or authorized by this acceptance.
