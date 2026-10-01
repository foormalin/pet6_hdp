# Приложение недоступно

## Симптом

Браузер не открывает GLPI, `/healthz` не отвечает или blackbox probe показывает `0`.

## Проверка

```bash
make status
docker compose logs --tail=200 nginx glpi
curl -v http://localhost:8080/healthz
```

Если `/healthz` отвечает, но GLPI нет, проверьте приложение из сети Docker:

```bash
docker compose exec nginx wget -S -O- http://glpi/ 2>&1 | head -n 30
```

## Действия

1. Если `glpi` unhealthy, проверьте журнал и состояние `db`.
2. Исправьте конфигурацию или нехватку ресурсов.
3. Перезапустите только затронутый сервис: `make restart SERVICE=glpi`.
4. Не удаляйте volumes при диагностике.

## Подтверждение

```bash
make health
curl -I http://localhost:8080/
```

Откройте существующую тестовую заявку и убедитесь, что данные читаются.
