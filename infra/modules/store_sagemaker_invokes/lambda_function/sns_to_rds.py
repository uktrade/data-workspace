import ast
import logging
import os
import uuid
from datetime import datetime

import psycopg

logger = logging.getLogger()
logger.setLevel("INFO")

DATASETS_DB_HOST = os.getenv("DATASETS_DB_HOST")
DATASETS_DB_USERNAME = os.getenv("DATASETS_DB_USERNAME")
DATASETS_DB_PASSWORD = os.getenv("DATASETS_DB_PASSWORD")
DATASETS_DB_NAME = os.getenv("DATASETS_DB_NAME")
DATASETS_DB_PORT = os.getenv("DATASETS_DB_PORT")
DATASETS_DB_ARN = os.getenv("DATASETS_DB_ARN")
DATASETS_DB_SECRET_ARN = os.getenv("DATASETS_DB_SECRET_ARN")


def lambda_handler(event, context):
    for record in event["Records"]:
        process_message(record)


def process_message(record):
    try:
        logger.info("Starting processing of message to determine contents")
        message_str = str(record["Sns"]["Message"])
        message_dict = ast.literal_eval(message_str)
        invocation_status = str(message_dict["invocationStatus"])
        endpoint_name = str(message_dict["requestParameters"]["endpointName"])
        federated_user_id = (
            str(message_dict["requestParameters"]["inputLocation"])
            .split("/user/federated/")[1]
            .split("/")[0]
        )
        inference_id = uuid.UUID(str(message_dict["inferenceId"]))
        event_time = datetime.strptime(
            str(message_dict["eventTime"]), "%Y-%m-%dT%H:%M:%S.%f%z"
        )
        received_time = datetime.strptime(
            str(message_dict["receivedTime"]), "%Y-%m-%dT%H:%M:%S.%f%z"
        )
        # TODO: add number of characters

        if invocation_status in ["Completed", "Failed"]:
            logger.info(f"Received notification of a {invocation_status} inference")
            sql_statement = (
                f"INSERT INTO inferences (id, "
                f"invocation_status, event_time, received_time, "
                f"endpoint_name, federated_user_id)\n"
                f"VALUES ({inference_id}, {invocation_status}, "
                f"{event_time}, {received_time}, {endpoint_name}, "
                f"{federated_user_id});"
            )
            with psycopg.connect(
                f"dbname={DATASETS_DB_NAME} user={DATASETS_DB_USERNAME} password={DATASETS_DB_PASSWORD} host={DATASETS_DB_HOST} port={DATASETS_DB_PORT}"
            ) as conn:
                with conn.cursor() as cur:
                    cur.execute(sql_statement)
                    conn.commit()

            logger.info("Sent to sagemaker database")
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e
