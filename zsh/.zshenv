#!/usr/bin/env zsh

# XDG Base Directory (spec defaults — old machines used non-standard paths;
# run scripts/migrate-xdg.sh once on those)
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Text Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Zsh Environment Variables
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export HISTFILE="$ZDOTDIR/.zsh_history"    # History filepath
export HISTSIZE=10000                      # Maximum events for internal history
export SAVEHIST=10000                      # Maximum events in history file
