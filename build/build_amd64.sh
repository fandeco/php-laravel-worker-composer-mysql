#!/bin/bash

# Подключаем библиотеку с общими функциями
source "$(dirname "$0")/lib.sh"

# Проверяем buildx и создаем билдер
check_buildx
create_builder

# Сборка образов
build_image 8.2 false 8.2 linux/amd64
build_image 8.2 true 8.2-xdebug linux/amd64
build_image 8.4.3 false 8.4 linux/amd64
build_image 8.4.3 true 8.4-xdebug linux/amd64

echo "Образы для amd64 собраны и архивированы."