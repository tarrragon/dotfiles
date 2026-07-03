# wofi — 應用啟動器設定

Wofi（Wayland 原生啟動器）的 stow 套件。Linux desktop 層部署，由 `hyprland.conf` 的 `SUPER+D` keybind 叫起。

## 規劃方向

- **檔案分工**：`config` 管行為（模式、尺寸、搜尋選項）、`style.css` 管外觀（色碼手動對齊 themes）。
- **只寫死最常用的模式**：`mode=drun`（列 .desktop 應用程式）。`run`（PATH 執行檔）與 `dmenu`（吃 stdin、當選單元件用）留給 CLI 旗標臨時切（`wofi --show run`），不寫進 config——config 承載預設路徑、旗標承載例外。

## 使用條件

- drun 模式只列有 `.desktop` 檔的程式；純 CLI 工具不會出現在清單（那是設計不是故障），要跑用終端機或 `--show run`。
- 依賴 `wofi` binary（`packages/arch-desktop.txt`）；icon 顯示（`allow_images`）吃 `.desktop` 宣告的 icon 主題。
