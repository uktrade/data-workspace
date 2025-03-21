import ast
import logging
from typing import Any

import boto3
from mypy_boto3_s3.type_defs import CopySourceTypeDef

logger = logging.getLogger()
logger.setLevel("INFO")
s3 = boto3.resource("s3")


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    for record in event["Records"]:
        process_message(record)


def process_message(record: dict[str, Any]) -> None:
    try:
        message_str = record["Sns"]["Message"]
        message_dict = ast.literal_eval(message_str)

        invocation_status = message_dict["invocationStatus"]
        endpoint_name = message_dict["requestParameters"]["endpointName"]
        input_file_uri = message_dict["requestParameters"]["inputLocation"]
        input_file_bucket = input_file_uri.split("/user/federated/")[0].split("s3://")[
            1
        ]
        federated_user_id = input_file_uri.split("/user/federated/")[1].split("/")[0]
        inference_id = message_dict["inferenceId"]
        logging.info(f"Invocation status: {invocation_status}")
        if invocation_status == "Completed":
            logger.info(f"Now processing a completed inference from {endpoint_name}")
            output_file_uri = message_dict["responseParameters"]["outputLocation"]
            output_file_bucket = (
                output_file_uri.split("https://")[1]
                .split("/")[0]
                .split(".s3.eu-west-2.amazonaws.com")[0]
            )
            output_file_key = output_file_uri.split("https://")[1].split("/")[1]
            inference_id = message_dict["inferenceId"]

            copy_source = CopySourceTypeDef(
                {"Bucket": output_file_bucket, "Key": output_file_key}
            )
            s3_filepath_output = f"user/federated/{federated_user_id}/sagemaker/outputs/{inference_id}.out"  # noqa: E501
            s3.meta.client.copy(copy_source, input_file_bucket, s3_filepath_output)
            logger.info(
                f"Output from {endpoint_name} with id:{inference_id} "
                "moved to user's files"
            )
        elif invocation_status == "Failed":
            logger.info(f"Now processing a failed inference from {endpoint_name}")
            error_message = message_dict["responseBody"]["content"]
            s3_filepath_output = f"user/federated/{federated_user_id}/sagemaker/errors/{inference_id}.out"  # noqa: E501
            s3.meta.client.put_object(
                Body=str(error_message).encode("unicode-escape"),
                Bucket=input_file_bucket,
                Key=s3_filepath_output,
            )
            logger.info(
                f"Output from {endpoint_name} with id:{inference_id} failed and "
                "the error output was stored to user's files for debugging"
            )
        else:
            logger.error(f"Unexpected invocation_status {invocation_status}")
    except Exception as e:
        logger.error(e)
        raise e
