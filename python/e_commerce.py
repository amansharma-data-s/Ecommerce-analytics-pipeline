import os
import glob
import pandas as pd
import numpy as np
import matplotlib as mpl
import seaborn as sb
import sqlalchemy as ssql
import pyodbc as pdc

 #loading tables with correct path 
script_dir = os.path.dirname(os.path.abspath(__file__))
Data_folder = os.path.join(script_dir,"Data","*.csv")
csv_files = glob.glob(Data_folder)

print(f"Found {len(csv_files)} files!")

dataset ={}
for file_path in csv_files:
    file_name = os.path.basename(file_path)
    dataset[file_name] = pd.read_csv(file_path)

#print("loaded tables:",list(dataset.keys()))



#setting correct data types
date_column = ["order_purchase_timestamp",
                 "order_approved_at",
                 "order_delivered_carrier_date",
                 "order_delivered_customer_date",
                 "order_estimated_delivery_date"]

Orders_df = dataset["olist_orders_dataset.csv"]

for col in date_column:
    Orders_df[col] = pd.to_datetime(Orders_df[col])


#added a new column based on dilivery status
Orders_df['is_delivered'] = Orders_df['order_delivered_customer_date'].notnull()
#print(Orders_df['is_delivered'].value_counts())


#added a new column based on delivery delay 
Orders_df['delivery_delay'] = (Orders_df['order_delivered_customer_date']-Orders_df['order_estimated_delivery_date']).dt.days
#print(Orders_df['delivery_delay'].dtype)

#added a new  lable column based on delivery delay

condition = [
    Orders_df['delivery_delay'].isnull(),
    Orders_df['delivery_delay'] < 0
]
choice = [
    "Not Delivered",
    "Early"
]
Orders_df['delivery_status'] =np.select(condition ,choice, default ="Late")
#print(Orders_df['delivery_status'].value_counts())


output_path =os.path.join(script_dir,"orders_cleaned.csv")

Orders_df.to_csv(output_path,index = False)

# loops to data check 
#for table_name , df in dataset.items():
#    print(f"table:{table_name}---")
#    print(f"shape:{df.shape}(rows, columns)")
#    print(f"columns:{list(df.columns)}\n")
#    print(f"has nulls:{df.isnull().sum()}")
#    print(f"has dupe:{df.duplicated().sum()}")
#  print(f"dtypes:\n{df.dtypes}\n")