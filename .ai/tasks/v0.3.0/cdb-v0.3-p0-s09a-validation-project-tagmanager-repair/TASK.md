# Task: cdb-v0.3-p0-s09a-validation-project-tagmanager-repair

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.standard
- Verifier: none; human observation closes the runtime check
- Review mode: LIGHT
- Execution profile: v0.3.coder.standard
- Predecessor: `cdb-v0.3-p0-s09-validation-project-package-reference`
  (`ACCEPTED`; no commit is required as an execution prerequisite).

## Objective

- Repair the malformed canonical empty Layer entries in
  `UnityValidationProject/ProjectSettings/TagManager.asset` so the already-open
  Unity 2022.3.47f1 validation project can parse the file.

## Scope

- Allowed production/config file:
  - `UnityValidationProject/ProjectSettings/TagManager.asset`
- Allowed evidence file:
  - this task's `RESULT.md`
- Replace only the 27 bare empty Layer entries whose complete line is `  -`
  with the Unity 2022.3.47f1 template form `  - ` (one trailing space).
- Preserve every other byte and all unrelated tracked or untracked changes.
- Do not change Package references, Package code, tests, other ProjectSettings,
  workflow documents, or prior task records.
- Do not commit, push, stash, reset, clean, rebase, or amend.

## Admission

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.
- Initial file SHA-256:
  `df48c19726c2653a8041b3fd11cae352d0acf7ddd0a679cfa19eba2743a6871b`.
- The target file must be tracked and clean before editing. If its hash or
  scoped status differs, stop and report `BLOCKED`; do not reconcile it.
- The user intentionally has `UnityValidationProject/` open. That existing
  user-controlled Editor is expected and is not a stop condition for this exact
  repair. Do not start, stop, restart, attach to, automate, or otherwise control
  Unity or Unity MCP.

## Execution And Evidence

- Read this task once and perform one bounded admission check limited to HEAD,
  target-file hash, and target-file scoped status.
- Use `apply_patch` for the exact 27 line changes.
- Perform one static check that:
  - exactly 27 lines equal `  - `;
  - no line still equals bare `  -`;
  - the file still contains the expected `TagManager`, `layers`, and
    `m_SortingLayers` records.
- Record the final SHA-256 and target-file scoped status in `RESULT.md`.
- Do not run `git diff --check`: the official Unity serialization deliberately
  uses trailing spaces for these empty Layer scalars. Do not run a full diff,
  repository search, Unity test, EditMode, C# compile, Package Manager action,
  or any other test.
- Budget: one edit attempt, one static check, retry `0/0`.
- Runtime evidence is human-owned: the user will observe whether the existing
  Console parse error disappears. Coder must not poll or inspect the Editor.

## Definition Of Done

- The only config change is the exact canonicalization of 27 empty Layer lines.
- Static check passes and `RESULT.md` records bounded evidence and all `NOT RUN`
  boundaries without claiming Unity runtime success.
- Changes remain uncommitted.

## Handoff

- Current task: cdb-v0.3-p0-s09a-validation-project-tagmanager-repair
- Current status: READY
- Next notification: UnityCodeDB v0.3 Planner
- Next action: Planner asks the human to confirm the Console parse error has
  disappeared; only after that confirmation may S10 focused EditMode planning
  continue.
- Unity testing, Unity MCP, Verifier routing, commit, and push remain separately
  gated.
