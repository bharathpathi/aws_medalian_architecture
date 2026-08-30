from datetime import timedelta
import pendulum
from airflow.sdk import dag, task, Asset
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator

AWS_CONN_ID = "aws_default"
PROJECT_BUCKET = "aws-medalion-project"
REDSHIFT_DATABASE = "cdw_opt_gold"  # update if gold reads/writes via a different Redshift database
REDSHIFT_WORKGROUP_NAME = "server-less-medalion"

SCRIPTS = {
    "run_gold_load": "Dags/03.gold_layer/scripts/05.load_data_to_gold.sql",
}

default_args = {
    "owner": "bharath",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=30),
    "email_on_failure": True,
    "execution_timeout": timedelta(minutes=30),
}

# The 4 silver assets this DAG waits on — must match the outlets
# declared in each silver DAG's final task.
SILVER_PROVIDER_ASSET = Asset("silver_provider")
SILVER_PAYMENTS_ASSET = Asset("silver_payments")
SILVER_MEMBERS_ASSET = Asset("silver_members")
SILVER_CLAIM_ASSET = Asset("silver_claim")


@dag(
    dag_id="gold_load",
    default_args=default_args,
    schedule=[
        SILVER_PROVIDER_ASSET,
        SILVER_PAYMENTS_ASSET,
        SILVER_MEMBERS_ASSET,
        SILVER_CLAIM_ASSET,
    ],
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    max_active_runs=1,
    tags=["redshift", "gold"],
)
def gold_load():
    @task
    def fetch_sql(sql_key: str) -> str:
        hook = S3Hook(aws_conn_id=AWS_CONN_ID)
        return hook.read_key(key=sql_key, bucket_name=PROJECT_BUCKET)

    script_items = list(SCRIPTS.items())

    redshift_tasks = [
        RedshiftDataOperator(
            task_id=task_id,
            database=REDSHIFT_DATABASE,
            workgroup_name=REDSHIFT_WORKGROUP_NAME,
            sql=fetch_sql(sql_key),
            aws_conn_id=AWS_CONN_ID,
            deferrable=True,
            wait_for_completion=True,
        )
        for task_id, sql_key in script_items
    ]

    for upstream, downstream in zip(redshift_tasks, redshift_tasks[1:]):
        upstream >> downstream


gold_load()