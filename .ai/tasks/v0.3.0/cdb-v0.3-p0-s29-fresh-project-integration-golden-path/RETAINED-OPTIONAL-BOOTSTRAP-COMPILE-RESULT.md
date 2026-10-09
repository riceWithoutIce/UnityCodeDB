# Optional bootstrap test helper compile regression result

2026-10-09. CODER_COMPLETE / STABLE_FOR_SCOPED_FIX_REVIEW.
Basebf7dd199f2dba0a56ce54e7e02cde9b59afcb378; index empty.
Only Tests/Editor/AICodedbManagerUiTests.cs source changed, exactly two lines:

- Qualify the new call as
  AICodedbHostPayloadMaterializerTests.CreateDirectoryJunction.
- Expose its existing single helper as internal static instead of private static.

The helper body and existing callers are unchanged; no duplicate helper. Earlier
optional-root journal/PS fix and all other39 frozen rows remain byte unchanged.
No Unity/real project/runtime/receipt/process-control/commit/export/switch/remote
operation, nested agent, normal closure or unchanged41PS assertion rerun.

## Precise symbol evidence

`.artifacts/tests/s29-optional-flat-compile/binding/Program.cs` extracts the exact
actual invocation statement, original caller method/class declarations, owning
class declaration and complete original helper body from the source syntax tree.
It substitutes unrelated caller statements only with two declaration-only string
locals. NUnit declarations are narrow stubs (Assert/Is/TestAttribute) for compile
resolution only. BCL references use the installed .NET runtime reference set.
Neither compiled consumer nor helper is executed. This is a scoped semantic
compilation and caller-binding proof, not Unity or full test-assembly compilation.

Actual results, binding-attempt-2.log:

- Baseline source from exact base commit:1 semantic error, CS0103 reproduced.
- Repaired extracted call/helper/classes:0 semantic errors.
- GetSymbolInfo resolves actual call to
  AICodedbHostPayloadMaterializerTests.CreateDirectoryJunction,
  accessibility Internal, static True, bound True.

Checker attempt1 failed before symbol diagnostics with ArgumentException
"inconsistent language versions": NUnit declaration tree used default parser
version while selected source tree used C#9. Only the ignored checker changed
to explicitly parse all trees as C#9; second attempt passed. Preserve
binding-attempt-1.log; no failed run relabeled. Two checker process attempts,
one successful paired baseline/repaired binding check. No product behavior
change or additional source edit was required for that harness correction.

## Frozen snapshot

40rows compared against `.artifacts/tests/s29-optional-flat/source.sha256`:
39 unchanged, only UI test changed.
`.artifacts/tests/s29-optional-flat-compile/source.sha256`:
SHA256b04e6ebf4765563dce378a9497205ae7e66bcc2d2ace00241e52e0e710d3afdd.
UI testSHA2564721b03d448942b7bcbc4785a831a7ed5bee3d375dd17955d6576ea1a8cdbcb2.
No source edits after this result. Reads/searches/output stayed bounded in this
follow-up; the earlier larger-output deviations remain in the original RESULT.

Independent review remains limited to original CS0103 and adjacent new call.
Human Unity compile/EditMode consumer gate still open; S29 PARTIAL.
