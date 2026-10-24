# Unity validation project index

Updated: 2026-10-20. Owner: current parent / organization task.

This is a route/disposition index, not an execution instruction or a replacement
for source, package, runtime or acceptance records. Roots below are relative
to the repository unless explicitly marked external. Three older projects were permanently deleted with explicit
user authorization on 2026-10-19; their necessary evidence remains protected.

| Root | Role / disposition | Evidence and next review |
| --- | --- | --- |
| `UnityValidationProject/` | Fixed tracked development EditMode project. Retain in place. | Existing local configuration remains unchanged by organization. Its old package reference is not a new test failure. |
| `UnityFreshInstallValidationProject/` | DELETED / evidence archived. | Initial preparation produced an unbound/ambiguous candidate; no complete lifecycle PASS. Independent evidence and exact limits in organization result. |
| `UnityFreshInstallValidationProjectS29/` | DELETED / ARCHIVED / PARTIAL / NOT_RELEASE_ACCEPTED. | Historical first Install and logical uninstall passed; latest full lifecycle unfinished. Unknown process-evidence limits remain. |
| `UnityFreshLifecycleValidationProjectS30/` | DELETED / historical partial lifecycle / evidence archived. | First Install passed; logical uninstall passed with Manager closure blocked; subsequent reinstall failed before observed dispatch. Later package smoke is separate from real reinstall acceptance. |
| `UnityFreshLifecycleValidationProjectS33/` | Historical failed-reinstall sample; evidence-first retention review due, retain pending disposition. | First Install/reopen/logical uninstall passed; reinstall failed. S38 now supplies a successful successor lifecycle, so review which S33 raw failure evidence is uniquely required before any full-project removal. Owner: current parent / S34. |
| `.artifacts/unity-projects/s35/` | ARCHIVED / BLOCKED / PARTIAL; evidence-first retention review due, retain pending disposition. | The authorized post-delivery Install was blocked by retained malformed history (`PREFLIGHT / INSTANCE_CONVERGENCE_FAILED`, `mutated_scopes=[]`). S38 success does not rewrite that failure. Assess unique failure evidence before any full-runtime removal. |
| `.artifacts/unity-projects/current-lifecycle/` | S38 action lifecycle PASS with periodic-observation warning; active acceptance project. | Exact `d856a8f` Package; first Install/independent Ready, human reopen smoke, logical Uninstall, same-version Install of a new instance and independent Ready passed. User reports heavier recurring checks after reinstall; stable idle UX/performance remains open. Cleanup PENDING; see S38 periodic observation result. |
| `<external-acceptance-root>/CodedbTest_0` (outside repository) | S39 selected independent non-Git consumer; preparation in progress. | User-created Unity 2022.3.62f3 project. Exact d856a8f ZIP independently copied/extracted to sibling `Packages/d856a8f`; all 623 files verified. Await normal Editor close before dependency setup. S38 remains retained until this replacement is accepted; no deletion authorized. See S39 TASK.md and RESULT.md. |

- [Organization result, preserved evidence and completed deletion](tasks/shared/unity-validation-project-organization/RESULT.md).
- [S35 clean-project lifecycle task and next human step](tasks/v0.3.0/cdb-v0.3-p0-s35-clean-project-lifecycle-acceptance/TASK.md).
- [S38 current-version lifecycle task and periodic observation result](tasks/v0.3.0/cdb-v0.3-p0-s38-current-version-lifecycle-acceptance/PERIODIC-OBSERVATION-RESULT.md).
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
