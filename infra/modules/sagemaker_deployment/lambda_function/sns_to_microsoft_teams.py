import json
import logging
import os
from datetime import datetime

import urllib3

logger = logging.getLogger()
logger.setLevel("INFO")
http = urllib3.PoolManager()


def lambda_handler(event, context):
    webhook_url = os.getenv("TEAMS_WEBHOOK_URL")
    message_str = event["Records"][0]["Sns"]["Message"]
    alarm_name = json.loads(message_str)["AlarmName"]
    dimensions_list = json.loads(message_str)["Trigger"]["Metrics"][0]["MetricStat"][
        "Metric"
    ]["Dimensions"]
    endpoint_name = next(
        x["value"] for x in dimensions_list if x["name"] == "EndpointName"
    )
    new_state = json.loads(message_str)["NewStateValue"]
    timestamp_str = json.loads(message_str)["StateChangeTime"]
    timestamp_dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%S.%f%z")
    readable_date_str = str(timestamp_dt.date())
    readable_time_str = str(timestamp_dt.strftime("%H:%M:%S"))
    region = "eu-west-2"  # it was easier to hard-code this (apologies for inelegance)

    alarm_url = f"https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#alarmsV2:alarm/{alarm_name}"

    if new_state == "ALARM":
        colour = "FF0000"
    elif new_state == "OK":
        colour = "00FF00"
    else:
        colour = "0000FF"

    message_card = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": colour,
        "title": f"Transition to {new_state} on {endpoint_name} for alarm {alarm_name}",
        "text": f"Triggered at {readable_time_str} on {readable_date_str}",
        "potentialAction": [
            {
                "@type": "OpenUri",
                "name": "View Alarm",
                "targets": [{"os": "default", "uri": alarm_url}],
            }
        ],
    }
    headers = {"Content-Type": "application/json"}
    encoded_message_card = json.dumps(message_card)
    response = http.request(
        method="POST",
        url=webhook_url,
        body=encoded_message_card,
        headers=headers,
    )
    logger.info(
        f"Completed with code {response.status} and full response {response.data}"
    )
