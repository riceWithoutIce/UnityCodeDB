# S39 MCP cwd registration fix — source result

Date: 2026-10-21. Status: SOURCE_COMPLETE / CONTRACT_ISOLATED_PASS /
NOT_COMMITTED / NOT_DELIVERED / REAL_CLIENT_ACCEPTANCE_DEFERRED.

## Behavior

New project registrations derive absolute cwd from the verified current Unity
root. Creation and repair share one values producer and a pure serialization
helper. Package source contains no developer-specific absolute path. Existing
relative or stale cwd values are updated through the existing explicitly
invoked config plan/publisher, retaining backup and drift guards. Equivalent
current cwd representations are preserved without config churn.

The flat and new-generation draft/validator use the same cwd helper. The cwd
reader accepts ordinary basic/literal quoting, slash/backslash forms, platform
case rules, Unicode and normalized trailing segments. It checks just this
single field against the current root; it does not probe the filesystem, add
environment prerequisites, expand variables or audit other MCP services.
Existing command/relative-args checks remain. The prior whole-config ban on
absolute paths is removed: it wrongly rejected legitimate client-owned values
and would reject the newly generated cwd. No general TOML parser was added.

Windows PowerShell 5.1 exposed a directly related UTF-8 issue in the validator:
default Get-Content decoding corrupted a Chinese cwd in a UTF-8 file. Both
current consumer layouts now explicitly read UTF-8. No runtime wrapper,
Provider, stdio, timeout, startup timing or background repair flow was changed.
Unconfirmed remains out of scope.

## Snapshot and exact scope

Base/HEAD: `237c72d9980114b99887fb8e805658447dd8d4fd`.
Branch: `codex/mcp-project-cwd`, attached managed worktree. Changes are unstaged,
uncommitted source, frozen by the local SHA-256 manifest below.

The existing canonical successor route produced poc.44. Its only differences
from poc.43 are generation-manifest.json, the draft, the validator and the new
shared cwd helper. The other copied generation files remain byte-identical.
Host/payload cross-hashes and the existing status fixture were updated through
the canonical writer. Package version remains 0.3.0-preview.5; this is not a
release/version announcement.

The raw-byte review finds 41 changed/new Package paths: 31 files in the new
generation plus 10 direct source/test/document/metadata paths. All 447 files
in predecessor generation directories match the base Git blobs exactly.
No historical generation was rewritten to make the change admissible.

On initial worktree creation, Git checkout normalized existing mixed/CRLF
bytes in three historical files. The task retained those checkout-produced
copies and extracted the exact base Package bytes from a Git archive before
implementation. Git status may still list these three EOL-filter artifacts;
the raw-byte review proves there is no actual historical-file byte delta.
Do not stage them as this task's changes.

Original checkout tracked-dirty count remains 69 and HEAD remains the base.
The external test project's config, manifest, lock, selected pointer and
wrapper all match their five frozen hashes, including restored original cwd.
There was no external config repair, Package switch, Install or process stop.

## Verification

| Scenario | Host | Final result |
| --- | --- | --- |
| `test-codedb-mcp-cwd.ps1 -Mode Contract` | PowerShell 7.6.5 | PASS 15 |
| Same contract scenario | Windows PowerShell 5.1.19041.6456 | PASS 15 |
| `test-codedb-mcp-cwd.ps1 -Mode Flow` | PowerShell 7.6.5 | PASS 16 |
| Same consumer-flow scenario | Windows PowerShell 5.1.19041.6456 | PASS 16 |
| Existing Package closure/production admission | Windows PowerShell 5.1 | PASS 62 declared files, zero hash mismatches |
| Owned source syntax/diff checks | PowerShell parser/Git | PASS |
| Raw Git-byte/source allowlist/external hashes | Read-only local reviewer script | PASS |

Contract coverage includes dynamic space/Unicode/apostrophe encoding, equivalent
representations, missing/wrong/relative paths, unchanged relative argv and
idempotence. Flow coverage executes actual production planner/publication
function bodies, preserves byte-exact pre-image backups and unrelated config,
regenerates after a move, and refuses intervening edits. It runs the unchanged
flat/successor validator and draft bodies with fixture context/Provider
boundaries. These fixtures never launch Provider, MCP or Unity. Operation-
ledger/fault-injection hooks are inert in the isolated publisher fixture;
publication/path/backup/drift functions themselves are production code.

The older aggregate materializer harness hardcodes 46 managed entries even
though the delivered base declares 60. This pre-existing fixture limitation
was found statically, not run or repaired as another task. Its cwd-specific
expectations were aligned, and its updated source parsed. The focused Flow
scenario supplies the immediate config/consumer evidence instead. No aggregate
materializer/full regression, real query, performance or upgrade PASS is claimed.

Retained corrections: two Contract fixture failures (invalid literal quoting
for an apostrophe-containing path; missing hash dependency); a Flow fixture
UTF-8 context-read correction and the resulting real 5.1 validator UTF-8 fix.
Earlier 13-case Flow passes preceded adding the directly affected flat-script
consumers; final 16-case results supersede them. Canonical generation preparation
also retained two pre-write invocation errors (implicit PackageRoot and omitted
required canonical-route switch) before the successful explicit invocation.
All failed evidence remains retained; no unchanged operational attempt retried.

## Evidence and limits

Local root: `.artifacts/tests/s39-cwd-fix/`.

- Contract final runs: `Contract-c76a455b45e44fc7a2ba60d2791c6929` (7),
  `Contract-409dd68689ab4f26982a791c58ca56e7` (5.1).
- Flow final runs: `Flow-6b27f73405814f01a412a0aff5d7af32` (7),
  `Flow-67d0e97bad41487c9e162701efc0982b` (5.1).
- `package-closure-complete.log`: final 62-file closure/admission.
- `raw-byte-review.json`: exact source SHA-256 list, immutable generations and
  external-project hashes; `review-source.mjs` is a local read-only verifier.
- `base-package.tar` and `checkout-filtered/`: retained baseline/EOL provenance.
- `refresh-cwd-metadata.ps1` in this task records the existing canonical-writer
  route used for current successor metadata; it never writes a consumer project.

Final generation manifest SHA-256:
`f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.
Final payload/runtime-contract SHA-256:
`ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5`.

This result addresses the supported cwd compatibility direction. The earlier
visibility experiment did not prove the historical failed child's effective
cwd or a fresh attributable handshake. Real-client acceptance still needs its
own agreed delivery/new-chat sequence, target status identity and one actual
query. No commit, export, external installation, Unity or real MCP action was
performed by this source task. At source completion delivery authority was NONE.
The user subsequently approved the separate DELIVERY-PLAN.md sequence on
2026-10-21 ("同意 批准"); delivery outcomes require their own receipt and do
not change the source evidence or real-client acceptance limits above.
