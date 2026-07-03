# caelestia — 整合式桌面 shell 設定（copy 部署、不 stow）

Caelestia（Quickshell 上的整合式 Hyprland 桌面 shell）的使用者層設定。Linux desktop 層部署，但**走 `deploy.sh` copy、不走 stow**——這是全 repo 唯一的例外，理由見下。

## 為什麼不 stow

caelestia 用 atomic write 改寫自己的 `shell.json`：驗證設定後重新序列化回寫，會把 stow symlink 換成實檔；且 `stow --adopt` 會把它改寫過的內容 clobber 回 repo。所以「app 自己管理的 config」走 copy 部署，`deploy.sh` 以一般使用者身分把 repo 版蓋過 live 檔。

## 維護規則（硬規則）

- **repo 是唯一真實來源**：持久設定改 `caelestia/.config/caelestia/` 再跑 `deploy.sh`（或 `scripts/remote-sync.sh`）。
- **不用 caelestia 的 GUI（nexus 設定面板）改設定**——那寫進 live 檔、下次部署被覆蓋。
- 判斷部署健康的訊號：live 檔從 symlink 變實檔屬預期（copy 部署）；repo 檔被程式重排序列化代表有人反向操作了。

## 內容

| 檔案            | 作用                                                       |
| --------------- | ---------------------------------------------------------- |
| `shell.json`    | shell 主設定（idle 鎖屏 timeout 等；caelestia 會回寫此檔） |
| `cli.json`      | caelestia CLI 設定（桌布目錄、scheme mode）                |
| `hypr-user.lua` | caelestia 的 Hyprland 使用者層 hook                        |
| `deploy.sh`     | copy 部署腳本（冪等、不 sudo）                             |

## 使用條件

- 依賴 `quickshell-git`（AUR、穩定版缺 API）與 Hyprland，套件在 `packages/arch-desktop.txt`。
- 只在跑 Hyprland 桌面的 Linux 機器有意義；`install.sh desktop` 階段自動呼叫 `deploy.sh`。
