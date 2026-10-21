# Volta agent instructions

Volta is an Omarchy shell plugin (Quickshell/QML) that shows and sets the left
and right output volume and stereo balance from the bar. Plugin id
`pym.volta`; public at https://github.com/mateuspim/omarchy-volta. The README
is the user manual; read its section before changing a feature.
`docs/architecture.md` says how the parts fit, `docs/adr/` why,
`docs/specs/` what the contracts are (IPC actions, keys, settings).

## Project

- Layout: every `.qml` and `.js` file at the root. Omarchy loads the one
  entry point in `manifest.json` (`Panel.qml`, a `bar-widget`); QML finds
  `AudioService` and `AudioModel` through `qmldir`, so a new component goes in
  `qmldir` too. Don't add QML subfolders. `assets/volta-bar-icon.png` is the
  bar and popup mark (`VoltaMark` in `Panel.qml`). Tests and the offscreen
  harness in `tests/`, brand sources in `docs/brand/`.
- Pure logic (clamping, channel maps, balance, labels) goes in `Model.js` so
  Node can test it. `AudioModel.qml` owns PipeWire state and writes;
  `AudioService.qml` is the one shared instance plus the IPC handler;
  `Panel.qml` is UI and input only.
- Naming: plugin id and panel `moduleName` `pym.volta`; IPC target
  `pym.volta-control`; preview env vars `VOLTA_PREVIEW_*`. No settings file.
- Qt 6.12: QtQuick exports its own `Color`. Write
  `import qs.Commons as Commons` and `Commons.Color.x`; never a bare `Color.`
  (ADR 11; `tests/qml.test.js` enforces it).
- Target Omarchy 4.0+ and its Quickshell-based `omarchy-shell`. Treat
  `/usr/share/omarchy/` as read-only reference; never edit packaged files.
  Useful references there: `shell/plugins/README.md`,
  `shell/plugins/bar/README.md`, `shell/plugins/panels/audio/`, and
  `shell/Ui/{Panel,PanelSlider,KeyboardPanel}.qml`.
- Audio goes through Quickshell's native PipeWire API (ADR 1). Don't add
  `wpctl`/`pactl` calls or a helper daemon unless a channel-level operation
  cannot be done through that API.
- Which sink is the real output, which sinks are selectable, and how the
  default changes all come from Omarchy's helpers
  (`omarchy-audio-output-sink`, `omarchy-audio-sink-availability`,
  `omarchy-audio-output-set-default`), so speaker tuning and DSP routing
  behave like the system audio panel (ADR 2). Reuse them; don't reimplement
  them.
- Stay a focused stereo control: L/R levels, balance, link, mute, reset and
  output choice. Per-app streams, inputs, EQ and profiles belong to Omarchy's
  audio panel, not here (ADR 3).
- Levels clamp to 0-150 % (`Model.MAX_VOLUME`) and turn the urgent colour
  above 100 % (ADR 4). Outputs without front-left and front-right keep mute,
  reset and output choice; L/R, balance and link are disabled (ADR 5).
- No global compositor bindings: outside the popup, actions are IPC only
  (ADR 6). The popup's own keys are in `docs/specs/keyboard.md`.
- Sink names come from PipeWire metadata that local clients control; pass
  every label through `Model.sinkLabel`/`safeSinkText` (ADR 8).
- Validate the repository root with `omarchy plugin validate .` after any
  change to `manifest.json`, `qmldir` or entry points. The plugin must stay
  installable with `omarchy plugin add <git-url> --enable`.

## Code style

- Match the surrounding file: 2-space QML and JS, no semicolons, typed QML
  properties where the shape is known.
- Functions small and single-purpose; files focused, split by
  responsibility. `Panel.qml` is near its limit; move new widgets into their
  own root-level QML file listed in `qmldir`.
- Names specific and greppable; avoid `data`, `handler`, `Manager`.
- Early returns over nested ifs. No duplication: pure logic in `Model.js`.
- Error messages say what failed and what the user can expect, and stay
  scoped to the operation that produced them.

## Comments

- Keep existing comments; they carry intent and provenance.
- Write WHY, not WHAT. Name the upstream constraint or bug a line exists for.

## Tests

- `npm test` runs every Node test (`tests/model.test.js`,
  `tests/qml.test.js`); CI runs the same.
- Every new pure function gets a test; bug fixes get a regression test.
  Channel maps come from the JSON fixtures in `tests/fixtures/`.
- Tests never touch real audio devices or the user's config.
- Visual checks offscreen only (ADR 12):
  `VOLTA_PREVIEW_DIR=<abs dir> bash tests/preview.sh` writes one PNG per
  scene from `tests/Preview.qml` with the fake `tests/offscreen/AudioModel.qml`
  and sample outputs. `MultiEffect` draws nothing offscreen, so the harness
  shows the mark untinted.
- Never screenshot (`grim`) or inject input (`wtype`) on the user's monitors.
  Deploy and let the user check by hand.
- Live shell log (read-only):
  `quickshell log -p /usr/share/omarchy/shell -t 200 | grep -i volta`.
  Ask before restarting the user's shell.

## Dependencies

- Runtime: Omarchy's `qs.Ui`/`qs.Commons`, Quickshell's
  `Quickshell.Services.Pipewire`, and the three Omarchy audio helpers above.
  Nothing else; no npm runtime dependencies.
- Reuse Omarchy's public `qs.Ui` components (`Panel`, `KeyboardPanel`,
  `PanelSlider`, `Dropdown`, ...). Don't copy the built-in `omarchy.audio`
  plugin.

## Public-repo hygiene

- No `/home/...` paths, real device names, serials or LAN addresses in
  tracked files. Fixtures and previews use sample names such as
  "Studio Headphones" and "Desk Speakers".
- Don't commit local `shell.json`, caches, installed plugin copies or
  machine-specific audio identifiers.
- Never modify user config on load; Volta changes only audio state, and only
  on an explicit user action.
- `HANDOFF.md` is local-only and stays gitignored.

## Commits and releases

- Branch `master`. Commit subjects are plain imperative sentences with a body
  that says why. Ask the owner before pushing commits or tags, and before
  publishing a GitHub release.
- Release: bump `version` in `manifest.json` and `package.json`, add the
  `CHANGELOG.md` entry, check the README covers the change, `npm test`,
  `omarchy plugin validate .`, commit `Release X.Y.Z`, annotated tag
  `vX.Y.Z` ("Volta X.Y.Z").
