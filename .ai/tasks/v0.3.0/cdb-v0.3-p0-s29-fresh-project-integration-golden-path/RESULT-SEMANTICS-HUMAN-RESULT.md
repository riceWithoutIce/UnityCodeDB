# S29 result semantics human validation evidence

Date: 2026-10-08. User reports: "test 都通过" after the delivered five-method /
45-case checklist. The supplied Test Runner screenshot visibly shows 45 passed,
0 failed, and all eight filtered ManagerReceipt_UnclassifiedEvidenceStaysBlockedWithOriginalPackage
cases green. This records HUMAN_REPORTED_TEST_PASS with screenshot corroboration;
no NUnit XML was supplied or independently parsed. The other method names are
covered by the user's all-tests-passed report, not individually visible in this
filtered screenshot. Real C# consumer execution is therefore human-reported,
not an agent-executed test result. No independent Console-zero count is claimed.

Delivered candidate: commit d56f0e507b48af24a39f23411c06dbdd4e093084,
.artifacts/s29-result-semantics-poc40/review/com.rice.ai-codedb, referenced by
UnityFreshInstallValidationProjectS29 during the preceding authorized preparation.
The screenshots do not independently display the full Package source path.

## Manager observation

The second screenshot no longer displays the previous generic resolved-marker /
original-receipt conflict. Its historical warning correctly identifies action
d8c736504562495dbafdd673c6851efb and original historical Package, states recorded
failed INSTALL with PENDING cleanup, explains that later completed stages do not
clear those effects, and requires separate removal confirmation/live safety checks.
This is the intended interpretation change for the diagnosed historical chain.

The activity pane shows that same historical Install, exit 6, elapsed 4.95 seconds,
with its originating_action error. It is evidence of retained original failure,
not evidence of a newly attempted Install or a regression in the current tests.
The historical raw output still contains garbled characters; no encoding repair
was part of this source change and no historical bytes were rewritten.

Current Manager presentation is CodeDB status unconfirmed, with current status
unavailable and an Uninstall CodeDB from Project button. Many diagnostics are
Not evaluated. This is not Ready, cleanup completion or verified removal admission.
No instruction to click a mutation button follows from this screenshot.

Follow-up human report: "切换各manager 页面，同时也无明显异常". All Manager
tab switching is now human-reported PASS at the no-obvious-abnormality scope.
Final human report: "关闭manager 后也无异常". Manager-close observation is
now human-reported PASS. Together with the reported 45-test PASS and screenshot
evidence, this closes the bounded result-semantics repair's human test/observation
cycle. No new review or unchanged test rerun is required. This does not certify
an independently inspected Console count, cleanup completion or real integration.
No Unity-close state is inferred. No agent
Unity/MCP action, live record inspection, install/remove/replay, cleanup, commit or
artifact/reference change occurred while recording this result.

Evidence images supplied by the user:

- C:/Users/admin/AppData/Local/Temp/codex-clipboard-61eb8495-e967-43d5-9705-a95043682722.png
  SHA256: 392491766D5221B921F66AD315D6926C1A2EC3E011556F306F40E3D68F59CA67.
- C:/Users/admin/AppData/Local/Temp/codex-clipboard-6f3cb988-1578-43a1-9105-cbf420f749a8.png
  SHA256: 2832DD08974F3A0163B1A4C86E88E8138D3F19B1F634A15881C888D9512A92DE.

Status: HUMAN_REPORTED_45_TEST_PASS / HISTORICAL_RESULT_PRESENTATION_CONFIRMED /
MANAGER_TAB_OBSERVATION_PASS / MANAGER_CLOSE_OBSERVATION_PASS /
RESULT_SEMANTICS_HUMAN_VALIDATION_COMPLETE /
REAL_INTEGRATION_UNACCEPTED / S29_PARTIAL.
