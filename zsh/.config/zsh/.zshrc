# Zsh Options
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.

setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.


# Aliases
alias vimdiff='nvim -d'
alias vim='nvim'
alias vi='nvim'

# Keep PATH/FPATH free of duplicates. Duplicate fpath entries change the file
# count compinit validates its cache against, forcing a rebuild.
typeset -U path fpath

# Add brew to path without forking `brew shellenv`: it is a script that spawns
# subprocesses, and each launch is intercepted by endpoint security, which made
# new terminals intermittently slow. Mirrors its output; compare after a brew
# upgrade with: env -i HOME=$HOME /opt/homebrew/bin/brew shellenv
# (Not exported: FPATH is not, so child shells don't inherit and duplicate it.)
# Must run before compinit so brew's completions are on fpath.
if [[ $OSTYPE == darwin* && -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew HOMEBREW_CELLAR=/opt/homebrew/Cellar HOMEBREW_REPOSITORY=/opt/homebrew
  fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
  path=($HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin $path)
  [[ ":$INFOPATH:" == *":$HOMEBREW_PREFIX/share/info:"* ]] || export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
fi

# Initialise completion
# (Docker Desktop installs its completions here; must be on fpath before compinit)
[[ -d $HOME/.docker/completions ]] && fpath=($HOME/.docker/completions $fpath)
source $ZDOTDIR/completion.zsh

# Vim mode
bindkey -v
export KEYTIMEOUT=1

# esc-v to edit command in text editor (vim)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# User-local bins (pipx, claude, etc.), matching .bashrc
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$PATH:$HOME/.local/bin"

# Set up fzf key bindings and fuzzy completion. `fzf --zsh` output is cached and
# regenerated only when the fzf binary changes, saving a launch per shell.
if (( $+commands[fzf] )); then
  _fzf_cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/fzf.zsh
  if [[ ! -s $_fzf_cache || $commands[fzf] -nt $_fzf_cache ]]; then
    mkdir -p ${_fzf_cache:h}
    # fzf < 0.48 (Ubuntu 24.04 ships 0.44) has no --zsh; fall back to the
    # scripts the Debian/Ubuntu package installs.
    fzf --zsh >| $_fzf_cache 2>/dev/null ||
      cat /usr/share/doc/fzf/examples/{key-bindings,completion}.zsh >| $_fzf_cache 2>/dev/null
  fi
  [[ -s $_fzf_cache ]] && source $_fzf_cache
  unset _fzf_cache
fi

# Syntax Highlighting
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Pure Prompt: https://github.com/sindresorhus/pure
fpath+=($ZDOTDIR/plugins/pure)
autoload -U promptinit; promptinit
prompt pure

# Machine-local: secrets, tokens, machine-specific config.
# $ZDOTDIR/.zshrc.local is untracked and must NEVER move into the dotfiles repo.
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
