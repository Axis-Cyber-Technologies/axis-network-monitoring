# Redis Workflow Design

We rely on Redis Streams, Hashes, and Sorted Sets to coordinate policy approvals
and AI-assisted conversations. This document describes the key keys and worker
processes.

## Key Spaces & Structures

### Streams
| Key | Purpose | Producers | Consumers |
|-----|---------|-----------|-----------|
| `approvals:requested` | New policy requests awaiting evaluation | UI/API, automated detectors | `validator`, `sla-monitor`, dashboards |
| `approvals:decided` | Final decisions emitted by reviewers or bots | UI/API | `config-applier`, audit logger |
| `ai:conv:<id>` | Ordered conversation events for a policy incident | UI, AI service | Researchers, reporting jobs |
| `alerts:policy` | High-priority alerts needing escalation | detection modules | on-call pager worker |

Each Stream uses consumer groups for HA (`GROUP validator`, `GROUP dashboard`).

### Hashes
- `approval:<req_id>`: canonical state snapshot.
  - Fields: `status`, `severity`, `requester`, `approver`, `policy_id`,
    `policy_version`, `requested_at`, `decided_at`, `deadline`, `notes`,
    `ai_summary`, `diff_ref`.
- `ai:state:<conv_id>`: short summary of the AI conversation with pointers to
  related policy/version and ticketing IDs.

### Sorted Sets
- `approvals:sla`: score equals deadline epoch; members are req IDs. Used by
  `sla-monitor` to detect overdue requests.
- `approvals:priority`: optional severity-based backlog ordering.

### Sets / Bitmaps
- `approvals:watchers:<policy_id>`: subscribers to policy updates (for
  notifications).
- `approvals:locks`: ephemeral keys (with PX TTL) used during atomic state
  transitions.

## Worker Responsibilities

| Worker | Function |
|--------|----------|
| `validator` | `XREADGROUP` from `approvals:requested`, enrich request (lookup owner, reputation), auto-approve low-risk or push to human. Writes updates to `approval:<id>` and forwards to `approvals:requested` with status `pending_review`. |
| `sla-monitor` | Scans `approvals:sla`, pushes overdue items into `alerts:policy`, optionally escalates status to `escalated`. |
| `ui-notifier` | Tails `approvals:requested` and `approvals:decided` to update WebSocket dashboards. |
| `config-applier` | Listens on `approvals:decided`, applies approved changes via configd (`configctl policy.apply`) and updates `policy_changes` in ClickHouse. Handles rollback on failure. |
| `audit-logger` | Mirrors every decision and auto-action into ClickHouse `policy_changes` table. |
| `ai-orchestrator` | Manages `ai:conv:*` Streams, injects AI responses (ChatGPT, local LLM) and stores condensed summary in `ai:state:<id>`. |

## Patterns & Conventions
- Every state transition obtains a short-lived lock (`SETNX approval:lock:<id>`
  1 EX 30) to prevent concurrent writes.
- All timestamps stored as ISO8601 strings (UTC) to ease cross-system parsing.
- Stream IDs follow the auto-generated format (`<msTime>-<seq>`). Workers keep
  per-group offsets with `XACK` to avoid redelivery storms.
- Strictly limit Stream retention via `XTRIM … MINID` (e.g., keep 14 days) since
  long-term history resides in ClickHouse.
- Use Redis ACLs: dedicate users for UI, workers, and monitoring; enable TLS.

## High-Level Flow

1. **Request raised**: `XADD approvals:requested * ... status="new"` and state
   stored in `approval:<id>`.
2. **Validation**: validator consumes, enriches, sets status `pending_review`,
   updates hash, re-adds to `approvals:sla`.
3. **Decision**: human UI posts decision → `HSET approval:<id>` + `XADD
   approvals:decided`.
4. **Apply**: config-applier executes configd action, logs success/failure,
   updates ClickHouse, modifies hash status to `applied` or `failed`.
5. **Audit**: watchers and dashboards respond through their consumer groups.

This architecture keeps the approval pipeline durable, observable, and
responsive while enabling future expansion (multi-region replication via
Redis Streams sharding).
