# Retained path identity correction result

Base HEAD: `915a21b8c09aa126bdf757711baa80632c537137`.
Coder stopped with the frozen allowlist only. The three implementation/test
files are changed; Payload and generation files are unchanged. Hash snapshot:
[`.artifacts/tests/s29-retained-path-identity/source.sha256`](../../../../../.artifacts/tests/s29-retained-path-identity/source.sha256).

Implemented `AICodedbPaths.AreSameAbsoluteProjectRoot` as the single retained
identity comparison entry. It admits fully qualified same-project roots,
normalizes separators and trailing separators in memory, applies Windows case
rules and ordinal rules elsewhere, and refuses relative, drive-relative,
current-drive-rooted, malformed, and different-root values without using the
current directory. Retained marker, removal-intent, desired-state, activation,
and operation comparisons now use that entry. Existing project/package keys,
record hashes, receipt layout, path containment/reparse checks, ownership
bindings, and the old failed/incomplete outcome remain enforced.

Evidence:

- Actual production PowerShell writer/fixture run completed in the fresh
  repository-local root with `FailedPreparationRecoveryOnly`, 39 cases,
  retained failed candidate, exit 6/incomplete terminal, and emitted proof at
  `writer-2a99290dd4454201afbb568084431344/emitted-record-context.json`.
- Exact-source extracted C# helper plus retained journal reader compiled and
  executed against those emitted marker/intent/desired/terminal bytes: PASS,
  32 checks. Same-root slash/case/trailing forms reached the real
  `ReadRetainedEffectsMarker`; refusal cases covered different, relative,
  drive-relative, current-drive-rooted and malformed roots, plus marker hash
  tampering. This is focused source/journal evidence, not Unity acceptance.
- Unity Editor/session execution, real S29 recovery, fresh INSTALL committed
  activation/operation branch, and release acceptance were not run.

The C# harness uses Roslyn to extract unchanged method bodies from the current
source. Actual `AICodedbStrictJson`, context, command result, receipt identity
methods and retained reader are used. Unity APIs and unavailable service members
are seams. `AICodedbCurrentInstanceStore.Read` throws rather than fabricating
READY authority; only the emitted `UNINSTALLED` current-state path executed.
Outer journal `Read`, session `RestoreDurable`, the authored NUnit test methods,
non-Windows runtime semantics, and later activation/operation authority remain
NOT RUN. The full original PS-to-journal/session NUnit test is preserved, with
equivalent root forms and marker/intent/desired root faults whose hashes are
rebound so root refusal is checked independently of byte authentication.

Commands and retained evidence files under the snapshot directory:

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File run-writer.ps1`:
  `writer-windowsps.log`, PASS 39 in 137975 ms, native children 0. The wrapper
  imports existing production functions unchanged, changes fixture location,
  and stops immediately after emitting the confirmed retained disposition;
  it does not run the subsequent fresh INSTALL branch.
- Bundled `pwsh.exe -NoProfile -File run-csharp.ps1 -ProofPath
  writer-2a99290dd4454201afbb568084431344/emitted-record-context.json`:
  `csharp.log`, PASS 32. No dependency download/install.

Attempt/budget deviations: the first wrapper construction used a CRLF-only
anchor against LF source and failed before execution; the anchor was corrected.
The first writer execution under bundled pwsh then failed at `payload manifest
must contain one JSON object` (`writer.log` retained); switching to the existing
Windows PowerShell 5.1 runtime completed the corrected writer evidence. The
precise pwsh reader mismatch was not investigated outside scope.
C# harness construction took four attempts (SDK Roslyn assembly conflict,
incorrect protocol source filename, then missing physical-key method dependency,
then PASS), one beyond initial plus two mechanical corrections. Earlier C#
construction outputs remain in the tool transcript; the final `csharp.log`
replaced their file output. This deviation is not retroactively compliant.
An initial generic `param` search exceeded the 50-match search guard; later
reads were narrowed. An accidentally unscoped `git diff --check` produced
285 lines of pre-existing unrelated `UnityValidationProject` trailing
whitespace, exceeding the 200-line command guard. No cleanup was performed,
and no global clean-worktree claim is made.

Protected Payload identity hashes (unchanged):

| Package-relative file | SHA256 |
| --- | --- |
| Payload~/payload-manifest.json | c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba |
| Payload~/host-current.json | ac35dd035c259c65064cc684101b51c3a435ca5cbb55f914d2e6b0d41d274089 |
| Payload~/Generations/poc.41/generation-manifest.json | c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec |

Changed source snapshot:

| Package-relative file | SHA256 |
| --- | --- |
| Editor/AICodedbPaths.cs | db15186a3a61f066d10ba1c023b6ada633ebef11cd760d4c84a6440e8fc40ac2 |
| Editor/AICodedbManagerActionJournal.cs | 720eafa2a33c96188dcbb9277f2ce31c31c8bf8253d38ab20d1db77dbd4cd363 |
| Tests/Editor/AICodedbManagerUiTests.cs | 4dd4f08ea4a4556fa4be3796d013426c73a88c1e0733add571c62b6abe206643 |

Stable Coder handoff: stopped; no commit, export, Unity/MCP/CUA/BatchMode,
process control, or Planner/Verifier edits performed.
HEAD remains the base SHA. Previous actual short proof container was read only
for its context and never changed. Inherited dirty state is preserved. Source
is ready for the independent scoped review; S29 remains PARTIAL and the human
compile/test gate remains pending. No source edits after this handoff.
