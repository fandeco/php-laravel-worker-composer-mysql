# Аргументы для версии PHP и временной зоны
ARG PHP_VERSION=8.2
ARG TZ=Europe/Moscow
ARG WITH_XDEBUG=false

# Основная стадия: Установка зависимостей
FROM php:${PHP_VERSION}-fpm-alpine AS base

# Установка системных зависимостей и очистка кэша
RUN apk update && apk upgrade && \
    apk add --no-cache \
    build-base \
    bash \
    nano \
    curl \
    autoconf \
    icu-dev \
    redis \
    libsodium-dev \
    supervisor \
    libtool \
    libwebp-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    libpng-dev \
    imagemagick-dev \
    && rm -rf /var/cache/apk/*

FROM base AS php
# Установка и включение расширений PHP
RUN docker-php-ext-install -j$(nproc) \
    exif \
    zip \
    bz2 \
    sodium \
    pdo_mysql \
    intl \
    pcntl \
    bcmath \
    && docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && pecl install imagick && docker-php-ext-enable imagick \
    && pecl install redis && docker-php-ext-enable redis \
    && if [ "$WITH_XDEBUG" = "true" ]; then \
        pecl install xdebug && docker-php-ext-enable xdebug; \
    fi

# Стадия 2: Установка Composer
FROM php AS composer

# Копирование Composer из официального образа
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Стадия 3: Установка Infisical (закомментировано)
# FROM composer AS infisical
# Установка Infisical CLI
# RUN curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
#     && apk add infisical

# Стадия 4: Финальная настройка
FROM composer AS final

# Копирование конфигурационных файлов
COPY ./supervisor/supervisord.conf /etc/supervisord.conf
COPY ./php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./php.nanorc /etc/nanorc

# Настройка Bash и рабочей директории
RUN echo 'alias nano="nano -l"' >> /etc/bash/bashrc
WORKDIR /var/www/html

# Копирование приложения
COPY --chown=www-data:www-data . /var/www/html

# Смена пользователя
USER www-data