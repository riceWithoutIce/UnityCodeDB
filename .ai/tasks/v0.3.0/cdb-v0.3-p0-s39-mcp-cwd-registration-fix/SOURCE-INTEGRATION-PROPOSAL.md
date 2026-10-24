# S39 primary source integration proposal

Date: 2026-10-21. Current status: APPROVED / EXECUTED /
PRIMARY_SOURCE_INTEGRATION_PASS.

The user approved the exact proposal below. All 72 paths were applied and
verified; see [SOURCE-INTEGRATION-RESULT.md](SOURCE-INTEGRATION-RESULT.md).
The proposal text remains the frozen execution scope, not a pending grant.

## Proposed result

Integrate the accepted S39 Package delta from
`c848049d90fbdf618905be25225580642d98d987` into the primary checkout at
`237c72d9980114b99887fb8e805658447dd8d4fd`, preserving unrelated local work.
The concrete proposed files and their current preimages are under
`.artifacts/maintenance/s39-source-integration-proposal/`.

This is source consolidation, not a new delivery candidate or release. The
existing exact ZIP and CodedbTest_2 acceptance remain unchanged and attributable
to their original source. External Unity projects are outside the write scope.

## Disposition of existing local changes

| Surface | Proposed disposition and evidence |
| --- | --- |
| Integration/reinstall contract | Three-way merge preserves local first-install/reinstall, prerequisite and instance-manifest clarifications, and adds the accepted cwd derivation/validation amendment. The prepared merge has no conflicts. |
| `Payload~/host-current.json` and `Payload~/payload-manifest.json` | Adopt the accepted poc.44 pair byte-for-byte. Local selection is poc.42; its 10 bootstrap transitions and 350 retired targets are subsets of the candidate's 12 and 410. There are no unique local entries in those inventories to discard. Keep the raw preimages for attribution. |
| `Tests/Editor/OwnerIdentityV2Status.json` | Adopt the accepted fixture with the poc.44 selection and runtime contract hash. Local semantic differences are the coupled generation/contract values; timestamp text variants parse to the same UTC instant. Do not independently edit its hashes. |
| Missing poc.43 generation | Restore all 30 files from the accepted commit, including original binary bytes. These are already tracked predecessor files, not a new implementation. |
| Local poc.42 coordinator | Preserve its current bytes as a preimage, then restore the accepted immutable poc.42 version. The local coordinator is byte-identical to accepted poc.43 and poc.44, so its later repair remains present in those generations. Its current poc.42 manifest declares the original coordinator hash and does not match the local file. Do not rewrite the old manifest to bless the replacement. |
| Remaining 37 S39 delta paths | Adopt accepted bytes; their local inputs match the original comparison's base/absence classification. The complete proposed overlay is recorded per path and hash. |
| Other local Package files and task records | Preserve exactly. No broad checkout reset, task-document replacement or cherry-pick is proposed. |

The resulting write envelope contains 72 paths: the accepted 41 Package paths
(one merged document), plus 30 missing poc.43 files and one poc.42 coordinator.
No source deletion is proposed. The full allowlist, missing-file preimages and
before/after hashes are in `proposal.json`; existing preimage bytes are retained
under `preimage/`, and proposed bytes under `candidate-delta/`.

## Historical ownership evidence

The 2026-10-11 S29 coordinator human-result record identifies the later
coordinator hash `928a58b3...` and the original `5a61242e...` separately.
The 2026-10-12 Manager action admission diagnosis already records the same
working-tree manifest/coordinator mismatch and explicitly distinguishes it
from the delivered Package. See:

- `../cdb-v0.3-p0-s29-fresh-project-integration-golden-path/COORDINATOR-READINESS-REPAIR-HUMAN-RESULT.md`
- `../cdb-v0.3-p0-s29-fresh-project-integration-golden-path/MANAGER-ACTION-ADMISSION-DIAGNOSIS-2026-10-12.md`

Commit `d127a45eafa62f04f25a4b578839e6056e46299a` subsequently put the repair in
poc.43 and restored the original poc.42 coordinator/manifest pair. This supports
the proposed immutable predecessor disposition. It does not establish why the
present local deletions/selection were made or authorize erasing them without
an explicit source-integration decision.

This is a known local source-state collision, not evidence of corruption in
CodedbTest_1 or a cause assigned to its observed MCP startup failure.

## Checks on the prepared result

The planning helper `prepare-source-integration-proposal.py` writes only its
new repository-local artifact directory. Its run completed with:

- all 62 selected payload entries matching their declared file hashes;
- file closure for poc.42, poc.43 and poc.44 matching their generation manifests;
- all 447 predecessor generation files equal to the accepted commit;
- no unique local transition/retired-target entry lost;
- merged contract retaining both local clarifications and the accepted cwd rule;
- primary tracked and nonignored untracked Package input bytes unchanged.

These are static checks of an artifact overlay, not a primary integration,
full test suite, native executable admission or Unity/runtime acceptance.
The already passed unchanged S39 tests were not rerun.

The proposed primary tree still differs from the accepted commit in the merged
contract, four other local documentation files, `Editor/AICodedbProcessRunner.cs`
and `Tools~/invoke-codedb-manager-action.ps1`. Those two local implementation
changes remain protected and are not reviewed or accepted by this task.
`package.json` also retains its local EOL bytes; its parsed JSON and normalized
text equal the accepted file. Do not export this combined primary tree as the
previously accepted exact Package or promote the old acceptance to that tree.

## Bounded execution proposed for approval

1. Recheck primary HEAD, the recorded Package input hashes and absence states,
   and the exact prepared 72-path overlay. Stop on drift or conflict.
2. Apply only those prepared paths, preserving existing preimages and all other
   local changes. Preserve raw immutable bytes rather than allowing checkout
   filters to change them. No generation regeneration is needed.
3. Verify the resulting 72 path hashes and the same affected static closure;
   confirm all out-of-scope Package inputs remain unchanged. Record the actual
   result separately from the accepted source's original evidence.
4. Stop. No staging, commit, merge commit, export, consumer reference switch,
   Unity action, MCP call, process operation, cleanup or publication is included.

Approval is needed for the named disposition of the existing local poc.42
selection/coordinator and poc.43 deletions. Earlier authorization to organize
the route and prepare a proposal did not authorize replacing these local
source states. The prepared files make that decision reviewable before writes.
