# Retained entry routing delivery and real preflight result

2026-10-09. SOURCE_AND_EXTRACTED_ENTRY_PASS / REAL_PREFLIGHT_BLOCKED.

Scoped commit: 2c85c37f25c2c4a8c1f40235ce60ce4cfd32c7ce,
`fix(host): route uninstalled recovery preflight to safety checks`.
Independent review: SCOPED_SOURCE_AND_SYNTHETIC_ENTRY_REVIEW_PASS.
Original dispatch finding is closed within the frozen source scope.

Immutable delivery: `.artifacts/s29-retained-entry-poc41/review/com.rice.ai-codedb`.
ZIP SHA256: 51a4d930be649d5a6cd12a174a5f68280be0565a14ed3f3d7662d52b1e10e26e.
555 entries / 11,713,585 uncompressed bytes. Commit/export admission and
58-source byte closure PASS; six accepted snapshot rows match extraction.
Actual Package remains 0.3.0-preview.5 / poc.41. Exact extracted production-entry
test PASS22 assertions / 8 CLI invocations. Existing suites were not repeated.
Evidence: `.artifacts/delivery/s29-entry/extracted-entry.log` and extracted
`review/.artifacts/tests/s29-entry/r-6be5c3c2`.

## One real read-only attempt

New extracted materializer invoked UninstallPreflight against closed S29 with
original INSTALL action f14c0524af324b7a802335a393483fa0. It reached the dedicated
validator rather than the previous early UNINSTALLED refusal, then reported:

```
[REMOVAL_PREFLIGHT] BLOCKED
Removal preflight requires review. Failed preparation contains an unexpected mutable directory.
```

The local wrapper used ErrorActionPreference=Stop. Native stderr became
NativeCommandError and interrupted its result/post-hash recording. Wrapper exit1
is recorded; native exit/timing were not saved and must not be inferred.
`real-preflight.log` holds stdout only; stderr is retained in the tool transcript
and above. No second real attempt or direct-function bypass occurred.

A separate read-only check afterward matches the prior two instance manifests,
removal intent and four original manager action/receipt hashes exactly:

| Protected file | SHA256 |
| --- | --- |
| poc.39 instance.json | 13cb910b889aa671024ad97a70e69601289be8892b4613b8494cdedcd526aeec |
| poc.40 instance.json | 1344f215160516141399556c250670021677e0ad0efa0465663c0821664b16f5 |
| removal intent | aa6dfb83231fadfc8fc6d1d1ecc963c4053414ede28bacb8bcfb3d810c7c8039 |
| original admitted | 85cce9f0721295c5eeecc1236b9d9e40a6389c44e36c8096f392606ccab4203b |
| original claim | f19743c72c551408f5a610ca09d9b377aeaa43c9985ff3bc98f27867e7b6aad5 |
| original terminal | cb7f796d8588117509da1792e4b8c392b5538b2b42889ea4f754f8085f30dc64 |
| original action.json | f662468c1e27b7a5ca30aab40ab084a69351549109ba6107fc68fcfd14890b5b |

Desired-state SHA256 observed afterward:
c930151b286a66126f190b975d27d8e7db468f361f7ac3b79303c8d5d9f9445f.
No saved pre-attempt desired-state hash is available; do not claim a full
eight-file before/after comparison from the interrupted wrapper.

## Bounded production topology diagnosis

Candidate 5a6ff71560234b558e1a42148b680a77 contains empty ordinary directories
`adapter/text-index/logs` and `adapter/text-index/tmp`; neither is a reparse point.
Frozen poc.40 `scripts/codedb-project-common.ps1:167` and :168 declare them.
`New-ProjectCodedbTextAdapterRuntime` (:430-444) creates both under ProviderRoot;
`build-codedb-project-text-adapter.ps1:16` calls this production initializer.
Thus these are declared producer outputs, not merely guessed names.

Current `Tools~/codedb-instance-engine.ps1:1957` accepts adapter/text-index but
neither child directory. Both violate its current directory classifier and
explain the reported generic refusal. No unknown files have been accepted.
This is a producer/recovery-classifier and representative-fixture gap; it does
not negate the scoped entry PASS or prove an export byte mismatch.

## Handoff

User confirmed Unity normally closed/reference switching allowed. Because real
preflight refused, references remain on s29-retained-path-poc42 and no new human
cycle is requested. No Unity launch, retained recovery, Install/Uninstall,
candidate deletion, receipt alteration, process termination or remote write.

Engine repair exceeds RETAINED-ENTRY-ROUTING-TASK.md's explicit production
allowlist. Proposed bounded scope is recorded separately for User disposition.
S29 remains PARTIAL; process/holder safety, real recovery and fresh Install
remain open. Three compiler warnings remain deferred.
