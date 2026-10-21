# 2. Follow Omarchy's audio helpers for the real output and the default sink

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `d74d6d7`, `83d1357`)

## Context

Omarchy can put a DSP sink (speaker tuning filter-chain, EasyEffects) in
front of the speakers. The PipeWire default is then the virtual sink, but
loudness lives on the physical sink it feeds; changing the virtual sink's
level only changes what goes into the processing. Omarchy also hides the
physical sink behind a tuning from output lists, and moves application
streams when the default changes. Reimplementing those rules in Volta
would drift from the system audio panel.

## Decision

Volta runs Omarchy's helpers instead of its own logic:

- `omarchy-audio-output-sink` resolves the sink whose volume really
  matters. It runs on start, whenever the default sink changes, 250 ms after
  Volta switches output, and every 15 s. Only the newest request's result is
  applied (a generation counter discards stale ones). If it fails, Volta
  uses the PipeWire default and shows "Could not resolve the physical
  output; using the PipeWire default."
- `omarchy-audio-sink-availability` marks sinks as available or not; it
  runs every 5 s and on default-sink changes, and unavailable sinks (except
  the current default) leave the output list.
- `omarchy-audio-output-set-default <id> <name>` switches the default and
  moves application streams, after Volta sets
  `Pipewire.preferredDefaultAudioSink`.

## Consequences

- Volta and Omarchy's audio panel agree on which device is "the output".
- Volta depends on those three commands existing in `PATH` (Omarchy 4.0+).
- The helpers run as short-lived processes on timers; keep their intervals
  coarse.
