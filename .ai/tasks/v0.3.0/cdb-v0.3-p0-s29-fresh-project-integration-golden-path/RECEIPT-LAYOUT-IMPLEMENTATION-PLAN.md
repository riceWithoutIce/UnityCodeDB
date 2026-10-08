# S29 compact receipt layout - implementation alignment

Date: 2026-10-08. APPROVED / SUPERSEDED_BY_FROZEN_EXECUTION_PACKET.
User approved continuation; RECEIPT-LAYOUT-TASK.md is the active frozen entry.
The inspection and recommendations below preserve the planning rationale.
User authorized continuing analysis after frozen layout rules. This packet turns
that design into direct-consumer scope; it does not implement or authorize live
migration. Canonical rules: Documentation~/manager-receipt-storage-layout.md.

## Inspected facts

- AICodedbPaths uses project24/Package24/Action32 and separate project index.
- ProcessRunner adds Stage64, writes admitted.json atomically using a GUID suffix,
  and enumerates stage directories on recovery.
- ManagerActionJournal stores project current/resolved entries and scans bounded
  legacy Package/action directories when needed. Resolved schema2 already means
  HistoricalUnknownReconciled, not storage layout2.
- Tools~/invoke-codedb-manager-action.ps1 takes a stage directory, requires it
  within the machine receipt root, verifies its old identity-derived suffix,
  and publishes claim/start-failure/terminal records. It is a direct consumer.
- Tests~/test-codedb-package-boundary.ps1 ManagerActionWriterOnly currently uses
  system temp for fixture project/Package and real LOCALAPPDATA for receipts.
  This is not acceptable isolation for new evidence under the workspace contract.
- Materializer's historical reconciliation reader near10958 is bound to a
  particular legacy action/stage and expected old admission+claim cardinality.
  It is a legacy-only direct reader, not a general compact action writer. Preserve
  this contract; do not silently convert it into new-format recovery authority.

## Recommended bounded decisions

1. Separate record schema from storage layout. Add explicit compact-layout binding
   to new admission, emitted receipts and current/resolved journal records. Do not
   reuse schema2 as a universal layout discriminator: that value already has an
   independent resolved-marker meaning. Freeze exact schema/field combinations in
   the Coder packet, including old-field-absent interpretation only at legacy paths.
   A new-path missing/wrong layout field fails; never fall back to legacy to pass.
2. Keep existing project index/lock scope; journal binds full Action ID and layout.
   Action receipt root is directly derived from authorized root plus full Action
   ID, with prefix16 Stage files. No second mapping table or broad root scan.
   Preserve full project/Package checks and history links after current entry is
   resolved. Missing/corrupt index is not permission to discover arbitrary actions.
3. Reserve a new action under existing admission authority; publish stage admission
   with exclusive/no-overwrite semantics and validate full identity before claim.
   Same locator/different full identity is conflict; same identity is existing
   evidence, never replay. Specify interrupted reservation/publication behavior
   before implementing, reusing journal ownership rather than another allocator.
4. Old operations are observed, never migrated or restarted automatically. An old
   pending/unknown operation retains existing admission rules. If an already
   dispatched old writer later emits a terminal record, read it through the legacy
   reader and existing validation; do not stop external processes or infer absence
   of effects from missing old files. Existing effect/PENDING rules stay intact.
5. Use short exclusive per-test roots (candidate12 hex with full owner token), no
   receipts-GUID wrapper. Freeze bounded collision handling and validate complete
   path including longest record/atomic temp name before writes. Representative
   deepest-path I/O must use actual target APIs. Do not introduce OS settings or
   a hard Unity patch-version requirement. Exact numeric limits require explicit
   implementation/evidence rationale, not an arbitrary new admission gate.
6. Move the focused writer fixture into repository .artifacts/tests/<run>/;
   launch only the fixture child with private LOCALAPPDATA/TEMP/TMP beneath that
   owned run. Parent/Unity/user environment unchanged; production writer still
   derives and confines paths to its own process environment as before. This is
   isolation of an authorized test process, not a new arbitrary-root production
   CLI option. No real machine journal or system-temp writes for this fixture.

## One coherent implementation unit

Expected source closure: AICodedbPaths, ProcessRunner, ManagerActionJournal,
invoke-codedb-manager-action.ps1; Manager session/action consumers only as directly
needed for layout propagation; AICodedbTestWorkspace, ManagerUiTests and direct
context tests; focused Package-boundary writer fixture. Shared language projections
may need one focused layout helper; choose its exact path and authority in the
write allowlist, not ad hoc copies of policy. Inspect directly coupled hashes and
Package/generation manifests before declaring any generation transition needed
or unnecessary. Historical generations remain immutable.

Read-only legacy materializer reader and its historical fixture stay unchanged
unless a concrete direct contract conflict is found; then reassess exact scope.
Do not redesign historical process proofs, broaden cleanup or reopen deferred
F-IMC-01/P3. Product action/effect authorization stays the existing contract.

## Evidence plan to freeze before execution

- Production C# path/record reader fixtures: compact success, preserved legacy,
  wrong/missing layout, collisions, duplicate evidence, Package replacement,
  immediate/resolved session behavior and pending old operations.
- Actual isolated PowerShell writer: compact admission->claim->terminal and
  refused replay/identity conflict. Assert all files confined to test root;
  do not invoke real host/Provider/Unity commands as fixture children.
- Physical path: representative S29-length project context plus longest filenames/
  temp suffix, full create/read/delete under target runtime; over-budget input
  gives precise pre-effect failure with no fallback or lost primary error.
- Reuse existing bounded scopes for failure/timeout/output scenarios only where
  changed writer layout directly affects them. No full regression or unchanged
  unrelated test batches. C# compilation/EditMode remains human-owned, source
  and PS PASS cannot substitute for it.
- After stable Coder snapshot: independent Verifier reviews the same consumer map
  and original path/format/identity boundaries; findings once to user.

Next: confirm the proposed execution boundary, freeze exact allowlist/schema and
bounded test process budget, then dispatch one continuous child Coder and later
Verifier. No new package, Unity retry, real cleanup, migration, commit or source
edit was performed during this design inspection.

## Planner path arithmetic during authorized implementation

Using the actual S29 project path,12hex workspace and existing C# GUID32 temporary
suffix, admitted is162 characters; Stage start-failure temporary is204; current
index temporary is213 and resolved index temporary214. These are string-length
calculations, not filesystem/Unity evidence. Final implementation must report its
actual names and probes; journal temporaries cannot be omitted from the budget.

Stable Coder accounting correction: journal publication actually uses
`<receipt root>/index-<GUID32>.tmp`, not a suffix on the current/resolved filename.
Its S29 calculated length is141; current/resolved final files are176/177. The
213/214 values above describe the earlier conservative suffix assumption only.
The final isolated PS deepest publication path measured227; Unity remains unrun.
