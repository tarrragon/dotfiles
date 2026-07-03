# git — 版控基礎設定

git 的全域設定。**base 層**部署（`install.sh` 最先 stow 的套件）——因為 clone 其他東西都靠它，任何機器、任何層都需要。

## 規劃方向

- `.gitconfig` 的行為選擇偏「線性歷史 + 少打旗標」：`pull.rebase`、`push.autoSetupRemote`、`fetch.prune`、`init.defaultBranch=main`。diff 顯示用 delta（語法高亮 + 行內差異），需要 `git-delta` binary（terminal 層清單）——base 層機器沒裝 delta 時 git 仍正常、只是回退純文字 diff。
- `.config/git/ignore` 是**全域 ignore**：目前擋 `**/.claude/settings.local.json`（Claude Code 的機器特有 permission / MCP 設定，不進任何專案版控）。跨專案都該被忽略的檔案往這裡加，不要逐專案重複。

## 使用條件

- `user.email` / `user.name` 是個人身分——這份 repo 給別人用時這是第一個要改的檔案。
- 工作用機器若需要不同 git 身分（公司 email），用 conditional include（`includeIf "gitdir:~/work/"`）疊加、不直接改這份。
