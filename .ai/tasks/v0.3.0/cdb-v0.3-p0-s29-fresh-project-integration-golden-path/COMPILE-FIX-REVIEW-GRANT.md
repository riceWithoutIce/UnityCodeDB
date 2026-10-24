# S29 Targeted Compile-Fix Source Review - 2026-10-07

## Authority And Frozen Input

- Same S29 task; the direct human compile-repair -> targeted independent review
  grant is recorded in COMPILE-FIX-GRANT.md. Coder has stopped. This is the one
  already authorized <=15-minute review, not a new review round or release gate.
- Route: existing `v0.3.verifier.deep`, DURABLE_SESSION / REUSE_ONLY, current
  model/reasoning unchanged. No child, new/replacement thread or recursive work.
- Branch: `codex/v0.3.0-legacy-workflow`.
- Base/actual HEAD at Planner admission:
  `306f329b8f51f82695dccc5e8de67c6bcea5320e`.
- Stable Coder report: COMPILE-FIX-RESULT.md, 7577 bytes, SHA-256
  `9df5331acd2762796f9c781ef7765b8c2dc192cb56f8e31b108d093bbaf7e663`.
- Ordered three-path identity: COMPILE-FIX-IDENTITY.txt, 371 bytes, SHA-256
  `e81b9e86379b48b28e06feb07e73720cb37cf422e364016b1678cc5bd06c9c55`.
  Algorithm remains lowercase SHA-256 of each full file, double-space separator,
  repository-relative path, allowlist order, UTF-8 without BOM, final LF;
  canonical identity hashes those exact text bytes. Do not use patch-id.

Ordered source/test closure:

1. `com.rice.ai-codedb/Editor/AICodedbProjectIntegrationState.cs`
2. `com.rice.ai-codedb/Editor/AICodedbStrictJson.cs`
3. `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`

Planner independently admitted current source/receipt equality. Verifier still
performs one bounded identity/HEAD/branch admission before semantics; identity
drift stops the review, with no source repair or newer snapshot substitution.

## Only Review These Original Gaps And Direct Neighbors

1. The original CS1503 boundary: the three origin call sites pass IDictionary
   into GetRequiredString; its parameter and coupled private GetRequiredProperty
   now accept IDictionary. Verify source-level type compatibility and existing
   concrete Dictionary parser/callers; do not claim actual compiler execution.
2. Origin-validation invariants: absent/null readability, exact three fields,
   INSTALL/UPGRADE/REINSTALL, strict lowercase action/operation IDs. State source
   and existing origin tests were not changed. Verify no guard bypass, duplicated
   readers, overload/cast/dynamic/suppression or behavior weakening.
3. Direct JSON helper neighbors: missing/null/wrong-type/null-object rejection
   and existing required scalar/array/nullable callers of the private helper.
   Use bounded signature/body/call-site excerpts, not all 496 calls or an audit
   of every file in the directory. Inspect further only a proven direct impact.
4. Two new regression methods/five authored cases: non-Dictionary IDictionary,
   concrete ParseObject caller, and four rejection cases. Review assertion intent
   and directly necessary imports/API usage. These tests are authored, NOT RUN.

Reads: this short grant, the bounded Coder report and identity, the changed
three-path diff and relevant source ranges; direct protocol definition in
AICodedbSupervisorBridge.cs only if needed for the unchanged ID guard. The
original compile grant is available for authority, not a reason to dump the
96-KiB TASK or entire session/history/runtime. No app session transcript read,
machine/global config, Provider, process, project runtime or old candidate read.

## Reused Evidence, Budget And Report

- One targeted review batch, <=15 minutes. V2_DEFAULT output limits: 32 KiB/200
  lines per normal command, 16 KiB/50 matches per symbol/result read, cumulative
  128 KiB. Limit reads before capture. Pre-side-effect mechanical construction
  corrections follow the existing workflow allowance; no blind evidence rerun.
- Reuse Coder static/source and exact three-path diff-check receipts. No tests,
  C# compile, EditMode, backend L0/L1, Package closure/path-provenance/full suite,
  Unity/MCP/CUA/BatchMode, Install/Uninstall/reinstall or alternative validation.
- Only write this task's new COMPILE-FIX-VERIFICATION.md, <=8 KiB. Preserve all
  previous reports and inherited dirty/untracked source/state. TASK, grants,
  source/test files, consumer files, artifacts, metadata/generation and all
  other records are read-only. No commit/export/push/tag/publication/cleanup.
- Return one consolidated list of material findings, prioritized by the user
  review rules, or explicitly none. Do not add theoretical hardening/style/
  unapproved requirements as blockers or ask Coder for immediate changes.
- If the original source gap is closed and direct source neighbors have no
  material finding, stop with SCOPED_SOURCE_REVIEW_PASS. This is not C# compile,
  executed tests, Ready, S29 ACCEPT, runtime recovery or release PASS. Describe
  any output/evidence limitation separately instead of a fabricated product FAIL.
- On identity mismatch, unavailable evidence or exhaustion, write one bounded
  BLOCKED report and stop; no automatic replacement, retries/renewal or new audit.

## Handoff

- Current task: cdb-v0.3-p0-s29-fresh-project-integration-golden-path.
- Next notification: stable review result to Planner/User in this thread/records.
- Next action: User/Planner findings disposition. New delivery waits for explicit
  human authorization of the exact source commit and a unique frozen output.
- Human decision or authorization required: findings disposition, source commit,
  later human compile/test/integration retry and overall S29/release ACCEPT.
- Do not contact Coder or dispatch anything. Receiving this dispatch does not
  authorize a cross-thread reply; return your terminal result and stop.
