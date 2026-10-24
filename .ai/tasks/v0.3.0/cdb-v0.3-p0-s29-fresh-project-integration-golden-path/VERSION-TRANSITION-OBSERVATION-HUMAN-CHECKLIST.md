# S29 version-transition observation — human Unity checklist

Use project: `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29`.
It now references the exact package under
`.artifacts/s29-version-transition-observation-14444cf/review/com.rice.ai-codedb`.

Before opening Unity, prepare the accepted production fixture directory:

`.artifacts/tests/s29-version-transition-observation/coder-a1/fixtures/r-c56cb129`

Set the Unity process environment variable:

`CODEDB_VERSION_OBSERVATION_FIXTURE=<absolute path to that fixture>`

If the variable is absent or the fixture is invalid, the focused test is
`Ignored`; that is not a PASS.

Then, in Unity:

1. Open the S29 project and confirm package import/compile has no errors.
2. Run the focused version-transition test:
   `ManagerVersionTransition_ProductionObservationKeepsIdentityAndSafetySeparate`.
   Record whether it runs and passes; distinguish Ignore, failure and PASS.
3. Run the previously accepted focused EditMode checklist if needed for the
   same package, without repeating Install.
4. Open Manager, close it, reopen it once, and switch its tabs.
5. Observe whether the UI distinguishes historical predecessor ownership from
   current target readiness. `Needs attention` is expected while poc.42 remains
   installed and poc.43 is the target; do not require Ready from this state.
6. Close Unity and record whether the first close blocks. Keep any shutdown
   observation separate from this version-transition change.

Do not click Install, Remove, Uninstall or Upgrade during this gate. Do not
delete historical receipts, candidates or indexes. Report the exact displayed
reason if the removal preflight still returns exit 4. This gate does not claim
real migration/removal, sustained Ready or release acceptance.
