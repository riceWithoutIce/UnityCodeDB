# Prospective child execution closure: bounded task proposal

Date: 2026-10-26. Status: `FOCUSED_SOURCE_PASS / CONSUMER_NOT_RUN`.
User approved continuation after the read-only causal analysis and scope
alignment. This slice implements prospective producer/consumer closure and
the bounded evidence below; it does not authorize consumer delivery.

## Objective

New supported operations must not become permanently ambiguous solely because
their owned child exits before OS identity capture. Preserve durable pre-spawn
admission and refusal of genuinely unresolved execution. Preserve command failure
as failure. Process termination, successful product postconditions and admission
of the next mutation are distinct conclusions.

This is prospective closure, not retrospective reconstruction of the four
CodedbTest_2 records. The completed null-parameter diagnostic guard remains
uncommitted in `.worktrees/cdb-v03-install-quarantine-admission`.

## Evidence semantics to freeze

| Case | Permitted conclusion | Disallowed inference |
| --- | --- | --- |
| Original caller proves it never reached spawn | Positively unstarted, existing NO_CHILD boundary if applicable | Null child or a failed result alone proves no execution |
| Original Supervisor observes its exact admitted ChildProcess close | Owned direct child has terminated; preserve original result and observation completeness | Command succeeded, no descendant exists, or cleanup is authorized |
| Supervisor interrupted before durable termination evidence | Execution remains unknown; refuse replay/admission where required | Parent PID absent, current Ready, later Uninstall or elapsed time closes old execution |
| OS identity query unavailable, no attributable close | Identity/termination unresolved | Clear marker or downgrade to NO_CHILD |

Do not turn CHILD_ADMITTED into a synonym for a captured identity. It remains
the pre-spawn admission marker. Do not populate the existing OS identity object
with guessed start times, argv, executable or hashes.

## Recommended mechanism and alternatives

Use the original owning ChildProcess as the source of prospective termination
observation, durably bound to the existing operation rather than a separate
global journal. Bind the exact admitted invocation/child attempt and owner,
with observation and terminal-result completeness. Identity of the admitted
invocation must be distinguished from an independently observed OS identity.
Decide the minimal compatible record representation before code changes.

Close and error listeners must be registered before evidence callbacks can
delay progress. Only the owning execution path can certify an observation;
generic finish(error), recovery, a missing process or a copied terminal label
cannot manufacture it. Consecutive child attempts must not overwrite an
unresolved predecessor; the current admission check remains.

Simply increasing polling, reducing the delay or moving the same OS query
earlier cannot guarantee capture of an arbitrarily short child. A gated launch
wrapper could ensure capture before work but widens launch/protocol scope and
is not the first choice. Allowing child=null based on result.exit_code, failed
state or output flags is rejected: none independently proves owned termination.

No guarantee about descendant processes is added. Existing coordinator,
Supervisor, retained-holder and competing-project execution checks continue.

## Consumer closure before implementation

| Consumer | Required consideration |
| --- | --- |
| Supervisor producer, finish, recovery and second-child admission | Persist attributable observation; retain conservative interruption semantics |
| Install history classification and referenced-terminal validation | Recognize only valid new proof; legacy null child stays blocked |
| Materializer terminal reader / Remove | Same proof semantics with independent instance, contract, owner and cleanup gates |
| History retention | No eager deletion or new failed-history pruning; no null dereference if new proof is accepted |
| C# AICodedbSupervisorTerminalEvidence | Exact-action Uninstall reader currently requires captured child argv; do not claim end-to-end Uninstall closure without handling this direct reader |
| Supervisor public projection / Bridge | Preserve existing response meanings; no independent authority in UI fields |

Primary candidate sources, subject to the minimal record representation:

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Editor/AICodedbSupervisorTerminalEvidence.cs`
- Direct existing focused tests and the host-action contract amendment.

Do not change Manager rendering, heartbeat, coordinator lifecycle, immutable
payload generations, registration paths or project settings. If the selected
representation requires a broader caller or record migration, return that
specific dependency for alignment before expanding the slice.

## Bounded evidence plan

L0: parse changed scripts and use original producer/reader functions with
controlled event/process observations. Cover short exit before capture,
pre-spawn rejection, identity-query failure, missing close, interruption before
terminal persistence, conflicting owner/operation/invocation, incomplete output,
legacy null child and multiple child attempts. Prove command failure stays
failure and unknown execution stays blocked. Bind producer output to reader input.

Affected L1: original runChild with a finite task-owned Node child, isolated
repository-local roots, no consumer/Unity/Provider/MCP. Verify real close before
delayed capture produces acceptable terminal evidence. Any deliberate crash
scenario requires an explicit owned-child lifecycle budget and cleanup plan.
Record native-child evidence separately from mocked OS/identity cases.

If C# terminal acceptance semantics change, select its exact existing focused
tests. Unity Test Runner remains a separately authorized human gate. A static
PowerShell/Node pass cannot close the C# or real consumer acceptance class.

Budget: one initial focused L0 and affected-L1 scenario, at most two same-cause
corrected semantic attempts inside the declared envelope. Preserve failures;
do not rerun unchanged passing batches or launch full regression automatically.
Actual per-run timeout and owned-process cleanup must be fixed before native
child execution; the implementation freeze below fixes that budget.

Implementation freeze: optional `child_execution` on the existing operation,
schema 1, contains a unique attempt id, operation/owner binding, resolved
executable and normalized argv/hash before spawn. Only the original
ChildProcess close callback adds pid, exit code or signal, and UTC observation.
The captured OS identity remains separate in `child`. The actual spawn uses
the admitted resolved executable. Publication failure remains a failed result
and cannot authorize another child from an in-memory close observation.

Native affected-L1 budget: one finite task-owned Node child per case, no child
descendants, each child timeout 5 seconds, harness total deadline 45 seconds.
The original runner owns child timeout/kill and close; the harness only knows
its own child handles. No crash or orphan experiment. Controlled native exit
codes 0 and 7 cover normal and failed short commands. No Unity/Provider/MCP.
All output remains under the task's repository-local artifact root. C# evidence
uses the production exact terminal reader with offline environment stubs, not
Unity execution; Unity compilation/Test Runner is a separate deferred gate.

## Done and remaining gates

Done for source: minimal agreed contract, producer/consumer closure, declared
focused evidence and stable attributable result. No broad refactor.

Not authorized by this proposal: commit/export/delivery, consumer mutation,
Install retry, history deletion/backfill, creating/opening Unity projects,
external process control, board sync or release. CodedbTest_2 remains the retained
blocked historical sample. After prospective closure, choose a clean project
for normal lifecycle acceptance separately; its PASS cannot close old recovery.

Implementation and bounded verification completed. See CHILD-CLOSURE-RESULT.md
for the hashed dirty snapshot, canonical evidence, retained correction and the
separate unrun Unity/consumer/release gates.
