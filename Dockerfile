# Аргументы для версии PHP и временной зоны
ARG PHP_VERSION=8.2
ARG TZ=Europe/Moscow
ARG WITH_XDEBUG=false

# Основная стадия: Установка зависимостей
FROM php:${PHP_VERSION}-fpm-alpine AS base

# Установка системных зависимостей
RUN apk update && apk upgrade
RUN apk add --no-cache
RUN apk add --no-cache build-base
RUN apk add --no-cache bash
RUN apk add --no-cache nano
RUN apk add --no-cache curl
RUN apk add --no-cache autoconf
RUN apk add --no-cache icu-dev
RUN apk add --no-cache redis
RUN apk add --no-cache libsodium-dev
RUN apk add --no-cache supervisor
RUN apk add --no-cache libtool
RUN apk add --no-cache libwebp-dev
RUN apk add --no-cache libjpeg-turbo-dev
RUN apk add --no-cache freetype-dev
RUN apk add --no-cache libzip-dev
RUN apk add --no-cache libpng-dev
RUN apk add --no-cache imagemagick-dev
RUN apk add --no-cache linux-headers
RUN apk add --no-cache ncdu
RUN apk add --no-cache btop
RUN apk cache clean 

FROM base AS php
# Установка и включение расширений PHP
RUN docker-php-ext-install exif
RUN docker-php-ext-install zip
RUN docker-php-ext-install bz2
RUN docker-php-ext-install sodium
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install intl
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install bcmath
RUN pecl install redis && docker-php-ext-enable redis

# Установка и включение расширения imagick, echo в RUN очень важно - не трогай!!
ARG PHP_VERSION
RUN echo "PHP_VERSION=$PHP_VERSION" && \
    if [ "$PHP_VERSION" = "8.2" ]; then \
        pecl install imagick && docker-php-ext-enable imagick; \
    fi

# Установка Xdebug, если WITH_XDEBUG=true, echo в RUN очень важно - не трогай!!
ARG WITH_XDEBUG
RUN echo "WITH_XDEBUG=$WITH_XDEBUG" && \
    if [ "$WITH_XDEBUG" = "true" ]; then \
        pecl install xdebug && docker-php-ext-enable xdebug; \
    fi

# Стадия 2: Установка Composer
FROM php AS composer

# Копирование Composer из официального образа
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Стадия 3: Установка Infisical
#FROM composer AS infisical
#
## Установка Infisical CLI
#RUN curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
#    && apk add infisical

# Стадия очистки
FROM composer AS clear

# Удаление временных файлов PECL
RUN rm -rf /tmp/pear

# Удаление временных файлов Composer
RUN composer clear-cache

# Очистка кеша APK
RUN apk cache clean && \
    rm -rf /var/cache/apk/*

# Стадия финальной настройки
FROM clear AS final

# Копирование конфигурационных файлов
COPY ./data/supervisord.conf /etc/supervisord.conf
COPY ./data/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./data/php.nanorc /etc/nanorc

# Настройка Bash и рабочей директории
RUN echo 'alias nano="nano -l"' >> /etc/bash/bashrc
WORKDIR /var/www/html
# Смена пользователя
USER www-data