# Cwd and import-chain static analysis after observation 04

Date: 2026-10-21. Status: READ_ONLY_COMPLETE / HOST_CWD_CONTRACT_GAP_FOUND /
FAILED_CHILD_CWD_NOT_OBSERVED / NO_ROOT_CAUSE_VERDICT.
Authority: user agreed to analyze the observation. No runtime attempt or repair.

## Main findings

1. Current registration and its validators assume cwd="." means Unity project
   root. Existing package-probe evidence does not validate that assumption in
   Codex. This is a confirmed acceptance-coverage gap, not a proven host defect
   or a proven cause of the observed child exit.
2. Current official general project-config guidance says relative paths resolve
   from the containing .codex folder. MCP cwd is separately typed as a legacy
   string path and its own docs do not specify relative-base semantics. Thus
   applying the general rule to this installed MCP implementation remains an
   inference. Do not claim the child definitely ran from .codex, or blindly
   replace "." with "..".
3. The delivered/installed entry closure is present and coherent. No missing
   static import, differing delivered bytes or current manifest/worker hash
   mismatch was found among the six inspected files. Actual historical file
   resolution, parsing and execution remain unverified.

## Registration and the probe's different boundary

Delivered Package source references below are relative to
`<external-package-root>/com.rice.ai-codedb/`, the exact 237c72d delivery.

`Tools~/materialize-codedb-host-payload.ps1`, Get-RepairMcpRegistrationContent
(around 3920-3929), produces command=node, cwd=".", relative wrapper entry,
--root "." and startup timeout 120. The current external project has that
exact registration. The writer does not derive cwd from the config directory
or emit a resolved project-root value.

`Tools~/probe-codedb-mcp-availability.mjs` resolves the wrapper against its
explicit projectRoot, calls process.chdir(projectRoot), and in the stable
branch uses spawn(process.execPath, [wrapperPath, "--root", "."],
{cwd: projectRoot, ...}) (around 172-203). The candidate branch uses Worker.
Neither branch launches via the Codex registration loader. A probe success can
therefore coexist with a host-specific relative-cwd/entry resolution failure.
This explains the acceptance gap; it does not prove which runtime setting failed.

`Tests~/test-codedb-host-payload-materializer.ps1` around 6534 checks only that
the generated text contains cwd="." and describes this as pinning project cwd.
Around 13768-13777 it rejects cwd=".." as differing from the required literal.
These are contract/text checks. They do not establish a real Codex child cwd;
no previous test PASS is upgraded to host acceptance here. No test was rerun.

## Official host guidance versus installed-host evidence

Official OpenAI pages fetched successfully with HTTP 200 on this date:

- [Advanced configuration](https://developers.openai.com/codex/config-advanced/),
  Project config files: "Relative paths inside a project config (for example,
  model_instructions_file) are resolved relative to the .codex/ folder that
  contains the config.toml."
- [MCP](https://developers.openai.com/codex/mcp/): cwd is the working directory
  to start the server from. It does not state a relative-path base.
- [Configuration reference](https://developers.openai.com/codex/config-reference/):
  mcp_servers.<id>.cwd is a string, working directory for the stdio process.
- [Configuration schema](https://developers.openai.com/codex/config-schema.json):
  RawMcpServerConfig.properties.cwd references LegacyAppPathString, itself
  type=string. AbsolutePathBuf separately documents base-path normalization.
  A string schema is not runtime resolver code; it does not prove normalization
  is absent or that one field is exempt from the general rule.

These are current public docs, not an exact-version source mapping to the
running installed app-server. Prior 403 outcomes do not apply to these new
successful reads. No hidden override or guessed logging key was used.

Read selected installed app.asar JS chunks without executing/importing them.
The network-startup chunk exposes generic spawning and app-server transport;
main contains built-in MCP config construction. This bounded inspection did
not establish how the native Codex MCP manager normalizes this project's cwd.
Generic spawn cwd or a JavaScript app-server launch is not the target MCP
launch implementation. No app archive/executable or host setting was modified.

## File resolution and static closure

Relative entry text is interpreted against the child's effective working
directory before the stable wrapper can run its own process.chdir. If cwd is
the Unity project root, the expected entry exists. At the project's .codex
folder it does not exist, and the Unity markers do not exist there either.
This is a conditional filesystem check, not observation of the failed cwd.

The stable wrapper resolves its owned root by walking three parents from its
module directory, then validates Unity markers. Only after that does it set
diagnosticRoot. Its --root assertion resolves against process.cwd. It validates
selection and only then calls process.chdir(unityRoot) before creating Worker.
It cannot repair a wrong cwd that prevents Node finding the relative entry.

Inspected files, with Package equivalents byte-identical:

| Project path | Static behavior / dependencies |
| --- | --- |
| AIWork/codedb/wrapper/codedb-project-wrapper.mjs | Built-in Node modules plus ../shared/codedb-instance-manifest-contract.mjs; module body establishes diagnostics only after root validation |
| AIWork/codedb/shared/codedb-instance-manifest-contract.mjs | Constants and exported pure parser; no external imports, filesystem/network calls or automatic parse invocation |
| AIWork/.runtime/codedb/host/generations/poc.43/wrapper/codedb-project-instance-worker.mjs | Built-ins plus manifest parser and host-use-gate; performs Node/version/context/Provider checks and lease setup before stdin handlers |
| Same generation shared/codedb-instance-manifest-contract.mjs | Pure parser copy, no extra import edge |
| Same generation shared/codedb-host-use-gate.mjs | Built-ins only; at module evaluation reads/decodes/validates its adjacent generation-manifest.json |
| Same generation generation-manifest.json | Present, valid UTF-8 without BOM and matching the instance hash; current identity values match the gate's documented conditions |

All six files decode as strict UTF-8 without BOM, match delivered bytes and
have present relative static import targets. Pointer-to-instance,
instance-to-generation-manifest and instance-to-worker SHA-256 references
match. No npm package import is required by this inspected entry closure.
This does not test JavaScript syntax/runtime module linking or inherited Node
loader/preload options. No target module was imported, evaluated or launched.

Errors linking the stable wrapper/its helper or opening the entry precede
wrapper-body diagnostics. Errors importing the worker's host-use-gate occur
after Worker creation, so ordinarily propagate to the wrapper error/exit
handlers and diagnostic writer, subject to write failure/interruption. The
unchanged old bootstrap directory therefore helps prioritize hypotheses but
cannot conclusively exclude worker/Provider failure or diagnostic-write failure.

## Priorities and concrete handling boundary

| Priority | Candidate / gap | Current status |
| --- | --- | --- |
| First | Effective host child cwd and relative entry resolution | Strong unresolved compatibility concern; required cwd not proven by existing validator/probe |
| Next | Node entry/module loader or inherited Node startup options | Still possible; no original error or effective startup options captured |
| Lower until primary evidence | Worker/Provider/lease/manifest failure after wrapper root validation | Not proven; expected diagnostic coverage is greater, but silence is not exclusion |
| No present evidence | Missing current helper, wrong delivered file bytes, 120-second timeout, query/index failure | Current static closure/trace does not support these explanations |

Do not repeat unchanged argv capture, reinstall, create another Unity project,
switch to v0.2, alter production wrapper code, or write a permanent cwd=".."
fix from this analysis. Keep process observation 04 closed and query acceptance
Attempt 04 on hold. No new operational window is authorized.

The decisive evidence is either the original child error/effective cwd from a
supported host source, or a separately agreed single-variable cwd experiment.
If such an experiment is chosen later, explicitly fix cwd to the confirmed
external Unity root while keeping command, entry/--root args, Package, normal
Codex privileges and stdio unchanged; first define exact backup/restore and
configuration-refresh timing. A machine-local temporary absolute cwd would
be diagnostic only, not the portable product fix. Success/failure would still
need attributable startup/error evidence. Do not execute or silently select
that experiment now.

Any eventual product correction must align generator, validator and acceptance
coverage with a verified host path contract. Changing only the external
consumer config could hide the defect from future installations.

## Retained static evidence

`.artifacts/tests/s39-static-resolution/delivered-closure.json` contains six-file
hashes/UTF-8/import-edge checks and manifest reference comparisons.
`installed-host-static.json` retains bounded installed-code excerpts, not user
configuration or environment. Helper scripts only read files; ordinary Node
was used for archive inspection, not to launch/import any CodeDB component.
Project config, Package and runtime inputs were not edited. No Unity, MCP,
Provider, wrapper, watcher, process control, trace, chat dispatch, test suite,
commit or push occurred. Unconfirmed FOLLOW-UP remains deferred.
