# Unity validation project index

Updated: 2026-10-19. Owner: current parent / organization task.

This is a route/disposition index, not an execution instruction or a replacement
for source, package, runtime or acceptance records. All roots below are relative
to the repository. Three older projects were permanently deleted with explicit
user authorization on 2026-10-19; their necessary evidence remains protected.

| Root | Role / disposition | Evidence and next review |
| --- | --- | --- |
| `UnityValidationProject/` | Fixed tracked development EditMode project. Retain in place. | Existing local configuration remains unchanged by organization. Its old package reference is not a new test failure. |
| `UnityFreshInstallValidationProject/` | DELETED / evidence archived. | Initial preparation produced an unbound/ambiguous candidate; no complete lifecycle PASS. Independent evidence and exact limits in organization result. |
| `UnityFreshInstallValidationProjectS29/` | DELETED / ARCHIVED / PARTIAL / NOT_RELEASE_ACCEPTED. | Historical first Install and logical uninstall passed; latest full lifecycle unfinished. Unknown process-evidence limits remain. |
| `UnityFreshLifecycleValidationProjectS30/` | DELETED / historical partial lifecycle / evidence archived. | First Install passed; logical uninstall passed with Manager closure blocked; subsequent reinstall failed before observed dispatch. Later package smoke is separate from real reinstall acceptance. |
| `UnityFreshLifecycleValidationProjectS33/` | Latest complete historical failure sample; retain in place temporarily. | First Install/reopen/logical uninstall passed; reinstall failed. Review when successor completes corresponding lifecycle or replaces the sample. Owner: current parent / S34. |
| `.artifacts/unity-projects/s35/` | ARCHIVED / BLOCKED / PARTIAL. First Install/independent Ready and Uninstall passed; the post-delivery same-version Install remains blocked by retained malformed history. | Human compile/focused-test/UI smoke passed against `d856a8f`; Manager had only Overview, so tab switching was N/A. The one authorized Install attempt on 2026-10-20 returned `PREFLIGHT / INSTANCE_CONVERGENCE_FAILED`, `mutated_scopes=[]`. Keep the project physically in place until the artifact-retention review decides whether its full runtime tree has unique value. |

- [Organization result, preserved evidence and completed deletion](tasks/shared/unity-validation-project-organization/RESULT.md).
- [S35 clean-project lifecycle task and next human step](tasks/v0.3.0/cdb-v0.3-p0-s35-clean-project-lifecycle-acceptance/TASK.md).
- [Organization task and approved retention policy](tasks/shared/unity-validation-project-organization/TASK.md).
- [S29 archive decision](tasks/v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/ARCHIVE-DECISION-2026-10-15.md).
- [S30 logical uninstall result](tasks/v0.3.0/cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/UNINSTALL-ACCEPTANCE-RESULT-2026-10-17.md).
- [S30 subsequent reinstall result](tasks/v0.3.0/cdb-v0.3-p0-s30-current-version-lifecycle-acceptance/REINSTALL-ACCEPTANCE-RESULT-2026-10-17.md).
- [S34 delivery and S33 human observation](tasks/v0.3.0/cdb-v0.3-p0-s34-supervisor-history-retention-terminal-closure/HUMAN-RESULT.md).

Default retention is one fixed development project, one active acceptance
project and at most one complete historical sample. Additional full retention
needs a concrete purpose, owner and review milestone. Deletion does not close
old issues or authorize stopping processes, removing shared state or deleting
protected evidence/packages. CleanupMono shutdown observation stays deferred.
