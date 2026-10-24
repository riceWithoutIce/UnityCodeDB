# S29 coordinator readiness repair — human Unity result

Date: 2026-10-11 (Asia/Shanghai). Human validation was performed against the
exact review package selected by the S29 project after delivery commit
`427a42495e0fd8a5707da3adf368f895dbf524ad`.

## Human PASS observations

The user reported:

> 编译通过、manager 开关没有异常、页签切换正常、unity关正常

This establishes human PASS for Unity compilation, Manager open/close, Manager
tab switching, and normal Unity shutdown for this run. The supplied screenshot
is retained as the UI evidence:

`C:/Users/admin/AppData/Local/Temp/codex-clipboard-1671c8c1-dbf7-4a29-9e1c-103b0471cf67.png`

## Read-only attribution

The project `Packages/manifest.json` and `Packages/packages-lock.json` both
select the new exact review package:

`file:G:/RiceProgram/UnityCodeDB/.artifacts/s29-coordinator-readiness-repair-427a424/review/com.rice.ai-codedb`

The package-owned `poc.42` generation manifest hash is
`944fab7055368870ab3a1fb4c5940e1d4b1ebe6b772a7e52d1bef728272af27f` and its
coordinator source hash is
`928a58b3e181417b4e70e6b8d23fe90da43147e50319f113b185674ee26baa09`.

The already installed S29 instance and host runtime still contain the previous
generation manifest hash
`2273266950bcd2867416821472285e217b64acdaae2fcf397712e8ab8defe026` and old
coordinator source hash
`5a61242e336fac40ac5ce94729d71c676272f65510993481c80a0ee71651ed00`.
The current instance remains `d620abbab0334a2d9c49e59888c1ef55`, generation
`poc.42`, with desired state `INSTALLED` and cleanup `PENDING`.

This explains the screenshot's `Host payload: Needs Setup` and generation
manifest mismatch: the Package reference was switched, while the existing
installed runtime was intentionally left untouched. The Manager is correctly
refusing to claim the new Package is materialized into the selected instance.

The current coordinator state is also consistent with the screenshot:
`provider_state=starting`, `provider_ready_at_utc=null`, and the latest start
has no recorded Ready convergence.

## Acceptance boundary

Human compilation, Manager open/close, tab switching, and Unity shutdown: **PASS**.

New-package host materialization, authenticated Ready, Provider/IPC startup,
lease publication, runtime convergence, and release acceptance: **NOT PASS /
UNRESOLVED**. No Install/Uninstall, retry, source change, export, reference
switch, process control, or runtime mutation was performed for this follow-up.
S29/release remain `PARTIAL`.
