ARG PHP_VERSION=8.2
ARG TZ=Europe/Moscow

# Второй этап: установка зависимостей с использованием Composer
FROM php:8.2-fpm-alpine

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./supervisor/supervisord.conf /etc/supervisord.conf

RUN apk update && apk upgrade
RUN apk add build-base
RUN apk add autoconf
RUN apk add libzip-dev
RUN apk add libpng
RUN apk add libpng-dev
RUN apk add freetype
RUN apk add freetype-dev
RUN apk add libjpeg-turbo
RUN apk add libjpeg-turbo-dev
RUN apk add libwebp-dev
RUN apk add libsodium-dev
RUN apk add icu-dev
RUN apk add bash
RUN apk add redis
RUN apk add supervisor
RUN apk add imagemagick
RUN apk add imagemagick-dev
RUN apk add libtool
RUN apk add nano
RUN apk add curl

# Установка подсветки синтаксиса для PHP
RUN curl -o /etc/nanorc/php.nanorc https://raw.githubusercontent.com/scopatz/nanorc/master/php.nanorc || echo "PHP nanorc already exists"

RUN echo "include /etc/nanorc/php.nanorc" >> /etc/nanorc

RUN docker-php-ext-install exif
RUN docker-php-ext-install zip
RUN docker-php-ext-install bz2
RUN docker-php-ext-install sodium
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install intl
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install bcmath

RUN apk add --no-cache bash curl && curl -1sLf \
'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
&& apk add infisical

COPY ./php.ini /usr/local/etc/php/conf.d/php.ini

# Установка и включение расширения GD
RUN docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd
# Установите и включите расширение imagick
RUN pecl install imagick && docker-php-ext-enable imagick
# Установите и включите расширение redis
RUN pecl install redis && docker-php-ext-enable redis

WORKDIR /var/www/html

COPY --chown=www-data:www-data . /var/www/html

USER www-data