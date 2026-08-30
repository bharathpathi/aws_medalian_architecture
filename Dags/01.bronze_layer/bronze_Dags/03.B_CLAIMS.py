from datetime import timedelta

import pendulum
from airflow.sdk import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.operators.athena import AthenaOperator
from airflow.exceptions import AirflowFailException
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

AWS_CONN_ID = "aws_default"
PROJECT_BUCKET = "aws-medalion-project"

SQL_KEY = "Dags/01.bronze_layer/scripts/b_claims.sql"
ATHENA_DATABASE = "opt_transaction_t"
ATHENA_WORKGROUP = "primary"
ATHENA_OUTPUT_LOCATION = "s3://backupaws-queries/"

LANDING_PREFIX = "landing/transactions/claims/"
ARCHIVE_PREFIX = "archive/"

STATEMENT_TASK_IDS = [
    "Truncate_Error_Table",
    "Load_Error_Table",
    "Error_count",
    "Load_Bronze_Table",
]

default_args = {
    "owner": "bharath",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=30),
    "email_on_failure": True,
    "execution_timeout": timedelta(minutes=20),
}


@dag(
    dag_id="b_claims_athena_load",
    default_args=default_args,
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    max_active_runs=1,
    tags=["athena", "transactions", "B_claims"],
)
def b_claims_athena_load():

    @task(retries=2, execution_timeout=timedelta(minutes=5))
    def fetch_and_split_sql() -> dict:
        hook = S3Hook(aws_conn_id=AWS_CONN_ID)
        raw_sql = hook.read_key(key=SQL_KEY, bucket_name=PROJECT_BUCKET)
        statements = [s.strip() for s in raw_sql.split(";")]
        statements = [s for s in statements if s]
        if len(statements) != len(STATEMENT_TASK_IDS):
            raise AirflowFailException(
                f"Expected {len(STATEMENT_TASK_IDS)} statements, found {len(statements)}"
            )
        return dict(zip(STATEMENT_TASK_IDS, statements))

    @task(retries=2, execution_timeout=timedelta(minutes=10))
    def move_files_to_archive():
        hook = S3Hook(aws_conn_id=AWS_CONN_ID)
        keys = hook.list_keys(bucket_name=PROJECT_BUCKET, prefix=LANDING_PREFIX) or []
        keys = [k for k in keys if not k.endswith("/")]

        moved = []
        for key in keys:
            archive_key = ARCHIVE_PREFIX + key[len(LANDING_PREFIX):]
            hook.copy_object(
                source_bucket_key=key,
                dest_bucket_key=archive_key,
                source_bucket_name=PROJECT_BUCKET,
                dest_bucket_name=PROJECT_BUCKET,
            )
            hook.delete_objects(bucket=PROJECT_BUCKET, keys=[key])
            moved.append(archive_key)

        return moved

    sql = fetch_and_split_sql()

    athena_tasks = [
        AthenaOperator(
            task_id=task_id,
            query=sql[task_id],
            database=ATHENA_DATABASE,
            output_location=ATHENA_OUTPUT_LOCATION,
            workgroup=ATHENA_WORKGROUP,
            aws_conn_id=AWS_CONN_ID,
            deferrable=True,
        )
        for task_id in STATEMENT_TASK_IDS
    ]
    trigger_silver_load = TriggerDagRunOperator(
        task_id="trigger_silver_claims_load",
        trigger_dag_id="silver_claim_load",
    )
    sql >> athena_tasks[0]
    for upstream, downstream in zip(athena_tasks, athena_tasks[1:]):
        upstream >> downstream

    athena_tasks[-1] >> move_files_to_archive() >>trigger_silver_load


b_claims_athena_load()