import json
import os
import urllib3

http = urllib3.PoolManager()

WEBHOOK_ID = os.environ["WEBHOOK_ID"]
CHANNEL_MAPPING = json.loads(os.environ.get("CHANNEL_MAPPING", "{}"))


def handler(event, context):
    for record in event["Records"]:
        sns_message = json.loads(record["Sns"]["Message"])
        alert_name = sns_message.get("AlarmName", "Unknown Alert")
        state = sns_message.get("NewStateValue", "Unknown State")
        reason = sns_message.get("NewStateReason", "No reason provided")

        channel = CHANNEL_MAPPING.get(alert_name, "#default-channel")

        payload = {
            "channel": channel,
            "text": f"*Alert:* {alert_name}\n*State:* {state}\n*Reason:* {reason}"
        }

        response = http.request(
            "POST",
            f"https://hooks.slack.com/services/{WEBHOOK_ID}",
            body=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )

        if response.status != 200:
            print(f"Failed to send alert: {response.data.decode('utf-8')}")

    return {"statusCode": 200}
