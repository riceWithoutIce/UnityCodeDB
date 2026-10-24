# S29 process identity — delivery complete

Date: 2026-10-14. Human result recorded: 2026-10-15.
Status: DELIVERY_COMPLETE / HUMAN_REPORTED_PASS / S29_PARTIAL.
User source disposition: `同意 accept`; delivery grant: `授权`, replying to the
concrete plan. See PROCESS-IDENTITY-ACCEPTANCE and DELIVERY-GRANT with this prefix.

## Exact source and Package

Commit: 544be4f7e339acefb47137b188cdc85e22483efb.
Subject: fix: distinguish supervisor PID reuse during removal preflight.
Exactly three accepted source/test files, 199 insertions / 12 deletions. No
unrelated docs, dirty Payload or project state was staged; index is empty.
All three committed/extracted source hashes equal the accepted snapshot.

Package: .artifacts/s29-removal-process-identity-544be4f/review/com.rice.ai-codedb.
ZIP: .artifacts/s29-removal-process-identity-544be4f/com.rice.ai-codedb.zip.
SHA256: 65c0bcbb46f138941b5becf4dd59abbebb6528524db7ef5cff91c3e6c152e16a.
617 files / ZIP entries; 13,204,981 uncompressed bytes. Package version remains
0.3.0-preview.5, target generation poc.43 and runtime contract
69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a.
No payload regeneration or generation/version transition.

Git-archive export uses the committed Package only. All 617 shipped files equal
the accepted overlay's corresponding files, zero mismatches. The sole excluded
directory-only item is the exact untracked test .cs.meta documented in DELIVERY-
PLAN: absent from the original ZIP and Git tree. No blanket meta exclusion or
silent file insertion. Prior ZIPs, source overlays and observed failures remain.

## Exact artifact gates

Delivery evidence root: .artifacts/delivery/s29-removal-process-identity-544be4f/.
Isolated test/tool root: .artifacts/tests/s29-removal-process-identity/delivery-544be4f/.
Protected snapshot/helper root: .artifacts/delivery/s29-removal-process-identity-prep-a1/.

| Gate | Result and evidence |
| --- | --- |
| Commit-stage and exact ZIP payload admission / byte closure | PASS, 60 sources, zero mismatches; existing native VerifyOnly. export-a1.log |
| Exact accepted source/Package equality | PASS617; inventory-a1.log and check-inventory.ps1 |
| Exact Package PathProvenanceOnly | PASS; path-a1.log |
| Original-byte Editor and full included Editor.Tests compilation | PASS, both exit0; compile-a1.log; test root compiler RSP/logs |
| Isolated production namespace/process/handoff/transaction/terminal/recovery chain | PASS141, native_children=0, copied_project_only=true; scenario-a1.log and test root scenario-a1.log |
| Exact production refusal -> C# diagnostics/cache/UI consumer | PASS; consumer-a1.log, test root seam-run-a1.log and exact-ast-binding.txt, 13 original members |
| Protected state before reference changes | PASS5680, zero differences; protected-artifact-a1.log |
| Reference JSON and only-reference text replacement | PASS, two files; reference-check-a1.log |
| Protected state after switch | PASS5680, exactly the two allowed reference changes; protected-after-a1.log |

All product process observations in the scenario use the accepted synthetic
seams; no real Supervisor child or IPC. The existing original C# compiler/seam
tools were copied to a unique owned root and their Package input/output paths
were rebound to the exact extracted artifact. Assertions were not rewritten.
Full native Unity workspace/lifecycle and real operational acceptance remain
NOT_RUN. Native VerifyOnly checks the artifact, not runtime activation.

## Reference switch and mechanical correction

Both S29 files now select:
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-process-identity-544be4f/review/com.rice.ai-codedb.

Only UnityFreshInstallValidationProjectS29/Packages/manifest.json and
Packages/packages-lock.json changed. Backup:
.backups/s29-removal-process-identity-544be4f/{manifest,packages-lock}.json.
Post-switch SHA256:

```text
ffd18b0eee0e2ca614f12436b60ad0213987dc2cde9a3d539f5d4831e3b405eb  manifest.json
d2b37c6812672afdf71c627d93bec8585ebfd4362f82c1339baea999c7d9f7c2  packages-lock.json
```

Immediately before switching, the read-only Unity check attributed every
observed Unity command line to another named project; no S29 process or
Temp/UnityLockfile existed. No external process was stopped or otherwise changed.
An initial delivery helper incorrectly parsed quoted "-projectPath" arguments
and stopped before backup/mutation. Read-only follow-up established the cause;
one mechanical argument-parsing correction accepted quoted/unquoted arguments
and rechecked exact absolute project paths. Initial helper and error attribution
are retained in prepare-reference-switch.ps1 / reference-ready-a1-error.txt;
successful helper/log are prepare-reference-switch-a2.ps1 / reference-ready-a2.log.
No product gate failed, product source changed or Package re-export occurred.

## Human handoff and retained limits

Human checklist: REMOVAL-PREFLIGHT-PROCESS-IDENTITY-HUMAN-CHECKLIST.md.
The human may now open the same S29 project, confirm compilation, run the six
ordinary listed tests, check Manager close/reopen and tabs, then close Unity.
The separately parameterized fixture-only test is already covered by exact
artifact evidence; do not ask the human to run it unconfigured.

The user reported Test Run, Manager close/reopen, tab switching and normal Unity
shutdown all passed. Post-human exact references, ZIP and protected baseline
checks passed; see REMOVAL-PREFLIGHT-PROCESS-IDENTITY-HUMAN-RESULT.md for the
evidence and its limits. This declared source/delivery/human smoke slice is
complete. Do not claim Ready, actual
removal admission, Install-button availability, migration or release completion.
The known missing-child histories remain refused; unavailable process identities
may also still refuse. Historical outcomes stay intact. CleanupMono remains
deferred. No real Install/Remove/Upgrade/Probe/preflight/IPC, automated Unity,
process control, environment change, history cleanup, push or publication.
After the human report, perform bounded read-only attribution; do not repeat
delivery or broaden repair. No task-document commit was made in this delivery.
