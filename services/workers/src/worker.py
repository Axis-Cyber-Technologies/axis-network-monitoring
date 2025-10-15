import os
import time
from datetime import datetime
from typing import Dict

from loguru import logger
from redis import Redis
import clickhouse_connect

REDIS_URL = os.getenv("REDIS_URL", "redis://:axis_secret@redis:6379/0")
REQUEST_STREAM = os.getenv("REQUEST_STREAM", "approvals:requested")
DECISION_STREAM = os.getenv("DECISION_STREAM", "approvals:decided")
CONSUMER_GROUP = os.getenv("CONSUMER_GROUP", "validator")
CONSUMER_NAME = os.getenv("CONSUMER_NAME", "validator-1")
POLL_TIMEOUT_MS = int(os.getenv("POLL_TIMEOUT_MS", "5000"))
AUTO_APPROVE_THRESHOLD = int(os.getenv("AUTO_APPROVE_THRESHOLD", "2"))

CH_HOST = os.getenv("CH_HOST", "clickhouse")
CH_PORT = int(os.getenv("CH_PORT", "8123"))
CH_USER = os.getenv("CH_USER", "axis_api")
CH_PASSWORD = os.getenv("CH_PASSWORD", "axis_secret")
CH_SECURE = os.getenv("CH_SECURE", "false").lower() == "true"


class ApprovalWorker:
    def __init__(self) -> None:
        self.redis = Redis.from_url(REDIS_URL, decode_responses=True)
        self._ensure_group()
        self.ch = clickhouse_connect.get_client(
            host=CH_HOST,
            port=CH_PORT,
            username=CH_USER,
            password=CH_PASSWORD,
            secure=CH_SECURE,
        )

    def _ensure_group(self) -> None:
        try:
            self.redis.xgroup_create(name=REQUEST_STREAM, groupname=CONSUMER_GROUP, id="0-0", mkstream=True)
            logger.info("Created consumer group {group} on stream {stream}", group=CONSUMER_GROUP, stream=REQUEST_STREAM)
        except Exception as exc:  # group exists
            if "BUSYGROUP" in str(exc):
                logger.debug("Consumer group already exists")
            else:
                raise

    def run(self) -> None:
        logger.info("Approval worker started as {name}", name=CONSUMER_NAME)
        while True:
            try:
                messages = self.redis.xreadgroup(
                    groupname=CONSUMER_GROUP,
                    consumername=CONSUMER_NAME,
                    streams={REQUEST_STREAM: ">"},
                    count=10,
                    block=POLL_TIMEOUT_MS,
                )
                if not messages:
                    continue
                for stream, entries in messages:
                    for entry_id, data in entries:
                        try:
                            self.process_entry(entry_id, data)
                            self.redis.xack(REQUEST_STREAM, CONSUMER_GROUP, entry_id)
                        except Exception as exc:  # noqa: BLE001
                            logger.exception("Error handling request {entry}: {exc}", entry=entry_id, exc=exc)
            except Exception as outer_exc:  # noqa: BLE001
                logger.exception("Stream polling error: {exc}", exc=outer_exc)
                time.sleep(5)

    def process_entry(self, entry_id: str, data: Dict[str, str]) -> None:
        req_id = data.get("req_id") or entry_id
        status = data.get("status", "new")
        severity = int(data.get("severity", "0"))
        logger.debug("Processing request {req} severity {sev} status {status}", req=req_id, sev=severity, status=status)

        self._update_hash(req_id, data, status="pending_review")

        if severity <= AUTO_APPROVE_THRESHOLD:
            decision = "approve"
            reason = "auto_approve_low_severity"
        else:
            logger.info("Request {req_id} queued for manual review", req_id=req_id)
            return

        self._emit_decision(req_id, data, decision, reason)
        self._record_policy_change(req_id, data, decision, reason)

    def _update_hash(self, req_id: str, data: Dict[str, str], status: str) -> None:
        key = f"approval:{req_id}"
        payload = {
            "status": status,
            "requester": data.get("requester", "unknown"),
            "target": data.get("target", "unknown"),
            "policy": data.get("policy", "default"),
            "severity": data.get("severity", "0"),
            "received_at": datetime.utcnow().isoformat() + "Z",
        }
        self.redis.hset(key, mapping=payload)

    def _emit_decision(self, req_id: str, data: Dict[str, str], decision: str, reason: str) -> None:
        now_iso = datetime.utcnow().isoformat() + "Z"
        self.redis.hset(
            f"approval:{req_id}",
            mapping={
                "status": "approved" if decision == "approve" else "denied",
                "decided_at": now_iso,
                "decided_reason": reason,
            },
        )
        payload = {
            "req_id": req_id,
            "decision": decision,
            "policy": data.get("policy", "default"),
            "reason": reason,
            "decided_at": now_iso,
        }
        self.redis.xadd(DECISION_STREAM, payload)
        logger.info("Auto {decision} request {req}", decision=decision, req=req_id)

    def _record_policy_change(self, req_id: str, data: Dict[str, str], decision: str, reason: str) -> None:
        self.ch.command(
            "INSERT INTO axis_monitor.policy_changes (ts, change_id, policy, policy_version, actor, actor_type, decision, comment, status, duration_ms, metadata) VALUES",
            [
                (
                    datetime.utcnow(),
                    req_id,
                    data.get("policy", "default"),
                    data.get("policy_version", "1"),
                    "auto-worker",
                    "automation",
                    "approved" if decision == "approve" else "denied",
                    reason,
                    "applied",
                    0,
                    {"source": data.get("source", "demo")},
                )
            ],
        )


if __name__ == "__main__":
    worker = ApprovalWorker()
    worker.run()
