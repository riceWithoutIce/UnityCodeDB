# S13 FIX 03 Attempt 03: Reuse Stable Read Evidence

## Metadata

- Parent contract: `FIX-03.md`
- Previous attempt: `FIX-03-ATTEMPT-02.md`, immutable `BLOCKED`
- Status: `READY_AWAITING_DISPATCH`
- Owner: `v0.3.coder.deep`
- User-confirmed gate: `UnityValidationProject/` is closed

## Frozen Identity

- HEAD: `9aada838e26879810a4f79760273ca66340ebf12`
- `FIX-03.md`: `8155 / 50d8ccf798768b74c1bb1133eb815aa79391cb3c08168c0487b7fe012b64b5`
- `FIX-03-ATTEMPT-02.md`: `5564 / d54c19c963691b910dfe8fb5a001200d8bd8a2a5c8d014483b73c2f8940fd041`
- `RESULT.md`: `42225 / 45532c7d733c430f3c54c8258ee807f5315afd837c280a126cbba4cd1629fe28`
- `codedb-instance-engine.ps1`: `249662 / cd3f95244b406c6010aeb1d2c5bd04736e53ad4c76a0f37d9b33d7ba2b8a48af`
- `test-codedb-host-payload-materializer.ps1`: `733447 / ca874c166e0789439d22decafeecfa777949935e3f6f34adc87708647f462058`

Any drift is a hard stop. Do not reset or repair it.

## Incremental Authorization Contract

Reuse the unchanged engine excerpts successfully captured by Attempt 02. Do not read
the engine, top-level materializer, FIX 03, Attempt 02, or prior RESULT content
again.

Perform one source read only: test file lines `7754-7821`. Measure the emitted
UTF-8 text before output; expected retained size is `10022` bytes and the hard
cap is `12288` bytes. Do not use `rg`, search, full-file read, diff, or
alternate context extraction.

Then execute the already-frozen repair from `FIX-03.md`:

- remove all four `[PRODUCT_LAYER PREREQUISITE]` writers from
  `codedb-instance-engine.ps1`;
- update only the direct prerequisite failure helper and
  `Invoke-MachinePrerequisiteContractScenarios` so current and missing DryRun
  output each prove exactly one marker with the expected value;
- preserve every other marker, exit code, mutation, and control path.

## Writable Surface

- `com.rice.ai-codedb/Tools~/codedb-instance-engine.ps1`
- `com.rice.ai-codedb/Tests~/test-codedb-host-payload-materializer.ps1`
- parent `RESULT.md`, append-only

No other file may change.

## Verification Budget

- One count-only static check; output counts/booleans only, no source lines.
- One invocation of
  `test-codedb-host-payload-materializer.ps1 -PrerequisiteOnly`, maximum `120`
  seconds and `16 KiB` captured output.
- One corrected retry only for command/fixture setup failure before a product
  assertion; any product assertion failure stops.
- One final `git diff --check` scoped to the two changed code/test files.
- No Unity, Unity MCP, BatchMode, C# L1, EditMode, Node L0, other tests,
  runtime/log reads, process operation, commit, push, or Verifier routing.

## Completion

Append `S13 FIX 03 Attempt 03` to `RESULT.md` with identity, actual read bytes,
two-file pre/post identities, count-only result, focused L0 and diff-check
evidence, retry ledger, deferred boundaries, and one status:
`FIXED_READY_FOR_COLD_START`, `BLOCKED`, or `FAILED`.

Stop and notify Planner. Do not open Unity or contact another role.
