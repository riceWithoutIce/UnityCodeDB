# v0.3 fixed candidate lifecycle acceptance

Date: 2026-10-26. Status: COMPLETE / HUMAN_CLOSE_REOPEN_PASS / BASELINE_STABLE_PASS.
Grant: user "ok 继续" after the proposed same-candidate close/reopen step.
Workflow: codedb-workflow-v2 revision 2.7. Same development session, no new chat,
agent or worktree. Paths relative to repository root or the already designated
external test root. Do not embed developer-machine paths in product/records.

## Current authorized slice

One human-owned normal close and reopen of existing external `CodedbTest_2`
with the unchanged delivered candidate. Record compilation and Manager readiness
without Install/Repair/Restart/Uninstall or forced process termination. This is
the first lifecycle slice, not authorization for every remaining golden-path
step. User owns the Unity Editor choice and project opening/closing.

Candidate commit: `11056964da1143955ed69a067361622799e3d6f2`.
Package tree: `0690f9fee09541da2d75df6878f53c0114869ce9`.
Package 0.3.0-preview.5; generation poc.44. Existing exported Package and source
hash manifest retained in the candidate-freeze-delivery-preparation task.
Source/export/delivery and bounded MCP status/query PASS; prior user result:
no compile errors and Manager Ready. Response identity attribution LIMITED.
F01 ordinary-use output snapshot PASS; none implies full lifecycle acceptance.

## Read-only start binding (confirmed this turn)

- Manifest/lock CodeDB reference both
  `file:../../Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`.
- Pointer SHA-256:
  `1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a`.
- Project-local registration SHA-256:
  `2d288afd9490ad2f51560f5a62658f12d2bb456326980e919b894035b3f0c2fd`.
- Fixed original probe SHA-256:
  `d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432`.

These are disk baseline values, not runtime-response identities. Preserve dirty
task records in the primary checkout and all isolation state. Do not switch a
Package or alter runtime state to make a check pass.

## Human procedure and stop rule

1. Normally close CodedbTest_2 and allow the Editor window to exit. If closing
   hangs or produces an error, stop and report; do not force-kill or reopen over
   a still-closing Editor. No precise manual duration measurement required.
2. Open that same project with the same previously used Unity Editor version.
   Do not change Package/configuration or invoke any Manager action.
3. After ordinary loading, report any compilation error and whether Manager
   returns to Ready. A transient startup state is recorded as a transition,
   not automatically classified as failure. If still unready after roughly
   three minutes, end observation and report current state without retries,
   refresh or repair. This is an observation bound, not a startup SLA.

One cycle only. No Play Mode/domain-reload trigger, additional MCP, observation
agent, log scan or install/uninstall experiment during this human procedure.
Any new error/drift stops the affected sequence for analysis, without replay.

## Records and follow-through

This task directory only: TASK.md and, after a real human result, RESULT.md.
No empty success receipt. After the report, one read-only check of the named
baseline files may establish their stability; no process/lease enumeration or
raw log collection automatically follows. Record human result separately from
disk stability and unrun MCP/response identity, shutdown ownership, performance
and release gates. No automated Unity action or independent reviewer claim.

Source changes, export/delivery, cleanup, commit/push, board updates, destructive
lifecycle steps and release are out of this slice. Active work STANDARD_30M;
one human cycle; two mechanical read/report corrections if needed. Human wait
is not a reason to start another scenario or claim a timed stability result.

Completion receipt is in RESULT.md; user reported a successful reopen with no
compilation errors and Manager Ready. The one permitted baseline reread passed.
No additional action is authorized by completion of this slice. Later
uninstall/fresh-install needs a separately concrete agreed sequence, preimages
and cleanup/retained-session handling; the historical exit-6 incident is context,
not authorization for retries or a new writer policy.
