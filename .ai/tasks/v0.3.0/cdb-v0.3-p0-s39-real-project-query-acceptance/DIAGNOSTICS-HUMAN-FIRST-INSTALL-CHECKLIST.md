# CodedbTest_1 — human compilation and first Install

Active project: CodedbTest_1, Unity 2022.3.62f3.
Delivered source: `237c72d9980114b99887fb8e805658447dd8d4fd`.
Expected dependency: `file:../../Packages/237c72d/com.rice.ai-codedb`.
Expected displayed Package/generation: `0.3.0-preview.5` / `poc.43`.
Prerequisite: DIAGNOSTICS-DELIVERY-RESULT.md records exact delivery/preparation PASS.
Older CodedbTest_0 checklists and client handoffs remain historical.

1. Open CodedbTest_1 and wait for normal Package resolution, import and script
   compilation. Unity owns package-lock and `.meta` generation.
2. Check Console. On a compilation/import error, stop and report the first full
   error with file/line; preserve the current state.
3. If compilation is clean, open `Tools > Rice AI > Codedb > Manager` and use
   the normal first `Install` action once. Do not use Reinstall/Uninstall.
   If Install is unavailable or the UI unexpectedly indicates an existing
   installation, stop and report the visible status/reason before acting.
4. Wait for that operation to finish; report compile status, Install result and
   Manager status/reason. A screenshot is useful. Stop at failure or Needs
   attention; do not retry Install or change registration/environment.
5. After Ready, return the human observation here before opening a target-root
   Codex acceptance chat. The actual-host attempt and new identity will receive
   a fresh bounded handoff; neither old client attempt is a retry grant.

Keep CodedbTest_0 and its original Package/runtime unchanged. Manager Ready is
a human UI observation, not proof of tool exposure, a status/query response or
MCP response identity. Bootstrap logs may be written during normal operations;
their disk-selection identity also does not substitute for response identity.
