# Nginx возвращает 502

## Симптом

`/healthz` отвечает 200, но корневой URL возвращает 502 Bad Gateway.

## Проверка

```bash
docker compose ps nginx glpi
docker compose logs --tail=200 nginx glpi
docker compose exec nginx getent hosts glpi
docker compose exec nginx wget -S -O- http://glpi/ 2>&1 | head -n 30
```

## Действия

1. Если имя `glpi` не разрешается, проверьте сеть `backend` в `docker compose config`.
2. Если порт недоступен, дождитесь healthcheck GLPI и изучите его журнал.
3. После исправления выполните `docker compose up -d glpi nginx`.
4. Не меняйте upstream на IP контейнера: адрес нестабилен.

## Подтверждение

```bash
curl -fsS http://localhost:8080/healthz
curl -I http://localhost:8080/
make health
```
