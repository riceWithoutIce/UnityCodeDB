# S29 startup authentication boundary repair

Date: 2026-10-13, Asia/Shanghai.
Status: SOURCE_READY_FOR_INDEPENDENT_REVIEW / PASS_WITH_LIMITS.
Coder: parent agent; no child was started for this repair.
Base and current HEAD: `04e9a6bd49ae46f5c10989f6e4c6efddc479ad24`.
Branch: `codex/v0.3.0-legacy-workflow`. Index remains empty.
Source identity: STARTUP-AUTH-BOUNDARY-REPAIR-SOURCE-SHA256.txt.

## Authority and scope

The human authorized this repair with “同意修复”. The continuation preserves
the agreed objective: historical candidate closure must not require an
operational lease; owner authentication is distinct from operational Ready;
historical removal uses independent preflight; an authenticated unrelated old
candidate may be historical information, while related, active or ambiguous
candidates remain fail-closed. The five Editor/test files in the hash record
are the complete source change set for this repair.

No authority for Unity/MCP/BatchMode/CUA, real Probe/Ensure, Install/Upgrade/
Remove, process control, history cleanup, commit, export, reference switch,
push or publication is inferred. Existing dirty docs, payload and projects
remain outside this repair. Human-deferred CleanupMono observation remains
deferred. S29/release remain PARTIAL.

## Resulting behavior

- Retained-current-state validation accepts authenticated Current or
  TrustedPrevious selection. A previous selection still cannot publish the
  current Package's operational Editor lease. Existing origin, desired-state,
  selection, Package-mismatch and applicable committed-handoff checks remain.
- Supervisor migration authentication accepts owner-bound protocol-valid
  starting, degraded, stopping and core_ready observations. This establishes
  current owner identity, not product Ready. Foreign or malformed authority
  remains invalid; unavailable transport remains transient authentication loss.
- TrustedPrevious + Installed lifecycle state reaches the existing independent
  historical removal preflight despite operational migration failure. It
  bypasses the operational authentication retry that previously returned before
  this route. The route blocks operational admission first and never grants
  Ready, bootstrap or a removal permit without its existing independent proof.
- An unowned PROVISIONING candidate is historical only after complete project,
  instance, worker and Package-declared generation closure; a different older
  generation; independent installed/committed selected control records; and
  absence of active or unknown Editor, instance or generation holders. Recent
  leases or a PID that still exists/has unknown query outcome remain blocking.
  Only structurally valid stale leases with absent PID may be ignored. Relevant
  runtime authority, malformed identities or incomplete proofs stay blocking.
  Its original outcome remains unknown; no cleanup or mutation is authorized.

The added journal logic is the largest change (~400 diff lines). Independent
review should concentrate on the relation/holder boundary and historical
authentication, rather than broadening into unrelated lifecycle or payload work.

## Validation

Final unmodified-source Roslyn semantic compilation: 34 Editor/test files,
C# 9, Unity 2022.3 managed references, zero errors. Executed Semantic.dll;
building the harness by itself is not source compilation evidence.

Final focused standalone execution: seven methods / 51 cases PASS:

| Method | Cases |
| --- | ---: |
| ManagerActionJournal_UnownedHistoricalCandidateRequiresIndependentSelection | 15 |
| RetainedCurrentState_AuthenticatesHistoricalSelectionWithoutOperationalLease | 4 |
| Read_ClassifiesLiveTransportSeparatelyFromInvalidAuthority | 11 |
| HistoricalRemovalRouting_OperationalFailureStillRequiresIndependentPreflight | 3 |
| HistoricalRemovalRouting_PreservesEarlierGuards | 6 |
| HistoricalRemovalRouting_ColdRepeatedAndExistingLease | 4 |
| HistoricalRemovalRouting_RejectsUntrustedPrerequisiteAndCancellation | 8 |

Journal cases run the production reader against actual isolated fixture files.
Retained cases invoke the changed private current-state validator via reflection
against real fixture selection/desired files; they do not independently replay
the complete retained-effects producer chain. Both check fixture file hashes
before/after. Lifecycle cases use worker delegates and prove routing/order and
refused preflight/cancellation behavior, not native lifecycle execution.

Harness: `.artifacts/tests/s29-auth-boundary-fix/` (ignored).
It adapts Unity static initialization, SessionState, native Application path
and Editor time; supplies a synthetic Unity synchronization context; adapts
NUnit assertions/numeric comparison for net10; and redirects temporary fixture
roots inside this artifact directory. It uses the existing historical
RuntimeShim.cs read-only. No product script is executed.

This is not Unity import, EditMode execution, UI acceptance, live Supervisor
IPC authentication, real removal or sustained operational readiness evidence.
Five-file `git diff --check` passed. No independent Verifier has run yet.

## Real project read-only evidence

The final current-source reader used the actual project manifest reference:
`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-historical-handoff-04e9a6b/review/com.rice.ai-codedb`.
The lock's dependency version selects the same reference.

Journal: `Empty`; selected: `TrustedPrevious` (installed poc.42, successor
Package poc.43). This is a current-source diagnostic against the referenced
Package, not evidence that the referenced package already contains this repair.

The journal preserves d8c736504562495dbafdd673c6851efb failed INSTALL / cleanup
PENDING and f14c0524af324b7a802335a393483fa0 original failed/unknown effects.
Orphan 330b7a972a7649259409fbce4de8ca56 / poc.39 is an unrelated historical
warning. No action index was released, no receipts were rewritten, and no
candidate was deleted. Empty journal does not itself authorize Install/Remove
or mean product Ready.

Protected state hashes match the continuation's supplied baseline and the
pre/final read-only checks:

| File under AIWork/.runtime/codedb/control | SHA256 |
| --- | --- |
| desired-state.json | 0abe47370544c18fe074f34a1230109da5ebe3a5de4951cc40a08c5680933f3b |
| current-instance.json | e270b40b20409f484a395f522ac9e2afa451499a1bdb0b1bc3bbe28c583274c1 |
| contracts/v0.3-control/v2/activation.json | afdce4014bd4ef18998f56933ea0b3bd4ad7189feda9d0022875cc278ef390e3 |
| contracts/v0.3-control/v2/operation.json | 0995b8929e763a2defdfe219fb42375ffc236322b89af5eb730e94c17f0a0ad2 |

Manifest SHA256: 936a1efb51c3b847b1fb134e7064a8d6c1821fc538f9399673e36158598879b9.
Lock SHA256: 1a1ae372733552c4d970bc9fe5f8ba009930c6dbd4fd4421e80a522379449ce1.
Historical installed runtime hashes were not rewritten to match the new Package.

## Corrections and evidence limits

Earlier continuation runs repeated the legacy 20-case harness and were not
final evidence for the added cases. A historical RuntimeTests.cs was
inadvertently changed; the two identified edits (extra deleted test name and
changed real Pending expectation) were restored. It is not reused for the new
focused run. A shared build-directory apphost also dispatched that old harness
once during the intended semantic command; it stopped on its obsolete Pending
expectation, before any clone/release tail. Direct DLL execution resolved that
dispatch ambiguity.

Focused validation corrections included a deleted project-identity fixture
lookup, unsupported object-array serialization, missing previous-generation
host pointer, and old NUnit CallContext incompatibility (one adapter compile
signature correction). The earlier project hash helper incorrectly required a
user-local journal path; generation hashing now uses validated project paths.
Some inspection outputs were truncated and earlier validation was repeated;
no strict whole-session output/attempt-budget compliance is claimed. Final
semantic and focused results apply to the recorded hashes only.

## Next boundary

Source is frozen and ready for one targeted independent read-only review of the
five files, the original boundaries and immediate regressions. Current human
AGENTS instructions require approval before opening a child; no new review
child has been started. Parent must remain active through review completion,
consume questions and return findings together. Do not rerun unchanged tests
or add requirements. Human source ACCEPT and delivery/real-environment gates
remain separate and pending.
