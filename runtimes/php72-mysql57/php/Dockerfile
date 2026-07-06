# 釘到 Debian buster + PHP 7.2；不用浮動 tag（php:7.2-fpm 會隨官方 rebuild 漂），
# 不用 alpine（musl libc 會在擴充/DNS/glibc-specific 行為上引入跟 prod 的差異）。
FROM php:7.2-fpm-buster

# Debian buster 已 EOL，套件庫從主 mirror 移到 archive.debian.org；不改 source，
# apt-get update 直接 404。這是「凍結舊環境」的固有稅：base image 的預設 mirror
# 隨發行版退役而失效。archive 的 Release 檔已過期，要關 Check-Valid-Until。
RUN printf '%s\n' \
        'deb http://archive.debian.org/debian buster main' \
        'deb http://archive.debian.org/debian-security buster/updates main' \
        > /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    # 擴充清單要「等於」prod、不是「涵蓋」prod：多裝的擴充讓本機能跑、prod 掛掉。
    # 取得 prod 清單：在 prod 跑 `php -m` 抄回來，一個對一個。
    && apt-get install -y --no-install-recommends libzip-dev libpng-dev \
    && docker-php-ext-install pdo_mysql mysqli gd zip \
    && rm -rf /var/lib/apt/lists/*

# prod 的 php.ini 差異抄進來，而不是吃 image 預設（時區、memory_limit、上傳上限都影響行為）
COPY php.ini /usr/local/etc/php/conf.d/zz-parity.ini
