# CodeDB artifact retention review — 2026-10-20

## Status

`POLICY_RECORDED / INVENTORY_COMPLETE / DELETION_NOT_AUTHORIZED`

This is a read-only organization task created after S35 was logically archived.
It records the first bounded inventory and the proposed retention groups. It
does not delete, overwrite, rewrite, or bulk-move artifacts.

The Artifact Lifecycle And Retention amendment is now recorded in workflow
revision 2.7. It adds lifecycle states, canonical-output rules, bounded
test-run retention, review triggers and staged cleanup checks. It does not
grant deletion authority for this inventory.

## S35 disposition

S35 is logically archived as `PARTIAL / BLOCKED` in the validation-project
index. The project was confirmed closed before this disposition: no Unity
process matched its project root, and no `Temp/UnityLockfile` or
`Library/EditorInstance.json` was present. The complete project remains at
`.artifacts/unity-projects/s35/` until its full-tree retention value is decided.

The authoritative package/human result remains in the S35 and S37 task records.
The historical malformed Supervisor operation is retained as evidence and is
not rewritten or deleted.

## Initial inventory

The largest top-level groups observed under `.artifacts/` were:

| Group | Approx. files | Approx. bytes | Initial disposition |
| --- | ---: | ---: | --- |
| `tests/` | 34,937 | 1.85 GiB | Review generated run artifacts by task/consumer; no bulk deletion yet |
| `unity-projects/` | 14,175 | 0.20 GiB | Keep S35 temporarily; retain fixed development project separately |
| `delivery/` | 612 | 0.16 GiB | Preserve linked human/release evidence until task closure review |
| `s29-payload-admission-hf-poc41/` | 3,379 | 0.08 GiB | Historical protected evidence; map before any cleanup |
| `s32-install-command-b0462ed/` | 1,528 | 0.05 GiB | Historical lifecycle evidence; map before any cleanup |
| versioned S34/S36/S37 package snapshots | about 1,200 each | about 29–30 MiB each | Candidate duplicate review; keep the exact current delivery and referenced historical packages |
| `validation-evidence/` | 187 | 9.2 MiB | Protected bounded evidence; retain |
| `archive/` | 2 | 19.8 MiB | Existing archive; retain and extend only with a named manifest |

The inventory also contains many S29-era source/package snapshots and older
`v0.3.0-preview.5-*` release candidates. Their names alone do not establish
that they are disposable: task records, package references, hashes and unique
failure evidence must be checked first.

## Proposed organization sequence

1. Build a path-level reference map from `.ai/tasks`, workflow records and all
   active Package manifests to each candidate artifact.
2. Mark exact current delivery, protected failure evidence and unique human
   acceptance evidence as `RETAIN`.
3. Mark byte-identical or superseded extracted snapshots as `REVIEW`, with a
   source-to-replacement hash mapping and recoverability note.
4. Move only explicitly approved evidence-only groups under a named archive
   directory; do not move a complete Unity project merely to reduce counts.
5. Delete only exact approved targets after containment, reference, hash and
   live-holder checks. Report removed paths and retained evidence.

No deletion or bulk relocation is part of this inventory. A later cleanup pass
must use an explicit target list and separate authorization.
