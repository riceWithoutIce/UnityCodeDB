# S35 clean-project current-version lifecycle acceptance

Date: 2026-10-19.
Status: FIRST_INSTALL_PASS / S37_HUMAN_ACCEPTED / UNINSTALL_PASS / SAME_VERSION_INSTALL_BLOCKED / SOURCE_REPAIR_READY.

## Metadata and authority

- Product/version: UnityCodeDB v0.3.0, package 0.3.0-preview.5 / poc.43.
- Workflow: codedb-workflow-v2 revision 2.6.
- Review mode: NORMAL for preparation; human real-project acceptance required.
- Execution mode: DURABLE_SESSION, current parent owns continuity and records.
- Coder/Verifier: no source-development or independent review dispatch requested.
- Delegation authorization: NOT_AUTHORIZED for this task; no child needed.
- Requirement source: existing current-version lifecycle route in the v0.3.0
  roadmap and S33/S34 results. This is a new acceptance baseline, not a repair.
- User asks to return to the new-project lifecycle after completing the exact
  historical-project deletion. Alignment, task preparation and read-only checks
  proceed; human creation, package integration and real lifecycle actions remain
  explicitly distinguishable stages. No earlier S33 action grant is replayed.
- User then reports `已创建并关闭` in response to the announced creation ->
  package-integration handoff. With the closed clean baseline verified, parent
  completed that bounded package setup under the current continuation request.
  This does not authorize first Install or subsequent real lifecycle commands.

## Single outcome and protected scope

Establish one attributable first Install -> Ready -> Uninstall -> same-version
Install -> Ready route in a clean human-created Unity project. Verify normal
Manager close/reopen and tabs, and human Unity reopen observations as declared.
First Install alone cannot close same-version reinstall acceptance.

Actual project root: `<repository-root>/.artifacts/unity-projects/s35/`.
Human created and closed this project; ProjectVersion.txt confirms Unity
2022.3.62f3 (96770f904ca7). Editor selection/open/close remains human-owned.
An empty project supplies no copied Assets/Library/AIWork or old configuration.

Protected state: tracked development project, retained complete S33 sample,
all existing evidence/backups/packages and unrelated dirty source. Cleanup does
not authorize removing their runtime, old machine action indexes or processes.
Product source changes, export/commit/push, historical recovery, new fixtures,
MCP/BatchMode, process termination and dependency/model acquisition are outside
this acceptance task. CleanupMono, log verbosity and Manager unconfirmed-display
UX remain deferred; observed shutdown results are recorded accurately.

## Reused exact artifact and read-only preparation

- Commit: `d4a097d20af598ca760163867a3394ff5efb116d`.
- Package: `.artifacts/s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`.
- ZIP: `.artifacts/s34-supervisor-history-d4a097d/com.rice.ai-codedb.zip`.
- ZIP SHA-256: `9a3d9a70a5d46fecea3a47920ad0463b3aefd076bf15efe51c6c4f1b31d25300`.
- Rechecked 2026-10-19: ZIP matches; all 623 original ZIP files match extracted
  bytes. One extra `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta`
  is retained as an import-generated file, not a changed original package file.
- Proposed root absent at preparation. Relative package reference computed from
  its Packages directory and resolved back to the exact extraction:
  `file:../../../s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`.
  Recompute/verify against actual root during setup; do not copy S33's literal.
- Proposed project root is ten characters shorter than S33's original root.
  Existing package longest observed absolute file path is 173 characters.
  These are observed path checks, not a new product path-length constant.

Delivery authority for existing artifact:
[S34 exact delivery](../cdb-v0.3-p0-s34-supervisor-history-retention-terminal-closure/DELIVERY-RESULT.md).
Historical route decision:
[S34 human result](../cdb-v0.3-p0-s34-supervisor-history-retention-terminal-closure/HUMAN-RESULT.md).

## Stages and grants

| Stage | Owner / required observation | Current authority and result |
| --- | --- | --- |
| Human creates clean project and closes Unity | Human; report actual root and Editor version | COMPLETE; actual root and 2022.3.62f3 checked. No agent project creation. |
| Read-only baseline and package setup | Parent; absence of old integration/runtime, checked process/lock and original config; hash-verified repository-local backups; only CodeDB manifest/lock entry and testables | COMPLETE; see RESULT.md. No runtime/config created, no Unity launch or product Install. |
| Compilation/Manager baseline | Human; compile normal, Manager NotIntegrated and Install available | PASS; human reports no error, initial screenshot confirms entry. |
| First confirmed Install | Human clicks/confirms once; parent checks attributable original result, selection/activation/instance and independent Ready | PASS; original writer exit 0 and matching core_ready evidence captured. |
| Reopen and UI smoke | Human; Manager close/reopen/tabs, normal Unity close/reopen and eventual Ready | HUMAN PASS in this S35 sample. Prior CleanupMono observations remain deferred. |
| Confirmed logical Uninstall | Human clicks/confirms once; parent checks original terminal result, desired state, selection/config disposition and relevant execution evidence | AUTHORIZED but PAUSED; user has not clicked. Idle NeedsAttention observed before Uninstall. |
| Confirmed same-version Install and Ready | Human; parent checks original new action/result and independent Ready on the same delivered package | PAUSED with preceding stage; not yet run. Principal unfinished lifecycle gate. |

Package setup plan, now completed after the human creation/closure handoff:
inspect only the actual new baseline; reject copied runtime or an
attributed active Editor. Preserve manifest/lock bytes in a fresh repository-local
backup, then add only CodeDB's local dependency/lock entry and testables, keeping
other project settings/dependencies unchanged. Parent verifies references and
returns the initial human smoke handoff. Do not create installed markers/config
or execute product commands to make the baseline look ready.

After initial smoke, proposed one bounded grant covering human lifecycle clicks
and parent read-only checks across the complete sequence, with stage results
reported before advancing. Already authorized stages need no repeated approval.
This task card itself does not grant those real operations. No agent clicks,
silent Install, Uninstall, background startup or approval bypass is implied.

### Approved concrete lifecycle grant

User explicitly replies `同意授权` to the complete three-command proposal,
and reports first Install, Manager tabs/reopen and Unity normal close/reopen
all successful. This current S35 grant covers the sequence below. First Install
is consumed and checked; Uninstall and same-version Install remain available
only in the declared stage order. No additional approval is needed within it.

The grant covers exactly three human-confirmed real commands in this S35
project on the same delivered d4a097d package, with normal product-owned project
configuration/runtime changes and identity-checked managed startup/shutdown:

1. First Install, then observe the original successful command and independent
   Ready; report result for parent read-only checks.
2. After those checks, human Manager reopen/tabs and Unity normal reopen may
   supply smoke. Then one logical Uninstall, report its original result for
   parent read-only closure/disposition checks.
3. After successful uninstall checks, one same-version Install, report its new
   attributable result and independent Ready for final parent read-only checks.

Human returns each stage's result before the parent hands off the next stage.
No repeated authorization is requested between these stages after grant; each
product confirmation is still human-owned. Failure, unknown outcome, new external
prerequisite or ten-minute nonconvergence stops dependent actions for discussion.
No repeated lifecycle command, manual history cleanup, provider/model acquisition,
agent process termination, export, source repair or S33 mutation is included.
Manager reopen/tab checks are now explicitly human-reported passed with the
first successful installed smoke, rather than inferred from the screenshot.

## Evidence, convergence and completion

- L0 / affected L1 tests: reuse accepted S34 focused evidence; no source change.
- Explicitly not run: repeated unchanged fixtures, full Test Runner/regression,
  automated Unity, provider-readiness/model-staging tasks or historical replay.
- Test rationale: this task supplies missing real lifecycle evidence; another
  isolated PASS cannot substitute for actual uninstall-to-reinstall acceptance.
- Per real stage observe its original result. At a proposed ten-minute checkpoint
  without convergence, report the actual state and stop dependent operations;
  no extra clicks, forced process stop or automatic retry to manufacture success.
- On failure, preserve first-action evidence and classify the direct current
  product/environment/baseline cause. Discuss bounded disposition before source
  repair or historical expansion; apply existing escalation limits.
- Capture readable results under this task and necessary raw evidence under
  repository-local artifacts. Use symbolic/relative paths in durable summaries.
- Completion needs attributable successful Install, logical Uninstall and new
  same-version Install, independent Ready observations, and human smoke results
  with deferred risks clearly separated. Cross-version upgrade, release/MCP and
  physical deletion of retained content are not established by this route.
- After the corresponding lifecycle completes, review S33's full-sample retention
  under the approved evidence-first policy; no automatic deletion grant.

## Handoff

Current task: S35 real clean-project lifecycle acceptance.
Current status: first Install and independent Ready remain verified on the prior
artifact. Corrected S36 delivery is now referenced by S35, and the human has
reported that the project reaches Ready again. A later background observation
returned to Ready; that periodic refresh is recorded separately as deferred S37
UX discussion. The complete lifecycle remains open and no Uninstall or
same-version Install has been executed on the corrected artifact.
See [RESULT.md](RESULT.md). User approved the narrow source-repair direction;
the separate [S36 task](../cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/TASK.md)
freezes that source deliverable. User subsequently approved its sequential
Coder -> read-only Verifier route; the stable source snapshot and targeted
independent review are complete, with source review PASS and execution limits.
User accepted that exact source snapshot with execution limits and subsequently
authorized precise commit/export/S35-reference switching. After the direct
NUnit compatibility correction, S36 delivery is complete at commit
`3c93ddfb52a801cefef99fd4e12d55c10fa7778c`; S35 now references
`.artifacts/s36-preflight-refresh-3c93ddf/review/com.rice.ai-codedb`.
See the [exact delivery and human checklist](../cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/DELIVERY-RESULT.md).
Human has reported Ready after the corrected delivery. Compilation, focused
tests, Manager close/reopen and tab results, and normal Unity close still need
explicit result classification unless already separately reported. Pending
Uninstall/reinstall remains paused; the original same-S34-artifact grant is not
silently extended to S36. No corrected-artifact lifecycle click has occurred.
No source fix, new agent, export, Unity control, forced refresh, Uninstall or
reinstall was performed by this diagnosis.
Do not erase state or treat the prior NotIntegrated wording follow-up as this
new cause. No new full Test Runner or unrelated historical recovery is requested.
See [project index](../../../validation-projects.md).

## Re-authorized lifecycle continuation — 2026-10-19

The user completed the first stage against the currently referenced S37
package. The uninstall result was `UNINSTALLED / LOGICAL_UNINSTALL_COMPLETE /
exit 0`; `cleanup_state=PENDING` is retained by the product contract. Read-only
process inspection found the S35 Unity Editor but no matching Supervisor,
Coordinator or Provider process.

The second stage is now pending: one human-confirmed same-version Install and
independent Ready observation. No automatic retry, forced process termination,
source edit, package export, reference switch, historical recovery or unrelated
test run is included.

The authorized Install was attempted once and stopped at preflight. The
original result was `BLOCKED / INSTANCE_CONVERGENCE_FAILED / exit 6` with
`mutated_scopes=[]`; no replay is authorized. The reported detail was that the
Install Supervisor execution result was missing `output_overflow`.

## Re-authorized lifecycle continuation — 2026-10-19

After S37's corrected package was accepted by human Unity observation, the
user explicitly re-authorized the remaining S35 lifecycle gates against the
currently referenced package. The grant is limited to two human-owned
commands in order:

1. One confirmed logical `Uninstall CodeDB from Project`, followed by the
   parent read-only result/disposition check.
2. Only after a successful uninstall result, one same-version `Install` and
   independent Ready observation, followed by the parent read-only closure.

No automatic retry, forced process termination, source edit, package export,
reference switch, historical recovery or unrelated test run is included. The
first stage is pending the user's manual action and original result.
