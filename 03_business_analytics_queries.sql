-- ====================================================================
-- Apple Retail Sales Analysis | Business Analytics Queries
-- Author: Pravin Ghule
-- Core Skills: Joins, Aggregations, Window Functions, CTEs, Case Statements
-- ====================================================================

-- ====================================================================
-- SECTION 1: STORE & COUNTRY PERFORMANCE ANALYSIS
-- ====================================================================

-- Q1: Store Performance Ranking
-- Which Apple retail stores generated the highest total revenue, units sold, and average order value?
SELECT 
    st.store_id,
    st.store_name,
    st.city,
    st.country,
    COUNT(s.sale_id) AS total_transactions,
    SUM(s.quantity) AS total_units_sold,
    ROUND(SUM(s.quantity * p.unit_price), 2) AS total_revenue_usd,
    ROUND(AVG(s.quantity * p.unit_price), 2) AS avg_order_value_usd
FROM stores st
JOIN sales s ON st.store_id = s.store_id
JOIN products p ON s.product_id = p.product_id
GROUP BY st.store_id, st.store_name, st.city, st.country
ORDER BY total_revenue_usd DESC;


-- Q2: Country & Regional Performance Breakdown
-- Compare total sales revenue, market share, and unit distribution across countries and regions.
WITH RegionalTotals AS (
    SELECT 
        st.region,
        st.country,
        SUM(s.quantity * p.unit_price) AS country_revenue,
        SUM(s.quantity) AS country_units
    FROM stores st
    JOIN sales s ON st.store_id = s.store_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY st.region, st.country
)
SELECT 
    region,
    country,
    ROUND(country_revenue, 2) AS country_revenue_usd,
    country_units,
    ROUND((country_revenue * 100.0) / SUM(country_revenue) OVER(), 2) AS global_revenue_share_pct,
    ROUND((country_revenue * 100.0) / SUM(country_revenue) OVER(PARTITION BY region), 2) AS regional_share_pct
FROM RegionalTotals
ORDER BY region, country_revenue_usd DESC;


-- ====================================================================
-- SECTION 2: PRODUCT DEMAND & CATEGORY PRICING ANALYSIS
-- ====================================================================

-- Q3: Top 10 Best-Selling Products by Revenue and Volume
-- Identify key revenue-driving products and their contribution to overall catalog sales.
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.unit_price,
    SUM(s.quantity) AS total_units_sold,
    ROUND(SUM(s.quantity * p.unit_price), 2) AS total_revenue_usd,
    ROUND(SUM(s.quantity * (p.unit_price - p.cogs)), 2) AS total_profit_usd
FROM products p
JOIN category c ON p.category_id = c.category_id
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name, c.category_name, p.unit_price
ORDER BY total_revenue_usd DESC
LIMIT 10;


-- Q4: Category Pricing & Margin Analysis
-- What is the average price point, gross margin percentage, and total sales across product categories?
SELECT 
    c.category_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    ROUND(AVG(p.unit_price), 2) AS avg_catalog_price_usd,
    SUM(s.quantity) AS total_units_sold,
    ROUND(SUM(s.quantity * p.unit_price), 2) AS total_revenue_usd,
    ROUND(SUM(s.quantity * (p.unit_price - p.cogs)), 2) AS total_profit_usd,
    ROUND((SUM(s.quantity * (p.unit_price - p.cogs)) / SUM(s.quantity * p.unit_price)) * 100, 2) AS profit_margin_pct
FROM category c
JOIN products p ON c.category_id = p.category_id
JOIN sales s ON p.product_id = s.product_id
GROUP BY c.category_name
ORDER BY total_revenue_usd DESC;


-- ====================================================================
-- SECTION 3: WINDOW FUNCTIONS & TREND TRACKING
-- ====================================================================

-- Q5: Year-over-Year (YoY) Revenue Growth using LAG()
-- Track annual revenue trends and calculate YoY growth percentage.
WITH YearlySales AS (
    SELECT 
        SUBSTR(s.sale_date, 1, 4) AS sales_year,
        ROUND(SUM(s.quantity * p.unit_price), 2) AS annual_revenue,
        SUM(s.quantity) AS annual_units
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY SUBSTR(s.sale_date, 1, 4)
)
SELECT 
    sales_year,
    annual_revenue,
    annual_units,
    LAG(annual_revenue, 1) OVER (ORDER BY sales_year) AS prior_year_revenue,
    ROUND(
        ((annual_revenue - LAG(annual_revenue, 1) OVER (ORDER BY sales_year)) / 
         LAG(annual_revenue, 1) OVER (ORDER BY sales_year)) * 100.0, 
        2
    ) AS yoy_growth_pct
FROM YearlySales
ORDER BY sales_year;


-- Q6: Monthly Cumulative Running Total Revenue
-- Calculate running revenue totals over time using SUM() OVER (ORDER BY...)
WITH MonthlyRevenue AS (
    SELECT 
        SUBSTR(s.sale_date, 1, 7) AS sale_month,
        ROUND(SUM(s.quantity * p.unit_price), 2) AS monthly_revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY SUBSTR(s.sale_date, 1, 7)
)
SELECT 
    sale_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY sale_month), 2) AS cumulative_running_total_usd
FROM MonthlyRevenue
ORDER BY sale_month;


-- Q7: Rank Products within Each Category using DENSE_RANK()
-- Find the #1 and #2 top revenue-generating products in each category.
WITH CategoryProductRank AS (
    SELECT 
        c.category_name,
        p.product_name,
        p.unit_price,
        SUM(s.quantity) AS units_sold,
        ROUND(SUM(s.quantity * p.unit_price), 2) AS revenue,
        DENSE_RANK() OVER (
            PARTITION BY c.category_name 
            ORDER BY SUM(s.quantity * p.unit_price) DESC
        ) AS rank_in_category
    FROM category c
    JOIN products p ON c.category_id = p.category_id
    JOIN sales s ON p.product_id = s.product_id
    GROUP BY c.category_name, p.product_name, p.unit_price
)
SELECT *
FROM CategoryProductRank
WHERE rank_in_category <= 2
ORDER BY category_name, rank_in_category;


-- ====================================================================
-- SECTION 4: ADVANCED COMMON TABLE EXPRESSIONS (CTEs)
-- ====================================================================

-- Q8: #1 Top Store in Each Region & Their Best-Selling Product
-- Multi-CTE determining top store per geographic region and identifying its primary driver.
WITH StoreRevenue AS (
    SELECT 
        st.region,
        st.store_id,
        st.store_name,
        st.city,
        ROUND(SUM(s.quantity * p.unit_price), 2) AS store_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY st.region 
            ORDER BY SUM(s.quantity * p.unit_price) DESC
        ) AS regional_rank
    FROM stores st
    JOIN sales s ON st.store_id = s.store_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY st.region, st.store_id, st.store_name, st.city
),
StoreTopProduct AS (
    SELECT 
        s.store_id,
        p.product_name,
        SUM(s.quantity) AS units,
        ROW_NUMBER() OVER (
            PARTITION BY s.store_id 
            ORDER BY SUM(s.quantity) DESC
        ) AS product_rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.store_id, p.product_name
)
SELECT 
    sr.region,
    sr.store_name,
    sr.city,
    sr.store_revenue AS top_store_revenue_usd,
    stp.product_name AS top_selling_product
FROM StoreRevenue sr
JOIN StoreTopProduct stp ON sr.store_id = stp.store_id AND stp.product_rank = 1
WHERE sr.regional_rank = 1
ORDER BY sr.store_revenue DESC;


-- ====================================================================
-- SECTION 5: WARRANTY CLAIMS & EARLY-LIFE FAILURE ANALYSIS
-- ====================================================================

-- Q9: Warranty Claim Rate by Product (Reliability Benchmarking)
-- Measure claim percentage per product to identify reliability outliers.
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(s.sale_id) AS total_units_sold,
    COUNT(w.claim_id) AS total_claims,
    ROUND((COUNT(w.claim_id) * 100.0) / COUNT(s.sale_id), 2) AS claim_rate_pct,
    ROUND(SUM(COALESCE(w.claim_amount, 0)), 2) AS total_warranty_cost_usd
FROM products p
JOIN category c ON p.category_id = c.category_id
JOIN sales s ON p.product_id = s.product_id
LEFT JOIN warranty_claims w ON s.sale_id = w.sale_id
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY claim_rate_pct DESC;


-- Q10: Early-Life Failures vs. Late Failures (Crucial Operational Metric)
-- Highlight hardware failures occurring within 60 days of purchase vs later failures.
SELECT 
    c.category_name,
    COUNT(w.claim_id) AS total_claims,
    SUM(CASE WHEN w.days_to_claim <= 30 THEN 1 ELSE 0 END) AS failures_within_30_days,
    SUM(CASE WHEN w.days_to_claim BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS failures_31_to_60_days,
    SUM(CASE WHEN w.days_to_claim > 60 THEN 1 ELSE 0 END) AS failures_after_60_days,
    ROUND(
        (SUM(CASE WHEN w.days_to_claim <= 60 THEN 1 ELSE 0 END) * 100.0) / COUNT(w.claim_id), 
        2
    ) AS early_life_failure_rate_pct
FROM warranty_claims w
JOIN sales s ON w.sale_id = s.sale_id
JOIN products p ON s.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY early_life_failure_rate_pct DESC;


-- Q11: Warranty Repair Status Breakdown & Cost Absorption
-- Evaluate the operational status of claims (Repaired vs Replaced vs Rejected).
SELECT 
    w.repair_status,
    COUNT(w.claim_id) AS total_claims,
    ROUND((COUNT(w.claim_id) * 100.0) / (SELECT COUNT(*) FROM warranty_claims), 2) AS pct_of_claims,
    ROUND(AVG(w.days_to_claim), 1) AS avg_days_to_claim,
    ROUND(SUM(w.claim_amount), 2) AS total_cost_usd,
    ROUND(AVG(w.claim_amount), 2) AS avg_cost_per_claim_usd
FROM warranty_claims w
GROUP BY w.repair_status
ORDER BY total_claims DESC;


-- Q12: Net Product Profitability after Warranty Loss (Executive P&L View)
-- Calculate real net profit after subtracting warranty repair costs from gross profit.
WITH ProductFinancials AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(s.quantity * p.unit_price) AS gross_revenue,
        SUM(s.quantity * (p.unit_price - p.cogs)) AS gross_profit,
        SUM(COALESCE(w.claim_amount, 0)) AS warranty_loss
    FROM products p
    JOIN sales s ON p.product_id = s.product_id
    LEFT JOIN warranty_claims w ON s.sale_id = w.sale_id
    GROUP BY p.product_id, p.product_name
)
SELECT 
    product_name,
    ROUND(gross_revenue, 2) AS gross_revenue_usd,
    ROUND(gross_profit, 2) AS gross_profit_usd,
    ROUND(warranty_loss, 2) AS warranty_loss_usd,
    ROUND(gross_profit - warranty_loss, 2) AS net_realized_profit_usd,
    ROUND(((gross_profit - warranty_loss) / gross_revenue) * 100.0, 2) AS net_profit_margin_pct
FROM ProductFinancials
ORDER BY net_realized_profit_usd DESC
LIMIT 10;
