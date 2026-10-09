# Optional bootstrap test helper accessibility regression

2026-10-09. SCOPED_REGRESSION_IMPLEMENTATION_AUTHORIZED.
User reported CS0103 during the just-authorized repair's human compile gate.
Basebf7dd199f2dba0a56ce54e7e02cde9b59afcb378; index empty. Preserve dirty state.
Earlier optional-root runtime fix remains frozen and unchanged. S29 PARTIAL.

Observed AICodedbManagerUiTests.cs:1581 calls CreateDirectoryJunction from
AICodedbProjectSettingsTests. Existing helper at5432 is private in the separate
AICodedbHostPayloadMaterializerTests class. Same file does not grant visibility.
Roslyn syntax-only PASS did not include symbol binding, so it missed CS0103.

Allowed source edit only Tests/Editor/AICodedbManagerUiTests.cs: qualify new
call with existing owning test class and expose that existing helper internally.
Reuse one helper; no duplicate implementation, generic helper framework or
changes to process/runtime behavior. Existing helper callers remain unchanged.
No journal/PS/Payload/engine/package identity/real runtime/receipt changes.
Snapshot prior40rows must differ only this test source. No generation bump.

Coder result RETAINED-OPTIONAL-BOOTSTRAP-COMPILE-RESULT.md; ignored evidence
`.artifacts/tests/s29-optional-flat-compile/`. Complete the precise missing-name/
accessibility validation with Roslyn semantic compilation of the actual relevant
test call/class/helper if possible. Declaration-only dependency stubs may be used
for this isolated test-helper compilation, clearly attributed, but do not claim
Unity/complete assembly compile or consumer execution. Exact source spans should
be used, not a rewritten imitation. Verify helper accessibility and actual caller
binding. Do not invent full Unity substitutes or rerun unchanged41PS assertions.
Normal source/exact-package closure remains Parent delivery responsibility.
Freeze40rows and state limits precisely, including syntax versus binding.

Child edits then stops; independent read-only fix review only original compile
finding and adjacent retained root test change, no broader audit. No Unity launch,
real/project edits, process termination, commit/export/switch/remote or nested
agents. Human compile/EditMode remains unclosed. Parent standing pre-human
delivery authority persists; switch only after user closes S29.
Targeted reads <=6KiB, <=50matches, bounded output/log tails; no broad source scan.
