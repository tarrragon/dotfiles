# Editor
alias sudo='sudo -E'

# --- Cross-platform aliases ---

alias ll='ls -alF'
alias la='ls -A'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'

# --- macOS only ---

if [[ "$(uname)" == "Darwin" ]]; then
    alias zshrc="cursor ~/.zshrc"
    alias ios="open -a Simulator"
    alias android="emulator -avd Medium_Phone_API_36"
fi

# --- Linux: caelestia drawer 快捷（有意義的動詞、不用背熱鍵）---
# 從終端機打詞就 toggle 對應 drawer；熱鍵（Super+N 等）是全域路徑，兩者並存。
# 需在圖形 session 內的互動 shell（XDG_RUNTIME_DIR 有設）。

if [[ "$(uname)" == "Linux" ]] && command -v caelestia &>/dev/null; then
    alias sidebar='caelestia shell drawers toggle sidebar'      # 通知 / 控制中心
    alias dashboard='caelestia shell drawers toggle dashboard'  # 日曆 / 媒體 / 天氣
    alias launcher='caelestia shell drawers toggle launcher'    # 應用啟動器
    alias clear-notifs='caelestia shell notifs clear'           # 清空通知
fi

# Project-specific aliases go in ~/.config/zsh/local.zsh
# Example (unimall, unipos, etc.):
#   alias unimall-dev='cd ~/project/unimall_shop && ./scripts/run_commands.sh dev'
