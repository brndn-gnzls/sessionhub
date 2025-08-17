# Sessionhub (Flutter + GraphQL + Python)

A production-grade, budget-friendly stack:

- **Client**: Flutter/Dart
- **API**: FastAPI + Strawberry GraphQL (on AWS Lambda via Mangum)
- **Transport**: API Gateway (HTTP for queries/mutations, WebSocket for subs)
- **DB**: PostgresQL on EC2 (private, same VPC as Lambda), PgBouncer for pooling
- **Infra**: AWS (API Gateway, Lambda, VPC, EC2, CloudWatch), IaC in `infra/aws`

## Monorepo Layout

- **api/**: FastAPI + Strawberry app (schema, resolvers, loaders, services)
- **infra/aws/**: IaC & deployment artifacts for API Gateway, Lambda, VPC, EC2, etc.
- **migrations/**:Alembic migrations
- **scripts/** Dev/ops scripts (seed, maintenance)
- **tests/** Unit & integration tests
- **.github/**  CI/CD workflows (GitHub Actions)


## GitHub Actions Workflow
![CI](https://github.com/brndn-gnzls/sessionhub/actions/workflows/ci.yml/badge.svg)