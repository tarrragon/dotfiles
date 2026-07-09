# dotfiles

Personal development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

> **Design** — this repo is the concrete instance of a personal-scale *paved road* (the idea Spotify/Netflix apply at org scale, scaled down): a repo as single source of truth, an idempotent installer (`scripts/install.sh`), and an ordered path through the docs. It stays operational here; the concept and a task-ordered on-ramp (bringing up a remote agent workstation) are written up on the blog — [paved road, the concept](https://tarrragon.github.io/blog/linux/dotfile/knowledge-cards/paved-road-golden-path/) and [the remote-agent on-ramp](https://tarrragon.github.io/blog/linux/tools/remote/remote-agent-paved-road/).

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
│   ├── install-debian.sh # Debian/Ubuntu package layer (apt + packages/debian-*.txt)
│   ├── remote-sync.sh    # sync-and-deploy to a remote machine (local push → remote pull + deploy)
│   └── verify.sh         # read-only post-install check (stow symlinks, zsh, omz/p10k, Claude Code)
├── packages/
│   ├── arch-{base,terminal,desktop}.txt    # Arch package lists per stage
│   └── debian-{base,terminal}.txt          # Debian/Ubuntu package lists per stage
├── runtimes/         # versioned app-runtime stacks (Dockerfile + compose) — NOT workstation config; see runtimes/README.md
└── Brewfile          # macOS package list (not staged; installed all at once)
```

## Where each setting lives

Most of this repo is **workstation dotfiles** — config for the machine *you* work on. `runtimes/` is the one exception (explained at the bottom).

| Concern | Location | What it holds |
| --- | --- | --- |
| Shell (zsh) | `zsh/` | `.zshrc`, `.zshenv`, modular `.config/zsh/` |
| Git | `git/` | `.gitconfig` (delta pager), `.config/git/ignore` |
| Terminal multiplexer | `zellij/` | `.config/zellij/config.kdl` |
| System monitors (TUI) | `btop/`, `broot/` | their `.config/` files |
| Linux desktop (rice) | `hyprland/` `waybar/` `wofi/` `mako/` `hyprlock/` `themes/` `caelestia/` | Wayland WM, bar, launcher, notifications, lock screen, colors, shell overlay |
| What to install | `packages/` (Arch/Debian) + `Brewfile` (macOS) | package lists, split by distro and stage |
| Install / bootstrap | `scripts/` | `install.sh` (cross-platform assembly) → `install-<platform>.sh` (packages) + `remote-sync.sh` |
| Service failure alerts | `monitoring/` | systemd `OnFailure` → ntfy; deployed to `/etc` via `deploy.sh` |
| Machine-specific overrides | `~/.config/zsh/local.zsh` | per-machine, **not** tracked by Git (see `local.zsh.example`) |
| Reference app-runtime stacks | `runtimes/` | versioned Dockerfile + compose stacks (see `runtimes/README.md`) |

### Why `runtimes/` is here (and when it isn't)

Workstation dotfiles configure *your* environment and travel with *you*. A Dockerfile configures an *app's* runtime and travels with *that app* — so a real project's runtime belongs in that project's repo, not here. The `runtimes/` stacks are the narrow exception: **cross-project reference stacks you maintain for yourself** (prod-parity templates, upgrade experiments) that follow you rather than any single app's deploy. If a stack becomes tied to one app's deployment, move it into that app's repo.

## Full setup, in order

The complete path from a fresh machine to a verified environment. Everything below assumes **you already have a shell on the machine and network access**; each step is idempotent, so re-running any of them is safe.

1. **Preconditions.** You need `git` to clone this repo — the repo installs git later, but not before you can clone it, so install it by hand first: Arch `sudo pacman -S git`, Debian/Ubuntu `sudo apt install git`, macOS gets it with the Command Line Tools. On a fresh **Arch** base image there is no `sudo` either — as root, `pacman -S sudo` and add your user to the `wheel` group first. In a **root shell** (e.g. a bare container) there is no `sudo` and none is needed; if the package scripts call `sudo` and it is absent, either install `sudo` or run them as root without it.

2. **Clone and install.**

   ```bash
   git clone https://github.com/tarrragon/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./scripts/install.sh            # everything (default); or a stage — see Quick start below
   ```

   This runs the per-platform package layer, stows the dotfiles, sets up oh-my-zsh + powerlevel10k, installs Claude Code, and (desktop stage) copy-deploys caelestia. A full timestamped log lands in `~/.local/state/dotfiles/`.

3. **System layer — optional (service-failure alerts).** Not run by `install.sh` because it writes to `/etc` and needs root:

   ```bash
   sudo ./monitoring/deploy.sh
   echo '<your-ntfy-topic>' | sudo tee /etc/svc-alert-topic   # fill the placeholder it created
   ```

4. **Secrets and per-machine config** (never tracked by Git):

   - **Claude Code auth** — run `claude setup-token` on a machine with a browser, then make `CLAUDE_CODE_OAUTH_TOKEN=<token>` available on this machine (the container agent stack reads it from `runtimes/agent-workstation/.env` instead — see that README).
   - **Per-machine overrides** — create `~/.config/zsh/local.zsh` (see `local.zsh.example`).

5. **Verify.** Confirm the environment actually came up — pass the same stage you installed:

   ```bash
   ./scripts/verify.sh            # base | terminal | desktop (default desktop)
   ```

   It checks the stow symlinks resolve into this repo, zsh is the default shell, oh-my-zsh/powerlevel10k and Claude Code are present, and (desktop) the caelestia deploy landed. Read-only; exits non-zero if anything is missing.

## Quick start

The one-command version of step 2 above (preconditions, system layer, secrets and verify still apply):

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
