import os
from datetime import datetime
from typing import Optional

import clickhouse_connect
from fastapi import FastAPI, HTTPException, Query

from redis import Redis

app = FastAPI(title="Axis Network Monitor API", version="0.1.0")

# Lazily initialized global clients
_ch_client: Optional[clickhouse_connect.driver.Client] = None
_redis_client: Optional[Redis] = None


def get_clickhouse_client() -> clickhouse_connect.driver.Client:
    global _ch_client
    if _ch_client is None:
        _ch_client = clickhouse_connect.get_client(
            host=os.getenv("CH_HOST", "clickhouse-gateway"),
            port=int(os.getenv("CH_PORT", "8443")),
            username=os.getenv("CH_USER", "axis_api"),
            password=os.getenv("CH_PASSWORD", "CHANGE_ME"),
            secure=os.getenv("CH_SECURE", "true").lower() == "true",
        )
    return _ch_client


def get_redis_client() -> Redis:
    global _redis_client
    if _redis_client is None:
        _redis_client = Redis.from_url(
            os.getenv(
                "REDIS_URL",
                "rediss://axis_api:CHANGE_ME@redis-gateway:6380/0",
            ),
            decode_responses=True,
        )
    return _redis_client


@app.get("/v1/flows/top-talkers")
def top_talkers(
    start: datetime = Query(..., alias="from"),
    end: datetime = Query(..., alias="to"),
    vlan: Optional[str] = None,
    limit: int = Query(20, gt=0, le=200),
):
    ch = get_clickhouse_client()
    conditions = ["ts BETWEEN %(start)s AND %(end)s"]
    params = {"start": start, "end": end, "limit": limit}
    if vlan:
        conditions.append("vlan = %(vlan)s")
        params["vlan"] = vlan
    query = f"""
        SELECT
            src_ip,
            sum(bytes_out) AS bytes_out,
            sum(bytes_in) AS bytes_in,
            count() AS flows
        FROM axis_monitor.sec_events
        WHERE {' AND '.join(conditions)}
        GROUP BY src_ip
        ORDER BY (bytes_out + bytes_in) DESC
        LIMIT %(limit)s
    """
    rows = ch.query(query, params).result_rows
    return [
        {
            "src_ip": row[0],
            "bytes_out": row[1],
            "bytes_in": row[2],
            "flows": row[3],
        }
        for row in rows
    ]


@app.get("/v1/dns/blocked/series")
def dns_blocked_series(
    start: datetime = Query(..., alias="from"),
    end: datetime = Query(..., alias="to"),
    bucket: str = Query("1h"),
):
    ch = get_clickhouse_client()
    query = """
        SELECT
            toStartOfInterval(ts, INTERVAL %(bucket)s) AS t,
            count() AS blocks
        FROM axis_monitor.dns_queries
        WHERE action = 'blocked'
          AND ts BETWEEN %(start)s AND %(end)s
        GROUP BY t
        ORDER BY t
    """
    rows = ch.query(query, {"start": start, "end": end, "bucket": bucket}).result_rows
    return [{"timestamp": row[0], "blocks": row[1]} for row in rows]


@app.get("/v1/security/attempts")
def security_attempts(
    kind: str = Query(..., regex="^(ssh|wireguard|openvpn)$"),
    start: datetime = Query(..., alias="from"),
    end: datetime = Query(..., alias="to"),
):
    ch = get_clickhouse_client()
    app_label = {"ssh": "ssh", "wireguard": "wireguard", "openvpn": "openvpn"}[kind]
    query = """
        SELECT
            toStartOfInterval(ts, INTERVAL 1 HOUR) AS bucket,
            count() AS attempts
        FROM axis_monitor.sec_events
        WHERE action = 'block'
          AND app = %(app_label)s
          AND ts BETWEEN %(start)s AND %(end)s
        GROUP BY bucket
        ORDER BY bucket
    """
    rows = ch.query(
        query,
        {"app_label": app_label, "start": start, "end": end},
    ).result_rows
    return [{"timestamp": row[0], "attempts": row[1]} for row in rows]


@app.get("/v1/policy/hits")
def policy_hits(
    policy: str,
    start: datetime = Query(..., alias="from"),
    end: datetime = Query(..., alias="to"),
    limit: int = Query(50, gt=0, le=500),
):
    ch = get_clickhouse_client()
    query = """
        SELECT
            rule_id,
            count() AS hits
        FROM axis_monitor.sec_events
        WHERE policy = %(policy)s
          AND ts BETWEEN %(start)s AND %(end)s
        GROUP BY rule_id
        ORDER BY hits DESC
        LIMIT %(limit)s
    """
    rows = ch.query(
        query,
        {"policy": policy, "start": start, "end": end, "limit": limit},
    ).result_rows
    return [{"rule_id": row[0], "hits": row[1]} for row in rows]


@app.get("/v1/approvals/pending")
def approvals_pending(count: int = Query(50, gt=0, le=500)):
    redis = get_redis_client()
    entries = redis.xread(
        {"approvals:requested": "0-0"},
        count=count,
        block=1,
    )
    pending = []
    for stream, items in entries:
        for entry_id, data in items:
            status = data.get("status")
            if status in ("new", "pending_review", "escalated"):
                pending.append(
                    {
                        "id": data.get("req_id"),
                        "status": status,
                        "requester": data.get("requester"),
                        "target": data.get("target"),
                        "reason": data.get("reason"),
                        "severity": data.get("severity"),
                        "submitted_at": data.get("submitted_at"),
                    }
                )
    return pending[:count]


@app.post("/v1/approvals/{req_id}/decision")
def approval_decision(
    req_id: str,
    decision: str,
    comment: Optional[str] = None,
):
    if decision not in {"approve", "deny"}:
        raise HTTPException(status_code=400, detail="Invalid decision")
    redis = get_redis_client()
    key = f"approval:{req_id}"
    if not redis.exists(key):
        raise HTTPException(status_code=404, detail="Request not found")
    now_iso = datetime.utcnow().isoformat() + "Z"
    redis.hset(
        key,
        mapping={
            "status": "approved" if decision == "approve" else "denied",
            "decided_at": now_iso,
            "comment": comment or "",
        },
    )
    redis.xadd(
        "approvals:decided",
        {
            "req_id": req_id,
            "decision": decision,
            "decided_at": now_iso,
            "comment": comment or "",
        },
    )
    return {"req_id": req_id, "decision": decision, "decided_at": now_iso}
