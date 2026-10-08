# Manager Receipt Storage Layout - Design Agreement

Date: 2026-10-08. User approved the concrete directory example below.
Status: SOURCE_ACCEPTED / HUMAN_COMPILE_TEST_PENDING.
This is the design authority, not proof of an implemented/validated on-disk format
or authority to rewrite existing records. Host Action Execution owns
action/evidence semantics; this document owns the proposed physical layout.

## Logical identity versus physical location

Project, Package source, Action, Stage and command identity remain required
logical distinctions. Complete identity values stay in records and must be
validated by readers. A short path locates a record; it does not authenticate it,
authorize execution, imply ownership or permit a mismatching record to overwrite
another. Neither Action IDs nor command/Stage hashes are semantically shortened.

One Action is the physical container. Stage and evidence kind are distinguished
by file names inside it; project/Package/Stage identities do not each require
their own physical directory. Do not introduce a separate database, generic
recovery service or competing identity authority merely to shorten paths.

## Initial illustrative example (refined below)

Under the actual Unity project's root:

```text
Library/CodeDB/Tests/
  r7k2/                       # one test-owned workspace
    .owner.json               # illustrative ownership record
    project/                  # simulated project, not the actual project
    package/                  # simulated Package, not installed source
    a9f3/                     # one Action receipt container
      s01.admitted.json
      s01.claim.json
      s01.terminal.json
      s02.admitted.json
      s02.claim.json
      s02.terminal.json
```

There is no additional receipts-GUID wrapper. r7k2, a9f3 and s01 illustrate
compact names only: they do not freeze four-character randomness, eight-character
hashes, sequential Stage allocation, a new marker schema or exact extension.
The current workspace marker need not be renamed merely to match the diagram.

Production uses the same receipt layout beneath its existing authorized root:

```text
<existing production receipt root>/
  <Action locator>/
    <Stage locator>.admitted.json
    <Stage locator>.claim.json
    <Stage locator>.terminal.json
```

Tests inject their one owned root into the actual layout/writer/reader route.
They must not silently use a separate shorter receipt layout from production.
Production receipts are not moved into Library/CodeDB/Tests. This agreement does
not relocate Provider installations, runtime candidates or MCP registration.

## Path feasibility and evidence

Budget the full physical path through every direct consumer, including the
longest evidence filename and atomic-publication temporary suffix. A shallow
workspace probe is not evidence of deepest-path usability. Validate representative
create/read/delete operations using the target runtime's real filesystem APIs,
with meaningful boundary coverage. Keep the workspace contract's ownership,
containment, cleanup and primary-failure preservation rules.

This example reduces CodeDB's added path length but does not guarantee arbitrary
project-root lengths. Actual limits and supported behavior need target-runtime
evidence. No implicit system-temp fallback, drive alias, registry/ACL/privilege
change, manual project relocation or shortened semantic identity is implied.

## Initial open questions (resolved in part by the approved rules below)

1. Locator allocation and recovery: choose a bounded unique creation method,
   validate complete identity on lookup, and define collision/concurrent-creation
   handling without blindly truncating hashes or silently reusing directories.
2. Discovery and consumers: bind existing journal/index, stage writer/readers,
   resolved marker, restart/Package replacement and cleanup to one layout route.
   Removing project/Package directories must not require a broad machine scan or
   confuse projects. Decide whether existing journal metadata is sufficient.
3. Historical records: choose and freeze an explicit legacy read/transition or
   defer policy. Preserve current evidence. No automatic deletion, migration,
   replay or failure erasure is authorized by this design agreement.
4. Implementation scope and evidence: enumerate direct writers/readers, including
   any Package/generation projections; honor immutable-generation constraints.
   Freeze one coherent change/test envelope before Coder dispatch. Do not fit a
   production storage change into the previous test-only allowlist.

S29 human validation remains failed/pending. This design cannot retrospectively
turn source reviews, byte checks or old failed test runs into runtime PASS.

## Approved concrete rules - 2026-10-08

The user approved and requested recording this refinement. This section supersedes
the initial short-Action example and its undecided allocation/transition policies.
It freezes design rules, not implementation or authority to change live records.

### Physical layout and identity

```text
<actual Unity project>/Library/CodeDB/Tests/
  7c91a20bd384/                         # short, exclusively owned test run
    .codedb-test-owner                  # retain full ownership token
    project/                           # simulated project
    package/                           # simulated Package
    eb3f4aa1003d4d989d3f9dabfee29782/    # complete existing Action ID
      a48ebf94ac92af47.admitted.json
      a48ebf94ac92af47.claim.json
      a48ebf94ac92af47.terminal.json
```

Production uses the same Action-directory/Stage-file layout under its existing
authorized receipt root, not the test Library directory. No receipts-GUID wrapper
or project/Package/Stage directory nesting in the new receipt layout.

Retain the complete existing32-hex Action ID as directory name. Use the first16
lowercase hex characters of the full64-hex Stage hash as file locator; do not
shorten semantic Stage/command identities. Full project, Package, Action, Stage
and command identities remain in records and are checked on creation and reading.
The short workspace example is illustrative; exact name length and exclusive
allocation method must be specified in the implementation packet/path budget.

### Allocation, collision and lookup

Workspace directories are exclusively created, never silently adopted. Any
allocation retry is bounded and precedes side effects. Keep full ownership tokens
in markers. No Action mapping table or external allocation database is introduced.

A same-prefix/different-full-identity Stage collision is explicitly refused: no
overwrite, mixing, automatic replay or blind retry under a different name. Matching
full identity also does not authorize replay. Concurrent creation must preserve
exclusive claims and no-overwrite publication; check-then-overwrite is insufficient.

The existing project journal/index remains the lookup authority for current and
historical actions. Its project-scoped index may retain a separate directory;
that directory is not the mandatory parent of every receipt. No machine-wide
discovery, competing lifecycle owner or extra database. Package replacement and
restart recover original Package/project identity from validated evidence.

### Old records and new writes

After implementation/validation, new actions write the compact format. Old
records stay in their original location and are read via an explicit legacy-format
branch. No automatic copy, migration, rename, flag rewrite, deletion or replay.
This preserves historical evidence, not old-Package upgrade/execution compatibility.

Formats must be unambiguously distinguished; malformed new records must not fall
back to old interpretation to pass. Conflicting old/new evidence cannot be resolved
by choosing whichever passes. Exact pending/resolved layout binding and treatment
of active old writers must be specified before implementation; no old execution
continuation is authorized merely by this read-only preservation policy.

### Full-path evidence and implementation closure

For the observed S29 project root, the concrete admitted path above is162 characters;
the existing C# atomic suffix (dot +32-hex GUID + .tmp) makes it199. These are
calculated examples, not Unity execution PASS or a universal path limit. Budget
all evidence names including start-failure, journal/marker paths and both C# and
PowerShell publication temporaries. Probe actual deepest create/read/delete routes,
not just a shallow workspace file; preserve all workspace ownership/cleanup rules.

Close these direct consumers together in one implementation envelope:

| Boundary | Existing entry points |
| --- | --- |
| Identity/path derivation and test root | AICodedbPaths, AICodedbTestWorkspace, receipt/session fixtures |
| Admission and result recovery | AICodedbProcessRunner, atomic publication and complete stage enumeration |
| Child writer | Tools~/invoke-codedb-manager-action.ps1, old suffix assumptions, claims/results |
| Lookup and markers | AICodedbManagerActionJournal, Manager session, restart/Package replacement |
| Evidence | Actual writer/reader layouts, both formats, collisions, full-path I/O and cleanup |

Do not put this production/test storage change under the previous test-only
allowlist. Enumerate any directly coupled Package/generation projections and
respect immutable generations. Preserve the production writer's machine-root
confinement; tests cannot achieve isolation by weakening that check or globally
changing environment variables. Shared layout/decoder checks and any child-writer
test seam require explicit scope. Schema discrimination, exact journal fields,
atomic allocation, path limits and active-old-writer handling remain implementation
details to close under the approved policies before Coder dispatch.

## Implementation binding frozen - 2026-10-08

User approved the complete implementation boundary. The active execution packet is
`.ai/tasks/v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/RECEIPT-LAYOUT-TASK.md`
(repository relative). These choices resolve the remaining implementation questions
above without changing logical action/effect authority:

- New admission, claim, terminal, start-failure and ordinary current/resolved index
  records carry `storage_layout: "compact-v1"`. Existing schema meanings stay intact;
  special historical resolved schema2 remains legacy-only. Legacy absence is read
  only in the explicit legacy branch. Unknown/missing compact binding is conflict.
- New writer `ReceiptPath` takes the exact compact admitted file, not a stage
  directory. Existing root confinement and full identity validation remain required.
- Action32 contains atomically published `action.json` binding full action/project/
  Package identity and layout. It is an identity manifest, not another lifecycle
  owner. Existing project journal/lock authorizes admission; duplicate stage evidence
  never authorizes replay. Interrupted/ambiguous dispatch keeps existing effect rules.
- Test workspaces use12 lowercase hex and full ownership token, with exclusive
  reservation and no existing-directory adoption. No allocation collision retry is
  needed in this task. Deepest-path probes include temporary and index/marker names.
- Legacy active writers may finish independently; new code observes their old
  receipts through legacy validation. No new legacy launch, migration or flag rewrite.
- Actual PowerShell writer tests use repository-owned scratch and only child-scoped
  environment overrides. Production confinement is not weakened for fixture access.

Implementation/source review and later human Unity evidence remain separate gates.

## Source acceptance - 2026-10-08

User accepted the implementation after FIX01 independent source review closed
both compact fixture consumer migration and original-context retention on conflict.
The named immutable-generation/legacy-materializer dependency check also closed.
PowerShell writer12/12 passed at a227-character tested publication path. C#34
methods/80cases and actual Unity filesystem behavior remain unrun; S29 integration
is not accepted by this source decision. New delivery must preserve exact reviewed
bytes and pass commit-derived/extracted artifact gates before human validation.

## Human test follow-up: legacy fixture feasibility

Human validation of the accepted artifact failed while writing a legacy fixture
at260 characters, before any recovery assertion. Compact path evidence does not
cover this retained old layout. The shared test workspace contract's subsequent
`Library/cdt/<8hex>` revision and explicit compact-plus-legacy capability profile
govern new test runs. Production layouts/full identities and old-record read rules
do not change; historical records and exports remain untouched. Runtime feasibility
of the revised tests remains pending human validation.
