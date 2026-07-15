# 核心 Brewfile — 每台機器都要的最小集。
#
# 選配工具（db / lsp / containers / editor / ai-agent / 其他 role-specific）不在這裡：
#   見 packages/optional.txt + scripts/install-optional.sh（picker 多選按需安裝）。
# 判準：stow config 綁定的 binary、bootstrap 依賴、通用 shell/git 日常 → core；
#       「某台有做那件事才要」→ optional。
#
# 語言 runtime（node/go/uv+Python/flutter）不由 brew 管：見 scripts/install-runtimes.sh，
# 它在 brew bundle「之前」跑，好讓下方 go/uv/npm 條目有 go/node/uv 可用。

# taps 保留原樣（onevcat/tap 供 optional 的 prowl；prowl 安裝時 brew 也會自動 tap，
# 待確認 omnisharp / onevcat 是否可精簡）
tap "omnisharp/omnisharp-roslyn"
tap "onevcat/tap"
tap "xo/xo", trusted: { formulae: ["usql"] }

# === 核心 CLI（每台機器）===

# Shell extension to jump to frequently used directories
brew "autojump"
# New way to see and navigate directory trees（stow config）
brew "broot"
# Resource monitor（stow config）
brew "btop"
# Fuzzy finder — 通用 + scripts/install-optional.sh 的 picker
brew "fzf"
# Disk usage analyzer with console interface written in Go
brew "gdu"
# GitHub command-line tool
brew "gh"
# Syntax-highlighting pager for git and diff output（綁 git config）
brew "git-delta"
# Improved top (interactive process viewer)
brew "htop"
# Simple terminal UI for git commands（主力 git TUI）
brew "lazygit"
# File browser（stow config）
brew "ranger"
# Organize software neatly under a single directory tree（bootstrap 依賴）
brew "stow"
# Pluggable terminal workspace（stow config、主力多工器）
brew "zellij"
# Fish shell like syntax highlighting for zsh
brew "zsh-syntax-highlighting"

# === 核心 GUI（有畫面的機器都要）===
# 主力終端機。repo 多處註解已把 Ghostty 當成既定前提（zsh/.zshenv 的 LC_CTYPE
# 處理、optional.txt 的字型說明），故納為核心而非選配。無畫面的機器裝 cask 亦無害
# （brew 會裝但不影響 headless 使用）。
cask "ghostty"

# === workflow 工具（go / uv / npm）===
# 不放這裡：brew bundle 的 go/uv/npm 條目會去裝 Homebrew 自己的 node/go（繞過我們用
# nvm/tarball pin 的版本、還會平行搶 node 的 lock 而失敗——乾淨機器冷測實證）。
# 改由 scripts/install-runtimes.sh 用「我們 pin 的 runtime」裝這些工具（見該檔 *_TOOLS）。

# 刻意不納管的實驗性套件（intentionally unmanaged）
# 一次性 / 實驗用途、決定既不進 core 也不進 optional。跑 `brew bundle cleanup` 或現況
# 比對時會出現在「未記錄」清單、屬預期、不用回頭查。
#   gifsicle  (formula) — GIF 編輯、一次性用途
#   utm       (cask)    — VM 實驗環境
# 註：ollama 已從這裡移到 packages/optional.txt 的 ai-agent 群組。
