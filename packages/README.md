# packages — 套件清單

兩類清單住在這裡：Linux（Arch）的分層套件清單，以及 macOS 的選配工具層。

Arch Linux 的套件清單由 `scripts/install-arch.sh` 讀取（過濾 `#` 註解與空行、餵給 `pacman -S --needed --noconfirm`）。macOS 的**核心**套件在 repo 根的 `Brewfile`（Homebrew 自有格式）；macOS 的**選配**工具在本目錄的 `optional.txt` + `Brewfile.editor`（見下方「macOS 選配層」）。

## 分層規劃

| 清單                | 層       | 收什麼                                                     | 什麼機器裝                 |
| ------------------- | -------- | ---------------------------------------------------------- | -------------------------- |
| `arch-base.txt`     | base     | bootstrap 自身依賴的最小集（stow / git / zsh / curl / CA） | 所有機器                   |
| `arch-terminal.txt` | terminal | CLI 工具鏈 QoL（含 stowed config 對應的 binary）           | 含 headless server         |
| `arch-desktop.txt`  | desktop  | Hyprland + rice + 字型                                     | 只有有畫面的機器           |

後層自動涵蓋前層（`install.sh desktop` 三層全裝）。

## 新增套件的判準

- 問「最小的哪種機器需要它」：bootstrap 跑不動就缺的 → base；SSH 進去工作會用到 → terminal；只在有螢幕時有意義（字型、GUI、compositor）→ desktop。
- **stowed config 跟它的 binary 要同層**：加了某工具的 stow 套件、它的 binary 就要進對應清單（歷史教訓：broot/btop/zellij 曾經 config stow 了、binary 沒裝）。
- 字型一律 desktop 層——字型只在有畫面的機器有意義。
- macOS 也要用的工具，`Brewfile` 同步加一筆。

## 使用條件

- `sudo` 是清單外前置：base 系統沒附 sudo、而清單就是靠 sudo 裝的（chicken-and-egg），要先以 root 手動裝。
- AUR 套件（如 `quickshell-git`）不在這些清單——pacman 裝不了，見 `arch-desktop.txt` 內的註記與對應手動步驟。
- Debian/Ubuntu 沒有分層清單（沒有實測機器）；真要支援時建 `debian-*.txt` + `install-debian.sh` 獨立維護。

## macOS 選配層

macOS 的工具分兩層：核心 `Brewfile`（每台都要）+ 本目錄的選配清單（role-specific、按需裝）。判準跟 Arch 同源——「stow config 綁定 / bootstrap 依賴 / 通用日常」→ 核心；「某台有做那件事才要」→ 選配。

| 檔案                    | 作用                                                                            |
| ----------------------- | ------------------------------------------------------------------------------- |
| `optional.txt`          | 選配工具清單，`group \| type \| name \| description`；`scripts/install-optional.sh` 讀取 |
| `Brewfile.editor`       | VS Code + 擴充的一整包（brew-native `vscode "..."`），對應 `optional.txt` 的 `editor \| bundle` 項 |

用法：`scripts/install-optional.sh` → picker 多選 → 按 `type`（brew / cask / bundle / curl）安裝、已裝跳過、單項失敗不中斷。

新增選配工具：在 `optional.txt` 加一行（挑既有 group 或開新 group）。非-brew 工具用 `type=curl`、並在 `install-optional.sh` 的 `curl_install()` 補對應安裝指令。VS Code 擴充加進 `Brewfile.editor`。
