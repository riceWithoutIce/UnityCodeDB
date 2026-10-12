# S29 historical candidate aggregation repair — Coder result

## Snapshot

- Base: `9179d8a1a679056bef19b7e9246988510c3c9284`
- Head: working-tree-only snapshot; no commit, package export, Unity launch, MCP, or runtime mutation performed.
- Allowlist: `Editor/AICodedbManagerActionJournal.cs`, `Editor/AICodedbManagerWindow.cs`, `Tests/Editor/AICodedbManagerUiTests.cs`.

## Change

`ReadLegacyPending` now checks project-local `PROVISIONING` instance candidates
against the set of action ids observed in authenticated receipts and resolved
markers. An INSTALL candidate whose `originating_action.action_id` has no
matching journal identity returns `Conflict` with an explicit historical
ownership ambiguity detail. This preserves fail-closed behavior while keeping
the authenticated retained result available as diagnostic context; it is never
used to bypass the orphan conflict.

When a current action index still exists, the same conflict is propagated
through that current-index read path instead of being reduced to a warning.

The retained-closure early return now performs the same ownership check before
returning its retained result, so an orphan candidate cannot bypass the
conflict through a resolved current index. A focused current-index regression
was added alongside the legacy-layout orphan scenario.

The regression exercises current-index conflict propagation with an unowned
provisioning candidate. It does not synthesize the full producer retained
marker/effects chain; the retained early-return guard remains covered by the
same source path and semantic compilation.

Durable retained history now replaces a stale non-running recovering
`SessionState` action for the same project, even when the stale action id is
different. The durable journal therefore remains authoritative after Manager
reopen.

Regression coverage adds an orphan `PROVISIONING` candidate journal scenario
and a stale recovering session replacement scenario.

## Verification

- Roslyn semantic compilation: `SEMANTIC errors=0`.
- `git diff --check` on the three touched files: clean.
- Standalone runtime harness was attempted. Existing real S29 runtime evidence
  contains the intentionally unowned `poc.39` candidate (`330b...`, origin
  `73c9...`), so the harness's pre-existing “real reader must authenticate
  source selection/index” assertion now fails closed with `state=Conflict`.
  This is expected evidence for the approved strict policy, not a Unity test
  pass.
- Unity EditMode/runtime/release gates: not run.

The orphan source-of-truth break remains outside this three-file allowlist;
this repair intentionally does not infer `73c9...` from d8 by time or
generation.
