# S38 first real Install result - 2026-10-20

Status: `FIRST_INSTALL_PASS / INDEPENDENT_READY_OBSERVED / HUMAN_SMOKE_PENDING`.

## Human observation

The user authorized the proposed single first Install, reports that it
succeeded, and supplied a Manager screenshot (attachment ending
`c7f38508-c34c-4cde-82a2-0b2dc6c1bac5.png`). It shows `current-lifecycle /
Ready`, Package `v0.3.0-preview.5`, Last activity `Install CodeDB / Ready`,
duration 16.08 s, and `Uninstall CodeDB from Project`. Diagnostics show the
selected `poc.43` instance and background cleanup `In progress`.

## Bounded read-only evidence

- The selected instance manifest identifies originating Install action
  `b4c155cae8cd455d96a90d97a420cc01` and originating operation
  `9094cd98c5ec4e15b99a2cb9cfcbc881`.
- The original machine-local action manifest records `project-install-v1`
  against this S38 project and the exact S37 `d856a8f` Package. Its action,
  project and Package keys match the terminal receipt. The receipt records
  confirmed project mutation with human confirmation and backend admission.
- The original writer is terminal for that action: exit 0, no timeout,
  overflow or incomplete output drain, empty stderr. Its structured result is
  `INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED`, cleanup `PENDING`.
  Terminal SHA-256:
  `7bff10ccbe2fc9d4766d319d9eab8c65d3b14bf697186afc333e0bd1cbe57020`.
- Selected instance `2fec1db083b74b2c9d371e1bce558736` is `READY`,
  Package `0.3.0-preview.5`, generation `poc.43`. The selected manifest hash
  matches the current pointer:
  `b941b2df8a5e741a56ec1693d5a3d609655dd57724986c604e64233353959f98`.
- Activation publication is `COMMITTED` for the same selected instance and
  epoch `7fb0873abd2547ba86a3c4ea984bd1db`. An existing independent
  Supervisor observation at `2026-10-20T04:38:24.242Z` records `core_ready /
  COORDINATOR_OPERATIONAL` for that same project, instance and epoch. No new
  status RPC or probe was issued by the parent.
- Desired state was `INSTALLED` with cleanup `PENDING` at the read-only sample.
  A later Supervisor sample still showed `core_ready` operational observation
  while its overall state was `maintenance` for a running automatic
  `materialize:Probe`. These point-in-time observations do not prove all
  maintenance or physical cleanup complete.
- Both Package configuration hashes still match `SETUP-RESULT.md`. The exact
  current-action index had no active action file at the checkpoint; no manual
  release or cleanup was performed.

This closes first Install and independent Ready for S38. It does not establish
normal reopen behavior, logical Uninstall or same-version reinstall. The parent
did not launch Unity, run product commands, stop processes, edit source, retry
Install or alter runtime/configuration.

## Next human checkpoint

Close and reopen Manager, visit the visible tabs, then close Unity normally and
reopen the same S38 project. Report whether Manager remains Ready, whether the
tabs behave normally, and any Console errors or shutdown blocking. This is a
normal UI/lifecycle observation. Do not click Uninstall or repeat Install yet;
the logical Uninstall action remains a separate gate.
