# S38 project and Package setup result

Date: 2026-10-20.
Status: `PROJECT_CREATED / PACKAGE_CONFIGURED / HUMAN_IMPORT_PENDING`.

The human reported that the clean Unity project was created at
`<repository-root>/.artifacts/unity-projects/current-lifecycle/` and the Editor
was closed. Read-only inspection confirmed Unity `2022.3.62f3
(96770f904ca7)`, default SampleScene only under `Assets/`, no CodeDB
dependency, no `AIWork/` or `.codex/`, no Git/reparse state, no Unity lock or
Editor instance file, and no process command line naming this project root.
This is a bounded closed-project baseline check, not Unity acceptance.

The original two Package configuration files were copied into
`.backups/s38-current-lifecycle-baseline-20261020/` and verified byte-identical:

| File | Original and backup SHA-256 | Configured SHA-256 |
| --- | --- | --- |
| `Packages/manifest.json` | `5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1` | `3ed7b6970c7571104609db14ce1aa255f765922c54a402211ab828be9ab04105` |
| `Packages/packages-lock.json` | `2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6` | `d2211f6e7032ba58322a652e5f8bbeeea036ff6b50be21618d8b3aa436d7b32e` |

Only the CodeDB local dependency, its lock entry and the Package testable were
added. Parsed manifest/lock CodeDB references agree and resolve from the actual
`Packages/` directory to the exact
`.artifacts/s37-supervisor-terminal-result-d856a8f/review/com.rice.ai-codedb`
extraction. The lock entry has `source=local`, `depth=0` and no child
dependencies. After removing those new entries in a structured comparison,
all original dependency values matched the backup. The source ZIP still has
SHA-256 `97aecd28ff47656a9b6cd66666f6c9030b95a8f4b5a98cf8cf68f588058031a9`.

The backup is temporary rollback data. Review its deletion after the new
project's import/configuration baseline is accepted and rollback is no longer
needed; no automatic cleanup is granted here.

No Unity launch, project runtime creation, CodeDB Install/Uninstall, source
edit, export, process control, commit or push was performed. Next, the human
opens this exact project, allows Package import/compilation to settle, and
reports Console/compile status plus whether Manager shows a clean uninstalled
baseline with `Install CodeDB` available. Do not click Install yet. Focused
Test Runner selection and the real-action grant remain separate next gates.
