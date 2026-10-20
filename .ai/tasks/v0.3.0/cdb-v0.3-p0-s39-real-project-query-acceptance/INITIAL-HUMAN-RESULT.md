# S39 external project import baseline — 2026-10-20

Status: `IMPORT_BASELINE_PASS / FIRST_INSTALL_PENDING`.

The user reports that the independent `CodedbTest_0` Unity project opened with
no Console errors. The attached Manager screenshot (`codex-clipboard-645dcef1-0f8f-4933-8e27-29affaa1124e.png`)
shows:

- Project `CodedbTest_0`, Package `0.3.0-preview.5`.
- Overview state: `Not installed`.
- `Install CodeDB` is available.
- No recent command is shown.
- The Manager explanatory text says setup could not finish; with no install
  action recorded in this project, retain that wording as the current
  uninstalled-state diagnostic rather than classifying it as an Install
  operation failure.

Read-only parent checkpoint while Unity remained open:

- One Unity Editor process targets this project; `Temp/UnityLockfile` exists.
- `AIWork/` and project `.codex/` do not yet exist.
- Configured manifest and lock hashes remain the recorded S39 values:
  `6ff38dacfb02aaebc7122ac24e1ec0677b1e66f4f06fdaef923fc62a077a8f51` and
  `e39be4e16dd7c41024445132a6b32725ed328c30e63503c94fb856ead82b7200`.
- The query sample exists under `Assets/CodeDBAcceptance/`.

This is human import/compile and uninstalled-baseline evidence. It does not
prove Package installation, runtime readiness, generated MCP registration or
real Codex query exposure. The next authorized human action is one first
Install after this clean baseline.

## Handoff

- Current task: S39 independent Package consumer and Codex query acceptance.
- Current status: IMPORT_BASELINE_PASS / FIRST_INSTALL_PENDING.
- Next notification: User.
- Next action: human confirms the single first Install in this project; parent
  then records the attributable terminal result and independent Ready.
- Human decision or authorization required: none beyond the already agreed
  first Install action; stop on an unknown or failed action and preserve it.
