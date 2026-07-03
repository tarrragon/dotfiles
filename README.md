# dotfiles

Personal development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow "package" — its contents mirror the target location relative to `$HOME`.

```text
dotfiles/
├── zsh/              # .zshrc, .zshenv, modular config (.config/zsh/)
├── git/              # .gitconfig (delta integration), .config/git/ignore
├── zellij/           # .config/zellij/config.kdl (clear-defaults keybinds)
├── btop/             # .config/btop/btop.conf
├── broot/            # .config/broot/conf.hjson, verbs.hjson
├── hyprland/         # .config/hypr/hyprland.conf
├── waybar|wofi|mako|hyprlock|themes/  # Linux rice (one stow package per tool)
├── caelestia/        # .config/caelestia/ (user overlay) — copy-deployed via deploy.sh, NOT stowed
├── monitoring/       # systemd service failure alerts (ntfy) — deployed to /etc via deploy.sh
├── scripts/
│   ├── install.sh        # entry + cross-platform assembly (stow / zsh framework / Claude Code)
│   ├── install-arch.sh   # Arch package layer (pacman + packages/arch-*.txt)
│   ├── install-macos.sh  # macOS package layer (brew + Brewfile)
│   └── remote-sync.sh    # sync-and-deploy to a remote machine (local push → remote pull + deploy)
├── packages/
│   ├── arch-base.txt     # minimal toolset (stow/git/zsh/curl/ca-certificates)
│   ├── arch-terminal.txt # CLI toolchain + Claude Code runtime
│   └── arch-desktop.txt  # Hyprland + rice + fonts
└── Brewfile          # macOS package list (not staged; installed all at once)
```

## Quick start

```bash
git clone https://github.com/tarrragon/dotfiles ~/dotfiles
cd ~/dotfiles
./scripts/install.sh            # everything (default)
./scripts/install.sh base       # minimal tools only
./scripts/install.sh terminal   # + CLI toolchain, oh-my-zsh/p10k, Claude Code
./scripts/install.sh desktop    # + Hyprland desktop (Linux) — same as default
```

Stages are cumulative and idempotent. `install.sh` owns the cross-platform assembly (stow, oh-my-zsh + powerlevel10k + plugins, Claude Code); per-platform package installation is delegated to `install-<platform>.sh`, each maintained independently. Precondition on Arch: `sudo` must be installed by root first (base image does not include it).

## Manual stow

```bash
cd ~/dotfiles
stow zsh git zellij btop broot                  # shared (macOS + Linux)
stow hyprland waybar wofi mako hyprlock themes  # Linux desktop
```

To remove symlinks: `stow -D <package>`

Two packages are **not** stowed:

- `caelestia/` — the app atomically rewrites its own `shell.json`, which would replace stow symlinks with real files (and `stow --adopt` would clobber those rewrites back into the repo). Deploy by copy instead: `./caelestia/deploy.sh` (run automatically by the desktop stage).
- `monitoring/` — installs to `/etc` and `/usr/local/bin`, outside stow's `$HOME` scope: `sudo ./monitoring/deploy.sh` (see `monitoring/README.md`).

## Remote machines

`scripts/remote-sync.sh` is the standard way to manage a remote machine — no ad-hoc SSH file drops. It commits/pushes locally, then has the remote `git pull` and run an idempotent deploy, so remote state is always reproducible from the repo:

```bash
scripts/remote-sync.sh <ssh-host>                              # default: ./scripts/install.sh
scripts/remote-sync.sh <ssh-host> 'sudo ./monitoring/deploy.sh'  # deploy monitoring only
```

## Machine-specific config

Create `~/.config/zsh/local.zsh` for machine-specific overrides (not tracked by Git). See `local.zsh.example` for format.

## Dependencies

- Oh My Zsh + Powerlevel10k theme (installed by `install.sh`)
- zsh-autosuggestions, zsh-syntax-highlighting (installed by `install.sh`)
- Nerd Font: MesloLGS (`ttf-meslo-nerd` on Arch, `font-meslo-lg-nerd-font` on macOS)
- git-delta (`git-delta` on Arch / Brew) for diff syntax highlighting
