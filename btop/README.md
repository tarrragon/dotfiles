# btop — 系統資源監控 TUI 設定

btop（CPU / 記憶體 / 網路 / 行程的全螢幕監控）的 stow 套件。terminal 層部署，跨 macOS / Linux 共用；binary 由 `Brewfile` / `packages/arch-terminal.txt` 安裝。

## 規劃方向

- **config 是全量檔**（283 行、含所有預設值與版本標頭）——這跟 broot 的「只放非預設」策略相反，因為 `btop.conf` 是 btop 自己產生與回寫的格式：在 UI 內按 `Esc → Options` 改設定，btop 會把整份檔案回寫。
- 由此的維護規則：**在 UI 改完設定後，回 repo `git diff` 檢視並提交**——repo 是持久狀態的真實來源，UI 是編輯介面。版本升級後標頭（`#? Config file for btop v.X`）變動屬正常 diff。

## 使用條件

- 跟 `monitoring/` 套件是互補關係：btop 是「人在終端機上即時看」，monitoring 是「沒人看時自動告警」。
- TUI 監控工具的選型（btop vs htop 的互動模型差異）見 blog 的 TUI 監控工具篇。
