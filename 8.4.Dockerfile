ARG PHP_VERSION=8.4
ARG TZ=Europe/Moscow

# Второй этап: установка зависимостей с использованием Composer
FROM php:8.4-fpm-alpine

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./supervisor/supervisord.conf /etc/supervisord.conf

RUN apk update && apk upgrade
RUN apk add --no-cache \
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
    imagemagick-dev

RUN docker-php-ext-install exif \
    && docker-php-ext-install zip \
    && docker-php-ext-install bz2 \
    && docker-php-ext-install sodium \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install intl \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install bcmath

RUN curl -1sLf \
'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
&& apk add infisical

# Установка и включение расширения GD
RUN docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd
# Установите и включите расширение imagick
# RUN pecl install imagick && docker-php-ext-enable imagick
# Установите и включите расширение redis
RUN pecl install redis && docker-php-ext-enable redis

COPY ./php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./php.nanorc /etc/nanorc
RUN echo 'alias nano="nano -l"' >> /etc/bash/bashrc
WORKDIR /var/www/html

USER www-data