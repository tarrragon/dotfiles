# macOS 的終端機（Ghostty 等）SSH 進 Linux 時常送 LC_CTYPE=UTF-8（非合法 Linux locale 名），
# Linux fallback 成 POSIX/C，使 zsh line editor 把輸入當單位元組、unicode prompt 重繪成亂碼。
# 在 Linux 上偵測到這情況就修正成合法的 UTF-8 locale。
if [[ "$OSTYPE" == linux* && ( "$LC_CTYPE" == "UTF-8" || -z "$LANG" ) ]]; then
  export LANG=en_US.UTF-8
  export LC_CTYPE=en_US.UTF-8
fi

# rust 環境（沒裝 rust 的機器要守衛，否則每次開 shell 都噴 no such file）
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
