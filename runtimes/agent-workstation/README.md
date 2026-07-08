# agent-workstation

遠端 coding agent 工作機的 runtime stack：把 Claude Code 裝進一個可重建的 container、掛工作目錄、用長效 token 注入認證。跟其他 `runtimes/` stack 一樣是「跟著你走、不綁單一 app」的參考 runtime；差別是它用 `docker run` + helper 驅動、不是 compose 多服務。

典型用法是一台常駐遠端機器（家用 VM 或 VPS）：從任何裝置連入、把任務丟給 container 內的 agent、關掉連線走人、跑完由 hook 推通知。

## 檔案

```text
agent-workstation/
├── Dockerfile        node:22-slim + Claude Code + git/curl/ripgrep、非 root node(UID 1000)
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

要「跑完主動推播到手機」時，在掛進 `claude-home` volume 的 `settings.json` 設一個 `Stop` hook 對 ntfy topic 發訊。topic 是機密（猜到就能發/收你的通知）、**不寫進本 repo**——真值走你自己的私密管道（環境變數或另一個 gitignored 檔）。設定形態：

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [
        { "type": "command",
          "command": "curl -s -H 'Title: 任務完成' -d 'agent 跑完了' https://ntfy.sh/<你的-topic>" }
      ] }
    ]
  }
}
```

hook 依賴 container 內有 `curl`（Dockerfile 已裝）。

## 升級紀律（同 runtimes 慣例）

image 不可變。要升 base（node major）或工具鏈時，複製整個目錄成新版本名、只改 `FROM` 與相依、build 成新 tag、舊目錄留著（git 隨時 rebuild 得回來）。不要「原地升級」一個 image。
