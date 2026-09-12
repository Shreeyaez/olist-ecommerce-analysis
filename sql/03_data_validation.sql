-- =========================================================
-- OLIST E-COMMERCE ANALYSIS
-- PHASE 4: DATA VALIDATION
-- =========================================================


-- =========================================================
-- 1. ROW COUNTS
-- =========================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM order_reviews

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM geolocation

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM product_category_translation

ORDER BY table_name;


-- =========================================================
-- 2. PRIMARY KEY / UNIQUE ID CHECKS
-- ====================== ===================================

-- Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM customers;


-- Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM orders;


-- Order Items
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS unique_item_keys
FROM order_items;


-- Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM products;


-- Sellers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids
FROM sellers;


-- Payments
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential)) AS unique_payment_keys
FROM order_payments;


-- Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(DISTINCT review_record_id) AS unique_review_record_ids
FROM order_reviews;


-- =========================================================
-- 3. NULL CHECKS
-- =========================================================

-- Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_customer_unique_id,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_state
FROM customers;


-- Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_date
FROM orders;


-- Order Items
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight
FROM order_items;


-- Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weight,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_length,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_height,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_width
FROM products;


-- Sellers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS null_state
FROM sellers;


-- Payments
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM order_payments;


-- Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS null_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_review_score
FROM order_reviews;


-- =========================================================
-- 4. FOREIGN KEY INTEGRITY
-- =========================================================

-- Orders -> Customers
SELECT COUNT(*) AS unmatched_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Order Items -> Orders
SELECT COUNT(*) AS unmatched_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Order Items -> Products
SELECT COUNT(*) AS unmatched_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Order Items -> Sellers
SELECT COUNT(*) AS unmatched_sellers
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Payments -> Orders
SELECT COUNT(*) AS unmatched_payment_orders
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Reviews -> Orders
SELECT COUNT(*) AS unmatched_review_orders
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- =========================================================
-- 5. ORDER DATE VALIDATION
-- =========================================================

-- Approved before purchase
SELECT COUNT(*) AS approved_before_purchase
FROM orders
WHERE order_approved_at < order_purchase_timestamp;


-- Delivered before purchase
SELECT COUNT(*) AS delivered_before_purchase
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;


-- Delivered before carrier handoff
SELECT COUNT(*) AS delivered_before_carrier
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;


-- Estimated delivery before purchase
SELECT COUNT(*) AS estimated_before_purchase
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;


-- =========================================================
-- 6. NUMERIC / BUSINESS VALIDATION
-- =========================================================

-- Negative item prices
SELECT COUNT(*) AS negative_prices
FROM order_items
WHERE price < 0;


-- Negative freight values
SELECT COUNT(*) AS negative_freight
FROM order_items
WHERE freight_value < 0;


-- Invalid review scores
SELECT COUNT(*) AS invalid_review_scores
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;


-- Invalid payment values
SELECT COUNT(*) AS negative_payment_values
FROM order_payments
WHERE payment_value < 0;


-- Invalid payment installments
SELECT COUNT(*) AS invalid_installments
FROM order_payments
WHERE payment_installments <= 0;


-- =========================================================
-- 7. ORDER STATUS DISTRIBUTION
-- =========================================================

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- =========================================================
-- 8. ORDERS WITHOUT ITEMS
-- =========================================================

SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;


-- =========================================================
-- 9. DUPLICATE REVIEW ID SUMMARY
-- =========================================================

SELECT
    COUNT(*) AS duplicated_review_ids,
    SUM(occurrences) AS affected_review_records
FROM (
    SELECT
        review_id,
        COUNT(*) AS occurrences
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) duplicates;

-- Number of non-unique reviews
SELECT COUNT(*) AS total_reviews, 
 COUNT(DISTINCT review_id) AS unique_review_id,
 COUNT(*) - COUNT(DISTINCT review_id) AS non_unique_reviews 
FROM order_reviews;

-- =========================================================
-- 10. REVIEW SCORE DISTRIBUTION
-- =========================================================

SELECT
    review_score,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;