# Volta for Omarchy

Volta is an Omarchy shell plugin for independent left/right output volume and stereo balance control.

> This repository currently contains the initial plugin scaffold. Audio controls are planned but not implemented yet.

## Requirements

- Omarchy 4.0+
- The Omarchy Quickshell shell
- PipeWire

## Install

Once this repository is published:

```bash
omarchy plugin add https://github.com/mateuspim/omarchy-volta.git --enable
```

For local development, place or clone the repository at:

```text
~/.config/omarchy/plugins/pym.volta/
```

Then validate and reload it:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/pym.volta
omarchy-shell shell rescanPlugins
omarchy plugin enable pym.volta
```

Plugin files hot-reload when edited inside the user plugin directory.

## Direction

The first functional milestone will provide:

- Left and right channel volume sliders
- A stereo balance control
- Mute and reset actions
- Output sink selection
- A compact bar indicator and native themed popup

See [AGENTS.md](AGENTS.md) for the working implementation plan and project constraints.

## License

MIT
