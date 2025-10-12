import os

import requests
import pandas as pd
from sqlalchemy import create_engine


POSTGRES_HOST = os.environ["POSTGRES_HOST"]
POSTGRES_PORT = os.environ["POSTGRES_PORT"]
POSTGRES_USER = os.environ["POSTGRES_USER"]
POSTGRES_PASSWD = os.environ["POSTGRES_PASSWORD"]
POSTGRES_DB = os.environ["POSTGRES_DB"]

URL: str = "https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_finals"
headers: dict[str, str] = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36'
}
db_connection_str = f"postgresql+psycopg2://{POSTGRES_USER}:{POSTGRES_PASSWD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
engine = create_engine(db_connection_str)

class ErrorStatusCode(Exception):
    pass

def extract():
    print("Extract Starting")
    response = requests.get(URL, headers=headers)

    if response.status_code in [200, 201]:
        dfs = pd.read_html(response.text)
        df = dfs[4]
        print("Extract Completed Successfully!!")
        return df
    else:
        print("Extract Failed!!!")
        raise ErrorStatusCode(f"Status code={response.status_code} instead of 200 or 201")

def load_to_postgres(df: pd.DataFrame, table_name: str = "worldcup_stg"):
    print("Load Starting")
    df.to_sql(
        table_name, 
        engine, 
        if_exists="append", 
        index=False,
        method="multi"
    )
    print("Load Completed Successfully!!")

if __name__ == "__main__":
    df = extract()
    load_to_postgres(df)
