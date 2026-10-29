# Design

Decisions made 2026-07-03, consolidating configs previously spread over
`isaacault/{nvim,tmux,zsh,.dotfiles,dotvim}` + live machines. Migrated from
chezmoi to plain git + GNU Stow on 2026-10-29; the earlier chezmoi rationale
is in this file's git history.

## Why plain git + stow

- **Nothing to learn beyond git.** The repo is ordinary files. Editing a live
  config edits the repo file (it is a symlink), so `git status` shows drift
  with no separate state machine, and nothing needs "re-adding".
- **Differences live in the files, not in a templating layer.** Per-machine
  values go in untracked `*.local` files that the tracked files source or
  include; OS differences branch on `uname` inside the file.
- **Public and private repos cannot mix.** Work config is a separate repo that
  is stowed on top, so a `git add -A` in this repo can never pick it up.
- Stow is small, packaged everywhere, and installable without root from source.

Trade-offs accepted: symlinks instead of copies (a few tools dislike symlinked
configs; none of the managed ones do), and no per-machine file generation.

## Decisions

1. **Full consolidation.** Old repos archived; this repo owns all config.
   Plugins that used to be git submodules are fetched by
   `scripts/fetch-plugins.sh` from pinned archives (tag or exact commit).
   Plugin *managers* (lazy.nvim, TPM) still own plugin installs at runtime;
   `lazy-lock.json` pins nvim plugins.
2. **Packages are the unit of selection.** Each top-level folder is a stow
   package. `install.sh` links the core set everywhere and the GUI set with
   `--gui` (sway/swaync/waybar only on Linux).
3. **Secrets live outside the repo, period.** `.bashrc` is generic and sources
   untracked `~/.bashrc.local`; `.gitconfig` includes `~/.gitconfig.local`.
   The repo must remain fully linkable with no secrets present.
   `.gitignore` excludes `*.local` and `*.work` as a safety net.
4. **Provisioning is opt-in.** `install.sh` only links; packages install only
   when `scripts/install-packages.sh` is run. Keeps work/ssh boxes config-only.
5. **bash on work boxes (starship), zsh on personal (pure)**: both managed
   everywhere; login shell choice stays per-machine.
6. **Git identity is layered**: the committed default is the personal email; a
   work machine overrides it in `~/.gitconfig.local`; `isaacault/*` GitHub
   remotes are forced back to the personal email via `includeIf hasconfig`,
   which is ordered after the local include so it wins.
7. **Work-specific config is an overlay, not code.** The repo is public and
   employer-agnostic: internal hostnames, tool names and the work email never
   appear in it. `scripts/work-overlay.sh <url>` clones the private overlay
   to `~/.work-dotfiles` and runs its `install.sh`; the overlay plugs into the
   same untracked `.local` hook files and never becomes commits layered on
   this repo. The URL is an argument, never committed.
8. **XDG paths standardized.** The old `.zshenv` exported non-standard
   `XDG_DATA_HOME=~/.config/local/share` and `XDG_CACHE_HOME=~/.config/cache`;
   both now use spec defaults (`~/.local/share`, `~/.cache`).
   `scripts/migrate-xdg.sh` is the one-time cleanup for older machines.
9. **`--no-folding` always.** Stow would otherwise link a whole directory when
   the target doesn't exist, and plugins fetched into it would land in the repo.

## Layout notes

- zsh is XDG-first: `~/.zshenv` only bootstraps `ZDOTDIR=~/.config/zsh`.
- tmux config is `~/.config/tmux/tmux.conf` (tmux >= 3.1); the legacy
  `~/.tmux.conf` symlink was retired.
- `alacritty.yml` (deprecated) was dropped; `alacritty.toml` kept.
- i3 + polybar were superseded by sway + waybar and removed.
- nvim's `node_modules`/`package*.json` (runtime artifacts) and the old
  per-repo `setup.sh` scripts were not folded in.

## SSH clones on fresh boxes

The overlay is cloned over SSH, often from a host on a non-standard port whose
key isn't in `known_hosts` yet; an unattended clone would otherwise hang on
host-key verification. `scripts/work-overlay.sh` sets
`GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10'`:
the port comes from the URL, new host keys are accepted on first contact and
pinned thereafter, and a dead host fails fast. On failure, almost always an
SSH key not yet registered with the host, it prints the fix and exits non-zero;
re-run it once access is sorted. The key itself must be registered first.

## Claude Code

`~/.claude/keybindings.json` only. `CLAUDE.md` and `settings.json` live in a
separate private repo. Config only, never state/credentials (`~/.claude.json`,
sessions, history, etc. stay out), and never the work-internal,
externally-managed `skills/`.

## Still planned

- **aerospace**: add `aerospace/.config/aerospace/aerospace.toml` from the Mac,
  and add `aerospace` to the macOS GUI packages in `install.sh`.
