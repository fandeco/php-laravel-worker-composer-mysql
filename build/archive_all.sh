#!/bin/bash

# Создаем директорию для архивов, если ее еще нет
mkdir -p images

# Архивируем все собранные образы в один архив
echo "Архивируем все образы в один архив..."
tar -czvf images/php_images.tar.gz images/*.tar

echo "Все образы архивированы в php_images.tar.gz."