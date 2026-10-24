# S29 removal history authority — delivery plan

Date: 2026-10-15. Status: AUTHORIZED / DELIVERY_IN_PROGRESS.
Source acceptance: REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-ACCEPTANCE.md.
User delivery grant: `同意授权`, replying to the concrete sequence
`commit → 精确出包核对 → 工程引用切换 → 人工 Unity 验收`.

## Exact boundary

Commit exactly these three accepted source/test files:

- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs`

Then export and independently verify a Package from that commit, switch only
`UnityFreshInstallValidationProjectS29/Packages/manifest.json` and
`Packages/packages-lock.json` after confirming S29 Unity is closed, and hand the
exact artifact to the user for Unity acceptance.

No push/publication, Install/Remove/Upgrade/Probe/IPC, process control, history
cleanup, Payload regeneration, generation transition or other project mutation
is authorized. Preserve all unrelated dirty files and prior artifacts. Stop at
the first failed gate; do not retry with a different source or broaden scope.

## Accepted source identity

Base HEAD: `544be4f7e339acefb47137b188cdc85e22483efb`.
Expected accepted source hashes are recorded in the acceptance and source hash
records. Commit subject: `fix: separate removal history authority sources`.

## Evidence and handoff

Delivery evidence belongs under `.artifacts/delivery/s29-removal-history-authority-<commit>/`.
The exact ZIP hash, file count, production admission, byte closure, path
provenance, and reference-switch/protected-state comparison are recorded before
human Unity acceptance. Human acceptance remains a separate gate and must report
compilation, listed tests, Manager close/reopen, tab switching and Unity close.
S29 remains PARTIAL; actual removal, child-null histories and CleanupMono remain
deferred.
