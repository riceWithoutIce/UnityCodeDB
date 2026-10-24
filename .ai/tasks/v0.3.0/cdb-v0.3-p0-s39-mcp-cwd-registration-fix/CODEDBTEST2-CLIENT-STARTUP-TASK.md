# CodedbTest_2: one bounded real-client startup/status observation

Run in a NEW Codex chat opened at `<test-projects>/CodedbTest_2`, after the human
first Install reached READY. This task text is for the user to deliver; it does
not authorize this development chat to create or message another chat.

## Scope and sequence

1. Record actual cwd and any system-provided attributable chat ID. Verify cwd
   is the intended Unity project root; do not manufacture an ID if unavailable.
2. Read only the project `.codex/config.toml` and selected pointer to identify
   this project. Registration must be `codedb-codedbtest-2`, cwd must equal this
   actual absolute project root, and relative wrapper/root argv must be retained.
   Pointer identity and generation must match the baseline below. Do not read
   global config or execute/import the wrapper for this check.
3. Observe the host's actual callable tools. Exact expected namespace:
   `mcp__codedb_codedbtest_2__*`. Record exposed tool names/count. If unavailable,
   stop immediately, report status calls=0 and no raw response; do not retry,
   reconnect, manually launch components or substitute another CodeDB service.
4. If the exact target `codedb_status` tool is exposed, call it with `{}` ONCE.
   Preserve its complete raw response, isError and any host-supplied failure.
   Do not issue any other CodeDB call, including text search, this phase.
5. Compare only fields the response actually provides against this Package,
   generation and generation-manifest baseline. Missing project/instance/epoch
   fields must be marked not provided, never filled with disk values. A usable
   status with matching exposed fields is startup/status evidence, not complete
   session identity or actual query acceptance. Stop after reporting this call.

No config/source/sample writes, Install/Repair/Uninstall, process stops, global
searches, diagnostics sweep or continuation of earlier Attempts are authorized.
No repeat of a failed status call. Normal host-owned startup is allowed; do not
replace it with shell/SDK/raw-stdio testing. Ordinary protocol lease effects are
distinct from manually launching or repairing a service.

## Expected local baseline

- Package: `0.3.0-preview.5`, selected generation `poc.44`.
- project_identity:
  `sha256:c49485bc88bd6e5cab2f8a45e04f3f5bd4dff15aaac2969cd7758bab976ff59c`.
- instance_id: `fe3b257859f34023a9e290db3b2ad457`.
- activation_epoch: `5bed173a875e461c981da8b7829a897b` (pointer authority).
- Generation manifest:
  `f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb`.
- Command `node`, timeout 120 s; args
  `["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]`.

Compare ordinary normalized path forms semantically; do not impose spelling,
case/slash/quote-style restrictions or require fields absent from this schema.
If local binding conflicts, stop before a call and report the actual conflict.

## Required result

Actual cwd/chat ID availability; project registration match; exact exposed tool
names/count; status call count (0 or 1); complete raw response or precise reason
none exists; actual response fields and missing fields; any identity conflict.
Keep tool exposure, status usability, full session identity and hit-query
acceptance as separate conclusions. Query calls must be 0 for this phase.
