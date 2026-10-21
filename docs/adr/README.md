# Architecture Decision Records

Each record describes one durable decision in Volta's design: the context
that led to it, what was decided, and what follows from it. They use Michael
Nygard's format (Title, Status, Context, Decision, Consequences) and are
numbered in the order they were recorded. For how the parts fit
together today, see the [architecture overview](../architecture.md).

Records 1-10 were documented from the code on 2026-10-21. Their dates and
commit ids are those of the commits that introduced the behaviour, taken
from the git history; the reasoning is reconstructed from the code and the
project's original plan, not from contemporaneous notes.

| # | Decision | Date | Status |
| --- | --- | --- | --- |
| [1](0001-native-pipewire-api.md) | Use Quickshell's native PipeWire API for levels and mute | 2026-08-25 | Accepted |
| [2](0002-follow-omarchy-sink-helpers.md) | Follow Omarchy's audio helpers for the real output and the default sink | 2026-08-25 | Accepted |
| [3](0003-focused-scope-not-a-mixer.md) | Stay a focused stereo control, not a general mixer | 2026-08-25 | Accepted |
| [4](0004-clamp-to-150-percent-with-warning.md) | Clamp levels to 0-150 % and flag over-gain | 2026-08-25 | Accepted |
| [5](0005-disable-lr-on-mono-and-odd-channel-maps.md) | Disable independent L/R on mono and odd channel maps | 2026-08-25 | Accepted |
| [6](0006-ipc-only-no-global-bindings.md) | Expose actions through IPC; install no global bindings | 2026-08-25 | Accepted |
| [7](0007-balance-keeps-the-louder-channel.md) | Balance keeps the louder channel and attenuates the other | 2026-08-26 | Accepted |
| [8](0008-escape-sink-labels.md) | Escape and bound sink labels from PipeWire metadata | 2026-08-26 | Accepted |
| [9](0009-one-shared-audio-model.md) | Share one audio model across bar instances | 2026-08-26 | Accepted |
| [10](0010-verify-writes-and-report-overrides.md) | Verify writes and show when PipeWire does not keep them | 2026-08-25 | Accepted |
| [11](0011-qualify-theme-color-for-qt-6-12.md) | Qualify the theme `Color` as `Commons.Color` (Qt 6.12) | 2026-10-21 | Accepted |
| [12](0012-offscreen-preview-harness.md) | Render previews offscreen with a fake audio model | 2026-10-21 | Accepted |
| [13](0013-stereo-stage-popup.md) | Lead the popup with a stereo stage, drawn from theme colours | 2026-10-21 | Accepted |
| [14](0014-inline-output-list.md) | Pick outputs from an inline list with device icons | 2026-10-21 | Accepted |

## Rules

- Add a record for a durable choice: a backend, a boundary, a safety rule,
  or something Volta deliberately refuses to do.
- Never rewrite an accepted record. To change a decision, add a new record,
  set the old one's status to "Superseded by N" with a link to the new
  record, and link back from the new one.
- Write "(unverified)" for anything you cannot confirm from the code or the
  history.
