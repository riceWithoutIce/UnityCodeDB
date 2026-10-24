# S40 F1 Coder repair result

Status: CODER_READY_FOR_TARGETED_REVIEW. F1 reproduced before repair and the
corrected isolated harness passes. Independent repair review is pending.

## Stable identity and bounded change

Base/HEAD remains `c848049d90fbdf618905be25225580642d98d987`, branch
`codex/retained-mcp-install-admission`. Checkout:
`<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.
The four-file uncommitted snapshot is SOURCE-SHA256.json. SOURCE-SHA256-02.json,
RESULT-02-SINGLE-CYCLE.md and VERIFICATION.md preserve the original reviewed
single-cycle source identity, Coder result and F1 finding.

Only two files changed for this repair: the engine and focused PowerShell test.
The caller carries each already validated removal intent's state identity keyed
by retained instance. The helper validates the current desired-state intent as
before, then uses that instance's own state identity to load its retained
normal-removal intent. Existing exact instance/hash/schema/wrapper comparisons
still apply; an absent association grants no exception. Current registration
deactivation is still checked against the latest desired-state identity.

The current project admission is distinct from an older instance's own removal
authority. No schema, history recovery, deletion, process-control, worker or
cleanup-accounting change was made for F1.

## Evidence

Run paths are beneath
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.

| Run/check | Result |
| --- | --- |
| `f1-two-cycle-before-a/run.log` | Exit 1 reproduces F1 at second-cycle admission after B uninstall; original 29 checks and new identity negatives pass before the expected old-reader rejection |
| `f1-two-cycle-after-a/result.json`, `run.log` | Exit 0, 46 checks PASS after repair |
| `f1-two-cycle-after-a/two-cycle-observation.json` | Distinct A/B/C and removal-state identities; command and desired cleanup PENDING; oldest lease present |
| Focused PowerShell parse and diff whitespace | PASS before corrected execution |

The pre-fix engine manifest hash matches SOURCE-SHA256-02.json. The corrected
run's manifest engine hash matches the repaired source. The test was unchanged
between these two runs; this was one reproduction plus one corrected run,
without fixture correction or retry.

Coverage extends the original harness only at F1: keep A's synthetic MCP reader
live across uninstall A -> Install B -> uninstall B -> Install C; reject B's
valid removal intent as authority for A; reject a tampered A manifest binding
even while B's latest intent is valid. A and B's normal removal intents and
all their instance-file hashes remain unchanged after C activation. C and its
epoch differ from both predecessors; command and desired cleanup stay PENDING,
and A's live holder still makes physical-deletion authority false.

The same batch retains single-cycle admission controls, no-retention COMPLETE,
failed-candidate UNINSTALLED/no-selection preservation, and unknown identity,
foreign lease/wrapper, missing/conflicting intent, selected predecessor,
Editor/coordinator, foreign-generation, failed-preparation and competing-writer
rejections. No unchanged S32 or worker scenario was rerun.

## Evidence boundaries and handoff

Evidence class is HARNESS / CONTRACT_ISOLATED: original production functions
and records, synthetic process/prerequisite observations and PocFixture candidate
verification. Repeated *real* client lifecycle, Provider query availability,
Unity behavior and eventual physical cleanup after lease drain remain untested.
The previously recorded PS7 compatibility follow-up remains open, with no PS7
PASS claim. Prior worker/S32 receipts retain their original bounded meaning.

Implementation is stopped at this stable snapshot. Reuse the original authorized
Verifier to assess only F1 and its nearest regression; its sole writable output
is VERIFICATION-F1.md. No automatic broad audit, new child, or repair dispatch.

No external project/configuration or process state changed. Primary dirty state,
immutable payloads and other worktrees were preserved. No Unity, real MCP,
Provider, Install/Uninstall, cleanup operation, commit, export or delivery ran.
All lifecycle execution here was inside repository-local synthetic fixtures.
