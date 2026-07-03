# ranger — 終端機檔案管理器的 stow 套件（預留殼）

ranger 客製設定的 stow 套件位置。目前是**預留殼**：binary 有裝（`Brewfile` 的 `brew "ranger"`、`packages/arch-terminal.txt`）、用預設值跑，沒有客製 config、也不在 `install.sh` 的 `stow_pkgs` 清單。

## 為什麼是空的

這個目錄跟 `broot/`、`btop/`、`zellij/` 是同一批建立的終端機 TUI 鷹架（2026-06-29）。其他三個後來放了實際 config 並進了 stow 清單；ranger 在檔案管理器選型實測後定位成「保留備用、不客製」——主力是 `yazi` / `broot`，ranger 的 Python 相依（新版 Python 噴 SyntaxWarning）與預設無語法高亮（要另裝 `highlight` / `bat` / `pygments` 當 previewer）讓它退居次選。

## 之後要啟用時

1. 設定檔放進 `ranger/.config/ranger/`，ranger 的主要設定檔：

   | 檔案         | 作用                                        |
   | ------------ | ------------------------------------------- |
   | `rc.conf`    | 主設定（keybinding、顯示選項、預覽開關）    |
   | `rifle.conf` | 檔案開啟規則（哪種副檔名用哪個程式開）      |
   | `scope.sh`   | 預覽腳本（接 `bat` / `highlight` 給高亮）   |

   產生預設檔當底再改：`ranger --copy-config=all`（會寫到 `~/.config/ranger/`，改完搬進來）。

2. 在 `scripts/install.sh` 的 stow 清單加上 ranger（跟 zellij / btop / broot 同一行）。

3. 目標機 `git pull` + 重跑 `install.sh`（或 `scripts/remote-sync.sh <host>`）即部署。
