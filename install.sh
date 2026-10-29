#!/bin/bash
# SPDX-License-Identifier: MIT
# Link this repo's packages into $HOME with GNU Stow.
#
#   ./install.sh            core packages (shell, git, nvim, tmux, starship, claude)
#   ./install.sh --gui      also the GUI packages for this OS
#                           (Linux: sway, swaync, waybar; macOS: aerospace, sketchybar)
#   ./install.sh -n         dry run: show what stow would do, change nothing
#
# --no-folding makes stow link individual files and never a whole directory.
# Without it, a plugin fetched into ~/.config/tmux/plugins would land inside
# this repo. Stow refuses to overwrite an existing real file: move it aside or
# diff it against the repo first.
set -euo pipefail

cd "$(dirname "$0")"

gui=0
dry=()
for arg in "$@"; do
  case "$arg" in
    --gui) gui=1 ;;
    -n|--dry-run) dry=(-n -v) ;;
    *) echo "usage: $0 [--gui] [-n]" >&2; exit 2 ;;
  esac
done

command -v stow >/dev/null 2>&1 || { echo "stow not found (brew/apt/dnf install stow)" >&2; exit 1; }

pkgs=(bash zsh git nvim tmux starship claude)
if [ "$gui" -eq 1 ]; then
  pkgs+=(alacritty)
  [ "$(uname)" = "Linux" ] && pkgs+=(sway swaync waybar)
  [ "$(uname)" = "Darwin" ] && pkgs+=(aerospace sketchybar)
fi

stow --no-folding ${dry[@]+"${dry[@]}"} -d "$PWD" -t "$HOME" -R "${pkgs[@]}"
