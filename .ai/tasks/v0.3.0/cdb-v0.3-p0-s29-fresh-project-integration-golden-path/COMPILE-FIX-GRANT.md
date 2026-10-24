# S29 Compile Interface Repair Grant - 2026-10-06

## Authorization And Entry

- Same task: `cdb-v0.3-p0-s29-fresh-project-integration-golden-path`.
- Direct human `同意` accepts compile-interface repair -> targeted independent
  review -> new local Package delivery. One continuous repair envelope, not
  per-command approvals. DURABLE_SESSION / REUSE_ONLY; existing Coder and
  Verifier profiles/settings only, no child/replacement or recursive delegation.
- Entry is conditional on human confirmation that
  `UnityFreshInstallValidationProjectS29` is closed. Do not infer closure, launch
  or terminate Unity, or substitute process/MCP/UI probes. Planner dispatches
  once after the confirmation and one compatible idle-binding check.
- Entry confirmation received in Planner chat: the human explicitly reported
  `UnityFreshInstallValidationProjectS29` closed on 2026-10-06. The compatible
  stopped existing Coder binding was admitted before the single dispatch.
- Branch: `codex/v0.3.0-legacy-workflow`.
- Base HEAD: `306f329b8f51f82695dccc5e8de67c6bcea5320e`.
- The three source/test paths below were clean at Planner preparation. Preserve
  all inherited dirty/untracked state, consumer projects and prior role records.

## Proven Cause And Required Outcome

At `AICodedbProjectIntegrationState.cs:339/341/342`, origin is statically
`IDictionary<string, object>` but `AICodedbStrictJson.GetRequiredString` accepts
`Dictionary<string, object>`. Close this one direct C# type boundary coherently.
Do not add duplicated field readers, unchecked casts, suppression, dynamic
dispatch, weaker validation, or a version/environment workaround. Retain:

- Legacy absent/null origin readability.
- Exactly `action`, `action_id`, `operation_id` for a present origin object.
- INSTALL/UPGRADE/REINSTALL action set and strict lowercase manager IDs.
- Existing parser/property/type failure semantics and neighboring JSON callers.
- All previously accepted first-install, correlation and lifecycle semantics.

No wider Host redesign, schema/identity changes or historical candidate recovery
is part of this compile repair. The online Package Manager search failure is
separate and out of scope.

## Exact Write Scope

Touch only the necessary subset of these repository-relative files:

1. `com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs`
2. `com.rice.ai-codedb/Editor/AICodedbStrictJson.cs`
3. `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`

Coder records: `COMPILE-FIX-RESULT.md` <=8 KiB and
`COMPILE-FIX-IDENTITY.txt` <=2 KiB in this task directory. Do not rewrite previous
RESULT/verification/checklist/identity evidence. TASK, this grant, human grant,
roadmap, contracts, workflow, index, versions, Package metadata, Tools, Payload,
generations, consumer manifests/locks and all `.artifacts` copies are read-only.

Read closure: this short grant, the relevant TASK failure section, these three
files and directly referenced JSON/protocol definitions/callers. Use bounded
symbol/range reads, not full TASK/history/session/runtime dumps. No machine
Provider, project runtime, global configuration, action-history or process reads.

Baseline SHA-256 rows (ordered exactly as the three-path scope above):

```text
34ea23e11d5b0704c57cd4048a1bd9450fd5134780c9b8d504c5ea792b77dcac
b56907a4de7e65aee515fa58488f4d299645ad9efa2fbce4bc909399e8b67f5e
6b526237449e514a692b8864e028e123dca456b6c60cb23a48edf1917b67c36a
```

## Evidence And Budgets

- Coder: one <=30-minute active window with existing deep profile/settings.
  V2_DEFAULT output guards; narrow individual reads before capture. No ACK turn.
- Static/source: one focused signature/call-chain consistency batch for this
  cause, including the required-property helper if its signature is coupled.
  Inspect all directly affected calls and preserve rejection semantics. Initial
  plus at most two justified corrected attempts; mechanical construction
  corrections retain their separate workflow budget. No blind replay.
- L0 / affected C# L1: existing `InstanceOrigin_*` methods, plus a directly
  needed type-boundary regression only within the allowed test file. Author or
  update only as necessary; C# execution remains DEFERRED / NOT RUN until the
  next separately activated human session. Do not invent an unrelated harness,
  install a compiler, or mislabel source assertions as compilation/testing.
- Non-Unity materializer/Supervisor L0/L1 evidence is unchanged and reused,
  not rerun. No additional backend, path-provenance, full-regression or Package
  closure invocation in this source-repair stage; no script changes allowed.
- At stable stop: one exact three-path `git diff --check`; write the changed
  subset/symbol mapping and final ordered path hashes. Identity algorithm:
  lowercase SHA-256 of each full file; identity text is UTF-8 without BOM with
  three `sha256  repository-relative-path` rows, in allowlist order, each ending
  LF. Canonical three-path identity is SHA-256 of those exact identity-text bytes.
  Record base HEAD, actual HEAD and identity; no mixed patch-id algorithms.
- Consolidate cause, fix, adjacent coverage, original error/corrections, exact
  evidence labels, unused budgets and stable snapshot once. A bounded static
  success is SOURCE_FIX_READY_FOR_REVIEW, never C#/EditMode/Ready/integration PASS.
- A second independent cause, required scope/authority expansion, unavailable
  entry/evidence or exhausted budget returns one same-S29 checkpoint; no hidden
  scope widening, replacement session or retries beyond the envelope.

## Review And Delivery Boundaries

- After the stopped Coder snapshot is admitted, Planner may route one
  <=15-minute independent read-only review to existing `v0.3.verifier.deep`.
  Verify only this CS1503 type boundary, the original origin-validation semantics
  and immediately affected JSON consumers. No general audit or test reruns.
  Verifier writes only `COMPILE-FIX-VERIFICATION.md` <=8 KiB and returns all
  findings once to Planner/User; no direct Coder messaging or new fix authority.
- The new Package delivery is authorized in principle but is downstream of a
  specifically authorized source commit and frozen delivery identity. Neither
  Coder nor Verifier commits or exports here. Planner must not infer Git commit
  permission from repair consent. Declare the exact source commit and unique
  `.artifacts` child before delivery; retain the old failure archive unchanged.
- The next human compile/focused-test/integration session is not activated by
  this grant. Preserve the same project; do not recreate it or automatically
  resume Install/Uninstall/reinstall while the current Package cannot compile.
- No Unity/MCP/CUA/BatchMode, real Install/Remove/reinstall, provider/process
  probe, external state change, commit/push/tag/publication, forced shutdown,
  cleanup or Windows/Codex restart is authorized in this source stage.

## Current Handoff

- Current status: COMPILE_FIX_AUTHORIZED / HUMAN_CLOSED_CONFIRMED /
  READY_FOR_SINGLE_DISPATCH.
- Next notification: Planner -> existing Coder once; then stable result to Planner.
- Next action: one conditional Coder dispatch; no independent review before its
  stopped snapshot, and no export before a human-authorized frozen source commit.
- Human decision or authorization required: none further inside this exact
  source-repair envelope; later findings disposition, exact source commit,
  human retry and S29/release ACCEPT remain gated.
