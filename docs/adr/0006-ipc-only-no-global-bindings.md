# 6. Expose actions through IPC; install no global bindings

- Status: Accepted
- Date: 2026-08-25 (documented from the code; landed in `301949e`)

## Context

Users want to nudge balance or switch outputs without opening the popup,
but keyboard shortcuts are personal and Hyprland bindings live in the
user's own config. A plugin that writes compositor bindings on load would
change configuration outside its own files.

## Decision

`AudioService.qml` registers the IPC target `pym.volta-control` with
eleven actions (`mute`, `reset`, `lock`, `leftUp`, `leftDown`, `rightUp`,
`rightDown`, `balanceLeft`, `balanceRight`, `previousSink`, `nextSink`).
Volta adds no Hyprland bindings; the README shows how to bind them by hand.
The popup's own keys only work while it has focus. `Panel.qml` sets
`manageIpc: false`, so Volta registers no open/close IPC of its own.

## Consequences

- Nothing outside Volta's files changes on install or load.
- Users who want global keys add one line per action to their Hyprland
  config. The action list is a public contract
  ([specs/ipc.md](../specs/ipc.md)).
