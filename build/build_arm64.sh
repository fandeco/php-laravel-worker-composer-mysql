#!/bin/bash

# Подключаем библиотеку с общими функциями
source "$(dirname "$0")/lib.sh"

# Проверяем buildx и создаем билдер
check_buildx
create_builder

# Сборка образов
build_image 8.2 false 8.2 linux/arm64
build_image 8.2 true 8.2-xdebug linux/arm64
build_image 8.4.3 false 8.4 linux/arm64
build_image 8.4.3 true 8.4-xdebug linux/arm64

# Архивация собранных образов
archive_images 8.2 arm64
archive_images 8.2-xdebug arm64
archive_images 8.4 arm64
archive_images 8.4-xdebug arm64

echo "Образы для arm64 собраны и архивированы."