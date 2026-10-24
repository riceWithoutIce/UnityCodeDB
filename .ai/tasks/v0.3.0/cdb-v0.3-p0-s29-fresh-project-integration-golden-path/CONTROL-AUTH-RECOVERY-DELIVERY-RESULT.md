# S29 control authentication recovery: exact package delivery

2026-10-10. User accepted v3 source, authorized the seven-file commit, and then
said "继续" to proceed with exact package export and S29 reference switching.
Source commit: `7c82ff46997417a82ccceedcf0f846afd8dcda93`; parent:
`9a2ca41e19baf125cae594eb10ceef6b28cfef9b`. The commit contains only the seven
accepted source/test files. B01 is closed; independent v3 review PASS is retained
in CONTROL-AUTH-RECOVERY-VERIFICATION.md. No push/publication.

## Exact package evidence

- Exporter: unchanged committed `com.rice.ai-codedb/Tests~/export-codedb-package.ps1`;
  worktree and committed exporter blob both `04b316b885dff3f57b4377dd1f6a1680dc523d57`.
- ZIP: `.artifacts/s29-control-auth-recovery-7c82ff4/com.rice.ai-codedb.zip`.
- ZIP SHA256: `24034e4e90b28c3fdfddfae0f07d0e9924d13abf9f4ea78958158eae5b4a3888`.
- Exact extraction: `.artifacts/s29-control-auth-recovery-7c82ff4/review/com.rice.ai-codedb`.
- 586 files / 586 ZIP entries; 12,361,818 uncompressed bytes.
- Both commit-staged and exact ZIP Packages: production payload admission PASS,
  native build VerifyOnly PASS, source_count=60, mismatch_count=0.
- Generation remains poc.42. Runtime-contract hash:
  `538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d`.
- All seven exact extracted source hashes match the accepted v3 SHA256 manifest.

Command:
`powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/export-codedb-package.ps1 -Commit 7c82ff46997417a82ccceedcf0f846afd8dcda93 -OutputRoot G:/RiceProgram/UnityCodeDB/.artifacts/s29-control-auth-recovery-7c82ff4`

## Exact extraction isolated evidence

Command:
`dotnet run --project .artifacts/delivery/s29-control-auth-recovery/exact-harness/Semantic.csproj -- run`

Exact extracted original Editor/Tests: semantic compilation 0 errors;
14 distinct methods / 30 cases PASS; full worker regressions 5/5 PASS.
The existing reviewed harness was copied to the delivery-owned exact-harness;
only its source and Package context paths were redirected to the exact extraction.
No product source was modified. Five CS8632 warnings are in the external harness.

Worker outcomes: recovery success reads=2/probes=1/Ready/lease prerequisite=1;
missing proof NeedsAttention/prerequisite=1; Probe timeout NeedsAttention/
prerequisite=0; exhaustion reads=3/probes=0/NeedsAttention/prerequisite=0;
no-timeout Ready unchanged/prerequisite=1.

Standalone substitutes the Unity lifecycle static initializer, SessionState,
native dataPath/time and NUnit assertion adapter; worker IPC, lease publication
and removal preflight remain explicit stubs. Production worker branching,
binding, cache publication and lease prerequisite logic are retained. These
results are not Unity import/EditMode, real IPC timing, actual lease-file
publication, JsonUtility round-trip, GUI or release acceptance.

## S29 reference switch

Target: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.
Before switching, parent observed no matching S29 Unity process and no S29
Temp/UnityLockfile. Other open Unity projects were untouched.

Only the CodeDB reference in Packages/manifest.json and packages-lock.json was
changed from the prior `s29-unity-crash-p1-9a2ca41` extraction to:
`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-control-auth-recovery-7c82ff4/review/com.rice.ai-codedb`.

Both JSON documents parse, references are equal, package.json exists, and all
other reference-file text is equal after newline normalization. Originals are
preserved under `.backups/s29-control-auth-recovery-7c82ff4/`.
Across the switch, 26 protected receipt/index and selected project control files
retain equal hashes, with no added/removed file in that checked set. This is
point-in-time preservation, not a new runtime acceptance or manual release.

## Next gate

CONTROL-AUTH-RECOVERY-HUMAN-CHECKLIST.md binds the human steps to this exact
commit/package. Current source is SOURCE_ACCEPTED; commit/export/reference
switch PASS. Human has now reported normal Manager open/close and normal Unity
close with no crash. The supplied UI screenshot still shows NeedsAttention and
SUPERVISOR_IPC_TIMEOUT; the corresponding read-only Probe record failed while
waiting 30 seconds for coordinator readiness. Therefore human shutdown behavior
is PASS, but authenticated Ready, real IPC/provider startup and release
acceptance remain unresolved; S29/release are PARTIAL. See
CONTROL-AUTH-RECOVERY-HUMAN-RESULT.md.

No Install/Uninstall, payload regeneration/generation bump, history cleanup,
manual index release, service/process stop, Unity launch/control, MCP/CUA/BatchMode
or remote publication occurred. Unrelated dirty state and older artifacts remain.
