# Task: cdb-v0.3-p0-s10b-editmode-evidence-extraction

## Metadata

- Product: UnityCodeDB
- Version: v0.3.0
- Status: READY
- Planner: UnityCodeDB v0.3 Planner
- Coder: v0.3.coder.deep
- Verifier: none for this evidence-only extraction
- Review mode: GUARDED
- Complexity: High
- Execution profile: v0.3.coder.deep
- Session policy: REUSE_ONLY
- Predecessor: `cdb-v0.3-p0-s10a-editmode-evidence-investigation`
  (`BLOCKED` only by an XML text-accessor ambiguity).
- Human authorization: on 2026-09-07 the user explicitly authorized this new
  bounded evidence-extraction attempt.

## Objective

- Complete the read-only evidence work that S10a stopped before performing.
- Extract the four existing NUnit failure texts with an explicit text-node
  accessor, map the 17 omitted Manager methods to their real declaring classes,
  inspect only Package/compile/timing evidence in the existing Unity log,
  verify post-run snapshot identity, and specify a corrected synchronous wait
  contract for a separately authorized future Unity run.

## Frozen Inputs

- Expected HEAD: `6408b0d540b32584147588efb67ecc5ba12b2fda`.

| Read-only artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| S10a `RESULT.md` | 5611 | `0f4dcc0cf6a2dde0d3303820057586d47d8b87a040886316040264763db42115` |
| S10 `RESULT.md` | 7073 | `9a60754e604a3e34db03271ad5843c3f506e55c1ac71f084b9341a9955dcd2ca` |
| `UnityValidationProject/TestResults-S10-control-plane.xml` | 29297 | `e826513cc4abfba4cae1e54b30f2a3d518fedb034ef596a1a8c386f9f30136f9` |
| `UnityValidationProject/Logs/S10-control-plane-focused-editmode.log` | 94435 | `f3d8c00640502b4dcd32d30daa9288c9ec425ed2a76fd2a8ea69e530236fc9d7` |

- S10a's four failure identities, root counts, and timings are accepted as
  frozen evidence. Do not emit all 26 case rows again.
- Seven expected repository content hashes and expected five-file scoped status
  are inherited exactly from the S10/S10a tasks.

## Exact XML Extraction

- Parse the frozen XML exactly once with an XML parser.
- Select exactly four nodes with:

```powershell
$failedCases = @($xml.SelectNodes('//test-case[@result="Failed"]'))
```

- Require `$failedCases.Count -eq 4` and require their full names to equal the
  four frozen identities in S10a.
- For each failed case, obtain text only through these accessors:

```powershell
$messageNode = $case.SelectSingleNode('./failure/message')
$stackNode = $case.SelectSingleNode('./failure/stack-trace')
if ($null -eq $messageNode -or $null -eq $stackNode) {
    throw 'Failed test case is missing message or stack-trace text.'
}
$message = $messageNode.InnerText.Trim()
$stack = $stackNode.InnerText.Trim()
```

- Reject empty text and the literal `System.Xml.XmlElement`. Record the complete
  bounded message and only the first relevant repository-relative stack frame.
  Limit each row to `2 KiB` and all four rows to `8 KiB`.
- Classify only whether the four failures share one immediate cause and whether
  that cause points to product code, test fixture/expectation, or environment.
  Read only those four method bodies and directly referenced local call sites if
  the extracted text alone is insufficient. Do not fix anything.

## Remaining Evidence Stages

1. Manager filter mapping:
   - Map only the 17 Manager methods listed in the S10 task to the nearest
     enclosing declared class in
     `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`.
   - Confirm every corrected fully-qualified name exists exactly once.
   - Confirm Manager totals `17` methods / `43` cases and combined totals `39`
     methods / `69` cases.
   - State explicitly that `AICodedbManagerUiTests` is a filename-derived,
     nonexistent type and caused all 17 Manager filters to be omitted.
2. Existing Unity log:
   - Search only for local Package resolution of `com.rice.ai-codedb`, `error CS`
     entries, Unity's immediate compiler-error summary markers, and test/process
     timestamps needed to compare launcher return with actual execution.
   - Report counts and at most the first relevant compiler error. Sanitize all
     machine paths to repository-relative project or Package paths.
3. Post-run snapshot:
   - Recompute the seven S10 content hashes once.
   - Run one relevant scoped status check covering the five accepted modified
     files plus Package Editor and Editor tests.
   - Do not use `git diff`, full status, history, blame, or patch-identity
     recomputation.
4. Future synchronous wait contract:
   - Specify an exact PowerShell approach that starts the resolved Unity
     executable without a hidden window and immediately waits on that exact
     process object, rather than relying on `&` to wait for a Windows GUI app.
   - The future wrapper must use the corrected 39-name filter, retain the S10
     Unity arguments, enforce a `300s` wait, capture the real process exit code
     and elapsed time, and never kill or signal Unity on timeout.
   - This stage is a written recommendation only. Do not launch a process.

## Execution And Budgets

- Perform one admission stage for HEAD and the four exact artifact identities.
- The exact XML extraction, Manager mapping, log check, and snapshot/wait
  analysis together form one authorized read-only evidence batch. `1/1` means
  one pass through all four declared stages; it does not mean stopping after the
  first successful stage.
- Retry budget: `0/0`. Stop on the first failed precondition or new ambiguity.
- Normal command maximum: `60 seconds`.
- Captured output: `16 KiB` per command and `64 KiB` aggregate.
- Write only this task's `RESULT.md`, with a concise evidence table,
  classification, future-run recommendation, deferred boundaries, and the
  standard completion-routing footer.

## Prohibited Actions

- Do not start, stop, attach to, signal, poll, or otherwise control Unity,
  Unity Hub, Unity MCP, or any business/runtime process.
- Do not rerun EditMode, compilation, Package Manager, L0/L1, or another test.
- Do not modify production, tests, configuration, S10/S10a records, XML, log,
  or ignored evidence.
- Do not inspect passed-case bodies, unrelated warnings, broad logs, full test
  classes, theoretical hardening, full regression, or release behavior.
- Do not commit, push, stash, reset, clean, rebase, amend, or contact Verifier.

## Definition Of Done

- Four unambiguous failure messages and first relevant stack frames are recorded
  and narrowly classified.
- Corrected Manager FQNs and the `39` method / `69` case filter are mechanically
  established.
- Existing Package resolution, C# compile disposition, run timing, seven hashes,
  and scoped status are reported.
- A real synchronous future wait contract is provided without running it.
- Planner can choose between a product/test FIX and one corrected future Unity
  run without another exploratory read.

## Handoff

Current task: cdb-v0.3-p0-s10b-editmode-evidence-extraction
Current status: READY
Next notification: v0.3.coder.deep
Next action: complete the four-stage read-only evidence batch and return
`RESULT.md` to UnityCodeDB v0.3 Planner
Human decision or authorization required: any product/test FIX, corrected Unity
rerun, Verifier routing, commit, or push remains separately gated
