# Stage 1: installed host diagnostic capability — 2026-10-21

Status: READ_ONLY_CAPABILITY_CHECK_COMPLETE / NO_COMPLETE_ROUTE_ADMITTED.
Authority: user agreed to Stage 1 in CLIENT-STARTUP-DIAGNOSTIC-PLAN.md.
No live capture, real MCP connection or settings change was performed.

## Bounded inspection

Inspected installed app package metadata, selected shipped JS chunks/CLI
strings, CLI help only, and the existing failure-time log window. No modified
app files, user/global config dump, full environment, live process inventory,
app-server command, message dispatch or schema generator execution.

Installed MSIX metadata reports OpenAI.Codex version 26.1013.4894.0.
PATH resolves a managed codex.exe of 341,312,816 bytes under
`<local-app-data>/OpenAI/Codex/bin/896a0166b774037a/`. The MSIX resource directory
also contains a same-size codex.exe. Equal size is not hash equivalence, and
no running-process image binding was performed. Installed artifact details
below therefore do not prove which exact image/settings the failed parent used.

CLI commands executed were only `debug --help`, `app-server --help` and
`debug app-server --help`; all exited zero. They did not start an app server
or MCP server. The displayed debug app-server command is send-message-v2,
not a retained-stderr reader; it was not executed. No dedicated stderr/export
switch was found in those limited help surfaces, not a claim about every API.

Official OpenAI documentation config-reference/logging page requests returned
HTTP 403. No product support guarantee or undocumented switch is inferred.

## Native evidence capability

The installed CLI binary contains `MCP server stderr (` and
`Failed to read MCP server stderr (` message strings. This supports existence
of code for reading/logging that stream; string presence alone does not prove
the code path, level, sink, permissions or runtime enablement.

Selected installed app.asar chunks were read without executing/importing them:

- `.vite/build/application-network-startup-DB1VeU3v.js`: local app-server launch
  code builds LOG_FORMAT=json and RUST_LOG from process.env.RUST_LOG, defaulting
  to warn. It also prepares executable/child environment/PATH. This is the
  app-server launch layer, not a direct observation of target MCP child state.
- The same chunk's StdioConnection listens to its app-server stderr, stores
  lastStderrMessage and passes it to onerror. This is the app-server's stream;
  it is not proof that target MCP child stderr is forwarded through it.
- `.vite/build/main-C4DYk222.js` has another executor branch with different
  log-filter construction. Do not apply that branch's defaults to this chat.

No log-level override was selected. The actual failed parent setting and the
CLI MCP stderr log site's effective level remain unverified. Active SQLite
rows at TRACE/INFO prove those rows were persisted, but do not establish the
filter at every stderr sink. Thus warn filtering is a candidate visibility
explanation, not a diagnosed cause of absent child stderr or startup failure.

The active `<codex-home>/logs_2.sqlite` was queried readonly only in
2026-10-21T01:58:08Z–01:58:16Z for the exact stderr message text (including
possible tracing prefixes). Zero matching stderr rows. Earlier retained
exact-thread startup/omission rows remain the positive evidence. No historical
full-database scan or unrelated response/header export is part of this result.

## Field and permission assessment

| Route | Established fields | Missing/unverified | Current admission |
| --- | --- | --- | --- |
| Existing desktop/SQLite records | Server/thread, event times, initialize failure, no-ready-client omission | Child image/cwd/entry, stderr, actual exit | Insufficient for root cause |
| Installed native stderr implementation | Message strings exist; app-server has stderr handling | Actual target stream sink/level and a supported bounded capture method | Not yet executable as a reviewed route |
| Existing WPR/logman process route | Previously inventoried PID/parent/image/time and exit templates | cwd/stderr; actual recording rights/field delivery untested | Insufficient alone; no recording |
| Procmon | Not found in PATH or four named common tool directories | Availability, actual fields/filter scope, rights, overhead and bounded export | Not selected or installed |
| Historical intermediary shim | Prepared concept for inherited cwd/executable/stderr | Changes launch topology/timing; real execution untested | Deferred, no implicit reuse |

Procmon lookup was limited, not an exhaustive disk search. Existing Windows
WPR.exe/logman.exe still resolve. No elevation/permission probe, event-channel
change or new recorder was attempted. The earlier ETW capability inventory is
historical and not represented as a fresh live-recording test.

## Recommendation and stop boundary

Stage 1 completes with an explicit evidence gap, not a speculative RUST_LOG
change. Do not spend another actual-host attempt merely to get the same summary.
Changing host log level could require a new parent/restart and change inherited
environment; that tradeoff must be explicit, not a hidden prerequisite.

Recommended next preparation is a separately aligned assessment of a passive
process/file-access tool such as Procmon: verify launch cwd/entry/image and
failed file-open fields, event filtering, permissions and retained raw scope
before any download/install or capture. This could locate an entry/import path
failure even without stderr; it must not promise stderr or guarantee root cause.
If new software is unacceptable, explicitly choose between a reviewed native
logging/restart experiment and the known-limited process-only observation.
The deferred shim remains a later alternative with disclosed timing effects.

No new software, live startup or repair is authorized by this recommendation.
The original registration, source, Package, project runtime and environments
remain unchanged. No commit/push. Continue diagnosis only after the next route
and its concrete envelope are agreed. Unconfirmed FOLLOW-UP remains deferred.
