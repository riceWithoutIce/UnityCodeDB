# S29 native daemon launch integration

## Metadata and authority

- Workflow codedb-workflow-v2 revision2.5; same S29 continuation.
- Status: SOURCE_ACCEPTED / DELIVERY_PREPARATION (2026-10-08).
- GUARDED / FAST_SUBAGENT / STANDING_WORKFLOW ACTIVE; single writer, depth1.
- Coder then fresh-context independent Verifier; no recursive delegation.
- Deep scope/budget, inherited current model/reasoning, no model override.
- User "好的 开始" after successful native POC and proposed product integration.
- Base codex/v0.3.0-legacy-workflow / d56f0e507b48af24a39f23411c06dbdd4e093084;
  index empty, product implementation clean, inherited dirty docs/Unity preserved.
- Planner owns task/contract records. Coder owns allowlisted source/evidence and
  NATIVE-LAUNCH-INTEGRATION-RESULT.md. Verifier owns only
  NATIVE-LAUNCH-INTEGRATION-VERIFICATION.md after Coder stops.

## Outcome and frozen design

Integrate the proven Windows x64 no-inherited-handle boundary into real coordinator
creation, with developer-side build and Package/generation closure. Short-command
native output and Manager EOF complete while coordinator stays ready/alive.
Creation failure and genuinely incomplete output remain failures.

One-shot native launcher: explicit executable/cwd/arguments, CreateProcessW with
bInheritHandles=FALSE, no upstream std handles, detached creation, close its own
returned handles and exit. Node awaits bounded creation outcome; existing
authenticated lifecycle/status alone proves readiness. Exit0/PID is not READY.
Preserve generation/env/demand/authentication, Attach and Stop ownership. No new
resident owner, durable receipt protocol, retry engine or cleanup authority.
Unsupported Windows architecture fails clearly; do not fall back to the leaking
route. Do not expand other OS support; preserve an existing non-Windows route.

Developer-side /MT build, x64/system-only import check, no consumer compilation.
Use installed MSVC/SDK from POC b71e8c92. Discover installed tools or accept explicit
build arguments; no embedded developer-drive paths, downloads, global config,
elevation, signing purchase or antivirus exclusions.

## Change allowlist

Paths relative to com.rice.ai-codedb/:

- Tools~/native/codedb-daemon-launch.cpp (new).
- Tools~/build-codedb-daemon-launch.ps1 (new).
- Payload~/AIWork/codedb/native/win-x64/codedb-daemon-launch.exe (new).
- Payload~/AIWork/codedb/native/win-x64/build-manifest.json (new).
- Payload~/AIWork/codedb/shared/codedb-daemon-launch.mjs (new caller if needed).
- Payload~/AIWork/codedb/coordinator/codedb-watch-coordinator.mjs.
- Payload~/Generations/poc.41/**: generated successor of protected poc.40;
  mechanically copy unchanged files, change only coordinator/new launch assets
  and manifest closure. No unrelated script/schema redesign.
- Payload~/payload-manifest.json; Payload~/host-current.json.
- Tests~/test-codedb-package-release-closure.ps1: extend existing canonical
  successor/closure route only for these source and binary additions.
- Tests/Editor/OwnerIdentityV2Status.json: generated identity projection only.
- Tests~/test-codedb-daemon-launch.ps1 and Tests~/test-codedb-daemon-launch.mjs
  (one or both new tightly coupled harness files as needed).
- Tests~/test-codedb-host-payload-materializer.ps1: focused launch entry/filter or
  directly coupled identity fixture adaptation only, no unrelated suite edits.

Other writes: fresh .artifacts/tests/<short-run-id>/ build/fixture/evidence paths
and NATIVE-LAUNCH-INTEGRATION-RESULT.md in this task directory. No .gitignore,
Editor C#, package.json, unrelated tests/docs or other task edits. Planner handles
contract/roadmap. Read closure: named paths and direct imports/callers; workflow,
Host Action contract, test-workspace-contract.md, prior POC plan/result/source and
compact writer/native harness. Supervisor fixtures may be read for lifecycle
records only; no full Supervisor/materializer test execution or repository audit.

## Protected state and identity route

Preserve all poc.40/older bytes, bootstrap-transition history, prior artifacts,
dirty docs/Unity state, real failed candidates and all consumer references.
No Unity/MCP calls, real Provider, Install/Uninstall, global config, process kill,
commit/tag/push, remote task update, Package export or human Unity request.

poc.41 is the next unused successor, created through the existing
test-codedb-package-release-closure.ps1 canonical generator. Extend that route as
needed, regenerate all generation/pointer/payload hashes together. No independent
manual hash edits or runtime poc.41 literals. Package remains0.3.0-preview.5 for
this source continuation; no release/publication claim. Flat/generation coordinator
already differ: preserve generation-specific bindings, not blind replacement.

## Producer/consumer closure

| Artifact | Producer | Consumer / required proof |
| --- | --- | --- |
| creation stdout/exit | native launcher | real Node caller; bounded decode/failure, no readiness inference |
| build manifest | developer build script | closure validator and runtime caller if used for integrity; source/options/tool/architecture/binary hash binding |
| binary/caller | build/source | flat bootstrap and successor coordinator, paths relative to owning payload |
| generation/pointer/payload | existing canonical generator | closure/materializer readers and OwnerIdentityV2Status projection |
| coordinator status | existing real coordinator | existing authenticated start/status/readiness, no schema change |

Include runtime additions in existing payload/generation hashes. Build provenance
must avoid developer absolute paths and a second generation/version authority.
Validate actual source/build/binary relationships, not JSON presence alone. Existing
git-archive exporter stays build-free; no post-archive artifact injection. Explain
platform/signing limits without adding release infrastructure.

## Continuous evidence envelope

Coder60minutes,2mechanical corrections/scenario and2semantic repairs/same cause.
Stop on scope/architecture/authority expansion, third independent product cause,
real-environment need or time limit; preserve a consolidated result. Use apply_patch
for authored edits; frozen generators/mechanical copy/build are allowed. Per-tool
output8KiB maximum, result16KiB; raw logs in .artifacts. No checkpoint per command.

L0: changed PS/JS parse, native build/imports, build provenance, focused argument/
cwd/environment transfer and real creation-result decoding.

L1, one focused launch harness: actual Manager writer and native file collector
plus real changed coordinator/caller. Synthetic Provider/adapter and owned project/
lifecycle records are allowed. Cover normal authenticated readiness with coordinator
alive after both collectors finish; creation failure or absent/corrupt binary
rejected before readiness; preserved incomplete-output rejection; exact-owned
lifecycle shutdown. All processes bounded, fixture-specific cooperative shutdown
and self-expiry fallback, no kills/unrelated process scans. Do not replace production
readiness with fixture-ready files and label it integration PASS.

L1 closure: canonical worktree Package closure, protected generation/transition
preservation, and binary/provenance tamper rejection in an owned copy. No generic
schema fuzzing or unchanged full regression. Roots/temp stay short and owned below
.artifacts/tests; no system TEMP fallback or product test hook. If real-boundary
proof cannot fit the allowed paths, report the exact gap rather than weaken DONE.

NOT RUN: Unity/C# compile/EditMode, real installation/recovery, external MCP or real
Provider, full suites, commit-derived export and release acceptance.

## Stable handoff and review

Coder reports changed paths/source/binary/metadata hashes, scoped diff summary,
commands/outcomes/corrections, old-byte preservation, process audit and limits.
No commit. Include exact changed tracked/untracked product file fingerprints in
an evidence manifest. Source review is distinct from delivery/human gates.

Verifier30minutes, read-only product/tests, fresh minimal context after Coder stops.
Check frozen map, normal user launch, release closure and attributable evidence;
reuse PASS evidence without reruns. Findings once to Planner/User, no Coder contact.
BLOCKER only for normal-path failure, data/config damage, external-process risk or
missing key promised evidence. Unfrozen/theoretical additions are FOLLOW-UP. Stop
after the claim-bounded review; Planner/User decides ACCEPT/FIX/DEFER.

## Terminal source-stage status

Coder stopped; independent Verifier returned SCOPED_NATIVE_INTEGRATION_REVIEW_PASS,
with no actionable product finding. Parent admitted the41file stable snapshot and
read the complete verification. Review limitations, including earlier run3 harness
bytes and output-discipline deviations, are retained; no retroactive compliance or
final-harness rerun is claimed. User explicitly ACCEPTED this source-stage outcome.
No further audit or test replay is required by this review. Commit-derived delivery,
human Unity, actual installation/recovery and overall S29 acceptance remain pending.

Standing pre-human preparation authority now applies to the separate scoped
NATIVE-LAUNCH-DELIVERY-PLAN.md. The source-task no-commit restriction bounded Coder
execution; it does not revoke the user's standing post-accept delivery authority.
