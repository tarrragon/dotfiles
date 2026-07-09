#!/usr/bin/env bash
# validate.sh — 在乾淨容器裡從頭跑一遍本 repo 的 setup，assert install + verify 綠。
#
# 這是「陌生人在乾淨機器上還能不能把這個 repo 帶起來」的回歸閘門，也是 golden-path-validation
# 方法「可執行核心」在本 repo 的實現：對每個目標起一個 bare 容器、把本 repo（committed HEAD，
# 經 git archive、不含 .git / 機密）放進去、跑 install.sh + verify.sh、綠燈才算過。
#
# 邊界：這隻只驗「照做跑不跑得起來」（執行層）。「陌生人看不看得懂」（理解層）要靠 LLM 冷讀
# 代理人，不是這隻腳本 —— 見 golden-path-validation skill。
#
# 用法：validate.sh [all|debian|arch] [base|terminal]   （預設 all terminal；desktop 是圖形桌面、不在容器驗）
set -uo pipefail   # 刻意不 -e：跑完所有目標再報，不中途停

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_ARCH="$(uname -m)"
TARGET="${1:-all}"
STAGE="${2:-terminal}"
case "$STAGE" in base|terminal) ;; *) echo "stage 只能 base|terminal（desktop 是圖形桌面、容器驗不了）"; exit 2 ;; esac
case "$TARGET" in all) TARGETS=(debian arch) ;; debian|arch) TARGETS=("$TARGET") ;; *) echo "用法: validate.sh [all|debian|arch] [base|terminal]"; exit 2 ;; esac

image_for() {
  case "$1" in
    debian) echo debian:bookworm ;;
    arch) { [ "$HOST_ARCH" = aarch64 ] || [ "$HOST_ARCH" = arm64 ]; } && echo menci/archlinuxarm:latest || echo archlinux:latest ;;
  esac
}

# timeout 是 GNU coreutils、macOS 預設沒有（有的話叫 gtimeout）；偵測、都沒有就略過（不硬依賴）
TIMEOUT_BIN=""
command -v timeout  >/dev/null 2>&1 && TIMEOUT_BIN=timeout
[ -z "$TIMEOUT_BIN" ] && command -v gtimeout >/dev/null 2>&1 && TIMEOUT_BIN=gtimeout

exec_in() {  # exec_in <container> <script>：docker exec bash -c，有 timeout 就套上限、沒有就直接跑
  if [ -n "$TIMEOUT_BIN" ]; then "$TIMEOUT_BIN" 1200 docker exec "$1" bash -c "$2"
  else docker exec "$1" bash -c "$2"; fi
}

run_one() {
  local distro="$1"
  local img name inner logf
  img="$(image_for "$distro")"
  name="validate-${distro}-$$"
  logf="/tmp/validate-${distro}-$$.log"
  docker rm -f "$name" >/dev/null 2>&1
  echo "== [$distro] $img =="
  if ! docker run -d --name "$name" "$img" sleep infinity >/dev/null 2>&1; then
    echo "   FAIL: 容器起不來（image 拉不到？）"; return 1
  fi
  # 把 committed HEAD 放進去：git archive 只含 tracked 檔、天然排除 .git 與 gitignored 的 .env（機密）
  docker exec "$name" mkdir -p /root/dotfiles
  git -C "$DOTFILES_DIR" archive --format=tar HEAD | docker exec -i "$name" tar -x -C /root/dotfiles

  # 照 runbook 的執行層：前置（distro 專屬）→ install → verify
  if [ "$distro" = arch ]; then
    inner='sed -i "/^\[options\]/a DisableSandbox" /etc/pacman.conf; pacman -Syu --noconfirm git'
  else
    inner='export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq git'
  fi
  inner="$inner; cd /root/dotfiles && ./scripts/install.sh $STAGE && ./scripts/verify.sh $STAGE"

  if exec_in "$name" "$inner" >"$logf" 2>&1; then
    echo "   PASS: install + verify 從乾淨環境綠燈"
    docker rm -f "$name" >/dev/null 2>&1
    return 0
  else
    echo "   FAIL: 見下方 tail（完整 log: ${logf}）"
    tail -12 "$logf" | sed 's/^/     /'
    docker rm -f "$name" >/dev/null 2>&1
    return 1
  fi
}

fail=0
for t in "${TARGETS[@]}"; do run_one "$t" || fail=$((fail+1)); done

echo
if [ "$fail" -eq 0 ]; then
  echo "OK — 所有目標（${TARGETS[*]}）stage=$STAGE 從乾淨環境跑到 verify 綠。"
  exit 0
else
  echo "FAILED — $fail / ${#TARGETS[@]} 個目標沒過。"
  exit 1
fi
