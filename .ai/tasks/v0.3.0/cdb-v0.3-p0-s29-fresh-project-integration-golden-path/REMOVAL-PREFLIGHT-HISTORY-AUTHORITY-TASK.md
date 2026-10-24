# S29 v2 removal history authority separation

Date: 2026-10-15. Status: HUMAN_REPORTED_PASS / S29_PARTIAL.
Workflow: codedb-workflow-v2 v2.6. Review: GUARDED.
Objective/contract: REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-PLAN.md, now approved;
diagnostic evidence: REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-DIAGNOSIS-2026-10-15.md.
User grant: `同意`, replying to the concrete three-file repair, isolated evidence
and reuse Coder -> independent read-only Verifier proposal. Not delivery authority.

## Route and execution

Mode: DURABLE_SESSION with user-approved task-specific transport exception to
reuse historical_handoff_coder then historical_handoff_verifier task-scoped roles.
Delegation: TASK_SPECIFIC / REUSE_ONLY / depth one. No new durable session,
binding/model change or recursive delegation. If old handles cannot be resumed,
record the concrete transport gap and obtain a route decision; do not silently
create replacement roles. Logical profile: deep Coder 60m / deep Verifier 30m;
reuse existing role model settings, record actual model/reasoning in results.
Parent remains active, receives questions and waits for terminal Coder, admits
stable snapshot, then dispatches Verifier and waits for its terminal result.
Verifier does not contact Coder or order repair. Findings returned together to User.

CONTINUOUS_WITHIN_SCOPE: scoped preflight -> implementation and same-cause
corrections -> focused evidence -> stable result/hash handoff -> independent
read-only verification -> consolidated user disposition. No intermediate ACK
or repeated start approvals. Source acceptance remains User-owned.

## Base and writes

Base HEAD: 544be4f7e339acefb47137b188cdc85e22483efb.
Branch: codex/v0.3.0-legacy-workflow. At pre-dispatch check index empty and the
three named files clean. SHA256 relative to com.rice.ai-codedb:

| Allowlisted file | Base hash |
| --- | --- |
| Tools~/materialize-codedb-host-payload.ps1 | 22aa5eedc0f5f61e90f2c17cabbe4496cccd8ba1b2e33028c2101a02268b4f2c |
| Tests~/test-codedb-host-payload-materializer.ps1 | 4b9e60cb7906852e6de3a694b6303451cc69473b4593a593632ad96fe439089b |
| Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs | 49aacc0dd0065c32f9d451dfe40da05b7a540afffba71b826dc9e2ab0f2a7f45 |

Coder owns only these three files, same-prefix RESULT.md / SOURCE-SHA256.txt,
and unique ignored helpers/evidence under
.artifacts/tests/s29-removal-history-authority/. Planner owns TASK/PLAN;
Verifier writes only same-prefix VERIFICATION.md.
Canonical Package input:
.artifacts/s29-removal-process-identity-544be4f/review/com.rice.ai-codedb (617 files).
Predecessor input: .artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb.
Do not add the old untracked test .cs.meta absent from this exact 617-file Package.
Do not use or regenerate dirty worktree Payload; overlay differs only by named
source/test bytes. Do not edit earlier evidence or accepted artifact inputs.

## Read closure and protected state

Read PLAN/DIAGNOSIS, workflow, test-workspace-contract, directly relevant roadmap
runtime identity section, prior PROCESS-IDENTITY RESULT/hash/verification and
existing exact-package scenario/compiler/C# seam tooling. Direct production
references: materializer removal history/owner/namespace/activation/handoff/
transaction/terminal/recovery, instance-engine generation identity/selection,
Supervisor context and operation/owner producer, directly coupled original C#
diagnostic/cache/UI consumers. DIRECT_REFERENCES_ONLY, no broad audit.

Protect all real S29 Packages/.codex/AIWork, Manager receipts, prior Packages/
evidence, dirty Payload/docs/old validation project, all outside-allowlist source,
HEAD/index and global settings. Reuse bounded hash-baseline helpers read-only
and compare before/after, excluding only declared owned writes. No runtime
history census or external product-process queries needed. No real product
reader/preflight/Probe/IPC, Install/Remove/Upgrade, Unity/MCP/CUA/BatchMode,
process control, cleanup, environment change, commit/export/reference switch,
push or publication. Local compiler/test shells allowed; product process
observations synthetic and copied-project-only, zero native product children.

## Frozen behavior

Implement the approved bounded provenance split, not a generic hash allowlist.
Authenticate selected instance closure/activation as before. Derive at most
selected-origin and current-Package-origin tuples from validated Package and
the single exact matching transition; deduplicate CURRENT, refuse ambiguous/
missing authority. No hardcoded generations/hashes/paths/IDs or directory scans.
Terminal operation schema lacks target/activation: preserve this schema and all
existing project/namespace/selected/terminal/child constraints, allow its hash
only from the derived applicable origins. Do not pretend absent fields establish
extra owner proof. Owner records require target/hash/disposition from one tuple,
not independently mixed sets; preserve activation, control identity, pairing,
fingerprint and process rules for stale/current. Keep original selection-runtime
context for activation and other unrelated consumers; do not broaden its meaning.
All original revalidation/terminal/recovery entry paths consume consistent rules.
Missing child, foreign/active/unknown records, live/unknown process and holders
remain refusals. No new delete targets, Ready/Install admission, history rewrite,
compatibility fallback, persisted schema or trust roots. Legacy/v1 unchanged.
Precise bounded operation/owner source-mismatch diagnostics, no secrets/argv.
If this frozen schema/allowlist cannot provide a safe coherent result, return
the exact gap rather than inventing schema or expanding authority.

## Evidence and convergence

L0: changed PowerShell parse; scoped diff-check; mandatory exact-overlay
Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly; original-byte Editor
and Editor.Tests semantic compilation via prior exact tooling. Use explicit
repository-owned test root and preserve failure evidence; no system-temp fallback.
Affected L1: extend existing RemovalNamespaceOnly production-call-chain fixture:

1. CURRENT single origin, TRUSTED_PREVIOUS mixed selected/current Package history;
   real producer field semantics, both source hashes represented.
2. Each origin's current/stale owners; cross target/hash/disposition, state/lock
   mixed owners, foreign selected/project and unknown/missing authority refused.
3. Existing process absent/live/reused/unknown/missing, active/malformed records,
   holders, canonical equality and preserved-history fingerprints remain covered.
4. Lock/before-mutation/before-commit provenance drift revalidation; copied
   transaction and original terminal/recovery; precise production refusal ->
   exact original C# diagnostic/cache/UI consumers and restoration.

Reuse compiler/seam tools by copying to unique owned root and changing only
input/output binding as needed; preserve assertions and exact-source binding.
Inventory overlay against canonical 617 files, exactly authorized differences;
freeze source/evidence hashes and protected-state comparison in result.
Do not rerun unchanged evidence after PASS or broaden to unrelated full tests.

Budgets: V2_DEFAULT output, Coder DEEP_60M, Verifier deep30m. Initial plus two
mechanical corrections and at most two causally justified semantic corrections
per affected local scenario family. Known previous task counts not reset; this
new bounded outcome is provenance separation, not child-null repair. Structural
ambiguity, second independent product cause, broader scope/trust/schema, missing
mandatory evidence or exhausted budget -> consolidated exact gap to User.

## Done / handoff

Stable three-file result, attributable hashes/base, mandatory L0 and affected L1,
unchanged protected state; Coder stops. Parent admits snapshot, then independent
Verifier reviews only this frozen outcome and adjacent regression evidence,
without rerunning tests or a full audit. Return consolidated findings once.
S29/release remain PARTIAL; child=null and CleanupMono explicitly deferred.
No human Unity or delivery/real removal PASS claimed from source/isolated evidence.

## Dispatch correction

The initial reused Coder returned an incorrect stale PASS claim. Parent admission
found no new source diff or RESULT/SOURCE-SHA256 in the shared checkout. Coder
confirmed no attributable history-authority snapshot existed; old process-
identity evidence is not evidence for this task. No Verifier was started.
User explicitly approved `批准重新派发同一 Coder（推荐）`; parent re-dispatched
the same frozen task to the same Coder. Scope and evidence boundaries unchanged.

## Stable snapshot admission

Re-dispatched Coder reached terminal completion and stopped writing. Parent
read RESULT and SOURCE-SHA256, confirmed all three working-tree hashes match,
HEAD remains base and staged index is empty. Exact overlay is617 with only the
three allowed differences; source/isolated PASS200, original-byte dual compile,
exact13-member C# seam and protected5818 are attributable in the current evidence
root. Runtime process inspection/Unity/delivery were not added.

Canonical input directory was observed as618 after human Unity import; parent
independently bound all617 original ZIP entries to matching directory bytes.
The sole additional .cs.meta SHA256 is
63b2a35a8ec29ed558ae263573a6ee43664ea1a17111352a61b1b6bc272aa20f.
Only that file was removed from the Coder-owned overlay, canonical unchanged.
Actual compile/scenario/seam ran with618; final617 differs only in that non-code
item, and PathProvenanceOnly was rechecked. This qualification is retained in
RESULT; no repeated semantic execution is claimed.
Initial local shell interruption and seam input-binding correction remain
declared. Independent read-only Verifier is now admitted for the frozen source,
declared proof and limits; no full audit or new runtime execution is authorized.

Verifier terminal result: SOURCE_AND_ISOLATED_PASS, 0 BLOCKER / 0 FOLLOW-UP.
Report: REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-VERIFICATION.md, SHA256
1bf2577491d32490bab44b2a1ddb99095794bb0ea8632ee351d9dcca2f0397db.
User source disposition is the next boundary. ACCEPT would accept this source
snapshot only; it would not authorize commit, export, reference switching,
Unity, Install/Remove/Upgrade, process control or release.

User accepted the source snapshot with `同意 accept`. Acceptance is recorded in
REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-ACCEPTANCE.md. No delivery or real-environment
authority is implied.

The user then authorized `commit → 精确出包核对 → 工程引用切换 → 人工 Unity
验收`. Delivery completed at commit `5b52c017e8415bb061f33a8380b3dcec2916411a`;
see REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-DELIVERY-RESULT.md. Only the human Unity
gate remains for this slice.
