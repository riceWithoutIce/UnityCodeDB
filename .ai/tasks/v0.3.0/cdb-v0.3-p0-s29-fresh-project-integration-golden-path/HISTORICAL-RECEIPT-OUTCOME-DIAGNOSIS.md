# S29 historical receipt outcome diagnosis

Date: 2026-10-08. Authorization: user approved bounded read-only diagnosis after
human-reported tests and Manager tab/close observations passed. No repair authorized
by this diagnostic step. HEAD: 3b09859045d0d4547d9ba2cef332a550e8530f99.

## Finding

The current recovery consumer rejects the real historical command outcome.
Both AICodedbActions.HasFailedInstallPendingEffects (line 236) and
AICodedbProcessRunner.RecoverFailedInstallFollowUp (line 1056) require FAILED.
The actual Install and Upgrade command results contain BLOCKED. The materializer
writer uses BLOCKED for an unsuccessful command when no outcome override exists
(Tools~/materialize-codedb-host-payload.ps1, Write-MaterializerCommandResult).
The command-status parser accepts this identifier; rejection is in the two
downstream semantic predicates, not JSON parsing.

ManagerReceiptFixture.CommandOutput fixes outcome to FAILED and reason_code to
FIXTURE (Tests/Editor/AICodedbManagerUiTests.cs, lines 160 onward). Its DryRun also
uses a synthetic UPGRADE_READY line. Thus passing fixtures do not cover the actual
historical output shape. This is a producer/consumer/test contract coverage gap.

The journal requires a CommandTerminal resolved marker to recover as Terminal;
the rejected shape instead yields Conflict. It then reports the generic
"A resolved action marker conflicts with its original receipt." This message
does not, by itself, prove disk corruption or a changed receipt.

## Read-only evidence

Project: UnityFreshInstallValidationProjectS29.
Action: d8c736504562495dbafdd673c6851efb.
Project key: a31d47273d22f34d00000fc234ff1b7dcc5afac6079b4e459935838d94c07c66.
Historical package key: 484a0de012a134f1eec7c80f662666ce0d084679de34f1295e8086bc52f80a29.
Historical package: .artifacts/0.3.0-preview.5-s29-compile-fix-70f33f7/review/com.rice.ai-codedb.
Index: C:/Users/admin/AppData/Local/Rice/CodeDB/manager-actions/a31d47273d22f34d00000fc2.
Resolved marker disposition: CommandTerminal; legacy layout (no storage_layout).
Marker SHA256: FA25EF8F4B00E84A326D3238C33BD922BED160D931BC62091F0BE260B47031A7.

| Recorded stage | Exit | Outcome / phase | Effects / cleanup |
| --- | --- | --- | --- |
| Install | 6 | BLOCKED / CANDIDATE | host_runtime, instance_candidate / PENDING |
| DryRun | 0 | No COMMAND_RESULT; NEEDS_ATTENTION, INSTALLED MISSING, CONFIGURED MISSING, MCP UNAVAILABLE, INSTANCE NONE | Read-only observation |
| Upgrade | 6 | BLOCKED / PREFLIGHT | Empty scopes / COMPLETE |

Install reason: INSTANCE_CANDIDATE_FAILED. Upgrade reason:
INSTANCE_CONVERGENCE_FAILED. Original Install failed on originating_action type;
the later Upgrade refused an unbound or ambiguous candidate.

All three stages have admitted, claim and terminal records. Bounded comparison
found no mismatch in action/project/package/stage identity, admission roots,
admission-to-terminal command/effect/authority/identity/terminal fields, or
claim-to-terminal writer PID. Recomputed argument and command identity hashes
matched each admission. All terminals declare terminal_for_action=true, without
timeout, overflow or incomplete drain. Ten inspected files (marker plus nine
records) had unchanged SHA256 before/after this read window. These are selected
field/hash checks, not execution of the complete C# receipt validator.

The actual DryRun NEEDS_ATTENTION output maps to HostPayloadState.Blocked in
AICodedbHostPayloadStatusBuilder, satisfying the recovery non-Unknown requirement.

Project manifest points to .artifacts/s29-test-runtime-poc40/review/com.rice.ai-codedb.
Source and that extracted artifact match for all five inspected files:

| File | SHA256 |
| --- | --- |
| Editor/AICodedbActions.cs | 4D2E3FCAFFA9EF34A92C54D9C5C1F16E89F910479B15ACD7A3BE3C75D1B8E6A6 |
| Editor/AICodedbProcessRunner.cs | 1ECA668E0AC0B2CB98E0C35964456111DD1A75DB4E6FC5581228F2845F657CFC |
| Editor/AICodedbManagerActionJournal.cs | B4A89217804BA841C4571BDF435D9A7B6BEC9ADF4356675ED08B67D968261FAA |
| Editor/AICodedbHostPayloadMaterializer.cs | E76D566EEB7A54CAA56F77B246CB26F7B896A899CCDA9826612727C157C6C200 |
| Tests/Editor/AICodedbManagerUiTests.cs | C0C3252660EF36C3B6E6948CA3D340348F33DF70C6A564470A5DDC235E6214B6 |

## Proposed coherent repair scope, pending user decision

1. Align bounded failed-command semantics in both Install and Upgrade consumers
   with the writer contract. Preserve identity, terminal completeness, action,
   phase, exit, mutation scopes and cleanup validation. Do not accept arbitrary
   BLOCKED records or treat them as successful installation.
2. Add sanitized regression coverage of the actual three-stage BLOCKED shape,
   resolved marker recovery and the retained removal gate, using test-workspace
   identities rather than live project paths. Cover rejected adjacent shapes.
   Check writer-to-consumer agreement rather than only a synthetic FAILED fixture.
3. Preserve the original Install result and PENDING effects. Upgrade COMPLETE is
   local to the refused Upgrade and must not clear Install effects. Do not rewrite
   historical records, delete the poc.39 candidate or automatically retry.
4. After stable Coder output, independently review this finding and adjacent
   regressions. Then complete authorized delivery prerequisites before one bounded
   human observation cycle. Correct history recognition alone is not S29 Ready,
   cleanup completion or real installation acceptance.

No production edits, tests, C# recovery invocation, Unity/MCP/BatchMode, process
probes, replay, cleanup, commit, export or publication occurred in this diagnosis.
Only task evidence is recorded. Status: CONTRACT_MISMATCH_CONFIRMED /
REPAIR_DECISION_PENDING / REAL_INTEGRATION_BLOCKED / S29_PARTIAL.
