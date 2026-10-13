# S29 preflight-to-durable-removal handoff fix — implementation verification

Date: 2026-10-12. Review mode: guarded, read-only. Verifier verdict:
**BLOCKED**.

This review covers the original preflight authority/token continuity finding
and the immediately adjacent `UNINSTALLED` routing regression only. No source,
project, payload, receipt, Unity state, or protected baseline was modified.
No Unity, live CLI, process control, real Remove/Install/Uninstall, export,
reference switch, commit, push, publication, or cleanup was run.

## Snapshot admission

- Candidate: `.artifacts/tests/s29-generation-alignment/fix-a1/com.rice.ai-codedb`.
- All five declared FIX source/test SHA256 values match
  `INSTALLED-GENERATION-ALIGNMENT-PREFLIGHT-HANDOFF-FIX-SOURCE-SHA256.txt`.
- `focused-a3.log` matches the declared SHA256 and length (5463 bytes), with
  retained result `GENERATION_ALIGNMENT PASS cases=29 native_children=0
  PocFixture=true external_process_observation=synthetic`.
- PowerShell AST parsing passes. These checks admit the supplied snapshot; they
  do not establish Unity, runtime, live consumer, or release acceptance.

## Passing portions

The snapshot implements the intended main-path handoff chain. The preflight
producer emits an integrity-bound token containing project, selected
instance/generation, generation manifest hash, activation epoch, runtime
contract, owner fingerprint, managed-configuration hash, expiry, and nonce.
The C# parser requires exactly one `AVAILABLE` line and exactly one non-empty
handoff line; Manager action code obtains a fresh preflight, rejects a missing
handoff, and appends the handoff to the `RemoveIntegration` arguments. The
normal dispatch at `materialize-codedb-host-payload.ps1:12253-12258` validates
the token against freshly recomputed authority/configuration before calling
the durable function. Historical Package identity, the three historical
removal-only admission gates, ordinary CURRENT/Uninstall/Install strictness,
and retained-successor evidence remain present in the admitted snapshot.

## Findings

### F1 — BLOCKER: `UNINSTALLED` early branch bypasses required handoff

At candidate `Tools~/materialize-codedb-host-payload.ps1:12074-12099`, the
`DesiredState == "UNINSTALLED"` branch handles `RemoveIntegration` by directly
calling:

```powershell
Invoke-RemoveIntegration -Manifest $payload -ProjectRoot $projectRootPath
```

It neither requires nor validates `RemovalPreflightHandoff`. The durable
function declares a `PreflightHandoff` parameter at `:11521-11526`, but a
read-only scan of its body through `:11605` finds no use of that parameter or
call to `Assert-RemoveIntegrationPreflightHandoff`; the handoff is therefore
enforced only by the later main dispatch. This is an alternate durable removal
entry that violates the frozen contract that durable `RemoveIntegration`
requires the authenticated preflight handoff. The main-path checks cannot close
this bypass.

This remains a normal-path safety and authority-continuity blocker. It requires
a new bounded fix disposition; this Verifier does not direct a repair.

### F2 — FOLLOW-UP: focused evidence does not exercise the bypass entry

The dedicated C# tests cover valid output, missing/duplicate output, and
argument construction requiring a handoff. The retained 29-case synthetic log
proves the producer/consumer roundtrip and token-integrity refusal, but it does
not invoke the `DesiredState == UNINSTALLED` early branch or prove that a
missing/expired/foreign handoff is rejected by every direct durable entry. This
is an adjacent evidence gap and should be added with the next narrowly scoped
repair/review; it is reported separately because F1 already establishes the
blocker from source inspection.

## Protected state and limits

The protected `OwnerIdentityV2Status.json` working-tree drift remains outside
this fix and is neither attributed nor changed. The original protected
baseline, source/candidate manifests, and earlier failed evidence remain
separate. The Coder's synthetic PASS is retained as evidence only; it does not
prove C# compilation, Unity EditMode execution, live readiness, real removal,
fresh installation, or release acceptance. S29/release therefore remain
PARTIAL pending a new user-approved disposition for F1 and its focused
regression coverage.
