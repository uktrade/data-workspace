import boto3
import ast

def lambda_handler(event, context):
    for record in event['Records']:
        process_message(record)
    print(f"sns message processed")

def process_message(record):
    try:
        message_str = record['Sns']['Message']
        s3 = boto3.resource('s3')
        message_dict = ast.literal_eval(message_str)
        print(message_dict)

        sagemaker_endpoint_name = message_dict["requestParameters"]["endpointName"]
        input_file_uri = message_dict["requestParameters"]["inputLocation"]
        input_file_bucket = input_file_uri.split("/user/federated/")[0].split("s3://")[1]
        federated_user_id = input_file_uri.split("/user/federated/")[1].split("/")[0]

        output_file_uri = message_dict["responseParameters"]["outputLocation"]
        output_file_bucket = output_file_uri.split("https://")[1].split("/")[0].split(".s3.eu-west-2.amazonaws.com")[0]
        output_file_key = output_file_uri.split("https://")[1].split("/")[1]

        copy_source = {
            'Bucket': output_file_bucket,
            'Key': output_file_key
            }
        s3_filepath_output = f"user/federated/{federated_user_id}/sagemaker/outputs/{output_file_key}"
        s3.meta.client.copy(copy_source, input_file_bucket, s3_filepath_output)

        print(f"User {federated_user_id} called Sagemaker endpoint {sagemaker_endpoint_name} and the output file key was {s3_filepath_output}")

    except Exception as e:
        print("An error occurred")
        raise e