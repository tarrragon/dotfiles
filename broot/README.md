# broot — 樹狀檔案管理器設定

broot（可展開樹狀 + 模糊跳轉的終端機檔案管理器）的 stow 套件。terminal 層部署（`install.sh` 的 `stow_pkgs zsh zellij btop broot`），跨 macOS / Linux 共用；binary 由 `Brewfile` / `packages/arch-terminal.txt` 安裝。

## 規劃方向

- **config 只放非預設值**（`conf.hjson` 首行宣告的原則）：broot 升級後新增的預設行為自動生效，不被舊的全量 dump 蓋住。改設定時維持這條——只寫「跟預設不同的」。
- **verbs 只留實際在用的**（`verbs.hjson`）：不留註解掉的範例。目前的自訂動詞：`edit`（$EDITOR 開檔不離開 broot）、`zip`、`create`、git diff 類。
- skins 引用 broot 內建路徑（dark-blue / white 依終端機 luma 自動切），不自帶 skin 檔。

## 使用條件

- 檔案管理器選型上 broot 是「樹狀」範式的主力（Miller 欄狀是 yazi / ranger），選型脈絡見 blog 的終端機檔案管理器選型篇。
- `$EDITOR` 未設時 `edit` 動詞會失敗——editor 由 zsh 套件的環境設定提供。
