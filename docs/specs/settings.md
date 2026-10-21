# Settings and manifest

Volta has no user settings and writes no settings file. Its behaviour is
fixed by the code and the decisions in [docs/adr](../adr/README.md).

`manifest.json` declares:

| Field | Value | Meaning |
| --- | --- | --- |
| `id` | `pym.volta` | Plugin id; also the panel `moduleName`. |
| `kinds` | `["bar-widget"]` | One bar widget, no panel or service kinds. |
| `entryPoints.barWidget` | `Panel.qml` | The bar mark and its popup. |
| `barWidget.category` | `Audio` | Where Omarchy lists it. |
| `barWidget.allowMultiple` | `false` | One instance per bar. |
| `barWidget.defaultSection` | `right` | Where it lands when enabled. |
| `barWidget.defaults` | `{}` | No per-instance options. |
| `barWidget.schema` | `[]` | No settings shown in Omarchy's bar settings. |

Adding a setting means adding a `schema` entry with a default in `defaults`,
reading it through the `Panel` base's `setting(name, fallback)`, documenting
it here and in the README, and recording why in an ADR.
