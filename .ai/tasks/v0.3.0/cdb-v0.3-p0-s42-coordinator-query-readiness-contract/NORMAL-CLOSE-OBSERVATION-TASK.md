# Human normal close and bounded retirement observation

Status: COMPLETE_OBSERVED_RETIRED; see NORMAL-CLOSE-OBSERVATION-RESULT.md.
Human approved the next normal-close/observation
gate after exact updated commit/export PASS. The export remains undelivered.

Target: external CodedbTest_2 Unity project, as bound by existing S42 receipts.
Human closes it normally and reports closure. Do not operate Unity automatically,
request Manager Stop, send Supervisor shutdown, Stop/Start, or reconnect. Do not
execute the observer before the human reports closed.

## Read-only observation envelope after reported closure

One bounded disk/process snapshot, maximum 30 seconds, no recurring polling or
waiting for a preferred result. Prepare the observer before executing it.
One read-only OS process inventory command (10-second timeout) and, only where
needed to resolve a recorded PID, at most four individual read-only identity
probes (3-second timeout each), maximum total 30 seconds. No authenticated status
RPC is needed: a residual live or unknown owner blocks this gate. No service
commands, process kills, locks acquired/deleted or runtime edits.

Read closure: target manifest/lock, selected pointer and bound instance manifest,
target UnityLockfile presence, existing Supervisor state/lock/current operation,
the known failed Stop history entry, selected coordinator state, policy/manual
state, and prior S42 safe ownership/retirement receipts as historical correlation.
If an existing record names a related child PID, include its disposition within
the stated probe budget; do not scan unrelated runtime directories or logs.
Validate safe paths/no redirects and file size before parsing. Tokens, pipe names,
raw command lines, free-text logs and raw state remain in memory; emit only safe
identity/disposition projections and source hashes.

Identify target-related live Unity/Supervisor/coordinator/Provider/worker or
maintenance processes by current path and invocation evidence, not stale PID
numbers alone. An absent state file, reused PID or shutdown acknowledgement is
not sufficient retirement evidence. Unreadable/unknown process identity, residual
target owner/child, ambiguous binding, exceeded budget, lock/Unity conflict or
pointer/reference drift ends this gate without further sampling or recovery.
Record pointer before/after stability and the exact evidence limits.

Expected binding remains old reference
file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb,
instance a492a5e936c14e4da3ed7e4cc7c8c16c,
activation 063aa347f49a4b9f955a5447f293a0ac,
pointer SHA-256 1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.
Historical owner/PIDs are correlation hints only; do not assume still current.

## Output and boundary

Fresh safe report under .artifacts/tests/s42-normal-close/ and a concise task
result. Classify OBSERVED_RETIRED, RESIDUAL_LIVE, or NOT_ESTABLISHED with reasons.
Do not report retired when attributable backend/maintenance disposition remains
unknown. Keep the former failed Stop and exact package evidence unchanged.

This grant covers human normal-close coordination and the bounded read-only
observation only. External Package copy, manifest/lock switching and reopening
are later operations requiring a concrete prepared delivery envelope. No action
is inferred from silence or elapsed time. The human reports closure first.
