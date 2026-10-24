# S33 fresh current-version lifecycle acceptance

Date: 2026-10-18.
Status: FIRST_INSTALL_PASS / READY_OBSERVED / REOPEN_PASS / LOGICAL_UNINSTALL_PASS / REINSTALL_BLOCKED_HISTORY_BOUND.

## Objective and evidence boundary

Use the newly created `UnityFreshLifecycleValidationProjectS33` to establish
current-version first Install -> Ready -> reopen -> Uninstall -> reinstall ->
Ready. This is same-version lifecycle evidence, not cross-version upgrade or
historical recovery. S30 preserves its existing failure/pending history and is
not this normal-route baseline. S32 source/delivery/human results remain intact.

User agreed to a fresh baseline and reports S33 creation. That permits baseline
inspection and preparation; explicit Package-reference configuration authority
is requested below. No actual lifecycle action is authorized by this record.

User `已关闭，授权你继续接入` on 2026-10-18 explicitly approves the concrete
Package setup below. Parent rechecked no S33 Unity process/lock, unchanged
configuration hashes and the exact Package/ZIP. Complete this setup without
repeated stage permission. Actual lifecycle actions remain outside the grant.

## Attributable package

- Commit: `b0462ed07b6a14be64bddf848e67609d9143fa71`.
- Package: `.artifacts/s32-install-command-b0462ed/review/com.rice.ai-codedb`.
- Identity: `0.3.0-preview.5 / poc.43`, no generation transition or new export.
- ZIP SHA-256: `56fdfbe2f81fe5ff3f1ccce07c6bc7fdd65610a218450f4ead9a3afaa5500fae`.
- Read-only preparation confirmed all original 623 Package hashes still match
  the frozen candidate. The previously recorded extra Unity-generated test meta
  stays preserved; no claim that the imported directory has exactly 623 files.

## S33 initial read-only baseline

- Root: `<repository-root>/UnityFreshLifecycleValidationProjectS33`, no redirected
  ancestors observed; Unity version `2022.3.62f3`.
- No CodeDB dependency in Packages/manifest.json. AIWork and project-level
  `.codex/config.toml` absent at this checkpoint. No old project runtime copied.
- Manifest SHA-256: `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1`.
- Lock SHA-256: `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6`.
- S33 Editor and two attributable AssetImportWorker processes and Unity lock
  were present. Do not change references while open or terminate these processes.
- Exact Package lifecycle's NotIntegrated branch publishes NotIntegrated and
  returns without automatic Supervisor start. Package import is separate from
  explicit product Install; do not pre-create desired state or installed markers.

## Concrete Package setup proposal

After explicit grant and normal human close, recheck S33 process/lock and both
configuration hashes. If drift is attributable to normal Unity closing, inspect
only changed configuration before proceeding; no blanket restore.

1. Back up both Packages JSON files under fresh repository-local
   `.backups/s33-lifecycle-setup-b0462ed/`, verify hashes and preserve all originals.
2. Add only `com.rice.ai-codedb` to manifest dependencies and lock dependencies,
   using `file:../../.artifacts/s32-install-command-b0462ed/review/com.rice.ai-codedb`.
   Lock entry: depth 0, source local, empty dependencies, matching Package metadata.
3. Add only `com.rice.ai-codedb` to manifest testables, preserving other entries.
   Preserve all other project/dependency configuration and verify both references
   resolve to the existing exact Package. No source or extracted Package edits.
4. Return setup identity and initial human instructions: open S33, confirm compile
   and Manager NotIntegrated/Install availability, report baseline before Install.

No Install, Uninstall, Provider installation, runtime/config generation, process
control, Unity/MCP/BatchMode launch, commit, export, push or publication is included
in this setup proposal. User owns Unity opening and lifecycle clicks.

## Subsequent bounded acceptance stages

| Stage | Required observations |
| --- | --- |
| First explicit Install | One confirmed action, authentic successful command result, independent Ready observation |
| Reopen | Manager and normal Unity reopen preserve the installed state and normal behavior |
| Explicit Uninstall | One confirmed action, authentic successful uninstall, product logically uninstalled with relevant execution safely closed |
| Same-version reinstall | One confirmed Install after normal uninstall, authentic successful result and independent Ready |

Align/authorize each real action before execution; never turn open/import/report
into permission for a real mutation. Retained content need not be physically
deleted to pass logical uninstall. Do not kill a bare PID, erase operation history
or repeat a failed action to manufacture success.

On failure preserve the first evidence and stop the dependent route. Separate
product, external-environment and baseline causes. No automatic source repair,
Provider/model acquisition, historical migration or isolation reconstruction.
Repeated blockage or broader authority returns for discussion under existing
workflow limits. Previously deferred CleanupMono observations stay deferred.

## Handoff

Setup and initial human baseline passed; see SETUP-RESULT.md and
INITIAL-HUMAN-RESULT.md. Authorized first Install now passed with actual complete
writer success and independent selected-instance readiness; see
FIRST-INSTALL-RESULT.md. Cleanup remains PENDING. Human Manager/tab/Unity reopen
observations now pass with non-blocking UX follow-ups; see REOPEN-HUMAN-RESULT.md.
Next: align one logical Uninstall using UNINSTALL-ACCEPTANCE-PROPOSAL.md, then
obtain explicit real-action approval. No real Uninstall, additional Install or
test batch is authorized by this handoff. The initial wording issue remains
a proposed FOLLOW-UP; no source fix or new subagent is started.

## First Install grant - 2026-10-18

User `同意，需要我直接点击 install 吗？` approves the immediately preceding
one-attempt first-Install proposal in INITIAL-HUMAN-RESULT.md. User may click
Install CodeDB once and confirm once in S33; normal product-owned project
runtime/config creation and managed process startup are included. Parent only
performs bounded read-only evidence checks after the human result. Observe actual
command outcome separately from Ready. Failure/unknown/new external prerequisite
stops the route; no repeat Install, dependency acquisition, state deletion,
Uninstall or reinstall. No agent Unity launch or process control is authorized.

## First Install consolidation - 2026-10-18

Human reports success/Ready. Bounded original receipt, selected-instance,
activation and operational-readiness evidence establishes first real Install
PASS on b0462ed / poc.43 in S33. No manual release or state repair occurred.
Remaining lifecycle gates: logical Uninstall and same-version reinstall. Cleanup
PENDING and point-in-time maintenance observations are recorded separately;
Ready grants no cleanup/process control or real Uninstall authority.

## Reopen consolidation - 2026-10-18

Human reports Manager close/reopen and tabs normal, Unity close/reopen normal,
and eventual Ready after Unity reopen. Reopen functional observations pass with
two UX issues: excessive diagnostic Console logs and prolonged unconfirmed
display when reopening Manager within the same Unity process. See
REOPEN-HUMAN-RESULT.md for bounded source diagnosis and proposed scope.
Current step is alignment only; no source repair or real Uninstall is granted.

User subsequently confirms both UX observations are non-blocking. Record them as
NON_BLOCKING FOLLOW-UP, with repair timing pending. Recommended next step is the
logical Uninstall acceptance envelope, followed by same-version reinstall on the
unchanged delivered baseline. Real actions still require the corresponding grant;
no source repair, export or reference switch is needed to continue this baseline.

## One-attempt Uninstall grant - 2026-10-18

User `同意授权` explicitly approves one human-confirmed Uninstall in S33 and
parent read-only follow-up under UNINSTALL-ACCEPTANCE-PROPOSAL.md. Pre-action
baseline checks show the expected installed instance/configuration and no
current-action index file. Human action/result is pending. No reinstall, retry,
source repair or manual runtime/process/state control is granted.

## Uninstall consolidation - 2026-10-19

The one authorized human Uninstall passed logically. Exact action
`bb9581b9872b419689da6eea91ff2ba8` and operation
`62fd5e331b76430983d23fd5611f9906` returned exit 0 and
`UNINSTALLED / COMPLETE / LOGICAL_UNINSTALL_COMPLETE`; see
UNINSTALL-RESULT.md. Desired state is UNINSTALLED and current instance selection
is absent. The warning is separately recorded as cleanup PENDING and queued
handoff (`selected_instance_changed`); no claim of physical cleanup or external
process retirement is made. Same-version reinstall remains a separate pending
gate and has not been run.

## Same-version reinstall proposal - 2026-10-19

The next gate is documented in REINSTALL-ACCEPTANCE-PROPOSAL.md. It is one
human-confirmed Install after the passed logical Uninstall, followed by exact
read-only terminal and Ready checks. No reinstall action is authorized yet;
cleanup, source repair, UX follow-ups and reference changes remain excluded.

## Reinstall failure consolidation - 2026-10-19

The one authorized same-version Install attempt failed in preflight; see
REINSTALL-RESULT.md. Exact action `3a9f458bf874431b80c32e9355d8a5b6` returned
exit 6 with `mutated_scopes=[]` and no candidate selection. The direct cause is
the S33 Supervisor operation-history count: 5301 records versus the delivered
Package's hard bound of 4096 in the Install preflight. Desired state remains
UNINSTALLED. Do not retry or delete/compact history yet; align a bounded,
identity-safe retention fix first.
