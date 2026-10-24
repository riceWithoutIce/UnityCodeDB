# Retained path test compilation correction delivery

2026-10-09. Commit a06944c1cb7e29ff0b2b209eebe6ca4fe502de85 contains the
single serializer qualification and its repair record. Separate local artifact:
.artifacts/s29-retained-path-poc42/review/com.rice.ai-codedb.
The directory suffix is only a delivery name: actual protected generation
remains poc.41, Package0.3.0-preview.5; no generation/version bump occurred.
Earlier references to this directory as a new poc42 generation were imprecise.

Standard exporter commit-stage/exact-ZIP admission and byte gates PASS,
58sources/0mismatches. ZIP SHA256:
b4d93b0d4ecb9c81eb831e3fc0ef0251b3d385ab8370bea0d2c5c5eb0debb253.
Fixed extracted test SHA256:
25c8b5a72b69567591f6e000d0b329d86f92aeb68065f3fff88b759a69804fa4.

Actual extracted WindowsPS writer PASS39/native_children0/113389ms;
exact extracted retained C# reader PASS32. Outer journal/session/NUnit and
fresh INSTALLED branch remain unrun. Fresh short proof:
.artifacts/tests/p41path-a3e940e131fb/emitted-record-context.json,
SHA256c403b4a75fc42fe46316ec0f179be1026498fc749fbb4bfa71938c521d296f6d.
Max existing file path231. An early log-tail check ran before writer completion
and found no PASS marker; this was a premature status check, not a failed
test or rerun. Full final log confirms PASS.

User confirmed Unity normally closed. Old S29 process absent and lockfile
absent before preparation; reference switch also refused existing lockfiles.
Only CodeDB manifest/lock references switched; reference-normalized hashes
unchanged from previous delivery. Backup under
.backups/s29-path-compile-reference-20261009. Real runtime/candidates untouched.

Updated child-only proof configuration and invoked existing launcher once
under the user's continue/closure authorization: PID44152. No automated Unity
test, MCP/CUA, real Install/Uninstall/recovery, persistent environment update,
process termination, remote write or publication. Compile success is NOT
established by launch. Human still runs the same three EditMode methods in
RETAINED-PATH-IDENTITY-HUMAN-CHECKLIST.md and observes Manager. S29 PARTIAL.
