# S31-A rebaseline Verifier acceptance

## Decision

The current active S31 source snapshot is accepted as the attributable
rebaseline for this continuation. The snapshot remains the basis for the
recorded focused fixture and Editor evidence.

## Accepted evidence

- Eight allowlisted source/test files match the active S31 checkout and the
  repo-local rebaseline snapshot.
- The production `RetainedDispositionOnly` fixture generation is recorded as
  passing 47 checks.
- The focused Editor evidence is `total=1, passed=1, failed=0, skipped=0`.

## Deferred follow-ups

- Align the `rerun` evidence filename with the actual test filter/name.
- Preserve an independent generator stdout/log artifact for the 47-case
  production fixture result.

These follow-ups do not invalidate the fresh focused PASS and are deferred
without expanding the current repair scope.

## Gate status

S31-A remains `PARTIAL / NOT_ACCEPTED`. Domain Reload/reopen, two-window
admission, terminal UI restoration, startup/reconnect fencing, and
Install/Remove/Repair Editor regressions remain `UNRUN`. No Verifier delivery,
commit, package export, reference switch, or real lifecycle operation is
authorized by this record.
