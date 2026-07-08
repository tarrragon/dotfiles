# runtimes

版本化的 runtime stack 定義（每個 stack 一個目錄，內含 Dockerfile + docker-compose + config）。跟 repo 主體（個人工作站 dotfile）分開放：主體管**你的工作站**，這裡管**跑 app 的 runtime image**——兩件不同的事，不共用同一個 artifact。

## 目錄 = 一個版本化的 stack

```text
runtimes/
├── php72-mysql57/      對齊接案 client 的凍結舊環境（PHP 7.2 / MySQL 5.7）
├── php82-mysql8/       同一個 app 的升級版（PHP 8.2 / MySQL 8.0）
└── agent-workstation/  遠端 coding agent 工作機（Claude Code in container、機密注入）
```

php 兩個目錄是**兩個獨立、都留著**的 stack，不是「新的取代舊的」。這是刻意的——見下面的管理紀律。

多數 stack 是 compose 多服務（`docker compose up`）；`agent-workstation/` 是單 container、用 `docker run` + helper 驅動。它的機密全走 runtime 注入的同一套模式（`--env-file` 帶 gitignored `.env`、不進 image 也不進 git）：Claude Code 的 OAuth token、GitHub 操作的 `GH_TOKEN`（PAT）、ntfy 推播的 `NTFY_TOPIC` 三顆正交機密都在此注入——它自己的 README 有完整說明。

## 管理紀律：image 不可變，升級是建新的

**沒有「升級一個 image」這個動作。** image 是不可變的：你改 Dockerfile（`FROM php:8.2-fpm`、`mysql:8.0`）→ build → 得到一個全新 image、新 tag，舊 image 動不到。所以「升級」的正確形態是：

1. 複製整個 stack 目錄到新版本名（`php72-mysql57/` → `php82-mysql8/`）。
2. 只改 `FROM` 與服務 image tag，其餘 config 依相容性調整。
3. build 成新 tag（`docker build -t app:php8.2-mysql8 ./php`），舊 stack 原封不動。
4. 兩版並跑對照（不同 port：舊版 8080、新版 8081），用 `src/index.php` 的 probe 逐行比對行為差異。
5. 驗過再切換；舊目錄留著（git 裡永遠可重建，不用另存 image 檔）。

**為什麼舊的要留**：因為 Dockerfile 在 git，任何一版隨時 `git checkout` 舊目錄 + rebuild 就一模一樣長回來。留目錄不是留備份，是留「精確可重現的定義」。

## 兩個 stack 的用法

```bash
cd php82-mysql8            # 或 php72-mysql57
docker compose up -d --build
curl http://localhost:8081/    # probe：印出版本 / 時區 / 擴充 / sql_mode / auth plugin
docker compose down -v
```

## 兩版之間實測到的差異（升級會踩的）

| 維度 | php72-mysql57 | php82-mysql8 |
| --- | --- | --- |
| base OS | Debian buster（EOL，Dockerfile 要改指 archive.debian.org 否則 apt 404） | Debian bookworm（支援中，無此稅） |
| MySQL 架構 | 5.7 無 arm64 原生，compose 要 `platform: linux/amd64` 走模擬 | 8.0 有 arm64 原生，不必 platform、跑得更快 |
| MySQL 認證 | `mysql_native_password` | `caching_sha2_password`（只升 MySQL、留舊 PHP 客戶端會 auth 炸；PHP 8.2 mysqlnd 才連得上） |
| 首次初始化 | 較快 | 較慢（`depends_on` 不等 ready 的窗口更長，probe 太早打會 connection refused） |

## 三層關係（承接 dotfile 模組十）

這些 stack 是 dotfile「工作站 / runtime / ergonomics」三層裡的 **Layer 2（runtime）**。Layer 1（工作站）是 repo 主體 + `scripts/install-{arch,macos,debian}.sh`；Layer 3（container 內 ergonomics）是各 stack 目錄下的 `ergonomics/setup.sh`。Layer 2 完全不碰主機的 package manager——它的載體是 image tag 跟 config。
