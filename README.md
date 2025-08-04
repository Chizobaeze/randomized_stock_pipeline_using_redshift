
# randomized_stock_pipeline
This project simulates transactional data for a fictional stock market to monitor the daily value of various stocks. It then builds a complete data pipeline that moves the generated data from local simulation to analytics-ready storage in Amazon Redshift.
The pipeline is designed to mirror a real-world scenario, where stock data is produced in large volumes, stored in the cloud, processed, and analyzed—all using automated, scalable tools.

## Built With
#### Apache Airflow – Orchestrates the end-to-end pipeline with daily scheduled jobs
#### Python + Faker + pandas – Simulates up to 1 million realistic stock transactions per run
#### AWS S3 – Serves as the raw data lake for storing daily Parquet files
#### Amazon Redshift – Final destination for analytical queries and dashboards
#### Terraform – Provisions cloud infrastructure like S3 buckets and Redshift clusters
#### Docker – Used to containerize and run Airflow locally for development/testing

