# Эксплуатация

## Ежедневная проверка

```bash
make status
make health
```

Ожидаемый результат: долгоживущие сервисы имеют состояние `healthy`, SQL-запрос выполняется успешно, `/healthz` отвечает HTTP 200.

## Логи

```bash
make logs SERVICE=glpi
make logs SERVICE=db
make logs SERVICE=nginx
```

Для разового снимка:

```bash
docker compose logs --tail=200 --timestamps glpi db nginx
```

## Перезапуск

```bash
make restart SERVICE=glpi
make health
```

Перезапускайте только неисправный компонент. Полный рестарт обычно не нужен и скрывает исходную причину.

## Мониторинг

Grafana автоматически загружает datasource Prometheus и dashboard **HelpDesk Overview**. Dashboard показывает доступность endpoint, состояние MariaDB, CPU/RAM контейнеров, использование файловых систем и длительность HTTP probe.

Полезные PromQL-запросы:

```promql
probe_success
mysql_up
up == 0
sum by (name) (container_memory_working_set_bytes{name!=""})
1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)
```

## Обновление образов

1. Создайте бэкап и проверьте `SHA256SUMS`.
2. Измените ровно одну или связанную группу версий в `.env` и `.env.example`.
3. Выполните `docker compose pull`.
4. Проверьте `docker compose config --quiet`.
5. Запустите `docker compose up -d` и `make health`.
6. Проверьте вход в GLPI и dashboard Grafana.

Не используйте `latest` в рабочем окружении. Для строгой воспроизводимости замените теги на digest после проверки.

## Runbooks

- [Приложение недоступно](runbooks/app-unavailable.md)
- [База недоступна](runbooks/database-unavailable.md)
- [Nginx возвращает 502](runbooks/nginx-502.md)
- [Заканчивается место](runbooks/disk-space-low.md)
