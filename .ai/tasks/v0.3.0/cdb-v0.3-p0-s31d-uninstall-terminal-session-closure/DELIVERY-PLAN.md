# S31-D Precise Delivery Proposal — 2026-10-17

Status: SOURCE ACCEPTED / GROUP DELIVERY COMPLETE / HUMAN UNITY PENDING.

Delivery executed as recorded in DELIVERY-RESULT.md; HUMAN-CHECKLIST.md is the
current route. The proposal and initial observations below remain historical.

## Explicit User Grant — 2026-10-17

User `同意 accept` and `授权 后续任务 精确提交 → 出包核对 → S30 工程引用切换`
accept the candidate below and authorize the complete bounded delivery group.
No repeated stage approval is required. Recheck S30 closure immediately before
switching; if it is open, defer only that switch. Real lifecycle operations,
runtime reconciliation, Unity launch, process control, push and publication
remain excluded. Earlier pending wording below is preparation history.

User `ok 继续` after the final F1 review authorizes continuation into delivery
preparation. No commit/export/reference-switch authority is inferred. The final
reviewed source and the task-only projection below are ready for a combined
source acceptance and bounded delivery grant.

## Concrete Candidate

- Base HEAD: `cc49c95e84945308385f64640963716d93d070ea`.
- Candidate: `.artifacts/tests/s31d-delivery-preparation-a/candidate/com.rice.ai-codedb`.
- Package identity: `0.3.0-preview.5 / poc.43`; no generation transition.
- 619 candidate files; all non-task files match the committed base.
- Exactly ten task files, relative to the Package:
  - `Editor/AICodedbSupervisorBridge.cs`
  - `Editor/AICodedbSupervisorTerminalEvidence.cs` and `.meta` (new)
  - `Editor/AICodedbManagerWindow.cs`
  - `Editor/AICodedbProcessRunner.cs` (task-only command-result projection)
  - `Tools~/codedb-project-supervisor.mjs`
  - `Tests/Editor/AICodedbEditorLifecycleTests.cs`
  - `Tests/Editor/AICodedbManagerUiTests.cs`
  - `Tests~/test-codedb-project-supervisor.mjs`
  - `Documentation~/v0.3.0-p0-host-action-execution.md` (task-only append)

The other eight files match the final F1 working-file hashes exactly.
ProcessRunner candidate SHA-256 is
`3c2f89000ea8e98130c06349b5fdbca1517dd05f704dee82eff186d80266f8f3`:
reviewed command-result types plus the HEAD runner body. A direct candidate/
worktree comparison confirms that only the three incoming timeout hunks are
excluded. Working-file content is preserved.

Contract candidate SHA-256 is
`b76723f040cd0c493a259e290293356103c32bf8bba3d86ed0e7b0493bd3675e`:
HEAD text plus the reviewed dated S31-D/F1 append. Earlier dirty historical
documentation sections are excluded and remain in the working file.

Dirty Payload selects poc.42 and removes committed poc.43 content. None of that
dirty Payload, the incoming runner timeout work, OwnerIdentityV2Status, runtime
PowerShell, unrelated docs/project state, or task raw artifacts belongs in this
commit or export. Do not export the working tree.

## Preparation Evidence

`prepare-delivery-candidate.ps1` constructs only a local source candidate; it
does not stage, commit, export a distributable Package, or switch references.
Driver SHA-256:
`f8b4f36222f5a5c34716ebbf7e2bea83036b058350e80ae1ef9afc5109eb5508`.

- PASS: exact candidate original Editor and Editor-test compilation, same
  three existing warnings, no new errors/warnings.
- PASS: candidate `test-codedb-package-boundary.ps1 -PathProvenanceOnly`;
  helper projections/decoding/caller bindings also passed.
- Candidate manifest SHA-256:
  `adc1df0f26eb0f69f4e6094152e072b4c842f64ae42e742b13d5bed9c48da954`.
- No full suite, Unity/native UI, real operation or unchanged semantic-test
  replay was performed during preparation. Exact extracted-artifact contract
  evidence is still required below; compilation does not substitute for it.

## Proposed Group Authorization

Accept the F1-reviewed task changes with the two exact projections above and
authorize these delivery actions together:

1. Recheck source/candidate hashes, unchanged base and empty/unrelated index
   ownership. Stage only these ten candidate files, preserving working-file
   dirty hunks; commit message:
   `fix: close uninstall actions from bound terminals and retain handoff warnings`.
   No blanket staging, cleaning, source overwrite or task-record sweep.
2. Use the existing `Tests~/export-codedb-package.ps1` against only the new
   frozen commit, with a fresh
   `.artifacts/s31d-uninstall-terminal-<commit-prefix>/` output. Verify commit
   and exact extracted ZIP byte/hash closure, production read-only payload
   admission/native binding, the ten candidate hashes and path provenance.
   Preserve earlier packages and failure evidence.
3. Reuse the existing task-local focused evidence route on that exact extracted
   Package for changed record producer -> real reader -> normal/reopen Manager
   -> exact journal release and F1 adjacent cases. Resolve source inputs from
   the extracted root, not the dirty checkout; fresh repository-local outputs,
   no Provider/model/new environment or full suite. Keep semantic closure and
   Package byte closure separate. Candidate/source PASS alone is insufficient.
4. After closure passes and the human has closed S30, recheck project process/
   lock ownership. Back up only S30 `Packages/manifest.json` and
   `Packages/packages-lock.json` under a fresh
   `.backups/s31d-uninstall-terminal-<commit-prefix>/` root. Change only their
   CodeDB reference to the new exact extraction; preserve `testables` and all
   unrelated fields. Verify both references agree and all other fields remain.
5. Return exact artifact/reference identity and a focused human checklist.
   Human Unity opening/tests/Manager behavior remain human-owned. No agent
   launches Unity or substitutes automation.

Stop dependent delivery if candidate/commit identity, closure or contract
evidence fails. Do not repair unrelated source, regenerate Payload, fall back
to dirty bytes or substitute another project. If S30 is open, defer only the
reference switch until the human closes it; never terminate Unity.

## Consumer And Preserved Runtime Boundary

Target is `<repository-root>/UnityFreshLifecycleValidationProjectS30`.
Manifest and lock currently agree on
`.artifacts/s31c-uninstall-entry-cc49c95/review/com.rice.ai-codedb` and testables
includes CodeDB. Current hashes:

- manifest.json: `525158f4699754f59848add163365b65401daf64c5f29e6527f08be0dfc8e75b`
- packages-lock.json: `67fe15f44147943c741b6598207f5345a71d8569bf3821d130fb047a3093296d`

Read-only preparation observed a Unity process attributable to S30 and its
Temp/UnityLockfile. This is point-in-time evidence; actual switching requires
a fresh closed/ownership check and the human's close handoff.

This delivery does not reconcile the preserved old S30 action. Its missing
binding/completeness fields remain a declared limit. Human validation must not
expect that old action to auto-unlock or click Install/Uninstall to manufacture
evidence. Any existing-action reconciliation/new real lifecycle attempt needs
a separate bounded User decision. No process control, runtime/config cleanup,
real Install/Uninstall, push or publication is included in this proposal.

Current task: S31-D precise delivery
Current status: COMPLETE / EXACT PACKAGE AND SEMANTIC GATES PASS / S30 SWITCHED
Next notification: User/current parent Planner
Next action: human Unity acceptance using HUMAN-CHECKLIST.md
Human decision required: human Unity result; real operation and release gates
remain separate
