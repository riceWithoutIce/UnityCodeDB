# Development Workflow v2.7 — Safe Execution And Route Reassessment

This file is a normative module of `codedb-workflow-v2` revision `2.7`.
The stable entry point remains [development-workflow.md](../development-workflow.md);
this module does not create a second workflow or authority.

## Closed Execution Envelope

One human authorization covers diagnosis, implementation, local repair,
mechanical correction, focused evidence, and result consolidation while all of
them remain inside the frozen objective, change allowlist, read closure,
side-effect authority, evidence scenarios, and budgets. A Coder must not return
an acknowledgement or a plan in place of executing that envelope.

| Event | Required action | Planner/User handoff |
| --- | --- | --- |
| Parser, escaping, quoting, path, marker, command-loading, or evidence-expression error before the intended assertion starts | Correct mechanically and continue within the mechanical-correction budget. | No |
| Fixture or assertion drift caused by the accepted design and inside the test allowlist | Correct the directly coupled assertion family, then continue the declared evidence scenario. | No |
| Product or contract defect inside the accepted outcome and change allowlist | Diagnose, repair, and run only its adjacent declared evidence within the semantic-repair budget. | No |
| Stable declared evidence passes | Write one consolidated terminal `RESULT.md`; Planner admits the snapshot and continues an already authorized review. | Planner handoff; no repeated stage approval |
| Objective, architecture, change allowlist, evidence class, side-effect authority, or protected state must expand | Preserve the stable snapshot and request a route decision before crossing the boundary. | Yes |
| A human-owned environment or external prerequisite is absent, evidence is unavailable/corrupt, or an authorized external attempt is exhausted | Stop the affected path and report the exact prerequisite or evidence gap. | Yes |
| Structural escalation threshold or active-time budget is reached | Start no new investigation, repair, or test; consolidate the current causal evidence and return `ROUTE_REASSESSMENT_REQUIRED` or the applicable terminal status. | Yes |

Continuous execution is not broad autonomy. The Coder may inspect only the
allowlist and its declared direct-reference closure, may edit only the change
allowlist, and may run only the named evidence scenarios. A `deep` profile adds
reasoning and active-time budget; it never widens authority or coverage.

## Read-Only Preflight

The beginning of a task is read-only and bounded:

- By default, run one `git status --short --branch`. Read `HEAD` only when the
  task's review mode or snapshot binding requires it.
- Do not run a full `git diff`, full history scan, or repository-wide file dump
  as routine admission work. If scope must be checked, use one targeted command
  restricted to the task's allowed files.
- Read `TASK.md` once, then search only the named files and their direct
  references before expanding the surface.
- Prefer line-ranged reads and symbol searches over dumping complete large files
  or generated output.
- Resolve scope, ownership, and acceptance language before editing.

Existing dirty worktree changes are preserved. They are not reset, checked out,
cleaned, or rewritten unless the user explicitly authorizes that exact action.

## Repository-Local Development Artifacts And Backups

Persistent repository-owned development output belongs to the repository/workspace
root of the authorized task. Derive that root from the current task context; do not
hard-code a developer drive or select a sibling directory as an implicit output
root. This rule does not relocate consumer Unity projects, app-managed Git
worktrees, project runtime state, or machine-level Node/Provider installations.
Task-owned isolation follows the same repository boundary: use the symbolic
layout `<repository-root>/.worktrees/<task-id>/` for an isolated checkout and
keep its durable task outputs under `<repository-root>/.artifacts/` and
`<repository-root>/.ai/tasks/`. An app-managed checkout outside that boundary
may be used only as an explicitly authorized transient execution source; it is
not the durable task root, and no handoff may depend on its location.
Test-owned ephemeral fixture roots follow the
[Development Test Workspace Contract](../test-workspace-contract.md): repository
tests use `.artifacts/tests/<run-id>/`; Unity tests use the actual test project's
`Library/cdt/<run-id>/` (current short-root policy in the workspace contract).
Their entry point owns root selection, isolation,
capability checks and bounded cleanup; helpers receive explicit owned paths.
System temp is not an implicit fallback. This does not move real runtime or
machine-level state or authorize cleanup of historical fixtures.

The distinction between isolated safety, environment closure, and production
representativeness is normative in the
[Isolation Environment Specification](../../../.ai/workflows/codedb-workflow-v2/isolation-environment-spec.md).

| Content | Default repository-relative destination | Git policy |
| --- | --- | --- |
| Exported ZIPs, extracted Packages, commit snapshots, and development evidence intermediates | `.artifacts/<task-or-candidate-id>/` | Ignore the generated copies. |
| Residual worktree copies and temporary recovery backups | `.backups/<backup-id>/` | Ignore the copies; review their recovery purpose before removal. |
| Source, canonical Package/payload identity contracts, export tools, and concise provenance/evidence records | Their existing source paths and `.ai` task records | Track the authoritative files, not duplicate output trees. |

An external output or backup destination is an exception, not a fallback. The
human must explicitly authorize its purpose and exact root, and the task record
must identify its owner and retention/recovery requirements. Protecting against
loss of the entire repository may justify an external backup, but does not
authorize an agent to invent an external location. One approved task envelope
covers its contained output; do not introduce per-file or per-command approval
steps for unchanged destinations.

Before a writer creates or migrates output, resolve the effective absolute
destination and verify it stays inside the applicable authorized root on a
directory-separator boundary. Reject traversal, parent/sibling destinations,
and symlink/junction escapes; an absolute path or an existing directory is not
authorization. New output must not overwrite a frozen candidate or historical
failure. Existing external artifacts remain preserved until an explicit
migration decision; this revision does not retroactively invalidate evidence,
reset budgets, or authorize retries.

### Git Tracking And Provenance

- Root ignore rules are `/.artifacts/` and `/.backups/`. Ignoring export/backup
  copies does not exclude canonical generated contracts inside the Package
  from source control, and does not untrack any already-tracked file.
- Record concise repository-relative locations, source commit or backup origin,
  artifact/archive hashes, purpose, known consumers, evidence status, and
  retention disposition in the existing `.ai` task/result records. Record
  authorized external-root exceptions without unnecessary machine details.
  Tracked workflow, task, and result records must use symbolic
  `<repository-root>` paths and must not contain developer drive letters,
  usernames, home directories, or other machine-specific absolute paths. Raw
  tool logs may retain paths emitted by the tool for forensic integrity, but
  summaries and durable records must redact them and reference only the
  repository-relative artifact location.
  Do not create a second identity authority or commit raw output/backup trees.
- A backup is not a second implementation source. Restoring useful changes is
  a separately authorized source edit at the normal tracked paths; never merge
  residual copies automatically or assume Git contains every untracked byte.

### Protected Retention And Migration

- Ignored does not mean disposable. Preserve active or frozen Package inputs,
  outputs referenced by known consumer manifests/lock files, and recovery data
  whose complete recoverability has not been proved. Unknown references are
  not evidence that an output is unused; review the declared consumers without
  expanding the task into a machine-wide reference scan.
- Historical output may be archived without rewriting its bytes. Preserve
  invalid release candidates and meaningful failure evidence under the Package
  Release Closure Gate. A passing successor does not by itself close an
  unresolved failure or make its necessary evidence disposable. For archive
  migration, verify the retained copy/archive against its recorded hashes and
  preserve the original-path mapping and recovery route before removing the source.
  Deliberate deletion of a classified intermediate needs no byte-for-byte
  replacement; record the result, lost recoverability and exact deleted path.
  For a retired Unity acceptance project, the evidence-only disposition in
  [Validation Project Evidence Retention And Deletion](#validation-project-evidence-retention-and-deletion)
  may replace a complete project copy after explicit approval of the exact
  evidence and deletion plan. It does not authorize deleting protected Package
  artifacts or unique reproduction inputs, or claim full project recoverability.
- Migration/cleanup requires explicit authorization for the exact source and
  destination/removal list and affected consumer references. Do not silently
  rewrite a Unity Package reference or lock file, start Unity, restore source,
  or clean another project. A directory move alone does not update `file:`
  dependencies. Coordinate permitted reference changes with the human-owned
  Unity lifecycle and verify the unchanged Package identity afterward.
- Do not use blanket `git clean -fdx`, recursively clear the workspace, or
  clear either storage root. Scope any approved cleanup to validated exact
  children, excluding protected inputs and the only recoverable copies.

`.backups/` is temporary recovery storage, not a default historical archive.
After the rollback window closes, review manifest/lock-file snapshots,
intermediate worktree copies and other temporary backups for deletion. A
different hash alone is not a retention reason. Keep a bounded exception only
when it is the sole copy of historical source, needed to reproduce an open
failure, or still needed for an active recovery route. Identify its owner,
reason and next review milestone; decide its final disposition separately.

### Artifact Lifecycle And Retention

Every repository-local artifact must have an owning task or candidate, a
declared purpose, an evidence level, and a retention disposition. The durable
task/result record remains the authority for source identity, Package identity,
test outcome and release status. An optional artifact manifest is only a
navigation and inventory aid; it must not become a second identity authority.

Use these lifecycle states:

| State | Meaning | Default action |
| --- | --- | --- |
| `ACTIVE` | Used by the current task, Package consumer or acceptance project | Retain and do not overwrite |
| `PROTECTED` | Evidence needed for an unresolved failure, blocker, crash, runtime, human or release conclusion; sole historical source or active recovery data | Retain until its need and replacement/disposition are reviewed |
| `FROZEN` | Task is complete but the artifact remains a historical reference | Retain one canonical copy |
| `REVIEW` | Candidate for deduplication, supersession, archive or deletion | Check purpose, references and identity before mutation |
| `ARCHIVED` | Removed from the active route but retained as evidence | Preserve bytes and recoverability limits |
| `DELETED` | Exact target removed after the deletion gate | Report target, reason, deletion receipt, retained evidence if any, and recovery limits |

At creation, record the task/candidate ID, artifact kind, source commit or
runtime identity, hash where applicable, known consumers, evidence level,
retention state and next review milestone. New artifact directories use a
stable task/candidate name and purpose; anonymous or reusable `latest` output
directories are not allowed for durable evidence.

The default artifact set for a completed task is one canonical exact Package
archive when Package evidence is required, one extracted Package only when a
consumer requires it, and the minimum evidence needed to explain the result.
Exact-byte duplicate ZIPs or extractions need only one canonical copy plus a
source-to-canonical mapping. A failed or blocked artifact is retained when its
bytes or reproduction inputs are needed to explain an unresolved result; a
later passing candidate alone does not settle that question.

For test runs, retain the final authoritative run and the bounded raw evidence
needed for unresolved failures. Once the task stage is closed and the final
result covers the relevant outcome, superseded attempts, build outputs,
temporary extractions and configuration backups become deletion candidates
after their consumer and rollback needs end. Different bytes or a historical
filename do not by themselves require preserving an intermediate. Keep the
result and disposition in the task record; intentional loss of intermediate
bytes is allowed. A task-level output budget or a repeated candidate set is a
review trigger, never automatic deletion authority.

Retention review is required when a task closes, a validation project leaves
the active route, a candidate is superseded, or a soft output budget is
reached. The review must classify each exact child as `RETAIN`, `PROTECTED`,
`ARCHIVE` or `DELETE_CANDIDATE`, list known consumers and preserve original
path-to-retained-path mappings for archived content. It must not expand into a
machine-wide search or make an unbounded historical scan.

Physical cleanup is a staged operation: (1) freeze the exact source and
destination/removal list; (2) verify containment, reparse safety, references,
current file count/hashes and live holders; (3) for archive migration, preserve
and verify the retained copy and original-path mapping; (4) move or delete only
the approved exact targets; and (5) recheck consumers and record the exact
removed paths, reason, retained evidence if any and recoverability limits in a
deletion receipt. A deliberate intermediate deletion does not require an
archive or replacement copy. Stop on the first mismatch. Never
move a complete Unity project while it is open, and never assume a relative
`file:` Package reference survives a project move without recomputing it.

## Bounded Inspection

The first pass over a large file, generated output, log, or session record is an
index pass: collect only metadata, sizes, timestamps, counts, and matching line
numbers needed to choose the next read. Then read the smallest relevant
excerpts.

- Do not load a complete session JSONL, log, generated artifact, or repository
  dump into the active context.
- A broad `rg` is allowed only with a path or symbol filter and the lower log
  or session output limit in the budget table below.
- When repeated extraction is justified, reuse an existing bounded helper or
  make one small reusable extractor. Do not create one-off full dumps merely to
  avoid selecting evidence.
- `git diff` is not a routine evidence source. When explicitly needed, restrict
  it to the named allowlist and capture only the relevant summary or check
  result once.

## Slice Sizing

The unit of slicing is one independently acceptable engineering outcome, not a
command, file count, language, test batch, elapsed work window, failure count,
or context compaction. A healthy task has:

- one observable product, contract, migration, or acceptance objective;
- one coherent causal chain from diagnosis through validation;
- declared authority, protected state, allowed files, and evidence classes;
- one stable result suitable for acceptance or targeted Verifier review.

Crossing C#, Node, and PowerShell or touching more than five files does not by
itself require a split when the changes implement one mechanically coupled
contract. File count, runtime boundaries, active time, output volume, and
context compaction are planning signals used to narrow commands and summarize
progress; they do not create task identity.

Split only when at least one of these is true:

- the independently acceptable objective changes;
- work enters a separately owned subsystem or produces a separately shippable
  deliverable;
- continuing requires a new high-risk side effect or authority outside the
  frozen envelope;
- an external condition prevents meaningful progress and the remaining work
  can no longer continue as the same owned outcome.

## Structural Escalation And Route Reassessment

Continuous repair is valid only while the evidence still describes a local
defect and the same user acceptance path is advancing. The task must enter
`ROUTE_REASSESSMENT_REQUIRED` no later than either of these limits:

- the same user acceptance path remains blocked after `2` local repair
  iterations;
- more than `2` causally independent product defects emerge inside the same
  execution envelope;
- `3` consecutive checkpoints improve diagnostics without advancing that
  acceptance path.

A local repair iteration is one causally distinct source or fixture correction
returned for the blocked path and followed by an acceptance re-evaluation. It
is not each edit, command, parser correction, quoting correction, or other
mechanical pre-side-effect correction. A diagnostic-only checkpoint is a
terminal handoff that adds cause or symptom detail but leaves the same
acceptance gate blocked. Counts persist across replacement sessions and are
recorded in `RESULT.md` and the task handoff. These numeric limits are the
latest mandatory escalation point, not a quota to consume before escalating.

Escalate immediately, regardless of count, when evidence shows any of these
structural signals:

- duplicate authorities for the same state, readiness, or admission decision;
- semantic conflict across components that independently classify the same
  product condition;
- a decision composed from caches or observations belonging to different
  revisions or snapshots;
- concrete causes repeatedly compressed into a generic error that prevents
  authoritative diagnosis or routing;
- progress requires another special-case branch, compatibility hole, or local
  exception instead of restoring one coherent contract.

When this gate triggers:

1. Stop further patches, repeated Unity or screenshot cycles, repeated tests,
   and Verifier routing for the affected path.
2. Preserve the current source, task records, and evidence as one frozen
   snapshot. Do not commit, revert, clean, or discard it merely because the
   gate triggered.
3. The Coder records the trigger, counters, structural signals, frozen identity,
   last acceptance state, and handoff to Planner. The Coder may identify the
   signals but may not expand scope or choose a new architecture.
4. Planner creates `ROUTE-REASSESSMENT.md`, consolidates the causal chain and
   affected authorities, and presents one route recommendation to the user.
5. The user chooses exactly one disposition: `CONTINUE_PATCH`, `REFACTOR`,
   `REDESIGN`, `DEFER`, or `STOP`.

`CONTINUE_PATCH` requires a recorded bounded hypothesis, allowed surface, and
new evidence envelope before work resumes. `REFACTOR` or `REDESIGN` becomes one
coherent vertical task spanning the affected contract from authority through
user-visible acceptance; do not decompose it into one microtask per symptom,
file, or test failure. `DEFER` and `STOP` preserve the frozen evidence and close
the current route accordingly. No role infers a disposition from silence.

`ROUTE-REASSESSMENT.md` has this minimum shape:

```text
# Route Reassessment: <task-id>

## Trigger
- Blocked acceptance path:
- Repair iterations: <current>/2
- Consecutive diagnostic-only checkpoints: <current>/3
- Immediate structural signals:

## Frozen State
- Source/task identity:
- Last acceptance state:
- Protected state and active external ownership:

## Causal Summary
- Established facts:
- Conflicting or duplicated authorities:
- Uncertainty and deferred evidence:

## Route Recommendation
- Recommended disposition:
- Coherent target boundary:
- Rejected patch-only alternatives:

## Human Decision
- Disposition: PENDING | CONTINUE_PATCH | REFACTOR | REDESIGN | DEFER | STOP
- Authorized envelope or next task:

## Handoff
- Current task:
- Current status: ROUTE_REASSESSMENT_REQUIRED
- Next notification: Planner/User
- Next action:
- Human decision or authorization required: yes
```

Route reassessment is a planning and decision artifact, not a checkpoint.
`CHECKPOINT` remains reserved for a real external interruption, unavailable
prerequisite, session handoff, or evidence contradiction that needs a durable
resume point.

### Acceptance Project Baseline And Historical Recovery

Before each acceptance round, record the attributable source/Package identity,
project references and relevant installed state; the one route to validate;
the allowed operations and protected state; and the completion and stop
conditions. Use existing task records rather than adding an approval round
inside an already authorized envelope.

An acceptance project is unsuitable as the primary normal-route baseline when
any of these conditions holds:

- its current source, Package reference or relevant installed state cannot be
  attributed sufficiently to interpret the declared acceptance result;
- retained candidates, failed operations or historical process evidence block
  the intended route before the current behavior can be exercised;
- acceptance has expanded into unrelated historical recovery or compatibility
  work instead of advancing the frozen objective;
- continuation depends on undocumented manual interventions and cannot be
  reproduced from the recorded baseline and steps.

Project age, file count and failure count alone do not establish these
conditions. First distinguish a product defect from historical environment
interference. A defect produced by supported normal operations remains a
product issue; creating a clean project must not erase it or substitute for
acceptance of the affected route.

When these conditions arise, stop automatic scope expansion and enter the
existing route-reassessment process. Historical routes do not receive unlimited
fallbacks. Present these two baseline options within that process:

| Option | Appropriate use | Evidence boundary |
| --- | --- | --- |
| New acceptance project; archive the old project from the active route | Historical state is unclear or recovery no longer serves the objective. | Validate the declared current-version route from a recorded clean baseline. Preserve old failures and unfinished gates. |
| Remove the relevant integration and reset the existing project | The project remains useful and the affected configuration, runtime state and ownership can be bounded. | Distinguish supported product removal from developer maintenance reset before execution. |

The user selects the route. Record that choice within the existing disposition
and execution envelope; it does not implicitly authorize project creation,
Unity execution, Install/Remove, process control, deletion or reference changes.
Apply the existing risk-boundary authorization rules, continuing without
repeated approval when those exact actions are already authorized. The standard
development EditMode project remains the default; this choice does not permit
substituting a new project during normal implementation.

Product-provided Remove is lifecycle acceptance only when its declared outcome
is actually verified. A developer maintenance reset is environment preparation,
not evidence that product Remove succeeded. Freeze the exact affected paths,
configuration and runtime ownership, preservation/recovery plan and resulting
baseline before an authorized reset. Do not clear unknown or shared state.

Freeze one bounded recovery or reset plan, including its permitted attempts.
If it requires an unrelated historical repair or other work outside that
envelope, stop the dependent route and return the baseline choice to the user.
Do not append more recovery branches, start successive reset plans or switch
projects automatically. Apply the earlier structural-escalation limits as well;
this rule does not create an extra repair quota.

Archival removes a project from the active acceptance route; it preserves its
source/Package identities, results, failure evidence and unresolved items.
Record partial completion explicitly rather than declaring the original route
passed. Logical archival does not move or delete the project or its runtime
data; physical archival and cleanup follow Protected Retention And Migration.
Active processes, shared resources and unknown identities retain their safety
boundaries. A new project may proceed with separately authorized, unaffected
validation, but its clean baseline does not prove the old state has exited.

Keep historical recovery separate from normal-route acceptance unless the
agreed product support scope explicitly requires it. Reopening an archived
route requires a separately agreed bounded objective and applicable authority.

### Validation Project Evidence Retention And Deletion

User-approved amendment, 2026-10-19. Retain problems and necessary evidence for
the long term; retain complete historical Unity projects only temporarily.
Moving every old project into a backup directory is not a retention strategy.

Logical archival records the passed, failed, deferred and unfinished routes and
removes the project from current acceptance selection. It does not require
immediate physical movement or deletion. Deleting an old project does not close
its issues, certify its lifecycle, or replace acceptance of a normal-path defect.

The default working set is one fixed development EditMode project, one active
current-version lifecycle acceptance project and at most one complete historical
acceptance project. A task number alone does not require a new project. The
existing accumulated projects are a cleanup backlog, not implicitly deletable
because this default is exceeded. Additional complete retention or independent
parallel acceptance requires a named purpose, owner and next review milestone.

Use these deletion/review points:

| Event | Disposition |
| --- | --- |
| Project leaves the active route | Record its results, issues and identity; stop appending unrelated acceptance work. |
| Necessary evidence has been independently preserved and checked | If the complete project has no unique reproduction value or other declared dependency, propose its exact deletion. It need not wait for every historical issue to be fixed. |
| Successor completes the corresponding acceptance route | Default deletion-review milestone for the previous complete project and temporary migration copies. An exception needs a concrete remaining purpose and next review milestone. |

Do not make deletion depend indefinitely on a successor passing. When a new
failure replaces the retained historical sample, assess both samples' distinct
reproduction value and keep only the complete project that still needs it,
unless a documented retention exception is approved. No automatic deletion is
implied by a time, count or successful successor.

Before proposing deletion, retain a bounded evidence set that another developer
can understand without opening the old Unity project:

- the route and trigger steps, expected and actual outcome, and exact failure;
- attributable source/Package identity, project references and relevant version
  metadata, linked to existing authoritative delivery/task records;
- relevant logs/screenshots and original runtime/configuration/operation records
  needed to explain the failure, including their identities and hashes;
- issue disposition (fix, defer, stop or accepted limitation), owner or owning
  task, unfinished gates, and any remaining reproduction dependency;
- an original-to-evidence mapping, checked file inventory/hashes and readable
  task/index links, with the full-project recovery limit stated explicitly.

Preserve original evidence bytes; do not retrospectively rewrite execution
records, remove uncertain history to make admission pass, or relabel failures.
Summary documents use repository-relative/symbolic paths. Raw evidence remains
in repository-local protected artifact storage; ignoring it in Git is not
permission to remove it. Do not duplicate the entire runtime or Package by
default when a bounded relevant evidence set and existing protected artifact
already establish the required facts.

Library, Temp, Obj and other rebuildable caches normally do not need long-term
retention. Determine whether any contains unique crash/reproduction evidence
before omission. If the full project is the only practical reproduction input
for an important unresolved issue, retain it temporarily with the specific
reason, owner and next review milestone. "Might be useful later" is insufficient.
Do not create a new harness or compatibility task solely to satisfy cleanup.

Complete project copies under `.backups/` are temporary migration/recovery
copies, each with a purpose and review milestone. Include them in the same
retention decision; do not delete the original while keeping unlimited complete
duplicates. Retained evidence and protected released/failed Package artifacts
have their own declared consumers and are not swept up with project caches.

Policy approval is not deletion authority. The execution plan must name exact
project/backup roots and evidence to preserve, check ownership, relevant live
holders, references and contained/reparse-safe targets, and verify preserved
evidence before authorized deletion. Full restoration is not promised for an
evidence-only archive. Do not stop unknown processes or remove shared state.
Return removed paths, retained evidence and recoverability limits after cleanup.
One explicit approval may cover the full bounded evidence/verify/delete group;
do not ask again between its already authorized stages. No scheduled purge,
age-based deletion or blanket cleanup is introduced.

## Command, Output, And Retry Budgets

The following guards limit resource use and unsafe repetition without defining
task identity. This document does not install an automatic wrapper or hook.

| Budget | Default guard | Required action |
| --- | --- | --- |
| Active role time | Coder `standard`: `30 minutes`; Coder `deep`: `60 minutes`; Verifier `standard`: `15 minutes`; Verifier `deep`: `30 minutes` | Finish only the current bounded, non-side-effecting operation. Start no new investigation, repair, or test; write the consolidated result or review and hand off. Reaching the limit does not create a new task. |
| A normal command's captured output (stdout and stderr) | `32 KiB` or `200` lines, whichever is reached first | Mark the output `TRUNCATED`, retain a concise summary, and narrow the next command. |
| A log, session record, or `rg` result | `16 KiB` or `50` matches, whichever is reached first | Keep only the relevant excerpt or an aggregate summary. Every `rg` must name a path, symbol, or file filter; an unbounded repository search is not permitted by default. |
| Cumulative captured output in one working window | `128 KiB` | Stop expanding inspection, summarize what is known, and continue only with narrower commands already required by the envelope. |
| A consolidated `RESULT.md` | `16 KiB` | Keep terminal facts and one correction summary. Put exceptional release evidence in a separately named, explicitly reviewed artifact and link it; do not append command transcripts. |
| A normal non-test command's wall-clock wait | Warn at `60 seconds`; stop waiting at `120 seconds` | Record `TIMEOUT`. Do not automatically terminate the process. |
| A focused test command's wall-clock wait | Warn at `120 seconds`; stop waiting at `300 seconds` | Record `TIMEOUT`. Do not automatically terminate Unity or another external process. |
| Parser, escaping, path-normalization, or admission command construction before side effects | Initial attempt plus at most `2` mechanical corrections | Record the concrete construction error and correction. These attempts do not consume the test or Unity invocation budget. Repeating the same uncorrected error is not allowed. |
| Local non-Unity evidence attempts | Initial attempt plus at most `2` corrected semantic attempts per declared scenario | One human authorization covers the full scenario envelope. A rerun requires a concrete repair or changed prerequisite. Mechanical command corrections do not consume these attempts. |
| Unity or other externally stateful validation attempts | Exact count declared per evidence class in `TASK.md` | No implicit attempt exists. Each run must remain inside the human-authorized external envelope and cleanup ownership. |
| Context compaction | Summarize after a compaction | Continue the same task from a concise state record. Create a file checkpoint only if execution stops, ownership changes, or evidence needs a durable recovery point. |

Count output limits in UTF-8 bytes when the tool exposes a byte count; otherwise
use a conservative bound without maintaining a manual byte ledger. A retry is
the same logical validation even if ordering or a display-only argument
changes. Warnings narrow the next action but do not authorize a blind rerun. A
timeout stops waiting, not ownership or lifecycle cleanup: starting, pausing,
and closing Unity or another external process still requires explicit
authorization and a recorded cleanup plan.

A task-local `retry 0/0`, `single attempt`, or `stop on first failure` clause
applies only to the explicitly named semantic assertion or external side effect
and must state its risk rationale. It never consumes or disables the two
pre-side-effect mechanical corrections. When no such approved exception is
present, an in-scope product failure returns to bounded diagnosis and repair;
it is not an automatic Planner checkpoint.

Unity and other expensive or externally stateful invocations have no implicit
budget. Their exact maximum count must be human-authorized in the task card.
For a release/full gate, the request may authorize an initial run plus up to two
same-scope corrected runs as one envelope; this is a maximum, not a requirement
to consume every attempt.

### Budget Ledger And Continuation Gate

Record only evidence that affects safety or interpretation: external/test
invocations, corrected attempts, retries, timeouts, truncation, and any process
whose ownership returns to the human. Do not maintain minute-by-minute or
estimated-byte accounting when the tools do not provide it.

Pause for Planner/User only when the objective changes, authority must expand,
an external prerequisite prevents progress, evidence is unavailable or corrupt,
or the authorized external/test attempt envelope is exhausted. An exhausted
envelope may be extended by appending authorization to the same task record;
it does not require a new task unless the independently acceptable outcome has
changed.

## Implementation Rules

- Use the repository's existing APIs, patterns, and ownership boundaries.
- Use `apply_patch` for manual edits.
- Keep changes semantic and local; do not perform opportunistic refactors,
  compatibility work, or formatting churn.
- Keep comments limited to important or non-obvious behavior.
- Do not add a second source of truth for version, control, or lifecycle policy.
- Keep Git inspection milestone-based and scoped: normally one bounded
  target-state check before dispatch and one final scoped status/diff or
  `diff --check` at handoff. Do not repeatedly run full-repository status,
  diff, or identity calculations. Freeze exact identities once, only when a
  `GUARDED` or `RELEASE` handoff needs them.
- Do not commit, push, publish, stop external processes, or mutate global
  configuration during implementation unless that action is explicitly
  authorized. Code sessions must never auto-commit when implementation or
  focused verification ends. A commit proposal is allowed, but the session
  must not infer authorization from dispatch, the task card, a `RESULT`, or a
  passing test.
- Coder and Verifier sessions must never create a Unity project, launch a
  Unity Editor, or run a Unity validation process in the background or hidden
  from the human. A task card or the presence of the standard validation
  project is not authorization. Unity may start only under the explicit
  EditMode/acceptance request defined below.
- If Unity MCP is unavailable, a connection fails, or the required MCP
  surface cannot be used, stop that Unity evidence path, preserve the original
  error, and notify the human. Do not retry in the background, switch to an
  unreviewed endpoint, create a substitute project, or present a direct probe
  as Unity/MCP evidence. Classify the gate as `BLOCKED` or `DEFERRED`.
- Subagents are off unless the frozen task selects `FAST_SUBAGENT` and records
  `TASK_SPECIFIC` or `STANDING_WORKFLOW` delegation. Apply the depth-one,
single-writer lifecycle above; Coder and Verifier children may not recursively
delegate or overlap their write phases.
