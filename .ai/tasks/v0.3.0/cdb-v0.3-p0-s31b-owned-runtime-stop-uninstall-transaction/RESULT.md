# S31-B Coder Result

## Outcome

- Status: `PARTIAL / NOT_ACCEPTED`.
- Terminal disposition: `COMPLETE / INFRASTRUCTURE_FAILURE_CLASSIFIED` for
  the executed setup/managed-producer evidence. The S31-B objective is not met.
- Original materializer entry can create an installed fixture. The managed
  request-producer join to that installed fixture did not yield an admitted
  request, so the dependent Uninstall/owned-stop/transaction chain was not run.
- No S31-B production fix was made. This checkout is an attributed composition
  of accepted base plus unaccepted A2 input bytes, not accepted source.
- Coder stopped on Planner's instruction to consolidate, without additional
  semantic attempts or a request/schema bypass.

## Execution identity

- Base and final HEAD: `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`.
- Checkout: `.worktrees/cdb-v0.3-p0-s31b-owned-runtime-stop-uninstall-transaction/`.
- Evidence root: `.artifacts/tests/cdb-v0.3-p0-s31b-owned-runtime-stop-uninstall-transaction/`.
- Model and reasoning settings: inherited from the parent task; no exact
  platform-reported model/effort name was exposed to this Coder. No override,
  recursive delegation, commit, export, reference switch or Unity was used.
- Active profile: `v0.3.coder.deep / DEEP_60M`.

## Input binding and stable snapshot

- Accepted Package witness SHA256 remains
  `78cc1bea38e9a9ca5f057a916b5ea78c9a4427905d682c242dce52e430cdb08c`.
  The existing review tree was read; no new export/extraction was performed.
- A2 source manifest binding:
  `ed75b9542451747ce8e75860419122e6d4800a380dde8be2e9d925f1209e3224`.
- A2 generator copy binding:
  `7e89f7e8bbc69ad02b30db4c10783f789bfb0195b5d2da8ac7e5e06a729f6764`.
  It was copied and hashed, not executed. No metadata was hand-patched.
- Copied all 47 non-document source/test/metadata entries from A2, then
  verified every destination against its declared hash. These include frozen
  Manager/Journal/Lifecycle inputs strictly as unchanged dependencies.
  The three historical documentation entries were not copied over the current
  workflow. Final source remains byte-identical to those 47 A2 entries.
- Verified all 476 protected payload entries against the accepted review tree
  and against the new checkout. A separate evidence copy is retained in
  `input/protected-payload/`; immutable predecessor bytes were not edited.
- The checkout already had three dirty predecessor paths when assigned:
  poc.42 generation manifest/common script and poc.43 common script. They were
  preserved. This result does not attribute those pre-existing changes to S31-B.
- `input/INPUT-MANIFEST.json` SHA256:
  `b3dd112979902a177dd9f7eb6cc82e45c93e857f66f438a337a4fec43c5cb5c4`.
- `FINAL-MANIFEST.json` SHA256:
  `e86b726e00288b44516b6cf7cebb7b05dc049e45815840b6e77138db1cd35214`.
  It lists 47 final source hashes, 476 protected matches and 542 evidence files.
  It intentionally excludes its own bytes; RESULT is outside that artifact set.

## Executed evidence

| Check | Result | Scope and limit |
| --- | --- | --- |
| Attributed A2 input copies | PASS | 47/47 listed source bytes match A2, not a source accept. |
| Protected payload | PASS | 476/476 byte identities match; no runtime claim. |
| Original materializer `ValidatePayload` | PASS | 90 files admitted; runtime contract `525202b6110587375d154338e21598cb9ae8da4d5325da7a28a3b57ab12a74e3`. |
| Original materializer `Install -PocFixture` | PASS | Created installed state with the original entry and original writers; candidate probe is explicitly deterministic fixture evidence. |
| Original C# producer on an empty short fixture | PASS WITH LIMIT | Existing compiled A2 Journal admitted request and read Pending; historical binary provenance is not a final-source compile/read proof. |
| Original C# producer on installed fixture | FAIL / setup unclosed | `TryAdmit` returned false, Journal Read returned Conflict; no admitted request for the next gate. |
| Node syntax, four relevant files | PASS | Supervisor, successor coordinator/host-use gate/instance worker only. |
| PowerShell parse, five relevant files | PASS | Materializer, engine, wrapper, successor watch/common scripts only. |

### Original-entry setup

The owned project is under
`replacement-fixture/AIWork/.runtime/codedb/materializer-poc/a11ff5030f404c98b4ea03b9293ceef2/uninstall-fixture/`.
It has the existing reviewed fixture layout/ownership marker and Unity project
markers. No real Unity project was opened or changed. Its marker/configuration
is new test setup, not forged installed authority.

The executed original entry was the new checkout's
`Tools~/materialize-codedb-host-payload.ps1 -Action Install -ProjectRoot <owned-project> -PayloadRoot <new-checkout>/com.rice.ai-codedb/Payload~ -PocFixture`.
Exit was 0. Original output included:

```text
[INSTALLING] Published immutable generation poc.44.
[PHASE CANDIDATE_VERIFY] READY - deterministic fixture evidence.
[RESULT] INSTALLED
[INSTANCE] 16cb1f16e5684b92b7a09c3a3c580000
[CLEANUP_STATE] COMPLETE
```

The original command result was `INSTALL / INSTALLED / COMPLETE`, reason
`INSTANCE_ACTIVATED`, exit 0. Original writers produced selection, activation,
desired state, instance manifest and MCP registration. The fixture Install
consulted the already-current machine prerequisite read-only; it neither
installed a machine Provider nor ran real candidate/native verification.

`setup-install.log` SHA256:
`c037d8481ef08bea0cff151e57f1cae08bd71425d154f37302fa2d0c1a60cd64`.
`setup-fixture.json` records the exact local fixture locator.

### Managed producer failure and corrections

The first probe invoked the existing A2 compiled protocol test with a new
task-owned fixture. It published a request index but failed the test assertion:
`The published Manager action index failed identity verification.` The fixture
and raw index remain preserved. It was not accepted as final-source evidence.

A task-owned reflection driver, `diagnose-producer.cs`, then invoked the original
compiled Journal `TryAdmit` and `Read`, without inventing request JSON. An empty,
shorter fixture returned `TRY_ADMIT=True`, `READ_STATE=Pending`. The installed
fixture returned:

```text
TRY_ADMIT=False DETAIL=A project-stable Manager action index already exists; a second owner was blocked.
READ_STATE=Conflict
READ_DETAIL=Manager action index validation failed: Could not find a part of the path "<owned-project>/AIWork/.runtime/codedb/instances/16cb1f16e5684b92b7a09c3a3c580000/instance.json"
```

The actual file exists in the original-entry fixture tree. This observation is
insufficient to prove a production defect or a particular path-length cause.
The exact compiled dependency closure and runtime path capability were not
rebuilt/proved for S31-B. No Journal/Lifecycle reader was relaxed or modified.

One diagnostic correction changed the task driver from process LOCALAPPDATA
mutation to the existing `UseManagerActionsRootForTests` scope. The installed
case still returned the same Conflict. No further semantic correction was run.
One malformed diagnostic command (invalid composed output filename) did not
start the target and was a mechanical construction error only. Initial copy
commands also needed correction because the protected list is `path hash`,
and its paths are relative to Payload, not candidate poc.44; their partial
copies were overwritten from the exact A2 47-file set before final hashing.

`transaction-producer.log` SHA256:
`929f108b6b0942308e42d1cf62d4f52c58b21c71f6424da38a3f8188bf7b75d2`.

## Process deviations and evidence exclusions

These issues are reported rather than hidden as passing evidence:

- Scenario/filter names and the final task-owned driver were not frozen into
  a declared scenario file before the first setup run, as TASK required.
- The first managed probe executed an existing runner from the historical
  checkout, and subsequent reflection probes loaded existing historical A2
  Editor DLL bytes. The historical files were not changed, but execution was
  outside the task's repository-local-only execution boundary. Therefore these
  managed observations are diagnostic only and cannot close the requested
  final-source C# producer/reader evidence gate.
- All newly created fixture/configuration/output files remained under the
  repository-local S31-B evidence root. No real receipt store was intentionally
  bound for writes. No cleanup was performed.
- One initial static-check command had the wrong working directory (and
  included an mjs file in a PowerShell parser list); it was a mechanical error.
  Corrected exact lists produced the PASS values recorded above.

## Not run / not claimed

- Original PS Uninstall and repeated uninstall/no-op: UNRUN, dependent on the
  unclosed accepted-request producer fixture.
- Native owned runtime graceful/force/PID-reuse/Unknown/missing-roster exits:
  UNRUN. No synthetic stop markers were substituted.
- Full successor spawn/restart fencing: UNRUN.
- Cooperative writer settlement and original C# terminal receipt reader join:
  UNRUN.
- Deactivation transaction, retained-content postconditions and nearest
  Install/Remove/Repair writer regressions: UNRUN beyond the setup Install.
- Final-source C# compile: UNRUN. Historical compiled binaries are diagnostic
  inputs only and do not prove this new composed snapshot compiles.
- Historical reconnect: DEFERRED non-blocking FOLLOW-UP, unchanged.
- Unity, real S30 install/uninstall, delivery and release: not authorized/run.

## Residual state and handoff

- No task-created runtime fixture child remains to stop: synchronous
  materializer/Mono/compiler invocations returned. The fixture Install used
  deterministic PocFixture candidate verification; no native successor fixture
  was started. Existing external processes were not censused or controlled.
- Retained content: all task-owned fixtures and evidence are preserved under
  the evidence root; the original-entry fixture still represents INSTALLED.
  Do not run real cleanup or Uninstall from it as a consequence of this record.
- Parent may admit this stable partial snapshot for the already-authorized
  read-only Verifier. Review the failed evidence boundary and scope/provenance,
  not as a source-accept candidate or complete S31-B runtime implementation.
- Next implementation decision needs a properly frozen, repository-local
  final-source managed producer/reader fixture with demonstrated path capability.
  Do not retry the exhausted A2 AST/global/GetNewClosure closure, forge request
  authority, or expand Journal/UI/Lifecycle writes to obtain PASS.

## R2 bounded F1 correction — 2026-10-16

Status: `PARTIAL / INCOMPLETE — NOT ACCEPTED`. The managed build and selected
compact-path capability gaps are now closed with current-source evidence.
Installed setup stops at a separate original-entry prerequisite: the deliberately
child-local Provider store has no required Provider. No product source was
changed; no S31-B implementation, installed admission or uninstall success is
claimed. The prior result above remains historical and is not superseded.

### R2 ownership, provenance and compile

- Exclusive owner: `<repository-root>/.artifacts/tests/s31b-r2/`, token
  `6ce64559e1c54212927158a5181e9848`. All new drivers, build/reference copies,
  receipts/local/temp roots, simulated projects and logs are inside this owner.
- Original source remains the S31-B checkout at base/HEAD
  `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`; its inherited 47-file A2 input
  composition is unaccepted and unchanged in this correction. No historical
  CodeDB DLL, executable or runner was loaded or executed in R2.
- `RUN-MANIFEST.json` was frozen before first compile/path/setup execution,
  SHA256 `df3bfa2d45c51f5153e18ebdf13222e5c8bbb84a1d10d6e53409fdef7764936e`.
  It binds exact case names, commands, 30 original Editor source hashes,
  generated RSPs, 219 Unity/framework references, compiler/Mono binaries and
  task-driver hashes. Existing Unity compiler/framework tools were used without
  launching Unity Editor. The prior Bee RSP supplied only compile defines and
  Unity reference layout; no historical CodeDB build output was referenced.
- `S31B.R2.ManagedCompile`: PASS. Original Editor DLL and task friend-assembly
  driver compiled directly, without rewritten source, replacement APIs, shims
  or stubs. The original Editor compile emitted two CS4014 and one CS0414
  warnings; no error. `managed-compile.log` and `driver-compile.log` preserve
  output. New Editor DLL SHA256:
  `a1d563378502afb6fb60026bfd552b5eb4864b525e5befbe53ac2e6d90ec53ab`.
- Child environment was explicitly scoped to owner-local TEMP, TMP,
  LOCALAPPDATA and MONO_PATH. No parent/global environment setting was changed.
  The inherited exact model identifier is not exposed to this task; no model
  override or recursive delegation was used.

### R2 path capability

`S31B.R2.PathCapability`: PASS for the selected compact owner and both explicitly
recorded project locators. The newly built driver executed under the bound Unity
Mono binary, called original `GetManagerReceiptRequiredPaths` and performed
create-new/write/flush/read/delete probes for receipts plus instance manifest,
instance publication temporary file, transaction backup and rollback publication
suffix paths. All selected-root probes passed. The longest original-driver path
was 255 characters; the corrected actual project locator's longest path was
254. No OS setting or fallback root was used.

The same process attempted an exact read-only `File.ReadAllBytes` on the
preserved historical 292-character instance locator. It returned
`System.IO.DirectoryNotFoundException`; this diagnostic is preserved in both
path logs. It demonstrates that runtime/API observation, not arbitrary path
support or a product root cause. Historical fixture contents were not changed.

### Setup attempts and bounded mechanical corrections

All three original materializer Install attempts returned exit 4 in PREFLIGHT,
with command result `BLOCKED`, `mutated_scopes=[]`, `cleanup_state=COMPLETE`.
No installed authority, selection, activation or candidate was produced in R2.

1. Initial `run-r2.ps1` setup used a driver-typed 33-character fixture run id.
   Original `Assert-PocMutationTarget` correctly rejected it because its reviewed
   layout requires 32 hexadecimal characters. `original-install.log` preserves
   this failed attempt. This was a task-driver construction mistake.
2. Mechanical correction 1: `run-r2-c1.ps1` explicitly selected a 32-character
   id inside the same compact owner, preserved the original driver/manifest/log,
   and froze `RUN-MANIFEST-C1.json` before execution. SHA256:
   `0fe875856fee83cfa5a19c2c00e9a7ce6789ca945f4a6514046c45fcf47e5f6e`.
   Corrected actual locator probes passed. Install then correctly rejected first
   Install because the probes had deleted files but left empty `instances` and
   `control/operations` directories. Original `Test-InstanceFirstInstall`
   explicitly disallows those pre-existing paths. `original-install-c1.log`
   preserves this separate task-driver cleanup omission.
3. Mechanical correction 2: `run-r2-c2.ps1` froze
   `RUN-MANIFEST-C2.json` including the existing empty-directory inventory and
   exact bottom-up deletion order. SHA256:
   `e76c0afd89652b2745bf1282cc9ebb15afcd85750eef0c5416ad06481f573bcd`.
   It revalidated containment, ordinary-directory status and emptiness before
   each non-recursive `Directory.Delete(path,false)`. Ten task-created empty
   probe directories were removed; no file or nonempty directory was deleted.
   `probe-directory-cleanup-c2.log` records all targets. Original fixtures,
   manifests, driver versions and failed-attempt logs remain preserved.
   This exhausts the two mechanical corrections for this setup case.

After correction 2 the unchanged original entry reached its real prerequisite
check and returned `PROVIDER_MISSING` for Provider `0.5.0-28e3912-c2` under the
explicitly isolated child LOCALAPPDATA. See `original-install-c2.log`.
The prior first-round Install had consulted an existing machine Provider store;
its successful setup is not proof that this fresh isolated local store contains
that prerequisite. R2 did not copy or install a Provider, reuse the machine
LOCALAPPDATA, synthesize Provider authority, bypass the original guard, set a
handwritten UNINSTALLED state, or retry after this boundary.

### Actual gate outcome and limits

| Gate | R2 evidence |
| --- | --- |
| Current original managed source compile | PASS, 30 source / 219 reference closure |
| Same Mono / exact compact path capability | PASS; long-locator diagnostic failure preserved |
| Original isolated installed setup | BLOCKED: PROVIDER_MISSING; no installed authority |
| Original Journal installed admission / absent and mismatched-owner checks | UNRUN: all reside in gated chain |
| Original PS/Node Uninstall and deactivation | UNRUN |
| Retained-content removal postconditions / repeat no-op | UNRUN; only untouched fixture user-content input exists |
| Actual terminal producer -> original C# consumer | UNRUN |
| Native graceful/force/PID-reuse/Unknown/missing-roster and no-restart cases | UNRUN |
| Nearest Install/Remove/Repair shared-writer semantic regressions | UNRUN beyond blocked setup |
| Unity, real S30 project, delivery or release | Not authorized / UNRUN |

There is no demonstrated product BLOCKER from these setup failures. F1's overall
installed producer/reader evidence gap remains open despite the narrower compile
and path progress. Native/runtime/transaction evidence is not replaced by this
static/component PASS. Historical reconnect remains deferred and unchanged.

### Stable R2 handoff

The original-entry prerequisite stop condition applies, so dependent cases were
not started and no further correction route was invented. All compiler/Mono/PS
children launched in R2 returned synchronously. No task-native runtime process
was launched; existing external processes were not censused or controlled.
The removed empty probe directories were temporary setup scaffolding, recorded
in the cleanup log and reproducible from the preserved path-probe driver.

`FINAL-MANIFEST-R2.json` under the compact owner binds this appended RESULT,
unchanged 47-file source composition, original 30-source managed closure,
references/tools, all new evidence, and verification of the historical 542-file
evidence set and original FINAL-MANIFEST. The parent may admit this stopped
partial snapshot for targeted read-only Verifier review. No source ACCEPT,
commit, export, reference switch or Unity acceptance is implied. Further setup
authority or product changes require a concrete user disposition of this
prerequisite; the exhausted mechanical allowance is not renewed by a new label.

## R3 isolated Provider prerequisite and chain — 2026-10-16

Status: `PARTIAL / INCOMPLETE — NOT ACCEPTED`. R3 closes the owned Provider,
fresh original installed setup, current-source installed request producer/reader
and actual failed-terminal C# consumer gaps. The original Uninstall was executed
once and refused before deactivation because the fixture's selected instance has
no Provider config. No product source was changed, and no successful uninstall,
native runtime stop, repeat no-op or complete S31-B acceptance is claimed.

### Frozen ownership and current-source binding

Exclusive owner: `<repository-root>/.artifacts/tests/s31b-r3/`, token
`023ef5050fd14a93932001f17bb07bfd`. The five TASK scenarios, exact entry files,
Provider input/destination hashes, source/build/tool closure, child environment,
probe cleanup and repeat route were frozen before first execution in
`RUN-MANIFEST-R3.json`, SHA256:
`3455c510748a713663c67ad073f7527656786c20a999b7457bcd03e2f3fedb2c`.

The unchanged 47-file source composition and all 30 original managed source
hashes bind to R2. The R2 current-source Editor DLL was checked against its final
manifest and copied into R3 build output, SHA256
`a1d563378502afb6fb60026bfd552b5eb4864b525e5befbe53ac2e6d90ec53ab`.
Only the new `managed-fixture-r3.cs` driver was compiled against that original
DLL and the same 219 verified Unity/framework references. No historical A2
CodeDB build was loaded, and no unchanged full Editor compile was repeated.
R2's 249 evidence files and final manifest were checked unchanged before reuse.

Tool-freeze limitation: the pre-execution tool hash set inherited from R2 covers
Mono, dotnet and csc. Node and Windows PowerShell were resolved through the
original runtime path/normal application lookup, but their executable hashes
were not frozen before execution. Their final hashes are recorded as post-run
attribution only, not retroactive pre-execution proof. This is a declared
workflow-evidence deviation; no extra unchanged execution was used to hide it.

All R3 outputs and child TEMP/TMP/LOCALAPPDATA/MONO_PATH remain under the R3
owner. No global or parent environment setting was changed. The inherited exact
model identifier is unavailable; no override, recursive delegation or Unity
Editor launch occurred.

### Provider input and original reader — PASS

Required version was derived from the bound original machine-provider contract:
`0.5.0-28e3912-c2`. Source closure was exactly the three permitted regular files,
with no reparse traversal. Each source SHA was rechecked before byte copying,
then source and destination hashes compared:

| File | Source and owned-copy SHA256 |
| --- | --- |
| codebase-mcp.exe | `38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7` |
| provider-manifest.json | `82bdc9508e05f1fae0ad013a96d88fd4e5c336c48b96a13b00a6d43cc2cb57a4` |
| THIRD-PARTY-NOTICES.txt | `5e69d07d422c858d299e1d51eac4aee820231ae4961151890e00ca278c9894ab` |

Only these bytes were copied from the existing real Provider store into
`local/Rice/CodeDB/providers/<required-version>/`. No source-store executable
was run, no machine installation/update/download/link was performed, and no
manifest field or CURRENT result was synthesized. `provider-copy.json` binds
the exact local locators and both sets of hashes.

One permitted Provider construction correction was used. The initial child
Windows PowerShell failed in the task Hash helper because `Get-FileHash` was
unavailable there, before invoking the original Provider reader or any Install.
The initial `run-r3.ps1`, manifest and `provider-prerequisite.log` are preserved.
`run-r3-c1.ps1` uses .NET SHA256 for that task-only helper without module or
environment changes. Its pre-execution `RUN-MANIFEST-R3-C1.json` SHA256 is
`a5f3e46931254e78e873d742387ced24ee78705dd44684a30fc28dcf82f1b93c`.
The single construction correction allowance is exhausted; R2's two setup
mechanical corrections were not reset or repeated.

`S31B.R3.ProviderPrerequisite`: PASS. Original
`Get-CodedbMachinePrerequisiteStatus` under the explicitly isolated child
environment reported CURRENT / PREREQUISITES_CURRENT, Node.js v24.14.1 and the
required Provider. Its reported Provider root/manifest/executable were checked
against the R3 owned copy. This is prerequisite integrity evidence, not native
runtime lifecycle evidence. See `provider-prerequisite-c1.log`.

### Paths and ONE original Install — PASS

The new Mono driver called original `GetManagerReceiptRequiredPaths` and probed
the exact receipt, instance, publication-temp, transaction-backup and rollback
paths. All 13 actual probes passed; the longest path was 254 characters.
It tracked every directory created by its own probes, then rechecked containment,
ordinary-directory status and emptiness before nonrecursive removal in reverse
creation order. Nineteen empty scaffolding directories were removed, no files
or nonempty directories. `path-probe-cleanup.log` preserves the targets. The
fresh project root was verified absent before materializer setup.

The one newly authorized original Install attempt used a reviewed fixture
marker/layout and `-PocFixture`, never combined with
`-ConfirmedProjectMutation`. It succeeded with original writers:

```text
INSTANCE: 4d7372064f5d43b6837426bfb5331287
INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED / exit 0
mutated_scopes: host_runtime, instance_activation, instance_candidate
cleanup_state: COMPLETE
```

`S31B.R3.PathAndFreshSetup`: PASS. Original selection, activation, desired state,
instance manifest and MCP registration exist. Candidate readiness is explicitly
the existing deterministic PocFixture seam; real Provider/coordinator/adapter
spawning and native availability were not exercised. See `original-install.log`.

### Original installed request admission — PASS

`S31B.R3.ManagedRequestAdmission`: PASS, action
`77d38dbaa5684aec9716ad76a59d4fd1`. Rebuilt original Journal `TryAdmit` emitted
an EXECUTING request for the actual installed fixture, and original
`ReadUninstallRequest` authenticated those bytes. An absent/foreign project saw
no request; a different-Package second owner was refused by the existing accepted
uninstall fence. No handwritten request authority was used. The same managed
request-owner process remained alive throughout its child Uninstall invocation.

### Actual original Uninstall and failed-terminal join

The driver invoked original ProcessRunner with its original admitted action
context. Original wrapper/materializer/Node ran and produced actual admitted,
claim, checkpoint and terminal records under the owned receipt store. Uninstall
returned:

```text
UNINSTALL / BLOCKED / PREFLIGHT / MATERIALIZER_EXIT_1 / exit 1
mutated_scopes: []
cleanup_state: COMPLETE
detail: selected Provider config was not found: <selected-instance>/config/codedb-mcp.toml
```

The command was not retried. Original `RecoverManagerAction` authenticated its
actual terminal and returned Terminal with authoritative exit 1. The emitted
checkpoint was CANCELLED_SAFE, no_more_mutations=true, journal_operation_id=null;
the terminal reported timed_out=false and no output overflow/drain loss.
`S31B.R3.TerminalReaderJoin`: PASS for truthful failed-result consumption. This
does not establish an UNINSTALLED postcondition or success of
`S31B.R3.TerminalReaderAndRepeat`.

Exact logs: `S31B.R3.ManagedRequestAdmission.log`, `managed-chain.log`,
`uninstall.stdout.log`, `uninstall.stderr.log`, `uninstall-result.log`,
`terminal-reader.log` and `S31B.R3.TerminalReaderJoin.log`. Original receipt stage
is `29e5c144f76a8048f0235d8bca8b4d6e488cf32f964aeb23f258bdfab9d460ba`.

### Bounded read-only cause and stop

The selected config locator is 221 characters, and both PowerShell and .NET
confirmed the file is actually absent. The selected instance contains its
manifest, deterministic `index/fixture-ready` and `adapter/fixture-ready`, and
availability evidence; its config file was not generated.

The original engine's PocFixture branch (`codedb-instance-engine.ps1`,
2774–2797) skips the real prepare-runtime/build-adapter/watch-manager calls.
Original Uninstall nevertheless calls Node `runOwnedRuntimeStop`, which first
calls `buildContext`; `codedb-project-supervisor.mjs:261` unconditionally requires
the selected Provider config before reaching request-owner/native-stop checks.
Thus the declared deterministic fixture setup does not supply a prerequisite
of this actual consumer path. No native stop or deactivation operation was
reached. This is an attributable fixture/consumer evidence boundary; it is not
proof that normal fully prepared real installations have the same defect.

Product source is read-only in R3. No config was fabricated, no extra prepare
entry or native setup was added, no guard was bypassed, and no product fix or
equivalent renamed retry was attempted. Per TASK, the unavailable original-entry
prerequisite stops the dependent path and returns this concrete dependency to
the parent/User for disposition.

### Per-case final outcome and residual state

| Frozen case | Actual R3 outcome |
| --- | --- |
| ProviderPrerequisite | PASS, original reader validates exact owned copy |
| PathAndFreshSetup | PASS, 13 probes, recorded empty-directory cleanup and one original Install |
| ManagedRequestAdmission | PASS, real installed request writer/reader and nearest ownership checks |
| UninstallTransaction | ATTEMPTED / BLOCKED in PREFLIGHT before Node stop/deactivation; not PASS |
| TerminalReaderAndRepeat | PARTIAL: actual failed-terminal reader PASS; successful UNINSTALLED, release and repeat no-op UNRUN |

Native graceful/force/PID-reuse/Unknown/missing-roster, successor restart fencing,
concurrent cooperative-writer settlement and nearest Install/Remove/Repair
semantic regressions remain separate UNRUN gates. There was no new native
fixture scenario, real project operation, Unity/MCP/BatchMode, delivery, commit,
export or reference switch. Historical reconnect remains deferred unchanged.

The original installed selection and INSTALLED desired state remain. The
user-retained input still contains `keep-user-content`; removal/retention
postconditions were not claimed. Original Journal release was not called after
the failed command: its accepted request remains EXECUTING in the preserved
owned fixture, while its managed owner has returned. Do not interpret the
fixture as clean or automatically resume/reconcile it.

All R3 compiler/Mono/PS invocations and the invoked Node error path returned.
No fixture runtime successor was launched; existing real/external processes
were not censused or controlled. Provider copies, installed fixture, receipts
and all successful/failed logs are retained inside the R3 owner. Removed empty
probe scaffolding is reconstructible from the frozen driver and cleanup log.

`FINAL-MANIFEST-R3.json` binds unchanged source, original managed build closure,
the three unchanged real Provider inputs and owned copies, all new evidence,
appended RESULT, and preservation checks of R2 and first-round evidence.
The parent can admit this stopped partial snapshot for the already authorized
targeted read-only Verifier. The broader S31-B transaction/native acceptance is
still incomplete; no source ACCEPT or release conclusion is implied.

### R4 production preparation route — 2026-10-16

Status: `PARTIAL / BLOCKED — NOT ACCEPTED`. R4 used a fresh repository-local
simulated project and the original production preparation route. It did not use
`-PocFixture`, did not handwrite Provider config, modify product source, touch
S30/Unity, or control existing external processes. The original production
Install guard and candidate watcher path were exercised once under child-local
environment; the route stopped at an authentic watcher readiness failure before
selecting a candidate.

R4 owner: `<repository-root>/.artifacts/tests/s31b-r4/`, token
`f7a0c2a94cbb4bb6a2f0bfe8d51a3b17`. `RUN-MANIFEST-R4.json` froze 47 source
inputs, 30 managed source inputs, 219 references, R3 final evidence and the
current-source Editor DLL. `RUN-MANIFEST-R4-C1.json` preserves a mechanical
correction snapshot, SHA256 `ffad07dc8a641fa3c0e6aaf70945528787311fea7d0ba8a76504b844ab53a1bb`.
The initial freeze accidentally bound the reused R3 DLL path through a JSON
object; it failed before any child or Provider copy. C1 explicitly binds the R3
root. Both manifests and this pre-execution failure remain retained.

Node and Windows PowerShell were hash-frozen before R4 execution:

| Tool | SHA256 |
| --- | --- |
| `F:/Program/nodejs/node.exe` | `58e74bf02fc5bbacc41dcb8bef089961cd5bd...` |
| `C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe` | `9785001b0dcf755eddb8af294a373c0b87b2498660f724e76c4d53f9c217c7a3` |

The full Node SHA is preserved in `RUN-MANIFEST-R4-C1.json` and final manifest.
The exact R3 Provider three-file copy was reused into R4's owned local store,
with source/destination hashes rechecked. The R3 managed driver and current
source Editor DLL were reused only after R3 final-manifest binding.

`S31B.R4.ToolFreeze`: PASS. Source, reference, tool, Provider and prior evidence
hashes matched; child TEMP/TMP/LOCALAPPDATA/MONO_PATH and the simulated project
root were bound below the R4 owner.

The first original Install invocation, without second-level confirmation,
returned PREFLIGHT/BLOCKED/MATERIALIZER_EXIT_4 with `mutated_scopes=[]`:
`Install requires the Package Manager's second-level project mutation
confirmation.` This is preserved as `original-install.log` and produced no
project mutation.

The one authorized owned-project confirmation then invoked the unchanged
original entry with `-ConfirmedProjectMutation` (never `-PocFixture`). Production
prepare generated runtime/config and watch config, built the text adapter and
launched the exclusive candidate watcher. Provider index refresh completed. The
candidate coordinator became stale waiting for readiness after 120000 ms:

```text
INSTALL / BLOCKED / CANDIDATE / INSTANCE_CANDIDATE_FAILED / exit 6
mutated_scopes: host_runtime, instance_candidate
cleanup_state: PENDING
detail: Timed out after 120000 ms waiting for coordinator readiness.
```

No candidate was selected and no `INSTALLED` authority was published. Original
candidate cleanup reported the expected coordinator lifecycle as stale and left
the candidate/host runtime closure pending. The output, generated configs and
production route are preserved in `original-install-confirmed.log`.

Durable coordinator state classified all started roles as `OWNED` for this exact
R4 project identity and recorded executable/argv/start identities:

- coordinator PID 39976, Node, start identity `639277549189521370`;
- Provider PID 4316, R4-owned `local/.../codebase-mcp.exe`, start identity
  `639277549204642400`;
- adapter worker PID 55136, Windows PowerShell, start identity
  `639277549200614830`.

The read-only post-run query found all three PIDs absent. No force termination or
PID-only action was attempted. Durable evidence is `OWNED / EXITED`; live OS
identity is `NOT_PRESENT`, so graceful-exit proof is not claimed. The candidate,
generated config, coordinator state, lease, index and logs remain under R4.
No automatic cleanup, recursive delete or uninstall was run after the failed
Install.

| Frozen case | R4 outcome |
| --- | --- |
| ToolFreeze | PASS |
| ProductionPrepareAndInstall | PARTIAL/BLOCKED: authentic preparation and watcher route, readiness timeout, no selected authority |
| ManagedRequestAdmission | UNRUN: no installed authority |
| OwnedRuntimeStopUninstall | UNRUN |
| TerminalReaderRetentionRepeat | UNRUN |

The new original Install attempt is exhausted. No additional retry, watcher
recovery, synthetic config, direct PID kill, real Uninstall, source fix or
renamed equivalent scenario is authorized. Native lifecycle gates remain UNRUN.
R1/R2/R3 evidence and failed fixtures remain preserved.
