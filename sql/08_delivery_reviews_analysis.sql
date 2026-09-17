-- ============================================================
-- PHASE 9: DELIVERY & REVIEW ANALYSIS
-- Olist Brazilian E-Commerce Dataset
-- ============================================================


-- ============================================================
-- QUERY 1: Delivery Overview
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            order_delivered_customer_date::DATE
            - order_purchase_timestamp::DATE
        )::NUMERIC,
        2
    ) AS average_delivery_days

FROM orders

WHERE order_delivered_customer_date IS NOT NULL;


-- ============================================================
-- QUERY 2: Delivery Time Distribution
-- ============================================================

SELECT
    CASE
        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 3
            THEN '0-3 days'

        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 7
            THEN '4-7 days'

        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 14
            THEN '8-14 days'

        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 21
            THEN '15-21 days'

        ELSE '22+ days'
    END AS delivery_bucket,

    COUNT(*) AS orders

FROM orders

WHERE order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 3
            THEN '0-3 days'

        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 7
            THEN '4-7 days'

        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 14
            THEN '8-14 days'

        WHEN order_delivered_customer_date::DATE
             - order_purchase_timestamp::DATE <= 21
            THEN '15-21 days'

        ELSE '22+ days'
    END

ORDER BY
    MIN(
        order_delivered_customer_date::DATE
        - order_purchase_timestamp::DATE
    );


-- ============================================================
-- QUERY 3: On-Time vs Late Delivery
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date::DATE
              <= order_estimated_delivery_date::DATE
    ) AS delivered_on_time,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date::DATE
              > order_estimated_delivery_date::DATE
    ) AS delivered_late,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date::DATE
                  <= order_estimated_delivery_date::DATE
        ) * 100.0 / COUNT(*),
        2
    ) AS on_time_percentage,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date::DATE
                  > order_estimated_delivery_date::DATE
        ) * 100.0 / COUNT(*),
        2
    ) AS late_percentage

FROM orders

WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- ============================================================
-- QUERY 4: Delivery Variance
-- ============================================================

SELECT
    ROUND(
        AVG(
            order_delivered_customer_date::DATE
            - order_estimated_delivery_date::DATE
        )::NUMERIC,
        2
    ) AS average_delivery_variance_days,

    ROUND(
        AVG(
            GREATEST(
                order_delivered_customer_date::DATE
                - order_estimated_delivery_date::DATE,
                0
            )
        )::NUMERIC,
        2
    ) AS average_late_days

FROM orders

WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- ============================================================
-- QUERY 5: Delivery Performance by Customer State
-- ============================================================

SELECT
    c.customer_state,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            o.order_delivered_customer_date::DATE
            - o.order_purchase_timestamp::DATE
        )::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date::DATE
                  > o.order_estimated_delivery_date::DATE
        ) * 100.0 / COUNT(*),
        2
    ) AS late_percentage

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY c.customer_state

ORDER BY average_delivery_days DESC;


-- ============================================================
-- QUERY 6: Delivery Performance by Seller State
-- ============================================================
-- Note:
-- This is a seller-origin perspective.
-- An order can contain items from more than one seller,
-- so DISTINCT order_id is used to avoid item-level
-- duplication within each seller state.
-- ============================================================

SELECT
    s.seller_state,

    COUNT(DISTINCT oi.order_id) AS delivered_orders,

    ROUND(
        AVG(
            o.order_delivered_customer_date::DATE
            - o.order_purchase_timestamp::DATE
        )::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        COUNT(DISTINCT oi.order_id) FILTER (
            WHERE o.order_delivered_customer_date::DATE
                  > o.order_estimated_delivery_date::DATE
        ) * 100.0
        / COUNT(DISTINCT oi.order_id),
        2
    ) AS late_percentage

FROM order_items oi

JOIN sellers s
    ON oi.seller_id = s.seller_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY s.seller_state

ORDER BY average_delivery_days DESC;


-- ============================================================
-- QUERY 7: Review Score Distribution
-- ============================================================

SELECT
    review_score,

    COUNT(*) AS reviews,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS review_percentage

FROM order_reviews

GROUP BY review_score

ORDER BY review_score;


-- ============================================================
-- QUERY 8: Average Review Score
-- ============================================================

SELECT
    ROUND(
        AVG(review_score)::NUMERIC,
        2
    ) AS average_review_score,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY review_score
        )::NUMERIC,
        2
    ) AS median_review_score

FROM order_reviews;


-- ============================================================
-- QUERY 9: Review Score vs Delivery Performance
-- ============================================================

SELECT
    r.review_score,

    COUNT(*) AS reviews,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(
            o.order_delivered_customer_date::DATE
            - o.order_purchase_timestamp::DATE
        )::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(
            GREATEST(
                o.order_delivered_customer_date::DATE
                - o.order_estimated_delivery_date::DATE,
                0
            )
        )::NUMERIC,
        2
    ) AS average_late_days,

    ROUND(
        COUNT(DISTINCT r.order_id) FILTER (
            WHERE o.order_delivered_customer_date::DATE
                  > o.order_estimated_delivery_date::DATE
        ) * 100.0
        / COUNT(DISTINCT r.order_id),
        2
    ) AS late_percentage

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY r.review_score

ORDER BY r.review_score;


-- ============================================================
-- QUERY 10: Review Score vs Freight
-- ============================================================
-- Freight and item price are item-level metrics.
-- Reviewed orders are counted distinctly.
-- ============================================================

SELECT
    r.review_score,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(oi.freight_value)::NUMERIC,
        2
    ) AS average_freight,

    ROUND(
        AVG(oi.price)::NUMERIC,
        2
    ) AS average_item_price

FROM order_reviews r

JOIN order_items oi
    ON r.order_id = oi.order_id

GROUP BY r.review_score

ORDER BY r.review_score;


-- ============================================================
-- QUERY 11: Review Score by Product Category
-- ============================================================

SELECT
    COALESCE(
        p.product_category_name,
        'unknown'
    ) AS product_category,

    COUNT(*) AS reviews,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews r

JOIN order_items oi
    ON r.order_id = oi.order_id

JOIN products p
    ON oi.product_id = p.product_id

GROUP BY product_category

HAVING COUNT(*) >= 50

ORDER BY average_review_score DESC;


-- ============================================================
-- QUERY 12: Review Score by Seller
-- ============================================================

SELECT
    s.seller_id,

    s.seller_state,

    COUNT(*) AS reviews,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews r

JOIN order_items oi
    ON r.order_id = oi.order_id

JOIN sellers s
    ON oi.seller_id = s.seller_id

GROUP BY
    s.seller_id,
    s.seller_state

HAVING COUNT(*) >= 20

ORDER BY average_review_score DESC;


-- ============================================================
-- QUERY 13: Late Delivery by Review Score
-- ============================================================

SELECT
    r.review_score,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    COUNT(DISTINCT r.order_id) FILTER (
        WHERE o.order_delivered_customer_date::DATE
              > o.order_estimated_delivery_date::DATE
    ) AS late_orders,

    ROUND(
        COUNT(DISTINCT r.order_id) FILTER (
            WHERE o.order_delivered_customer_date::DATE
                  > o.order_estimated_delivery_date::DATE
        ) * 100.0
        / COUNT(DISTINCT r.order_id),
        2
    ) AS late_percentage

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY r.review_score

ORDER BY r.review_score;


-- ============================================================
-- QUERY 14: Delivery Time vs Review Score
-- ============================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 3
            THEN '0-3 days'

        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 7
            THEN '4-7 days'

        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 14
            THEN '8-14 days'

        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 21
            THEN '15-21 days'

        ELSE '22+ days'
    END AS delivery_bucket,

    COUNT(*) AS reviews,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 3
            THEN '0-3 days'

        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 7
            THEN '4-7 days'

        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 14
            THEN '8-14 days'

        WHEN o.order_delivered_customer_date::DATE
             - o.order_purchase_timestamp::DATE <= 21
            THEN '15-21 days'

        ELSE '22+ days'
    END

ORDER BY
    MIN(
        o.order_delivered_customer_date::DATE
        - o.order_purchase_timestamp::DATE
    );


-- ============================================================
-- QUERY 15: Monthly Delivery Performance
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS purchase_month,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            o.order_delivered_customer_date::DATE
            - o.order_purchase_timestamp::DATE
        )::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date::DATE
                  > o.order_estimated_delivery_date::DATE
        ) * 100.0 / COUNT(*),
        2
    ) AS late_percentage

FROM orders o

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY purchase_month

ORDER BY purchase_month;


-- ============================================================
-- QUERY 16: Monthly Review Performance
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS purchase_month,

    COUNT(*) AS reviews,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

GROUP BY purchase_month

ORDER BY purchase_month;


-- ============================================================
-- QUERY 17: Extreme Delivery Delays
-- ============================================================

SELECT
    o.order_id,

    o.order_purchase_timestamp::DATE AS purchase_date,

    o.order_delivered_customer_date::DATE AS delivered_date,

    o.order_estimated_delivery_date::DATE AS estimated_date,

    o.order_delivered_customer_date::DATE
    - o.order_purchase_timestamp::DATE AS delivery_days,

    o.order_delivered_customer_date::DATE
    - o.order_estimated_delivery_date::DATE AS delay_days

FROM orders o

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

ORDER BY delay_days DESC

LIMIT 20;


-- ============================================================
-- QUERY 18: On-Time vs Late Reviews
-- ============================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date::DATE
             <= o.order_estimated_delivery_date::DATE
            THEN 'on_time'

        ELSE 'late'
    END AS delivery_status,

    COUNT(*) AS reviews,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_status

ORDER BY delivery_status;


-- ============================================================
-- QUERY 19: Low Review Score + Late Delivery
-- ============================================================

SELECT
    COUNT(DISTINCT r.order_id) AS low_score_late_orders,

    ROUND(
        COUNT(DISTINCT r.order_id) * 100.0
        /
        (
            SELECT COUNT(DISTINCT r2.order_id)
            FROM order_reviews r2
            JOIN orders o2
                ON r2.order_id = o2.order_id
            WHERE o2.order_delivered_customer_date IS NOT NULL
              AND o2.order_estimated_delivery_date IS NOT NULL
        ),
        2
    ) AS percentage_of_reviewed_delivered_orders

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

WHERE r.review_score <= 2
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date::DATE
      > o.order_estimated_delivery_date::DATE;


-- ============================================================
-- QUERY 20: Review Quality by Delivery Status
-- ============================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date::DATE
             <= o.order_estimated_delivery_date::DATE
            THEN 'on_time'

        ELSE 'late'
    END AS delivery_status,

    COUNT(*) AS reviews,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score,

    COUNT(*) FILTER (
        WHERE r.review_score <= 2
    ) AS low_score_reviews,

    ROUND(
        COUNT(*) FILTER (
            WHERE r.review_score <= 2
        ) * 100.0 / COUNT(*),
        2
    ) AS low_score_percentage

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_status

ORDER BY delivery_status;