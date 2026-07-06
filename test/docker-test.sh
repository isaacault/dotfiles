#!/bin/bash
# SPDX-License-Identifier: MIT
# Fresh-machine test: apply this repo onto a pristine Ubuntu container as a
# non-root user, then assert the expected targets landed.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"

# --- case 1: config-only (provision=false), gui=true ---
docker run --rm -v "$SRC:/dotfiles:ro" ubuntu:24.04 bash -euo pipefail -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y -qq git curl ca-certificates >/dev/null
  useradd -m tester
  su - tester -c "
    set -eu
    sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \$HOME/.local/bin >/dev/null
    \$HOME/.local/bin/chezmoi init --apply --source /dotfiles \
      --promptBool work=false,gui=true,provision=false \
      --promptString kb=

    # core
    test -f \$HOME/.bashrc
    test -f \$HOME/.zshenv
    test -f \$HOME/.config/zsh/.zshrc
    test -f \$HOME/.config/tmux/tmux.conf
    test -f \$HOME/.config/nvim/init.lua
    test -f \$HOME/.config/starship.toml
    grep -q isaac.ault@gmail.com \$HOME/.gitconfig      # personal email on non-work

    # externals fetched (pinned archives)
    test -f \$HOME/.config/tmux/plugins/tpm/tpm
    test -f \$HOME/.config/tmux/plugins/tmux/catppuccin.tmux
    test -d \$HOME/.config/zsh/plugins/pure

    # gui module present (gui=true)
    test -f \$HOME/.config/sway/config
    test -x \$HOME/.config/waybar/mediaplayer.sh        # executable bit restored

    # work module absent (work=false)
    test ! -e \$HOME/.work-dotfiles

    # repo meta not deployed
    test ! -e \$HOME/README.md
    test ! -e \$HOME/docs
    test ! -e \$HOME/test

    # no secrets anywhere in the applied home
    ! grep -rE \"(nvapi-|glpat-|ghp_)\" \$HOME --exclude-dir=.local || exit 1

    echo FRESH-MACHINE TEST OK
  "
'

# --- case 2: provision=true — exercises the package install plus the
# nvim/starship/Claude CLI installers. Needs sudo, so grant the tester
# passwordless sudo and keep DEBIAN_FRONTEND across sudo for unattended apt. ---
echo "=== provision=true (packages + nvim/starship/claude) ==="
docker run --rm -v "$SRC:/dotfiles:ro" ubuntu:24.04 bash -euo pipefail -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y -qq git curl ca-certificates sudo >/dev/null
  useradd -m tester
  printf "tester ALL=(ALL) NOPASSWD:ALL\nDefaults env_keep += \"DEBIAN_FRONTEND\"\n" > /etc/sudoers.d/tester
  su - tester -c "
    set -eu
    export DEBIAN_FRONTEND=noninteractive
    sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \$HOME/.local/bin >/dev/null
    \$HOME/.local/bin/chezmoi init --apply --source /dotfiles \
      --promptBool work=false,gui=false,provision=true \
      --promptString kb=

    # provisioned tooling landed
    command -v jq >/dev/null                     # apt package (needed by install-mcp)
    test -x \$HOME/.local/bin/nvim               # neovim release tarball
    test -x \$HOME/.local/bin/starship           # starship installer
    test -x \$HOME/.local/bin/claude             # Claude CLI installer

    echo PROVISION TEST OK
  "
'
