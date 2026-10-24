# v0.3 preview candidate and evidence matrix

Date: 2026-10-21. Status: CONSOLIDATED / BASIC_FLOW_BASELINE_ALIGNED /
NOT_RELEASE_ACCEPTED.

Subsequent alignment: the user agreed to basic-use-flow preview stabilization
with the exact c848049 runtime baseline and confirmed only basic-flow completion
so far. LIFECYCLE-GAP-PLAN.md maps the current-candidate lifecycle gap and the
proposed bounded supplement. The recommendations below are retained as the
decision context; no runtime attempt or release was authorized by that alignment.

This is a read-only source/evidence consolidation after the approved primary
integration. It selects no new implementation or operational attempt and does
not independently review or accept the historical S31 WIP.

## Candidate recommendation and actual source states

Recommend the already delivered exact commit
`c848049d90fbdf618905be25225580642d98d987` as the preview runtime baseline for
the next scope decision. Package version is `0.3.0-preview.5`, generation
`poc.44`. This recommendation does not freeze a release promise or approve
public distribution.

Its existing ZIP remains available at
`.artifacts/exports/s39-cwd-c848049/com.rice.ai-codedb.zip`. The current read-only
hash check matches the delivery receipt:
`3d266307ba7e052140575ada0c39d689e5a62d28a9aa3d686420f15e76a98a5d`.
No new export or external reference switch is needed to identify this baseline.

The primary HEAD is still
`237c72d9980114b99887fb8e805658447dd8d4fd`. The primary working files now contain
the integrated S39 delta and preserved local work. Comparison of the 664
committed candidate Package paths found eight byte differences: five documents,
two implementation files and EOL-only `package.json`. This count is not an
inventory of ignored/generated content. The primary dirty tree is not the
accepted exact candidate and must not be exported under that candidate's name.

Read-only bindings are recorded in
`.artifacts/maintenance/s39-candidate-evidence-matrix/snapshot.json`.

## Attribution of the two retained implementation deltas

| File | Current primary SHA-256 | Exact candidate SHA-256 |
| --- | --- | --- |
| `Editor/AICodedbProcessRunner.cs` | `a3c9ae743c4634167f8cbbf20146be9b06132f8a54ef8f9e463f3a4bfc7380d1` | `56fe365a01da3a9b526f494080055c4d42e5b8f809849f1868d42eb4185fd32f` |
| `Tools~/invoke-codedb-manager-action.ps1` | `44216a7061384c095b54b2183bc9dacb19f63428c3868f19ec9f1f4c8b11334c` | `cb0a431dc5f0340623d5e79ea8a48a45cb5f74d883f45cce7aa31e9793d5d017` |

The current primary hashes exactly match the S32 source RESULT rows. S32's
DELIVERY-PLAN explicitly excluded incoming timeout/termination changes from
both files; its projected candidate hashes exactly match the c848049 files.
Both candidate files also equal their S38 delivery-commit versions. These local
differences are retained earlier WIP, not unexplained additions from S39.

Their behavior matches S31's historical A1 partial checkpoint: a protected
`ConfirmedProjectMutation` writer/child is no longer killed by the generic
timeout/overflow cleanup. That checkpoint was `PARTIAL / NOT_ACCEPTED` and
explicitly lacked bounded safe-point cancellation, guaranteed settlement and
coupled semantic scenarios. Its stated possibility of an indefinitely retained
owner is a historical limitation of that WIP, not an observed runtime incident
in CodedbTest_2 and not a new independent audit finding here.

Provenance:

- `../cdb-v0.3-p0-s31-project-uninstall-workflow/RESULT.md`, historical A1
  checkpoint and writer-lifetime limitation;
- `../cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md`, source hashes;
- `../cdb-v0.3-p0-s32-install-project-command-closure/DELIVERY-PLAN.md`, explicit
  task-only projections excluding those incoming changes.

Recommended disposition: preserve both local files and their evidence, exclude
the WIP from the preview candidate, and leave completion to a separately scoped
writer-lifetime task. Do not silently accept it, reset the primary files, or
restart the broad historical S31 task. Any future change to transaction safety
needs its own supported behavior and directly affected evidence.

## Functional and artifact evidence

| Gate | Attributable evidence | Current conclusion |
| --- | --- | --- |
| cwd derivation and equivalent config handling | S39 source Contract checks: 15 scenarios per PS host; Flow: 16 per host. RESULT.md retains scope. | PASS at focused isolated boundary; no wrapper/Provider timing change was introduced by the cwd fix. |
| Exact candidate delivery | DELIVERY-RESULT.md: exact committed tree, 664 ZIP files, 62 payload entries, native bindings, exact-extraction Flow checks. | PASS for c848049; current ZIP hash reconfirmed, earlier tests not rerun. |
| Fresh external Unity install | CODEDBTEST2-READY-RESULT.md: human compile/Install/Ready and disk bindings for the exact Package. | PASS for the agreed fresh external flow. |
| Actual client startup/status | CODEDBTEST2-CLIENT-STARTUP-RESULT.md: user-transferred raw target response; six exact tools, status once. | PASS at the agreed startup/status boundary. |
| Actual C# hit | CODEDBTEST2-HIT-QUERY-RESULT.md: user-transferred raw response, one search, exact path/line/marker. | PASS for this sample; query gate closed, no repeat needed. |
| Primary integration | SOURCE-INTEGRATION-RESULT.md: 72 path hashes, 62 payload entries, generation closures and 447 immutable predecessors. | PASS for static consolidation only; no acceptance of the retained WIP. |
| Exact-candidate lifecycle supplement | LIFECYCLE-REOPEN-RESULT.md and LIFECYCLE-UNINSTALL-RESULT.md pass; LIFECYCLE-REINSTALL-BLOCKED-RESULT.md records the separately authorized single Install failure at PREFLIGHT, exit 6, retained-holder refusal. | Reopen and logical Uninstall PASS for c848049; cleanup PENDING; same-version reinstall BLOCKED, post-reinstall reopen NOT RUN. Supplement stopped/incomplete; no release closure. |
| Install/reopen/logical uninstall/same-version reinstall | S38 TASK.md and stage results, exact d856a8f / poc.43 Package. | Earlier-candidate lifecycle PASS with periodic-observation warning and cleanup pending. Not a complete c848049 lifecycle PASS. |
| Complete session/response identity | ACCEPTANCE-CLOSURE.md: response lacks independent project/instance/epoch fields. | Deferred evidence limitation; not reopened as a blocker on the completed sample gate. |

The S38-to-c848049 Package delta spans 58 paths, including bootstrap, generation
selection, integration readers and materialization changes. The two writer
files being unchanged does not make those Packages identical or automatically
transfer every lifecycle result. No lifecycle test was performed in this
consolidation.

## Existing Runtime Release Gates

The full roadmap gates remain in force. The following entries describe what
this bounded consolidation can substantiate; `NOT_MAPPED` means evidence was
not established here for the exact candidate, not that no historical work exists.
Do not start a new implementation or full regression merely from this label.

| Roadmap gate | Candidate evidence disposition | Next handling before claiming that gate |
| --- | --- | --- |
| Main-thread work prohibition and instrumentation | NOT_MAPPED for an exact-candidate instrumented claim. Human no-error/no-stutter reports do not prove zero main-thread I/O. | Map existing attributable evidence first; select a bounded gap only if the release promise requires more. |
| Domain Reload reconnect / same owner / no duplicate backend | S38 normal Unity reopen smoke is earlier-candidate evidence and is not a Domain Reload identity trace. | Map directly relevant historical evidence before choosing an exact-candidate check. |
| Query-first maintenance and compile/asset/Play deferral | Fresh query PASS; overlapping maintenance scheduling NOT_MAPPED. | Do not infer scheduling from the isolated hit or Unconfirmed UI observations. |
| Stale index and missing-index startup semantics | Sample creation then retrieval PASS; explicit stale/missing-index reason behavior NOT_MAPPED. | Review the declared supported semantics and evidence before selecting a scenario. |
| Fail-closed command ownership and authenticated project-only shutdown | Earlier S38 logical lifecycle evidence exists; full exact-candidate shutdown/foreign-client preservation is not established by the marker test. The unaccepted local WIP is excluded by recommendation. | Map focused owned-process evidence; do not launch process-stop testing or revive S31 automatically. |
| Exact preview local and external acceptance | Fresh external install/client/sample PASS. Exact local-project and full lifecycle coverage remain separately attributable, not fully mapped here. | Decide the concrete preview promise and actual affected gap before any new run. Two-project/elevation matrices retain their existing deferred status. |

These unmapped claims are release-evidence decisions, not a new source blocker
list or a demand to implement every item immediately. Any narrowing of an
existing release promise requires an explicit scope decision; this document
does not waive the roadmap gates.

## Discover Read and recorded follow-ups

The original Discover Read scope and eight release criteria remain open at their
existing evidence boundaries: corpus completeness, freshness, anchored symbol
and dependency accuracy, containment, representative p95, semantic context and
ten real navigation tasks before preferring CodeDB over routine `rg`. One C#
sample and its timing do not prove these criteria or a performance improvement.
Implementation status is to be determined per selected task, not inferred
solely from absent acceptance in this matrix.

Ready/Unconfirmed, previous-generation admission, full session attribution and
physical cleanup remain separately recorded. No diagnostic retry, test project,
process stop or clean-up was activated here.

## Concrete route choices

| Route | Consequence | Recommendation |
| --- | --- | --- |
| Keep exact c848049 as the preview runtime baseline | Retain attributable source, ZIP and fresh functional acceptance. Preserve local WIP outside that candidate. | Recommended next baseline decision; still not full release acceptance. |
| Use the entire current primary tree | Includes the two expressly unaccepted lifetime changes and local documentation differences. Existing exact-candidate acceptance is insufficient for that tree. | Do not select it implicitly or call it the same Package. |
| Finish writer-lifetime behavior first | Requires a new bounded objective, supported cancellation/ownership semantics and affected evidence. | Separate development decision; not required merely to consolidate S39. |

Next align the preview's concrete supported behavior and evidence obligations
against this matrix, starting from the recommended exact baseline. Reuse
existing evidence where attributable; select only actual remaining gaps. No
new commit/export/runtime attempt is authorized by this planning record.
