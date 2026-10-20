# S37 terminal-result repair delivery — 2026-10-19

## Scope

The user accepted the narrow terminal-result repair and authorized the exact
`commit -> package closure -> closed-S35 reference switch` sequence. This
record covers that delivery only. It does not authorize or perform another
Install, Uninstall, Unity launch, process termination, or push.

## Source and package

- Commit: `d856a8f0916253f45369ae3fde7f4a2a6b26b9cb`
- Message: `fix: preserve supervisor terminal result completeness`
- Package root: `<repository-root>/.artifacts/s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`
- ZIP: `<repository-root>/.artifacts/s37-supervisor-terminal-result-d856a8f/com.rice.ai-codedb.zip`
- ZIP SHA-256: `97aecd28ff47656a9b6cd66666f6c9030b95a8f4b5a98cf8cf68f588058031a9`
- Extracted package files / ZIP entries: `623 / 623`

Commit-stage and exact-ZIP release-closure validation both passed production
payload admission, native binding, and 60-source byte closure with zero
mismatches. The package was exported once from the named commit.

## S35 reference switch

S35 was confirmed closed immediately before mutation: no process command line
matched the S35 project root, and `Temp/UnityLockfile` and
`Library/EditorInstance.json` were absent. The unrelated Unity processes
observed at that time belonged to another project.

Backups were written under
`<repository-root>/.backups/s37-supervisor-terminal-result-d856a8f-s35-reference/`:

- `manifest.json` before SHA-256:
  `201B9FDD4B423A223BD86FDD7CE1508FDF72626F53179CF278A62E207EE0E4CB`
- `packages-lock.json` before SHA-256:
  `4108CC8D3028CF3D194973D36C9262847317F7BFABFF0D9BF22FB803F53C343A`

Only the CodeDB local reference changed in each consumer. Both now resolve to
`<repository-root>/.artifacts/s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`;
the `com.rice.ai-codedb` testable and all other dependency bytes remain
unchanged. The replacement was checked as an exact single-string substitution.

## Gate

Delivery is complete. Human Unity acceptance remains pending for this exact
package: open S35, allow import/compile, run the agreed focused Test Runner
checks, then verify Manager close/reopen and tab switching. Do not replay the
blocked same-version Install automatically; the retained malformed historical
record remains fail-closed evidence and is outside this delivery.

## Human acceptance update — 2026-10-20

The user reports focused Test Runner PASS, normal Manager and Unity open/close
behavior, and no compile error. The Manager was in `Uninstalled` state with
`Install CodeDB` visible. Only the Overview content was present, so there were
no additional tabs available; tab switching is N/A for this sample.

This closes the delivered package's compile, focused-test and UI-smoke gate as
`HUMAN_ACCEPTANCE_PASS_WITH_LIMITS`. Install was not retried; the retained
same-version Install blocker remains fail-closed evidence.

## Authorized Install attempt — 2026-10-20

The user authorized one Install attempt. It stopped before candidate selection:

- Action: `dcf80a320cc2477aa5a63f990dd376c6`
- Result: `BLOCKED / PREFLIGHT / INSTANCE_CONVERGENCE_FAILED`
- Exit code: `6`
- `mutated_scopes=[]`
- Project remained `UNINSTALLED`

The new terminal receipt is structurally complete, including
`output_overflow=false` and `output_drain_incomplete=false`. Preflight instead
rejected the retained historical Supervisor operation
`ce169d22b8544299b01407cef5d9b70b.json`, whose failed `result` predates those
required fields and has `execution_disposition=CHILD_ADMITTED` with
`child=null`. The source repair therefore works for newly written terminal
records but does not rewrite or infer identity for this old record. No history
file was edited or deleted.

Disposition: S35 lifecycle remains blocked at the historical-record boundary;
any migration, explicit archival, or bounded compatibility policy requires a
separate alignment and authorization.
