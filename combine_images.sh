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

# Функция для загрузки образов из архивов
load_images() {
    local tag=$1
    echo "Загружаем образы для тега $tag..."
    docker load -i images/${tag}_amd64.tar
    docker load -i images/${tag}_arm64.tar
}

# Функция для объединения образов
combine_images() {
    local tag=$1
    echo "Объединяем образы для тега $tag..."
    docker buildx imagetools create \
        -t traineratwot/php:$tag \
        traineratwot/php:$tag-amd64 \
        traineratwot/php:$tag-arm64 \
        --output type=oci,dest=images/$tag.tar
    docker buildx imagetools push traineratwot/php:$tag
}

# Загрузка образов из архивов
load_images 8.2
load_images 8.2-xdebug
load_images 8.4
load_images 8.4-xdebug

# Объединение образов
combine_images 8.2
combine_images 8.2-xdebug
combine_images 8.4
combine_images 8.4-xdebug

echo "Все образы собраны, загружены и отправлены в реестр."