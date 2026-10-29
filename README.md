# dotfiles

Single source of truth for machine configuration: a plain git repo, linked
into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/). Consolidates
the old `nvim`, `tmux`, `zsh` and `.dotfiles` repos (now archived).

## Layout

Each top-level folder is a stow *package*: just a folder, not a sub-repo.
Files inside sit at the path they have under `$HOME`.

```
bash/.bashrc, .profile
zsh/.zshenv, .config/zsh/
git/.gitconfig, .config/git/
nvim/.config/nvim/
tmux/.config/tmux/
starship/.config/starship.toml
claude/.claude/keybindings.json
alacritty/, sway/, swaync/, waybar/      GUI packages
```

`stow nvim` makes `~/.config/nvim/...` symlinks into `nvim/.config/nvim/...`.
Edit either path; `git status` here shows the change.

## Fresh machine

```sh
git clone https://github.com/isaacault/dotfiles ~/dotfiles
cd ~/dotfiles
scripts/install-packages.sh [--devtools]   # stow, git, tmux, zsh, nvim, starship, claude
scripts/fetch-plugins.sh                   # pinned tmux + zsh plugins
./install.sh -n                            # dry run: what would be linked
./install.sh [--gui]                       # link it
```

Stow refuses to overwrite an existing real file. If `./install.sh` reports a
conflict, diff the existing file against the repo and move one aside.

`--gui` adds alacritty, plus sway/swaync/waybar on Linux. Packages can also be
linked individually: `stow --no-folding -t ~ nvim`. `--no-folding` matters:
it stops stow linking whole directories, which would let fetched plugins
land inside this repo.

## What's managed

- **shell**: `bash` (starship prompt) and `zsh` (pure prompt, `ZDOTDIR=~/.config/zsh`)
- **tmux**: `~/.config/tmux/tmux.conf`; plugins fetched by `scripts/fetch-plugins.sh` (pinned tpm, catppuccin, resurrect, continuum)
- **nvim**: full lazy.nvim config, `lazy-lock.json` pins plugins
- **git**: shared identity; `~/.gitconfig.local` for machine-local extras
- **Claude Code**: `keybindings.json` only; `CLAUDE.md`, `settings.json` and skills live in a separate private repo
- **GUI (optional)**: sway, swaync, waybar, alacritty
- **work (optional)**: a private overlay repo owns all work-specific config; see below

## Git identity

- default: `isaac.ault@gmail.com`
- work machines: put the work identity in `~/.gitconfig.local` (untracked)
- **`isaacault/*` GitHub repos: always `isaac.ault@gmail.com`, on any
  machine.** An `includeIf hasconfig:remote.*.url` rule pulls in
  `~/.config/git/personal`, and it is ordered after the local include so it wins.

## Work overlay

```sh
scripts/work-overlay.sh <private-overlay-repo-url>
```

Clones the private overlay to `~/.work-dotfiles` and runs its `install.sh`,
which hooks into the same untracked `.local` files this repo already sources.
Everything work-specific (tools, hosts, extra shell/git config) lives in the
overlay; this repo never references any of it, and the URL is never committed.

The clone uses SSH, so **this machine's SSH key must be registered with the
git host first.** New host keys are accepted automatically
(`StrictHostKeyChecking=accept-new`), including non-standard ports from the URL.

## Migrating an old machine

Machines set up before this repo used non-standard XDG paths
(`~/.config/local/share`, `~/.config/cache`). Run once:

```sh
scripts/migrate-xdg.sh
```

## Secrets policy

**No secrets in this repo, ever.** The repo must link cleanly on a machine
with zero secrets present. Machine-local files (untracked, sourced if present;
`*.local` and `*.work` are gitignored):

- `~/.bashrc.local`: tokens, API keys, machine-specific paths
- `~/.gitconfig.local`: work identity, credential helpers, host overrides

## Day 2

```sh
cd ~/dotfiles
git pull && ./install.sh   # sync this machine; new files get linked
git status                 # local edits show up here, since the live files are symlinks
git add -p && git commit   # then push
```

A file added to a package needs `./install.sh` once to get its symlink.

## Testing

- `test/local-test.sh`: no-docker smoke test; links into scratch `$HOME`s
  (core+gui, core only, work overlay fixture) and asserts gating, symlinks,
  plugin fetch and that nothing leaks into the repo
- `test/docker-test.sh`: fresh-machine run in an Ubuntu container
- CI runs the smoke test on ubuntu + macos for every push

Design decisions and rationale: [docs/DESIGN.md](docs/DESIGN.md).

## License

[MIT](LICENSE).
