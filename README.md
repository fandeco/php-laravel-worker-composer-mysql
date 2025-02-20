# Docker для modx

```bash
# только для amd64
docker buildx build --platform linux/amd64 -t php-laravel-worker-composer-mysql:latest .

# для включение поддержки amd64
docker buildx create --use

# Сборка и публикация образа
# перед выполнением проверить авторизации на docker hub "docker login"
docker buildx build --platform linux/arm64,linux/amd64 -t traineratwot/php-laravel-worker-composer-mysql:latest -f "8.4.Dockerfile" --push .
docker buildx build --platform linux/arm64,linux/amd64 -t traineratwot/php-laravel-worker-composer-mysql:8.4 -f "8.4.Dockerfile" --push .
docker buildx build --platform linux/arm64,linux/amd64 -t traineratwot/php-laravel-worker-composer-mysql:8.2 -f "8.2.Dockerfile" --push .
```
