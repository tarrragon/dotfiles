# zsh — shell 設定（模組化）

zsh 的 stow 套件。terminal 層部署（**不在 base 層**：`.zshrc` 依賴 oh-my-zsh / powerlevel10k / plugins，這些由 `install.sh` 的 terminal 階段 git clone——config 跟它依賴的框架同層交付，缺了框架 shell 會壞）。

## 檔案分工

| 檔案                            | 作用                                                                        |
| ------------------------------- | --------------------------------------------------------------------------- |
| `.zshenv`                       | 最早載入：SSH locale 修正（macOS 終端機送非法 LC_CTYPE 的防護）、cargo env |
| `.zshrc`                        | OMZ 框架載入、theme、plugins 宣告，末端 source `.config/zsh/` 各模組       |
| `.config/zsh/path.zsh`          | PATH 組裝（uv / bun / fvm / nvm 等工具鏈，全部帶存在性守衛）               |
| `.config/zsh/aliases.zsh`       | 跨平台 alias + 平台分支（Darwin 專屬段）                                   |
| `.config/zsh/tools.zsh`         | 工具初始化 hook（autojump / nvm / completions）                            |
| `.config/zsh/local.zsh.example` | 機器特定 override 的模板（copy 成 `local.zsh`，git 不追蹤）                |

## 規劃方向

- **模組化切檔**：一類職責一個檔（PATH / alias / 工具 hook），加東西時進對的檔、不全塞 `.zshrc`。
- **每個外部依賴都帶存在性守衛**（`[[ -f ... ]] &&`）：沒裝該工具的機器開 shell 不噴錯、優雅退化。新加工具初始化時維持這條。
- **機器特定的東西進 `local.zsh`**（不進版控）：專案 alias、機器特有 PATH、secret export。repo 內只放跨機器共識。

## 使用條件

- 預設 shell 切換（`chsh`）需要互動輸密碼，無人值守 bootstrap 會跳過——手動補跑 `chsh -s $(command -v zsh)`。
- p10k instant prompt 要求它的區塊保持在 `.zshrc` 最頂端，往上面加東西會破壞 instant prompt。
- SSH 進遠端亂碼 / 打字重複的老問題由 `.zshenv` 的 locale 修正處理，背景與 terminfo 那半見 blog 的 SSH 終端機故障篇。
