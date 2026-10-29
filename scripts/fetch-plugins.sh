#!/bin/bash
# SPDX-License-Identifier: MIT
# Fetch the pinned tmux and zsh plugins into ~/.config. Idempotent: a plugin
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

# zsh plugins (ZDOTDIR = ~/.config/zsh)
fetch zsh/plugins/zsh-completions         https://github.com/zsh-users/zsh-completions/archive/03bae0bf3f9c4ab894f1f11a31ffe7a1e1029879.tar.gz
fetch zsh/plugins/zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting/archive/1d85c692615a25fe2293bdd44b34c217d5d2bf04.tar.gz
fetch zsh/plugins/pure                    https://github.com/sindresorhus/pure/archive/d0f35c270bad6d3df57f8da3f8d02e5465fb9b3d.tar.gz
