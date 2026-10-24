# S34 exact delivery result - 2026-10-19

Status: SOURCE_ACCEPTED / DELIVERY_COMPLETE / HUMAN_BASELINE_PASS_WITH_SHUTDOWN_EXCEPTION.
Human baseline observations are recorded in HUMAN-RESULT.md; delivery-time
observations below remain unchanged.
S33 same-version reinstall remains unaccepted. Existing canonical UNKNOWN
evidence remains an explicit baseline limitation, not repaired historical data.

## Authorization and precise commit

User accepted source, authorized exact commit -> export checks -> S33 reference
switch, and confirmed S33 Unity closed. No repeated stage permission needed.

- Parent: `b0462ed07b6a14be64bddf848e67609d9143fa71`.
- Source commit: `d4a097d20af598ca760163867a3394ff5efb116d`.
- Message: `fix: converge supervisor history and terminal evidence`.
- Exactly five accepted source/test files plus TASK/RESULT/VERIFICATION committed.
  Staged paths matched the eight-file allowlist and staged/worktree bytes agreed.
  Staged diff check passed; index empty after commit.
- Other dirty source, payload and historical records were not staged or modified.
  No push/publication occurred. This delivery record and task status update are
  subsequent local records, outside the frozen source commit.

## Exact artifact gates

Existing exporter ran once with the exact source commit; no dirty-tree export.

- ZIP: `.artifacts/s34-supervisor-history-d4a097d/com.rice.ai-codedb.zip`.
- ZIP SHA-256:
  `9a3d9a70a5d46fecea3a47920ad0463b3aefd076bf15efe51c6c4f1b31d25300`.
- Consumer extraction:
  `.artifacts/s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`.
- Exactly 623 files / ZIP entries, 13,369,891 extracted bytes.
- Both commit-stage and exact ZIP passed production read-only payload admission
  (60 files), byte closure (zero mismatches), identity/hash closure and native
  source/build/binary VerifyOnly binding.
- After focused semantic evidence, all 623 extraction file hashes matched the
  commit-stage Package. No extraction edits or generated files inside Package.
- Package identity remains `0.3.0-preview.5 / poc.43`; generation transition NONE.
  Changed producers/readers are Package-owned Tools scripts, not modifications
  to an immutable generation.
- Generation manifest SHA-256:
  `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`.
- Host-current SHA-256:
  `ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1`.
- Runtime contract SHA-256:
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Exact extracted Package PathProvenanceOnly and existing helper binding checks
  PASS. No unchanged full regression suite was run.

## Affected record consumer closure

Paths below are relative to the exact extraction, not worktree substitutes.

| Contract | Production writer | Actual readers | Evidence |
| --- | --- | --- | --- |
| Unstarted failed terminal: NO_CHILD, null start, complete result flags, cancellation reason | Tools~/codedb-project-supervisor.mjs completeUnstartedMaintenance / compactResult | Tools~/codedb-instance-engine.ps1 Assert-ProjectInstallTerminalResult / Assert-ProjectInstallExecutionDisposition; Tools~/materialize-codedb-host-payload.ps1 Assert-RemoveIntegrationTerminalOperation / shared terminal timing | Node-produced queued and admission-publication bytes decoded by actual poc.43 strict JSON parser, accepted by both readers; six adjacent refusals PASS |
| Eligible routine-history retention | Tools~/materialize-codedb-host-payload.ps1 Invoke-SupervisorHistoryRetention; engine locked call sites | Existing Install/removal history consumers; unchanged 4096 bound | Exact extracted focused fixture: 5000 routine records -> 130 records, preserving canonical, UNKNOWN and suffix 128 |

Cross-language driver:
`.artifacts/delivery/s34-supervisor-history-d4a097d/verify-contract.ps1`.
Node output is owned by the extraction's parent review directory at
`.artifacts/tests/s34-history/delivery-node/`; Package is source input only.
Retention fixture:
`.artifacts/tests/s34-history/delivery-d4a097d-retention/`.

Driver imports actual source definitions without executing the materializer
entry point. It accepts two producer shapes through two readers, and rejects
legacy UNKNOWN, conflicting child and missing drain-completeness evidence in
both readers. No child/process check or termination path is invoked for these
NO_CHILD records. This proves decoding closure, not full installation.

One harness correction: first reader invocation used ConvertFrom-Json, yielding
the wrong numeric token type for the production reader. Driver changed to the
exact generation's ConvertFrom-StrictJsonText and reused original Node output.
Corrected pass required no source/Package change, new producer invocation or
real runtime mutation.

The retention fixture uses the real retention function with synthetic identity,
terminal-validation and process seams. Its PASS proves bounded retention in that
fixture, not real S33 cleanup, all pinned-reference scenarios, process identity,
interruption behavior or successful reinstall. Cross-language checks above use
actual strict decoding and actual terminal/disposition readers without those
terminal-validation stubs.

## S33 switch and protected state

Immediately before switch, no S33 Unity process or EditorInstance/UnityLockfile
was present. Other Unity processes belonged to another project and were untouched.
Hash-verified backups:
`.backups/s34-supervisor-history-d4a097d/{manifest.json,packages-lock.json}`.

Only the CodeDB reference changed from the S32 extraction to
`file:../../.artifacts/s34-supervisor-history-d4a097d/review/com.rice.ai-codedb`.
Raw-byte comparison against backups proves every other byte unchanged. Parsed
manifest/lock references agree, resolve to the exact Package, and retain testables.

| File | Before SHA-256 | After SHA-256 |
| --- | --- | --- |
| manifest.json | 8929fb4db3d357752ce95e3bc2a94417571dc8e011dc8700812ca2b10ebbe77c | 53dfcd41f0e291377fb94ed8cc6b7fc2f83293776cbe29abcee062cb081bad79 |
| packages-lock.json | d7b58d7e8defcc01e77dceda90bcb608473eaa45dfc11689c8d0320ef08b21b9 | 0dba10b5211e403dd8357e0f52f03b406674b03b6d5f7e9e7f2ad76d9b3ff526 |

All 5362 files inventoried under S33 AIWork and .codex retained identical hashes
and file count. Inventory: same backup root, protected-s33.xml.
History remains 5301 records. Canonical operation
`c61cdf881d39405f85d4f19ae8ac1076` remains UNKNOWN. No history deletion,
backfill, admission release, Install, Uninstall, Unity launch or process control.

## Handoff

Human may open S33 for compilation and Manager baseline inspection. No new
Editor test methods were added by this Tools-only change; relevant non-Unity
contract gates passed. Do not infer real reinstall PASS. Before another Install,
align existing UNKNOWN baseline disposition and separately authorize the attempt.
Do not bypass it with manual history cleanup. Log reduction, Manager reopen UX
and CleanupMono observations remain deferred. See HUMAN-CHECKLIST.md.
