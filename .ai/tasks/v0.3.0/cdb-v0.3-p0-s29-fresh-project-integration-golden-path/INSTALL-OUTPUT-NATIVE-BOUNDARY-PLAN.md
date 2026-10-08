# S29 one-shot daemon launch boundary - screening and POC proposal

2026-10-08. Decision: BOUNDED_POC_COMPLETE / APPROVE_FOR_INTEGRATION_PLANNING.
The three scenarios below completed once each with expected outcomes; parent
assessment is in INSTALL-OUTPUT-NATIVE-BOUNDARY-RESULT.md. This execution window
is closed. The following authorization is retained as scope history.
After reviewing the concrete scope, the user explicitly replied "同意授权".
Compilation and the bounded sandbox experiments below are authorized. Production
integration, successor generation, export and real project Install retry remain
outside this grant. No new installation, dependency download or runtime compilation
route is authorized. Parent records the stable result before any next decision.

## Problem and evidence

The shipped file-output launcher and existing pipe launcher both fail the normal
detached daemon topology. See INSTALL-OUTPUT-REPRO-RESULT.md and
INSTALL-OUTPUT-LAUNCH-SELECTION-RESULT.md. Direct exit0 does not prove complete
output. Existing Node flags already include detached, stdio ignore and unref.

Inspected Node v24.14.1 source: deps/uv/src/win/process.c calls CreateProcessW
with handle inheritance enabled; process-stdio.c configures standard descriptors.
src/node.cc calls uv_disable_stdio_inheritance during ordinary initialization,
but that routine addresses standard handles and inherited CRT descriptors, not
an explicit allowlist of every OS handle. Microsoft documents unrestricted
inheritance when bInheritHandles is TRUE, and selective inheritance via
PROC_THREAD_ATTRIBUTE_HANDLE_LIST. This is a mechanism hypothesis consistent with
the reproduction, not identification of the actual historical handle holder.

## Candidate comparison

| Candidate | Environment/distribution | Advantage | Cost / decision |
| --- | --- | --- | --- |
| Existing PowerShell file or pipe helper | Already delivered, no dependency | Lowest change cost | Normal topology failed; reject direct substitution |
| Small native one-shot launcher at daemon creation | Windows x64, MSVC build before distribution | Explicitly prevents upstream handle inheritance at one boundary | Additional binary/build evidence; recommended for bounded POC planning |
| Prebuilt managed launcher with Win32 interop | Requires a declared .NET runtime or self-contained distribution | Same underlying Win32 control | Adds runtime/distribution decisions without a demonstrated advantage here; defer |

Runtime Add-Type compilation, another resident broker, and OS service/task
registration are outside this repair. The candidate pool is deliberately small:
existing Package helpers, supported Windows process APIs, and installed build tools
were examined; no third-party dependency or generic executor platform is needed.

## Build and distribution gates

Read-only environment evidence: Windows x64; installed Visual Studio Community
18.6.11819.183 with VC x86/x64 tools; selected MSVC directory14.51.36231,
cl.exe file version19.51.36244.0, link.exe14.51.36244.0; Windows SDK10.0.26100.0.
Compiler, linker, dumpbin, libcmt.lib, kernel32.lib, libucrt.lib and Windows.h exist.
No compiler or SDK installation, compilation or download was performed.

| Gate | Result | Evidence / limit |
| --- | --- | --- |
| Target environment | PASS for proposed local Windows x64 POC | Existing WinPS5.1 / Node24.14.1 topology; no ARM64 or other OS claim |
| Supported build path | PASS for POC feasibility | Installed Microsoft toolchain and SDK; compile/link still unrun |
| Consumer distribution | PASS as design; release validation deferred | Compile before release, static CRT /MT, ship exact binary with Package; inspect imports before executing POC |
| Generated-data boundary | PASS | All build/run/output files below one exclusive .artifacts/diagnostics/io/<short-id> |
| Ignore/isolation | PASS | git check-ignore matched proposed diagnostic output; no global environment/config changes |
| Side effects | PASS for proposed scope | Only sandbox-owned fixture processes; no network at runtime, elevation, service, scheduled task or broad process access |
| Repeatability/removal | PASS as plan | Record compiler/SDK/options/source/binary hashes; self-expiring daemon and cooperative stop; preserve evidence |
| Integration boundary | PASS as design | Launcher creates daemon and exits; existing CLI verifies readiness; coordinator retains lifecycle ownership |
| Advantage over baseline | Hypothesis only | Both command collectors must finish while the daemon is alive; POC must establish this |

Existing export-codedb-package.ps1 exports a named Git commit, validates that
snapshot, builds the ZIP, then validates exact extracted bytes. It does not build
binaries. If later integrated, launcher source/build recipe and exact binary must
be reviewed before export. Keep the distributable binary inside the successor
generation, tracked and included in existing generation/payload hashes. Build
metadata binds compiler, SDK, options and source hash to binary hash. Build outputs
stay ignored; export must not inject or rebuild unreviewed files. This is not yet
implemented. Do not introduce a second independent generation/version authority.

Use /MT as the initial build choice; dumpbin must show only expected Windows system
imports, not a new VC runtime DLL dependency. This is a validation condition, not a
claim that an unbuilt binary is already self-contained. Rebuilding static runtime
code for servicing remains a maintenance responsibility. Signing/reputation and
supported architecture policy require production integration review, not a global
antivirus exclusion or automatic broadening of this POC.

## Narrow component responsibility

Proposed chain: unchanged Manager writer -> unchanged command/native collector ->
watcher/Node CLI -> one-shot launcher -> independently living Node daemon.

The first candidate uses CreateProcessW with bInheritHandles=FALSE and detached
daemon creation, with no upstream standard-output handles forwarded. The daemon
uses its own existing log/status mechanisms. This no-handle route is smaller than
an explicit handle-list implementation when the daemon requires zero inherited
handles; handle-list support is deferred unless a concrete requirement appears.

The launcher uses explicit executable/working-directory paths, preserves reviewed
arguments/environment, closes its own returned process/thread handles and exits.
Closing those handles must not terminate the daemon. It reports creation failure
through bounded diagnostics; exit0 means creation only, never readiness. The Node
CLI must await the launch outcome and use the existing authenticated lifecycle
status response to establish readiness. No new persistent receipt, action identity,
service owner, retry engine, automatic cleanup authority or supervision role.

## Proposed bounded POC

Write allowlist after approval: one fresh exclusive diagnostic sandbox (source,
build script, binary, fixtures, receipts and evidence), plus
INSTALL-OUTPUT-NATIVE-BOUNDARY-RESULT.md. No product source, observed poc.40,
real project/candidate/receipt, Package reference, commit/export or remote write.
One diagnostic child may implement within this boundary under STANDING_WORKFLOW;
parent assesses the stable handoff. Do not initiate another broad product audit.

1. Build one tiny Windows x64 candidate with the installed toolchain. Child-local
   TEMP/TMP and all object/executable/build records stay in the sandbox. Parse
   fixture PowerShell before execution. Check binary architecture/imports and
   preserve source/options/tool/binary hashes. No user-machine compilation path.
2. Reuse the exact shipped writer and original file-output helper, not the failed
   pipe replacement. Reuse prior leaf/daemon business-free fixture semantics;
   change only daemon creation to use the candidate. Preserve old sandboxes.
3. Run normal detached startup first. Require native complete, actual Manager
   terminal complete and external writer stdout/stderr EOF while the exact daemon
   PID/start/token is independently observed alive. All are required for PASS.
4. If normal startup passes, run one controlled launch failure (nonexistent exact
   sandbox child executable) and one intentional upstream-output-retention case.
   The latter uses a fixture-only retained-output child before the isolated launch
   boundary; do not add an unsafe inheritance switch to the production candidate.
   Capture must still fail within its original bounds. No success-by-exit0 bypass.

Maximum3process scenarios,60seconds/run,35second daemon self-expiry,30minute window
including build. One correction for a build/harness defect is allowed and recorded;
no normal-case retry, candidate redesign or extra topology after a mechanism
failure. Argument transfer checks include a sandbox path with spaces/non-ASCII
characters and exact argument recording without additional daemon scenarios.

Fix the previous observer limitation before running: persist native/terminal
observations and exact daemon-liveness snapshots independently of waiting for
observer EOF. Bound each wait; persist partial evidence in a finally path. Successful
return must never depend on daemon expiry. Only after required checkpoints may a
cooperative stop be requested. Self-expiry is the fallback; no kills or external
process-tree scan. Audit exact recorded fixture PIDs; report any survivors honestly.

Reject on normal-case incompleteness, missing live-at-completion proof, required
extra runtime/elevation, scope escape or inability to retain bounded evidence.
Successful POC supports production integration planning only. It does not repair
the retained failed S29 candidate, permit adoption/retry, or accept S29.

## Sources

- Node source: https://github.com/nodejs/node/blob/v24.14.1/deps/uv/src/win/process.c
- Node stdio: https://github.com/nodejs/node/blob/v24.14.1/deps/uv/src/win/process-stdio.c
- Node initialization: https://github.com/nodejs/node/blob/v24.14.1/src/node.cc
- Windows CreateProcessW: https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw
- Windows selective inheritance: https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute
- MSVC static CRT: https://learn.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library

Source/API documentation was inspected read-only during this evaluation. SDK and
compiler presence proves a feasible build route, not successful compilation or
runtime isolation. S29 remains PARTIAL.
