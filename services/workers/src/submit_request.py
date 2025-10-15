import os
import uuid
from datetime import datetime

from redis import Redis

REDIS_URL = os.getenv("REDIS_URL", "redis://:axis_secret@localhost:6379/0")
STREAM = os.getenv("REQUEST_STREAM", "approvals:requested")


def submit(severity: int = 1, target: str = "198.51.100.10", policy: str = "default") -> str:
    redis = Redis.from_url(REDIS_URL, decode_responses=True)
    req_id = str(uuid.uuid4())
    payload = {
        "req_id": req_id,
        "status": "new",
        "severity": str(severity),
        "target": target,
        "policy": policy,
        "policy_version": "1",
        "requester": "demo-user",
        "reason": "demo submission",
        "submitted_at": datetime.utcnow().isoformat() + "Z",
        "source": "demo_cli",
    }
    redis.xadd(STREAM, payload)
    return req_id


if __name__ == "__main__":
    rid = submit()
    print(f"submitted: {rid}")
