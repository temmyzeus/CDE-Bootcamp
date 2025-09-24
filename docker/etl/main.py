from extract import extract
from transform import transform
from load import load

if __name__ == "__main__":
    df = extract()
    df_transform = transform(df)
    load(df)
