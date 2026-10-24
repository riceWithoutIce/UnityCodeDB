# S39 accepted source: primary-checkout integration preparation

Date: 2026-10-21. Current status: PRIMARY_SOURCE_INTEGRATION_PASS /
NOT_COMMITTED / NOT_RELEASE_ACCEPTED.

The user approved the concrete 72-path proposal, and execution plus bounded
static verification completed. See
[SOURCE-INTEGRATION-RESULT.md](SOURCE-INTEGRATION-RESULT.md). The preparation
updates and source-state description below are retained as historical inputs,
not the current primary checkout state.

Update, 2026-10-21: the concrete three-way proposal and static artifact checks
are complete; see [SOURCE-INTEGRATION-PROPOSAL.md](SOURCE-INTEGRATION-PROPOSAL.md).
It names the disposition of the local selection, predecessor files and coupled
fixture. Primary source writes remain unexecuted. The comparison and open
questions below are retained as the preparation history; the proposal supplies
the subsequently established ownership evidence and the exact write envelope.

The bounded fresh-project functional gate passed; do not repeat its real-client
calls. Next recommended work is bringing the accepted source into the primary
development checkout while preserving existing local changes, before selecting
another feature or deferred issue.

## Current source state

- Primary HEAD: `237c72d9980114b99887fb8e805658447dd8d4fd`.
- Accepted branch: `codex/mcp-project-cwd`, commit
  `c848049d90fbdf618905be25225580642d98d987`.
- Isolated checkout: `.worktrees/cdb-v0.3-p0-s39-mcp-cwd-registration-fix/`.
- Task records/evidence have already been consolidated under the primary root.
- Primary checkout contains unrelated pre-existing changes. A successful isolated
  delivery does not mean these changes have been merged or accepted.

Read-only comparison of the 41 frozen Package paths found 37 whose current
primary bytes equal the base (including absent new files), and four whose
primary bytes diverge from that base:

- `com.rice.ai-codedb/Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md`
- `com.rice.ai-codedb/Payload~/host-current.json`
- `com.rice.ai-codedb/Payload~/payload-manifest.json`
- `com.rice.ai-codedb/Tests/Editor/OwnerIdentityV2Status.json`

This is a raw-byte collision screen, not a semantic conflict verdict. Do not
assume a divergent file is disposable, use it as grounds for broad rollback,
or replace the primary checkout with the accepted checkout. Existing historical
generation deletions/local metadata may belong to other work and require cause
classification before applying new selection/cross-hashes.

Evidence: `.artifacts/maintenance/s39-source-integration-preparation/comparison.json`.

Focused semantic inspection found real existing deltas, not just EOL status:

- The integration contract has local first-install versus reinstall and
  prerequisite clarification text. Preserve this wording while incorporating
  the accepted cwd-registration amendment.
- The primary host pointer and payload manifest currently select poc.42,
  whereas the base selects poc.43 and the accepted commit selects poc.44.
  The local payload transition/retired-target inventories also differ.
- The local OwnerIdentityV2Status fixture matches the local poc.42/runtime
  contract selection. It must not be independently overwritten while leaving
  the rest of that selection inconsistent.
- The prior tracked status includes locally deleted poc.43 generation files.
  Those bytes are required as preserved predecessor inputs by the accepted
  candidate; their disposition is part of integration, not incidental checkout
  repair. No deletion or reset was performed during this inspection.

Do not label the existing poc.42 arrangement accidental or damaged: its owner
and intended disposition have not yet been established. Normalizing it back to
the accepted candidate would be a source-state decision, not a read-only tidy.

## Proposed bounded next step

Inspect just the four divergent files and adjacent generation/metadata ownership
to classify which deltas are unrelated local work and which are merely formatting
or previously prepared generated output. Prepare a three-way integration from
base -> accepted source while preserving unrelated primary changes. Validate
the concrete proposed result before any primary source write. Do not stage,
commit, cherry-pick, reset, restore deleted historical generations or regenerate
cross-hashes merely because the source gate passed.

Any integration requiring a disposition of existing local work must name that
disposition explicitly. Package selection metadata and immutable-generation
bytes must stay mutually consistent; do not patch one hash as a shortcut.
No new client call, external Package switch, Unity action or independent audit
is implied. Further focused checks depend on the actual agreed integration
delta; do not rerun passed unchanged tests to fill this planning step.

After source alignment, choose the next objective separately. Old-project
migration/holder admission, Ready/Unconfirmed, full session attribution and
public release gates remain deferred. No deferred item was activated here.
