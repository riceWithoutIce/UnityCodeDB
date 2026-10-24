# S29 Human Golden-Path Checklist

Status: PREPARATION_COMPLETE / AWAITING_HUMAN_AUTHORIZATION.
Stage A's exact extracted-Package closure passed on 2026-10-05. Only preparation
has been authorized/executed; project creation/open/import, real actions and
client/runtime evidence remain NOT_AUTHORIZED until a separate human grant.
Do not begin the session below merely because the Package is prepared.

## Preparation Handoff Fields

- Confirmed new-project directory:
  `G:\RiceProgram\UnityCodeDB\UnityFreshInstallValidationProject`.
- Candidate source: `91a295b28969c8a0d0dc66b6c19581fcdc9f7f5f`.
- Planning/admission document HEAD: `b15292f8978272244e605805a9ec064049141ee2`;
  this is not the candidate source. Planner's scoped admission was reused.
- Expected Package/generation: `com.rice.ai-codedb 0.3.0-preview.5` / `poc.39`;
  confirmed against the extracted canonical Package/payload/pointer contract.
- Expected ZIP SHA-256:
  `ca72ef948caddf7cffbe11a659d2a0dd9fec703cbd5cb695b50ef5a986123086`.
- Admitted reviewed ZIP:
  `G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s28-phase-c-91a295b/com.rice.ai-codedb.zip`.
- Absolute consumed `package.json` (the exact Add package from disk selection):
  `G:/RiceProgram/UnityCodeDB/.artifacts/0.3.0-preview.5-s29-fresh-project-91a295b/package/com.rice.ai-codedb/package.json`.
- Its SHA-256: `fcb67de746dd681b4194ac2003a867a7be69079d9027fe81a4743b475352402a`.
- Whole extracted Package identity: 482 files; sorted ordinal Package-relative
  path + space + lowercase file SHA-256, UTF-8 LF/no-final-LF digest
  `14eed019184e48e3f8b13f26231380c212f397326169e6f7c9cf0a44878ca293`.
  All 482 Git blobs match the source commit and all extracted bytes match ZIP;
  post-closure digest unchanged. No repair, export or generation transition.
- Exact extracted closure: PASS, source_count=46, mismatch_count=0; one initial
  invocation, no semantic retry. 22 generation file hashes and all 46 runtime
  targets cross-bound (22 flat / 23 generation / 1 pointer).
- Runtime contract SHA-256:
  `df329facd024dd45b8753cff921cf340543e31798be5a485f99421e523402303`.
- Generation manifest SHA-256:
  `b634d66584c84f4855fb4b29a1c16f9ecc6898cca670258454d9c9c12d794666`.
- Host-current SHA-256:
  `9f5b72e8ee2992e69172c9f4727d578f5a9ec35e8bab61b084ed1ee281f0612b`.
- Source/focused and human S28PhaseC 25/25 evidence are REUSED, not fresh S29
  Unity/compile/integration evidence. Path provenance: NOT_APPLICABLE; no Package
  bytes changed. Detailed commands, correction and limits: [RESULT.md](RESULT.md).
- Actual Unity Editor version: PENDING human selection within declared support.
  Declared support line is Unity 2022.3; no agent Editor discovery or launch.
- Human action budget: initial Install 1; confirmed Remove Integration 1;
  subsequent Install/Reinstall 1. No action replay after failure or unknown.
- Optional external client evidence: at most one human reconnect/new task at
  the end; not a prerequisite for every transition.

## One Session After Preparation And Authorization

| Stage | Human action | Evidence and exit condition |
| --- | --- | --- |
| 1. Fresh entry | Create the confirmed directory as a genuinely new Unity project through Unity Hub; open it. Import the exact local `package.json` via Package Manager's add-from-disk action. | Record actual Editor and imported path/version; compile finishes with zero C# errors. No copied runtime or previous integration. |
| 2. Initial Install | Open CodeDB Manager. Capture the no-integration state and eligibility. Invoke Install CodeDB once under its ordinary confirmation. | Record exact command/action result and attributable Ready, with project/Package/instance/activation/registration binding. Exit 0 alone is insufficient. |
| 3. Read-only usability | Allow Ready to settle; switch Manager tabs, repaint and close/reopen Manager without clicking maintenance actions. | No unsolicited Install/Remove or repeated action; UI remains responsive. Keep a screenshot and relevant terminal fields, not whole logs. |
| 4. Remove project integration | Choose Remove CodeDB Integration once. Review the exact owned scope and explicitly confirm it. Do not remove the UPM Package. | Authenticated Uninstalled; active selection/Supervisor/managed registration deactivated. COMPLETE or authenticated inert PENDING is acceptable. Preserve unrelated content/keys and shared prerequisites. |
| 5. Fresh reinstall | Only after the authenticated logical terminal state, invoke Install/Reinstall once as offered by the Manager. | New committed activation/journal and restored stable project entry/wrapper bind to the new current instance. Ready passes again; old activation is not relabelled or reused. |
| 6. Optional client exposure | If separately authorized, use at most one human-controlled reconnect/new task rooted in this new project. Keep the Planner task unchanged. | Distinguish actual new-project tools/status/one bounded read-only query from Package-owned availability. If absent/unrun, record DEFERRED rather than Ready-derived PASS. |
| 7. Exit | Close Manager normally; exit Unity normally once. | Record responsiveness and actual exit duration/anomalies. The agent does not stop Unity, clients, or processes. |

Observe each transition for at most 300 seconds. A terminal failure, unknown
receipt, missing expected action or timeout stops subsequent mutations. Report
the stage and exact message; do not retry Configure/Install, delete state,
change Package, restart Windows, or repeatedly reopen Unity to force success.
Mechanical errors in a pre-effect evidence command do not consume action runs.

The genuinely fresh first Install uses ordinary no-integration admission; do
not fabricate a previous removal intent or copy old-project state. If the
expected action is unavailable, stop on this S29 card. Missing Node/Provider or
another prerequisite also stops the session; no dependency installation,
repeated Configure clicks or global configuration repair is granted.

The Coder may inspect only TASK's new-project/action-bound evidence closure.
Human screenshots support presentation evidence; the required activation,
registration and removal bindings cannot be inferred from a screenshot alone.
If a binding cannot be proved without extra authority, record that gap and
return for same-card reassessment instead of improvising a probe.

## Meaning Of Removal And Ready

- Removal is of CodeDB's project integration: managed selection, activation,
  registration and runtime authority under authenticated ownership rules.
  It is not Package removal, shared Provider/Node uninstall or global cleanup.
- Physical retained content may remain PENDING when proven inert and bound to
  removal intent. No recursive deletion or waiting for all holders to exit is
  added to the normal reinstall path; ambiguous active state still blocks it.
- Ready is a fresh attributable current-product result, independent of old
  command history. Removal/reinstall require their own backend admission.
- New-project success says nothing about the deferred old validation project.

## Compact Human Return

Report each completed stage with its screenshot/terminal text and any action
ID visible. Mark unreached stages NOT RUN. The Coder will append a concise
artifact/project-bound outcome to RESULT; no test/Ready/receipt is fabricated.

```text
Project / Editor / imported package.json:
C# compile: zero errors / exact failure
Initial Install: action/result + Ready evidence
Manager tabs/repaint/closure:
Remove: action/result + Uninstalled / cleanup state
Preservation and registration/activation evidence:
Reinstall: action/result + new activation + Ready evidence
Optional client exposure: PASS / FAIL / DEFERRED
Normal Unity exit: duration / anomalies
Unreached stages and blockers:
```

No full EditMode or repeated S28PhaseC test batch is requested: the exact
candidate's accepted focused evidence is reused. A real failure remains on
S29; any necessary code/scope expansion is a separate same-card decision.
