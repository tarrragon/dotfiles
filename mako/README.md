# mako — 通知 daemon 設定

Mako（Wayland 輕量通知 daemon）設定。Linux desktop 層部署，由 `hyprland.conf` 的 `exec-once` 啟動。

## 規劃方向

- 走「手動拼裝桌面」的通知位：Catppuccin Mocha 配色手抄 themes 的 hex（mako 的 ini 格式引用不到 Hyprland 變數）、字型用實裝的 `MesloLGS Nerd Font`（字族名要對齊 `packages/arch-desktop.txt` 實際裝的字型，教訓見 blog handson record）。
- `[urgency=...]` 區塊只覆寫邊框色，讓緊急程度可視化、其餘全域統一。

## 使用條件

- 改設定用 `makoctl reload` 熱載，不必重啟 daemon。但**補裝字型後要重啟 mako**——字型可用集合在 process 啟動時決定，reload 只重讀設定、不重建字型快取。
- 發通知的 app 要有 `libnotify`（`notify-send`）；CJK 內容要 `noto-fonts-cjk`，缺了通知變豆腐。兩者都在 `packages/arch-desktop.txt`。
- `monitoring/desktop/`（ntfy 桌面訂閱）把遠端告警轉成本地通知時，最後一哩就是打到 mako。
