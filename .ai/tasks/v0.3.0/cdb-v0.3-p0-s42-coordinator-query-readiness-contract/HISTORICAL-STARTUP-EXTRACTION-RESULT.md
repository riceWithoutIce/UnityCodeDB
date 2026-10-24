# Historical startup extraction result

Status: COMPLETE_HISTORICAL_EXTRACTION / REQUEST_PHASE_NOT_ESTABLISHED.
One authorized invocation, no retry. Capture 2026-10-22T07:48:39.140Z through
07:48:39.348Z, 208ms processing. Observer syntax PASS; script SHA-256:
99abacebb992188443af0a4a01de8751a5250db5b7423ee8233df61d58eea3f4.

Safe report under <repository-root>:
.artifacts/tests/s42-startup-history/capture-NBsArA/report.json.
SHA-256: a428ea7284782637c49d09f8b95488e7605d77a3999c34bf34d3c580f859d257.
Further analysis read this safe receipt only, not the live source logs again.

## Read limits and provenance

Read fixed-length prefixes of existing files once: Supervisor events 606,186
bytes (SHA-256 ed54efe31b3c65aae0f31aac519ff614c1bfadedf36a1fa9a8c598b0649684a8),
Editor.log 5,755,131 bytes (b99ffe3cc98d0609a4d2e98f3112d03d53f30855778fcfb8b5d07c4c6c79ffd7),
and 182 operation-history JSON files totaling 655,995 bytes. History count grew
from preparation metadata; actual remained within the frozen 256-file / 4MiB
budget. Supervisor error file missing. All other declared limits met.

No live state/lease read, RPC, CodeDB call, process scan, consumer write, Unity
operation, service command or reproduction. Project paths and free-text/raw
records remained in memory; only reviewed safe projections/hashes were emitted.
Captured log prefixes do not freeze future appends or establish continuous state.

## Startup-window evidence

Window: 2026-10-22T06:26:02.409Z through 06:33:53.622Z.
54 matching Supervisor events retained, sequence 1 through 54 in this window.

| UTC | Existing event evidence |
| --- | --- |
| 06:28:29.201 | supervisor_started; event detail matches target project |
| 06:28:29.435 - 06:28:37.895 | materialize:Probe started/completed |
| 06:28:43.658 - 06:28:53.115 | materialize:Upgrade started/completed |
| 06:30:23.182 - 06:30:52.361 | one Probe took 29.179s between start/completion events |
| 06:33:47.803 | Probe started; completion outside this window is not followed |

Window totals: 18 Probe starts, 9 Upgrade starts, 26 completion events, last Probe
still without completion within the selected window. No operation_failed event
or explicit IPC timeout marker in those selected event records. This does not
prove no client timeout: ordinary operation events do not log every exchange.
Operation duration is not IPC response latency or a product performance result.
Repeated Upgrade naming alone does not prove repeated redeployment, an automatic
repair defect, user intervention or the cause of a timeout.

No operation-history JSON matched started/completed timestamps in this window.
The currently retained entries range from 2026-10-21T09:34:36.279Z to
2026-10-22T07:48:31.470Z, but this broad range does not imply coverage of every
intervening operation. Do not infer the retention/deletion cause. Missing error
file is not proof of no earlier error.

## Editor evidence and its limits

Exact target project path appears in the prefix, but does not bind every line
or provide the screenshot timestamps. Selected CODEDB_S12_EVIDENCE entries also
match the selected instance or the historically established Supervisor PID.

Recorded state/owner transitions, in log line order:

| Line | Reconcile completed count | Product state | Supervisor / Coordinator PID |
| --- | --- | --- | --- |
| 782 | 20 | Ready | 42020 / 59360 |
| 2178 | 97 | NeedsAttention | 42020 / 59360 |
| 2196 | 98 | Ready | 42020 / 59360 |
| 3152 | 142 | NeedsAttention | 42020 / 59360 |
| 3205 | 144 | Ready | 42020 / 59360 |

These entries report supervisor_identity_change_count=0; their aggregate
post_admission_disposition is RetirementSelected. These counters may retain
earlier fields; they are not per-request causality proof. No precise UTC time
is available in the extracted lifecycle entries.

At lines 3009 and 3170, identical hashed lines contain SUPERVISOR_IPC_TIMEOUT /
"The Supervisor IPC request timed out." No explicit timestamps or correlated
request/operation IDs are supplied by those lines. Two occurrences need not mean
two distinct requests; a message may have been emitted more than once. Do not
assign these warnings to an adjacent lifecycle entry solely by line proximity.

Conclusion: records show attention/recovery state samples with the same reported
process pair after recorded Ready samples, so a cold-start-only hypothesis is
too narrow. They do not prove unchanged process start identity, absence of lease
turnover, failure-time owner continuity or attribution to the screenshot event.

## Decision

Existing evidence does not distinguish initial command acknowledgment from later
operation polling, nor write vs read wait. The historical read grant is consumed;
do not rescan logs or rerun the scenario to hunt for a better result.

Recommend minimum client-side failure-phase evidence first; see
IPC-FAILURE-DIAGNOSTICS-PROPOSAL.md. Do not enlarge timeout, relabel attention,
change queue/lease behavior or infer a broad lifecycle refactor from this result.
Current S41 functional PASS remains valid; final probe stays B.
