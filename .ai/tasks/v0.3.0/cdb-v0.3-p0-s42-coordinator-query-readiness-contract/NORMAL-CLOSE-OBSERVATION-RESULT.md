# Normal-close retirement observation result

Status: OBSERVED_RETIRED_AT_CAPTURE. Date: 2026-10-22.
Human confirmed CodedbTest_2 Unity closed before this one authorized snapshot.
No automatic Unity operation or additional shutdown/Stop request was performed.

## Evidence

Canonical safe receipt:
`<repository-root>/.artifacts/tests/s42-normal-close/2026-10-22T06-14-35-847Z-c53e13/report.json`.
SHA-256: ba7c8183fbd927e5b10dd55817d409013648383887e61616d2cf03571fb2e336.
Capture 2026-10-22T06:14:35.847Z to 06:14:36.844Z, elapsed 997 ms.

One complete Win32_Process metadata inventory command; individual identity probes
0, service RPC 0, maintenance requests 0, CodeDB calls 0, consumer writes 0.
Task observer syntax PASS. No retries, repeated snapshots or waiting loop.
Raw process paths/argv and runtime secrets stayed in memory; output is sanitized.

Observed together:

- Target UnityLockfile absent; no target-related Unity process identified.
- Supervisor state and lock absent; selected coordinator state absent.
- No target-related backend/maintenance process or unattributed relevant candidate
  identified in the inventory. The observer/ancestor process chain was excluded.
- Recorded old Supervisor, coordinator and Provider PIDs absent. The latest
  maintenance child, known failed Stop child and prior recorded Probe child PIDs
  were also absent. This is corroboration, not PID-only authority.
- Latest persisted materialize:Probe is completed, exit 0, disposition
  CHILD_ADMITTED, with child identity recorded. No running/queued operation.
- The known failed Stop remains failed/exit 1; its SHA-256 is unchanged. Normal
  close did not retroactively turn that attempt into a successful Stop.
- Desired state enabled; selected manual-runtime record absent. No manual mode
  was manufactured, reset or inferred from the prior failed Stop alone.

## Stable selection and reference

Manifest and lock still reference
`file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb`.
Their hashes remain ea79c33e16767692fc3cb14cc92145e97705c42353e84e7955da539164da4485
and 183766b27213ff3a0bc1b604785661d5e39372c4918ef7c5b9bc9e947da2298d.

Selected instance a492a5e936c14e4da3ed7e4cc7c8c16c, activation
063aa347f49a4b9f955a5447f293a0ac, generation poc.44. Instance manifest hash matches
the selected pointer. Pointer before/after is byte-stable with SHA-256
1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a.

## Interpretation and next gate

The combined process inventory, absent owner records/Unity lock, terminal
maintenance evidence and stable binding establish retirement for this snapshot.
It is not a guarantee against a later external reopen/start or proof of exact
shutdown event ordering. No authenticated IPC or query response was requested.
Future mutations must recheck their own immediate preconditions.

Updated Package commit 4589249 remains an internal verified artifact, not yet
copied/referenced by the consumer. Unity remains human-closed. Next prepare the
concrete external copy/reference-switch envelope, preserving exact original
manifest/lock bytes and protected project state; do not copy/switch under this
observation-only grant. No cleanup of legacy runtime or historical artifacts.
