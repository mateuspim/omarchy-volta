# Development runbook

## Set up

You need Omarchy 4.0+ (with `omarchy-shell`), Node.js 22 or newer for the
tests, and `librsvg` (`rsvg-convert`) only to re-render the README hero.

Link a checkout into the user plugin directory (never into
`/usr/share/omarchy`), then rescan and enable it:

```sh
git clone https://github.com/mateuspim/omarchy-volta.git
ln -s "$PWD/omarchy-volta" ~/.config/omarchy/plugins/pym.volta
cd omarchy-volta
omarchy plugin validate .
omarchy-shell shell rescanPlugins
omarchy plugin enable pym.volta
```

Changes under the plugin directory hot-reload with the shell. Watch the live
log (read-only) while you work:

```sh
quickshell log -p /usr/share/omarchy/shell -t 200 | grep -i volta
```

The live shell is the user's session: don't restart it from scripts or
agents without asking. If the plugin directory is your working checkout,
work on a branch in a separate `git worktree` so half-finished edits don't
reload into the running bar.

## Test

```sh
npm test
omarchy plugin validate .
```

`npm test` runs `tests/model.test.js` (clamping, channel maps from
`tests/fixtures/*.json`, balance, labels and escaping) and
`tests/qml.test.js` (no bare `Color.` in QML, see
[ADR 11](../adr/0011-qualify-theme-color-for-qt-6-12.md)). GitHub Actions runs
`npm test` on every push and pull request.

## Offscreen previews

Check UI changes without touching the desktop or PipeWire
([ADR 12](../adr/0012-offscreen-preview-harness.md)):

```sh
VOLTA_PREVIEW_DIR="$PWD/.preview" bash tests/preview.sh
```

It writes `headphones.png`, `speakers.png`, `mono.png` and `muted.png`
(scenes defined in `tests/Preview.qml`) and fails on QML errors, binding loops or
`Unable to assign` warnings. `QT_SCALE_FACTOR` (default 2) sets the pixel
density. How it works:

- `Commons` and `Ui` are linked from `/usr/share/omarchy/shell`;
  `Ui/KeyboardPanel.qml` is replaced by `tests/offscreen/KeyboardPanel.qml`,
  an Item that draws the popup card without a layer-shell window.
- The plugin is copied and its `AudioModel.qml` replaced by
  `tests/offscreen/AudioModel.qml`, which has the same public properties but
  sample outputs and no PipeWire import.
- A throwaway `HOME` with `tests/offscreen/colors.toml` (the shell's default
  palette with Volta's amber accent) keeps your theme and settings out. Set
  `VOLTA_PREVIEW_COLORS` to another `colors.toml`, for example
  `/usr/share/omarchy/themes/catppuccin-latte/colors.toml`, to check that the
  popup follows light themes and other accents.
- `MultiEffect` draws nothing on the offscreen software renderer, so the
  harness shows the mark's white source image instead of the tinted one.

Keep `.preview/` or any output folder out of git. Never use `grim` or input
injection on the live monitors.

## Refresh the preview

The README hero is `preview.png` (3840 × 2160) at the repository root. Its
editable layout is [`docs/brand/preview.svg`](../brand/preview.svg), which
places two captures from `docs/brand/captures/`: `speakers.png` (Desk
Speakers, linked at 80 %) behind and `headphones.png` (Studio Headphones,
64 % / 118 %, balance row focused) in front. All names are samples.

1. Re-render the captures at 3× so they stay sharp in the hero:

   ```sh
   QT_SCALE_FACTOR=3 VOLTA_PREVIEW_DIR="$PWD/docs/brand/captures" bash tests/preview.sh
   ```

2. Look at each capture. Edit `docs/brand/preview.svg` if the layout,
   tagline or chips need to change; keep the icon paths in sync with
   `icon.svg`.
3. Render and inspect the result:

   ```sh
   rsvg-convert -o preview.png docs/brand/preview.svg
   ```

The current image was rendered with librsvg 2.63.3 on a system where
Fontconfig substitutes Liberation Sans for DejaVu Sans and JetBrainsMono Nerd Font for
DejaVu Sans Mono. Other font setups change text widths; check that no chip
text touches its border. Keep the README alt text accurate.

## Release

1. Bump `version` in `manifest.json` and `package.json`.
2. Add a `## X.Y.Z - YYYY-MM-DD` entry at the top of `CHANGELOG.md`.
3. Check the README covers the change.
4. `npm test` and `omarchy plugin validate .`.
5. Commit `Release X.Y.Z` and create an annotated tag
   `git tag -a vX.Y.Z -m "Volta X.Y.Z"`.
6. Ask the owner before pushing commits or tags and before publishing a
   GitHub release.
