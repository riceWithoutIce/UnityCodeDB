# S33 same-version reinstall acceptance proposal

Date: 2026-10-19.
Status: PROPOSAL_PENDING_REAL_ACTION_GRANT / NOT_RUN.

Use the unchanged S32 Package reference already present in
UnityFreshLifecycleValidationProjectS33. The preceding logical Uninstall passed;
its cleanup remains pending and is recorded separately. This gate establishes
one fresh same-version Install after Uninstall. It does not repair source,
change Package references, perform physical cleanup, or address deferred log/
Manager-reopen UX follow-ups.

## One-attempt human action

After explicit approval, the human clicks `Install CodeDB` once and confirms
once in the open S33 Manager. Wait for the action to settle and report the final
Manager state, Last activity result, and Console errors/warnings. Do not click
again, close Unity during the action, delete retained state, or manually stop a
process. The parent performs only bounded read-only checks against the exact
action and selected instance afterward.

## Pass conditions

- Exact Install terminal is attributable to S33 and the accepted Package, with
  exit code 0 and command result `INSTALLED / COMPLETE` (or its current exact
  successful equivalent).
- A fresh selected instance is activated and independent readiness reaches
  Ready; desired state is INSTALLED.
- Manager shows Ready and the normal installed action surface after convergence.
- Cleanup, retained prior content and external process retirement remain
  separately reported; `CLEANUP_STATE=PENDING` alone does not fail Install.

## Stop conditions

Preserve the first evidence and stop if Install fails, is unknown, does not
converge, requires a new external prerequisite, or conflicts with prior
identity. No automatic retry, state deletion, manual cleanup, process kill,
historical recovery, source repair, new export or reference switch is included.

This proposal is not a grant. It expires after this one action/result; any
later Install or upgrade needs a new alignment.
