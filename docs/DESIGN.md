# Design

Decisions made 2026-07-03, consolidating configs previously spread over
`isaacault/{nvim,tmux,zsh,.dotfiles,dotvim}` + live machines.

## Why chezmoi (vs stow / bare repo / hand-rolled shell)

- Machines are a **work/personal mix**: templates + per-machine prompt data
  handle the differences in one branch (git email, work-only files, GUI
  modules) with no branch drift or hostname conditionals in configs.
- **State machine, not one-shot installer**: `diff` before apply, `status` for
  drift, `re-add` to absorb hot fixes made on remote boxes.
- **Copies, not symlinks**: correct private-file permissions, nothing breaks
  if the repo moves, tools that dislike symlinked configs just work.
- Single static binary, no root: works on locked-down ssh boxes.

## Decisions

1. **Full consolidation.** Old repos archived; this repo owns all config.
   Their git submodules became `.chezmoiexternal.toml` entries (tmux + zsh
   plugins), refreshed weekly. Plugin *managers* (lazy.nvim, TPM) still own
   plugin installs at runtime; `lazy-lock.json` pins nvim plugins.
2. **Machine flags, not OS sniffing alone**: `work`, `gui`, `provision`
   prompted once at init (`promptBoolOnce`), stored per-machine. OS gates
   combine with flags in `.chezmoiignore` (e.g. sway needs linux AND gui).
3. **Secrets live outside the repo, period.** The repo's `.bashrc` is generic
   and sources untracked `~/.bashrc.local` for secrets/machine paths;
   `.gitconfig` includes `~/.gitconfig.local`. The repo must remain fully
   applyable with no secrets present. Password-manager/age integration is
   available in chezmoi later if wanted.
4. **Provisioning is opt-in** (`provision=true`): configs always apply;
   packages install only when asked. Keeps work/ssh boxes config-only.
5. **bash on work boxes (starship), zsh on personal (pure)** — both managed
   everywhere; login shell choice stays per-machine.
6. **Git identity is layered**: machine default from the `work` flag
   (work → the email prompted at init, else gmail), overridden per-repo for
   `isaacault/*` GitHub remotes via `includeIf hasconfig` so personal projects
   always commit as `isaac.ault@gmail.com` even from work machines.
7. **Work-specific config is data + overlay, not code.** The repo is public
   and employer-agnostic: internal hostnames, tool names and the work email
   never appear in it. `email` and an optional `overlay` repo URL are
   prompted once on work machines (`promptStringOnce`) and stored in the
   untracked machine-local config. The overlay repo (private, internal-only)
   is cloned and applied by a `run_once` gated on `work`, and plugs into the
   same untracked `.local` hook files — it owns all work-specific config,
   and never becomes commits layered on this repo.
8. **XDG paths standardized.** The old `.zshenv` exported non-standard
   `XDG_DATA_HOME=~/.config/local/share` and `XDG_CACHE_HOME=~/.config/cache`;
   both now use spec defaults (`~/.local/share`, `~/.cache`) so chezmoi's
   source location is identical on every machine. `scripts/migrate-xdg.sh`
   is the one-time cleanup for previously-set-up personal machines.

## Layout notes

- zsh is XDG-first: `~/.zshenv` only bootstraps `ZDOTDIR=~/.config/zsh`.
- tmux config is `~/.config/tmux/tmux.conf` (tmux ≥ 3.1); the legacy
  `~/.tmux.conf` symlink was retired.
- `alacritty.yml` (deprecated) was dropped; `alacritty.toml` kept.
- i3 + polybar were superseded by sway + waybar and removed.
- nvim's `node_modules`/`package*.json` (runtime artifacts) and the old
  per-repo `setup.sh` scripts were not folded in.

## Phase 2 (planned, not yet done)

- **aerospace**: `chezmoi add ~/.aerospace.toml` from the Mac (ignore rule
  already gates it to darwin+gui).
- **AI tooling**: curated subset of `~/.claude/` (CLAUDE.md, settings.json,
  commands/, agents/) — config only, never state/credentials
  (`~/.claude.json` stays out).
- **KB provisioning**: a `run_once` script to clone the knowledge-base repo
  and prompt for `kb import` of the latest snapshot on new machines.
