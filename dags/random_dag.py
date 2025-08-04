from datetime import timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator
from airflow.utils.dates import days_ago
from extract_random import generate_all_records, uploading_df_to_s3

# AWS and Redshift connection info
AWS_CONN_ID = "aws_conn"
REDSHIFT_CONN_ID = "redshift"
S3_BUCKET = "airflow-redshift-random"
S3_KEY = "randomized-redshift/{{ ds }}/data.parquet"
REDSHIFT_DATABASE = "mydb"
REDSHIFT_SCHEMA = "public"
REDSHIFT_TABLE = "transactions"

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="chiz_daily_to_redshift",
    default_args=default_args,
    start_date=days_ago(1),
    schedule_interval="@daily",
    catchup=False,
    description="Generate and load daily transactions to Redshift",
) as dag:

    generate_transaction_data = PythonOperator(
        task_id="generate_transaction_data",
        python_callable=generate_all_records,
    )

    write_to_s3 = PythonOperator(
        task_id="upload_to_s3",
        python_callable=uploading_df_to_s3,
    )

    load_to_redshift = S3ToRedshiftOperator(
        task_id="load_to_redshift",
        schema=REDSHIFT_SCHEMA,
        table=REDSHIFT_TABLE,
        s3_bucket=S3_BUCKET,
        s3_key=S3_KEY,
        redshift_conn_id=REDSHIFT_CONN_ID,
        aws_conn_id=AWS_CONN_ID,
        copy_options=["FORMAT AS PARQUET"],
    )

    generate_transaction_data >> write_to_s3 >> load_to_redshift
