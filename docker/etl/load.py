import os

import pandas as pd
from sqlalchemy import create_engine

POSTGRES_HOST = os.environ["PG_HOST"]
POSTGRES_PORT = os.environ["PG_PORT"]
POSTGRES_USER = os.environ["PG_USER"]
POSTGRES_PASSWD = os.environ["PG_PASSWD"]
POSTGRES_DB = os.environ["PG_DB"]

db_connection_str = f"postgresql+psycopg2://{POSTGRES_USER}:{POSTGRES_PASSWD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
engine = create_engine(db_connection_str)

def load(df: pd.DataFrame, table_name: str = "world_cup"):
    print("Load Starting")
    df.to_sql(table_name, engine, if_exists="replace", index=False)
    print("Load Completed Successfully!!")
