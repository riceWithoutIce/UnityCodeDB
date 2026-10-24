# S29 v2 removal process identity: stable Coder result

Date: 2026-10-14. Base: `39d79aeee1bd5525c6ed2eb1369f6c27334b9d07`.
Status: SOURCE_AND_ISOLATED_PASS / STABLE_FOR_READ_ONLY_VERIFIER.
Mandatory source gates are complete and PASS; no mandatory gate is waived.
This is not source acceptance, real removal, Unity or release acceptance.

## Implemented outcome

Only the task's three allowlisted files changed (199 insertions / 12 deletions).
The materializer adds one v2-removal-local assertion and calls it for terminal
history child, paired stale owner and current owner. It validates recorded
canonical positive decimal UTC ticks within DateTime range and producer
microsecond precision. Current raw UTC ticks are compared after subtracting
`ticks % 10`, exactly as the Windows Supervisor producer does. No Unix-millisecond
lease matcher, time tolerance, executable-name inference or compatibility
fallback is used.

An explicitly absent/exited PID continues the remaining gates. A matching start
identity refuses with `original process is still alive`; a different valid start
identity continues the remaining gates without claiming the reused process.
Observation failure or missing/unreadable/unusable current start identity refuses
with `process identity is unavailable`. Invalid recorded identity refuses before
it can be interpreted as absent or reused. Missing child remains a separate
`child evidence is missing` refusal and now identifies its validated operation ID.
History refusals identify the bounded operation ID; owner refusals identify the
current/stale role. Derived classification is not a permit or persisted authority.

No other production function was changed. In particular generic process
inspection, generation lease comparison, partial-v1 helpers, strict v1/default
inventory, holder aggregation, namespace/fingerprint/configuration checks,
transaction publication and terminal/recovery invariants remain unchanged.
Current-owner dispatch calls the new comparison only for VERSIONED_V2; the old
PID-only refusal remains the exact else branch for older authorities.

The PowerShell fixture extends the existing RemovalNamespaceOnly route with
explicit task-owned process-identity roots and synthetic process observations.
The directly coupled C# consumer retains prior namespace evidence/assertions and
additionally consumes precise role/mode refusals for the new fixture family.
Existing original cache assertions and finally restoration remain byte-identical.

## Frozen identity and inventory

Evidence root: `G:/RiceProgram/UnityCodeDB/.artifacts/tests/s29-removal-process-identity/coder-a1`.
Successful immutable overlay: `attempt-a2/com.rice.ai-codedb` under that root.
Canonical input: `.artifacts/s29-removal-namespace-39d79ae/review/com.rice.ai-codedb`.
Predecessor: `.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb`.
Both were read-only; dirty worktree Payload was not used as authority.

Inventory uses `Get-ChildItem -LiteralPath -Recurse -File`: accepted baseline
618 files; successful overlay 618 files; missing 0; extra 0; changed exactly:

- Tools~/materialize-codedb-host-payload.ps1
- Tests~/test-codedb-host-payload-materializer.ps1
- Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs

The earlier ca316db Package had 617 files. Accepted39d79ae adds
`Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta`.
This task adds no Package file. Every other accepted Package file, including
Payload, is byte-identical in the overlay. Worktree/overlay hashes match all
three authorized sources; SOURCE-SHA256 beside this result freezes them.

## Mandatory gates and consumer evidence

All artifact paths below are relative to the evidence root.

| Gate | Result | Evidence |
| --- | --- | --- |
| Changed PowerShell syntax; scoped diff-check; PathProvenanceOnly on exact overlay | PASS, exit 0 | attempt-a2/l0-a1.log; attempt-a2/prepare-and-l0.ps1 |
| Original-byte Editor semantic compilation | PASS, exit 0 | attempt-a2/Rice.AICodedb.Editor-compile-a1.log; corresponding .rsp |
| Original-byte full Editor.Tests semantic compilation | PASS, exit 0 | attempt-a2/Rice.AICodedb.Editor.Tests-compile-a1.log; corresponding .rsp |
| RemovalNamespaceOnly isolated production-call-chain scenario | PASS141, exit 0, native product children 0 | attempt-a2/scenario-a1.log; attempt-a2/run-scenario.ps1 |
| Original C# fixture -> diagnostic/cache/UI seam | PASS, exit 0 | attempt-a2/seam-run-a1.log; attempt-a2/run-seam.ps1; Runner.cs |
| Exact original source-member binding | PASS, 13 members | attempt-a2/exact-ast-binding.txt; extractor-a1.log; extractor/Extract.cs |
| Exact overlay inventory/source and production-function closure | PASS | source-overlay-check.log; verify-source.ps1 |
| Protected state before/after, including HEAD/index | PASS, 4174 identical entries | protected-before.txt; protected-after.txt; protected-comparison.log; snapshot.ps1 |

Executed with Windows PowerShell5.1, `-NoProfile -NonInteractive -ExecutionPolicy
Bypass`, using the saved scripts above. The successful production fixture is
`attempt-a2/scenario-a1/r-d13d25b0`. Compiler paths and source bindings are in the
compiler script/RSPs. Original Editor compilation emits three warnings in
unchanged Manager code; compilation succeeds. The seam emits expected local
exact-member type-shadow warnings; no assertions or native initializer are
rewritten. Full native Unity workspace/lifecycle execution is NOT_RUN.

The PASS141 scenario covers:

- All three v2 roles: absent, matching original process, producer precision
  matching after a 9-tick remainder, valid reuse 10 ticks apart with the same
  executable, query exception, null/malformed/missing current start identity,
  and invalid recorded start evidence. Recorded-invalid cases never become
  absence. Product observations only use explicitly listed synthetic PIDs.
- PID reuse still refuses active/foreign/malformed history, missing child,
  conflicting ownership, and live/unknown/invalid related MCP holder evidence.
  Holder tests retain the production lease parser and holder aggregator. The
  existing positive success/failure history proof, canonical equality, strict
  schema/size/count/reparse gates and preserved fingerprints remain exercised.
- The exact production current-owner branch is extracted without rewriting it
  and run for VERSIONED_V1 and LEGACY_FIXED: valid reuse still hits their original
  PID-only refusal. The original strict/default namespace inventory also refuses
  retired v2 evidence. Full legacy/v1 transactions are not claimed.
- Exact production preflight handler outputs saved child/stale/current live and
  unknown refusals plus missing-child refusal. The unchanged handoff production
  and consumption, configuration/selection/history drift, rollback and copied
  removal transaction remain covered. Observations change while record bytes and
  handoff remain fixed at existing lock-time, before-mutation and before-commit
  boundaries: original-live and unknown identity each refuse the stale permit.
- Copied successful removal reaches UNINSTALLED/PENDING and retains every history
  and stale-pair byte. Original terminal entry rechecks child and stale owner for
  live/unknown/reused/absent states. Original COMMITTED recovery refuses child and
  stale-owner live/unknown states before journal cleanup, preserves the journal on
  refusal, and clears only the journal once the original checks pass. Existing
  retained-byte drift and missing-whole-namespace refusals also remain covered.

The C# seam runs the unchanged bounded/redacted diagnostic assertions and exact
cache helper, then consumes all seven newly saved production refusals through the
original fixture consumer. It checks role/operation attribution, bounded length,
unavailable permits and UI diagnostic retention; saved success and incomplete
output behavior remain covered. It compiles the complete native Unity test
assembly but executes only the exact isolated source members, not native Unity
workspace allocation or Manager lifecycle.

## Attempts and retained boundaries

Initial scenario artifact `scenario-a1.log`, fixture `scenario-a1/r-2397b06a`,
and its Package overlay remain unchanged. That run stopped at the first emitted
child-live output assertion: success and failure histories reused one synthetic
PID, so the production reader could correctly attribute the first refusal to the
other operation ID. The fixture incorrectly assumed the first operation ID.
Its preceding basic classification/precision/holder checks passed. One causal
fixture correction gives the success history a separate synthetic PID; successful
attempt-a2 retains its own full overlay, fixture and log. No product classification
failure or production code correction was needed after the initial implementation.
One initial plus one corrected semantic attempt was used; no timeout or process
termination occurred. No failed evidence was overwritten.

Copied fixture bootstrap reports legacy closure cleanup PENDING because its
existing synthetic inspector refuses an unlisted setup PID. It performs no real
inspection and does not claim closure cleanup PASS. Required copied installation
and all141 declared scenario assertions complete; this warning is preserved in
the logs rather than changing generic/cleanup code or expanding the allowed PID
observations beyond the explicit scenario identities.

Protected snapshots cover all tracked paths outside the three-file allowlist,
real S29 Packages/.codex/AIWork, Manager receipts, dirty Payload/owner fixture,
accepted/predecessor Packages, earlier namespace/path-fix evidence and HEAD/index.
No differences were found. No production native child/IPC, real reader/preflight,
Install/Remove/Upgrade/Probe, Unity/MCP/CUA/BatchMode, environment change, process
control, cleanup, commit/export/reference switch, push or publication was done.
Copied-project production functions are the authorized synthetic fixture only.

No claim is made for actual history admission, actual removal-button availability,
target Ready, real removal, new Unity bytes, or S29 completion. The two known real
child=null records remain deferred and blocked by design. Non-Windows identity
comparison is explicitly unavailable; no other-platform execution is claimed.
CleanupMono remains deferred. Parent may admit this stable snapshot, then reuse
the authorized independent read-only Verifier. New source accept and separate
delivery authority remain downstream gates. Coder stops writing at handoff.
