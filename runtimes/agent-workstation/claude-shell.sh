#!/usr/bin/env bash
# 互動式 Claude Code：注入 token、掛工作目錄、起互動對話 session。
#
# 用法：claude-shell.sh            進互動對話
#      claude-shell.sh -p "任務"  一次性（等同 run-agent.sh）
#
# 認證綁「每次 run 注入 token」、不綁 session 或登入態：直接打 claude（未注入）
# 即使在活著的 zellij session 裡也會要求重認證。一律用本 helper 就永遠免重認證。
#
# 打中文對話請用純 SSH 連線（非 mosh）——mosh 的本地回顯預測會讓 CJK 雙寬字顯示錯位。
#
# 工作目錄預設為本目錄下的 work/、可用 AGENT_WORK 覆蓋。
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${AGENT_WORK:-$DIR/work}"
mkdir -p "$WORK"

docker run --rm -it \
  --env-file "$DIR/.env" \
  -v claude-home:/home/node/.claude \
  -v "$WORK:/work" \
  --memory=2g \
  agent-workstation:v1 \
  claude --dangerously-skip-permissions "$@"
