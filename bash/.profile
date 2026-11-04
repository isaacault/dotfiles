# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# PATH (~/bin, ~/.local/bin, Homebrew) is set once in ~/.bashrc, above its
# interactive guard, so it also applies to `bash -lc`. Don't prepend here: it
# would duplicate entries and undo the ordering.

export XDG_CONFIG_HOME="$HOME/.config"
