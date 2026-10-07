# S29 Instance Manifest Closure - Targeted Verification

Date: 2026-10-07. Role: independent, read-only child Verifier.
Result: PASS for the bounded source review, with one non-blocking FOLLOW-UP.
Findings: 0 BLOCKER; 1 FOLLOW-UP. No fixes were dispatched.

This verdict addresses the original flat instance decoder / exact 17-field
admission failure and its adjacent regressions. It does not declare full
malformed-input equivalence, a real candidate recovered, human acceptance,
exact extracted-artifact closure, whole S29 or release PASS.

## Frozen inputs and admission

The full REVIEW-PACKET, bounded PLAN and RESULT, compact IDENTITY, and the two
named contract/workflow sections were read. No whole TASK, historical review
corpus, session record, real project/runtime or PENDING candidate was read.

- Branch: codex/v0.3.0-legacy-workflow.
- HEAD: 70f33f7e9f7b39b63aaf9c1d4eedba122f67799a.
- Package/source candidate: 0.3.0-preview.5 / poc.40 / sequence 40.
- PLAN: 9648 bytes; SHA256
  bcd26679b6f5748d1af47fdf375928cd6686ea2cad5c554c23db80265da7323a.
- RESULT: 12606 bytes; SHA256
  3ae1709e4e57200adb5a196115335852868d45ac78059a0e8ee6f31cb64b5c3a.
- IDENTITY: 5656 bytes, 39 ordinal rows; SHA256
  c4a1cfe61877dfce0bd81759840f4b64fd08d1c987b5e9bb76ea1b13be4dba0d.

Initial admission and the final handoff recheck both PASS: all 39 source file
hashes matched, identity encoding was strict UTF-8 without BOM with LF/final LF,
and frozen document hashes plus Git identity matched. The final check also
confirmed poc.40 has exactly 26 regular files and no reparse entry.

Protected generation proof excluding poc.40: 332 regular files; aggregate
502bf6d2e3bbc697ed1d5927deb16274cbbb6ecb76c729b6838af71217c32dc9,
matched at admission and handoff. The complete old-generation table was not
printed. C# projection hash remained
34ea23e11d5b0704c57cd4048a1bd9450fd5134780c9b8d504c5ea792b77dcac;
canonical/poc.39/poc.40 Provider helper hashes all remained
ebcaf8792a5f759ed9639c7250d1d411362ec4a90a32dcbf506020b10fd872be.
The scoped Git diff showed no C# source or canonical Provider helper edit.

## Original gap and adjacent consumer coverage

All source paths below are relative to com.rice.ai-codedb.

| Boundary | Verification and attributable evidence |
| --- | --- |
| Production writer / atomic bytes | Tools~/codedb-instance-engine.ps1:2057-2127 binds the shared origin validator, retains New-InstanceManifestDocument and Write-InstanceManifest, and serializes the origin as an object. Tests~/test-codedb-host-payload-materializer.ps1:465-505 checks production function-body identity, writes through the actual writer, then calls the actual copied poc.40 reader/context. |
| PS decoding | poc.40/scripts/codedb-project-common.ps1:207-234 retains bounded size, BOM and strict UTF-8 checks and calls ConvertFrom-CodedbInstanceManifestJson. The shared recursive parser retains duplicate/case ambiguity, nesting and trailing-content rejection. The four unchanged parser-body comparisons are reused Coder static evidence. |
| PS field admission | The same common file:247-315 calls Assert-CodedbInstanceManifestFields, admitting the 17 required fields plus optional originating_action. The old fixed-count gate is removed. Path containment, no-reparse, directory/project identity, PROVISIONING/READY, Package/generation/protocol, generation hash and worker hash checks remain. RETIRED and wrong-generation-hash rejection are actual context cases. |
| Shared PS callers | Source bindings establish 14 callers through Get-ProjectCodedbContext and Assert-CodedbUnityProject, whose instance branch calls Assert-CodedbInstanceContext (:332-336). They include prepare, build/probe adapter, verify, watch including its failure/cleanup action route, freshness/index/refresh, MCP draft/config and Provider guidance. No individual action rewrite is needed to reach this shared boundary. |
| Node stable front door / worker | The stable wrapper:116 and poc.40 worker:258 unconditionally call the imported parseCodedbInstanceManifest after their existing bounded/strict byte read and selection/path checks. Identity/state and worker/generation binding remain outside the pure decoder. The Node fixture:17-32 checks helper-copy equality, both real imports and call statements, and decodes the exact PS case files through both helper copies. It does not import either service. |
| Other direct readers | Current/LKG and retired instance routes use Read-BoundedJsonDocument and retain origin validation; retained removal-intent reads retain hash/identity/path checks and do not interpret origin. The Supervisor instance route (:3208) uses its existing recursive parseStrictJson, which supports object/null. These are inventoried source routes, not new operational acceptance claims. |
| C# / Provider | Existing C# instance and control projections already validate origin (:330, :467 and AICodedbControlContract.cs:624); their source is unchanged. The Provider helper and its separate flat contract remain unchanged. No C# compilation or Unity replay occurred. |

The pure PS and Node projections accept absent/null origin and the three
existing action values, require exactly the three origin properties and string
IDs, and preserve the directly coupled invalid-origin rejections. Attribution
does not replace selection, readiness, ownership or an effect-point permit.
The narrowly identified final-newline ID edge is listed below as FOLLOW-UP.

## Successor and evidence assessment

The existing release-closure route admits one -SuccessorGenerationId, derives
sequence from that identity and the prior sequence, rejects an existing target,
projects common/worker from the prior immutable template, copies the three
canonical helpers, enumerates new files and derives coupled metadata. Inspected
New-CanonicalSuccessorGeneration retains prior transitions and appends the
poc.39 predecessor record. Eight historical transition values/order, remaining
coupled hashes and fixture identity projections are supported by the frozen
Coder evidence and matching handoff source hashes. No generator was invoked.

The following results are reused from the frozen COMPLETE RESULT; they were
not rerun or promoted to external acceptance:

| Evidence | Accepted declared result |
| --- | --- |
| Static/source | PS 10 / Node 5; 14 PS callers; four retained PS parser bodies; unchanged C#/Provider. |
| InstanceManifestContractOnly | PS 45; Node 26 byte cases / 52 helper decodes; one test-owned Node runner; zero service children. |
| Adjacent regressions | FirstInstallAttributionOnly 26 and NextChangeAdmissionIntegrationOnly 45, both first-attempt PASS with zero native children. |
| Source candidate | PathProvenanceOnly PASS; release-closure source_count=52 / mismatch_count=0; scoped diff-check and old-generation/history protection PASS. |

The early focused selector returns before the full-harness stubs. Its production
body assertions, actual common import, writer/reader/context calls and Node
case-byte transfer substantiate the original decoding/admission closure.
Declared L0 accounting remains four physical starts, with one semantic and two
mechanical corrections. The Coder's recorded earlier output/cumulative guard
breach is retained as a deviation; this report does not relabel it compliant.

## One-time finding

F-IMC-01 - FOLLOW-UP / P3: final-newline origin IDs pass the PS projection.

At Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1:16-17,
the .NET regex ^[0-9a-f]{32}$ can match before a final LF. A JSON string
containing 32 lowercase hex characters followed by an escaped newline therefore
passes the PS ID checks although the frozen representation says exactly 32
characters. The Node counterpart :91 uses JavaScript's non-multiline end
assertion, which requires the end of input; this is a projection consistency
edge. Each generated helper is byte-identical to its canonical counterpart.
The PS writer already used this regex before the repair; ordinary GUID-N IDs
and the original Install path are not made unavailable by this edge.

This is a format-exhaustion edge under the frozen FOLLOW-UP threshold, not a
source-window BLOCKER or a basis for broadening this review. No test was added
or run to investigate it. Return the finding once to User/Planner for
FIX / DEFER / ACCEPT; no Coder contact or repair request was issued.

## Budget, handoff and acceptance boundary

Review started 2026-10-07 08:42:54 UTC. Final source identity check passed at
08:54:08 UTC, approximately 11 minutes 14 seconds after the first budget clock.
Per-call output remained bounded; no Verifier output was truncated. The
conservative inspection-output ledger approached 128 KiB (about 130.4 kB), so
further semantic source reads were stopped before handoff. A 5000-byte
workflow-section allocation was replaced by its actual 3123-byte output count;
this was bookkeeping, not a test/parser replay or replacement evidence.

The only write was this report via apply_patch. No tests, product scripts,
parsers, generator, service/process probes, Unity/MCP/CUA/BatchMode, real runtime
access, candidate cleanup, source/config/artifact mutation, commit, export,
push or publication occurred. No grandchildren or Coder/durable-chat contact.

PASS closes only this bounded source review. The original failed Install and
cleanup PENDING remain preserved packet evidence. Extracted-artifact byte and
consumer closure, separately authorized candidate handling, human Install /
Ready / Uninstall / Reinstall / shutdown, whole S29 and release gates remain
unresolved. All Verifier writes stop with this handoff.
