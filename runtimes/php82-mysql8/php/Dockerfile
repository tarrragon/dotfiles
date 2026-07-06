# 升級版：PHP 8.2 + bookworm。跟 php72-mysql57 的差異：
# bookworm 仍在支援期，不需要 archive.debian.org 那段（那是 buster EOL 的稅）。
FROM php:8.2-fpm-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev libpng-dev \
    && docker-php-ext-install pdo_mysql mysqli gd zip \
    && rm -rf /var/lib/apt/lists/*

COPY php.ini /usr/local/etc/php/conf.d/zz-parity.ini
