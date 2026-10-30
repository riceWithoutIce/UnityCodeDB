# Unity validation project index

Updated: 2026-10-30. Owner: current parent / organization task.

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
| `.artifacts/unity-projects/current-lifecycle/` | Retained S38 action lifecycle evidence, with periodic-observation warning; no longer the current Ready UX test target. | Exact `d856a8f` first Install/independent Ready, human reopen smoke, logical Uninstall, same-version new-instance Install and independent Ready are historical PASS. Stable idle UX/performance remains open. Test8 is a separate observation baseline and does not replace unrun lifecycle/release gates. Cleanup remains PENDING. |
| `<external-acceptance-root>/CodedbTest_0` and `CodedbTest_1` | Historical independent consumers; compact archive candidates, originals retained. | Current Package references are `c07bb59` and `c848049`. No Library remains. Prior S39 preparation text is historical, not a pending instruction to switch the current references. |
| `<external-acceptance-root>/CodedbTest_2` | Retained historical blocked evidence; compact archive verified, generated Library children cleaned. | Reference `09d345d-v03-quarantine-admission`. Four unresolved child-admission histories stay open. AIWork, config, assets, Library/CodeDB, Logs and referenced Package retained; no history repair or whole-project deletion. |
| `<external-acceptance-root>/CodedbTest_3` through `CodedbTest_6` | Historical functional-validation consumers; compact archives verified, originals retained, selected generated Library children cleaned. | References respectively `d84b5ca-v03-child-close`, `8f8971d-v03-watch-handoff`, `poc45-v03-quarantine-admission`, `5218091-cleanup-observer`. Source, per-project evidence, Logs/Library-CodeDB diagnostics and exact local Package bytes are preserved independently. Only the approved exact cache children were removed. |
| `<external-acceptance-root>/CodedbTest_7` | Retain complete migration/removal BLOCKED repro in place. | Reference `9f76fd1-poc52-integration-control`, with retained old selection/history. No reset, reference switch or cache cleanup in this batch. Test8 clean-project observations do not close this gate. |
| `<external-acceptance-root>/CodedbTest_8` | Current human Ready UX observation baseline; retain complete project and cache. | Reference `3beb2c7-poc52-ready-observation`. Human observed Ready, Manager reopen and Play-to-Edit, but long Unconfirmed/Starting waits and idle readiness changes remain unresolved. This is evidence of the old implementation, not acceptance of the frozen redesign. |

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

Current external acceptance root is `G:/RiceProgram/Test/CodedbTest`.
The 2026-10-30 housekeeping task keeps Test8 active and Test7 as the complete
historical migration repro, with verified compact evidence for Test0-Test6 and
approved cache cleanup completed for Test2-Test6.
S33/S35/S38 still occupy older retained storage; this update makes no claim that
the retention target has already been achieved. They require their own evidence
disposition before removal. Review milestone: environment cleanup execution,
then each corresponding lifecycle/migration gate; owner remains the current parent.
See [environment preparation](tasks/shared/cdb-environment-preparation-20261030/TASK.md).
The separately approved housekeeping batch also records three local commits and
Project 7 synchronization. This index update does not authorize any additional
project deletion, Package reference change, Unity/runtime command, push or Project write.
