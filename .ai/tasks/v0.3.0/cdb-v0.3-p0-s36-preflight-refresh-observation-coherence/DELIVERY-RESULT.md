# S36 exact delivery result

Date: 2026-10-19. Status: DELIVERY_COMPLETE / HUMAN_ACCEPTANCE_PENDING.

Subsequent human result: COMPLETE / HUMAN_COMPILE_FAILURE_CLASSIFIED. The
delivered artifact is preserved; delivery byte/identity checks below remain
valid, but this artifact is not human-accepted. See the failure section below.

## Authorization and exact commit

User accepted the source (`同意 accept`), reported S35 closed
(`s35 已经关闭`), and explicitly authorized the named local commit/export/
reference-switch group (`同意授权`). The parent performed those actions
sequentially without extending that grant to Unity or lifecycle commands.

- Parent: `d4a097d20af598ca760163867a3394ff5efb116d`.
- Commit: `4291e80795681ad0057518b5ecd6c04e3c9ca92b`.
- Message: `fix: preserve lifecycle observation during preflight refresh`.
- Exactly the six paths in DECISION.md were staged and committed. Index was
  empty before staging and after commit; staged paths matched the allowlist,
  staged/worktree blobs agreed, accepted C# hashes matched, diff check passed.
- Source production diff: +38/-13; tests +294/-0. Other committed additions
  are the four S36 source-stage records. Unrelated dirty files were preserved.
- The two accepted source/test files are clean after commit. No push occurred.
- Delivery result and route updates are subsequent local records, outside the
  six-path source commit; no extra automatic commit was made.

## Exact artifact and gates

Existing exporter matched the committed exporter bytes and ran once against
the exact commit, using a fresh repository-local contained output directory.

- ZIP: `.artifacts/s36-preflight-refresh-4291e80/com.rice.ai-codedb.zip`.
- ZIP SHA-256:
  `0e996028b1100260c366528db3cfc6a63b64120b117c841925bd1a8f4e575e5c`.
- Commit-stage Package:
  `.artifacts/s36-preflight-refresh-4291e80/package/com.rice.ai-codedb`.
- Consumer extraction:
  `.artifacts/s36-preflight-refresh-4291e80/review/com.rice.ai-codedb`.
- Files / ZIP entries: 623 / 623; extracted bytes: 13,388,482.
- Commit-stage and exact-ZIP production read-only payload admission PASS,
  source count 60; byte closure PASS, mismatches 0; identity/hash closure PASS.
- Both flat/generation native source/build/binary VerifyOnly bindings PASS
  on both validated Package copies. No native rebuild was performed.
- Exact extracted Package PathProvenanceOnly and instance-helper binding
  checks PASS; working-tree supplemental precommit check also passed.
- All 623 consumer files were hash-compared to the commit-stage Package;
  zero missing/mismatched files and matching counts. The accepted Lifecycle
  and test SHA-256 values in RESULT.md match the exact extracted files.
- Package/generation remain `0.3.0-preview.5 / poc.43`; transition NONE.
- Generation-manifest SHA-256:
  `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`.
- Host-current SHA-256:
  `ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1`.
- Runtime-contract SHA-256:
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- No serialized record contract changed; no changed producer/consumer closure
  or immutable generation migration is required by this C# cache-only diff.
- No semantic C# compilation, NUnit, Unity or real idle PASS is claimed.
  No full regression or incompatible historical harness was run.

## Closed-S35 reference switch

Target: `.artifacts/unity-projects/s35/`, Unity 2022.3.62f3.
Immediately before backup/switch, read-only checks found zero attributable
S35 Unity processes and no UnityLockfile or EditorInstance.json. Backup and
target parents were checked for repository containment and reparse traversal.

Hash-verified original backups:
`.backups/s36-preflight-refresh-4291e80/{manifest.json,packages-lock.json}`.

The relative reference was computed from the actual S35 Packages directory:
`file:../../../s36-preflight-refresh-4291e80/review/com.rice.ai-codedb`.
Both parsed consumers agree and resolve to the verified extraction. CodeDB
testables remain enabled. Raw-byte comparison proves the exact old/new
reference substitution is the only byte change in either file, including
preserved encoding, formatting and other dependencies.

| File | Before SHA-256 | After SHA-256 |
| --- | --- | --- |
| `Packages/manifest.json` | `ebbdae44ade67b94bc927439bfa215c871e7bfb53abb6d9a8216eb7783d7de8e` | `d40a4d084200cc7766f40d7a1a1f266d08b484e803a3a2ccc1da0f23a38f47f0` |
| `Packages/packages-lock.json` | `fddd8b1d34c6155b1e884004afef5e31d014dd91213b8c732dacec3da6c78279` | `379152b500bd19b695c09b8212955d16ecbfc3005891ba75e334003356c4a537` |

These selected protected records retained their exact before-switch hashes;
this is a bounded protection check, not an exhaustive runtime audit:

| Protected project-relative path | Unchanged SHA-256 |
| --- | --- |
| `.codex/config.toml` | `7975ac850e520cdbc03fcfaeb95849c07a5c7c0208d1661984d58d02a16ce490` |
| `AIWork/.runtime/codedb/control/current-instance.json` | `51451aebd74bb9baea5d5ee64f01acadae307dab6b0863602d8d9c581d5f097b` |
| `AIWork/.runtime/codedb/control/desired-state.json` | `c416ed236360ccc7517cf4e40aada871e5340ab71ed743b59a00e950472a822f` |
| `AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/activation.json` | `b6f7692b9a72ab3bb46ecdf66e17748e6cd7327b4942074445d14dd4cc02e6be` |

No Unity launch, lifecycle command, live RPC/probe, process control, runtime
cleanup or machine-store write ran. Prior S34 artifacts and S35 failure/first
Install evidence remain protected.

## Human acceptance handoff

Use the existing S35 project; the reference is already switched. The human owns
Editor selection/open/close and Test Runner execution. No agent execution is
authorized by this checklist. Compatibility line: existing pinned 2022.3.62f3.

User action / visible result:

1. Open S35 and allow import/compilation. Report any compile/Console error.
2. In EditMode Test Runner, run only the groups below (search each name and
   run selected). Do not run the complete suite by default. Preserve the first
   test/compile failure and report it; no automatic repair/retry is implied.
3. Open Manager; wait for current readiness, close/reopen once and switch tabs.
   Leave the Editor and Manager open for 3-5 minutes after Ready, exceeding the
   120-second preflight refresh interval. Report final state, any recurring
   same-revision NeedsAttention detail and other visible errors. The existing
   policy may expire old evidence; retaining stale Ready is not an acceptance
   goal and preflight success is not new readiness evidence.
4. Check normal Unity close and report its result. CleanupMono remains a
   deferred observation, not a new repair priority in this slice.

Focused Test Runner selections:

| Class / test selection | Purpose |
| --- | --- |
| `Rice.AI.Codedb.Editor.Tests.AICodedbPreflightRefreshTests` (10 parameterized cases) | Paired observation, preflight result, expiry age, newer state publication, terminal protection, cancellation/context |
| `LifecycleStatusBinding_RequiresSameOperationalObservationRevision` | Existing strict observation mismatch rejection |
| `ManagerStatusBoundary_RejectsStaleForeignAndIncompleteReadyEvidence` | Existing direct Manager stale/foreign/incomplete boundary |
| `ManagerReadyFreshness_SharedAcrossDisplayCacheAndExpiry` (all its cases) | Existing shared freshness rule |
| `ManagerReadyExpiry_PrecedesUnchangedLifecycleRevisionGate` | Existing unchanged-cache expiry order |

This is the focused proposed human evidence gate; none of these tests has run
as part of delivery. The four nearest existing selections are direct consumers/
guards from the frozen S36 scope, not a new full review.

Do not click Install/Uninstall/reinstall during this smoke/idle check. S35's
original complete lifecycle grant was tied to the S34 artifact; pending stages
remain paused. After this acceptance result, align the remaining logical
Uninstall and same-version Install handoff on the newly delivered artifact
before executing either command. No new project or repeated first Install is
needed for this source-delivery handoff.

Technical evidence remains separate: the original first Install was verified
on S34, S36 source is accepted and delivered, while compilation/NUnit and actual
idle behavior on S36 remain pending until the human reports their results.

## Human compile failure and read-only diagnosis

User reports errors with two original screenshots. Both CS0246 messages point
to `Tests/Editor/AICodedbEditorLifecycleTests.cs(383,6)` in the S36 exact
extraction: `NonParallelizableAttribute` and `NonParallelizable` cannot be found.
These are two diagnostics for one unsupported attribute on the new
`AICodedbPreflightRefreshTests` class, not two independent runtime defects.
Compilation has not passed; focused tests and idle acceptance cannot proceed.

Read-only inspection of S35's actual dependency closure shows
`com.unity.test-framework@1.1.33` and `com.unity.ext.nunit@1.0.6`, using
`net35/unity-custom/nunit.framework.dll`, assembly version `3.5.0.0`.
The DLL SHA-256 is
`e388e140954de12970384331d1730e95b4613ef53c3326b6f8fa0fffdbc9314f`.
Managed assembly metadata lookup confirms `TestAttribute` exists,
`NonParallelizableAttribute` does not exist, and
`ParallelizableAttribute(ParallelScope)` plus `ParallelScope.None` exist.
This confirms a compatibility omission in the newly added test decoration;
the earlier syntax-only check did not validate referenced NUnit types. The
previous source review and byte closure do not override this compiler failure.

Proposed bounded correction: replace only `[NonParallelizable]` with
`[Parallelizable(ParallelScope.None)]` in the canonical test file, preserving
the explicit nonparallel intent and all ten scenarios. No production-source,
Unity dependency, generation or external-runtime change is proposed. Before
delivery, use actual referenced NUnit metadata for this attribute compatibility
check; retain semantic compilation/NUnit/human idle execution as separate gates.
Do not patch the observed extraction or reuse its output directory.

Human authorization for this correction and stopped Coder -> read-only Verifier
reuse was pending at diagnosis. The subsequent user reply `同意批准` authorizes
exactly that correction and sequential stopped-role reuse. Parent froze the
repair envelope in TASK.md and re-dispatched the existing Coder. No new delivery
or Unity authority was granted. No source fix, test run, new agent, new commit/export/reference
switch or Unity operation was performed by the original diagnosis. This is a same-task
direct regression, not a new architecture or historical-recovery task.

Original screenshots were copied and hash-verified under
`.artifacts/delivery/s36-preflight-refresh-4291e80/compile-failure/`:

| Evidence | SHA-256 |
| --- | --- |
| `nonparallelizable-attribute-error.png` | `352d2dc40e3ad6c32a8aafe6c4a2ec87b3868f40076db9fc68fa5fe61a6f7408` |
| `nonparallelizable-name-error.png` | `66ea6b8b3da85135692f2fa1b56aea504d255dd40f8b1fc5db75511d5364f558` |

The original ZIP still hashes to the delivery identity above. Preserve the
failed artifact, screenshots and config backups. S35 remains on this artifact;
Uninstall/reinstall and dependent smoke/idle acceptance remain paused.

## Updated handoff

- Current task: S36 exact delivery.
- Current status: COMPLETE / TARGETED_REPAIR_REVIEW_PASS_WITH_EXECUTION_LIMITS /
  DELIVERY_REAUTH_REQUIRED.
- Next notification: User, for corrected-source disposition and renewed exact
  delivery authorization.
- Next action: after explicit renewed authorization, commit only the one-line
  correction, export/check the corrected commit and switch the closed S35
  reference; the prior delivery grant is consumed and not reused;
  retain all runtime/source and real acceptance evidence limits.
- Human decision or authorization required: corrected-source disposition and a
  new exact delivery grant. No Unity or real lifecycle authority follows from
  the repair review.
