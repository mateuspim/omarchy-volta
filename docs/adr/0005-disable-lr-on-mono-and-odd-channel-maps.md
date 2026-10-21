# 5. Disable independent L/R on mono and odd channel maps

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `d74d6d7`, `88cb944`)

## Context

Not every sink has a front-left and front-right channel. Mono devices
expose one `Mono` (or `FrontCenter`) channel; some sinks expose only rear
or auxiliary channels. Guessing which channel is "left" would write the
wrong speakers.

## Decision

`Model.readStereo` finds `FrontLeft`/`FL` and `FrontRight`/`FR` by name,
in any order and alongside other channels (5.1 sinks work; only the two
front channels change). Without both:

- Mono (`Mono` or `FrontCenter`): the popup shows a single VOLUME slider and
  a note; wheel, `j`/`k`, `J`/`K` and reset change the whole sink volume.
- No usable map: L/R, balance and link are disabled with "This output does
  not expose front-left and front-right channels." Writes are refused with
  a visible error.

Mute, reset (mono) and output choice stay available in both cases.

## Consequences

- Volta never writes to a channel it cannot name.
- Surround sinks get stereo control of the front pair only.
