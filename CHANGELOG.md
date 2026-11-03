# Changelog

## 0.2.1 - 2026-11-03

- Keep the contributor and agent instructions out of automatic agent
  discovery: they move from the root `AGENTS.md`/`CLAUDE.md` to
  `docs/contributing/agent-instructions.md`, so an ordinary
  `omarchy plugin add` install no longer loads them into coding agents.
  Contributors opt in with `scripts/dev-setup`, which creates gitignored
  root entry points (ADR 15).
- Add `tests/repo.test.js`, which fails if a file that coding agents load
  automatically is tracked.

## 0.2.0 - 2026-10-21

- Redesign the popup: a stereo stage with large L/R readouts over a mirrored
  meter, sliders with a tinted 100-150 % over-gain zone and a balance fill
  from the centre, keycap hints beside each control, Link and Mute as
  toggles, and a keycap footer. All widget colours come from the theme.
- Replace the output dropdown with an inline list: device icon, name,
  connection and mono note per output, the default marked with an accent
  check. More than four outputs collapse to three plus "+N more"; Enter
  expands. The wheel over the list cycles outputs.
- Render previews under any theme with `VOLTA_PREVIEW_COLORS`; add muted
  and six-output preview scenes.
- Refresh the README hero with the new popup, the two captures side by
  side.
- Fix theme colours on Qt 6.12: the centred balance label, the focused
  balance slider and warning fill now use `Commons.Color` instead of an
  undefined colour.
- Add a new amber Volta icon and wordmarks, and a 3840 × 2160 README hero
  built from offscreen renders with sample outputs.
- Add an offscreen preview harness (`tests/preview.sh`) with a fake audio
  model, and a test that rejects bare `Color.` in QML.
- Add documentation: architecture, decision records, IPC/keyboard/settings
  specs, development and troubleshooting runbooks, branding, contributing
  and security guides, CI and GitHub templates.
- Rewrite the README and agent instructions to the shared repo standard.
- Credit Mateus Pim as the author.

## 0.1.0 - 2026-08-25

- First functional release with native per-channel PipeWire control.
- Add L/R volume, balance, channel linking, mute, reset, and sink selection.
- Add reactive device updates, visible unsupported-device errors, and model tests.
- Restore the original TUI shortcuts and lock/reset semantics in the native popup.
- Refine the popup hierarchy with sink cycling, channel sections, status details, and an inline shortcut guide.
