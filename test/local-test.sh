#!/bin/bash
# SPDX-License-Identifier: MIT
# Docker-free smoke test: apply the repo into scratch $HOME dirs and assert
# module gating, templating, externals, and executable bits. Needs network
# (externals) but no root/docker.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
CZ="${CHEZMOI:-$(command -v chezmoi || echo "$HOME/.local/bin/chezmoi")}"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Run chezmoi fully jailed into a scratch home — HOME alone is not enough:
# inherited XDG_* vars would leak the generated config into the real one.
cz() {
  local home="$1"; shift
  env HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" \
      XDG_DATA_HOME="$home/.local/share" "$CZ" "$@"
}

# --- case 1: personal + gui ---
H1="$(mktemp -d)"
cz "$H1" init --apply --source "$SRC" \
  --promptBool work=false,gui=true,provision=false

[ -f "$H1/.bashrc" ]                          || fail "bashrc missing"
[ -f "$H1/.zshenv" ]                          || fail "zshenv missing"
[ -f "$H1/.config/zsh/.zshrc" ]               || fail "zshrc missing"
[ -f "$H1/.config/tmux/tmux.conf" ]           || fail "tmux.conf missing"
[ -f "$H1/.config/nvim/init.lua" ]            || fail "nvim missing"
[ -f "$H1/.config/starship.toml" ]            || fail "starship missing"
grep -q isaac.ault@gmail.com "$H1/.gitconfig" || fail "personal email not set"
[ -f "$H1/.config/sway/config" ]              || fail "sway missing (gui=true)"
[ -x "$H1/.config/waybar/mediaplayer.sh" ]    || fail "waybar script not executable"
[ -f "$H1/.config/tmux/plugins/tpm/tpm" ]     || fail "external tpm not fetched"
[ -d "$H1/.config/zsh/plugins/pure" ]         || fail "external pure not fetched"
[ ! -e "$H1/.work-dotfiles" ]                 || fail "work overlay ran (work=false)"
[ ! -e "$H1/README.md" ]                      || fail "README leaked"
[ ! -e "$H1/docs" ]                           || fail "docs leaked"
! grep -qrE '(nvapi-|glpat-|ghp_)' "$H1/.bashrc" "$H1/.gitconfig" "$H1/.config/zsh" \
                                              || fail "secret pattern in applied home"
rm -rf "$H1"
echo "case 1 (personal+gui) OK"

# --- case 2: work + no gui ---
# work values are placeholders: real ones are typed once at init and only
# ever live in the machine-local (untracked) chezmoi.toml. The overlay is a
# throwaway fixture repo proving the clone-and-install mechanism end to end.
OVR="$(mktemp -d)"
git -C "$OVR" init -q
printf '#!/bin/sh\ntouch "$HOME/.overlay-ran"\n' > "$OVR/install.sh"
chmod +x "$OVR/install.sh"
git -C "$OVR" add -A
git -C "$OVR" -c user.name=fixture -c user.email=fixture@example.com \
  commit -qm "overlay fixture"

H2="$(mktemp -d)"
cz "$H2" init --apply --source "$SRC" \
  --promptBool work=true,gui=false,provision=false \
  --promptString "email=work@example.com,overlay=file://$OVR"

grep -q work@example.com "$H2/.gitconfig"     || fail "work email not set"
[ -f "$H2/.config/git/personal" ]             || fail "personal git include missing"
grep -q '\.local/share' "$H2/.zshenv"         || fail "XDG_DATA_HOME not standard"
[ -d "$H2/.work-dotfiles/.git" ]              || fail "overlay not cloned"
[ -f "$H2/.overlay-ran" ]                     || fail "overlay install.sh did not run"
[ ! -e "$H2/.config/sway" ]                   || fail "sway leaked (gui=false)"
[ ! -e "$H2/.config/alacritty" ]              || fail "alacritty leaked (gui=false)"
rm -rf "$H2" "$OVR"
echo "case 2 (work+nogui) OK"

echo "LOCAL SMOKE TEST OK"
