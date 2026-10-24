# S40 prepared delivery candidate

Status: DELIVERY_COMPLETE. User replied `批准` to this exact delivery sequence.
Commit, exact export and bounded consumer reference switch passed; see
DELIVERY-RESULT.md. Human lifecycle actions remain a separate gate.

## Exact source candidate

- Branch: `codex/retained-mcp-install-admission`.
- Base/HEAD: `c848049d90fbdf618905be25225580642d98d987`.
- Checkout: `<repository-root>/.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission`.
- Commit scope: exactly the four Package paths/hashes in SOURCE-SHA256.json:
  engine, reinstall contract clarification, focused PowerShell and Node tests.
- Projected complete Git tree: `02abee80e348c3ea21b2f542432679b4fc447586`.
- Package identity stays `0.3.0-preview.5` / `poc.44`. No immutable generation,
  wrapper, payload manifest, serialized schema or package identity changed.
  Delivered source commit, artifact hash and engine hash distinguish the fix.
- Preserve primary dirty state, other worktrees, prior Packages and all raw
  failure/acceptance evidence. No merge, push or cleanup is proposed.

## Completed preparation and correction disclosure

F1 is closed by independent targeted review in VERIFICATION-F1.md. Its reviewed
production engine hash still exactly matches this delivery candidate. After
that review, mandatory path provenance exposed an overlooked fixed-drive
synthetic Node pathname in the focused PowerShell test. Only that pathname was
changed to a RunRoot-derived value; assertions and production behavior did not
change. SOURCE-SHA256-03-F1-REVIEWED.json preserves the reviewed identity.

The parent verified that reversing only the fixture-path substitutions in
memory reproduces the exact previously reviewed test hash. This mechanical
correction has parent verification, not a new independent-review claim for the
new test bytes. Production code, contract and Node test hashes are unchanged.

Evidence root: `<repository-root>/.artifacts/tests/s40-retained-mcp-install/`.

- `delivery-preflight-a/path-provenance-before.log`: failed required path gate.
- `delivery-preflight-a/path-provenance-after.log`: corrected provenance PASS,
  canonical helper projections and actual PS/Node decoder bindings PASS.
- `delivery-preflight-a/mechanical-correction.json`: exact test-only substitution
  proof and independently reviewed engine hash unchanged.
- `path-derived-fixture-a/result.json`, `run.log`: corrected fixture PASS,
  46 checks, including original F1 and its nearest regressions.
- `delivery-projection-b/projection.json`, `closure.log`: an isolated Git index
  and object directory project only the four source paths onto the base. The
  extracted tree has 666 Package files; four candidate file hashes match.
  Byte closure PASS (62 declared files, zero mismatches), production materializer
  read-only admission PASS, native source/build/binary binding PASS.
  Real index bytes are unchanged. This tree/archive is preparation, not a commit
  or formal release artifact. `delivery-projection-a` retains the initial
  archive-option command-construction failure; it was corrected without source
  or external effects. No other retries were needed for this preparation.

## Proposed delivery grant

1. Recheck base, branch, four source hashes and empty real index. Stage exactly
   these four paths as raw blobs, verify indexed SHA-256 values and exact scope,
   and require the resulting tree to equal the prepared tree above. Create one
   source commit on the isolated branch. Do not touch the dirty primary index.
2. Use the existing `Tests~/export-codedb-package.ps1` for that exact commit,
   writing a fresh `<repository-root>/.artifacts/exports/s40-retained-mcp-<sha7>/`.
   Require commit-staged and exact-ZIP byte closure and production admission.
   Run the existing 46-check focused PowerShell 5.1 harness once from that exact
   extracted Package, with a fresh task-owned RunRoot, and compare exported
   candidate file hashes to the frozen source. No PS7 rerun, full regression,
   Unity, real Provider or MCP is included.
3. Recheck `<test-projects>/CodedbTest_2` is closed: readable Unity process
   inventory with no target editor and no Temp/UnityLockfile. Recheck the seven
   baseline file hashes and selected-pointer absence from
   `delivery-preflight-a/consumer-baseline.json`. Preserve manifest/lock exact
   pre-images in a fresh delivery-execution evidence directory before writing.
4. Copy the exact extracted Package into a new sibling
   `<external-packages>/<sha7>-s40-codedbtest2/com.rice.ai-codedb/`; refuse any
   existing destination. Verify the full copied-file inventory. Preserve the
   old delivered Package untouched.
5. Replace only the CodeDB local-file reference in target manifest and lock:
   from `file:../../Packages/c848049-codedbtest2/com.rice.ai-codedb` to
   `file:../../Packages/<sha7>-s40-codedbtest2/com.rice.ai-codedb`.
   Preserve unrelated bytes. Validate both new references and original byte
   preservation elsewhere. Writes are sequential, not cross-file atomic.
6. Recheck protected runtime/configuration hashes and selected-pointer absence.
   Record commit/tree, ZIP hash, extracted consumer-test result, copied file
   hashes, new relative reference and backup receipts. Stop before Unity or a
   real Install, Uninstall, MCP call, reconnect or process-control operation.

Stop on identity/index/source drift, closure/test failure, target occupancy,
baseline conflict or partial switch. Retain exact effects/evidence; do not
retry or reset the project automatically. Source commit/export does not imply
that the following reference-switch gate passed.

## Consumer starting state and next human gate

Read-only preparation observed manifest/lock on the old reference above,
desired UNINSTALLED/PENDING, no selected pointer, no Unity processes and no
UnityLockfile. These are point-in-time facts and must be rechecked before writes.
The seven hashed inputs include manifest, lock, Unity version declaration,
project MCP config, stable wrapper, desired state and activation contract.
Live MCP lease heartbeats are not frozen file baselines or deletion authority.

Reuse CodedbTest_2 because its logical-uninstalled retained state is the original
failure topology. No new Unity project, state reset, manual pointer/config patch,
lease fabrication or old-client stop is part of delivery. Preserve the old
client connection if present; do not assume the historical PID is still current.

After delivery, the human opens the project and reports compilation/Manager
state first. A separately agreed bounded Install attempt follows, with one
attempt and stop on failure. Real target-chat namespace/status/query attribution
and a possible second lifecycle cycle remain separate acceptance steps. If the
required retained-client condition is absent, record that limitation and align
the acceptance starting state rather than manufacturing a lease.

PowerShell 7 compatibility, eventual physical cleanup after lease drain,
Unconfirmed UX, performance, upgrade and public release acceptance stay outside
this delivery proposal.
