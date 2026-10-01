# База данных недоступна

## Симптом

GLPI сообщает об ошибке соединения, `db` unhealthy или метрика `mysql_up` равна `0`.

## Проверка

```bash
docker compose ps db mysql-exporter
docker compose logs --tail=200 db mysql-exporter
docker compose exec -T db sh -ec 'mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" --execute="SELECT 1" "$MARIADB_DATABASE"'
```

Проверьте диск:

```bash
df -h
docker system df
```

## Действия

1. При нехватке места следуйте runbook `disk-space-low.md`.
2. При ошибке учётных данных сравните `GLPI_DB_*` и `MARIADB_*` в итоговой модели `docker compose config` без публикации вывода.
3. Если БД завершилась после сбоя, перезапустите только её: `make restart SERVICE=db`.
4. При повреждении данных остановите изменения и восстановите последний проверенный бэкап.

## Подтверждение

```bash
make health
docker compose exec -T db sh -ec 'mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" --execute="SHOW TABLES" "$MARIADB_DATABASE" | head'
```

После восстановления проверьте вход и одну существующую заявку.
