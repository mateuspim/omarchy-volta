# IPC actions

Volta registers one Quickshell IPC target, `pym.volta-control`, in
`AudioService.qml`. It is the only way to control Volta while the popup is
closed; Volta installs no compositor bindings ([ADR 6](../adr/0006-ipc-only-no-global-bindings.md)).

```sh
omarchy-shell pym.volta-control <action>
```

Every action takes no arguments, returns nothing, and acts on the current
output (the sink resolved by `omarchy-audio-output-sink`, see
[ADR 2](../adr/0002-follow-omarchy-sink-helpers.md)).

| Action | Effect | On mono or unsupported outputs |
| --- | --- | --- |
| `mute` | Toggle mute. | Works. |
| `reset` | Unlink, set both channels to 100 %. | Mono: whole volume to 100 %. Unsupported: error. |
| `lock` | Link channels: set both to their average and keep them equal. When already linked, unlink without changing levels. | Error. |
| `leftUp` / `leftDown` | Left channel +5 % / -5 % (both when linked). | Error. |
| `rightUp` / `rightDown` | Right channel +5 % / -5 % (both when linked). | Error. |
| `balanceLeft` / `balanceRight` | Shift balance 3 % toward that side, keeping the louder channel's level ([ADR 7](../adr/0007-balance-keeps-the-louder-channel.md)). | Error. |
| `previousSink` / `nextSink` | Make the previous / next available output the default, wrapping around. | Works; no-op with fewer than two outputs. |

"Error" means the write is refused and the reason shows in the popup the next
time it is open. Levels are clamped to 0-150 %
([ADR 4](../adr/0004-clamp-to-150-percent-with-warning.md)).

Example bindings for `~/.config/hypr/bindings.lua` (Omarchy 4's Lua
config; add them yourself. The keys are suggestions that Omarchy's defaults
did not use when this was written):

```lua
o.bind("SUPER + CTRL + ALT + comma", "Volta balance left", "omarchy-shell pym.volta-control balanceLeft")
o.bind("SUPER + CTRL + ALT + PERIOD", "Volta balance right", "omarchy-shell pym.volta-control balanceRight")
o.bind("SUPER + CTRL + ALT + SLASH", "Volta next output", "omarchy-shell pym.volta-control nextSink")
```

Renaming or removing an action is a breaking change: note it in the
CHANGELOG and the README.
