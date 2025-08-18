.PHONY: dev up down logs sh ruff mypy test

dev:
	docker compose up --build

up:
	docker compose up

down:
	docker compose down -v

logs:
	docker compose logs -f api

sh:
	docker compose exec api sh

ruff:
	docker compose exec api ruff check .

mypy:
	docker compose exec api mypy api

test:
	docker compose exec api pytest -q