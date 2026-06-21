"""EC2 + RDS 전원 제어 Lambda.
EventBridge Scheduler 가 {"action": "start"} / {"action": "stop"} 으로 호출.
이미 해당 상태이거나 전이 중이면 무시(멱등).
"""
import os
import boto3
from botocore.exceptions import ClientError

ec2 = boto3.client("ec2")
rds = boto3.client("rds")

INSTANCE_ID = os.environ["INSTANCE_ID"]
DB_INSTANCE_ID = os.environ["DB_INSTANCE_ID"]


def _safe(fn, **kwargs):
    try:
        fn(**kwargs)
        print(f"OK: {fn.__name__} {kwargs}")
    except ClientError as e:
        # 이미 start/stop 됐거나 전이 중 → 무시
        print(f"SKIP: {fn.__name__} {kwargs} -> {e.response['Error']['Code']}")


def handler(event, context):
    action = (event or {}).get("action")
    print(f"action={action} ec2={INSTANCE_ID} rds={DB_INSTANCE_ID}")

    if action == "start":
        # RDS 는 기동이 느리므로 먼저 시작
        _safe(rds.start_db_instance, DBInstanceIdentifier=DB_INSTANCE_ID)
        _safe(ec2.start_instances, InstanceIds=[INSTANCE_ID])
    elif action == "stop":
        _safe(ec2.stop_instances, InstanceIds=[INSTANCE_ID])
        _safe(rds.stop_db_instance, DBInstanceIdentifier=DB_INSTANCE_ID)
    else:
        raise ValueError(f"unknown action: {action!r} (expected 'start' or 'stop')")

    return {"action": action, "ec2": INSTANCE_ID, "rds": DB_INSTANCE_ID}
