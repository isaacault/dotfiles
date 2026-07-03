# dotfiles

Single source of truth for all machine configuration, managed with
[chezmoi](https://chezmoi.io). Consolidates the old `nvim`, `tmux`, `zsh` and
`.dotfiles` repos (now archived).

## Fresh machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply isaacault
```

One command: installs chezmoi to `~/bin`, clones this repo, asks three
questions (work machines get two more), applies everything.

| Prompt | Effect |
|---|---|
| `work` | prompts for work git `email` + an optional private `overlay` repo URL; otherwise personal email |
| `gui` | deploys sway/swaync/waybar (linux), aerospace (mac), alacritty |
| `provision` | installs packages on first apply (apt/dnf/brew; nvim + starship via official releases) |

Answers are stored per-machine in `~/.config/chezmoi/chezmoi.toml` (untracked).
To change an answer later: edit that file, then `chezmoi apply`.

## What's managed

- **shell** — `bash` (starship prompt) and `zsh` (pure prompt, `ZDOTDIR=~/.config/zsh`)
- **tmux** — `~/.config/tmux/tmux.conf`; plugins pulled as chezmoi externals (tpm, catppuccin, resurrect, continuum)
- **nvim** — full lazy.nvim config, `lazy-lock.json` pins plugins
- **git** — identity templated by machine kind; `~/.gitconfig.local` for machine-local extras
- **GUI (optional)** — sway, swaync, waybar, alacritty, aerospace
- **work (optional)** — a private overlay repo owns all work-specific config;
  see below

## Git identity

- work machines (`work=true`): the work email given at init — stored only in
  the machine-local untracked config, never in this repo
- personal machines: `isaac.ault@gmail.com`
- **`isaacault/*` GitHub repos: always `isaac.ault@gmail.com`, on any
  machine** — via an `includeIf hasconfig:remote.*.url` rule pulling in
  `~/.config/git/personal`

## Work overlay

Work machines may name a private overlay repo at init (the `overlay` prompt).
A `run_once` clones it to `~/.work-dotfiles` and runs its `install.sh`, which
hooks into the same untracked `.local` files this repo already sources.
Everything work-specific — tools, hosts, extra shell/git config — lives in
the overlay; this repo never references any of it.

## Migrating an old machine

Personal machines set up before this repo used non-standard XDG paths
(`~/.config/local/share`, `~/.config/cache`). After the first `chezmoi apply`,
run once:

```sh
~/.local/share/chezmoi/scripts/migrate-xdg.sh
```

## Secrets policy

**No secrets in this repo, ever.** The repo must apply cleanly on a machine
with zero secrets present. Machine-local files (untracked, sourced if present):

- `~/.bashrc.local` — tokens, API keys, machine-specific paths
- `~/.gitconfig.local` — credential helpers, host overrides

The same goes for work-specific values (git email, overlay repo URL): they
are prompted at init and live only in the untracked per-machine
`~/.config/chezmoi/chezmoi.toml` — the repo itself stays employer-agnostic.

## Day 2

```sh
chezmoi diff              # what would apply change?
chezmoi apply             # make $HOME match the repo
chezmoi update            # git pull + apply (sync this machine)
chezmoi edit ~/.bashrc    # edit the source of a managed file
chezmoi re-add            # absorb local edits back into the repo
chezmoi cd                # drop into the repo to commit/push
```

## Testing

- `test/local-test.sh` — no-docker smoke test: applies into scratch $HOMEs
  (personal+gui and work+nogui) and asserts gating/templates/externals
- `test/docker-test.sh` — fresh-machine apply in an Ubuntu container
- CI runs fresh applies on ubuntu + macos for every push

Design decisions and rationale: [docs/DESIGN.md](docs/DESIGN.md).

## License

[MIT](LICENSE).
