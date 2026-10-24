# S39 primary source integration result

Date: 2026-10-21. Status: PRIMARY_SOURCE_INTEGRATION_PASS /
NOT_COMMITTED / NOT_RELEASE_ACCEPTED.

## Authorization and executed scope

The user replied `同意` to the concrete 72-path source-integration proposal,
including disposition of the local poc.42 selection/coordinator and missing
poc.43 files. Execution used `apply-source-integration.py` with the frozen
artifact proposal. Primary HEAD remains
`237c72d9980114b99887fb8e805658447dd8d4fd`; accepted source remains
`c848049d90fbdf618905be25225580642d98d987`.

Applied exactly 72 Package paths:

- 41 accepted S39 delta paths, with the integration/reinstall contract merged
  to preserve local clarifications;
- 30 missing tracked poc.43 predecessor files restored from the accepted commit;
- one poc.42 coordinator restored to the immutable version declared by its
  generation manifest. Its later repair remains present in poc.43 and poc.44.

The selected Package payload now uses the accepted poc.44 metadata pair and
coupled status fixture. Local contract explanations and the accepted cwd
derivation amendment are both retained. No primary file was deleted.

All recorded input hashes and missing states were checked before writes.
Prepared file hashes and retained preimages matched the approved proposal.
Original bytes remain in
`.artifacts/maintenance/s39-source-integration-proposal/preimage/`;
previously missing files are recorded with null preimage hashes.

## Verification

| Check | Result |
| --- | --- |
| Approved overlay | 72/72 actual file hashes match the prepared proposal. |
| Selected payload | 62/62 declared file hashes match the actual source files. |
| Generation file closure | poc.42, poc.43 and poc.44 files match their generation manifests. |
| Immutable predecessors | All 447 predecessor files equal accepted Git bytes. |
| Selection bindings | poc.44 pointer/manifest and status fixture generation/runtime-contract bindings match. |
| Local document preservation | First-install and instance-manifest clarifications plus the cwd amendment remain; no merge conflict markers. |
| Protected Package state | Tracked and nonignored untracked Package inputs outside the allowlist retain their original hashes and path inventory. |
| Git state | HEAD and Git index unchanged; no staging or commit. |
| Diff format | Focused changed text-file checks passed. |

Evidence:

- `.artifacts/maintenance/s39-source-integration-proposal/proposal.json`
- `.artifacts/maintenance/s39-source-integration-proposal/input-package-sha256.json`
- `.artifacts/maintenance/s39-source-integration-execution/writes.jsonl`
- `.artifacts/maintenance/s39-source-integration-execution/result.json`

These are bounded source-integration/static checks. Previously passed unchanged
S39 tests were not rerun. No independent Verifier, Unity, MCP, native executable
admission, new Package export, consumer switch, process operation, cleanup,
push or publication occurred.

## Retained local changes and acceptance boundary

The combined primary checkout is not byte-identical to the delivered accepted
candidate. It intentionally retains the merged integration contract, four
other locally modified documentation files and these two existing implementation
changes:

- `com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs`
- `com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1`

Their bytes were preserved. Their acceptance/ownership was not decided by this
integration. Local `package.json` EOL bytes also remain, with unchanged parsed
JSON content. No broad normalization or historical evidence replacement was
performed. Protected workflow/roadmap documents were not edited by execution;
their earlier source-integration-pending checkpoint is superseded by this
attributable result and the current task records.

The original ZIP and CodedbTest_2 functional acceptance remain attributable to
the exact c848049 candidate. They are not automatically acceptance of this
combined primary tree. The S39 startup/query gate remains closed; no repeat
client call is needed.

The next planning objective is the candidate evidence matrix, including the
disposition of the two retained local implementation deltas before choosing a
release candidate. Source integration is complete; no new implementation,
delivery or deferred issue is activated by this result.
