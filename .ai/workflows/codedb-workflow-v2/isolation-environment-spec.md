# Isolation Environment Specification

Status: active companion specification for `codedb-workflow-v2`.

This specification defines the responsibility and evidence boundary for an
isolated development or validation environment. It is normative for task cards,
Coder results, Verifier reviews, and route reassessment. It does not replace a
task's explicit scope, authority, or acceptance gate.

## Purpose And Non-Goals

Isolation exists to make destructive or externally stateful work safe,
repeatable, attributable, and recoverable. It protects real Unity projects,
machine configuration, external processes, and historical evidence.

Isolation is not a second product implementation and is not required to emulate
an entire developer machine. A task must declare the smallest environment
closure that can answer its acceptance question. Adding a hidden dependency,
compatibility branch, machine installation, network download, or global fallback
to make a scenario pass is scope expansion.

## Environment Closure

Before an isolated scenario runs, its manifest must bind every input that can
change the result:

- the repository-local checkout, fixture root, runtime root, receipt root, and
  temporary root;
- all environment variables that redirect user, cache, temporary, or provider
  state;
- Provider, model, runtime, native helper, Node, PowerShell, and other host
  inputs, with source, destination, version, and hash;
- the network policy and any permitted machine-level dependency;
- the allowed child-process roles and their project, instance, generation, and
  owner identity fields;
- the production entry point, configuration source, and authoritative readers
  used by the scenario.

Every effective path must be resolved before a writer starts. It must remain
inside its declared root on a directory-separator boundary, with junction,
symlink, parent, and sibling escapes rejected. System temporary directories and
machine-global state are never implicit fallbacks.

If a required input is absent from the manifest, the scenario is
`ENVIRONMENT_INCOMPLETE`; it is not a product failure and must not be repaired
by inventing a replacement input.

## Two Kinds Of Correctness

An isolated result has two independent dimensions:

1. **Internal correctness**: the harness enforces its roots, identities,
   ownership, locks, state transitions, and evidence writes, and the observed
   result came from the original production entry point.
2. **External validity**: the isolated inputs and side effects are behaviorally
   equivalent to the real environment for the declared acceptance contract.

Internal correctness does not imply external validity. A fixture can have
perfect path containment while missing a Provider model, runtime asset,
permission, or startup behavior required by production. Conversely, a failed
fixture run does not prove a product defect when the environment closure is
incomplete.

## Evidence Levels

Every result must name its level:

| Level | What it proves | What it cannot prove |
| --- | --- | --- |
| `HARNESS` | Root, identity, serialization, and evidence mechanics | Production runtime behavior |
| `CONTRACT_ISOLATED` | The declared production contract under a complete child-local closure | Real machine/provider availability |
| `PRODUCTION_EQUIVALENT` | The same entry point and required external dependencies under a reviewed equivalent profile | Human Unity or release acceptance |
| `REAL_ENVIRONMENT` | The user-facing project and machine path requested by the task | Unrequested scenarios or broader release scope |

Passing a lower level never upgrades a result to a higher level. A required
level that cannot run is recorded as `BLOCKED` or `DEFERRED`, with the exact
missing prerequisite.

## Bounded Responsibility And Convergence

An isolation environment is converged when its declared closure is stable, no
new hidden prerequisite is discovered, one bounded run produces attributable
results, and the same result can be reproduced from the manifest without a
fallback.

The following rules prevent infinite environment repair:

- Do not absorb a newly discovered dependency silently into the current task.
- Allow only the mechanical corrections and bounded semantic attempts already
  authorized by the workflow and task card.
- After the workflow's structural escalation threshold, or when a new external
  dependency changes the environment class, freeze the evidence and enter route
  reassessment.
- Do not retry an unchanged environment. A new attempt requires a concrete,
  recorded prerequisite change or a new user-authorized evidence envelope.
- Do not modify product code solely to satisfy an incomplete fixture. If the
  production-equivalent closure cannot be assembled, create a separate
  environment-prerequisite task.

## Responsibility Split

| Owner | Responsible for | Must not absorb |
| --- | --- | --- |
| Isolation harness | Roots, redirects, manifests, hashes, process attribution, and evidence capture | A second product path, hidden fallback, or whole-machine emulation |
| Product code | The declared state machine, ownership rules, transactions, and readers | Fixture-specific bypasses or relaxed guards |
| External dependency | Its executable, protocol, model/runtime assets, and startup contract | Unreviewed machine installation or silent downloads by the task |
| Acceptance owner | Real Unity/project behavior and release evidence | Treating isolated PASS as real-environment PASS |

## Stop And Escalate Conditions

Stop the affected scenario and preserve its evidence when any of these occur:

- a path or process cannot be attributed to the declared task root;
- PID, executable, invocation, start identity, or owner identity is missing or
  conflicting;
- a required Provider/model/runtime asset is absent or its provenance is
  unknown;
- cleanup or termination would require a bare PID, name, tree, or directory;
- the proposed next step adds a compatibility branch, external install,
  network acquisition, historical search, or a new authority;
- the result would otherwise be reported as product failure despite an
  incomplete environment closure.

The terminal classification must distinguish `PRODUCT_FAILURE`,
`ENVIRONMENT_INCOMPLETE`, `UNKNOWN`, `BLOCKED`, and `DEFERRED`. Preserved
failure fixtures and receipts remain protected inputs for later reassessment.

## Isolation Route Pause And Reassessment

When the bounded execution allowance is exhausted, or when the same
acceptance path fails again without a concrete prerequisite change, pause the
affected isolation route. Freeze its manifests, logs, receipts, and current
classification before taking another action.

If the next proposal would add an external dependency, change the environment
class, broaden the product responsibility, or introduce historical fallback,
do not continue repairing the fixture under the current task. The parent route
must be reassessed by the user or Planner with one explicit disposition:
`CONTINUE_PATCH`, `REFACTOR`, `REDESIGN`, `DEFER`, or `STOP`.

This pause applies only to the affected isolation route. It does not block an
independent formal product task whose own scope and evidence closure are
ready. An `ENVIRONMENT_INCOMPLETE` or `BLOCKED` isolation result remains
separate from a product defect until a complete, attributable environment
closure proves otherwise.

## Acceptance Rule

Formal acceptance requires both the evidence level named by the task and the
separate human or release gate named by the task. Isolated evidence may support
source or contract admission, but it does not authorize commit, package export,
reference switching, Unity acceptance, or release promotion.
