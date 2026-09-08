# Decision: cdb-v0.3-p0-s09-validation-project-package-reference

Status: ACCEPT

## Disposition

- Human decision: ACCEPT the frozen S09 validation-project Package-reference
  correction after Coder completion, Planner review, report-only FIX 01, and
  GUARDED targeted verification.
- Decision date: 2026-09-07.
- Accepted HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Accepted files and identities:
  - `UnityValidationProject/Packages/manifest.json`:
    `2fd3f7756881d98b1e5aaa8b8d9b46602a11e9b2c259214d6b19e2135f8234bd`;
  - `UnityValidationProject/Packages/packages-lock.json`:
    `6e3b066fc707fda65ee3c24ec0b7f0eaf53190ed2a85fdb465deebd76cf38913`.
- Accepted S08 combined patch identity remains
  `aae922016172611d6742e7d878cf1d9e6378c617`.
- Accepted evidence: static L0 `1/1 PASS`, retry `0/0`, scoped
  `git diff --check` PASS, and Verifier `PASS / NO NEW FINDINGS`.
- The original report sanitization finding is closed by FIX 01; task records
  use repository-relative paths.

## Accepted Boundary

- Both tracked dependency records now use the exact local Package reference
  `file:../../com.rice.ai-codedb`.
- Static resolution from `UnityValidationProject/Packages/` reaches the
  repository Package whose identity is `com.rice.ai-codedb`.
- The accepted change is limited to the two declared dependency values; no
  other JSON field, Package source, S08 behavior, or process state is accepted
  as changed by this task.

## Deferred Boundaries

- Actual Unity Package Manager resolution, package import, C# compilation, and
  affected focused EditMode remain `DEFERRED` for a separately authorized task.
- Fresh full EditMode, PlayMode, cold start, Domain Reload, real
  Manager/Supervisor/Codex/MCP, consumer/third-party Package, release,
  publication, and deployment remain separate gates.
- This decision does not authorize Unity, Unity MCP, commit, push, publication,
  or release activity.

## Handoff

Current task: cdb-v0.3-p0-s09-validation-project-package-reference
Current status: ACCEPTED
Next notification: UnityCodeDB v0.3 Planner / Human
Next action: align and freeze a separate focused Unity EditMode task using
`UnityValidationProject/`; the first authorized Unity run should jointly verify
Package resolution, C# compilation, and the directly affected EditMode filter.
Human decision or authorization required: next-task creation and explicit Unity
process authorization; commit remains a separate optional human decision.
