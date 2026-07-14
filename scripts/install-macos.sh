#!/usr/bin/env bash
# macOS 套件安裝層 — brew bootstrap + Brewfile。
# stage 參數保留介面一致但目前不分層：macOS 是主力工作機、一次全裝的實益高，
# Brewfile 拆層等真的有「macOS 只裝一半」的需求再做。
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${1:-desktop}"

# Homebrew：未裝就裝，然後把它加進「當前 shell」的 PATH。
# 關鍵（乾淨機器冷測實證）：Apple Silicon 的 installer 裝到 /opt/homebrew 但不會改當前
# shell 的 PATH（只提示你手動加進 .zprofile），所以裝完後本 script 若直接用 brew 會
# 「command not found」。這裡 eval brew shellenv 補上；也涵蓋「已裝但這個 shell 沒載入」。
if ! command -v brew &>/dev/null; then
    if [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    for brewbin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$brewbin" ]] && eval "$("$brewbin" shellenv)" && break
    done
fi

command -v stow &>/dev/null || brew install stow

# 非 Homebrew 語言 runtime（Node/Go/uv+Python/Flutter）+ 它們的 workflow 工具，
# 版本釘死、冪等。工具（go/uv/npm）已從 Brewfile 移進這裡，用 pin 的 runtime 裝，
# 所以跟 brew bundle 解耦——排在前或後都行，這裡放前面（無害）。
# 需在 Homebrew bootstrap 之後跑：CLT 由 bootstrap 裝好，滿足 nvm/flutter 的 git 需求。
echo "Installing non-Homebrew language runtimes + workflow tools..."
"$DOTFILES_DIR/scripts/install-runtimes.sh"

# 新版 Homebrew 已移除 lock 檔功能與 --no-lock 選項（帶了會報 invalid option）；
# 現在 brew bundle 預設就不產 Brewfile.lock.json，不需任何 flag。
echo "Installing packages from Brewfile (stage=$STAGE, Brewfile 不分層)..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
