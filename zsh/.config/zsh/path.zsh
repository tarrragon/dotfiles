typeset -U PATH  # deduplicate

# --- Cross-platform ---

export PATH="$HOME/.local/bin:$PATH"

# uv
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# Flutter (FVM)
# ~/fvm/bin = fvm CLI 本體(fvm 4.x installer 落點);~/fvm/default/bin = 目前選定的 flutter
[[ -d "$HOME/fvm/bin" ]] && export PATH="$HOME/fvm/bin:$PATH"
[[ -d "$HOME/fvm/default/bin" ]] && export PATH="$HOME/fvm/default/bin:$PATH"

# Go (官方 tarball 解到 /usr/local/go;取代官方 pkg 的 /etc/paths.d/go 系統檔)
# $HOME/go/bin 是 GOPATH bin:`go install` 與 Brewfile 的 go "..." 工具落點
[[ -d "/usr/local/go/bin" ]] && export PATH="/usr/local/go/bin:$PATH"
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

# --- macOS ---

if [[ "$(uname)" == "Darwin" ]]; then
    # Homebrew — 讓 brew 及所有 brew 安裝的 binary 上 PATH。
    # 沒這段的話 /opt/homebrew/bin 不在 PATH、brew 與 lazygit/gh/btop 等全找不到。
    # （原本靠機器本地的 ~/.zprofile eval shellenv、但那檔不在 dotfiles、新機沒有——冷測揭露）
    for brewbin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$brewbin" ]] && eval "$("$brewbin" shellenv)" && break
    done

    # Homebrew Ruby
    if [[ -d "/opt/homebrew/opt/ruby/bin" ]]; then
        export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
        export PATH="$(gem environment gemdir)/bin:$PATH"
    fi

    # Java (Homebrew)
    [[ -d "/opt/homebrew/opt/openjdk@17/bin" ]] && export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

    # Android SDK (macOS path)
    [[ -d "$HOME/Library/Android/sdk/emulator" ]] && export PATH="$PATH:$HOME/Library/Android/sdk/emulator"

    # Cursor editor
    [[ -d "/Applications/Cursor.app" ]] && export PATH="$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"
fi

# --- Linux ---

if [[ "$(uname)" == "Linux" ]]; then
    # Android SDK (Linux path)
    [[ -d "$HOME/Android/Sdk/emulator" ]] && export PATH="$PATH:$HOME/Android/Sdk/emulator"
fi
