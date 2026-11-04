#!/bin/bash
# SPDX-License-Identifier: MIT
# Build and install SbarLua (sketchybar's Lua module) into
# ~/.local/share/sketchybar_lua. macOS only.
#   scripts/install-sbarlua.sh [--force] [--check]
#     --force  rebuild even if sketchybar.so is already installed
#     --check  only report whether it is installed (exit 0 if so, 1 if not)
#
# Pinned on purpose: SbarLua's makefile embeds its own Lua, and the .so must
# match the Lua that runs the config (Homebrew `lua`, 5.4.x). Upstream moved to
# Lua 5.5 in dba9cc42; this is its parent, the last commit that embeds 5.4.7.
# Bump the pin only together with Homebrew's lua major.minor.
set -euo pipefail

PIN=437bd2031da38ccda75827cb7548e7baa4aa9978
REPO=https://github.com/FelixKratz/SbarLua.git
DEST="$HOME/.local/share/sketchybar_lua"

force=0 check=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --check) check=1 ;;
    *) echo "usage: $0 [--force] [--check]" >&2; exit 2 ;;
  esac
done

if [ "$check" -eq 1 ]; then
  if [ -f "$DEST/sketchybar.so" ]; then
    echo "SbarLua installed: $DEST/sketchybar.so"
    exit 0
  fi
  echo "SbarLua not installed (run scripts/install-sbarlua.sh)" >&2
  exit 1
fi

if [ "$(uname)" != "Darwin" ]; then
  echo "SbarLua is macOS only; nothing to do." >&2
  exit 0
fi

if [ "$force" -eq 0 ] && [ -f "$DEST/sketchybar.so" ]; then
  echo "SbarLua already installed ($DEST/sketchybar.so); use --force to rebuild."
  exit 0
fi

for tool in git make clang; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required (install Xcode Command Line Tools: xcode-select --install)" >&2
    exit 1
  fi
done

if ! command -v lua >/dev/null 2>&1; then
  echo "lua is required first (brew install lua, or scripts/install-packages.sh --gui)" >&2
  exit 1
fi
case "$(lua -v 2>&1)" in
  "Lua 5.4."*) ;;
  *)
    echo "lua is not 5.4.x ($(lua -v 2>&1)); the pinned SbarLua embeds Lua 5.4 and would not match." >&2
    echo "Install Lua 5.4, or update PIN in $0 together with the Lua version." >&2
    exit 1
    ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git clone --quiet "$REPO" "$tmp/SbarLua"
git -C "$tmp/SbarLua" checkout --quiet "$PIN"
(cd "$tmp/SbarLua" && make install)

echo "Installed $DEST/sketchybar.so (SbarLua ${PIN:0:8}, Lua 5.4)"
