# 10. Verify writes and show when PipeWire does not keep them

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `d74d6d7`, `d3508e2`)

## Context

A write to PipeWire can be ignored or rewritten by WirePlumber policy,
another client, or a device that disappears mid-change. An optimistic UI
would show values the hardware is not using.

## Decision

Every level write records the expected values and the sink, then checks
800 ms later. If the sink changed, the check is dropped. If the levels
differ by more than 1.5 %, Volta shows "PipeWire did not keep the
requested channel levels; another audio policy may be overriding them."
(or the mono equivalent). Control, verification and resolver errors are
kept separately and shown one at a time, control first, and each clears
when its own operation next succeeds. Changing sink clears link state and
control errors.

## Consequences

- The UI always reflects PipeWire's state, with a reason when it differs
  from what the user asked for.
- Fast slider drags may briefly show a stale verification error; the next
  write clears it.
