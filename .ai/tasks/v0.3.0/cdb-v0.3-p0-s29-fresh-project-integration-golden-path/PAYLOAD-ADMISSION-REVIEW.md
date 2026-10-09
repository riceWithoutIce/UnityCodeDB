# S29 payload admission independent review packet

2026-10-09. Coder stopped; Parent checked the four source hashes against RESULT
and the scoped changed/new script set. Index is empty; HEAD remains
8b2061d45504da551b626714a877176051a43fe1. User confirmed the S29 Unity project
normally closed and permits a later reference switch; no consumer change yet.

Frozen task SHA256 f2498663b9a41bacd02243f5877a734526b43232faa03426d23cc2692d88f74d.
Result SHA256 5830bba57e720e3e1d6dd03d667ef66bca6ca0f210c25c7cc0b6d49072077365.
The result's four final source hashes match current bytes. Read the complete
task/result in bounded chunks, then direct source dependencies as needed.

Review only the original admission finding and adjacent regressions:
1. Six exact audited targets; no new wildcard or manifest-derived permission.
2. ValidatePayload invokes the actual Read-PayloadManifest and target policy,
   exits before project integration, prerequisites, locks and mutation.
3. Standard export helper requires separately attributable admission/byte PASS;
   both commit-stage and exact ZIP gates use the actual production reader.
4. Saved positives and two negative layouts prove gate refusal specifically at
   the original boundary, with valid source hashes and protected/no-write state.
5. Workflow amendment is limited to this gate and focused consumer-map coverage.

Evidence: .artifacts/tests/pa41-baseline, pa41-admission-01, pa41-final/proof.txt.
RESULT names the exact commands/raw output/snapshots. Reuse saved PASS evidence;
no runtime/tests/cleanup/Unity/commit or production edits. Source snapshot ZIP
is not a new commit-derived delivery; the latter is still a Parent prerequisite.

Verifier writes only PAYLOAD-ADMISSION-VERIFICATION.md in this task directory,
<=12 KiB. No nested agents or Coder requests. User finding thresholds apply:
normal path/data/config safety/critical promised evidence may block; theoretical
hardening/unfrozen breadth is follow-up. Return all findings once, or scoped
PASS, and stop. At most 20 minutes, tool output <=8 KiB, targeted reads only.
Disclosed early Coder output-budget breach is retained as a workflow deviation;
do not retroactively claim compliance or broaden review because of it.

No real Install/recovery, human Unity, C# compile or release acceptance is
claimed. Prior daemon evidence and all protected payload/history remain intact.
