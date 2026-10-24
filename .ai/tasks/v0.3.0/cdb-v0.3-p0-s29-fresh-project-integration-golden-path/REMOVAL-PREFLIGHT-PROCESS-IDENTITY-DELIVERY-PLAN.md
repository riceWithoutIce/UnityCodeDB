# S29 process identity — proposed delivery envelope

Date: 2026-10-14. Current status: DELIVERY_COMPLETE / HUMAN_PENDING.
The prepared plan received the later explicit `授权` recorded in DELIVERY-GRANT;
execution and exact identities are recorded in DELIVERY-RESULT with this prefix.
The plan by itself was not a delivery grant. User source accept is
recorded in REMOVAL-PREFLIGHT-PROCESS-IDENTITY-ACCEPTANCE.md. Subsequent `ok 继续`
continues preparation of the delivery envelope proposed in that handoff.

## Exact source and commit boundary

Current HEAD: 39d79aeee1bd5525c6ed2eb1369f6c27334b9d07. Index empty.
Rechecked accepted hashes:

```text
22aa5eedc0f5f61e90f2c17cabbe4496cccd8ba1b2e33028c2101a02268b4f2c  com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1
4b9e60cb7906852e6de3a694b6303451cc69473b4593a593632ad96fe439089b  com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
49aacc0dd0065c32f9d451dfe40da05b7a540afffba71b826dc9e2ab0f2a7f45  com.rice.ai-codedb/Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs
```

Proposed local source commit includes exactly these three paths, no task/docs,
dirty Payload, old validation project or unrelated changes. Review the staged
allowlist and byte hashes before committing. No push, merge or publication.
If HEAD/index/source changes before execution, stop for attribution instead of
staging or committing somebody else's changes.

## One continuous delivery sequence after approval

1. Commit the three accepted files. No additional source repair.
2. Use existing Tests~/export-codedb-package.ps1 with that exact commit and a
   new exclusive .artifacts/s29-removal-process-identity-<shortSHA> output root.
   Preserve every earlier artifact, including failed attempts. The exporter uses
   git archive, never dirty working-tree Payload. No generation/version bump.
3. Require commit-stage and exact ZIP production payload admission, native
   VerifyOnly and 60-source byte closure. Verify ZIP identity, accepted source
   equality and all tracked Package bytes against the accepted baseline plus
   exactly the three approved changes. Check PathProvenanceOnly on the exact
   extracted Package. No broad whole-product regression.
4. Run the declared affected namespace/process-identity scenario against that
   exact extracted Package, using synthetic observations and the original
   production functions. Preserve isolated PASS141-equivalent scenario evidence,
   original-byte Editor/Editor.Tests compilation, and exact C# fixture/diagnostic/
   cache/UI consumer binding and assertions. No supervised native process or IPC.
   Adapt existing task-owned harness input/output paths, not source assertions.
5. Compare protected runtime/configuration/history/receipt/Payload/earlier artifact
   state. Only after all artifact gates pass and S29 Unity is closed, back up and
   switch the two explicitly named Package reference files below. Recheck closure
   immediately before mutation. An open/unverifiable project blocks the switch;
   do not close or terminate Unity automatically.
6. Verify both JSON references resolve to the exact new review Package and that
   each text diff contains only its old-to-new reference substitution. Compare
   protected state with only these two reference changes allowed. Record ZIP
   SHA256, file/byte counts, commit, hashes, logs, backup and exact reference.
7. Prepare the exact-package human checklist and hand off. Human owns project
   launch, compilation/Test Runner, Manager close/reopen, tabs and Unity close.
   Fixture-only tests requiring explicit arguments remain isolated evidence;
   do not ask the human to run them as ordinary unconfigured Unity tests.

Parent performs the approved local delivery; no new delegation/session/model
change is included or required. Once approved, continue this declared sequence
without per-command approval. Any failed gate preserves evidence and stops the
dependent delivery; it does not grant repair, retry or broader environment work.

## Exact reference target and current observations

Only:

- UnityFreshInstallValidationProjectS29/Packages/manifest.json
- UnityFreshInstallValidationProjectS29/Packages/packages-lock.json

Current value in both:
file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-namespace-39d79ae/review/com.rice.ai-codedb.
New value: the corresponding file reference beneath the exact new export root.
Pre-change SHA256:

```text
3167fe9057071161875621d22afc532987f1aec28160c4e672a68ddffb16a59f  manifest.json
4a86d28e96739a4baa1e63b671bae50d6a287ef6fd23ce2b1d9f486d62fa21d7  packages-lock.json
```

Preparation found no matching S29 Unity.exe or Temp/UnityLockfile. This is a
point-in-time observation; recheck before switching. Backup goes to the unique
.backups/s29-removal-process-identity-<shortSHA>/ directory. Raw delivery evidence
goes to .artifacts/delivery/s29-removal-process-identity-<shortSHA>/ and isolated
test evidence to .artifacts/tests/s29-removal-process-identity/delivery-<shortSHA>/.
All new paths stay in this repository and remain ignored artifacts/backups.

## Package inventory attribution

Read-only ZIP inspection confirms the existing39d79ae ZIP has 617 entries and
does not contain Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta.
That single 243-byte file currently exists in the reference review directory,
but is untracked and absent from the original ZIP. SHA256:
63b2a35a8ec29ed558ae263573a6ee43664ea1a17111352a61b1b6bc272aa20f.
Thus the current source-review input/overlay counts of 618 are directory counts,
not a claim that the committed or original ZIP inventory contained 618 files.
Its creation source is not established by metadata alone. Do not stage it,
rewrite old ZIPs or silently copy it into a new commit export. Reconcile exactly
this known untracked meta item when comparing the accepted overlay to git export;
do not use a blanket meta-file exemption. Every shipped source/payload byte must
still have exact committed provenance and accepted semantic evidence.

## Preserved limits

Source acceptance covers identity classification, not full history reconstruction
or real removal unlock. Both known child=null histories remain explicitly blocked.
Historical outcomes and records stay intact; CleanupMono remains deferred.
No real Install/Remove/Upgrade/Probe/preflight/IPC, automated Unity/MCP/CUA/BatchMode,
process control, cleanup, environment edit or publication. The closure validator's
existing native VerifyOnly is artifact validation only, not runtime activation.
Human Unity evidence and subsequent read-only checks are separately attributable;
S29/release remain PARTIAL. Writing this plan grants none of the proposed writes.
