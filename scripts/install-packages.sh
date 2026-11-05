#!/bin/bash
# SPDX-License-Identifier: MIT
# Core tool install (stow included). Run by hand on a new machine:
#   scripts/install-packages.sh [--devtools] [--gui] [--extras]
# The package lists live in packages/: Brewfile* on macOS, *.txt for apt/dnf.
#   always      packages/Brewfile           packages/{apt,dnf}.txt
#   --devtools  packages/Brewfile.devtools  packages/{apt,dnf}-devtools.txt
#               (eza, bat, zoxide, uv, glab, node)
#   --gui       packages/Brewfile.gui       packages/{apt,dnf}-gui.txt
#   --extras    packages/Brewfile.extras    macOS only: personal, not needed by the configs
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Versions for the Linux installers below. To bump one, look up the latest
# release (gh api repos/<owner>/<repo>/releases/latest --jq .tag_name), change
# it here, and check the installer URL still exists. Claude Code's installer
# and glab (always the latest release) are not pinned. zoxide's installer has
# no version flag: its pin fixes the script, but it still installs the latest.
STARSHIP_VERSION="v1.27.0"   # starship/starship, tag with the leading v
ZOXIDE_VERSION="v0.10.0"     # ajeetdsouza/zoxide, tag with the leading v
UV_VERSION="0.13.7"          # astral-sh/uv, no leading v

# scratch space for downloaded installers; removed on exit
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# fetch <url> <file>: download to a file so a failed or truncated download is
# never executed
fetch() { curl -fsSL --retry 3 "$1" -o "$2"; }

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
  [ "$extras" -eq 1 ] && echo "note: --extras has no Linux package list; ignoring" >&2

  SUDO=""
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"

  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -qq
    pkgs apt.txt | xargs $SUDO apt-get install -y -qq
    [ "$devtools" -eq 1 ] && pkgs apt-devtools.txt | xargs $SUDO apt-get install -y -qq
    [ "$gui" -eq 1 ] && pkgs apt-gui.txt | xargs $SUDO apt-get install -y -qq
  elif command -v dnf >/dev/null 2>&1; then
    pkgs dnf.txt | xargs $SUDO dnf install -y -q
    [ "$devtools" -eq 1 ] && pkgs dnf-devtools.txt | xargs $SUDO dnf install -y -q
    [ "$gui" -eq 1 ] && pkgs dnf-gui.txt | xargs $SUDO dnf install -y -q
  else
    echo "No supported package manager (apt/dnf): install the packages in packages/apt.txt manually" >&2
  fi

  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"

  # neovim: distro repos lag badly; use the official release tarball
  # (published for x86_64 and arm64, e.g. a Jetson or a Raspberry Pi)
  case "$(uname -m)" in
    x86_64|amd64) nvim_arch=x86_64 ;;
    aarch64|arm64) nvim_arch=arm64 ;;
    *) nvim_arch="" ; echo "nvim: no release tarball for $(uname -m); install it yourself" >&2 ;;
  esac
  if [ -n "$nvim_arch" ] && ! command -v nvim >/dev/null 2>&1 && [ ! -d "$HOME/.local/opt/nvim-linux-$nvim_arch" ]; then
    fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$nvim_arch.tar.gz" "$tmp/nvim.tar.gz"
    tar xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt"
    ln -sf "$HOME/.local/opt/nvim-linux-$nvim_arch/bin/nvim" "$HOME/.local/bin/nvim"
  fi

  # starship prompt
  if ! command -v starship >/dev/null 2>&1; then
    fetch https://starship.rs/install.sh "$tmp/starship.sh"
    sh "$tmp/starship.sh" -y -v "$STARSHIP_VERSION" -b "$HOME/.local/bin"
  fi

  if [ "$devtools" -eq 1 ]; then
    # not in standard apt/dnf repos
    if ! command -v zoxide >/dev/null 2>&1; then
      fetch "https://raw.githubusercontent.com/ajeetdsouza/zoxide/${ZOXIDE_VERSION}/install.sh" "$tmp/zoxide.sh"
      sh "$tmp/zoxide.sh"
    fi
    if ! command -v uv >/dev/null 2>&1; then
      fetch "https://astral.sh/uv/${UV_VERSION}/install.sh" "$tmp/uv.sh"
      sh "$tmp/uv.sh"
    fi
    if ! command -v glab >/dev/null 2>&1; then
      case "$(uname -m)" in
        x86_64|amd64) glab_arch=amd64 ;;
        aarch64|arm64) glab_arch=arm64 ;;
        *) echo "glab: unsupported architecture $(uname -m)" >&2; exit 1 ;;
      esac
      fetch https://gitlab.com/api/v4/projects/34675721/releases "$tmp/glab-releases.json"
      GLAB_VERSION="$(jq -r '.[0].tag_name // empty' "$tmp/glab-releases.json")"
      [ -n "$GLAB_VERSION" ] || { echo "glab: could not determine the latest version" >&2; exit 1; }
      fetch "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION#v}_linux_${glab_arch}.tar.gz" "$tmp/glab.tar.gz"
      tar xzf "$tmp/glab.tar.gz" -C "$HOME/.local/bin" --strip-components=1 bin/glab
    fi
  fi
fi

# Claude Code CLI (cross-platform): the native installer symlinks
# ~/.local/bin/claude. The -x test keeps this idempotent before PATH reloads.
# The installer script can't be pinned or checksummed from here (it fetches
# the current release itself); it is downloaded first so a failed download
# never runs, and it is the vendor's own script, so this trusts claude.ai.
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
  fetch https://claude.ai/install.sh "$tmp/claude.sh"
  bash "$tmp/claude.sh"
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
