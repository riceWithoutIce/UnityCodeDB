# S29 native launch integration - independent verification

2026-10-08. Terminal disposition: **SCOPED_NATIVE_INTEGRATION_REVIEW_PASS**.
No BLOCKER or actionable product finding in the frozen claims. This is an
independent source/evidence review, not S29, delivery, real-install or release
acceptance. Planner/User owns ACCEPT/FIX/DEFER. Coder was stopped throughout.

## Scope and stable identity

Read the complete NATIVE-LAUNCH-INTEGRATION-REVIEW, TASK and RESULT packets;
reviewed only the native creation boundary, immediate coordinator consumers,
canonical generation/build closure and attributable saved focused evidence.
Product/tests/fixtures remained read-only. No test rerun, compilation, process
launch/cleanup, Unity/MCP/Provider invocation, Git mutation or Coder contact.
Only this verification report was written.

Independent opening and terminal checks agree. Terminal check at
2026-10-08T14:26:45.4790621Z:

- HEAD: `d56f0e507b48af24a39f23411c06dbdd4e093084`.
- Index hash: `93c1f4ef48e5a8e0f058b1750132991af8eb010a`; staged paths: 0.
- source-snapshot.json SHA256:
  `5569d6f51642fcc3e22440fe72f5641691eb715ed7939fce323f79820d6f9197`.
- All 41 recorded files match size/SHA256; scoped tracked/untracked changed-path
  set also contains exactly those 41 paths, with 0 differences.
- RESULT SHA256:
  `52f352508a49afbd764bf5eab8f59dec06ecd65ea895218901d4c1335eedaad0`.
- file-inventory.json SHA256:
  `f72751837a8b5976c601b792b1a19110638a2be2e6fec31798008c1053a78234`;
  all 422 listed evidence files independently match size/SHA256.

Paths below are relative to `com.rice.ai-codedb/` unless prefixed `.artifacts/`.
Inherited documentation/Unity state was not audited or modified.

## Frozen claims

| Claim | Disposition | Direct evidence and consequence |
| --- | --- | --- |
| Native no-handle creation | PASS | `Tools~/native/codedb-daemon-launch.cpp:27` initializes STARTUPINFO without std-handle flags; line 31 passes FALSE to CreateProcessW with detached/new-group flags. Lines 38-44 report creation metadata and close returned handles. Explicit executable/cwd and CRT argument quoting preserve the intended boundary. |
| Bounded real Node caller | PASS | `Payload~/AIWork/codedb/shared/codedb-daemon-launch.mjs:10` preserves the non-Windows route; line 17 rejects unsupported Windows architecture. Lines 21-35 check package-relative binary/hash/PE architecture; lines 36-50 bound invocation to 5s/8KiB, reject creation failures and decode creation evidence. No creation PID/exit code is used as readiness. |
| Real coordinator bindings and readiness | PASS | Flat coordinator diff changes only import and spawn boundary. `Payload~/Generations/poc.41/coordinator/codedb-watch-coordinator.mjs:516` preserves generation/lifecycle/arguments; line 539 preserves RICE_CODEDB_UNITY_ROOT. Lines 543-558 retain authenticated status, context/lifecycle matching and isLaunchReady. Comparison against poc.40 confirms only import/creation-block changes. Existing attach/stop/authentication bodies remain unchanged. |
| Developer build and provenance | PASS, saved build evidence reused | `Tools~/build-codedb-daemon-launch.ps1:20`, 24-55, 87-126 establish /MT x64 options, actual PE import inspection, source/script/binary hashes and developer tool metadata. BuildRoot is fresh under checkout .artifacts/tests; tool discovery has no embedded developer drive. Both shipped binary copies hash to `6d1ec230841951f2c80e8b8a0ffd3a385a4abff394690cc69e367a102f3544a3`. Saved build and canonical closure logs establish the reported KERNEL32.DLL-only result; no compile was repeated. |
| Canonical successor and package closure | PASS, source/worktree level | `Tests~/test-codedb-package-release-closure.ps1:137` projects only native creation; lines 154-176 require the next unused successor and validate provenance before writing; lines 218-255 copy source/binary/caller and derive manifest/pointer identities. Lines 377-387 verify flat and generation provenance and source closure. No new runtime poc.41 constant or exporter mutation was introduced. |
| Actual-chain behavior and owned shutdown | PASS, synthetic environment only | Production Manager writer and AST-imported production materializer collector feed real generated coordinator/caller/native executable. Four retained scenarios, authenticated status, three live checkpoints and matching-lifecycle cooperative stop support the claim below. |

The Node timeout can terminate its directly owned one-shot launcher; creation
effects after timeout remain uncertain. It does not establish READY, daemon
shutdown, safe replay or new cleanup authority. This matches the stated boundary.

## Evidence attribution and outcomes

Evidence root: `.artifacts/tests/nl41a/`. Reviewed harness construction and
assertions at `Tests~/test-codedb-daemon-launch.ps1:32-57`, 109-128, 139-191 and
`Tests~/test-codedb-daemon-launch.mjs:14-89` against saved JSON/log contents.
No harness was executed by Verifier.

The run3/run4 writer hashes equal current production writer SHA256
`657f780c53d2cc69e47b16a4b28954003a3fdfcf9397d551db779ac0f8bed0a4`.
Their production materializer hash equals current
`39e7872ab387457c477da318a271776ae4c9fc565e12af0f26ba2c8d072cc16a`.
Generation-manifest and test-JS identities match the stable snapshot. Independently
compared all 28 declared generation files in each scenario copy: normal/retained
have zero drift; missing/corrupt differ only at the intended native executable.
Thus product evidence is attributable to the reviewed implementation.

| Saved scenario | Native ms / exit / incomplete | Manager ms / exit / incomplete | External EOF ms | Verification |
| --- | --- | --- | --- | --- |
| run3/normal | 1530 / 0 / false | 1973 / 0 / false | 2539 | PASS; PID 14940 alive, provider ready and adapter watching at all 3 checkpoints |
| run4/missing | 731 / 1 / false | 1136 / 1 / false | 1712 | PASS; missing binary rejected, no coordinator state/readiness |
| run4/corrupt | 699 / 1 / false | 1080 / 1 / false | 1595 | PASS; provenance rejection, no coordinator state/readiness |
| run4/retained | 6535 / 0 / true | 11873 / 6 / true | 36298 | PASS; deliberate upstream retained stream remains incomplete; PID 52152 remains ready/alive |

These durations have different clock origins. Native TimedOut is false in all
four scenarios. Normal authenticated-status evidence rejects a wrong token with
UNAUTHORIZED and wrong-lifecycle Stop, then reports the expected generation,
lifecycle, provider ready and adapter watching. The harness performs the same
checks in retained. Matching-lifecycle cooperative-stop records return exit 0 for
PIDs 14940/52152. Scenario remaining-process arrays are empty. Final saved audit
contains 30 exact recorded process identities, all absent; SHA256
`b8f6b7f8413297b8b0ec3b159dc2df5612436b96bb74bb2db111b3ac3d98905a`.
This is saved exact-PID evidence, not a new live process scan or proof about every
short-lived process. Transfer/one-shot exits are separate evidence, as disclosed.

Run3 used PS harness hash `d223d146...`, while run4 and the frozen harness use
`35bc28fb...`. Do not describe normal as a rerun of the final harness bytes.
The earlier full harness bytes are not in the declared evidence inventory; its
reported missing-case assertion correction cannot be independently reduced to
that one textual edit from hashes alone. This does not defeat normal product
attribution: immutable scenario copies, writer/helper hashes, raw collector
results, authenticated status, PID/start-time checkpoints and stop records were
checked directly. Run4 failure/retention controls bind to the final harness.

Saved parse-checks contain 30 PASS entries. Saved closure-results and their five
logs agree: canonical PASS with 58 sources/0 mismatches; owned-copy binary,
source, options and build-script tampering each exit 1 with the specific expected
provenance mismatch. The copied closure test restores each changed file before
the next case. These are existing evidence, not independent reruns.

Independently compared all 358 historical generation files against before.json:
zero size/hash changes. All 9 prior transition objects remain identical, with one
new predecessor entry. preservation.json and its producer retain the 93-entry POC
inventory check with zero mismatches; successor changes are limited to generation
manifest, coordinator, caller and two native assets. Current package version stays
0.3.0-preview.5; no commit-derived delivery claim follows.

## Findings, workflow qualifications and deferred gates

Product findings: none under the user's frozen BLOCKER/FOLLOW-UP thresholds.
No additional hardening, platform, schema or inherited-state work is made a gate.

Coder's disclosed output-budget/whitespace-check deviations remain recorded and
were not treated as automatic evidence invalidation. Verifier also had output
discipline deviations: an early combined snapshot/native-source tool response
exceeded the 8KiB target, and a later evidence-tree search was truncated. No
claim of complete per-call compliance is made. Both were read-only; relevant
acceptance facts were independently obtained through compact hash/JSON/range
checks, without rerunning product tests. Neither truncated output is relied on
as exhaustive evidence. Review remained within the 30-minute scope and below
the cumulative 128KiB output envelope; this report is below 16KiB.

NOT RUN / DEFERRED: product C#/Unity compile and EditMode; real installation,
failed-candidate recovery, real Provider and adapter-worker execution, external
MCP, full suites, clean commit-derived git-archive export, Authenticode/reputation,
other platforms and release acceptance. A synthetic editor lease and synthetic
Provider do not establish any of these gates.

Terminal handoff: **Planner/User disposition**. Current frozen review is complete;
no Coder dispatch, automatic repair loop or broader audit is requested.
