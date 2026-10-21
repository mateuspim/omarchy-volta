# 9. Share one audio model across bar instances

- Status: Accepted
- Date: 2026-08-26 (documented from the code; landed in `2093f3d`, `584a49e`)

## Context

Omarchy creates a bar widget per monitor. With a model per widget, each
monitor ran its own resolver and availability timers and could hold its
own link state, so two bars could disagree.

## Decision

`AudioService.qml` is a `pragma Singleton` (declared in `qmldir`) that owns
one `AudioModel { optionsActive: true }` and the IPC handler. Every
`Panel.qml` reads `Volta.AudioService.audio`. Each popup snapshots
`sinkOptions` when it opens and refreshes it 75 ms after changes, so a
hotplug does not rebuild the dropdown under the cursor.

## Consequences

- One set of timers and helper processes regardless of monitor count.
- Link state and errors are the same on every monitor.
