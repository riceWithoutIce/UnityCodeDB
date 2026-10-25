# Proposed CodedbTest_2 candidate delivery

Status: PREPARED_ONLY; no export or consumer switch executed.
All repository paths are relative to `<repository-root>`; external paths below
are relative to the already user-designated sibling test root, not new locations.

## Source and outputs

- Source: the final candidate commit recorded in this task's RESULT.md. It adds
  four exact Git-filter exceptions to the implementation snapshot cd7dd01,
  preserving historical payload byte hashes in ordinary checkouts/commits.
  Package 0.3.0-preview.5; poc.44; F01 off by default; F02 excluded.
- Local export: `.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/`
  `export-<candidate-short-hash>/`, through
  `com.rice.ai-codedb/Tests~/export-codedb-package.ps1 -Commit <candidate-commit>`.
  Use new output only; retain failures and stop rather than automatic re-export.
- Existing exporter must pass production payload admission and Package byte
  closure on both commit-staged Package and exact ZIP. Preserve ZIP SHA-256,
  complete file manifest, Package tree, generation manifest and wrapper hashes.
- Proposed destination under the existing external test root:
  `Packages/<candidate-short-hash>-v03-reviewed-candidate/com.rice.ai-codedb`.
  Copy only the successfully validated artifact, verify every file hash, and
  preserve the previous package directory.

## Consumer switch prerequisites and scope

Consumer: `CodedbTest_2` under the user-designated test root. User must confirm
Unity is closed immediately before any copy/reference change. The old report
does not establish its current state. No automated Editor launch/stop.

Read-only preparation found both manifest/lock still referencing:
`file:../../Packages/fe08d6e-c-scheme-observation/com.rice.ai-codedb`.

An authorized switch changes only CodeDB's reference in `Packages/manifest.json`
and `Packages/packages-lock.json` to the proposed candidate directory. Preserve
unrelated JSON data/formatting and compare both references before and after.
Task-owned backups of these two files go under the export/delivery evidence run.
Do not rewrite MCP registration, pointer, instance, probes or runtime state;
do not invoke Install, Repair, Restart or Uninstall during this source delivery.
Any differing preimage or failed gate stops the switch for analysis.

Rollback is a separately confirmed two-reference restoration from saved
preimages with Unity closed; no automatic replay or package deletion.

## Acceptance after a successful switch

1. Human opens the same CodedbTest_2 Editor: compile result, Manager transition
   and eventual stable Ready are recorded separately from offline evidence.
2. Verify a short bounded ordinary-use interval creates no new diagnostic
   sidecar or CODEDB_S12_EVIDENCE document output with diagnostics unset. Compare
   a pre-open baseline; do not delete old logs or infer absence from old files.
3. A separately authorized target-project chat performs bounded real MCP:
   precise namespace visible, one status, one fixed existing marker query;
   first error stops, no retry/substitute. Record raw response identity fields
   as supplied; disk evidence does not substitute missing response fields.
4. Continue the candidate's lifecycle golden-path acceptance only after these
   candidate checks. Existing historical PASS is not a new-candidate runtime PASS.

Unity EditMode/focused tests, real MCP and lifecycle steps require their named
execution grant/task; this preparation does not initiate them or claim release.
