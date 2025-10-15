# Axis Network Monitor API

Prototype FastAPI service exposing aggregated analytics endpoints and approval
workflow operations.

## Local Development

```
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
export CLICKHOUSE_BASIC_AUTH=$(python - <<'PY'
from base64 import b64encode
print(b64encode(b"axis_api:CHANGE_ME").decode())
PY
)
uvicorn src.main:app --reload --host 0.0.0.0 --port 8080
```

Environment variables:
- `CH_HOST`, `CH_PORT`, `CH_USER`, `CH_PASSWORD` (optional overrides)
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_USER`, `REDIS_PASSWORD`

## Endpoints
- `GET /v1/flows/top-talkers` — aggregate bandwidth per source IP.
- `GET /v1/dns/blocked/series` — blocked DNS timeline.
- `GET /v1/security/attempts` — SSH/WireGuard/OpenVPN block counts.
- `GET /v1/policy/hits` — busiest rules within a policy.
- `GET /v1/approvals/pending` — peek into Redis Stream queue.
- `POST /v1/approvals/{id}/decision` — write decision back to Redis.

Add authentication/authorization (JWT) before production use.
