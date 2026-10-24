# S29 Upgrade async call-site compile repair — result

Date: 2026-10-13. Status: REFERENCE_SWITCH_COMPLETE / HUMAN_UNITY_PENDING.
Verdict: PASS_WITH_LIMITS.

## Authority and frozen scope

User replied `同意授权` to the concrete single-file repair and focused
verification proposal after the human CS7036 report. The parent performs this
small call-site fix directly; no new subagent or independent review is claimed.
The grant does not include commit, export, reference switch, Unity launch,
runtime actions or cleanup. Base HEAD remains
`4b9beef8f435ed7b85e980f4a60cb01ae64e96b2`.

Only product change:
`com.rice.ai-codedb/Editor/AICodedbHostPayloadMaterializer.cs`, RunUpgradeAsync,
now passes explicit `null` as the fifth RunAsync argument. The Upgrade action,
captured execution context and mutation timeout remain unchanged. The required
five-argument signature and explicit authenticated handoff in
RunRemoveIntegrationAsync are unchanged. RemoveIntegration still refuses a
missing handoff; no optional parameter or default permit was added.

Before SHA256:
`c229d9778f07154d8dbb74ddf5e431ecf5fe82c29d8e5f7d0e4efea3dab70b3f`.
After SHA256:
`6089ea99ff56690ad9055336ef28bfe77152705ffcd7eed7db8a5741e25efd1b`.
Git diff is one hunk, two added lines / one removed line. Exact source text
comparison allows only this argument addition. Scoped whitespace check passes.

## Compiler and focused evidence

Used the installed Unity 2022.3.62f3 Roslyn compiler and actual S29 Bee Editor
response, including its references, symbols and source generators. All compiler
outputs went to `.artifacts/tests/s29-upgrade-callsite-compile-fix/`; no project
Library output was replaced. The 30-file Editor source assembly was copied
from the failed exact Package with only the approved source overlay. All copied
source bytes were checked against frozen originals or the repaired source.

- Baseline exact Package: exit 1, one error, reproducing CS7036 at the missing
  removalPreflightHandoff argument.
- Repaired Editor assembly: exit 0, zero errors, three inherited ManagerWindow
  warnings (two CS4014 and one CS0414). These warnings remain outside scope.
- Existing dedicated handoff test source: exit 0, zero compiler errors,
  referencing the newly compiled Editor assembly.
- Three unchanged existing test methods executed under the installed Unity
  Mono runtime, all PASS:
  `RemovalPreflight_RequiresOneAvailableLineAndHandoff`,
  `RemovalPreflight_RejectsMissingOrDuplicateHandoff`,
  `RemovalIntegrationArguments_RequireHandoff`.

Standalone execution invokes only the above synchronous logical methods.
No production source or NUnit assertions were rewritten, no Unity Editor
started, and no materializer/process/mutation action was invoked. This is actual
C# compiler and standalone pure-logic evidence, not Unity import/EditMode
lifecycle, Manager UI or real historical-removal evidence.

## Harness corrections and preserved observations

Two harness mechanical corrections were needed: PowerShell array-expression
grouping for the runner output argument, then excluding unmanaged runtime DLLs
from C# metadata references. Their failed response/log files remain intact.
Once compiled, the .NET 6 runner failed because Unity's legacy NUnit depends
on System.Runtime.Remoting.Messaging.CallContext. One causally corrected
execution used Unity Mono, preserving test bodies and assertions; it passed.
No product repair or compiler-source rerun was needed for those runner issues.
Initial artifact discovery and the unmanaged-reference compiler output were
truncated; complete compiler log files are retained. No blanket output-budget
compliance claim is made.

Protection checks confirm all 32 other originally dirty tracked files unchanged,
all 617 original failed-artifact file hashes unchanged, failed ZIP hash unchanged,
both S29 reference hashes unchanged and HEAD/index unchanged. The failed review
directory additionally contains the handoff test's `.cs.meta`, observed after
human import and absent from the frozen inventory. Its exact hash is recorded
in result.json. It was not created or modified by this repair; preserve it and
do not represent the post-import directory as still having exactly 617 entries.
This observed metadata addition is distinct from the CS7036 fix and is not
silently added to its product allowlist.

Evidence: baseline.log, fixed.log, handoff-tests.log, runner.log,
runner-a2.log, runner-a3.log, handoff-run.log, mono-runner.log,
handoff-mono-run.log, compiler response files and result.json under the isolated
directory above. Failed source/ZIP and previous review records remain intact.

## Delivery completed

The user approved the exact grouped delivery. Local source commit:
`34b3a65c8c3f136ccb052ba52bb10a8476676546`.
The exact Package is
`G:/RiceProgram/UnityCodeDB/.artifacts/s29-upgrade-callsite-fix-34b3a65/review/com.rice.ai-codedb`.
ZIP SHA256 is
`6f83c71255c2c2c5479f7183b80bf6acce52a825f94cce1672b140dcb79bccaf`;
617 files and 13,055,586 uncompressed bytes. Commit-stage and exact ZIP
passed production admission, 60-file byte closure with zero mismatches and
native VerifyOnly. Compared with the frozen d127a45 inventory, 616 files are
byte-identical and the only changed product file is the accepted
`Editor/AICodedbHostPayloadMaterializer.cs` repair.

S29 references now point to the new exact Package. Backup:
`.backups/s29-upgrade-callsite-fix-34b3a65`.
Only `Packages/manifest.json` and `Packages/packages-lock.json` changed;
replacement count is one each, JSON parsing passed. After hashes are
`manifest.json` `9adea12c24219aea55d06364dbb38346b418079746e59c05c37fcb7efd8fbc09`
and `packages-lock.json`
`507a4db713e10748a63d7a694729649f5550b2e2e42cd449d86a74636d9982d6`.
Final protection passed: 9 non-Package protected roots, 28 unrelated dirty
files, 616 original artifact files, and both reference preimages unchanged.

The human checklist is
INSTALLED-GENERATION-ALIGNMENT-UPGRADE-CALLSITE-FIX-HUMAN-CHECKLIST.md.

## Remaining gates

No independent Verifier result is claimed. Repaired-package human compilation,
focused EditMode and Manager/tabs pass. First-close normal shutdown is
PARTIAL: the first close displayed an 11-second `CleanupMono` hold while the
second close completed normally. See
INSTALLED-GENERATION-ALIGNMENT-UPGRADE-CALLSITE-FIX-HUMAN-RESULT.md. Real
Remove/Install and release acceptance remain unrun. Do not patch either
Package in place or regenerate Payload. S29/release remain PARTIAL.
