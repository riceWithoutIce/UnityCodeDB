# S29 native launch integration - Coder stable handoff

2026-10-08. Status: IMPLEMENTED / FOCUSED_EVIDENCE_PASS / REVIEW_PENDING.
Same S29 continuation, frozen NATIVE-LAUNCH-INTEGRATION-TASK.md. No source
acceptance, delivery, human Unity or S29 completion claim. Coder stopped after
this consolidated handoff; Planner and independent Verifier own the next gate.

Base/head: `d56f0e507b48af24a39f23411c06dbdd4e093084` on
`codex/v0.3.0-legacy-workflow`. Index before/after:
`93c1f4ef48e5a8e0f058b1750132991af8eb010a`. No commit or staging.
Evidence root: `.artifacts/tests/nl41a`. No recursive delegation or model override.

## Implementation and responsibility

- Added developer-built Windows x64 one-shot launcher. Explicit executable, cwd
  and quoted arguments; `CreateProcessW(..., FALSE, DETACHED_PROCESS |
  CREATE_NEW_PROCESS_GROUP, ...)`; no STARTF_USESTDHANDLES; closes returned
  handles. Exit0 and its bounded JSON identify creation, never READY.
- Real coordinator `start` now awaits the shared caller. Windows x64 reads the
  package-relative executable/provenance and rejects missing, hash-invalid or
  wrong-architecture binaries. The caller bounds the one-shot invocation to5s
  and8KiB output, reports creation error/code, and validates the creation JSON.
  Existing authenticated readiness, generation/lifecycle/demand, Attach and Stop
  remain unchanged. The generation-specific `RICE_CODEDB_UNITY_ROOT` environment
  and `--generation-id` are preserved. Existing non-Windows detached route remains;
  unsupported Windows Node architecture fails rather than using that route.
- The caller uses execFile's timeout for its directly owned one-shot process;
  it never terminates a daemon to manufacture output completion. No timeout or
  process termination occurred during the fixture evidence. A timed-out creation
  can retain unknown effects and is not READY or automatic replay authority.
- Added build script discovering installed MSVC/Windows SDK, or accepting explicit
  tool roots. `/MT /O2 /W4 /WX /EHsc /utf-8 /Brepro`, x64, KERNEL32.DLL only,
  checked through the actual PE import table. Build scratch/TEMP/TMP stay in the
  explicit fresh repository test root. No download or consumer compilation.
- Build manifest binds exact source, build-script/options, compiler/linker hashes,
  SDK version, binary and imports, without developer absolute paths or another
  generation/version authority. Closure validates actual relationships, not just
  existence. Native additions participate in both flat and generation hashes.
- Extended the canonical successor generator for actual launch additions, retaining
  the already-applied instance decoder projection. It patches only the generation
  coordinator creation block, not the entire flat coordinator. New successor is
  `poc.41`; Package remains `0.3.0-preview.5`. No exporter edits or injected files.

## Focused evidence

L0: native compilation and PE/source/build/binary verification PASS; changed/new
PowerShell/Node syntax checks PASS (30 parsed files including mechanically copied
successor scripts). Exact scoped `git diff --check` PASS. Argument transfer via
the actual shared caller includes spaces, Chinese, embedded quote, trailing slash,
empty string and slash-before-quote. Cwd and explicit child-only environment match.
Missing target executable returns Win32 error2 through the real caller and is
rejected. Node v24.14.1; WinPS5.1; MSVC19.51.36244.0; SDK10.0.26100.0.

L1 actual topology: byte-identical production Manager writer -> short WinPS command
-> actual materializer file-output collector imported from AST -> short WinPS leaf
-> Node test CLI -> **real generated coordinator start/caller/native launcher** ->
real coordinator daemon. Provider is a repository-local synthetic MCP executable
compiled by the developer harness using installed .NET Framework csc (no Add-Type),
and real adapter filesystem watching is enabled with an inert fixture builder.
No real Provider, Unity, Supervisor or candidate Install was executed.

Readiness is the existing coordinator protocol: live desired-state plus PID/start
bound synthetic editor lease, real Provider initialize/tools-list, real adapter
watchers, and authenticated named-pipe status. It is not a fixture-ready file.
Wrong token gets UNAUTHORIZED and wrong lifecycle Stop is rejected. Exact matching
lifecycle then cooperatively stops coordinator and closes Provider stdin; no kill.

| Scenario / evidence | Native ms / exit / incomplete | Manager ms / exit / incomplete | External EOF ms | Result |
| --- | --- | --- | --- | --- |
| Normal, run3/normal |1530 /0 /false|1973 /0 /false|2539|PASS, coordinator14940 live/ready at all3checkpoints|
| Missing binary, run4/missing |731 /1 /false|1136 /1 /false|1712|PASS, no coordinator state or readiness|
| Corrupt binary, run4/corrupt |699 /1 /false|1080 /1 /false|1595|PASS, no coordinator state or readiness|
| Intentional upstream retention, run4/retained |6535 /0 /true|11873 /6 /true|36298|PASS, normal incomplete-output rejection retained|

The three clocks have different origins. Retention control deliberately spawns a
fixture child with inherited streams upstream of the product isolation boundary.
It self-expires at35s; both collectors fail within their original bounds, while
the real coordinator52152 remains ready/alive even at external EOF. No timeout
extension, FileShare workaround, fake readiness, collector change or daemon stop
was used to make a normal case pass. Fixture lifecycle has a50s exact-owned demand
expiry guard and Provider has a70s self-expiry fallback. Neither fallback was
needed for real coordinator shutdown. All30recorded fixture roles are absent in
the final audit. Short-lived transfer and one-shot creation processes were not all
captured with process start ticks; their successful exit/creation records are
retained separately. Audit is limited to exact recorded PIDs, not a process scan.

L1 closure: canonical worktree closure58sources/0mismatches. Owned-copy tests
reject four actual drifts: binary bytes, source bytes, options provenance and
build-script bytes. Each rejection is attributable in `closure-results.json` and
its exact log. No package export or real runtime mutation followed these tests.

## Protected state and exact snapshot

`preservation.json`:358files across all existing generations unchanged;
all9historical bootstrap transition objects unchanged, one new predecessor record
appended for poc.40. Prior native POC b71e8c92 has93inventory entries, all unchanged.
New generation differs from poc.40 only at generation-manifest.json, coordinator,
shared caller and the two native assets; all remaining successor bytes match.
Original failed candidates, consumer references, Manager receipts/history, Unity
state, global config and prior artifacts were not edited.

`source-snapshot.json` lists41changed/new product files with exact size/SHA256:
the frozen allowlist only, including all newly copied poc.41 files. Editor C#,
package.json and the materializer script/test were not changed. `file-inventory.json`
lists422retained evidence files excluding itself. Stable identities:

| Artifact | SHA256 |
| --- | --- |
| native source |`f21557cbb64acd6b6afba418225dab7be1aad24d960b558daaa34fa30975b29a`|
| build script |`e217321f9f4290a52a3b5b948497b5e637795cf23265ae8f0859b14d2deac922`|
| shared caller |`9d606df32b90136944cfc446778c1e3d391a96efabfb735a8207fa592b6fe118`|
| native executable, both copies |`6d1ec230841951f2c80e8b8a0ffd3a385a4abff394690cc69e367a102f3544a3`|
| build manifest, both copies |`bf3aea66660562dfa25ac0441ed5117efabdb80ddc0330281517cb93910588b5`|
| generation manifest |`c9114d7de03ea26520a07d32915c9e62a1a976028ec282051c9a1142a700f7ec`|
| host-current |`ac35dd035c259c65064cc684101b51c3a435ca5cbb55f914d2e6b0d41d274089`|
| payload manifest |`c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba`|
| source-snapshot.json |`5569d6f51642fcc3e22440fe72f5641691eb715ed7939fce323f79820d6f9197`|
| file-inventory.json |`f72751837a8b5976c601b792b1a19110638a2be2e6fec31798008c1053a78234`|
| final-process-audit.json |`b8f6b7f8413297b8b0ec3b159dc2df5612436b96bb74bb2db111b3ac3d98905a`|

## Commands, corrections and limits

Developer commands: build script `-BuildRoot .artifacts/tests/nl41a/build2`;
canonical closure `-RepairCanonicalMetadata -SuccessorGenerationId poc.41`;
focused harness `-RunRoot .../run3`, followed by `.../run4 -Scenarios
missing,corrupt,retained`; owned-copy `verify-closure.ps1`; `finalize.ps1` for
preservation, parse, fingerprints and audit. All scripts are retained or product
source. Final verification did not repeat successful process scenarios.

Corrections were mechanical/preflight, with no new independent product cause:
build script parser loop increment and WinPS default PackageRoot initialization;
successor preflight pattern corrected to explicitly preserve the generation env
assignment before any successor write; fixture preflight Write alias collision and
automatic `$args` collision (run1/run2, no real coordinator scenario began); missing
scenario assertion used StandardError rather than nonexistent StdErr (run3 already
showed correct product rejection; only this and pending controls ran in run4);
final audit flattened WinPS ConvertFrom-Json arrays. Failed evidence is retained.

Process/read-budget qualification: initial batched source reads and an accidentally
unscoped `git diff --check` emitted more than the8KiB tool-output target; the latter
was truncated while listing inherited Unity settings whitespace. No Unity file was
changed, no full product audit or suite was run, and subsequent diff check was
limited to product allowlist. This is not claimed as retroactive budget compliance;
Planner decides workflow disposition separately from attributable product evidence.

NOT RUN: Unity/C# product compile or EditMode, real installation/recovery or external
MCP, actual Provider/adapter-worker execution, full suites, clean Git-archive export,
platforms other than Windows x64, Authenticode/reputation/distribution acceptance.
Executable is unsigned; system-only imports and local execution do not establish
consumer security-product reputation. No elevation/download/global registration,
system-temp generated source, cleanup/adoption of failed candidate, commit/tag/push,
release or human Unity operation. Progress-bar issue remains separate P3.
