import ast
import logging
import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
    for record in event["Records"]:
        process_message(record)


def process_message(record):
    try:
        message_str = record["Sns"]["Message"]
        s3 = boto3.resource("s3")
        message_dict = ast.literal_eval(message_str)

        endpoint_name = message_dict["requestParameters"]["endpointName"]
        input_file_uri = message_dict["requestParameters"]["inputLocation"]
        input_file_bucket = input_file_uri.split("/user/federated/")[0].split("s3://")[
            1
        ]
        federated_user_id = input_file_uri.split("/user/federated/")[1].split("/")[0]

        output_file_uri = message_dict["responseParameters"]["outputLocation"]
        output_file_bucket = (
            output_file_uri.split("https://")[1]
            .split("/")[0]
            .split(".s3.eu-west-2.amazonaws.com")[0]
        )
        output_file_key = output_file_uri.split("https://")[1].split("/")[1]

        copy_source = {"Bucket": output_file_bucket, "Key": output_file_key}
        s3_filepath_output = (
            f"user/federated/{federated_user_id}/sagemaker/outputs/{output_file_key}"
        )
        s3.meta.client.copy(copy_source, input_file_bucket, s3_filepath_output)
        logger.info(
            f"Output frm {endpoint_name} with id:{federated_user_id} mvd to usr's files"
        )
    except Exception as e:
        logger.error(e)
        raise e
