# S29 declared Adapter output retention - Coder result

2026-10-09. IMPLEMENTED / STABLE_SNAPSHOT / INDEPENDENT_REVIEW_PENDING.
Base HEAD: 2c85c37f25c2c4a8c1f40235ce60ce4cfd32c7ce.
Scope: RETAINED-ADAPTER-OUTPUT-TASK.md. S29 remains PARTIAL.

## Implementation and consumer evidence map

- Added side-effect-free `Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1`.
  It owns Adapter root, logs/tmp subtree declarations and retention-only meaning.
  It performs no filesystem/process work on import. A file must be a descendant
  of a declared directory, not substitute for the tree root.
- Flat common and successor common import the same declaration bytes, bind
  context paths from it and use the existing production initializer. The
  text-adapter build algorithm/other contracts are unchanged.
- Materializer audits both new shared payload targets and imports the Package
  declaration by the existing shared-contract route. Engine consumes it only
  for failed-preparation inventory, with generated artifact checks unchanged.
- Ordinary nonempty nested outputs are preserved without parsing their content
  or demanding an Adapter result manifest. Outside-tree refusal names the
  relative path; no-reparse refusal names the affected retained path.
- Existing action/candidate/generation checks, process/holder checks, v2
  inventory512 / intent128KiB and intent snapshot revalidation remain. No
  physical deletion route was widened. Original failed/unknown result and
  cleanup PENDING remain after the synthetic retained Uninstall.
- Normal new generation poc.42 was produced by one ignored mechanical route,
  `.artifacts/tests/s29-adapter/project-successor.ps1`, for generation manifest,
  pointer and payload projections. Sequence42 is defined only in that entry;
  consumers use manifest identity. Package0.3.0-preview.5/schema unchanged.

Allowed production/test changes: new declaration, flat common, materializer,
engine, actual entry harness, successor42's30 files, payload and pointer.
No C#/UI, old generation, actual project/receipt or external config edits.
The snapshot lists all37 raw source/projection paths, including the complete
new generation. RESULT is outside the source snapshot to avoid self-reference.

## Focused evidence

Windows PowerShell5.1.19041.6456; actual original on-disk materializer dispatch.
Only runner Win32_Process enumeration is synthetic. Ownership/hash/action/PID
decoders and process state/holder checks remain production functions. Existing
fixture helper uses frozen producer slug/template bytes; new topology invokes
both real flat and successor common context/initialization functions. Flat
legacy context is rebound to the fixture candidate before its real initializer;
successor uses its actual RICE_CODEDB_INSTANCE_ROOT binding.

Final source fixture `.artifacts/tests/s29-adapter/r-452cf2c7`:
37 assertions / 14 actual CLI invocations PASS; final-entry.log.

- Complete production-created empty logs/tmp: AVAILABLE, file+directory digest
  and receipt equality before/after.
- Nonempty nested ordinary opaque files: AVAILABLE, existing v2 retained intent
  contains exact paths/kinds/SHA256; confirmed synthetic retained Uninstall
  preserves effects, original history, links and PENDING outcome.
- Declared output without any Adapter manifest/files.jsonl/index.jsonl:
  AVAILABLE, read-only, original Install still failed/incomplete.
- New mutable subtree snapshot before refreshed intent: existing reader refuses
  `retained effect snapshot changed`, read-only.
- Unknown Adapter sibling directory: refuses with concrete relative path;
  a file replacing the declared tree root refuses with concrete path/cause.
- A junction inside a declared tree: refuses with reparse/path diagnostics;
  intent, receipts and empty redirect target unchanged. The junction is removed
  only as fixture teardown, with no traversal/deletion of its target.
- Existing unknown/tampered action, ambiguous relevant process, no confirmation,
  confirmed Reinstall refusal and confirmed retained Uninstall links all PASS.

Final source materializer ValidatePayload PASS60files:
runtime contract538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d;
final-admission.log. Final closure PASS60payload sources/29generation files,
identical declaration bytes, all387 prior-generation tracked files raw Git
bytes unchanged; final-closure.log. Predecessor41 manifest remains
c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec.
Scoped git diff --check passed (line-ending advisory only).

## Attempts and execution-limit disclosure

- Mechanical projection attempt1 failed PowerShell nested-array enumeration
  after writing only the new unaccepted generation/pointer; payload remained41.
  Preserved projection-attempt1.txt. One causal correction completed the same
  single route; no old generation or artifact overwritten.
- First entry proof PASS35/CLI13 (`attempt1.log`, r-b70718a4). Adjacent type
  boundary review found that a file at logs/tmp root should not count as a tree.
  Added descendant-only file classification and root-file refusal test, refreshed
  new42 hashes through the same route, then final proof PASS37/CLI14. No failed
  CLI scenario was blindly retried. First/final admission and closure logs kept.
- Initial combined read exceeded6KiB. Later an ignored-artifacts filename search
  used a malformed regex in a recursive pipeline; per-item errors produced
  enormous repeated diagnostic output (tool reported about2.2million raw tokens).
  Ended the agent-owned read-only search with Ctrl+C. Single-read/cumulative128KiB
  limits were breached; this window is NOT budget-compliant and reruns do not
  retroactively restore compliance. No actual project runtime/receipts were read
  or written. Parent notified, later reads narrowed to known files. Independent
  review must use fresh stable snapshot/limited evidence, not this search output.
- Test CLI waits retained120swarning/300sstop, no external process termination.

## Unrun gates and handoff

No broad old suites, C# compile/Unity/EditMode/real recovery/fresh Install/Ready,
exact exported-package admission, release or remote update. No commit/export,
Unity launch, actual project runtime/receipt access, process termination or
external MCP change. Parent owns delivery and authentic read-only preflight.
All source edits stopped after final evidence and raw snapshot; independent
read-only Verifier may review only the frozen gap and adjacent safety boundaries.
