# S29 payload admission independent verification

2026-10-09. **SCOPED_SOURCE_AND_SAVED_EVIDENCE_PASS**. Original six-path
admission blocker is closed at the frozen working-tree snapshot. No blocking
finding or adjacent product finding remains in this review scope. S29 remains
PARTIAL; committed delivery and human/runtime acceptance are separate pending
gates.

## Authority and attribution

Coder was stopped before this independent read-only review. Reviewed the complete
PAYLOAD-ADMISSION-TASK.md, PAYLOAD-ADMISSION-RESULT.md and review packet, the
three tracked production/export diffs, the entire focused harness, targeted
actual-reader/dependency/control-flow excerpts, the two scoped workflow additions,
and saved raw outputs, commands and fingerprints. No Coder messages, nested
agents, test execution, runtime/Unity launch, cleanup, consumer operations or
production edits. This VERIFICATION is the only Verifier write.

Task SHA256: `f2498663b9a41bacd02243f5877a734526b43232faa03426d23cc2692d88f74d`.
Result SHA256: `5830bba57e720e3e1d6dd03d667ef66bca6ca0f210c25c7cc0b6d49072077365`.
Both were directly rechecked. Base commit and saved fixture provenance are
`8b2061d45504da551b626714a877176051a43fe1`; no new delivery commit is claimed.

Paths below are relative to com.rice.ai-codedb/. Current source hashes equal
RESULT, final parser-proof hashes, and the corresponding stage/extracted files:

| Path | SHA256 |
| --- | --- |
| Tools~/materialize-codedb-host-payload.ps1 | 1708bf8df295953c40a3698f6781f7e488076de4516b8b303a529aaaf918e65d |
| Tests~/test-codedb-package-release-closure.ps1 | d5100c392056174746bd63f02766f68d9eac284173173adb30213153650b57f2 |
| Tests~/export-codedb-package.ps1 | c0e4da862e6b3f4e6276dc9ce017d7223ce0ea8cd2a68ce8b8aa90b44c91668f |
| Tests~/test-codedb-payload-admission.ps1 | f142a2bda5bd7f3e83887053ed18ec72c75b2fed374c867c173706a5b5bee2e5 |

## Scoped conclusions

1. **Exact admission policy PASS.** Materializer additions are exactly
   `native/win-x64/build-manifest.json`, `native/win-x64/codedb-daemon-launch.exe`
   and `shared/codedb-daemon-launch.mjs` in the flat and generation allowlists.
   Assert-TargetRelativePath (line 1134) still normalizes paths and requires exact
   map membership, including generation-relative membership. No new directory
   wildcard or permission derived from manifest declarations. Saved six-targets
   evidence names all six canonical entries, including generation poc.41.

2. **Actual reader and non-mutating route PASS.** ValidatePayload (line 11642)
   uses the existing initialization and Read-PayloadManifest (line 1177), not a
   copied parser or policy. The reader invokes the unchanged strict bounded JSON,
   owner/version/control contract, exact target admission, source/hash and
   source/target containment/reparse checks, and generation-contract validation.
   Its branch returns before the normal project-state, Unity marker,
   prerequisite, lock and runtime dispatch. Failure handling does not publish a
   mutation result: Write-MaterializerCommandResult returns for this action
   because Test-MaterializerMutationAction does not admit ValidatePayload.

3. **Export binding PASS at source scope.** Standard release closure invokes
   this materializer subprocess before metadata projections (line 302); failure
   stops before closure PASS. Exporter's Invoke-PackageClosureValidator requires
   exit zero and separate PRODUCTION_PAYLOAD_ADMISSION and PACKAGE_BYTE_CLOSURE
   PASS markers (line 19). Its unchanged normal export sequence invokes the gate
   for the archived commit stage (line 104) and exact ZIP extraction (line 113).
   Byte closure and production admission remain separately attributable.

4. **Adjacent rejection regressions PASS from saved evidence.** Both copied
   negative manifests have 58 entries and identical source/hash tuples to the
   stage manifest. Each changes exactly one build-manifest target to
   `native/win-x64/unaudited-adjacent.json` in its selected layout. The saved
   reader failures name that exact unaudited target; the export failures name
   production admission exit 2. They cannot pass merely through a later
   generation/runtime-identity mismatch. Neither negative gate emitted closure
   or export PASS.

5. **Preservation and focused workflow scope PASS.** All seven saved Package
   before/after fingerprint pairs are byte-identical, as are source before/after
   and stage/extracted fingerprint files. Baseline protected Payload tuples and
   saved final source Payload tuples match for all 417 files. Final capture code
   and proof bind protected generation/manifests/current-pointer bytes and
   pre-existing tracked dirty hashes, excluding the declared Parent-owned
   workflow document. Harness checks that logical projection roots were never
   created. The two current workflow additions (lines 909 and 916) concern the
   actual-reader gate and the directly affected manifest producer/reader/negative
   consumer map; they do not require an unchanged full-suite replay. Unrelated
   pre-existing workflow edits were outside this review. No history repair or
   consumer action was invoked by the reviewed focused route.

## Saved evidence reused

All paths below are repository-relative. The Verifier inspected these retained
records; their executions belong to Coder, not to a new Verifier test run.

| Evidence in .artifacts/tests/ | Observed result |
| --- | --- |
| pa41-baseline/{exit-code,stderr}.txt | Original actual reader exit 2; known flat build-manifest target rejected |
| pa41-admission-01/canonical-source.* | Exit 0; actual reader PASS; file_count=58 |
| pa41-admission-01/source-snapshot-stage.* | Exit 0; separate admission/byte closure PASS and export-gate PASS |
| pa41-admission-01/exact-zip.* | Exit 0; same separate gate outcomes on exact extracted snapshot |
| pa41-admission-01/unknown-flat-reader.* | Exit 2; exact adjacent unaudited flat target rejected |
| pa41-admission-01/unknown-generation-reader.* | Exit 2; exact adjacent unaudited generation target rejected |
| pa41-admission-01/unknown-{flat,generation}-export-gate.* | Exit 1; actual production admission failure; empty stdout, no export/closure PASS |
| pa41-admission-01/{six-targets,source-script-hashes,summary}.txt | Six-entry coverage, attributable frozen scripts, no-write harness completion |
| pa41-admission-01/*.package-{before,after}.txt and source-{before,after}.txt | Retained full file/directory fingerprints agree |
| pa41-final/{capture.ps1,proof.txt} | Saved Windows PowerShell 5.1 parser PASS for four scripts; preservation and ZIP hash proof |

Positive closure output retains two existing native VerifyOnly byte-binding
checks. This is not a native build, launch or daemon runtime result.

## Delivery and acceptance boundary

The harness archives the base commit and overlays exactly the four repair
scripts, then calls the existing deterministic ZIP helper and validates its
exact extraction. ZIP SHA256 is
`9cd3d76dfdccab0bcaa5af0646da75500520ecd963aa603237b6fa180e1eea92`;
runtime contract remains
`c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba`.
This is attributable source-snapshot gate evidence. It is not a final artifact
exported solely from a new frozen commit. Parent still owns that committed
delivery prerequisite and any authorized consumer reference switch.

Real Install/recovery, C# compile/test, Unity/EditMode, Provider, live consumer,
runtime and release acceptance remain unrun by this review. Historical poc.40
failure evidence is not a repaired fresh Install result. No such acceptance is
inferred from this PASS.

## Process deviations and stop

Coder's disclosed early output-budget breach remains recorded. Verifier's early
combined reads/searches also exceeded the requested output allowance and/or
were truncated; later targeted excerpts recovered needed source context, but
do not retroactively establish output-budget compliance. This is a workflow
deviation, not an additional product blocker under the user's frozen thresholds.

Original blocker and directly adjacent focused regressions are closed at the
identified source snapshot. No broader audit or repair request follows. Verifier
stops here; final delivery and human/runtime gates remain with User/Parent.
