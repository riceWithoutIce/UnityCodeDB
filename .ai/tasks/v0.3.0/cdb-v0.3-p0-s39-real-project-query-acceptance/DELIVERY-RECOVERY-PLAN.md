# S39 delivery preparation and existing-project recovery

Date: 2026-10-20. Status: PREPARED_FOR_EXACT_DELIVERY_AUTHORIZATION.
Authority: user said to continue after source repair; this pass prepares and
validates the candidate and recovery plan. No commit, export, external reference
switch, recovery write, Install, Unity launch or real-client retry has occurred.

## Prepared candidate

Base: `ccf75ae` (full committed Package; immutable preview.5 / poc.43 payload).
Candidate: `.artifacts/tests/s39-delivery-prep-a/com.rice.ai-codedb/`.
This is an uncommitted review candidate, not the final export or release artifact.
The original worktree's dirty poc.42 payload and removed poc.43 files are untouched.

The six production-file repair baselines were independently checked against
HEAD Git blobs and match. Candidate content comes from `git archive HEAD`, then
overlays only those six production files and the two new focused harnesses.
The contract document receives only the stable-entry dependency amendment,
excluding unrelated worktree documentation changes.

Candidate delta from HEAD:

- Tools~/codedb-instance-engine.ps1
- Tools~/materialize-codedb-host-payload.ps1
- Tools~/codedb-project-supervisor.mjs
- Editor/AICodedbPackageRuntimeContract.cs
- Editor/AICodedbHostGenerationStore.cs
- Editor/AICodedbProjectIntegrationState.cs
- Tests~/test-codedb-stable-bootstrap.ps1 (new)
- Tests~/test-codedb-stable-bootstrap.mjs (new)
- Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md (amendment only)

Paths above are relative to `com.rice.ai-codedb/`. Also include this S39 task
packet in the exact commit; do not stage unrelated tasks or all dirty content.
Durable snapshot: `candidate-diff.json` and `candidate-files.sha256` in the
preparation root. If any named source changes before delivery, rebind the delta
before committing; never silently include a new file or unrelated hunk.

## Completed preparation checks

- Candidate release-closure validator: PASS, all 60 payload sources match,
  production materializer admission PASS, native binary/source binding PASS.
- Candidate Package path-provenance gate: PASS; three parser projections,
  PS decoding/admission and both Node caller bindings pass.
- Candidate's own focused stable-bootstrap entry: PASS (25 PS checks,
  3 Supervisor cases, 2 real stable-entry protocol fixtures, 1 production PS
  probe/native collector, 6 standalone C# cases).
- Canonical focused run: `.artifacts/tests/s39-stable-bootstrap/r-5110a391/`.
  The updated harness resolves extracted candidates to the enclosing Git
  repository's test root, bounding Windows paths and preserving test ownership.

Package/payload identity stays preview.5 / poc.43 because this delta changes
Package-owned publishing/readers and docs/tests; no immutable-generation bytes,
worker/parser shape, serialized schema, version, sequence or identity changed.
The commit and extracted file inventory distinguish the repaired artifact.
Full Unity compilation remains pending. Exact post-commit ZIP closure and
changed-consumer evidence are mandatory before consumer reference switching.

## Observed consumer baseline

Consumer: `<external-project>` = the existing `CodedbTest_0`.
Package reference: `file:../../Packages/d856a8f/com.rice.ai-codedb`.
The old delivery remains protected and must not be edited in place.

Latest read-only observation: no Unity.exe processes, no UnityLockfile and no
EditorInstance.json. Recheck immediately before any consumer write; this is a
point-in-time observation, not a permanent closure guarantee.

| Protected file / identity | Baseline |
| --- | --- |
| Packages/manifest.json SHA-256 | 6ff38dacfb02aaebc7122ac24e1ec0677b1e66f4f06fdaef923fc62a077a8f51 |
| Packages/packages-lock.json SHA-256 | e39be4e16dd7c41024445132a6b32725ed328c30e63503c94fb856ead82b7200 |
| .codex/config.toml SHA-256 | 770d2319ae6fbfa0eb01cec1faf4870e2a96033453dee44637aef4f88a943502 |
| selected pointer SHA-256 | b28c7e8c1268bd06b5c58b1f8a16c1470701b0d06602ed2685b1d5b74db8e00c |
| selected instance manifest SHA-256 | dd1244b1660a26b102867035cb85525d7e124b0c72ae0c55e18868eeab8b423e |
| instance_id | 2414c73c2fbb47f4b664c1bdbcad5969 |
| activation_epoch | 4ad2120d1559487f8e54c015685496f6 |
| generation_id | poc.43 |
| generation manifest SHA-256 | 55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5 |
| installed wrapper SHA-256 | 7f209316005ffd02bccd01c78ae1773d695694a77817d99f1753041b6aef4399 |

The stable decoder target is still absent. Its selected-generation source exists
and has SHA-256
`de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f`.

## Exact proposed sequence

1. Freeze and commit only the candidate delta plus the S39 task packet, leaving
   unrelated worktree and staged state intact. No push. The dirty contract
   document must use the candidate's narrow amendment as its commit content.
2. Run `Tests~/export-codedb-package.ps1` from that commit to a fresh repository
   artifact root. Require staged and exact-ZIP production admission, complete
   byte/hash closure, and the affected focused scenario on the extracted ZIP.
   Preserve d856a8f and its failed-attempt evidence.
3. With CodedbTest_0 still closed, back up its two Package-reference JSON files
   and snapshot the listed protected hashes into a task-owned repository backup.
   Copy the exact extracted new artifact to a fresh sibling
   `<external-packages>/<new-commit>/com.rice.ai-codedb/` directory. Replace only
   the CodeDB local reference in manifest and lock, preserving other bytes.
4. Apply one explicitly bounded bootstrap recovery, without running Install:
   source = `<external-project>/AIWork/.runtime/codedb/host/generations/poc.43/shared/codedb-instance-manifest-contract.mjs`;
   destination = `<external-project>/AIWork/codedb/shared/codedb-instance-manifest-contract.mjs`.
   Before writing, recheck the exact selected pointer/instance/generation hashes,
   its unique declared helper entry, the new Package's identical helper bytes,
   normal filesystem containment, and absence of the destination. Create only
   the missing `shared/` directory and one module using no-overwrite publication;
   verify the published hash. Any changed selection, unknown existing file,
   reparse point, open project or failed prerequisite stops this sequence.
5. Recheck Package references and all protected runtime/config identities. The
   selected instance, epoch, manifests, wrapper and MCP registration must remain
   byte-identical. Record this as explicit recovery of a historical install,
   never as proof that the repaired installer created that file originally.

Do not automatically fall back to Reinstall/Uninstall or stop any process.
Recovering this diagnosed missing module preserves the original sample and
avoids a newly selected instance hiding the regression. File recovery alone
does not pass the client gate or prove a real clean first Install.

## Human and client handoff after delivery

Then ask the human to open CodedbTest_0, wait for import/compile, and check
Manager status. Do not trigger Install/Reinstall as an implicit compile step.
Record Unity compilation/UI evidence separately from source/fixture results.
After that result, arrange one new attributable Codex-client attempt with this
project's exact MCP namespace. New target tools, usable status/query responses
and instance/epoch/generation correlation are required; disk Ready alone is not
query acceptance. No new Unity project is required for this regression.

Execution of steps 1–5 was explicitly authorized on 2026-10-20. The user also
confirmed CodedbTest_0 is closed. Recheck closure and protected hashes before
external writes. This grant covers the exact commit (no push), export and
verification, reference switch and one-file historical bootstrap recovery;
Unity execution, Install/Reinstall and a real-client retry remain separate.
