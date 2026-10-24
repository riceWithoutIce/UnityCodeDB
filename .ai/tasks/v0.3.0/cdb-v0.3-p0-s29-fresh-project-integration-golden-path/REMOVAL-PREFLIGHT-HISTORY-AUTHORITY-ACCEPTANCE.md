# S29 removal history authority — source acceptance

Date: 2026-10-15. Status: SOURCE_ACCEPTED / DELIVERY_COMPLETE / HUMAN_PENDING / S29_PARTIAL.
User disposition: `同意 accept`.

## Accepted snapshot

Base HEAD remains `544be4f7e339acefb47137b188cdc85e22483efb`; the staged index is
empty. The accepted source snapshot is exactly the three changed files recorded
by Coder and independently verified:

```text
2fb1ab328213bda1a2a3c45d4891604deefa55fdb1a88e0c4f6dc78ed1f5b99a  com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1
397635c916d6a1fdb8b1cf6d1eb3baa8008b4565553d0f10acc1d1f9b319134d  com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1
cf8ebddd4ac0b10d2e9b7e7fee9888d5762ab3e19fd50c99cf1363707be6c0eb  com.rice.ai-codedb/Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs
```

Independent Verifier: `SOURCE_AND_ISOLATED_PASS`, 0 BLOCKER / 0 FOLLOW-UP.
Report SHA256:
`1bf2577491d32490bab44b2a1ddb99095794bb0ea8632ee351d9dcca2f0397db`.

The accepted behavior separates selected-instance authority from the executing
Package authority for v2 removal history. It allows only validated current and
trusted-predecessor tuples, keeps target/hash/disposition atomic for owners, and
retains all process, child, holder, activation, fingerprint and revalidation
refusals. No persisted schema, generic compatibility fallback, process action,
delete target or Ready/Install admission was added.

## Evidence accepted with limits

The declared source/isolated evidence is accepted: PASS200 production seam,
original-byte Editor and Editor.Tests compilation, exact C# diagnostic/cache/UI
seam, final ZIP617 overlay/path provenance, and 5818-entry protected-state
equality. The semantic/compiler/C# evidence ran before removal of one unrelated
Unity-generated `.cs.meta` from the owned overlay; the final overlay differs
only by that non-code file and its path-provenance gate was rerun. This is not a
new semantic execution claim.

## Downstream gates

The subsequent delivery grant was explicitly provided as `同意授权`; delivery
is recorded in REMOVAL-PREFLIGHT-HISTORY-AUTHORITY-DELIVERY-RESULT.md. Human Unity
acceptance remains pending. No Install/Remove/Upgrade/Probe/IPC, process control,
history cleanup, push, publication or release is authorized by that record.
Actual removal remains fail-closed; child-null histories and CleanupMono remain
deferred. S29 and release status remain `PARTIAL`.
