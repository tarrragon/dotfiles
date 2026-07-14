#!/usr/bin/env bash
# dotfiles bootstrap 入口 — 一鍵把新機器帶到可用的工作環境。
#
# 分層：base（工具最小集）→ terminal（CLI 工具鏈 + shell 框架 + Claude Code）
#       → desktop（圖形桌面，平台分歧最大）。後層自動涵蓋前層。
# 用法：install.sh [base|terminal|desktop]（預設 desktop = 全裝）
#
# 職責切分：本檔只放跨平台同一套邏輯的「環境組裝」（stow / git clone / curl installer）；
# 「套件怎麼裝」按平台委派給 install-<platform>.sh，各自獨立維護、分歧不寫進共通層。
# 冪等設計：重跑不會覆蓋已有設定（--needed / --adopt / -d 檢查都在）。
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OS="$(uname -s)"
STAGE="${1:-desktop}"

case "$STAGE" in base|terminal|desktop) ;; *) echo "usage: install.sh [base|terminal|desktop]"; exit 2 ;; esac

# --- Logging：全輸出 tee 到帶時間戳的 log 檔，失敗時記行號+指令 ---
# 設計理由：bootstrap 失敗是常態，沒有 log 就只能瞎找。tee 留完整紀錄、
# ERR trap 在 set -e 中斷前先印出失敗的行號與確切指令，讓除錯有突破口。
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
trap 'log "ERROR line $LINENO: [$BASH_COMMAND] exit=$?"' ERR

log "install.sh start | OS=$OS | STAGE=$STAGE | DOTFILES_DIR=$DOTFILES_DIR"
log "log file: $LOG_FILE"

# --- 套件安裝：按平台委派（分歧層，各自維護）---

if [[ "$OS" == "Darwin" ]]; then
    "$DOTFILES_DIR/scripts/install-macos.sh" "$STAGE"
elif [[ "$OS" == "Linux" ]]; then
    if command -v pacman &>/dev/null; then
        "$DOTFILES_DIR/scripts/install-arch.sh" "$STAGE"
    elif command -v apt-get &>/dev/null; then
        "$DOTFILES_DIR/scripts/install-debian.sh" "$STAGE"
    fi
fi

# macOS：把 brew 加進「這個父行程」的 PATH，讓共通層的 stow 等 brew 工具可用。
# install-macos.sh 裡的 eval 只改它自己的子行程、不會傳回這裡（子行程 PATH 不上傳父行程）。
if [[ "$OS" == "Darwin" ]]; then
    for brewbin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$brewbin" ]] && eval "$("$brewbin" shellenv)" && break
    done
fi

# --- 共通層：環境組裝（跨平台同一套邏輯）---

cd "$DOTFILES_DIR"

# --adopt：目標位置已有同名檔案時把它「收養」進 repo（之後 git diff 可檢視差異），
# 比直接報錯好——新機器可能已有工具自動生成的預設 config，adopt 後由 repo 統一管理。
stow_pkgs() {
    local pkg
    for pkg in "$@"; do
        if [[ -d "$pkg" ]]; then
            log "Stowing $pkg..."
            stow --adopt "$pkg" 2>/dev/null || stow "$pkg"
        fi
    done
}

# base：只部署不依賴任何框架的 config（zsh config 依賴 OMZ、歸 terminal 層一起交付）
stow_pkgs git

if [[ "$STAGE" != "base" ]]; then
    # terminal：config 跟它依賴的框架同層交付（.zshrc 期望 OMZ/p10k 存在、缺了 shell 會壞）
    stow_pkgs zsh zellij btop broot

    # oh-my-zsh + powerlevel10k + 外掛（git clone 進 OMZ custom，對齊 .zshrc 的 plugin 機制）
    # 只靠套件管理器裝不出 OMZ 的 custom theme/plugin 佈局，要 clone。
    ZSH_DIR="$HOME/.oh-my-zsh"
    ZSH_CUSTOM="$ZSH_DIR/custom"
    if [[ ! -d "$ZSH_DIR" ]]; then
        log "Installing oh-my-zsh..."
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
    fi
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        log "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
            log "Installing zsh plugin: $plugin..."
            git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin"
        fi
    done

    # Claude Code（原生 installer 裝進 ~/.local/bin、免 sudo、自動更新；認證另外做）
    if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
        log "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    # chsh 需要使用者密碼（互動式）。無人值守環境會失敗、不擋後續步驟——
    # 用 || 記 log 而不是讓 set -e 中斷，shell 留原樣是可接受的退化。
    if [[ "$(basename "$SHELL")" != "zsh" ]]; then
        log "Changing default shell to zsh..."
        chsh -s "$(command -v zsh)" || log "chsh failed (non-TTY?) — 手動跑: chsh -s \$(command -v zsh)"
    fi
fi

if [[ "$STAGE" == "desktop" && "$OS" == "Linux" ]]; then
    # desktop（Linux）：Hyprland + rice 的 config；macOS 的 GUI 由 Brewfile cask 段涵蓋
    stow_pkgs hyprland waybar wofi mako hyprlock themes
    # caelestia 不 stow：它用 atomic-write 改寫自己的 shell.json、會把 stow symlink 換成實檔，
    # 且 stow --adopt 會把它改寫過的內容 clobber 回 repo。改 copy 部署、repo 為唯一真實來源。
    log "Deploying caelestia config (copy, not stow)..."
    bash "$DOTFILES_DIR/caelestia/deploy.sh"
fi

log "install.sh done (stage=$STAGE)"
echo ""
echo "Done. Notes:"
echo "  - Full log: $LOG_FILE"
echo "  - Review any adopted files: git diff"
echo "  - Machine-specific overrides: ~/.config/zsh/local.zsh (see local.zsh.example)"
echo "  - Secrets (SSH keys, API tokens) are NOT managed by this repo"
echo "  - Claude Code auth: 在有瀏覽器的機器跑 'claude setup-token'，再於本機 export CLAUDE_CODE_OAUTH_TOKEN=<token>"
