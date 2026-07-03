# hyprland — Wayland compositor 主設定

Hyprland 的主設定。Linux **desktop 層**部署（`stow_pkgs hyprland waybar wofi mako hyprlock themes` 一批），只在有畫面的 Linux 機器有意義；binary 由 `packages/arch-desktop.txt` 安裝。

## 規劃方向

- **最小配置策略**：從「VM（virtio-gpu）上能啟動 + render」的最小集長出來，每加一段都有實測理由（VM cursor 失效用 `cursor { no_hardware_cursors }`、單虛擬輸出用 `monitor = , preferred, auto, 1`）。不從網路上的大而全範本起步。
- **它是桌面元件的組裝點**：waybar / mako 由本檔 `exec-once` 啟動、wofi / hyprlock 由本檔 keybind 叫起（`SUPER+D` / `SUPER+L`）、配色 `source ~/.config/hypr/colors.conf`（themes 套件提供）。桌面元件的啟動關係都在這份檔案裡查。

## 使用條件

- **機器特定的段落**：`monitor` 行在多螢幕實體機要 override（解析度 / 位置 / 縮放是硬體綁定的，這行是每台機器最可能要改的地方）。
- 鍵盤 layout 目前 `us`；`$mainMod` 在 Mac host 的 VM 裡有 SUPER 鍵被宿主攔截的問題（實測見 blog handson record），VM 上要測 keybind 用 `hyprctl dispatch` 從終端機觸發。
- 只能從實體圖形 VT 啟動（compositor 需要 DRM master 與 logind seat），SSH pty 起不來——這是架構約束不是 config 問題。
