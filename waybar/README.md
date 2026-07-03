# waybar — 狀態列設定

Waybar（Wayland 狀態列）的 stow 套件。Linux desktop 層部署，由 `hyprland.conf` 的 `exec-once` 啟動。

## 規劃方向

- **檔案分工**：`config.jsonc` 管結構與模組（放什麼、在哪邊）、`style.css` 管外觀（色碼手動對齊 themes 的 Catppuccin Mocha——CSS 引用不到 Hyprland 變數）。
- **佈局取捨**（VM 實測定案）：左 = 工作區 + 視窗標題（focus 狀態）、中 = 時鐘（最常看的放正中）、右 = 系統狀態（network / audio / cpu / memory / battery / tray）。
- **一份 config 跨機型**：模組對缺席硬體自動退化（VM 沒電池時 battery 模組自動隱藏、不報錯不留空位），所以桌機 / 筆電 / VM 共用同一份，不為機型分檔。

## 使用條件

- 字型用 `MesloLGS Nerd Font`（狀態列 icon 是 Nerd Font 私有區 glyph，字族名對不上會變豆腐方塊）。
- 改設定後重啟生效：`pkill waybar` 後由 Hyprland 重新 exec（或手動 `waybar &`）。
- 「bar 還畫著但點不動」是 shell 類程式的共通陷阱（畫得出來不等於還活著），判讀見 blog 的桌面故障篇。
