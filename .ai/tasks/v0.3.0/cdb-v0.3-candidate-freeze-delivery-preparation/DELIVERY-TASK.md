# CodedbTest_2 candidate delivery — 2026-10-26

Status: COMPLETE / DELIVERY_PASS. User grant: "批准" for the concrete DELIVERY-PLAN.md;
current prerequisite confirmed: "已关闭，可以交付". Current session executes;
no subagent, new checkout or automated Unity/process operations.

Copy only the validated candidate `11056964da1143955ed69a067361622799e3d6f2`
from repository-local export `export-1105696/review/com.rice.ai-codedb` into
the designated external test root's
`Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
Require the destination not to exist; preserve the previous package.

Consumer write allowlist, relative to that external test root:

- New candidate directory above, containing exactly the exported 669 files.
- `CodedbTest_2/Packages/manifest.json`: CodeDB dependency string only.
- `CodedbTest_2/Packages/packages-lock.json`: CodeDB version string only.

Expected old reference:
`file:../../Packages/fe08d6e-c-scheme-observation/com.rice.ai-codedb`.
New reference:
`file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
Reject preimage drift; preserve all other JSON bytes and properties. Retain both
original files before writing. No automatic rollback, overwrite or replay after
an actual failure. Record partial effects and stop for analysis.

Local scripts/records: this task directory only. Backups, journal and receipt:
`.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/delivery-1105696/`.
All persistent records use repository-relative paths or symbolic external-root
paths. The execution command supplies the user-designated external test root;
no machine path is embedded in the script or Package.

Checks: export ZIP and every source/destination file SHA-256; exact inventory;
two reference resolutions to the delivered Package; unchanged unrelated JSON
bytes; protected registration/pointer/probe hashes; source HEAD/index unchanged.
No need to repeat the unchanged export closure gates or start components.

No registration/runtime/instance/probe changes, installation, repair/restart,
Unity/MCP, real query, cleanup/deletion, commit/push, board change or release.
STANDARD_30M, one delivery attempt, two mechanical corrections per scenario.
Delivery PASS does not establish Unity compilation, Ready or real MCP acceptance.
