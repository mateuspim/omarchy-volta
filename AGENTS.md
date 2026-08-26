# Volta for Omarchy: Agent Guide

## Mission

Build a native Omarchy shell plugin that makes independent left/right output volume and stereo balance easy to inspect and control. Preserve Volta's focused identity; do not grow it into a general-purpose audio mixer unless the project direction explicitly changes.

## Environment and safety

- Target Omarchy 4.0+ and its long-running Quickshell-based `omarchy-shell`.
- Treat `/usr/share/omarchy/` as read-only reference material. Never edit packaged Omarchy files.
- Third-party plugin installs belong at `~/.config/omarchy/plugins/pym.volta/`.
- The plugin must remain installable with `omarchy plugin add <git-url> --enable`.
- Validate the repository root with `omarchy plugin validate .` before committing manifest or entry-point changes.
- Plugin code runs unsandboxed inside `omarchy-shell`; keep subprocess calls minimal, explicit, and safely quoted.
- Prefer native Quickshell and PipeWire APIs. Add an external helper only when channel-level operations cannot be implemented reliably through the installed API.
- Follow the local Omarchy skill instructions when changing a user's Omarchy configuration.

## Installed references

Use these packaged sources to follow current conventions:

- `/usr/share/omarchy/shell/README.md`
- `/usr/share/omarchy/shell/plugins/README.md`
- `/usr/share/omarchy/shell/plugins/bar/README.md`
- `/usr/share/omarchy/shell/plugins/panels/audio/`
- `/usr/share/omarchy/shell/Ui/Panel.qml`
- `/usr/share/omarchy/shell/Ui/PanelSlider.qml`
- `/usr/share/omarchy/shell/Ui/PopupCard.qml`

## Architecture direction

The plugin root is the distributable repository. `manifest.json` declares `pym.volta` as a single `bar-widget`, and `Panel.qml` is its entry point.

Keep responsibilities separated as the implementation grows:

```text
manifest.json      Plugin identity, entry point, and settings schema
Panel.qml          Bar representation, popup composition, and interaction
AudioModel.qml     Reactive sink/channel state and control operations
Model.js           Pure formatting, clamping, and balance calculations
tests/             Pure JavaScript tests and backend fixtures
assets/            Project-owned images only when QML-native visuals are insufficient
```

Do not copy the complete built-in `omarchy.audio` plugin. Reuse Omarchy's public `qs.Ui` and `qs.Commons` components and implement only Volta's distinct channel-control experience.

## Implementation plan

### 1. Prove the audio contract

- Inspect the installed Quickshell PipeWire API for channel volume access and mutation.
- Test stereo, mono, Bluetooth, HDMI, virtual/DSP, disconnected, and no-sink states where available.
- Record the decision in the README: native PipeWire API, `wpctl`/`pactl`, or a narrowly scoped helper.
- Do not build the full UI until channel reads and writes are demonstrated end to end.

### 2. Build the reactive model

- Track the effective default physical output, including Omarchy speaker-tuning/DSP routing behavior.
- Expose left volume, right volume, balance, mute, active sink, and available sinks.
- Clamp output to 0–150%, with a clearly indicated over-gain region above 100%.
- Surface backend failures instead of leaving optimistic UI state stale.
- React to device, default-sink, external-volume, and channel-map changes.

### 3. Implement the Volta interaction

- Compact themed bar icon with mute and imbalance states.
- Native popup with separate L/R sliders and a centered balance control.
- Lock/unlock channels, mute, reset to 100%, and sink selection.
- Keyboard navigation consistent with Omarchy panels; preserve useful Volta shortcuts where they do not conflict.
- Support horizontal and vertical bars, narrow displays, mouse, wheel, touchpad, and keyboard interaction.

### 4. Harden and release

- Add pure tests for balance math, clamping, channel parsing, and formatting.
- Test plugin validation, hot reload, shell restart, multi-monitor mounting, and removal/fallback.
- Document local development, installation, update, removal, limitations, and troubleshooting.
- Add `LICENSE`, screenshots, changelog, and tagged releases.
- Verify installation from the public repository with `omarchy plugin add` before declaring the first stable release.

## Definition of done for the first functional milestone

- Plugin installs and enables without editing packaged Omarchy files.
- Current stereo channel levels appear correctly.
- Either channel and balance can be changed and remain synchronized with PipeWire.
- Mute, reset, sink changes, and external changes update the UI correctly.
- Backend errors are visible and recoverable.
- The popup follows the active Omarchy theme and works on horizontal and vertical bars.
- Validation and automated tests pass.

## Commit discipline

- Keep commits small and outcome-oriented.
- Do not commit local `shell.json`, generated caches, installed plugin copies, or machine-specific audio identifiers.
- Update this plan when an architectural decision materially changes the remaining work.
