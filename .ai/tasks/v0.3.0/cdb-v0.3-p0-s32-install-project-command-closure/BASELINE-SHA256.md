# S32 incoming source binding

HEAD: `97471f537749eba97171f6756a29112dd552a22b`.
These bind active worktree bytes, not HEAD bytes. Preserve incoming unrelated
hunks in ProcessRunner, instance-engine, direct writer and the contract document.
Payload/generation manifests are outside the write allowlist.

| Repository-relative path | Incoming SHA-256 |
| --- | --- |
| com.rice.ai-codedb\Editor\AICodedbActions.cs | 9c2133d9790183b22d57415977a9dafa8518c7df9730271785bc5b2fffd4bee2 |
| com.rice.ai-codedb\Editor\AICodedbHostPayloadMaterializer.cs | 8c42c3f094b443245189487229f8f6effc7a461c93bea02b5d4068d09b93d1f5 |
| com.rice.ai-codedb\Editor\AICodedbManagerWindow.cs | 93d988f4ea9de1cd417e9bd66418fa8da8f73155b22e32de60559de25593215b |
| com.rice.ai-codedb\Editor\AICodedbManagerActionSession.cs | ABSENT |
| com.rice.ai-codedb\Editor\AICodedbManagerActionJournal.cs | 6d2937b3df6e9d5aebd454e4971200c1bace52c0c107216f8c9af7a3a1aa2090 |
| com.rice.ai-codedb\Editor\AICodedbProcessRunner.cs | f00ffc13ea934b4f05ccf5d132bb3d1348f8014f0132378c39040f4a0dfa1f3f |
| com.rice.ai-codedb\Editor\AICodedbSupervisorBridge.cs | c1b8d95b2867a773192f41b30ccbc0617a45b61c27af99ffecb9be0a0493782f |
| com.rice.ai-codedb\Editor\AICodedbInstallAdmission.cs | ABSENT |
| com.rice.ai-codedb\Editor\AICodedbInstallAdmission.cs.meta | ABSENT |
| com.rice.ai-codedb\Tools~\codedb-instance-engine.ps1 | dd27865c0fe3b29b1f001467b7201dc606b32170649c626de6a98d3c199097c4 |
| com.rice.ai-codedb\Tools~\invoke-codedb-manager-action.ps1 | 2c1ed6b3dff2fb2dbb2e06ed8dab252738349d951f57347845d7c337fec0bf06 |
| com.rice.ai-codedb\Tests\Editor\AICodedbManagerUiTests.cs | e446fe051ca6c54a359c7f21800f7847f878d723d76bd5503007d3b5fba167b7 |
| com.rice.ai-codedb\Tests\Editor\AICodedbEditorLifecycleTests.cs | 6354e22fba319d4d80c1b8daba0cfbd18ca6b615aecec5d15f7d9e9049eb8f7d |
| com.rice.ai-codedb\Tests\Editor\AICodedbS32InstallTests.cs | ABSENT |
| com.rice.ai-codedb\Tests\Editor\AICodedbS32InstallTests.cs.meta | ABSENT |
| com.rice.ai-codedb\Tests~\test-codedb-host-payload-materializer.ps1 | 397635c916d6a1fdb8b1cf6d1eb3baa8008b4565553d0f10acc1d1f9b319134d |
| com.rice.ai-codedb\Tests~\test-codedb-project-supervisor.mjs | 8da23e2dca16526e09321040ff71fa1970af0c8b02269cfac2338d36c18f5ebd |
| com.rice.ai-codedb\Documentation~\v0.3.0-p0-host-action-execution.md | ef1c5262fd49e3286700b77a6c073af85fe084039a5e3d2f7e8162d6f400e431 |
