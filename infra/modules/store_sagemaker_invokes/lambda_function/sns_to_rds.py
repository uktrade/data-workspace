import ast
import logging
import os
from datetime import datetime as Datetime
from typing import Any

import boto3
import psycopg

logger = logging.getLogger()
logger.setLevel("INFO")
s3 = boto3.resource("s3")

DATASETS_DB_HOST = os.getenv("DATASETS_DB_HOST")
DATASETS_DB_USERNAME = os.getenv("DATASETS_DB_USERNAME")
DATASETS_DB_PASSWORD = os.getenv("DATASETS_DB_PASSWORD")
DATASETS_DB_NAME = os.getenv("DATASETS_DB_NAME")
DATASETS_DB_PORT = os.getenv("DATASETS_DB_PORT")


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    for record in event["Records"]:
        process_message(record)


def process_message(record: dict[str, Any]) -> None:
    try:
        logger.info("Starting processing of message to determine contents")
        message_str = str(record["Sns"]["Message"])
        message_dict = ast.literal_eval(message_str)
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
        bucket = input_payload_file.split("s3://")[1].split("/")[0]
        key = "/".join(input_payload_file.split("s3://")[1].split("/")[1:])
        logger.info("Reading payload from s3")
        input_payload_obj = s3.Object(bucket_name=bucket, key=key)
        input_payload_str = input_payload_obj.get()["Body"].read().decode("utf-8")
        n_characters_payload = int(len(input_payload_str))

        if invocation_status in ["Completed", "Failed"]:
            logger.info("Initiating connection to datasets db")
            sql_statement = (
                f"INSERT INTO inferences (id, federated_user_id,"
                f"invocation_status, event_time, received_time, "
                f"n_characters_payload, endpoint_name)\n"
                f"VALUES ('{inference_id}', '{federated_user_id}', "
                f"'{invocation_status}', '{event_time}', '{received_time}', "
                f"'{n_characters_payload}', '{endpoint_name}');"
            )
            with psycopg.connect(
                f"dbname={DATASETS_DB_NAME} user={DATASETS_DB_USERNAME} "
                f"password={DATASETS_DB_PASSWORD} host={DATASETS_DB_HOST} "
                f"port={DATASETS_DB_PORT}"
            ) as conn:
                with conn.cursor() as cur:
                    cur.execute(sql_statement)
                    conn.commit()
            logger.info("Sent data to inferences table")
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e
