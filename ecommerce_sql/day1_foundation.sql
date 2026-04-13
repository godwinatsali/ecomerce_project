-- ============================================================
-- DAY 1: Foundation & Data Exploration
-- ============================================================

-- Q1: Total orders by status + percentages
SELECT
    COUNT(*)                                                        AS total_orders,
    COUNT(CASE WHEN order_status = 'Completed'  THEN 1 END)        AS completed,
    COUNT(CASE WHEN order_status = 'Cancelled'  THEN 1 END)        AS cancelled,
    COUNT(CASE WHEN order_status = 'Returned'   THEN 1 END)        AS returned,
    ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 1) AS completed_pct,
    ROUND(COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*), 1) AS cancelled_pct,
    ROUND(COUNT(CASE WHEN order_status = 'Returned'  THEN 1 END) * 100.0 / COUNT(*), 1) AS returned_pct
FROM orders;

-- ============================================================
-- Q2: Top 10 best-selling products by total quantity sold
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.price,
    SUM(oi.quantity)                                        AS total_units_sold,
    COUNT(DISTINCT oi.order_id)                             AS times_ordered,
    ROUND(SUM(oi.quantity) * p.price, 2)                   AS total_revenue,
    ROW_NUMBER() OVER (ORDER BY SUM(oi.quantity) DESC)     AS sales_rank
FROM order_items  oi
JOIN products     p  ON p.product_id  = oi.product_id
JOIN categories   c  ON c.category_id = p.category_id
GROUP BY p.product_id, p.product_name, c.category_name, p.price
ORDER BY total_units_sold DESC
LIMIT 10;

-- ============================================================
-- Q3: City with the most customers
SELECT
    city,
    COUNT(*)                                                AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)    AS pct_of_total
FROM customers
GROUP BY city
ORDER BY total_customers DESC;

-- ============================================================
-- Q5: Number of products per category
SELECT
    c.category_name,
    COUNT(p.product_id)   AS total_products
FROM categories  c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_products DESC;

-- ============================================================
-- Q6: Customers who signed up in 2023
SELECT
    COUNT(*)   AS customers_2023
FROM customers
WHERE EXTRACT(YEAR FROM signup_date) = 2023;