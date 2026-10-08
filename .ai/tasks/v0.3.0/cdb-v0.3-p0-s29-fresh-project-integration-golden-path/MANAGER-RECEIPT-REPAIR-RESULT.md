# S29 Manager receipt repair - Coder stopped snapshot

Date: 2026-10-08. Final source identities captured at 02:32:57 UTC.
Base HEAD: `651f9b3b4a8af3108823036107f1d76bc450f760`.
Disposition: SOURCE_IMPLEMENTED / STATIC_CHECKS_PASS / UNITY_NOT_RUN /
INDEPENDENT_VERIFIER_PENDING / GUARDED_OUTPUT_BREACH. Whole S29 remains PARTIAL.
No commit, export, publication, real receipt edit, process probe or Unity action.

## Implemented envelope

- `Paths`: fresh action identities reset stage/terminal flag and dispatch tracker;
  same-action nested scopes preserve the explicit stage; disposal restores every
  prior field. Detached contexts retain project/Package roots but have no Manager
  identity, effect/confirmation authority, terminal stage or dispatch tracker.
  An async-local receipt-root scope isolates the new tests from machine journals.
- `EditorLifecycle`: both reconcile dispatch and the private automatic Supervisor
  command/fallback boundary enter that detached context. Existing lifecycle policy
  and project/Package capture remain in force.
- `ProcessRunner`: every observed stage goes through the existing strict reader.
  Completed nonterminal stages are collected, not silently ignored. The only
  admitted multiple-stage compatibility case is exactly the diagnosed failed
  INSTALL / successful DryRun / pre-effect rejected UPGRADE semantic shape.
  Additional checks bind materializer script path, arguments hash, command hash,
  effect/authority and command/result semantics. The returned result is the original
  INSTALL object/output; later COMPLETE cannot replace its PENDING mutations.
- `Actions`: one predicate identifies the strict failed INSTALL candidate/effect
  shape for the aggregate and retained historical presentation.
- `ManagerActionJournal` / `ManagerWindow`: validated historical failure is retained
  as a completed failure plus a PENDING historical warning after Package replacement.
  Normal admission can proceed only through its existing independent authority;
  removal still needs separate confirmation and the existing current/live gate.
  Conflict preserves original context from a validated marker or successfully
  validated original receipt context. Otherwise the banner says original Package
  unavailable; current Package is not labeled original.
- Host Action Execution contract: bounded section appended. The inherited first
  28,222 bytes reproduce their baseline SHA256 exactly (see identity table).

All aggregation is derived on read. No new receipt schema, writer, durable summary,
parallel admission owner, historical rewrite, automatic replay or live cleanup.

## Evidence actually obtained

- One scoped `git diff --check` across all nine allowlisted paths: PASS, exit 0.
- One focused source assertion batch: 12 PASS. Assertions checked strict-reader
  wiring, three-stage cardinality, original INSTALL return, removal of the silent
  nonterminal skip, admitted argument-hash binding, both lifecycle isolation sites,
  stage restoration, retained historical result, isolated fixture root, shared
  serializer accessibility, 19 declared Editor cases, and exact inherited contract
  prefix. These are source assertions, not execution of the C# behavior.
- Initial implementation was followed by source-only same-cause refinements:
  private lifecycle command isolation and replacement of an already recovering
  matching session from a freshly validated historical failure. One pre-execution
  mechanical correction qualified the reused fixture serializer in its actual
  existing test class and made that serializer internal. No failed semantic test,
  blind retry or repeated unchanged behavioral batch occurred.
- L0: DEFERRED. Direct closure exposes Editor/NUnit tests and no applicable existing
  pure harness. No substitute C# or external Unity test platform was invented.
- L1 / Unity C# compilation / EditMode / runtime / real recovery / live removal /
  full regression: NOT RUN. All newly added Editor tests below are human-owned.

## Human test manifest (19 cases, none run)

In `AICodedbProjectSettingsTests` in `AICodedbManagerUiTests.cs`:

1. `ManagerReceipt_FailedInstallRestoresOriginalResultAndRemovalGate` (4 cases:
   one versus three stages, unresolved current index versus resolved marker).
   Includes both stage creation orders, real production receipt/journal readers,
   replacement Package, session completion, original result and PENDING preservation,
   immutable resolved fixture bytes, removal presentation, cancellation confirmation
   and a fresh separately attributed action.
2. `ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage` (8 cases:
   pending, malformed, identity mismatch, altered arguments, extra nonterminal
   mutation, nonterminal historical follow-up, mutating UPGRADE, duplicate INSTALL).
3. `ManagerReceipt_ConflictWithoutAuthenticatedContextLabelsOriginalUnavailable`
   (1 case).
4. `ManagerReceipt_SingleStagePreservesNormalTerminalAndUnknown` (3 cases:
   successful terminal, pending claim, completed nonterminal).

In `AICodedbEditorLifecycleTests`:

5. `LifecycleExecutionContext_DetachesInheritedManagerStateAcrossAwait` (2 cases:
   outer action terminal true/false).
6. `ActionContext_NewIdentityResetsStageAndRestoresOuterScope` (1 case).

Fixtures use unique temporary contexts and an async-local temporary journal root;
the existing synchronous session fixture restores the saved live session without
editing its state. No `C:/fixture/project` or real validation/machine journal is
used by these new tests. Fixture writes are test code only; they were not executed.

## Review attention and guard accounting

The compatibility classifier is intentionally bounded. Multiple completed-stage
sets outside the exact three-stage shape remain Conflict, including nonterminal
mutating stages that the former reader silently ignored. Single-stage terminal
behavior is retained. Independent review must assess this boundary against the
frozen normal-terminal and additional-mutation invariants; no claim of broad
multi-command historical recovery is made.

Guard deviation: several early combined source-read outputs exceeded the normal
200-line target despite each constituent slice being bounded; one combined search
output exceeded 50 matches. Reviewing accumulated output late in the turn indicates
the cumulative 128 KiB output envelope was likely exceeded. Exact cumulative bytes
were not instrumented, so compliance cannot be certified and is NOT claimed.
Further source exploration stopped when this was recognized. Required final hash
metadata and this report were then produced. Earlier evidence was not erased,
replayed, or relabeled to manufacture compliance. The initial single-suffix contract
hash calculation used the wrong newline assumption; the subsequent bounded check
proved the actual original byte prefix exactly, with no contract content rewrite.

This report is not a guarded-review PASS. Parent/User disposition of the guard
breach and independent review remain required. No request was made for developer
changes from a concurrent reviewer; Coder now stops for the stable-snapshot review.
F-IMC-01/P3, human Unity acceptance and release acceptance remain DEFERRED.

## Exact SHA256 identity manifest

Paths are relative to `com.rice.ai-codedb/`. Only the contract was already dirty
among these nine paths. Other inherited dirty files were not edited by this Coder.

| Path | Baseline SHA256 | Final SHA256 |
| --- | --- | --- |
| Editor/AICodedbPaths.cs | EB571172BAC6AFD7DD34EC85F3088D8A0F6A6FB71505A8FF67336EFBBF858B28 | C6735CE5B81886C7FDD100BCA460E134346733D35E4F7E8B6D4BEF59458565CA |
| Editor/AICodedbEditorLifecycle.cs | 733ED2AB97EDBFF21D52AC3D5CE236A31B803248843332CAD5F138E3DC8F9120 | F6AEDEF76CC029CC3F046F97A30F739AEDC4B5EA695F6948CCD1F0BA35FAF765 |
| Editor/AICodedbActions.cs | 27EEE0278233E1A89FA3CF29363D4D941548D5CE692617EF3DD7FAE542F6C529 | E61A9C7D43BFE3B40CE69408B0B0F50E7803E3641CFC690E84374DCC469C29FC |
| Editor/AICodedbProcessRunner.cs | 96D0213CC8DFFE5D83DF757117D5A89B62A2FFBAF0196524E1D338089FF84265 | 05E33DA855C64391094B6CC4FC5609CC6C60C7D87EF309833A6EAD8E3DC67544 |
| Editor/AICodedbManagerActionJournal.cs | E03AD95304E32C82B861EBAFB6391502CA65F217105478114C75C3C55EF026CF | F9CB0A93858542CCE3173DF0F1EDB1186FA56C4448E414642DBF5D3C2B7A14EC |
| Editor/AICodedbManagerWindow.cs | B53F80837C79CCFE9D03B45EDCE43B52D2678CEBD78DBC9C3DEAFEB8AD50043D | 2C90018797EA2336A4BFDB9C28137FDAFC739ACFBFA073C761BF58D02EF7156B |
| Tests/Editor/AICodedbManagerUiTests.cs | 98DBC7ADC4D09895EB555785A2C512E34A882D2629CC405C2E0CCC9585A8AD70 | 0F4C7665ECC43AC814B20C3DDBBB8E341EC6344A3E1E227891241C9412982FD0 |
| Tests/Editor/AICodedbEditorLifecycleTests.cs | 0C0E21B57232F12A96B41C1BDD9DFD7403FC433844552B8E5A40701266F73208 | 59BF754DF11E63F9EE3755EA4A8700069172DDA4D189F1885736BB5BFA4D2068 |
| Documentation~/v0.3.0-p0-host-action-execution.md | DB3208BD3872A013CB8AAFC8DF4A611090D7AFB7F67DD129454A439E34B94AE9 | C44546077E57B4F55F6F3BD642983461F3D577939FB6E2CDEA934DE136D94DAC |

Stable stopped snapshot: no further source edits or checks after the final manifest.
