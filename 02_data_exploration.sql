-- ====================================================================
-- Apple Retail Sales Analysis | Initial Data Exploration & Sanity Checks
-- Author: Pravin Ghule
-- ====================================================================

-- 1. Total Record Counts across all tables
SELECT 'stores' AS table_name, COUNT(*) AS total_records FROM stores
UNION ALL
SELECT 'category', COUNT(*) FROM category
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'warranty_claims', COUNT(*) FROM warranty_claims;

-- 2. Date Range of Transactions & Warranty Claims
SELECT 
    MIN(sale_date) AS earliest_sale,
    MAX(sale_date) AS latest_sale,
    ROUND((JULIANDAY(MAX(sale_date)) - JULIANDAY(MIN(sale_date))), 0) AS total_sales_history_days
FROM sales;

-- 3. High-level Financial Overview
SELECT 
    COUNT(s.sale_id) AS total_orders,
    SUM(s.quantity) AS total_units_sold,
    ROUND(SUM(s.quantity * p.unit_price), 2) AS gross_revenue_usd,
    ROUND(SUM(s.quantity * p.cogs), 2) AS total_cogs_usd,
    ROUND(SUM(s.quantity * (p.unit_price - p.cogs)), 2) AS gross_profit_usd,
    ROUND((SUM(s.quantity * (p.unit_price - p.cogs)) / SUM(s.quantity * p.unit_price)) * 100, 2) AS overall_profit_margin_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id;

-- 4. Warranty Claims High-Level Overview
SELECT 
    COUNT(w.claim_id) AS total_claims,
    ROUND((COUNT(w.claim_id) * 100.0) / (SELECT COUNT(*) FROM sales), 2) AS global_claim_rate_pct,
    ROUND(SUM(w.claim_amount), 2) AS total_warranty_costs_usd,
    ROUND(AVG(w.days_to_claim), 1) AS avg_days_to_failure
FROM warranty_claims w;
