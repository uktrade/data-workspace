#!/bin/bash

export AIRFLOW_CONN_DATASETS_DB=$(aws secretsmanager get-secret-value --region eu-west-2 --secret-id ${secret_name}/data-infrastructure | jq -r '.SecretString | fromjson | .AIRFLOW_CONN_DATASETS_DB')
