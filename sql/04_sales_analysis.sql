-- =========================================================
-- PHASE 5: SALES ANALYSIS
-- =========================================================


-- =========================================================
-- 1. OVERALL SALES PERFORMANCE
-- =========================================================

SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_order_value,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id;

-- =========================================================
-- 2. REVENUE BY YEAR
-- =========================================================

SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    EXTRACT(YEAR FROM o.order_purchase_timestamp)
ORDER BY year;

-- =========================================================
-- 3. MONTHLY SALES PERFORMANCE
-- =========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- =========================================================
-- 4. MONTHLY AVERAGE ORDER VALUE
-- =========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- =========================================================
-- 5. SALES BY ORDER STATUS
-- =========================================================

SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_status
ORDER BY
    total_orders DESC;

-- =========================================================
-- 6. TOP PRODUCT CATEGORIES BY REVENUE
-- =========================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY
    product_revenue DESC;

-- =========================================================
-- 7. TOP CATEGORIES BY ITEMS SOLD
-- =========================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(
        SUM(oi.price) / COUNT(*),
        2
    ) AS average_item_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY
    items_sold DESC;

-- =========================================================
-- 8. REVENUE BY CUSTOMER STATE
-- =========================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    total_revenue DESC;

-- =========================================================
-- 9. REVENUE BY CUSTOMER CITY
-- =========================================================

SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_city,
    c.customer_state
ORDER BY
    total_revenue DESC
LIMIT 20;

-- =========================================================
-- 10. MONTH-OVER-MONTH REVENUE GROWTH
-- =========================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS month,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_TRUNC('month', o.order_purchase_timestamp)
)

SELECT
    month,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        LAG(total_revenue) OVER (ORDER BY month),
        2
    ) AS previous_month_revenue,
    ROUND(
        (
            (total_revenue -
             LAG(total_revenue) OVER (ORDER BY month))
            / NULLIF(
                LAG(total_revenue) OVER (ORDER BY month),
                0
            )
        ) * 100,
        2
    ) AS mom_growth_percentage
FROM monthly_sales
ORDER BY month;

-- =========================================================
-- 11. CATEGORY REVENUE CONTRIBUTION
-- =========================================================

WITH category_sales AS (
    SELECT
        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category,
        SUM(oi.price) AS product_revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct
        ON p.product_category_name = pct.product_category_name
    GROUP BY
        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    category,
    ROUND(product_revenue, 2) AS product_revenue,
    ROUND(
        product_revenue /
        SUM(product_revenue) OVER () * 100,
        2
    ) AS revenue_percentage
FROM category_sales
ORDER BY product_revenue DESC;

-- =========================================================
-- 12. TOP 10 PRODUCT CATEGORIES
-- =========================================================

WITH category_sales AS (
    SELECT
        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category,
        COUNT(*) AS items_sold,
        SUM(oi.price) AS product_revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct
        ON p.product_category_name = pct.product_category_name
    GROUP BY
        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        )
),

ranked_categories AS (
    SELECT
        category,
        items_sold,
        product_revenue,
        RANK() OVER (
            ORDER BY product_revenue DESC
        ) AS revenue_rank
    FROM category_sales
)

SELECT
    revenue_rank,
    category,
    items_sold,
    ROUND(product_revenue, 2) AS product_revenue
FROM ranked_categories
WHERE revenue_rank <= 10
ORDER BY revenue_rank;

-- =========================================================
-- 13. TOP 10 PRODUCTS BY REVENUE
-- =========================================================

SELECT
    oi.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY
    product_revenue DESC
LIMIT 10;

-- =========================================================
-- 14. TOP 10 PRODUCTS BY SALES VOLUME
-- =========================================================

SELECT
    oi.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY
    items_sold DESC
LIMIT 10;

-- =========================================================
-- 15. MONTHLY ORDERS, ITEMS AND REVENUE
-- =========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- ============================================
-- 16. Sales by Payment Method
-- ============================================

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        SUM(COUNT(DISTINCT order_id)) OVER (),
        2
    ) AS order_percentage
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- ============================================
-- 17. Freight Impact on Sales
-- ============================================

SELECT
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_order_value,
    ROUND(
        SUM(oi.freight_value) * 100.0 /
        NULLIF(SUM(oi.price + oi.freight_value), 0),
        2
    ) AS freight_percentage
FROM order_items oi;

-- ============================================
-- 18. Order Status Distribution
-- ============================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;