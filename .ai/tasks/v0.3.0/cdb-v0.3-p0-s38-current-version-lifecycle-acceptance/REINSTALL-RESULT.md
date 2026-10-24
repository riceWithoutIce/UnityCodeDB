# S38 same-version reinstall result - 2026-10-20

Status: `CURRENT_VERSION_LIFECYCLE_PASS / PERIODIC_OBSERVATION_WARNING / CLEANUP_PENDING`.

## Human observation

The user reports the authorized single same-version Install succeeded. The
Manager screenshot (attachment ending `78748058-4aa5-45af-9d05-cfebffdf59d4.png`)
shows `current-lifecycle / Ready`, Package `v0.3.0-preview.5`, Last activity
`Install CodeDB / Ready` with duration 33.08 s, and the Uninstall entry.
Diagnostics identify the new `poc.43` instance and show background cleanup
`In progress`. The user has not separately reported a post-reinstall Console
check or another Manager/Unity reopen smoke.

## Attributable result

- The selected instance identifies originating action
  `db78f2b4b52244059450093058a87667` and operation
  `867119ecbc174159b53a7b0b1a817859`. The action manifest binds
  `project-install-v1` to this S38 project and the unchanged S37 `d856a8f`
  Package.
- The original action terminal is terminal for that action, exit 0, with no
  timeout, output overflow or incomplete drain and empty stderr. Its
  structured result is `INSTALL / INSTALLED / COMPLETE / INSTANCE_ACTIVATED`,
  cleanup `PENDING`. Terminal SHA-256:
  `de54464ccd2b8bfdc0415df341735a61f5085d866d699780182a8ce1e4b5f0c4`.
- The selected instance `fc7f8014b60b4b359f4582d06cdba2dd` is `READY`,
  Package `0.3.0-preview.5`, generation `poc.43`. It differs from the first
  Install instance `2fec1db083b74b2c9d371e1bce558736`. The pointer's
  instance manifest hash matches the selected file:
  `b448c2c6a2df05a48fc2e58af249a05a491e3116fd1eaf816999643f5f47f453`.
- Activation and operation publication are `COMMITTED` for the new instance
  and epoch `c76f2e0631834a158b996b2c5d1ea94e`. Desired state is
  `INSTALLED`; the CodeDB-owned project MCP table is active again.
- An existing independent Supervisor observation at
  `2026-10-20T07:14:48.287Z` is `core_ready / COORDINATOR_OPERATIONAL`
  for the same project, new instance and epoch. The latest sampled maintenance
  operation was completed. No new status RPC or probe was issued by the parent.
- Both Package configuration hashes still match `SETUP-RESULT.md`. The
  project Manager index holds resolved markers for the first Install, logical
  Uninstall and second Install, with no current-action marker at this sample.

The attributable S38 sequence passes: first Install and independent Ready,
human installed-state reopen smoke, logical Uninstall, then same-version
Install of a new instance and independent Ready. This is current-version
Unity-project lifecycle evidence for the exact delivered Package. It does not
establish physical cleanup completion, post-reinstall reopen smoke,
cross-version migration, device behavior or release acceptance. S35's
historical blocked result remains unchanged.

The subsequent human periodic-check observation is recorded separately in
`PERIODIC-OBSERVATION-RESULT.md`; this action-level PASS does not establish
stable idle UX or performance equivalence to the first installation.

The S33 and S35 full-project retention review is now due under the project
organization rule. Their failure records and any unique reproduction evidence
must be assessed before any physical removal; this task grants no deletion.
No Unity automation, product command, process control, retry, source edit,
commit or push was performed by the parent.
