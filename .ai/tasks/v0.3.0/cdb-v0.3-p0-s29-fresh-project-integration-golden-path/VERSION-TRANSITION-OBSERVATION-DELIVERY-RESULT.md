# S29 version-transition observation — delivery result

Date: 2026-10-14, Asia/Shanghai.
Status: DELIVERY_COMPLETE / HUMAN_UNITY_PENDING.

Human continuation: focused consumer test PASS (1/0), other requested Manager
interactions normal; Unity close blocked at CleanupMono. See
VERSION-TRANSITION-OBSERVATION-HUMAN-RESULT.md. Real Manager still reports a
prerequisite/context refusal; no real recovery or S29 completion is claimed.

## Commit and package

The accepted four-file snapshot was committed exactly as authorized:

- Commit: `14444cf1ad179fe29e067e8dcfdc7b0b5496e230`
- Subject: `fix: authenticate retained predecessor observations independently`
- Commit contents: only the four accepted source/test files; unrelated dirty and
  untracked content was not staged.

The existing exporter ran against that commit and passed both commit-stage and
exact-ZIP gates:

- Review package:
  `.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb`
- ZIP:
  `.artifacts/s29-version-transition-observation-14444cf/com.rice.ai-codedb.zip`
- ZIP SHA256:
  `44f71bc7f0e9ac8ef99ff3d05cb8262f2359e1f7c2994f3528fbe2e473723136`
- 617 files/entries; 13,136,560 uncompressed bytes.
- Production payload admission, native build/VerifyOnly and 60-source byte
  closure all passed with zero mismatches.
- Target generation remains `poc.43`; runtime contract hash remains
  `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.

## S29 reference switch

Before switching, the project was confirmed closed. Backups are in:
`.backups/s29-version-transition-observation-14444cf/`.

Both files now select exactly:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb`

- `UnityFreshInstallValidationProjectS29/Packages/manifest.json`
- `UnityFreshInstallValidationProjectS29/Packages/packages-lock.json`

JSON parsing passed, references are equal, and the exact package `package.json`
exists. The post-switch manifest and lock hashes are respectively
`f598cd61be5090b6fb809651a73445cd61105c77773b1f3c737e295b58195e41` and
`19652067689ad489c7be0b61e9ba185b9e82a82207dc0b5f57f315c342c1eee5`.

The selected/desired/activation/operation control hashes remained unchanged:

`0abe47370544c18fe074f34a1230109da5ebe3a5de4951cc40a08c5680933f3b`
`e270b40b20409f484a395f522ac9e2afa451499a1bdb0b1bc3bbe28c583274c1`
`afdce4014bd4ef18998f56933ea0b3bd4ad7189feda9d0022875cc278ef390e3`
`0995b8929e763a2defdfe219fb42375ffc236322b89af5eb730e94c17f0a0ad2`

No S29 Unity process was present after the switch. No Install, Remove, Upgrade,
history cleanup, index release, process control, push or publication occurred.

## Remaining gate

Human Unity validation is still required for this exact new reference. The
version-transition test has an environment variable and must not be treated as
PASS if its fixture is absent. The earlier removal-preflight exit 4 and the
complete Journal -> Session -> UI runtime chain remain declared limits.
