import sqlite3
import os

db_path = r"C:\Users\Pravin Ghule\Downloads\BT_Mini_Project\Apple_Retail_Sales_SQL_Project\apple_retail.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

queries = [
    ("Q1: Top 5 Apple Stores by Revenue", """
        SELECT st.store_name, st.city, st.country,
               SUM(s.quantity) AS units_sold,
               ROUND(SUM(s.quantity * p.unit_price), 2) AS total_revenue_usd
        FROM stores st
        JOIN sales s ON st.store_id = s.store_id
        JOIN products p ON s.product_id = p.product_id
        GROUP BY st.store_id, st.store_name, st.city, st.country
        ORDER BY total_revenue_usd DESC
        LIMIT 5;
    """),

    ("Q2: Regional Sales & Revenue Share", """
        WITH RegionalTotals AS (
            SELECT st.region,
                   SUM(s.quantity * p.unit_price) AS region_revenue,
                   SUM(s.quantity) AS region_units
            FROM stores st
            JOIN sales s ON st.store_id = s.store_id
            JOIN products p ON s.product_id = p.product_id
            GROUP BY st.region
        )
        SELECT region,
               ROUND(region_revenue, 2) AS revenue_usd,
               region_units,
               ROUND((region_revenue * 100.0) / SUM(region_revenue) OVER(), 2) AS global_share_pct
        FROM RegionalTotals
        ORDER BY revenue_usd DESC;
    """),

    ("Q3: Top 5 Best-Selling Products by Revenue", """
        SELECT p.product_name, c.category_name, p.unit_price,
               SUM(s.quantity) AS units_sold,
               ROUND(SUM(s.quantity * p.unit_price), 2) AS revenue_usd,
               ROUND(SUM(s.quantity * (p.unit_price - p.cogs)), 2) AS profit_usd
        FROM products p
        JOIN category c ON p.category_id = c.category_id
        JOIN sales s ON p.product_id = s.product_id
        GROUP BY p.product_id, p.product_name, c.category_name, p.unit_price
        ORDER BY revenue_usd DESC
        LIMIT 5;
    """),

    ("Q4: Year-over-Year (YoY) Growth using LAG()", """
        WITH YearlySales AS (
            SELECT SUBSTR(s.sale_date, 1, 4) AS sales_year,
                   ROUND(SUM(s.quantity * p.unit_price), 2) AS annual_revenue
            FROM sales s
            JOIN products p ON s.product_id = p.product_id
            GROUP BY SUBSTR(s.sale_date, 1, 4)
        )
        SELECT sales_year, annual_revenue,
               LAG(annual_revenue, 1) OVER (ORDER BY sales_year) AS prior_year_rev,
               ROUND(((annual_revenue - LAG(annual_revenue, 1) OVER (ORDER BY sales_year)) / 
                      LAG(annual_revenue, 1) OVER (ORDER BY sales_year)) * 100.0, 2) AS yoy_growth_pct
        FROM YearlySales
        ORDER BY sales_year;
    """),

    ("Q5: Early-Life Failures (<= 60 Days) vs Late Failures by Category", """
        SELECT c.category_name,
               COUNT(w.claim_id) AS total_claims,
               SUM(CASE WHEN w.days_to_claim <= 30 THEN 1 ELSE 0 END) AS under_30_days,
               SUM(CASE WHEN w.days_to_claim BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS days_31_to_60,
               SUM(CASE WHEN w.days_to_claim > 60 THEN 1 ELSE 0 END) AS over_60_days,
               ROUND((SUM(CASE WHEN w.days_to_claim <= 60 THEN 1 ELSE 0 END) * 100.0) / COUNT(w.claim_id), 2) AS early_life_rate_pct
        FROM warranty_claims w
        JOIN sales s ON w.sale_id = s.sale_id
        JOIN products p ON s.product_id = p.product_id
        JOIN category c ON p.category_id = c.category_id
        GROUP BY c.category_name
        ORDER BY early_life_rate_pct DESC;
    """),

    ("Q6: Warranty Repair Status Breakdown & Cost Absorption", """
        SELECT w.repair_status,
               COUNT(w.claim_id) AS total_claims,
               ROUND((COUNT(w.claim_id) * 100.0) / (SELECT COUNT(*) FROM warranty_claims), 2) AS pct_of_claims,
               ROUND(SUM(w.claim_amount), 2) AS total_cost_usd,
               ROUND(AVG(w.claim_amount), 2) AS avg_claim_cost_usd
        FROM warranty_claims w
        GROUP BY w.repair_status
        ORDER BY total_claims DESC;
    """)
]

print("=" * 80)
print("APPLE RETAIL SALES ANALYSIS | SQL QUERY EXECUTION RESULTS")
print("=" * 80)

for title, sql in queries:
    print(f"\n>>> {title}:")
    cur.execute(sql)
    col_names = [desc[0] for desc in cur.description]
    rows = cur.fetchall()
    
    # Format as pretty table
    header_str = " | ".join(f"{col:<20}" for col in col_names)
    print("-" * len(header_str))
    print(header_str)
    print("-" * len(header_str))
    for r in rows:
        row_str = " | ".join(f"{str(val):<20}" for val in r)
        print(row_str)

conn.close()
print("\n" + "=" * 80)
print("ALL SQL QUERIES EXECUTED SUCCESSFULLY ON LOCAL DATABASE.")
print("=" * 80)
