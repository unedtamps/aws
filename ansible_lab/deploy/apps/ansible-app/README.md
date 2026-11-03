# ansible-app

Simple GET-only car API for the `ansible_lab` deployment. Go + PostgreSQL,
built to run on the lab's EC2 workers (ingress for ports `8000-8020` is
already open on the `ansible-sg` security group).

## Routes

| Method | Route    | Description                                        |
|--------|----------|----------------------------------------------------|
| GET    | `/`      | Health check (same response as `/health`)          |
| GET    | `/health`| Liveness: always `{"status":"ok"}`                 |
| GET    | `/ready` | Readiness: `200` when Postgres is reachable, `503` otherwise |
| GET    | `/car`   | List car details from the database                 |

## Startup behaviour

On every start the app:

1. Connects to Postgres using the `DB_STRING` DSN (waits up to 60s for the
   database to become reachable).
2. Runs embedded SQL migrations (`migrations/`, tracked in
   `schema_migrations`, guarded by a `pg_advisory_lock`).
3. Seeds 20 random car details (brand/model/color/year/price), but only when
   the `cars` table is empty — restarts never duplicate or overwrite rows.

## Configuration

| Env        | Required | Default | Description                              |
|------------|----------|---------|------------------------------------------|
| `DB_STRING`| yes      | -       | Postgres DSN, e.g. `postgres://user:pass@host:5432/db?sslmode=disable` |
| `PORT`     | no       | `8000`  | HTTP listen port                          |

## Build and run

```sh
# locally
go build -o ansible-app .
DB_STRING='postgres://postgres:postgres@localhost:5432/ansible_app?sslmode=disable' ./ansible-app

# docker
docker build -t ansible-app .
docker run --rm -p 8000:8000 \
  -e DB_STRING='postgres://postgres:postgres@db:5432/ansible_app?sslmode=disable' \
  ansible-app
```
