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
    products.product_id,
    products.product_name,
    categories.category_name,
    products.price,
    SUM(order_items.quantity)                                        AS total_units_sold,
    COUNT(DISTINCT order_items.order_id)                             AS times_ordered,
    ROUND(SUM(order_items.quantity) * products.price, 2)                   AS total_revenue,
    ROW_NUMBER() OVER (ORDER BY SUM(order_items.quantity) DESC)     AS sales_rank
FROM order_items
JOIN products ON products.product_id  = order_items.product_id
JOIN categories ON categories.category_id = products.category_id
GROUP BY products.product_id, products.product_name, categories.category_name, products.price
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
    categories.category_name,
    COUNT(products.product_id)   AS total_products
FROM categories  
LEFT JOIN products ON products.category_id = categories.category_id
GROUP BY categories.category_name
ORDER BY total_products DESC;

-- ============================================================
-- Q6: Customers who signed up in 2023
SELECT
    COUNT(*)   AS customers_2023
FROM customers
WHERE EXTRACT(YEAR FROM signup_date) = 2023;