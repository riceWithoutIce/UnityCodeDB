# S29 test runtime adaptation - delivered

2026-10-08. SOURCE_ACCEPTED / COMMIT_EXPORT_PASS / HUMAN_COMPILE_DISCOVERY_TEST_PENDING.
Commit3b09859045d0d4547d9ba2cef332a550e8530f99:
`test(editor): adapt legacy receipt paths and async Unity test entries`.
Exactly11paths per DELIVERY-PLAN. Nine accepted source/script hashes matched;
only three tests changed. Raw reviewed source bytes preserved. Workflow staged
only current adaptation paragraph over HEAD, preserving inherited worktree edits.
Exact staged set/blob checks and diff-check PASS; index empty before/after commit.
No amend, push/tag/publication, reset/clean or remote update.

Fresh .artifacts/s29-test-runtime-poc40 exported once from exact commit with unchanged
exporter. Commit-staged and exact-ZIP extracted closure both PASS52sources/0mismatches.
All nine reviewed source/script hashes match source and extraction; three committed
document blobs match extraction. No C# behavioral harness exists outside human
Unity; no synthetic compiler substitute or unchanged PS writer/parser rerun.

- Package review/com.rice.ai-codedb/package.json;0.3.0-preview.5/poc.40 unchanged.
- ZIP com.rice.ai-codedb.zip:2,419,079bytes/517entries.
- ZIP SHA256:e85849b660a065966205cebe2a40d550dd66631c19bc7530e0dcc9e32b63df79.
- Extracted517files/10,791,849bytes.
- Generation manifest SHA256:d427ffa383c7de5203637ca16cee5a1480e470c812d30fa523f332d7385d92d3.

User confirmed S29 Unity normally closed before switching. After byte gates PASS,
only CodeDB reference in manifest/lock changed to this review Package. JSON parse
and exact reference PASS; full reference-normalized before/after hashes match:
- manifest:4AAA6ACC8BE49754617B2F0F53E34A748881221544E0503DE2D3651AC4F39300.
- lock:81920D91CE6BC6961578D971D4F2F94E107648C19097573E7A71BA1C9ED46899.
Thus every other character in both files is unchanged. No old artifact/root cleanup,
real candidate/journal edit, actual Install/Remove/Configure/replay or Unity control.

TEST-RUNTIME-ADAPTATION-HUMAN-CHECKLIST.md consolidates39methods/88cases plus compile,
runner discovery and Manager observations into one opening. All human checks NOT RUN.
S29 remains PARTIAL; source acceptance and byte closure do not erase previous human
failures or prove the new Unity filesystem/async behavior. Delivery records and
project refs remain uncommitted without source amend.
