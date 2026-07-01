# dotfiles

Personal development environment configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow "package" — its contents mirror the target location relative to `$HOME`.

```bash
dotfiles/
├── zsh/           # .zshrc, .zshenv, modular config in .config/zsh/
├── git/           # .gitconfig, .config/git/ignore
├── zellij/        # .config/zellij/config.kdl
├── btop/          # .config/btop/btop.conf
├── broot/         # .config/broot/conf.hjson, verbs.hjson
├── scripts/       # install.sh (not a stow package)
└── Brewfile       # macOS package list
```

## Quick start

```bash
git clone https://github.com/tarrragon/dotfiles ~/dotfiles
cd ~/dotfiles
./scripts/install.sh
```

## Manual stow

```bash
cd ~/dotfiles
stow zsh git zellij btop broot
```

To remove symlinks: `stow -D <package>`

## Machine-specific config

Create `~/.config/zsh/local.zsh` for machine-specific overrides (not tracked by Git).

## Dependencies

- Oh My Zsh + Powerlevel10k theme
- zsh-autosuggestions, zsh-syntax-highlighting plugins
- Nerd Font (MesloLGS or similar)

## Adding new tools

1. Create `~/dotfiles/<toolname>/.config/<toolname>/` mirroring the target path
2. Copy the config file in
3. `cd ~/dotfiles && stow <toolname>`
4. Commit
