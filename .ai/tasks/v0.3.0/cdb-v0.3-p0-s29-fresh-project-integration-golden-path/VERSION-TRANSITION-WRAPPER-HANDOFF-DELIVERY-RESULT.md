# S29 historical wrapper handoff — delivery result

Date: 2026-10-14, Asia/Shanghai.
Status: DELIVERY_COMPLETE / HUMAN_VALIDATION_RECORDED_WITH_LIMITS.

Human reported test/Manager/normal Unity exit PASS. Screenshot confirms real
retained-effects SAFE; independent removal preflight still fails with exit 4.
See VERSION-TRANSITION-WRAPPER-HANDOFF-HUMAN-RESULT.md for attribution limits
and the still-PARTIAL overall S29 status. The remaining-gate section below
records the original delivery handoff, not a request to repeat it.

## Source commit

- Commit: `d88a101f15d21f916cbee9578ab887aa1ea862cd`
- Subject: `fix: authenticate historical wrapper handoff observations`
- Only the two accepted source/test files were committed:
  `Tools~/codedb-instance-engine.ps1` and
  `Tests~/test-codedb-host-payload-materializer.ps1`.
- No unrelated dirty or untracked content was staged.

## Exact package

- Review package:
  `.artifacts/s29-version-transition-wrapper-handoff-d88a10/review/com.rice.ai-codedb`
- ZIP:
  `.artifacts/s29-version-transition-wrapper-handoff-d88a10/com.rice.ai-codedb.zip`
- ZIP SHA256:
  `59e2d32b70912cbac18399d39764d888a3ec491d1d7b14b875df1d9021978c26`
- 617 files/ZIP entries; 13,142,119 uncompressed bytes.
- Production payload admission, native build/VerifyOnly and 60-source byte
  closure passed with zero mismatches.
- Target generation remains `poc.43`; runtime contract hash remains
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Delivered source hashes:
  `5a00e3c5351ea10cd532cdd3b31a25305f2e1d2e885412119ff2af91d3487a39`
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
  `6340ad4298c528edbb9be85abaf26255bf6ff5a0da9bea227cc18d96bfe23bfc`
  `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`

## S29 reference switch

Both files now select exactly:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-version-transition-wrapper-handoff-d88a10/review/com.rice.ai-codedb`

- `UnityFreshInstallValidationProjectS29/Packages/manifest.json`
- `UnityFreshInstallValidationProjectS29/Packages/packages-lock.json`

JSON parsing, reference equality and exact package existence passed.
Post-switch hashes:

- manifest: `41844f3eaca9ef1ab87c3851955f856941741b5d4de49492a98f02b6ee0ce40c`
- lock: `b594909d34b4f9f629866341982885a2fc83b245b6143bc214bc8fa607345b29`

Backup is preserved at `.backups/s29-version-transition-wrapper-handoff-d88a10/`.
Protected control hashes remain:

`0abe47370544c18fe074f34a1230109da5ebe3a5de4951cc40a08c5680933f3b`
`e270b40b20409f484a395f522ac9e2afa451499a1bdb0b1bc3bbe28c583274c1`
`afdce4014bd4ef18998f56933ea0b3bd4ad7189feda9d0022875cc278ef390e3`
`0995b8929e763a2defdfe219fb42375ffc236322b89af5eb730e94c17f0a0ad2`

No Install, Remove, Upgrade, history cleanup, index release, process control,
push or publication occurred.

## Remaining gate

Human Unity validation is required for this exact new reference. The focused
test requires `CODEDB_VERSION_OBSERVATION_FIXTURE` inherited by Unity; an absent
fixture means Ignore, not PASS. The separate MissingPrerequisite message, real
removal-preflight exit 4, consumer runtime chain and CleanupMono shutdown remain
independent limits. Do not click Install/Remove/Upgrade during this gate.
