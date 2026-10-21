#!/usr/bin/env bash
# Render the Volta popup offscreen with sample outputs, one PNG per scene.
# Usage: VOLTA_PREVIEW_DIR=<absolute dir> bash tests/preview.sh
# Never opens a window, never talks to PipeWire, never reads the user's config.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
out_dir="${VOLTA_PREVIEW_DIR:?set VOLTA_PREVIEW_DIR to an absolute output directory}"
[[ "$out_dir" == /* ]] || { echo "VOLTA_PREVIEW_DIR must be absolute: $out_dir" >&2; exit 2; }
mkdir -p "$out_dir"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/volta-preview.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT

# Commons and Ui come from the installed Omarchy shell; KeyboardPanel needs a
# layer-shell PanelWindow, so it is swapped for an Item stand-in.
ln -s /usr/share/omarchy/shell/Commons "$work_dir/Commons"
mkdir "$work_dir/Ui"
ln -s /usr/share/omarchy/shell/Ui/* "$work_dir/Ui/"
ln -sf "$repo_dir/tests/offscreen/KeyboardPanel.qml" "$work_dir/Ui/KeyboardPanel.qml"

# A copy of the plugin with the PipeWire-backed model replaced by sample data.
mkdir "$work_dir/plugin"
cp "$repo_dir"/{Panel.qml,AudioService.qml,Model.js,qmldir} "$work_dir/plugin/"
cp -r "$repo_dir/assets" "$work_dir/plugin/"
cp "$repo_dir/tests/offscreen/AudioModel.qml" "$work_dir/plugin/AudioModel.qml"
# MultiEffect draws nothing on the offscreen software renderer, so show the
# mark's white source image directly instead of its theme-tinted copy.
sed -i -e "s/^      visible: false$/      visible: true/" -e "s/^      layer.enabled: true$/      layer.enabled: false/" "$work_dir/plugin/Panel.qml"
cp "$repo_dir/tests/Preview.qml" "$work_dir/shell.qml"

mkdir -p "$work_dir/home/.local/state/omarchy/current/theme" "$work_dir/runtime"
cp "$repo_dir/tests/offscreen/colors.toml" "$work_dir/home/.local/state/omarchy/current/theme/colors.toml"
chmod 700 "$work_dir/runtime"
status=0
env -u DISPLAY -u WAYLAND_DISPLAY \
  HOME="$work_dir/home" XDG_CONFIG_HOME="$work_dir/home/.config" \
  XDG_RUNTIME_DIR="$work_dir/runtime" XDG_CACHE_HOME="$work_dir/cache" \
  XDG_STATE_HOME="$work_dir/state" PIPEWIRE_REMOTE=none \
  VOLTA_PREVIEW_DIR="$out_dir" QT_QPA_PLATFORM=offscreen \
  QT_SCALE_FACTOR="${QT_SCALE_FACTOR:-2}" QT_STYLE_OVERRIDE=Fusion QT_QPA_PLATFORMTHEME=xdgdesktopportal \
  timeout 30s quickshell -p "$work_dir/shell.qml" --no-color >"$work_dir/output" 2>&1 || status=$?
cat "$work_dir/output"
[[ "$status" -eq 0 ]]
if grep -Ei '(TypeError|ReferenceError|SyntaxError|is not a type|Cannot assign|Unable to assign|Binding loop|VOLTA_PREVIEW_FAILED)' "$work_dir/output"; then
  exit 1
fi
grep -q VOLTA_PREVIEW_OK "$work_dir/output"
