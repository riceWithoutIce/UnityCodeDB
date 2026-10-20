# Proposed diagnostics delivery — 2026-10-20

Status: GRANTS_A_B_AUTHORIZED / EXECUTION_IN_PROGRESS.

The human explicitly replied `批准` to the named commit, exact Package
export/verification/copy, and CodedbTest_1 manifest/sample preparation sequence.
Execution stops before human Unity compilation/first Install. This authorization
supersedes the proposal-only status; it does not expand the listed boundaries.

Purpose: deliver the checked diagnostic bytes through the normal Package and
first-Install path, preserve CodedbTest_0, then obtain evidence from a separately
authorized actual-host attempt. Root cause and query acceptance remain open.

## Proposed bounded grant A: exact local commit and Package delivery

Suggested commit message:
`fix(codedb): retain bootstrap termination diagnostics`.

Package scope is exactly the six candidate paths in
`DIAGNOSTICS-DELIVERY-PREPARATION-RESULT.md`, with bytes recorded by
`.artifacts/tests/s39-diagnostics-delivery/r-e9f859cd/candidate-diff.json`.
Stage the candidate bytes, not broad dirty worktree directories. Preserve the
worktree's unrelated generated metadata and contract-document hunks. A scoped
Git index/blob operation can stage the candidate metadata/document without
overwriting those working files. Inspect the complete staged diff before
committing; stop on any extra Package delta, changed base, or candidate drift.

Task-record scope under this task directory:

- `TASK.md`: bootstrap diagnostics and local preparation sections, corresponding
  current handoff changes only.
- `RESULT.md`: diagnostics source completion and delivery-preparation additions
  only; exclude earlier unrelated/historical unstaged result additions.
- `BOOTSTRAP-DIAGNOSTICS-RESULT.md` including its appended portability note.
- `DIAGNOSTICS-DELIVERY-PREPARATION-RESULT.md`.
- `DIAGNOSTICS-DELIVERY-PLAN.md`.
- `prepare-diagnostics-delivery.ps1`.
- `test-diagnostics-handoff.ps1`.

Do not stage other untracked historical handoffs, receipts, deferred trace/shim
plans, artifacts, generated caches or unrelated repository changes. Existing
historical evidence remains on disk. No push or public publish is proposed.

After explicit authorization, commit this exact snapshot, record its full SHA,
and export only that commit's Package. Extract the exact ZIP into a fresh owned
repository-local directory and verify byte closure, immutable bindings, path
provenance and all 15 diagnostics scenarios using the extracted copy. Stop on
the first failed delivery check; do not consume a failed artifact externally.

Only after checks pass, copy the exact extracted Package to a fresh
`<external-packages>/<new-commit>/com.rice.ai-codedb` directory. Refuse overwrite
of an existing nonmatching destination. Preserve the c07bb59 delivery and its
artifact bytes. Record artifact SHA-256 and copied-file closure in the receipt.
This is local artifact delivery, not public distribution or release acceptance.

## Later human-owned project gate

The human creates CodedbTest_1 using the same Unity version as the original
project (2022.3.62f3), then closes it and provides its exact root. No automated
Unity launch, project creation or Editor process control is proposed.

After a specific project-preparation grant, inspect only the named project and
prepare its Package reference, corresponding lock handling through the agreed
normal import flow, and query sample. Stop if existing content conflicts; do
not silently overwrite local changes or synthesize imported lock authority.
Use the exact newly delivered Package path. Keep CodeDB registration generated
by the normal integration; no shim, substitute service, global config change,
environment patch or extra startup wrapper is proposed.

The human opens/imports/compiles the project and performs one normal first
Install. Record human compilation/Manager observations separately from disk
identity. Stop at failure or Needs attention and collect bounded existing
evidence before any further action. No automatic Install retry is included.

CodedbTest_0 configuration, runtime, identities, old failed attempts and owner
state remain protected. Using a different project does not authorize stopping
its old Supervisor or managing any external process.

## Later real-client gate

After human Ready, align a fresh target-root actual Codex attempt with new
project/instance/epoch/contract evidence. Do not reuse either old attempt's
grant or expected namespace. Observe target tool exposure before a bounded
status/query sequence. Missing target tools stops the attempt; no substitute
CodeDB service or manual wrapper query is acceptance evidence.

Diagnostic files carry disk-selection identity only. Absence of a record does
not prove that the wrapper never started; pre-import failure and forced exit
remain coverage limits. Retain requested wrapper exit, worker exit, actual
child exit and probe-requested termination as separate facts. Ready and isolated
fixture PASS do not complete the real-client query or response-identity gates.

Grant A does not authorize project edits, Unity/Provider/real MCP startup,
new-chat dispatch, Install, tracing, process control, push or public publish.
Those human/environment gates remain separate. If the user chooses to reuse
CodedbTest_0 instead, align the identity-changing reinstall route before acting.

## Fresh project confirmed; proposed bounded grant B

The user chose CodedbTest_1, created it and reported Unity closed. Read-only
preflight confirms version 2022.3.62f3 (96770f904ca7), an ordinary project-root
directory, no CodeDB manifest dependency, no AIWork directory, no project
`.codex/config.toml`, and no `Temp/UnityLockfile`. The absent lock file supports
the human report; it is not an independent process inventory. No process was
enumerated or controlled, and no external file was written.

Project-relative preflight SHA-256:

| Path | SHA-256 |
| --- | --- |
| `ProjectSettings/ProjectVersion.txt` | `b51164d22c4d2716ba8aee7f0b59d6b7dd0efa8552fd1db2a8c3b123fae3a1ec` |
| `Packages/manifest.json` | `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1` |
| `Packages/packages-lock.json` | `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6` |

The six candidate Package hashes still match their preparation receipt and
HEAD remains the recorded base. The Git index is empty. Choosing/creating the
new project does not itself initiate the exact commit in grant A.

Grant B is proposed for the named CodedbTest_1 project only, after successful
grant A delivery:

1. Recheck the recorded project inputs and human-closed condition before writes;
   stop on unexpected changes or conflicting sample content.
2. Add only `com.rice.ai-codedb` to `Packages/manifest.json`, referencing
   `file:../../Packages/<new-commit>/com.rice.ai-codedb`. Confirm that path resolves
   to the newly verified external Package. Preserve all other dependencies.
3. Create `Assets/CodeDBAcceptance/S39QueryProbe.cs` as the simple static query
   sample below. Record its exact hash and marker line for the later handoff.
4. Leave `Packages/packages-lock.json` and `.meta` generation to the human's
   normal Unity import. Do not pre-create MCP registration or runtime state.
5. Return a checklist for the human to open/import/compile and perform one first
   Install. Stop at that human gate; no launch, Install or real-client retry.

Proposed complete sample (UTF-8, LF):

```csharp
namespace CodeDBAcceptance
{
    public static class S39QueryProbe
    {
        public const string Marker = "CODEDB_S39_EXTERNAL_20261020";
    }
}
```

Grants A and B may be explicitly authorized together. Their combined boundary
is exact local commit -> artifact verification/copy -> manifest and sample
preparation -> stop for human Unity work. No push, public publish, old-project
write, registration timing workaround, real runtime startup or process control
is included. The preflight and grant-B text are part of the named task-record
scope for the proposed commit, not an additional Package delta.
