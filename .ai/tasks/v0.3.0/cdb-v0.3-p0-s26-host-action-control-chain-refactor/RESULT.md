# S26 Coder Result

## Snapshot And Scope

- Status: SOURCE_COMPLETE / focused synthetic L0 PASS; C# semantic and Unity gates DEFERRED.
- Branch/HEAD at handoff: `1f2fcb23e6d840956063aa398d1bb6ece6a01717`.
- The task card's `f71129e35aa2487ce7f69b45131d2e7456d5a0a9` is the source baseline before its documentation commit, not the current HEAD.
- Ordered eight-path source/test SHA-256 identity before edits: `a67ba5efd0126a79384f4718322ad99eba74f85e443fc1c66b0c7fe4599bc264` (the optional journal files were absent).
- Final ordered eight-path source/test SHA-256 identity: `640e27807619bdc01cc5857127a8f37b61ecfd93ce791a5bbc9631120c3e5f5f`. Each row is `<relative path> <lowercase SHA-256>`, joined with LF in the task allowlist order, then SHA-256 hashed. The new journal and `.meta` are included.
- Inherited S18/S22/S23/S25 records, validation-project state, and S25 real admission/claim evidence were not edited, cleaned, retried, or read as runtime inputs. All S26 changes remain uncommitted.

## Changed Paths

- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`: background durable admission/recovery, original-ID reattachment, exact direct/Supervisor result lookup, pre-effect/terminal/unknown handling, and bounded direct-only refusal classification. Local automatic-update policy and read-only watcher status retain their existing non-writer route.
- `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs`: explicit Manager evidence kind, implicit Manager results default to indeterminate, start-failure receipt authentication, pending-stage validation, and fail-closed conflicting receipt handling.
- `com.rice.ai-codedb/Editor/AICodedbPaths.cs`: project-stable user-local index path and shared in-memory direct-writer dispatch tracker.
- `com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs` and `.meta` (new): Package-independent index with original ID in filename, full project/Package binding, exclusive admission, bounded legacy receipt discovery, read-only closed markers, and exact-ID release. Legacy pending receipts are only read and never altered.
- `com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1`: pre-claim process preparation, bounded asynchronous stdout/stderr drain without `Add-Type`, and distinct proven child-start-failure receipt. Only known Win32 pre-creation failures or `Start()` returning false may publish that receipt; other failures remain unconfirmed.
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`: nearest-neighbor index/full-exit/Package-change, legacy claim, corruption, pre-effect, and dispatch-tracker cases (source added; execution deferred).
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`: fixture-owned writer success, nonzero failure, timeout, overflow, child-start failure, and identity rejection.

## Evidence Ledger

| Evidence | Exact command or check | Exit | Wall time | Result |
| --- | --- | ---: | ---: | --- |
| Initial PowerShell AST static batch | `[System.Management.Automation.Language.Parser]::ParseFile` on the writer and Package-boundary harness | 0 | ~0.29 s | Both `AST_OK` |
| Initial bounded source batch | PowerShell exact-marker checks on Manager, Runner, journal, writer, harness and `RestorePending` slice | 0 | ~0.23 s | 12/12 checks OK; no synthetic ID in restore slice |
| Initial focused L0 | `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1 -ManagerActionWriterOnly` | 0 | 12,155 ms | `[OK] Focused Manager action writer receipt scenarios passed.` |
| Same-cause corrected focused L0 | Same command, after narrowing `Process.Start()` failure proof | 0 | 12,119 ms | Same `[OK]` line; no other L0 was run |
| Corrected bounded source check | PowerShell exact-marker checks for legacy read, closed marker, exact ID, tracker, route lookup and conflict block | 0 | ~0.24 s | 10/10 checks OK |
| Scoped diff check | `git diff --check --` the eight allowlist paths | 0 | 143 ms, 145 ms, 139 ms | Empty output each time; final invocation followed the last source edit |
| New-file whitespace check | `rg -n '[ \t]+$'` on the new journal and `.meta` | 0 wrapper | ~0.23 s, ~0.23 s | No trailing whitespace; untracked files are not covered by `git diff --check` |

Budget accounting: focused L0 initial `1/1`, same-cause corrected attempt `1/2`, other L0 `0`; PowerShell AST/source initial plus one corrected source check; scoped diff-check `3` total as the implementation continued after the earlier checks; C# L1 `0`; Unity/EditMode `0`; real Remove/Install/Provider operations `0`; test retries after the corrected writer run `0`. The two earlier diff checks are recorded, not represented as final evidence for later edits. Exact cumulative captured-output bytes and active/paused time were not available; wall times above are measured per command where shown. Compaction count/retry metadata were unavailable.

The dynamic L0 exercises writer receipts only. The C# index and recovery cases are authored but **not executed**. Static marker checks establish source presence, not C# semantic correctness. In particular, full Editor exit, Package replacement, Supervisor response loss, and corrupt-record behavior still require the separately authorized affected L1/Unity evidence. The current S25 real Remove remains UNCONFIRMED; this task does not infer uninstall or authorize fresh Install.

## Remaining Risk And Route

- C# compile and focused `AICodedbManagerUiTests`/EditMode: NOT RUN / DEFERRED by the task's Unity authorization boundary. No substitute prebuilt-DLL claim is made.
- The bounded historical receipt scan and closed-marker lifecycle are source-only until C# L1; its 4,096-record limit is an explicit fail-closed operational bound, not proof that a larger history can be admitted.
- Real Unity, Package export, Remove-to-Install acceptance, Provider probes, and release verification: NOT RUN / DEFERRED. No Unity, Unity MCP, real project mutation, process probe, commit, tag, push, or publication was performed.
- Focused writer L0 passed on the final writer/harness bytes; later edits were limited to C# source/tests. Planner should inspect the eight-path identity and this evidence before any Verifier or human Unity routing.

Current task: `cdb-v0.3-p0-s26-host-action-control-chain-refactor`
Current status: `SOURCE_COMPLETE / FOCUSED_L0_PASS / CSHARP_L1_DEFERRED`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner review of the stable uncommitted snapshot, task scope, fault-matrix coverage, and deferred C# gate; only Planner/User may authorize Verifier or Unity acceptance.
Human decision or authorization required: C# L1/EditMode/Unity, real Remove/Install, commit, Package export, push, tag, publication.
