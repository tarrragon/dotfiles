# zellij — 終端機多工器設定

Zellij 的 stow 套件。terminal 層部署，跨 macOS / Linux 共用；binary 由 `Brewfile` / `packages/arch-terminal.txt` 安裝。

## 規劃方向

- **`clear-defaults=true` + 全量自定 keybind**：不疊在預設鍵位上打補丁，整份鍵位表自己寫（vim 風格導航）。代價是 zellij 升級新增的預設鍵位不會自動出現，收益是鍵位行為完全由 repo 決定、不隨版本漂移。
- 這是 repo 裡最大的單一 config（270 行），幾乎全是 keybind 表——改鍵位時整份檔案就是完整真相，不用對照官方預設表推算。

## 使用條件

- **無人值守 / SSH 長任務的關鍵件**：session 在 SSH 斷線後存活，重連 `zellij attach` 回到現場。遠端機器跑長任務（建置、agent）靠它，操作模式見 blog 的無人值守篇。
- 判斷「session 還在不在」用 `zellij list-sessions`（權威來源），不是看終端機畫面。
- 多工器選型（tmux vs zellij）的脈絡見 blog 的 multiplexer 篇——這裡選 zellij 是因為預設 UI 對新手可見（底部鍵位提示列）。
