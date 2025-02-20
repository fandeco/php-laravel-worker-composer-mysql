#!/bin/bash
# Получаем абсолютный путь к текущему скрипту
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "${SCRIPT_DIR}")"

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
    local build_success
    local out_file

    start_time=$(date +%s)
    php_version=$1
    xdebug=$2
    tag=$3
    platform=$4
    platform_safe=$(echo "$platform" | tr '/' '_')
    log_file="${SCRIPT_DIR}/logs/build_${tag}_${platform_safe}.log"
    out_file="${SCRIPT_DIR}/images/${tag}_${platform_safe}.tar"
    rm -f "$log_file"
    rm -f "$out_file"
    echo "Собираем образ для PHP $php_version с Xdebug=$xdebug на платформе $platform..."
    DOCKER_BUILDKIT=1 docker buildx build \
        --platform "$platform" \
        --build-arg PHP_VERSION=$php_version \
        --build-arg WITH_XDEBUG=$xdebug \
        -t traineratwot/php:$tag-$platform_safe \
        --output type=docker,dest=${out_file} "${DOCKER_DIR}" &> "$log_file"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo "Сборка образа для PHP $php_version с Xdebug=$xdebug на платформе $platform завершена за $duration s"

    # Проверяем успешность сборки
    if grep -q "failed" "$log_file"; then
        echo "Сборка образа завершилась с ошибкой. Проверьте лог файл: $log_file"
        build_success=1
    else
        build_success=0
        echo "Загружаем образ из файла ${out_file}..."
        docker load -i "${out_file}"  &>> "$log_file"
        if [ $? -ne 0 ]; then
            echo "Ошибка при загрузке образа из файла ${out_file}. Проверьте файл."
            build_success=1
        else
            echo "Образ успешно загружен."
            # Проверяем наличие образа в списке
            if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^traineratwot/php:$tag-$platform_safe$"; then
                echo "Образ traineratwot/php:$tag-$platform_safe найден в списке."
                echo "Публикуем образ traineratwot/php:$tag-$platform_safe..."
                docker push traineratwot/php:"$tag"-"$platform_safe" &>> "$log_file"
                if [ $? -ne 0 ]; then
                    echo "Ошибка при публикации образа traineratwot/php:$tag-$platform_safe. Проверьте лог файл: $log_file"
                    build_success=1
                else
                    echo "Образ traineratwot/php:$tag-$platform_safe успешно опубликован."
                fi
            else
                echo "Образ traineratwot/php:$tag-$platform_safe не найден в списке после загрузки."
                build_success=1
            fi
        fi
    fi

    return $build_success
}