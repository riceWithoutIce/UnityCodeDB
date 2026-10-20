# Diagnostics delivery preparation result — 2026-10-20

Status: LOCAL_CANDIDATE_CLOSURE_PASS / SAME_GENERATION_HANDOFF_NOT_ADMITTED /
FRESH_INSTALL_FIXTURE_PASS / NOT_DELIVERED / REAL_CLIENT_QUERY_BLOCKED.

## Scope and candidate

This continuation prepares repository-local evidence only. No commit, formal
export, external project/package write, Install, Unity, Provider, Supervisor,
real MCP connection, trace or process inventory/control was performed.

Base: `c07bb5903b5b3fcda7d97f5238c2915e3c566cf8`.
Candidate: `.artifacts/tests/s39-diagnostics-delivery/r-e9f859cd/candidate/com.rice.ai-codedb/`.
Preparation receipts: `preparation.json`, `candidate-diff.json` and `owner.json`
under that run root. The task-local `prepare-diagnostics-delivery.ps1` reads a
Git archive of the base, overlays only this change, and uses the canonical
release-closure test writer function bodies to regenerate candidate metadata.
This local review copy is not a formally exported delivery.

Exactly six Package paths differ from the base:

| Package-relative path | Change |
| --- | --- |
| `Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs` | Termination diagnostics |
| `Tools~/probe-codedb-mcp-availability.mjs` | Bounded child stderr and exit attribution |
| `Tests~/test-codedb-bootstrap-diagnostics.mjs` | Isolated diagnostics verification |
| `Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md` | New diagnostics subsection only |
| `Payload~/payload-manifest.json` | Canonical wrapper/runtime-contract closure |
| `Tests/Editor/OwnerIdentityV2Status.json` | Corresponding runtime-contract fixture |

Unrelated dirty worktree changes, including poc.42/poc.43 state, were preserved.
The candidate's immutable generation manifest and host-current bytes match the
base. No existing activation records or validation rules were relaxed.

## Verification

- Candidate release closure: all 60 declared bytes verified; materializer
  admission and native build/source/binary binding PASS.
- Candidate's own diagnostics harness: all 15 synthetic scenarios PASS.
  Evidence: `.artifacts/tests/s39-bootstrap-diagnostics/r-11338940-3655-4fd4-85ac-99362069c1ee/result.json`.
- Candidate Package boundary `-PathProvenanceOnly` and harness syntax PASS.
- Handoff proof: `.artifacts/tests/s39-diagnostics-delivery/r-e9f859cd/handoff-f8d785fb/result.json`.
  The earlier `handoff/result.json` remains retained as the initial proof.
- Git index was empty at preparation completion. No files were staged.

The harness now accepts optional `--repository-root` for a candidate extracted
inside an enclosing checkout. It validates containment and reparse ancestry;
the source default and production files are unchanged by this portability edit.
Its current SHA-256 is
`9c0f991640f683b30c9dc0e69940c37fffebeb5d4874cc5032aaca1354af7531`.
The earlier source-result hash remains a historical snapshot.

## Handoff finding and consequence

The proof imports production reader/publisher function bodies without running
their script main. Existing deterministic test seams replace prerequisites and
candidate verification; no real process observation or Provider is permitted.

1. Baseline Package admits its synthetic committed installation.
2. Candidate Package refuses that installation's old wrapper: `Selected stable
   wrapper does not match the Package-declared runtime identity.`
3. Replacing only the fixture wrapper allows selected-instance reading with
   the same instance/epoch, but activation reading refuses: `activation record
   does not match its trusted contract or project context.`
4. The original fixture pointer, activation and operation records remain
   byte-identical. The old runtime contract is not the new Package contract.
5. A separate fresh fixture installed through the candidate's existing Install
   publisher commits; both selected-instance and activation readers admit it.

The blocking check is the exact `runtime_contract_sha256` binding in
`Assert-InstanceActivationDocumentContext` in `Tools~/codedb-instance-engine.ps1`.
Selected-instance and Supervisor wrapper checks also derive expected wrapper
bytes from the Package. The prior tools-only delivery did not change these
payload bytes; its handoff procedure cannot be reused for this change.

| Candidate authority | SHA-256 |
| --- | --- |
| wrapper | `a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e` |
| probe | `21983ad0792eab4bb03cf5685e12758cbf719914795071a2f8cdf957ce8966a4` |
| runtime contract/payload manifest | `750f54d6bd187b51a436e28002ea2099b9ce0a21b9f9fe6543ecc4197269b84a` |
| baseline runtime contract | `69d731882c730c9ad75af8c5385d5f36fb62d48067749a22e5c224cdbd55559a` |
| unchanged generation manifest | `55b042b1d6ddf66b45d167765a8f345a38478e9775b06973b8dfa7a88c8a4bb5` |
| unchanged host-current | `ef73f381ffc3f5a611b1712edaf91958cacb6dc304eec4e9d3d96495403619e1` |

## User decision

Recommend retaining CodedbTest_0 unchanged and using a new CodedbTest_1 for a
normal first Install after exact authorized delivery. The proposed project
directory was absent during this preparation; no project was created.

A new project is recommended to preserve evidence, not an absolute product
requirement. Reusing CodedbTest_0 would require separately aligned supported
uninstall/fresh-install work and would change its installation identity.
Installed-state migration support is outside this logging change. Do not
rewrite old activation authority or weaken its validation.

These are isolated compatibility facts, not real Install/Ready, root-cause,
response-identity, query, performance, upgrade or release acceptance. See
`DIAGNOSTICS-DELIVERY-PLAN.md` for the concrete proposed authorization boundary.
