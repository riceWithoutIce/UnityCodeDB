# S29 archive decision — 2026-10-15

Status: **ARCHIVED / PARTIAL / NOT_RELEASE_ACCEPTED**.

## User decision and effect

User: “同意我们不应该继续执着 s29 了，它已经偏离我们开发路线而无限兜底了。我建议 s29 直接归档。”

S29 is closed administratively with partial results. Stop extending this task
to recover arbitrary retained candidates, historical operations or execution
trees. Its historical recovery is no longer a prerequisite for progressing
normal product development. This decision supersedes earlier “current”,
“next”, pending-human and continuation instructions throughout this task folder,
including RETAINED-EXECUTION-ISOLATION-ALIGNMENT-PLAN.md. Historical grants are
records of completed or bounded work, not instructions to replay operations.
Any reopening requires a separately agreed scope and applicable authorization.

Archival preserves accepted source changes, evidence, packages, the S29 Unity
project and runtime records in place. It does not delete, relocate, rewrite or
clean them, bypass safety admission, or mark unresolved behavior fixed.

## Results retained

| Route / evidence | Disposition at archival |
| --- | --- |
| Source repairs and focused verification | Accepted bounded slices remain accepted; latest source is `5b52c017e8415bb061f33a8380b3dcec2916411a`. |
| Latest exact delivery and human smoke | Package delivery and human-reported Test Run / normal Manager operations passed; see the authority delivery and human records below. |
| Historical real first Install | Successful poc.42 installation and Ready evidence retained; this does not prove a clean first Install of the latest package. |
| Historical real logical uninstall | Successful 2026-10-08 logical uninstall retained; physical cleanup was not completed. |
| Continuous latest-package golden path | Not completed. No full Install → Ready → Remove → reinstall → Ready PASS. |
| Cross-version replacement | Remove old integration → Install target version remains the agreed route; full acceptance is pending. |
| Runtime / MCP / release acceptance | Not established by S29 archival or its source and smoke results. |

Evidence entry points:

- [Latest human result](REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-HUMAN-RESULT.md).
- [Latest exact delivery](REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-DELIVERY-RESULT.md).
- [Historical reinstall result](REAL-REINSTALL-VALIDATION-RESULT.md).
- [Historical successful Install](POST-INSTALL-EDITMODE-UI-HUMAN-RESULT.md).
- [Read-only process diagnosis](REMOVAL-PREFLIGHT-PROCESS-OBSERVATION-DIAGNOSIS-2026-10-15.md).
- [Bounded isolation feasibility result](RETAINED-EXECUTION-ISOLATION-FEASIBILITY-RESULT.md).

## Unresolved limitations retained without active S29 work

The existing S29 project's removal remains refused by historical evidence
admission. Two operation histories retain `child=null`; complete termination
or isolation proof was not established. They are not demonstrated live orphan
processes. PID absence, confirmed PID reuse and unknown process identity remain
distinct; unknown identity does not authorize ignoring or stopping a process.
No brute-force PID termination or new retrospective fallback is adopted.

Unity shutdown / CleanupMono remains a deferred observation item under the
user's earlier decision, not an active S29 repair. Old code and historical
content cleanup remain a separate post-stability task under
[the cleanup plan](POST-STABILITY-CLEANUP-ARCHIVE-PLAN.md).

## Forward route

Align a separate bounded task for current-version normal lifecycle acceptance:
clean first Install → Ready → Remove Integration → Uninstalled → Install → Ready.
Keep controlled cross-version replacement acceptance separately attributable:
Remove old integration → Install target version. Neither route inherits a
requirement to repair arbitrary S29 history or a claim that S29 passed.

This archive update does not create a new project, start either route, authorize
new source changes, run Unity, perform Install/Remove, switch references, export
a package, commit or publish. Existing safety refusals remain intact.

## Tracking scope

Local task, result, handoff, documentation index and roadmap entries are updated
to this decision. A read-only GitHub issue search for `S29` returned no matching
issue; no remote issue or Project item archival is claimed.
