# S29 removal history authority: stable Coder result

Date: 2026-10-15. Base:544be4f7e339acefb47137b188cdc85e22483efb.
Status: SOURCE_AND_ISOLATED_PASS / STABLE_FOR_READ_ONLY_VERIFIER.
This is not User source acceptance, delivery, Unity, real removal or release PASS.
Route: reused task-scoped historical_handoff_coder, depth one, no new delegation.
Model/reasoning settings were inherited unchanged; this child cannot independently
query the actual model identifier. The parent route record owns that metadata.

## Implemented behavior

Only the three TASK-authorized source/test files changed,160 insertions/11 deletions.
New local Get-RemoveIntegrationHistoryAuthorities authenticates selected identity
through the existing exact Package identity/closure path, validates current Package
generation authority, then derives at most two tuples: selected target/hash/CURRENT
and current Package target/hash/TRUSTED_PREVIOUS. CURRENT deduplicates to one tuple.
Missing, conflicting or ambiguous origins refuse. No disk search, record-supplied
trust root, hardcoded generation/hash/ID, new persisted schema or compatibility
fallback was introduced.

Terminal operation schema remains unchanged: project/root/namespace/selected,
terminal/result, owner epoch, child and process checks still apply. Only its
runtime hash matches exactly one authenticated origin; absent target/activation
fields are not invented or claimed as extra proof. Owner target/hash/disposition
must match one whole tuple, retaining selection/activation, control identity,
state/lock pairing, fingerprints and current/stale process checks. Source mismatch
diagnostics identify a validated bounded operation ID or owner role, without
tokens or argv.

Exactly three existing production functions changed: terminal operation reader,
v2 namespace proof and owner-record validator. One local helper was added.
Original selected runtime context, activation, generic process inspector, lease
helper, authority/handoff, transaction, terminal/recovery implementations and
v1/legacy dispatch are unchanged. Their existing call paths consume the updated
local validation consistently. Removal targets, Install/Ready admission and all
real histories remain unchanged.

## Evidence

Evidence root (absolute):
G:/RiceProgram/UnityCodeDB/.artifacts/tests/s29-removal-history-authority/coder-a1/.
All logs/helpers below are relative to that owned root. Canonical input:
.artifacts/s29-removal-process-identity-544be4f/review/com.rice.ai-codedb;
predecessor:.artifacts/s29-post-install-ui-poc42/review/com.rice.ai-codedb.
Dirty worktree Payload was not used. SOURCE-SHA256 beside this result freezes the
three exact source hashes; overlay/source equality passes.
EVIDENCE-SHA256.txt in the owned root freezes logs and helpers independently.

| Gate | Result | Evidence |
| --- | --- | --- |
| Both changed PowerShell parsers, scoped diff-check | PASS | l0-a1.log; prepare-and-l0.ps1 |
| Initial PathProvenanceOnly | PASS on initial618 tree | l0-a1.log |
| Final exact617 PathProvenanceOnly | PASS, exit0 | path-final617.log |
| Original-byte Editor and full Editor.Tests semantic compilation | PASS, both exit0 | Rice.AICodedb.Editor-compile-a1.log; Rice.AICodedb.Editor.Tests-compile-a1.log; corresponding RSPs; compile-exact.ps1 |
| RemovalNamespaceOnly original production call chain | PASS200, native_children=0 | scenario-a1.log; scenario-a2/r-671f4b06/; run-scenario.ps1 |
| Exact original C# diagnostic/cache/UI consumers | PASS, exit0 | seam-run-a1.log; seam-compile-a1.log; run-seam.ps1; Runner.cs |
| Original member/source binding | PASS13 members | exact-ast-binding.txt; extractor-a1.log; extractor/Extract.cs |
| Exact shipped617 overlay inventory, source and production closure | PASS | source-overlay-check.log; verify-source.ps1 |
| Protected before/after, HEAD/index | PASS5818 identical entries | protected-before.txt; protected-after.txt; protected-comparison.log; snapshot.ps1 |

Commands ran in Windows PowerShell5.1 -NoProfile -NonInteractive -ExecutionPolicy
Bypass. Compiler and runtime paths are retained in copied exact tooling/RSPs.
Editor compilation emits three existing Manager warnings; full original native
Unity assemblies compile, while only the13 exact extracted source members execute
under the isolated C# seam. Native Unity workspace allocation/lifecycle is NOT_RUN.
The cache finally restoration and original assertions are preserved, not replaced.

PASS200 includes CURRENT single origin; predecessor two distinct producer origins;
current/stale owners from each origin; six cross-combinations refused per owner
role; valid-but-different state/lock source pairing refused; foreign selected,
project/hash; missing/ambiguous origins; mixed terminal histories and both stale
owner origins retained. Exact production handler saves three attributable source
refusals consumed by original diagnostic/cache/UI code. Original absent/live/reused/
unknown/malformed process, missing child, holder, canonical equality, schema,
count/size/reparse, fingerprint and retained-byte checks remain exercised.
Current Package provenance changes with unchanged permit/history at lock,
before-mutation and before-commit each refuse. Copied transaction rollback and
success, terminal revalidation and COMMITTED recovery all pass with mixed origins;
preserved history/stale-pair bytes remain exact, refusals retain the journal.

## Attempts and exact inventory qualification

The first task-owned local shell was accidentally interrupted by a Ctrl+C tool
input. Its scenario-a1/r-07c952bd fixture is preserved; it did not finish and has
no terminal log because the copied runner buffered until completion. It is
INTERRUPTED, not a test assertion failure or PASS. The unchanged source then ran
in scenario-a2/r-671f4b06 and completed PASS200. The runner retained the old output
filename scenario-a1.log; that log explicitly ends with the actual scenario-a2
root. No failed log was overwritten. The first seam invocation rejected setup
before running because its copied parent check still named scenario-a1; one
input-binding-only correction to scenario-a2 yielded PASS. No product semantic
correction was made. See attempt-notes.md.

The first final inventory assertion refused617 because the canonical directory
has618 files: the accepted ZIP/Git tree has617 and its sole directory-only extra
is Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta,
SHA25663b2a35a8ec29ed558ae263573a6ee43664ea1a17111352a61b1b6bc272aa20f.
The parent independently verified the discrepancy and all617 ZIP/canonical bytes.
Only this exact file was removed from the owned overlay after checking containment;
canonical and accepted ZIP were untouched, so it remains recoverable there.
This implements TASK's explicit no-old-meta boundary. No blanket meta exclusion.

Semantic/compiler/C# seam evidence ran on the initial618 tree. The final617 tree
differs from that tested tree solely by the non-code Unity meta deletion. The
affected PathProvenanceOnly gate was rerun and passed; unchanged semantics and
compilation were not rerun or misrepresented as a later execution. Final inventory
binds exact accepted ZIP SHA25665c0bcbb46f138941b5becf4dd59abbebb6528524db7ef5cff91c3e6c152e16a,
all617 corresponding canonical bytes, zero missing/extra, and exactly the three
authorized modified files. Every other shipped byte, including Payload, is equal.

## Boundaries and handoff

Protected5818 entries include all tracked paths outside the three source writes,
real S29 Packages/.codex/AIWork, Manager receipts, dirty Payload, old validation
configuration, canonical/predecessor inputs, prior process/namespace evidence,
HEAD/index. They are unchanged. Result/hash and unique owned helpers/evidence are
the only additional writes. No real product reader/preflight/Probe/IPC,
Install/Remove/Upgrade, product process control, Unity/MCP/CUA/BatchMode,
environment change, cleanup, commit/export/reference switch, push or publication
was performed. Product process observations were synthetic copied-project only.
The accidental interruption affected only this task's local test shell.

No actual history admission, removal unlock, Ready/Install button, real removal
or S29/release completion is promised. Known child=null histories remain refused;
CleanupMono remains deferred. Parent may admit this frozen snapshot for the
already-authorized independent read-only Verifier. User source acceptance and
any delivery/real operation require their separate downstream gates.
Coder stops writing at handoff.
