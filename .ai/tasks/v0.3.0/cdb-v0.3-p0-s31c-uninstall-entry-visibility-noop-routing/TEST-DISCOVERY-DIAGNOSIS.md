# S31-C human test discovery prerequisite — 2026-10-17

Status: CONFIGURATION CORRECTED / HUMAN UNITY DISCOVERY PENDING.

User reported no selectable EditMode test; screenshot filters the exact
`RemovalMenu_KeepsKnownIntegrationVisibleWithoutGrantingAdmission` method.

## Evidence

- S30 manifest selects the delivered cc49c95 extraction correctly.
- Extracted original test source and `Rice.AICodedb.Editor.Tests.asmdef` exist;
  the asmdef includes Editor and optional `TestAssemblies` references.
- S30 manifest lacks top-level `testables`. Standard UnityValidationProject
  already declares CodeDB in that field.
- S30 ScriptAssemblies contains the CodeDB Editor assembly but not its test DLL.
- Thus the Package-test discovery prerequisite is missing. This is not a
  failing assertion or evidence that the accepted implementation regressed.
  Clearing the name filter alone does not add the undiscovered Package assembly.
- Parent's prior delivery checklist omitted this prerequisite check.

## Bounded Proposed Correction

Add only top-level `"testables": ["com.rice.ai-codedb"]` to the S30 manifest,
preserving dependencies, package reference, lock file and real installation.
Back up the current manifest under a new repository-local backup root first.
Do not create a test assembly, move source into Assets, reinstall, re-export,
modify accepted Package bytes, launch Unity or execute a real lifecycle action.

Prior delivery authority limited consumer writes to exact CodeDB reference
replacement; request authorization for this additional project configuration.
Human retains Unity reload/test execution. After enabling discovery, use the
same focused HUMAN-CHECKLIST.md; do not broaden the suite.

## Authorized Correction Result

- User `好的 请你编辑一下` authorized the single manifest correction.
- Backed up the current manifest to
  `.backups/s31c-test-discovery-20261017-a/manifest.json`; verified original
  SHA-256 `ed054ad5489f6aa007cf311b426040c5d828eeeeedd06c51f90ea45537ee42a5`.
- Added only top-level `testables` containing `com.rice.ai-codedb`.
  JSON parsing and before/after comparison passed: all other properties,
  dependencies and the lock file unchanged.
- Updated manifest SHA-256:
  `525158f4699754f59848add163365b65401daf64c5f29e6527f08be0dfc8e75b`.
- One command parser/parenthesis error occurred before any side effect;
  corrected once. Backup and configuration change then completed successfully.
- No package/source changes, new export, install, real uninstall, Unity launch
  or test execution. Human discovery and focused test results remain pending.
