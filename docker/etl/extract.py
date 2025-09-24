import requests
import pandas as pd

URL: str = "https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_finals"
headers: dict[str, str] = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36'
}

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
