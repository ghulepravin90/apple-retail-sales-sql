-- ====================================================================
-- Apple Retail Sales Analysis | PostgreSQL Database Setup & Schema
-- Author: Pravin Ghule
-- ====================================================================

-- Drop tables if they already exist (in correct dependency order)
DROP TABLE IF EXISTS warranty_claims CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS stores CASCADE;

-- 1. STORES TABLE
CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL
);

-- 2. CATEGORY TABLE
CREATE TABLE category (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);

-- 3. PRODUCTS TABLE
CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id VARCHAR(10) NOT NULL,
    launch_date DATE NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price > 0),
    cogs NUMERIC(10, 2) NOT NULL CHECK (cogs > 0),
    CONSTRAINT fk_products_category 
        FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE RESTRICT
);

-- 4. SALES FACT TABLE
CREATE TABLE sales (
    sale_id VARCHAR(15) PRIMARY KEY,
    sale_date DATE NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    payment_method VARCHAR(30) NOT NULL,
    CONSTRAINT fk_sales_store 
        FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_product 
        FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

-- 5. WARRANTY CLAIMS TABLE
CREATE TABLE warranty_claims (
    claim_id VARCHAR(15) PRIMARY KEY,
    claim_date DATE NOT NULL,
    sale_id VARCHAR(15) NOT NULL,
    claim_type VARCHAR(100) NOT NULL,
    repair_status VARCHAR(50) NOT NULL,
    days_to_claim INTEGER NOT NULL CHECK (days_to_claim >= 0),
    claim_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_warranty_sale 
        FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE
);

-- PERFORMANCE INDEXES
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_store ON sales(store_id);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_warranty_sale ON warranty_claims(sale_id);
CREATE INDEX idx_warranty_status ON warranty_claims(repair_status);

-- DATA INGESTION VIA POSTGRESQL \copy (Run in psql terminal or pgAdmin Query Tool)
/*
\copy stores FROM 'stores.csv' WITH (FORMAT csv, HEADER true);
\copy category FROM 'category.csv' WITH (FORMAT csv, HEADER true);
\copy products FROM 'products.csv' WITH (FORMAT csv, HEADER true);
\copy sales FROM 'sales.csv' WITH (FORMAT csv, HEADER true);
\copy warranty_claims FROM 'warranty_claims.csv' WITH (FORMAT csv, HEADER true);
*/
