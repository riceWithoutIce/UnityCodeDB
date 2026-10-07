# S29 Instance Manifest Closure - Frozen Targeted Review

Date: 2026-10-07. Status: AUTHORIZED / REVIEW_ONLY / SOURCE_WINDOW_CLOSED.
Mode: FAST_SUBAGENT / TASK_SPECIFIC, depth one, one independent child Verifier.
The Coder has terminated; all implementation/test writes are stopped.
This reviews the already authorized repair, not a new whole-product audit.

## Stable Inputs

All paths below are repository-relative to G:\RiceProgram\UnityCodeDB.
Task directory: .ai/tasks/v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path.

- Branch: codex/v0.3.0-legacy-workflow.
- HEAD: 70f33f7e9f7b39b63aaf9c1d4eedba122f67799a.
- Package: 0.3.0-preview.5; successor generation: poc.40; sequence: 40.
- INSTANCE-MANIFEST-CLOSURE-PLAN.md: 9648 bytes; SHA256
  bcd26679b6f5748d1af47fdf375928cd6686ea2cad5c554c23db80265da7323a.
- INSTANCE-MANIFEST-CLOSURE-RESULT.md: 12606 bytes; SHA256
  3ae1709e4e57200adb5a196115335852868d45ac78059a0e8ee6f31cb64b5c3a.
- INSTANCE-MANIFEST-CLOSURE-IDENTITY.txt: 5656 bytes; 39 ordinally sorted
  path/TAB/lowercase-SHA256 rows, UTF-8 without BOM, LF with final LF; SHA256
  c4a1cfe61877dfce0bd81759840f4b64fd08d1c987b5e9bb76ea1b13be4dba0d.
- Protected generations excluding poc.40: 332 regular files; aggregate
  502bf6d2e3bbc697ed1d5927deb16274cbbb6ecb76c729b6838af71217c32dc9.
  Algorithm remains generation-relative ordinal rows/TAB/lowercase-SHA256,
  joined by LF with final LF. Do not emit the entire old-generation table.

Read this packet, the full bounded plan and result, and the compact identity.
Read the named Instance Manifest Contract And Consumer Closure section in
com.rice.ai-codedb/Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md
and the Record Contract Consumer Closure Gate in development-workflow.md.
Do not read the whole TASK, historical result/review corpus, logs, or Codex
session records. Use bounded definitions/callers/diffs for source inspection.

## Original Gap And Review Claims

Original normal Install failed because the production writer emitted an object
originating_action but real Host/Node instance readers borrowed flat Provider
decoders, and PS context still required exactly the old 17 fields.

Review only that gap and its nearest regressions:

1. Production writer and atomic serializer bytes reach the actual poc.40 PS
   reader/context and the canonical/generated Node decoder; no fixture seam
   replaces those decoding or field-admission boundaries.
2. Origin is missing/null or exactly action/action_id/operation_id; action is
   INSTALL/UPGRADE/REINSTALL and both IDs are lowercase 32-hex strings. Strict
   parsing/rejection remains; origin grants no ownership, selection, readiness,
   adoption, cleanup or next-change permission.
3. Both PS decoding and context-field admission are closed. Demonstrated shared
   caller bindings include prepare, adapter, verify and watch failure/cleanup.
   The Node worker and stable front door unconditionally use the tested decoder.
   Existing other direct readers are inventoried, not silently omitted.
4. C# projections and Provider contracts/range remain unchanged. Pure shared
   helper projections and the original four PS parsing bodies are consistent.
   Preserve existing state/path/no-reparse/identity/hash/effect checks.
5. The existing canonical successor route admits poc.40 once, preserves old
   generations and eight historical transitions, and derives all coupled
   identity/helper-copy/hash/fixture projections from that input.
6. Declared evidence corresponds to this identity and supports only the claims
   below; no inference of real-project recovery, extracted-artifact closure,
   Unity/runtime or release acceptance.

Attributable Coder evidence to reuse, without rerunning:

- Static: PS 10 / Node 5; 14 PS callers; shared helper/projection bindings.
- InstanceManifestContractOnly: PS 45; Node 26 byte cases / 52 decodes; one
  test-owned Node runner, zero service children.
- FirstInstallAttributionOnly: 26; NextChangeAdmissionIntegrationOnly: 45;
  both first-attempt PASS with zero native children.
- PathProvenanceOnly: PASS; source-candidate byte closure: 52 / 0 mismatch.
- Scoped diff-check and old-generation/history protection: PASS.

Coder reports the early output/cumulative guard breach explicitly. One semantic
and two mechanical L0 corrections are retained; this is not a claim of prior
budget compliance. Parent admission independently matched all 39 source hashes,
HEAD, scope, plan/result identities, protected C#/Provider and the 332-file hash.
Parent corrected one non-side-effecting BOM check command: culture-sensitive
StartsWith treated U+FEFF as ignorable; ordinal comparison matched the actual
63-6f-6d prefix (no BOM). No record/source bytes or tests changed in admission.

## Execution And Stop Boundaries

Active review budget: 30 minutes from dispatch; V2_DEFAULT output guards apply.
One targeted read-only review. Admit frozen identity before semantic review and
recheck it at handoff. On drift or an unresolvable scope/budget gate, record
BLOCKED and stop; never repair or invent substitute evidence.

Implementation/test/source paths are read-only. The only writable output is
INSTANCE-MANIFEST-CLOSURE-VERIFICATION.md in the task directory (<=16 KiB).
Use apply_patch. No grandchildren or Coder/durable-thread contact.
No test or parser replay, generator invocation, service/script execution,
Unity/MCP/CUA/BatchMode, process probe/start/termination, real project/runtime
read, candidate reconciliation/cleanup, artifact/config changes, commit,
export, push or publication. The real PENDING candidate remains protected.

Return findings once to Planner/User. Use the agreed blocker threshold: normal
user flow unavailable, data/config corruption risk, external-process safety,
or a missing key frozen release promise. Theory/rare race/style/new demand is
FOLLOW-UP, not a reason to expand this review. Do not dispatch fixes.
Even PASS closes only this bounded source review; whole S29, human Install /
Ready / Uninstall / Reinstall / shutdown and delivery gates remain unresolved.
