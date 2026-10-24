# Result: cdb-v0.3-p0-s31b-provider-readiness-prerequisite

## Disposition

- Status: `ENVIRONMENT_INCOMPLETE / BLOCKED`
- Evidence class: read-only Provider readiness prerequisite review
- Product source changed: no
- Provider launched: no
- Network or machine installation: no
- S31-B Install/Uninstall rerun: no

## Stage A/B findings

The R4 production-equivalent route generated a project-local runtime config
whose `[embedding].model` points to:

```text
AIWork/.runtime/codedb/<instance>/models/potion-code-16M
```

The R4 child-local fixture has no such model directory. The child-local
Provider copy contains only the pinned executable, provider manifest and
third-party notices. The known machine Provider stores also contain only those
three installation files; no model asset was found there.

The pinned Provider binary contains static diagnostics for a configured local
embedding model path, Model2Vec loading, missing vocab/merges and a model path
that does not exist. The coordinator separately requires the Provider's
`initialize` and `tools/list` handshake before readiness. These facts support
the missing-model hypothesis, but no preserved Provider stderr proves it was
the exact R4 failure cause.

The production runtime preparation path creates project-local config, index,
logs and temporary roots and renders the config template. It has no current
source, copy, download or hash step for `potion-code-16M`. The Provider
installation contract intentionally installs only the executable and manifest
side of the machine dependency. Model ownership is therefore unresolved.

## Boundary decision

This is an environment-closure gap, not a confirmed uninstall defect. The
task must stop here under the isolation specification. S31-B remains
`PARTIAL / BLOCKED — NOT ACCEPTED`; its native stop, deactivation, terminal
reader and repeat no-op cases remain unrun.

No model may be fabricated, silently downloaded, copied from an unknown cache,
or used to relax the production guards. No unchanged-environment retry is
authorized.

## Next action

A later user grant must identify an authorized model source, ownership,
provenance/license and expected SHA-256 before any child-local staging. After
that closure is frozen, one bounded readiness observation may be authorized.
Without that source, defer this prerequisite task and keep S31-B blocked.

## Bounded cache follow-up — 2026-10-16

The permitted read-only follow-up inspected the conventional local
HuggingFace/Model2Vec cache roots and the machine CodeDB root. The conventional
model cache roots were absent; the machine CodeDB root contained only
`providers` and `manager-actions`, with no model or embedding cache. A
repository search found only the repeated runtime-template reference and no
download, copy, or model-preparation implementation.

This bounded check found no newly attributable source. The stop condition is
unchanged: no broader filesystem search, network acquisition, or unchanged
readiness retry is authorized.

## Upstream source identification — 2026-10-16

A read-only static inspection of the pinned Provider binary exposed its
Hugging Face model identifier and cache conventions:

```text
minishlab/potion-code-16M
https://huggingface.co
```

The same strings reference Hugging Face cache snapshots and a
`codedb-mcp-cache/models/potion-code-16M` fallback. This identifies the
upstream model owner and repository, but it is not yet an authorized local
artifact, and the current Package contract does not pin a model archive or
directory SHA-256. No network request or download was performed.

The task remains `SOURCE_REQUIRED`: a user-provided local model directory or
archive must still be inspected, with a deterministic per-file manifest and
manifest SHA-256 recorded before child-local staging.
