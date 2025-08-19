import json


def handler(event, context):
    body = {
        "ok": True,
        "service": "bootstrap",
        "route": (event.get("requestContext") or {}).get("routeKey"),
    }
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }
