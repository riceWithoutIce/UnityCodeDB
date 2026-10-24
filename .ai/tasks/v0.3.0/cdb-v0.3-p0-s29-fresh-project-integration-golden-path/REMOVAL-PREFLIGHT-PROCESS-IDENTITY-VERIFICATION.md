# S29 v2 removal process identity — independent verification

Date: 2026-10-14 (Asia/Shanghai)  
Base: `39d79aeee1bd5525c6ed2eb1369f6c27334b9d07`  
Disposition: **SOURCE_AND_ISOLATED_PASS**  
Findings: **0 BLOCKER, 0 FOLLOW-UP** within this GUARDED scope.

## Admission and review boundary

The complete TASK, PLAN including its authorization addendum, RESULT and
SOURCE-SHA256 were read, together with the relevant workflow path gate and
test-workspace contract. Coder had terminated before review. This review covers
only the frozen three-file process-identity outcome and adjacent consumers. No
source was edited, test rerun, Coder repair requested or live operation performed.
The only write is this report.

All 25 frozen source/tool/evidence hashes match. The three source files also
match the successful overlay:

| Path relative to com.rice.ai-codedb | SHA-256 |
| --- | --- |
| Tools~/materialize-codedb-host-payload.ps1 | 22aa5eedc0f5f61e90f2c17cabbe4496cccd8ba1b2e33028c2101a02268b4f2c |
| Tests~/test-codedb-host-payload-materializer.ps1 | 4b9e60cb7906852e6de3a694b6303451cc69473b4593a593632ad96fe439089b |
| Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs | 49aacc0dd0065c32f9d451dfe40da05b7a540afffba71b826dc9e2ab0f2a7f45 |

Independent comparison found accepted/overlay counts 618/618 and exactly the
three authorized differences; accepted Payload remains unchanged. The earlier
ca316db Package has 617 files because the current accepted Package adds the
PreflightHandoff test `.cs.meta`; this task adds no Package file. This is source
attribution, not delivery acceptance. Current read-only comparison also confirms
all 4,174 protected entries unchanged, including real state, dirty Payload,
earlier evidence, accepted/predecessor Packages and HEAD/index. Index is empty.

## Frozen behavior verified

`Assert-RemoveIntegrationV2ProcessAbsent` validates recorded positive decimal
UTC ticks, DateTime range and microsecond comparability before observing the PID
(:10156). A definitive absent/exited result continues; matching observed identity
refuses as original-live; a different valid identity continues the remaining
gates as PID reuse. Inspection exceptions, unavailable/malformed current identity
and unsupported comparison remain unknown/refused. Invalid recorded identity
cannot be converted into absence or reuse.

The exact Windows Supervisor producer uses UTC ticks minus `ticks % 10`
(`codedb-project-supervisor.mjs:2556-2563`). The new comparison uses that same
precision on observed raw ticks, with no lease tolerance, executable-name
inference, implicit unit conversion or other-platform fallback.

The three consumers pass the recorded start identity with bounded attribution:
terminal child (:10235), paired stale owner (:10301), and current owner
(:10955). The current branch applies only to VERSIONED_V2; older authorities
retain the original PID-only refusal. Generic inspection, lease matching, holder
aggregation and all other existing production functions remain unchanged.
Strict history/owner validation, canonical equality, preserved fingerprints,
configuration/selection checks and selected/LKG holders remain independent gates.
No delete target, persisted authority, Ready/Install permit or process action was
added. Missing child remains the explicitly approved deferred refusal.

Existing revalidation invokes the same proof at entry/lock/before mutation and
through terminal validation before commit and recovery. The isolated fixture
changes observations while keeping evidence/handoff bytes fixed, establishing
that stale permits cannot override original-live or unknown identities.

## Mandatory and directly coupled evidence

Evidence root: `.artifacts/tests/s29-removal-process-identity/coder-a1`.
The following are inspected Coder results; they were not rerun by Verifier.

| Gate | Attributable result |
| --- | --- |
| PowerShell syntax, scoped diff-check, Package PathProvenanceOnly | PASS — `attempt-a2/l0-a1.log`; gate script targets the exact overlay. Independent scoped diff-check also passed. |
| Original-byte Editor and complete Editor.Tests compilation | PASS — `attempt-a2/Rice.AICodedb.Editor*-compile-a1.log` and RSPs; 30 Editor / 4 test sources, all overlay-bound, output assemblies present. Three unchanged Manager warnings are retained. |
| Isolated production call chain | PASS141 — `attempt-a2/scenario-a1.log`; independently counted 141 OK assertions, zero product native children. |
| Exact C# diagnostic/cache/UI consumers | PASS — `attempt-a2/seam-run-a1.log`, `exact-ast-binding.txt`, Runner/extractor; 13 original members, unchanged cache assertions/finally, explicit caller-owned fixture root. |
| Source scope and protected state | PASS — `source-overlay-check.log`, `protected-comparison.log`; independent hashes/inventory/current protection checks above. |

PASS141 covers all three roles' absent/live/reused/unknown/invalid cases,
9-tick precision normalization and same-executable reuse 10 ticks apart; active,
foreign, malformed and missing-child history still refuses. Live/unknown/invalid
related holder evidence still refuses. The exact current dispatch branch retains
VERSIONED_V1/LEGACY_FIXED refusal. Full v1 transactions are not claimed.

Lock-time, before-mutation and before-commit observation changes refuse; rollback
retains selection and proof. Copied removal reaches UNINSTALLED/PENDING without
changing retained history bytes. Original terminal/recovery entries reobserve
child and stale owner; refusal preserves the committed journal and valid proof
allows journal cleanup. Retained-byte drift and missing whole namespace continue
to refuse.

All seven saved process refusals were inspected: child/current/stale live and
unknown, plus missing child. The actual extracted production handler emitted
them, and the original C# fixture consumes them through bounded diagnostics,
unavailable permits and the original cache/UI path. Original redaction and
success/incomplete-output assertions remain exercised. No full argv, token or
handoff is introduced by these refusal messages.

## Attempts, limits and stop

The initial fixture/log/overlay remain retained. Its first child-live attribution
assertion failed because success and failure history shared one synthetic PID;
the reader could legitimately refuse the other operation first. The a2 fixture
assigns the success history PID424245 and lists it in the seam. The materializer
hash is identical between attempts. A2 also adds direct old-authority dispatch
assertions and saves refusal text before asserting it. This is one causal fixture
correction plus in-scope evidence completion, not a production repair/retry.
The bootstrap cleanup PENDING warning for an unlisted synthetic setup PID remains
visible and is not promoted to cleanup PASS.

One aggregate test diff output was truncated; the affected scenario ranges were
then read directly. No complete history, runtime census or broad audit conclusion
is based on that truncated output.

Native Unity workspace/lifecycle, live process inspection, real histories,
actual removal-button availability, real Install/Remove/Upgrade/Probe/IPC,
runtime/device/performance and release acceptance remain unrun. Classification
alone grants no removal or termination permit. The two known child=null records
and CleanupMono remain explicitly deferred; no finding asks to bypass them.

Mandatory source gates are present; none is waived. This report supplies the
independent bounded review, not user source acceptance or delivery authority.
No further in-scope work remains; findings are returned once and review stops.
