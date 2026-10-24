# S29 startup authentication boundary — human Unity checklist

Use the already switched project:
`G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.

1. Open the project in Unity and wait for import/compile to settle. Record any
   compiler or package errors.
2. Run the focused EditMode tests for the accepted Manager/lifecycle change if
   the project is already configured for them. Do not run Install, Upgrade,
   Remove or cleanup solely for this checklist.
3. Open CodeDB Manager, close it, reopen it once, and switch its tabs. Record
   visible status transitions and the final state.
4. Close Unity. Record whether the first close blocks; if it does, do not force
   terminate it without separately recording that human action. A later close
   attempt should be recorded as a separate observation.

This is a human-owned gate. Do not infer source or package failure from an
unrelated Unity project process. Keep the exact package path above in the
result.
