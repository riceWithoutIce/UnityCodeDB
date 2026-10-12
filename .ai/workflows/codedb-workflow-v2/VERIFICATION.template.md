# Verification: <task-id>

## Outcome

- Verdict: PASS | FAIL | BLOCKED | DEFERRED
- Workflow: codedb-workflow-v2
- Workflow revision: 2.6
- Review mode: GUARDED | RELEASE | <explicit request>
- Actual execution mode/profile/model/reasoning:
- Delegation authorization used: NOT_APPLICABLE | TASK_SPECIFIC | STANDING_WORKFLOW
- Frozen identity admission:
- Reviewed claims:

## Evidence

- Reused Coder evidence:
- Path provenance gate admission: NOT_APPLICABLE | <reused Coder result and affected path review>
- Targeted read-only checks:
- Tests rerun: none | <explicitly authorized run>
- Identity stability:
- Release closure identity: exact artifact, frozen commit, extracted root, and
  cross-hash checks:

## Findings And Limits

- One-time findings: none | BLOCKER/P1/P2/FOLLOW-UP
- Original finding and adjacent regression status, when applicable:
- NOT RUN/DEFERRED boundaries:
- Package source enumeration and artifact extraction reused:
- Out-of-scope observations:
- Mode promotion: NOT_REQUIRED | MODE_PROMOTION_REQUIRED: <reason>

## Handoff

- Current task:
- Current status:
- Next notification: Planner/User
- Next action: decide ACCEPT | FIX | DEFER | STOP
- Human decision or authorization required: yes

Verification is read-only and claim-bounded. Do not audit the repository,
rerun unchanged Coder tests, widen coverage, contact Coder, or turn theoretical
hardening into a blocker. Report all material in-scope findings once.
Return findings for User disposition. After User approves a bounded FIX,
Planner continues the declared repair and targeted repair review without
another start approval. Do not infer delivery authority from source acceptance.
