# S35 package setup result

Date: 2026-10-19.
Status: FIRST_INSTALL_PASS / IDLE_ATTENTION_REGRESSION_OBSERVED / LIFECYCLE_PAUSED.
Uninstall and same-version reinstall: NOT RUN; original sequence authorized but
dependent actions paused after the idle status issue.

## Outcome and scope

User reports `已创建并关闭` following the announced human-creation -> package
integration handoff. Parent inspected the actual closed project and completed
the previously described two-file setup under the current continuation request.
No earlier S33 real-action authorization was reused.

Project: `.artifacts/unity-projects/s35/`.
Actual Editor metadata: 2022.3.62f3 (96770f904ca7).

Before setup, neither package file contained a CodeDB dependency. AIWork and
project .codex were absent, as were Temp/UnityLockfile and Library/EditorInstance.json.
No attributed project command-line process or redirected inspected ancestor was
observed. This is bounded setup evidence, not a general machine-process audit.

## Preserved originals and precise changes

Exactly two original files copied to fresh repository-local
`.backups/s35-lifecycle-setup-d4a097d/`. Source-before/source-after-copy and
backup SHA-256 values matched. Existing backups were not overwritten.

| Project file | Original / backup SHA-256 | Configured SHA-256 |
| --- | --- | --- |
| `Packages/manifest.json` | `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1` | `ebbdae44ade67b94bc927439bfa215c871e7bfb53abb6d9a8216eb7783d7de8e` |
| `Packages/packages-lock.json` | `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6` | `fddd8b1d34c6155b1e884004afef5e31d014dd91213b8c732dacec3da6c78279` |

Manifest: added CodeDB's local dependency and testables entry only.
Lock: added CodeDB at depth 0, source local, empty dependencies, matching package
metadata. Both references resolve from the actual Packages directory to:

`file:../../../s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`

Parsed JSON comparison after removing exactly the new entries matched the
originals, proving all other JSON content unchanged. No project settings or
other dependency settings were edited. This is a semantic comparison, not a
claim of byte identity between the configured files and their original backups.

## Artifact and verification evidence

Reused source `d4a097d20af598ca760163867a3394ff5efb116d`, package
`0.3.0-preview.5 / poc.43`, exact existing extraction:
`.artifacts/s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`.
ZIP SHA-256 rechecked and matched
`9a3d9a70a5d46fecea3a47920ad0463b3aefd076bf15efe51c6c4f1b31d25300`.
The original 623 file byte checks and the additional preserved import .meta
are recorded in [TASK.md](TASK.md). No export or extracted-package edit occurred.

After setup, both local references resolve correctly and agree; manifest has
exactly the added CodeDB testable and lock shape is correct. AIWork/.codex,
Unity lock and EditorInstance remain absent. No attributed project process
appeared. Parent did not start Unity, invoke MCP/BatchMode, run Test Runner,
Install/Uninstall or provider/model acquisition, stop a process, edit product
source, commit or publish. Accepted S34 focused tests were not rerun.

Task/index records updated alongside the two package configuration files.
Tracked development project, S33, other artifacts and unrelated dirty source
remain outside the setup change scope.

## Original initial-baseline handoff (completed)

Open the existing S35 project in Unity 2022.3.62f3 and allow package import and
compilation to finish. Confirm no compilation error, open CodeDB Manager, and
report the initial NotIntegrated / Install available state. Manager close/reopen
once and tab switching can supply initial UI smoke.

Do not click Install yet. No repeated full Test Runner batch is requested for
this configuration-only setup. On compile/import/Manager error, report the
original state and stop before real product actions. A setup PASS is not Unity
compilation PASS, real first Install PASS, reinstall PASS or release acceptance.

After baseline feedback, align one bounded human lifecycle grant for first
Install -> Ready -> logical Uninstall -> same-version Install -> Ready with
parent read-only postchecks and no repeated approval inside the agreed stages.
CleanupMono, log verbosity and Manager reopen unconfirmed UX remain deferred.

## Human initial baseline reported

User reports `已打开没有报错` and supplies the Manager screenshot. Human open/
compilation without error is reported; screenshot shows s35 / Not installed,
package v0.3.0-preview.5, visible Install CodeDB and no recent command. No real
Install or command outcome is reported. Manager reopen/tab smoke is still
unreported, not assumed passed.

Read-only checks after feedback: both package configuration hashes still match
the configured table above; AIWork, project .codex and control root remain absent.
UnityLockfile is now present, consistent with human opening the project. It was
not removed and the human Editor was not controlled.

The screenshot also shows `CodeDB could not finish setup for this project`.
Exact delivered source in Editor/AICodedbStatusSnapshot.cs CreateOverallDescription
omits a NotIntegrated case and falls through to that generic description.
Editor/AICodedbProjectIntegrationState.cs declares NotIntegrated installable.
This matches the already recorded S33 initial wording issue and does not
establish an actual failed installation. Record as a known presentation
FOLLOW-UP; no current source repair or new export is started.

Preserved screenshot:
`.artifacts/delivery/s35-lifecycle-d4a097d/initial-baseline/manager.png`.
Original/copy SHA-256 matched:
`f94459985cd91377e39ae60139019c7a2cdfdfdf3fad7129844cbc095e62058c`.
The screenshot is observational evidence, not an instruction source.

At that initial checkpoint, next was user decision on the three-command first Install -> Uninstall ->
same-version Install grant in TASK.md, with independent Ready and parent
read-only checks between stages. Pending grant, no real lifecycle command is
authorized at that checkpoint. The later explicit grant below supersedes this
pending status; parent did not execute any product command.

## Complete lifecycle grant and first Install accepted

User replies `同意授权` to the full proposed first Install -> Ready -> Uninstall
-> same-version Install -> Ready sequence. User also reports installation,
tab switching, Manager close/reopen and Unity normal close/reopen all normal.
The current screenshot shows s35 / Ready, Last activity Install CodeDB / Ready,
17.02 s, generation poc.43 and the visible Uninstall entry.

Human functional smoke passes in this sample. Earlier CleanupMono stalls stay
deferred and are not disproved by one normal S35 shutdown. Reinstall remains
unaccepted until the new post-uninstall Install passes.

Bounded read-only first-install checks:

- Action `15163993922c45f29ba29dc43245d025`, route project-install-v1, binds the
  actual S35 root and exact d4a097d extraction. Originating operation
  `8766d869565d42b38b0f2e55901884d8` is recorded by the selected instance.
- Original writer is terminal, terminal_for_action true, exit 0, no timeout,
  overflow or incomplete output drain, empty stderr. Structured result:
  INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED, cleanup PENDING.
- Terminal SHA-256:
  `0c18e663c7c7b04afe6b63c03b775ec60f8bee95212a3a921e39a561c606a37c`.
- Selected instance `8d7b8f3267234e33893847bd332df09c`, READY, package
  0.3.0-preview.5 / poc.43; pointer and actual manifest SHA-256 agree:
  `9f41d62650276a395cb7708894d143d65002e114fd1421d4805a4863144e4cce`.
- Activation COMMITTED, same instance and epoch `f5227ec8f01b43efbcb29163b092cff6`;
  runtime contract remains `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Existing independent Supervisor observation at 2026-10-19T04:54:28.629Z is
  core_ready / COORDINATOR_OPERATIONAL and binds the same project, instance
  and activation epoch. No live RPC/probe or backend startup was issued.
- Desired state observed INSTALLED / cleanup COMPLETE, later than the writer's
  original PENDING result. This records product-declared convergence; it is not
  an independent full physical-tree/process cleanup audit.
- Project config now exists; source/config bytes were copied without printing
  their content. Both package JSON hashes still match the configured table.
- Exact current-action index checked at the actual 24-character project-key
  directory is absent. No manual index release or state cleanup occurred.

Nine original action/stage/selection/instance/desired-state/activation/config
records were copied with source-before/source-after/copy hash equality to:
`.artifacts/delivery/s35-lifecycle-d4a097d/first-install/records/`.
Its manifest lists symbolic source categories and hashes; summary and the
selected readiness observation are also preserved. Supervisor credential fields
are not copied into that selected readiness observation.

Screenshot: `.artifacts/delivery/s35-lifecycle-d4a097d/first-install/manager-ready.png`,
verified SHA-256 `af7708c644f3b1b3fbc426e0eba2a2edec6e355493c08736a5d867639c5ff248`.
No parent lifecycle command, source repair, package change, process control,
Unity launch or test invocation was performed.

## Previous Uninstall handoff (paused by the idle report below)

Within the already approved complete lifecycle envelope, human clicks
`Uninstall CodeDB from Project` once and confirms once in the current S35
Manager. Observe the original action and report its command result, final
uninstalled/other state and any Console error. Keep the project open for the
parent's read-only result/desired-state/selection/config/operation checks.

Do not click Install or repeat Uninstall before those checks. On error, unknown
outcome, new external prerequisite or ten-minute nonconvergence, report the
first result and stop dependent actions. No new approval is needed for this
already authorized stage; product confirmation remains human-owned.
After successful uninstall checks, parent hands off the one same-version
Install in the existing grant. Full lifecycle is still incomplete at this point.

## Idle Ready -> NeedsAttention before Uninstall

User explicitly reports no Uninstall click and says Manager changed to attention
after a long idle period. Screenshot shows Needs attention, no recent command,
Uninstall still visible and diagnostics ending `Materializer and Bridge
operational observations do not identify the same revision.` Most checks become
Not evaluated. This is distinct from the initial NotIntegrated generic wording.
Stop the dependent Uninstall/reinstall handoff while aligning its disposition.
No failed Uninstall is recorded because that command was not executed.

Read-only existing records still show the original instance and activation epoch,
INSTALLED / declared cleanup COMPLETE, unchanged project config versus the
preserved first-install copy, Supervisor core_ready / COORDINATOR_OPERATIONAL
and Coordinator provider_state ready. Latest persisted materialize:Probe remains
completed, exit 0, no timeout/overflow/drain error. History contains only three
records at the first diagnosis sample; no new reinstall or mass history growth
is implicated. These observations do not replace live MCP or complete process
health validation, neither of which was run.

Direct exact-package source provides a concrete causal path:

1. Editor/AICodedbEditorLifecycle.cs uses a 120-second removal-preflight cache.
   Its no-backend-reconcile Ready branch retrieves cachedResult and cachedStatus,
   refreshes only removal preflight, then calls RememberLifecycleProductStatus
   with that older cachedResult (around lines 1280-1300).
2. RememberLifecycleProductStatus binds its result to SupervisorBridge.CachedSnapshot
   at call time (around lines 3461-3476), rather than retaining the supervisor
   observation that originally accompanied that result.
3. BindProductStatusToSupervisorObservation requires exact observation id/revision
   and owner bindings; mismatch produces the exact screenshot detail and
   NeedsAttention (around lines 3584-3627).
4. Supervisor polls at 1000 ms and publishOperationalReadiness creates a new id
   and increments revision on publication, including normal healthy refreshes.
   Thus matching owner/instance and continued core_ready do not imply matching
   observation revisions. Existing persisted Probe output carries revision 7;
   live persisted Supervisor samples carried revision 1221 and then 1318, same
   instance, owner epoch `1356c641bf914b05ab75da6b52e37feb`, activation epoch and
   Supervisor pid. The selected later sample is dated 2026-10-19T05:11:46.537Z.

Conclusion: the screenshot, healthy existing runtime records and this exact
source path strongly support old command observation/new Bridge snapshot mixing
during cached preflight refresh as the cause. Exact screenshot-time in-memory
cachedResult and CachedSnapshot were not captured, so no exact live tuple or
trigger timestamp is asserted. This is a current clean-project status-refresh
finding, not arbitrary historical recovery or evidence of a failed Install.
Prior first-install and reopen evidence remains valid at its recorded times;
sustained idle Ready is now an explicit unresolved acceptance observation.

Existing test LifecycleStatusBinding_RequiresSameOperationalObservationRevision
deliberately rejects differing revisions. A repair should preserve that binding,
not remove equality checks or accept a newer observation solely because its owner
matches. Proposed narrow direction: preserve/reuse the coherent cached lifecycle
tuple when only removal preflight changes; obtain a complete properly bound fresh
observation when actual readiness needs refresh. Expired evidence must not be
promoted to fresh Ready. Keep uninstall admission and process-identity rules
separate from readiness display. This is a proposal, not an authorized source fix.

Preserved evidence base:
`.artifacts/delivery/s35-lifecycle-d4a097d/idle-attention/`.

| File | SHA-256 |
| --- | --- |
| manager-attention.png | `3c3094d53ce7b36bfcc28c4b04ad0697b8bf0377d3d7f0f6d7062bc37d556573` |
| current-instance.json | `51451aebd74bb9baea5d5ee64f01acadae307dab6b0863602d8d9c581d5f097b` |
| desired-state.json | `c416ed236360ccc7517cf4e40aada871e5340ab71ed743b59a00e950472a822f` |
| last-probe-operation.json | `06a5636033bea4abd56d335c375b888a6242d3f3b5861c5519a028413c8d77e3` |

Selected-supervisor-observation.json stores only the selected runtime/readiness
fields, not credentials. Source data is preserved without retrospective edits.
No parent RPC/probe, Unity interaction, process control, runtime mutation, test,
source fix, package export or reference change occurred. Next: align the narrow
status-refresh disposition before resuming the original lifecycle sequence.

## Approved narrow source-repair route

User subsequently replied `好的 同意` to the narrow cache-coherence repair.
The [S36 task](../cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/TASK.md)
freezes two source/test files, strict observation matching and unchanged
freshness, conditional publication against the captured cache revision, and
focused evidence. This supersedes the proposal's unapproved status above; it
does not retroactively grant delivery, Unity execution or child delegation.
The subsequent user reply `同意批准` authorizes a task-scoped Coder followed by
a stable-snapshot read-only Verifier. Parent has dispatched the bounded Coder
and remains active through completion. Coder has now stopped with its stable
two-file source/test snapshot; parent matched RESULT.md hashes and admitted the
targeted read-only Verifier. Syntax/static checks passed; compilation, NUnit
execution and real idle stability remain deferred. S35's original artifact and successful
first-install evidence remain protected, and dependent Uninstall/reinstall
actions remain paused. Source completion and human acceptance are still open.

S36 has now reached a stable completed Coder snapshot and independent targeted
source-review PASS with no in-scope finding. Parent verified the two file hashes
after review. See S36 `RESULT.md` and `VERIFICATION.md` for exact identities.
Source disposition is pending. Semantic compilation, NUnit and real idle
stability remain deferred, and neither delivery nor an S35 package-reference
switch has occurred. S35 still uses the original S34 artifact. The initial
Install remains a passed recorded stage; idle stability, logical Uninstall and
same-version reinstall are still open. Do not resume the lifecycle automatically
or treat the source review as a real-environment result.

User subsequently replied `同意 accept`, accepting the S36 source snapshot with
the declared execution limits. See S36 `DECISION.md` for the exact acceptance
and proposed six-path commit/export/S35-reference-switch group. No delivery
authorization has been granted by source acceptance. S35 remains on the S34
artifact, with pending lifecycle commands paused. If the reference is later
switched, explicitly update the human acceptance/lifecycle handoff rather than
silently treating the original same-S34-artifact grant as covering a new package.

## Authorized S36 delivery and pending human idle check

After human S35 closure and explicit `同意授权`, parent completed the exact
six-path S36 commit, commit-derived export/checks and S35 reference switch.
Current delivered source: `4291e80795681ad0057518b5ecd6c04e3c9ca92b`.
Current Package reference:
`file:../../../s36-preflight-refresh-4291e80/review/com.rice.ai-codedb`.
ZIP SHA-256:
`0e996028b1100260c366528db3cfc6a63b64120b117c841925bd1a8f4e575e5c`.
Exact 623-file byte closure, production admission, identity/native binding and
path provenance passed; S35's two config files have only the approved reference
substitution. Project config, current instance, desired state and activation
hashes remained unchanged. Originals are backed up under
`.backups/s36-preflight-refresh-4291e80/`.

See S36 `DELIVERY-RESULT.md` for full identities and the focused human checklist.
First Install remains historically passed on S34. After the corrected delivery,
the human reports that S35 reaches Ready; a later background observation also
returns to Ready, with the visible state showing the last verified Ready
observation as cached. This is the deferred S37 periodic-refresh observation,
not a new failure. Compile/NUnit, Manager reopen/tabs and normal close must be
classified from their actual human results. Remaining Uninstall/same-version
Install stay paused and require a changed-artifact lifecycle handoff; no first
Install replay is requested.

Human then reported two CS0246 compile diagnostics on S36's added
`[NonParallelizable]` test decoration. Actual referenced Unity-custom NUnit
3.5.0 metadata does not contain that attribute; it does expose the scoped
Parallelizable attribute. See S36 DELIVERY-RESULT.md for preserved screenshots,
actual DLL binding and the proposed single-attribute correction. Human compile
acceptance is FAIL; focused tests and dependent idle/lifecycle gates are paused.
No production-runtime failure or failed new Install is inferred from this
test-source compiler error. Source repair and repeat delivery are not automatic.

## Re-authorized uninstall result — 2026-10-19

The user completed the first stage against the currently referenced S37
package. Manager showed `Uninstalled`, restored the `Install CodeDB` entry, and
reported `Completed` with exit code 0. The retained warning corresponds to
`cleanup_state=PENDING`; the original operation output classified the result as
`UNINSTALLED` with reason code `LOGICAL_UNINSTALL_COMPLETE` and stated that no
external MCP process was stopped.

Read-only project evidence confirms `desired_state=UNINSTALLED` and the
completed `materialize:Uninstall` operation. Only the S35 Unity Editor process
matched the project root; no matching Supervisor, Coordinator or Provider
process was found. This closes the Uninstall gate. The same-version Install
gate is now the only remaining S35 lifecycle action and remains human-owned.

## Same-version Install preflight failure — 2026-10-19

The user attempted the authorized same-version Install once. It stopped in
preflight with exit code 6:

`BLOCKED / INSTANCE_CONVERGENCE_FAILED / mutated_scopes=[]`

The reported detail was `Install Supervisor execution result is missing
required property output_overflow`. The Manager therefore remained
`Uninstalled`; no new candidate was selected and no project mutation occurred.

Read-only inspection found one retained failed Supervisor history record,
`ce169d22b8544299b01407cef5d9b70b.json`, whose result has `exit_code=1`,
`timed_out=false`, but omits both `output_overflow` and
`output_drain_incomplete`. Its error is `Prior child admission has unresolved
identity; another child is blocked.` The current S37 Supervisor source's
`finishOperation` error branch constructs the same incomplete result shape,
which explains the contract mismatch; this is a source-level diagnosis only.

The project remains safely `desired_state=UNINSTALLED`. The lifecycle gate is
blocked pending alignment on a narrow terminal-result/unknown-child repair.
No retry, history rewrite, manual deletion, source edit, package export or
reference switch was performed.

## Narrow terminal-result repair — 2026-10-19

The user authorized a narrow source repair after the preflight blocker was
diagnosed. `Tools~/codedb-project-supervisor.mjs` now routes exception-created
terminal results through the same compact result projection as normal child
completion, explicitly recording `output_overflow=false` and
`output_drain_incomplete=false` when no child output was drained. The existing
unknown-child admission state remains `CHILD_ADMITTED` with a null child and
continues to fail closed; no identity is inferred.

The focused Supervisor fixture now exercises the actual
`finishOperation(..., error)` branch and asserts both output fields plus the
continued unresolved-identity rejection.

Validation passed:

- `node --check` for production and fixture;
- `node --unhandled-rejections=strict Tests~/test-codedb-project-supervisor.mjs --s32-disposition-fixture ...`;
- `git diff --check` for both touched files.

Working-tree hashes:

- production: `7A39A8080737CBED2FD4D912651BEF3F74221B4099E503568E1D2EAC9E150E4B`;
- focused test: `D73D0E3CC9C7436FB8DFBBB7DC605043A5BA3F963243ED18400B16990F5398BE`.

This source snapshot does not rewrite S35's existing malformed
`ce169d22b8544299b01407cef5d9b70b.json`, does not retry Install, and is not yet
committed or exported. Delivery and a new human lifecycle attempt require a
separate explicit authorization.

## S37 terminal-result package human smoke — 2026-10-20

Against the exact package referenced by S35 after the `d856a8f` delivery, the
user reports focused Test Runner PASS, normal Manager and Unity open/close
behavior, and no compile error. The Manager was in `Uninstalled` state with
`Install CodeDB` visible. Only the Overview content was present, so there were
no additional tabs available; tab switching is N/A for this sample.

This closes the package compile, focused-test and UI-smoke gate as
`PASS_WITH_LIMITS`. Install was not retried, so the same-version lifecycle gate
remains separately blocked by the retained fail-closed historical record.

## Authorized Install attempt after S37 delivery — 2026-10-20

One human Install attempt was performed against the exact S37 package. It
returned `BLOCKED / PREFLIGHT / INSTANCE_CONVERGENCE_FAILED`, exit code `6`,
with `mutated_scopes=[]`; no candidate was selected and desired state remains
`UNINSTALLED`.

The newly written action receipt is complete and contains both output evidence
fields. The blocker is the retained historical operation
`ce169d22b8544299b01407cef5d9b70b.json`, whose old failed result omits
`output_overflow` and `output_drain_incomplete` while retaining unresolved child
identity (`CHILD_ADMITTED`, `child=null`). The source delivery deliberately does
not rewrite or infer that historical identity. No retry or manual cleanup was
performed; S35 now requires a separate decision on migration, archival, or
leaving the historical acceptance project blocked.
