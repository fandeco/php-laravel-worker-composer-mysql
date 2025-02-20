#!/bin/bash

# Подключаем библиотеку с общими функциями
source "$(dirname "$0")/lib.sh"

# Проверяем buildx и создаем билдер
check_buildx
create_builder

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
    local amd64_tag="${tag}-amd64"
    local arm64_tag="${tag}-arm64"
    echo "Проверяем наличие образов для тегов $amd64_tag и $arm64_tag..."
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^traineratwot/php:$amd64_tag$" && \
       docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^traineratwot/php:$arm64_tag$"; then
        echo "Объединяем образы для тега $tag..."
        docker buildx imagetools create \
            -t traineratwot/php:$tag \
            traineratwot/php:$amd64_tag \
            traineratwot/php:$arm64_tag \
            --output type=oci,dest=images/$tag.tar
        docker buildx imagetools push traineratwot/php:$tag
    else
        echo "Образы для тегов $amd64_tag и/или $arm64_tag не найдены. Объединение прервано."
        exit 1
    fi
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