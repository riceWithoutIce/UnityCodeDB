# S29 retained candidate recovery - continuation

2026-10-09. CODER_STOPPED / PARTIAL / NO_SOURCE_PASS.
Same frozen TASK, baseline4ba4ccb6cfc437343c8e4cdc7c45816e4510882e.
Stopped prior RESULT remains unchanged. No real project/receipt/Provider/process
access, Unity actions, Payload writes, commits or exports authorized/performed.

Pre-write map reused from stopped RESULT: actual producers are historical
Payload~/Generations/poc.40 scripts, not legacy flat counterparts. Fixed adapter
files manifest.json/files.jsonl/index.jsonl bind output and providerName
codedb-<projectSlug>-<instance8>. TOML runtime token binds instances/<id>.
Pinned Provider src/cache.rs at28e3912d5cd67ff3499734984f3e3d626a204796 declares
six index manifest references to index/outlines/outlines_index/fingerprints/deps
.<unix-ms>.<pid>.<counter>.bin and bm25.<same>.postings. Exact watch/log/lifecycle
names and native-<32hex>.stdout/stderr.log are capture effects; lifecycle record
binds actual project fields. Instance/generation/origin identity remains owned
by existing strict production readers. No invented Provider identity fields.

Schema2 projection uses FailedCandidateEffectsRetained, independent of S27:
original action/stage/storage layout/project/Package plus authentic original
admission/claim/terminal and command identity hashes; retained instance,
generation, removal state, real v2 intent and current desired-state hashes;
current holder/no-active-authority proof. Original failed/unknown/incomplete
command outcome and receipt bytes remain unchanged. Actual committed Uninstall
producer and journal/session restore must revalidate real references; marker
presence cannot release a gate. Interrupted publication requires explicit
same-proof completion, no Install replay or manufactured EOF.

## Implemented draft and remaining acceptance

Draft modified10 allowlisted files: engine/materializer PS; journal/window/
lifecycle/host materializer/process-result C#; focused PS test; Manager UI and
lifecycle C# tests. Actions.cs unchanged. No independently accepted code yet.

- Engine draft classifies bounded exact advanced files and actual field binding;
  real removal-intent readers authenticate old closures before selecting one
  additional attributed candidate. Confirmed Uninstall can retain it from prior
  UNINSTALLED/PENDING; automatic cleanup keeps unknown candidates refused.
- Materializer draft authenticates original INSTALL receipt hashes/context/
  compact16hex filename vs full64 stage and separate legacy layout, exact
  original Package script/writer bytes, action/operation, failed terminal,
  writer/child absence and relevant process/holder proof. It emits new schema2
  after actual v2 intent commit through existing index lock. No old receipt edit.
- Journal draft reads real referenced intent and bounded retained effects,
  original receipt hashes and failed result; different READY/COMMITTED INSTALL
  handoff uses CurrentInstanceStore plus narrowly decoded activation/operation/
  wrapper mutation evidence. Existing Uninstall menu/admin recovery dispatch,
  worker preflight, cached Uninstalled presentation and separate session/result
  kind are wired. These C# drafts have not compiled or executed in Unity.
- PS test family uses real imported production engine/transaction/receipt/
  disposition functions with synthetic native process identities. New fixture
  root is dynamically bound repository-local rc41 evidence, preserved at stop.
  Advanced fixture bytes derive from recorded fixed producer declarations;
  config/adapter data are synthesized to that schema, not actual external
  Provider generation (no Provider execution). Authored C# test consumes actual
  PS emitted context via RICE_CODEDB_RETAINED_EFFECTS_PROOF; it does not fabricate
  a reader-only marker. No final marker/context was emitted by the failed run,
  so this cross-language test has no passing execution evidence.

| Frozen case | Actual evidence / status |
| --- | --- |
| early v2 preserved | New CURRENT early fixture passed production intent/removal/lease tests before advanced case. Complete family failed; no family PASS |
| bound old + one advanced -> two retained | cycle2 actual Invoke-InstanceUninstall committed second v2 intent; assertion two-retained-closures-preserve-old-intent passed. Old intent hash retained |
| original failed/incomplete receipt + committed intent -> final schema2 marker -> C# session | NOT PASSED. Actual pending writer succeeded; final explicit completion failed before final marker. C# tests authored only |
| unknown extra/unowned/project/hash/current authority/live ambiguous holder refusal | Existing CURRENT adjacent fixture cases executed before advanced case; detailed logs retained. New advanced refusal coverage incomplete |
| interrupted publication -> explicit idempotent completion | FAILED in production Publish-FailedCandidateEffectsRetained: pending file already exists; strict Write-DurableUtf8File Move rejects replacement. No third correction |
| next-change admission + fresh distinct Install handoff | New two-intent real reader passes during explicit retry, but post-disposition Assert-InstanceNextChangeAdmission/fresh Install test not reached |
| installed v1 preserved | NOT RUN in new family; original old suite failed at OLD wrapper compressed fixture hash before final v1 assertion. No v1 PASS claim |
| exact extracted Package same checks | NOT RUN; no package export/extraction performed |
| PS static parse | Both production scripts parsed before focused cases; final focused test script parse errors0 |
| C# compile/test, human Unity | NOT RUN. No existing isolated C# toolchain was available per Parent; authored source-level intent only |
| real retained candidate safety/S29/runtime/release | NOT RUN; source authorization excludes actual consumers/processes |

## Exact blocker, calls and retained logs

Test entry: `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass
-File com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
-RetainedCandidateRecoveryOnly` (stdout/stderr redirected to repository evidence).
Helper Invoke-RetainedCandidateRecoveryCase invokes actual engine
Invoke-InstanceUninstall -> Publish-FailedCandidateEffectsRetained.

Production gap in Tools~/materialize-codedb-host-payload.ps1 function
Publish-FailedCandidateEffectsRetained: explicit retry calls
Write-DurableUtf8File on existing
`resolved-action-<action_id>.pending.json`. That durable helper deliberately
publishes with create+Move and cannot replace existing pending bytes. The final
Move from pending to resolved is never reached. Same-proof completion must
validate/reuse existing partial publication without treating it as authority,
overwriting histories, replaying Install or weakening current receipt/intent
proof. This is the exact next same-scope causal repair; no broader design is
needed. No additional fix or retry was attempted after two allowed corrections.

Logs under `.artifacts/tests/rc41-retained-candidate-recovery/`:

- `ps-recovery.log`: first legacy FailedPreparationRecoveryOnly EXIT1,
  "Exact historical wrapper fixture bytes are drifted." This focused call used
  the existing OS TEMP default before inspection discovered it; that violates
  the repository-local fixture constraint and is not retroactively compliant.
  Child naturally exited; no process termination or business-process control.
- `ps-continuation.log`: new repository-local family EXIT1, empty string
  Get-TextSha256 fixture argument. Correction1 used actual empty files hash and
  guarded empty process inventory digest.
- `ps-continuation-cycle1.log`: EXIT1, failed candidate INSTALL argument reader
  erroneously wrapped Get-RequiredJsonArray in @() and nested the array.
  Correction2 removed that wrapper using actual array-return contract.
- `ps-continuation-cycle2.log`: EXIT1 at existing pending durable publication
  described above. It includes successful actual two-retained assertion.
  Evidence fixture is
  `.artifacts/tests/rc41-retained-continuation-62a4a47662364c8c840d6933c95808de/`.

## Limits and stopped identity

Actual returned UTF8 ledger exceeded adjusted160KiB at164897bytes (1057byte
overrun). Parent preserved this breach and authorized only additional16KiB
completion tail without resetting ledger. All calls guarded output <=5800bytes
before emission; required reads were rejected rather than truncated. Final
ledger before final artifact identity call178218bytes; after that call178291bytes,
within authorized completion-tail ceiling181281bytes,
but no claim of original160KiB compliance. Target60minutes/two corrections
reached; Parent instructed stopped snapshot, no further implementation or full
Verifier/source acceptance request.

Fresh stable exact11-file SHA256 snapshot:
`.artifacts/tests/rc41-retained-candidate-recovery/continuation-source.sha256`.
Includes unchanged Actions.cs for scoped identity. Protected Payload~ rehash:
417 files, relative-name=SHA256 UTF8 LF aggregate digest unchanged
`d395508812c306439d4c392ab26d492bd2346e579f64c0d563f67a697c7bb84a`.
Prior stopped RESULT/baseline remain preserved. Parent must admit the next
same-gap source correction separately; no commit/export/Unity/actual recovery.
