# 1. Use Quickshell's native PipeWire API for levels and mute

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `d74d6d7`)

## Context

Volta needs to read and write the left and right channel of the current
output, follow external changes (keyboard volume keys, other mixers,
hotplug) and do it from a shell that runs for the whole session. The
options were polling `wpctl`/`pactl`, a small helper daemon, or the
`Quickshell.Services.Pipewire` module that `omarchy-shell` already loads.
Polling spawns a process per refresh and per slider step and still lags
behind external changes; a daemon is one more thing to install and keep
running.

## Decision

`AudioModel.qml` reads `Pipewire.defaultAudioSink`, `Pipewire.nodes`, and
each node's `audio.channels`, `audio.volumes`, `audio.volume` and
`audio.muted`. Writes assign `sink.audio.volumes` (both channels in one
array, other channels untouched), `sink.audio.volume` (mono) or
`sink.audio.muted`. A `PwObjectTracker` keeps the candidate sinks bound so
their audio properties stay live. Pure channel math lives in `Model.js`.

## Consequences

- Levels update reactively with no polling and no process per change.
- Channel names come from `PwAudioChannel.toString`, so `Model.js` accepts
  both `FrontLeft` and `PwAudioChannel.FrontLeft` forms and short `FL`/`FR`.
- Anything the API cannot express would need a narrowly scoped helper; none
  is needed today. The remaining processes are Omarchy's own sink helpers
  (ADR 2).
