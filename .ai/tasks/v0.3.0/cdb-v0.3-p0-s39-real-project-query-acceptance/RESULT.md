# S39 preparation result

Date: 2026-10-20.
Current status: `FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_BLOCKED`.
The initial nested-project preparation below is historical and superseded by
the external-route update at the end of this record.

## Prepared changes

- Frozen task envelope in TASK.md.
- Added project `Assets/CodeDBAcceptance/S39QueryProbe.cs`, a seven-line static
  C# class with no Unity callback, scene attachment or external dependency.
- Prepared the human import checkpoint and exact new-chat instruction in
  CLIENT-HANDOFF.md. No new chat was created or messaged by the parent.

## Static evidence

- The literal marker occurs once in project Assets C# source, on line 5:
  `        public const string Marker = "CODEDB_S39_CURRENT_LIFECYCLE_20261020";`
- Sample SHA-256:
  `8724e76c9d937318d2cd24cc897cb74ef7ad16744af98b43e8efd3d932d1cf47`.
- Manifest and lock both reference
  `file:../../../s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`;
  the reference resolves to the existing Package.
- Project MCP configuration still registers `codedb-current-lifecycle` with
  the project wrapper and a 120-second startup timeout.
- Selected instance and activation epoch match the task's S38 binding.
  The actual `instance.json` SHA-256 matches the pointer:
  `b448c2c6a2df05a48fc2e58af249a05a491e3116fd1eaf816999643f5f47f453`.
- Sample line/content and uniqueness assertions passed. Scoped whitespace
  checks passed for the initial task, handoff and sample.

These checks prove preparation and on-disk bindings only. Unity import/C#
compilation, client tool injection, live status identity and query execution
have not been observed in S39. No direct wrapper probe or runtime RPC ran.
Unity-generated metadata is owned by the human import step.

## Handoff

Configuration clarification after user review: the nested project path is not
an isolated Codex configuration environment. A targeted ancestor-file check
found only the Unity project's `.codex/config.toml` in the inspected chain;
there was no repository-root or intermediate project config. This does not
exclude user-level configuration or establish the effective config in a new
client. CLIENT-HANDOFF.md now explicitly requires target-server binding checks
and forbids treating a new chat as proof of configuration isolation. No project
move, runtime reset or configuration edit was performed.

- Current task: S39 real project Codex query acceptance.
- Current status: PARTIAL / HUMAN_IMPORT_AND_NEW_CHAT_PENDING.
- Next notification: User.
- Next action: in the exact current-lifecycle Unity project, allow import and
  compilation; confirm no new errors and Manager Ready. Then create a new
  Codex chat at that project root and paste CLIENT-HANDOFF.md's instruction.
- Human action required: import checkpoint and target-root chat provisioning.
  The agreed single status/query sequence needs no repeated authorization.

Keep S38 lifecycle PASS and the periodic-status FOLLOW-UP separate. This result
does not close standalone external-project discovery, performance or release.

## External-route update — user-selected CodedbTest_0

The user chose standalone acceptance outside the repository and created
`<external-acceptance-root>/CodedbTest_0`. Its exact local binding is in the
user message. TASK.md and CLIENT-HANDOFF.md now target this project; the earlier
current-lifecycle sample/result remains historical. No S38 state was copied.

Read-only baseline:

- Unity 2022.3.62f3 (96770f904ca7), no CodeDB manifest dependency, no AIWork,
  no project Codex configuration, and no Assets C# source.
- No `.git`, `AGENTS.md` or `.codex/config.toml` was found on the inspected
  project-to-drive-root ancestor chain. User/global config is not excluded.
- Editor PID 37824 and import workers 54196/44644 were running at inspection;
  `Temp/UnityLockfile` existed. No process was stopped.
- Original manifest SHA-256:
  `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1`.
- Original lock SHA-256:
  `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6`.

External delivery preparation completed:

- Copied the existing exact S37 ZIP to
  `<external-acceptance-root>/Packages/d856a8f/com.rice.ai-codedb.zip` and
  extracted it there; no new source build/export occurred.
- Original and copied ZIP SHA-256 both match
  `97aecd28ff47656a9b6cd66666f6c9030b95a8f4b5a98cf8cf68f588058031a9`.
- All 623 extracted files match their ZIP entry SHA-256. Entries were checked
  to remain under the new delivery directory before extraction. Existing
  destination overwrite was forbidden.
- Extracted metadata is `com.rice.ai-codedb`, `0.3.0-preview.5`.
- Proposed `file:../../Packages/d856a8f/com.rice.ai-codedb` resolves from this
  project's Packages directory to the independent extraction.
- Project configuration and Assets have not been changed. Backup and sample
  preparation wait for the closed-Editor checkpoint. No runtime probe ran.

Current task: S39 independent Package consumer and Codex query acceptance.
Current status: EXTERNAL_PROJECT_CONFIGURED / HUMAN_IMPORT_PENDING.
Next notification: User.
Next action: open CodedbTest_0, wait for Package import and C# compilation,
then report the Console and Manager baseline before Install.
Human action required: import/compile checkpoint. First Install and real-client
query remain subsequent human/client gates; none is claimed passed here.

## External project configuration result — 2026-10-20

The human reported that CodedbTest_0 was closed. A read-only checkpoint found
zero Unity processes for that project and no Unity lock file. The original
manifest and lock hashes matched the external baseline. The parent then made
the authorized consumer configuration change:

- Backups were written under `<external-acceptance-root>/.backups/` with the
  original manifest hash
  `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1` and
  lock hash
  `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6`.
- Manifest and lock now reference the independently extracted Package through
  `file:../../Packages/d856a8f/com.rice.ai-codedb`; the lock entry is local,
  depth 0, and has no child dependencies. The Package resolves and reports
  `0.3.0-preview.5`.
- The manifest testable list now contains `com.rice.ai-codedb`.
- Added the inert sample `Assets/CodeDBAcceptance/S39QueryProbe.cs`. Its marker
  occurs once and its SHA-256 is
  `76442fb3d5d7c950f8836f152bfd273c9b9a00c06d1d287eba036dc6e5d23842`.
- Configured manifest SHA-256:
  `6ff38dacfb02aaebc7122ac24e1ec0677b1e66f4f06fdaef923fc62a077a8f51`.
- Configured lock SHA-256:
  `e39be4e16dd7c41024445132a6b32725ed328c30e63503c94fb856ead82b7200`.

Static reference, lock/source/depth, testable, package-resolution, sample
uniqueness and backup checks passed. Unity import, compilation, Manager state,
first Install, generated registration, runtime identity and real-client query
remain unobserved. No Unity process was launched or stopped by the parent.

## Human import baseline — 2026-10-20

The user reports that CodedbTest_0 opened with no errors. The attached Manager
screen shows the expected fresh-project surface: Package `0.3.0-preview.5`,
`Not installed`, `Install CodeDB` available and no recent command. It also shows
the generic uninstalled-state wording that setup could not finish. Because no
Install action has occurred in this project, this wording is retained as a
baseline diagnostic and is not classified as an Install failure.

The parent read-only checkpoint found one Unity process for CodedbTest_0,
`Temp/UnityLockfile`, no `AIWork/` and no project `.codex/`. Manifest/lock
hashes remain unchanged from the configured S39 values and the sample exists.
See `INITIAL-HUMAN-RESULT.md` for the attributable human evidence.

Current status: `IMPORT_BASELINE_PASS / FIRST_INSTALL_PENDING`.
Next action: human performs the one agreed first Install; parent then checks
the original terminal, selected instance and independent Ready observation.

## First Install and Ready closure — 2026-10-20

The human reports Ready and supplies the installed Manager screenshot. The
parent correlated the successful original Install terminal (exit 0, no timeout
or output loss), selected READY instance, committed activation and generated
project-local registration. Details and original receipt hashes are retained
in `FIRST-INSTALL-HUMAN-RESULT.md`. The screenshot is a cached UI Ready
observation; no new parent readiness probe was performed. Original cleanup
status remains `PENDING` and is not a cleanup-complete claim.

- Actual server: `codedb-codedbtest-0`.
- Selected instance: `2414c73c2fbb47f4b664c1bdbcad5969`, generation `poc.43`.
- Activation epoch: `4ad2120d1559487f8e54c015685496f6`.
- Sample hash, unique occurrence at line 5, Package references and manifest/lock
  hashes remain consistent with the configured external-project baseline.
- Replacement parent chat: `01a158ae-66a6-78d3-8200-f1061a98f503`, replacing
  `01a1574f-99dd-7463-a495-3ce0d736e0d6` after predecessor service failures.

Current status: `PARTIAL / FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_PENDING`.
Next action: human creates the target-root client chat and uses the finalized
CLIENT-HANDOFF.md instruction. No repeat Install is required. Real client tool
injection/status/query, performance and release acceptance are not claimed.

## Client attempt 01 — stopped before tool invocation

The human returned the completed result from `验收 S39 MCP 查询`, chat
`01a158b6-693a-7901-9da3-fda6d8a55490`. Its cwd and on-disk configuration,
pointer, manifest hash and expected identities match. Target project tools were
not exposed. Both target status and query call counts are zero; there is no
query response or attributable new client lease. No substitute services were
called. This is not an empty-query result.

Parent read-only inspection of that chat's desktop startup log then found
`codedb-codedbtest-0` starting at `2026-10-20T09:48:32.126Z` and failing at
`09:48:32.371Z` with `handshaking with MCP server failed: connection closed:
initialize response`. The target registration therefore reached the client's
startup path. The failure is before successful initialize/tool exposure, not
an established post-tools-list injection failure. The deeper process/stdio
cause is unproven. The user config currently marks this exact project trusted;
that current observation does not reconstruct every effective startup layer.

See CLIENT-ATTEMPT-01-RESULT.md for attribution, exact log message, limitations
and route handoff. First Install/Ready remains PASS. Real-client acceptance is
BLOCKED; the approved single client attempt has ended. No parent runtime probe,
retry, configuration/source change, process termination or new chat was made.

Current status: `PARTIAL / FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_BLOCKED`.
Next action: User/Planner alignment on a bounded startup/initialize diagnosis
envelope. A new external validation attempt is a separate gate.

## Authorized diagnosis 01 — source cause identified

The user approved read-only diagnosis. STARTUP-DIAGNOSIS-01.md records the
confirmed defect: the installed stable wrapper statically imports a sibling
shared module that is present in the delivered payload but absent in the
project. The instance activation publisher writes the stable wrapper without
that dependency; candidate MCP verification directly probes the generation
worker and bypasses the registered stable entry. Wrapper hash-only validation
does not catch the missing module.

Evidence is source/filesystem/retained-log evidence, not a fresh runtime
reproduction. Current source and frozen delivery match for the wrapper and
instance engine. No implementation, consumer runtime change or client retry
occurred. Continue using CodedbTest_0 for diagnosis and eventual client
regression; a separate clean-install gate depends on the agreed repair.

Current status: `REAL_CLIENT_QUERY_BLOCKED / SOURCE_CAUSE_IDENTIFIED / REPAIR_SCOPE_PENDING`.
Next action: align the stable-entry dependency design and narrow repair
envelope before implementation/delivery or another client attempt.

## Authorized stable-entry source repair — completed

The user approved the frozen repair scope. STABLE-ENTRY-REPAIR-RESULT.md records
SOURCE_FOCUSED_PASS: transactional dependency publication/rollback, operational
closure validation, lifecycle preservation/removal, and a real stable-entry
post-commit probe that preserves COMMITTED effects on failure. Focused evidence:
25 PS checks, 3 Supervisor cases, 2 Node entry cases, 1 production PS probe case,
and 6 standalone C# contract cases. This is not Unity compilation or real
Provider/Codex acceptance.

Current development payload hash inconsistency was preserved; successful
fixtures use the existing frozen immutable delivery as read-only input. Exact
Package delivery closure and existing-consumer bootstrap recovery need an
explicit next route. No consumer, frozen delivery, version or generation was
changed; no export, commit, push, Unity run or real-client retry occurred.

Current status: `PARTIAL / SOURCE_FOCUSED_PASS / REAL_CLIENT_QUERY_BLOCKED`.
The existing CodedbTest_0 is sufficient for the later regression; a new Unity
project is not required by this result. CLIENT-HANDOFF.md remains historical.

## Delivery preparation — candidate verified

DELIVERY-RECOVERY-PLAN.md freezes the exact candidate and proposed delivery/
single-module historical recovery. The candidate uses HEAD's coherent poc.43
payload and only this repair's delta, preserving all unrelated dirty work.
Its release closure (60/60 sources), production admission, path provenance,
and own focused harness PASS; focused run r-5110a391. No version/generation
regeneration is required by this Package-side change. Test-root resolution was
adjusted to keep extracted-candidate fixtures inside the enclosing repository.

Current status: `SOURCE_AND_CANDIDATE_FOCUSED_PASS / DELIVERY_AUTHORIZATION_PENDING /
REAL_CLIENT_QUERY_BLOCKED`. No commit, export, external reference switch,
bootstrap restoration, Unity execution, MCP attempt or process stop occurred.
