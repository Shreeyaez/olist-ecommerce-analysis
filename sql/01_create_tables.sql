-- ============================================================
-- Olist E-commerce Analysis
-- File: 01_create_tables.sql
-- Purpose: Create the core database tables
-- ============================================================


-- ============================================================
-- 1. Customers
-- Grain: One row per customer order record
-- ============================================================

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);


-- ============================================================
-- 2. Orders
-- Grain: One row per order
-- ============================================================

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);


-- ============================================================
-- 3. Order Items
-- Grain: One row per item within an order
-- ============================================================

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);



-- ============================================================
-- 4. PRODUCTS
-- Grain: One row per product
-- ============================================================

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g NUMERIC(10,2),
    product_length_cm NUMERIC(10,2),
    product_height_cm NUMERIC(10,2),
    product_width_cm NUMERIC(10,2)
);


-- ============================================================
-- 5. SELLERS
-- Grain: One row per seller
-- ============================================================

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);


-- ============================================================
-- 6. ORDER PAYMENTS
-- Grain: One row per payment record within an order
-- Primary key: Combination of order_id + payment_sequential
-- ============================================================

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);


-- ============================================================
-- 7. ORDER REVIEWS
-- Grain: One row per review record
-- ============================================================

CREATE TABLE order_reviews (
    review_record_id BIGSERIAL PRIMARY KEY,
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- ============================================================
-- 8. GEOLOCATION
-- Grain: One row per geolocation record
-- Note: ZIP code prefix may occur multiple times
-- ============================================================

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat NUMERIC(10,6),
    geolocation_lng NUMERIC(10,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);


-- ============================================================
-- 9. PRODUCT CATEGORY TRANSLATION
-- Grain: One row per product category translation
-- ============================================================

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);