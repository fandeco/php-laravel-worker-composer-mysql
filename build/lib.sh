#!/bin/bash
# Получаем абсолютный путь к текущему скрипту
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
DOCKER_DIR="$(dirname "${SCRIPT_DIR}")"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

echo "$SCRIPT_PATH"
echo "$SCRIPT_DIR"
echo "$SCRIPT_NAME"
# Убедимся, что buildx установлен и инициализирован
check_buildx() {
    if ! docker buildx ls &> /dev/null; then
        echo "Docker Buildx не установлен. Пожалуйста, установите его."
        exit 1
    fi
}

# Создаем билдер, если его еще нет
create_builder() {
    if ! docker buildx inspect php_builder &> /dev/null; then
        echo "Создаем билдер php_builder..."
        docker buildx create --use --name php_builder
    fi
}

# Функция для сборки образа
build_image() {
    local start_time
    local end_time
    local duration
    local php_version
    local xdebug
    local tag
    local platform
    local platform_safe
    local log_file

    start_time=$(date +%s)
    php_version=$1
    xdebug=$2
    tag=$3
    platform=$4
    platform_safe=$(echo "$platform" | tr '/' '_')
    log_file="${SCRIPT_DIR}/logs/build_${tag}_${platform_safe}.log"
    rm -f "$log_file"
    echo "Собираем образ для PHP $php_version с Xdebug=$xdebug на платформе $platform..."
    DOCKER_BUILDKIT=1 docker buildx build \
        --platform "$platform" \
        --build-arg PHP_VERSION=$php_version \
        --build-arg WITH_XDEBUG=$xdebug \
        -t traineratwot/php:$tag-$platform_safe \
        --load "${DOCKER_DIR}" &> "$log_file"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo "Сборка образа для PHP $php_version с Xdebug=$xdebug на платформе $platform завершена за $duration s"
}

# Проверка успешности сборки и архивация образов
archive_images() {
    local start_time
    local end_time
    local duration
    local tag
    local platform
    local platform_safe
    local platform_tag

    start_time=$(date +%s)
    tag=$1
    platform=$2
    platform_safe=$(echo "$platform" | tr '/' '_')
    platform_tag="${tag}-${platform_safe}"
    echo "Проверяем наличие образа для тега $platform_tag..."
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^traineratwot/php:$platform_tag$"; then
        echo "Архивируем образ для тега $platform_tag..."
        docker save -o images/${tag}_${platform_safe}.tar traineratwot/php:$platform_tag
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "Архивация образа для тега $platform_tag завершена за $duration s"
    else
        echo "Образ для тега $platform_tag не найден. Архивация прервана."
        exit 1
    fi
}