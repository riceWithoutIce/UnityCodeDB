# F01/F02 bounded repair result

Date: 2026-10-25. Status: `SCOPED_FIX_AND_REVIEW_PASS`.
User disposition: FIX_NOW for F01 and F02 ("需要处理 f01 \\ f02").
Paths below are relative to the repository root. No commit or package delivery.

## F01 — Default diagnostic publication disabled

Changed only `.worktrees/cdb-identity-handoff-heartbeat-followup/`
`com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` on top of isolation HEAD
`0f61646ae376ec5ddf3351581487f468ade93520` (Package baseline equals fe08d6e).

- Default Manager factory returns null; its existing render consumer returns
  before collecting/publishing transition evidence. No default sidecar writer.
- Both full-document `CODEDB_S12_EVIDENCE` log routes require explicit opt-in.
- `CODEDB_EDITOR_DIAGNOSTICS=1` in the Unity process environment enables the
  retained diagnostic paths. The value is cached once per script domain; change
  it before launching an intentional diagnostic session. Other values stay off.
- Counters, SessionState save/restore, existing regression tests, helper bounds,
  lifecycle scheduling, C-scheme observation and product failure logs retained.
- No new menu, polling loop or logging subsystem. Historical diagnostics were
  not deleted; the existing consumer Package has not been changed.

Final source SHA-256:
`e939c8d8163ede9ca4a372a608fc5d7c66e24d83d230438e71db496048ea865e`.

## F02 — Unaccepted writer-lifetime WIP excluded

In the primary checkout, restored exactly these two files to the Git blob bytes
at accepted baseline `fe08d6e0961189cedd467487675062564c470644`:

| File | Restored SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs` | `56fe365a01da3a9b526f494080055c4d42e5b8f809849f1868d42eb4185fd32f` |
| `com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1` | `cb0a431dc5f0340623d5e79ea8a48a45cb5f74d883f45cce7aa31e9793d5d017` |

Preimages matched immutable commit
`f7634d29664e6557308938068814d5d2d1c0fd5c` exactly, and are recoverable with
`git show <that-commit>:<file>`. Preimage hashes respectively:

- `a3c9ae743c4634167f8cbbf20146be9b06132f8a54ef8f9e463f3a4bfc7380d1`
- `44216a7061384c095b54b2183bc9dacb19f63428c3868f19ec9f1f4c8b11334c`

Only the independent timeout-policy deltas were removed. No alternative writer
policy implemented or runtime safety verdict asserted for either strategy.
Main and isolation source remain separate; this is not whole-Package integration.

## Focused evidence and limitations

Task harness: `verify-f01-f02.ps1` in this directory. Generated run root:
`.artifacts/tests/cdb-v0.3-candidate-residual-legacy-review/`
`1d2ce6c8-f8fc-4fbb-98e9-6c907b4ec160/`.

- `receipt.json`: PASS, nine grouped checks. Compiles exact extracted gate,
  factory/checkpoint/Manager-close bodies with the unchanged BCL sidecar helper;
  Unity logging, JSON facade, SessionState and counter are explicit stubs.
  Executes absent/0/true/1 opt-in cases; checks disabled paths create no project
  directory/logs, counters persist, explicit-on writes valid sidecar JSON and
  emits both logs, and the gate stays cached after environment changes.
- Entire changed evidence file and restored C# runner parse successfully;
  restored PowerShell writer parses without running the writer.
- `closure.json`: PASS. Exact accepted Git-byte equality and immutable WIP
  recovery checked for both writer files; all six pre-existing isolation dirty
  files match their original hashes. Both HEADs unchanged; no extra isolation
  changes; scoped whitespace checks pass.
- `preimage.json`: retained original dirty-file and writer source hashes.
- `receipt-mechanical-error.json`: first harness attempt failed before scenario
  assertions because PowerShell reflection wrapped a string in PSObject. The
  harness invocation was corrected once; no product repair/retry was needed.
  The original failure receipt is retained.

This is offline BCL/extracted-body and syntax/source evidence, not full Unity
compilation, NUnit/EditMode, consumer, MCP, lifecycle or release acceptance.
No Unity/MCP start, live process control, export, installation, reference switch,
consumer writes, commit or push. Formal tests and existing dirty state retained.

Current session completed the stable repair then reviewed only F01/F02 and
adjacent wiring; this is not independent review. Both findings close at the
source/candidate-scope level. Source integration, delivery and any authorized
Unity acceptance remain subsequent work. Stop this review here.
