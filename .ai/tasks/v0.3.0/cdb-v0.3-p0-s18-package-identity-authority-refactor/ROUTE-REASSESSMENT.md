# Route Reassessment: cdb-v0.3-p0-s18-package-identity-authority-refactor

## Trigger

- Blocked acceptance path: successor Package identity authority and external
  Configure Dependencies golden path.
- Repair iterations: `0/2` in this refactor task.
- Consecutive diagnostic-only checkpoints: `1/3`.
- Immediate structural signals: one additional Package-version authority was
  found outside the initial implementation allowlist.

## Frozen State

- Source/task identity: HEAD
  `7bd3eaca0243b17fbc60cd3d3a624f755846408b`; all seven TASK baseline hashes
  passed inventory admission.
- Last acceptance state: `poc.38` external convergence failed because its
  generation manifest declares sequence `38` while its common PowerShell
  runtime authority declares `35`.
- Protected state: every `poc.38` byte, commit-derived artifacts, and the
  external project's nine `PROVISIONING` instance directories.

## Causal Summary

- Established facts:
  - The payload manifest can remain the canonical Package runtime tuple.
  - The immutable generation manifest is the hash-bound projection consumed
    by PowerShell and Node loaders.
  - Existing C# loaders and the materializer already validate the pointer,
    manifest, generation, worker, and instance closure; they need no edit.
  - `poc.39` needs the same exact 23-path generation closure, with identity
    literals removed from the common PowerShell, Node gate, and Node worker.
- Conflicting or duplicated authorities:
  - `install-codedb-provider.ps1` independently defaults and pins
    `0.3.0-preview.4`, rejecting a caller-supplied successor version.
  - `test-codedb-provider-installer.ps1` encodes the same duplicate authority.
- Uncertainty and deferred evidence: implementation, local L0, successor
  artifact, external cleanup, Unity, and external acceptance have not run.

## Route Recommendation

- Recommended disposition: `REFACTOR` continuation with the exact two-path
  allowlist expansion.
- Coherent target boundary: canonical payload tuple -> immutable generation
  projection -> PowerShell/Node loaders -> caller-supplied Provider Package
  version validation -> Package-boundary/materializer/provider tests ->
  successor artifact.
- Exact expansion:
  - `com.rice.ai-codedb/Tools~/install-codedb-provider.ps1`
  - `com.rice.ai-codedb/Tests~/test-codedb-provider-installer.ps1`
- Rejected patch-only alternatives:
  - changing `35` to `38` in protected `poc.38`;
  - replacing Provider `preview.4` literals with `preview.5` literals;
  - weakening instance identity validation;
  - deleting external provisioning instances to hide the Package defect.

## Human Decision

- Disposition: `REFACTOR`
- Authorized envelope or next task: continue this same frozen task with
  candidate `0.3.0-preview.5 / poc.39 / sequence 39`, the original allowlist,
  and the exact two Provider-installer paths above. The installer must remove
  its second Package-version authority rather than replace the old literal
  with a new candidate literal.

## Handoff

- Current task: `cdb-v0.3-p0-s18-package-identity-authority-refactor`
- Current status: `REFACTOR_AUTHORIZED / IMPLEMENTATION_PENDING`
- Next notification: UnityCodeDB v0.3 Coder
- Next action: implement the frozen authority route and bounded evidence plan.
- Human decision or authorization required: later Verifier, commit, export,
  external cleanup/retry, and publication.
