# S29 preflight to durable removal handoff — FIX2 result

Date: 2026-10-12. Status: `CODER_STABLE_FOCUSED_PASS / VERIFIER_PENDING`.
FIX2 addresses the Verifier's F1 durable `UNINSTALLED` bypass and adds the
requested direct-entry evidence. The source snapshot is ready for a new
read-only Verifier; no Unity or real project operation was performed.

## Bounded repair

`Invoke-RemoveIntegration` now consumes the existing `PreflightHandoff`
parameter at its own durable function boundary. Before failed-candidate
recovery, lock recovery, or empty-directory cleanup it:

1. resolves the current historical removal authority with `-AllowMissing`;
2. refuses an absent authority with an explicit no-cleanup/no-recovery conflict;
3. requires the handoff and validates it against the current authority and
   managed configuration plan.

After acquiring the materializer lock, it repeats the authority/configuration
resolution and handoff validation immediately before the existing historical
next-change admission and recovery/cleanup gates. The top-level
`UNINSTALLED` dispatch passes the handoff into this function, closing the
previous direct call that dropped it. Ordinary current-strict routes remain
unchanged.

The no-authority `UNINSTALLED` case is intentionally fail-closed: it is a
terminal conflict because the approved same-token contract cannot authenticate
an absent authority. The function returns before cleanup or recovery, and the
focused test proves the project digest remains unchanged. No new schema,
transport, recovery route, or architecture was introduced.

## Focused evidence

- Candidate: `.artifacts/tests/s29-generation-alignment/fix2-a4/com.rice.ai-codedb`.
- `focused-a4.log`: `GENERATION_ALIGNMENT PASS cases=35`,
  `native_children=0`, `PocFixture=true`,
  `external_process_observation=synthetic`.
- Cases include the prior 29 alignment cases plus actual durable direct-entry
  valid removal, missing handoff, expired handoff, authority drift,
  configuration drift, and `UNINSTALLED` no-authority read-only refusal.
- PowerShell AST parse: `PASS`.
- `git diff --check` over the changed source/test files: `PASS`.
- Exact source hashes and candidate evidence are recorded in the paired
  `FIX2-SOURCE-SHA256.txt` and `FIX2-PROJECTION-MANIFEST.md` files.

## Limits and handoff

This is focused synthetic Coder evidence, not C# compilation, Unity EditMode,
live readiness, real removal, fresh installation, release or human acceptance.
The prior path-provenance limitation and protected `OwnerIdentityV2Status.json`
drift remain outside scope. The parent task may admit this stable snapshot and
dispatch the authorized read-only Verifier for F1 and its adjacent direct-entry
coverage only.
