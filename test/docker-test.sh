#!/bin/bash
# SPDX-License-Identifier: MIT
# Fresh-machine test: stow this repo onto a pristine Ubuntu container as a
# non-root user, then assert the expected targets landed. The repo is mounted
# read-only, so any plugin or state that wrongly landed inside it would fail.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"

# --- case 1: config only, with gui ---
docker run --rm -v "$SRC:/dotfiles:ro" ubuntu:24.04 bash -euo pipefail -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y -qq git curl ca-certificates stow >/dev/null
  useradd -m tester
  su - tester -c "
    set -eu
    /dotfiles/install.sh --gui
    /dotfiles/scripts/fetch-plugins.sh

    # core
    test -f \$HOME/.bashrc
    test -f \$HOME/.zshenv
    test -f \$HOME/.config/zsh/.zshrc
    test -f \$HOME/.config/tmux/tmux.conf
    test -f \$HOME/.config/nvim/init.lua
    test -f \$HOME/.config/starship.toml
    grep -q isaac.ault@gmail.com \$HOME/.gitconfig

    # plugins fetched (pinned archives)
    test -f \$HOME/.config/tmux/plugins/tpm/tpm
    test -f \$HOME/.config/tmux/plugins/tmux/catppuccin.tmux
    test -d \$HOME/.config/zsh/plugins/pure

    # gui module present
    test -f \$HOME/.config/sway/config
    test -x \$HOME/.config/waybar/mediaplayer.sh

    # repo meta not deployed
    test ! -e \$HOME/README.md
    test ! -e \$HOME/docs
    test ! -e \$HOME/test

    # no secrets anywhere in the linked home
    ! grep -rE \"(nvapi-|glpat-|ghp_)\" \$HOME --exclude-dir=.local || exit 1

    echo FRESH-MACHINE TEST OK
  "
'

# --- case 2: package install. Exercises apt plus the nvim/starship/Claude
# CLI installers. Needs sudo, so grant the tester passwordless sudo and keep
# DEBIAN_FRONTEND across sudo for unattended apt. ---
echo "=== install-packages (packages + nvim/starship/claude) ==="
docker run --rm -v "$SRC:/dotfiles:ro" ubuntu:24.04 bash -euo pipefail -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y -qq git curl ca-certificates sudo >/dev/null
  useradd -m tester
  printf "tester ALL=(ALL) NOPASSWD:ALL\nDefaults env_keep += \"DEBIAN_FRONTEND\"\n" > /etc/sudoers.d/tester
  su - tester -c "
    set -eu
    export DEBIAN_FRONTEND=noninteractive
    /dotfiles/scripts/install-packages.sh

    command -v stow >/dev/null
    command -v jq >/dev/null
    test -x \$HOME/.local/bin/nvim
    test -x \$HOME/.local/bin/starship
    test -x \$HOME/.local/bin/claude

    echo PROVISION TEST OK
  "
'
