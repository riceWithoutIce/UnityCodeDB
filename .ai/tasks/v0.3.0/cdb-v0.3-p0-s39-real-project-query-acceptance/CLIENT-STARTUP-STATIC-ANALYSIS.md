# Correct-root client startup: static cause analysis — 2026-10-21

Status: STARTUP_BOUNDARY_NARROWED / ROOT_CAUSE_UNRESOLVED / READ_ONLY_ANALYSIS.
User authorization: `我们分析问题`. No implementation or operational attempt.

## Established outcome

The CodedbTest_1 client reaches target-server startup but initialize fails
before ready-client exposure. Existing desktop intervals are 174 ms and 85 ms;
these are event intervals, not proven child process lifetimes. Not a 120-second
startup timeout, a search/no-hit failure, or a wrong acceptance-chat cwd.

An additional active database was found at `<codex-home>/logs_2.sqlite`.
The previously inspected `<codex-home>/sqlite/logs_2.sqlite` is a separate older
database. Readonly SELECTs bounded to 01:58:08Z–01:58:16Z of the active database
corroborate, for thread 01a15c2e-25ee-7620-9cad-ade624685b4a:

- id 98064591, target codex_mcp::rmcp_client: startup failed, initialize
  connection closed.
- id 98064593, target codex_mcp::connection_manager::tool_catalog: omitting MCP
  server without an exact ready client, server_name codedb-codedbtest-1.

Retained only those exact-thread/server event suffixes in
`.artifacts/tests/s39-attempt03-codedbtest1/existing-runtime-startup.json`.
The earlier no-matching-row result applied only to the old database, not the
active log store. No child stderr/cwd/executable/exit was obtained from the
bounded MCP-target rows. Full runtime/config/environment dumps were not saved.

This establishes tool omission downstream of failed startup. Complete effective
config and actual process launch still are not observed.

## Startup chain and diagnostic coverage

Read the exact delivered Package under
`.artifacts/tests/s39-diagnostics-delivery/r-e9f859cd/execution-9c51a1ce/export/review/com.rice.ai-codedb/`.
Production source is referenced below relative to that Package root.

1. Host resolves `node`, cwd `.` and relative entry argument. Host config
   selection/startup events do not disclose the child's actual resolved paths.
2. Node opens/parses/links the wrapper and its static imports. Failures here
   precede all wrapper-body logging, even though the file contains a try/catch.
3. Wrapper validates arguments and its module-owned Unity root. Only after
   owned-root validation does it set diagnosticRoot. Earlier failures have no
   diagnostic destination; stderr is the only intended error evidence.
4. Wrapper checks asserted cwd/root, pointer, instance/generation/worker hashes,
   then creates a Worker. Ordinary caught failures now request a termination
   diagnostic; normal worker error/exit also requests one.
5. Worker links its own imports, checks Node major (22/24), builds context,
   verifies LOCALAPPDATA/Provider and instance, and publishes a lifetime lease.
   Failures propagate through the already-created wrapper Worker events and
   ordinarily produce a wrapper diagnostic, subject to logging limitations.
6. Worker installs stdin protocol handlers; initialize returns server metadata
   and tools/list returns tools. Search/index work is later. It does not wait
   for a real query to return initialize.

Coverage references: `Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs`
(imports, fail, writeTerminationDiagnostic, resolveUnityRoot) and
`Payload~/Generations/poc.43/wrapper/codedb-project-instance-worker.mjs`
(Node gate, createContext, resolveMachineProvider, acquireInstanceLifetimeLease,
stdin end, handleRequest initialize). Registration writer:
`Tools~/materialize-codedb-host-payload.ps1` around lines 3924–3928.

Important distinction: wrong actual child cwd can prevent Node finding the
relative entry at all (no self-log), or, if the entry was reached, fail the
wrapper's asserted-root check (normally self-log). Correct chat cwd alone does
not prove effective child cwd. No claim is made about Codex's undocumented
relative-cwd resolution rules; the missing actual launch facts must decide it.

## Hypothesis assessment

| Candidate | Fit with existing evidence | What remains missing |
| --- | --- | --- |
| Node cannot open intended relative entry; actual child cwd/entry differs | Can explain quick initialize closure and no new self-log | Actual Node image, effective cwd/entry and stderr |
| Node loader/static import/runtime pre-body failure | Can explain both observations | Actual Node/options and stderr; body-entry evidence |
| Unsupported Node, LOCALAPPDATA/Provider failure in worker | Can explain early closure, but normally should emit wrapper worker-exit diagnostic | Error/exit and reason diagnostics absent; not established |
| Pointer/hash/instance validation failure | Normally diagnostic after root validation; client disk checks pass | Time-specific stderr and execution identity |
| Log write refused or process forcibly interrupted | Preserves no-log ambiguity for later failure paths | Exact failed write/termination evidence |
| Missing registration or target tool intentionally absent despite ready | Inconsistent with target startup failure and no-ready-client omission events | No evidence of successful target ready client |
| Query/index operation, 120-second timeout, reported Unconfirmed transition | Not the observed failure boundary | No basis to expand into these areas now |

These are investigative priorities, not numerical likelihoods or a root-cause
verdict. 85/174 ms by itself cannot distinguish them. No successful installation
can prove that the Codex parent uses the same launch environment.

## Current static artifact checks

Five installed files match the delivered Package byte-for-byte: stable wrapper,
its manifest-decoder import, immutable worker, and that worker's host-use-gate
and manifest-decoder imports. The earlier missing shared-helper defect is not
present in the current inspected installation. This is current filesystem
evidence; it does not reconstruct file access at the failed startup instant.

Diagnostic destination ancestors currently contain no reparse points. The
existing normal-use record proves writing worked in that earlier context;
no write test was performed in the failed host context, so permissions/write
failure cannot be categorically excluded. Lease cleanup on worker exit means
absence of a surviving MCP lease does not prove it was never created.

The installer probe explicitly chooses process.execPath and cwd=projectRoot
for the stable entry, while a candidate probe uses a Worker directly. Neither
is the Codex parent's actual `command=node`, relative-cwd/entry resolution.
This launch-boundary difference explains the evidence gap; it does not itself
prove which setting is wrong. No manual probe was run during this analysis.

## Next diagnostic target, not an execution grant

Prioritize capturing the actual failed child's stderr and resolved entry/cwd/
Node image and exit, before changing registration, package, Node or environment.
An existing host-native bounded stderr/launch record would preserve the normal
path best. Current inspected logs lack those fields. A passive process trace
could narrow image/lifetime/exit but cannot alone supply cwd/stderr with the
previously inventoried capabilities. Another wrapper-body log alone cannot
cover entry-load failure. Re-Install or another unchanged query attempt would
not resolve that evidence gap.

Any additional live capture must be separately aligned for real startup,
attribution, bounded fields and timing impact; a shim/config workaround remains
deferred, not approved here. No tool retry, source/config/runtime mutation,
Unity/Provider/wrapper launch, process inventory/control, tracing, new chat,
commit or push occurred. Only analysis/task evidence was written. The independent
Unconfirmed FOLLOW-UP remains deferred.

## Post-observation-04 cwd/import refinement

See CWD-AND-IMPORT-STATIC-ANALYSIS.md. Captured actual argv is now available,
but effective child cwd/resolved entry and primary stderr remain absent.
Current official project-config guidance uses the containing .codex folder
for general relative paths; MCP cwd has a legacy string field whose exact
installed-runtime base is not established by that guidance or bounded app-JS
inspection. Do not assume the generic rule proves the failed MCP child's cwd.
The generator/validators require the literal cwd="."; the availability probe
instead supplies explicit projectRoot cwd and resolved entry, bypassing Codex
path normalization. This is a real acceptance-coverage gap, not a root-cause
verdict. Six installed entry/closure/manifest files match delivered bytes and
their relative import targets/current hash references exist and agree. No
runtime module execution, configuration edit or new operational attempt occurred.
