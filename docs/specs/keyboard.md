# Keyboard and pointer map

Defined in `Panel.qml` (`handleKey`, `adjust`, and the `BarIconButton`
handlers). Popup keys work only while the popup has focus; nothing here is a
global binding ([ADR 6](../adr/0006-ipc-only-no-global-bindings.md)).

## Bar mark

| Input | Action |
| --- | --- |
| Left click | Open or close the popup. |
| Right click | Toggle mute. |
| Middle click | Reset to 100 % and unlink. |
| Wheel / touchpad scroll | Both channels ±5 % per 120 units of wheel delta (whole volume on mono). |

The tooltip shows the output name and `L x%  R y% · balance`, or `Volume x%`
on mono.

## Popup rows

`Up` / `Down` move a cursor through seven rows (it does not wrap):

| Row | Control | `Left` / `Right` | `Enter` / `Return` / `Space` |
| --- | --- | --- | --- |
| 0 | Output list | Previous / next output | Show or hide the outputs past the first few (more than four outputs only) |
| 1 | Left (Volume on mono) | -5 % / +5 % | - |
| 2 | Right | -5 % / +5 % | - |
| 3 | Balance | 20 % toward left / right | - |
| 4 | Link | - | Toggle link |
| 5 | Mute | - | Toggle mute |
| 6 | Reset | - | Reset |

## Direct keys

| Key | Action |
| --- | --- |
| `k` / `j` | Left +5 % / -5 % (volume on mono) |
| `K` / `J` (`Shift+k` / `Shift+j`) | Right +5 % / -5 % (volume on mono) |
| `h` / `l` | Balance 3 % left / right |
| `Shift+l` | Link / unlink channels (linking averages them) |
| `m` | Mute / unmute |
| `r` | Reset to 100 % and unlink |
| `Tab` / `Shift+Tab` | Next / previous output |
| `q` / `Escape` | Close the popup |

Over the output list, the mouse wheel moves to the previous / next output
(one step per 120 units of wheel delta) and a click selects an output; an
expanded list longer than six rows scrolls with the wheel instead
([ADR 14](../adr/0014-inline-output-list.md)).
