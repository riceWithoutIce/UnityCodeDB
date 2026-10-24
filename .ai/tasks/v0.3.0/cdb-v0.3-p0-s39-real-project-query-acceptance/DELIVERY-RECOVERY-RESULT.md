# S39 exact delivery and historical bootstrap recovery

Date: 2026-10-20.
Status: DELIVERY_AND_HISTORICAL_RECOVERY_PASS / HUMAN_UNITY_CHECK_PENDING /
REAL_CLIENT_QUERY_PENDING.

The user explicitly authorized the exact commit, export/verification, closed-
project reference switch and one-file recovery in DELIVERY-RECOVERY-PLAN.md,
and confirmed CodedbTest_0 was closed. All authorized delivery steps completed.
No push, Unity execution, Install/Reinstall/Uninstall or real-client retry ran.

## Delivered artifact

- Commit: `c07bb5903b5b3fcda7d97f5238c2915e3c566cf8`.
- Exact scope: six production files, two new focused harnesses, only the narrow
  stable-entry contract amendment, and the S39 task packet. Unrelated dirty
  files and immutable payload worktree changes were preserved; index is empty.
- ZIP: `.artifacts/exports/s39-c07bb59/com.rice.ai-codedb.zip`.
- SHA-256: `a56f2f8f0ab6562e298dde96c1f520cba58b4886615ead67e7877ef51bc1ec5f`.
- Inventory: 630 files, 13,456,960 bytes; identical candidate, commit-staged
  export, exact-ZIP extraction and new external delivery inventories.
- Package/payload identity remains `0.3.0-preview.5` / `poc.43`.

Commit-staged and exact-ZIP production admission and byte closure PASS: all
60 payload source hashes match, with native source/build/binary binding PASS.
Exact-ZIP Package path-provenance PASS, including three helper projections,
two PS decoding/admission bindings and two Node caller bindings.

Exact-ZIP focused run `.artifacts/tests/s39-stable-bootstrap/r-32cd4765/` PASS:
25 PS checks, three Supervisor readers, two real Node stable-entry protocol
fixtures, one production PS probe/native collector case and six standalone
C# contract cases. Backends/process boundaries are synthetic. Expected fixture
cleanup PENDING is not evidence of real cleanup success. This does not establish
Unity compilation, a real Provider or actual Codex tool exposure/query success.

Logs: `.artifacts/tests/s39-final-export-c07bb59.log`,
`.artifacts/tests/s39-final-provenance-c07bb59.log` and
`.artifacts/tests/s39-final-focused-c07bb59.log`.

## Existing-project delivery and recovery

Consumer: `<external-project>` = CodedbTest_0.
Reference changed only from `file:../../Packages/d856a8f/com.rice.ai-codedb`
to `file:../../Packages/c07bb59/com.rice.ai-codedb` in manifest and lock.
Each file was verified byte-for-byte against that single literal replacement.
The new external Package inventory equals the exact extracted ZIP; the complete
old d856a8f inventory is unchanged. Neither delivery was edited in place.

No Unity.exe process or project lock/state file was observed before or after
the writes. No process was stopped. The two original JSON files, protected
baseline hashes and complete old/new Package inventories were backed up under
`.backups/s39-delivery-c07bb59/` before external modification.

Restored exactly one missing file:
`AIWork/codedb/shared/codedb-instance-manifest-contract.mjs`.
Source: selected poc.43 generation's `shared/` module. Pointer-to-instance and
instance-to-generation manifest hashes were authenticated against the frozen
baseline; the unique generation helper entry and both new-Package helper
copies match SHA-256
`de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f`.
Path ancestry had no reparse points; destination and shared directory were
absent. Publication created only that directory and file using CreateNew.
Published bytes match the authenticated source.

The selected pointer, instance manifest, generation manifest, installed wrapper,
generation helper source and project `.codex/config.toml` remain byte-identical.
Preserved identity:

- project_identity: `sha256:85d0f58fdebf7f4d5fb92ae80ba2a797a6f76f03a4443684deca2026f6f5bfc3`
- instance_id: `2414c73c2fbb47f4b664c1bdbcad5969`
- activation_epoch: `4ad2120d1559487f8e54c015685496f6`
- generation_id: `poc.43`

Machine-readable before/after evidence: DELIVERY-RECOVERY-RECEIPT.json, also
retained at `.backups/s39-delivery-c07bb59/delivery-result.json`.
This is explicitly historical-install recovery. It does not prove the repaired
installer originally published the module or pass a real clean first Install.

## Retention and handoff

Owner: S39. Protect the final ZIP, canonical focused result/logs, backup JSON
files, protected hashes and delivery inventories through acceptance. Package
export staging/extraction directories are derivative verification output;
the preparation candidate remains historical review evidence. No cleanup or
relocation is authorized by this delivery.

Human next step: HUMAN-POST-DELIVERY-CHECKLIST.md. Reopen the existing project,
wait for import/compile and report Console plus Manager observations. Do not
click Install, Reinstall or Uninstall as an implicit validation action.
After the human result, arrange a separately bounded attributable Codex-client
attempt using only the target project's tools. CLIENT-HANDOFF.md is historical
and does not authorize a retry. A new Unity project is unnecessary for this
regression. Public distribution, performance, cross-version upgrade and release
acceptance remain separate.
