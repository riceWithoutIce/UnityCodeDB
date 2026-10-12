# S29 Manager admission — durable session replacement repair

Date: 2026-10-12. Status: SOURCE_REPAIR_VERIFIED / DELIVERY_NOT_STARTED.

## Scope

User authorized only the repair of the reported durable retained-result session
failure. The repair is limited to:

- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`

No commit, export, package reference switch, Unity operation, receipt/candidate
mutation, or external process action was performed.

## Repair

When durable recovery replaces a stale recovering session for the same project,
the code now removes the old SessionState marker only when the marker still
starts with that superseded, validated Manager action ID. The new retained
result must first complete successfully. Active sessions, different action
markers, different projects, and failed/conflict recovery remain untouched. The
same exact-marker cleanup also covers domain-reload startup where `_current` is
empty but the project-scoped SessionState marker survives.

The regression now asserts that the old marker is empty and that a repeated
`CurrentFor` lookup returns the retained completed session with the retained
action ID. A second regression covers direct durable restoration with no
in-memory session, representing domain reload.

## Verification

- Focused standalone execution of
  `ManagerActionSession_DurableRetainedResultReplacesStaleRecoveringSession`:
  PASS.
- Focused standalone execution of
  `ManagerActionSession_DurableRetainedResultClearsPendingAfterDomainReload`:
  PASS.
- The focused run reproduced the original path before the repair and passed
  after the repair in the existing isolated SessionState harness.
- Full semantic compilation through
  `.artifacts/tests/s29-post-install-ui/Semantic.csproj --no-restore`:
  `SEMANTIC errors=0`.
- Touched-file `git diff --check`: PASS. Repository-wide diff-check was not
  used because unrelated protected dirty Unity project files already contain
  trailing whitespace.
- Repaired source SHA256:

```text
efd2f66f74883a5c99c0ee28d78d0513cdf8a912ec3d96ce4e00ba1c915a4ca2  com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs
07b4fdd66d921c267686966c037226878c60030075ed40c574d2a50145707f9d  com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
```

The existing harness also performs a separate read-only real-history check using
an older optional-flat package context; that check returned the known
`Manager action index validation failed` Conflict and did not modify evidence.
It is not evidence against this session repair.

## Next gate

The current `1889abe` package still contains the pre-repair source. A new
bounded accept/commit/export/reference-switch cycle is required before another
Unity human gate. S29 and release remain PARTIAL until that later exact-package
gate passes.
