# S29 declared Adapter output retention

2026-10-09. FROZEN / IMPLEMENTATION_AUTHORIZED.
User: `好的 继续，冻结后请你派发coder执行`.
Base HEAD: 2c85c37f25c2c4a8c1f40235ce60ce4cfd32c7ce.
Sequential depth-one child Coder -> stopped stable snapshot -> fresh independent
read-only Verifier -> Parent/User disposition. Preserve inherited dirty state.

## Frozen behavior

Authoritative design: reinstall contract `Declared Adapter Outputs and Retention
Boundary - 2026-10-09` and RETAINED-ADAPTER-DIRECTORY-SCOPE.md. Supersedes the
earlier empty-only admission proposal. Authenticated original failed INSTALL
candidate may retain ordinary files/directories inside the two declared mutable
Adapter output trees without interpreting names/content or requiring an Adapter
result manifest. Existing generated-artifact checks remain. Outside scope,
redirected paths, unreadable/incomplete inventory, snapshot drift and unsafe
holder/action evidence continue to refuse. Diagnostics on touched refusal paths
name the relative path/cause. No real recovery mutation is included.

Retention records existing v2 effects, deactivates integration and publishes
FAILED_CANDIDATE_EFFECTS_RETAINED/PENDING; preserve original failure/unknown.
It must not widen any physical deletion, readiness or automatic-replay route.
Existing inventory512 / intent128KiB limits remain; no new schema/platform.

## Declaration and consumer route

Add one dedicated side-effect-free PowerShell declaration:
`Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1`.
It owns candidate-relative Adapter root plus logs/tmp output-tree definitions
and their retention-only meaning. No duplicated path constants in consumers.
Prefer small functions/values over a new JSON schema or permission framework.

`Payload~/AIWork/codedb/scripts/codedb-project-common.ps1` imports the declaration,
uses it to bind context paths and initialize the trees. The successor generation
common script consumes the same declaration bytes. Existing adapter build
script already invokes that initializer; no build-algorithm change is needed.

Package `Tools~/materialize-codedb-host-payload.ps1` imports the Package-owned
shared declaration via its existing shared-contract route, and audits the new
flat/generation payload targets. `Tools~/codedb-instance-engine.ps1` consumes
it for failed-preparation effects only, including existing intent revalidation.
Never execute old project scripts to discover ownership. Historical observed
poc.40/poc.41 output scopes use this same declared layout only after existing
candidate/action/generation authentication. Do not add unbound project scanning.

## Successor and production write allowlist

Frozen Generations/poc.41 and all older generations are read-only byte-for-byte.
Create successor poc.42 from current poc.41 using existing Package identity/
generation conventions. Package version remains0.3.0-preview.5; bootstrap,
owner/control contract and record schemas unchanged. Generation42 is the sole
new sequence authority; consumers obtain identity from existing manifests,
never hardcode another version. Prior transition/trust entries are preserved.

Allowed production writes only:
- the new shared declaration and flat common-script consumer above;
- Tools~/materialize-codedb-host-payload.ps1 and Tools~/codedb-instance-engine.ps1;
- new Payload~/Generations/poc.42 (mechanical predecessor projection except
  declaration/common consumer changes and normal generation identity/hashes);
- Payload~/payload-manifest.json and Payload~/host-current.json, solely normal
  audited new file/current successor/byte closure projections.

Do not edit unrelated shared instance/provider/JSON contracts or C#/UI code.
Any further identity authority path requirement or incompatible routing must
be reported as one scope question before writes outside this allowlist.

Allowed tests: Tests~/test-codedb-retained-entry-routing.ps1 and existing
Tests~/test-codedb-host-payload-materializer.ps1 fixture builder only if needed.
One optional focused Tests~/test-codedb-retained-adapter-outputs.ps1 may keep
new cases separate. Coder result RETAINED-ADAPTER-OUTPUT-RESULT.md plus ignored
`.artifacts/tests/s29-adapter/` scripts/logs/snapshot. Parent owns other records.
Use apply_patch for source edits; mechanical generation/hash projections may
use the existing bulk-mechanical route. Never overwrite frozen artifacts.

## Focused proof

Use Windows PowerShell5.1, short dynamically bound repository-local fixtures;
no system TEMP or fixed fake project root. Actual on-disk materializer CLI
dispatch and production Adapter declaration/initializer must execute. Existing
Win32_Process fixture seam remains explicit; no replaced ownership decoder.

Required cases:
1. Complete production Adapter topology incl empty logs/tmp: preflight AVAILABLE,
   fixture/receipt byte equality.
2. Nonempty nested logs/tmp produced under the same initialization declaration:
   preflight AVAILABLE and read-only; confirmed synthetic retained Uninstall
   emits exact preserved entries/hashes, leaves original failure and PENDING.
3. Partial initialization without Adapter result manifest, with declared output:
   same scoped admission; no fabricated build/readiness success.
4. One effect outside declared trees refuses with concrete relative path/cause;
   redirect/reparse refuses (reuse existing adjacent proof if attributable).
5. Retained snapshot change refuses through existing intent reader; demonstrate
   declared mutable-tree admission did not weaken snapshot equality.
6. Source payload admission/byte closure passes for successor, both producer
   projections consume identical declaration and historical41 hashes unchanged.

Do not rerun broad older suites. New fixture digests should include directories
as well as files when proving read-only topology. Keep real projects/manager
receipts inaccessible to child. Parent exact-extraction and real read-only
preflight are later distinct delivery/operational gates.

## Execution and review bounds

Coder30min; initial plus2 causally corrected non-Unity attempts per scenario;
preserve failures, no blind retry. <=6KiB/read, <=50matches/search, <=128KiB
cumulative captured output. Disclose any breach; narrow further reads.
Tests wait120swarn/300sstop, never terminate external processes.
No child delegation, commit/export/download/Unity/MCP/CUA/BatchMode, real project
runtime/receipt access, process control or remote writes. Parent handles delivery.

Stable snapshot records base HEAD, touched paths/raw SHA256 and all changed
projection files, plus frozen predecessor generation manifest hash. Report seams,
actual assertion/CLI counts, attempts and unrun gates. Stop edits for independent
review. Verifier reviews original contract gap and immediately adjacent frozen
refusals/physical-cleanup separation only; findings go once to Parent/User.

S29 remains PARTIAL. User confirmed Unity normally closed and reference switching
allowed; do not ask again absent reopening. Standing prerequisites persist after
scoped disposition; actual retained recovery and new Unity launch remain separate.
