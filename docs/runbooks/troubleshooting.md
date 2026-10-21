# Troubleshooting

Start with the live shell log (read-only):

```sh
quickshell log -p /usr/share/omarchy/shell -t 200 | grep -i volta
```

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Volta is not in the bar | Plugin not enabled, or the manifest failed validation. | Run `omarchy plugin validate ~/.config/omarchy/plugins/pym.volta`, then `omarchy-shell shell rescanPlugins` and `omarchy plugin enable pym.volta`. |
| Popup says "No output available" | PipeWire has no default sink, or the shell lost its PipeWire connection. | Check `wpctl status`. If the output is there, restart the shell with `omarchy restart shell`. |
| L/R sliders, balance and Link are greyed out with a mono note | The output is mono (`Mono` or `FrontCenter` channel). | Expected: volume, mute, reset and output choice still work ([ADR 5](../adr/0005-disable-lr-on-mono-and-odd-channel-maps.md)). |
| "This output does not expose front-left and front-right channels." | The sink's channel map has no FL/FR pair. | Expected; pick a stereo output. Check the map with `wpctl inspect <id>`. |
| "Could not resolve the physical output; using the PipeWire default." | `omarchy-audio-output-sink` failed, so Volta controls the default sink directly. Behind a speaker tuning or EasyEffects, that is the DSP input, not the speakers. | Run `omarchy-audio-output-sink` in a terminal and fix what it reports; Volta retries every 15 s and on every output change. |
| Levels change on the wrong device behind DSP | The resolver returned an unexpected sink. | Compare `omarchy-audio-output-sink` with the device you expect; Volta follows that helper ([ADR 2](../adr/0002-follow-omarchy-sink-helpers.md)). |
| A value does not stick; "PipeWire did not keep the requested channel levels…" | Another client or a WirePlumber policy rewrote the volume. | Volta shows what PipeWire actually holds. Find the other client (`wpctl status`, other mixers, EasyEffects presets). |
| "The selected output disappeared. Refreshing devices…" | The output was unplugged or became unavailable while you chose it. | Wait for the list to refresh, then pick again. |
| An output is missing from the list | `omarchy-audio-sink-availability` marks it unavailable (no port connected, or a physical sink hidden behind a speaker tuning). | Expected for tuned speakers: choose the tuning sink. Otherwise connect the device; the list refreshes every 5 s. |
| Values above 100 % are red | Software gain above 100 % can clip. | Intended warning ([ADR 4](../adr/0004-clamp-to-150-percent-with-warning.md)); press `r` to reset to 100 %. |
| Keys do nothing while the popup is closed | Volta adds no global bindings. | Bind the IPC actions yourself ([specs/ipc.md](../specs/ipc.md)). |

When reporting a bug, include the Volta version from `manifest.json`,
`omarchy version`, the relevant log lines, and the output's channel map
(rename the device if you prefer not to share it).
