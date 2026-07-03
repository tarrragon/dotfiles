# packages — Arch 套件清單（分層）

Arch Linux 的套件清單，`scripts/install-arch.sh` 讀取（過濾 `#` 註解與空行、餵給 `pacman -S --needed --noconfirm`）。macOS 的對應物是 repo 根的 `Brewfile`（Homebrew 自有格式，不在這個目錄）。

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
