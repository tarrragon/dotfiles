#!/usr/bin/env bash
# 語言 runtime 重現層 — 非 Homebrew 安裝的 SDK,版本釘死、冪等。
#
# 為什麼獨立於 Brewfile:nvm / go / fvm 各自帶安裝器與版本管理,brew bundle 管不到。
# 為什麼不放進 install.sh 共通層:這裡帶「釘死的版本號」且目前是 darwin-arm64 專屬,
#   跟共通層那些「無版本、跨平台」的 curl installer 性質不同。要支援 Linux 再抽共通。
# 冪等:每個 runtime 先比對現有版本,已達標就跳過;重跑安全。
#
# 升級版本:改下方常數即可,重跑本腳本。
# 涵蓋範圍:Node(nvm)/ Go / uv+Python / Flutter(fvm),外加它們的 workflow 工具
#   (go install / npm -g / uv tool，見底部 *_TOOLS)。Ruby / Java 走 Homebrew(見 Brewfile)。
#   Python 不另裝 standalone:uv 供給 uv-managed Python、隔離使用(見 install_uv)。
#   另收尾 cc-statusline:go install 只 build binary,補上 macOS ime-helper(swiftc)與
#   ~/.claude/settings.json 的 statusLine 接線(見 setup_cc_statusline)。
# 未納管(刻意):Rust(rustup)/ Bun — 需要時自行 curl 官方 installer。
#
# 為什麼工具在這裡而非 Brewfile:brew bundle 的 go/uv/npm 條目會去裝 Homebrew 自己的
#   node/go(繞過我們 pin 的 nvm/tarball 版本)、且多條目平行搶 node 的 lock 而失敗
#   (乾淨機器冷測實證)。改由本腳本用「已裝好的 pin runtime」裝工具,徹底解耦。
#
# 執行順序:本腳本必須在 Homebrew bootstrap 之「後」——nvm(git clone)與 flutter(git)
#   需要 CLT,由 Homebrew bootstrap 一併裝好;下方守衛在 CLT 不在時 fail-fast。
#   相對 brew bundle 的位置已不重要(go/uv/npm 工具已移出 Brewfile、兩者解耦);
#   install-macos.sh 目前仍排在 brew bundle 之前,無害。只有 Go(純 curl+tar)不需 CLT。
set -Eeuo pipefail

# --- 釘死的版本(要升級改這裡)---
NVM_VERSION="v0.40.3"
NODE_VERSION="22.18.0"
GO_VERSION="1.26.5"   # 升自 1.25.1:workflow 的 go 工具(cc-statusline 等)需 go >= 1.26.1
FLUTTER_VERSION="3.38.10"
PYTHON_VERSION="3.14"   # uv 裝最新 3.14.x 修訂版;要降版改這裡(例:3.13)

# darwin-arm64 專屬;換平台要改這裡與 Go tarball 命名
GO_ARCH="darwin-arm64"

log() { printf '[runtimes] %s\n' "$*"; }

# --- 前置:Xcode Command Line Tools ---
# nvm(git clone)與 flutter(git)都需要 CLT。真實 flow 由 Homebrew bootstrap 先裝好;
# 若獨立跑本腳本且 CLT 不在,在此 fail-fast、給明確指引(而非讓 nvm 噴難懂的 git 錯誤)。
if ! xcode-select -p &>/dev/null; then
    log "缺 Xcode Command Line Tools;nvm / flutter 會失敗。"
    log "先跑 'xcode-select --install',或直接跑完整 install-macos.sh(Homebrew 會一併裝 CLT)。"
    exit 1
fi

# --- Node via nvm ---
# nvm 本體 curl 到 ~/.nvm、再由 nvm 裝指定 node 並設 default。
# path.zsh / tools.zsh 已有 nvm 接線,這裡只補「安裝 + pin 版本」。
install_node() {
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        log "installing nvm $NVM_VERSION"
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    fi
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    if ! nvm ls "$NODE_VERSION" &>/dev/null; then
        log "installing node $NODE_VERSION"
        nvm install "$NODE_VERSION"
    fi
    nvm alias default "$NODE_VERSION" >/dev/null
    log "node $(nvm run "$NODE_VERSION" --version 2>/dev/null) ready (default=$NODE_VERSION)"
}

# --- Go via 官方 tarball ---
# 官方 pkg 會寫 /etc/paths.d/go(系統檔、不入 dotfiles);改用 tarball 解到 /usr/local/go,
# PATH 由 path.zsh 的 /usr/local/go/bin 守衛接手(repo 可控、不依賴系統檔)。
install_go() {
    if [[ "$(/usr/local/go/bin/go version 2>/dev/null)" == *"go$GO_VERSION "* ]]; then
        log "go $GO_VERSION already installed, skip"
        return
    fi
    local tarball="go${GO_VERSION}.${GO_ARCH}.tar.gz"
    log "installing go $GO_VERSION (需要 sudo 解壓到 /usr/local)"
    curl -fsSL "https://go.dev/dl/${tarball}" -o "/tmp/${tarball}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "/tmp/${tarball}"
    rm -f "/tmp/${tarball}"
    log "go $(/usr/local/go/bin/go version) ready"
}

# --- uv + Python ---
# uv 走 astral standalone installer(curl 到 ~/.local/bin),再由 uv 供給一份 pin 的
# uv-managed Python。不另裝 standalone Python:系統 python3 由 CLT / Homebrew 依賴提供、
# 實際工作全走 uv 隔離環境(per-project venv / uv tool)。path.zsh 已有 ~/.local/bin/env 接線。
# 位置重點:必須在 brew bundle 之前,Brewfile 的 uv "..." 工具條目需要 uv 已在。
install_uv() {
    if ! command -v uv &>/dev/null && [[ ! -x "$HOME/.local/bin/uv" ]]; then
        log "installing uv (astral)"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v uv &>/dev/null; then
        log "WARN: uv 安裝後仍不在 PATH,跳過 Python provision"
        return
    fi
    log "uv $(uv --version 2>/dev/null | awk '{print $2}') ready"
    log "installing uv-managed Python $PYTHON_VERSION"
    uv python install "$PYTHON_VERSION"
    log "uv-managed python $PYTHON_VERSION ready"
}

# --- Flutter via fvm ---
# fvm CLI 走官方 standalone installer;fvm global 會建 ~/fvm/default symlink,
# path.zsh 的 ~/fvm/default/bin 守衛接手。只重現 default 版(多版本各專案自行 fvm install)。
install_flutter() {
    if ! command -v fvm &>/dev/null; then
        log "installing fvm"
        curl -fsSL https://fvm.app/install.sh | bash
        # installer 落點:fvm 4.x 裝到 ~/fvm/bin(macOS VM 冷測實證);其餘為舊版 / 別種 installer
        # 的可能位置。補進 PATH 供本次 session 使用。
        for d in "$HOME/fvm/bin" /usr/local/bin "$HOME/.fvm/bin" "$HOME/.pub-cache/bin"; do
            [[ -x "$d/fvm" ]] && export PATH="$d:$PATH"
        done
    fi
    if ! command -v fvm &>/dev/null; then
        log "WARN: fvm 安裝後仍不在 PATH,跳過 flutter;請確認 fvm installer 落點"
        return
    fi
    if [[ ! -d "$HOME/fvm/versions/$FLUTTER_VERSION" ]]; then
        log "installing flutter $FLUTTER_VERSION"
        fvm install "$FLUTTER_VERSION"
    fi
    fvm global "$FLUTTER_VERSION"
    log "flutter $FLUTTER_VERSION set as global default (~/fvm/default)"
}

# --- workflow 工具 ---
# 從 Brewfile 搬來（brew bundle 的 go/uv/npm 條目會裝 Homebrew node/go、繞過我們 pin 的
# 版本又會平行搶 lock——冷測實證）。這裡用上面裝好的 runtime 裝,版本跟隨各 runtime。
# 工具版本沿用原 Brewfile 的「不 pin、裝 latest」行為;要 pin 個別工具在名稱後加版本。

GO_TOOLS=(
    "github.com/tarrragon/cc-statusline@latest"
    "golang.org/x/tools/gopls@latest"
    "honnef.co/go/tools/cmd/staticcheck@latest"
    "github.com/xo/usql@latest"
)
NPM_TOOLS=(
    "@colbymchenry/codegraph" "@vtsls/language-server" "corepack" "ctx7"
    "intelephense" "markdownlint-cli" "typescript"
    "vscode-langservers-extracted" "yaml-language-server"
)
# UV_TOOLS 目前為空(刻意)。原本的 7 個工具是各專案 .claude/skills/ 內嵌、由
# `uv tool install --from <本地路徑>` 裝、不在 PyPI,無法 by-name 在新機重現(冷測實證
# 4 個 fail)。改為 clone 對應專案後手動裝。長期歸宿:抽成獨立 repo / 發佈(backlog)。
#   doc-system / ticket-system      ← <project>/.claude/skills/{doc,ticket}
#   version-release / mermaid-ascii / project-init / skill-sync ← <project>/.claude/skills/...
#   worktree-skill                  ← <project>/.claude/skills/worktree
UV_TOOLS=()

install_go_tools() {
    export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
    command -v go &>/dev/null || { log "WARN: go 不在,跳過 go tools"; return; }
    for pkg in "${GO_TOOLS[@]}"; do
        log "go install ${pkg%@*}"
        go install "$pkg" || log "WARN: go tool 失敗: $pkg"
    done
}

# --- cc-statusline：補上 go install 補不到的兩步 ---
# GO_TOOLS 的 `go install .../cc-statusline` 只 build 出 Go binary，但這個 statusline 還需要：
#   (1) macOS 的 ime-helper（Swift）——`go install` 不碰 .swift，缺它 IME 顯示會被靜默略過；
#       helper 必須跟 binary 放同一目錄（~/go/bin），statusline 才找得到。
#   (2) ~/.claude/settings.json 的 statusLine 條目——binary 裝好也要接進 Claude Code 才會生效。
# 兩步都依賴 binary（上一步 install_go_tools 剛裝好），且都是 darwin 專屬，故緊接於此。
# 遵循本 repo「config 跟依賴的框架同層交付」原則：statusLine 設定寫在 binary 落地的同層。
setup_cc_statusline() {
    export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
    local bin; bin="$(command -v cc-statusline || true)"; [[ -z "$bin" ]] && bin="$HOME/go/bin/cc-statusline"
    if [[ ! -x "$bin" ]]; then
        log "WARN: cc-statusline binary 不在（go install 失敗？），跳過 statusline 設定"
        return
    fi

    # (1) ime-helper：從 go module cache 取跟 binary 同版本的 .swift 原始碼（go install 已解壓進 cache、
    #     免再 clone、版本天然對齊），swiftc build 進 ~/go/bin。缺 swiftc / 缺原始碼都只 WARN 不中斷
    #     ——IME 顯示是選配，缺 helper statusline 只是靜默略過該欄，非致命。
    if command -v swiftc &>/dev/null; then
        local src; src="$(ls -d "$(go env GOMODCACHE)"/github.com/tarrragon/cc-statusline@*/ 2>/dev/null | sort -V | tail -1)"
        if [[ -n "$src" && -f "${src}helper_darwin.swift" ]]; then
            log "building ime-helper (swiftc)"
            swiftc -O "${src}helper_darwin.swift" -o "$HOME/go/bin/ime-helper" \
                && log "ime-helper → ~/go/bin/ime-helper" \
                || log "WARN: swiftc build 失敗，IME 顯示將被略過"
        else
            log "WARN: 找不到 helper_darwin.swift（module cache 未就緒？），跳過 ime-helper"
        fi
    else
        log "WARN: 無 swiftc，跳過 ime-helper（IME 顯示將被略過）"
    fi

    # (2) 接進 Claude Code：jq 併入 statusLine（保留 theme/tui 等既有鍵），寫絕對路徑避免依賴
    #     Claude 執行 statusline 時的 PATH。冪等：內容無變不覆寫；settings 非合法 JSON 只 WARN。
    command -v jq &>/dev/null || { log "WARN: 無 jq，跳過 claude statusLine 設定"; return; }
    local settings="$HOME/.claude/settings.json"
    mkdir -p "$(dirname "$settings")"
    [[ -f "$settings" ]] || echo '{}' > "$settings"
    local tmp; tmp="$(mktemp)"
    if jq --arg cmd "$bin" '.statusLine = {type:"command", command:$cmd}' "$settings" > "$tmp" 2>/dev/null; then
        if cmp -s "$tmp" "$settings"; then
            log "claude statusLine 已是最新，skip"; rm -f "$tmp"
        else
            mv "$tmp" "$settings"; log "claude statusLine → $bin"
        fi
    else
        rm -f "$tmp"; log "WARN: $settings 非合法 JSON，跳過 statusLine 設定（請手動加）"
    fi
}

install_npm_tools() {
    export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    command -v npm &>/dev/null || { log "WARN: npm 不在,跳過 npm tools"; return; }
    log "npm install -g（${#NPM_TOOLS[@]} 個,跑 nvm node ${NODE_VERSION}）"
    npm install -g "${NPM_TOOLS[@]}" || log "WARN: 部分 npm 工具失敗"
}

install_uv_tools() {
    # 空陣列守衛:bash 3.2 + set -u 下對空陣列展開 "${ARR[@]}" 會報 unbound
    [[ ${#UV_TOOLS[@]} -eq 0 ]] && { log "無 by-name uv 工具(skills 工具改手動,見上方註解)"; return; }
    export PATH="$HOME/.local/bin:$PATH"
    command -v uv &>/dev/null || { log "WARN: uv 不在,跳過 uv tools"; return; }
    for t in "${UV_TOOLS[@]}"; do
        log "uv tool install $t"
        uv tool install "$t" || log "WARN: uv tool 失敗: $t"
    done
}

install_node
install_go
install_uv
install_flutter
# 工具用上面裝好的 runtime 裝（node/go/uv 必須先跑）
install_npm_tools
install_go_tools
setup_cc_statusline   # ime-helper build + 接進 ~/.claude/settings.json（依賴 install_go_tools 的 binary）
install_uv_tools
log "runtimes done"
