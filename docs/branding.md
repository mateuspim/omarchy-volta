# Volta brand assets

The mark is a vector version of Volta's bar glyph: five level bars that
step down toward the centre, the left pair and right pair standing for the
two channels, over a balance slider with its knob in the middle. Together
the bars also read as a "V". At 32 px the bars and slider stay distinct; at
16 px the mark reduces to an amber V over a line. It is drawn as vector
paths on a rounded square.

| Colour | Hex | Use |
| --- | --- | --- |
| Amber (accent) | `#f5a524` | Icon border, outer bars, slider knob, wordmark on dark, hero accents |
| Amber outline | `#b9760f` | Slider track in the icon; wordmark on light surfaces |
| Amber highlight | `#ffd58a` | Centre bar |
| Icon field | `#1f1709` | Icon background and knob outline |

The wordmark is the whole word **Volta** in amber (dark surfaces) or amber
outline (light surfaces), in DejaVu Sans Bold.

| Asset | Use |
| --- | --- |
| [`icon.svg`](../icon.svg) | Square app icon and README heading. |
| [`logo.svg`](brand/logo.svg) | Horizontal wordmark on a dark surface. |
| [`logo-light.svg`](brand/logo-light.svg) | Horizontal wordmark on a light surface. |
| [`preview.svg`](brand/preview.svg) | Editable README hero layout. |
| [`captures/`](brand/captures/) | Offscreen popup renders with sample outputs, placed by the hero. |
| [`preview.png`](../preview.png) | Rendered README hero at 3840 × 2160. |
| [`assets/volta-bar-icon.png`](../assets/volta-bar-icon.png) | White source of the in-shell mark; `Panel.qml` tints it to the theme. |

The logo SVGs and the preview inline the mark so they render standalone; keep
the paths in sync when changing the icon. Wordmarks use live SVG text, so the
font can vary when DejaVu Sans is unavailable.

The popup captures are real Quickshell renders of `Panel.qml`, made offscreen
with a fake audio model and a sample theme whose accent is Volta amber; inside
Omarchy the popup follows the user's theme. They contain no real device names.

Keep clear space around the mark and the wordmark casing **Volta**. The
[development runbook](runbooks/development.md#refresh-the-preview) explains how
to re-render the hero from offscreen captures with fake data.
