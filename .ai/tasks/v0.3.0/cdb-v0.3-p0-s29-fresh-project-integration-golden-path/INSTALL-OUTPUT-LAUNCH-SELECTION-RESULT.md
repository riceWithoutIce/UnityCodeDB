# S29 existing pipe launcher selection result

2026-10-08. Stable diagnostic handoff. Status:
EXISTING_PIPE_LAUNCHER_NORMAL_DETACHED_FAIL / REJECT_DIRECT_HELPER_SWAP /
EXACT_OS_HANDLE_OWNER_UNPROVEN / ALL_EIGHT_RECORDED_FIXTURE_PIDS_ABSENT.

## Decision and bounds

The existing delivered `Invoke-BoundedNativeProcess` does not resolve the reproduced
output-lifetime boundary. A direct switch from the file-output helper to this pipe
helper is rejected by the normal detached-service scenario. No production repair is
selected or implemented. Do not weaken EOF checks or interpret direct exit0 as success.

Fresh exclusive sandbox: `.artifacts/diagnostics/io/a67ea4b3`.
Owner token: `a67ea4b39dba4326ad74bd5fd4042ba6`.
Runs began 2026-10-08T13:14:23Z (21:14:23 UTC+08). Exactly two scenarios executed:
ordinary leaf and normal detached daemon. No intentional retention control, additional
causal follow-up, baseline rerun or extra candidate was run after normal-case failure.
Daemon self-expiry was35seconds; each run remained inside60seconds. No early daemon
exit was used to create a successful result. The20minute task budget was not exhausted.

## Exact implementation and results

The actual delivered Manager writer was copied byte-for-byte. The control imported
the delivered ProcessStartInfo pipe helper and its argument helper as exact AST
function extents, without materializer top-level evaluation. Leaf WinPS and Node
CLI/daemon bodies are byte-identical to prior sandbox995de5da. Normal Node startup
remains detached:true, stdio:ignore, windowsHide:true, unref(). All child TEMP, TMP,
LOCALAPPDATA and generated receipts/data are sandbox-local. No HOME or CODEX_HOME
override. Runtime Windows PowerShell5.1.19041.6456, Node24.14.1.

| Scenario | Native elapsed | Native direct exit / incomplete | Manager elapsed | Manager command exit / incomplete |
| --- | ---: | --- | ---: | --- |
| Baseline leaf | 314ms | 0 / false | 744ms | 0 / false |
| Normal detached service | 5602ms | 0 / true | 11010ms | 6 / true |

Manager command exit is the actual writer receipt's exit_code, not the utility's
own exit. Native and Manager clocks have different origins. Baseline observer saved
both outer stdout/stderr EOF and a terminal receipt at its completion checkpoint;
observer duration2166ms and writer utility exit0. Native baseline captured expected
leaf stdout/stderr normally.

Normal detached native error:
`Native output collection is incomplete; project effects are not proved stopped.`
Actual Manager terminal independently records output_drain_incomplete=true and:
`Manager action output did not reach EOF after the child exited; captured output may be incomplete.`
The control's exit6 maps its real native incomplete result into fixture command
failure; no actual installation or instance engine was invoked.

The same failure therefore persists without the file-output helper. This is evidence
against an intermediate-file-redirection-only explanation. It does not identify any
specific OS handle or process as the handle owner, nor reconstruct the live S29 case.

## Daemon lifetime and observer limitation

At native return, control recorded exact daemon PID26144, start ticks
639270620665013388, executable F:/Program/nodejs/node.exe, matching run token, and
alive=true at13:14:31.8338388Z. No daemon exit file existed then.
The actual Manager failure terminal was persisted at13:14:36.8888737Z.

The external observer's completion condition additionally required EOF on its own
writer stdout/stderr pipes before its second daemon-live checkpoint and cooperative
stop. Those outer tasks did not let that checkpoint execute while the daemon survived.
When it finally attempted the checkpoint, Get-Process for PID26144 failed because the
daemon had already self-expired. The daemon records `self-deadline` at13:15:01.551Z.
The observer exited1 at this identity/lifetime check and did not save detached
result.json, writer-stdout.log, writer-stderr.log, or manager-checkpoint.json.

This is a harness reporting limitation, not a product PASS. There is **no saved
daemon-live proof at a successful Manager EOF checkpoint**. No such successful
Manager internal checkpoint occurred: its authoritative terminal explicitly says
incomplete. The separate observer outer EOF timing was not saved and cannot be given
an exact millisecond value. Do not mislabel its eventual drain after self-expiry as
successful isolation. Exact Manager-time daemon liveness was not independently
sampled into a persistent checkpoint; native liveness plus daemon self-expiry records
provide chronology, not that missing direct checkpoint.

The independent native result and actual Manager terminal were durable before this
observer exception and are sufficient to reject the candidate. A read-only finalizer
collected them into recovered-results.json, audited exact recorded PIDs and source
hashes, and checked old evidence. It did not rerun any process scenario or modify the
observer implementation to retrospectively make the run pass.

## Cleanup and preservation

No cooperative-stop file was sent in the normal scenario because the EOF checkpoint
was never reached with the daemon alive. The unchanged daemon's35second self-expiry
ended it. No kill, broad scan, process-tree termination or unrelated PID access was
performed. Final exact-PID audit records all8fixture roles absent:

- Baseline: writer28172, control33652, leaf21420.
- Detached: writer15380, control29024, leaf34644, Node CLI37916, daemon26144.

WinPS records contain exact start ticks; Node CLI self record lacks OS start ticks.
Daemon exact ticks are retained in native-result.json. No termination depended on
incomplete attribution. All receipts and evidence are retained in the new sandbox.
The91files present in995de5da before this work match afterwards by path, length and
SHA256; no old file changed, disappeared or was added. Source writer/materializer
hashes were rechecked and unchanged. All42new evidence files existing at finalization
are enumerated in file-inventory.json (the inventory itself is excluded).

## Source identities and evidence

Delivered source root:
`.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb`.

| Source/import | SHA256 / exact AST lines |
| --- | --- |
| Tools~/invoke-codedb-manager-action.ps1 and sandbox copy | 657f780c53d2cc69e47b16a4b28954003a3fdfcf9397d551db779ac0f8bed0a4 |
| Tools~/materialize-codedb-host-payload.ps1 | 39e7872ab387457c477da318a271776ae4c9fc565e12af0f26ba2c8d072cc16a |
| ConvertTo-NativeProcessArgument | 481e3b4b131e99e0f6c439d272fb8a75dd9e422e9dee3ed19008936994b7b1b1; lines323-360 |
| Invoke-BoundedNativeProcess | 6e07a2171a1cfe275e0fa216cdfb1d301cd18ee6ba7873aa0105df375cdf91f6; lines362-447 |
| command.ps1 | 63ba64914b850a050371e6d504da9efe42cbcfcd0e74bf47c1d78c8b8c81e1fe |
| run.ps1 | 8a57949a9b5023de5514cf3d7198ab33de09c3ecf5b656e9474152f9f78ca5e2 |
| unchanged leaf.ps1 | 3f4e3c842fd9ff8dd41782c36f13360dbc3ab6bdea18029da662e5fd26028066 |
| unchanged service.mjs | 28a8f44bc41ca5cc5aefcee70ed3272cb2aec10d62c2e9a8c59a14f42871863a |
| recovered-results.json | 34ed1701b60d90e5d7bf76b822347a54d052ea6d55f05c3098ed0e7fa24c627c |
| final-process-audit.json | 269ce9a3c4b10c23f0bf758884abaf20558aec6c23991b44f853466b56c8ceb9 |

Source and fixture PowerShell ASTs were parsed before child execution. The actual
writer accepted both sandbox admission identities and emitted terminal receipts.
Native-result.json, actual compact terminal files, recovered-results.json,
identity.json, source-recheck.json, prior-before.json,
prior-preservation-check.json, final-process-audit.json and file-inventory.json
are the authoritative saved evidence; no synthetic receipt replaces writer output.

## Integration recommendation

Stop this selection window. The selected existing pipe implementation failed its
critical normal-case test, so there is no justified production helper substitution.
Any next mechanism requires parent/user alignment and its own narrowly justified
selection, not automatic escalation to native interop or a new broker. Exact OS
handle owner remains unproved.

Even a future successful isolation mechanism must preserve bounded capture, timeout,
partial-output handling, identity, cleanup and Manager receipt semantics. This helper
uses ReadToEndAsync and differs from the file helper in capture/timeout behavior;
those details cannot be accepted wholesale on topology evidence alone. This report
does not broaden into auditing all helper behavior.

No production, immutable generation, S29 project, live receipt, Provider/MCP/Unity,
install/uninstall, commit, export, push, download, runtime compilation or new helper
component was touched. Only this result document and fresh diagnostic sandbox changed.

## Parent evidence assessment - 2026-10-08

Parent read the stable report and saved evidence without rerunning scenarios.
All42inventory entries matched file length and SHA256. Both recovered native
results and both Manager terminals matched their separately saved original JSON.
Delivered writer/materializer hashes still match the frozen source identities.
The saved exact-PID final audit reports all8roles absent; the preserved prior
sandbox audit reports91/91files unchanged. HEAD remains
d56f0e507b48af24a39f23411c06dbdd4e093084; index is empty and product
Editor/Tools~/Payload~/Tests paths have no tracked diff. Inherited documentation
and Unity working-tree changes remain outside this diagnostic comparison.

Decision confirmed: reject the direct existing-helper swap. This is a negative
selection result, not production acceptance. The detached observer failed its
post-EOF identity checkpoint and did not save the four artifacts identified above;
the missing checkpoint remains missing. Durable native/terminal failures suffice
to reject this candidate, but do not prove the exact OS handle owner.

Close this POC window. Next design alignment must address explicit output-resource
inheritance across the short-command/daemon launch boundary. No native interop,
broker, additional experiment, production repair or real Install retry is selected
by this assessment. The technology-selection screening ruled out promoting the
existing pipe candidate without its required normal-case isolation evidence.
