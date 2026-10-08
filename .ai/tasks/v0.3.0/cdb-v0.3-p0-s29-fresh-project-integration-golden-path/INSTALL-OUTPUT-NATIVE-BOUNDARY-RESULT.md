# S29 native daemon launch boundary - bounded POC result

2026-10-08. Coder diagnostic handoff: stable. Decision recommendation:
**APPROVE_FOR_INTEGRATION_PLANNING**, limited to the demonstrated Windows x64
creation boundary. No production integration or real Install retry performed.
Parent assessment is separate. S29 remains PARTIAL.

## Scope and frozen source

Authorized by INSTALL-OUTPUT-NATIVE-BOUNDARY-PLAN.md and user "同意授权".
Exclusive sandbox: `.artifacts/diagnostics/io/b71e8c92`.
HEAD: `d56f0e507b48af24a39f23411c06dbdd4e093084`.
Index hash before/after: `93c1f4ef48e5a8e0f058b1750132991af8eb010a`.

The actual shipped Manager writer was copied byte-for-byte from
`.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb`.
The original file-output helper and four required dependencies were imported from
the materializer AST unchanged. The prior `995de5da` command.ps1 and leaf.ps1 were
copied unchanged. Only the business-free Node fixture's daemon-creation boundary
was changed to call the native one-shot component.

- Writer SHA256: `657f780c53d2cc69e47b16a4b28954003a3fdfcf9397d551db779ac0f8bed0a4`.
- Materializer SHA256: `39e7872ab387457c477da318a271776ae4c9fc565e12af0f26ba2c8d072cc16a`.
- File helper AST SHA256: `f9f9ec59e4a1c4966898f7fbcda8f3f1ac2c83bac968f63a9a7a720d1f3654b1`.
- command.ps1 SHA256: `21d77bebdd91443e826e4b36bed5eba1e2b4d876750c12746527ea53d2a94cf4`.
- leaf.ps1 SHA256: `3f4e3c842fd9ff8dd41782c36f13360dbc3ab6bdea18029da662e5fd26028066`.

Prior sandboxes are unchanged: `995de5da` 91 files; `a67ea4b3` 43 files, exact
path/size/hash preservation. Final shipped-source hashes, HEAD and index match
their starting values. No product source, immutable generation, real project,
real candidate, package reference, Git commit/export or remote state was changed.

## Build and execution gates

Installed MSVC 19.51.36244.0 / tool directory14.51.36231 and Windows SDK10.0.26100.0.
Compiler and linker SHA256, complete arguments, source and binary hashes are in
`build/build-identity.json`. Build uses `/MT /O2 /W4 /WX /EHsc /utf-8 /Brepro`, x64.
`dumpbin /headers` and `/dependents` were checked before executable invocation:
x64, **KERNEL32.dll only**, no new runtime DLL dependency.

- Native source SHA256: `9ed650ef62ecf5e020acff82dffffd28f7c6f7bd3d1a9296b7a8cf8efbf6d818`.
- Native binary SHA256: `6d1ec230841951f2c80e8b8a0ffd3a385a4abff394690cc69e367a102f3544a3`.
- Binary size:154624 bytes.
- Compiler SHA256: `9cf613fcbebece019712511eec4b1a32d0a9c94e65249a1aeb326305c2388d6b`.
- Linker SHA256: `101461b51a18daaf033cb743690e20b449e9ac8783638e961bb65c5fd36e9cb5`.
- WinPS5.1.19041.6456; Node v24.14.1.

The component passes an explicit executable and cwd to CreateProcessW, quotes each
argument, sets bInheritHandles=FALSE and DETACHED_PROCESS|CREATE_NEW_PROCESS_GROUP,
closes returned process/thread handles and exits. Exit0 means creation only. The
Node CLI independently awaits its token/PID-bound fixture readiness file and checks
argument/cwd transfer before declaring readiness. This fixture does not claim to
exercise the real authenticated coordinator protocol.

One permitted build/harness correction was consumed before any binary/scenario
execution: PowerShell option concatenations in an array needed explicit grouping.
The initial compiler D9024 warning became a WinPS NativeCommandError before the
build log was saved. The exact initial tool output remains in the session;
`build-correction.md` preserves its cause and scope. Corrected argument grouping,
native-stderr capture and WinPS non-ASCII source-literal handling together; no
mechanism redesign, scenario retry or second correction. Successful build log is
retained. The first invocation did not produce root-level obj/exe/pdb/ilk files.

Build objects/executable, TEMP/TMP and fixture LOCALAPPDATA stay sandbox-local.
Environment overrides occurred only in child processes. No HOME/CODEX_HOME or
global configuration change; no download, runtime Add-Type compilation, elevation,
network service, OS registration, Unity launch or real Provider/MCP operation.

## Scenario results

Three scenarios, normal first, each executed once. Each stayed under60seconds;
retaining processes had35second self-expiry. No kill or unrelated-process scan.

| Scenario | Native elapsed / exit / incomplete | Actual Manager elapsed / command exit / incomplete | External writer EOF | Expected result |
| --- | --- | --- | --- | --- |
| Normal isolated daemon | 549ms / 0 / false | 1011ms / 0 / false | 1596ms from observer launch | PASS while exact daemon alive |
| Missing sandbox executable | 440ms / 70 / false | 817ms / 70 / false | 1339ms | PASS: Win32 error2 and exit70 propagate |
| Upstream retained-output control | 5498ms / 0 / true | 10866ms / 6 / true | 36226ms, after retainer self-expiry | PASS: original bounded incomplete-output rejection retained |

Native and Manager elapsed values use their own clock origins; external EOF uses
the outer observer clock. Complete observer durations:1988ms,1586ms,36508ms.

### Normal live-at-completion proof

The observer persisted native, terminal and external EOF checkpoints independently.
It never waited for observer EOF before recording the earlier checkpoints. Partial
state was saved every iteration and final results/output saved in a finally path.
All PowerShell fixture files were parsed before the first scenario.

Exact daemon PID50616, start ticks639270636830128193, executable
`F:/Program/nodejs/node.exe`, token`9f17cd3f2ec74b0ab78cc372277c4bbf`:

| Checkpoint | Daemon observed alive UTC | Observer ms |
| --- | --- | --- |
| native result persisted and complete | 2026-10-08T13:41:23.2074622Z |1489|
| actual Manager terminal persisted and complete | 2026-10-08T13:41:23.2892909Z |1582|
| actual writer exited, both external streams EOF | 2026-10-08T13:41:23.3042511Z |1596|

PID and process start time were cross-checked against native CreateProcess output
and token-bound fixture readiness. Only after all three checkpoints passed was a
cooperative stop written. Daemon recorded cooperative exit at13:41:23.382Z. Success
did not depend on daemon expiry or forced termination.

Argument transfer included spaces, Chinese text, embedded quote, trailing slash,
empty string and slash-before-quote; exact arrays matched in the running daemon.
Cwd was the sandbox directory `daemon space 中文`, confirmed by the child.
Evidence: `normal/ready.json`, `launcher-result.json`, `spawn.json` and checkpoints.

### Failure and retention controls

Missing target was the exact nonexistent sandbox path
`missing/missing-child.exe`, not a system executable. Native launcher emitted
`LAUNCH_CREATE_FAILED win32=2`, exited70, and no daemon readiness was produced.
CLI, leaf, native collector and actual Manager retained exit70 with complete output.

Retention control spawned a separate fixture-only detached Node child with inherited
stdio upstream of the isolated launch boundary. No unsafe inheritance switch was
added to the native component. At native and Manager completion, both daemon21520
and retainer21476 were independently alive. Native observed exit0 but correctly
reported incomplete output, and the actual writer persisted exit6/incomplete.
External EOF waited for the deliberate retainer's35second self-expiry; this is
evidence of retained rejection, not a normal-path success claim or timeout extension.
Retainer and daemon self-expired, no cooperative stop or kill in this scenario.

## Final audit and retained evidence

`final-process-audit.json`: **18 recorded fixture roles, zero PIDs present**.
Short-lived launchers were identified from spawnSync's returned child PID; their
start times were unavailable after exit, explicitly null in audit. All observed
longer-lived roles retain exact start ticks and token. Audit queried only recorded
fixture PIDs. No survivor requires cleanup.

`file-inventory.json` lists93 files with size/SHA256, excluding itself. Core evidence:

- `identity.json`, `build/build-identity.json`, `build/gate.json`, import/header logs.
- `normal|missing|retained/result.json`, `native-result.json`, actual compact Manager
  receipts, stdout/stderr, independent checkpoints and continuously saved observation.
- `summary.json`, `final-process-audit.json`, `source-recheck.json`.
- Both prior `*-before.json` snapshots and `prior-preservation-check.json`.

Hashes:

- run.ps1: `248236adbfc20b5779665988d67c2e5974a4d99557360b40d219c950be4b579e`.
- service.mjs: `d2bccc9b6d7e6e555fd3cf46d6addfba18c60166835bab2a365bd6741eb1ba03`.
- file-inventory.json: `7ed4039be3593c3a5ba40d2afb1866e91450acd44a5df9ab5d40ba571265b30e`.
- final-process-audit.json: `bfd69aef428759cbb6e3cbbee203e5b9aa37df83ac66e14797ac453e6c4ea7cd`.
- summary.json: `6467dc0960768468c1f995ba1c16c9d34ded24585fe3930c901dfd132e866482`.

## Meaning and limits

Compared with both previously failing normal detached paths, this one-shot native
boundary gives a concrete local advantage: the actual shipped collectors complete
while the daemon lives, without weakening failure semantics. The same mechanism
keeps argument/cwd transfer and does not add a resident owner.

This supports integration planning, not production acceptance. Exact historical OS
handle ownership remains unproved; the POC did not inspect a live failed candidate.
Real watcher/coordinator integration, authenticated readiness, package binary review,
successor-generation identity/closure, architecture support and release reputation
remain later work. The observed poc.40 and failed candidate remain untouched.
Do not automatically retry/adopt the failed Install, export a Package, or claim S29
accepted. Missing progress indication remains its separately scoped follow-up.

## Parent assessment - 2026-10-08

Decision: APPROVE_FOR_INTEGRATION_PLANNING / BOUNDED_POC_COMPLETE.
Parent read the stable report, launcher/fixture/observer source, build identity,
dependency log, native results, actual Manager terminals and saved checkpoints.
All93inventory files match length/SHA256. All3recovered native/terminal pairs match
their independently saved original records. Normal checkpoints bind PID50616,
creation time and token and precede the cooperative stop at observer1622ms.
The negative controls preserve creation failure and incomplete-output failure.
Saved final audit contains18roles, all absent. Parent independently rehashed both
prior sandboxes:91+43files, zero mismatches or count changes. Delivered writer and
materializer hashes still match; HEAD remains d56f0e507b48af24a39f23411c06dbdd4e093084,
index empty, and product Editor/Tools~/Payload~/Tests paths have no tracked diff.

No process scenario or compilation was rerun during this assessment. One permitted
pre-execution harness correction and its evidence limits remain recorded above.
There is sufficient evidence for the narrow Windows x64 output-isolation mechanism,
not for a production launcher or real authenticated coordinator integration.
Close the POC window. Next work must bind this mechanism to the existing launch,
identity, readiness, generation and release contracts as one coherent integration
task. Product source development requires its own scoped Coder/Verifier sequence;
no replay/adoption/cleanup of the real failed candidate follows from this result.
