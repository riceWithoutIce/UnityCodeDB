# S36 source disposition and delivery proposal

## Human source acceptance

On 2026-10-19 the user replied `同意 accept` to the consolidated S36 source
result and independent targeted review. Disposition: ACCEPT / SOURCE_ACCEPTED
WITH EXECUTION LIMITS. This is explicit source acceptance, not delivery or
real-environment acceptance.

Parent rechecked both accepted SHA-256 values against RESULT.md before recording
this decision; they match. HEAD remains
`d4a097d20af598ca760163867a3394ff5efb116d`; the index is empty. Coder and Verifier
are both complete. Their original terminal evidence records remain unchanged.

The source removes old-command/new-Bridge rebinding during preflight-only
refresh and rejects publication if the captured cache revision changed. Strict
identity/revision binding and Manager freshness policy remain unchanged.
Whitespace, syntax-only and targeted source-review evidence passed. Semantic
compilation, NUnit, actual preflight and real idle behavior remain DEFERRED.

## Authorized delivery group

User replied `同意授权` after the explicit delivery request and the verified
`s35 已经关闭` closure handoff. This authorizes exactly the following group,
with no repeated stage confirmation: exact local commit -> exact commit-derived export and
package checks -> S35 package-reference switch after human closes that project.

Authorized preparation check: existing focused Package path-provenance and
instance-helper binding gate passed on the working tree. This supplemental
delivery evidence does not replace the later exact-extraction check or add
semantic/NUnit execution claims.

Commit message: `fix: preserve lifecycle observation during preflight refresh`.
Exactly six paths, no unrelated dirty content or historical route records:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/TASK.md`
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/RESULT.md`
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/VERIFICATION.md`
- `.ai/tasks/v0.3.0/cdb-v0.3-p0-s36-preflight-refresh-observation-coherence/DECISION.md`

Before commit, recheck accepted source hashes, exact index allowlist, staged
bytes and diff checks. Use the existing exporter
`com.rice.ai-codedb/Tests~/export-codedb-package.ps1` with the resulting exact
commit, not dirty working-tree inputs. Derive a fresh output root
`.artifacts/s36-preflight-refresh-<commit-short>/`, with ZIP and consumer
`review/com.rice.ai-codedb` extraction beneath it. Preserve the existing S34
artifact and every prior evidence directory.

Run only existing required export/admission, byte/identity/native-binding and
path-provenance checks appropriate to the artifact. This C#-only change has no
serialized record or immutable generation transition. Do not manufacture new
semantic evidence, run broad regression or silently regenerate dirty payloads.
Stop the dependent delivery on a failed gate or source/identity mismatch and
report its original evidence.

Target project remains `.artifacts/unity-projects/s35/` (Unity 2022.3.62f3).
Before switching, require the human closure handoff and read-only project process/
lock checks. Back up and hash-check its original `Packages/manifest.json` and
`Packages/packages-lock.json` under a fresh repository-local `.backups/` child.
Change only the CodeDB local package reference in those two files to the new
verified extraction; preserve testables and every unrelated byte. Recompute
the relative reference from the actual Packages root and verify both consumers
resolve to the same extraction. Do not rewrite runtime/config/installed state.

No Unity launch, Test Runner execution, Install/Uninstall/reinstall, process
termination, push or publication is proposed in this delivery group. Subsequent
human acceptance should cover compilation, the focused S36 regression tests,
Manager reopen/tabs and an idle interval exceeding the 120-second preflight
refresh period. Its result and existing freshness expiry remain separate from
syntax/source review. S35's pending lifecycle sequence requires a fresh handoff
that accounts for the changed delivered package; do not silently extend its
original same-S34-artifact grant.

## Handoff

## Corrected delivery authorization

The prior artifact failed human compilation because its test used an NUnit
attribute absent from S35's actual consumer DLL. The approved one-line repair
was independently reviewed and closed the original finding. User now replied
`授权` to the renewed delivery request. Treat this as authorization for the
corrected snapshot only: one exact local commit, exact commit-derived export
and checks, then replacement of the closed S35 Package reference. It does not
authorize Unity launch, Test Runner execution, Install/Uninstall/reinstall,
process control, push or publication. The prior failed artifact and evidence
remain protected.

- Corrected test SHA-256:
  `3a2d379799924e62bd482b28f369d61f2e0915ea06d0d4482b979e5e67b87d2f`.
- Production SHA-256 remains:
  `07594a7b236465e26ca91ab2832b9c82d694728a64a3004dac5144d2c0f691a6`.
- New commit message: `fix: use supported NUnit parallel attribute`.
- Exact new commit allowlist: the corrected test file and this task's six
  records (`TASK.md`, `RESULT.md`, `VERIFICATION.md`, `DECISION.md`,
  `DELIVERY-RESULT.md`); no production source or unrelated dirty path.
- After export, use a fresh output root under
  `.artifacts/s36-preflight-refresh-<new-commit-short>/`. Back up the current
  S35 manifest/lock under a new repository-local `.backups/` child and replace
  only their existing S36 reference with the new exact extraction.
- Recheck S35 closure immediately before switching. If Unity is open or a lock
  is present, stop and hand the closure prerequisite back to the user; do not
  terminate it.

Human closure handoff received: `s35 已经关闭`. Parent read-only checks found
zero attributed S35 Unity processes, no `Temp/UnityLockfile` and no
`Library/EditorInstance.json`. Accepted source/test hashes still match, and
the index remains empty. This establishes the closure prerequisite at the
check time; recheck it immediately before a future reference switch. The reply
confirms project closure; explicit authorization for the proposed delivery
group was still pending at that earlier closure check. The subsequent explicit
`同意授权` grants the group above; execution starts after recording this grant.

- Current task: S36 source repair.
- Current status: SOURCE_ACCEPTED_WITH_EXECUTION_LIMITS / CORRECTED_DELIVERY_AUTHORIZED.
- Next notification: current parent, for the corrected exact commit/export and
  closed-S35 reference switch.
- Next action: execute the renewed corrected delivery group and then hand back
  the human compile/focused-test/idle checklist.
- Human authorization required: none inside this corrected delivery group;
  real Unity and lifecycle commands remain outside it.
