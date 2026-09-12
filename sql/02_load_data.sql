-- ============================================================
-- Olist E-commerce Analysis
-- File: 02_load_data.sql
-- Purpose: Load raw CSV files into PostgreSQL tables
-- ============================================================


-- ============================================================
-- 1. CUSTOMERS
-- ============================================================

\copy customers
FROM 'data/raw/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 2. ORDERS
-- ============================================================

\copy orders
FROM 'data/raw/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 3. ORDER ITEMS
-- ============================================================

\copy order_items
FROM 'data/raw/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 4. PRODUCTS
-- ============================================================

\copy products
FROM 'data/raw/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 5. SELLERS
-- ============================================================

\copy sellers
FROM 'data/raw/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 6. ORDER PAYMENTS
-- ============================================================

\copy order_payments
FROM 'data/raw/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 7. ORDER REVIEWS
-- ============================================================

\copy order_reviews
(review_id, order_id, review_score, review_comment_title,
 review_comment_message, review_creation_date, review_answer_timestamp)
FROM 'data/raw/olist_order_reviews_utf8.csv'
WITH (
    FORMAT csv,
    HEADER true,
    ENCODING 'UTF8'
);


-- ============================================================
-- 8. GEOLOCATION
-- ============================================================

\copy geolocation
FROM 'data/raw/olist_geolocation_dataset.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================
-- 9. PRODUCT CATEGORY TRANSLATION
-- ============================================================

\copy product_category_translation
FROM 'data/raw/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true);

