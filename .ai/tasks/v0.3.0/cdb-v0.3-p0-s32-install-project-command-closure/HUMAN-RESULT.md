# S32 human Unity result and read-only follow-up - 2026-10-18

Status: HUMAN_REPORTED_PASS_WITH_LIMITS / tests, Manager open-close and Unity
exit reported normal. Real lifecycle acceptance remains DEFERRED.

## Human evidence

User reported: `testrun 都通过 manager 开关、unity 关闭都正常` and supplied
the Manager screenshot ending `137d1fe6-fcfa-4374-bad0-cc46f16b6b4b.png`.
Treat this as human-confirmed test and UI/exit evidence for the requested round;
no agent rerun or automatic Unity launch was substituted. The report does not
individually enumerate test cases. Tab switching and a standalone compilation
result were not separately reported; no compilation error was reported. Do not
invent those separate observations or infer full-suite/runtime acceptance.

Screenshot observations:

- CodeDB Manager is open and displays Package v0.3.0-preview.5.
- Current integration displays CodeDB uninstalled from this project and not
  connected; automatic installation/watcher attachment are disabled.
- Previous Install action `6b9678672d3744f0ab052e521ae42ad6` retains unknown
  outcome, with its original S31-D Package attribution. New changes remain
  blocked pending execution-safety proof.
- Last activity says no recent command; Outcome unconfirmed reports absent
  Supervisor state. This does not prove a new Install was attempted or failed.

These observations agree with the checklist's protected historical-state limit.
Current integration status and prior command outcome remain separate. Neither
the screenshot nor passing tests releases the old action or proves safe retry.

## Read-only follow-up

At the follow-up checkpoint:

- Both S30 Package JSON references still select the exact S32 extraction from
  commit `b0462ed07b6a14be64bddf848e67609d9143fa71`; CodeDB testables remains.
- Manifest SHA-256: `4403660cfa8eff983797450fd30686a3be1b96a76cae05be229d6c3e433f0273`.
- Lock SHA-256: `1298107ff26332b4ff0c8bccce16fa000336294a9c031b3e52e299171c433307`.
- ZIP SHA-256 still equals
  `56fdfbe2f81fe5ff3f1ccce07c6bc7fdd65610a218450f4ead9a3afaa5500fae`.
- All original 623 extracted Package files still match the frozen candidate.
- An initial exact-count check found 624 files; bounded comparison found exactly
  one additional import metadata file:
  `Tests/Editor/AICodedbHostPayloadMaterializerPreflightHandoffTests.cs.meta`,
  GUID `a58d22f687287e34eaa604d5eac3c832`. This is consistent with Unity import
  metadata creation. It was preserved; no original Package byte or ZIP changed.
  Do not describe the post-import directory as exactly identical to the ZIP.
- No attributed S30 Unity process and no Temp/UnityLockfile were present,
  supporting the human normal-exit report at this checkpoint.
- HEAD remains the delivery commit; staged index empty. All eight protected
  baseline inputs other than the two authorized Package-reference changes match.

No tests, live backend, Install/Uninstall, pending-action recovery, history
rewrite, process control, package regeneration or reference switching was run
in this follow-up. Only task documentation was updated.

## Disposition and next boundary

Source acceptance, exact delivery and the reported focused Unity tests/Manager/
exit round are recorded as passed with the limits above. The old unknown action
is a preserved historical boundary, not a reopened S32 source finding. No further
source repair or review loop is started.

Next: align a bounded real current-version install/lifecycle acceptance route
and its baseline. Decide separately how to handle the existing protected S30
pending action/legacy records, or choose a clean acceptance baseline under the
existing workflow. Do not silently clear history, infer NO_CHILD for legacy
records, or authorize a retry from this human result. Successful initialization,
Provider, Ready and real reinstall remain unverified.
