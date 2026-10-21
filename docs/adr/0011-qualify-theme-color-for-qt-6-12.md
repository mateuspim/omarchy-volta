# 11. Qualify the theme `Color` as `Commons.Color` (Qt 6.12)

- Status: Accepted
- Date: 2026-10-21 (`a9341da`)

## Context

`Panel.qml` used Omarchy's theme singleton from `qs.Commons` unqualified
(`Color.accent`). Qt 6.12's `QtQuick` exports its own `Color`, which wins
the unqualified lookup. An offscreen render logged "Unable to assign
[undefined] to QColor" for the centred balance label and the focused
balance slider.

## Decision

Like Omarchy's own Ui kit, `Panel.qml` imports `qs.Commons as Commons` and
writes `Commons.Color.…`. The unqualified `import qs.Commons` stays for
`Style`. `tests/qml.test.js` fails on any bare `Color.x` in root QML
files.

## Consequences

- Theme colours resolve on Qt 6.12 and earlier.
- A bare `Color.x` breaks silently at runtime, so the Node check and the
  offscreen harness's warning filter catch it.
