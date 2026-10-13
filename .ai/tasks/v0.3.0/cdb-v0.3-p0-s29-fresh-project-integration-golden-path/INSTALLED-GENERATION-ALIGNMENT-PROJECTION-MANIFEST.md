# S29 installed generation alignment — isolated projection manifest

Candidate root: `.artifacts/tests/s29-generation-alignment/implementation-a2/com.rice.ai-codedb`.
The candidate is isolated from the dirty working tree and real S29 project.

| Projected root | Files | Sorted relative-path/raw-hash inventory SHA256 |
| --- | ---: | --- |
| `Payload~/payload-manifest.json` | 1 | `3dfbb4ef721e057402ab2c21629c1c2835c5f6f736bf4a5b6ea7ba8bef983b3f` |
| `Payload~/host-current.json` | 1 | `306c2afdf9f896a1c4a3f0d46a42b522e2d8e1e25379c2707b59f383761ba885` |
| `Payload~/Generations/poc.42` | 30 | `ec3e6ae82ffda41876f69547635f0be26585438654a92d02717e14e805c63c32` |
| `Payload~/Generations/poc.43` | 30 | `19e407abb5fd14551f946466da842f2e76334c2c3f95b6f4e8c4149045ba621b` |
| `Tests/Editor/OwnerIdentityV2Status.json` | 1 | `2861af437106d52560d2f02ea02ae2fa3699b01aac0b2abb176a79bcbfdd8fe7` |

The original poc.42 generation has 30 files and zero raw-hash differences from
the frozen `s29-post-install-ui-poc42` predecessor closure. Its predecessor
manifest SHA256 is `2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026`.
The successor payload is `poc.43`, sequence 43, package
`0.3.0-preview.5`, bootstrap protocol 1. Its transition declares
`source_runtime_contract_sha256=538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d`.
The successor payload runtime hash is
`69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a`.

`ValidatePayload` passed with 60 declared files; native daemon `VerifyOnly`
passed. Node supervisor `--check` passed. The package path-provenance gate was
run against both the candidate and frozen retained-disposition source and fails
on the pre-existing absolute-path finding in `Tests/Editor/AICodedbManagerUiTests.cs`;
no test file was changed for this task. Focused production synthetic batch passed
27 cases, including actual historical owner/preflight/removal/three next-change
historical gates/fresh Install, wrong or missing authority, owner/selection/
activation/project/epoch/operation tampering, holders, config drift, retained
immutable predecessor and distinct successor publication. External process and
native seams are synthetic (`PocFixture=true`); this is not live readiness.
