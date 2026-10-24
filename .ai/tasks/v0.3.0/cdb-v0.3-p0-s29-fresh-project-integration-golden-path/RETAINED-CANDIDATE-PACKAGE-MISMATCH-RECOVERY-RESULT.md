# S29 retained-candidate package-mismatch recovery entry — Coder result

Verifier follow-up: the package-mismatch early return was moved after
selected-instance `INSTALL`/`READY`/different-action authentication. Focused
negative coverage now rejects `UPGRADE`, `REINSTALL`, and a same-action-id
candidate before any package-owned contract comparison is bypassed.

## Scope

Base source snapshot: `427a42495e0fd8a5707da3adf368f895dbf524ad`.

Head commit SHA (unchanged; working-tree-only follow-up):
`427a42495e0fd8a5707da3adf368f895dbf524ad`.

Allowlist:

- `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs`
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`

No Unity, MCP, CUA, Install, Uninstall, Remove Integration, package export,
reference switching, runtime mutation, receipt rewrite, or commit was performed.

## Change

When a retained failed-install candidate is fully authenticated but the current
canonical Package key differs from the original Package key, the journal keeps
validating the historical receipts, retained effects, and current desired-state
identity, then skips only the old candidate's fresh activation-contract
comparison against the new Package. This prevents a package switch from being
reported as `Retained candidate fresh activation context conflicts` while
preserving the retained marker and runtime state.

The Manager exposes `Install CodeDB` only for this explicit combination:
authenticated retained failed-install result, completed recovery session,
canonical Package-key mismatch, `NeedsAttention` with no migration reason, and
Host payload `SetupRequired`. Other conflicts remain fail-closed.

## Verification

- `git diff --check`: no touched-file errors; pre-existing unrelated Unity
  project whitespace warnings remain.
- `Tests~/test-codedb-package-boundary.ps1 -ManagerActionWriterOnly`: PASS
  (12 focused writer scenarios).
- `Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly`: DEFERRED/FAIL
  on pre-existing package absolute-path admission at
  `Tests/Editor/AICodedbManagerUiTests.cs`.
- `Tests~/test-codedb-retained-entry-routing.ps1`: DEFERRED/FAIL on pre-existing
  payload source hash mismatch for `Generations/poc.42/coordinator/codedb-watch-coordinator.mjs`.
- Unity EditMode/runtime/release gates: NOT RUN.

The focused UI regression covers exposing the primary action only when the
explicit package-mismatch recovery bit is true and hiding it while an action is
in flight. The journal path remains read-only until the user later confirms the
single normal Install operation.

The focused origin negative cases pass 3/3. Unity import/EditMode/runtime and
release gates remain not run.
