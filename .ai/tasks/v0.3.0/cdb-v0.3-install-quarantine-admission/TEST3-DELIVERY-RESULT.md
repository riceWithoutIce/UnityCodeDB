# Test3 candidate delivery result

Date: 2026-10-26. Outcome: `DELIVERY_PASS / HUMAN_UNITY_PENDING`.
Grant: user explicitly approved scoped commit, export/validation, Package copy
and both Test3 dependency edits. No Unity launch or product Install executed.

## Frozen source and artifact

Branch: `codex/install-quarantine-admission`.
Commit: `d84b5ca88b1adb57748b2988aa79cc9c7e6e8be9`.
Message: `fix(codedb): persist owned child close evidence`.
Exactly the ten approved snapshot files were committed. Isolated source tree
is clean. No merge, push, tag, board sync or unrelated primary-tree staging.

Canonical artifact family:
`.artifacts/tests/cdb-v0.3-install-quarantine-admission/`.
Export: `export-d84b5ca/com.rice.ai-codedb.zip`.
SHA-256: `e096468b884c4fa8809377a9d6f14bb13da2ddf99b643ba99f327de24d2caa05`.
Single Package root, 673 files, 14,311,406 bytes.
Package `0.3.0-preview.5`, generation `poc.44`.

Both commit-stage and exact ZIP extraction passed the existing byte-closure
and production materializer read-only payload admission gates (62 entries,
zero mismatches), including existing native build/binary binding checks.
Generation manifest remains
`f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.
Runtime contract remains
`ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5`.

Exact extracted Package contract evidence is in
`09-exact-zip-child-closure/`: original producer 11 checks PASS, PowerShell
readers/retention 54 checks PASS, offline C# exact reader 27 checks PASS.
Producer cases include two finite owned Node child exits. No real
Supervisor/Provider/Unity/MCP process was started. This is exact-artifact
record closure, not real lifecycle acceptance.

## Delivered binding

Project: `<external-test-root>/CodedbTest_3`, Unity 2022.3.62f3.
Destination:
`<external-test-root>/Packages/d84b5ca-v03-child-close/com.rice.ai-codedb`.
Reference in both manifest and lock:
`file:../../Packages/d84b5ca-v03-child-close/com.rice.ai-codedb`.

All 673 delivered files match the ZIP extraction inventory and SHA-256.
`delivery-d84b5ca-test3/file-manifest.json` records the full inventory;
`result.json` records the per-step journal. The same directory retains exact
preimages of both changed JSON files. No old candidate was overwritten.

| Project-relative file | SHA-256 after delivery |
| --- | --- |
| `Packages/manifest.json` | `f76fbe737a44a72097b0b0552e1b7749fc8d8509c2b8242a49751bebc95344ee` |
| `Packages/packages-lock.json` | `1537b9dbe9528d6bb874f2e246f287f68a5f315e5c299a4ffa34607f288429a8` |

Only the direct local CodeDB dependency was added; all unrelated dependency
values were preserved. ProjectVersion bytes are unchanged. AIWork and .codex
remain absent at handoff. No probe, runtime, registration or history was copied
from Test2. No target Unity process or lock was present before delivery.

## Human next step

Open Test3 in the human-selected 2022.3.62f3 Editor. Allow normal package
import/compilation and open the CodeDB Manager. Report compilation errors or
the displayed state. Do not click Install, Repair, Restart or Uninstall yet.
A fresh uninstalled project need not display Ready before Install. If any
error appears, retain it and stop; no automatic retry or environment reset.

Real Install and subsequent lifecycle/client checks remain separate pending
gates. Test2 historical blockers are unchanged. Delivery PASS does not close
historical recovery, full response identity, long-term stability or release.
