# base image 固定 tag：Claude Code 是 npm 套件、用官方 node image 省一層 runtime 版本漂移
# 嚴格版可再往下釘到 digest（docker inspect node:22-bookworm-slim 取 RepoDigest）
FROM node:22-bookworm-slim

# 開發工具鏈：git 給版本控制、ripgrep 給搜尋、ca-certificates 給 HTTPS
# curl 是 ntfy hook 依賴、node:slim 不內建、少了 hook 會靜默失效
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates curl ripgrep less \
    && rm -rf /var/lib/apt/lists/*

# agent 程式裝進 image：Claude Code 全域安裝
RUN npm install -g @anthropic-ai/claude-code

# 預建 ~/.claude 並 chown 給 node：named volume 首次掛載會沿用 image 內該目錄的 owner
# 少了這行、空 volume 會以 root 掛上、container 內的 node 寫不進憑證
RUN mkdir -p /home/node/.claude && chown -R node:node /home/node/.claude

# 非 root 使用者：直接用 node base 內建的 node(UID 1000)、對齊多數 host 使用者(1000)
# 掛載進來的專案檔在 host / container 兩側 owner 一致、避免權限錯亂
USER node
ENV HOME=/home/node
WORKDIR /work
CMD ["bash"]
