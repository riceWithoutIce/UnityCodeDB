# S29 isolated execution/output lifetime reproduction result

2026-10-08. Stable diagnostic handoff; no production repair.

Status: NORMAL_DETACHED_TOPOLOGY_REPRODUCED / OUTPUT_LIFETIME_COUPLING_CONFIRMED /
EXACT_OS_HANDLE_OWNER_UNPROVEN / ALL_RECORDED_FIXTURE_PIDS_ABSENT / S29_PARTIAL.

## Scope and implementation

Exclusive sandbox: `.artifacts/diagnostics/io/995de5da` under UnityCodeDB.
Owner token: `48d60b42a85049be9b5bbb39347e0b16` (owner.json).
Initial three runs started 10:44:45 UTC; focused comparison at 10:46:54 UTC.
Each run completed below its 60-second bound; only four operational runs were made.
One unused comparison remains unused. No child delegation.

The delivered Package at `.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb`
was read-only. Its Manager writer was copied byte-for-byte into sandbox `pkg/Tools~`.
The native file-output launcher and four dependencies were imported from the actual
delivered materializer's AST function extents without editing them or evaluating
materializer top level. Admission/action/receipt identity followed the existing
package-boundary writer fixture recipe, bound exclusively to sandbox project/package
roots. The unmodified writer accepted those identities and published all four receipts.

Actual topology: writer WinPS -> fixture control WinPS -> actual Start-Process
file-output launcher -> short WinPS -> Node CLI -> Node daemon. Normal Node startup
uses detached:true, stdio:ignore, windowsHide:true, unref(), matching shipped
coordinator startup flags. The inherited fixture working directory is its sandbox
project root, equivalent to the shipped coordinator's explicit cwd context.root.
Business work was replaced by writing readiness/identity files; no real coordinator,
Provider, adapter, MCP registration, index or real project operation was performed.

All launched fixture descendants received sandbox-local TEMP, TMP, LOCALAPPDATA;
no user/global environment was changed. The daemon had a 35-second self-expiry and
token-scoped cooperative stop file. Original source hashes were checked again after
execution and retained in file-inventory.json. Runtime: Windows PowerShell
5.1.19041.6456, Node v24.14.1 at F:/Program/nodejs/node.exe.

## Results

Times below come from native-result.json and the actual Manager terminal receipt.
Manager exit means its recorded command exit, not the writer utility's exit (the
writer itself exited 0 after successfully publishing each terminal receipt).

| Scenario | Native elapsed | Native direct exit / incomplete | Manager elapsed | Manager command exit / incomplete | Outcome |
| --- | ---: | --- | ---: | --- | --- |
| baseline: leaf only | 372 ms | 0 / false | 878 ms | 0 / false | Complete output; no daemon |
| detached: normal stdio ignore daemon | 5508 ms | 0 / true | 10866 ms | 6 / true | Both reported failure signatures reproduced |
| retained: deliberately stdio inherit daemon | 5470 ms | 0 / true | 10814 ms | 6 / true | Deliberate adverse control, not claimed as historical cause |
| early: normal detached daemon, cooperative stop at 2512 ms | 1758 ms | 0 / false | 2157 ms | 0 / false | Both collectors complete after early daemon exit |

The native clock starts within the fixture control process; the Manager clock starts
within the writer; observer clock starts before writer launch. Their origins differ.
Do not subtract the columns as though they shared an origin. Total observer run
durations were 1496, 15236, 15261, and 2773 ms.

The detached scenario reproduces the failure without deliberate output inheritance:
the native launcher returns the literal `Package-owned native client output remained
locked after the direct process exited.` and the actual writer sets
output_drain_incomplete=true with its original missing-EOF diagnostic.
The fixture control returns exit6 when the native launcher marks output incomplete;
this is fixture business behavior, not a claim that it ran the real instance engine.

Normal detached stdout stayed locked; stderr became readable. The adverse inherit
control kept both stdout and stderr locked. Thus the normal run matches the live
failure class and both-layer symptoms, but not the live report's exact two-file lock
count. No additional run was used merely to make the symptoms identical.

## Original exception and timeline

The production launcher deliberately collapses IOException details. A separate,
read-only observer attempted System.IO.File.ReadAllText against sandbox native log
files; it did not edit or replace the launcher. It captured:

- System.IO.IOException, HResult -2147024864 = 0x80070020 (sharing violation).
- Original message: the process cannot access the specific sandbox stdout.log
  because it is being used by another process.
- This is exception evidence, not identification of a process holding a handle.

Normal detached observer timeline (ms after writer launch):

- 939: fixture control observed.
- 940/941: native stderr/stdout sharing violations observed.
- 1176: short WinPS process observed.
- 1309: daemon observed alive (PID49836); readiness written.
- 1310: stderr readable; stdout remains sharing-violating.
- 11459: Manager writer exits after publishing incomplete-output terminal.
- 15080: cooperative stop requested for the fixture daemon.
- 15204: previously locked stdout becomes readable; retained snapshot is 63 bytes.
- Daemon recorded cooperative exit; final process audit confirms PID absent.

The early comparison uses the unchanged same control/leaf/Node scripts and the same
native/writer implementation. Only the external cooperative-stop time changes from
after both drain windows (~15 s) to 2512 ms. The direct short command already exited;
the daemon exits after the stop; native collection and Manager EOF then succeed.
This establishes a causal dependency of output completion on the test daemon's
lifetime in the reproduced topology. It does NOT prove the numeric OS handle,
whether the file handle is held by WinPS redirection or a descendant, nor the exact
historical holder in the now-ended real Install. No handle scanner was used.

The long-lived service is correctly allowed to outlive its starting command. The
concrete repair boundary to align next is short-command output ownership versus
daemon lifetime, including both native file-redirection completion and outer Manager
pipe completion. Longer timeouts, treating shared-file reads as EOF, or accepting
exit0 alone would not establish that boundary. No repair is selected or implemented.

## Process attribution and cleanup

Every fixture role wrote its PID, token and UTC record. WinPS writer/control/leaf
records also capture exact process StartTime ticks. The observer captured exact
Get-Process start ticks and executable paths for all long-lived daemons and the
roles it observed before exit. Short baseline leaf and detached CLI exited between
observer polls: their self records exist, but the CLI's exact OS start ticks were not
captured in that run. This limits historical attribution precision for that brief
process; no termination relied on it.

All three daemons recorded `cooperative-stop`; self-expiry was not needed. No
fallback kills, process-tree kills or broad process enumeration were used. Final
audit queried only the 18 PIDs present in fixture role records (including transient
CLI/leaf PIDs); every PID was absent. No fixture service remains. The actual helper
may delete its own native logs on success as part of its unchanged finally block;
its returned output and observer snapshots were retained. The sandbox, all receipts,
JSON timelines and remaining logs are preserved; nothing in a real project was
cleaned, replayed, selected or rewritten.

## Evidence and exact identities

Evidence root `.artifacts/diagnostics/io/995de5da`:

- `results.json`: initial three full receipts, events and process proofs.
- `comparison-results.json`: focused early-stop comparison.
- `{baseline,detached,retained,early}/native-result.json`: unmodified launcher result.
- Per-scenario `local/Rice/CodeDB/manager-actions/<action32>/`: actual writer records.
- Per-scenario role JSON, daemon-exit.json, stdout/stderr snapshots and outer logs.
- `final-process-audit.json`: bounded final audit, all18 PID records absent.
- `identity.json`, `comparison-identity.json`: exact source/import/runtime identities.
- `file-inventory.json`: SHA256 and sizes of90 evidence files plus source rechecks.

| File / exact import | SHA256 |
| --- | --- |
| delivered Manager writer and exact sandbox copy | 657f780c53d2cc69e47b16a4b28954003a3fdfcf9397d551db779ac0f8bed0a4 |
| delivered materializer | 39e7872ab387457c477da318a271776ae4c9fc565e12af0f26ba2c8d072cc16a |
| Invoke-BoundedNativeProcessWithFileOutput AST extent | f9f9ec59e4a1c4966898f7fbcda8f3f1ac2c83bac968f63a9a7a720d1f3654b1 |
| run.ps1 | a02312cbe6d45dc6c6a4eba463ab0c60f3e9bc87ed0a216abef6490292973ca5 |
| command.ps1 | 21d77bebdd91443e826e4b36bed5eba1e2b4d876750c12746527ea53d2a94cf4 |
| leaf.ps1 | 3f4e3c842fd9ff8dd41782c36f13360dbc3ab6bdea18029da662e5fd26028066 |
| service.mjs | 28a8f44bc41ca5cc5aefcee70ed3272cb2aec10d62c2e9a8c59a14f42871863a |
| compare.ps1 | 9d3b18d912471a0e57e14d8d1312c3c912d6f6f006dabdf53a47ca6a6389236a |
| results.json | 03260d22cb6b7725d0f060b68ae60be3755e6645a469eccfcc37f713614727aa |
| comparison-results.json | 2e6335abb53fc65a1445b9fc2a8a3997b22f89373448dd39fabc04d938463c50 |

All five AST-import hashes and their original line extents are in identity.json;
only the primary launcher is duplicated above. Fixture scripts parsed before child
execution. One read-only summary shell expression initially failed to parse and was
corrected; it did not run a scenario. Initial console summaries used Select-Object
on a hashtable and displayed null fields; authoritative saved JSON was intact and
was read back. The comparison summary casts to PSCustomObject; original scripts and
evidence remain preserved. These presentation issues do not alter scenario results.

No production/Package/generation changes, Unity/MCP/Provider invocation, real project
read or write, live process probing, commit/export/push or semantic acceptance of the
failed Install occurred. Stop here for parent assessment and repair-scope alignment.

## Parent evidence assessment

Parent inspected the stable fixture control/leaf/Node scripts, all four saved
native results and actual writer terminal receipts, and the final exact-PID audit.
Independently matched all90file-inventory hashes with path containment checks;
four saved result pairs agree with the table above. The saved final audit contains
18roles, all absent. Parent did not rerun scenarios or probe processes again.
Production Tools~/Payload~ show no diff; HEAD remains d56f0e5 and index empty.

Accept the bounded diagnostic conclusion: normal detached topology reproduces
the two-layer output failure, and the early cooperative-exit comparison proves
an output-completion dependency on fixture daemon lifetime. Exact OS handle owner
and the historical live holder remain unproved. This is reproduction evidence,
not a selected/implemented production fix or restored real Install acceptance.
