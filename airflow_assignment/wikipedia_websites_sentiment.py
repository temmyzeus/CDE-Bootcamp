import os
from datetime import timedelta
from urllib.parse import urlparse

from airflow.sdk import DAG
from airflow.exceptions import AirflowSkipException
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.amazon.aws.transfers.local_to_s3 import LocalFilesystemToS3Operator
from airflow.providers.standard.operators.python import (
    BranchPythonOperator,
    PythonOperator
)
from pendulum import datetime, DateTime

# TMP_LOAD_PARENT_DIR
TMP_LOAD_DIR: str = "/tmp/wikimedia_pageviews_data_dumps"
TMP_LOAD_DIR_DECOMPRESED: str = os.path.join(TMP_LOAD_DIR, "decompressed")

DATA_DUMP_FILE_URL: str = (
    "https://dumps.wikimedia.org/other/pageviews/"
    "{{ logical_date.year }}/"
    "{{ logical_date.format('YYYY-MM') }}/"
    "pageviews-"
    "{{ logical_date.format('YYYYMMDD-HH') }}0000"
    ".gz"
)

def get_filename_from_url(url: str) -> str:
    return os.path.basename(url)

def construct_download_filepath(filename: str, parent_dir: str = TMP_LOAD_DIR) -> str:
    return os.path.join(parent_dir, filename)

def construct_download_filepath_from_url(url: str) -> str:
    return construct_download_filepath(
        get_filename_from_url(url)
    )

def check_is_url(url: str) -> bool:
    parse_result = urlparse(DATA_DUMP_FILE_URL)
    print(parse_result)
    if all([parse_result.scheme, parse_result.netloc]):
        return True
    else:
        False

def _check_if_file_exists(filepath: str) -> bool:

    print(f"Checking if file: {filepath} exists")

    if check_is_url(filepath):
        print(f"File: {filepath} is a URL")
        filepath = os.path.join(
            TMP_LOAD_DIR,
            os.path.basename(filepath)
        )

    if os.path.exists(filepath):
        if os.path.isfile(filepath):
            print(f"File: {filepath} is an existing file")
            return True
    print(f"File: {filepath} does not exist")
    return False

def check_data_dump_existing_on_local(filepath: str):
    if _check_if_file_exists(filepath):
        return "validate_full_data_download"
    return "get_wikipedia_data_dump"

def _validate_full_data_download(url: str):
    download_file_path = construct_download_filepath_from_url(url)
    download_file_size = os.path.getsize(download_file_path)

    print(f"Download file size for file: {download_file_path!r} = {download_file_size} bytes")

    VALID_FILE_SIZE_THRESHOLD: int = 500

    if download_file_size < VALID_FILE_SIZE_THRESHOLD:
        raise ValueError(f"Size for the Downloaded file: {download_file_path!r} less then {VALID_FILE_SIZE_THRESHOLD} bytes")
    
downloaded_data_dump_filepath = construct_download_filepath_from_url(DATA_DUMP_FILE_URL)
decompressed_data_dump_filepath = os.path.join(
    TMP_LOAD_DIR_DECOMPRESED,
    os.path.basename(downloaded_data_dump_filepath).replace(".gz", ".txt")
)

with DAG(
    dag_id="wikipedia_websites_sentiment",
    start_date=datetime(2025, 10, 20),
    schedule="@hourly",
    catchup=False,
    default_args={
        "depends_on_past": False,
        "retries": 5,
        "retry_delay": timedelta(minutes=5)
    }
):
    
    make_tmp_dir_if_not_exists = BashOperator(
        task_id="make_tmp_dir_if_not_exists",
        bash_command=f"mkdir -p {TMP_LOAD_DIR} {TMP_LOAD_DIR_DECOMPRESED}"
    )

    get_data_dump_size = BashOperator(
        task_id="get_data_dump_size",
        bash_command=f"curl --head " + DATA_DUMP_FILE_URL + " | awk '/Content-Length:/ {print $2}'"
    )

    check_data_dump_existing_on_local_branch=BranchPythonOperator(
        task_id="check_data_dump_existing_on_local_branch",
        python_callable=check_data_dump_existing_on_local,
        op_kwargs={
            "filepath": DATA_DUMP_FILE_URL
        }
    )

    get_wikipedia_data_dump = BashOperator(
        task_id="get_wikipedia_data_dump",
        bash_command=f"curl -O -L --output-dir {TMP_LOAD_DIR} " + DATA_DUMP_FILE_URL
    )

    # Check data packets is same size as already exisitng file

    validate_full_data_download=PythonOperator(
        task_id="validate_full_data_download",
        python_callable=_validate_full_data_download,
        op_kwargs={
            "url": DATA_DUMP_FILE_URL
        },
        trigger_rule="none_failed"
    )

    upload_to_object_store = LocalFilesystemToS3Operator(
        task_id="upload_to_object_store",
        filename=construct_download_filepath_from_url(DATA_DUMP_FILE_URL),
        dest_key=os.path.join(
            "pageviews_data_dumps",
            get_filename_from_url(DATA_DUMP_FILE_URL)
        ),
        dest_bucket="wikimedia",
        replace=True,
        aws_conn_id="minio_conn",
        verify=False
    )

    decompress_data_dump_file = BashOperator(
        task_id="decompress_data_dump_file",
        bash_command=f"gzip -dkc {downloaded_data_dump_filepath} > {decompressed_data_dump_filepath}"
    )
    
    create_staging_table = SQLExecuteQueryOperator(
        task_id="create_staging_table",
        sql="""
            CREATE TABLE IF NOT EXISTS PageViews_STG (
                Domain_Code TEXT,
                Page_Title TEXT,
                View_Count BIGINT,
                Response_Size_Bytes BIGINT
            );
            """,
        conn_id="postgres_default",
        database="CoreSentimentDB",
        show_return_value_in_logs=True
    )

    load_to_staging = SQLExecuteQueryOperator(
        task_id="load_to_staging",
        sql="""
            \COPY PageViews_STG FROM %(load_data_file_path)s
            (
                DELIMITER ' '
            );
            """,
        conn_id="postgres_default",
        database="CoreSentimentDB",
        show_return_value_in_logs=True,
        parameters={
            "load_data_file_path": decompressed_data_dump_filepath
        },
        hook_params={"enable_log_db_messages": True}
    )

    # load_to_staging = BashOperator(
    #     task_id="load_to_staging",
    #     bash_command=f"psql -h {} -p  -U {}"
    # )

    drop_decompressed_data_dump_file = BashOperator(
        task_id="drop_decompressed_data_dump_file",
        bash_command=f"rm {decompressed_data_dump_filepath}"
    )

    make_tmp_dir_if_not_exists >> get_data_dump_size >> check_data_dump_existing_on_local_branch >> [get_wikipedia_data_dump, validate_full_data_download]
    get_wikipedia_data_dump >> validate_full_data_download >> upload_to_object_store >> decompress_data_dump_file >> create_staging_table >> load_to_staging >> drop_decompressed_data_dump_file
