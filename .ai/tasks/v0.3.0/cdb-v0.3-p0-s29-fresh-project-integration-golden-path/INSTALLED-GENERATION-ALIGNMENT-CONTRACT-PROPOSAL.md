# S29 generation alignment — proposed contract expansion

Date: 2026-10-12. Status: USER_APPROVED / IMPLEMENTATION_AUTHORIZED.
Source remains unmodified at approval. Coder's stable gap record is
INSTALLED-GENERATION-ALIGNMENT-RESULT.md. Independent gap review completed as
CONTRACT_GAP_CONFIRMED / NOT SOURCE PASS; see GAP-VERIFICATION.md with the same
prefix. User explicitly approved this presented expansion with "批准".

## Exact extension requested

Add optional `source_runtime_contract_sha256` to an exact canonical
bootstrap_transitions entry. It is the lowercase SHA256 of the predecessor
Package's original payload-manifest.json bytes. The generator receives the
independently validated frozen predecessor Package root and emits the field;
neither current generation hash nor a live activation/owner value is its source.
For this original42, the value is
538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d.
This value is fixture/contract evidence, not a hard-coded production exception.

Existing transitions without this field retain their existing meanings. This
new historical selected-v2 removal route requires it; absent, malformed or
conflicting authority fails closed. It does not grant runtime CURRENT, upgrade,
installation or cleanup permission.

## Producer / consumer closure

| Boundary | Proposed responsibility |
| --- | --- |
| Canonical generator | Separate corrected successor input from original predecessor Package; validate original closure; emit raw predecessor runtime hash and preserve original immutable bytes. |
| Read-PayloadManifest | Validate the optional hash when present and project it into the existing exact transition object. |
| Historical generation/selection | Resolve one Package-declared predecessor tuple and exact retained closure before deriving historical runtime authority. |
| Historical selected-v2 owner | Bind original target, selected instance, epoch, control contract and declared runtime hash consistently across state/lock and committed activation/operation; preserve holder/configuration gates. |
| Historical activation context | Use the Package-declared predecessor hash; verify records against it rather than letting activation choose its own trusted runtime hash. |
| Actual RemoveIntegration admission and pre-commit revalidation | Invoke-RemoveIntegration's three Assert-InstanceNextChangeAdmission call sites (current lines 11436/11455/11500) must carry the same removal-only, Package-bound historical context through activation/recovery checks. Preserve ownership, journal and resource gates; do not weaken the generic CURRENT/ordinary Uninstall path. |
| C# / Node transition readers | Verify real-reader compatibility with the generator-emitted declaration and unchanged five-field routing. Do not edit them merely to mirror a PowerShell-only removal field. If either must change, identify exact path/behavior and return before expanding. |
| Retained intent / fresh successor | Reuse existing authenticated removal and next-change readers; original retained42 stays inert, new43 publishes at a distinct path. |

## Bounded implementation and validation

Use the source task's existing allowlist: instance engine, materializer, canonical
generator and focused materializer/boundary tests. Permit only the named field
and its parser/reader semantics as the schema expansion. Preserve dirty Payload,
fixture and actual project bytes; generated metadata remains in an isolated
candidate projection. No new persistence platform or arbitrary history admission.

Focused evidence adds missing/malformed/wrong declared runtime hash, correlated
record tampering, mismatched original target/epoch/project/operation, unchanged
current-runtime validation and old-transition compatibility. Retain all source
task cases for generation closure, foreign/ambiguous holder, managed config,
logical removal and distinct successor fresh-install publication. Actual
production writers/readers are required at the changed boundaries; seams and
unrun real readiness remain explicitly labeled.

Independent gap review additionally requires actual Invoke-RemoveIntegration
evidence, not just preflight AVAILABLE: cover all three next-change reads and
revalidation before commit, including changed/conflicting historical evidence
and original holder/resource refusal. These are directly affected consumers
inside the existing two PowerShell allowlist paths, not a global reader bypass.

The already authorized Coder -> stable snapshot -> read-only Verifier route
continues after this extension is approved, within the original attempt/time
budgets starting with actual implementation (no test attempts consumed yet).
No additional delegation confirmation is required for that same task.
Verifier returns all findings to User; source ACCEPT is still a later disposition.
No actual removal/Install, Unity, cleanup, process stop, export, reference switch,
commit/push/publication or release authority is included.

## Decision

User explicitly approved this exact contract/loader responsibility expansion
on 2026-10-12 after the consolidated diagnosis and minimum scope were presented.
Continue the existing task-specific Coder -> stable snapshot -> read-only
Verifier stages without another start/delegation gate. No source ACCEPT or
real/delivery authority is granted by this approval.
