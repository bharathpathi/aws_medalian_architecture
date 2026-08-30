from datetime import timedelta
import pendulum
from airflow.sdk import dag, task, Asset
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

AWS_CONN_ID = "aws_default"
PROJECT_BUCKET = "aws-medalion-project"
REDSHIFT_DATABASE = "cdw_opt_silver"
REDSHIFT_WORKGROUP_NAME = "server-less-medalion"

SCRIPTS = {
    "run_i_s_providers": "Dags/02.silver_layer/scripts/02.load_I_s_providers.sql",
    "run_i_providers_to_providers": "Dags/02.silver_layer/scripts/02.load_I_S_PROVIDERS_to_load_S_PROVIDERS.sql",
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

SILVER_PROVIDER_ASSET = Asset("silver_provider")


@dag(
    dag_id="silver_PROVIDER_load",
    default_args=default_args,
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    max_active_runs=1,
    tags=["redshift", "silver", "providers"],
)
def silver_PROVIDER_load():
    @task
    def fetch_sql(sql_key: str) -> str:
        hook = S3Hook(aws_conn_id=AWS_CONN_ID)
        return hook.read_key(key=sql_key, bucket_name=PROJECT_BUCKET)

    script_items = list(SCRIPTS.items())
    last_index = len(script_items) - 1

    redshift_tasks = [
        RedshiftDataOperator(
            task_id=task_id,
            database=REDSHIFT_DATABASE,
            workgroup_name=REDSHIFT_WORKGROUP_NAME,
            sql=fetch_sql(sql_key),
            aws_conn_id=AWS_CONN_ID,
            deferrable=True,
            wait_for_completion=True,
            outlets=[SILVER_PROVIDER_ASSET] if i == last_index else None,
        )
        for i, (task_id, sql_key) in enumerate(script_items)
    ]

    for upstream, downstream in zip(redshift_tasks, redshift_tasks[1:]):
        upstream >> downstream


silver_PROVIDER_load()