# S38 logical Uninstall result - 2026-10-20

Status: `LOGICAL_UNINSTALL_PASS / CLEANUP_PENDING / REINSTALL_NOT_RUN`.

## Human observation

The user reports `uninstall 成功` and supplied a Manager screenshot (attachment
ending `704221b3-f739-4af0-a283-f9a9dc693861.png`). It shows
`current-lifecycle / Uninstalled`, `CodeDB is uninstalled from this project`,
an available `Install CodeDB` entry, and Last activity `Uninstall CodeDB from
Project / Completed / Exit 0`. The UI says the command completed with warning;
that warning is classified separately below.

## Exact action and operation

- Manager action `67e4cec33b0849b9a2be636e5710f939` binds the exact S38
  project and S37 `d856a8f` Package. Its binding identifies only operation
  `ab35b80a3bcd40e3bf3f823b44546bb0`.
- The original operation is `materialize:Uninstall`, state/phase `completed`,
  started `2026-10-20T06:02:56.164Z` and completed
  `2026-10-20T06:03:07.512Z`. It matches the pre-action selected instance
  `2fec1db083b74b2c9d371e1bce558736` and generation `poc.43`.
- Its writer records exit 0, no timeout, overflow or incomplete output drain,
  and empty stderr. The structured result is `UNINSTALL / UNINSTALLED /
  COMPLETE / LOGICAL_UNINSTALL_COMPLETE`, mutated scope
  `instance_activation`, cleanup `PENDING`. Original operation-history SHA-256:
  `891b4a73b112d50ab910d2f01a257468dc9b4c40fd6e3b90653a61d0182c25de`.
- The operation has `handoff_queued=true`, reason
  `selected_instance_changed`. This explains the UI warning. Its result says
  the prior instance remains inert and pending, and no external MCP process
  was stopped. These are product-reported handoff facts, not an independent
  physical process or tree cleanup audit.

## Logical postconditions and separate maintenance

- `desired-state.json` is `UNINSTALLED`, cleanup `PENDING`. The active
  `current-instance.json` pointer is absent.
- Project `.codex/config.toml` has no active configuration lines; its six
  lines are CodeDB-owned uninstall tombstone comments. SHA-256:
  `b8775476bd1c0752f66813ae0c0d229f7f02a77cba4751d8559bb43560513cf4`.
- Package manifest and lock still resolve to the same S37 extraction, with
  hashes matching `SETUP-RESULT.md`. The exact project Manager index has a
  resolved action marker and no current-action file.
- An automatic `materialize:Upgrade` completed as `failed` 11 ms after the
  Uninstall operation. It had `NO_CHILD`, no child process and exit 4 because
  the selected instance changed before the queued request was admitted. It
  has no Manager action id and is not the Uninstall operation. The last
  operation record is terminal rather than running. This bounded observation
  does not establish full background cleanup.

Logical Uninstall passes. Retained instance files, pending cleanup and the
queued maintenance handoff remain separate. No retry, manual cleanup,
process control, Unity automation, source edit or Package switch occurred.

## Proposed same-version Install

After a separate explicit grant, the human may click `Install CodeDB` once in
this same S38 project and confirm once, using the unchanged Package reference.
Normal product-owned runtime/config creation and managed process startup are
included. Let the command settle and report Last activity, final Manager
state and any Console errors. The parent will check the attributable original
result, newly selected instance and an independent Ready observation. A new
instance must be distinguished from the retired first-install instance.

At failure, unknown result, a new prerequisite or ten-minute nonconvergence,
preserve the first evidence and stop. Do not retry, reset history, delete the
retained instance, stop any process or reinterpret the earlier Uninstall.
This proposal does not authorize the Install action.

## Explicit same-version Install grant and pre-action checkpoint

The user replied `同意` after the same-version Install proposal, authorizing
one human-confirmed Install and the bounded read-only evidence check. This is
the second Install in the S38 lifecycle and must create a new selected
instance; the first instance remains historical retired content. No retry,
manual cleanup, process control or further lifecycle action is included.

The pre-action checkpoint confirms `desired_state=UNINSTALLED`,
`cleanup_state=PENDING`, and no active `current-instance.json`. The project
`.codex/config.toml` has zero active configuration lines and retains only six
CodeDB-owned uninstall tombstone comments. Package manifest and lock still
resolve to the exact S37 `d856a8f` extraction and the testable declaration is
present. The Manager action directory has only resolved markers and no active
action marker. The prior maintenance `materialize:Upgrade` failure is terminal,
had `NO_CHILD`, and is preserved as a separate post-Uninstall observation.

The human may now click `Install CodeDB` once and confirm once in this same
project. Keep Unity open until it settles. Report the Last activity result,
final Manager state, Console errors, and preferably a screenshot. On failure,
unknown result, a new prerequisite or ten-minute nonconvergence, preserve the
first result and stop; do not click again.
