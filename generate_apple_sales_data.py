import csv
import random
import sqlite3
import os
from datetime import datetime, timedelta

random.seed(101)

project_dir = r"C:\Users\Pravin Ghule\Downloads\BT_Mini_Project\Apple_Retail_Sales_SQL_Project"

# 1. Stores Data
stores_data = [
    ("ST-101", "Apple Fifth Avenue", "New York", "United States", "Americas"),
    ("ST-102", "Apple Regent Street", "London", "United Kingdom", "Europe"),
    ("ST-103", "Apple Ginza", "Tokyo", "Japan", "Asia Pacific"),
    ("ST-104", "Apple BKC", "Mumbai", "India", "Asia Pacific"),
    ("ST-105", "Apple Marina Bay Sands", "Singapore", "Singapore", "Asia Pacific"),
    ("ST-106", "Apple Champs-Élysées", "Paris", "France", "Europe"),
    ("ST-107", "Apple Sydney", "Sydney", "Australia", "Asia Pacific"),
    ("ST-108", "Apple Kurfürstendamm", "Berlin", "Germany", "Europe"),
    ("ST-109", "Apple Toronto Eaton Centre", "Toronto", "Canada", "Americas"),
    ("ST-110", "Apple Dubai Mall", "Dubai", "UAE", "Middle East"),
    ("ST-111", "Apple Union Square", "San Francisco", "United States", "Americas"),
    ("ST-112", "Apple Covent Garden", "London", "United Kingdom", "Europe"),
    ("ST-113", "Apple Saket", "New Delhi", "India", "Asia Pacific"),
    ("ST-114", "Apple Piazza Liberty", "Milan", "Italy", "Europe"),
    ("ST-115", "Apple Shibuya", "Tokyo", "Japan", "Asia Pacific"),
]

# 2. Categories Data
categories_data = [
    ("CAT-1", "iPhone"),
    ("CAT-2", "MacBook & Mac"),
    ("CAT-3", "iPad"),
    ("CAT-4", "Apple Watch"),
    ("CAT-5", "AirPods & Audio"),
    ("CAT-6", "Accessories & Displays"),
]

# 3. Products Data
products_data = [
    ("P-101", "iPhone 15 Pro Max 256GB", "CAT-1", "2023-09-22", 1199.00, 560.00),
    ("P-102", "iPhone 15 Pro 128GB", "CAT-1", "2023-09-22", 999.00, 480.00),
    ("P-103", "iPhone 15 128GB", "CAT-1", "2023-09-22", 799.00, 390.00),
    ("P-104", "iPhone 14 128GB", "CAT-1", "2022-09-16", 699.00, 340.00),
    ("P-105", "iPhone 13 128GB", "CAT-1", "2021-09-24", 599.00, 290.00),
    ("P-106", "MacBook Air 13\" M2 256GB", "CAT-2", "2022-07-15", 999.00, 490.00),
    ("P-107", "MacBook Air 15\" M3 512GB", "CAT-2", "2024-03-08", 1499.00, 710.00),
    ("P-108", "MacBook Pro 14\" M3 Pro 512GB", "CAT-2", "2023-11-07", 1999.00, 950.00),
    ("P-109", "MacBook Pro 16\" M3 Max 1TB", "CAT-2", "2023-11-07", 3499.00, 1600.00),
    ("P-110", "Mac Studio M2 Max", "CAT-2", "2023-06-13", 1999.00, 920.00),
    ("P-111", "iPad Pro 11\" M4 256GB", "CAT-3", "2024-05-15", 999.00, 460.00),
    ("P-112", "iPad Air 11\" M2 128GB", "CAT-3", "2024-05-15", 599.00, 280.00),
    ("P-113", "iPad 10th Gen 64GB", "CAT-3", "2022-10-26", 349.00, 170.00),
    ("P-114", "iPad mini 6th Gen", "CAT-3", "2021-09-24", 499.00, 240.00),
    ("P-115", "Apple Watch Series 9 45mm", "CAT-4", "2023-09-22", 429.00, 195.00),
    ("P-116", "Apple Watch Ultra 2 49mm", "CAT-4", "2023-09-22", 799.00, 360.00),
    ("P-117", "Apple Watch SE 40mm", "CAT-4", "2022-09-16", 249.00, 110.00),
    ("P-118", "AirPods Pro 2nd Gen USB-C", "CAT-5", "2023-09-22", 249.00, 98.00),
    ("P-119", "AirPods 3rd Gen", "CAT-5", "2021-10-26", 169.00, 65.00),
    ("P-120", "AirPods Max Over-Ear", "CAT-5", "2020-12-15", 549.00, 220.00),
    ("P-121", "Studio Display 27\" 5K", "CAT-6", "2022-03-18", 1599.00, 780.00),
    ("P-122", "MagSafe Dual Charger", "CAT-6", "2020-12-08", 129.00, 38.00),
    ("P-123", "Magic Keyboard with Touch ID", "CAT-6", "2021-08-03", 199.00, 62.00),
]

# 4. Generate Sales Records (2,500 transactions across 2021-2024)
start_date = datetime(2021, 1, 1)
end_date = datetime(2024, 9, 30)
delta_days = (end_date - start_date).days

sales_data = []
payment_methods = ["Apple Pay", "Credit Card", "Debit Card", "Apple Financing", "Cash"]
payment_weights = [0.45, 0.30, 0.12, 0.08, 0.05]

# High volume products get more transactions
popular_product_ids = ["P-101", "P-102", "P-103", "P-106", "P-111", "P-115", "P-118"]
all_product_ids = [p[0] for p in products_data]

product_dict = {p[0]: p for p in products_data}
store_dict = {s[0]: s for s in stores_data}

total_sales = 2500
for i in range(1, total_sales + 1):
    sale_id = f"S-{i:05d}"
    
    # Store selection with slight bias toward flagship stores
    store = random.choice(stores_data)
    store_id = store[0]
    
    # Product selection
    if random.random() < 0.65:
        product_id = random.choice(popular_product_ids)
    else:
        product_id = random.choice(all_product_ids)
        
    p_info = product_dict[product_id]
    p_launch = datetime.strptime(p_info[3], "%Y-%m-%d")
    
    # Sale date must be on or after product launch date
    min_date = max(start_date, p_launch)
    avail_days = (end_date - min_date).days
    if avail_days <= 0:
        sale_date_obj = min_date
    else:
        sale_date_obj = min_date + timedelta(days=random.randint(0, avail_days))
        
    sale_date = sale_date_obj.strftime("%Y-%m-%d")
    
    # Quantity: accessories/AirPods might be 1-3, high end Macs/Phones usually 1-2
    if p_info[2] in ["CAT-5", "CAT-6"]:
        quantity = random.choices([1, 2, 3], weights=[0.75, 0.20, 0.05])[0]
    else:
        quantity = random.choices([1, 2], weights=[0.90, 0.10])[0]
        
    payment = random.choices(payment_methods, weights=payment_weights)[0]
    
    sales_data.append((sale_id, sale_date, store_id, product_id, quantity, payment))

# 5. Generate Warranty Claims Data
# Some sales have warranty claims. Early-life failures happen within 60-90 days.
repair_statuses = [
    "Repaired & Returned", 
    "Replaced with New Device", 
    "Pending Inspection", 
    "Rejected - Accidental Damage"
]
repair_status_weights = [0.55, 0.25, 0.08, 0.12]

claim_types = [
    "Battery Degradation / Not Holding Charge",
    "Screen Display Flickering / Dead Pixels",
    "Logic Board Failure / Boot Loop",
    "Charging Port / Connection Fault",
    "Camera Sensor Defect",
    "Speaker Distortion / Audio Failure"
]

warranty_data = []
claim_counter = 1

for s in sales_data:
    sale_id, sale_date_str, store_id, product_id, qty, _ = s
    sale_date_obj = datetime.strptime(sale_date_str, "%Y-%m-%d")
    
    # Probability of claim: ~14%
    if random.random() < 0.14:
        claim_id = f"CLM-{claim_counter:04d}"
        
        # Days between sale and claim (some early life 5-60 days, some later 61-365 days)
        if random.random() < 0.40:
            # Early life failure (under 60 days)
            days_to_claim = random.randint(3, 59)
        else:
            days_to_claim = random.randint(60, 365)
            
        claim_date_obj = sale_date_obj + timedelta(days=days_to_claim)
        if claim_date_obj > datetime(2024, 10, 31):
            claim_date_obj = datetime(2024, 10, 31)
            
        claim_date = claim_date_obj.strftime("%Y-%m-%d")
        status = random.choices(repair_statuses, weights=repair_status_weights)[0]
        c_type = random.choice(claim_types)
        
        # Claim cost
        unit_price = product_dict[product_id][4]
        if status == "Replaced with New Device":
            claim_amount = round(unit_price * 0.75, 2)
        elif status == "Repaired & Returned":
            claim_amount = round(unit_price * random.uniform(0.15, 0.35), 2)
        elif status == "Rejected - Accidental Damage":
            claim_amount = 0.00
        else:
            claim_amount = round(unit_price * 0.20, 2)
            
        warranty_data.append((claim_id, claim_date, sale_id, c_type, status, days_to_claim, claim_amount))
        claim_counter += 1

# Write CSV files
def write_csv(filename, headers, rows):
    filepath = os.path.join(project_dir, filename)
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
    print(f"Wrote {len(rows)} records to {filename}")

write_csv("stores.csv", ["store_id", "store_name", "city", "country", "region"], stores_data)
write_csv("category.csv", ["category_id", "category_name"], categories_data)
write_csv("products.csv", ["product_id", "product_name", "category_id", "launch_date", "unit_price", "cogs"], products_data)
write_csv("sales.csv", ["sale_id", "sale_date", "store_id", "product_id", "quantity", "payment_method"], sales_data)
write_csv("warranty_claims.csv", ["claim_id", "claim_date", "sale_id", "claim_type", "repair_status", "days_to_claim", "claim_amount"], warranty_data)

# Create and populate SQLite database for immediate execution & testing
db_path = os.path.join(project_dir, "apple_retail.db")
if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("""
CREATE TABLE stores (
    store_id TEXT PRIMARY KEY,
    store_name TEXT NOT NULL,
    city TEXT NOT NULL,
    country TEXT NOT NULL,
    region TEXT NOT NULL
);
""")

cur.execute("""
CREATE TABLE category (
    category_id TEXT PRIMARY KEY,
    category_name TEXT NOT NULL
);
""")

cur.execute("""
CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id TEXT NOT NULL,
    launch_date TEXT NOT NULL,
    unit_price REAL NOT NULL,
    cogs REAL NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);
""")

cur.execute("""
CREATE TABLE sales (
    sale_id TEXT PRIMARY KEY,
    sale_date TEXT NOT NULL,
    store_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    payment_method TEXT NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
""")

cur.execute("""
CREATE TABLE warranty_claims (
    claim_id TEXT PRIMARY KEY,
    claim_date TEXT NOT NULL,
    sale_id TEXT NOT NULL,
    claim_type TEXT NOT NULL,
    repair_status TEXT NOT NULL,
    days_to_claim INTEGER NOT NULL,
    claim_amount REAL NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);
""")

cur.executemany("INSERT INTO stores VALUES (?, ?, ?, ?, ?)", stores_data)
cur.executemany("INSERT INTO category VALUES (?, ?)", categories_data)
cur.executemany("INSERT INTO products VALUES (?, ?, ?, ?, ?, ?)", products_data)
cur.executemany("INSERT INTO sales VALUES (?, ?, ?, ?, ?, ?)", sales_data)
cur.executemany("INSERT INTO warranty_claims VALUES (?, ?, ?, ?, ?, ?, ?)", warranty_data)

conn.commit()
conn.close()
print(f"Successfully created and seeded SQLite database: {db_path}")
