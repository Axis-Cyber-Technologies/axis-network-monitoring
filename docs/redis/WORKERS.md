# Worker Implementation Notes

The `services/workers` package contains a minimal Redis Stream consumer that
illustrates the approval automation pipeline described in `WORKFLOWS.md`.

## Components
- `worker.py`: listens on the `approvals:requested` stream, enriches request
  hashes, auto-approves low severity items, records policy changes in
  ClickHouse, and emits decisions to `approvals:decided`.
- `submit_request.py`: simple helper for enqueuing demo requests.

## Running via Docker Compose
The worker container (`axis-approval-worker`) starts automatically with the
local development stack defined in `docker-compose.yml`.

Environment overrides:
- `AUTO_APPROVE_THRESHOLD` — maximum severity auto-approved (default: `2`).
- `CONSUMER_GROUP`, `CONSUMER_NAME` — customize Redis consumer group identity.
- `CH_*` — ClickHouse connection settings.

## Local CLI Usage
Activate the `api` virtualenv (or create one) and run:

```sh
python services/workers/src/submit_request.py
```

The worker will log whether the request was auto-approved and inserts a record
into `axis_monitor.policy_changes`.

## Next Enhancements
- Add exception handling for duplicate decisions and retries.
- Implement manual review workflow (UI or CLI) that updates the Redis hash and
  emits to `approvals:decided`.
- Extend `worker.py` with pluggable validators (reputation checks, compliance
  policies) before approving.
