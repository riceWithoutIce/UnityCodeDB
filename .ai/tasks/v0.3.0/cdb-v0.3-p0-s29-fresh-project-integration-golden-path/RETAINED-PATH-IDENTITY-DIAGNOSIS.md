# S29 human retained-proof path identity diagnosis

2026-10-09. READ_ONLY_DIAGNOSIS_COMPLETE / HUMAN_GATE_FAILED.
Delivered source commit915a21b8c09aa126bdf757711baa80632c537137,
Package0.3.0-preview.5/poc.41. Original delivered artifact is unchanged.

Human ran ManagerActionJournal_ActualPowerShellRetainedEffectsProofPreservesFailedOutcomeAndReleasesSession.
It failed in0.034s at AICodedbManagerUiTests.cs:1429: expected Empty, actual
Conflict; Manager action index validation failed: Failed candidate intent
identity is invalid. This does not establish PASS for later session/outcome
assertions, negative hashes, the second method or Manager observation.

Actual launcher-bound proof context:
.artifacts/tests/rc41-retained-continuation-25cc8d5e1ca6/emitted-record-context.json.
Its synthetic project is failed-preparation-CURRENT-False in that container;
no real S29 runtime, user-local original action receipt or candidate was changed.

The ten existing intent identity predicates were checked against the actual
marker/context. Schema, managed_by, authority_kind, state, operation, retained
instance, generation, project identity and lower-hex authority fingerprint all
match. Raw project_root equality is false; the same predicate after existing
absolute path normalization is true. Producer intent root has native Windows
backslashes; Editor context has forward slashes. Desired-state root has the
same representation difference. Case-insensitive string comparison does not
normalize separators.

Intent SHA256b12afb2592766f2d056951f7ed15960f73757448f82993c193b98d209097b32f
matches marker removal_intent_sha256. Actual marker SHA256:
7bc81154a67604d0aa385e8976d85637c69817e4edef40d5b094fd5a6edfbf52.
Affected Editor/AICodedbManagerActionJournal.cs, Editor/AICodedbPaths.cs and
Tools~/codedb-instance-engine.ps1 worktree bytes equal extracted delivery bytes.
These observations exclude a wrong-Package/intent-hash mismatch for this failure.

Root cause is direct string comparison of a filesystem identity across two
production representations. PS-only41assertion evidence did not execute the
C# consumer; prior source review did not identify this representation conflict.
Existing Record Contract Consumer Closure Gate already requires the boundary.
The repair clarifies path semantics within that gate, without adding an approval
tier or Host-wide audit. Original failed human result and earlier evidence remain.

User approved the scoped contract/implementation/review plan with `同意`.
RETAINED-PATH-IDENTITY-TASK.md is the frozen repair. No evidence rewrite,
operational retry, process termination, real recovery or release acceptance.
