import csv
import json
import logging
import os
from datetime import datetime as Datetime
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

s3 = boto3.client("s3")
S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "")
S3_OBJECT_KEY: str = os.getenv("S3_OBJECT_KEY", "")


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    for record in event["Records"]:
        process_message(record)


def process_message(record: dict[str, Any]) -> None:
    try:
        logger.info("Starting processing of message to determine contents")
        message_str = str(record["Sns"]["Message"])
        message_dict = json.loads(message_str)
        invocation_status = str(message_dict["invocationStatus"])
        logger.info(f"Received notification of a {invocation_status} inference")
        endpoint_name = str(message_dict["requestParameters"]["endpointName"])
        federated_user_id = (
            str(message_dict["requestParameters"]["inputLocation"])
            .split("/user/federated/")[1]
            .split("/")[0]
        )
        inference_id = str(message_dict["inferenceId"])
        event_time = Datetime.strptime(
            str(message_dict["eventTime"]), "%Y-%m-%dT%H:%M:%S.%f%z"
        )
        received_time = Datetime.strptime(
            str(message_dict["receivedTime"]), "%Y-%m-%dT%H:%M:%S.%f%z"
        )
        input_payload_file = str(message_dict["requestParameters"]["inputLocation"])
        input_payload_bucket = input_payload_file.split("s3://")[1].split("/")[0]
        input_payload_key = "/".join(
            input_payload_file.split("s3://")[1].split("/")[1:]
        )
        payload_length = retrieve_payload_and_determine_length(
            input_payload_key, input_payload_bucket
        )
        logger.info(f"New payload_length {payload_length}")
        new_data_row = [
            inference_id,
            federated_user_id,
            invocation_status,
            event_time,
            received_time,
            endpoint_name,
            payload_length,
        ]
        logger.info(f"New data row is {new_data_row}")
        if invocation_status in ["Completed", "Failed"]:
            logger.info("Querying existing data in s3 file")
            append_new_rows_to_s3_object(new_data_row)
            logger.info("New row appended in s3 file")
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e


def append_new_rows_to_s3_object(new_data_row: list[object]) -> None:
    local_file_name = r"/tmp/db.csv"
    s3.download_file(Bucket=S3_BUCKET_NAME, Key=S3_OBJECT_KEY, Filename=local_file_name)
    with open(local_file_name, "a") as f:
        writer = csv.writer(f)
        writer.writerow(new_data_row)
    s3.upload_file(Filename=local_file_name, Bucket=S3_BUCKET_NAME, Key=S3_OBJECT_KEY)
    return


def retrieve_payload_and_determine_length(payload_key: str, payload_bucket: str) -> str:
    local_file_name = r"/tmp/payload.json"
    s3.download_file(Bucket=payload_bucket, Key=payload_key, Filename=local_file_name)
    with open(local_file_name, "r") as f:
        payload_data = str(json.load(f))
    payload_length = str(len(payload_data))
    return payload_length
