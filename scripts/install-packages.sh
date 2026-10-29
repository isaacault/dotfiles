#!/bin/bash
# SPDX-License-Identifier: MIT
# Core tool install (stow included). Run by hand on a new machine:
#   scripts/install-packages.sh [--devtools]
# --devtools also installs the enhanced CLI tools (eza, bat, zoxide, uv, glab, node).
set -euo pipefail

devtools=0
[ "${1:-}" = "--devtools" ] && devtools=1

if [ "$(uname)" = "Darwin" ]; then
  command -v brew >/dev/null 2>&1 || { echo "Homebrew required first: https://brew.sh" >&2; exit 1; }
  brew install stow git tmux zsh fzf ripgrep fd jq neovim starship
  [ "$devtools" -eq 1 ] && brew install bat eza zoxide uv glab node
else
  SUDO=""
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"

  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq stow git curl tmux zsh fzf ripgrep fd-find xclip jq build-essential
    [ "$devtools" -eq 1 ] && $SUDO apt-get install -y -qq bat eza nodejs npm
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y -q stow git curl tmux zsh fzf ripgrep fd-find xclip jq gcc gcc-c++ make
    [ "$devtools" -eq 1 ] && $SUDO dnf install -y -q bat eza nodejs npm
  else
    echo "No supported package manager (apt/dnf): install stow, git, tmux, zsh, fzf, ripgrep, fd, jq manually" >&2
  fi

  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"

  # neovim: distro repos lag badly; use the official release tarball
  if ! command -v nvim >/dev/null 2>&1 && [ ! -d "$HOME/.local/opt/nvim-linux-x86_64" ]; then
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      | tar xz -C "$HOME/.local/opt"
    ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
  fi

  # starship prompt (bash uses it; zsh uses pure)
  if ! command -v starship >/dev/null 2>&1; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  fi

  if [ "$devtools" -eq 1 ]; then
    # not in standard apt/dnf repos
    command -v zoxide >/dev/null 2>&1 || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
    if ! command -v glab >/dev/null 2>&1; then
      GLAB_VERSION=$(curl -fsSL https://gitlab.com/api/v4/projects/34675721/releases | grep -oP '"tag_name":"\Kv[^"]+' | head -1)
      curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION#v}_linux_amd64.tar.gz" \
        | tar xz -C "$HOME/.local/bin" --strip-components=2 bin/glab
    fi
  fi
fi

# Claude Code CLI (cross-platform): the native installer symlinks
# ~/.local/bin/claude. The -x test keeps this idempotent before PATH reloads.
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
