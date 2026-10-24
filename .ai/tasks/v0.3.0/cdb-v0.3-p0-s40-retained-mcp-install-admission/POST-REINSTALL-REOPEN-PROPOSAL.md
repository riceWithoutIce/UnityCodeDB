# Proposed next gate: ordinary reopen after reinstall

Date: 2026-10-22. Status: PREPARED / HUMAN ACTION NOT STARTED BY THIS PROPOSAL.

## Why this next step

The original S39 lifecycle supplement explicitly included installed-state
reopen, logical Uninstall, same-version Install and post-reinstall reopen.
The first two passed on c848049. Its Install stopped, preserving that failure.
S40 repaired the bounded cause and delivered 186aacf. The subsequent human
Install terminal/new selection and new target-chat status/query passed.
The final post-reinstall reopen is not yet reported for this new activation.

This is the next narrow proposed supplement to the agreed basic-use-flow
preview work, not a repeat of passed client calls or a full-runtime acceptance.
Do not promote earlier-candidate lifecycle evidence into exact 186aacf evidence.

## Concrete bounded human procedure

User action: keep the same CodedbTest_2 and delivered 186aacf Package. Normally
close Unity once and reopen the same project once, then open CodeDB Manager.
Keep Codex clients and existing configurations as they are. Do not click
Install/Uninstall, remove the Package, force-stop processes or reset runtime.

Visible result: after normal import/compile/observation settles, Manager
returns Ready without a persistent Console error or demand to reinstall.
Report final state and any errors. A transient Unconfirmed state that returns
to Ready is recorded separately and does not itself fail the ordinary-reopen
gate. Use the existing proposed ten-minute nonconvergence ceiling; stop at
failure or nonconvergence without another close/reopen or repair.

Technical evidence (separate from the user procedure): before the human action,
the development chat may capture one bounded read-only baseline for the Package
reference and selected instance/epoch. After the human report it may capture
one bounded read-only snapshot of those bindings and the existing attributable
operational-readiness record. Expected instance is
`a492a5e936c14e4da3ed7e4cc7c8c16c`, epoch
`063aa347f49a4b9f955a5447f293a0ac`, generation `poc.44`. A new independently
written readiness observation must be distinguished from cached display.
Do not poll, manually launch a probe or issue CodeDB status/query calls.
If readiness evidence is absent or stale, report that limit rather than
injecting a new operation to make this gate pass.

## Result and stopping boundary

A passing result establishes one ordinary reopen after the observed reinstall.
It does not complete response/session identity, pre-Install live-old-reader
coverage, physical cleanup, multiple real lifecycle cycles, PS7 compatibility,
Unconfirmed cause analysis, Domain Reload identity, performance or release.

After this small gate, consolidate exact-candidate evidence and remaining
preview/release decisions. Do not automatically activate those deferred tasks
or the full Discover Read roadmap. Preserve the Ready project and all existing
source, artifact and failed-attempt evidence.

This proposal performs no Unity, runtime, query, lifecycle, configuration,
source integration, delivery or cleanup operation. It prepares the next human
step for alignment; no new acceptance result is asserted.
