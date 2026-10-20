# S39 first Install and Ready evidence

Date: 2026-10-20.
Status: `FIRST_INSTALL_READY_PASS / REAL_CLIENT_QUERY_PENDING`.

## Human observation

The user reports that Install in `CodedbTest_0` reached Ready. The attached
`codex-clipboard-60b4c5b1-6b16-46c3-a7a0-07ac1db5df08.png` shows project
`CodedbTest_0`, Package `0.3.0-preview.5`, Overview `CodeDB is ready`, and last
activity `Install CodeDB / Ready / 17.50 s`. The display explicitly describes
the Ready observation as cached. This is human UI evidence; the parent did not
perform another readiness probe. Earlier Ready feedback in the predecessor
chat was interrupted by service failures and did not require another Install.

## Original installation result

Read-only inspection correlated the Manager action receipt at
`<manager-actions-root>/28af60680747462d9ac437b1b9aeeebb/` with this project
and the external delivered Package. No runtime command was invoked.

- Action: `28af60680747462d9ac437b1b9aeeebb`.
- Stage: `594fb8ed53b70c8a328c10ce2a05eb05e42c866920fd131a7d2e88a3529cbe23`.
- Execution route: `project-install-v1`; terminal_for_action: `true`.
- Exit code: `0`; timed_out, output_overflow and output_drain_incomplete:
  all `false`; elapsed: `17499 ms`; stderr: empty.
- Completed: `2026-10-20T09:01:29.4482471Z`.
- Original stdout reports candidate initialize/tools/status/bounded-query
  success, `INSTALLED`, `CONFIGURED`, `MCP_AVAILABLE` current and product
  `READY`. These are Package-owned probe results, not real Codex evidence.
- Command result: action `INSTALL`, outcome `INSTALLED`, phase `COMPLETE`,
  reason `INSTANCE_ACTIVATED`; cleanup_state `PENDING`. The original retained
  watcher/draining messages remain part of the result. Cleanup is not claimed
  complete and no cleanup, retry or process termination was attempted.

Original receipt SHA-256 values, retained at their original location:

| File | SHA-256 |
| --- | --- |
| action.json | `0517725244bbedc265b554fd426a3823ccb7bf1d4ee64ecd25f60850aac33e0c` |
| 594fb8ed53b70c8a.admitted.json | `b5d8efa1dfd0873816cdffb4b0fc0acd0c7a4d80abc734809cedb89267368ff6` |
| 594fb8ed53b70c8a.claim.json | `42adcfdcdc794471c740f47ea3df67187a2c979189d3e37c86a199177ac7aa29` |
| 594fb8ed53b70c8a.terminal.json | `e77b2ba4158da14f19da8e7c5b8cc22d88b6563df209d2511c523bae2ab30212` |

## Selected installation and registration

- Project identity:
  `sha256:85d0f58fdebf7f4d5fb92ae80ba2a797a6f76f03a4443684deca2026f6f5bfc3`.
- Package identity:
  `sha256:1b5c1b8c06314235bd5858b62f811b6f8777f3b9bde0c5f4349b676eb4fb510c`.
- Instance: `2414c73c2fbb47f4b664c1bdbcad5969`, manifest state `READY`.
- Epoch: `4ad2120d1559487f8e54c015685496f6`.
- Generation: `poc.43`, Package `0.3.0-preview.5`.
- Instance manifest actual SHA-256 matches current pointer:
  `dd1244b1660a26b102867035cb85525d7e124b0c72ae0c55e18868eeab8b423e`.
- Current pointer and committed activation agree on identity, instance and epoch;
  activation and control operation both report `COMMITTED`. Control operation
  `4b97951dfa7a418599d5918c61fc685d` is distinct from originating instance
  operation `8514bf888330480795b72dd919500d4b`; identifiers are not conflated.
- `.codex/config.toml` registers `codedb-codedbtest-0`: command `node`, cwd `.`,
  args `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]`,
  startup timeout `120` seconds. Configuration SHA-256:
  `770d2319ae6fbfa0eb01cec1faf4870e2a96033453dee44637aef4f88a943502`.
- Manifest/lock references and hashes match the configured S39 baseline.
- Sample remains unique at `Assets/CodeDBAcceptance/S39QueryProbe.cs:5`, text
  `        public const string Marker = "CODEDB_S39_EXTERNAL_20261020";`, SHA-256
  `76442fb3d5d7c950f8836f152bfd273c9b9a00c06d1d287eba036dc6e5d23842`.

The selected pointer establishes disk identity only. The delivered status tool
does not print instance_id or activation_epoch. The acceptance chat must retain
that limitation and correlate any attributable client lease if available;
missing identity fields must not be fabricated or treated as direct proof.

## Handoff

First-install/Ready evidence passes. Real new-client tool exposure and the
single bounded query remain pending. Use CLIENT-HANDOFF.md from a human-created
chat at the external project root. S38, cleanup, performance and public release
gates retain their separate evidence boundaries.
