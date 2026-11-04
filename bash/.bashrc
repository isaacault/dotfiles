# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# --- environment (all shells) ---
# Everything above the interactive guard below also applies to `bash -lc ...`
# (via ~/.profile), where tools and agents expect brew, nvim etc. on PATH.
# macOS /etc/profile (path_helper) reorders PATH in every login shell (tmux
# panes, nested `bash -l`), so entries are stripped and re-prepended every time
# rather than skipped when already present. Plain loops: works in bash 3.2.
_path_strip() {
  local d out= IFS=:
  for d in $PATH; do
    [ -n "$d" ] && [ "$d" != "$1" ] && out="${out:+$out:}$d"
  done
  PATH=$out
}
_path_prepend() { _path_strip "$1"; PATH="$1${PATH:+:$PATH}"; }
_path_append() { _path_strip "$1"; PATH="${PATH:+$PATH:}$1"; }

# user-local bins (prepended so they beat distro packages) and the Linux nvim
# tarball; brew is prepended after these, below
[ -d /opt/nvim-linux-x86_64/bin ] && _path_append /opt/nvim-linux-x86_64/bin
[ -d "$HOME/.local/bin" ] && _path_prepend "$HOME/.local/bin"
[ -d "$HOME/bin" ] && _path_prepend "$HOME/bin"

# macOS: silence Apple's "default shell is now zsh" notice, and set up Homebrew
# without forking `brew shellenv`: it spawns subprocesses, and each launch is
# intercepted by endpoint security, which made new terminals slow. Mirrors its
# output; compare after a brew upgrade with:
#   env -i HOME=$HOME /opt/homebrew/bin/brew shellenv
# Apple Silicon lives in /opt/homebrew, Intel in /usr/local.
if [[ $OSTYPE == darwin* ]]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
  # BSD ls has no --color; CLICOLOR turns on its colours (Linux gets them from
  # the dircolors block below)
  export CLICOLOR=1
  for _brew_prefix in /opt/homebrew /usr/local; do
    if [ -x "$_brew_prefix/bin/brew" ]; then
      if [ "$_brew_prefix" = /opt/homebrew ]; then
        export HOMEBREW_PREFIX=$_brew_prefix HOMEBREW_CELLAR=$_brew_prefix/Cellar HOMEBREW_REPOSITORY=$_brew_prefix
      else
        export HOMEBREW_PREFIX=$_brew_prefix HOMEBREW_CELLAR=$_brew_prefix/Cellar HOMEBREW_REPOSITORY=$_brew_prefix/Homebrew
      fi
      _path_prepend "$HOMEBREW_PREFIX/sbin"
      _path_prepend "$HOMEBREW_PREFIX/bin"
      case ":${INFOPATH:-}:" in
        *":$HOMEBREW_PREFIX/share/info:"*) ;;
        *) export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}" ;;
      esac
      break
    fi
  done
  unset _brew_prefix
fi
export PATH

export EDITOR=nvim
export VISUAL=nvim
unset -f _path_strip _path_prepend _path_append

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# fallback prompt (starship replaces this when installed)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- personal (https://github.com/isaacault/dotfiles) ---

# macOS: Homebrew bash-completion@2 (needs bash >= 4.2; its loader skips older
# bash). PATH/HOMEBREW_* are set above the guard.
[ -n "${HOMEBREW_PREFIX:-}" ] && [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

alias vim='nvim'
alias vi='nvim'
alias vimdiff='nvim -d'

# history: deeper, with dup suppression (overrides stock above)
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups

# vi mode (`v` in command mode edits the line in nvim)
set -o vi

# completion QoL
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set mark-symlinked-directories on'

# fzf: Ctrl-R fuzzy history, Ctrl-T file picker
if command -v fzf >/dev/null 2>&1; then
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else
    # fzf < 0.48: distro-shipped bindings
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
  fi
fi

# prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Machine-local: secrets, tokens, machine-specific paths.
# ~/.bashrc.local is untracked and must NEVER move into the dotfiles repo.
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
