# Install quarantine admission repair result — 2026-10-26

Outcome: `SOURCE_IMPLEMENTED / FOCUSED_HARNESS_PASS`.
This is a stable uncommitted source result, not real Fresh Install acceptance.
Baseline: `11056964da1143955ed69a067361622799e3d6f2`.
Source checkout: `.worktrees/cdb-v03-install-quarantine-admission`.
Branch: `codex/install-quarantine-admission`.

## Final behavior and scope

Only Install admission and a focused test were changed. The namespace scanner
recognizes the producer's exact paired stale state/lock filename shape, caps
the pair count at 32 and each record at 256 KiB, and rejects incomplete pairs.
It checks typed project/root/runtime/control identity and stable owner/pair
coherence, then calls the unchanged original-owner process absence assertion.
Missing processes or valid PID reuse allow continuation; live same-start,
incomparable or unavailable process identity remains blocked.

Historical instance/generation/activation values are checked for shape and pair
coherence, not forced to equal the current/new selected instance or Package
runtime contract. No old Package or instance closure is reopened for quarantine.
Dynamic publication/readiness metadata, auth tokens and diagnostic fields are
not admission prerequisites. No generic whole-record field allowlist is added.
Quarantine remains byte-for-byte retained and supplies no activation/deletion
authority. Existing history, writer, retained-MCP and execution gates still run.

The removal-specific full owner/namespace proof is not reused; the pure pipe
derivation, bounded JSON/path helpers and original Windows process-start
comparison are reused. No shared lifecycle redesign or payload update.

Stable file hashes:

| Source path | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `cedb50d67fe09a663c582cbec35dbcff42d3b08ae995aff280c6f337c169d6e2` |
| `com.rice.ai-codedb/Tests~/test-codedb-install-quarantine-admission.ps1` | `c5b1fee0226930b0810324ad14e95a9e96583e5c3e44a382830c8e0e1f564aa6` |

## Verification

| Evidence | Result |
| --- | --- |
| Parse both changed PowerShell files | PASS |
| Focused production admission harness | PASS, 28 checks |
| Retained-MCP adjacent `-L0Only` regression | PASS, 17 checks |
| Scoped diff/whitespace check | PASS |
| Real consumer compilation/Install/Ready/reopen/MCP | NOT_RUN |
| Independent Verifier | NOT_RUN, no delegation |

Canonical evidence:

- `.artifacts/tests/cdb-v0.3-install-quarantine-admission/03/`
- `.artifacts/tests/s40-retained-mcp-install/quarantine-final-l0/`
- `.artifacts/tests/cdb-v0.3-install-quarantine-admission/source-snapshot/`
  preserves both final source files and a manifest binding their hashes to the
  two canonical test-input manifests and terminal result hashes. Both harness
  manifests were verified to contain the exact final engine hash above.

Both canonical harness runs use Windows PowerShell 5.1 and the original
production functions loaded by the existing AST fixture convention. Process
observations are synthetic, explicitly recorded. The retained-MCP fixture also
uses its existing synthetic prerequisites and PocFixture backend. These runs do
not demonstrate actual Node/Provider availability or real process exit.

Focused checks cover the original normal path, historical pair acceptance and
byte retention, PID reuse, live/unknown/unavailable/incomparable identity,
missing/mismatched/foreign records, malformed process evidence, oversized and
redirected inputs, pair budget, current/unknown/takeover entries, pending and
incomplete execution, missing canonical anchor, unknown child disposition,
writer admission and live competing project execution. The OS observation seam
does not stub any production JSON/path/control/quarantine/absence validator.
No actual child-process crash/recovery or retained live-child lifecycle experiment
was performed. Original execution safety checks remain unchanged.

## Corrections and retained intermediate evidence

Initial implementation parse errors were corrected before behavior evidence.
The first test scaffold was replaced before any passing behavior result: its
proposed JSON/path/process-validator stubs would not have established the agreed
production evidence. The final test contains only declared OS observation seams.

The first two retained-MCP attempts used the available PowerShell 7.6.5 host and
failed before quarantine validation with a strict JSON root-type error. Their
artifacts remain at `quarantine-candidate-l0` and `quarantine-candidate-l0b`
under the retained-MCP artifact root. The stock strict JSON reader reproduced a
List/object return mismatch under that host. No JSON/product compatibility repair
was added. Switching to the product's existing Windows PowerShell 5.1 execution
host yielded PASS, first at `quarantine-windows51-l0`, then at the canonical
final-source run. This does not establish general PowerShell 7 compatibility.

Two unnecessary conditional pre-run cleanup command proposals were rejected by
automatic command review; neither deleted files. Work continued safely with new
unique output directories. There was no runtime Install retry or forced cleanup.

Preliminary focused scaffold runs found task-root/path-expression issues and
type differences; an owned intermediate run under the source checkout was kept
as noncanonical fixture output. The first production-validator run `01` stopped
on a test-only OrderedDictionary Clone method error after normal admission PASS.
The fixture copy was corrected; `02` passed 26 checks, then `03` passed the final
28 with incomparable-start and unknown-disposition assertions added. No previous
run was overwritten/deleted or relabeled PASS. Temp probe script removed from
the source checkout; no test hook was added to production.

## Remaining boundary

Source delta is confined to the two named files; primary Package source and the
delivered candidate remain unchanged. No consumer, runtime/quarantine, registry,
MCP config, external process or Unity action was changed. No commit, export,
delivery, reference switch, push, board update or release.

The original exit-6 failure is preserved and real lifecycle acceptance remains
BLOCKED until a new accepted candidate is separately delivered and one human
normal Fresh Install succeeds on retained CodedbTest_2. Do not manually remove
quarantine, create a clean replacement project, drain clients or replay the old
candidate to make the test pass. Next review/accept this exact source delta,
then agree the bounded commit/export/delivery procedure. Human Unity closing
and actual Install remain separate gates.
