# 4. Clamp levels to 0-150 % and flag over-gain

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `d74d6d7`)

## Context

PipeWire accepts volumes above 1.0. Some quiet sources need a boost, but
software gain above 100 % can clip, and an unbounded slider makes that easy
to do by accident.

## Decision

`Model.MAX_VOLUME` is 1.5. Every read and write goes through
`Model.clampVolume`, which maps non-numbers to 0 and clamps to 0-1.5. The
channel sliders run 0-150 % with ticks at 0/50/100/150 %, and a channel
above 100 % draws its value and slider fill in the theme's urgent
colour. The bar mark is highlighted only for mute or a strong imbalance.

## Consequences

- Boost is available but always visible.
- Volumes set elsewhere above 150 % display as 150 %; the next Volta write
  for that channel stores at most 150 %.
