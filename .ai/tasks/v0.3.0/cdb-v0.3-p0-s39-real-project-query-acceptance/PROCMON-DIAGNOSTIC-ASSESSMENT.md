# Procmon diagnostic screening — 2026-10-21

Status: READ_ONLY_SCREENING_COMPLETE / DEFER / NO_CAPTURE_ROUTE_ADMITTED.
Authority: user approved continuing the passive-tool assessment after Stage 1.
This is route selection, not an installation, POC or real-client attempt.

## Problem and baseline

The existing target-thread host records establish initialize connection closure
after 174 ms and 85 ms, without attributable child launch fields or stderr.
Wanted evidence is actual child image/entry/cwd, exit and a loader error or
relevant failed entry/import open. Keep normal project registration, stdio,
inherited environment and launch topology unchanged. Attempt 04 stays on hold.

## Current official evidence

Retrieved the Microsoft Sysinternals [Process Monitor page](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon)
on 2026-10-21. It identifies Process Monitor v4.12, published 2026-10-15, and
lists client support as **Windows 11 and higher**; server support is Windows
Server 2019 and higher. A fresh read-only Win32_OperatingSystem query confirms
this machine is Windows 10, version 10.0.19045, build 19045.

The advertised current release therefore does not pass the documented target
support gate. This does not prove that it cannot execute on Windows 10; no
execution or compatibility experiment was performed. No official supported
older binary/version was established by this screening, and no third-party
mirror or guessed legacy download is admitted.

The official page documents:

- Filesystem, Registry and process/thread activity; image path, command line,
  user and session details; process relationships.
- Non-destructive filtering: filters can be changed **without losing data**.
  A target-only display is consequently not proof of target-only raw capture.
- Native logs preserve all data, per-operation stacks are available, and logs
  can scale to tens of millions of events and gigabytes. No overhead bound is
  documented on this page; passive observation is not zero timing impact.

The landing page does not establish the exact CurrentDirectory or process-exit
field delivery needed here, a version-specific pre-capture exclusion/drop
policy, permissions/driver lifecycle, a bounded invocation, or a stderr capture
facility. These remain unknown, not absent by proof. Do not promise stderr from
process/file events. An attempted Microsoft troubleshooting article URL returned
404 and provides no supporting evidence. No executable/archive/help payload was
downloaded; no recorder was launched to inspect its menus or options.

## Candidate comparison

| Candidate | Purpose and support | Data/side effects and boundary | Advantage and disposition |
| --- | --- | --- | --- |
| Existing desktop/SQLite logs; no new technology | Already retained actual-host target events | Read-only exact-thread/time-window extraction; no changed launch | Lowest impact; confirms failure and omission but lacks decisive launch/stderr fields; baseline retained |
| Installed process-only ETW route | Existing WPR/logman/provider inventory; live permissions and emitted fields untested | OS recorder/session would require separate authorization; process keyword can still collect unrelated process events; no target-only raw scope promised | Can add PID/parent/image/exit ordering without changing MCP command; lacks established cwd/stderr/file-open evidence; insufficient alone |
| Official current Procmon v4.12 | Established tool with official distribution; current documented client minimum Windows 11 | New tool/recorder; filtering is non-destructive by default, raw retention and driver/rights/removal unknown | Potential entry/import open and command/image evidence; fails documented support gate on this Windows 10 host; defer |

The earlier shim is a deferred fallback, not another passive candidate: it
changes the launch topology/timing. Native logging with an override/restart is
also a separate experiment; a supported target-stderr setting and its actual
sink have not been established. Neither is silently substituted here.

## Hard gates for current Procmon

| Gate | Result | Evidence |
| --- | --- | --- |
| Target support | fail | Official current release lists Windows 11+; actual client is Windows 10/19045 |
| Official distribution | pass | Microsoft page links its official download; bytes/signature not acquired or verified |
| Scoped disposable generated data | unknown | No verified version/command/backing-file setup; repository-owned output alone would not isolate collection |
| Ignore/exclusion behavior | unknown | Documented non-destructive filters do not establish pre-retention exclusion |
| Security/privacy/network/filesystem side effects | unknown | Can observe broad system data; version-specific rights, driver and persistence lifecycle not established |
| Repeatable setup/validation/removal | unknown | No compatible artifact, signature, help or bounded invocation verified |
| Clear integration boundary | pass | Proposed external observer only; no Package/registration/stdio integration |
| Plausible advantage | pass | Image/command and file-access evidence could narrow pre-body loader/path failures |

Decision: **defer**, not approve for POC. Stop before download or capture. No
executable capture plan or unverified CLI flags are issued while early gates
fail/remain unknown. Permission and overhead remain explicit open questions;
they were not tested by elevation, driver loading or a benchmark.

## Concrete continuation choices

Do not repeat the unchanged real-client attempt or create another Unity project.
Keep CodedbTest_1 and the already installed exact Package as the diagnostic target.

The preferred next alignment, if preserving the original parent/environment
remains the priority, is whether to pursue **official Windows-10-compatible
tool provenance and documented raw-data isolation only**. This is not approval
to download/run a legacy tool. Reject that route if official provenance/support
or a reviewable raw-data boundary cannot be established; do not substitute an
unverified mirror. A compatible version's fields, rights, startup behavior,
stack settings and cleanup must be verified before admitting a live plan.

Alternatively, explicitly accept evaluating a host-native logging experiment
that may require changing logging settings/restarting the parent. Its supported
setting and stderr sink must first be established; do not guess RUST_LOG or
claim that it preserves the failed parent's inherited environment. This is a
different diagnostic environment, not untouched-path acceptance.

Neither choice is executed here. If neither tradeoff is acceptable, report the
remaining evidence gap rather than run a known-incomplete recorder. No request
for a download/capture approval is made before a compatible, bounded plan exists.

## Completed scope

Documentation requests, OS version query and task-record edits only. No software
download, browser/app launch, capture, driver, elevation, process control, host
restart, config/environment/source/runtime change, MCP call, client retry,
commit or push. Existing dirty state is preserved. The independent Unconfirmed
FOLLOW-UP is unchanged. Root cause and real-client query acceptance remain open.

## Approved historical provenance/isolation follow-up — 2026-10-21

The user approved the recommended read-only continuation. Inspected the official
MicrosoftDocs file's bounded commit history and two historical text revisions,
plus Microsoft Learn search results and the official startup-troubleshooting
article. No archives, executables or drivers were acquired. This closes the
historical-source check; do not keep repeating route discovery indefinitely.

### Historical support versus obtainable artifact

The [official June 2026 revision](https://github.com/MicrosoftDocs/sysinternals/blob/abc3a6933d904d0bd53b0a8651fe774ed3ca9c96/sysinternals/downloads/procmon.md)
identifies **v4.04**, published June 17, 2026, and lists Windows 10 and higher.
The [earlier official revision](https://github.com/MicrosoftDocs/sysinternals/blob/3de7bdec8533ab751a49f853dcbb983a40cc5a60/sysinternals/downloads/procmon.md)
identifies **v4.01**, published June 20, 2024, with the same client minimum.
Thus historical documented Windows 10 compatibility is established for those
versions. It is no longer accurate to treat all Procmon versions as lacking a
Windows 10 support statement.

Both revisions link the same unversioned
`https://download.sysinternals.com/files/ProcessMonitor.zip` and Sysinternals Live
executable. A historical documentation commit freezes its text, not the linked
binary. It supplies neither a pinned old archive nor its authoritative digest.
No version-pinned official distribution was established by this bounded check;
this is not proof that no such distribution exists anywhere. No request was made
to fetch that mutable ZIP, and a successful response would not by itself prove
v4.04 identity. Do not guess a legacy URL, use a mirror, or promote documentation
history into verified binary provenance.

### Permissions, automatic capture and filtering

Microsoft's [startup troubleshooting article](https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/troubleshoot-apps-start-failure-use-process-monitor)
explicitly instructs running Procmon elevated, matching the executable to the
platform, and states that recording normally starts automatically. Opening the
tool merely to inspect menus is therefore not an admitted no-capture operation.
The article documents backing files and warns that unbounded virtual-memory or
disk retention can exhaust the respective resource. It provides a broad capture
then post-filter example, which is not the target-only collection boundary
required here. Do not execute its generic terminate command against an unknown
recorder or assume it identifies an owned session.

The article's example includes Process Create/Process Exit events. This strengthens
the generic process-event capability evidence, but does not verify exact exit-code
or cwd fields in an acquired compatible version, target-child attribution, stderr,
or measured overhead on this machine.

Learn search surfaced community Q&A about `Drop Filtered Events`, including a
historical version-specific behavior report. Community reports/search snippets
are not a supported pre-retention exclusion guarantee for v4.04. No version's
raw-isolation gate is passed from these results, and no experimental verification
was performed. No claim that Procmon has no drop option is made.

### Gate update and decision

| Gate | Historical compatible candidate | Current v4.12 |
| --- | --- | --- |
| Documented Windows 10 support | pass for historical v4.04/v4.01 documentation | fail against current documented client minimum |
| Official obtainable fixed binary/provenance | unknown; mutable download URL only | official source exists, but wrong documented client minimum |
| Pre-retention raw isolation | unknown | unknown |
| Permissions/start behavior | generic elevated/auto-capture behavior documented; version-specific lifecycle unverified | same generic evidence; no local run |
| Complete evidence fields and bounded overhead | unverified | unverified |

Final Procmon disposition remains **DEFER / DO_NOT_ACQUIRE_OR_RUN**. It is a
diagnostic-route suitability result, not a UnityCodeDB defect or a diagnosed
cause of initialize closure. No POC is admitted while distribution/isolation
gates remain open.

Recommended continuation: stop chasing historical tool versions and return to
the **host-native stderr evidence boundary**. The next read-only check should
establish a supported logging control, the applicable target-child stderr site
and sink, the narrowest filter/output scope, and whether the installed host
requires restart. Do not repeat the completed failure-window search or infer
effective behavior from a current upstream source version alone. If a necessary
setting/restart would change the parent or inherited child environment, disclose
that as a separate diagnostic experiment before any execution. If no supported
bounded route is found, return the missing facts rather than adding another
tool or retry. No host setting/restart experiment is executed or authorized by
this follow-up result.

Only task records were written; config, Package/source/runtime, registration and
the deferred Unconfirmed task remain untouched. CodedbTest_1 remains the target;
Attempt 04 remains on hold. No new Unity project, MCP call or client attempt.
