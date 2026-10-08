# Development Test Workspace Contract

Decision frozen: 2026-10-08. Scope: development/test temporary files and their
ownership. This document is the canonical contract; workflow and task cards
reference it. Design approval does not claim existing tests already comply.

## Root ownership

| Purpose | Owning context | Destination | Git policy |
| --- | --- | --- | --- |
| Repository script/non-Unity test scratch | Explicit authorized development checkout | `.artifacts/tests/<run-id>/` | Ignore generated contents. |
| Unity EditMode test scratch | Actual Unity project executing the tests | `Library/CodeDB/Tests/<run-id>/` | Ignore generated contents under Library. |
| Package exports and delivery intermediates | Authorized development checkout | `.artifacts/<candidate-id>/` | Follow workflow provenance/retention rules. |
| Development recovery backups | Authorized development checkout | `.backups/<backup-id>/` | Follow workflow protected-backup rules. |

The drive letter is not the policy: all test writes stay inside the applicable
development checkout or actual test project. A user project may be outside the
CodeDB checkout; its tests remain inside that project. Installed Package code
must not assume the consumer contains a CodeDB Git checkout. Package root is
source input, never the writable test root (it may be immutable/read-only).
Track source, this contract and concise evidence records, not generated trees.

## Single entry and isolated consumers

The test entry point establishes one workspace owner for its runtime. Unity
captures the real project context on the Editor main thread before any test
action override or background work. Repository runners receive or derive the
explicit authorized checkout context. Missing context is an actionable setup
failure, not permission to search drives, choose a sibling or use system temp.

The owner creates a unique run directory and passes explicit owned paths to
fixtures/helpers. Simulated project, Package, journal and receipt paths are
children of that workspace and cannot bind real project/runtime or machine
journal state. Lower-level helpers do not select roots independently. Existing
test-scoped injection seams remain test-only and restore prior context.

Do not use `Path.GetTempPath()`, process TEMP/TMP or a hard-coded fixture path
as the default for test-owned persistent writes. A GUID suffix alone does not
establish acceptable location, permissions or ownership. Do not introduce a
silent fallback to another root when the chosen workspace is unavailable.

If an authorized test child process requires temporary files, pass that child
its owned temporary directory using child-only environment/options. Do not
rewrite global/user environment variables, the entire Unity process environment,
ACLs or privilege level. Tools which cannot honor this boundary must report the
limitation before execution; do not expand this into a new process platform.

## Setup, cleanup and evidence

Before executing the test body, verify the resolved workspace is inside its
authorized parent at a directory boundary, has no traversal or reparse escape,
and is uniquely owned by this run. Probe the required create/read/delete cycle
inside it. On failure report the effective path and failing operation; do not
proceed under a different location or request administrator mode as a workaround.

Cleanup targets only exact descendants owned by this run, with ownership and
containment rechecked before recursive operations. It must never recursively
clear Library, `.artifacts`, the tests parent, another run or historical evidence.
Restore test scopes/resources even when cleanup fails. Preserve the primary
assertion/exception and report cleanup failure separately; a cleanup-only failure
also remains a failed test, not a swallowed error or PASS. Keep any residual path
in the failure evidence for later explicitly scoped cleanup.

## Implementation and acceptance boundary

Implement one shared test-workspace entry per runtime; a PowerShell and C# entry
may project this contract without each fixture inventing its own storage policy.
The initial correction covers S29 receipt/session fixtures and their directly
coupled tests. It does not authorize a repository-wide rewrite. For later touched
test paths, reviewers verify root origin, explicit propagation, isolation and
cleanup/error behavior as part of the existing review, not a new approval chain.
Focused validation covers a writable owned root, an unavailable root with no
fallback, bounded cleanup, scope restoration and primary-failure preservation.
Unity evidence remains human-owned; source review is not an execution PASS.

No production Provider installation, real Manager receipt, runtime candidate,
MCP registration or other machine-level state is relocated by this contract.
Existing external/system-temp leftovers are not automatically migrated/deleted.
Existing frozen artifacts and failure evidence remain unchanged. Implementing
this design, cleanup of old leftovers and running Unity retain their task-specific
authority; this design freeze alone authorizes none of those actions.

## Compact receipt layout agreement - 2026-10-08

The [Manager receipt storage layout](manager-receipt-storage-layout.md) freezes
the subsequently agreed example: one owned run root, direct Action containers,
Stage/evidence filenames, no receipts-GUID or project/Package directory nesting.
The later approved refinement retains full Action ID directories and Stage hash
prefix16 filenames solely for location, with full-identity collision validation.
Existing journal remains the lookup authority; old records stay in place behind
an explicit legacy reader. Workspaces use short exclusive names; exact allocation
must be specified before dispatch. This is a shared production/test layout target,
not a test-only bypass. That design freeze did not alter historical records.
Full consumer-path budgeting must include publication suffixes and target-runtime
deep-path probes; the existing shallow capability probe alone is insufficient.

The compact layout implementation was source-accepted after FIX01 on2026-10-08:
12hex exclusively reserved workspace names, full ownership tokens, actual production
path derivation and deepest-path probes. Historical records remain unchanged.
Human Unity compile and34methods/80cases remain pending; source/PS evidence does
not prove Unity System.IO behavior.
