# 12. Render previews offscreen with a fake audio model

- Status: Accepted
- Date: 2026-10-21 (`ddfd807`)

## Context

The first README image was a desktop screenshot. It showed a real headphone
model and could only be reproduced on the author's machine. Screenshots of
the live desktop can also capture unrelated windows, and test popups can
steal keyboard focus.

## Decision

`tests/preview.sh` builds a throwaway Quickshell config: `Commons` and `Ui`
linked from `/usr/share/omarchy/shell`, `KeyboardPanel` replaced by an Item
stand-in, a copy of the plugin with `tests/offscreen/AudioModel.qml`
(sample outputs, no PipeWire import) in place of the real model, and a
sample theme with Volta's amber accent. It runs with
`QT_QPA_PLATFORM=offscreen`, a throwaway `HOME` and `XDG_RUNTIME_DIR`, and
`tests/Preview.qml` saves one PNG per scene with `grabToImage`.

## Consequences

- README captures are private, repeatable and use sample names.
- The software renderer skips `MultiEffect`, so captures show the mark's
  untinted source image.
- The fake model must keep the real model's public surface; when
  `AudioModel.qml` gains a property the popup reads, add it to the fake.
