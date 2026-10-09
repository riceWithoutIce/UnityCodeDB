# Adapter output committed delivery checkpoint

2026-10-09. SCOPED_COMMIT_PASS / EXPORT_CLOSURE_BLOCKED.

User's latest retry succeeded: Git status exit0, HEAD/base and empty index
verified. Parent revalidated37raw snapshot rows, separately verified387frozen
generation files against base archive and reviewed touched engine/materializer
diff. Scoped commit2154b814e1c4720e7e0915c1843d70eab0c3a0ec:
`fix(host): align adapter output retention with production scopes`.
48paths:37source/projections,3task-only document projections,8records.
Unrelated dirty/untracked state remains. No push/tag/remote write.

Default staged diff --check reported raw CRLF and an inherited blank EOF;
invocation-local `core.whitespace=cr-at-eol,-blank-at-eof` check passed. Raw
accepted bytes were not normalized. All37staged blobs matched stopped source;
index is empty after commit. Budget deviations in DECISION remain disclosed.

## Exact-commit export attempt

The standard committed exporter invoked commit2154b81 and fresh output
`.artifacts/s29-adapter-output-poc42`. Failed once, exit1, before ZIP generation:

```
Runtime contract identity mismatch.
Expected 538c9bd7db266698c437410543676469c950b431cdc24ddaf03a876b708c5e4d
got c4558f82d56e4ec7e4da484dcd30029ea812e285e7a141ebcb4367907067caba.
```

Production payload admission PASS60 preceded the full release-closure refusal.
Do not relabel admission as PACKAGE_BYTE_CLOSURE/export PASS. Preserve first
failed extracted package and `.artifacts/delivery/s29-adapter/export.log`;
no repair inside that artifact, ZIP, extracted-entry rerun or reference switch.
All37 source SHA256 still match stopped snapshot after failure.

## Attributed missed consumer and proposed scope reassessment

`Tests~/test-codedb-package-release-closure.ps1:269` consumes
`Tests/Editor/OwnerIdentityV2Status.json`. Its checks374/375 require both fixture
runtime hashes to equal payload-manifest raw hash. The fixture remains unchanged
from predecessor41 (SHA256915e919b45fb3f4d46d1638ee87cc608f966dcffd2b3b0bd13e24f1bd8aab907).
It carries5generation fields at lines19/20/21/53/54 and2runtime hashes at23/55.
The mechanical successor route generated the three payload identities but
omitted this existing consumer projection. Coder ValidatePayload and custom
closure checks did not exercise the full standard release closure; independent
source review inherited the frozen narrow map. This is a missed identity-fixture
projection/evidence gate, not product/runtime success or a corrupt export.

Proposed correction is confined to that fixture's five generation and two hash
projections plus the same ignored generator entry's synchronization/assertion.
Read target identity/hash from final manifests; no copied new version constants,
validation weakening, product/schema change, old generation rewrite or new
feature. Extend the focused proof to run the existing full release closure
without RepairCanonicalMetadata before accepting the fixture snapshot; exact
committed export then reuses the same standard gate. Do not rewrite accepted
payload hashes merely to repair fixture metadata or normalize old frozen bytes.

The fixture was outside RETAINED-ADAPTER-OUTPUT-TASK.md's explicit test allowlist.
Parent reassessed that narrow omission against the user's standing authorization
to complete all pre-human prerequisites without repeated questions. This existing
identity projection is a routine required export prerequisite, not a materially
new product action. Parent explicitly freezes the extension in
RETAINED-ADAPTER-IDENTITY-PROJECTION-TASK.md before any source write and informs
User; real operations remain separately gated. Use Coder/stopped-snapshot/Verifier
workflow for original projection finding and adjacent identity assertions only.
No broad old tests/new human session needed for this correction.

Real read-only preflight, retained recovery and S29/Unity/release acceptance
remain pending. S29 manifest still selects s29-retained-path-poc42. Closed-project
reference permission persists unless reopened; no Unity launch, actual runtime
mutation, receipt change, process kill or original candidate cleanup occurred.
