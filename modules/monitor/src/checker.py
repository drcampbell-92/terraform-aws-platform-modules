import json
import os
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
TARGETS = json.loads(os.environ["TARGETS"])
TIMEOUT = float(os.environ.get("TIMEOUT_SECONDS", "5"))
RETENTION_DAYS = int(os.environ.get("RESULT_RETENTION_DAYS", "7"))
TOPIC_ARN = os.environ.get("ALERT_TOPIC_ARN", "")
STATUS_BUCKET = os.environ.get("STATUS_BUCKET", "")
STATUS_KEY = os.environ.get("STATUS_KEY", "status.json")

table = boto3.resource("dynamodb").Table(TABLE_NAME)
sns = boto3.client("sns") if TOPIC_ARN else None
s3 = boto3.client("s3") if STATUS_BUCKET else None


def check(name, url):
    started = time.monotonic()
    try:
        request = urllib.request.Request(url, headers={"User-Agent": "uptime-checker"})
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            status = response.status
    except urllib.error.HTTPError as error:
        status = error.code
    except Exception:
        status = 0
    latency_ms = int((time.monotonic() - started) * 1000)
    return {
        "name": name,
        "url": url,
        "status": status,
        "latency_ms": latency_ms,
        "ok": 200 <= status < 400,
    }


def handler(event, context):
    now = datetime.now(timezone.utc)
    checked_at = now.isoformat()
    expires_at = int((now + timedelta(days=RETENTION_DAYS)).timestamp())

    results = [check(name, url) for name, url in TARGETS.items()]

    for result in results:
        table.put_item(
            Item={
                "target": result["name"],
                "checked_at": checked_at,
                "status": result["status"],
                "latency_ms": result["latency_ms"],
                "ok": result["ok"],
                "expires_at": expires_at,
            }
        )

    failures = [result for result in results if not result["ok"]]

    if sns and failures:
        lines = [f"{r['name']} ({r['url']}) returned {r['status']}" for r in failures]
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="Uptime check failed",
            Message="\n".join(lines),
        )

    if s3:
        s3.put_object(
            Bucket=STATUS_BUCKET,
            Key=STATUS_KEY,
            Body=json.dumps({"checked_at": checked_at, "results": results}),
            ContentType="application/json",
            CacheControl="max-age=60",
        )

    return {"checked": len(results), "failures": len(failures)}