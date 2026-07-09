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
│   ├── verify.sh         # read-only post-install check (stow symlinks, zsh, omz/p10k, Claude Code)
│   └── scratch.sh        # spin up a disposable clean container (bare, or --provision with this repo)
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

1. **Preconditions.** You need `git` to clone this repo (the install scripts install it too, but not before you can clone). Install it — and on Arch, sync the package DB in the same step:

   - **Arch**, as root: `pacman -Syu git` (a fresh base image ships an empty package DB; use `-Syu`, not a bare `-Sy` — a partial refresh hits file conflicts on the next upgrade, e.g. `libstdc++ … exists in filesystem`). In an Arch **container**, pacman 7's sandbox may fail with a Landlock error (`switching to sandbox user 'alpm' failed`) — add `DisableSandbox` to `/etc/pacman.conf`; a real Arch host is unaffected.
   - **Debian/Ubuntu**: `apt update && apt install -y git` (prefix `sudo` if you are not root).
   - **macOS**: git comes with the Command Line Tools (`xcode-select --install`).

   About `sudo`: the install scripts detect when they run as **root** and skip `sudo` entirely, so a bare root container works with no `sudo` installed. If instead you run as a **non-root user**, install and configure `sudo` first (creating that user and its privileges is machine setup, outside this repo's scope).

2. **Clone and install.**

   ```bash
   git clone https://github.com/tarrragon/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./scripts/install.sh            # default = everything (desktop); headless/server → ./scripts/install.sh terminal
   ```

   Stages: `base` (minimal), `terminal` (+ CLI toolchain, oh-my-zsh/p10k, Claude Code), `desktop` (+ Hyprland rice, Arch only). This runs the per-platform package layer, stows the dotfiles, sets up oh-my-zsh + powerlevel10k, installs Claude Code, **changes your default shell to zsh** (`chsh`), and (desktop stage) copy-deploys caelestia. A full timestamped log lands in `~/.local/state/dotfiles/`. If a target file already exists as a real file (not a symlink), stow adopts it into the repo (review with `git diff`) — back up any dotfiles you want to keep before running.

3. **System layer — optional (service-failure alerts).** Not run by `install.sh` because it writes to `/etc` and needs root:

   ```bash
   sudo ./monitoring/deploy.sh
   echo '<your-ntfy-topic>' | sudo tee /etc/svc-alert-topic   # fill the placeholder it created
   ```

4. **Secrets and per-machine config** (never tracked by Git):

   - **Claude Code auth** — run `claude setup-token` on a machine with a browser, then add `export CLAUDE_CODE_OAUTH_TOKEN=<token>` to `~/.config/zsh/local.zsh` (per-machine, not tracked). The container agent stack reads it from `runtimes/agent-workstation/.env` instead — see that README.
   - **Per-machine overrides** — that same `~/.config/zsh/local.zsh` holds any machine-specific config (see `local.zsh.example`).

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
./scripts/install.sh desktop    # + Hyprland rice (Arch only) — same as default; headless/server: use terminal, not this
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

## Disposable scratch environment

`scripts/scratch.sh` spins up a throwaway clean container — for cold-read testing this repo's own setup, or just for a quick disposable shell.

```bash
./scripts/scratch.sh debian                  # bare debian:bookworm, drop into a shell, removed on exit
./scripts/scratch.sh arch --provision        # native Arch (arm64 host → real Arch Linux ARM), install.sh terminal, verify
./scripts/scratch.sh arch --provision --keep # same, but keep the container to re-enter
```

`arch` on an arm64 host uses a native Arch Linux ARM image (not the amd64 `archlinux` under qemu, which gives false results), and `--provision` handles pacman 7's in-container Landlock sandbox (`DisableSandbox`) and `-Syu`. `bare` is what you want for validating the setup guide from a stranger's clean slate; `--provision` is a ready-to-use scratch box with the toolchain installed.

## Dependencies

- Oh My Zsh + Powerlevel10k theme (installed by `install.sh`)
- zsh-autosuggestions, zsh-syntax-highlighting (installed by `install.sh`)
- Nerd Font: MesloLGS (`ttf-meslo-nerd` on Arch, `font-meslo-lg-nerd-font` on macOS)
- git-delta (`git-delta` on Arch / Brew) for diff syntax highlighting
