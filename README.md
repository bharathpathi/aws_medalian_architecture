# aws_medalian_architecture
architecture diagram:
<img width="817" height="442" alt="image" src="https://github.com/user-attachments/assets/42662cf2-317d-40b7-923f-d321002fdb6f" />



Here's the project starting from the point that's actually implemented — data already sitting in the S3 raw landing zone:

Bronze layer (S3 + Iceberg)

Raw JSON lands in S3 as Parquet in the landing zone. From there:

An AWS Glue Crawler scans that raw S3 data and infers/updates the schema
The schema gets registered in the Glue Data Catalog
Athena queries the cataloged data to validate and process it
Validated records get written into Iceberg tables as the bronze layer — each Iceberg table has a paired quarantine/error table; if any rows fail validation and land in quarantine, the job fails fast instead of quietly loading bad or partial data downstream

Silver layer (Redshift)

Once bronze is ready, 4 parallel Airflow DAGs running on MWAA each pick up one entity (members, providers, claims, payments) and run SQL against Redshift via the Redshift Data API. This is where the data gets cleaned, deduplicated, and merged using SCD1/SCD2 logic — SCD1 for entities where you only care about the current state, SCD2 for entities where you need to preserve history of changes over time.

Gold layer (Redshift)

Once all 4 silver DAGs have finished, a separate Gold DAG fires automatically — not on a schedule, but triggered by Airflow Assets: each silver DAG's last task emits an asset update, and the gold DAG watches all 4 assets, only running once every one of them has fired since its last run. It then builds a denormalized fact table in Redshift by joining the 4 silver tables together — the final layer, ready for reporting/analytics.

The one thing not yet built: everything to the left of S3 in this diagram — the Python producer, Kinesis Data Streams, Kinesis Firehose, and the Lambda transform that would automatically push JSON events into that S3 landing zone. Right now data reaches S3 through an interim method; that ingestion path is the next piece to build.
