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
├── hyprland/         # .config/hypr/hyprland.conf (VM minimal config)
├── caelestia/        # .config/caelestia/ (user overlay: shell.json + hypr-user.lua)
├── scripts/          # install.sh (not a stow package)
├── Brewfile          # macOS package list
└── packages-arch.txt # Arch Linux package list
```

## Quick start

```bash
git clone https://github.com/tarrragon/dotfiles ~/dotfiles
cd ~/dotfiles
./scripts/install.sh
```

`install.sh` handles: package installation (Brewfile on macOS, packages-arch.txt on Arch), stow deployment, oh-my-zsh + powerlevel10k + plugins, Claude Code.

## Manual stow

```bash
cd ~/dotfiles
stow zsh git zellij btop broot          # shared (macOS + Linux)
stow hyprland waybar wofi mako hyprlock  # Linux desktop
stow caelestia                           # after caelestia install
```

To remove symlinks: `stow -D <package>`

## Machine-specific config

Create `~/.config/zsh/local.zsh` for machine-specific overrides (not tracked by Git). See `local.zsh.example` for format.

## Dependencies

- Oh My Zsh + Powerlevel10k theme (installed by `install.sh`)
- zsh-autosuggestions, zsh-syntax-highlighting (installed by `install.sh`)
- Nerd Font: MesloLGS (`ttf-meslo-nerd` on Arch, `font-meslo-lg-nerd-font` on macOS)
- git-delta (`git-delta` on Arch / Brew) for diff syntax highlighting
