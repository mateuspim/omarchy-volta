# Changelog

## 0.2.0 - 2026-10-21

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
