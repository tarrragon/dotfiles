# scripts/ — bootstrap 腳本使用說明

把一台新機器帶到可用工作環境的分層 bootstrap。三個檔案的職責切分：

| 檔案               | 職責                                                                       |
| ------------------ | -------------------------------------------------------------------------- |
| `install.sh`       | 入口 + 共通層：偵測平台 → 委派套件安裝 → stow 部署 / oh-my-zsh + powerlevel10k / Claude Code |
| `install-arch.sh`  | Arch 套件層：`pacman -Syu` + 依 stage 讀 `packages/arch-*.txt`             |
| `install-macos.sh` | macOS 套件層：brew bootstrap + `Brewfile`（不分層、一次全裝）              |

## 用法

```bash
./scripts/install.sh            # 全裝（預設 = desktop）
./scripts/install.sh base       # 最小工具集（stow/git/zsh/curl）+ git config
./scripts/install.sh terminal   # base + CLI 工具鏈 + zsh 框架 + Claude Code
./scripts/install.sh desktop    # terminal + 圖形桌面（Linux = Hyprland + rice）
```

- **層是累進的**：後層自動涵蓋前層。
- **冪等**：重跑安全（`pacman --needed` / `stow --adopt` / 目錄存在檢查都在），改了 config 或清單直接重跑即可。
- **選層判準**：CI / 容器 → `base`；headless server / 遠端開發機 → `terminal`；桌面機 → `desktop`。

## 分層內容

| Stage      | 套件                                        | 共通層動作                                              |
| ---------- | ------------------------------------------- | -------------------------------------------------------- |
| `base`     | stow / git / zsh / curl / ca-certificates   | stow `git`                                               |
| `terminal` | CLI 工具鏈（rg/fd/fzf/tig/lazygit...）+ nodejs | stow `zsh zellij btop broot`、clone OMZ + p10k + plugins、裝 Claude Code、chsh |
| `desktop`  | Hyprland + rice + 字型                      | stow `hyprland waybar wofi mako hyprlock themes caelestia`（Linux only） |

config 跟它依賴的框架同層交付——`.zshrc` 期望 OMZ/p10k 存在，所以 zsh 的 stow 歸 `terminal` 不歸 `base`；字型只在有畫面的機器有意義，歸 `desktop`。

## 前置條件

- **Arch**：`sudo` 要先由 root 手動裝（base image 不附、而腳本靠 sudo 裝套件，chicken-and-egg）。無人值守環境另需 NOPASSWD：

  ```bash
  pacman -S --needed sudo git
  echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/20-nopasswd
  chmod 0440 /etc/sudoers.d/20-nopasswd
  ```

- **macOS**：無前置，`install-macos.sh` 會自己裝 Homebrew。
- **Claude Code 認證**：腳本只裝不認證。在有瀏覽器的機器跑 `claude setup-token`，再於目標機 `export CLAUDE_CODE_OAUTH_TOKEN=<token>`。

## Log 與除錯

- 每次執行完整輸出在 `~/.local/state/dotfiles/install-<timestamp>.log`。
- 失敗時 ERR trap 會印出行號與確切指令（`ERROR line N: [指令] exit=N`），從那行開始查。
- 非互動（SSH 一行式、無人值守）踩過的坑都已內建處理：pacman `--noconfirm`、裝前 `-Syu`（stale db 404）、`chsh` 失敗不中斷。

## 平台分歧的維護規則

1. 安裝手段跨平台一致（git clone、curl installer、stow）→ 寫進 `install.sh` 共通層
2. 只是「套件名 / 套件管理器」不同 → 各平台腳本 + `packages/<distro>-*.txt`，各自維護
3. 概念只存在某平台（Hyprland、cask app）→ 只出現在該平台清單的 desktop 層

新增發行版（如 Debian）：建 `install-debian.sh` + `packages/debian-*.txt`，在 `install.sh` 的分支加一行委派。清單逐台實測建立，不憑印象抄對照表——套件名跨發行版不通用（`fd` vs `fd-find`、`github-cli` vs `gh`）。
