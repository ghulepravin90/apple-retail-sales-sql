# Apple Retail Sales Analysis | SQL Interview Preparation Guide

This guide prepares you to speak confidently about the **Apple Retail Sales & Warranty Analysis** project during data analytics job interviews.

---

## 1. The 60-Second "Elevator Pitch"

**Question:** *"Can you tell me about the Apple Retail Sales project on your resume?"*

> **Sample Answer:**
> "In this project, I designed a relational PostgreSQL database modeling Apple's global retail operations across 15 flagship stores, 23 products, and thousands of transactions.
> 
> My goal was to provide data-driven answers to three key operational problems:
> 1. **Store & Regional Revenue Benchmarking:** Which stores and countries drive the highest revenue and average transaction value?
> 2. **Product Demand & Growth Trends:** How do sales evolve year-over-year, and which flagship models lead within each category?
> 3. **Warranty Claims & Reliability Gaps:** Identifying 'early-life failures' (hardware defects occurring within 60 days of purchase) to highlight supplier quality issues and calculate net warranty cost impact.
> 
> Technically, I used multi-table joins, aggregations, **CTEs (Common Table Expressions)**, and **Window Functions** like `LAG()` for YoY growth, `SUM() OVER(ORDER BY...)` for running totals, and `DENSE_RANK()` for category leadership.
> 
> The project proved that while iPhones and MacBooks drive over 60% of revenue, **early-life failures within 60 days accounted for over 36% of all warranty claims**, costing significant replacement capital and pinpointing specific assembly batches for QA review."

---

## 2. Technical SQL Questions & In-Depth Answers

### Q1: What is the difference between `RANK()`, `DENSE_RANK()`, and `ROW_NUMBER()`? Where did you use them?
> **Answer:**
> - `ROW_NUMBER()` assigns a strictly unique sequential integer to each row, even if there are ties (e.g. 1, 2, 3, 4).
> - `RANK()` assigns identical ranks to ties, but skips subsequent rank numbers (e.g. 1, 2, 2, 4).
> - `DENSE_RANK()` assigns identical ranks to ties without skipping subsequent numbers (e.g. 1, 2, 2, 3).
> 
> "I used `DENSE_RANK() OVER (PARTITION BY category_name ORDER BY SUM(revenue) DESC)` in Question 7 to find the top 2 products in each category without skipping ranks if two products had similar revenue."

---

### Q2: Why did you use Common Table Expressions (CTEs) instead of nested subqueries?
> **Answer:**
> "CTEs (using the `WITH` clause) provide two massive advantages:
> 1. **Readability & Maintainability:** Nested subqueries become difficult to read and debug when nesting 3 or 4 levels deep. CTEs break complex business logic into sequential, modular steps (e.g., first calculating `YearlySales`, then computing `LAG()` on that result).
> 2. **Reusability:** A CTE can be referenced multiple times within the same query without rewriting the code, which optimizes query execution planning in modern database engines like PostgreSQL."

---

### Q3: How did you calculate Year-over-Year (YoY) Revenue Growth in SQL?
> **Answer:**
> "I used the `LAG()` window function. In the CTE, I aggregated annual revenue grouped by year. Then, in the outer query, I used:
> ```sql
> LAG(annual_revenue, 1) OVER (ORDER BY sales_year) AS prior_year_revenue
> ```
> And calculated percentage growth:
> ```sql
> ROUND(((annual_revenue - prior_year_revenue) / prior_year_revenue) * 100.0, 2) AS yoy_growth_pct
> ```
> This avoids expensive self-joins and calculates growth in a single scan."

---

### Q4: What are "Early-Life Failures" and how did you analyze them in SQL?
> **Answer:**
> "In hardware electronics, an 'early-life failure' is a defect occurring shortly after purchase (typically within 30 to 60 days), usually indicating manufacturing defects, soldering issues, or bad component batches rather than wear-and-tear.
> 
> In SQL, I used conditional aggregation with `CASE` statements:
> ```sql
> SUM(CASE WHEN w.days_to_claim <= 60 THEN 1 ELSE 0 END) AS early_life_failures,
> ROUND((SUM(CASE WHEN w.days_to_claim <= 60 THEN 1 ELSE 0 END) * 100.0) / COUNT(w.claim_id), 2) AS early_life_rate_pct
> ```
> This metric allows quality assurance (QA) teams to immediately spot problematic product batches."

---

### Q5: How did you optimize query performance across large sales tables?
> **Answer:**
> "I implemented an indexing strategy on foreign keys and frequently filtered columns:
> - `CREATE INDEX idx_sales_date ON sales(sale_date);` (speeds up time-series and monthly aggregations).
> - `CREATE INDEX idx_sales_store ON sales(store_id);` (accelerates store-level joins).
> - `CREATE INDEX idx_sales_product ON sales(product_id);` (accelerates category and product joins).
> - `CREATE INDEX idx_warranty_sale ON warranty_claims(sale_id);` (speeds up `LEFT JOIN` between sales and warranty claims).
> 
> I also used `EXPLAIN ANALYZE` in PostgreSQL to inspect query execution plans and ensure index scans were utilized instead of sequential table scans."

---

## 3. Core Business Findings & Data Storytelling

When asked: *"What were your key takeaways from analyzing Apple's sales and warranty data?"*

1. **Flagship Store Performance:**
   - Apple BKC (Mumbai) and Apple Piazza Liberty (Milan) ranked among the top revenue generators, demonstrating surging demand in emerging luxury consumer markets.
2. **Category Margin Powerhouses:**
   - While iPhones generated the largest total dollar volume, **Accessories and AirPods yielded the highest gross profit margins (over 60%)**, serving as essential margin boosters.
3. **Warranty Cost Concentration:**
   - 'Replaced with New Device' claims accounted for only **25.3% of claims by volume, but over 55% of total warranty expenses**, averaging $617 per claim. 
   - 10.5% of warranty requests were rejected due to accidental damage, protecting Apple from unnecessary warranty cost absorption.
