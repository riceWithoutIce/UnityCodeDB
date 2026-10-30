# Candidate export result — 2026-10-26

Outcome: `EXPORT_BYTE_PROVENANCE_PASS`. One export attempt, exit code 0,
no repair flags, retry or alternate exporter. All paths repository-relative.

| Identity | Actual result |
| --- | --- |
| Candidate commit | `11056964da1143955ed69a067361622799e3d6f2` |
| Package Git tree | `0690f9fee09541da2d75df6878f53c0114869ce9` |
| Package / generation | `0.3.0-preview.5` / `poc.44` |
| ZIP file count / size | 669 / 3,491,580 bytes |
| ZIP SHA-256 | `8a3fcad610093f17eca062726cd5412ad47a64bf565e835690e69b9de8329ef8` |
| Committed-source manifest SHA-256 | `e1f7ff9eb53b0ad10362e3b3ae1a37e5c2658370950683e6501ef97769365229` |
| Generation manifest SHA-256 | `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb` |
| Runtime contract / payload manifest SHA-256 | `ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5` |
| Stable wrapper SHA-256 | `a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e` |

## Artifact and checks

Artifact:
`.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/export-1105696/com.rice.ai-codedb.zip`.

Exporter's commit-staged Package and exact ZIP both returned:

- `[PRODUCTION_PAYLOAD_ADMISSION] PASS file_count=62`
- `[PACKAGE_BYTE_CLOSURE] PASS source_count=62 mismatch_count=0`
- `[PACKAGE_CLOSURE] PASS byte_closure=PASS production_admission=PASS`
- `[PACKAGE_EXPORT_GATE] PASS` for each of the two artifact forms.

Existing native VerifyOnly evidence checks also passed; no native build or
daemon launch was requested. Exporter source matched the candidate Git blob;
new repository-local output paths were verified absent before invocation.

After export, both 669-file directories (`package/` and extracted `review/`)
were checked against the frozen committed-source manifest. All file hashes
also matched the 669 candidate Git blobs. The ZIP hash matched exporter output.
Candidate HEAD, tracked source and Git index are unchanged.

Evidence directory:
`.artifacts/tests/cdb-v0.3-candidate-freeze-delivery-preparation/export-1105696-evidence/`.
Contains preflight.json, full export.log, execution.json, verification.json and
artifact-file-manifest.json. Earlier frozen evidence remains untouched.

## Boundary and next step

This closes this candidate's exact export byte/production-admission gate only.
Unity compilation, NUnit/EditMode, consumer Manager/runtime, real client MCP,
lifecycle, performance and release acceptance remain NOT_RUN for this export.
No consumer package copy or reference switch, registration/runtime edits,
Unity/MCP/Supervisor start, install/uninstall, commit/push, board change, tag
or release. This stage adds task records only to the primary working tree.

The concrete proposed delivery is in DELIVERY-PLAN.md: copy the validated exact
Package to the existing test root's
`Packages/1105696-v03-reviewed-candidate/com.rice.ai-codedb`; verify the complete
inventory, preserve the old package, back up and switch only CodeDB's manifest
and lock references. It requires the user's delivery grant and current explicit
confirmation that CodedbTest_2 Unity is closed. No state inferred from old reports.
