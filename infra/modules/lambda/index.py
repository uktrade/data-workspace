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
        for record in event["records"]:
            compressed_payload = base64.b64decode(record["data"])
            decompressed_payload = gzip.GzipFile(fileobj=BytesIO(compressed_payload)).read()
            log_events = json.loads(decompressed_payload)

            log_group = log_events.get("logGroup", "unknown-group")
            log_stream = log_events.get("logStream", "unknown-stream")

            timestamp = datetime.now(timezone.utc).strftime("%Y/%m/%d/%H-%M-%S")
            s3_key = f"logs/{log_group}/{log_stream}/{timestamp}.json"

            s3.put_object(
                Bucket=bucket_name,
                Key=s3_key,
                Body=json.dumps(log_events),
                ContentType="application/json"
            )

        return {
            "statusCode": 200,
            "body": json.dumps("Logs successfully uploaded to S3.")
        }
    except Exception as e:
        print(f"Error processing logs: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error: {str(e)}")
        }
