# S29 Upgrade async call-site compile repair — result

Date: 2026-10-13. Status: SOURCE_ACCEPTED / DELIVERY_PREPARED.
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

## Remaining gates

User replied `同意授权` after this source result was returned, accepting the
single-file repair and authorizing delivery preparation. The exact new group
is in INSTALLED-GENERATION-ALIGNMENT-UPGRADE-CALLSITE-FIX-DELIVERY-PREPARATION.md.
No independent Verifier result is claimed.
No source/evidence commit, new export or S29 reference switch was performed.
The human project still selects the failed d127a45 Package, so it is expected
to keep showing CS7036 until a separately approved exact delivery occurs.
Repaired-package human compilation, focused EditMode, Manager/tabs/normal
close, real Remove/Install and release acceptance remain unrun.

After source acceptance, the concrete next delivery is the single repaired
source plus its bounded task/evidence records, a new exact commit-derived
artifact with unchanged accepted generation projection, and a backed-up
two-file S29 reference switch after human Unity closure. That sequence requires
its own exact grouped approval. Do not patch the failed Package in place or
regenerate Payload. S29/release remain PARTIAL.
