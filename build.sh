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
    local log_file="logs/build_${tag}_${platform}.log"
    rm -f "$log_file"
    echo "Собираем образ для PHP $php_version с Xdebug=$xdebug на платформе $platform..."
    DOCKER_BUILDKIT=1 docker buildx build \
        --platform "$platform" \
        --build-arg PHP_VERSION=$php_version \
        --build-arg WITH_XDEBUG=$xdebug \
        -t traineratwot/php:$tag-$platform \
        --push=false . &> "$log_file"
}

# Сборка образов для разных платформ
build_image 8.2 false 8.2 linux/amd64
build_image 8.2 true 8.2-xdebug linux/amd64
build_image 8.4.3 false 8.4 linux/amd64
build_image 8.4.3 true 8.4-xdebug linux/amd64

# Предположим, что вы используете QEMU для сборки на ARM на x86 машине
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

build_image 8.2 false 8.2 linux/arm64
build_image 8.2 true 8.2-xdebug linux/arm64
build_image 8.4.3 false 8.4 linux/arm64
build_image 8.4.3 true 8.4-xdebug linux/arm64

# Функция для объединения образов
combine_images() {
    local tag=$1
    echo "Объединяем образы для тега $tag..."
    docker buildx imagetools create \
        -t traineratwot/php:$tag \
        traineratwot/php:$tag-linux-amd64 \
        traineratwot/php:$tag-linux-arm64 \
        --output type=oci,dest=images/$tag.tar
    docker buildx imagetools push traineratwot/php:$tag
}

# Объединение образов
combine_images 8.2
combine_images 8.2-xdebug
combine_images 8.4
combine_images 8.4-xdebug

echo "Все образы собраны и отправлены в реестр."