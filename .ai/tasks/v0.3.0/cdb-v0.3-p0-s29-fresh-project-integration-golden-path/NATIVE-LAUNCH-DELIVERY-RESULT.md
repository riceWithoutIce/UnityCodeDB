# S29 native launch accepted-source delivery

2026-10-08. SOURCE_ACCEPTED / COMMIT_EXPORT_PASS / EXTRACTED_LAUNCH_EVIDENCE_PASS /
PROJECT_REFERENCE_SWITCH_PASS / HUMAN_COMPILE_OBSERVATION_PENDING. S29 PARTIAL.

## Scoped commit

User accepted source review; standing pre-human preparation authority applied.
Commit8b2061d45504da551b626714a877176051a43fe1:
fix(host): isolate coordinator launch output with packaged native boundary.
Exactly50paths per NATIVE-LAUNCH-DELIVERY-PLAN.md:41reviewed product paths,
7task documents and only the new source contract/roadmap sections over HEAD.
All41source hashes matched before staging and after extraction. Raw blobs were
staged without line-ending filters. Other dirty documentation/Unity state and
master TASK remained uncommitted; index is empty after commit. No amend/push/tag,
publication or remote Project update.

Initial staged whitespace check found an inherited blank line at EOF in copied
poc.41/shared/codedb-strict-json.ps1. Its hash equals protected poc.40. Preserve
the reviewed bytes: only that path's blank-at-eof check was waived; its other
whitespace checks and all other staged files passed. This is an explicit inherited
formatting exception, not a product change or blanket suppression. Staging records
and HEAD-based document projections: .artifacts/delivery/s29-native41/.

## Exact committed artifact

Export root: .artifacts/s29-native-launch-poc41.
Review Package: review/com.rice.ai-codedb.
Package0.3.0-preview.5, generationpoc.41.

- Commit-stage and exact-ZIP extraction: closure58sources/0mismatches, native
  source/build/binary provenance and x64/system-only import checks PASS.
- 41reviewed product files and2committed document projections match extraction.
- ZIP2708424bytes,553entries; extracted553files/11585960bytes.
- ZIP SHA25646605f2ac5acc0dd62d9471d57448e756d7937224119512fe8c7f1860fb2bb8f.
- generation-manifest SHA256c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec.
- host-current SHA256ac35dd035c259c65064cc684101b51c3a435ca5cbb55f914d2e6b0d41d274089.
- payload contract SHA256c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba.

## Extracted real-caller evidence

Ran the extracted test-codedb-daemon-launch.ps1 once, exit0, using its supported
Package-parent-relative root review/.artifacts/tests/nl41-delivery. All generated
files remained under the repository export tree, outside the review Package.
Actual extracted writer/native collector/coordinator/caller/native binary were
used; Provider and editor lease were synthetic. No live Unity/Provider/MCP action.

| Scenario | Native exit / incomplete | Manager exit / incomplete | External EOF ms | Result |
| --- | --- | --- | ---: | --- |
| normal |0 /false|0 /false|2713|PASS, coordinator live and authenticated READY at required checkpoints|
| missing binary |1 /false|1 /false|1702|PASS, rejected before READY|
| corrupt binary |1 /false|1 /false|1633|PASS, rejected before READY|
| intentional retained output |0 /true|6 /true|36232|PASS, bounded original failure retained|

All scenario remaining-process arrays empty. Saved final audit25recorded roles,
0present. No kills or unrelated process scans. Different clocks retain their own
origins. This binds the final committed harness and exact exported product bytes;
it is separate from the earlier worktree run3 harness-version qualification.

## Pending human gate

User explicitly confirmed UnityFreshInstallValidationProjectS29 closed. Changed
only CodeDB's local dependency reference in Packages/manifest.json and
Packages/packages-lock.json from s29-result-semantics-poc40 to
s29-native-launch-poc41/review/com.rice.ai-codedb. Both JSON documents parse and
resolve the exact new reference. Full reference-normalized text hashes match
before/after, proving all other content unchanged:

- manifest:4aaa6acc8be49754617b2f0f53e34a748881221544e0503de2d3651ac4f39300.
- lock:81920d91ce6bc6961578d971d4f2f94e107648c19097573e7a71ba1c9ed46899.

Project changes remain uncommitted. No Unity launch or process operation. Delivery
preparation is complete; use NATIVE-LAUNCH-HUMAN-CHECKLIST.md for human observation.

No real Install/Uninstall/recovery/adoption, old candidate/receipt rewrite or
historical cleanup occurred. Native artifact evidence is not Unity compilation,
real project integration, signing/reputation or release acceptance. Progress UI
remains separate. Follow-up records stay uncommitted without amending the source
commit. Next: human compile and Manager observation on the switched candidate.
