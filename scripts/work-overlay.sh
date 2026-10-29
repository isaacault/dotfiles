#!/bin/bash
# SPDX-License-Identifier: MIT
# Clone and install the private work overlay. The URL is an argument and is
# never committed here; this repo stays employer-agnostic.
#   scripts/work-overlay.sh git@host:me/overlay.git
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 <overlay-repo-url>" >&2; exit 2; }

DEST="$HOME/.work-dotfiles"

if [ ! -d "$DEST/.git" ]; then
  # accept-new handles first contact with a host on a non-standard SSH port
  # without a manual known_hosts step, and still pins the key afterwards.
  if ! GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10' \
       git clone "$1" "$DEST"; then
    echo "work overlay clone failed: most likely this machine's SSH key is not yet registered with the git host." >&2
    exit 1
  fi
fi

if [ -x "$DEST/install.sh" ]; then
  "$DEST/install.sh"
else
  echo "overlay cloned to $DEST but no executable install.sh found" >&2
fi
