# S29 removal refusal — current process observation diagnosis

Date: 2026-10-15. Status: READ_ONLY_DIAGNOSIS_COMPLETE / USER_DISPOSITION_PENDING.
Source/selected Package commit: `5b52c017e8415bb061f33a8380b3dcec2916411a`.
User request: `好的 我们定位具体问题`. This authorizes diagnosis, not repair.

## Finding and evidence boundary

The latest screenshot shows the suffix `identity is unavailable; removal remains
blocked.` and `[REMOVAL_PREFLIGHT] BLOCKED`. The operation label/ID is clipped.
The exact Package has two branches emitting that suffix in
`Assert-RemoveIntegrationV2ProcessAbsent` (materializer lines 10169 and 10179).
They reject missing/unreadable observation, distinct from original-process-live,
invalid recorded identity and missing-child refusals. No persisted full matching
diagnostic was found in the bounded Library/CodeDB, project Logs and Editor.log
search. No exact first record is attributed to the photographed invocation.
The history reader traverses hashtable keys, not a stable sorted refusal order.

Read-only inspection covered the current v2 Supervisor namespace under:
`UnityFreshInstallValidationProjectS29/AIWork/.runtime/codedb/control/contracts/v0.3-control/v2/supervisor`.
History has 1017 files / 3,737,093 bytes. Selected instance remains
`d620abbab0334a2d9c49e59888c1ef55`, generation `poc.42`, activation epoch
`2f8b2a509a1e4086af4a4457e618d037`.

## Point-in-time process classification

Diagnostic code read JSON with ConvertFrom-Json, observed distinct PIDs with
System.Diagnostics.Process and compared UTC ticks at the existing local
microsecond precision. It did not import or execute the product materializer.
This is field/process analysis, not full strict namespace validation or a permit.
PowerShell 7.6.5 at 06:05:12Z and Windows PowerShell 5.1.19041.6456 at
06:06:37Z returned the same classifications on 2026-10-15:

| Classification under the existing observation rule | History records |
| --- | ---: |
| PID absent | 972 |
| PID visible, readable start time differs | 31 |
| PID visible, start time unavailable | 12 |
| child=null | 2 |
| Original start identity still live | 0 |

The 1015 non-null children contain 770 distinct PIDs. Counts are record counts,
not unique-process counts. Process state is volatile and these observations do
not reconstruct its state at screenshot time or prove all other removal gates.

## Exact unknown candidates

The 12 unknown records refer to nine PIDs. All remain safety refusals under
the shipped reader. A separate local Win32_Process CIM query could read creation
times for those same PIDs, all different from their historical start identities.

| Historical operation ID | PID |
| --- | ---: |
| 57d7e9bce29f4fe881de9edbfcc2f48d | 2592 |
| 5fec6d5fed0048e1a33a23df1636189c | 3664 |
| 8b6804d564274999bbe6bba6a9ec4b72 | 1392 |
| 9e63bcdda5024358a8f475fdb230e9e1 | 19668 |
| a4c80cb23d644b7a8384fbd890e7be27 | 5072 |
| aa4be3ee477344d1876e642392ac0d19 | 4996 |
| aa4c8029f3c14d55b0ed11a9bf71e0de | 196 |
| ac842922d35e4054b108794a7dc36025 | 1392 |
| b1004beea052442fb9c47d36932b557d | 12832 |
| ba5fba9b84ad47a0b6e5c0b78e3aa4f0 | 2592 |
| c347957e897146f68d028b2dd73383f7 | 19668 |
| e12dfd2d0d8144949299a7add3908cae | 2616 |

The current processes are seven svchost PIDs, one MoUsoCoreWorker PID (12832)
and one conhost PID (196); names are descriptive only, not ownership proof.
For PID1392, calling get_StartTime directly exposed Win32Exception native error5
(Access denied). Ordinary PowerShell property access yielded null and the
ToUniversalTime call failed; the product catches this and retains Alive=true
with null StartTicks. Other candidates showed the same null-valued observation
symptom; the underlying native exception was directly sampled only for PID1392.

Concrete comparison for operation `8b6804d564274999bbe6bba6a9ec4b72`:
recorded PID1392 start `2026-10-09T17:28:29.8734350Z`; CIM current creation
`2026-10-15T01:23:20.6112840Z`. Across the twelve records, historical times are
October9 or October13; the nine CIM creation times are October15. These are
supplementary observations supporting PID reuse, not newly accepted product
authority. No fallback was installed and no removal permission was issued.

## Independent retained boundary

Two histories remain child=null:
`45e02ba862654c81af4d592dc56e49d3` (Probe) and
`69d2e7c44f774e3687e352d5faf9eb97` (Upgrade).
They still cannot prove child termination. Completing process observation alone
would not unlock real removal. Two stale Supervisor owner PIDs23984 and8532
were absent on separate read-only lookup; no owner-schema admission is claimed.

## Disposition proposal

The concrete new issue is observation coverage: an existing PID's start time
can be denied through .NET even while another OS observation exposes creation
time. Fail-closed behavior is correct for the reader's current evidence. This
is not a reason to kill a PID, discard history, equate terminal success with
termination, or weaken unknown/missing-child refusal.

If prioritized, first define a bounded Windows read-only identity-observation
contract and decide whether the supplementary channel can safely establish
the same PID/start-time identity, including precision, races, disagreement,
failure and revalidation. Keep it local to the reviewed consumer unless a wider
change is separately approved. This diagnosis does not select or authorize a
production fallback. Preserve the prior no-unbounded-legacy-compatibility policy.
Child-null history disposition remains a separate deferred decision; CleanupMono
remains deferred. S29/release remain PARTIAL.

## Execution limits

No product preflight/Probe/IPC, Unity launch/automation, process stop,
Install/Remove/Upgrade, history mutation, export, reference switch or commit
was performed. Accepted three-file source diff is empty, HEAD remains5b52c01,
and staged index remains empty. Only this diagnostic document was added in this
diagnosis stage. No protected-state baseline comparison was performed here.

Initial over-broad listings were truncated. One analysis command mistakenly
separated finally from try/catch and emitted repeated shell errors; corrected
diagnostic code supplied the bounded counts above. Two auxiliary commands were
rejected at parse time for piping a foreach statement directly; corrected
array-wrapped statements supplied the observations. These are diagnostic helper
errors, not product test failures or product changes. No new test PASS is claimed.
