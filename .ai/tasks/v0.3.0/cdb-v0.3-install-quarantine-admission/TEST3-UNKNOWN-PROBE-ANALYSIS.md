# Pre-child Probe failure and retained UNKNOWN history

Date: 2026-10-26. Status: READ_ONLY_CAUSAL_ANALYSIS_COMPLETE.
Candidate: `d84b5ca88b1adb57748b2988aa79cc9c7e6e8be9`.
User approved continuing the proposed read-only producer/consumer analysis.
No source edit, history edit, runtime test or Fresh Install was performed.

## Confirmed causal chain

1. New maintenance records start with execution_disposition UNKNOWN, child null
   (`codedb-project-supervisor.mjs:1515`). startMaintenance persists running /
   admitted before calling entry.run.
2. materialize:Probe calls ensureCoordinatorWithAttribution before runMaterializer
   (`:1634`). ensureCoordinator checks the existing Coordinator service shape.
   An exclusive lifecycle mismatch throws at `:2006`, before its Coordinator
   child prepare/run and before the Probe materializer child.
3. The compatible ready-attach branch does explicitly publish NO_CHILD (`:2012`),
   but the earlier mismatch branch never reaches it. The general error terminal
   handler (`:1331`) preserves the initial UNKNOWN and completes with failure.
   No persisted execution-boundary certificate is added by this route.
4. Exact rereads after Uninstall confirm all four named records still exist,
   failed / UNKNOWN / child null / child_execution absent, with the known
   lifecycle mismatch error and exit 1. Their hashes match the earlier snapshot.
5. Install history admission (`codedb-instance-engine.ps1:5304,5340`) rejects
   UNKNOWN for every discovered history before skipping irrelevant history.
   A later successful Uninstall is not a history disposition override.
6. Routine retention is not a recovery route: it returns early for <=256 files;
   its eligible set additionally requires completed/completed routine records,
   valid execution disposition and the existing identity/reference checks.
   Failed UNKNOWN history is retained even above the count threshold.

The supported Manager Install dispatcher carries project-install-v1 admission
into the child through RICE_CODEDB_PROJECT_INSTALL_ADMISSION
(`invoke-codedb-manager-action.ps1:267-278`). Thus the source-supported normal
Fresh Install route has a concrete retained-history obstacle. No actual admission
or Fresh Install was executed, and the first failing precondition is not claimed;
other gates may also reject earlier.

## Interpretation

The producer has a positively unstarted branch that lacks durable classification;
the consumer appropriately refuses records that do not carry that classification.
This is a consequence of the original install ownership mismatch plus an evidence
production gap. It is distinct from the earlier short-lived CHILD_ADMITTED / null
OS identity problem: these four records have no admitted child_execution at all.

The current source trace explains why this branch did not launch a child. The
historical record itself does not durably certify that fact at its original
execution boundary. Error text, null child, a missing parent, elapsed time or a
successful later action must not become generic retrospective NO_CHILD proof.

## Proposed narrow repair boundaries (not authorized here)

| Work item | Goal | Boundary |
| --- | --- | --- |
| Install ownership handoff | Explicit transition from candidate validation ownership to normal Supervisor operation | Keep existing owner safety; no unrelated heartbeat/UI redesign or immutable payload edits without a separate route decision. |
| Prospective pre-child classification | Original executing path records proven no-child execution on a controlled pre-admission failure | Check no previous unresolved child/attempt; keep command failure as failure; never downgrade in generic finish(error) or recovery. |
| Existing affected history | Define a supported, separately reviewed recovery policy for the four already UNKNOWN records | Preserve originals; no guessed rewrite/deletion or general exception based on matching error strings. A future producer fix cannot retroactively create old proof. |

Existing completeUnstartedMaintenance certifies queue/admission-publication
boundaries before entry.run. This failure happens after entry.run starts;
calling that helper unchanged would misstate its authority. Any new narrow
proof point must be defined at the actual execution boundary.

Existing focused tests cover compatible ready NO_CHILD and service mismatch
refusal, but the inspected mismatch assertions do not carry a maintenance
operation through finish/persistence into Install admission. The prospective
test needed is that producer-to-consumer path, plus guards for already-admitted
children, interruptions and unknown legacy records. No test was run in this
analysis; a hypothesis is not a harness PASS.

## Evidence and limits

Post-Uninstall exact-four-record artifact:
`.artifacts/tests/cdb-v0.3-install-quarantine-admission/test3-post-uninstall-unknown-01/snapshot.json`.
SHA-256:
`7dfb811314b71fc0324c44c17997f183c40ba0d467c2ba70169d7f587164b2f1`.
Four reads, 256 KiB/file cap; no directory enumeration, runtime status, leases,
logs or process inspection. Per-record observation around 2026-10-26 15:26:27
UTC+8. Snapshot contains whitelisted diagnostic fields and source hashes only.

Named record IDs:
008607a4424644afab1a7955d5acc823;
96aa2730203f42f4a143ed15bf44a972;
b6a3302c24af43ef8ab4cfb3bf9ba1ed;
fa7c329609a54c9f857db0d8438d098b.

Primary checkout is older than the candidate. One preliminary search included
older primary-source references; all causal conclusions above were checked
against the isolated committed candidate. An initial task-document read used
the isolated checkout where that untracked primary task file did not exist;
the correct primary record was then read. Neither changed product/runtime state.

Current project remains logically uninstalled. Keep Fresh Install on hold.
Next decision is the bounded repair and existing-history recovery policy;
no blanket refactor or machine cleanup is implied.
