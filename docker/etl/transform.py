import numpy as np
import pandas as pd


def transform(df: pd.DataFrame) -> pd.DataFrame:
    print("Transform Starting")
    df["Years won"] = df["Years won"].replace(
        "—",
        np.nan,
        inplace=False
    )
    df["Years runners-up"] = df["Years runners-up"].replace(
        "—",
        np.nan,
        inplace=False
    )
    print("Transform Completed!!!")
    return df
