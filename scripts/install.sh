#!/usr/bin/env bash
# dotfiles bootstrap — 一鍵把新機器從零帶到可用的開發環境。
# 冪等設計：重跑不會覆蓋已有設定（--needed / --adopt / -d 檢查都在）。
# 支援 macOS（Homebrew + Brewfile）和 Arch Linux（pacman + packages-arch.txt）。
# 執行順序：套件 → stow 部署 → zsh 框架 → Claude Code → 預設 shell
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OS="$(uname -s)"

# --- Logging：全輸出 tee 到帶時間戳的 log 檔，失敗時記行號+指令 ---
# 設計理由：bootstrap 失敗是常態，沒有 log 就只能瞎找。tee 留完整紀錄、
# ERR trap 在 set -e 中斷前先印出失敗的行號與確切指令，讓除錯有突破口。
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
trap 'log "ERROR line $LINENO: [$BASH_COMMAND] exit=$?"' ERR

log "install.sh start | OS=$OS | DOTFILES_DIR=$DOTFILES_DIR"
log "log file: $LOG_FILE"

# --- Package manager & packages ---

if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! command -v stow &>/dev/null; then
        echo "Installing stow..."
        brew install stow
    fi

    # --no-lock 不產生 Brewfile.lock.json（機器間 lock 不可攜、.gitignore 已排除）
    echo "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock

elif [[ "$OS" == "Linux" ]]; then
    if command -v pacman &>/dev/null; then
        # stow/git/zsh 是 bootstrap 自身的前提，先確保有再讀套件清單
        # --noconfirm：bootstrap 常在非 TTY（SSH 指令、無人值守）跑，
        # pacman 的 [Y/n] 互動確認沒人回答會直接 exit 1（apt 分支的 -y 同理）
        log "Installing base packages (Arch)..."
        sudo pacman -S --needed --noconfirm stow git zsh
        if [[ -f "$DOTFILES_DIR/packages-arch.txt" ]]; then
            # 剝掉行內/整行註解（# 之後）+ trim 空白 + 濾空行，其餘當套件名
            mapfile -t arch_pkgs < <(sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$DOTFILES_DIR/packages-arch.txt" | grep -vE '^$')
            if [[ ${#arch_pkgs[@]} -gt 0 ]]; then
                sudo pacman -S --needed --noconfirm "${arch_pkgs[@]}"
            fi
        fi
    elif command -v apt-get &>/dev/null; then
        echo "Installing base packages (Debian/Ubuntu)..."
        sudo apt-get update && sudo apt-get install -y stow git zsh
    fi
fi

# --- Deploy configs via stow ---

cd "$DOTFILES_DIR"

# Shared packages (both macOS and Linux)
PACKAGES=(zsh git zellij btop broot)

# Linux desktop packages (skip on macOS)
if [[ "$OS" == "Linux" ]]; then
    for pkg in hyprland waybar wofi mako hyprlock caelestia; do
        [[ -d "$pkg" ]] && PACKAGES+=("$pkg")
    done
fi

# --adopt：若目標位置已有同名檔案，stow 把它「收養」進 repo（之後 git diff 可檢視差異）。
# 比直接報錯好——新機器可能已有工具自動生成的預設 config，adopt 後由 repo 統一管理。
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        log "Stowing $pkg..."
        stow --adopt "$pkg" 2>/dev/null || stow "$pkg"
    fi
done

# --- Post-install ---

# oh-my-zsh + powerlevel10k + 外掛（git clone 進 OMZ custom，對齊 .zshrc 的 plugin 機制）
# .zshrc 期望這些存在；只靠 pacman 裝不出 OMZ 的 custom theme/plugin 佈局，要 clone。
setup_zsh_framework() {
    local ZSH_DIR="$HOME/.oh-my-zsh"
    local ZSH_CUSTOM="$ZSH_DIR/custom"
    if [[ ! -d "$ZSH_DIR" ]]; then
        log "Installing oh-my-zsh..."
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
    fi
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        log "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi
    local plugin
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
            log "Installing zsh plugin: $plugin..."
            git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin"
        fi
    done
}
setup_zsh_framework

# Claude Code（原生 installer 裝進 ~/.local/bin、免 sudo、自動更新；認證另外做）
if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
    log "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

# chsh 需要使用者密碼（互動式）。若在無人值守環境跑，
# 事前用 NOPASSWD sudo + 手動改 /etc/passwd 繞過，或接受 shell 留 bash。
if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
fi

log "install.sh done"
echo ""
echo "Done. Notes:"
echo "  - Full log: $LOG_FILE"
echo "  - Review any adopted files: git diff"
echo "  - Machine-specific overrides: ~/.config/zsh/local.zsh"
echo "  - Project aliases: add to ~/.config/zsh/local.zsh (see local.zsh.example)"
echo "  - Secrets (SSH keys, API tokens) are NOT managed by this repo"
echo "  - Claude Code auth: 在有瀏覽器的機器跑 'claude setup-token'，再於本機 export CLAUDE_CODE_OAUTH_TOKEN=<token>"
