# 3. Stay a focused stereo control, not a general mixer

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `c5a5952`)

## Context

Omarchy already ships an audio panel with per-application streams, inputs
and device selection. What it lacks is a quick view of the left and right
channel and a balance control. A second general-purpose mixer would
duplicate it and make Volta harder to keep small and correct.

## Decision

Volta controls one thing: the current output's front-left and front-right
levels, the balance between them, linking, mute, reset to 100 %, and which
output is the default. It has no per-app streams, inputs, EQ, profiles or
settings.

## Consequences

- The popup fits in one card and every control has a key.
- Requests for mixer features are out of scope unless the project direction
  changes; record that change as a new ADR.
