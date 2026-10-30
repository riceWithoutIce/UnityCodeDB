# Fresh Install attempt 01 — blocked, 2026-10-26

Candidate: `11056964da1143955ed69a067361622799e3d6f2`.
Action: `1a02434fd5424d379508b338318c1b65`.
Outcome: `BLOCKED / PREFLIGHT / INSTANCE_CONVERGENCE_FAILED`, exit 6.
Human invoked one normal Manager Install after the completed uninstall check.
Elapsed reported by Manager: 13.82 seconds. No retry or repair.

## Original human output

```text
Command failed with exit code 6.

Exit Code: 6
Elapsed: 13.82 s
Action ID: 1a02434fd5424d379508b338318c1b65

Output:
[CONFIRMED] Install is scoped to CodeDB-owned paths in this Unity project.
[PRODUCT_LAYER PREREQUISITE] CURRENT - Node.js v24.14.1 and CodeDB Provider 0.5.0-28e3912-c2 are verified.
[PRODUCT_LAYER PREREQUISITE] CURRENT - Node.js v24.14.1 and CodeDB Provider 0.5.0-28e3912-c2 are verified.
[COMMAND_RESULT] {"schema_version":1,"managed_by":"com.rice.ai-codedb","action":"INSTALL","outcome":"BLOCKED","phase":"PREFLIGHT","reason_code":"INSTANCE_CONVERGENCE_FAILED","mutated_scopes":[],"cleanup_state":"COMPLETE","next_action":"Review the original failure and retained or unknown candidate effects before another confirmed project change; no automatic replay is authorized.","exit_code":6,"detail":"Instance Install failed without selecting an unverified candidate. Supervisor owner, takeover or unknown execution evidence remains; Install is blocked."}

Error:
Instance Install failed without selecting an unverified candidate. Supervisor owner, takeover or unknown execution evidence remains; Install is blocked.
```

Screenshot separately shows uninstalled integration, status unconfirmed and failed
Install activity. UI does not prove live ownership or process status.

## Read-only direct-cause investigation

No runtime helper was imported/executed. Read the exact action's four compact
receipts and the two directly identified quarantine files, each <=256 KiB.
Listed only immediate entries of this action directory and the known Supervisor
runtime, bounded at 24 and 32 entries respectively; no recursive action search,
process/lease scan, RPC, event-log read or polling.

At `2026-10-26T02:35:01.9095266Z` the runtime contained only:

- `manager-actions/`
- `operation-history/`
- `operation.json`
- `supervisor-events.jsonl`
- `supervisor-state.json.stale.1792636589842.21e4730684ce4af9ac62090523fa04dc`
- `supervisor.lock.stale.1792636589842.21e4730684ce4af9ac62090523fa04dc`

The quarantine pair's recorded file modification times were 2026-10-22,
before this Install. No current state/lock or takeover claim was listed.
These are disk observations, not proof of process absence or valid retirement.

The four action receipts match the exact action, project and candidate Package
keys. Admission/claim/terminal stage IDs agree. Terminal confirms exit 6,
elapsed 13,815 ms, timeout/overflow/drain-incomplete all false, completed UTC
`2026-10-26T02:33:50.8327149Z`. Its stdout/stderr match the human result.

The stale state/lock documents share the target project identity and owner epoch
`03e2797f6bf940b1a5df867305d2d57d`. Matching fields alone are not full authority
validation; their process liveness was not queried.

## Source trace and interpretation

`com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1:5005` defines
`Assert-ProjectInstallExecutionAdmission`. Its immediate runtime scan allows
only events/error, canonical operation and operation-history/manager-actions
directories. At line 5094 every other entry produces the exact reported error.
Both observed `.stale.*` entries enter that rejection branch. The message groups
owner, takeover and unknown evidence together; it does not identify which kind
was seen or demonstrate a live owner.

`Tools~/codedb-project-supervisor.mjs:722` generates this quarantine filename
shape during stale takeover; lines 726 onward rename state/lock with the same
suffix. This is a product-produced record shape, not necessarily test junk.
`Tools~/materialize-codedb-host-payload.ps1:10416` also contains a separate
removal namespace proof that recognizes paired stale records and validates them.
That recognition is absent from the Install admission loop. This observation
does not assert that the removal proof is suitable for direct reuse in Install.

The source trace plus exact terminal and runtime inventory establish the direct
rejection mechanism. This is a producer/consumer admission compatibility gap to
address. It does not establish that arbitrary stale files should be accepted or
that this pair's referenced processes are absent.

Delivered candidate and repository hashes match for both relevant files:

| File | SHA-256 |
| --- | --- |
| `Tools~/codedb-instance-engine.ps1` | `1fd30107b3229d6a118d1f004d2ea868b3c330f5ba46d9259cd4bac16e86589d` |
| `Tools~/codedb-project-supervisor.mjs` | `50260e1a355907a163e7841dc7a076e1917c0cec1e4b0d3f4f6f4a7186e59aca` |

## Evidence and next boundary

Sanitized snapshot:
`.artifacts/tests/cdb-v0.3-candidate-lifecycle-acceptance/fresh-install-attempt-01/snapshot.json`.
SHA-256: `fb5d26bb394b2c1f9e8705d11686a837ea3bd0c03e94ce83b50f65ce9a1b6d68`.
Task-only helper: `check-install-failure.cjs`. Stored paths are symbolic and
authentication material redacted. One local artifact sanitization correction
used only the already captured snapshot; no external reread/runtime retry.

`cleanup_state=COMPLETE` belongs to this blocked Install result. It does not
upgrade the earlier Uninstall's `PENDING` physical cleanup to COMPLETE.
`mutated_scopes=[]` is the backend's declared scope result, not independent proof
that no bookkeeping file was written anywhere. No after-Install pointer/content
stability claim is added without a separate check.

Fresh Install acceptance is **BLOCKED**; Ready, post-install reopen and new-client
acceptance are NOT_RUN. Earlier functional PASS and logical uninstall evidence
remain attributed to their original stages. The prior handoff check deliberately
did not enumerate quarantine content; its no-concrete-conflict conclusion was
limited to its own envelope and did not predict successful Install admission.

Next proposed scope: a narrow design/repair of Install handling of recognized
quarantine pairs, with bounded project/namespace/owner binding and existing
execution-safety checks. Unknown content, incomplete/mismatched pairs, live or
unknown execution must remain blocked. Do not blanket-ignore stale filenames,
delete evidence, weaken all admission checks or broaden into Supervisor redesign.
Agree the repair envelope before editing product source. No repair or new real
Install attempt is authorized by this report.

No consumer edits, cleanup, process action, MCP query, additional Install,
Repair/Restart, Unity launch/close, commit/push or board update was performed by
the development session. Only task/evidence files were written.
