# IPC diagnostics compile repair result

Date: 2026-10-22. Status: ISOLATED_REPAIR_PASS / NOT_DELIVERED.

## Diagnosis

The first c53e181 Package produced a Unity compile error at
`Editor/AICodedbControlContract.cs` where a
`Func<string, string, CancellationToken, string>` is assigned from
`AICodedbSupervisorBridge.SendPipeRequest` through `??`. The diagnostics change
changed the only transport method from three parameters to three parameters
plus an optional diagnostic parameter. Unity's compiler does not use that
optional parameter to make this method-group conversion compatible.

This is a direct regression from the diagnostics change. It is not a CodedbTest_2
project corruption, Package copy failure or runtime/Manager readiness issue.
The current external project remains on the first c53e181 Package and retains
the reported compile error until a repaired Package is delivered.

## Minimal repair

The isolated Bridge restores the original three-argument overload and forwards
to the four-argument diagnostic transport with a null context. The four-argument
method remains the diagnostic implementation. No timeout, cancellation,
disposal, queue, ownership, readiness, UI or wire behavior changes.

The focused test harness now checks both overloads and compiles a C# method-group
fixture matching the Unity consumer delegate. Existing transport extraction and
local named-pipe cases remain unchanged.

## Verification

One same-cause corrected focused batch passed: **82 assertions**.

Tested files in the isolated checkout:

| File | SHA-256 |
| --- | --- |
| `Editor/AICodedbSupervisorBridge.cs` | `b2fe1c6564ea0bf5f386eaf40e1ca6ace7643f925203ff520ffb202500a2bfe5` |
| `Tests~/test-codedb-supervisor-ipc-diagnostics.ps1` | `165c283496a9cc0f2093994a518b361ee7d9750da07fee150ce7b81c808e18c8` |
| receipt.json | `ecb56fa72cea680989eca180796d32f9075577c9de94b17aced2ad279f1f0d26` |

The full Unity project was not opened by this session; the reported external
compile error is the confirming consumer evidence. No real Supervisor, MCP,
Install/Repair/Restart/Uninstall or process operation was performed.

## Boundary

The repaired source is now committed as `61dcd26`, exported, and delivered to a
new Package destination after the separate handoff approval. See
IPC-COMPILE-REPAIR-DELIVERY-RESULT.md. Do not infer runtime readiness from this
file-delivery result; Unity must be reopened by the human.
