# S29 retained path identity compile fix

2026-10-09. SOURCE_FIX_READY_FOR_DELIVERY.

Human Unity import exposed CS0103 at `AICodedbManagerUiTests.cs:1506`:
`SerializeObject` was unqualified. The existing helper is owned by
`AICodedbControlContractMigrationClassifierTests`; the call now uses that
qualified symbol. No runtime logic, path comparison helper, evidence file,
Payload identity, or unrelated test changed.

Base commit: `9330930b037c5ab9ed73829c9580965280bcf997`.
Fixed test SHA256:
`25c8b5a72b69567591f6e000d0b329d86f92aeb68065f3fff88b759a69804fa4`.

Validation was limited to the exact one-line diff and whitespace check. The
previous Package is immutable; this source fix requires a new scoped commit,
new Package export, and a fresh Unity import. No test or real action was
rerun yet.
