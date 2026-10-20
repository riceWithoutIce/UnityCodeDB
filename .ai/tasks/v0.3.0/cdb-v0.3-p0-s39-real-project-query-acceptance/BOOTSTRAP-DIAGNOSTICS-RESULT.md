# S39 bootstrap diagnostics — source-focused result

Date: 2026-10-20. Status: SOURCE_FOCUSED_PASS / NOT_DELIVERED /
REAL_CLIENT_QUERY_BLOCKED. Base HEAD: c07bb5903b5b3fcda7d97f5238c2915e3c566cf8.

## Authorized outcome and implementation

The user approved bounded startup diagnostics after static analysis. The parent
implemented and verified the agreed source slice without delegation. This
does not establish the cause of Attempt 02 or repair real-host initialization.

Changed Package sources:

- `Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs`: retains startup
  stages in memory; on wrapper exception or worker exit writes at most one
  create-only JSON record below the validated project's
  `AIWork/.runtime/codedb/diagnostics/bootstrap/`. Records worker exit facts,
  including zero, and the parent's requested exit code separately. No protocol
  observation or handshake-success inference. No startup file writes.
- `Tools~/probe-codedb-mcp-availability.mjs`: retains bounded stderr and actual
  child exit facts in existing schema-2 evidence, including on initialize
  failure. ChildProcess close/drain precedes failure reporting. Both process
  kill and Worker terminate requests are explicitly attributed to the probe.
  The original availability/status/query assertions remain unchanged.
- `Tests~/test-codedb-bootstrap-diagnostics.mjs`: production-entry fixtures with
  synthetic workers and run-owned storage only.
- `Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md`: narrow
  termination-diagnostics section; prior unrelated edits preserved.

TASK.md, RESULT.md and this file provide task-local scope and evidence. No
generated manifest, immutable generation, registration, lifecycle/Provider or
external consumer source was changed.

The record's selected identity is a validated disk selection, not a response
identity. Error text is bounded to 2048 characters per field with credential
assignment/Bearer redaction; raw stack, argv and full environment are not
serialized. LOCALAPPDATA has only presence and absolute-shape booleans. Source
paths come from the Package; runtime paths come from the validated project.
Ancestor junctions/symlinks are refused; logging failures are swallowed without
changing original stderr/exit semantics. There is no historical-log deletion.

## Focused verification

Final run:
`.artifacts/tests/s39-bootstrap-diagnostics/r-b90d9fa3-6c2d-4722-8c3c-21a635f884d2/result.json`.

Command: `node com.rice.ai-codedb/Tests~/test-codedb-bootstrap-diagnostics.mjs`.

All 15 scenarios PASS:

1. Exact stdout forwarding, no startup writes, neutral zero exit and bounded
   environment facts without unrelated environment values.
2. Worker error plus exit emits one record and preserves stderr/exit.
3. Invalid selection retains only completed validation; selected identity null.
4. Unwritable log storage preserves original stderr and nonzero exit.
5. Ancestor junction refuses writes through to another fixture-owned directory.
6. Unvalidated project root has no diagnostic writes.
7. Static-import failure remains stderr-only, explicitly outside self-log coverage.
8. Concurrent exits create distinct records without overwrite.
9. Production stable-entry probe retains natural preinitialize failure stderr/exit.
10. Production probe with a synthetic direct entry bounds stderr at 64 Ki
    characters and records truncation.
11. Synthetic direct entry exiting zero before initialize remains UNAVAILABLE.
12. Probe-requested process termination is attributed and stderr drained.
13. Candidate Worker probe preserves the original error.
14. Candidate Worker termination is also attributed and stderr retained.
15. Real stable wrapper/probe still initializes/lists/status/queries using a
    synthetic worker. This is not a real Provider or Codex-host query.

Node syntax checks for both production files and the harness PASS. The focused
`test-codedb-package-boundary.ps1 -PathProvenanceOnly` PASS, including existing
instance-helper projection/binding checks. Scoped whitespace check PASS.

Test ownership: one unique run below repository `.artifacts/tests/`, bounded
containment and reparse checks plus create/read/delete preflight. All fixture
and mock Package paths derive from that root. No system-temp fallback, global
environment edits or recursive cleanup. Only exact fixture-owned child
processes/Workers are terminated by their normal probe error paths. Evidence
is retained; no real Provider, Unity, Supervisor or Codex connection is started.

## Corrected fixture expectation and evidence limits

The initial run `r-b7894d72-fc84-46b2-8c87-6d0b0e917911` stopped after eight
passes: its next assertion incorrectly expected a naturally observed wrapper
exit code 7 after the worker exited. Existing stdin piping can keep the parent
alive until the probe times out and terminates it. The fixture expectation was
corrected; the stable wrapper's connection behavior was preserved. Worker exit,
parent requested exit code, actual child-process exit and probe-requested
termination are now distinct evidence. Intermediate passing runs are retained;
the final run above binds the final sources after these attribution refinements.

No internal diagnostic can cover failure before static imports execute. No log
is evidence of success, and an OS-terminated process may not self-log. Records
are not fsync/durable-publication authority and are not used operationally.
Normal termination performs one synchronous diagnostic write, which adds exit
I/O; no zero-overhead or unchanged-timing claim is made.

## Source snapshot and next boundary

SHA-256:

| Source | Hash |
| --- | --- |
| stable wrapper | a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e |
| availability probe | 21983ad0792eab4bb03cf5685e12758cbf719914795071a2f8cdf957ce8966a4 |
| focused harness | 0fae6d25fc7b8cc793fa38a1422e28f84345be9727f2d0c80e20bf434992e1ce |

The pre-existing dirty poc.42/poc.43 payload state and generated manifests were
preserved. The changed wrapper source has not been incorporated into a newly
generated/admitted payload closure; this is a source snapshot, not an installable
or releasable Package. Do not claim full Package closure from these fixtures.

CodedbTest_0 and the existing c07bb59 delivery were not modified or launched.
No commit, push, export, reference switch, Install/Reinstall, real-host retry,
trace recording or system-level process control occurred. Source disposition
comes next; a concrete authorized delivery must separately resolve closure and
bootstrap handoff before another human-owned client attempt. Existing capture
shim/passive-trace proposals remain deferred, not prerequisites for this work.

## Subsequent local preparation note — 2026-10-20

The snapshot above remains historical. The harness subsequently gained optional
`--repository-root` so the extracted candidate can use its enclosing checkout's
owned test storage. Current harness SHA-256:
`9c0f991640f683b30c9dc0e69940c37fffebeb5d4874cc5032aaca1354af7531`.
Production wrapper/probe hashes are unchanged. Candidate-own 15 scenarios and
canonical closure now pass in a repository-local review copy; no formal
delivery occurred. Same-generation direct bootstrap handoff is not admitted
by existing activation authority. See DIAGNOSTICS-DELIVERY-PREPARATION-RESULT.md
and DIAGNOSTICS-DELIVERY-PLAN.md for evidence and the proposed fresh-project route.
