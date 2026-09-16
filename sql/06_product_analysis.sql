-- ============================================
-- PHASE 7: PRODUCT ANALYSIS
-- E-commerce Sales & Customer Intelligence
-- ============================================


-- 1. Product Overview
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT product_category_name) AS categories
FROM products;


-- 2. Products by Category
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT p.product_id) AS product_count
FROM products p
GROUP BY p.product_category_name
ORDER BY product_count DESC;


-- 3. Category Sales Performance
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;


-- 4. Top 20 Categories by Revenue
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 20;


-- 5. Top 20 Categories by Sales Volume
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY items_sold DESC
LIMIT 20;


-- 6. Average Product Price by Category
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price), 2) AS average_product_price,
    ROUND(MIN(oi.price), 2) AS minimum_price,
    ROUND(MAX(oi.price), 2) AS maximum_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY average_product_price DESC;


-- 7. Top 20 Products by Revenue
SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS average_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY product_revenue DESC
LIMIT 20;


-- 8. Top 20 Products by Sales Volume
SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS average_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY items_sold DESC
LIMIT 20;


-- 9. Product Revenue Contribution by Category
WITH category_revenue AS (
    SELECT
        COALESCE(p.product_category_name, 'Unknown') AS category,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_category_name
)
SELECT
    category,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        total_revenue * 100.0 /
        SUM(total_revenue) OVER (),
        2
    ) AS revenue_percentage
FROM category_revenue
ORDER BY total_revenue DESC;


-- 10. Category Revenue Rank
WITH category_revenue AS (
    SELECT
        COALESCE(p.product_category_name, 'Unknown') AS category,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_category_name
)
SELECT
    category,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_revenue
ORDER BY revenue_rank;


-- 11. Products with No Sales
SELECT
    COUNT(*) AS products_without_sales
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;


-- 12. Category Products with No Sales
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(*) AS products_without_sales
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL
GROUP BY p.product_category_name
ORDER BY products_without_sales DESC;


-- 13. Product Review Performance
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT r.review_record_id) AS review_count,
    ROUND(AVG(r.review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE r.review_score = 5) AS five_star_reviews,
    COUNT(*) FILTER (WHERE r.review_score = 1) AS one_star_reviews
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN order_reviews r
    ON oi.order_id = r.order_id
GROUP BY p.product_category_name
ORDER BY average_review_score DESC;


-- 14. Product Price Distribution
SELECT
    CASE
        WHEN price < 50 THEN 'Under R$50'
        WHEN price < 100 THEN 'R$50–99'
        WHEN price < 250 THEN 'R$100–249'
        WHEN price < 500 THEN 'R$250–499'
        WHEN price < 1000 THEN 'R$500–999'
        ELSE 'R$1000+'
    END AS price_range,
    COUNT(*) AS items_sold,
    ROUND(SUM(price), 2) AS product_revenue,
    ROUND(AVG(price), 2) AS average_price
FROM order_items
GROUP BY
    CASE
        WHEN price < 50 THEN 'Under R$50'
        WHEN price < 100 THEN 'R$50–99'
        WHEN price < 250 THEN 'R$100–249'
        WHEN price < 500 THEN 'R$250–499'
        WHEN price < 1000 THEN 'R$500–999'
        ELSE 'R$1000+'
    END
ORDER BY MIN(price);


-- 15. Category Sales vs Product Catalog Size
WITH category_catalog AS (
    SELECT
        COALESCE(product_category_name, 'Unknown') AS category,
        COUNT(*) AS catalog_products
    FROM products
    GROUP BY product_category_name
),
category_sales AS (
    SELECT
        COALESCE(p.product_category_name, 'Unknown') AS category,
        COUNT(*) AS items_sold,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_category_name
)
SELECT
    c.category,
    c.catalog_products,
    COALESCE(s.items_sold, 0) AS items_sold,
    ROUND(COALESCE(s.total_revenue, 0), 2) AS total_revenue
FROM category_catalog c
LEFT JOIN category_sales s
    ON c.category = s.category
ORDER BY total_revenue DESC;

-- 16. Category Sales Efficiency
WITH category_catalog AS (
    SELECT
        COALESCE(product_category_name, 'Unknown') AS category,
        COUNT(*) AS catalog_products
    FROM products
    GROUP BY product_category_name
),
category_sales AS (
    SELECT
        COALESCE(p.product_category_name, 'Unknown') AS category,
        COUNT(*) AS items_sold,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_category_name
)
SELECT
    c.category,
    c.catalog_products,
    COALESCE(s.items_sold, 0) AS items_sold,
    ROUND(COALESCE(s.total_revenue, 0), 2) AS total_revenue,
    ROUND(
        COALESCE(s.items_sold, 0)::NUMERIC
        / c.catalog_products,
        2
    ) AS items_sold_per_product,
    ROUND(
        COALESCE(s.total_revenue, 0)
        / c.catalog_products,
        2
    ) AS revenue_per_product
FROM category_catalog c
LEFT JOIN category_sales s
    ON c.category = s.category
ORDER BY revenue_per_product DESC;

-- 17. Top Products Contribution Within Each Category
WITH product_sales AS (
    SELECT
        p.product_category_name AS category,
        p.product_id,
        SUM(oi.price + oi.freight_value) AS product_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_category_name,
        p.product_id
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC
        ) AS product_rank
    FROM product_sales
)
SELECT
    category,
    product_id,
    ROUND(product_revenue, 2) AS product_revenue,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY category, product_rank;

