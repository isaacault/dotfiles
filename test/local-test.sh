#!/bin/bash
# SPDX-License-Identifier: MIT
# Docker-free smoke test: stow the repo into scratch $HOME dirs and assert
# module gating, symlinks, plugin fetch, and executable bits. Needs stow and
# network (plugins) but no root/docker.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

# --- case 1: core + gui ---
H1="$(mktemp -d)"
HOME="$H1" "$SRC/install.sh" --gui

[ -L "$H1/.bashrc" ]                          || fail "bashrc not linked"
[ -f "$H1/.zshenv" ]                          || fail "zshenv missing"
[ -f "$H1/.config/zsh/.zshrc" ]               || fail "zshrc missing"
[ -f "$H1/.config/tmux/tmux.conf" ]           || fail "tmux.conf missing"
[ -f "$H1/.config/nvim/init.lua" ]            || fail "nvim missing"
[ -f "$H1/.config/starship.toml" ]            || fail "starship missing"
[ -f "$H1/.config/alacritty/alacritty.toml" ] || fail "alacritty missing (--gui)"
grep -q isaac.ault@gmail.com "$H1/.gitconfig" || fail "personal email not set"
[ -f "$H1/.claude/keybindings.json" ]         || fail "claude keybindings missing"
if [ "$(uname)" = "Linux" ]; then
  [ -f "$H1/.config/sway/config" ]            || fail "sway missing (--gui)"
  [ -x "$H1/.config/waybar/mediaplayer.sh" ]  || fail "waybar script not executable"
else
  [ ! -e "$H1/.config/sway" ]                 || fail "sway linked on non-Linux"
fi
[ ! -e "$H1/README.md" ]                      || fail "README leaked"
[ ! -e "$H1/docs" ]                           || fail "docs leaked"

# plugins must land in $HOME, never inside the repo (needs --no-folding)
HOME="$H1" XDG_CONFIG_HOME="$H1/.config" "$SRC/scripts/fetch-plugins.sh"
[ -f "$H1/.config/tmux/plugins/tpm/tpm" ]     || fail "plugin tpm not fetched"
[ -d "$H1/.config/zsh/plugins/pure" ]         || fail "plugin pure not fetched"
[ ! -e "$SRC/tmux/.config/tmux/plugins" ]     || fail "plugins leaked into the repo"

# re-running must be a no-op, not an error
HOME="$H1" "$SRC/install.sh" --gui

! grep -qrE '(nvapi-|glpat-|ghp_)' "$H1/.bashrc" "$H1/.gitconfig" "$H1/.config/zsh/" \
                                              || fail "secret pattern in linked home"
rm -rf "$H1"
echo "case 1 (core+gui) OK"

# --- case 2: core only ---
H2="$(mktemp -d)"
HOME="$H2" "$SRC/install.sh"
[ -f "$H2/.config/nvim/init.lua" ]            || fail "nvim missing"
[ ! -e "$H2/.config/sway" ]                   || fail "sway linked without --gui"
[ ! -e "$H2/.config/alacritty" ]              || fail "alacritty linked without --gui"
rm -rf "$H2"
echo "case 2 (core only) OK"

# --- case 3: work overlay clone-and-install mechanism ---
OVR="$(mktemp -d)"
git -C "$OVR" init -q
# shellcheck disable=SC2016  # $HOME must stay literal: it expands when the generated install.sh runs
printf '#!/bin/sh\ntouch "$HOME/.overlay-ran"\n' > "$OVR/install.sh"
chmod +x "$OVR/install.sh"
git -C "$OVR" add -A
git -C "$OVR" -c user.name=fixture -c user.email=fixture@example.com commit -qm "overlay fixture"
H3="$(mktemp -d)"
HOME="$H3" "$SRC/scripts/work-overlay.sh" "file://$OVR"
[ -d "$H3/.work-dotfiles/.git" ]              || fail "overlay not cloned"
[ -f "$H3/.overlay-ran" ]                     || fail "overlay install.sh did not run"
rm -rf "$H3" "$OVR"
echo "case 3 (work overlay) OK"

echo "LOCAL SMOKE TEST OK"
