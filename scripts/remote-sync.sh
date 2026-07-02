#!/usr/bin/env bash
# remote-sync.sh — 用 git 把 dotfiles 的狀態同步到遠端機器並套用。
#
# 這是「管理遠端機器」的標準入口：不 ad-hoc SSH 手放檔案，而是
#   本地 commit/push  →  遠端 git pull  →  遠端跑冪等 deploy。
# 遠端機器的狀態永遠可從 repo 重現；SSH 只用來觸發，不用來手動改狀態。
#
# 用法：
#   scripts/remote-sync.sh <ssh-host> [deploy-cmd]
#     <ssh-host>   ~/.ssh/config 裡的 host（如 arch-vm）
#     [deploy-cmd] 遠端 pull 後執行的部署指令，預設 ./scripts/install.sh
#                  （只部署監控：scripts/remote-sync.sh arch-vm 'sudo ./monitoring/deploy.sh'）
# 環境變數：
#   REMOTE_DOTFILES_DIR  遠端 dotfiles clone 路徑，預設 ~/dotfiles
set -Eeuo pipefail

HOST="${1:?usage: remote-sync.sh <ssh-host> [deploy-cmd]}"
DEPLOY_CMD="${2:-./scripts/install.sh}"
REMOTE_DIR="${REMOTE_DOTFILES_DIR:-\$HOME/dotfiles}"

# 1) 本地必須乾淨且已推送——遠端只能拉到已 push 的東西。
#    有未提交變更就擋下：逼你把改動走 commit，而不是繞過 repo 手放到遠端。
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: 本地有未提交變更。先 commit（不要透過 SSH 手動補到遠端）。" >&2
  git status --short >&2
  exit 1
fi
echo "[remote-sync] push 本地 → origin ..."
git push

# 2) 遠端 pull + 冪等 deploy——唯一改變遠端狀態的路徑。
#    ff-only：遠端若有分歧的本地改動會擋下（不靜默覆蓋），逼你先處理遠端的髒狀態。
echo "[remote-sync] $HOST: git pull --ff-only + deploy ..."
ssh "$HOST" "cd $REMOTE_DIR && git fetch --quiet && git pull --ff-only && $DEPLOY_CMD"
echo "[remote-sync] done"
