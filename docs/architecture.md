# Architecture

Volta is one Omarchy `bar-widget` made of a few flat source files at the
plugin root. There is no daemon and no settings file.

```text
manifest.json     identity, the bar-widget entry point, empty settings schema
qmldir            every sibling QML type (a qmldir hides unlisted files)
Panel.qml         bar button, tooltip, popup layout and all input handling
StereoStage.qml   popup stage: L/R readouts over the mirrored segment meter
LevelSlider.qml   one popup row: label, keycaps, value, slider with zones
KeyHints.qml      a shortcut as keycaps plus a short label
KeyCap.qml        one key drawn as a keycap
VoltaMark.qml     the PNG mark recoloured to the theme
AudioService.qml  the one shared AudioModel + IPC target pym.volta-control
AudioModel.qml    PipeWire state, Omarchy helper processes, writes, errors
Model.js          pure maths and text: clamp, channel maps, balance, labels
assets/           volta-bar-icon.png, the mark drawn in the bar and popup
tests/            Node tests, channel fixtures, offscreen preview harness
```

## Components

**`Panel.qml`** extends Omarchy's `qs.Ui` `Panel`. It draws a
`BarIconButton` whose icon is `VoltaMark` (the PNG mark recoloured with
`MultiEffect` to the bar foreground, or the active colour when the popup is
open, the output is muted or balance is off-centre by 12 % or more). The
popup is a `KeyboardPanel` with a `PanelHero` header (state pill and output
position), an output `Dropdown` with previous/next buttons, a `StereoStage`,
`LevelSlider` rows for left and right (or volume on mono, 0-150 %) and
balance (-100 % to +100 %), Link / Mute / Reset toggles and a `KeyHints`
footer ([ADR 13](adr/0013-stereo-stage-popup.md)). `LevelSlider` keeps
Omarchy's `PanelSlider` for the knob, drag, wheel and notches and draws the
track, two-tone fill and over-gain zone itself. Layout maths (`gainSplit`,
`balanceSpan`, `meterSegment`, `heroMeta`, `heroDetail`, `footerHints`) is
in `Model.js`. A
`keyboardRow` cursor and `handleKey` implement the key map in
[specs/keyboard.md](specs/keyboard.md). The panel sets `manageIpc: false`; its
IPC lives in `AudioService`.

**`AudioService.qml`** is a `pragma Singleton`. It owns one
`AudioModel { optionsActive: true }` that every monitor's `Panel` shares
([ADR 9](adr/0009-one-shared-audio-model.md)) and the `IpcHandler` for
`pym.volta-control` ([specs/ipc.md](specs/ipc.md)).

**`AudioModel.qml`** turns PipeWire into a small reactive surface:
`available`, `stereoSupported`, `mono`, `left`, `right`, `volume`,
`balance`, `muted`, `channelsLocked`, `sinks`, `sinkIndex`, `sinkOptions`,
`sinkLabel` and `error`, plus the write functions (`setLeft`, `setRight`,
`setBalance`, `setVolume`, `adjustBoth`, `toggleLock`, `toggleMute`,
`reset`, `selectSinkId`, `cycleSink`).

**`Model.js`** is a `.pragma library` with no QML dependencies, loaded by
Node in `tests/model.test.js`.

## Data flow

```text
PipeWire ──(Quickshell.Services.Pipewire)──▶ AudioModel ──▶ Panel (every monitor)
   ▲                                          │   ▲               │
   │ sink.audio.volumes / volume / muted      │   │ IPC           │ clicks, wheel, keys
   └──────────────────────────────────────────┘   │               ▼
                                              AudioService ◀── omarchy-shell pym.volta-control
Omarchy helpers (short-lived processes):
  omarchy-audio-output-sink        → which sink is the real output
  omarchy-audio-sink-availability  → which sinks may be listed
  omarchy-audio-output-set-default → switch default, move app streams
```

1. **Which sink.** `Pipewire.defaultAudioSink` is the starting point.
   `omarchy-audio-output-sink` names the physical sink behind any DSP or
   speaker-tuning sink; if that sink is among the candidates and has audio,
   Volta controls it instead of the default
   ([ADR 2](adr/0002-follow-omarchy-sink-helpers.md)). Candidates are
   PipeWire nodes that are sinks and not streams; `sinks` drops those that
   `omarchy-audio-sink-availability` reports as unavailable, but always
   keeps the current default.
2. **Reading.** Channel names (`PwAudioChannel.toString`) and volumes go to
   `Model.readStereo`, which finds front-left/front-right or a mono channel
   and clamps to 0-150 % ([ADR 4](adr/0004-clamp-to-150-percent-with-warning.md),
   [ADR 5](adr/0005-disable-lr-on-mono-and-odd-channel-maps.md)).
3. **Writing.** `write(left, right)` validates the channel map, builds the
   new `volumes` array with `Model.withStereoVolumes` (other channels
   untouched) and assigns it in one step. Balance uses
   `Model.applyBalance` ([ADR 7](adr/0007-balance-keeps-the-louder-channel.md)).
   Linking writes the average to both sides and then keeps them equal.
4. **Verifying.** 800 ms after a write Volta compares PipeWire's values with
   what it asked for and shows an error if a policy changed them
   ([ADR 10](adr/0010-verify-writes-and-report-overrides.md)).
5. **Switching output.** `selectSink` sets
   `Pipewire.preferredDefaultAudioSink`, runs
   `omarchy-audio-output-set-default <id> <name>` detached, and re-resolves
   the physical sink 250 ms later. A sink change unlinks the channels and
   clears errors.

## Timers and processes

| What | When |
| --- | --- |
| `omarchy-audio-output-sink` | at start, on default-sink change, 250 ms after a switch, every 15 s |
| `omarchy-audio-sink-availability` | at start, on default-sink change, every 5 s |
| `omarchy-audio-output-set-default` | only when the user picks an output |
| write verification | 800 ms after each level write |
| popup output list refresh | 75 ms after the sink list changes, while open |

## Boundaries

- Volta never writes outside PipeWire state: no config files, no
  compositor bindings ([ADR 6](adr/0006-ipc-only-no-global-bindings.md)), no
  edits under `/usr/share/omarchy`.
- It does not manage streams, inputs, EQ or profiles
  ([ADR 3](adr/0003-focused-scope-not-a-mixer.md)).
- Sink text from PipeWire is escaped before display
  ([ADR 8](adr/0008-escape-sink-labels.md)).
- Theme colours come from `Commons.Color`
  ([ADR 11](adr/0011-qualify-theme-color-for-qt-6-12.md)).
