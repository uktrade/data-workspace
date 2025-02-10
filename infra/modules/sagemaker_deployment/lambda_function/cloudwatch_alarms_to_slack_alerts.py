import json
import os

import urllib3

http = urllib3.PoolManager()

# Environment variable containing SNS -> webhook URL mapping
SNS_TO_WEBHOOK_JSON = json.loads(os.environ["SNS_TO_WEBHOOK_JSON"])
ADDRESS = os.environ["ADDRESS"]


def lambda_handler(event, context):
    for record in event["Records"]:
        sns_message = json.loads(record["Sns"]["Message"])
        topic_arn = record["Sns"]["TopicArn"]  # SNS Topic ARN
        alert_name = sns_message.get("AlarmName", "Unknown Alert")
        state = sns_message.get("NewStateValue", "Unknown State")
        reason = sns_message.get("NewStateReason", "No reason provided")

        arn = topic_arn.replace(ADDRESS, "")
        # Determine the webhook URL for the SNS topic
        webhook_url = f"{SNS_TO_WEBHOOK_JSON.get(arn)}"
        if not webhook_url or webhook_url is None:
            continue

        payload = {
            "text": f"*Alert:* {alert_name}\n*State:* {state}\n*Reason:* {reason}"
        }

        # Send the alert to Slack
        response = http.request(
            "POST",
            f"https://hooks.slack.com/services/{webhook_url}",
            body=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )

        if response.status != 200:
            pass

    return {"statusCode": 200, "body": "Alerts processed successfully"}
