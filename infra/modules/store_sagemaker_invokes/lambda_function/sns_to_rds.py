import ast
import logging
import os
import uuid
from datetime import datetime

import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

rds = boto3.client("rds-data")


def lambda_handler(event, context):
    for record in event["Records"]:
        process_message(record)


def process_message(record):
    try:
        logger.info(f"Starting processing of message to determine contents")
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

        if invocation_status in ["Completed", "Failed"]:
            logger.info(f"Received notification of a {invocation_status} inference")
            sql_statement = (
                f"INSERT INTO inferences (id, "
                f"invocation_status, event_time, received_time, "
                f"endpoint_name, federated_user_id)\n"
                f"VALUES ({inference_id}, {invocation_status}, "
                f"{event_time}, {received_time}, {endpoint_name}, "
                f"{federated_user_id})"
            )

            response = rds.execute_statement(
                resourceArn=os.getenv("SAGEMAKER_DB_ARN"),
                secretArn=os.getenv("SAGEMAKER_DB_SECRET_ARN"),
                sql=sql_statement,
                database="sagemaker",
            )
            logger.info(f"Sent to sagemaker database - response contents: {response}")
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e
