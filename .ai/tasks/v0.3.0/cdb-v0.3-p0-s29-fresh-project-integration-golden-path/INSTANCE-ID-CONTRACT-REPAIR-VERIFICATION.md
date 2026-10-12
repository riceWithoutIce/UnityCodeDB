# S29 instance ID contract repair — independent Verifier result

Date: 2026-10-12.
Verifier: `/root/instance_id_contract_verifier`.
Recorded by parent from the Verifier's terminal response; parent separately
confirmed the agent is completed. No source mutation during verification.

## Verdict

`PASS_WITH_LIMITS`. The original instance ID contract defect is closed in the
frozen snapshot. No BLOCKER, P1 or P2 finding in the original finding and adjacent
regression scope. S29 / release remain PARTIAL.

## Reviewed boundary

- Legacy receipt Package directory keys retain the 24-character lowercase hex
  rule. Instance directories use a separate 32-character lowercase hex check.
- The current action is passed to legacy aggregation after index identity
  validation. An attributed PROVISIONING candidate no longer becomes an orphan
  solely because the current index was omitted from the known action set.
- Legacy actions and resolved markers retain their existing known-action
  aggregation. Unknown origins and invalid instance directories remain Conflict.
- The old `73c9...` attribution is not inferred and the multi-failure history
  selection strategy is unchanged.

## Independently executed evidence

- `.artifacts/tests/s29-instance-id/Focused.csproj --no-restore`:
  `SEMANTIC errors=0`, four test methods / nine cases PASS.
- Same harness with `--pre-fix`: valid 32-character READY/current case becomes
  Conflict as expected, showing that the regression detects the original
  24-character instance validation error.
- `git diff --check` is clean for the two allowlisted files.
- Both source hashes match INSTANCE-ID-CONTRACT-REPAIR-SOURCE-SHA256.txt:

```text
210f4b20ff948df31e9368adbfc06a428276865fd7123a360ef0b499559e1327  com.rice.ai-codedb/Editor/AICodedbManagerActionJournal.cs
27e962563aef0eccf147945afd66e7b73ccdc6892d546cfa561d4f5c7896cc7b  com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs
```

## Limits

The standalone harness replaces SessionState, Application.dataPath, Editor time
and lifecycle static initialization with isolated boundaries, and uses NUnit
constraints to execute assertions. This is not a Unity / NUnit runner PASS.

`AssertRetainedCurrentIndexRejectsUnownedInstance` was source-reviewed and
semantically compiled; the complete PowerShell retained producer chain was
NOT_RUN. Follow-up execution belongs to a separately authorized validation gate.

Human Unity UI, real producer, package/export/reference switch, payload hash
repair and release acceptance are NOT_RUN. No source/test/payload edits, Unity
or MCP startup, real Install/Uninstall, commit or export were performed by the
Verifier. Historical orphan recovery remains deferred.

## Handoff

Independent review is complete. User disposition of this PASS_WITH_LIMITS source
snapshot is the next step; it does not authorize delivery or real-project actions.
