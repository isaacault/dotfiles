#!/bin/bash
# SPDX-License-Identifier: MIT
# Core tool install (stow included). Run by hand on a new machine:
#   scripts/install-packages.sh [--devtools] [--gui] [--extras]
# The package lists live in packages/: Brewfile* on macOS, *.txt for apt/dnf.
#   always      packages/Brewfile           packages/{apt,dnf}.txt
#   --devtools  packages/Brewfile.devtools  packages/{apt,dnf}-devtools.txt
#               (eza, bat, zoxide, uv, glab, node)
#   --gui       packages/Brewfile.gui       macOS only
#   --extras    packages/Brewfile.extras    macOS only: personal, not needed by the configs
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

devtools=0 gui=0 extras=0
for arg in "$@"; do
  case "$arg" in
    --devtools) devtools=1 ;;
    --gui) gui=1 ;;
    --extras) extras=1 ;;
    *) echo "usage: $0 [--devtools] [--gui] [--extras]" >&2; exit 2 ;;
  esac
done

# package names from a manifest: one per line, blank lines and # comments ignored
pkgs() { grep -v -E '^[[:space:]]*(#|$)' "$ROOT/packages/$1"; }

if [ "$(uname)" = "Darwin" ]; then
  command -v brew >/dev/null 2>&1 || { echo "Homebrew required first: https://brew.sh" >&2; exit 1; }
  brew bundle --file="$ROOT/packages/Brewfile"
  [ "$devtools" -eq 1 ] && brew bundle --file="$ROOT/packages/Brewfile.devtools"
  if [ "$gui" -eq 1 ]; then
    brew bundle --file="$ROOT/packages/Brewfile.gui"
    # sketchybar's Lua module is not a brew package; build the pinned version
    "$ROOT/scripts/install-sbarlua.sh"
  fi
  [ "$extras" -eq 1 ] && brew bundle --file="$ROOT/packages/Brewfile.extras"
else
  [ "$gui" -eq 1 ] || [ "$extras" -eq 1 ] && echo "note: --gui and --extras have no Linux package lists yet; ignoring" >&2

  SUDO=""
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"

  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -qq
    pkgs apt.txt | xargs $SUDO apt-get install -y -qq
    [ "$devtools" -eq 1 ] && pkgs apt-devtools.txt | xargs $SUDO apt-get install -y -qq
  elif command -v dnf >/dev/null 2>&1; then
    pkgs dnf.txt | xargs $SUDO dnf install -y -q
    [ "$devtools" -eq 1 ] && pkgs dnf-devtools.txt | xargs $SUDO dnf install -y -q
  else
    echo "No supported package manager (apt/dnf): install the packages in packages/apt.txt manually" >&2
  fi

  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"

  # neovim: distro repos lag badly; use the official release tarball
  if ! command -v nvim >/dev/null 2>&1 && [ ! -d "$HOME/.local/opt/nvim-linux-x86_64" ]; then
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      | tar xz -C "$HOME/.local/opt"
    ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
  fi

  # starship prompt
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

# bash is the shell everywhere. macOS ships bash 3.2, so make Homebrew's the
# login shell; changing /etc/shells needs sudo, so print the steps instead.
if [ "$(uname)" = "Darwin" ]; then
  want="$(brew --prefix)/bin/bash"
  [ "${SHELL:-}" = "$want" ] && want=""
else
  want="/bin/bash"
  case "${SHELL:-}" in */bash) want="" ;; esac
fi
if [ -n "$want" ]; then
  echo "Login shell is ${SHELL:-unset}. To switch to bash:"
  grep -qxF "$want" /etc/shells || echo "  echo $want | sudo tee -a /etc/shells"
  echo "  chsh -s $want"
fi
