# S29 retained-disposition exact delivery result

Date: 2026-10-12.
Status: REFERENCE_SWITCH_COMPLETE / HUMAN_TESTS_UI_PASS / SHUTDOWN_HANG_DEFERRED_OBSERVATION.
Authorization: RETAINED-DISPOSITION-DELIVERY-GRANT.md and user's explicit
commit -> exact export -> project reference switch -> human Unity request.

## Accepted source and commit

- Base: b76957a9dbcae9b00eff73775a97c4e8f33ae785.
- Source commit: 74c4db0cb44afd431b3b861439b3e6ef219d71f3.
- Twenty-two explicitly scoped files committed: seven accepted source/test
  changes, eleven task/evidence/grant records, workflow amendment and three
  templates. ProcessRunner remains unchanged.
- All eight accepted source bytes matched staged raw blobs. The workflow was
  staged as HEAD plus the current v2.6 approval amendment only, preserving
  older unrelated dirty workflow changes in the working tree.
- Staged diff check passed after an EOF-only mechanical correction to that
  ignored workflow projection; no product bytes changed during delivery.
- No push or publication. Existing unrelated dirty/untracked files retained.

## Exact artifact and checks

- Output: .artifacts/s29-retained-disposition-74c4db0.
- Review Package: .artifacts/s29-retained-disposition-74c4db0/review/com.rice.ai-codedb.
- ZIP: .artifacts/s29-retained-disposition-74c4db0/com.rice.ai-codedb.zip.
- ZIP SHA256:
  1325857c43a0f002f6feb25e1830efd00fc312e4e4de8120952d4963ef00e26c.
- Exporter: existing Tests~/export-codedb-package.ps1 with the exact source
  commit; output root was new. No payload regeneration or generation bump.
- Commit-stage and exact ZIP each passed production payload admission,
  native VerifyOnly and full sixty-source byte closure, mismatch_count=0.
- 586 files / ZIP entries; 12,446,175 uncompressed bytes.
- Generation remains poc.42; package generation manifest SHA256:
  944fab7055368870ab3a1fb4c5940e1d4b1ebe6b772a7e52d1bef728272af27f.
- Runtime contract SHA256:
  24bc8da5c9fb1914113b0d9270ecbb77285b09a7ce9f31841a6ac58906863604.
- Exact extraction matches eight accepted file hashes; all 586 stage/extracted
  files match byte hashes with zero differences.
- Exact-extraction C# semantic compile errors=0 and fifteen focused managed
  cases PASS. Reused reviewed native-boundary adapters and production SAFE
  fixture; reads Editor/tests from the exact extracted Package. New evidence:
  .artifacts/delivery/s29-retained-disposition/exact-compile.
  This is not native Unity/NUnit or real action execution. The original
  forty-seven backend cases were not rerun.

## Reference switch and protection

- No S29 Unity process observed immediately before switch; three unrelated
  miniGame_int Unity processes (Editor plus import workers) were untouched.
- Backup: .backups/s29-retained-disposition-74c4db0.
- Original manifest SHA256:
  9c8df031a2c08b52b97721d871300367ce93894f22c81b4a8f4dcc64b40dbdb2.
- Original lock SHA256:
  22faa7f99d7fb741d87be2e2230cc7348d2907767e6a8eb6202da68a55543a55.
- New manifest SHA256:
  c723ee546d1166dd8cec9274a804d57817dc0f544db3c7bd2560abb708db6046.
- New lock SHA256:
  7defc8f775e20094fd9555711a68c78b224dd967b04a2c2cb289246df242b570.
- Both select:
  file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-retained-disposition-74c4db0/review/com.rice.ai-codedb.
- Each has exactly one reference replacement; JSON parses, local source agrees
  and target package.json exists. No other semantic reference-file change.
- Fifteen bounded runtime/history/receipt/payload protected hashes remain
  unchanged; the two authorized reference hashes changed as recorded above.
- Thirty-five initially dirty tracked-file bytes remain unchanged, including
  protected payload declarations and unrelated workflow edits. This is bounded
  preservation evidence, not a whole-worktree immutability claim.

## Next gate and limits

Human opens the exact S29 project, performs the focused checklist, observes
Manager reopen/tab/status behavior and closes Unity normally. Tests requiring
production observation need the existing isolated fixture environment;
Ignore/Skipped is not PASS. Carry forward previous unreported admission cases.
See RETAINED-DISPOSITION-HUMAN-CHECKLIST.md.

The actual project remains INSTALLED with a distinct runtime generation
manifest. SAFE historical retained effects do not authorize Install, migration
or Ready. An absent Install button alone is not failure of this slice.
No Install/Uninstall/Configure/removal, cleanup, process stop, Unity/MCP/CUA/
BatchMode, true first-install, migration or release acceptance was performed.
After human report, bounded read-only attribution remains authorized.
S29/release PARTIAL; do not repeat export or reference switch.

## Subsequent human report

User reported 26 focused tests, compile and Manager reopen/tabs passing, then
normal-close hang at CleanupMono; user manually force-terminated PID 16436.
Windows AppHangB1 corroborates the hang. Read-only triage found the synchronous
CodeDB quitting callback returned in 1322 microseconds with no queue/reconcile/
Manager refresh in flight, but no blocking stack establishes the teardown owner.
See RETAINED-DISPOSITION-HUMAN-RESULT-2026-10-12.md. A subsequent authorized
no-test session closed normally. User then explicitly deferred the unresolved
hang for observation during future tests because attribution is unsupported by
the small sample. It no longer blocks this slice; the original failed-close
evidence remains a failure, not a retroactive PASS. No dedicated investigation,
source repair or extra Unity retry is authorized by this disposition.
Installed-generation alignment and overall S29/release remain separately PARTIAL.
