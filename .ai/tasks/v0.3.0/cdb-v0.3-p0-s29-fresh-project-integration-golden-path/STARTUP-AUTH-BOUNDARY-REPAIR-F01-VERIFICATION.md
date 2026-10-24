# S29 startup authentication boundary — F-01 targeted re-review

Date: 2026-10-13. Verdict: **PASS_WITH_LIMITS**. **F-01: CLOSED**.
Scope: original F-01 and nearest holder/history regressions only.
No open finding remains from the original concentrated review.

## Admission and exact delta

Completely read STARTUP-AUTH-BOUNDARY-REPAIR-F01-RESULT.md, the actual named
STARTUP-AUTH-BOUNDARY-REPAIR-F01-SOURCE-SHA256.txt and the F-01 grant appended
to STARTUP-AUTH-BOUNDARY-REPAIR-TASK.md. Human “同意” authorizes this same-task
targeted re-review; parent kept source frozen and remained active.
The short hash filename in the dispatch was shorthand, confirmed by the parent.

One source-hash admission matched all five replacement hashes. HEAD remains
`04e9a6bd49ae46f5c10989f6e4c6efddc479ad24`.

| Repository-relative file | Current SHA256 |
| --- | --- |
| com.rice.ai-codedb/Editor/AICodedbControlContract.cs | d554dc37ce80d9336de58e60efd01c1f12d4ce95c48fc348ec5d2f2cdef46d01 |
| com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs | 386790741bca240e1cf19bee06df8cce9a16cdb3c39969f39d916cbdab39aa69 |
| com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs | 732b95b6b81ef44bb92f44817d55c649d95efdcfcd0d66e50bc19cccc863ffb3 |
| com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs | dddab0e34ea36b33f9982e7aba33770824246860821ea62f1eb23c92907ccf5d |
| com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs | fca5b0a60f6a4baccc023a71fc74e1a72664967fd239337e229b1bcc60ad6bf4 |

For the two changed files, reversing only the declared filename correction and
the new test case/assertions **in memory, without a write**, reproduced their
first-review hashes exactly:
`ece23060d2c4fc86f69521f436a9b7eaacd056833f1fefd12b664802a4676ca3`
and `ed49c4f2c48ccf2d9cec167dd75184fd434dd79ad4b3fc971bd496a0376e998d`.
The other three hashes equal the first review. Thus this repair has no hidden
source/test delta beyond the approved F-01 correction.

## F-01 closure and nearest regression

Journal line 1271 now checks
`watch/coordinator/coordinator-state.json`, matching the production poc.39
coordinator's STATE_FILE at line 16 and runtime join at line 108, and the
producer/reader attribution recorded in the original review.
Lines 1273–1275 retain project-path validation and conservatively return
`candidate has unresolved runtime authority` for either a file or directory at
that location. The original trigger therefore cannot reach the historical
warning merely because its real coordinator state filename was missed.
The check does not parse or trust the state, probe a PID, delete it, or grant a
mutation permit. **F-01 is CLOSED at the source boundary.**

The added TestCase at ManagerUiTests line 4236 creates the real-named state
at lines 4364–4366 for the existing otherwise unrelated older candidate fixture,
without creating a holder lease. Lines 4371–4372 require both Conflict and the
specific `unresolved runtime authority` reason, so an unrelated earlier Conflict
does not satisfy the new regression. Existing six protected fixture-file hash
assertions remain at lines 4367–4374.

The preceding Editor/instance/generation holder checks (Journal lines
1205–1270), timestamp/PID conservatism and the other state/retiring presence
guards are unchanged. Historical and stale-editor/no-holder cases remain the
same informational paths; active Editor/instance/generation and invalid lease
cases retain their blocking paths. Exact reverse-delta attribution above
supports this nearest-regression conclusion without reopening the wider audit.

## Evidence attribution, limits and stop

Coder reports one corrected-source standalone run: seven journal-reader cases
PASS (historical, stale-editor, editor-holder, instance-holder,
generation-holder, invalid-lease, coordinator-state), plus current-source
34-file C# 9 semantic compilation with zero errors and scoped whitespace PASS.
These are **Coder execution evidence**, not tests or compilation rerun by this
Verifier. The inspected harness filter at RuntimeTests.cs lines 47–58 selects
only those cases; lines 79–82 return before the original real-project reader.
The current journal method has 16 declared cases. This re-review does not claim
a new full 52-case run or reattribute the previous snapshot's 51-case PASS to
the changed bytes. Existing standalone/native/static and NUnit adaptation
limitations remain.

No tests, builds, product scripts, live reader, Unity/MCP/BatchMode/CUA,
Probe/Ensure/Install/Upgrade/Remove, process control, source repair, agent spawn,
commit, export, reference switch or cleanup ran here. Only this new report was
written with apply_patch; original review and unrelated dirty state are preserved.
An accidental read of the main S29 historical TASK.md produced truncated output;
it was excluded from review evidence and introduced no new requirement.

Native Unity/EditMode/lifecycle/UI, live IPC/readiness, real mutation/removal,
delivery and release remain NOT RUN. The uncommitted source repair is not part
of the already referenced Package. S29/release remain PARTIAL.
F-01 and its agreed immediate regressions are closed within the static evidence
boundary; this targeted review stops here, with no new finding or operation.
