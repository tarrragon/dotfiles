#!/usr/bin/env bash
# fire-and-forget：注入 token、掛工作目錄、跑一次性 agent 任務。
# 跑完由 container 內的 Stop hook（若已設）推 ntfy 通知。
#
# 用法一：run-agent.sh "任務描述"
# 用法二（手機友善、免引號）：直接跑 run-agent.sh、看到提示後整行輸入任務
#   —— 手機軟體鍵盤常把直引號換成智慧引號、shell 不認、參數會壞；互動輸入避開這個坑。
#
# 工作目錄預設為本目錄下的 work/、可用 AGENT_WORK 覆蓋。
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${AGENT_WORK:-$DIR/work}"
mkdir -p "$WORK"

if [ $# -ge 1 ]; then
  PROMPT="$*"
else
  printf '輸入 agent 任務（整行、免引號）: '
  IFS= read -r PROMPT
fi
[ -n "$PROMPT" ] || { echo "任務不可為空"; exit 1; }

echo "=== 派給 agent: $PROMPT ==="
docker run --rm \
  --env-file "$DIR/.env" \
  -v claude-home:/home/node/.claude \
  -v "$WORK:/work" \
  --memory=2g \
  agent-workstation:v1 \
  claude -p "$PROMPT" --dangerously-skip-permissions
