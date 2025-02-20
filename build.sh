#!/bin/bash

# Убедимся, что buildx установлен и инициализирован
if ! docker buildx ls &> /dev/null; then
    echo "Docker Buildx не установлен. Пожалуйста, установите его."
    exit 1
fi

# Создаем билдер, если его еще нет
if ! docker buildx inspect php_builder &> /dev/null; then
    echo "Создаем билдер php_builder..."
    docker buildx create --use --name php_builder
fi

# Функция для сборки образа
build_image() {
    local php_version=$1
    local xdebug=$2
    local tag=$3
    local log_file="logs/build_${tag}.log"

    echo "Собираем образ для PHP $php_version с Xdebug=$xdebug..."
    DOCKER_BUILDKIT=1 docker buildx build \
        --platform linux/amd64 \
        --build-arg PHP_VERSION=$php_version \
        --build-arg WITH_XDEBUG=$xdebug \
        -t traineratwot/php:$tag \
        --push . &> "$log_file"
}

# Сборка образов
build_image 8.2 false 8.2
build_image 8.2 true 8.2-xdebug
build_image 8.4.3 false 8.4
build_image 8.4.3 true 8.4-xdebug

echo "Все образы собраны и отправлены в реестр."