# S39 startup diagnosis 01: missing stable-wrapper dependency

Date: 2026-10-20.
Status: `SOURCE_CAUSE_IDENTIFIED / REPAIR_SCOPE_PENDING`.

## Authorization and execution

The user approved diagnosis after client attempt 01 stopped and asked whether
the next test requires another Unity project. This pass inspects the existing
project, delivered Package, their direct startup/publisher/probe dependencies
and retained host logs. It does not authorize a product repair, delivery,
Install/reinstall, new external client attempt or new Unity project.

Only source/filesystem/hash reads and Node resolution/version inspection ran.
No wrapper or instance worker was executed, no runtime probe or MCP request was
made, no project state was changed, and no process was stopped. A malformed
PowerShell read/hash command failed at parse time and was mechanically
corrected; it was not a product test.

## Confirmed immediate startup defect

1. The installed stable entry is
   `<external-project>/AIWork/codedb/wrapper/codedb-project-wrapper.mjs`.
2. Its line 8 is a top-level ES module import:
   `import { parseCodedbInstanceManifest } from "../shared/codedb-instance-manifest-contract.mjs";`.
3. That resolves to
   `<external-project>/AIWork/codedb/shared/codedb-instance-manifest-contract.mjs`.
   The target does not exist; `AIWork/codedb/` contains only `wrapper/`.
4. The dependency exists inside the delivered Package under
   `Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.mjs`.
   The payload manifest declares that source and the matching project target.
   Its SHA-256 matches the declared
   `de2366310169830738ceef4cba4d24e2b54da72f6a8a11ec8c564b4dc298d07f`.
5. Installed, delivered and development-source wrappers have identical SHA-256:
   `7f209316005ffd02bccd01c78ae1773d695694a77817d99f1753041b6aef4399`.

A missing statically imported module prevents evaluation of the wrapper body;
it fails before the try block, instance selection, Worker construction or MCP
initialize handling. This is a concrete entry-point dependency defect and
explains a connection closing before initialize. Original child stderr/exit
code were not recovered, and no fresh runtime reproduction is claimed.

## Publisher cause and why installation Ready did not catch it

The delivered `Tools~/codedb-instance-engine.ps1` has the same bytes as the
development source, SHA-256
`7f87723497483a5a679cd7c8d52b3101119381d32bd143f1fe8bfe332ac68cf1`.
These verified source references therefore apply to both:

- `Get-InstanceActivationEntries`, lines 3503-3581, builds the activation
  transaction. Lines 3517-3518 select the stable-wrapper file; line 3578
  publishes it. The function does not add its sibling shared module to the
  activation entries. The retained committed control operation likewise
  records publication of the wrapper, with no shared-module publication.
- `Invoke-InstanceCandidateProbe`, lines 2648-2659, selects the generation's
  `wrapper/codedb-project-instance-worker.mjs` and passes that worker as
  `--wrapper` to the probe. This bypasses the stable project entry used by
  `.codex/config.toml`. A successful generation-worker status/query probe
  therefore does not exercise the missing top-level stable-wrapper import.
- `Assert-InstanceStableWrapper`, lines 3600-3619, checks stable-wrapper
  presence and SHA-256 only; it does not validate imported sibling modules.

The source and retained project state establish a publication dependency gap
plus a validation gap. They do not establish a damaged Unity project, lack of
Git support or a post-handshake tool-injection defect.

## Environment evidence limit

The current diagnostic shell resolves Node `v24.14.1`, the same version named
by the original Install prerequisite output. Another bundled Node is present
later in current command resolution. This is not proof of the executable or
environment selected by the earlier Codex MCP child. The missing relative
module remains a defect independent of that unresolved historical detail.

## Repair boundary and test-project decision

Repair should close the stable-entry dependency contract and its verification
gap, then check the real registered entry. Do not silently copy a module into
the consumer project as the product fix, rewrite the frozen delivered Package,
or relabel a direct probe as real Codex evidence. The choice between a fully
self-contained stable entry and publishing/managing its dependency closure
must be frozen before implementation; the latter also touches ownership,
retirement, rollback and removal responsibilities.

Use the existing `CodedbTest_0` for diagnosis and the later repaired-client
regression. It retains the attributable failure, original Install and selected
identity; no evidence presently requires a new Unity project. A new Codex chat
or explicit reconnection may be needed for a future authorized client attempt,
which is distinct from creating another Unity project.

If the chosen fix changes first-install publication, it also needs a clean
first-install scenario to prove that no manually retained dependencies hide
the defect. Start with an isolated focused fixture. A later real fresh-project
acceptance can be separately agreed if required; same-project client success
alone cannot establish that clean first-install gate.

Next action: User/Planner aligns the narrow repair design and allowlist, its
focused evidence, delivery boundary and future client-attempt bounds. Original
S39 query acceptance remains BLOCKED and no retry is included in this pass.
