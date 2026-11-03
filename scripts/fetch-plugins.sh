#!/bin/bash
# SPDX-License-Identifier: MIT
# Fetch the pinned tmux plugins into ~/.config. Idempotent: a plugin
# directory that already exists is left alone; delete it to re-fetch.
#
# PINNED for reproducibility: each is a versioned archive (a tag or an exact
# commit), so every machine gets identical plugins regardless of when it was
# set up. To upgrade, bump the URL here in one reviewable commit.
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

fetch() {
  local dest="$CONFIG/$1" url="$2"
  [ -d "$dest" ] && return 0
  mkdir -p "$dest"
  curl -fsSL "$url" | tar xz --strip-components=1 -C "$dest"
  echo "fetched $1"
}

# tmux plugins (TPM expects them under ~/.config/tmux/plugins/; catppuccin/tmux
# deliberately lands as "tmux", the name TPM uses)
fetch tmux/plugins/tpm              https://github.com/tmux-plugins/tpm/archive/e261deb1b47614eed3400089ce7197dc68acc4eb.tar.gz
fetch tmux/plugins/tmux             https://github.com/catppuccin/tmux/archive/refs/tags/v2.3.0.tar.gz
fetch tmux/plugins/tmux-resurrect   https://github.com/tmux-plugins/tmux-resurrect/archive/cff343cf9e81983d3da0c8562b01616f12e8d548.tar.gz
fetch tmux/plugins/tmux-continuum   https://github.com/tmux-plugins/tmux-continuum/archive/0698e8f4b17d6454c71bf5212895ec055c578da0.tar.gz
