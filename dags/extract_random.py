import random
from datetime import datetime

import awswrangler as wr
import boto3
import pandas as pd
from airflow.models import Variable
from faker import Faker

fake = Faker()
stock_symbols = ["AAPL", "GOOG", "MSFT", "AMZN", "TSLA"]


# Generate between 500,000 and 1,000,000 fake stock records
def generate_all_records():
    record_count = random.randint(500_000, 1_000_000)
    records = []
    for i in range(record_count):
        symbol = random.choice(stock_symbols)
        name = fake.name()
        account_name = fake.name()
        quantity = random.randint(1, 1000)
        price = round(random.uniform(50.0, 1500.0), 2)
        total_cost = round(quantity * price, 2)
        txn_id = fake.uuid4()
        payment_date = datetime.now().strftime("%Y-%m-%d")

        one_record = {
            "symbol": symbol,
            "name": name,
            "account_name": account_name,
            "quantity": quantity,
            "price": price,
            "total_cost": total_cost,
            "Transaction Type": "BUY",
            "txn_id": txn_id,
            "payment_date": payment_date,
        }
        records.append(one_record)
    # Convert to DataFrame and return
    df = pd.DataFrame(records)
    print("DataFrame created!")
    print(df)
    return df


# Load AWS credentials from Airflow Variables
def uploading_df_to_s3():
    df = generate_all_records()
    access_key = Variable.get("ACCESS_KEY").strip()
    secret_key = Variable.get("SECRET_KEY").strip()

    session = boto3.Session(
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name="us-east-1",
    )

    date_str = datetime.today().strftime("%Y-%m-%d")
    path = "s3://airflow-redshift-random/randomized-redshift/" f"{date_str}.parquet"
    # Upload DataFrame to S3 as Parquet
    wr.s3.to_parquet(df=df, path=path, dataset=False, boto3_session=session)
    return df
