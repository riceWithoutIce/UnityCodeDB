# Development Workflow v2.6 — Package Integrity Gates

This file is a normative module of `codedb-workflow-v2` revision `2.6`.
The stable entry point remains [development-workflow.md](../development-workflow.md);
this module does not create a second workflow or authority.

## Implementation Rules

### Package Identity Authority Gate

Any task that changes a Package version, payload sequence, generation id,
generation manifest, current pointer, instance identity, or release artifact
must use one explicit identity contract route. Version and generation values
must not be copied as independent literals across PowerShell, Node, C#, JSON,
fixtures, or generated files.

- The task must name the canonical contract for the target generation and the
  read-only loaders used by each language. A language-specific script may
  validate or project the contract, but it must not become a second authority.
- `package.json`, the payload manifest, the current pointer, the immutable
  generation manifest, and instance manifests must be checked as one identity
  closure. Historical transition records are evidence, not a runtime source.
- Generation-owned scripts must consume the canonical contract. Package-boundary
  evidence must scan direct consumers for duplicated identity literals and must
  exercise the same generation materializer path used by the external Package.
- An immutable generation is never edited in place after a frozen or externally
  observed snapshot. A contract correction creates a successor generation and,
  when the Package identity changes, a successor Package identity. The prior
  generation and its failure evidence remain protected.
- A single external failure that exposes an identity mismatch is a structural
  contract finding. Stop retries and local typo fixes; route the task through
  `ROUTE_REASSESSMENT_REQUIRED` and use one coherent authority-refactor task
  spanning contract, loaders, generation materialization, boundary tests, and
  user-facing acceptance.
- A task is not ready for human Unity or external acceptance until the identity
  authority gate passes on the exact commit-derived artifact. Unity evidence
  cannot compensate for a failed Package identity closure.

### Record Contract Consumer Closure Gate

A change to a serialized field's shape, type, presence, validation or meaning
must close its producer-to-consumer boundary, even when the schema/version
number is unchanged or the field is described as additive. Identity/hash
closure alone does not prove that a runtime consumer can read the record.

- Name the authoritative record contract/schema route once. Each language
  projects that contract; a domain-specific parser for another record is not
  an independent authority or a generic JSON reader. For instance manifests,
  use the [project-integration contract](../v0.3.0-p0-project-integration-reinstall-contract.md#instance-manifest-contract-and-consumer-closure---2026-10-07).
- Put one compact map in the existing task: changed field and expected shape;
  production writer; real decoding entry points, including failure/cleanup
  paths; owning Package/generation; and focused evidence. Discover consumers
  from the actual call chain, not just filenames, the write allowlist or
  language-local tests. Shared decoding entry points may be grouped once when
  their caller bindings are demonstrated.
- For filesystem identity fields, distinguish original serialized bytes from
  path identity comparison. Freeze accepted path representations and reject
  relative or different-root identities; project the same comparison semantics
  across the affected languages. Normalize in memory only, preserving original
  records and byte-hash authentication. Include a production-writer-to-real-reader
  check; language-local PASS is not cross-language contract closure.
- Planner freezes that map and a coherent write/evidence scope. Coder closes
  the affected writers/readers and reports their bindings. Verifier checks the
  frozen map and attributable evidence, not a new whole-product audit. A
  consumer outside the current allowlist requires scope reassessment, not
  silent omission, widening, field removal or validation bypass.
- Use bytes emitted by the production writer with the real production reader
  for the target Package/generation in the existing focused harness. Cover
  the valid changed shape and directly coupled rejection cases. Inputs and
  temporary roots remain test-owned; pure decoding evidence does not require
  Unity, Provider, MCP or a real project. A synthetic downstream process may
  remain a seam, but it must not replace the decoding boundary being proved.
- If an affected reader belongs to a frozen/observed immutable generation,
  close the change through the existing successor-generation authority route
  before freezing delivery. Do not declare generation transition NONE merely
  because only Package-side source was initially allowlisted.
- Reuse the same focused evidence plan for the exact extracted delivery
  artifact, invoking its affected writer/reader route rather than worktree
  substitutes. Label byte closure and contract-consumer closure separately.
  Missing/failed evidence for a normal user path blocks that delivery gate;
  C# compile, fixture availability or a hash PASS cannot substitute for it.
- This map and evidence belong to the existing task/batch/review. They do not
  authorize full regression, unrelated schema hardening, a new schema platform,
  repeated unchanged tests, real runtime recovery or extra Unity sessions.

### Package Release Closure Gate

For retained-effect consumer changes, include the pre-fresh-install topology
when the optional bootstrap root is absent. A post-handoff emitted fixture may
create the root and hide a producer/consumer disagreement. Use actual emitted
records through the journal/session reader; retain adjacent missing recorded or
mandatory path and unknown-present refusals. No broader filesystem matrix.

For retained-recovery project-root consumer changes, distinguish immutable
record/command byte authentication from platform path identity. The bounded
consumer map includes the decoded receipt root and the recorded command argument
when both bind the current project. In focused actual-entry fixtures, independently
select recorded and caller root spelling; a single reused path variable cannot
prove cross-language slash/case/trailing-separator behavior. Keep original hash,
different-project and incomplete-root refusals in the same focused proof. This
adds no global path audit or new platform/schema framework.

For a change to failed-candidate mutable-output retention, include the producer
scope declaration, initialization consumer, recovery inventory consumer and
existing snapshot reader in the same bounded ownership/evidence map. Record
whether the operation preserves or deletes content; permission to inventory
and preserve a declared tree is not physical-cleanup authority. Exercise the
production declaration/initialization through the affected recovery entry with
representative nonempty and partial outputs. Do not replace it with an empty
handwritten topology or broaden the change into a generic ownership framework.

Any task that exports, installs, or publishes a Package must prove the bytes
that will be consumed, not only the source worktree. The release gate is a
single ordered closure and is required before Unity, EditMode, external
consumer, or publication evidence.

- One generator route must produce `generation-manifest.json`,
  `host-current.json`, and `payload-manifest.json` from the canonical identity
  contract. Manual independent hash edits are forbidden.
- Enumerate every `payload-manifest.files[*]` entry. Each declared source must
  exist, and its actual SHA-256 must equal the declared source hash. Missing,
  extra, or mismatched entries fail the gate.
- Cross-check the actual generation-manifest hash against the payload manifest,
  `host-current.generation_manifest_sha256`, and the activation/runtime target
  hash. Cross-check the actual `host-current.json` hash against its payload
  manifest target entry.
- Export the artifact from the frozen commit only, extract that exact archive,
  and rerun the complete closure validator on the extracted single-root
  Package. A worktree-only pass does not authorize release.
- Every export must also pass the production materializer's read-only payload
  manifest admission route, including its exact target-path policy, on both the
  commit-stage Package and exact ZIP extraction. Report byte/hash closure and
  production admission separately; export PASS requires both. Manifest entries
  cannot authorize themselves, and a focused native-output collector test does
  not prove manifest admission. This check does not run project installation,
  prerequisites, Unity, MCP, or an unchanged whole-product regression suite.
- A task adding payload files must name their manifest writer, production
  admission reader and focused evidence in its existing consumer map. Include
  the added audited targets and directly coupled unknown-target rejection cases
  in that same task; no independent parser or duplicate permissive target list.
- Complete the named changed-record producer/real-consumer checks on that
  extracted Package under the Record Contract Consumer Closure Gate. Keep
  their semantic result distinct from the byte/hash closure result; both are
  required for affected normal user paths before human acceptance. Do not
  turn this into an unchanged whole-Package test replay.
- Preserve any previously observed invalid artifact and its evidence. If an
  immutable generation was externally observed, either formally admit it as a
  protected historical failure or create a successor generation; never repair
  it silently in place.
- Unity/EditMode and external consumer acceptance are downstream gates. They
  must record the exact artifact identity and may not be used to compensate for
  a failed release closure.

## Package Path Provenance Gate

Every path consumed by Package code or tests must have an explicit source:
the current execution/project context, a Package-owned contract, or a
test-owned temporary root created or derived at test runtime. A serialized
fixture may use a symbolic template only when the test binds it to such a root
before invoking production validation. Do not embed a developer machine path
or a fixed drive-root "fixture" path in shipped Package source or tests, and
do not exempt a path merely because its name says `fixture` or `synthetic`.

For any change to Package text, run the focused
`Tests~/test-codedb-package-boundary.ps1 -PathProvenanceOnly` check before
freezing the Coder snapshot. It uses the same text-file selection and Windows
drive-root rejection as the full Package-boundary gate. Record the result in
the task handoff; a failure is corrected inside the task before Verifier
routing. For a task with no Package text changes, record `NOT_APPLICABLE`.
The focused check does not replace the full Package-boundary gate or prove
Unity/consumer behavior. Review relative paths, environment-derived paths,
and test-to-production binding at the directly affected call sites as part
of the task's normal source review.

For changed test writers, also apply the [test workspace contract](../test-workspace-contract.md).
Freeze root authority, direct consumers and cleanup/error evidence in the same
task envelope. A drive-literal scan alone cannot validate environment-derived
root selection. Check actual entry-to-helper binding and preserve primary test
failures when cleanup fails; no separate per-directory approval gate is added.

For changed physical storage layouts, include full consumer-path length and
publication suffixes in the same contract/evidence map. A writable parent or
short-path probe does not prove deepest consumer operations work. Test and
production receipt layout must share an authority; see the frozen
[Manager layout design](../manager-receipt-storage-layout.md). This gate does not
authorize migration or expand an existing test-only source allowlist.

Manager receipt changes follow that contract's full-Action/prefix16-Stage rules.
Full record identities remain authoritative; locator collisions cannot overwrite
or merge evidence. Preserve existing journal lookup and old-format read-only
evidence. Close C# admission, PowerShell writer, recovery, markers and test
consumers together, without a competing mapping database, silent migration or
relaxed production-root restrictions for tests.

For mixed compact/legacy fixture coverage, explicitly select and probe each
exercised layout before the test body. Include legacy filename overhead even when
production writes only compact records. Async test entry points must be supported
by the consumer Unity test runner; preserve internal await semantics and propagate
errors through supported coroutine entries. Merge still-open prior case groups
into the new human manifest instead of dropping them when regenerating a checklist.
