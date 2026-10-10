# S29 post-install EditMode UI diagnosis

Date: 2026-10-09. Evidence: read-only source, current project records, authenticated action terminal, Unity Editor log, and human screenshots/report. No new backend command, Unity control, process stop, package switch, or source repair was performed.

## Installation outcome

Human-confirmed INSTALL `dc72675bc8e54b4daaf82592115f2448` has a complete terminal: exit 0, no timeout/overflow/drain-incomplete, terminal_for_action true. It reports INSTALLED, INSTANCE_ACTIVATED, all product layers CURRENT, PRODUCT_STATE READY, and cleanup PENDING. Selected instance `d620abbab0334a2d9c49e59888c1ef55`, generation poc.42, activation epoch `2f8b2a509a1e4086af4a4457e618d037`. The control operation reports INSTALL/COMMITTED with operation `048d631f6e6542bf8e1225f22b156530`. This proves the installation outcome; it does not establish ongoing UI/readiness or release acceptance.

## Confirmed findings

1. Incorrect Play wording in EditMode. Human reports no Play transitions; recent CODEDB_S12_EVIDENCE records play_transition_count 0. AICodedbManagerWindow.TryApplyCachedLifecycleStatus uses CreateCachedStatus in EditMode. Its shared AICodedbStatusSnapshot constructor nevertheless describes Ready as 'before Play mode' and diagnostics as resuming 'after Play mode'. A Play transition is not required for those strings to appear.
2. Missing operation progress. AICodedbActivityPanel.DrawRunningSummary renders a bar only when HasProgress is true. UpdateProgressLine accepts only PROVIDER_STAGE. The actual INSTALL terminal output contains no such stage. RunInstallCodeDBAsync also has no output observer argument. Progress presentation must work for an active operation even without a measurable stage, without inventing a percentage or treating presentation as completion evidence.
3. Product readiness and retirement observation are being mixed. Lifecycle observes CURRENT layers, selects RetirementSelected for cleanup PENDING, runs materialize/Upgrade, then replaces its product status with the retirement result. Editor log repeatedly reports NeedsAttention and 'automatic retired-instance convergence failed: Command completed successfully.' Manager also has a 30-second Ready freshness expiry. These are confirmed competing status paths; exact timing of the photographed oscillation and the raw retirement response still require a focused regression/reproduction. A pending historical cleanup alone must not be represented as a failed new INSTALL.

## Unresolved adjacent evidence

The successful action's current-action index remains pending. RequiresRetainedAdmission only tests timeout/overflow/drain-incomplete, all false in the terminal; TryReleaseDurableIndex is invoked after terminal lookup, but its return/detail is discarded. The exact release failure is not established by this read-only pass. Do not delete or release the index manually, or weaken receipt authentication on this evidence.

CanRequestInstallReconcile additionally requires cleanup COMPLETE, so this successful PENDING install does not request that post-command reconcile. This is an observed contract restriction, not yet proof that it caused the photographed oscillation.

## Proposed bounded repair for disposition

Separate EditMode cache presentation from explicit Play suspension; provide operation progress feedback independent of Provider stage markers; preserve authenticated current-instance readiness separately from historical retirement/cleanup observation, while keeping readiness freshness and genuine availability failures visible. Trace the successful terminal-to-index-release result as the immediately adjacent regression. Retain original failed-action history, do not fabricate readiness, repeat INSTALL, stop external holders, or broaden into a Host redesign.

Implementation and independent review have not started for these new findings. Unity remains human-controlled. S29 remains PARTIAL.
