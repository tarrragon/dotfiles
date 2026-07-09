#!/usr/bin/env bash
# verify.sh — read-only check that install.sh actually produced a working environment.
#
# Takes the same stage arg as install.sh (base|terminal|desktop, default desktop) and
# checks the artifacts that stage should have created. Read-only: it changes nothing,
# so it is safe to run any number of times. Exits 0 if every check passes, 1 otherwise.
#
# Why this exists: install.sh automates the setup but "did it actually work" was left to
# eyeballing. This turns that into one command — the last step of the setup runbook.
set -uo pipefail   # deliberately NOT -e: run every check and report, don't stop at the first failure

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OS="$(uname -s)"
STAGE="${1:-desktop}"
case "$STAGE" in base|terminal|desktop) ;; *) echo "usage: verify.sh [base|terminal|desktop]"; exit 2 ;; esac

pass=0; fail=0
ok()  { printf '  [ ok ] %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  [FAIL] %s\n' "$1"; fail=$((fail+1)); }
info() { printf '  [info] %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
# stowed <live-path> <repo-relative-path>: true if live path resolves to the repo file
stowed() { [[ -L "$1" && "$1" -ef "$DOTFILES_DIR/$2" ]]; }

echo "verify.sh | OS=$OS | STAGE=$STAGE | repo=$DOTFILES_DIR"

echo "-- base --"
have git  && ok "git present"  || bad "git missing"
have stow && ok "stow present" || bad "stow missing (package layer did not run?)"
stowed "$HOME/.gitconfig" "git/.gitconfig" && ok "~/.gitconfig -> repo" || bad "~/.gitconfig is not a repo symlink"

if [[ "$STAGE" != base ]]; then
  echo "-- terminal --"
  have zsh && ok "zsh present" || bad "zsh missing"
  case "${SHELL:-}" in */zsh) ok "default shell is zsh" ;; *) bad "default shell is not zsh (chsh not applied yet — re-login, or run: chsh -s \$(command -v zsh))" ;; esac
  stowed "$HOME/.zshrc" "zsh/.zshrc" && ok "~/.zshrc -> repo" || bad "~/.zshrc is not a repo symlink"
  stowed "$HOME/.config/zellij/config.kdl" "zellij/.config/zellij/config.kdl" && ok "zellij config -> repo" || bad "zellij config is not a repo symlink"
  [[ -d "$HOME/.oh-my-zsh" ]] && ok "oh-my-zsh present" || bad "oh-my-zsh missing"
  [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]] && ok "powerlevel10k present" || bad "powerlevel10k missing"
  { have claude || [[ -x "$HOME/.local/bin/claude" ]]; } && ok "Claude Code present" || bad "Claude Code missing (installer needs network + curl)"
fi

if [[ "$STAGE" == desktop && "$OS" == Linux ]]; then
  echo "-- desktop (Linux) --"
  stowed "$HOME/.config/hypr/hyprland.conf" "hyprland/.config/hypr/hyprland.conf" && ok "hyprland config -> repo" || bad "hyprland config is not a repo symlink"
  [[ -f "$HOME/.config/caelestia/shell.json" ]] && ok "caelestia shell.json deployed" || bad "caelestia shell.json missing (desktop deploy did not run?)"
fi

# Optional system layer — only reported, never fails the run (it is opt-in and root-owned)
echo "-- monitoring (optional) --"
if [[ -f /etc/systemd/system/alert@.service ]]; then
  if [[ -r /etc/svc-alert-topic ]] && ! grep -qiE 'example|changeme|<.*>' /etc/svc-alert-topic 2>/dev/null; then
    info "alert service installed, topic filled"
  else
    info "alert service installed, but topic looks like a placeholder — fill /etc/svc-alert-topic"
  fi
else
  info "not deployed (run: sudo ./monitoring/deploy.sh — optional)"
fi

echo
if [[ $fail -eq 0 ]]; then
  echo "OK — $pass checks passed for stage '$STAGE'."
  exit 0
else
  echo "FAILED — $fail failed, $pass passed for stage '$STAGE'. See the notes above."
  exit 1
fi
