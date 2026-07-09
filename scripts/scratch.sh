#!/usr/bin/env bash
# scratch.sh — 一鍵起一個可拋棄的乾淨容器。
#
# 兩種用途：
#   bare（預設）  純淨 base image、什麼都沒裝。給「陌生人照做」的 cold-read 驗證當 fixture、
#                 或只是要一個乾淨 scratch 環境。
#   --provision  clone 本 dotfiles + 跑 install.sh terminal，得到一個裝好工具鏈的「可用」scratch。
#
# 用法：
#   ./scripts/scratch.sh <debian|arch>            # bare 可拋棄容器，進 shell，退出即刪
#   ./scripts/scratch.sh arch --provision         # 裝好 dotfiles 的可用 scratch，退出即刪
#   ./scripts/scratch.sh arch --provision --keep  # 同上但保留容器，可重複 docker exec 進去
#
# 為什麼是這支而不是隨手 docker run：
#   - arch 在 arm64 主機自動用原生 Arch Linux ARM image（menci/archlinuxarm），避免 qemu 模擬給假結果。
#   - --provision 時處理 pacman 7 在容器內的 Landlock sandbox（加 DisableSandbox）與 -Syu 前置。
#   - 統一清理，不留一堆 scratch-* 容器。
set -euo pipefail

DISTRO="${1:-}"; shift || true
PROVISION=0; KEEP=0
for a in "$@"; do
  case "$a" in
    --provision) PROVISION=1 ;;
    --keep) KEEP=1 ;;
    *) echo "unknown flag: $a"; exit 2 ;;
  esac
done

REPO="https://github.com/tarrragon/dotfiles"
HOST_ARCH="$(uname -m)"

case "$DISTRO" in
  debian) IMG="debian:bookworm" ;;
  arch)
    if [ "$HOST_ARCH" = "aarch64" ] || [ "$HOST_ARCH" = "arm64" ]; then
      IMG="menci/archlinuxarm:latest"   # 原生 arm64，避免 archlinux:latest（amd64-only）走 qemu 模擬
    else
      IMG="archlinux:latest"
    fi ;;
  *) echo "用法: scratch.sh <debian|arch> [--provision] [--keep]"; exit 2 ;;
esac

# 生命週期：預設 --rm（退出即刪）；--keep 給名字、留著可重進
if [ "$KEEP" = 1 ]; then
  NAME="scratch-${DISTRO}-$$"
  RUN=(docker run -it --name "$NAME")
else
  RUN=(docker run --rm -it)
fi

# provision：在容器內裝 git（arch 先關 sandbox + -Syu）、clone、install.sh terminal、verify
provision_steps() {
  if [ "$DISTRO" = arch ]; then
    printf 'sed -i "/^\\[options\\]/a DisableSandbox" /etc/pacman.conf\n'   # pacman 7 容器 Landlock 逃生閥
    printf 'pacman -Syu --noconfirm git\n'                                   # -Syu 非 -Sy，避免 partial upgrade
  else
    printf 'export DEBIAN_FRONTEND=noninteractive\n'
    printf 'apt-get update -qq && apt-get install -y -qq git\n'
  fi
  printf 'git clone --depth=1 %s /root/dotfiles\n' "$REPO"
  printf 'cd /root/dotfiles && ./scripts/install.sh terminal\n'
  printf 'echo; echo "== provisioned; verify: =="; ./scripts/verify.sh terminal || true\n'
}

if [ "$PROVISION" = 1 ]; then
  INNER="$(provision_steps)
exec bash -l"
else
  INNER="exec bash -l"
fi

label="$DISTRO ($IMG)"
[ "$PROVISION" = 1 ] && label="$label, provisioned"
[ "$KEEP" = 1 ] && label="$label, kept as $NAME"
echo "== scratch: $label =="

"${RUN[@]}" "$IMG" bash -c "$INNER"

if [ "$KEEP" = 1 ]; then
  echo "容器保留為 $NAME。重進：docker start -ai $NAME　｜　清掉：docker rm -f $NAME"
fi
