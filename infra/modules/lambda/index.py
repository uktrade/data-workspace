import boto3
import gzip
import json
import base64
from io import BytesIO
import os
from datetime import datetime, timezone

s3 = boto3.client("s3")
bucket_name = os.environ["S3_BUCKET_NAME"]



def lambda_handler(event, context):
    try:
        # Validate the payload structure
        if "awslogs" not in event or "data" not in event["awslogs"]:
            raise ValueError("Invalid payload format: missing 'awslogs' or 'data' key")

        # Decode and decompress the CloudWatch Logs payload
        compressed_payload = base64.b64decode(event["awslogs"]["data"])
        decompressed_payload = gzip.GzipFile(fileobj=BytesIO(compressed_payload)).read()
        log_events = json.loads(decompressed_payload)

        # Extract log group, log stream, and log events
        log_group = log_events.get("logGroup", "unknown-group")
        log_stream = log_events.get("logStream", "unknown-stream")
        log_messages = [
            {
                "timestamp": event["timestamp"],
                "message": event["message"]
            } for event in log_events.get("logEvents", [])
        ]

        # Create a timestamped S3 key
        timestamp = datetime.now(timezone.utc).strftime("%Y/%m/%d/%H-%M-%S")
        s3_key = f"logs/{log_group}/{log_stream}/{timestamp}.json"

        # Upload the log messages to S3 as a JSON file
        s3.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=json.dumps(log_messages),
            ContentType="application/json"
        )

        print(f"Logs successfully uploaded to S3: {s3_key}")
        return {
            "statusCode": 200,
            "body": json.dumps("Logs successfully uploaded to S3.")
        }
    except ValueError as ve:
        print(f"Validation error: {str(ve)}")
        return {
            "statusCode": 400,
            "body": json.dumps(f"Validation Error: {str(ve)}")
        }
    except Exception as e:
        print(f"Error processing logs: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error: {str(e)}")
        }
