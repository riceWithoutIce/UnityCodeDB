# Decision: cdb-v0.3-p0-s12-fresh-lifecycle-integration

Status: FIX_REQUIRED

## Disposition

- Planner disposition on 2026-09-08: S12 is not accepted. The authorized
  visible scenario envelope ended as `COMPLETE / TEST_FAILURE_CLASSIFIED`.
- All three scenario attempts were consumed. A fourth S12 scenario is
  prohibited; another unchanged rerun would not be evidence.
- The failure remains inside the Runtime Release Gate. It does not advance the
  roadmap to Discover Read, third-party acceptance, publication, or release.
- The branch remains `codex/v0.3.0-legacy-workflow` at committed HEAD
  `9aada838e26879810a4f79760273ca66340ebf12`, with the S11 and S12 work left
  uncommitted. This decision does not authorize commit or push.

## Frozen Failed Snapshot

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s12-fresh-lifecycle-integration/TASK.md` | `14703` | `ca73b65c2d5c0c4477eff62b1bf15a43af89c6b925592b7bab557b66bd0ed423` |
| `.ai/tasks/v0.3.0/cdb-v0.3-p0-s12-fresh-lifecycle-integration/RESULT.md` | `31852` | `1262a60123fa184aec6965e9528369fc7cac5c1237d0c32214fe9e635eb6281e` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `138081` | `dbff5d64c400241154de4e8c5cfa5795f616d35ccfda50ef9a52f398abb79a0e` |
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | `118587` | `bc24ef7d67b450b7dae6d3ff4292109fc406739aed57db376e6cd3d46b30cf4b` |
| `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs` | `47442` | `12b7ce93dd6dc168d35080e56394b1d2b40f6e9077b27a6554b5f351765cfa8e` |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorBridge.cs` | `122662` | `efde2a5ca6318466ffe31b51172e49301dcff9656881e9f83179492b6bba3a7f` |
| `com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` | `25291` | `775142faa711431f89d80cfd4694eeb052b11a43f224ee284abf09bd208392e4` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `188604` | `fdc640ae0c5022f029bbcbb655c0491131a8ea750db3c3ab70f8af96fdc2499e` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `159374` | `792cd1d9a49c4520da2bd051bb61268f89bffc8c59d58dd1331b76f8d2d88315` |
| `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs` | `128166` | `d7567cda79add3a1717c861f542d9516e18cb483fe44220da1b704931c7dd176` |
| `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs` | `67313` | `82fe3eb07c3ef88dde193b73e00cb6377d24334bde0b4402e63f7ee3d9223a50` |

## Evidence That Passed

- The final visible Editor used the declared `UnityValidationProject/` and
  Unity `2022.3.47f1`. The closing cleanup baseline later confirmed zero
  matching validation-project Unity processes.
- The one-line NUnit correction removed the original `Is.Greater` compiler
  error. Attempts 2 and 3 returned no current C# compiler error in their
  bounded windows.
- S12 instrumentation consistently reported zero prohibited CodeDB work on
  Unity's main thread and zero main-thread violations.
- The outer Supervisor and selected instance remained stable within each
  observed attempt. No manual Reinstall, duplicate Supervisor owner, direct
  materializer fallback, or unrelated-process control was observed.
- The focused coordinator-readmission Node fixture passed once with exit `0`
  in `2.9515044s`, with no retry. It proved that admitted Probe/Upgrade work
  retries coordinator admission before materialization, remains fail-closed on
  ensure failure, and preserves the coordinator and outer Supervisor owners.
- The final scoped two-file `git diff --check` passed. Unity, EditMode, or the
  full Supervisor suite was not rerun for that bounded repair.

## Release-Blocking Result

- Every visible attempt stopped at the Cold Start entry gate. The final result
  remained `NeedsAttention` with `coordinator_pid=0` while the authenticated
  outer Supervisor and selected instance were still identifiable.
- The Manager classified the direct reason as `Selected instance coordinator
  is not operational.` Control-contract migration was inactive/not required;
  Package compilation and the corrected Editor test assembly were not the
  final blocker.
- A passive post-run identity check proved that the final outer Supervisor was
  created after the routing repair and used the current Package Supervisor
  script. The failure is therefore not explained by a stale Supervisor script.
- The routing repair closes a missing re-admission opportunity, but the real
  selected coordinator continues to fail startup. Its sanitized terminal cause
  is not available in the current Unity evidence surface.
- Manager cache-only acceptance, Play, proved Domain Reload reconnect, return
  to Edit Mode, and authenticated final shutdown were not reached. S12 cannot
  claim any of those outcomes.

## Verification Disposition

- No stable passing runtime snapshot exists, so S12 is not routed to Verifier.
- The focused Node evidence may be reused by the successor task. It is not a
  substitute for fresh local Unity lifecycle acceptance.
- A Verifier review is appropriate only after the persistent coordinator
  startup cause is corrected and one new complete lifecycle scenario passes.

## Protected Boundary

- `UnityValidationProject/.codex/` and `UnityValidationProject/AIWork/` were
  not admitted as direct diagnostic inputs and remain protected.
- The existing modified `UnityValidationProject/ProjectSettings/ProjectSettings.asset`
  and `com.rice.ai-codedb/Documentation~/development-workflow.md` remain
  unrelated protected changes. Do not normalize, revert, stage, or include
  them implicitly.
- No process was force-stopped. After the user closed the final visible Editor
  normally, one passive check at `2026-09-08T22:24:58+08:00` found zero
  matching validation-project Unity processes.

## Handoff

Current task: `cdb-v0.3-p0-s12-fresh-lifecycle-integration`  
Current status: `FIX_REQUIRED / CLOSED_WITH_CLASSIFIED_FAILURE`  
Next notification: `UnityCodeDB v0.3 Planner / Human`  
Next action: review and authorize one successor engineering task that combines
sanitized coordinator-start failure attribution, root-cause repair, focused
evidence, and one fresh complete visible lifecycle scenario  
Human decision or authorization required: the successor task, any new visible
Unity scenario, immutable generation transition, commit, push, Verifier
routing, publication, and release remain separately gated
