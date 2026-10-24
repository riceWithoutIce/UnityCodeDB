# S29 isolated execution/output lifetime reproduction

2026-10-08. User approved the concrete project-local isolated reproduction plan
with "同意". This authorizes fixture implementation and bounded execution, not
production fixes or real project operations. Mode FAST_SUBAGENT under existing
STANDING_WORKFLOW; one diagnostic Coder, no further delegation. Parent reviews
the stable evidence after the child stops. Inherit model/effort.

## Frozen target

Reproduce and distinguish output completion of a short command from lifetime of
a daemon it starts, using the actual delivered Package Manager writer and native
file-output launcher. Base HEAD d56f0e507b48af24a39f23411c06dbdd4e093084; Package
.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb is read-only.
Read INSTALL-OUTPUT-LIFETIME-DIAGNOSIS.md and directly referenced source/dependencies.
Do not reread live S29 receipts, candidates or processes; diagnosis has their facts.

## Write and execution scope

- New exclusive sandbox under G:/RiceProgram/UnityCodeDB/.artifacts/diagnostics/io/
  with a short run identifier. Do not adopt/overwrite an existing directory.
- Fixture scripts, PID/start/owner records, scoped temp/profile, stdout/stderr,
  timelines and result JSON only below that sandbox. Use apply_patch for scripts.
- Child report INSTALL-OUTPUT-REPRO-RESULT.md and optional identity JSON in this
  task directory. Parent alone updates TASK.md / this packet.
- Production/Package/generation files, validation projects, machine journal and
  user/global config are read-only/out of scope. No Install/Remove/replay,
  Provider/MCP launch, Unity/BatchMode/CUA, release export, commit or publication.

Reuse actual Package writer unchanged (copy byte-for-byte into test-owned Package
context if necessary); import native launcher/dependency function bodies without
running materializer top level. Test operation bodies substitute business work.
Bind valid receipt identities to the fixture roots, never bypass production reader
checks. Reuse the existing test-codedb-package-boundary.ps1 writer fixture design.
TEMP/TMP and any child LOCALAPPDATA override must be child-scoped and inside the
sandbox; never alter user/global environment, HOME or CODEX_HOME.

## Three scenarios and stop conditions

1. Leaf command writes stdout/stderr and exits, no daemon: baseline.
2. Windows PowerShell short command starts Node CLI -> detached Node daemon using
   the shipped coordinator topology (stdio ignore, unref), then exits while the
   daemon remains alive: normal background-service scenario.
3. Test-owned descendant intentionally retains the relevant output handle after
   the short command exits: adverse control, explicitly not proof of scenario2.

Run initial three scenarios sequentially; at most two causally justified focused
follow-ups/instrumented comparisons, no repeated unchanged PASS or broad matrix.
Total window30minutes, each scenario outer bound60seconds. Every fixture daemon
has a self-exit deadline within that bound and a scoped cooperative stop route.
Use hidden windows. Record exact process objects/PIDs/start times/token/paths;
cleanup may target only proven fixture-owned processes, preferably cooperative.
If attribution is uncertain, stop dependent execution and preserve evidence;
never use process-name kill, broad tree termination or cleanup against repo roots.
Preserve sandbox logs/evidence; no recursive deletion needed.

Capture command exit, file-read/pipe-EOF timing, service-alive interval and errors
per layer. For original IOException/HResult, obtain diagnostic-only observations
or a clearly separated instrumented fixture copy; do not change the unmodified
baseline launcher or present instrumented code as production behavior. No native
handle-scanner downloads, global process enumeration or privilege escalation.

## Evidence and handoff

Report actual scenario results, runtime/tool versions, copied/imported source
hashes, exact deviations, remaining fixture process state and output evidence paths.
Distinguish reproduced real-like failure, deliberate fault control and unproven
historical cause. If no reproduction, say so; do not call a synthetic injected
failure the root cause. Stop after identifying a concrete repair boundary or
the limits of reproduction. No source repair in this task.
Read/output target80lines/4KiB per call; avoid raw runtime/config dumps.
Return stable results and stop editing for parent assessment.
