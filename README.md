# dotfiles

Single source of truth for machine configuration: a plain git repo, linked
into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/). Consolidates
the old `nvim`, `tmux`, `zsh` and `.dotfiles` repos (now archived).

## Layout

Each top-level folder is a stow *package*: just a folder, not a sub-repo.
Files inside sit at the path they have under `$HOME`.

```
bash/.bashrc, .profile
git/.gitconfig, .config/git/
nvim/.config/nvim/
tmux/.config/tmux/
starship/.config/starship.toml
claude/.claude/keybindings.json, statusline.py
alacritty/                               GUI package (both OSes)
sway/, swaync/, waybar/                  GUI packages (Linux)
aerospace/, sketchybar/                  GUI packages (macOS)
```

`stow nvim` makes `~/.config/nvim/...` symlinks into `nvim/.config/nvim/...`.
Edit either path; `git status` here shows the change.

## Fresh machine

```sh
git clone https://github.com/isaacault/dotfiles ~/dotfiles
cd ~/dotfiles
scripts/install-packages.sh [--devtools] [--gui] [--extras]   # see "Package lists" below
scripts/fetch-plugins.sh                   # pinned tmux plugins
./install.sh -n                            # dry run: what would be linked
./install.sh [--gui]                       # link it
```

Stow refuses to overwrite an existing real file. If `./install.sh` reports a
conflict, diff the existing file against the repo and move one aside.

`--gui` adds alacritty, plus sway/swaync/waybar on Linux (installed from the `--gui` package lists) or aerospace/sketchybar
on macOS. On macOS also run `scripts/build-swift-tools.sh` once: it compiles
the aerospace cheat sheet, the sketchybar pomodoro panel and the Wi-Fi name
helper from the Swift sources (the binaries are gitignored build output). The
Wi-Fi helper needs Location Services once, because macOS hides the network
name from command-line tools: `open ~/.config/sketchybar/wifi-ssid/wifi-ssid.app`
and click Allow (repeat after a rebuild). Without it the widget shows
"Connected" instead of the name. aerospace and sketchybar
themselves come from `packages/Brewfile.gui`; sketchybar's Lua module (SbarLua)
is not packaged: `scripts/install-packages.sh --gui` builds it with
`scripts/install-sbarlua.sh` into `~/.local/share/sketchybar_lua`. The script pins
a SbarLua commit that embeds Lua 5.4 to match Homebrew's `lua`, since upstream
HEAD moved to Lua 5.5 (`--force` rebuilds).
Packages can also be
linked individually: `stow --no-folding -t ~ nvim`. `--no-folding` matters:
it stops stow linking whole directories, which would let fetched plugins
land inside this repo.

On macOS, Caps Lock -> Control is a system setting, not a file: System Settings >
Keyboard > Keyboard Shortcuts > Modifier Keys.

## Package lists

What `scripts/install-packages.sh` installs is kept in `packages/`, one list per
purpose, so the lists are the single place to edit:

| flag | macOS (`brew bundle`) | Linux (apt / dnf) |
|---|---|---|
| always | `Brewfile` | `apt.txt` / `dnf.txt` |
| `--devtools` | `Brewfile.devtools` | `apt-devtools.txt` / `dnf-devtools.txt` |
| `--gui` | `Brewfile.gui` | `apt-gui.txt` / `dnf-gui.txt` |
| `--extras` | `Brewfile.extras` (personal, optional) | none |

The `.txt` lists take one package per line; blank lines and `#` comments are
ignored. neovim and starship come from their own installers on Linux, because
distro versions lag. The Linux GUI lists need Debian 13 / Ubuntu 24.04 or
newer, or Fedora; Nerd Fonts are not packaged, so download them into
`~/.local/share/fonts` yourself. To see what a Brewfile would still install on a Mac:
`brew bundle check --no-upgrade --verbose --file=packages/Brewfile.gui`.

## What's managed

- **shell**: `bash` everywhere, starship prompt. On macOS the login shell is Homebrew's bash (`install-packages.sh` prints the `chsh` steps)
- **tmux**: `~/.config/tmux/tmux.conf`; plugins fetched by `scripts/fetch-plugins.sh` (pinned tpm, catppuccin, resurrect, continuum)
- **nvim**: full lazy.nvim config, `lazy-lock.json` pins plugins
- **git**: shared identity; `~/.gitconfig.local` for machine-local extras
- **Claude Code**: `keybindings.json` and a status-line script (`statusline.py`: model, context, cost, directory); `CLAUDE.md`, `settings.json` and skills live in a separate private repo. To use the status line, add to `~/.claude/settings.json`: `"statusLine": {"type": "command", "command": "python3 ~/.claude/statusline.py"}`
- **GUI (optional)**: sway, swaync, waybar, alacritty, aerospace, sketchybar
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

Machines that had the old `zsh` package linked: unlink it **before** pulling
the commit that removed it (stow needs the package files to undo the links),
then switch the login shell to bash (`scripts/install-packages.sh` prints how):

```sh
stow -D --no-folding -d ~/dotfiles -t ~ zsh
git -C ~/dotfiles pull && ~/dotfiles/install.sh
```

Already pulled? `find ~ ~/.config/zsh -maxdepth 1 -xtype l` lists the
dangling links left behind.

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
