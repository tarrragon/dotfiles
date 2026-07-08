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

# gh CLI：agent 要 clone/push 私有 repo 與開 PR。走官方 apt repo（Debian 預設源沒有 gh）
# gh 原生讀環境變數 GH_TOKEN/GITHUB_TOKEN、不需 `gh auth login` 的存檔登入——對齊本 stack 的無狀態注入模型
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# 預建 ~/.claude 並 chown 給 node：named volume 首次掛載會沿用 image 內該目錄的 owner
# 少了這行、空 volume 會以 root 掛上、container 內的 node 寫不進憑證
RUN mkdir -p /home/node/.claude && chown -R node:node /home/node/.claude

# 非 root 使用者：直接用 node base 內建的 node(UID 1000)、對齊多數 host 使用者(1000)
# 掛載進來的專案檔在 host / container 兩側 owner 一致、避免權限錯亂
USER node
ENV HOME=/home/node

# git over HTTPS 的 GitHub 憑證走 gh 的 credential helper：helper 只引用 gh、真值來自 runtime 的 GH_TOKEN
# 這行在 build 期設定但不含任何機密——token 到 `docker run --env-file` 才進來、不落 image 層也不進 .gitconfig
RUN git config --global credential."https://github.com".helper '!gh auth git-credential' \
    && git config --global credential."https://gist.github.com".helper '!gh auth git-credential'

WORKDIR /work
CMD ["bash"]
