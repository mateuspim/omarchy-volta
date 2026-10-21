# 13. Lead the popup with a stereo stage, drawn from theme colours

- Status: Accepted
- Date: 2026-10-21

## Context

The 0.2.0 popup gave every control the same weight: a header repeating the
two levels, three plain `PanelSlider` rows with shortcuts written into their
labels, Link / Mute / Reset buttons with key letters in their text, and a
dense block of key hints. Nothing showed the stereo picture at a glance, the
over-gain range (ADR 4) appeared only as a fill colour change, and the
balance fill ran from the far left even though balance is centred.

## Decision

- Open with a `StereoStage`: large left and right readouts over a mirrored
  meter that grows out from an accent centre line, one segment per 10 %.
  Segments step up in height toward the edges, echoing the Volta mark, and
  the five outer segments form a tinted over-gain zone. Mono outputs show a
  single centred volume readout.
- Draw each keyboard row as a `LevelSlider`: label, value where it is not
  already on the stage (balance), keycaps on the right, a two-tone fill and
  a tinted 100-150 % zone on volume rows, and a fill that grows from the
  centre detent on the balance row. Omarchy's `PanelSlider` still provides
  the knob, drag, wheel and notches.
- Show shortcuts as keycaps (`KeyHints`) beside their row and in a footer,
  not inside labels. Link and Mute are toggles with fixed labels and a
  selected state; the keyboard cursor uses the kit's hover-cursor frame.
- Take every widget colour from the theme (`Commons.Color`, `Style` state
  tokens, the bar's colours). Volta's amber is a brand colour for the icon,
  wordmarks and README hero only.

## Consequences

- The popup reads correctly under any Omarchy theme, light or dark; check
  with `VOLTA_PREVIEW_COLORS` in the preview harness.
- The popup is taller than before (stage plus rows), still 400 units wide.
- Five small sibling components are listed in `qmldir`; a new one must be
  added there too, because a directory with a `qmldir` hides unlisted files.
- Keys, IPC actions and pointer behaviour did not change.
