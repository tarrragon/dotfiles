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

# Project-specific aliases go in ~/.config/zsh/local.zsh
# Example (unimall, unipos, etc.):
#   alias unimall-dev='cd ~/project/unimall_shop && ./scripts/run_commands.sh dev'
