import json
import logging
import os
from datetime import datetime as Datetime
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

s3 = boto3.client("s3")
S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "")


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    load_date = Datetime.now().strftime("%Y%m%d%H%M%S%f")
    bronze_s3_key = rf"bronze/sm_sns_messages/{load_date[:4]}/{load_date[4:6]}/{load_date}_sm_sns_source.json"  # noqa: E501
    logger.info(f"Uploading json source to {bronze_s3_key}  in  {S3_BUCKET_NAME}")
    s3.put_object(
        Bucket=S3_BUCKET_NAME,
        Key=bronze_s3_key,
        Body=json.dumps(event),
    )
