# agent-workstation

遠端 coding agent 工作機的 runtime stack：把 Claude Code 裝進一個可重建的 container、掛工作目錄、用長效 token 注入認證。跟其他 `runtimes/` stack 一樣是「跟著你走、不綁單一 app」的參考 runtime；差別是它用 `docker run` + helper 驅動、不是 compose 多服務。

典型用法是一台常駐遠端機器（家用 VM 或 VPS）：從任何裝置連入、把任務丟給 container 內的 agent、關掉連線走人、跑完由 hook 推通知。

## 檔案

```text
agent-workstation/
├── Dockerfile        node:22-slim + Claude Code + gh + git/curl/ripgrep、非 root node(UID 1000)
├── deploy.sh         冪等：build image + scaffold .env 佔位 + 建 work/
├── run-agent.sh      fire-and-forget：注入 token、跑一次性任務（-p）
├── claude-shell.sh   互動對話：注入 token、起 -it 的 Claude Code
├── .env.example      token 佔位（複製成 .env 填真值）
└── work/             掛進 container /work 的工作目錄（不進 git）
```

## 起手

```bash
./deploy.sh                 # build image + 建 .env 佔位 + work/
```

### 一次性認證（產 token）

`deploy.sh` 不會替你認證——token 是機密、要手動取得並填入 `.env`。認證只做一次、token 有效約一年。

需要真 TTY（`docker run -it`），從自己的終端機跑（SSH 要帶 `-t`）：

```bash
docker run --rm -it -v claude-home:/home/node/.claude agent-workstation:v1 claude setup-token
```

流程印一個授權 URL、瀏覽器用 Anthropic 帳號授權、把授權碼貼回終端。跑完印出 `sk-ant-oat01-` 開頭的**長效 token**（不是你貼進瀏覽器的那個授權碼）。把它填進 `.env`：

```bash
umask 077
read -rs "T?貼上 token 後按 Enter: "   # zsh 語法；bash 用 read -rsp "..." T
printf 'CLAUDE_CODE_OAUTH_TOKEN=%s\n' "$T" > .env
chmod 600 .env
```

## 日常用

```bash
./claude-shell.sh                 # 互動對話（坐著跟 agent 聊）
./run-agent.sh                    # fire-and-forget，互動輸入任務（免引號）
./run-agent.sh -p "跑個測試"      # 一次性、帶參數
AGENT_WORK=~/proj ./claude-shell.sh   # 掛別的工作目錄
```

兩個 helper 每次都注入 `.env` 的 token，所以永遠不用重認證。

## 認證的心智模型（重要）

認證綁「每次 run 有沒有注入 token」、**不綁 session 或登入態**。這是 `setup-token` 的 env-var 模型：token 是機密、存在 host 側的 `.env`、`docker run` 時用 `--env-file` 注入；image 本身不含任何憑證。

由此得到幾個實務結論：

- 直接打 `claude`（沒注入 token）即使在活著的 session 裡也會要你重認證——一律用 helper。
- 在 `--rm` 臨時 container 裡走一次互動登入多半白做：憑證寫進容器、容器一結束就蒸發。可靠做法是注入 token、不靠登入態。
- image rebuild 幾次都不影響認證：token 跟 image 生命週期完全解耦。

## GitHub 認證（clone/push 私有 repo、開 PR）

agent 要動私有 repo 時、GitHub 認證是**跟 Claude Code 正交的第二顆機密**——`CLAUDE_CODE_OAUTH_TOKEN` 認證 agent → Anthropic（能不能思考）、GitHub token 認證 git 操作 → GitHub（能不能 clone/push）。兩者無關、但走**同一個注入模式**：gitignored `.env` 存機密、`--env-file` 在 runtime 注入、不進 image 也不進 repo。沒有這顆 token 時只能匿名讀 public repo；私有 repo 的 clone/push 會卡在 `could not read Username for 'https://github.com'`。

作法分兩步：產一顆 fine-grained PAT、把它填進 `.env` 的 `GH_TOKEN`。

**第一步：產 token**。到 <https://github.com/settings/personal-access-tokens/new>（或右上頭像 → Settings → 左側最底 Developer settings → Personal access tokens → Fine-grained tokens → Generate new token）：

- **Token name**：可辨識來源，例如 `agent-workstation-vm`（之後方便單獨 revoke）。
- **Expiration**：給短（30-90 天），到期或裝置遺失回同一頁 revoke / 重發。
- **Repository access → Only select repositories**：勾要讓 agent 動的 repo。**範圍外的 repo 會回 404 / 403**——事後要加新 repo，編輯同一顆 token 的 Repository access 即可，token 值不變、`.env` 不用重填。
- **Repository permissions → Contents: Read and write**（clone / push 的核心）；要用 `gh pr create` 再加 **Pull requests: Read and write**；Metadata 會自動變 Read-only（必帶）。

按 Generate 後，`github_pat_` 開頭的值只顯示一次、直接複製進下一步。

**第二步：填進 `.env`**。用 `read -rs` 讓 token 不顯示、不進 shell history、也不落在指令參數裡（整段照貼、看到提示再貼 token 按 Enter）：

```bash
cd <本目錄>   # runtimes/agent-workstation/
bash -c 'read -rsp "fine-grained PAT: " T && sed -i "s|^GH_TOKEN=.*|GH_TOKEN=$T|" .env && unset T && echo " 已寫入"'
```

**驗證**（token 有效 + git 真的帶得進去）：

```bash
docker run --rm --env-file .env agent-workstation:v1 gh auth status        # 應印：✓ Logged in to github.com account <你> (GH_TOKEN)
docker run --rm --env-file .env agent-workstation:v1 gh api user --jq .login
docker run --rm --env-file .env agent-workstation:v1 \
  bash -lc 'git ls-remote https://github.com/<owner>/<repo>.git HEAD'      # 授權內的 repo 應列出 HEAD；範圍外回 403 Write access not granted
```

`git ls-remote` 對授權外的 repo 回 `403 Write access to repository not granted` 其實是好訊號：代表 token 被 git 帶到 GitHub、且被驗過，只是 scope 不含該 repo——認證管線通、差授權。

image 內 git 已設好 credential helper（`git config --global credential."https://github.com".helper '!gh auth git-credential'`）：git 走 HTTPS 時把 `GH_TOKEN` 當密碼、`x-access-token` 當使用者名。token 從不寫進 `.gitconfig` 或 `~/.config/gh`、每次現讀環境變數——跟 Claude Code 的 env-var 模型一致。`gh` CLI 也原生讀同一顆 `GH_TOKEN`、所以 `gh pr create` 這類指令不需另外 `gh auth login`。

安全紀律跟 OAuth token 同一套：PAT 一樣躺在 container 的環境變數裡（`/proc/self/environ` 讀得到），在「`--dangerously-skip-permissions` + 開放 egress」下可被外洩。所以用 fine-grained + 最小 repo 範圍 + 短輪替、把 blast radius 壓到最小。

## 資安：token 為什麼不進 image、也不進 repo

- **image layer 不是機密**：`ENV TOKEN=...` 或 `COPY` token 進 Dockerfile 會烤進某一層、`docker history` 就讀得到、隨 image push/cache 到處跑。
- **私有 repo 也不是保險箱**：協作者、CI、誤設公開、git 歷史永久留存都是曝露面；token 有效一年、blast radius 大。
- **正解就是本 stack 的作法**：image / Dockerfile / helper 進 repo（無機密）、token 走 gitignored `.env`（`600`）在 runtime 注入。`.env` 已被 repo 根 `.gitignore` 與本目錄 `.gitignore` 雙重排除。
- **輪替**：到期前換、裝置遺失就到 Anthropic 後台 revoke 重發。

## 實測踩過、要知道的

- **`--dangerously-skip-permissions` 是刻意的**：container 邊界即權限邊界、agent 只碰得到掛進去的 `/work`、爆了困在 cgroup。容器內不必再疊一層檔案權限確認。
- **named volume 掛載點權限**：`~/.claude` 要在 image 裡先以 node owner 存在（Dockerfile 已 `mkdir + chown`），否則空 volume 以 root 掛上、非 root 的 node 寫不進憑證。
- **資源上限**：helper 帶 `--memory=2g`。任務吃爆時死的是 container 內程序、host 的連線基礎設施無感。
- **CJK 輸入用純 SSH、不要 mosh**：mosh 的本地回顯預測會讓中文（雙寬字元）輸入行顯示錯位；純 SSH 沒預測、顯示正常。移動漫遊才用 mosh、且此時多半打英文。

## ntfy 通知 hook（選用）

要「跑完主動推播到手機」時，在掛進 `claude-home` volume 的 `settings.json` 設一個 `Stop` hook 對 ntfy topic 發訊。topic 是機密（猜到就能發/收你的通知），走跟兩顆 token 同一套注入模式——填進 `.env` 的 `NTFY_TOPIC`、hook 用 `$NTFY_TOPIC` 引用它，設定檔本身不含機密：

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [
        { "type": "command",
          "command": "curl -s -H 'Title: 任務完成' -d 'agent 跑完了' \"https://ntfy.sh/$NTFY_TOPIC\"" }
      ] }
    ]
  }
}
```

hook 命令是 claude 程序 spawn 的子程序、繼承 container 的環境變數，所以 `$NTFY_TOPIC` 在執行時被展開。`settings.json` 躺在 `claude-home` volume、可以進版控（放結構、不放機密）；topic 只在 runtime 由 `--env-file` 補齊。

`Title:` header（`任務完成`）**不是機密、不注入**：它是會被公共 `ntfy.sh` server 看到的顯示字，直接寫在 settings.json 即可——反而要確保裡面不含敏感內容。hook 也依賴 container 內有 `curl`（Dockerfile 已裝）。

## 升級紀律（同 runtimes 慣例）

image 不可變。要升 base（node major）或工具鏈時，複製整個目錄成新版本名、只改 `FROM` 與相依、build 成新 tag、舊目錄留著（git 隨時 rebuild 得回來）。不要「原地升級」一個 image。
