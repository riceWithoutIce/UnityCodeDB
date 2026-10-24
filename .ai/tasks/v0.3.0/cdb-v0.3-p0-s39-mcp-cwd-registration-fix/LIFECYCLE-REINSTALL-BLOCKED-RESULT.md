# CodedbTest_2 same-version Install blocked: attempt stopped

Date: 2026-10-21. Status: SAME_VERSION_REINSTALL_BLOCKED /
LIFECYCLE_SUPPLEMENT_INCOMPLETE / NO_RETRY.

## Authorized action and original failure

The user approved one same-version Install after logical Uninstall passed.
The human clicked the normal Install once and supplied its failure output and
Manager screenshot. The action is `2764806408804be0b282d792eabf6b7d`.

The original terminal binds this action, project and the unchanged c848049
Package. Stage identity:
`549df2a8bc002f8b20aabc89277ae92fe61f1cc4ed28d24f4019c69be6a30400`.
It completed at `2026-10-21T09:41:14.6979616Z`, exit 6, elapsed 4276 ms, with
no timeout, output overflow or incomplete drain. Terminal SHA-256:
`905d599aa76c6871b0ae83dd3b7b1020082a5e72cc92708312f5c67147650f1d`.

Structured result:

```json
{"action":"INSTALL","outcome":"BLOCKED","phase":"PREFLIGHT","reason_code":"INSTANCE_CONVERGENCE_FAILED","mutated_scopes":[],"cleanup_state":"COMPLETE","exit_code":6}
```

Original detail:

> Instance Install failed without selecting an unverified candidate. Retained instance execution is live or unknown; Install remains blocked.

Product prerequisites report Node and Provider CURRENT. This is an explicit
retained-holder preflight refusal, not an observed compilation error, missing
target tool registration failure or startup timeout. The screenshot's
Unconfirmed/Needs attention presentation does not supersede the original
action's failed result.

The latest Supervisor operation file still records the preceding successful
Uninstall action, not this Install. The new direct action terminal is used as
the Install evidence; the earlier operation is not relabeled or substituted.

## Logical state after the refusal

Read-only checks confirm:

- Desired state remains `UNINSTALLED`, retired cleanup `PENDING`.
- No selected pointer exists and no new activation is claimed.
- Project registration bytes remain the inactive uninstall comments.
- Package manifest/lock, Unity version declaration and C# marker match the
  pre-action baseline. No pending Manager current-action file remains.
- The retired instance remains
  `fe3b257859f34023a9e290db3b2ad457`, generation poc.44, referenced by the
  existing removal intent.

The failed command's `cleanup_state=COMPLETE` describes its own attempt/result;
it does not establish completion of the retired-instance cleanup. Desired-state
cleanup is still PENDING. No broad no-write assertion is inferred solely from
`mutated_scopes=[]`; the named logical state/config inputs were checked.

## Bounded holder observation and static explanation

Source-only inspection found the failure branch at
`Tools~/codedb-instance-engine.ps1:4987`: every intent/control-bound retired
instance must return holder evidence `Clear=true` before Install can proceed.
The combined check at line 4311 requires zero live/invalid MCP leases, zero
live/invalid Editor leases and no LIVE/INVALID coordinator state. An active
MCP wrapper is sufficient to refuse even when Unity/editor-owned runtime
records have settled.

The post-failure snapshot found two existing MCP lease files for that retired
instance. One lease binds PID 53456 with start identity `1792569206110` and a
recent heartbeat. A targeted OS snapshot found PID 53456 still running Node,
parent PID 75104, with the registered relative wrapper/root arguments. OS
creation time is `1792569205947` Unix milliseconds, a 163 ms difference from
the lease. The existing matcher accepts a difference up to 2000 ms
(`Tools~/materialize-codedb-host-payload.ps1:3423`).

The other lease names PID 25692; that PID was absent in the initial two-PID OS
observation. Editor lease directory was empty and the old coordinator state
file was absent. The Supervisor state file was also absent at this read; an
initial attempted read encountered that absence. It is recorded as unavailable,
not a parse failure, running Supervisor assertion or evidence to recreate it.

The live matching lease/Node observation is consistent with the preflight
refusal. This is a bounded post-failure explanation, not a replay of the
preflight, exact-at-failure branch instrumentation, or complete holder audit.
No materializer function was invoked to recreate the classification. The
wrapper's owning Codex chat/client has not been identified. PID existence,
arguments and a lease do not authorize stopping that external client.

## Evidence and acceptance disposition

Evidence directory:
`.artifacts/maintenance/s39-lifecycle-acceptance/reinstall-failure-01/`:
`result.json`, original terminal output and retained Manager screenshot.

- Earlier first-install/client/C# hit and installed-state reopen PASS remain
  attributable and unchanged.
- Logical Uninstall PASS remains valid, with physical cleanup pending.
- Same-version reinstall did not pass; post-reinstall reopen is NOT RUN.
- The current lifecycle supplement stops here and does not establish basic
  lifecycle closure or release acceptance.

No retry, manual cleanup, source/config modification, extra MCP call, component
start/stop or Package switch was performed by this chat. Do not resolve this
acceptance failure by silently killing the wrapper, deleting its lease,
closing an unidentified chat, weakening the ownership gate or creating another
fresh project to bypass the retained-instance path.

Next discussion should address the supported user flow for logical Uninstall
followed by Install while an external MCP client still holds the retired
instance: intended admission, client detachment guidance and ownership
boundaries. The present observation does not decide whether the eventual
solution is documented user action, lifecycle handoff or a bounded code change.
No repair, client-close operation or new live attempt is authorized by this
failure record. The unrelated retained writer-lifetime WIP is not activated.
