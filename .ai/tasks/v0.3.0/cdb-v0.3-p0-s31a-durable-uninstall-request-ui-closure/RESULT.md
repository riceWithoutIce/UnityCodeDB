# S31-A Coder result

## Terminal status — 2026-10-16

**PARTIAL / NOT_ACCEPTED.** The durable request/UI source snapshot compiles and
the task-owned protocol/UI seams pass, but the full S31-A acceptance gate is
not met. No Verifier, commit, package export, reference switch, Unity/MCP
operation, real Install/Uninstall, or live process control was performed.

The checkout is the isolated worktree
`<isolated-worktree>`, based on
`ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`. Existing A2 Payload dirty files
were preserved byte-for-byte in place and were not edited by S31-A. The only
source changes are within the eight S31-A allowlisted C#/test files; the task
runner and fixture files are under `.artifacts/`.

## Implemented S31-A closure

- Durable Uninstall request identity is read from the project action index and
  remains the fence source across Manager windows and reloads.
- Duplicate confirmed callers attach to the existing request; startup
  Supervisor admission remains fenced while it is unresolved.
- Terminal failed Uninstall results now persist as `TERMINAL/FAILED` with a
  reason. They remain fenced and are not treated as `UNINSTALLED`; a later
  separately confirmed Uninstall may admit a new action id. Historical terminal
  records are ordered by their durable accepted monotonic timestamp so a newer
  retry can supersede an older failed terminal without losing the trace.
- Unauthenticated Uninstall results are persisted as `UNKNOWN` while retaining
  ownership. No automatic replay was added.
- Manager removal presentation remains callable independently of stale cached
  product status; terminal observation remains read-only.

## Final source hashes

| Path | SHA256 |
|---|---|
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | `38938e1d8f107f86901ce5a4b889e38573250aa7ff452b0dc428b6d9988894d1` |
| `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` | `0e4d6e54266e584e61bf9e534e10746c4a44f308f75a01d5b0af61f72072c0f2` |
| `com.rice.ai-codedb/Editor/AICodedbActions.cs` | `101346ae6d1110d3ef2fccde028077794f4e252cf791baa45a5e2df7a55df666` |
| `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs` | `8e8a418bd1a718a6de81f3e1c3c4b4e704e6003dd16ef0d03033135225b1e333` |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorLauncher.cs` | `c638057c1cb933ce40b0c2646b1762c0e9e995d2c9aa76f759e2b7b7ded5c826` |
| `com.rice.ai-codedb/Editor/AICodedbSupervisorRequestQueue.cs` | `4cd25b2756a44a3b4ee52858f967fb93766bfbcd6b54c5f80305586e26c9ecbd` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `ceae87a6e2ab31b9b1f6800c3234f9486cbb3bd0f825753a0386a03734c284f3` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `be61964b76445d442d5956e5f89d54c53bbaaf046e5088038cfc87a8db1395af` |

## Evidence

- Original-byte full Editor compilation: **PASS**. Final assembly hash:
  `c12eb340d6a2d48d60efa7387cd685c97392532e2b7a488eaed0444db780d119`.
- Original-byte full affected Editor.Tests compilation: **PASS**. Final
  assembly hash:
  `103ae03226c0d0444f1131799292ec1205aae0a2b607ceff157530f865ac7d`.
- `git diff --check`: **PASS** on the S31-A checkout (pre-existing Payload
  newline warnings remain unchanged).
- Task-owned Mono reflection runner on final assemblies: **PASS** for
  `S31Uninstall_RequestProducerRoundTripsAndDuplicatesAttach`,
  `S31Uninstall_StaleUnknownAndBusyPresentationRemainCallable`,
  `ManagerCommandResult_IncompleteSuccessIsNotNextChangePermission`,
  `RemovalMenu_AllowsRequestIndependentlyOfCachedAdmission`,
  `MissingRemovalStatus_AllowsConfirmedBackendClassification`, and
  `UninstallPreflight_RemainsReadOnlyWithoutGatingRequest`.

## Evidence limits / open gaps

- Reload/session/terminal tests that use `AICodedbTestWorkspace` could not run
  under the task-owned Mono reflection runner: the production test harness
  correctly rejected the non-Editor-main-thread invocation (`Test workspace
  capture requires the Editor main thread`). This is UNRUN evidence, not a
  source assertion failure.
- Unknown-result explicit retry still requires an Editor-thread end-to-end
  admission/reader scenario; no automatic replay or unsafe ownership release
  was introduced.
- Full Domain Reload/two-window lifecycle, terminal Manager repaint after
  reopen, actual startup/reconnect fence, and final Install/Remove/Repair
  Editor regressions remain UNRUN. Runtime stop, complete uninstall
  transaction, generation/Payload and package delivery remain S31-B or later.
- Unity/MCP/BatchMode, real project mutation, process census, commit, export and
  reference switching remain outside this dispatch.

The Coder is terminal. Parent owns alignment on whether to authorize an
Editor-thread semantic continuation or keep this partial snapshot for review.
