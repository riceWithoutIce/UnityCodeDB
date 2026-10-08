# S29 accepted native-launch delivery preparation

2026-10-08. User explicitly accepted the independent source review. Standing
pre-human prerequisite authorization covers scoped commit, local export, artifact
checks and human checklist. This follows prior same-S29 delivery practice; do not
ask again for those already authorized prerequisites. Project reference switch
requires a current confirmed normal Unity shutdown. No real runtime action.

Source baseline HEAD d56f0e507b48af24a39f23411c06dbdd4e093084, empty index.
Accepted source-snapshot .artifacts/tests/nl41a/source-snapshot.json SHA256
5569d6f51642fcc3e22440fe72f5641691eb715ed7939fce323f79820d6f9197,
41changed/new product paths. Review is NATIVE-LAUNCH-INTEGRATION-VERIFICATION.md.

## Exact scoped commit

Commit the41snapshot product paths byte-for-byte, preserving Git-filter-sensitive
bytes. Add only the two new Host Action sections beginning Short-command output
and One-shot Windows daemon creation to that document's HEAD version; add only
the S29 source integration checkpoint to the roadmap HEAD version. Preserve all
other dirty portions of these documents in the worktree. Include these7task files:

- NATIVE-LAUNCH-INTEGRATION-TASK.md
- NATIVE-LAUNCH-INTEGRATION-RESULT.md
- NATIVE-LAUNCH-INTEGRATION-REVIEW.md
- NATIVE-LAUNCH-INTEGRATION-VERIFICATION.md
- INSTALL-OUTPUT-NATIVE-BOUNDARY-PLAN.md
- INSTALL-OUTPUT-NATIVE-BOUNDARY-RESULT.md
- NATIVE-LAUNCH-DELIVERY-PLAN.md

Total50paths. Master TASK and other inherited docs/Unity files stay uncommitted.
Check exact staged paths and raw source/blob identities before commit. Message:
fix(host): isolate coordinator launch output with packaged native boundary.
No amend, push, tag, remote Project update or publication. Generated delivery
records and staged-doc projections stay below .artifacts/delivery/s29-native41.

## Exact artifact checks

Use unchanged committed export-codedb-package.ps1, exact resulting commit,
fresh .artifacts/s29-native-launch-poc41. Both commit-stage and extracted ZIP
closure gates must pass. Compare all41accepted product bytes and the two committed
document blobs to extraction. Keep Package0.3.0-preview.5 / generationpoc.41.

Run the extracted Package's test-codedb-daemon-launch.ps1 once with its accepted
Package-parent-relative root: .artifacts/s29-native-launch-poc41/review/.artifacts/
tests/nl41-delivery, for normal,missing,corrupt,retained. This remains repository-local
and honors the unmodified extracted harness's containment check. This is
exact-artifact consumer evidence, not a replay for an unchanged worktree PASS.
Use its real coordinator/caller/writer path and synthetic Provider as reviewed.
Record original error and stop on failure; no automatic product repair or real
project fallback. The already-reviewed script owns its bounded cooperative
shutdown/self-expiry; do not kill or scan unrelated processes. No Unity/MCP or
real Provider. Retain generated output and concise outcomes in delivery result.

## Human handoff and reference

Prepare one human checklist: open the existing S29 project only after its reference
is switched, confirm no C# compile errors, observe Manager and its tabs/close.
Product C# was unchanged; do not require all historical Editor suites by default.
Manager observation is not a real Install authorization. Existing failed candidate
and prior PENDING/history remain protected; fresh reinstall needs its own precise
recovery/operation plan after package validation. Progress-bar follow-up is separate.

After current normal-close confirmation and artifact checks, replace only CodeDB's
dependency path in S29 Packages/manifest.json and packages-lock.json. Verify strict
JSON, exact new reference and unchanged full reference-normalized content. Keep
project edits uncommitted and preserve prior artifacts. If Unity remains open,
finish every other prerequisite and leave reference unchanged until closure.

Delivery result/checklist and later status records are not amended into the source
commit. S29 remains PARTIAL; local export/native evidence is not Unity, real
installation/recovery, signing/reputation or release acceptance.
