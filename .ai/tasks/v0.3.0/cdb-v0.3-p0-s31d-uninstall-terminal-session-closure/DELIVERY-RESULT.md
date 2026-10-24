# S31-D authorized delivery result — 2026-10-17

Status: PRECISE COMMIT / EXACT PACKAGE GATES / S30 REFERENCE SWITCH COMPLETE.
Human Unity acceptance remains NOT RUN / HUMAN OWNED.

## Authorization And Source Identity

User explicitly accepted the reviewed candidate and authorized precise commit,
export verification and S30 reference switching as one group. No new source
review or stage confirmation was required.

- Parent: `cc49c95e84945308385f64640963716d93d070ea`.
- Commit: `97471f537749eba97171f6756a29112dd552a22b`.
- Message: `fix: close uninstall actions from bound terminals and retain handoff warnings`.
- Exactly ten candidate files were committed. Candidate manifest:
  `.artifacts/tests/s31d-delivery-preparation-a/manifest.json`, SHA-256
  `adc1df0f26eb0f69f4e6094152e072b4c842f64ae42e742b13d5bed9c48da954`.
- Stage used exact candidate blobs. ProcessRunner and the host-action contract
  used their approved projections. All accepted working-file hashes remained
  unchanged; incoming timeout/documentation/Payload and unrelated changes were
  preserved. The staged index is empty after commit.
- Identity: `0.3.0-preview.5 / poc.43`, generation transition NONE.

## Exact Artifact Gates

The existing unchanged exporter ran against only that commit, once.

- Artifact: `.artifacts/s31d-uninstall-terminal-97471f5/com.rice.ai-codedb.zip`.
- ZIP SHA-256: `8c5a7341614b2236e4fa99284ae3a34d813fea7285fae83ed4514bf09ed664cc`.
- 619 files / ZIP entries; 13,295,769 extracted bytes.
- Extraction: `.artifacts/s31d-uninstall-terminal-97471f5/review/com.rice.ai-codedb`.
- PASS separately on commit stage and exact ZIP: production read-only payload
  admission (60 declared files), byte/hash closure (zero mismatches), native
  source/build/binary binding.
- Runtime contract SHA-256:
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.
- Generation manifest SHA-256:
  `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5`.
- Host-current SHA-256:
  `ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1`.
- All 619 extracted files match the frozen candidate hashes, including the ten
  task files. Rechecked after focused tests; Package bytes remain unchanged.
- Exact extracted Package path-provenance PASS; helper projections/decoding/
  caller-binding checks also PASS.

## Exact Artifact Semantic Closure

Task-local `run-focused.ps1` now accepts the exact delivery source root and
fresh delivery attempt names. It compiles the original extracted Editor and
Editor-test sources with the existing hash-bound compiler/references. The
original extracted Node producer-only entry executes its production serializer
helpers; real C# readers and Manager/journal consumers process those records.
No Supervisor/backend/Provider or Unity was started.

First attempt `attempt-delivery-a` failed while Mono read a generated record.
Read-only checks confirmed the records exist at 267–270-character paths. The
failure is consistent with standalone Mono long-path access, not missing
producer output. Preserved manifest SHA-256:
`dba089283f0c9cf2284571d02c3ebb08af2d731092991fffb53ec1484e7386e1`;
focused-log SHA-256:
`1e0946f75cb4132a250cb8fddd0ab4fff3139dcf03140ffb9aff9b8b3e1a0ca3`.

One bounded mechanical correction shortened only new test-output locators to
`review/.artifacts/tests/s31d-uninstall-terminal/d2` and `f2`. These are siblings
of the exact Package within repository-local export output, selected under the
unchanged producer entry's existing root guard. No product source, Package
bytes, parser, evidence rules or old outputs changed. No new export occurred.

- PASS `attempt-delivery-b`: five production fixtures, complete success and
  failure, normal/reopen Manager resolution and exact journal release; wrong
  action/operation/owner/request/bindings, missing/pending, timeout and incomplete
  output refusals through existing assertions.
- PASS `attempt-f1-delivery-b`: success/failure producer fixtures; handoff failure
  warning/detail survives conversion with backend result unchanged, confirmed
  handoff clears warning, reopen remains handoff-unconfirmed without replay,
  normal completion avoids second lookup and foreign-action release is refused.
- Compilation PASS, same three existing warnings (CS4014 twice, CS0414 once).
- General manifest SHA-256:
  `8be016b657a0ac38fafa79113144a6ce56b43ef2b869ade9687748a320357224`.
- General focused-log SHA-256:
  `6e3bdda1cf9d160b9e817710588133d89d66a399f8ccc2626c2c7d2e61e3bb3c`.
- F1 manifest SHA-256:
  `e36ace1c2f37d9ac4206f2bea75808b7a063d750e13b2b1c6b9cfb7915125652`.
- F1 focused-log SHA-256:
  `929c54f564bbc0340f6487fca909936eb124865969e1ed10d54f8ddf1b5f0d04`.
- Final task-local driver SHA-256:
  `3045cb268af289ee48541937d961c08e2857dd78185ca2f5e4c0c234d6a94974`.

## Consumer Switch And Preservation

Immediately before switching, S30 had no attributed Unity process and no
`Temp/UnityLockfile`. Original configuration hashes matched the proposal.
Both original files were copied and hash-verified under
`.backups/s31d-uninstall-terminal-97471f5/` before editing.

Only the CodeDB local Package reference changed in S30's
`Packages/manifest.json` and `Packages/packages-lock.json`, from
`.artifacts/s31c-uninstall-entry-cc49c95/review/com.rice.ai-codedb` to the exact
extraction above. Text comparison against the backups proves no other changes;
both parsed JSON references agree and `testables` still includes CodeDB.

| File | Backup SHA-256 | Current SHA-256 |
| --- | --- | --- |
| manifest.json | `525158f4699754f59848add163365b65401daf64c5f29e6527f08be0dfc8e75b` | `599af94eb4eaeacf223e719054d9fab88f37ad41535b7ad99a386f7b11a0346e` |
| packages-lock.json | `67fe15f44147943c741b6598207f5345a71d8569bf3821d130fb047a3093296d` | `7d73367478748ba240d9cdfead652a598e5d7ba7c558e906edea92fe35b2a3e7` |

All seven protected copied S30 runtime evidence hashes match their preflight.
The original pre-repair pending action remains unmodified and lacks the new
binding/completeness anchors: no automatic reconciliation/unlock is promised.
No actual Install/Uninstall/Remove, runtime rewrite, index deletion, process
control, Unity launch, push or publication occurred. This result is delivery
and isolated contract evidence; it is not real lifecycle or Unity acceptance.

## Handoff

Current task: S31-D human Unity acceptance of the delivered exact Package.
Next actor: User; use HUMAN-CHECKLIST.md. No reinstall is needed.
Next parent action: collect human result and perform bounded read-only checks.
Any reconciliation of the existing old action or new real lifecycle operation
requires a separate bounded decision; it is not part of this checklist.
