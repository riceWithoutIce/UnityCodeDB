# S29 path-guard separation repair — result

Date: 2026-10-12.
Status: `PASS_WITH_LIMITS` / source-only checkpoint.

## Scope

This narrow repair separates the user-local Manager action-history path guard
from the project-local CodeDB instance-candidate scan. It does not change
admission policy, historical ownership attribution, multi-failure recovery,
generation matching, payload files, package references or runtime state.

## Change

`FindUnownedProvisioningCandidate` now validates `instancesRoot`, candidate
directories and `instance.json` through `AssertProjectPath`. Manager index,
receipt, lock and legacy package paths continue to use `AssertPath` against
`GetManagerActionsRoot()`.

`AssertPathWithinRoot` contains the shared normalized containment and existing
segment reparse-point checks while preserving distinct error messages for the
two roots. The existing 32-character instance ID contract and strict orphan
candidate conflict behavior are unchanged.

## Verification

- Focused harness: `.artifacts/tests/s29-instance-id/Focused.csproj --no-restore`.
- Semantic compilation: `SEMANTIC errors=0`.
- Focused execution: 9/9 cases PASS.
- Pre-fix comparison: replacing the 32-character instance check with the old
  24-character receipt-key check rejects the valid READY case as expected.
- `git diff --check`: PASS.
- Read-only Verifier: `PASS_WITH_LIMITS`, no BLOCKER/P1/P2 findings.

Current source hashes:

```text
59c24572f0a80311dd290318d7fce50436601ffa0cbea054bbddf6d572a004aa  com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
07b4fdd66d921c267686966c037226878c60030075ed40c574d2a50145707f9d  com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
```

## Limits

This is semantic/standalone evidence, not Unity/NUnit runner acceptance. The
retained producer chain, real project history, Unity UI, package export,
reference switching and release gates were not run. Historical orphan
attribution and multi-failure history remain fail-closed and deferred.

No commit, package regeneration, Unity launch, Install/Uninstall or runtime
record mutation was performed.
