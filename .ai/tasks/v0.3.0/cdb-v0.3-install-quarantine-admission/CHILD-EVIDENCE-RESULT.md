# Install missing-child diagnostic repair - 2026-10-26

Outcome: `SOURCE_IMPLEMENTED / FOCUSED_HARNESS_PASS`.
Real Fresh Install: `BLOCKED`, not rerun or accepted.

Authorization: user "ok 那我们继续" following alignment on a narrow
missing-child diagnostic guard and adjacent regression. This continuation
does not authorize history recovery, consumer changes, commit, export or delivery.

Source checkout: `<repository-root>/.worktrees/cdb-v03-install-quarantine-admission`.
Branch: `codex/install-quarantine-admission`.
Source base: `09d345d96ec782be2ac101016d8b75b14bce6000`.
The two-file delta is uncommitted; the primary checkout and delivered Package
remain unchanged.

## Scope and behavior

For `CHILD_ADMITTED` with a null child, Install admission now reports:

`Install Supervisor execution disposition is incomplete: child evidence is missing.`

The explicit guard runs before binding the null child to the mandatory `Object`
parameter. The same unknown execution remains blocked. It is not inferred to be
`NO_CHILD`, admitted, cleaned, rewritten or granted activation authority.
The guard fixes diagnostic behavior only, not the missing execution identity.

L0: production Windows PowerShell 5.1 parse and focused admission harness.
Affected L1: retained-MCP Install harness with `-L0Only`.
Rationale: the changed function is called by Install's execution admission;
retained-MCP uses that admission directly. No serialized record shape changes.
Explicitly not run: real Unity, Provider or MCP, consumer read/replay,
Install/Repair/Restart, history migration/deletion and full regression.

## Evidence

| Check | Result |
| --- | --- |
| Windows PowerShell parser / harness loading of production sources | PASS |
| Focused production admission harness | PASS, 30 checks |
| Retained-MCP adjacent `-L0Only` harness | PASS, 17 checks |
| Scoped diff and whitespace | PASS |
| External Fresh Install / release acceptance | NOT_RUN |

Canonical artifacts:

- `.artifacts/tests/cdb-v0.3-install-quarantine-admission/05-child-evidence/`
- `.artifacts/tests/s40-retained-mcp-install/child-evidence-l0/`

Added coverage reaches the actual admission guard with failed terminal history,
`CHILD_ADMITTED`, null child and a byte-identical canonical anchor. It checks
the explicit missing-child message and that both history and canonical bytes
remain unchanged. Original quarantine, writer, unknown execution and competing
process refusal coverage remains in the passing batch. All OS observations are
synthetic; this is HARNESS evidence only.

| Changed source | SHA-256 |
| --- | --- |
| `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1` | `1743693944f954df2c406e1132e4cf3684b5bb7027bd4c330d88c48875b97287` |
| `com.rice.ai-codedb/Tests~/test-codedb-install-quarantine-admission.ps1` | `8ee45bdf52d9f2216327f9b1ed3f10b7fe5fe5de0bfd16d034c641272c275a98` |

## Retained failures and corrections

A nested-shell parser command initially failed during quoting before parsing
the product source or starting the harness. Corrected shell quoting passed.

Focused attempt `04-child-evidence` failed because the added fixture updated
history without refreshing the canonical anchor. The production hash gate
correctly refused it before the intended assertion. The fixture now refreshes
the anchor; attempt `05-child-evidence` passes. The failed run was preserved,
not relabeled or overwritten. No product gate was weakened.

## Handoff boundary

No consumer files, runtime history, quarantine, processes or Package references
were changed. No new Unity project, delegation, commit, export, delivery or
Install retry was performed. Do not deliver solely to retry the same historical
blocker: this change intentionally preserves that refusal. Historical-state
disposition and a clean-project lifecycle acceptance remain separate decisions.
