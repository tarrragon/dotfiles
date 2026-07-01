typeset -U PATH  # deduplicate

# --- Cross-platform ---

export PATH="$HOME/.local/bin:$PATH"

# uv
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# Flutter (FVM)
[[ -d "$HOME/fvm/default/bin" ]] && export PATH="$HOME/fvm/default/bin:$PATH"

# --- macOS ---

if [[ "$(uname)" == "Darwin" ]]; then
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
