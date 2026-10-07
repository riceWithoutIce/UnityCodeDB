# S29 Failed Install Repair - Independent Verification

Date: 2026-10-07. Final source admission UTC: 2026-10-07T14:48:07Z.
Verdict: **SCOPED_SOURCE_REVIEW_PASS**.
Combined declared isolated evidence: **SCOPED_FIXTURE_PASS**, with reuse described below.
No P1/BLOCKER or other actionable finding was established in the five frozen claims and their adjacent regressions. This closes this targeted source review only.

## Authority and snapshot admission

Read FAILED-INSTALL-REVIEW-PACKET.md completely and the repair packet, including the Continuation 02 shared-wrapper clarification and Continuation 03 fixture-only allowance. Both Coders were stopped before review. Used the named latest RESULT sections and latest identity, preserving earlier failures as historical evidence.

- HEAD: `13bf5fd16c15c42e1379ce35a06e49c20753195f`.
- Index SHA256: `f97b6bcf28b896b789d9de85fe24212b51bcd327e01531a432294099b22acbed`.
- RESULT: matched `a863e2758fd9e2df4bf25caf6a9cc9be97d519d3c9fac86f1bac5050a9b16279`.
- IDENTITY: matched `ad10aea47ab8e7cf1c4c4cb8503ff50602393b07b618a65dd90cbb1b2d2ce223`.
- Latest ordered ten-path raw SHA256 admission: 10 matched, 0 mismatches, repeated at review completion with the same result. Harness matched `c451454a5863c28803bab54b08151e66a1cf71ff8efff4288ef33354a5073eba`.
- All 358 tracked generation files matched aggregate `6014a59cde8ed85d47338b97a11adb272823fbe22cafcef3c99ca7c3b2ca8d94`, using the identity's ordered lowercase raw-hash UTF-8 concatenation method. No generation inventories were emitted.
- HEAD/index remained unchanged at completion. No source/test edits were made by this Verifier.

## Frozen claims reviewed

1. **Invocation attribution.** ManagerWindow's actual async action runs inside `UseActionContext` (line 2776). `BuildRuntimeScriptArguments` (HostPayloadMaterializer:295) resolves one direct operation ID and the actual current action ID before handing its argument array to ProcessRunner. ProcessRunner's existing durable path hashes that array (line 657); it is unchanged. Actions' allowed fallback (line 309) invokes the direct route only when the Supervisor explicitly permits fallback. Standalone operation/action binding remains separate from historical backend-origin records. Authored C# argument assertions were inspected, not executed.

2. **Failed Install convergence.** Both actual Install action entry points call `RequestInstallReconcile`; `CanRequestInstallReconcile` (Actions:208) requires authoritative terminal success, no retained admission, a valid INSTALL/INSTALLED command result, and COMPLETE cleanup. Manager callbacks use the same Install predicate (ManagerWindow:2880). Failed, missing, malformed/unknown and PENDING outcomes cannot request this automatic convergence; successful complete Install retains it. Lifecycle's missing-selection/retained-instance check (EditorLifecycle:956) returns NeedsAttention before automatic prerequisite/convergence work. It leaves original command evidence intact. C# tests cover the predicate cases and authored lifecycle boundary only.

3. **Failed-preparation authority and actual v2 consumers.** Engine `Get-FailedPreparationRemovalAuthority` (1999), v2 writer (2044), and `Get-InstanceRemovalIntent(s)` (2065/2194) bind one unverified PROVISIONING original INSTALL, project/manifest/generation identity, deterministic bounded effects, registration plan, and holder evidence. Conflicting selected/active/Supervisor authority and unexpected mutable/bootstrap content refuse. The failed-preparation-only preserved-generation route (3447/3562/3648) requires a unique declared old transition and trusted Package closure; default retired readers retain their existing map requirement. v2 omits fabricated selection/activation evidence; v1 retains its own schema semantics. All removal-reader call sites in the two production scripts pass Package authority, including next-change admission, cleanup, activation entries, fresh Install, recovery and RemoveIntegration terminal validation.

4. **Durability, logical removal, inert retention.** `Invoke-InstanceUninstall` (5048) reacquires the existing project lock and revalidates the snapshot after operation recovery. It adds the v2 intent before deactivation entries; the failed-preparation route publishes desired UNINSTALLED last. `Publish-InstanceOperation` (3026) uses the existing journal and applies the effect guard before each mutation, with verification before commit. The terminal verification checks absent selection, disabled managed registration and UNINSTALLED state. The classifier had already refused active/conflicting authority. Cleanup recognizes removal-bound instances and preserves PENDING (4188/4246); the retained failed candidate/bootstrap closure is not passed to generic retirement deletion or an external-process stop path. Repeat Uninstall/RemoveIntegration uses the existing authenticated desired-state/intent and terminal or cleanup paths.

5. **Fresh Install and shared wrapper.** Fresh Install authenticates the retained intent and creates its own verified candidate (convergence:4699 onward); the failed candidate is never adopted as predecessor/LKG. `Assert-FailedPreparationWrapper` (1931) accepts the original observation, an exact ACTIVATING INSTALL journal with a different verified candidate and matching wrapper pre-image/desired hash, or a matching COMMITTED different READY selection and authenticated generation wrapper. The low-level activation decoder validates paired records; shared-wrapper validation does not recurse through removal/admission/cleanup. Original wrapper observation is immutable in the intent, while other recorded effects stay byte-exact. Unknown wrapper bytes refuse. Fixed missing wrapper ancestors are the only added-directory exception. Later admission/cleanup revalidates the retained closure and preserves PENDING. Existing activation recovery restores the pre-publication state after the declared interrupted publication.

## Isolated evidence and practical limits

Inspected the actual focused harness import, shared-module binding, production-body assertions, fault injection, emitted-record readers, real transaction entry paths, finalization recovery and wrapper assertions (test harness:61-111, 205-245, 591-819). Production authority readers and transition functions are imported unchanged. Machine prerequisites/process identity and candidate/runtime availability use fixture seams; native service execution is prohibited in this family. This supports isolated source/transaction behavior, not live runtime readiness.

- Reused Continuation 02's three complete CURRENT/ABSENT/OLD removal -> fresh Install -> retained PENDING paths on unchanged product hashes, including later admission/cleanup, unknown wrapper refusal, production status and v1 reader compatibility.
- Continuation 02's overall run remains **partial**: exit 1 after 193 successful assertions because the negative-case digest opened its own exclusive lock. It is not relabeled as a full-family pass.
- Continuation 03 changes only the harness and supplies the remaining **51-assertion PASS**, exit 0, 43.514 s, stderr 0, no native children. It checks real INSTALL-journal authorization, wrong action/pre-image refusal with byte preservation, the pre-commit exception and explicit production rollback/recovery to the original wrapper plus UNINSTALLED/PENDING v2 authority.
- The digest exception is restricted to the explicitly supplied held fixture lock, validated against the open stream path. Other authority/effect files remain in the digest. The finalization case constructs a real COMMITTED journal over fixture records and invokes the production recovery reader. The activation interruption is exception injection through production publication, not an OS process-kill experiment.
- Coder-declared PowerShell parse and scoped diff checks were accepted as declared evidence; Verifier did not rerun them or any test.

## Boundary and disposition

Only this report was written. No Unity/MCP/CUA/BatchMode, service/native test execution, real project/candidate/receipt access, source edits, commit/index writes, export, broad audit, extra agents or Coder contact occurred.

C# compilation and C# test execution: **NOT RUN**. Unity/EditMode, live runtime/Provider, real consumer/integration, device/performance, S29 product acceptance and release acceptance: **NOT RUN / NOT CLAIMED**. The source verdict must not be reported as any of those gates passing.

F-IMC-01 / P3 remains **DEFERRED**, outside this repair. No additional theoretical-hardening audit or new follow-up list was opened. Return this consolidated result to User/Planner and stop the targeted review.
