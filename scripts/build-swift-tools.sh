#!/bin/bash
# SPDX-License-Identifier: MIT
# Build the macOS helper binaries from their Swift sources. The binaries are
# build output (gitignored); they land next to the linked config, which is a
# real directory because install.sh stows with --no-folding.
#   aerospace/cheatsheet               alt-/ cheat sheet window
#   sketchybar/pomodoro/pomodoro-panel pomodoro history & settings panel
set -euo pipefail

[ "$(uname)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
command -v swiftc >/dev/null 2>&1 || { echo "swiftc not found (xcode-select --install)" >&2; exit 1; }

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

swiftc -O "$CONFIG/aerospace/cheatsheet.swift" -o "$CONFIG/aerospace/cheatsheet"
swiftc -O "$CONFIG/sketchybar/pomodoro/pomodoro-panel.swift" -o "$CONFIG/sketchybar/pomodoro/pomodoro-panel"
echo "built cheatsheet and pomodoro-panel"
