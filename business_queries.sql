-- ============================================================
-- SQL Mini Project — 10 Business Queries
-- E-Commerce Analytics
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- Q1: Total Revenue Generated (All Time)
-- Business Question: How much total revenue has our store made?
-- ─────────────────────────────────────────────────────────────
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status != 'cancelled';


-- ─────────────────────────────────────────────────────────────
-- Q2: Monthly Revenue Trend
-- Business Question: How is revenue trending month over month?
-- ─────────────────────────────────────────────────────────────
SELECT
    TO_CHAR(o.order_date, 'YYYY-MM')            AS month,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)  AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- Q3: Top 5 Best-Selling Products by Revenue
-- Business Question: Which products drive the most revenue?
-- ─────────────────────────────────────────────────────────────
SELECT
    p.name                                       AS product_name,
    p.category,
    SUM(oi.quantity)                             AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)   AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
WHERE o.status != 'cancelled'
GROUP BY p.product_id, p.name, p.category
ORDER BY total_revenue DESC
LIMIT 5;


-- ─────────────────────────────────────────────────────────────
-- Q4: Customer Lifetime Value (CLV) — Top 10 Customers
-- Business Question: Who are our highest-value customers?
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.name,
    c.country,
    COUNT(DISTINCT o.order_id)                   AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)   AS lifetime_value
FROM customers c
JOIN orders o     ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id  = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY c.customer_id, c.name, c.country
ORDER BY lifetime_value DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────────────
-- Q5: Average Order Value (AOV) by Country
-- Business Question: Which countries have the highest order values?
-- ─────────────────────────────────────────────────────────────
SELECT
    c.country,
    COUNT(DISTINCT o.order_id)                      AS num_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price) /
        COUNT(DISTINCT o.order_id), 2
    )                                               AS avg_order_value
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY c.country
ORDER BY avg_order_value DESC;


-- ─────────────────────────────────────────────────────────────
-- Q6: Customer Retention — Repeat vs One-Time Buyers
-- Business Question: What share of customers have bought more than once?
-- ─────────────────────────────────────────────────────────────
WITH purchase_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS num_orders
    FROM orders
    WHERE status != 'cancelled'
    GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN num_orders = 1  THEN 1 ELSE 0 END)  AS one_time_buyers,
    SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END)  AS repeat_buyers,
    ROUND(
        100.0 * SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END)
              / COUNT(*), 1
    )                                                  AS repeat_rate_pct
FROM purchase_counts;


-- ─────────────────────────────────────────────────────────────
-- Q7: Order Status Breakdown
-- Business Question: What percentage of orders are delivered, pending, or cancelled?
-- ─────────────────────────────────────────────────────────────
SELECT
    status,
    COUNT(*)                                   AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- ─────────────────────────────────────────────────────────────
-- Q8: Product Return Rate
-- Business Question: Which products have the highest return rates? (Quality signal)
-- ─────────────────────────────────────────────────────────────
SELECT
    p.name                                                AS product_name,
    p.category,
    COUNT(DISTINCT oi.order_id)                           AS times_ordered,
    COUNT(DISTINCT r.return_id)                           AS times_returned,
    ROUND(
        100.0 * COUNT(DISTINCT r.return_id) /
        NULLIF(COUNT(DISTINCT oi.order_id), 0), 1
    )                                                     AS return_rate_pct
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN returns      r  ON p.product_id = r.product_id
GROUP BY p.product_id, p.name, p.category
HAVING COUNT(DISTINCT oi.order_id) > 0
ORDER BY return_rate_pct DESC;


-- ─────────────────────────────────────────────────────────────
-- Q9: Low Stock Alert
-- Business Question: Which products are running low and need restocking?
-- ─────────────────────────────────────────────────────────────
SELECT
    product_id,
    name                                       AS product_name,
    category,
    stock                                      AS units_remaining,
    CASE
        WHEN stock = 0        THEN '🔴 Out of Stock'
        WHEN stock < 50       THEN '🟠 Critical — Reorder Now'
        WHEN stock < 100      THEN '🟡 Low Stock — Monitor'
        ELSE                       '🟢 Sufficient Stock'
    END                                        AS stock_status
FROM products
ORDER BY stock ASC;


-- ─────────────────────────────────────────────────────────────
-- Q10: Revenue by Product Category
-- Business Question: Which product categories contribute the most to revenue?
-- ─────────────────────────────────────────────────────────────
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id)                  AS orders_containing_category,
    SUM(oi.quantity)                             AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)   AS category_revenue,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price) /
        SUM(SUM(oi.quantity * oi.unit_price)) OVER(), 1
    )                                            AS revenue_share_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status != 'cancelled'
GROUP BY p.category
ORDER BY category_revenue DESC;
