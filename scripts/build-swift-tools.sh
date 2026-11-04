#!/bin/bash
# SPDX-License-Identifier: MIT
# Build the macOS helper binaries from their Swift sources. The binaries are
# build output (gitignored); they land next to the linked config, which is a
# real directory because install.sh stows with --no-folding.
#   aerospace/cheatsheet                alt-/ cheat sheet window
#   sketchybar/pomodoro/pomodoro-panel  pomodoro history & settings panel
#   sketchybar/wifi-ssid/wifi-ssid.app  Wi-Fi network name for the wifi widget
set -euo pipefail

[ "$(uname)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
command -v swiftc >/dev/null 2>&1 || { echo "swiftc not found (xcode-select --install)" >&2; exit 1; }

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

swiftc -O "$CONFIG/aerospace/cheatsheet.swift" -o "$CONFIG/aerospace/cheatsheet"
swiftc -O "$CONFIG/sketchybar/pomodoro/pomodoro-panel.swift" -o "$CONFIG/sketchybar/pomodoro/pomodoro-panel"

# wifi-ssid is an .app bundle, not a bare binary: the Location Services
# permission it needs is tied to the bundle id in its Info.plist, and the
# ad-hoc signature gives TCC a stable identity (until the next rebuild).
app="$CONFIG/sketchybar/wifi-ssid/wifi-ssid.app"
mkdir -p "$app/Contents/MacOS"
swiftc -O "$CONFIG/sketchybar/wifi-ssid/wifi-ssid.swift" -o "$app/Contents/MacOS/wifi-ssid"
cp "$CONFIG/sketchybar/wifi-ssid/Info.plist" "$app/Contents/Info.plist"
codesign --force --sign - "$app"

echo "built cheatsheet, pomodoro-panel and wifi-ssid.app"
echo "wifi-ssid needs Location Services once (and again after a rebuild):"
echo "  open \"$app\"    then click Allow"
