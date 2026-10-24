# S39 fresh project: first Install reached READY

Date: 2026-10-21. Status: HUMAN_FIRST_INSTALL_READY /
REGISTRATION_STATIC_MATCH / REAL_CLIENT_STATUS_AND_QUERY_PENDING.

The human reported no compile errors after Package import. The supplied initial
Manager screenshot showed Not installed, no project integration and Install
CodeDB available. After the agreed single human Install, the next screenshot
shows Ready, CURRENT host payload and poc.44 current instance/host generation.
It displays Install duration 19.44 s; this is UI activity evidence, not a
controlled performance result. The separate Unconfirmed issue is not evaluated.

Read-only disk checks confirm:

- Target: `<test-projects>/CodedbTest_2`.
- Registration: `codedb-codedbtest-2`; command `node`; startup timeout 120 s.
- Generated cwd is an absolute path equal to this actual project root, with
  slash normalization. No manual config edit was used to achieve this state.
- Args remain `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]`.
- Manifest/Unity-resolved lock both reference
  `file:../../Packages/c848049-codedbtest2/com.rice.ai-codedb`.
- Package 0.3.0-preview.5; selected generation poc.44; instance state READY.
- project_identity:
  `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`.
- instance_id: `fe3b257859f34023a9e290db3b2ad457`.
- activation_epoch: `5bed173a875e461c981da8b7829a897b`.
- Activation publication phase COMMITTED, bound to the same selection.
- runtime contract:
  `ebf044f122f8fe878682caf5dee8ba8adb71068ea8bd8d24b5d720cee591acd5`.
- Generation manifest:
  `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.

Config SHA-256:
`2d288afd9490ad2f51560f5a62658f12d2bb456326980e919b894035b3f0c2fd`.
Selected pointer SHA-256:
`56ec118b90ff8110940bb2453dac7c0866a550bde4197ec820b785729450078b`.
Instance manifest SHA-256 matches its pointer declaration:
`2b2ccab8660a2f0944c666335d42235a40a441bb2bcb9a2d06728f856df6a9d2`.
The activation epoch comes from pointer/activation authority; instance.json does
not declare that field. Its absence is not a newly imposed schema failure.

The current Assets scan found only Scenes/SampleScene.unity and no C#/Shader/HLSL
test sample. Do not invent a marker hit, query a different project or treat an
empty sample as a retrieval regression. First arrange the new real-client
tool/status check in CODEDBTEST2-CLIENT-STARTUP-TASK.md, then agree a representative
bounded sample and actual hit query. No sample file was added in this observation.

Disk READY and correct registration are not proof that Codex loaded this server,
nor proof of a successful MCP status/query or response-side identity. Current
getStatusText exposes Package version, selected generation and generation
manifest; it does not expose all pointer identity fields. Preserve actual
response fields and mark missing ones as not provided instead of fabricating
them from local files or adding protocol requirements during acceptance.

All development-session checks here were read-only. CodeDB calls=0, no service
manually launched/reconnected/retried, no consumer config/runtime file changed.
Earlier acceptance attempts remain closed; CodedbTest_1 migration stays deferred.
