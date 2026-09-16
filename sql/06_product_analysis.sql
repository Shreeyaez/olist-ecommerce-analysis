-- ============================================================
-- PHASE 7: PRODUCT ANALYSIS
-- Olist Brazilian E-Commerce Dataset
-- ============================================================

-- ============================================================
-- 1: Product Catalog Overview
-- ============================================================

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_category_name) AS categories,
    COUNT(DISTINCT product_weight_g) AS distinct_weights,
    COUNT(DISTINCT product_length_cm) AS distinct_lengths
FROM products;


-- ============================================================
-- 2: Number of Products by Category
-- ============================================================

SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM products
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY product_count DESC;


-- ============================================================
-- 3: Product Sales Performance by Category
-- ============================================================

SELECT
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS freight_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    COALESCE(p.product_category_name, 'unknown')
ORDER BY product_revenue DESC;


-- ============================================================
-- 4: Top 20 Products by Revenue
-- ============================================================

SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    COALESCE(p.product_category_name, 'unknown')
ORDER BY revenue DESC
LIMIT 20;


-- ============================================================
-- 5: Top 20 Products by Units Sold
-- ============================================================

SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    COALESCE(p.product_category_name, 'unknown')
ORDER BY units_sold DESC
LIMIT 20;


-- ============================================================
-- 6: Average Product Price by Category
-- ============================================================

SELECT
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_price,
    ROUND(MIN(oi.price)::NUMERIC, 2) AS minimum_price,
    ROUND(MAX(oi.price)::NUMERIC, 2) AS maximum_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    COALESCE(p.product_category_name, 'unknown')
ORDER BY average_price DESC;


-- ============================================================
-- 7: Category Revenue Share
-- ============================================================

WITH category_revenue AS (
    SELECT
        COALESCE(p.product_category_name, 'unknown') AS product_category_name,
        SUM(oi.price) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        COALESCE(p.product_category_name, 'unknown')
)

SELECT
    product_category_name,
    ROUND(revenue::NUMERIC, 2) AS revenue,
    ROUND(
        revenue * 100.0 / SUM(revenue) OVER (),
        2
    ) AS revenue_percentage
FROM category_revenue
ORDER BY revenue DESC;


-- ============================================================
-- 8: Products with No Recorded Sales
-- ============================================================

SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS product_category_name
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL
ORDER BY product_category_name;


-- ============================================================
-- 9: Number of Products with Recorded Sales
-- ============================================================

SELECT
    COUNT(DISTINCT p.product_id) AS products_with_sales,
    (SELECT COUNT(*) FROM products) AS total_products,
    ROUND(
        COUNT(DISTINCT p.product_id) * 100.0 /
        (SELECT COUNT(*) FROM products),
        2
    ) AS sales_coverage_percentage
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id;


-- ============================================================
-- 10: Product Sales Coverage by Category
-- ============================================================

SELECT
    p.product_category_name,
    COUNT(DISTINCT p.product_id) AS total_products,
    COUNT(DISTINCT oi.product_id) AS products_with_sales,
    ROUND(
        COUNT(DISTINCT oi.product_id) * 100.0 /
        COUNT(DISTINCT p.product_id),
        2
    ) AS sales_coverage_percentage
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY sales_coverage_percentage DESC;


-- ============================================================
-- 11: Product Weight vs Revenue
-- ============================================================

SELECT
    CASE
        WHEN p.product_weight_g < 1000
            THEN 'Under 1kg'
        WHEN p.product_weight_g < 3000
            THEN '1-3kg'
        WHEN p.product_weight_g < 5000
            THEN '3-5kg'
        ELSE '5kg+'
    END AS weight_group,
    COUNT(DISTINCT p.product_id) AS products,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_weight_g IS NOT NULL
GROUP BY weight_group
ORDER BY revenue DESC;


-- ============================================================
-- 12: Product Dimensions vs Freight
-- ============================================================

WITH product_size AS (
    SELECT
        p.product_id,
        CASE
            WHEN p.product_length_cm *
                 p.product_height_cm *
                 p.product_width_cm < 10000
                THEN 'Small'

            WHEN p.product_length_cm *
                 p.product_height_cm *
                 p.product_width_cm < 50000
                THEN 'Medium'

            ELSE 'Large'
        END AS size_group
    FROM products p
    WHERE p.product_length_cm IS NOT NULL
      AND p.product_height_cm IS NOT NULL
      AND p.product_width_cm IS NOT NULL
)

SELECT
    ps.size_group,
    COUNT(DISTINCT ps.product_id) AS products,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2) AS average_freight,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight
FROM product_size ps
JOIN order_items oi
    ON ps.product_id = oi.product_id
GROUP BY ps.size_group
ORDER BY average_freight DESC;


-- ============================================================
-- 13: Category Price vs Sales Volume
-- ============================================================

SELECT
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(*) AS units_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    COALESCE(p.product_category_name, 'unknown')
ORDER BY units_sold DESC;


-- ============================================================
-- 14: Revenue Concentration by Products
-- ============================================================

WITH product_revenue AS (
    SELECT
        p.product_id,
        SUM(oi.price) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_id
),

ranked_products AS (
    SELECT
        product_id,
        revenue,
        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,
        SUM(revenue) OVER () AS total_revenue
    FROM product_revenue
)

SELECT
    revenue_rank,
    product_id,
    ROUND(revenue::NUMERIC, 2) AS revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue_rank
        ) * 100.0 / total_revenue,
        2
    ) AS cumulative_revenue_percentage
FROM ranked_products
WHERE revenue_rank <= 50
ORDER BY revenue_rank;


-- ============================================================
-- 15: Products with High Sales but Low Price
-- ============================================================

SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(*) AS units_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    COALESCE(p.product_category_name, 'unknown')
HAVING COUNT(*) >= 20
   AND AVG(oi.price) < 50
ORDER BY units_sold DESC;


-- ============================================================
-- 16: Products with Low Sales but High Price
-- ============================================================

SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(*) AS units_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS average_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    COALESCE(p.product_category_name, 'unknown')
HAVING COUNT(*) <= 3
   AND AVG(oi.price) > 500
ORDER BY average_price DESC;