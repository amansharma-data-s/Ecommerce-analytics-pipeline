import os 
import glob
import pandas as pd
from sqlalchemy import create_engine

script_dir = os.path.dirname(os.path.abspath(__file__))
Data_folder = os.path.join(script_dir,"Data","*.csv")

csv_files = glob.glob(Data_folder)

dataset ={}
for file_path in csv_files:
    file_name = os.path.basename(file_path)
    if file_name != "olist_orders_dataset.csv":
        dataset[file_name] = pd.read_csv(file_path)

edited_file = os.path.join(script_dir,"orders_cleaned.csv")
dataset["orders"] = pd.read_csv(edited_file)

#print(list(dataset.keys()))

sql_adres ="LENOVO-8L6GJFR0\\SQLEXPRESS"
database = "E_commerce (brazill)"
driver ="ODBC+Driver+18+for+SQL+Server"

engine = create_engine(f"mssql+pyodbc://@{sql_adres}/{database}?driver={driver}&trusted_connection=yes&TrustServerCertificate=yes")

for table_name, df in dataset.items():
    df.to_sql(table_name.removeprefix("olist_").removesuffix("_dataset.csv"),engine,if_exists ="replace",index=False)

