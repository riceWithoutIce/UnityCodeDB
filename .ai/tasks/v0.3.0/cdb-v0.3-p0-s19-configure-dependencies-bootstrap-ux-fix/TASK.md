# cdb-v0.3-p0-s19 Configure Dependencies Bootstrap and UX Fix

## Objective

Close the fresh-package Configure Dependencies dead end and keep operation
progress out of the Manager's full-width status row.

## Scope

- When the project has trustworthy prerequisite evidence but no selected
  current instance, skip the pre-deployment Supervisor Probe and enter the
  existing guarded instance deployment path.
- Keep the running operation presentation in the Last activity panel while
  leaving the Manager header stable.
- Update only the direct lifecycle and Manager UI tests for these contracts.

## Boundaries

- Do not broaden Provider, Package identity, generation, or MCP contracts.
- Do not bypass prerequisite, lease, Supervisor, or activation gates.
- Do not start, stop, or probe Unity, Unity MCP, or external business
  processes automatically.
- Preserve unrelated dirty worktree changes.

## Validation

- Static/source review and scoped diff check.
- C# EditMode and UnityValidationProject verification require a separate
  human-owned gate after the source snapshot is stable.
