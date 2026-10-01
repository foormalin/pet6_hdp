# Установка и первый запуск

## Предварительные требования

- Linux x86_64/arm64 или WSL 2;
- Docker Engine 24+ и Docker Compose v2;
- минимум 4 ГБ свободной RAM и 10 ГБ диска;
- `make`, `curl`, `gzip`, `sha256sum`.

Проверьте окружение:

```bash
docker version
docker compose version
make --version
```

## Настройка

```bash
cp .env.example .env
```

Замените каждое значение `change_me_*`. Для генерации секрета можно использовать:

```bash
openssl rand -base64 32
```

Пароль пользователя метрик должен состоять из букв, цифр, `_`, `-` или `.`: он передаётся в SQL при первичной настройке exporter-аккаунта.

Проверьте итоговую модель без запуска контейнеров:

```bash
make config
```

## Запуск

```bash
make pull
make up
make health
```

`make health` ожидает готовность до четырёх минут. Если таймаут недостаточен на медленном компьютере:

```bash
HEALTH_TIMEOUT=600 make health
```

Откройте:

- GLPI: http://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

GLPI автоматически устанавливает схему, когда заданы все пять `GLPI_DB_*` переменных. Для первого входа используйте `glpi` / `glpi` и сразу смените пароль. Grafana использует данные `GRAFANA_ADMIN_*` из `.env`.

## Остановка

```bash
make down
```

Команда сохраняет named volumes. Не запускайте `docker compose down --volumes`, если данные нужны.

## Перенос на VPS

1. Установите Docker и Compose на поддерживаемый Linux.
2. Скопируйте репозиторий без `.env` и каталога `backups`.
3. Создайте новый `.env` с уникальными секретами.
4. Сначала оставьте `BIND_ADDRESS=127.0.0.1` и проверьте сервис через SSH tunnel.
5. Добавьте TLS-терминацию и firewall.
6. Только после этого меняйте bind address или публикуйте reverse proxy.

Для VPS отдельно настройте копирование `backups/` на другой хост или object storage.
