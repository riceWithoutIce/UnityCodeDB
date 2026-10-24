# Bounded existing startup evidence extraction

Status: COMPLETE; see HISTORICAL-STARTUP-EXTRACTION-RESULT.md. Human said continue after the historical read-only
route proposal. One invocation, no retry or live service observation.

Target: existing external CodedbTest_2. Historical window inclusive:
2026-10-22T06:26:02.409Z through 2026-10-22T06:33:53.622Z. This bounds the
post-delivery reopen through the healthy capture; screenshot times are unknown.

Read closure: selected project's fixed control/contracts/v0.3-control/v2/
supervisor/supervisor-events.jsonl, optional supervisor-error.json, and one
enumeration of operation-history/*.json. Also existing LOCALAPPDATA/Unity/
Editor/Editor.log. Do not read current state, leases, tokens, other projects,
rotated logs or alternate locations. No RPC, shell process inventory or imports
of production entrypoints. Metadata already found ~601KB events, 167 history
files totaling ~602KB, ~5.8MB Editor log; supervisor-error absent.

Limits: events <=1MiB / 10,000 lines, history <=256 regular JSON files / 256KiB
each / 4MiB total, optional error <=64KiB, Editor log <=8MiB / 100,000 lines,
total reading/processing <=20s. Refuse symlink/junction ancestors. Snapshot
existing file length on open and read only that prefix once; no following live
append, resampling, retry, sleep or wait for desired results. Incomplete final
JSONL line is recorded as such, not repaired. Changed/truncated reads stop.

Safe repository-local report only, under .artifacts/tests/s42-startup-history/.
Project paths and raw bodies remain in memory. Project-bound events are selected
by file location and timestamp; retain only safe event/code/name, timestamp,
sequence, operation/request/owner IDs, phase and exit classification, source
prefix hashes. Free-text detail/output/error becomes hash plus predefined
matching flags. No raw tokens, pipes, command lines, source excerpts or Editor
log dump. At most 128 matching events and 64 matching operations emitted.

Editor log: determine whether exact project path appears, retaining only its
boolean/line numbers, not path lines. Scan once for predefined timeout/error
markers and CODEDB_S12_EVIDENCE JSON. Keep at most first/last 32 errors, and first
64 lifecycle state/owner transitions matching selected instance or known owner.
Emit safe counters/codes, source line and any explicit timestamp, not raw text.
If no timestamp/correlation exists, mark time/target attribution limited; do not
ascribe the whole Editor log or later entries to this startup window.

Preserve missing records and truncation as evidence limits. Script fixture or
syntax correction before reading is mechanical preparation; no second semantic
capture after first live historical extraction. On first parsing/budget/binding
anomaly save the partial safe report and stop. No product mutation, diagnostic
instrumentation, Unity operation, cleanup or fresh reproduction is authorized.
