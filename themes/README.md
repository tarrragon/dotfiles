# themes — 跨工具配色定義（Catppuccin Mocha）

集中配色的 stow 套件，部署 `colors.conf` 到 `~/.config/hypr/`。Linux desktop 層。

## 為什麼獨立成一包

配色是跨工具共用的資產——「一個工具一個 stow 套件」的切法下，配色不屬於任何單一工具、自成一包。換配色方案時只動這裡加上各工具的引用處，不必翻每個套件。

## 使用條件（實測確認的邊界）

- **只有 Hyprland 自家的 .conf 能 `source` 這些 `$` 變數**（`hyprland.conf`；hyprlock 雖同語法家族但獨立 binary、也 source 不到）。Waybar / Wofi 的 CSS、Mako 的 ini 各自獨立、無法引用——所以這份是 Hyprland 系的 SSoT，**其他工具的色碼靠人工對齊同一組 hex**。
- 換配色方案的完整動作：改這份 → 手動同步 waybar `style.css`、wofi `style.css`、mako `config`、hyprlock `hyprlock.conf` 的字面色碼 → 各工具 reload。grep 舊 hex 值可以確認沒漏。
- caelestia 走自己的 scheme 系統（`cli.json` 的 `scheme.mode`），不吃這份——整合式 shell 與手動拼裝是兩條配色管線。
