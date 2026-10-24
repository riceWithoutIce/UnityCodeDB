# CodedbTest_1 first Install observation — 2026-10-21

Status: HUMAN_INSTALL_READY_OBSERVED / DISK_BINDING_MATCH /
REAL_CLIENT_QUERY_NOT_EXECUTED. Source delivery: 237c72d9980114b99887fb8e805658447dd8d4fd.

The human returned a screenshot showing CodedbTest_1 Ready, Last activity
Install CodeDB / Ready (17.41 s), Package 0.3.0-preview.5, generation poc.43,
current instance and project MCP config OK. It is evidence of the human-run
Install/UI result; a separate explicit Console-clean report was not supplied.
No claim of a full compiler-log review is made.

Read-only project observation confirms:

| Field | Value |
| --- | --- |
| project_identity | sha256:df651cdb0a4933afe68d959f08b5a1f00648a2631f598f606c7d2f756b9ff89e |
| instance_id | d442deda8b914a7bad6af7dd79e2d50c |
| pointer activation_epoch | 5b1c035c0fd44ea095d045ab4f5c79ba |
| generation / version / instance state | poc.43 / 0.3.0-preview.5 / READY |
| pointer SHA-256 | 06a1afc91f9bea6a15b6d19130a166c5aa2c8926edd976ae36c61cbf7c37af1d |
| instance manifest SHA-256 | a329f604fa5c048026622f0e8736dfd6f732adf9009931023125a01b67ccceeb |
| installed wrapper SHA-256 | a54bbd3abaa2007597757b568877be8f86b1334e27c54fd186a3b1f3c853bb8e |
| activation runtime contract | 750f54d6bd187b51a436e28002ea2099b9ce0a21b9f9fe6543ecc4197269b84a |
| project MCP config SHA-256 | cc266892469cc172733cea857fd29eaf80c44c0c37f4fa1b2ad4987dc494038b |
| query sample SHA-256 | 0b606ee895088add24435eb628f6ebfb2e3af8facec3133b6eee96623ba3041b |

Manifest and Unity-generated lock both reference
`file:../../Packages/237c72d/com.rice.ai-codedb`. Project registration is
`codedb-codedbtest-1`, command node, cwd '.', original stable wrapper/root
arguments and startup_timeout_sec 120. The installed instance hash matches the
pointer; pointer text was unchanged before/after observation. The sample marker
remains line 5. User/global registration sources were not inspected.

The instance availability receipt reports AVAILABLE, status usable and search
callable at 2026-10-21T01:47:49.8806923Z, before pointer activation at
01:47:51.0972676Z. It is installation verification, not a target-root Codex
response. Missing activation_epoch/runtime-contract fields on instance.json
are not manufactured; those authority facts are read from pointer/activation.

## Bootstrap diagnostic baseline

One existing file was observed under project-relative
`AIWork/.runtime/codedb/diagnostics/bootstrap/`:
`60580-e1219fb5-feb2-4530-8d81-4688cd6805e3.json`.
SHA-256: `0078acec8b76a0551ad0de928bb58ccd3b91a6d4c3d97657fa0e4f29daf8d5c1`.

It records worker_exit at 2026-10-21T01:47:53.330Z, stage worker_created,
PID 60580/thread 1, Node 24.14.1, project-root startup cwd and expected disk
selection identity/epoch. LOCALAPPDATA present/absolute are true. Worker exit
and requested wrapper exit code are 0; error null. No independent process-exit
or protocol success is inferred. Its caller is not independently attributed.
This pre-existing record is not evidence from the upcoming actual-client chat.
The diagnostic feature has produced an on-disk record through normal use.

The development session made zero MCP calls and did not start Unity, Provider,
Supervisor, wrapper, probes, tracing or new chats. No external files/config or
processes were modified. Existing diagnostics remain untouched. Repository task
records alone were updated, without commit/push. Next: user creates a fresh
target-root chat and sends CLIENT-ATTEMPT-03-HANDOFF.md's instruction. Preparing
that instruction does not itself execute or authorize a background attempt.
