-- ============================================================
-- PHASE 8: SELLER ANALYSIS
-- Olist Brazilian E-Commerce Dataset
-- ============================================================


-- ============================================================
-- QUERY 1: Seller Overview
-- ============================================================

SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_city) AS seller_cities,
    COUNT(DISTINCT seller_state) AS seller_states
FROM sellers;


-- ============================================================
-- QUERY 2: Sellers by State
-- ============================================================

SELECT
    seller_state,
    COUNT(*) AS seller_count
FROM sellers
GROUP BY seller_state
ORDER BY seller_count DESC;


-- ============================================================
-- QUERY 3: Sellers by City
-- ============================================================

SELECT
    seller_city,
    seller_state,
    COUNT(*) AS seller_count
FROM sellers
GROUP BY
    seller_city,
    seller_state
ORDER BY seller_count DESC
LIMIT 20;


-- ============================================================
-- QUERY 4: Seller Sales Performance
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS freight_revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY product_revenue DESC
LIMIT 20;


-- ============================================================
-- QUERY 5: Top 20 Sellers by Revenue
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY revenue DESC
LIMIT 20;


-- ============================================================
-- QUERY 6: Top 20 Sellers by Units Sold
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY items_sold DESC
LIMIT 20;


-- ============================================================
-- QUERY 7: Average Order Item Price by Seller
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_item_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY average_item_price DESC
LIMIT 20;


-- ============================================================
-- QUERY 8: Seller Revenue by State
-- ============================================================

SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS sellers,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY revenue DESC;


-- ============================================================
-- QUERY 9: Seller Revenue Share
-- ============================================================

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_id
)

SELECT
    seller_id,
    ROUND(revenue::NUMERIC, 2) AS revenue,
    ROUND(
        revenue * 100.0 / SUM(revenue) OVER (),
        2
    ) AS revenue_percentage
FROM seller_revenue
ORDER BY revenue DESC
LIMIT 20;


-- ============================================================
-- QUERY 10: Revenue Concentration by Sellers
-- ============================================================

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        revenue,
        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,
        SUM(revenue) OVER () AS total_revenue
    FROM seller_revenue
)

SELECT
    revenue_rank,
    seller_id,
    ROUND(revenue::NUMERIC, 2) AS revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue_rank
        ) * 100.0 / total_revenue,
        2
    ) AS cumulative_revenue_percentage
FROM ranked_sellers
WHERE revenue_rank <= 50
ORDER BY revenue_rank;


-- ============================================================
-- QUERY 11: Seller Freight Analysis
-- ============================================================

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2) AS average_freight,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_state
HAVING COUNT(*) >= 20
ORDER BY average_freight DESC
LIMIT 20;


-- ============================================================
-- QUERY 12: Seller Freight as Percentage of Product Revenue
-- ============================================================

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS freight_revenue,
    ROUND(
        SUM(oi.freight_value) * 100.0 /
        NULLIF(SUM(oi.price), 0),
        2
    ) AS freight_percentage
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_state
HAVING COUNT(*) >= 20
ORDER BY freight_percentage DESC
LIMIT 20;


-- ============================================================
-- QUERY 13: High-Volume Sellers
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_item_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING COUNT(*) >= 100
ORDER BY items_sold DESC;


-- ============================================================
-- QUERY 14: High-Value Sellers
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_item_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING SUM(oi.price) >= 50000
ORDER BY revenue DESC;


-- ============================================================
-- QUERY 15: Sellers with High Volume but Low Average Price
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_item_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING COUNT(*) >= 50
   AND AVG(oi.price) < 50
ORDER BY items_sold DESC;


-- ============================================================
-- QUERY 16: Sellers with Low Volume but High Average Price
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_item_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING COUNT(*) <= 10
   AND AVG(oi.price) > 500
ORDER BY average_item_price DESC;


-- ============================================================
-- QUERY 17: Seller Activity Coverage
-- ============================================================

SELECT
    COUNT(DISTINCT s.seller_id) AS sellers_with_sales,
    (SELECT COUNT(*) FROM sellers) AS total_sellers,
    ROUND(
        COUNT(DISTINCT s.seller_id) * 100.0 /
        (SELECT COUNT(*) FROM sellers),
        2
    ) AS sales_coverage_percentage
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id;


-- ============================================================
-- QUERY 18: Average Revenue per Active Seller
-- ============================================================

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_id
)
SELECT
    ROUND(AVG(revenue)::NUMERIC, 2) AS average_revenue_per_seller,
    ROUND(MIN(revenue)::NUMERIC, 2) AS minimum_revenue,
    ROUND(MAX(revenue)::NUMERIC, 2) AS maximum_revenue,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY revenue)::NUMERIC,
        2
    ) AS median_revenue
FROM seller_revenue;