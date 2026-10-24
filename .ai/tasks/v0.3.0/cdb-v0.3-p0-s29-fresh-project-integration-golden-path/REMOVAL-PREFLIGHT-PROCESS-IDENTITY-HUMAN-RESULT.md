# S29 removal process identity — human result and read-only attribution

Date: 2026-10-15.
Status: HUMAN_REPORTED_PASS / REAL_REMOVAL_NOT_UNLOCKED / S29_PARTIAL.
Exact source commit: 544be4f7e339acefb47137b188cdc85e22483efb.

## Human evidence

User report: `test run Manager 关闭重开、页签切换 Unity 正常关闭 都通过`.
Record the checklist Test Run, Manager close/reopen, tab switching and normal
Unity shutdown as human-reported PASS. No compilation problem was reported.
No raw Test Runner XML or per-method counts were supplied; do not invent those
counts or claim execution of the separately configured isolated fixture.
No CleanupMono recurrence was reported in this sample; observation remains
deferred rather than declaring that issue fixed.

Screenshot preserved at:
.artifacts/delivery/s29-removal-process-identity-544be4f/human-a1/manager.png.
SHA256: 000044d9bde1ac400082c5581881fa3bf440197d74676bfd84d2dfa138d4828a.
The copy matches the supplied image. Manager shows CodeDB needs attention,
Removal required, retained historical effects and [REMOVAL_PREFLIGHT] BLOCKED.
The visible diagnostic ends with active, foreign or inconsistent identity; the
full detail is clipped. Do not infer an exact blocking record or process from
the image. This is consistent with a retained safety refusal, not proof of
successful removal admission, Ready state or Install-button availability.

## Post-human read-only checks

- HEAD remains the exact source commit above; staged index is empty.
- Both S29 Package manifest and lock still select exactly
  file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-removal-process-identity-544be4f/review/com.rice.ai-codedb.
- Manifest SHA256 remains
  ffd18b0eee0e2ca614f12436b60ad0213987dc2cde9a3d539f5d4831e3b405eb;
  lock SHA256 remains
  d2b37c6812672afdf71c627d93bec8585ebfd4362f82c1339baea999c7d9f7c2.
- ZIP SHA256 remains
  65c0bcbb46f138941b5becf4dd59abbebb6528524db7ef5cff91c3e6c152e16a.
- No matching S29 Unity process or S29 Temp/UnityLockfile was observed. The only
  observed Unity process belongs to G:/work/miniGame_int and was not operated on.
- All 5680 entries in the delivery protected-after baseline were checked:
  changed=0, missing=0. This checks recorded paths, not an inventory of additions.
  No protected data or configuration was written by this verification.
- Selected instance remains d620abbab0334a2d9c49e59888c1ef55 / poc.42,
  activation epoch 2f8b2a509a1e4086af4a4457e618d037. Package target remains poc.43.
  Desired state remains INSTALLED / PENDING with state ID
  fbd6a56590584b7a97faf7f4de80737a.
- Verifier record SHA256 still equals
  d8fb9ae6c5f2ef6bfdeb26685110bb291dc9c1af5d64b99f1abbf88d0420125e.

No tests were rerun, standalone product preflight/Probe/IPC invoked, Unity
automated, process stopped, history repaired, or Install/Remove/Upgrade executed.
No new commit, export, reference switch, push or publication occurred. Only task
acceptance records and the repository-local screenshot copy were written.

## Completion and remaining boundary

This bounded process-identity source/delivery/human smoke slice is complete.
PID classification does not grant removal permission. Missing-child historical
records remain fail-closed; they were not reconstructed, bypassed or deleted.
Actual removal, installation/migration and release acceptance remain separate
unfinished gates. S29 remains PARTIAL. Any next investigation should first
attribute the full current refusal read-only, without replaying delivery or
expanding repair. CleanupMono remains deferred under the user's decision.
