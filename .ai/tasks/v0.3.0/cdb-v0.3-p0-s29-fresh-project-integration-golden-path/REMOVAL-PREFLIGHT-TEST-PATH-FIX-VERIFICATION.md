# Removal preflight test path — focused independent verification

Date: 2026-10-14 (Asia/Shanghai)  
Base: `ca316dba4a9567c754c92f0096d0b7a401a9a67d`  
Disposition: **PASS — original fixed-path finding closed**  
Findings: 0 BLOCKER; 0 FOLLOW-UP in this repair scope.

## Boundary and snapshot

This follow-up is confined to the original fixed drive-root test-helper finding
and its direct consumers. The TASK, RESULT, SOURCE-SHA256, Package Path Provenance
Gate and test-workspace contract were read. No source was edited, tests rerun,
repair dispatched, or wider audit started. The only write is this report.

Both corrected test files match the stable hashes in the source record and
overlay:

- `Tests/Editor/AICodedbEditorLifecycleTests.cs`:
  `292d4eead32cd7b311f9b1ca55bd4f9a5fd3e94ab7f8e218a11c9e947c3c86c0`.
- `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs`:
  `52d8945d5398eaca37120e17cae128cf5b956036f09a847a9876ed75b094587a`.

All 13 frozen source/tool/evidence hashes match. Independent read-only comparison
of the accepted Package and new overlay found 617 files in each, with exactly
the two authorized test-file differences. Every other accepted Package byte,
including Payload, is unchanged. HEAD remains the declared base; index is empty.

## Original path finding and root propagation

The Unity test entry now calls `AICodedbTestWorkspace.Run` and passes
`workspace.Root` to `AssertCachedRemovalFailure` (LifecycleTests:38-45). The
unchanged shared allocator captures the actual Unity project on the Editor main
thread, creates its owned `Library/cdt/<run-id>` root, and invokes the body only
after initialization. No alternate allocator was introduced.

The repository fixture test receives the explicit
`RemovalNamespaceFixtureRoot` TestContext parameter and passes it to the original
fixture consumer (PreflightHandoffTests:19-27). That consumer passes its same
root to the cache helper (:36). The repository runner separately requires the
existing task-owned `owned-fixture` root and passes it explicitly to the exact
helper and consumer.

The helper derives only `Path.Combine(testRoot, "project")` and
`Path.Combine(testRoot, "package")`; the fixed `C:/codedb-synthetic` paths are
gone. It selects no Temp, environment, discovered drive, or fallback root. Both
direct callers are updated. The scoped source diff changes only entry wrapping,
helper root parameter/path derivation and direct caller forwarding. All original
NUnit assertions and the cache-restoring `finally` remain unchanged.

## Mandatory source gates

Evidence root: `.artifacts/tests/s29-removal-namespace/test-path-fix-a1`.
These are existing Coder execution results inspected here, not Verifier reruns.

| Required gate | Disposition and artifact |
| --- | --- |
| Package PathProvenanceOnly | PASS in `path-provenance-a1.log`; exact overlay gate retained and hash-bound. |
| Original-byte Editor compile | PASS in `Rice.AICodedb.Editor-compile-a1.log` / `.rsp`; 30 original overlay source files, output assembly present. Existing warnings do not prevent compilation. |
| Full original-byte Editor.Tests compile | PASS in `Rice.AICodedb.Editor.Tests-compile-a1.log` / `.rsp`; four original overlay test files, including `AICodedbTestWorkspace.cs`, output assembly present. |
| Original diagnostic/cache/UI and direct fixture consumer assertions | PASS in `seam-run-a1.log`; `Runner.cs` passes the explicit owned root to the exact original helper and consumer. |
| Exact member and Unity-entry root binding | PASS in `exact-ast-binding.txt` / `extractor-a1.log`; 13 extracted members retain identical text, and Unity entry forwards `workspace.Root`. |
| Overlay/source equality, scope and assertion preservation | PASS in `snapshot-check-a1.log`; independently confirmed two hashes and 617-file comparison. Scoped `git diff --check` also passes. |

The harness executes the original bounded/redacted diagnostic assertions,
cached refusal/state/UI assertions, malformed/incomplete/timeout permit checks,
and saved production fixture output consumption. The helper restores cache in
its original `finally`. The extractor checks exact member text after reparsing;
it does not rewrite assertions or substitute the native workspace allocator.
Saved production fixture output is reused from the earlier isolated scenario;
this correction does not claim namespace/wrapper replay.

No mandatory source gate is missing or waived as an execution limitation.

## Acceptance boundary and stop

The full original native `AICodedbTestWorkspace.Run` entry is compiled and
source/AST-reviewed, but its allocation/probe/cleanup execution remains **NOT_RUN**
and belongs to human Unity acceptance. The extracted repository harness runs the
helper with an explicit owned root; it does not prove native workspace execution.
PathProvenanceOnly also does not replace downstream full Package-boundary release
acceptance.

The original finding is closed and the required focused evidence is complete.
No Unity/MCP/CUA/BatchMode, live reader/preflight, real Install/Remove/Upgrade,
environment/process change, cleanup, commit/export/reference switch or delivery
was performed by this review. Source acceptance remains the user's next gate;
overall S29 remains PARTIAL and CleanupMono remains deferred. This guarded
follow-up stops here.
