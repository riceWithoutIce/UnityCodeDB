# cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance Result

## Phase A Status

`IMMUTABLE_GENERATION_TRANSITION_REQUIRED`

Phase A stopped during bounded admission before source, test, Package metadata,
or payload edits. No candidate was formed and no evidence batch was run.

Execution profile: `v0.3.coder.deep` on the existing `REUSE_ONLY` binding.
Human precondition: `UnityValidationProject/` was reported closed by the human;
the Coder did not inspect process state.

## Bounded Admission

- Branch: `codex/v0.3.0-legacy-workflow` (`PASS`).
- HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63c` (`PASS`).
- Scoped production delta before S17 edits: only
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`, `199/12`.
- S14/S14r task directories remain read-only, untracked provenance. They were
  not rewritten or admitted as source snapshots.
- The current S14r engine input contains the intended PowerShell consumer:
  it validates a versioned Supervisor operational-readiness observation and
  no longer recomputes Coordinator operational readiness.
- The task-card engine identity
  `702a5e5c4748136cf292f962eebadb899fdef9b` has 39 hexadecimal characters and
  therefore cannot be a Git SHA-1. The one canonical single-path binary-diff
  calculation returned the valid 40-character identity
  `c702a5e5c4748136cf292f962eebadb899fdef9b`. It is the task literal with the
  missing leading `c`, but this result does not silently rewrite or claim an
  exact match to malformed frozen metadata. Planner must correct/admit that
  identity explicitly in any continuation.

### Authority and consumer contract

| Fact | Authority | Bounded consumer path | Admission |
| --- | --- | --- | --- |
| Static Package/project admission | PowerShell materializer | Lifecycle product status | Present |
| Runtime operational readiness | Node Supervisor `resolveOperationalReadiness` | Authenticated observation passed to PowerShell, Bridge, Lifecycle | Present on ordinary admitted materializer path |
| Observation identity/revision | Node Supervisor | PowerShell validates identity; Bridge parses; Lifecycle binds product output to the same revision | Present |
| Presentation | Lifecycle-cached composite | Manager cache-only UI | Present in committed HEAD |
| Recovered materializer verification | Node Supervisor | `verifyRecoveredOperation` invokes `Verify` | Incomplete: the recovered `Verify` child is not given the authoritative observation environment supplied by ordinary `runMaterializer` |

The inherited engine input is therefore preserved and semantically admitted as
the S14r PowerShell side of the authority refactor, but it is not frozen into a
candidate because the task identity is malformed and candidate generation
closure cannot be formed inside the current authorization.

## Candidate Contract Stop Condition

Current exact metadata and immutable closure:

| Artifact | Version/identity |
| --- | --- |
| `package.json` | `0.2.5-preview.5`; SHA-256 `4932ecb76b699ae3d917d4fbbde9513691bc8b62f2a0f1e39bf4b3bf70d31957` |
| `Payload~/payload-manifest.json` | Package `0.2.5-preview.5`, payload/generation `poc.34`, sequence `34`; SHA-256 `c49bb41eb36049ed16f500b71654e93b2cdd25bc11984f07e4938995e2ac6b91` |
| `Payload~/Generations/poc.34/generation-manifest.json` | Package `0.2.5-preview.5`; SHA-256 `265ab443207282d0b33b4231e472b310ab83f11d87ca3b6d2667a52bb9077b80` |
| `Payload~/host-current.json` | Package `0.2.5-preview.5`, generation `poc.34`; SHA-256 `78f4fadb9c08c3382dcf7f7036a2e5596b9a30a9b772c5fbdc2f20910d4fb9df` |

Both immutable-generation and pointer hashes exactly match their entries in
the payload manifest.

The current strict Package contract requires the payload manifest, generation
manifest, and current pointer package versions to agree. Changing only the
allowed candidate metadata to `0.3.0-preview.1` would therefore make the
Package fail closed. `poc.34` also embeds `0.2.5-preview.5` and/or `poc.34` in
its generation manifest, instance worker, machine-provider contract,
host-use gate, and common PowerShell script. Editing those published bytes is
forbidden.

Changing validators to ignore this mismatch would alter the established
generation identity contract and would require updating
`Tests~/test-codedb-package-boundary.ps1`, which is outside the current Phase A
write allowlist. That is not treated as an implicit compatibility bypass.

Consequently an internally coherent `0.3.0-preview.1` candidate requires a
new immutable generation. The task-card stop condition applies.

## Exact Same-S17 Expansion Proposal

Planner/User may separately authorize one continuation of this S17 Phase A
with the following frozen expansion; no new task is required:

1. Correct the malformed inherited engine identity to
   `c702a5e5c4748136cf292f962eebadb899fdef9b` after independent review, then
   bind the continuation to the same HEAD and current engine bytes.
2. Allocate successor generation `poc.35` with package version
   `0.3.0-preview.1`, payload version/generation `poc.35`, sequence `35`, and
   the existing bootstrap protocol. Create
   `Payload~/Generations/poc.35/**` from the reviewed `poc.34` closure, changing
   only generation/package identity-bearing bytes and recomputing its manifest
   hashes. Keep every `poc.34` byte unchanged.
3. Add exact write authorization for
   `Payload~/Generations/poc.35/**`, `Payload~/host-current.json`, and
   `Tests~/test-codedb-package-boundary.ps1`. Existing S17 allowlisted paths
   remain unchanged.
4. Update `Payload~/payload-manifest.json` to target `poc.35`, bind every new
   source/target hash, retain `poc.34` as an exact reviewed transition and
   retired generation, and update `host-current.json` to the new generation
   manifest hash. Update `package.json` and `CHANGELOG.md` to the exact
   `0.3.0-preview.1` candidate.
5. Update only directly coupled Node, PowerShell, and Package-boundary fixtures
   for the new current identity while preserving all historical
   `0.2.5-preview.5` transition identities.
6. In the existing allowed Node Supervisor and focused fixture, pass the
   current authenticated operational-readiness observation into recovered
   materializer `Verify` exactly as the ordinary admitted materializer path
   does, and assert that recovery uses the same observation rather than a
   second readiness authority.
7. Reissue a bounded Phase A budget: one static/source batch, one consolidated
   stop-on-first-failure L0 batch containing only the affected Supervisor
   recovery, operational-readiness, payload-contract, and Package-boundary
   members, one candidate contract parse, one final scoped diff check, and one
   final candidate identity. No Unity or later phase is implied.

## Commands And Budget

- Bounded preflight commands: branch, HEAD, one scoped status/stat query, one
  engine binary-diff identity, named S14/S14r terminal-record reads, and direct
  source/contract reads. All completed with exit `0`.
- Candidate baseline parse/hash command: exit `0`; internal parse stopwatch
  `226 ms`; tool-observed wall time `1.8 s`.
- No command was retried. No test process or external business process was
  started.
- Some parallel named-path inspection output was tool-truncated. Exact captured
  byte count is unavailable, so output-budget compliance is not claimed beyond
  the facts that no logs, history scan, repository-wide diff, or protected
  runtime state were read.

| Evidence/budget | Used | Result |
| --- | ---: | --- |
| TASK read | `1/1` | Complete |
| bounded admission | `1/1` | Stop condition found |
| structural repairs | `0/2` | Not started |
| Phase A static/source batch | `0/1` | NOT RUN |
| Phase A focused L0 batch | `0/1` | NOT RUN |
| candidate contract/final identity | `0/1` | NOT RUN; no candidate exists |
| final scoped status/diff check | `0/1` | NOT RUN after stop condition |
| corrected retries | `0` | Not authorized/used |

## Deferred And Protected Boundaries

Phase B/C/D, C# L1/EditMode, full regression, Unity, Unity MCP, real Codex,
third-party project, publication, commit, tag, push, protected validation
runtime reads, runtime cleanup, process termination, and Verifier contact were
all `NOT RUN / DEFERRED`. `UnityValidationProject/` was not opened, operated,
enumerated, or modified. No existing generation, production source, test,
Package metadata, task contract, or predecessor record was modified; the only
write is this S17 `RESULT.md`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A`
Current status: `IMMUTABLE_GENERATION_TRANSITION_REQUIRED`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the malformed engine identity and the exact same-S17 `poc.35` expansion, then seeks explicit human authorization before any continuation.
Human decision or authorization required: corrected frozen identity; successor-generation/allowlist expansion; renewed Phase A evidence budget; all later Unity, publication, Verifier, commit, tag, push, and promotion transitions.

## Planner Decision - Phase A Successor Generation Continuation

Decision date: `2026-09-11`.

The user authorized one continuation of this same S17 Phase A. The original
bounded-admission record above is preserved. This section corrects its frozen
metadata and records the new authorization; it does not retroactively convert
the stopped attempt into a completed Phase A result.

### Frozen identity correction

- Actual committed HEAD:
  `5587f4739426f11fa859ced02e5e6164b0429a63`.
- The earlier task/result literal
  `5587f4739426f11fa859ced02e5e6164b0429a63c` contains 41 hexadecimal
  characters and an extra trailing `c`. Its `PASS` wording is superseded by
  this correction. The repository HEAD itself did not drift.
- Independently recalculated canonical single-path binary-diff identity for
  `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`:
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- The earlier task literal omitted the leading `c`; the Coder's calculated
  engine identity is admitted as the corrected frozen input.

### Authorized continuation

- Create only immutable successor generation `poc.35` for exact local
  candidate `0.3.0-preview.1`; keep every `poc.34` byte unchanged.
- Expand the Phase A write ceiling only to
  `Payload~/Generations/poc.35/**`, `Payload~/host-current.json`, and
  `Tests~/test-codedb-package-boundary.ps1` in addition to the existing S17
  allowlist.
- Preserve strict Package/generation/pointer identity validation. Do not widen
  the allowlist into permission to relax the contract or rewrite historical
  `0.2.5-preview.5` identities.
- Close recovered materializer `Verify` forwarding of the same authenticated
  Supervisor operational-readiness observation used by the ordinary admitted
  path.
- Renew exactly one Phase A static/source batch, one consolidated focused L0
  batch, one candidate contract parse, one final scoped diff check, and one
  final candidate identity calculation. No automatic retry is authorized.

Unity, Unity MCP, C# L1/EditMode, Phase B/C/D, Verifier routing, commit, tag,
push, publication, and release promotion remain `NOT AUTHORIZED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A successor-generation continuation`
Current status: `AUTHORIZED / READY_FOR_CODER`
Next notification: existing `v0.3.coder.deep` binding by manual transfer
Next action: Coder executes the authorized continuation once and appends its
stable result without starting Unity or contacting Verifier.
Human decision or authorization required after completion: any corrected
retry; affected EditMode; Phase B; Verifier routing; commit, tag, push,
publication, promotion, and final acceptance.

## Phase A Successor-Generation Continuation - Admission Stop

Decision date: `2026-09-11`.

Effective status:
`ROUTE_REASSESSMENT_REQUIRED / PROVIDER_PACKAGE_RANGE_TRANSITION`.

The continuation stopped before creating `poc.35` or editing any production,
test, Package, pointer, or payload file. The renewed evidence budgets were not
consumed.

### Corrected frozen identity admission

- Branch: `codex/v0.3.0-legacy-workflow` (`PASS`).
- HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63` (`PASS`), command stopwatch
  `192 ms` for the combined HEAD/branch check.
- Inherited engine single-path binary-diff identity:
  `c702a5e5c4748136cf292f962eebadb899fdef9b` (`PASS`), command stopwatch
  `170 ms`.
- `poc.34` HEAD tree identity:
  `cb3f56d08ea76f9556465c7d78b029670c905629`.
- Scoped `poc.34` worktree status count: `0`; `poc.35` existed before this
  continuation: `false`. Combined command stopwatch: `252 ms`.
- Exact scoped status contained only the inherited engine modification and the
  S17 task/result records. No unexpected allowed production/test path was
  dirty.

### Newly established blocking contract

The reviewed machine Provider contract fixes all of these values:

- Provider version: `0.5.0-28e3912`.
- Provider commit: `28e3912d5cd67ff3499734984f3e3d626a204796`.
- supported Package range: `>=0.2.5-preview.5,<0.2.6`.

`0.3.0-preview.1` is outside that semantic-version range. This is not merely a
fixture literal:

1. `Tools~/materialize-codedb-host-payload.ps1` resolves the Package-owned
   flat target
   `AIWork/codedb/shared/codedb-machine-provider-contract.ps1` and calls
   `Get-CodedbMachinePrerequisiteStatus -PackageVersion
   $Manifest.PackageVersion`.
2. The flat contract source is
   `Payload~/AIWork/codedb/shared/codedb-machine-provider-contract.ps1`, which
   is outside the continuation write allowlist. It both enforces the semantic
   range and requires the external machine Provider manifest to declare the
   exact same minimum and maximum.
3. The immutable-generation instance worker independently requires its
   reviewed Provider manifest range and currently requires Package version
   `0.2.5-preview.5` to equal that minimum.
4. The materializer fixture models the same exact range. Therefore copying the
   current closure to `poc.35` and changing only successor identity bytes would
   produce a candidate that deterministically fails prerequisite admission.

Changing the flat contract alone would not prove compatibility: the installed
external Provider manifest is a separate signed/reviewed prerequisite and the
current contract requires its exact declared range. This task prohibits reads
or mutations of that global Provider state, and no authorization establishes
a Provider artifact whose manifest supports `0.3.0-preview.1`.

Silently widening the Package-side range, retaining the old Package identity
inside `poc.35`, or bypassing the equality/range checks would violate strict
Provider admission and would make the exact-preview normal path unusable or
unproved. No such change was made.

### Required Planner reassessment

Before this S17 Phase A can continue, Planner/User must select and freeze a
Provider compatibility transition. A safe continuation requires all of the
following to be explicit:

1. The reviewed Provider artifact/version/commit and immutable manifest whose
   declared Package range includes `0.3.0-preview.1`; binary compatibility may
   not be inferred from the existing `0.5.0-28e3912` artifact.
2. The exact package-side Provider contract constants and whether both the
   flat payload contract and new `poc.35` generation contract bind a new
   Provider version or an independently reviewed manifest-only transition.
3. Write-allowlist expansion for
   `Payload~/AIWork/codedb/shared/codedb-machine-provider-contract.ps1` and any
   other exact Provider-contract source/fixture paths selected by that design.
4. Updated payload-manifest hashes for every changed flat and `poc.35` source,
   while retaining all `poc.34` bytes and historical transition identities.
5. A fresh bounded evidence budget that proves accepted/rejected Provider
   ranges, exact manifest identity, successor generation closure, and the
   previously authorized recovered-`Verify` observation forwarding in one
   coherent Phase A snapshot.

Planner may keep this as one S17 continuation, but the new Provider identity
and compatibility authority must be frozen before Coder edits. Merely granting
another file path without resolving the external Provider contract is
insufficient.

### Budget and mutation ledger

| Item | Used | Result |
| --- | ---: | --- |
| Updated TASK read | `1/1` | Complete |
| Existing RESULT read | `1/1` | Complete |
| Continuation bounded admission | `1/1` | Stop condition found |
| Structural repairs | `0/2` | Not started |
| `poc.35` creation | `0` | Not started |
| Static/source evidence | `0/1` | NOT RUN |
| Consolidated focused L0 | `0/1` | NOT RUN |
| Candidate contract parse | `0/1` | NOT RUN |
| Final scoped diff check | `0/1` | NOT RUN |
| Final candidate identity | `0/1` | UNAVAILABLE; no candidate exists |
| Retry/correction | `0` | Not used or authorized |

All admission commands exited `0`; the stop is a confirmed contract result,
not a command failure. Direct named-path source inspection tool envelopes were
`7.9 s` and `6.7 s`. No test, child business process, or external Provider
probe was started.

Phase B/C/D, C# L1/EditMode, Unity, Unity MCP, protected runtime reads,
Provider installation/inspection, publication, commit, tag, push, Verifier
contact, and release promotion remain `NOT RUN / DEFERRED`. Every `poc.34`
byte remains unchanged. The only write in this continuation is this append to
S17 `RESULT.md`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A successor-generation continuation`
Current status: `ROUTE_REASSESSMENT_REQUIRED / PROVIDER_PACKAGE_RANGE_TRANSITION`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner freezes an explicit Provider compatibility/artifact decision and any exact allowlist/evidence expansion before redispatching this same S17 task.
Human decision or authorization required: Provider transition design and artifact identity; exact allowlist expansion; renewed evidence budget; all later Unity, Verifier, commit, tag, push, publication, promotion, and acceptance transitions.

## Planner Route Reassessment - Provider Capability Contract

Decision date: `2026-09-11`.

The user selected `REFACTOR`. The authoritative decision is recorded in
`ROUTE-REASSESSMENT.md`; the Coder's admission stop above remains preserved and
is not rewritten as a completed implementation.

The selected route removes Package semantic version from active Provider
compatibility admission while preserving exact Provider artifact, commit,
executable hash, source, path, protocol, and runtime tool-surface checks. It
allocates side-by-side Rice distribution `0.5.0-28e3912-c2` with Provider
manifest schema 2 and capability contract `codedb-search-tools-v1`, reusing the
same reviewed upstream executable bytes without overwriting historical
distribution `0.5.0-28e3912`.

The Provider contract migration, `poc.35`, recovered materializer `Verify`
observation forwarding, and exact `0.3.0-preview.1` candidate closure remain one
continuous S17 Phase A outcome. All `poc.34` and schema-1 Provider bytes remain
protected. No S17r microtask is created.

This Planner documentation update does not authorize implementation or consume
the unused Phase A evidence budget. Unity, Unity MCP, real Provider install,
Phase B/C/D, Verifier routing, commit, tag, push, publication, promotion, and
acceptance remain separately authorized.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A route reassessment`
Current status: `ROUTE_REASSESSMENT_COMPLETE / REFACTOR_SELECTED / DISPATCH_NOT_AUTHORIZED`
Next notification: UnityCodeDB v0.3 Planner
Next action: obtain explicit user authorization for one manual dispatch to the
existing `v0.3.coder.deep` binding.
Human decision or authorization required: Coder dispatch; any corrected retry;
affected EditMode; Phase B/C/D; real Provider installation; Verifier routing;
commit, tag, push, publication, promotion, and final acceptance.

## Planner Dispatch Authorization - Provider Contract Refactor

Authorization date: `2026-09-11`.

The user authorized one manual dispatch of the updated same-S17 Phase A to the
existing `v0.3.coder.deep` binding. Coder must use `TASK.md` and
`ROUTE-REASSESSMENT.md` as the authoritative scope, execute the bounded
Provider schema-2/capability-contract continuation once, append this
`RESULT.md`, and return to Planner.

No automatic retry, Unity, Unity MCP, real Provider installation, Phase B/C/D,
Verifier routing, commit, tag, push, publication, or release promotion is
authorized.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor`
Current status: `AUTHORIZED / READY_FOR_CODER`
Next notification: existing `v0.3.coder.deep` binding by manual transfer
Next action: Coder executes the authorized continuation once and returns one
stable result to Planner without contacting Verifier.
Human decision or authorization required after completion: any corrected retry;
affected EditMode; Phase B/C/D; real Provider installation; Verifier routing;
commit, tag, push, publication, promotion, and final acceptance.

## Phase A Provider Contract Refactor - Static Evidence Stop

Execution date: `2026-09-11`.

Effective status:
`BLOCKED / STATIC_SOURCE_ASSERTION_MARKER_MISMATCH`.

Execution profile: `v0.3.coder.deep` in the existing Coder binding. The
implementation and review work used the frozen branch and HEAD below and did
not start Unity, Unity MCP, or a real Provider installation.

### Frozen input and implementation snapshot

- Branch: `codex/v0.3.0-legacy-workflow`.
- HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited `Tools~/codedb-instance-engine.ps1` single-path binary-diff
  identity: `c702a5e5c4748136cf292f962eebadb899fdef9b`; accepted as the inherited
  S14/S14r input and not edited by this continuation.
- Protected `UnityValidationProject/ProjectSettings/ProjectSettings.asset`,
  `UnityValidationProject/.codex/`, and `UnityValidationProject/AIWork/` state
  was preserved and not read.
- Historical Provider distribution `0.5.0-28e3912`, schema 1, `poc.34`, and
  all older generations were left unchanged.

The uncommitted S17 implementation snapshot contains these direct paths:

- `com.rice.ai-codedb/Tools~/codedb-provider-distribution.json`
- `com.rice.ai-codedb/Tools~/install-codedb-provider.ps1`
- `com.rice.ai-codedb/Tools~/materialize-codedb-host-payload.ps1`
- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Editor/AICodedbProjectSettings.cs`
- `com.rice.ai-codedb/Editor/AICodedbActions.cs`
- `com.rice.ai-codedb/Payload~/AIWork/codedb/shared/codedb-machine-provider-contract.ps1`
- `com.rice.ai-codedb/Payload~/AIWork/codedb/scripts/codedb-project-common.ps1`
- `com.rice.ai-codedb/Payload~/AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1`
- `com.rice.ai-codedb/Payload~/Generations/poc.35/**`
- `com.rice.ai-codedb/Payload~/host-current.json`
- `com.rice.ai-codedb/Payload~/payload-manifest.json`
- `com.rice.ai-codedb/package.json`
- `com.rice.ai-codedb/Tests~/test-codedb-provider-installer.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`
- `com.rice.ai-codedb/README.md`
- `com.rice.ai-codedb/CHANGELOG.md`
- `com.rice.ai-codedb/Documentation~/index.md`
- `com.rice.ai-codedb/Documentation~/provider-installation-contract.md`

The implementation binds candidate `0.3.0-preview.1` / generation `poc.35`
(sequence `35`) to side-by-side Provider distribution
`0.5.0-28e3912-c2`, manifest schema `2`, protocol `codedb-cli-v1`, capability
contract `codedb-search-tools-v1`, upstream commit
`28e3912d5cd67ff3499734984f3e3d626a204796`, and executable SHA-256
`38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7`.
Active Provider admission no longer treats Package semver as a Provider
capability. Recovered Supervisor materializer `Verify` receives the same
authenticated operational-readiness observation as the ordinary path.

The directly affected C# lifecycle prerequisite test uses a temporary
Package/Payload fixture for its alternate executable hash. It updates the flat
and `poc.35` Provider-bound sources and then recomputes the generation manifest,
current pointer, and payload-manifest hashes inside that fixture only. No
immutable candidate source is rewritten by the test.

### Static/source evidence and first failure

One pre-execution command-construction attempt was rejected by PowerShell at
parse time because `$Path:` was not delimited. The corrected form `${Path}:`
was used for the authorized static/source execution. The parse-only attempt did
not invoke an AST parser, Node, Git, a test, or any runtime process and did not
consume the evidence batch.

The corrected bounded static/source command then ran once:

- Command class: one in-memory PowerShell assertion batch over the actual S17
  PowerShell, Node, JSON, C#, and immutable-generation paths.
- Exit code: `1`.
- Tool-reported wall time: `1.1073769 s`.
- Concise original failure:
  `Provider installer is missing: $script:ProviderVersion = "0.5.0-28e3912-c2"`.

Before that assertion, the same command completed PowerShell AST parsing for
the changed/inherited scripts and `poc.35` scripts, Node `--check` for the
changed Supervisor/test and `poc.35` modules, strict schema-2 distribution
property/identity checks, absence of `supported_package_` from the schema-2
descriptor, flat Provider admission, equality of flat and `poc.35` Provider
contract hashes, and the `poc.35` worker capability markers. The command then
stopped at a Coder-authored installer source marker. It did not reach the
recovered-Verify, C# fixture, or final `poc.34` subassertions.

This failure is evidence-command localization, not proof of a production
activation or Provider-contract defect. The task grants no automatic retry, so
the marker was not inspected, corrected, or rerun. No source file was changed
after the failed batch.

### Budget and deferred boundaries

| Item | Used | Result |
| --- | ---: | --- |
| Route-reassessed implementation | `1/1` | Snapshot prepared |
| Static/source evidence batch | `1/1` | FAIL at installer marker assertion |
| Automatic retry | `0/0` | Not authorized; not attempted |
| Consolidated focused L0 batch | `0/1` | NOT RUN after first failure |
| Candidate contract parse | `0/1` | NOT RUN after first failure |
| Final scoped diff check | `0/1` | NOT RUN after first failure |
| Final candidate identity | `0/1` | UNAVAILABLE; not calculated after first failure |
| C# L1/EditMode | `0` | DEFERRED / NOT AUTHORIZED |

Phase B/C/D, Unity, Unity MCP, real Provider installation or inspection,
network retrieval, full regression, C# compile/EditMode, protected runtime
reads, Verifier contact, commit, tag, push, publication, promotion, and final
acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor`
Current status: `BLOCKED / STATIC_SOURCE_ASSERTION_MARKER_MISMATCH`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the preserved implementation snapshot and decides whether to authorize one corrected static/source attempt that changes only the installer marker localization before any remaining evidence runs.
Human decision or authorization required: corrected static/source attempt and all remaining L0/candidate/diff/identity evidence; affected EditMode; Phase B/C/D; real Provider installation; Verifier routing; commit, tag, push, publication, promotion, and final acceptance.

## Planner Authorization - Corrected Static/Source Attempt

Authorization date: `2026-09-12`.

Planner confirmed that the stopped assertion targeted a nonexistent duplicate
installer constant, `$script:ProviderVersion`. The installer instead owns the
exact Package candidate through
`$script:ProviderPackageVersion = "0.3.0-preview.1"` and consumes the
Provider distribution identity from the sourced authoritative contract through
`$script:CodedbRequiredProviderVersion`. This is an evidence-command marker
localization error, not a confirmed production or test finding.

The user authorized one corrected execution of the same bounded static/source
batch with these limits:

- Change only the in-memory evidence-command marker localization. Do not modify
  production, test, Package, payload, generation, documentation, or task-scope
  bytes as part of the correction.
- Assert the exact installer Package constant and its consumption of
  `$script:CodedbRequiredProviderVersion`; do not require or introduce a
  duplicated Provider-version literal in the installer.
- Execute the corrected static/source batch exactly once. No automatic retry is
  authorized.
- If it passes, continue with the still-unused single focused L0 batch,
  candidate contract parse, final scoped diff check, and final candidate
  identity already authorized by the task. These are not reruns.
- Stop at the first new failure, identity drift, unexpected path, or required
  scope expansion and return one stable result to Planner.

Unity, Unity MCP, real Provider installation/inspection, C# L1/EditMode,
Phase B/C/D, Verifier routing, commit, tag, push, publication, promotion, and
final acceptance remain `NOT AUTHORIZED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence`
Current status: `CORRECTED_STATIC_SOURCE_ATTEMPT_AUTHORIZED / READY_FOR_CODER`
Next notification: the existing Coder thread that returned the blocked S17
handoff.
Next action: Coder performs the one corrected static/source attempt and, only
if it passes, consumes the remaining previously authorized Phase A evidence
once before returning to Planner.
Human decision or authorization required after the next stop/completion: any
further retry or scope expansion; affected EditMode; Phase B/C/D; real Provider
installation; Verifier routing; commit, tag, push, publication, promotion, and
final acceptance.

## Corrected Static/Source Attempt and Focused L0 Stop

Execution date: `2026-09-12`.

Effective status:
`BLOCKED / FOCUSED_L0_INVOCATION_FAILURE`.

The authorized in-memory correction was applied only to the evidence command:
the installer assertion now checks the actual
`$script:ProviderPackageVersion = "0.3.0-preview.1"` marker and the installer
consumption of the sourced authoritative `$script:CodedbRequiredProviderVersion`.
No production, test, Package, payload, generation, documentation, or task
scope byte was changed for this correction.

### Corrected static/source batch

The corrected bounded static/source batch ran exactly once:

- Exit code: `0`.
- Tool-reported wall time: `1.5048111 s`.
- Output: `[PASS] S17 corrected static/source batch: PowerShell AST=26; Node syntax=5; schema-2 Provider, capability admission, recovered Verify forwarding, C# fixture rebinding, and immutable poc.34 checks passed.`
- Evidence covered the exact schema-2/capability Provider contract, absence of
  active Package-semver Provider admission, side-by-side `0.5.0-28e3912-c2`,
  recovered `Verify` observation forwarding, C# fixture hash rebinding, and
  unchanged `poc.34` status.

### Consolidated focused L0 batch

Because the corrected static batch passed, the one previously authorized
consolidated L0 batch was started once with stop-on-first-failure ordering:

1. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-provider-installer.ps1`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -PrerequisiteOnly`
3. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -PayloadContractOnly`
4. `RICE_CODEDB_SUPERVISOR_TEST_FILTER=coordinator-readmission node com.rice.ai-codedb\Tests~\test-codedb-project-supervisor.mjs`
5. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1`

The batch wrapper returned `exit=1` after `0.1734319 s` and emitted no
per-step line, test output, or failure text. Consequently the first reached
test and any test-specific assertion are `UNAVAILABLE`; this record does not
claim a Provider, materializer, Supervisor, or package-boundary production
failure. The batch is nevertheless consumed under the no-retry budget, and no
corrected retry or diagnostic rerun was attempted.

No candidate contract parse, final scoped diff check, or final candidate
identity calculation was run after that first L0 invocation failure.

### Budget ledger and boundaries

| Item | Used | Result |
| --- | ---: | --- |
| Corrected static/source batch | `1/1` | PASS |
| Consolidated focused L0 batch | `1/1` | BLOCKED at invocation boundary; output unavailable |
| Corrected L0 retry | `0/0` | Not authorized; not attempted |
| Candidate contract parse | `0/1` | NOT RUN after first L0 failure |
| Final scoped diff check | `0/1` | NOT RUN after first L0 failure |
| Final candidate identity | `0/1` | NOT RUN after first L0 failure |
| Source changes in this attempt | `0` | Only RESULT.md append |

Unity, Unity MCP, real Provider installation/inspection, C# L1/EditMode,
Phase B/C/D, protected runtime reads, Verifier contact, commit, tag, push,
publication, promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence`
Current status: `BLOCKED / FOCUSED_L0_INVOCATION_FAILURE`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the passed corrected static evidence and the L0 invocation-boundary failure, then decides whether a new authorization is warranted for a separately corrected L0 command wrapper. No remaining evidence item was run automatically.
Human decision or authorization required: any corrected L0 attempt or command-wrapper correction; candidate parse/diff/identity evidence; affected EditMode; Phase B/C/D; real Provider installation; Verifier routing; commit, tag, push, publication, promotion, and final acceptance.

## Planner Authorization - Corrected Focused L0 Wrapper Attempt

Authorization date: `2026-09-12`.

Planner accepts the corrected static/source PASS. The focused L0 result is not
attributable to a production or test failure: the wrapper returned `exit 1` in
`0.1734319 s` without a step-start marker, per-step exit code, stdout, or
stderr. The user authorized one new, independent corrected L0 wrapper attempt
on the preserved S17 implementation snapshot.

The authorization is limited as follows:

- Do not modify production, test, Package, payload, generation, documentation,
  or task-scope bytes to correct the wrapper.
- Execute the same five focused L0 steps in the same order. Before invoking
  each child, emit one concise step-start marker; after it returns, record its
  native exit code and bounded stdout/stderr. Stop immediately at the first
  nonzero exit.
- Invoke the PowerShell and Node children directly. Scope
  `RICE_CODEDB_SUPERVISOR_TEST_FILTER=coordinator-readmission` only to the
  Supervisor step and restore the prior environment afterward.
- Execute this corrected wrapper exactly once. No automatic or same-cause
  retry is authorized. If the wrapper fails before identifying a child, stop
  and return to Planner.
- If all five L0 steps pass, continue once with the still-unused candidate
  contract parse, final scoped diff check, and final candidate identity already
  authorized by the task. Do not rerun static/source evidence.
- Stop on the first test failure, identity drift, unexpected path, protected
  state access, or required scope expansion. Preserve the exact first failure
  without investigation or repair.

Unity, Unity MCP, real Provider installation/inspection, C# L1/EditMode,
Phase B/C/D, Verifier routing, commit, tag, push, publication, promotion, and
final acceptance remain `NOT AUTHORIZED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence`
Current status: `CORRECTED_FOCUSED_L0_ATTEMPT_AUTHORIZED / READY_FOR_CODER`
Next notification: existing `v0.3.coder.deep` thread.
Next action: Coder performs the corrected five-step L0 wrapper exactly once;
on complete PASS it consumes the three remaining Phase A evidence items once,
then returns one stable result to Planner.
Human decision or authorization required after the next stop/completion: any
repair, retry, or scope expansion; affected EditMode; Phase B/C/D; real
Provider installation; Verifier routing; commit, tag, push, publication,
promotion, and final acceptance.

## Corrected Focused L0 Wrapper Attempt - Supervisor Stop

Execution date: `2026-09-12`.

Effective status:
`BLOCKED / SUPERVISOR_COORDINATOR_READMISSION_ASSERTION`.

The newly authorized corrected wrapper was executed once on the preserved S17
snapshot. It emitted a step-start marker before every child that it reached,
captured bounded merged stdout/stderr, recorded native exits, stopped at the
first nonzero child, and restored the prior
`RICE_CODEDB_SUPERVISOR_TEST_FILTER` value in `finally`. No source, Package,
payload, generation, documentation, or task-scope file was changed by the
wrapper.

### Child evidence

1. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-provider-installer.ps1`
   - native exit: `0`
   - child wall: `12522 ms`
   - bounded conclusion: `[OK] Provider installer focused regression passed.`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -PrerequisiteOnly`
   - native exit: `0`
   - child wall: `57192 ms`
   - bounded conclusion: exact schema-2 artifact/capability admission and
     strict mismatch rejection passed; focused machine prerequisite scenarios
     passed.
3. `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 -PayloadContractOnly`
   - native exit: `0`
   - child wall: `7436 ms`
   - bounded conclusion: synthetic payload manifest and marker identity passed;
     focused payload manifest contract scenarios passed.
4. `RICE_CODEDB_SUPERVISOR_TEST_FILTER=coordinator-readmission node com.rice.ai-codedb\Tests~\test-codedb-project-supervisor.mjs`
   - native exit: `1`
   - child wall: `4486 ms`
   - first independent failure: Node `AssertionError` at
     `Tests~/test-codedb-project-supervisor.mjs:1514`,
     `verifyRecordedChildAlreadyAbsentUsesAuthoritativeVerifier`.
   - bounded failure detail: recovered `selected_instance_id` actual
     `cc7227e70a8746a8b1b0821113ea5acc` did not equal expected
     `891a8220fa844500999f5fa847afb98f`.
   - Node runtime reported: `v24.14.1`.

The fifth child, package boundary, was not started because the Supervisor
child was the first nonzero exit. The wrapper's tool-session waits totalled
approximately `60.02 s`; the authoritative child stopwatches above are the
precise per-step timings. No retry, diagnosis, fixture investigation, or
repair was performed. This record preserves the assertion as evidence and
does not claim a production defect beyond the failing focused regression.

### Remaining evidence and budget

| Item | Used | Result |
| --- | ---: | --- |
| Corrected static/source batch | `1/1` | PASS (previous authorized attempt) |
| Corrected focused L0 wrapper | `1/1` | STOP at Supervisor child, native exit `1` |
| L0 retry | `0/0` | Not authorized; not attempted |
| Package-boundary child | `0` | NOT RUN after first L0 failure |
| Candidate contract parse | `0/1` | NOT RUN |
| Final scoped diff check | `0/1` | NOT RUN |
| Final candidate identity | `0/1` | NOT RUN |
| Production/test changes in this attempt | `0` | Only RESULT.md append |

Unity, Unity MCP, real Provider installation/inspection, C# L1/EditMode,
Phase B/C/D, protected runtime reads, Verifier contact, commit, tag, push,
publication, promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence`
Current status: `BLOCKED / SUPERVISOR_COORDINATOR_READMISSION_ASSERTION`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the three passing L0 children and the preserved Supervisor recovered-observation assertion failure, then decides whether any new repair or retry authorization is appropriate. No remaining evidence item was run automatically.
Human decision or authorization required: Supervisor finding disposition and any repair/retry authorization; package-boundary/candidate/diff/identity evidence; affected EditMode; Phase B/C/D; real Provider installation; Verifier routing; commit, tag, push, publication, promotion, and final acceptance.

## Planner Authorization - Recovered Observation Operation Binding FIX

Authorization date: `2026-09-12`.

Planner reviewed the focused failure against the exact test and Supervisor
paths. The handoff summary labeled the mismatched values as
`selected_instance_id`, but the reported source location currently compares
`recoveredObservation.observation_id` with an earlier persisted Supervisor
state observation. The production recovery path forwards one authenticated
observation to recovered materializer `Verify`, but unlike ordinary admitted
materializer operations it does not bind that observation to the recovered
operation in `operationReadiness`. Periodic refresh may therefore publish a
new observation before terminal operation status is read, so the terminal
response need not identify the exact observation consumed by `Verify`.

The user authorized one bounded two-file FIX:

- Writable production path:
  `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`.
- Writable direct test path:
  `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`.
- Before starting persisted-operation recovery, freeze the current
  authenticated operational-readiness observation and associate that exact
  object with the recovered operation through the existing
  `operationReadiness` mechanism, then pass the same object to recovered
  `Verify`.
- Update only the adjacent recovered-operation tests so the captured child
  observation is compared with
  `terminal.status.operational_readiness`, including observation ID, revision,
  owner epoch, selected instance, and selected generation. Do not weaken these
  checks to state-only or field-subset equivalence and do not rely on a
  periodically refreshed state-file snapshot for exact revision equality.
- Preserve fail-closed behavior when verification rejects, when child identity
  is absent/ambiguous, and when no authenticated observation is available.

Evidence authorization is limited to one Node syntax check over the two
changed files and one
`RICE_CODEDB_SUPERVISOR_TEST_FILTER=coordinator-readmission` focused L0. Do not
rerun the three passing Provider-installer/materializer L0 children or the full
static/source batch. If the focused repair passes, run the previously unstarted
package-boundary child, candidate contract parse, final scoped diff check, and
final candidate identity once. Stop at the first failure; no automatic retry,
new diagnosis, or further repair is authorized.

Unity, Unity MCP, real Provider installation/inspection, C# L1/EditMode,
Phase B/C/D, Verifier routing, commit, tag, push, publication, promotion, and
final acceptance remain `NOT AUTHORIZED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor FIX`
Current status: `RECOVERED_OBSERVATION_BINDING_FIX_AUTHORIZED / READY_FOR_CODER`
Next notification: existing `v0.3.coder.deep` thread.
Next action: Coder applies the two-file bounded FIX, executes the authorized
focused evidence once, and returns one stable result to Planner.
Human decision or authorization required after completion: any further repair,
retry, scope expansion, or affected EditMode; Phase B/C/D; real Provider
installation; Verifier routing; commit, tag, push, publication, promotion, and
final acceptance.

## Recovered Observation Binding FIX - Package Boundary Stop

Execution date: `2026-09-12`.

Effective status:
`BLOCKED / PACKAGE_BOUNDARY_MACHINE_LOCAL_PATH`.

### Bounded FIX

Only the two authorized paths were changed:

- `com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs`
- `com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs`

The Supervisor now captures the current authenticated
`state.operational_readiness` object immediately before persisted-operation
recovery, registers that exact object in the existing `operationReadiness`
WeakMap, and passes the same reference to recovered materializer `Verify`.
The two adjacent recovered-child tests now compare the captured child
observation with `terminal.status.operational_readiness` using full-object
equality plus explicit observation ID, revision, owner epoch, selected
instance, and selected generation assertions. Fail-closed recovery paths were
left intact.

### Authorized evidence

1. Two-file Node syntax batch:
   - Command: `node --check` over the two changed files only.
   - Exit: `0`.
   - Wall: `230 ms`.
   - Result: `[PASS] S17 recovered-observation FIX Node syntax batch: files=2; exit=0`.
2. Focused Supervisor L0:
   - Command: `RICE_CODEDB_SUPERVISOR_TEST_FILTER=coordinator-readmission node com.rice.ai-codedb\Tests~\test-codedb-project-supervisor.mjs`.
   - Exit: `0`.
   - Wall: `5872 ms`.
   - Result: `[PASS] Supervisor coordinator re-admission and persisted-child recovery preserve authoritative operation evidence.`
   - The three previously passing Provider/materializer L0 children and the
     full static/source batch were not rerun.
3. Previously unstarted package-boundary child:
   - Command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1`.
   - Exit: `1`.
   - Wall: `1544 ms`.
   - First independent failure: `Package contains a machine-local absolute
     path: Tests/Editor/AICodedbEditorLifecycleTests.cs`.
   - The package-boundary assertion stopped the evidence sequence. No
     investigation was performed, so the source of that path is not inferred.

Candidate contract parse, final scoped `git diff --check`, and final candidate
identity were not run after the first post-repair failure. No retry or repair
was attempted. The only writes in this bounded FIX after implementation were
the two authorized source/test edits and this append to `RESULT.md`.

### Budget ledger and deferred boundaries

| Item | Used | Result |
| --- | ---: | --- |
| Recovered-observation production/test FIX | `1/1` | Applied within two-file allowlist |
| Two-file Node syntax batch | `1/1` | PASS, `230 ms` |
| `coordinator-readmission` focused L0 | `1/1` | PASS, `5872 ms` |
| Previously passing Provider/materializer L0 children | `0` | NOT RERUN |
| Full static/source batch | `0` | NOT RERUN |
| Package-boundary child | `1/1` | BLOCKED, machine-local-path assertion |
| Candidate contract parse | `0/1` | NOT RUN after first failure |
| Final scoped diff-check | `0/1` | NOT RUN after first failure |
| Final candidate identity | `0/1` | NOT RUN after first failure |
| Retry / diagnosis / additional repair | `0/0` | Not authorized; not attempted |

Unity, Unity MCP, real Provider installation/inspection, C# L1/EditMode,
Phase B/C/D, protected runtime reads, Verifier contact, commit, tag, push,
publication, promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor FIX`
Current status: `BLOCKED / PACKAGE_BOUNDARY_MACHINE_LOCAL_PATH`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the recovered-observation FIX, passing syntax/L0 evidence, and the package-boundary machine-local-path finding; any source/test repair or remaining candidate evidence requires a new explicit authorization.
Human decision or authorization required: package-boundary finding disposition and any retry/repair; candidate parse/diff/identity evidence; affected EditMode; Phase B/C/D; real Provider installation; Verifier routing; commit, tag, push, publication, promotion, and final acceptance.

## Package-Boundary Fixture Literal FIX - Independent Boundary Stop

Execution date: `2026-09-12`.

Effective status:
`BLOCKED / PACKAGE_BOUNDARY_REQUEST_QUEUE_BOUNDARY`.

### Authorized test-only change

The Planner-authorized single-file correction changed only:

`com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs:1270`

from a source-contiguous machine path fixture literal to:

`document.post_admission_disposition = "C" + @":\machine\detail";`

The runtime value remains exactly `C:\machine\detail`, while the source no
longer contains the Package-boundary scanner's contiguous drive-prefix pattern.
No production file, Package-boundary scanner, payload, generation,
documentation, or task file was changed.

### Evidence

The previously failing Package-boundary child was rerun exactly once:

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1`
- Exit code: `1`
- Tool-reported wall time: `3245 ms`
- The prior machine-local-path assertion was passed. The first new failure was:
  `Supervisor request queue is missing boundary: AICodedbSupervisorRequestPriority`.
- Source location reported by the test: `Tests~\test-codedb-package-boundary.ps1:16`.

This is recorded as the next independent Package-boundary failure. No
investigation, repair, retry, or scanner change was performed. Candidate
contract parsing, final scoped `git diff --check`, and candidate identity were
not run after this first failure.

### Identity and boundaries

- Frozen branch remains `codex/v0.3.0-legacy-workflow`.
- Known frozen committed HEAD remains
  `5587f4739426f11fa859ced02e5e6164b0429a63` (no commit was made).
- Inherited engine identity remains
  `c702a5e5c4748136cf292f962eebadb899fdef9b` from the accepted snapshot.
- A new final candidate/worktree identity was not calculated because the
  authorized sequence stopped at the first Package-boundary failure.
- `poc.34` was not modified.

| Item | Used | Result |
| --- | ---: | --- |
| Single-file test-only fixture FIX | `1/1` | Applied at the authorized line |
| Package-boundary retry after FIX | `1/1` | BLOCKED, next independent boundary failure |
| Static/source evidence | `0` | NOT RERUN |
| Provider installer / PrerequisiteOnly / PayloadContractOnly | `0` | NOT RERUN |
| Coordinator-readmission L0 | `0` | NOT RERUN |
| Candidate contract parse | `0/1` | NOT RUN after first failure |
| Final scoped diff-check | `0/1` | NOT RUN after first failure |
| Final candidate identity | `0/1` | NOT RUN; unavailable by stop condition |
| Retry / investigation / additional repair | `0/0` | Not authorized; not attempted |

Unity, Unity MCP, C# compile/L1/EditMode, real Provider operation,
Phase B/C/D, protected runtime reads, Verifier contact, commit, tag, push,
publication, promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor FIX`
Current status: `BLOCKED / PACKAGE_BOUNDARY_REQUEST_QUEUE_BOUNDARY`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the accepted fixture-literal correction and the newly exposed request-queue boundary failure; any further test repair or remaining candidate evidence requires new explicit authorization.
Human decision or authorization required: disposition/authorization for the new Package-boundary finding; candidate parse/diff/identity evidence; affected EditMode; Phase B/C/D; real Provider installation; Verifier routing; commit, tag, push, publication, promotion, and final acceptance.

## Package-Boundary Contract-Alignment FIX - Test Script Parse Stop

Execution date: `2026-09-12`.

### Authorization and bounded change

Planner authorized one coherent, single-file test-only contract-alignment FIX
for the stale Supervisor request-queue/lifecycle assertions. The existing
fixture-literal correction was preserved. Only the following task file was
changed by this FIX:

- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`

The replacement assertions cover the C# `AICodedbSupervisorIntentAdapter`
intent/generation/suspension boundary, reject local runtime admission markers,
route lifecycle dispatch/invalidation through the adapter, and inspect the
already loaded `$supervisorSource` for query-first ordering, key/coalescing,
owner-epoch, and maintenance admission/dispatch ownership. No production,
C#, Node, payload, generation, or package metadata file was changed.

### Evidence and stop condition

The single authorized Package-boundary command was attempted once:

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1`
- Exit code: `1`
- Tool-reported wall time: `0.458 s`
- Batch/retry: Package-boundary `1/1`; retry `0/0`
- First failure: PowerShell parser error at the newly added ownership marker
  around line `1001`; the embedded JavaScript `\"running\"` text is not a
  valid PowerShell double-quoted string escape.

The script did not reach any Package-boundary assertion. No investigation,
correction, retry, candidate contract parse, final scoped `git diff --check`,
or candidate identity calculation was performed after this first failure.

### Identity and deferred boundaries

- Frozen committed HEAD remains
  `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited engine identity remains
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- `poc.34` remains protected and was not modified.
- Unity, Unity MCP, C# L1/EditMode, real Provider installation, Phase B/C/D,
  Verifier contact, commit, tag, push, publication, promotion, and final
  acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor FIX`
Current status: `BLOCKED / PACKAGE_BOUNDARY_TEST_SCRIPT_PARSE`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the bounded test-only contract-alignment change
and authorizes any corrected script attempt if desired.
Human decision or authorization required: corrected Package-boundary attempt;
candidate parse/diff/identity evidence; affected EditMode; Phase B/C/D; real
Provider installation; Verifier routing; commit, tag, push, publication,
promotion, and final acceptance.

## Package-Boundary Corrected Script Attempt - Command Path Stop

Execution date: `2026-09-12`.

### Authorized two-marker correction

The single authorized same-cause correction changed only the two newly added
ownership markers in:

- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`

Both outer PowerShell strings now use single-quoted literals, preserving the
runtime JavaScript marker text containing `"running"` and `"maintenance"`.
No other test logic, production file, C# or Node test, payload, generation,
package metadata, or task file was changed.

### Evidence and stop condition

The one authorized corrected Package-boundary attempt was issued once:

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File com.rice-codedb\Tests~\test-codedb-package-boundary.ps1`
- Exit code: `1`
- Tool-reported wall time: `0.299 s`
- Batch/retry: corrected Package-boundary `1/1`; additional retry `0/0`
- First failure: the command path was mistyped as `com.rice-codedb` rather than
  the package directory `com.rice.ai-codedb`; PowerShell reported that the
  `.ps1` file did not exist.

The corrected script was therefore not loaded. Per the zero-retry and
stop-on-first-failure authorization, no command-path correction, investigation,
candidate contract parse, final scoped `git diff --check`, or candidate
identity calculation was performed.

### Identity and deferred boundaries

- Frozen committed HEAD remains
  `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited engine identity remains
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- `poc.34` remains protected and was not modified.
- Unity, Unity MCP, C# L1/EditMode, real Provider installation, Phase B/C/D,
  Verifier contact, commit, tag, push, publication, promotion, and final
  acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor FIX`
Current status: `BLOCKED / PACKAGE_BOUNDARY_COMMAND_PATH`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the completed two-marker correction and the
consumed corrected-attempt budget, then decides whether a new authorization is
required for any further evidence.
Human decision or authorization required: any further Package-boundary attempt;
candidate parse/diff/identity evidence; affected EditMode; Phase B/C/D; real
Provider installation; Verifier routing; commit, tag, push, publication,
promotion, and final acceptance.

## Package-Boundary Evidence-Only Continuation - Lifecycle Order Stop

Execution date: `2026-09-12`.

### Frozen-snapshot evidence

This evidence-only continuation made no source, test, payload, generation,
package metadata, or task-contract changes. The two previously corrected
PowerShell marker literals remain in place.

The exact authorized command was executed once from the repository root:

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1`
- Exit code: `1`
- Tool-reported wall time: `3.354 s`
- Batch/retry: Package-boundary `1/1`; retry `0/0`
- First real assertion failure: `Editor lifecycle must read integration,
  classify migration, and apply prerequisite admission before its first
  Supervisor command.`
- Reported source location: `com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1:16`

The script loaded successfully and stopped at this first lifecycle ordering
assertion. Candidate contract parsing, final scoped `git diff --check`, and
candidate identity were not run. No investigation, correction, or retry was
performed.

### Identity, budget, and deferred boundaries

- Frozen committed HEAD remains
  `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited engine identity remains
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- `poc.34` remains protected and unchanged.
- Candidate identity: unavailable; the evidence sequence stopped before its
  authorized calculation.
- Unity, Unity MCP, C# L1/EditMode, real Provider installation, Phase B/C/D,
  full regression, Verifier contact, commit, tag, push, publication,
  promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence-only continuation`
Current status: `BLOCKED / PACKAGE_BOUNDARY_LIFECYCLE_ORDER_ASSERTION`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the first lifecycle ordering assertion failure and
decides whether a separate repair authorization is required.
Human decision or authorization required: any repair or retry; candidate parse,
final diff-check, candidate identity; affected EditMode; Phase B/C/D; real
Provider installation; Verifier routing; commit, tag, push, publication,
promotion, and final acceptance.

## Lifecycle-Admission Assertion FIX - Manager Refresh Boundary Stop

Execution date: `2026-09-12`.

### Authorized bounded change

Planner authorized one continuous test-only correction. Only the following
file was modified:

- `com.rice.ai-codedb/Tests~/test-codedb-package-boundary.ps1`

The former lifecycle-admission block was replaced as one unit. It now asserts
the exact source order
`integration read < migration read < one direct prerequisite ReadStatus <
ApplyPrerequisiteGatedLeaseRefresh < TryResolveControlContractMigrationBlock <
first RunSupervisorCommand`, while retaining blocked-migration suppression,
explicit/lifecycle trigger bypass, recovery, watcher, and reconnect boundaries.
The obsolete Probe-before-lease assertion was removed. No production, C# or
Node test, payload, generation, package metadata, or protected predecessor was
changed.

### Evidence and stop condition

The exact authorized Package-boundary command was executed once from the
repository root:

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1`
- Exit code: `1`
- Tool-reported wall time: `3.294 s`
- Batch/retry: Package-boundary `1/1`; retry `0/0`
- Lifecycle-admission block: passed.
- First subsequent failure: `Manager status refresh must reserve direct
  materializer launch for explicit force refresh.`
- Reported source location: `com.rice.ai-codedb\Tests~\test-codedb-package-boundary.ps1:16`

Per stop-on-first-failure, this Manager boundary was not investigated or
repaired. Candidate contract parsing, final scoped `git diff --check`, and
candidate identity were not run. No retry was attempted.

### Identity and deferred boundaries

- Frozen committed HEAD remains
  `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited engine identity remains
  `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- `poc.34` remains protected and unchanged.
- Candidate identity: unavailable; the sequence stopped before its authorized
  calculation.
- Unity, Unity MCP, C# L1/EditMode, real Provider installation, Phase B/C/D,
  full regression, Verifier contact, commit, tag, push, publication,
  promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor test-only FIX`
Current status: `BLOCKED / PACKAGE_BOUNDARY_MANAGER_REFRESH_ASSERTION`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the passed lifecycle-admission correction and the
new first Manager refresh boundary failure, then decides whether a separate
repair authorization is required.
Human decision or authorization required: any further repair or retry;
candidate parse, final diff-check, candidate identity; affected EditMode;
Phase B/C/D; real Provider installation; Verifier routing; commit, tag, push,
publication, promotion, and final acceptance.

## Phase A Evidence Continuation - Candidate Contract Parse Stop

Execution date: `2026-09-12`.

### Frozen snapshot and reused evidence

This continuation used the existing S17 uncommitted snapshot. No production,
test, payload, generation, package metadata, or task-contract file was changed
in this attempt. The previously completed Package-boundary PASS was reused and
was not rerun.

- Branch: `codex/v0.3.0-legacy-workflow`.
- Frozen HEAD checked by the candidate parser: `5587f4739426f11fa859ced02e5e6164b0429a63`.
- Inherited engine identity remains `c702a5e5c4748136cf292f962eebadb899fdef9b`.
- `poc.34` was not modified by this attempt; its parser immutability check was
  scheduled after the failing generation-cardinality assertion and therefore
  was not reached.

### Candidate contract parse: `1/1`, BLOCKED

One in-memory PowerShell bounded parser was executed once. It structurally
parsed `package.json`, `Payload~/payload-manifest.json`,
`Payload~/host-current.json`, and `Payload~/Generations/poc.35/generation-manifest.json`,
then checked candidate identity fields, payload/generation hash closure, the
current-pointer binding, and the expected `poc.35`/`poc.34` file closure.
It did not start a test, Unity, Provider, or external process and did not write
a temporary script or repository file.

- Command class: `pwsh -NoProfile -Command` with one bounded in-memory
  candidate-contract parser (the exact parser body was supplied directly to
  the command; no script file was created).
- Exit code: `1`.
- Tool-reported wall time: approximately `0.500 s`.
- First failure: `Generation file count mismatch.`
- No diagnosis, source inspection, correction, retry, or alternate parser was
  performed after the failure.

The stop occurred before the parser's later `poc.34` status check. Candidate
identity is therefore unavailable from this continuation.

### Remaining budget and boundaries

| Item | Used | Result |
| --- | ---: | --- |
| Previously passing Package-boundary | `1/1` prior evidence | Reused; not rerun |
| Candidate contract parse | `1/1` | BLOCKED at generation file count assertion |
| Final scoped `git diff --check` | `0/1` | NOT RUN after first failure |
| Final candidate identity | `0/1` | NOT RUN; unavailable |
| Retry/investigation/repair | `0/0` | Not authorized; not attempted |

Unity, Unity MCP, C# L1/EditMode, real Provider installation or inspection,
Phase B/C/D, other tests, full regression, Verifier contact, commit, tag, push,
publication, promotion, and release acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence`
Current status: `BLOCKED / CANDIDATE_CONTRACT_PARSE`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the first candidate-contract cardinality failure
and decides whether a separate correction/renewed evidence authorization is
required; no remaining evidence item was run automatically.
Human decision or authorization required: any correction or retry; final
scoped diff-check; candidate identity; affected EditMode; Phase B/C/D; real
Provider installation; Verifier routing; commit, tag, push, publication,
promotion, and final acceptance.

## Phase A Evidence Continuation - Corrected Candidate Parser Stop

Execution date: `2026-09-12`. Planner authorized one independent, evidence-only
correction to the candidate parser. The Package-boundary PASS (exit `0`,
`3.753 s`) was reused without rerun. No production, test, payload,
generation, metadata, or task contract was edited.

### Parser correction and bounded result

The in-memory PowerShell command separated the unique
`Generations/poc.35/generation-manifest.json` self-description entry from the
other payload generation entries. It required the exact installed target and
SHA-256 of that file, then mapped each of the remaining 22 entries bijectively
by relative path to the 22 generation-owned runtime entries, verifying
source, target, manifest hash, and file bytes. This `22+1` boundary passed.
The same command structurally parsed all four candidate documents, verified
package/payload/pointer/generation identity `0.3.0-preview.1` / `poc.35` /
sequence `35`, all 46 payload source hashes, the pointer binding, predecessor
identity, `poc.34` zero worktree status, and immutable `poc.34` HEAD tree
`cb3f56d08ea76f9556465c7d78b029670c905629`; those checks passed.

- Command class: one `pwsh -NoProfile -Command` in-memory bounded candidate
  contract parser, with no script file or runtime process created.
- Frozen HEAD: `5587f4739426f11fa859ced02e5e6164b0429a63` (parser PASS).
- Exit code: `1`.
- Tool-reported wall time: `0.878 s`.
- First failure: `Unexpected poc.35 delta from poc.34:`
  `generation-manifest.json, scripts/codedb-project-common.ps1,`
  `scripts/show-codedb-project-provider-guidance.ps1,`
  `shared/codedb-host-use-gate.mjs,`
  `shared/codedb-machine-provider-contract.ps1,`
  `wrapper/codedb-project-instance-worker.mjs`.
- The parser expected the same set without
  `shared/codedb-host-use-gate.mjs`. This is a failed evidence assertion;
  whether that extra delta is authorized or a candidate defect was not
  investigated or inferred in this checkpoint.

The inherited engine patch identity remains the previously frozen
`c702a5e5c4748136cf292f962eebadb899fdef9b`; it was not recalculated in
this attempt. `poc.34` was not changed.

| Evidence | Used | Result |
| --- | ---: | --- |
| Corrected candidate parser | `1/1` | `22+1` closure PASS; final allowed-delta assertion FAIL |
| Final scoped `git diff --check` | `0/1` | NOT RUN after first failure |
| Final candidate identity | `0/1` | NOT RUN; unavailable |
| Retry, investigation, repair | `0/0` | Not attempted |

No static/source, Package-boundary, Provider-installer, PrerequisiteOnly,
PayloadContractOnly, coordinator-readmission, or other test was rerun. Unity,
Unity MCP, C# L1/EditMode, real Provider, Phase B/C/D, full regression,
protected runtime reads, Verifier contact, commit, tag, push, publication,
promotion, and final acceptance remain `NOT RUN / DEFERRED`.

Current task: `cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance`
Current phase: `Phase A Provider contract refactor evidence continuation`
Current status: `BLOCKED / CANDIDATE_ALLOWED_DELTA_ASSERTION`
Next notification: `UnityCodeDB v0.3 Planner`
Next action: Planner reviews the preserved first failure and determines whether
the additional `shared/codedb-host-use-gate.mjs` delta is an authorized
candidate change or a defect before any new evidence authorization.
Human decision or authorization required: any correction/retry; final scoped
diff-check and candidate identity; affected EditMode, Phase B/C/D, real
Provider installation, Verifier routing, commit, tag, push, publication,
promotion, and final acceptance.

## Phase A Evidence Continuation - Allowed-Delta Closure Command Stop

Execution date: 2026-09-12. This was the one newly authorized bounded
continuation after the Planner accepted the shared/codedb-host-use-gate.mjs
candidate delta. No production, test, payload, generation, metadata, or task
contract file was changed; only this RESULT.md was appended.

### Minimal six-path closure: 1/1, BLOCKED

The single in-memory PowerShell closure compared the poc.35 and poc.34
generation file/directory sets, calculated SHA-256 differences, required the
exact six-path delta, and then checked the host-use-gate line change. It did
not start a test, Unity, Provider, or external process. The command stopped
inside its own host-use-gate read expression before any delta result was
produced: ReadAllText received two arguments because the line-normalization
operator was parenthesized as a second method argument.

- Command: one bounded in-memory PowerShell closure from the repository root;
  roots Payload~/Generations/poc.34 and Payload~/Generations/poc.35;
  expected paths generation-manifest.json,
  scripts/codedb-project-common.ps1,
  scripts/show-codedb-project-provider-guidance.ps1,
  shared/codedb-host-use-gate.mjs,
  shared/codedb-machine-provider-contract.ps1, and
  wrapper/codedb-project-instance-worker.mjs.
- Exit code: 1.
- Tool-reported wall time: 0.5001514 s.
- Output: Cannot find an overload for "ReadAllText" and the argument count:
  "2." at the host-use-gate read expression.
- Delta conclusion: unavailable. The command did not establish PASS or FAIL
  for the six-path closure, and no source delta was investigated.
- Retry/investigation: 0/0; the closure was not restarted after this stop.

### Remaining budget and boundaries

| Evidence | Used | Result |
| --- | ---: | --- |
| Minimal six-path allowed-delta closure | 1/1 | BLOCKED by command construction before assertion |
| Final scoped git diff --check | 0/1 | NOT RUN because closure did not PASS |
| Final canonical candidate identity | 0/1 | NOT RUN; unavailable |
| Retry / diagnosis / repair | 0/0 | Not authorized; not attempted |

The previously accepted Package-boundary and candidate-parser evidence was not
rerun. Unity, Unity MCP, C# L1/EditMode, Provider installation, Phase B/C/D,
other tests, protected runtime reads, Verifier contact, commit, tag, push,
publication, promotion, and final acceptance remain NOT RUN / DEFERRED.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase A Provider contract refactor evidence continuation
Current status: BLOCKED / CANDIDATE_ALLOWED_DELTA_CLOSURE_COMMAND
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews the bounded command-construction stop and decides
whether a separately authorized corrected closure is permitted; no automatic
retry or subsequent evidence was run.
Human decision or authorization required: any corrected closure, final scoped
diff-check, candidate identity, affected EditMode, Phase B/C/D, real Provider
installation, Verifier routing, commit, tag, push, publication, promotion,
and final acceptance.

## Workflow v2 Transition - Phase A Candidate Evidence Closure

Execution date: 2026-09-12. Workflow v2 is the active project baseline. The
frozen TASK.md was not modified. This continuation changed no production,
test, package, payload, generation, or protected validation-project bytes;
only this RESULT.md was appended.

The prior ReadAllText two-argument error was treated as the authorized
pre-side-effect mechanical command-construction error. One correction was
used out of the maximum two. No semantic retry was used.

### Evidence

- Minimal allowed-delta closure: exit 0; wall time 0.6334844 s. The poc.34
  and poc.35 file/directory sets matched, the exact six-path delta passed, and
  shared/codedb-host-use-gate.mjs changed only
  GENERATION_ID poc.34 to poc.35.
- Final scoped git diff --check: exit 0; wall time 0.3690391 s; no output.
  The ordered 22-path candidate scope was used, including
  Payload~/Generations/poc.35/**.
- Canonical candidate identity: exit 0; wall time 0.3144827 s. The exact
  ordered candidate scope was streamed through git diff --binary to
  git hash-object --stdin. Identity:
  af645f364fb41202ef3b56d7113b5d29aa6aef32.

Candidate metadata remains package 0.3.0-preview.1, generation poc.35,
sequence 35, Provider distribution 0.5.0-28e3912-c2, schema 2,
protocol codedb-cli-v1, and capability codedb-search-tools-v1. Frozen HEAD
remains 5587f4739426f11fa859ced02e5e6164b0429a63; inherited engine identity
remains c702a5e5c4748136cf292f962eebadb899fdef9b; poc.34 remains protected.

### Budget and deferred boundaries

| Evidence | Used | Result |
| --- | ---: | --- |
| Mechanical command correction | 1/2 | Applied only to in-memory read expression |
| Minimal six-path allowed-delta closure | 1/1 | PASS |
| Final scoped git diff --check | 1/1 | PASS |
| Final canonical candidate identity | 1/1 | PASS; af645f364fb41202ef3b56d7113b5d29aa6aef32 |
| Additional retry | 0/0 | Not used |

Previously passing Provider, materializer, Supervisor, Package-boundary,
candidate parser, pointer, hash, and immutable-poc.34 evidence was reused and
not rerun. Unity, Unity MCP, C# L1/EditMode, real Provider installation,
Phase B/C/D, full regression, protected runtime reads, Verifier contact,
commit, tag, push, publication, promotion, and final release acceptance
remain NOT RUN / DEFERRED.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase A Provider contract refactor evidence-only closure
Current status: COMPLETE / PASS
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews the stable candidate snapshot and decides whether
to route the required Verifier review or authorize a later phase.
Human decision or authorization required: Verifier routing, Unity/EditMode,
real Provider installation, Phase B/C/D, commit, tag, push, publication,
promotion, and final release acceptance.

## Phase B - Fresh Local Exact-Candidate Scenario Stop

Execution date: 2026-09-14. Planner authorized the one visible local Phase B
scenario for candidate 0.3.0-preview.1 / generation poc.35, with canonical
Phase A identity af645f364fb41202ef3b56d7113b5d29aa6aef32. The human-reported
precondition that UnityValidationProject/ was visibly open and compilation
had completed was accepted. No source, test, task, payload, generation, or
protected validation-project file was changed.

### Environment stop: 1/1, BLOCKED

The permitted passive Computer Use inventory was requested twice before any
Unity action. Both observations returned apps: [] and no targetable Unity
window. The preserved raw helper error was:
unsupported Codex auth method: apikey
(reported while enumerating browsers). No Unity window was activated or
selected; Unity, Unity Hub, Unity MCP, BatchMode, process inspection, logs,
alternate endpoints, and direct probes were not used.

Because the visible Unity surface was unavailable to the bounded observer,
the scenario stopped before compilation-state, cold-admission, Play/Edit,
Domain Reload, Manager, query/maintenance, or shutdown stages. This is an
environment/tool availability blocker, not evidence of a product failure.

### Scenario budget and deferred boundaries

| Item | Used | Result |
| --- | ---: | --- |
| Visible Phase B scenario | 1/1 | BLOCKED before first Unity stage |
| Automatic semantic retry | 0/0 | Not attempted |
| Human-owned transition waits | 0 | No transition requested |
| Phase A evidence | Reused | Not rerun |

Compilation confirmation beyond the human report, cold admission, Play/Edit
transition, Domain Reload/reconnect, Manager cache-only counters,
query-first maintenance overlap, authenticated shutdown, Unity/MCP,
C# L1/EditMode, Phase C/D, real Provider, full regression, protected runtime
reads, Verifier, commit, tag, push, publication, and release promotion remain
NOT RUN / DEFERRED.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B fresh local exact-candidate scenario
Current status: BLOCKED / VISIBLE_UNITY_SURFACE_UNAVAILABLE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner records the preserved CUA availability error and decides
whether a separately authorized visible-surface continuation is possible; no
automatic second Unity scenario was attempted.
Human decision or authorization required: any new Phase B scenario or
environment/tool recovery, Verifier routing, Phase C/D, commit, tag, push,
publication, promotion, and final release acceptance.

## Planner Classification Correction - Phase B Admission Surface

Execution date: 2026-09-14. The earlier Computer Use inventory failure is
classified as BLOCKED / PHASE_B_ADMISSION_SURFACE_UNAVAILABLE, not as a
consumed product scenario. The visible Phase B scenario is 0/1 NOT STARTED:
no Unity stage, product assertion, or UI transition was entered.

The passive surface inventory allowance is 2/2 exhausted. Both observations
returned apps=[] and preserved the original helper error
unsupported Codex auth method: apikey. Semantic retry is 0/0; no retry
occurred. No source, test, task, payload, generation, or protected
validation-project file was changed.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B human-evidence admission checkpoint
Current status: WAITING_FOR_HUMAN_EVIDENCE
Next notification: UnityCodeDB v0.3 Planner
Next action: obtain one minimal human-visible checkpoint for compilation and
cold-admission state before requesting any Play transition.

## Phase B - Human Cold-Admission Evidence

Execution date: 2026-09-14. This is the first real Phase B cold-admission
checkpoint within the single continuous scenario. The human-provided
temporary evidence artifact is recorded only as sanitized metadata:
filename codex-clipboard-97797ddc-45d2-41dd-ab8e-fe16925b16e1.png,
size 127220 bytes, SHA-256
c02be2cc4962d4172cde20991f3d2e8aa3de61cb4543b544d5b29a99fdbc80db.
No machine absolute path is recorded.

The visible CodeDB Manager Overview showed package 0.3.0-preview.1 and a
stable supported prerequisite state: Missing prerequisite; CodeDB
dependencies are not configured; Configure Dependencies is the supported
next action. The host payload was Needs Setup / Not evaluated and identified
the expected Provider distribution 0.5.0-28e3912-c2. Current instance,
Coordinator startup, host generation, Provider executable, Project MCP
config, MCP availability, and background cleanup were inactive or not
evaluated. Control contract migration was inactive / Not required. The view
was not Checking and did not reach Ready. The visible button was not clicked.

The human separately reported compilation completed, but no Console evidence
was supplied in this checkpoint; no stronger compilation claim is made.
Because the stable supported state is explicitly blocked on an unconfigured
Provider prerequisite, this is classified as an environment/precondition
blocker, not a confirmed product defect:
BLOCKED / REQUIRED_PROVIDER_PREREQUISITE_NOT_CONFIGURED.

No Configure Dependencies, Refresh, Reinstall, cleanup, configuration edit,
Provider inspection or installation, Play/Edit transition, Domain Reload,
Manager transition, query/maintenance overlap, shutdown, source/test change,
or additional evidence run occurred. The human-owned scenario remains one
attempt and stopped at cold admission.

### Phase B budget and routing

| Item | Used | Result |
| --- | ---: | --- |
| Visible Phase B scenario | 1/1 | BLOCKED at cold-admission prerequisite gate |
| Cold-admission checkpoint | 1/1 | Stable Missing prerequisite; usable Ready gate not met |
| Semantic retry | 0/0 | Not attempted |
| Provider installation/configuration | 0 | Separately human-gated; not run |

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B fresh local exact-candidate scenario
Current status: BLOCKED / REQUIRED_PROVIDER_PREREQUISITE_NOT_CONFIGURED
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner decides whether to seek a separate human authorization
for the required Provider prerequisite installation/configuration; no further
Phase B stage is authorized by this evidence.
Human decision or authorization required: Provider installation/configuration,
any resumed Phase B scenario or transition, Verifier routing, Phase C/D,
commit, tag, push, publication, promotion, and final release acceptance.

## Phase B - Post-Configure Terminal Evidence

Execution date: 2026-09-14. This is a continuation of the same single
human-owned Phase B scenario, not a second scenario or an automatic retry.
Only sanitized screenshot metadata is recorded.

- Artifact A: filename codex-clipboard-ab03102e-bc0c-41a5-94fb-bd7ca5c954d8.png;
  1466x871; 165042 bytes; SHA-256
  39f07e13fe88f8b9acd8c4d1b8e2fab933dde9fa5186a764f634eebf46057413.
- Artifact B: filename codex-clipboard-a64aca34-a651-410d-9f70-29587c1182ca.png;
  1466x871; 166511 bytes; SHA-256
  0a6b09f2f5cae1b1affea54de08cc22696ed10dce55f6c80b541ee93790d1250.

Artifact A visibly showed one completed Configure CodeDB Dependencies
operation: Completed - needs attention, Command completed successfully,
Exit Code 0, elapsed 17.95 s, and six Provider stages. Provider executable
was OK / Found for the expected 0.5.0-28e3912-c2 distribution, and Project
MCP config was OK / Found. The host payload was Error / NEEDS_ATTENTION;
current instance was Needs Setup / Updating from poc.34; host generation was
Needs Setup / Previous poc.34; MCP availability was Error / Unavailable with
the visible relative evidence path AIWork/.runtime/codedb/payload-materializer/
mcp-availability.json. Coordinator startup was Inactive / NOT_EVALUATED,
control-contract migration was Inactive / Not required, and cleanup was
Complete.

Artifact B showed the same completed operation and Needs attention presentation,
but the concrete terminal values had regressed to generic Needs Setup or
Inactive / Not evaluated values for host payload, current instance,
Coordinator, host generation, Provider executable, Project MCP config, MCP
availability, and cleanup. The header remained Needs attention. Neither
artifact showed Checking or Ready.

The Provider prerequisite/configuration stage therefore visibly succeeded, but
the normal poc.34 to poc.35 automatic setup/convergence path still failed.
MCP availability Unavailable is recorded as visible evidence only and is not
asserted as the root cause. The loss of concrete diagnostic values between
Artifacts A and B while Needs attention remained visible is a directly
adjacent evidence-retention/presentation failure in the same blocked user
path, not a separate broad audit.

Exact classification:
BLOCKED / PHASE_B_AUTOMATIC_CONVERGENCE_FAILURE
with an in-scope adjacent diagnostic-retention regression. This is not a
successful corrected Phase B scenario and does not establish a root-cause
production defect without a bounded diagnosis.

No further UI action, probe, test, source/test/task change, runtime/provider
inspection, log read, process action, Play/Edit transition, Domain Reload,
query/maintenance overlap, or shutdown was performed after the evidence.

### Phase B budget and structural routing

| Item | Used | Result |
| --- | ---: | --- |
| Visible Phase B scenario | 1/1 | BLOCKED after post-Configure convergence |
| Configure Dependencies action | 1 | Human-authorized continuation; no second scenario |
| Automatic semantic retry | 0/0 | Not attempted |
| Cause-specific diagnosis | 0/1 | Required decision; not authorized or run |
| Structural repair counter | 0/2 | Unchanged; no repair or authority expansion |
| Diagnostic-only checkpoint counter | 0/3 | Unchanged by this product-path result |

The narrowest useful next evidence boundary is one separately authorized,
read-only, cause-specific inspection of the exact automatic poc.34 to poc.35
handoff and terminal-evidence retention path, limited to its named lifecycle,
materializer, Provider/MCP-admission source and direct tests. It must not read
runtime logs or machine state, operate the UI, retry convergence, or widen
into another phase. Workflow v2 structural-reassessment counters are
unchanged; this evidence alone does not trigger route reassessment.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B fresh local exact-candidate scenario
Current status: BLOCKED / PHASE_B_AUTOMATIC_CONVERGENCE_FAILURE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner decides whether to authorize the single narrow
cause-specific read-only diagnosis described above; no further UI action is
requested in this checkpoint.
Human decision or authorization required: bounded diagnosis or repair,
Verifier routing, Phase C/D, commit, tag, push, publication, promotion, and
final release acceptance.

## Phase B - Cause-Specific Read-Only Diagnosis

Execution date: 2026-09-14. Read-only inspection was limited to the eleven
task-allowlisted source/test paths. No source, test, task card, runtime state,
log, process, Unity, MCP, or test command was used.

### Causal result

The visible sequence is: Configure Dependencies invokes the Provider installer
and can return success; Manager then refreshes its snapshot and requests a
separate lifecycle reconcile; reconcile performs prerequisite/integration
reads, Supervisor Probe, current-instance selection, and a Supervisor-owned
Upgrade/Probe handoff from poc.34. Product status requires every layer,
including MCP availability, to be current, so an unavailable MCP layer
fail-closes to NeedsAttention. A later cache-only Manager presentation can
fall back to the persisted product state alone; that path deliberately creates
generic CachedUnknown / Inactive / Not evaluated rows while retaining the
NeedsAttention header.

### Evidence classification

CONFIRMED:

- Provider Configure success is independent of the later lifecycle
  Upgrade/Probe convergence.
- Automatic handoff/convergence is a distinct Supervisor path.
- Product-status construction maps an unavailable MCP layer to NeedsAttention
  and does not report Ready.
- The state-only persisted fallback loses layer diagnostics and creates generic
  rows.

SUPPORTED_BUT_NOT_ROOT_CAUSE:

- Human Artifact A showed the expected Provider executable and project MCP
  configuration after Configure.
- The observed failure is after/around poc.34 to poc.35 convergence, with MCP
  availability visibly unavailable.
- This supports a fail-closed admission/convergence result, but does not say
  why the MCP handshake was unavailable.

UNPROVED_WITHOUT_FORBIDDEN_RUNTIME_EVIDENCE:

- The exact MCP-unavailable cause (wrapper/provider handshake, generation or
  runtime-evidence mismatch, or another runtime condition).
- Whether diagnostic loss is caused by a race, cache-revision timing, window
  reopen, or another lifecycle transition.

Diagnostic retention is on the same Manager/status projection path and is
directly adjacent fallout in the blocked user path. Its causal link to the
underlying MCP/convergence failure is not proven; classify it as an adjacent
presentation/evidence-retention defect, not a separate broad audit.

### Coverage and next bounded boundary

Existing tests cover Manager cache-only/ownership routing, unavailable-MCP
NeedsAttention and Ready-layer requirements, first-frame Starting behavior,
and selected lifecycle disposition mappings. They do not cover one end-to-end
Configure-success followed by failed automatic Upgrade/Probe, persistence of
the concrete terminal failure into the next cache-only Manager presentation,
or the invariant that a full terminal diagnostic cannot regress to generic
rows. No permitted evidence establishes the runtime MCP reason.

The narrowest future FIX allowlist is
`AICodedbEditorLifecycle.cs`, `AICodedbStatusSnapshot.cs`,
`AICodedbManagerWindow.cs`, and their direct tests
`AICodedbEditorLifecycleTests.cs` and `AICodedbManagerUiTests.cs`;
`AICodedbHostPayloadMaterializer.cs` should be added only if a bounded source
check proves marker/command translation is defective. The focused scenario
should simulate successful Configure plus failed automatic Upgrade/Probe and
assert that terminal diagnostic and layer values survive the next cache-only
Manager presentation. It must remain fixture/static, with no real Provider,
runtime-state, Unity, or UI retry.

### Structural accounting and routing

Independent product cause: 1/2 (first Phase B automatic-convergence cause).
Structural repair count: 0/2. Diagnostic-only checkpoint count: 1/3.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B cause-specific read-only diagnosis
Current status: BLOCKED / PHASE_B_AUTOMATIC_CONVERGENCE_FAILURE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner decides whether to authorize the narrow diagnosis-driven
FIX/evidence attempt described above, or keep Phase B deferred.
Human decision or authorization required: any source repair or new evidence
attempt, Verifier routing, Phase C/D, commit, tag, push, publication, and final
release acceptance.

## Phase B - Runtime Evidence Diagnostic Continuation 02

Execution date: 2026-09-14. This was the second terminal diagnostic
continuation and remained read-only. The exact primary artifact check returned
`exists=false`, `regular=false`, `bytes=unavailable`, and
`sha256=unavailable` for
`UnityValidationProject/AIWork/.runtime/codedb/payload-materializer/mcp-availability.json`.
Per the read envelope, content was not read and no second reference was
followed. No raw runtime document, directory listing, source, test, log,
process, Unity, MCP, Git, or product command was accessed.

Conclusion: EVIDENCE_INSUFFICIENT.

Current artifact facts: the named MCP-availability artifact was absent at the
authorized exact relative path; therefore no sanitized status, reason,
error-code, generation, provider, or evidence-producer field is available.
The prior visible `MCP unavailable` result and the prior source diagnosis
remain observations, not a newly proven runtime cause. Hypotheses such as a
wrapper/provider handshake failure, generation mismatch, stale evidence, or
cache/lifecycle timing remain unresolved.

This artifact does not support proving a single coherent FIX that addresses
both convergence and diagnostic retention. If the Planner later authorizes a
source-only attempt, the minimum candidate allowlist remains
`AICodedbEditorLifecycle.cs`, `AICodedbStatusSnapshot.cs`,
`AICodedbManagerWindow.cs`, plus direct tests in
`AICodedbEditorLifecycleTests.cs` and `AICodedbManagerUiTests.cs`;
`AICodedbHostPayloadMaterializer.cs` is conditional on a bounded source proof
of marker/command translation failure. No such change is authorized or made.
The corresponding focused fixture would model successful Configure followed
by failed Upgrade/Probe and assert terminal diagnostic/layer retention in the
next cache-only Manager presentation, without real Provider or runtime access.

### Diagnostic accounting and routing

Runtime evidence reads: 1/1 (primary artifact missing; stopped immediately).
Second-reference read: 0/1. Mechanical parser corrections: 0/2.
Retry: 0/0. Independent product cause: 1/2. Structural repair: 0/2.
Diagnostic-only checkpoint: 2/3. Active time: unavailable; no new operation
was started at the limit. No test or product operation ran.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B cause-specific runtime evidence
Current status: BLOCKED / EVIDENCE_INSUFFICIENT
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner decides whether to keep the Phase B blocker deferred or
authorize a separately bounded source/fixture diagnosis; no runtime retry is
requested by this checkpoint.
Human decision or authorization required: any further runtime read, source
repair/evidence attempt, Verifier routing, Phase C/D, commit, tag, push,
publication, or final release acceptance.

## Phase B - Terminal Evidence Authority Refactor Boundary Result

Execution date: 2026-09-14. The authorized refactor was stopped before any
source or test edit. The initial bounded symbol search accidentally exceeded
the closed-envelope search limit (more than 50 matches and more than 16 KiB
of produced output). This is the first crossed boundary; no substitute search
or correction was attempted.

Status: BLOCKED / SEARCH_ENVELOPE_EXCEEDED.

The route record active Phase B section was read. No runtime/Provider/
validation-project state, Unity, MCP, process, Git identity, test, compile,
or product operation was run. No writable source path changed, no second
authority or compatibility path was introduced, and `AICodedbActions.cs`
remains byte-unchanged. The requested lifecycle-owned terminal envelope and
direct test-family update therefore remain unimplemented. Structural repair
accounting remains 0/2; independent product cause remains 1/2; no L0 was
authorized or run; affected EditMode remains DEFERRED.

Scoped `git diff --check` was not run because the task requires stopping at the
first boundary. Command exit/wall time for the over-limit search are recorded
as unavailable; the tool returned truncated output with 628 and 5,119 visible
matches in its two result sections. No retry was consumed.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B terminal evidence authority refactor
Current status: BLOCKED / SEARCH_ENVELOPE_EXCEEDED
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner decides whether to issue a new bounded dispatch with a
corrected, per-path/per-symbol search envelope; no implementation or evidence
retry was performed in this dispatch.
Human decision or authorization required: any resumed refactor attempt,
source/test edits, scoped diff check, EditMode, Unity, Verifier routing,
commit, tag, push, publication, or release acceptance.

### Planner Mechanical Inspection Correction

The preceding boundary entry is retained as history. Planner reclassified its
joint-search result as `TRUNCATED / MECHANICAL_INSPECTION_NARROWING_REQUIRED`
under Workflow v2: the output guard was crossed before any product assertion
or source change, and this is not a semantic retry or scope expansion.
Product repair remains 0/2; independent product cause remains 1/2.
Mechanical inspection correction count is now 1/2. Continuation uses one exact
symbol in one exact closed path per command, `rg -m 20`, and line-ranged
excerpts within the remaining cumulative active-time budget.

## Phase B - Terminal Evidence Authority Refactor Result

Execution date: 2026-09-14. The authorized bounded source continuation is
complete and remains uncommitted. Frozen route identity was preserved:
branch `codex/v0.3.0-legacy-workflow`, HEAD
`5587f4739426f11fa859ced02e5e6164b0429a63`, and Phase A identity
`af645f364fb41202ef3b56d7113b5d29aa6aef32`. The identities were carried from
the route record and were not recomputed with a prohibited repository-wide
identity scan.

Changed paths, all within the authorized allowlist:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`: lifecycle-owned,
  authenticated terminal convergence envelope with bounded serialization,
  package fingerprint and Supervisor observation binding, monotonic
  replacement, and newer authenticated Ready clearing. Display-only persisted
  lookup accepts only a lifecycle-published project identity and does not
  derive or hash identity on the Manager caller thread.
- `com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs`: cache projection of
  retained terminal evidence, including concrete product-layer values and a
  visible bounded diagnostic row; retained failure forces `NeedsAttention` and
  suppresses false `Checking`/`Ready`.
- `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs`: Manager fallback and
  cached lifecycle projection now carry the lifecycle envelope; no second
  authority or runtime read was added.
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`: round-trip,
  authenticated-layer preservation, transient/missing/older/same-revision
  rejection, newer-failure replacement, and authenticated-Ready clearing
  coverage.
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`: retained
  terminal evidence remains error-state and never claims `Checking`, while
  concrete layer rows and diagnostics survive cache projection.

`com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs` was allowlisted but
remained byte-unchanged. Read-only closure paths
`AICodedbHostPayloadMaterializer.cs`, `AICodedbSupervisorBridge.cs`, and
`AICodedbActions.cs` were not modified; no second activation/readiness
authority was introduced.

Static evidence was limited to exact-symbol `rg -m 20` searches and
line-ranged excerpts (maximum excerpt about 80 lines). The final and only
scoped formatting check was:

`git diff --check -- "com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs" "com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs" "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs" "com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs"`

Exit: `0`; wall time: `1.1573462s`; output: empty. No retry was used.

Budget and boundaries: mechanical inspection correction `1/2`; structural
repair `1/2`; independent product cause `1/2`; L0 `0`; retry `0`. C# compile,
EditMode, Unity, Unity MCP, runtime/process/log inspection, Provider or real
external validation, and full regression were NOT RUN / DEFERRED. No commit,
tag, push, publication, or Verifier contact occurred. Affected EditMode must
be separately authorized and remains the next executable evidence class.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B terminal evidence authority refactor
Current status: COMPLETE / IMPLEMENTATION_READY_FOR_AFFECTED_EDITMODE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews the stable source snapshot and decides whether to
route the affected EditMode tests for the retained terminal-failure and
cache-only Manager regressions.
Human decision or authorization required: affected EditMode/Unity evidence,
Verifier routing, Phase C/D, commit, tag, push, publication, and release
acceptance.

## Phase B - Planner FIX 01 Result

Execution date: 2026-09-14. The authorized same-envelope correction is
complete and remains uncommitted. The route snapshot was preserved at branch
`codex/v0.3.0-legacy-workflow`, HEAD
`5587f4739426f11fa859ced02e5e6164b0429a63`, with Phase A identity
`af645f364fb41202ef3b56d7113b5d29aa6aef32`. No candidate identity
calculation or repository-wide identity command was run.

Changed paths (the complete correction allowlist):

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`: terminal failure
  replacement and Ready clearing now compare authenticated
  `SupervisorId`/`OwnerEpoch` authority epochs. Same-authority observations
  require a strictly higher revision; a new authenticated authority may start
  at a lower revision. Package fingerprint, observation authentication,
  transient/missing evidence rejection, and fail-closed behavior remain.
  Authoritative Uninstalled status clears the in-memory envelope, updates the
  lifecycle cache as Uninstalled, and clears the persisted envelope before
  persisting the Uninstalled product state.
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`: direct
  coverage for cross-authority low-revision failure replacement and Ready
  clearing, same-authority stale rejection, and seeded Uninstalled envelope
  resolution.
- `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs`: seeded terminal
  evidence is projected as Uninstalled with no terminal row and Install action.

`AICodedbStatusSnapshot.cs`, `AICodedbManagerWindow.cs`, and
`AICodedbLifecycleEvidence.cs` were preserved byte-for-byte in this correction;
no second authority or protocol change was introduced.

The only authorized evidence command was:

`git diff --check -- "com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs" "com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs" "com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs" "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs"`

Exit: `0`; wall time: `0.8217687s`; output: empty. No retry was used.

Budget and boundaries: structural repair `2/2`; mechanical inspection
correction remains `1/2`; independent product cause `1/2`; L0 `0`; retry
`0/0`. C# compile, EditMode, Unity, Unity MCP, runtime/process/log
inspection, Phase A/B/C/D evidence, full regression, Verifier contact,
commit, tag, push, and publication were NOT RUN / DEFERRED. Active time is
unavailable; no additional evidence attempt is authorized in this dispatch.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B terminal evidence authority refactor
Current status: COMPLETE / FIX_READY_FOR_AFFECTED_EDITMODE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews the FIX 01 snapshot and decides whether to route
the named affected EditMode tests for targeted read-only acceptance.
Human decision or authorization required: affected EditMode/Unity evidence,
Verifier routing, any further semantic repair (structural budget exhausted),
commit, tag, push, publication, and release acceptance.

## Phase B - Atomic Cache Closure Result

Execution date: 2026-09-14. The separately authorized atomic cache closure
`1/1` is complete and remains uncommitted. The preserved route snapshot is
branch `codex/v0.3.0-legacy-workflow`, HEAD
`5587f4739426f11fa859ced02e5e6164b0429a63`; no identity calculation or broad
Git inspection was run.

Writable changes were limited to:

- `com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs`: consolidated the
  existing lifecycle cache publication under one lock/revision path. The
  authoritative Uninstalled completion now publishes one tuple containing
  `hasProductStatus=true`, canonical `Uninstalled` product status, null
  materializer result, null terminal failure, null Supervisor snapshot, and
  one strictly newer cache revision, then clears the persisted envelope before
  persisting product state.
- `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs`:
  `AuthoritativeUninstalledCompletion_PublishesCoherentCacheRevision` seeds
  a terminal failure publication, applies the same Uninstalled publication
  method, and verifies the complete cache tuple and exactly-one revision step.

`AICodedbStatusSnapshot.cs`, `AICodedbManagerWindow.cs`,
`AICodedbLifecycleEvidence.cs`, and `AICodedbManagerUiTests.cs` were not
modified in this correction. Lifecycle remains the sole cache authority; no
new Manager/Snapshot cache, protocol, or runtime path was introduced.

The only evidence command was:

`git diff --check -- "com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs" "com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs" "com.rice.ai-codedb/Editor/AICodedbStatusSnapshot.cs" "com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs" "com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs"`

Exit: `0`; wall time: `0.3325739s`; output: empty. Retry `0/0`.

Boundaries: atomic cache closure `1/1`; structural repair remains exhausted
at `2/2`; L0 `0`. Compile, EditMode, Unity, Unity MCP, runtime/process/log
inspection, full regression, Phase A/B/C/D, identity calculation, Verifier,
commit, push, and publication were NOT RUN / DEFERRED.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current phase: Phase B atomic cache closure
Current status: COMPLETE / ATOMIC_CACHE_CLOSURE_READY_FOR_EDITMODE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner reviews the coherent cache handoff and decides whether
to authorize the named affected EditMode acceptance.
Human decision or authorization required: EditMode/Unity evidence, Verifier
routing, commit, push, publication, and release acceptance.

## Human Compile Gate - Missing Overload Closure Result

Execution date: 2026-09-14. The authorized compile integration closure `1/1`
is complete and remains uncommitted. Only
`com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs` was modified; Manager,
Snapshot, all tests, and every other path remain unchanged.

Added the exact internal forwarding overload:

`TryGetPersistedProductState(string projectRoot, out AICodedbProductState state, out AICodedbTerminalConvergenceFailure terminalFailure)`

It forwards to the existing five-argument overload with lifecycle-published
`_projectRoot` and `_projectIdentity`, matching the existing two-argument
cache-only boundary. No identity derivation, hashing, filesystem read, or new
authority was introduced.

The only evidence command was:

`git diff --check -- "com.rice.ai-codedb/Editor/AICodedbEditorLifecycle.cs"`

Exit: `0`; wall time: `0.2603643s`; output: empty; retry `0/0`.
Compile, C# L1, EditMode, Unity, Unity MCP, L0, runtime inspection, full
diff/status, identity calculation, Verifier, commit, push, and publication
remain NOT RUN / DEFERRED. Human recompile is the next evidence gate.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current status: COMPLETE / READY_FOR_HUMAN_RECOMPILE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner hands the stable snapshot back for human Unity recompile.

## Affected EditMode Evidence Result

Execution date: 2026-09-14. The human-provided precondition was that
`UnityValidationProject` was open with compilation complete. The visible
Windows UI bridge could not initialize, so no Unity/Test Runner window state
was obtained and no test was launched. Both the initial call and the single
permitted recovery attempt returned the unchanged error:
`failed to write kernel assets: 系统找不到指定的路径。 (os error 3)`.

The seven authorized tests were all unlaunched/skipped; attempted `0`, passed
`0`, failed `0`, skipped `7`. UI selection batches `0/4`; semantic retry
`0/0`; UI recovery `1/2`; elapsed scenario time unavailable because the
evidence interface failed before selection. No Unity window was started,
restarted, closed, or operated; no Manager, Play Mode, MCP, CLI, process/log,
Git, compile, or alternate probe was used. No file other than this RESULT.md
append changed.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current status: BLOCKED / EXACT_TEST_SELECTION_UNAVAILABLE
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner decides whether to provide a working visible Test Runner
interface and authorize a fresh seven-test evidence attempt.

## Human Affected EditMode Result

Evidence date: 2026-09-14. After the CUA attempt stopped before test launch,
the human executed the exact seven-test fallback listed in
`ROUTE-REASSESSMENT.md` against the already-open, successfully compiled
`<repository-root>/UnityValidationProject`.

Human-reported result: attempted `7`, passed `7`, failed `0`, skipped `0`.
All named terminal-failure authority, Uninstalled cache publication, and
cache-only Manager projection tests passed. No failure text was reported.
The result is a human attestation; screenshots, per-test duration, aggregate
elapsed time, and independent tool observation are unavailable and are not
inferred. The earlier CUA error remains retained as tooling history but is not
a product or EditMode failure.

Current task: cdb-v0.3-p0-s17-preview-runtime-isolation-acceptance
Current status: COMPLETE / AFFECTED_EDITMODE_HUMAN_PASS
Next notification: UnityCodeDB v0.3 Planner
Next action: Planner records the gate disposition and decides whether to route
the stable snapshot to Verifier for targeted read-only acceptance.
