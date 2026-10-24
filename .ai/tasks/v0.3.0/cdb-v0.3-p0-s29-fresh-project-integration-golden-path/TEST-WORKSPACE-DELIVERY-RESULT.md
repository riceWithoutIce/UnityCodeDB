# S29 test workspace - accepted delivery

Date: 2026-10-08. SOURCE_ACCEPTED / COMMIT_EXPORT_PASS /
HUMAN_COMPILE_TEST_PENDING / S29_PARTIAL.

Commit332c7ffd510daebb6da6a386d66783d4aabf6bd6:
test(editor): own S29 fixture workspace lifecycle.
Exactly14 paths per DELIVERY-PLAN: four accepted test/metadata files, canonical
workspace contract, three scoped document additions and six task/evidence records.
Initial index empty; accepted raw identities, staged exact path/byte checks and
diff-check PASS. Postcommit index empty. No production Editor/Payload change.
Inherited dirty docs and other worktree contents preserved. Workflow commit uses
a dedicated ownership section instead of importing unrelated uncommitted changes.
No blanket staging, reset/clean, amend, push/tag/publication or remote updates.

## Export evidence

Fresh .artifacts/0.3.0-preview.5-s29-test-workspace-poc40, exact commit above.
Package review/com.rice.ai-codedb/package.json, version0.3.0-preview.5/poc.40.
Unchanged committed exporter invoked once after absent-destination/non-reparse
ancestor checks. Both commit-staged and exact-ZIP closure PASS:52 sources/0
mismatches. Four accepted test/metadata hashes match TEST-WORKSPACE-REPAIR-RESULT;
four scoped committed doc hashes also match extraction:

- test-workspace-contract.md: AAFC5CF3A7AB79E832D794A5A7F00869993D017AB74F4FCE6E48E23A655FB4F3
- development-workflow.md: 8B26C9EB0041696060F7767A347612905B47903F8DBA5C2EF5E28F26647CB18D
- index.md: 0B1DB969B3943F07EE9701C6EF486479DB5A14F99EC7E2031E22B1CDC356F606
- v0.3.0-p0-host-action-execution.md: 5C5F301EE61FBD4355DEB9361685CF015010AC8F1DBD742B9856BF073C1E3E16

ZIP:2,402,784 bytes,516 entries. Extracted516 files/10,721,539 bytes.
SHA256:6890f7b5a642294f69a5a0fdc4612a8646114dd89a903e29126f7cc1f4a1b728.
Unchanged generation manifest hash:
d427ffa383c7de5203637ca16cee5a1480e470c812d30fa523f332d7385d92d3.
Byte closure does not prove C# compilation or fixture behavior.

## Human state and reference switch

Initially human said Unity remained open; no references changed at that point.
Human subsequently confirmed manual closure in the same turn. After export/hash
PASS, only CodeDB references in S29 manifest.json/packages-lock.json changed from
manager-receipts-poc40 to test-workspace-poc40/review/com.rice.ai-codedb.
Both JSON parse; normalized hashes prove all other text unchanged:
manifest ED4F4DA3C47659A4A954CE707D8D1E98FC1FF5A7302E47E34939EA8AA0B7E192;
lock 1F3F89C6DB4AB5314D377F036028E38AE6FABB677523B345276106F72E936A45.
Old artifacts, real candidate/receipts, environment/ACLs/system temp untouched.

TEST-WORKSPACE-HUMAN-CHECKLIST.md defines4 groups: workspace9, context3, receipts38,
shared session12 =62 cases/24 methods, all NOT RUN. Compile + tests + observation
next; no actual mutation buttons. No Unity/MCP/CUA/BatchMode or process probes,
real Install/Remove/replay, cleanup or previous48/11/201 batch performed.
F-IMC-01/P3 and real S29 integration/release remain DEFERRED/PARTIAL.
Delivery docs/TASK/local references remain uncommitted, with no source amend.
