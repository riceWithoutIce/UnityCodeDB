# Proposed one-shot retained failed INSTALL disposition

2026-10-09. USER_AUTHORIZED_ONE_REAL_MUTATION_ATTEMPT. S29 PARTIAL.
User replied "好的 继续" to Parent's explicit request to execute this prepared
retained-effect recovery. This authorizes the single command and evidence checks
below; fresh Install remains a separately confirmed gate.
Execution completed once: native exit0 /33578ms; linked retained disposition
verified. See RETAINED-ORIGINAL-ROOT-RECOVERY-RESULT.md. No replay or fresh Install.
Authentic read-only preflight AVAILABLE, original8protected files unchanged.

Target only UnityFreshInstallValidationProjectS29; original failed INSTALL
f14c0524af324b7a802335a393483fa0, retained candidate
5a6ff71560234b558e1a42148b680a77, immutable generationpoc.40.
Use exact extracted Package from source commit12b3582, ZIP hash70105a5c...

Concrete command after authorization, repository working directory:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .artifacts/s29-original-root-poc42/review/com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1 -Action Uninstall -ProjectRoot G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29 -RetainedCandidateActionId f14c0524af324b7a802335a393483fa0 -ConfirmedProjectMutation
```

The engine revalidates original receipt/command/root identity, current effects,
holder/process proofs and next-change admission under the materializer lock.
For the currently unbound candidate, expected writes are a new failed-candidate
removal intent and operation journal, CodeDB-owned project deactivation/control
state (desired remains UNINSTALLED/PENDING), managed project MCP deactivation,
and a linked resolved-action disposition in the original Manager action index.
Existing original action/admitted/claim/terminal bytes, prior removal intent,
candidate data and immutable generations are preserved. Original command outcome
remains failed_or_unknown; the new proof records retained effects, not success.

No fresh Install, native readiness/workers, physical candidate/output deletion,
external process termination, OS/ACL/TEMP changes, global Codex config edits or
Unity launch. Capture stdout/stderr/native exit separately and compare protected
receipt/old-intent/candidate hashes, verify new intent/desired/disposition links.
Exactly one attempt; stop on first refusal/failure, retain evidence, no automatic
retry or automatic Install. Report the real disposition before proposing fresh
Install as a separate gate. Backend refusal remains authoritative if state drifts.
