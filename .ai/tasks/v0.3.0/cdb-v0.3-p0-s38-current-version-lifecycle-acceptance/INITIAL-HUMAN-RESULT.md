# S38 initial human baseline - 2026-10-20

Status: `HUMAN_COMPILE_PASS / NOT_INSTALLED_ENTRY_VISIBLE / FIRST_INSTALL_NOT_RUN`.

The user reports no errors after opening the new project and allowing the
Package to import. The supplied Manager screenshot (attachment ending
`4f63950d-7c57-4810-a4c5-ceb1fe192dc3.png`) shows:

- `current-lifecycle` and Package `v0.3.0-preview.5`.
- `Not installed`, `CodeDB is not installed in this project`, and an
  `Install CodeDB` entry on Overview.
- Last activity: no recent command.
- The normal Overview, Setup, Index, MCP and Policy tab strip.

The generic description `CodeDB could not finish setup for this project` also
appears. This is the previously documented NotIntegrated presentation wording;
the screenshot does not establish that an Install was attempted or failed.
Button visibility does not prove successful action admission or activation.

Read-only checks after the report found no `AIWork/` or `.codex/` in this project.
Both Package configuration file hashes still match `SETUP-RESULT.md`. No S38
Test Runner result has been reported. The exact `d856a8f` Package already has a
human focused Test Runner PASS in the S35/S37 smoke record; that prior result is
reused as Package evidence, not claimed as a new-project test run. The S38
compile and Manager baseline gate passes with that limit.

## Proposed first real action

After a separate explicit grant, the human may click `Install CodeDB` once in
this S38 project and confirm once. Normal product-owned runtime/config creation
and managed process startup are included in that action. Let the command settle,
then report the actual result, final Manager state and any Console errors. The
parent will read only the attributable original receipt, selected identity and
an independent Ready observation before classifying this stage.

At failure, unknown result, a new external prerequisite or ten-minute
nonconvergence, preserve the first result and stop. No second click, automatic
retry, forced process stop, state deletion, Uninstall or reinstall is covered by
this proposal. Writing it does not authorize the action.
