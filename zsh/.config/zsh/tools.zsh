# autojump
if [[ "$(uname)" == "Darwin" ]]; then
    [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
else
    [ -f /usr/share/autojump/autojump.sh ] && . /usr/share/autojump/autojump.sh
fi

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
