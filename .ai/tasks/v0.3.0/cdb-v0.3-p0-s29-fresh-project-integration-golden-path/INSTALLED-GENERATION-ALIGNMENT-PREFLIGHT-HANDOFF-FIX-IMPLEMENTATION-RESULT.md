# S29 preflight to durable removal handoff — fix result

Date: 2026-10-12. Status: `CODER_STABLE_FOCUSED_PASS / VERIFIER_PENDING`.
The user approved the minimum scope extension for the single authority/token
continuity finding. The repaired snapshot is ready for independent read-only
review; no Unity or real project operation was performed.

## Repair

`RemoveIntegrationPreflight` now emits one short-lived, integrity-bound handoff
token. The token binds project identity, selected instance/generation and
activation epoch, Package runtime contract and owner fingerprint, managed
configuration bytes, expiry and nonce. Durable `RemoveIntegration` requires the
handoff and validates it against freshly recomputed historical authority and
configuration before mutation.

The C# materializer parses exactly one AVAILABLE line and exactly one non-empty
handoff line, forwards the handoff argument, and rejects missing or duplicate
handoffs. Manager action code performs its existing cached/current admission
checks, runs a fresh preflight, requires the parsed handoff, and only then
starts durable removal. The handoff parser uses the Package strict JSON parser;
this preserves the signed 64-bit JSON integer contract under Windows
PowerShell, where the generic `ConvertFrom-Json` path produced `Int32`.

## Evidence

- Candidate: `.artifacts/tests/s29-generation-alignment/fix-a1/com.rice.ai-codedb`.
- Focused run: `.artifacts/tests/s29-generation-alignment/fix-a1/focused-a3.log`.
- Result: `GENERATION_ALIGNMENT PASS cases=29`, `native_children=0`,
  `PocFixture=true`, `external_process_observation=synthetic`.
- Earlier `focused-a2.log` failure is retained and was caused by the numeric
  parser mismatch above; `focused-a3` passes after the narrow parser correction.
- PowerShell AST parse: `PASS`.
- `git diff --check` over the five changed source/test files: `PASS`.
- Source hashes and candidate inventory are recorded in the paired
  `...FIX-SOURCE-SHA256.txt` and `...FIX-PROJECTION-MANIFEST.md` files.

## Limits and handoff

This is a focused Coder result, not Unity, runtime, release or human
acceptance. Existing path-provenance and protected-status limitations remain
unchanged. No package export, commit, push, reference switch, real removal or
cleanup was run. The parent task may now admit this stable snapshot and start a
read-only Verifier for the original finding and adjacent regression only.
