#!/bin/bash
# SPDX-License-Identifier: MIT
# One-time cleanup for machines set up with the OLD non-standard XDG paths
# the previous .zshenv exported:
#   XDG_DATA_HOME=~/.config/local/share   (spec: ~/.local/share)
#   XDG_CACHE_HOME=~/.config/cache        (spec: ~/.cache)
# Moves data entry-by-entry to the spec locations, never clobbering existing
# data. Run once per affected (personal/zsh) machine, then restart the shell.
set -euo pipefail

OLD_DATA="$HOME/.config/local/share"
NEW_DATA="$HOME/.local/share"
OLD_CACHE="$HOME/.config/cache"

if [ -d "$OLD_DATA" ]; then
  mkdir -p "$NEW_DATA"
  for entry in "$OLD_DATA"/* "$OLD_DATA"/.[!.]*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    if [ -e "$NEW_DATA/$name" ]; then
      echo "SKIP (exists in both, merge manually): $name" >&2
    else
      mv "$entry" "$NEW_DATA/$name"
      echo "moved: $name"
    fi
  done
  rmdir "$OLD_DATA" "$HOME/.config/local" 2>/dev/null || true
else
  echo "no old data dir ($OLD_DATA) — nothing to move"
fi

if [ -d "$OLD_CACHE" ]; then
  echo "removing old cache dir (caches regenerate): $OLD_CACHE"
  rm -rf "$OLD_CACHE"
fi

echo "XDG migration done — restart your shell."
