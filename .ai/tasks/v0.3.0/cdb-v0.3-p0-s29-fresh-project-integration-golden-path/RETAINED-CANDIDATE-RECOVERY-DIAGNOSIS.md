# S29 retained candidate recovery - bounded read-only diagnosis

2026-10-09. READ_ONLY_DIAGNOSIS_COMPLETE / RECOVERY_ROUTE_ALIGNMENT_PENDING.
User asked `好的 我们继续` following completed Package/UI observation. This
record identifies the next blocker and proposes a coherent same-S29 scope;
it does not authorize code repair or real project mutation. Unity stays human-owned.

## Current evidence

Project UnityFreshInstallValidationProjectS29 uses committed Package4ba4ccb /
unchanged payloadpoc.41. The observed automatic cleanup warning is exit1:
`Next project change refused: relevant candidate execution is unbound or ambiguous.`
The actual project contains two historical PROVISIONING candidates:

| Candidate | Generation | Attribution | Disposition |
| --- | --- | --- | --- |
| 330b7a972a7649259409fbce4de8ca56 | poc.39 | original action73c9d6a0a8ba4df0898721265ec515d6 | Bound by failed-preparation removal intent35db5b76947741278dceeef1d98990c7, 46retained effects |
| 5a6ff71560234b558e1a42148b680a77 | poc.40 | INSTALLf14c0524af324b7a802335a393483fa0, operation5acbabf5705f48208d7d57882702d14d | Failed with incomplete output; no retained/removal intent binding |

Desired state is UNINSTALLED/PENDING, state35db5b76947741278dceeef1d98990c7.
Both candidate instance.json hashes match prior known evidence. The four
compact f14c action/admission/claim/terminal hashes also match the earlier
diagnosis. Admission explicitly records the same project, original poc.40
Package and action/operation in arguments. Terminal remains exit6,
output_drain_incomplete=true, completed2026-10-08T10:18:22.0632507Z.
This makes the original linkage inspectable; it does not prove effect completeness
or authorize retrospective command-success rewriting.

No instances/current.json or last-known-good.json, host current/last-known-good,
control operation.json/contracts/supervisor were present at inspection.
control/operations is empty; one removal-intent file binds only poc.39.
Host generation directories poc.39/poc.40 remain. No liveness/lock/holder safety
proof was performed, so absence of selection is not evidence of safe cleanup.

## Production contradiction

Tools~/codedb-instance-engine.ps1 Assert-InstanceNextChangeAdmission lines3213ff
builds bound candidates from authenticated intents/selected/retired authorities.
Its directory loop line3248 rejects the extra unbound poc.40 candidate. This
refusal protects unknown effects and is not itself permission to bypass policy.

Existing Get-FailedPreparationRemovalAuthority lines2021-2032 requires exactly
one candidate and exactly one generation in the whole project. It cannot admit
a new failed candidate alongside a previously authorized retained closure.
Get-FailedPreparationEffects lines1867-1869 admits only instance.json and known
editor-lease mutable files. The poc.40 preparation actually progressed further:
known config files, text adapter/index, logs and lifecycle state exist.
Thus simply weakening the candidate-count condition cannot safely unblock it.

The reinstall contract explicitly allows preserving an inert PENDING closure
while a fresh Install creates a distinct verified candidate. Recovery currently
covers the first early failed preparation, not failure of that subsequent fresh
Install after additional candidate effects exist. This is a lifecycle recovery
coverage gap, separate from the closed payload-admission/export finding.

ReconcileHistoricalUnknown is not a generic recovery route: the current code
binds exact historical action3049af7cfc9f4260928e3f89d18672c0 / S27 receipt layout.
Do not invoke or broaden it to f14c or manufacture old resolution evidence.

## Proposed same-S29 correction, not frozen implementation authority

Extend the existing confirmed uninstall/failed-candidate disposition route to
classify one precisely attributed failed candidate separately from already
bound retained closures. Reuse existing instance/generation contracts, project
lock, removal intent and holder/registration authority. Inventory only its
actual known production-generated candidate effects, with bounded paths and
attribution; reject unowned bytes, mismatches, redirects, conflicting authority,
additional unknown candidates and live/ambiguous holders. Preserve both old
closures and original failed results. New disposition proves current inactive
integration/effect state, never historical command success or output completeness.

The direct normal-path regression is:
failed Install -> confirmed removal/inert retained closure -> fresh Install
fails after preparation -> confirmed disposition -> fresh Install can proceed.
Freeze one consumer/effect map and focused source+exact-Package evidence for
this sequence and its directly coupled refusals. Avoid a generic historical
framework, repeated old suites or a policy that admits all unknown directories.
No PID kill, OS/session restart, cleanup deletion, candidate adoption, user-global
config change or new validation project. Real disposition/new Install follows
its own concrete reviewed human operational checkpoint after source delivery.

## Fingerprints and limits

- poc.39 instance.json:13cb910b889aa671024ad97a70e69601289be8892b4613b8494cdedcd526aeec.
- poc.40 instance.json:1344f215160516141399556c250670021677e0ad0efa0465663c0821664b16f5.
- f14c admission:85cce9f0721295c5eeecc1236b9d9e40a6389c44e36c8096f392606ccab4203b.
- f14c claim:f19743c72c551408f5a610ca09d9b377aeaa43c9985ff3bc98f27867e7b6aad5.
- f14c terminal:cb7f796d8588117509da1792e4b8c392b5538b2b42889ea4f754f8085f30dc64.
- f14c action.json:f662468c1e27b7a5ca30aab40ab084a69351549109ba6107fc68fcfd14890b5b.

No runtime writes, process scans/stops, Unity control, operational scripts,
tests, source edits, reference switches or commit. Reads stayed within the
current candidate/intents/original receipt and direct production functions.
Two early command outputs were truncated; later compact field/fingerprint reads
supplied decisive evidence. This does not substitute for the still-unproved
holder/effect safety. Only this diagnosis and Parent task status were written.
