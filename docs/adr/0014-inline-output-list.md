# 14. Pick outputs from an inline list with device icons

- Status: Accepted
- Date: 2026-10-21

## Context

After [ADR 13](0013-stereo-stage-popup.md) the output picker was still a
`Dropdown` between two arrow buttons. It showed one name at a time, said
nothing about what each output is, needed a separate "output N of M" line
in the header, and opened a list over the popup to choose. Choosing an
output is one of Volta's three jobs.

## Decision

- Show outputs as an `OutputList`: one row per output with a device icon,
  the name, a subtitle with the connection and a "mono" / "no stereo" note,
  and an accent bar, check and selected surface on the default. Clicking a
  row calls `selectSinkId`, so the default changes through Omarchy's sink
  helpers exactly as before ([ADR 2](0002-follow-omarchy-sink-helpers.md)).
- Classify in `Model.js`: `sinkConnection` (Bluetooth, DisplayPort, HDMI,
  USB, Built-in, Virtual) and `sinkKind` (headphones, display, speakers,
  bluetooth, usb, generic) from `device.api`, `device.bus`,
  `device.form-factor`, `device.icon-name`, the profile and the node name.
  Properties are read only once a node is bound (`node.ready`), as Omarchy's
  audio panel does; the model already tracks every candidate sink.
- Show four outputs or fewer inline. Above four, show a three-row window
  around the default in list order plus "+N more"; expanded, the list
  scrolls past six rows (`visibleOutputs`).
- Keep the list one keyboard row: Left/Right and Tab/Shift+Tab cycle,
  Enter expands or collapses. The wheel over the list cycles outputs.
- The header says "Stereo output" or "Mono output"; the list shows position.
- Rows render labels as plain text, so `plainSinkLabel` bounds the label
  without the escaping [ADR 8](0008-escape-sink-labels.md) applies to text
  that reaches rich-text widgets (the bar tooltip still uses `sinkLabel`).
- The popup snapshot from [ADR 9](0009-one-shared-audio-model.md) now
  copies `sinkEntries` instead of `sinkOptions`, with the same 75 ms delay.

## Consequences

- Outputs are scannable and recognisable without opening anything.
- The popup is taller by up to four rows; very long lists stay bounded.
- A node whose properties are not bound yet shows no subtitle and a generic
  icon until they arrive.
- Classification is heuristic; unusual devices fall back to the generic
  icon. New rules belong in `sinkKind` / `sinkConnection` with a test.
