# S32 approved execution-disposition refactor

Status: SOURCE_ACCEPTED / PASS_WITH_LIMITS / 2026-10-18.
User `批准`, 2026-10-18, approves this existing-operation
producer/consumer contract, focused isolation and Coder -> read-only Verifier.
Task-specific depth-one routing/inherited settings continue; no recursive agents.
This is the bounded REFACTOR decision for ROUTE-REASSESSMENT.md.

## Contract

Frozen field: optional `execution_disposition` in existing durable operation and
its public projection, one of `UNKNOWN`, `NO_CHILD`, `CHILD_ADMITTED`.
Missing legacy field is UNKNOWN, never inferred as NO_CHILD. New operation begins
UNKNOWN; only an original proven no-child branch may publish NO_CHILD. Child
admission durably publishes CHILD_ADMITTED before spawn. Later attach/error/
finish/recovery must not downgrade prior child admission to NO_CHILD. Existing
child identity, result completeness and ownership remain separate requirements.
If minimal additional bookkeeping is necessary to retain prior child admissions,
Coder presents exact fields/consumer map to parent before editing; no new result
store/executor or independent ownership subsystem is permitted.

Select current/referenced/unclosed authority before detailed child validation.
Bounded project-local discovery must still find pending/conflicting execution
hidden by overwritten canonical. Proved NO_CHILD does not need child-exit proof,
but cannot bypass terminal, identity, owner/admission or instance validation.
History presence alone is not active authority; declare inert-classification
evidence, never infer it from absent owner files or later uninstall alone.
Do not accept all child:null, migrate/backfill records or relax legacy unknowns.

## Write scope

Only directly required hunks under com.rice.ai-codedb:

- Tools~/codedb-project-supervisor.mjs: disposition initialization/no-child branch,
  pre-spawn admission, durable/public projection, persisted operation reader.
  No startup/IPC/process-control redesign.
- Tools~/codedb-instance-engine.ps1: S32 Install selector and terminal checks;
  preserve incoming Uninstall idempotence.
- Tools~/materialize-codedb-host-payload.ps1: necessary strict operation-field
  acceptance/shared terminal disposition only; no broader Remove recovery or writes.
- Editor/AICodedbSupervisorBridge.cs (contains AICodedbSupervisorProtocol) and
  AICodedbSupervisorTerminalEvidence.cs: new-field reader/projection only if
  required; preserve old actions/release behavior.
- Tests~/test-codedb-project-supervisor.mjs: focused producer-only entry/tests;
  no full suite or live Supervisor/backend.
- Tests/Editor/AICodedbS32InstallTests.cs and directly necessary S31-D terminal
  tests: field consumer nearest regression, if C# changes.
- Documentation~/v0.3.0-p0-host-action-execution.md: S32 append amendment only.
- Coder RESULT append and task-local driver/fixture source; Verifier owns only
  new VERIFICATION-DISPOSITION.md. Other task decisions stay parent-owned.

Read closure DIRECT_REFERENCES_ONLY: above and existing direct operation loaders,
ownership/lease/identity helpers and producer-only fixture dependencies.
RESULT must name every changed serialized field and actual consumer.

## Evidence and budgets

Required original boundary: already-ready no-spawn production branch -> original
terminal/durable serializer -> actual PowerShell Install reader; pre-spawn
CHILD_ADMITTED with failed identity capture stays unknown/refused; identified
child with complete result retains identity checks; old missing field is not
promoted; terminal completeness unchanged; current/inert/hidden-unclosed selection;
multiple-child admission cannot erase earlier unknown execution.

Use existing producer VM/fixture patterns and production functions, with explicit
mocked process/coordinator-status inputs and honest HARNESS/CONTRACT_ISOLATED
classification. No live Supervisor/Coordinator/Provider or Unity. If C# changes,
compile affected original source and only direct-field regression; otherwise
reuse admitted assemblies, do not repeat unchanged compilation/full suites.
No whole-machine emulation, new downloads/models/tools, or tests solely for
unrelated hardening. Mechanical fixture/producer closure must not become objective.

Initial plus 2 mechanical and 2 causally justified semantic corrections per named
scenario; Coder 30 minutes, Verifier 15 minutes. No unchanged retries. Stop for
new independent cause, missing external closure, wider authority/infrastructure,
out-of-scope consumer or exhausted budget; preserve snapshot and return boundary.

## Protected state and handoff

Incoming snapshot: RESULT's 11-file table with repair overrides, plus newly
allowlisted producer/reader hashes in DISPOSITION-BASELINE-SHA256.md. Ten parent
protected inputs remain protected. Outputs use fresh repository-local children
of .artifacts/tests/s32-install; preserve old attempts and immutable reviews.
Durable docs symbolic/repository-relative; no machine-specific literals.

No S30 runtime/receipt/index/history/config mutation, delivered extraction edits,
cleanup, process stop, Unity/MCP/BatchMode, network, generation identity change,
commit/export/reference switch/push/publication. Old S30 null-child records and
pending action are not proven/released by future producer fields. Full successful
initialization, Provider, Ready, Unity and real reinstall remain deferred.

One sole Coder -> stable RESULT with hashes -> parent admission -> one targeted
read-only Verifier -> User disposition. Parent remains active, answers returned
questions and waits for both terminal completions. No repeated approval inside
this unchanged approved envelope. No source acceptance or delivery implied.
