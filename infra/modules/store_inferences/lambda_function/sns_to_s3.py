import csv
import json
import logging
import os
from datetime import datetime as Datetime
from typing import Any

import boto3

"""
Download source     Upload source      Extract relevant data     Upload csv to
data to local   --> file to bronze --> from source and store --> silver S3
tmp folder          S3 location        in local csv              location
"""

logger = logging.getLogger()
logger.setLevel("INFO")

s3 = boto3.client("s3")
S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "")
BRONZE_S3_OBJECT_KEY = r"bronze/sm_sns_messages/{LOAD_DATE_YEAR}/{LOAD_DATE_MONTH}/{FILE_LOAD_DATE}_sm_sns_source.json"  # noqa: E501
SILVER_S3_OBJECT_KEY = r"silver/sm_sns_messages/{LOAD_DATE_YEAR}/{LOAD_DATE_MONTH}/{FILE_LOAD_DATE}_sm_sns_messages.csv"  # noqa: E501


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    load_date = Datetime.now().strftime("%Y%m%d%H%M%S%f")
    # Load bronze
    load_bronze(event, load_date)
    # Process records into csv
    for record in event["Records"]:
        process_message(record, load_date)
    # Load silver
    load_silver(load_date)


def format_path(path: str, load_date: str) -> str:
    load_date_year = load_date[:4]  # e.g. "2025"
    load_date_month = load_date[4:6]  # e.g. "04"
    formatted_path = path.format(
        LOAD_DATE_YEAR=load_date_year,
        LOAD_DATE_MONTH=load_date_month,
        FILE_LOAD_DATE=load_date,
    )
    return formatted_path


def clean_up_tmp(local_file_name: str) -> None:
    logger.info(f"Cleaning up local tmp directory: {local_file_name}")
    if os.path.isfile(local_file_name):
        os.remove(local_file_name)
        logger.info(f"Removed from local: {local_file_name}")
    else:
        logger.info(f"File does not exist: {local_file_name}")
    return


def load_bronze(source: dict[str, Any], load_date: str) -> None:
    local_dest = rf"/tmp/{load_date}_source.json"
    with open(local_dest, "w") as f:
        json.dump(source, f)
    bronze_s3_key = format_path(BRONZE_S3_OBJECT_KEY, load_date)
    logger.info(f"Uploading json source to {bronze_s3_key}  in  {S3_BUCKET_NAME}")
    s3.upload_file(
        Filename=local_dest,
        Bucket=S3_BUCKET_NAME,
        Key=bronze_s3_key,
    )
    clean_up_tmp(local_dest)
    return


def append_new_rows_to_local(new_data_row: list[object], load_date: object) -> None:
    local_dest = rf"/tmp/{load_date}_source.csv"
    with open(local_dest, "a") as f:
        writer = csv.writer(f)
        writer.writerow(new_data_row)
    return


def retrieve_payload_and_determine_length(
    payload_key: str, payload_bucket: str, inference_id: str
) -> str:
    local_file_name = rf"/tmp/{inference_id}_payload.json"
    logger.info(
        f"Downloading  {payload_key}  from  {payload_bucket}  to  {local_file_name}"
    )
    s3.download_file(Bucket=payload_bucket, Key=payload_key, Filename=local_file_name)
    with open(local_file_name, "r") as f:
        payload_data = str(json.load(f))
        logger.info(payload_data)
    payload_length = str(len(payload_data))
    clean_up_tmp(local_file_name)
    return payload_length


def process_message(record: dict[str, Any], load_date: str) -> None:
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
            input_payload_key,
            input_payload_bucket,
            inference_id,
        )
        logger.info(f"New payload_length {payload_length}")
        load_date_formatted = Datetime.strptime(load_date, "%Y%m%d%H%M%S%f")
        new_data_row = [
            inference_id,
            federated_user_id,
            invocation_status,
            event_time,
            received_time,
            endpoint_name,
            payload_length,
            load_date_formatted,
        ]
        logger.info(f"New data row is {new_data_row}")
        if invocation_status in ["Completed", "Failed"]:
            logger.info("Appending row to local file")
            append_new_rows_to_local(new_data_row, load_date)
            logger.info("New row appended to local file")
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e


def load_silver(load_date: str) -> None:
    silver_s3_object_key = format_path(SILVER_S3_OBJECT_KEY, load_date)
    logger.info(f"Uploading csv to {silver_s3_object_key}  in  {S3_BUCKET_NAME}")
    local_dest = rf"/tmp/{load_date}_source.csv"
    s3.upload_file(Filename=local_dest, Bucket=S3_BUCKET_NAME, Key=silver_s3_object_key)
    clean_up_tmp(local_dest)
    return
