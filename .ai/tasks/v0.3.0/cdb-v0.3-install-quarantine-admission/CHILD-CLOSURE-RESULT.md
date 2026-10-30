# Prospective owned-child closure result

Date: 2026-10-26. Outcome: `FOCUSED_SOURCE_PASS / CONSUMER_NOT_RUN`.
Source base: `09d345d96ec782be2ac101016d8b75b14bce6000`.
Branch: `codex/install-quarantine-admission`.
Checkout: `<repository-root>/.worktrees/cdb-v03-install-quarantine-admission`.
Evidence belongs to an uncommitted, hashed source snapshot. This is not an
independent Verifier review, Unity gate or release acceptance.

## Resulting behavior

Before an operation-associated spawn, Supervisor persists the resolved
invocation and a unique attempt in optional `child_execution`, preserving
`CHILD_ADMITTED`. Actual spawn uses that executable. Only its owning direct
ChildProcess close callback records pid, exit code or signal and observation
time. Delayed OS identity remains separately recorded in `child`; a short
process may finish with null OS identity and attributable termination proof.

Install, removal, routine retention and the exact C# Uninstall reader recognize
the proof with their original authority and terminal gates. Conflicting, open,
legacy-null and incomplete observations remain blocked. A stale callback cannot
close a new attempt. Publication failure clears in-memory close authorization.
Recovery/exception after admission cannot manufacture output completeness from
close alone. Original failed command results remain failures.

The proof establishes direct-child termination only, not descendant absence,
Supervisor handoff, product success, selection or cleanup authority. Routine
retention remains limited to eligible completed routine history.

## Focused evidence

Canonical prefix:
`.artifacts/tests/cdb-v0.3-install-quarantine-admission/07-prospective-child-closure/`.

| Evidence | Result | Scope |
| --- | --- | --- |
| Original producer/admission/recorder/runner/finish | 11 checks PASS | Extracted production functions, controlled environment/process observations |
| Windows PowerShell 5.1 Install + removal readers | 54 checks PASS | 26 producer-derived cases, immutable input bytes, argv serialization and retention |
| Complete C# exact-action reader + strict JSON parser | 27 checks PASS | 26 cases plus original argv escaping; environment/action-journal seams stubbed |
| Native finite Node children | 2 cases PASS | Real owned ChildProcess/close with exit 0 and 7; delayed identity lookup deliberately synthetic absent |
| Quarantine admission regression | 30 checks PASS | Production admission, synthetic OS; `08-closure-admission-regression/` in the same task family |
| Retained MCP Install L0 regression | 17 checks PASS | Production records/convergence, synthetic OS/prerequisites, PocFixture; `.artifacts/tests/s40-retained-mcp-install/prospective-child-closure-l0/` |
| Existing Supervisor focused fixtures | PASS | S32 disposition, watch-manager context and S31-D terminal-session fixtures; worktree-local bounded outputs |
| Static | PASS | Node syntax, four changed PS scripts parsed by 5.1, git diff whitespace check |

Native cases use a 5-second child timeout and finish within the frozen 45-second
harness budget. Only task-owned finite Node children run; no crash/orphan,
Supervisor daemon, Provider, Unity or MCP experiment. The retention fixture
keeps canonical/open/failed/legacy records byte-for-byte and prunes only its
eligible task-owned completed records.

Cases include success/failure, open/legacy-null evidence, owner/operation/
attempt/hash/command/PID/time conflicts, timeout or incomplete output,
conflicting NO_CHILD, matching/conflicting captured identity, extra invocation
arguments, signal termination, unstarted state, interruption after close and
native short exits. Generic readers may accept a complete different invocation
as terminated; the exact C# Uninstall reader rejects extra args/Node invocations.

## Retained attempts and correction

`06-prospective-child-closure/` preserves the first producer/PowerShell pass.
Initial C# compilation stopped on CS0649 in a new fixture-only unassigned field,
not product code (`CSharp-failure.txt`). Explicit stub initialization yielded
`CSharp-02-result.json`, 25/25 PASS. No product validator was weakened.

Subsequent inspection identified that generic finish/recovery could otherwise
claim complete output after lost terminal publication. The bounded same-cause
correction marks new admitted execution output incomplete; `07` is the final
batch and adds that negative case and retention coverage. Failed evidence and
the four consumer history records were neither overwritten nor deleted.

## Stable source identity

All ten changed source/test/contract files are listed in canonical
`source-snapshot.json`. SHA-256:
`f8274bc854678251f7ab4d816555195e23fbcedcd36e3c649b58ab71bf663deb`.

| Production file | SHA-256 |
| --- | --- |
| `Tools~/codedb-project-supervisor.mjs` | `536ced981dd5ace32b564c452f6af91cf97da333a7ce890709e3b0da2bc84f7e` |
| `Tools~/codedb-instance-engine.ps1` | `530d1c3b63e595788b5ab7baf2748ece593f9eeaca6d14c714a0c2d7e03bd2b7` |
| `Tools~/materialize-codedb-host-payload.ps1` | `70d94d2d7fc57ca7dbe92ceed3395a59af10df7177c565374e3ecd31c1949b1d` |
| `Editor/AICodedbSupervisorTerminalEvidence.cs` | `73ac8815ca0e190161f77ed7df6a9cb7c7c0dae32a4206e7d9d79487faf1c539` |

Paths in the table are relative to `com.rice.ai-codedb/` in the isolated
checkout. The host-action contract documents additive record semantics. No
immutable payload/generation bytes changed.

## Remaining boundaries

Unity compile/Test Runner, real Install/Uninstall, real client MCP, external
delivery/consumer mutation, independent review, commit/push/board sync and
release are NOT_RUN. Offline C# compilation does not substitute for Unity.

`CodedbTest_2` remains the retained blocked historical sample. Its four
`CHILD_ADMITTED`/null-child records lack new close proof; this repair does not
release them. After snapshot review/delivery authorization, a clean project can
validate normal lifecycle separately. Its success would not establish old
history recovery or erase the retained failure evidence.
