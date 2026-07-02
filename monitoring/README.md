# monitoring — systemd 服務失敗告警

把「服務掛了主動推播」正規化成 repo 管理的可複用件，而不是在機器上 ad-hoc 手放。

## 內容

| 檔案 | 部署到 | 作用 |
| --- | --- | --- |
| `bin/notify-failure` | `/usr/local/bin/notify-failure` | 送告警的腳本（本機留底 + curl ntfy） |
| `system/alert@.service` | `/etc/systemd/system/alert@.service` | OnFailure 處理器（template，已內建遞迴防護） |
| `svc-alert-topic.example` | `/etc/svc-alert-topic`（佔位） | ntfy topic；真值不進 git、部署後手填 |
| `deploy.sh` | — | 在目標機冪等安裝上述系統檔（需 sudo） |

## 部署

系統 unit 在 `/etc`、stow 管不到，所以走 `deploy.sh`（在目標機的 dotfiles clone 裡跑）：

```bash
sudo ./monitoring/deploy.sh
echo 'your-private-topic' | sudo tee /etc/svc-alert-topic   # 填真正的 topic
```

從本機一鍵同步到遠端機器（推薦）：

```bash
scripts/remote-sync.sh <ssh-host> 'sudo ./monitoring/deploy.sh'
```

## 讓某個 service 被監控（宣告式）

要監控哪些 service 由 `hooks/units.txt` 宣告——一行一個 unit。deploy 為每個裝
`<unit>.d/onfailure.conf` drop-in（附加、不動原 unit）。加一行就多監控一個、走 git 部署即生效：

```bash
echo 'nginx.service   # 加註解說明為何監控它' >> monitoring/hooks/units.txt
git add monitoring/hooks/units.txt && git commit -m "monitor nginx"
scripts/remote-sync.sh <host> 'sudo ./monitoring/deploy.sh'
```

驗證掛上了（不必弄掛服務）：`systemctl show <unit> -p OnFailure` 應列出 `alert@<unit>.service`。

臨時、不進 repo 的掛法（ad-hoc、不建議常態用）：`sudo systemctl edit <unit>` 填 `[Unit]` + `OnFailure=alert@%n.service`。

要一次套用到所有 service，用 top-level drop-in（`/etc/systemd/system/service.d/onfailure.conf`）：

```ini
[Unit]
OnFailure=alert@%n.service
```

`alert@.service` 已內建 `OnFailure=`（清空）防止全域 drop-in 讓它觸發自己。

## 先自動重啟、放棄才告警

暫時性失敗自己重試就好。讓 systemd 先重啟、撐過上限才進 failed：

```ini
[Service]
Restart=on-failure
RestartSec=5
[Unit]
StartLimitBurst=3
StartLimitIntervalSec=60
```

實測坑：`OnFailure` **每次失敗都觸發**（含 auto-restart 中途），只靠這段 config 會被每次瞬斷洗告警（一個重試 3 次的 crash 觸發了 4 次）。`notify-failure` 已內建 gate（`ActiveState != failed` 就跳過中途），所以實際只在真正放棄那次告警——config 管「重試幾次」、handler 的 gate 管「只在終局吵」。

## 整台機器死掉的盲點

`OnFailure` 靠 systemd 觸發，機器當掉就發不出告警。那一層要體外心跳（dead-man switch）：機器定時 `curl` healthchecks.io / Uptime Kuma，訊號停由體外告警。體內方案報不了自己這台的死。

完整判讀與四層框架見 blog：`/linux/debug/service-failure-monitoring/`。

## demo canary（測試靶子）

`demo/` 是一個可控的 HTTP 健康服務，給監控當靶子與 canary（不必拿 sshd 這種真服務去故意弄掛）。部署（需先跑過本層 deploy.sh）：

```bash
sudo ./monitoring/demo/deploy.sh
```

它示範兩種失敗、對應兩層偵測：

- `curl 127.0.0.1:8899/crash` → 進程退出 → systemd 標 failed → `OnFailure` 告警。
- `curl 127.0.0.1:8899/hang` → 進程活著但不回應 → systemd 抓不到，靠 `demo-health-check.timer` 每 2 分鐘 curl `/health` 逾時失敗才觸發告警。這條補上「進程活著 ≠ 在運作」的盲點。
