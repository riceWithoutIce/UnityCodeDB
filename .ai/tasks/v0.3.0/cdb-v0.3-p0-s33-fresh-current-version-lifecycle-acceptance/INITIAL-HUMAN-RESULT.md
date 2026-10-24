# S33 initial human baseline - 2026-10-18

Status: HUMAN_COMPILE_PASS / NOT_INTEGRATED_ENTRY_VISIBLE / FIRST_INSTALL_NOT_RUN.

User reports no compilation errors and supplied Manager screenshot ending
`8d971e15-c79b-45cb-84af-e3206c03f2cf.png`. The screenshot shows:

- Package v0.3.0-preview.5, Overview and the normal tab strip.
- `CodeDB is not installed in this project` and a visible Install CodeDB entry.
- Last activity: no recent command.
- A misleading `CodeDB could not finish setup for this project` description.

Button visibility is observed; screenshot alone does not prove successful
activation or backend admission. No Install attempt/result is reported.

## Bounded read-only explanation

Both S33 Package JSON references still identify the exact b0462ed extraction.
AIWork and project .codex/config.toml remain absent at this checkpoint. No live
backend or installation command was run by the agent.

Direct exact-Package source explains the description:

- `Editor/AICodedbProjectIntegrationState.cs` classifies absence of integration
  evidence as NotIntegrated and declares Install available.
- `Editor/AICodedbStatusSnapshot.cs` maps NotIntegrated to inactive and the
  correct not-installed title, but CreateOverallDescription (line 739) omits
  NotIntegrated. It falls through to the generic setup-failure text at line 780.
- `Editor/AICodedbManagerWindow.cs` displays the correct title and Install label
  and routes NotIntegrated actions to the existing confirmed Install entry.

This is a bounded presentation defect, not evidence that Install failed or a
reason to manufacture history/recovery. Recommend a later UI wording FOLLOW-UP;
no source fix, new package, audit or repair loop was started. The user has not
yet decided that follow-up's implementation timing.

## Proposed next first-Install envelope

Authorize one human-confirmed `Install CodeDB` in S33 using the existing exact
Package. Normal product-owned project runtime/config creation and managed
process startup are part of Install; success and subsequent Ready are separate
observations. Agent only reads bounded resulting evidence after the user report.

User procedure after approval: click Install once, confirm once, let that action
settle, and report its actual command result and final Manager state/Console
errors. If it fails, remains unknown or requires a new external prerequisite/
download, preserve the first result and stop; no repeated Install, dependency
installation or state deletion. No Uninstall/reinstall yet. S30 and its history
remain outside this envelope. Pending explicit user authorization; no action
is authorized by writing this proposal.

User subsequently approved this precise first-Install envelope with
`同意，需要我直接点击 install 吗？`. One human-confirmed attempt is now
authorized; its execution and result are pending. All stop/exclusion boundaries
above remain in force. This grant does not establish a successful installation.
