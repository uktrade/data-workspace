import urllib3
import json
import os
import ast

http = urllib3.PoolManager()


def lambda_handler(event, context):
    url = os.getenv("TEAMS_WEBHOOK_URL")
    message_str = event["Records"][0]["Sns"]["Message"]
    message_dict = json.loads(message_str)
    alarm_name = message_dict["AlarmName"]
    alarm_description = message_dict['AlarmDescription']
    old_state = message_dict["OldStateValue"]
    new_state = message_dict["NewStateValue"]
    timestamp = message_dict["StateChangeTime"]
    msg = {"text": str({"alarm_name": alarm_name, "old_state": old_state, "new_state": new_state, "timestamp": timestamp , "alarm_description": alarm_description})}
    encoded_msg = json.dumps(msg).encode("utf-8")
    resp = http.request("POST", url, body=encoded_msg)
    print(msg)
    print(encoded_msg)
    print(resp.status)
    print(resp.data)
