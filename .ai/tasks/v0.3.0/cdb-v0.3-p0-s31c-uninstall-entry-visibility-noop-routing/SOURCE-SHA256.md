# S31-C source snapshots

## Initial reviewed snapshot (preserved)

- Base/Head SHA (unchanged): `279b442c657676d1adbda7d15151a3770682a674`
- Coder role: task-scoped single writer, inherited configured model/reasoning.
- Incoming tree was dirty; HEAD does not identify its source bytes.
- All paths below are relative to `<repository-root>`.

| Path | Incoming SHA-256 | Final SHA-256 |
| --- | --- | --- |
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | `54c206316444959c354032f8b4246d790bd6869965cebbbee6948b115744e5876` | `d812bd9ee59a1a9518eebb4a5918b8877e6dc8ca834275fa2107433df936947e` |
| `com.rice.ai-codedb/Editor/AICodedbActions.cs` | `9afd83bf12e6e2cdde38cc1630686fc9beb020bf745b6322544a4ec5fc2371e0` | `4b52d1321522ed86ffa7f40245e8a3de2685fe2402e965466b573383ad9671d0` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `a95bea3e96c2d2931ae7da947b4df48b40ab7afc0ee7fc1032b0050e5577d13e` | `d01a897b186e735734b557eae9b0585a764323416ddf531324a600c2046f4501` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `be61964b76445d442d5956e5f89d54c53bbaaf046e5088038cfc87a8db1395af` | `634100865e8e7410b6d35cfb4bb6ff526cc383c0d8cdbfbe70e9682f3354662e` |

- `run-focused.ps1`: `f6a2a7f931e08f228e9d01691dab84794298b0415d8e63929df3136b27e517a5`
- Final compile snapshot `.artifacts/tests/s31c-entry-20261017-c/manifest.json`: `0f3d7be4f360819796bd8f5af5009b180722ab16149da8343acb4899de30b9ca`
- Earlier focused execution `.artifacts/tests/s31c-entry-20261017-b/manifest.json`: `1f0c3d4084ac8c16e2f5b70a8fe1796d994f84a38ac21644b494365108cc3974`
- The only source change between `-b` and `-c` is a receipt-root isolation scope
  inside the unexecuted full-session Editor test; executed product/label/busy
  methods are byte-equivalent. Final `-c` compiled successfully; no native retry.
- Manifest binds original current Editor/test C# inputs, tool/reference hashes,
  driver hash and environment redirects. Raw artifact paths are diagnostic data.
- No commit, generated package or consumer reference was changed by this task.

## F1-only repair snapshot — latest

- Base/Head SHA remains `279b442c657676d1adbda7d15151a3770682a674`.
- Prior final hashes above are the F1 repair baseline, including dirty state.
- Only Actions, directly related ManagerUiTests, the task-local driver and
  task records changed during this repair. F2 was not touched.

| Path | Before F1 SHA-256 | After F1 SHA-256 |
| --- | --- | --- |
| `com.rice.ai-codedb/Editor/AICodedbActions.cs` | `4b52d1321522ed86ffa7f40245e8a3de2685fe2402e965466b573383ad9671d0` | `9c2133d9790183b22d57415977a9dafa8518c7df9730271785bc5b2fffd4bee2` |
| `com.rice.ai-codedb/Tests/Editor/AICodedbManagerUiTests.cs` | `d01a897b186e735734b557eae9b0585a764323416ddf531324a600c2046f4501` | `abf690e017b4343b0dfda8d26b7cd71a4744831cfd52ee5126b954dc7e745fd5` |
| `com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs` | `d812bd9ee59a1a9518eebb4a5918b8877e6dc8ca834275fa2107433df936947e` | unchanged |
| `com.rice.ai-codedb/Tests/Editor/AICodedbEditorLifecycleTests.cs` | `634100865e8e7410b6d35cfb4bb6ff526cc383c0d8cdbfbe70e9682f3354662e` | unchanged |

- Latest `run-focused.ps1`: `b6c598fc6416ef84f8b3d33389cf8dd1556fc2736b6c4423353951f917f4a4b6`.
- `.artifacts/tests/s31c-f1-20261017-a/manifest.json`:
  `fc29f42496bf02b026d0becd859c5e99daf9f42a0a5cedd3de0c149dc3b4c5f0`.
- The latest manifest binds all original Editor/test input hashes and reused
  tool/reference hashes. Compilation PASS; F1-only typed component execution
  PASS. Frozen native reader/session scenarios and old 22 tests were not rerun.
