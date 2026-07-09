# zoxide — smarter cd (z to jump by frecency, zi to pick interactively). autojump 的維護版替代，
# Arch 官方 repo 已把 autojump 移到 AUR、zoxide 兩發行版官方都有。init 走這裡（不靠 oh-my-zsh
# 有沒有對應 plugin）、guard 讓缺 binary 時是 no-op。cross-platform、不需分 OS。
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# broot
[ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

# Claude Code
export ENABLE_LSP_TOOL=1
export CLAUDE_CODE_NO_FLICKER=1
