# S29 continuous real project-integration validation

2026-10-08. User explicitly authorized the aligned uninstall -> fresh Install
validation with "同意授权". This is one continuous grant with result checkpoints,
not separate permission requests for each successful step. Status: AUTHORIZED /
AWAITING_HUMAN_UNINSTALL_RESULT. Neither real action has been reported as executed.

## Exact target and baseline

- Project: G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29.
- Package: .artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb.
- Commit: d56f0e507b48af24a39f23411c06dbdd4e093084.
- ZIP SHA256: 869491b76cdf6e97c66f28f87e71b2bb3875aeae9c923bdfc81d80b531457d06.
- Source accepted and independently reviewed; human reports45tests passed,
  screenshots corroborate45/0 and original failed Install/PENDING presentation;
  tab switching and Manager close reported normal.
- Current project reference rechecked against this candidate. No current runtime
  preflight or removability is presumed from the visible button.

## Responsibilities and permitted sequence

Human operates Unity and confirmation dialogs. Planner records results and may
perform narrowly relevant read-only checks of this target's operation evidence
when needed. No agent UI control, Unity/MCP automation or shell substitute for the
human action. Keep the existing Unity session; no new project, Package removal,
test replay or routine Unity/Codex/Windows restart is required.

1. Open Manager Overview. Use the visible Uninstall CodeDB from Project action
   once. Its existing dialog confirms project integration removal and preservation
   scope; human confirms Uninstall CodeDB. Backend performs its normal ownership
   and live safety checks. Do not bypass refusal.
2. Checkpoint: retain full output, exit code, new action ID and final Manager
   presentation. Planner checks the authentic uninstall outcome and retained-effect
   meaning before proceeding. An authenticated UNINSTALLED/PENDING is acceptable
   only under the existing contract: old authority disabled, retained closure inert
   and bound, no ambiguity. A missing directory or exit zero alone is insufficient.
3. Only after that checkpoint satisfies the contract, human uses Install CodeDB
   once and confirms fresh project integration creation from the current Package.
   This action is already authorized; checkpoint review is not a new grant.
4. Checkpoint: retain install output/action ID and final Manager state. Verify new
   selection/activation and managed project configuration belong to the new
   integration, not the failed candidate. Separate successful command, product
   Ready/MCP availability and actual client tool exposure evidence.

The existing project-integration-reinstall contract owns exact mutation scope.
Preserve user files, unrelated configuration/MCP entries, UPM Package, machine
Node/Provider and external processes. Failed-preparation removal may retain the
old candidate/host closure inert with PENDING; no recursive deletion, historical
receipt rewrite, candidate adoption or automatic reclamation is authorized.

Stop at the first failure, ambiguous result, missing expected entry or unexpected
scope. Preserve evidence and report; no repeated click, automatic retry or broad
repair. This grant does not authorize source fixes or a second failed attempt.
Successful state progression within the sequence does not require reauthorization.

Project MCP uses its stable project entry/wrapper; do not change user-global Codex
configuration or stop/rebind external clients. First verify project configuration
and activation; only if actual client reload is needed, align one human-controlled
reconnect separately. No automatic session changes or Windows restart.

## First human checkpoint

Return the complete Copy output text and Manager final screenshot after uninstall.
Do not start Install until this result is checked. A retained historical failure
message alone is not proof that the new Uninstall failed; use its new action ID
and result. Overall S29 remains PARTIAL until the real sequence is evidenced.

## Execution checkpoint - 2026-10-08

Human Uninstall succeeded logically with PENDING cleanup. The subsequent single
authorized Install failed with incomplete execution/output observation. This
sequence is now stopped under its first-failure condition; it does not authorize
a repeated Install, another uninstall or effect cleanup. See
REAL-REINSTALL-VALIDATION-RESULT.md for both distinct action IDs and evidence.
