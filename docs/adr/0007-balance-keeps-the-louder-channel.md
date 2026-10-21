# 7. Balance keeps the louder channel and attenuates the other

- Status: Accepted
- Date: 2026-08-26 (documented from the code; landed in `8391714`)

## Context

A balance control can either redistribute a fixed total between the sides
or keep the loudest side and attenuate the other. Redistributing changes
the perceived level as the knob moves and can push a side above 100 %.

## Decision

`Model.balance` is `(right - left) / max(left, right)`, from -1 (all left)
to 1 (all right). `Model.applyBalance` keeps the peak level on the favoured
side and sets the other to `peak * (1 - |b|)`. With both channels at 0,
balance is 0 and stays 0.

## Consequences

- Moving balance never raises the louder channel, so it never adds gain.
- Balance cannot recover a silent pair; raise the level first.
- "Center" is shown within 0.5 % of zero.
