# hyprlock — 鎖屏設定

Hyprlock（Hyprland 生態的 ext-session-lock 鎖屏）設定。Linux desktop 層部署，由 `hyprland.conf` 的 `SUPER+L` keybind 叫起。

## 規劃方向

- 配色目標是 Catppuccin Mocha，但**色碼用 rgba 字面值、不引用 themes 的變數**——hyprlock 是獨立 binary、自己的設定語法，source 不到 `colors.conf` 的 `$` 變數。改配色方案時這份要手動對齊 themes。
- 背景用「截當下畫面 + 模糊」；`blur_passes = 2` 是 VM 軟體渲染下「看得出霧化又不卡」的實測折衷，實體 GPU 機器可以調高。

## 使用條件

- **測試鎖屏前先想好回程**：鎖屏一旦啟動、唯一正常出口是認證。`pkill hyprlock` 不會解鎖——compositor 會維持鎖定進入失效保護（ext-session-lock 的安全語意），要從另一個 TTY 或 SSH 用 `allow_session_lock_restore` 復原。VM / 自動化環境測試尤其注意。
- 依賴 `hyprlock` binary（`packages/arch-desktop.txt`）與跑著的 Hyprland session。
