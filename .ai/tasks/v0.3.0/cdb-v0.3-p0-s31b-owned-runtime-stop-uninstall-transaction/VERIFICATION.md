# S31-B Read-only Verification

## Disposition

- Review: `COMPLETE / READ_ONLY_VERIFICATION`.
- Product task: `PARTIAL / NOT_ACCEPTED`; the S31-B objective remains unmet.
- The stable result accurately separates original-entry fixture setup from the
  unclosed managed request and unexecuted downstream lifecycle. No source
  acceptance, delivery, Unity or real-project lifecycle PASS is supported.
- No demonstrated product BLOCKER was established by this bounded review.
  The evidence gap below prevents acceptance; it is not proof that the normal
  product uninstall path is broken.
- Coder was terminal before admission. This Verifier performed one read-only
  batch, ran no tests, controlled no processes, contacted no Coder, and edited
  only this file. Exact platform model/reasoning settings were not exposed;
  settings were inherited with no override. Profile: `v0.3.verifier.deep / 30M`.

## Frozen identity and inspected scope

- Checkout: `.worktrees/cdb-v0.3-p0-s31b-owned-runtime-stop-uninstall-transaction/`.
- Base and observed HEAD: `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`.
- Evidence root: `.artifacts/tests/cdb-v0.3-p0-s31b-owned-runtime-stop-uninstall-transaction/`.
- Reviewed TASK/RESULT, current development workflow and test-workspace contract,
  the bound manifests, setup/producer logs and records, diagnostic driver, and
  directly relevant original Journal/Paths/materializer guards. No full-product
  audit or speculative process-stop review was performed on the unrun chain.
- RESULT SHA256:
  `61b3e25705073ef5ec009f36d414ea91c8958e16f29d4b7154aab1139f87dabb`.
- FINAL-MANIFEST SHA256:
  `e86b726e00288b44516b6cf7cebb7b05dc049e45815840b6e77138db1cd35214`.
- INPUT-MANIFEST SHA256:
  `b3dd112979902a177dd9f7eb6cc82e45c93e857f66f438a337a4fec43c5cb5c4`.
- Copied generator SHA256:
  `7e89f7e8bbc69ad02b30db4c10783f789bfb0195b5d2da8ac7e5e06a729f6764`.

Independent read/hash checks found 47/47 final source entries and 542/542
evidence entries matching FINAL-MANIFEST. All 476 protected entries matched
INPUT-MANIFEST in each of the new checkout, accepted Package review tree and
bound evidence copy: 1,428 comparisons, zero mismatches. The three predecessor
paths reported dirty by Git are included in this byte agreement. Their Git
status is not evidence of a new S31-B repair or accepted-payload modification.

The 47 source entries remain attributed A2 WIP inputs, not a new implementation
or accepted successor. The independent review did not recompile those inputs,
execute the generator, extract a Package or rerun Coder's checks.

## Evidence assessment

| Claim | Assessment and limit |
| --- | --- |
| Original `ValidatePayload` admission | Preserved log reports PASS, 90 files and runtime contract `525202b6110587375d154338e21598cb9ae8da4d5325da7a28a3b57ab12a74e3`; static admission only. |
| Original `Install -PocFixture` setup | Log and generated instance/activation/selection records support installed fixture setup. Original guards require reviewed fixture layout, ownership marker and no reparse escape. Candidate READY is explicitly deterministic fixture evidence, not native runtime acceptance. |
| Empty managed fixture | Preserved diagnostic log reports TryAdmit=True / Pending. Historical compiled dependency provenance does not establish a final-source production-writer/reader PASS. |
| Installed managed fixture | Preserved log reports TryAdmit=False / Conflict. An admitted request for this fixture was not established. The failure occurred before original PS Uninstall or owned-runtime stop. |
| PS/Node parse checks | Coder-reported static evidence, not rerun here; these do not close managed compile or lifecycle gates. |
| Native stop, restart suppression, writer settlement, uninstall transaction, repeat/retention and C# terminal-reader join | UNRUN. No conclusion about their runtime correctness is supported by this review. |

The setup log reports machine prerequisites CURRENT. The materializer setup
uses the original fixture path and marker; its project outputs remain beneath
the recorded task-owned root. No evidence of machine Provider installation or
real-project configuration mutation was found in this bounded packet. There
was no before/after machine-state audit, so this is not a machine-wide clean-state
certification.

## Consolidated finding

### F1 — Evidence gate: attributable final-source managed setup remains unclosed

Priority: `P2 / EVIDENCE_GAP`, no demonstrated product BLOCKER.

The requested chain requires original C# request bytes for the installed
fixture before PS Uninstall, native stop and deactivation. The actual first
managed probe used a historical runner; the subsequent reflection driver used
historical Editor DLLs. The saved response file also references the historical
A2 Editor reference assembly. Consequently neither the shallow Pending result
nor installed Conflict proves behavior of a newly compiled S31-B final-source
dependency closure. RESULT correctly excludes these from acceptance evidence.

The installed fixture's instance manifest exists under the exact reported
locator; its current absolute locator is 292 characters long. The preserved
managed error says that part of that path could not be found. File existence
and this static length are relevant setup facts, but do not identify which
runtime/API/dependency caused the failure. No target-runtime deepest-path
capability result is preserved. Do not label this as a proved path-length
product bug, fix the Journal reader, or weaken request validation on this basis.

User/Planner disposition is required before further work. If continuing the
same objective, first freeze a repository-local producer/reader fixture,
compile its actual final-source closure, and establish its real consumer-path
capability before a semantic attempt. Preserve this failure and its attempt
history. Do not retry the exhausted A2 extracted-closure scenario, create
request authority by hand, or treat this recommendation as authorization to
run a new test or expand the source allowlist.

## Disclosed process deviations and safety limits

- Pre-execution scenario/filter/driver freezing was required but absent.
  Historical runner execution and historical DLL loading also crossed the
  repository-local execution boundary. These are confirmed deviations already
  disclosed by Coder. Excluding their results avoids an invalid acceptance
  claim; it does not retroactively make those executions compliant. A future
  attempt must bind its entry, input assembly/source hashes, owned roots and
  child environment before execution.
- The first managed test source temporarily selects task-owned LOCALAPPDATA;
  its preserved index is physically under the task's `local/Rice/CodeDB/manager-actions`
  tree. The original Paths reader selects process LOCALAPPDATA when no test
  scope is present. The final diagnostic source instead uses the existing
  `UseManagerActionsRootForTests` scope. Installed diagnostic residues inspected
  here are task-owned `index.lock` files. These observations do not establish
  a real machine receipt write. Full isolation of every historical invocation
  is not independently proved by a retained invocation/environment transcript;
  no machine scan or cleanup was undertaken to invent that proof.
- No native runtime-stop scenario was executed. Process absence, termination
  identity and safe-force behavior therefore remain unproved, rather than
  certified safe by hashes or the synchronous setup log. Coder reports its
  synchronous children returned; this review did not census external processes.
- Historical reconnect stays a deferred, non-blocking FOLLOW-UP. No UI,
  SupervisorBridge, real project, delivery or Unity scope is reopened.

## Completion routing

Current task: S31-B owned-runtime stop and uninstall transaction.

Current status: review COMPLETE; product PARTIAL / NOT_ACCEPTED.

Next notification: current parent Planner; return this finding and the disclosed
execution deviations together to User.

Next action: choose the bounded final-source managed-fixture route, or defer/stop;
preserve the installed task-owned fixture and failed evidence without cleanup.

Human decision or authorization required: disposition of the remaining evidence
gap and next execution route. This review grants no source acceptance, repair,
test retry, commit, export, reference switch, Unity or real uninstall authority.

## R2 targeted F1 repair review — 2026-10-16

### Disposition and snapshot

- Review: `COMPLETE / TARGETED_READ_ONLY_REVIEW` of original F1 and its nearest
  R2 evidence only. Earlier findings and their historical evidence remain intact.
- F1: `OPEN / P2 / EVIDENCE_GAP`, partially addressed. Current-source compile
  and selected compact-path capability are now supported; installed setup and
  production request/reader closure remain unproved. Product task stays
  `PARTIAL / INCOMPLETE — NOT ACCEPTED`.
- No new product BLOCKER was established. The observed failures are setup
  construction/prerequisite boundaries, not demonstrated normal uninstall
  failures. No product source repair or source acceptance is implied.
- The Coder was terminal before this review. No tests, processes, machine
  Provider inventory or additional product surface were exercised. Only this
  dated section was appended. Inherited model settings remain unchanged; exact
  platform model/effort names were not exposed. Verifier ceiling: 30M.

R2 owner is `.artifacts/tests/s31b-r2/`; source stays in the original S31-B
checkout at base/HEAD `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`.

- Admitted RESULT SHA256:
  `6976dfc7faa1a66413055952a516fc9a4e15146925f2c10d06b034aba32fdc37`.
- FINAL-MANIFEST-R2 SHA256:
  `0cf37d729124c7194ce7a3b305e5d1e5b6d62c38ed514f2a5263b5ac26074980`.
- R2 rebuilt Editor DLL SHA256:
  `a1d563378502afb6fb60026bfd552b5eb4864b525e5befbe53ac2e6d90ec53ab`.

Independent hashes matched all 47 inherited source entries, 249 new evidence
files, 30 managed source files, 219 references, three compiler/runtime tools and
all original 542 evidence files. All six sets had zero mismatches. The prior
VERIFICATION hash was still `bb5299c8a9573a719aaecc48d2a62d7aaad0b984ec4762b674fe7e4b174508b7`
before this append. Original FINAL-MANIFEST was preserved. Product bytes were
not changed in R2.

### F1 portions now supported

The saved Editor RSP names the 30 actual current-checkout Editor sources and
only the bound Unity/framework references. The driver RSP references the newly
built owner-local Editor DLL and the task driver. The build entries do not
rewrite source or substitute Journal/Paths/System.IO APIs. Compiler logs record
two CS4014 warnings and one CS0414 warning, with no error; the driver log has no
diagnostic. This is a bounded current-source compile result under the frozen
defines/reference/tool set, not Unity import/Editor acceptance.

`RUN-MANIFEST.json` binds exact cases, entries, source/reference/tool/RSP hashes
and child environment. C1 and C2 retain separate manifests, drivers and failed
logs. Inspected manifest/log timestamps and each staged driver's checks are
consistent with freezing before the corresponding build/path/setup execution.
R2 therefore addresses the prior missing scenario freeze and historical-CodeDB
binary execution deviations for this correction. Those prior deviations remain
historical facts; R2 does not retroactively validate their observations.

The child launcher uses `ProcessStartInfo.EnvironmentVariables` for owner-local
TEMP, TMP, LOCALAPPDATA and MONO_PATH, without mutating parent/global values.
The managed driver calls the original `GetManagerReceiptRequiredPaths` under
the existing test receipt-root scope. Its probes use CreateNew, write, flush,
read and delete, including original receipt publication suffixes and the
declared instance/transaction backup/rollback paths. Preserved logs support
PASS for these selected paths: maximum 255 characters at the initial locator,
254 at the corrected actual fixture locator. No fallback owner was selected.

The same bound Mono/driver process performed an exact read-only
`File.ReadAllBytes` on the preserved 292-character instance locator and logged
`DirectoryNotFoundException`. This adds actual runtime/API evidence for that
exact old locator; it does not establish arbitrary deep-path support or prove
the whole historical request-admission failure's product root cause. The
selected compact-path PASS is likewise not a semantic installed-admission PASS.

### Remaining setup prerequisite and attempt boundary

All three preserved original Install logs report exit 4, PREFLIGHT/BLOCKED,
`mutated_scopes=[]`, and cleanup COMPLETE. The driver and original guards support
Coder's classification:

1. Initial setup used 33 hex characters; original fixture layout requires 32.
2. C1 corrected that construction inside the same selected owner. Path-probe
   files had been deleted, but empty instances/operations directories remained;
   original `Test-InstanceFirstInstall` rejects those existing paths.
3. C2 froze a ten-directory inventory/deletion order, rechecked each target's
   containment, ordinary-directory status and emptiness, then used only
   non-recursive `Directory.Delete(path,false)`. The ten recorded task-owned
   empty scaffolding directories were removed. No file or nonempty directory
   deletion is shown. The unchanged Install entry then reached
   `PROVIDER_MISSING` and stopped without another attempt.

This used the initial setup attempt plus the two declared mechanical
corrections. The unsupported-prerequisite stop and dependent-case gating were
honored; there is no authority to reset the correction allowance by renaming
the next driver or scenario.

The direct original call chain explains the new prerequisite precisely:
`Invoke-InstanceConvergence` calls `Assert-MachinePrerequisiteForAction`, which
loads the Package manifest target
`AIWork/codedb/shared/codedb-machine-provider-contract.ps1` and calls
`Get-CodedbMachinePrerequisiteStatus` / `Assert-CodedbMachineProvider`. The bound
payload source has SHA256
`ebcaf8792a5f759ed9639c7250d1d411362ec4a90a32dcbf506020b10fd872be`.
It locates Provider root, manifest and executable directly under process
LOCALAPPDATA:

`<child-localappdata>/Rice/CodeDB/providers/0.5.0-28e3912-c2/`.

Thus selecting owner-local LOCALAPPDATA isolates receipts and also changes the
original Provider lookup root. The C2 failure is consistent with that isolated
store lacking the required Provider. It does not establish that the machine
Provider is absent. No machine inventory, Provider copy/install, fallback to
real LOCALAPPDATA, synthetic Provider authority or guard bypass was performed
by this review or appears in the R2 execution entries. The original prerequisite
reader itself is read-only; deciding how to supply a legitimate isolated
prerequisite is the remaining User/Planner scope decision.

### Remaining F1 and completion routing

Actual installed setup is BLOCKED. Original Journal admission, absent/foreign
request checks, PS/Node Uninstall, native identity/exit/restart cases, cooperative
writer settlement, deactivation, repeat/retention and actual terminal-producer
to C#-reader join all remain UNRUN. The unused driver's intended assertions
are not execution evidence. Existing historical reconnect deferral is unchanged.

Current task: S31-B, original F1 bounded correction.

Current status: targeted review COMPLETE; F1 OPEN with compile/path sub-evidence
addressed; product PARTIAL / INCOMPLETE — NOT ACCEPTED.

Next notification: current parent Planner; return the narrowed remaining setup
prerequisite and evidence limits together to User.

Next action: align one valid isolated Provider-prerequisite route for the same
objective, or defer/stop. Preserve R2's failed setup and original evidence.

Human decision or authorization required: disposition of that prerequisite and
any corresponding side-effect/attempt envelope. This review authorizes no new
execution, Provider staging/install, product edits, delivery or Unity operation.

## R3 targeted F1 and prerequisite review — 2026-10-16

### Disposition

- Review: `COMPLETE / TARGETED_READ_ONLY_REVIEW`.
- Original F1: `CLOSED WITH DECLARED EVIDENCE LIMITS`. The attributable
  current-source managed setup/request-producer gap is closed. Original Journal
  admission/read on a genuinely original-entry installed fixture is now proved;
  actual original failed-terminal consumption is also supported. This closes
  the original finding rather than extending it to every downstream UNRUN gate.
- S31-B objective: `PARTIAL / INCOMPLETE — NOT ACCEPTED`. Successful owned
  runtime stop/deactivation and repeated no-op remain unproved. The concrete
  remaining fixture prerequisite is recorded below, independently of F1.
- No demonstrated product BLOCKER or additional broad-audit finding. The
  fixture config omission is not proof that normally prepared real installations
  cannot uninstall. Product source remains unchanged; no source acceptance or
  delivery approval follows from closing this evidence finding.

Coder was terminal before admission. This review read only the R3 grant,
appended result, frozen drivers/manifests, direct production anchors, receipts
and logs. It ran no tests, processes or machine Provider inventory, contacted
no Coder, and appended only this section. Model settings were inherited without
override; exact platform model/effort names remain unavailable. Ceiling: 30M.

### Admitted identity

R3 owner: `.artifacts/tests/s31b-r3/`. Source remains the same S31-B checkout at
base/HEAD `ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`.

- RESULT SHA256:
  `bcd1e92492662bef35b06c149812051153042e5f6c0e2aa1cdc8b9bececf9bc4`.
- FINAL-MANIFEST-R3 SHA256:
  `553faf7e7554040f7b4cefbb60041f7452cc7d3bd8b2e9b6d931c3e45cae3b58`.
- RUN-MANIFEST-R3 SHA256:
  `3455c510748a713663c67ad073f7527656786c20a999b7457bcd03e2f3fedb2c`.
- Provider-construction correction manifest SHA256:
  `a5f3e46931254e78e873d742387ced24ee78705dd44684a30fc28dcf82f1b93c`.

Independent checks matched 47 unchanged product input files, 304 R3 evidence
files, 30 bound managed sources, 219 references, three pre-frozen tools, all
542 original evidence files and all 249 R2 evidence files: zero mismatches in
each set. The prior verification hash still matched
`c9eec59e4f8eda8a37b7d2a6e56ab35b134e1b7ba88c30ad03f33b38d79eaf5e`
before this append. The reused R2 current-source Editor DLL matches
`a1d563378502afb6fb60026bfd552b5eb4864b525e5befbe53ac2e6d90ec53ab`;
the new driver compiles against that exact owned copy and the bound references.
No historical A2 CodeDB binary or substituted production reader is used by the
inspected R3 route.

### Supported producer/consumer facts

| Boundary | Evidence and limit |
| --- | --- |
| Isolated Provider prerequisite | The three owned copies match the exact authorized EXE/manifest/notices hashes. Preserved copy records bind source and destination bytes. The original reader returned CURRENT with paths inside R3 child-local LOCALAPPDATA. This is prerequisite integrity, not Provider runtime lifecycle acceptance. No machine inventory was performed by Verifier. |
| Selected consumer paths | Thirteen real API probes passed, including original receipt helper/publication paths; longest 254 characters. Nineteen newly created empty probe directories were removed nonrecursively after ownership/emptiness checks. This does not claim arbitrary path support. |
| Original fresh Install | One authorized materializer Install with PocFixture returned INSTALLED / COMPLETE / INSTANCE_ACTIVATED / exit 0. Generated selection/activation/instance records are preserved. Candidate READY remains the explicit deterministic fixture seam. |
| Installed managed request | Original Journal TryAdmit and ReadUninstallRequest agreed on request `77d38dbaa5684aec9716ad76a59d4fd1`, phase EXECUTING. The frozen driver checks absent/foreign project absence and refuses a different-Package second admission. These assertions executed before Uninstall. |
| Actual failed-terminal consumption | Original ProcessRunner/wrapper/materializer/Node ran once. RecoverManagerAction returned Terminal with exit 1. Actual admitted/claim/checkpoint/terminal records bind the same action, stage, project/Package and command identity. The admitted script/writer hashes independently match the current materializer/wrapper. This proves truthful failed-result consumption, not UNINSTALLED. |

The preserved terminal contains UNINSTALL / BLOCKED / PREFLIGHT /
MATERIALIZER_EXIT_1, `mutated_scopes=[]`, exit 1; timeout, overflow and drain-loss
flags are false. Its checkpoint is CANCELLED_SAFE with no_more_mutations=true
and no journal operation id. Neither these records nor their successful C#
authentication prove native identity checking, writer settlement or transaction
commit: those stages were not reached.

The single allowed Provider construction correction replaced the task Hash
helper after the child could not resolve Get-FileHash. Initial failure and
driver remain preserved; the correction uses .NET SHA256 without altering the
original Provider reader. Manifest/log ordering is consistent with freezing
before each corrected execution. R3 used its one additionally authorized Install
attempt and one actual Uninstall attempt; no failed semantic command was retried.

### Remaining limitation — original fixture preparation does not supply config

The exact selected-instance `config/codedb-mcp.toml` locator is 221 characters
and is actually absent in the retained R3 tree. This is an existence/prerequisite
failure, not merely a repetition of the former long-locator diagnostic.

Direct source explains the observed boundary. The engine's PocFixture branch
in `Tools~/codedb-instance-engine.ps1` around lines 2774–2797 writes fixture-ready
markers but skips the real runtime preparation, adapter build and watch-manager
calls. In the attempted uninstall, `Invoke-ProjectUninstallOwnedRuntimeStop`
invokes original Node uninstall-stop. `runOwnedRuntimeStop` first calls
`buildContext`, whose selected-instance config assertion around
`Tools~/codedb-project-supervisor.mjs:261` requires that missing file before
request-owner/native-stop checks. The emitted error and current tree agree with
this direct call path.

Therefore the deterministic installed fixture is sufficient for the now-proved
managed request and failed-result readers, but insufficient for this original
runtime-stop consumer. This is the remaining S31-B evidence prerequisite, not a
new general product defect or authorization to relax the consumer. No config was
fabricated, prepare entry added, native successor started, guard bypassed or
product change made. Native stop, deactivation, concurrent writer settlement,
restart suppression, retention postconditions, release and repeat remain UNRUN.

One concrete next dependency is a valid original production preparation route
that supplies this owned selected-instance config, with its exact side effects
and evidence envelope agreed before execution. This review does not authorize
that route, hand-written config, cleanup/reconciliation of the retained request,
or another attempt. There is no reason to reopen the closed managed provenance
finding merely because this downstream prerequisite remains unresolved.

### Tool-freeze and residual-state limits

The pre-execution manifest froze Mono/dotnet/csc, but not the Node and Windows
PowerShell executable hashes. Their saved hashes are post-run attribution only.
This is a confirmed, disclosed workflow-evidence deviation: the run cannot be
called fully compliant with the promised pre-frozen tool closure. No rerun or
retrospective hash entry can turn it into such proof. The current-source managed
writer and actually preserved failed-terminal observations remain supported
within that declared limit; they do not gain native/end-to-end acceptance.

Owned child TEMP/TMP/LOCALAPPDATA/MONO_PATH and the approved three-file Provider
copy are explicit in the inspected entries. No machine installation/fallback
or global environment rewrite appears in them. Existing installed selection and
INSTALLED desired state remain. The original request is still EXECUTING while
its managed owner has returned; the driver stopped before Journal release.
The fixture must not be described as clean, automatically resumed or implicitly
authorized for cleanup. User content is preserved, but uninstall retention
postconditions were not exercised. Historical reconnect stays deferred.

### Completion routing

Current task: S31-B, original F1 and R3 isolated prerequisite route.

Current status: targeted review COMPLETE; original F1 CLOSED within the stated
evidence limits; S31-B PARTIAL / INCOMPLETE — NOT ACCEPTED.

Next notification: current parent Planner; return the remaining selected-instance
config preparation prerequisite and tool-freeze deviation together to User.

Next action: align that single original preparation dependency, or defer/stop,
while preserving installed fixture, EXECUTING request and failed terminal.

Human decision or authorization required: disposition and any exact next
preparation/side-effect/attempt envelope. No product edits, new execution,
Provider operation, commit/export/reference switch or Unity authority is granted.

## R4 targeted read-only verification — 2026-10-16

R4 is a separate repository-local evidence owner at
`.artifacts/tests/s31b-r4/`, with source snapshot
`.worktrees/cdb-v0.3-p0-s31b-owned-runtime-stop-uninstall-transaction/` at
`ed97c3808bd7b2466bcc2a045ee18f2d02ca9cb6`. The frozen R4 manifest
`FINAL-MANIFEST-R4.json` has SHA256
`74badabbee5aea37f226a6fe2787e547320214a57c431079524ed07d8b5ce381`;
the current task `RESULT.md` has SHA256
`a38b3aef00028c6121a99579889c097ddf79f63e81cc0bbe290196a6abadb8ac`.
The R3, R2 and historical manifest hashes remain preserved as
`553faf7e7554040f7b4cefbb60041f7452cc7d3bd8b2e9b6d931c3e45cae3b58`,
`0cf37d729124c7194ce7a3b305e5d1e5b6d62c38ed514f2a5263b5ac26074980`, and
`e86b726e00288b44516b6cf7cebb7b05dc049e45815840b6e77138db1cd35214`.

The R4 manifest contains 47 source files, 30 managed source files, 219
references, 3 Unity tools, 3 Provider files and 292 new evidence files. Direct
hash checks matched all 47/47 R4 source entries and 292/292 R4 evidence
entries. Preserved predecessor evidence also matched 304/304 R3, 249/249 R2
and 542/542 historical entries. Absolute manifest paths were checked at their
recorded paths; no relative-path reinterpretation was used.

The pre-freeze mechanical correction is retained in
`RUN-MANIFEST-R4-C1.json`: the initial reused R3 DLL binding accidentally
represented the manifest root as a JSON object. C1 explicitly bound the R3
root. The initial failure happened before any child, Provider or product
execution; no production/source/environment change occurred before correction.

The first Install invocation omitted second-level confirmation and returned:

```text
INSTALL / BLOCKED / PREFLIGHT / MATERIALIZER_EXIT_4 / exit 4
mutated_scopes=[]
Install requires the Package Manager's second-level project mutation confirmation.
```

It produced no project mutation. The single confirmed invocation used the
original production route (`prepare-codedb-project-runtime.ps1`, text-adapter
build, and `manage-codedb-project-watch.ps1`) with `-ConfirmedProjectMutation`
and without `-PocFixture`. Runtime/config/watch files and Provider index data
were generated, but coordinator readiness timed out after 120000 ms:

```text
INSTALL / BLOCKED / CANDIDATE / INSTANCE_CANDIDATE_FAILED / exit 6
mutated_scopes=["host_runtime","instance_candidate"]
cleanup_state=PENDING
detail=Timed out after 120000 ms waiting for coordinator readiness.
```

No candidate was selected and no `INSTALLED` authority was published. The
retained candidate/host runtime closure, configs, coordinator state, lease,
index and logs remain under the R4 owner. No retry, automatic cleanup,
recursive deletion or real Uninstall was performed.

The durable R4 coordinator records classify the exact project roles as
`OWNED`: coordinator PID `39976` with start identity
`639277549189521370`, Provider PID `4316` with start identity
`639277549204642400`, and adapter worker PID `55136` with start identity
`639277549200614830`. Read-only rechecks reported each live OS identity as
`NOT_PRESENT`. This supports durable `OWNED / EXITED` classification only;
graceful-exit proof is not claimed. No bare-PID kill, `Stop-Process`,
`taskkill`, process census/control, or recursive cleanup was used.

R4 outcomes remain bounded as follows:

| Frozen case | R4 outcome |
| --- | --- |
| ToolFreeze | PASS |
| ProductionPrepareAndInstall | PARTIAL/BLOCKED: authentic production route, readiness timeout, no selected authority |
| ManagedRequestAdmission | UNRUN: no installed authority |
| OwnedRuntimeStopUninstall | UNRUN |
| TerminalReaderRetentionRepeat | UNRUN |
| Native stop/uninstall/terminal/repeat | UNRUN |
| Unity or release acceptance | UNRUN |

R2/R3/history evidence remains intact, and no new product blocker was found
within this requested R4 scope. Product status remains `PARTIAL / BLOCKED — NOT
ACCEPTED`; R4 is evidence only and does not establish source acceptance,
delivery, Unity acceptance or native lifecycle completion.
