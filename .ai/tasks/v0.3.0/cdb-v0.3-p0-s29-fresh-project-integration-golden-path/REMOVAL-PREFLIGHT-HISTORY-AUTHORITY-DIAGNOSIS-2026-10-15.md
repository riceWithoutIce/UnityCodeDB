# S29 removal refusal — mixed history authority diagnosis

Date: 2026-10-15. Status: READ_ONLY_ANALYSIS / NO_REPAIR_AUTHORITY.
Source and selected Package commit: 544be4f7e339acefb47137b188cdc85e22483efb.
User continuation: `好的 我们继续`, following the proposed read-only attribution.
No delegation, product preflight, process query/control or real mutation was used.

## Finding

The current history reader conflates the selected instance's runtime contract
with the runtime contract of the Package that produced a Supervisor operation.
This is a deterministic source/data mismatch capable of producing the pictured
`Retained Supervisor operation has active, foreign or inconsistent identity.`
It is independent of PID classification and occurs before child identity checks.
It does not invalidate the completed bounded PID-classification acceptance.

The read covered only the current v2 Supervisor namespace and its 1017 history
JSON files (3,737,093 bytes), bounded by the existing 4096-record/32-MiB limits.
All records have maintenance lane, terminal completed/failed state with matching
phase, the same project/root/namespace, selected instance
d620abbab0334a2d9c49e59888c1ef55 and selected generation poc.42.
This field summary is not full strict product decoding or successful admission.

Runtime-contract distribution:

| Origin authority | SHA256 | History records |
| --- | --- | --- |
| Selected poc.42 predecessor, declared by the current Package transition and committed activation | 538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d | 1010 |
| Current poc.43 Package payload-manifest bytes | 69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a | 7 |

The seven records are all terminal failures from 2026-10-13T03:08:17.257Z to
03:10:55.514Z. They retain selected42 while recording the executing Package's
runtime contract. Their operation IDs are:
023ba757012744efa16a296508874bb0, cb60d76287524845974b6539cc23e741,
488d829eaa1a47adb5cf34241316e268, 588c7331e56148ec8af4bf370e1e91c2,
90c17e9c48b843c2a5c37ae4ddfdec53, e12dfd2d0d8144949299a7add3908cae,
1a43cdf055cd43d389388598b2cf93ae. All have a child record.

## Source chain and evidence limits

- Tools~/codedb-project-supervisor.mjs:228 reads the executing Package contract;
  :295-298 keeps selected generation separate from target generation and Package
  contract. :1481-1483 writes selected instance/generation alongside that Package
  contract into operation history. Thus selected42 plus Package43 contract is
  an expressible producer tuple, not by itself a foreign project or live process.
- Tools~/codedb-instance-engine.ps1:3622 resolves exact generation identity;
  :3673-3681 selects one Package-declared predecessor transition; :3720 returns
  its SourceRuntimeContractSha256.
- Tools~/materialize-codedb-host-payload.ps1:11001-11018 therefore supplies the
  selected42 predecessor hash to the namespace proof. :10280-10284 supplies that
  single expected hash to every history record. :10203-10205 rejects the seven
  Package43 hashes with the generic active/foreign/inconsistent message.
- The worktree and exact Package materializer hashes both equal the accepted
  22aa5eedc0f5f61e90f2c17cabbe4496cccd8ba1b2e33028c2101a02268b4f2c.
  The current Package payload-manifest SHA256 equals the Package43 hash above.
- No real preflight was replayed. The screenshot clips its detail and carries
  no operation ID. History validation iterates hashtable keys, so this diagnosis
  does not identify the first record encountered by the photographed invocation
  or exclude earlier independent refusals. No persisted full Manager refusal
  was found in Library/CodeDB (only the Tests directory was present).

## Independent retained boundary

Two predecessor records still have child=null:
45e02ba862654c81af4d592dc56e49d3 (Probe completed, exit0), and
69d2e7c44f774e3687e352d5faf9eb97 (Upgrade failed, exit1).
Their missing-child refusal remains required; terminal outcome does not prove
child absence. Fixing history authority alone cannot promise unlocked removal.
Current process identity for other recorded children was not inspected here.

## Proposed next alignment

Separate installed selection/activation authority from operation-producing
Package authority in a bounded history contract. Enumerate only explicitly
trusted current/predecessor tuples and their original selection/project binding;
do not accept an arbitrary hash, a record's self-declaration, or all old versions.
Before implementation, define whether those tuples provide sufficient ownership
proof and how owner/stale records and existing revalidation consume them.
Do not change selected42 or its activation to Package43 merely to pass equality.

Preserve strict schema, terminal/child/process checks, closure, canonical-history
equality, fingerprint/revalidation and foreign-record refusal. Improve this
specific authority-mismatch diagnostic to identify a bounded operation and
cause; do not merge it with active-process refusal. Missing child remains a
separate deferred decision, with no fabricated proof, history rewrite/deletion
or compatibility fallback. CleanupMono stays deferred.

This record changes no source, Package, project reference, runtime or history.
HEAD remains 544be4f7e339acefb47137b188cdc85e22483efb; staged index remains empty.
No test, Unity, Install/Remove/Upgrade, export or release evidence is added.
S29 remains PARTIAL. A concrete repair contract and new source authorization
are required before implementation; this analysis does not authorize that step.
