#!/usr/bin/env bash
# 選配工具安裝器 — 讀 packages/optional.txt、picker 多選、按 type 安裝。
#
# 定位：核心 Brewfile 只裝每台都要的；role-specific 工具（db/lsp/containers/editor/
#   ai-agent 等）放這裡按需裝。不由 install.sh 自動跑（互動式、opt-in）。
# 冪等：已裝的自動跳過。容錯：單項失敗（如 prowl macOS 版本不符）記錄後續跑，不中斷。
# 選擇 UX：有 fzf 用 fzf 多選；沒有退回數字選單（bootstrap 早期 fzf 未裝時仍可用）。
# 相容：避開 bash 4+ 語法（mapfile 等）；macOS 預設 bash 3.2 亦可跑。
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$DOTFILES_DIR/packages/optional.txt"

log()  { printf '[optional] %s\n' "$*"; }
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

# 非-brew（curl）工具的安裝對照；目前無項目，新增非-brew 選配時在此加 case。
curl_install() {
    case "$1" in
        # example) curl -fsSL https://example.com/install.sh | sh ;;
        *) log "curl 安裝未定義: $1"; return 1 ;;
    esac
}

[[ -f "$MANIFEST" ]] || { log "找不到 manifest: $MANIFEST"; exit 1; }
command -v brew &>/dev/null || { log "需要 Homebrew（brew 不在 PATH）"; exit 1; }

# 過濾註解與空行，留 `group | type | name | description`
ENTRIES=()
while IFS= read -r l; do ENTRIES+=("$l"); done < <(grep -vE '^[[:space:]]*(#|$)' "$MANIFEST")
[[ ${#ENTRIES[@]} -gt 0 ]] || { log "manifest 沒有可裝項目"; exit 0; }

# --- 選擇 ---
SELECTED=()
if command -v fzf &>/dev/null; then
    while IFS= read -r l; do SELECTED+=("$l"); done < <(printf '%s\n' "${ENTRIES[@]}" \
        | fzf --multi --height=80% --reverse \
              --header='空白鍵多選、Enter 確認、Esc 取消 | 欄位: group | type | name | 說明')
else
    log "fzf 不在，改用數字選單"
    i=1
    for e in "${ENTRIES[@]}"; do printf '  %2d) %s\n' "$i" "$e"; i=$((i+1)); done
    printf '輸入編號（空白分隔、可多選；直接 Enter 取消）: '
    read -r picks
    for n in $picks; do
        [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#ENTRIES[@]} )) && SELECTED+=("${ENTRIES[$((n-1))]}")
    done
fi

[[ ${#SELECTED[@]} -gt 0 ]] || { log "沒有選擇任何項目，結束"; exit 0; }

# --- 安裝 ---
installed=(); skipped=(); failed=()

for line in "${SELECTED[@]}"; do
    IFS='|' read -r group type name desc <<< "$line"
    type="$(trim "$type")"; name="$(trim "$name")"; short="${name##*/}"

    case "$type" in
        brew)
            if brew list --formula --versions "$short" &>/dev/null; then
                log "已裝，跳過: $name"; skipped+=("$name")
            else
                log "安裝 (brew): $name"
                if brew install "$name"; then installed+=("$name"); else log "失敗: $name"; failed+=("$name"); fi
            fi ;;
        cask)
            if brew list --cask --versions "$short" &>/dev/null; then
                log "已裝，跳過: $name"; skipped+=("$name")
            else
                log "安裝 (cask): $name"
                if brew install --cask "$name"; then installed+=("$name"); else log "失敗: $name"; failed+=("$name"); fi
            fi ;;
        bundle)
            log "安裝 (bundle): $name"
            if brew bundle --file="$DOTFILES_DIR/packages/$name"; then
                installed+=("$name"); else log "失敗: $name"; failed+=("$name"); fi ;;
        curl)
            if curl_install "$short"; then installed+=("$name"); else failed+=("$name"); fi ;;
        *)
            log "未知 type '$type'，跳過: $name"; failed+=("$name") ;;
    esac
done

# --- 摘要 ---
echo
log "完成 — 安裝 ${#installed[@]} / 跳過 ${#skipped[@]} / 失敗 ${#failed[@]}"
[[ ${#failed[@]} -gt 0 ]] && log "失敗清單: ${failed[*]}"
exit 0
