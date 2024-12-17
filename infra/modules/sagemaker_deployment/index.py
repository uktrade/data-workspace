import json
import os
import urllib3

http = urllib3.PoolManager()

# Environment variable containing SNS -> webhook URL mapping
SNS_TO_WEBHOOK_JSON = json.loads(os.environ["SNS_TO_WEBHOOK_JSON"])

def handler(event, context):
    for record in event["Records"]:
        sns_message = json.loads(record["Sns"]["Message"])
        topic_arn = record["Sns"]["TopicArn"]  # SNS Topic ARN
        alert_name = sns_message.get("AlarmName", "Unknown Alert")
        state = sns_message.get("NewStateValue", "Unknown State")
        reason = sns_message.get("NewStateReason", "No reason provided")

        # Determine the webhook URL for the SNS topic
        webhook_url = SNS_TO_WEBHOOK_JSON.get(topic_arn)
        if not webhook_url:
            print(f"No webhook URL found for SNS topic: {topic_arn}")
            continue

        payload = {
            "text": f"*Alert:* {alert_name}\n*State:* {state}\n*Reason:* {reason}"
        }

        # Send the alert to Slack
        response = http.request(
            "POST",
            webhook_url,
            body=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )

        if response.status != 200:
            print(f"Failed to send alert to Slack: {response.data.decode('utf-8')}")

    return {"statusCode": 200, "body": "Alerts processed successfully"}
