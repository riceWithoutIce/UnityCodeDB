# Existing identity fixture projection result

2026-10-09. CODER_STABLE_SNAPSHOT / INDEPENDENT_REVIEW_PENDING.
Base HEAD `2154b814e1c4720e7e0915c1843d70eab0c3a0ec`.

Only source change: `Tests/Editor/OwnerIdentityV2Status.json`.
Five existing generation fields now derive `poc.42` from the final payload
manifest: status generation_id, target_generation_id, selected_generation_id;
operational_readiness selected_generation_id and target_generation_id.
Both runtime_contract_sha256 fields derive the actual final payload-manifest
SHA256 `538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d`.
Git diff is exactly seven replaced value lines; all other fixture bytes/shape
retained. Raw fixture SHA256:
`3cdf6ac436264ff391acafd77999b8aa62966f5295b7481cb0c004ee3afcf6a7`.

Existing ignored single route `.artifacts/tests/s29-adapter/project-successor.ps1`
now synchronizes that fixture after the final manifest and runs the original full
release-closure gate as a mandatory prerequisite. New `-FixtureOnly` mode reads
the committed final manifest without executing any payload projection; incompatible
projection switches are refused. Projection guards and validators are unchanged.
Route raw SHA256:
`3c75c21de8af64c89a56afafc256a7c5cd762ec73f002995a5b26115d0b28cb6`.

One actual invocation, zero failed attempts or corrections:
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .artifacts/tests/s29-adapter/project-successor.ps1 -FixtureOnly`.
Exit 0. It executed existing
`Tests~/test-codedb-package-release-closure.ps1 -PackageRoot <source>` without
`RepairCanonicalMetadata`; full gate exit 0. Production admission 60 files PASS;
both existing x64 native VerifyOnly checks PASS; byte closure 60 sources,
0 mismatches PASS; existing owner fixture identity assertions and full package
closure PASS. Log:
`.artifacts/tests/s29-adapter-identity/r-5d8d12e2/release-closure.log`.

All 37 original accepted snapshot rows compared after gate: 0 mismatches.
Accepted snapshot raw SHA256
`416da42825b8742d5c76a23b71c6c3933f534c8e8f38e598a85b5c0f1f08c9c2`.
New two-row raw snapshot: `.artifacts/tests/s29-adapter-identity/source.sha256`.
Evidence summary: `.artifacts/tests/s29-adapter-identity/protected-equality.txt`.

Bounded reads remained below 6KiB per file slice/read and 64KiB cumulative;
targeted search returned only 3 matches. No broad search, old suite rerun,
validator/exporter/package.json change, actual project access, process control,
Unity, MCP, commit, export, remote writes, or nested agents. Previous failed
artifact/log were not accessed or overwritten. S29 real recovery/human/release
gates remain unchanged and PARTIAL. Coder has stopped writes for independent
Verifier review of this stable snapshot.
