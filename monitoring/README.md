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

## 讓某個 service 被監控

deploy 只裝告警基礎件，不替你決定監控誰。要監控某個 unit，加一行 `OnFailure`：

```bash
# 針對單一 unit（drop-in，不動原始 unit 檔）
sudo systemctl edit <unit>
# 在編輯器裡填：
#   [Unit]
#   OnFailure=alert@%n.service
```

要一次套用到所有 service，用 top-level drop-in（`/etc/systemd/system/service.d/onfailure.conf`）：

```ini
[Unit]
OnFailure=alert@%n.service
```

`alert@.service` 已內建 `OnFailure=`（清空）防止全域 drop-in 讓它觸發自己。

## 先自動重啟、放棄才告警

暫時性失敗自己重試就好。讓 systemd 先重啟、撐過上限才 failed 才告警：

```ini
[Service]
Restart=on-failure
RestartSec=5
[Unit]
StartLimitBurst=3
StartLimitIntervalSec=60
```

## 整台機器死掉的盲點

`OnFailure` 靠 systemd 觸發，機器當掉就發不出告警。那一層要體外心跳（dead-man switch）：機器定時 `curl` healthchecks.io / Uptime Kuma，訊號停由體外告警。體內方案報不了自己這台的死。

完整判讀與四層框架見 blog：`/linux/debug/service-failure-monitoring/`。
