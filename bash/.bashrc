# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

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

# macOS: silence Apple's "default shell is now zsh" notice, and set up Homebrew
# without forking `brew shellenv`: it spawns subprocesses, and each launch is
# intercepted by endpoint security, which made new terminals slow. Mirrors its
# output; compare after a brew upgrade with:
#   env -i HOME=$HOME /opt/homebrew/bin/brew shellenv
# Must come before the fzf and starship checks below, which need brew's PATH.
if [[ $OSTYPE == darwin* ]]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
  # BSD ls has no --color; CLICOLOR turns on its colours (Linux gets them from
  # the dircolors block above)
  export CLICOLOR=1
  if [ -x /opt/homebrew/bin/brew ]; then
    export HOMEBREW_PREFIX=/opt/homebrew HOMEBREW_CELLAR=/opt/homebrew/Cellar HOMEBREW_REPOSITORY=/opt/homebrew
    case ":$PATH:" in
      *":$HOMEBREW_PREFIX/bin:"*) ;;
      *) export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH" ;;
    esac
    case ":${INFOPATH:-}:" in
      *":$HOMEBREW_PREFIX/share/info:"*) ;;
      *) export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}" ;;
    esac
    # bash-completion@2 (needs bash >= 4.2; its loader skips older bash)
    [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
  fi
fi

export EDITOR=nvim
export VISUAL=nvim
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

# user-local bins
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin" ;;
esac
[ -d /opt/nvim-linux-x86_64/bin ] && export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

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
