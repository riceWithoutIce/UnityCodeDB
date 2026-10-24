# Process observation 03 — capture complete, correlated early Node exit

Date: 2026-10-21.
Status: CAPTURE_COMPLETE / TARGET_INITIALIZE_FAILED /
TARGET_PID_ATTRIBUTION_INCOMPLETE / QUERY_NOT_EXECUTED.

The human executed the authorized observation 03 launcher in a separate
administrator Windows PowerShell and created one normal target-root chat after
OBSERVER_READY. The development session analyzed only retained data afterward;
it did not start another recorder, MCP connection or target query.

## Window and integrity

- Ready: 2026-10-21T04:22:04.2230124Z.
- Receipt ended: 2026-10-21T04:22:11.9090681Z; interval 7.6860557 seconds.
- Create and stop both returned 0. Final query returned 0x80300002 (session
  absent), confirmed again by a read-only exact-name query from development.
- ETL: 131072 bytes, below the 16 MiB circular cap. Tracerpt reports 16 buffers,
  44 total events and 0 lost events: 29 process starts, 13 process stops and
  two trace metadata events. No circular overwrite is indicated by file size.
- Get-WinEvent returned the same 42 process events plus one metadata record;
  the metadata record contains ProcessingErrorData. Tracerpt warns of a schema
  mismatch. This metadata decoding limitation is retained, rather than claiming
  every event decoded cleanly. Both readers agree on the process-event counts
  and candidate lifecycle fields.
- Registration, manifest, lock, selected pointer and wrapper hashes match
  between the recorder's before/after snapshots.

Raw scope remains all process metadata from the enabled provider in this short
window, not a target-only trace. No additional file/Registry/network/stack or
stderr stream collection was performed. Raw data is retained, not uploaded or
automatically deleted.

## Target thread attribution

The retained host events name thread
`01a15cb1-fc9a-7080-8598-7137e037884c`. A read-only app thread lookup confirms
the title **观测 MCP 启动状态**, the CodedbTest_1 cwd, and the exact instruction/
returned result supplied by the user. Thus the host startup failure belongs
to the intended chat even though the chat itself could not report its ID.

Target service `codedb-codedbtest-1`:

| Event | UTC |
| --- | --- |
| Host starting | 04:22:11.014 |
| Host failed, initialize response connection closed | 04:22:11.265 |

The host interval is 251 ms. Target namespace absent; status/query/other CodeDB
calls all zero. The target chat's only shell command read cwd; its later duration
does not extend the already completed recorder window.

## Correlated candidate lifecycle

| Field | Candidate A | Candidate B |
| --- | --- | --- |
| PID | 70836 | 22252 |
| Process sequence | 224892 | 224891 |
| Parent PID / sequence | 75104 / 159910 | 75104 / 159910 |
| Create UTC | 04:22:11.0359488 | 04:22:11.0319984 |
| Image | Same Node executable as ordinary target-session resolution | Same Node executable |
| Exit UTC | 04:22:11.2637733 | No stop event in this window |
| Exit code | 1 | Not observed |

The read-only QueryDosDevice check establishes the candidate NT image volume
matches the drive used by the target-session Node path; its remaining image
path is the expected Node installation path. The machine-specific absolute
paths are retained in the local analysis JSON, not used as durable product
configuration. The actual Node version of the exited process was not captured;
same image path is not a new runtime version measurement.

Candidate A lived **227.8245 ms** and exited **1.2267 ms before** the host
reported this target initialize failure. A scoped current parent snapshot
identifies PID 75104 as the managed Codex executable, parent 61080, with a
creation time preceding the capture. ETW parent sequence/time plus that snapshot
support the app-server lineage; the snapshot is separate from the historical
ETW event, not a captured parent command line.

This is strong temporal/lineage evidence, but **not a direct target-PID binding**.
At least two Node children of the same parent were created together, and other
normal MCP services initialize in a new chat. There is no argv, cwd, registration
name or wrapper path in these process events. Candidate A may therefore be
described as highly correlated, never as proven execution of the target wrapper.
Exit code 1 does not identify which check failed or who initiated termination.

## Additional bounded evidence

A single post-run bootstrap-directory snapshot found only the existing
60580 baseline record from 01:47:53Z; no new diagnostic record was present.
This does not prove wrapper code never ran or place failure before a particular
checkpoint. An existing runtime DB query bounded to this new window found no
matching MCP-stderr messages; the database is not treated as a complete child
stderr transcript. No stderr was obtained by this observation.

## What this establishes and what remains

Established: the observer works with administrator permissions, records actual
process lifecycles, and cleans up within this window; the intended host attempt
fails initialize; app-server-created Node processes exist, including one early
exit with code 1 closely aligned to that failure. Ordinary-session Node/image
selection has additional corroboration. No project mutation was observed.

Still unknown: which PID is the target service, actual target child cwd/argv,
executed wrapper/worker checkpoints, child stderr, and precise failure cause.
It is not valid to conclude target child creation or successful wrapper loading
solely from these correlated Node events. No source defect, environment defect,
Provider/lease failure, transport defect or release/query PASS is diagnosed.

The next useful evidence is a **direct binding of target server to PID/entry**
and a **cause-bearing launch detail or stderr**. Do not repeat an unchanged
process-only window, create another Unity project or retry queries. Any new
collection route or launch modification needs its own concrete scope; this
completed run does not authorize another window.

Evidence directory:
`.artifacts/tests/s39-process-observation/eae4fb16d8894512967086c76f0ceaab/`:
receipt.json, process.etl, process-decoded.xml, trace-summary.txt and
candidate-analysis.json. No raw unrelated process history was added to this
durable result.
