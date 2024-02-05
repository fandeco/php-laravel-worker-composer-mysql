ARG PHP_VERSION=8.2
ARG TZ=Europe/Moscow

# Второй этап: установка зависимостей с использованием Composer
FROM php:8.2-fpm-alpine

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./docker/app/supervisor/supervisord.conf /etc/supervisord.conf

RUN apk update && apk upgrade
RUN apk add build-base autoconf libzip-dev libpng-dev libjpeg-turbo-dev libwebp-dev libsodium-dev icu-dev bash redis supervisor

#RUN pecl install xdebug-3.2.2

RUN docker-php-ext-configure gd --with-jpeg --with-webp && docker-php-ext-install gd
RUN docker-php-ext-install exif
RUN docker-php-ext-install zip
RUN docker-php-ext-install bz2
RUN docker-php-ext-install sodium
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install sodium
RUN docker-php-ext-install intl
RUN docker-php-ext-install pcntl

RUN apk add --no-cache bash curl && curl -1sLf \
'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
&& apk add infisical

COPY ./docker/app/php.ini-production /usr/local/etc/php/conf.d/php.ini

# Установка и включение расширения GD
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd

WORKDIR /var/www/html

COPY --chown=www-data:www-data . /var/www/html

USER www-data
