# Development Stack

Docker Compose stack spins up ClickHouse, Redis, Fluent Bit, and the FastAPI
service to exercise the architecture locally.

## Prerequisites
- Docker & Docker Compose plugin
- Optional: `make` for helper commands

## Bring Up the Stack

```sh
docker compose up --build
```

Services:
- `clickhouse` (ports 8123/9000) with schema + user provisioning via
  `docker/clickhouse/initdb.d`.
- `redis` (port 6379) secured with password `axis_secret`.
- `api` (port 8080) exposing the FastAPI prototype.
- `fluent-bit` shipping sample logs from `demo/logs/` into ClickHouse.
- `worker` processing approval streams and auto-approving low severity
  requests.

Once running, query the API:

```sh
curl 'http://127.0.0.1:8080/v1/flows/top-talkers?from=2024-10-15T00:00:00Z&to=2024-10-16T00:00:00Z'
```

Inject a sample approval request:

```sh
docker compose exec axis-approval-worker python /app/src/submit_request.py
```

Observe worker logs and confirm audit entry:

```sh
docker logs axis-approval-worker --tail=50
docker exec -it axis-clickhouse clickhouse-client --user axis_api --password axis_secret \
  --query 'SELECT ts, policy, decision, comment FROM axis_monitor.policy_changes ORDER BY ts DESC LIMIT 5'
```

Inspect ClickHouse directly:

```sh
docker exec -it axis-clickhouse clickhouse-client --user axis_api --password axis_secret \
  --query 'SELECT ts, src_ip, action, bytes_out FROM axis_monitor.sec_events LIMIT 5'
```

## Updating Sample Data

Edit or append files under `demo/logs/` to simulate new events, then restart the
Fluent Bit container or touch the files to trigger tailing.

## Teardown

```sh
docker compose down -v
```

> **Note**: This stack is for development only—no TLS, coarse auth, and static
> secrets. Production deployments must harden credentials, enable TLS, and add
> monitoring/alerts.
