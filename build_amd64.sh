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
    local platform=$4
    local log_file="logs/build_${tag}_amd64.log"
    rm -f "$log_file"
    echo "Собираем образ для PHP $php_version с Xdebug=$xdebug на платформе amd64..."
    DOCKER_BUILDKIT=1 docker buildx build \
        --platform "$platform" \
        --build-arg PHP_VERSION=$php_version \
        --build-arg WITH_XDEBUG=$xdebug \
        -t traineratwot/php:$tag-amd64 \
        --push=false . &> "$log_file"
}

# Сборка образов
build_image 8.2 false 8.2 linux/amd64
build_image 8.2 true 8.2-xdebug linux/amd64
build_image 8.4.3 false 8.4 linux/amd64
build_image 8.4.3 true 8.4-xdebug linux/amd64

# Проверка успешности сборки и архивация образов
archive_images() {
    local tag=$1
    local amd64_tag="${tag}-amd64"
    echo "Проверяем наличие образа для тега $amd64_tag..."
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^traineratwot/php:$amd64_tag$"; then
        echo "Архивируем образ для тега $tag-amd64..."
        docker save -o images/${tag}_amd64.tar traineratwot/php:$amd64_tag
    else
        echo "Образ для тега $amd64_tag не найден. Архивация прервана."
        exit 1
    fi
}

# Архивация собранных образов
archive_images 8.2
archive_images 8.2-xdebug
archive_images 8.4
archive_images 8.4-xdebug

echo "Образы для amd64 собраны и архивированы."