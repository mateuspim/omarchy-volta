# Volta for Omarchy

Volta is a focused Omarchy shell plugin for independent left/right output volume and stereo balance control. It provides a compact bar indicator and a theme-native popup without becoming a general-purpose mixer.

The bar mark is adapted from the original [Volta logo](https://github.com/mateuspim/volta/blob/master/assets/logo.png), simplified for legibility at status-bar size and colorized to the active Omarchy theme.

## Requirements

- Omarchy 4.0+
- The Omarchy Quickshell shell
- PipeWire
- A stereo output exposing `FrontLeft` and `FrontRight` channels

## Install

From the public repository:

```bash
omarchy plugin add https://github.com/mateuspim/omarchy-volta.git --enable
```

The plugin is installed disabled unless `--enable` is supplied. Remove it with:

```bash
omarchy plugin remove pym.volta
```

## Controls

- Left click opens the popup; right click toggles mute; middle click resets both channels to 100%.
- Wheel over the bar icon changes both channels by 5%.
- The popup provides L/R sliders, balance, linked/independent mode, mute, reset, and output selection.
- Values above 100% (up to 150%) use the urgent theme color as an over-gain warning.
- The original TUI controls are preserved: J/K changes the left channel by 5%, Shift+J/K changes the right, H/L shifts balance by 3%, Left/Right or Tab/Shift+Tab cycles outputs, Shift+L locks channels at equal volume, M toggles mute, R resets and unlocks, and Q closes. C is a convenient alias for linking. Up/Down remains available for visual control navigation.

Locking averages the current channels and keeps L equal to R while either slider moves. Dragging the balance control preserves the louder channel and attenuates the other side.

The same actions are available for compositor or script keybindings through `omarchy-shell pym.volta-control`: `mute`, `leftUp`, `leftDown`, `rightUp`, `rightDown`, `balanceLeft`, `balanceRight`, `lock`, `reset`, `previousSink`, and `nextSink`.

## Backend decision

Volta uses the installed Quickshell PipeWire API directly. `PwNode.audio.channels` provides the reactive channel map and writable `PwNode.audio.volumes` provides end-to-end per-channel reads and mutations. Mute and default-node tracking are native as well, so no volume command is spawned and external PipeWire changes update the UI through QML property notifications.

Two Omarchy helpers are intentionally retained:

- `omarchy-audio-output-sink` resolves the effective physical output behind Omarchy speaker tuning or another DSP sink.
- `omarchy-audio-output-set-default` applies output selection consistently with Omarchy and WirePlumber.

This is smaller and safer than parsing `pactl` output continuously, while matching the built-in audio panel's DSP routing behavior.

## Development

For a local development copy, link the repository only into the user plugin directory:

```bash
ln -s /path/to/omarchy-volta ~/.config/omarchy/plugins/pym.volta
```

Do not place development files under `/usr/share/omarchy`. Validate, test, rescan, and enable with:

```bash
npm test
omarchy plugin validate .
omarchy-shell shell rescanPlugins
omarchy plugin enable pym.volta
```

Plugin files hot-reload when edited inside the user plugin directory.

## Limitations

- Mono outputs and unusual channel maps remain visible and support mute/output selection, but independent sliders are disabled with an explanation.
- Volta controls the front-left/front-right pair on surround devices and leaves every other channel unchanged.
- Bluetooth profiles that expose stereo work; hands-free/mono profiles do not provide independent L/R control.
- PipeWire node labels depend on metadata made available by the active session manager.
- A limiter or hardware device may make 100–150% sound no louder even though PipeWire accepts the value.

## Troubleshooting

- **No output:** confirm PipeWire/WirePlumber is running with `wpctl status`, then restart the shell with `omarchy restart shell`.
- **Stereo controls disabled:** inspect the selected sink's channel map. Mono and channel maps without `FrontLeft`/`FrontRight` are intentionally rejected.
- **Wrong device behind DSP:** run `omarchy-audio-output-sink`; Volta falls back to PipeWire's default and shows an error if resolution fails.
- **Plugin not visible:** run `omarchy plugin validate .`, `omarchy-shell shell rescanPlugins`, and `omarchy plugin enable pym.volta`.
- **A write does not stick:** another audio policy or application may be replacing the value. Volta reflects the resulting PipeWire state instead of keeping stale optimistic UI state.

## Verification status

Pure model tests cover clamping, formatting, channel-map parsing, stereo mutation, and balance math using stereo, mono, and surround fixtures. Plugin validation checks the manifest and entry point. Device behavior should be exercised after installation with stereo, mono/Bluetooth, HDMI, virtual/DSP, disconnected, and no-sink states; unavailable hardware is not simulated by the plugin.

## License

MIT
