# S40 authorized delivery result

Status: DELIVERY PASS / HUMAN UNITY AND REAL LIFECYCLE ACCEPTANCE PENDING.

The user explicitly approved DELIVERY-PLAN.md with `批准`. Its source commit,
exact artifact checks and closed-Unity consumer reference switch are complete.

## Source and artifact

- Branch: `codex/retained-mcp-install-admission`, repository-local task checkout.
- Commit: `186aacf0371ba64e47114306170b449dbca261c9`.
- Parent: `c848049d90fbdf618905be25225580642d98d987`.
- Complete tree: `02abee80e348c3ea21b2f542432679b4fc447586`, exactly the
  previously prepared tree. Commit scope is exactly the four frozen Package
  paths in SOURCE-SHA256.json; raw indexed bytes matched each SHA-256.
- The isolated checkout is clean. Primary checkout changes were preserved;
  its index SHA-256 before/after commit matched. No merge or push occurred.
- Artifact root: `<repository-root>/.artifacts/exports/s40-retained-mcp-186aacf/`.
- ZIP SHA-256: `b129339ede1a09075fcc49cb19abc131f23bd40e17fa6f81ce0a70972ae4db65`.
- Exact commit-stage and exact-ZIP byte closure and production admission PASS;
  62 declared payload files, zero byte mismatches; native build binding PASS.
- Stage and extracted ZIP contain identical inventories of 666 Package files.
  All four exported candidate hashes match the frozen source snapshot.
- One focused Windows PowerShell 5.1 run from the exact ZIP extraction: 46
  checks PASS, including the retained oldest reader across two reinstall
  cycles and adjacent ownership rejection controls. Provider execution and
  external client calls were zero. This remains isolated HARNESS evidence.
- Package version/generation remain `0.3.0-preview.5` / `poc.44`; the source
  commit, artifact and engine hashes distinguish this repair.

## Consumer delivery

Consumer: `<test-projects>/CodedbTest_2`, deliberately retaining the original
logical-uninstalled topology rather than creating/resetting a project.

Readable Unity process inventories before copying, immediately before reference
switching and after switching found no Unity editor processes. UnityLockfile
was absent. All seven baseline input hashes and selected-pointer absence
matched before writes, and again before replacing references.

Exact manifest/lock pre-images are retained. The ZIP-extracted Package was
copied to a fresh destination:
`<external-packages>/186aacf-s40-codedbtest2/com.rice.ai-codedb/`.
Its complete 666-file inventory matched the exact ZIP extraction. The older
Package was not modified.

Only the CodeDB local reference bytes in manifest and lock changed:

`file:../../Packages/c848049-codedbtest2/com.rice.ai-codedb`

to:

`file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb`.

Writes were sequential, with each exact postimage checked. All other bytes,
including BOM/EOL, were preserved. The five remaining protected files (Unity
version declaration, project MCP config, stable wrapper, desired state and
activation contract) retained their baseline hashes. No selected pointer was
created. No lease, old-client connection or global configuration was changed.

| Reference file | New SHA-256 |
| --- | --- |
| `Packages/manifest.json` | `ea79c33e16767692fc3cb14cc92145e97705c42353e84e7955da539164da4485` |
| `Packages/packages-lock.json` | `183766b27213ff3a0bc1b604785661d5e39372c4918ef7c5b9bc9e947da2298d` |

## Evidence and next gate

Canonical delivery receipts:
`<repository-root>/.artifacts/tests/s40-retained-mcp-install/delivery-execution-a/`.

- `commit.json`, `commit.log`, `approval.json`: source identity and scope.
- `export.log`: exact commit/ZIP closure, admission and artifact hash.
- `exact-harness.log`: extracted Package harness output; detailed manifest,
  transcript and result in sibling `delivery-exact-ps51-186aacf/`.
- `source-inventory.json`, `copied-inventory.json`: complete file/hash closure.
- `consumer-preimages/`: exact original manifest/lock bytes.
- `before-copy-unity.json`, `before-reference-switch-unity.json`,
  `after-reference-switch-unity.json`: occupancy observations.
- `switch-journal.json`, `delivery.json`: sequential effects, baseline hashes
  and terminal delivery result.

These directories and the exact export are retained delivery/evidence artifacts;
no cleanup or relocation is authorized. Earlier failed/preparatory receipts
remain historical evidence and are not substituted for this exact delivery.

Next human action: open CodedbTest_2, wait for compilation/import to settle and
report Console errors plus Manager state. Do not click Install/Uninstall yet.
The separately aligned one-attempt Install gate follows that report. A retained
client condition must be observed, not fabricated; if absent, record the limit
before attributing real-world coverage to this repair.

No Unity launch, real Install/Uninstall, Provider/MCP call, reconnect, process
control or physical cleanup occurred. Real target-client attribution, possible
second lifecycle cycle, PS7 compatibility, Unconfirmed UX, performance, upgrade
and public release acceptance remain outside this completed delivery.
