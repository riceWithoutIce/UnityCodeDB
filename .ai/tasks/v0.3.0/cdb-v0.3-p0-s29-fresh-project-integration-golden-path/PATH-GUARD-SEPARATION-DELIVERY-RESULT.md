# S29 path-guard separation — delivery result

Date: 2026-10-12.
Status: `REFERENCE_SWITCH_COMPLETE / FOCUSED_HUMAN_GATE_PASS_WITH_LIMITS / SHUTDOWN_CONFIRMED`.

## Source and package

- Commit: `b76957a9dbcae9b00eff73775a97c4e8f33ae785`
- Package root: `.artifacts/s29-manager-admission-b76957a`
- Review Package: `.artifacts/s29-manager-admission-b76957a/review/com.rice.ai-codedb`
- ZIP SHA256: `f6b82ec21851c528ab9e947e9d1f058059be02a5f389e3b3c56cf937806f3c20`
- ZIP bytes: `2947168`
- Export: 586 entries; 12,399,813 uncompressed bytes.
- Generation hash: `944fab7055368870ab3a1fb4c5940e1d4b1ebe6b772a7e52d1bef728272af27f`
- Host-current hash: `1c03e579c69cbecc1909ea54c1cd5a05497c07d0ab38aea7817941149b0559af`
- Runtime contract hash: `24bc8da5c9fb1914113b0d9270ecbb77285b09a7ce9f31841a6ac58906863604`

Commit-stage and exact-ZIP export both passed production payload admission,
native VerifyOnly and 60-source byte closure with zero mismatches.

## Reference switch

S29 project: `UnityFreshInstallValidationProjectS29`.

Both `Packages/manifest.json` and `Packages/packages-lock.json` now point to:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-manager-admission-b76957a/review/com.rice.ai-codedb`

The lock source is `local`, JSON parsing passed, target `package.json` exists,
and each file had exactly one intended old-to-new replacement. Backups are in
`.backups/s29-manager-admission-b76957a`.

No S29 Unity process was running during the switch. No process was stopped;
the unrelated Unity project/processes were untouched.

## Human gate and limits

The user reported normal Manager close/reopen, tab switching and Unity shutdown
for this exact package. Read-only checks confirmed the selected reference and
ZIP hash and found no S29 Unity process. The supplied screenshot no longer
shows the false user-local-root diagnostic; historical ownership and generation
conflicts still block changes as intended by the retained fail-closed boundary.
Focused Unity EditMode tests for this exact package remain NOT_REPORTED, so this
is a limited human result. See
PATH-GUARD-SEPARATION-HUMAN-RESULT-2026-10-12.md for attribution and limits.
Do not run Install, Uninstall, Remove Integration or Configure solely for this
gate.

S29/release remain `PARTIAL`. No push, publication, payload regeneration or
history cleanup was performed.
