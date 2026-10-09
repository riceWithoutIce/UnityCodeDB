# S29 retained-candidate recovery independent verification

2026-10-09. SOURCE_REVIEW_PARTIAL / NO_SOURCE_PASS. No independently established
implementation BLOCKER was found in the inspected source. This is not a complete
source acceptance: the bounded review stopped with the remaining direct evidence
listed below. No Unity/runtime/project recovery or release acceptance is claimed.

## Stable identity and authority

- Base/HEAD: 4ba4ccb6cfc437343c8e4cdc7c45816e4510882e.
- Snapshot: .artifacts/tests/rc41-retained-candidate-recovery/fixture-completion-source.sha256.
- Snapshot SHA256: 44d592d02a4a28c99428310241b71e45b5b8921aefb80985b1352bdc616e02fa.
- Eleven rows are package-relative; Parent's attributable corrected package-root
  comparison matched all eleven. Ten scoped source/test files are modified;
  Actions.cs is unchanged. Other dirty state was preserved.
- Read REVIEW, frozen TASK, and latest FIXTURE-COMPLETION-RESULT completely.
  Coder was stopped; no Coder contact, other agents, source edits, test execution,
  export, commit, real project/receipt reads, Unity or process operations occurred.
- Reused Parent evidence: tracked Payload diff is empty; 417 enumerated and tracked
  Payload files. No independent aggregate historical hash-baseline claim is made.

## Inspected source findings

No deterministic normal-path contradiction was established in these inspected
segments. This conclusion applies only to the evidence below.

1. Editor/AICodedbManagerActionJournal.cs:311: the schema2 retained-effects reader
   binds action/stage/project/original Package, distinguishes compact and legacy
   receipt layouts, reads and hashes admitted/claim/terminal bytes, and retains
   nonzero original exit status. Lines370-438 validate the actual v2 intent path,
   intent hash, instance-origin action linkage, exact bounded effect hashes and
   unrecorded-effect refusal. Lines439-446 preserve stdout/stderr, timeout,
   overflow and incomplete-drain fields without authoritative terminal success.
2. Journal lines476-576 validate current desired state and absent active
   authority, or a distinct READY/COMMITTED INSTALL using the existing selected
   instance reader plus real activation/operation identity and wrapper bytes.
   The later wrapper exception body after line578 was not read in this window.
   Lines678-686 retain failed INSTALL history; lines950-970 release only the same
   action's re-read matching retained-effects disposition under the index lock.
3. Editor/AICodedbManagerWindow.cs:2231: the existing confirmed Uninstall route
   requires the cached removal preflight, dispatches explicit recovery tied to
   the original action, reads the resulting journal and releases the matching
   index before session completion. Lines3753-3783 project disposition separately
   from successful terminal evidence. Editor/AICodedbEditorLifecycle.cs:1157
   adds worker removal preflight to the Uninstalled cached snapshot; materializer
   C# lines173-195 wire the same original-action preflight/recovery command.
4. Tools~/codedb-instance-engine.ps1:1829-1960: generated-effect ownership uses
   exact config/adapter declarations, Provider manifest filename families sharing
   one generation token, lifecycle project identity, and bounded native capture
   names. It retains the existing 512-entry policy and rejects unknown mutable
   files/directories and drifted bootstrap bytes. Diff at2091-2120 validates old
   intent-bound closures before selecting exactly one unbound candidate and
   validates the associated generation set; it does not pick first/latest.
5. Engine diff at5109-5194 permits confirmed failed-candidate retention while
   desired state remains UNINSTALLED, preserves automatic-cleanup distinction,
   demands original INSTALL recovery attribution/process proof, and explicitly
   completes only one intent-bound candidate without replaying INSTALL.
6. Tools~/materialize-codedb-host-payload.ps1:10965-11068: original-action proof
   preserves compact16hex versus legacy64hex stage rules, reads actual original
   receipts and original Package/writer hashes, validates INSTALL arguments,
   action/operation linkage and command fingerprint. Process proof rejects a
   live/ambiguous original writer or live child; the following process-command
   scan body was not fully read. Publication lines11079-11116 independently read
   real committed intent/desired state, call next-change admission, reject active
   authority, take index.lock, revalidate receipt/process proofs and hash actual
   intent/state. Pending publication requires explicit validated completion.

## Evidence boundaries and remaining closure

The latest Coder RESULT provides attributable Windows PowerShell focused EXIT0
and 41 successful labels, including two retained closures, interrupted marker
completion preserving failed/incomplete original output, actual next-change
admission, actual fresh distinct INSTALL handoff and installed-v1 reader. This
Verifier did not rerun unchanged evidence. It does not equate that test run with
production Provider execution or C# execution.

The direct remaining source examination is limited to this original frozen path:

- Engine existing holder/lease/coordinator safety body at4137 and the remainder
  of confirmed Uninstall transaction/publication after5194, including its final
  publication call at5286.
- Materializer process-command scan after11068 and final pending-marker
  publication after11116.
- Focused fixture body at Tests~/test-codedb-host-payload-materializer.ps1:662
  and directly coupled C# authored fixture bodies, including their wrong-proof
  consumers, session/UI and lifecycle cancellation coverage. Their presence or
  Coder descriptions alone are not substituted for independent body review.
- Journal's later wrapper handoff exception after578 and the remaining tightly
  coupled restore/session path if needed to close the actual emitted fixture.

Consequently, no full scoped source PASS or complete mandatory fixture-coverage
PASS is issued. This is an incomplete verification evidence boundary, not a
fabricated implementation defect and not a BLOCKER classification.

Separately, the latest RESULT explicitly leaves advanced-specific false
receipt/intent proof execution, early-v2 ABSENT/OLD and wrapper interruption,
C# compile/tests, extracted Package parity and human/real recovery unrun. The
earlier OLD fixture failure remains preserved. C# cross-language test requires
RICE_CODEDB_RETAINED_EFFECTS_PROOF with the actual emitted context; Parent
confirmed it otherwise Assert.Ignore. Human acceptance must distinguish a skip
from an executed PASS. These later gates and overall S29 PARTIAL do not by
themselves establish a source implementation failure.

## Read-limit accounting and stop

The initial combined identity/status output and one REVIEW/snapshot/memory output
were emitted without aggregate UTF8 prechecks and may exceed6KiB/call. This
deviation is preserved; subsequent checks cannot retroactively cure it. Original
returned-byte total is a conservative near100KiB estimate, not a counted ledger.
Later selected reads were strict UTF8 decoded and bounded before output, with
oversized selections rejected rather than evidence truncated.

Parent added a20KiB directed tail in REVIEW:52-59 without resetting the original
ledger. Counted returned UTF8 for this tail was approximately19.5KiB including
the short directive and rejected-read diagnostics (a conservative700-byte
allowance covers the initial directive). The attempted final848-byte source
selection was rejected against remaining per-tail budget. An orchestration
TextEncoder reference error produced no source output and its selected read was
then correctly emitted once. No test was retried or executed.

Stopped at these declared limits. Findings and remaining evidence return once
to Parent/User; no autonomous repair, expanded audit or new gate follows.
