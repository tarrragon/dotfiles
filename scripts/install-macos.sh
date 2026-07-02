#!/usr/bin/env bash
# macOS 套件安裝層 — brew bootstrap + Brewfile。
# stage 參數保留介面一致但目前不分層：macOS 是主力工作機、一次全裝的實益高，
# Brewfile 拆層等真的有「macOS 只裝一半」的需求再做。
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${1:-desktop}"

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

command -v stow &>/dev/null || brew install stow

# --no-lock 不產生 Brewfile.lock.json（機器間 lock 不可攜、.gitignore 已排除）
echo "Installing packages from Brewfile (stage=$STAGE, Brewfile 不分層)..."
brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock
