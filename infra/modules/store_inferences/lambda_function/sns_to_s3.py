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

LOAD_DATE = Datetime.now()  # e.g. datetime.datetime(2025, 4, 25, 12, 5, 35, 882529)
LOAD_DATE_YEAR = str(LOAD_DATE.year)  # e.g. "2025"
LOAD_DATE_MONTH = f"0{LOAD_DATE.month}"[-2:]  # e.g. "04"
LOAD_DATE_DAY = f"0{LOAD_DATE.day}"[-2:]  # e.g. "25"
LOAD_DATE_TIME = (
    str(load_date.time()).replace(":", "").replace(".", "")
)  # e.g. 111146605639
FILE_LOAD_DATE = (
    LOAD_DATE_YEAR + LOAD_DATE_MONTH + LOAD_DATE_DAY + LOAD_DATE_TIME
)  # e.g. 20250425111146605639

FILE_NAME = f"{FILE_LOAD_DATE}_sm_sns_messages.csv"  # e.g. 20250425111146605639_sm_sns_messages.csv
LOCAL_DEST = rf"/tmp/{FILE_NAME}"
S3_OBJECT_KEY = rf"{LOAD_DATE_YEAR}/{LOAD_DATE_MONTH}/{FILE_NAME}"
S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "")


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    retain_source(event)
    for record in event["Records"]:
        process_message(record)
    logger.info(
        f"Uploading local file to S3 -> Bucket:{S3_BUCKET_NAME}  Location:{S3_OBJECT_KEY}"
    )
    s3.upload_file(Filename=LOCAL_DEST, Bucket=S3_BUCKET_NAME, Key=S3_OBJECT_KEY)
    clean_up_tmp(LOCAL_DEST)


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
            logger.info("Appending row to local file")
            append_new_rows_to_local(new_data_row)
            logger.info("New row appended to local file")
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e


def clean_up_tmp(local_file_name: str) -> None:
    logger.info(f"Cleaning up local tmp directory: {local_file_name}")
    if os.path.isfile(local_file_name):
        os.remove(local_file_name)
        logger.info(f"Removed from local: {local_file_name}")
    else:
        logger.info(f"File does not exist: {local_file_name}")
    return


def append_new_rows_to_local(new_data_row: list[object]) -> None:
    with open(LOCAL_DEST, "a") as f:
        writer = csv.writer(f)
        writer.writerow(new_data_row)
    return


def retrieve_payload_and_determine_length(payload_key: str, payload_bucket: str) -> str:
    local_file_name = r"/tmp/payload.json"
    logger.info(
        f"Downloading  {payload_key}  from  {payload_bucket}  to  {local_file_name}"
    )
    s3.download_file(Bucket=payload_bucket, Key=payload_key, Filename=local_file_name)
    with open(local_file_name, "r") as f:
        payload_data = str(json.load(f))
    payload_length = str(len(payload_data))
    clean_up_tmp(local_file_name)
    return payload_length


def retain_source(source: dict) -> None:
    local_file_name = rf"/tmp/{FILE_LOAD_DATE}_source.json"
    with open(local_file_name, "w") as f:
        json.dump(source, f)
    logger.info(
        f"Uploading source to {LOAD_DATE_YEAR}/{LOAD_DATE_MONTH}/{FILE_LOAD_DATE}_sm_sns_source.json  in  {S3_BUCKET_NAME}"
    )
    s3.upload_file(
        Filename=local_file_name,
        Bucket=S3_BUCKET_NAME,
        Key=rf"{LOAD_DATE_YEAR}/{LOAD_DATE_MONTH}/{FILE_LOAD_DATE}_sm_sns_source.json",
    )
    clean_up_tmp(local_file_name)
    return
