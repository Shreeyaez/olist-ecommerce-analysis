-- ============================================
-- PHASE 6: CUSTOMER ANALYSIS
-- E-commerce Sales & Customer Intelligence
-- ============================================


-- ============================================
-- 1. Customer Overview
-- ============================================

SELECT
    COUNT(*) AS total_customer_records,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(DISTINCT customer_city) AS cities,
    COUNT(DISTINCT customer_state) AS states
FROM customers;


-- ============================================
-- 2. One-Time vs Repeat Customers
-- ============================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customer_orders
GROUP BY
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END
ORDER BY customers DESC;


-- ============================================
-- 3. Orders per Customer
-- ============================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(AVG(total_orders), 2) AS average_orders_per_customer,
    MAX(total_orders) AS maximum_orders_by_customer
FROM customer_orders;


-- ============================================
-- 4. Customer Spending
-- ============================================

WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price + oi.freight_value) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(AVG(total_spending), 2) AS average_customer_spending,
    ROUND(MIN(total_spending), 2) AS minimum_customer_spending,
    ROUND(MAX(total_spending), 2) AS maximum_customer_spending
FROM customer_spending;


-- ============================================
-- 5. Top 20 Customers by Spending
-- ============================================

SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spending
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
ORDER BY total_spending DESC
LIMIT 20;


-- ============================================
-- 6. Customer Revenue by State
-- ============================================

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(
        SUM(oi.price + oi.freight_value) /
        COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS revenue_per_customer
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- ============================================
-- 7. Customer Revenue by City
-- ============================================

SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(
        SUM(oi.price + oi.freight_value) /
        COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS revenue_per_customer
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_city,
    c.customer_state
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================
-- 8. Monthly New Customers
-- ============================================

WITH first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    DATE_TRUNC('month', first_purchase_date)::DATE AS first_purchase_month,
    COUNT(*) AS new_customers
FROM first_purchase
GROUP BY DATE_TRUNC('month', first_purchase_date)
ORDER BY first_purchase_month;


-- ============================================
-- 9. Cohort Retention Analysis by Month Number
-- ============================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC(
            'month',
            MIN(o.order_purchase_timestamp)
        )::DATE AS cohort_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),

customer_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,
        co.cohort_month,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS purchase_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN customer_orders co
        ON c.customer_unique_id = co.customer_unique_id
),

cohort_activity AS (
    SELECT
        cohort_month,
        purchase_month,
        (
            EXTRACT(YEAR FROM purchase_month) * 12
            + EXTRACT(MONTH FROM purchase_month)
        )
        -
        (
            EXTRACT(YEAR FROM cohort_month) * 12
            + EXTRACT(MONTH FROM cohort_month)
        ) AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM customer_activity
    GROUP BY
        cohort_month,
        purchase_month
),

cohort_sizes AS (
    SELECT
        cohort_month,
        MAX(active_customers) FILTER (
            WHERE month_number = 0
        ) AS cohort_size
    FROM cohort_activity
    GROUP BY cohort_month
)

SELECT
    ca.cohort_month,
    ca.month_number,
    ca.active_customers,
    cs.cohort_size,
    ROUND(
        ca.active_customers * 100.0
        / cs.cohort_size,
        2
    ) AS retention_percentage
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON ca.cohort_month = cs.cohort_month
ORDER BY
    ca.cohort_month,
    ca.month_number;


-- ============================================
-- 10. Repeat Purchase Rate
-- ============================================

WITH customer_orders AS (
    SELECT  
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    ROUND(
        COUNT(*) FILTER (WHERE total_orders > 1) * 100.0 /
        COUNT(*),
        2
    ) AS repeat_customer_rate
FROM customer_orders;


-- ============================================
-- 11. Customer Purchase Frequency Distribution
-- ============================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    total_orders,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;


-- ============================================
-- 12. Customer Lifetime Value
-- ============================================

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(AVG(total_spending), 2) AS average_customer_lifetime_value,
    ROUND(PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY total_spending)::NUMERIC, 2) AS median_customer_lifetime_value,
    ROUND(PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY total_spending)::NUMERIC, 2) AS p75_customer_lifetime_value,
    ROUND(PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY total_spending)::NUMERIC, 2) AS p90_customer_lifetime_value
FROM customer_value;


-- ============================================
-- 13. Top Customers by Order Frequency
-- ============================================

SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
ORDER BY total_orders DESC
LIMIT 20;


-- ============================================
-- 14. Average Spending: One-Time vs Repeat Customers
-- ============================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price + oi.freight_value) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_spending), 2) AS average_spending,
    ROUND(SUM(total_spending), 2) AS total_revenue
FROM customer_orders
GROUP BY
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END
ORDER BY total_revenue DESC;


