# S38 current-version lifecycle acceptance

Date: 2026-10-20.
Status: `CURRENT_VERSION_LIFECYCLE_PASS / PERIODIC_OBSERVATION_WARNING / CLEANUP_PENDING`.

## Outcome and authority

Establish one attributable first Install -> independent Ready -> logical
Uninstall -> same-version Install -> independent Ready route in a fresh Unity
project. A first Install PASS alone does not close reinstall acceptance.

The user agreed the fixed project root
`<repository-root>/.artifacts/unity-projects/current-lifecycle/` and the
current-version lifecycle route after S35 was logically archived as
`BLOCKED / PARTIAL`. The human creates and closes the new Unity project at this
root; Editor selection, launch and real Manager actions remain human-owned.
This task card records the route and preparation boundary. It is not authority
to replay S35's blocked action, alter its historical operation, run Unity,
invoke MCP/BatchMode, stop a process, or perform a lifecycle click.

The fixed development project, S33 complete historical sample, S35 archived
project, all existing Package/evidence roots and unrelated dirty worktree are
protected. S35's old `CHILD_ADMITTED`/null-child record and missing output
fields remain an unresolved historical result, not a clean-project baseline.
No product source change, new export, commit, push, provider/model acquisition,
historical repair or physical cleanup is in this task.

## Exact Package baseline

- Source delivery commit: `d856a8f0916253f45369ae3fde7f4a2a6b26b9cb`.
- Extracted Package:
  `.artifacts/s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`.
- ZIP: `.artifacts/s37-supervisor-terminal-result-d856a8f/com.rice.ai-codedb.zip`.
- ZIP SHA-256:
  `97aecd28ff47656a9b6cd66666f6c9030b95a8f4b5a98cf8cf68f588058031a9`.
- Package version: `0.3.0-preview.5`; Unity target: `2022.3.62f3`.

The ZIP hash and extracted Package existence were rechecked before this task
card was written. Reuse this exact Package; do not rebuild or silently select
the current dirty source tree. From the agreed root's future `Packages/`
directory, the expected local reference is
`file:../../../s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`.
Recompute and resolve it after the real project exists before editing either
Package consumer file. The older d4a097d reference in the organization task
was a historical proposal and is superseded for this new route.

## Stages and stop rules

| Stage | Owner and evidence | State |
| --- | --- | --- |
| Create clean project, then close Unity | Human reports actual root and Editor version; no copied Assets, Library, AIWork, runtime or Package configuration from S33/S35 | COMPLETE; Unity 2022.3.62f3 baseline checked |
| Baseline check and Package configuration | Parent checks original project state, process/lock ownership and exact Package; backs up original manifest/lock; changes only CodeDB dependency, lock entry and testable declaration; verifies both parsed references | COMPLETE; see SETUP-RESULT.md |
| Import, compile and baseline UI | Human opens project and reports Console/compile status, focused Package tests, Manager baseline and Install availability | PASS WITH LIMITS; no errors reported and Manager entry visible. Exact-Package focused tests passed earlier in S35; no S38 Test Runner run. See INITIAL-HUMAN-RESULT.md |
| First Install and independent Ready | Human confirms one action; parent reads attributable result, selected identity and separate Ready observation | PASS; original writer exit 0, selected instance and independent core_ready match. Cleanup PENDING; see FIRST-INSTALL-RESULT.md |
| Installed-state reopen smoke | Human closes/reopens Manager, visits visible tabs, then normally closes/reopens Unity and reports retained state and errors | PASS; user reports no abnormality. See INSTALLED-SMOKE-RESULT.md |
| Logical Uninstall | Human confirms once after first-stage closure; parent checks terminal result and project disposition | PASS; exact operation exit 0, desired UNINSTALLED, pointer absent, owned MCP table inactive. Cleanup PENDING; see UNINSTALL-RESULT.md |
| Same-version Install and independent Ready | Human confirms once after successful uninstall; parent checks new action and separate Ready | PASS; new selected instance, original terminal exit 0 and independent core_ready match. See REINSTALL-RESULT.md |

Stage results are recorded before the next action. An unsuccessful or unknown
action, new external prerequisite, or ten-minute nonconvergence stops dependent
stages. Do not retry, reset state, reinterpret historical records or substitute
isolated tests for real acceptance. Manager reopen/tab and normal Unity
close/reopen observations are human-reported smoke evidence, separate from the
action outcome. CleanupMono, startup presentation and cross-version migration
remain deferred unless a later scoped decision changes that boundary.

At completion or baseline replacement, update the project index and review
S33/S35 retention under the evidence-first rule. This task grants no deletion.

## Current handoff

The authorized single first Install passed with matching original terminal,
selected instance and independent Supervisor Ready evidence. The user also
reports normal Manager close/reopen, tab use and Unity close/reopen; the
read-only checkpoint still shows the same installed instance and core_ready.
See `FIRST-INSTALL-RESULT.md`, `INSTALLED-SMOKE-RESULT.md` and
`UNINSTALL-RESULT.md`. The authorized single logical Uninstall passed with
matching original operation and project postconditions. Cleanup remains
PENDING; its handoff warning and a rejected queued maintenance request are
recorded separately. The authorized same-version Install passed with a new
selected instance, attributable original terminal and independent Ready
observation. See `REINSTALL-RESULT.md`. The core S38 lifecycle is complete;
cleanup remains PENDING and post-reinstall reopen smoke was not observed.
The user subsequently reported recurring `CodeDB status unconfirmed / Checking`
for an estimated 30-60 seconds, then automatic recovery to Ready, with no
perceived Unity stutter or abnormal interaction so far; see
`PERIODIC-OBSERVATION-RESULT.md`. Stable idle UX/performance is an open S37
follow-up, separate from the attributable Install/Uninstall action results.
S33/S35 full-project retention is due for evidence-first review, without a
deletion grant. No Unity launch or product action was performed by the parent.
