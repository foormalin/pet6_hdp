SHELL := /bin/sh
COMPOSE := docker compose
SERVICE ?= glpi
BACKUP ?=

.PHONY: init config pull up down restart status health logs backup restore

init:
	@test -f .env || cp .env.example .env
	@printf '%s\n' 'Configuration is ready in .env. Replace every change_me_* value before starting.'

config:
	@$(COMPOSE) config --quiet

pull:
	@$(COMPOSE) pull

up:
	@test -f .env || { printf '%s\n' 'Missing .env. Run: make init'; exit 1; }
	@$(COMPOSE) up -d --remove-orphans
	@printf '%s\n' 'HelpDesk is starting. Run: make health'

down:
	@$(COMPOSE) down --remove-orphans

restart:
	@$(COMPOSE) restart $(SERVICE)

status:
	@$(COMPOSE) ps

health:
	@./scripts/healthcheck.sh --wait

logs:
	@$(COMPOSE) logs --tail=200 -f $(SERVICE)

backup:
	@./scripts/backup.sh

restore:
	@test -n "$(BACKUP)" || { printf '%s\n' 'Usage: make restore BACKUP=backups/<timestamp>'; exit 1; }
	@./scripts/restore.sh "$(BACKUP)"
