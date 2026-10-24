# Unity crash P1 human validation — repaired package

Package reference has been switched to:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-unity-crash-p1-9a2ca41/review/com.rice.ai-codedb`

Package ZIP SHA-256:

`153816dd39868a104937f193147b1322d51f1645461684f22bfcf754a1f3b597`

With the S29 Unity project closed before the switch:

1. Open `G:/RiceProgram/UnityCodeDB/UnityFreshInstallValidationProjectS29` in Unity.
2. Wait for compilation to finish and confirm there is no compiler error.
3. Open the CodeDB Manager and use the normal EditMode path. Observe the window briefly, then close and reopen it once.
4. Close Unity normally once.

Please report:

- whether Unity showed the Crash Reporter or closed unexpectedly;
- whether the Console/Editor.log contains `GetManagerFromContext` fatal shutdown text or a new `Crash!!!`;
- whether the final Manager state remains `Ready` or changes to another state;
- any status oscillation observed during open/close.

This is a bounded runtime check for the shutdown crash repair. Do not run
Install, Uninstall, or any package export during this check.
