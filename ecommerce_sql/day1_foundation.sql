<<<<<<< HEAD
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

-- ============================================================
-- DAY 1 FINDINGS & INSIGHTS
-- ============================================================

-- Q1 FINDING: Out of 300 total orders, 220 were completed (73.3%),
-- 40 were cancelled (13.3%), and 40 were returned (13.3%).
-- The cancellation and return rates are equal and relatively high —
-- combined 26.7% of orders did not result in a successful sale.
-- This is worth investigating in later analysis.

-- Q2 FINDING: All top 10 products sold exactly 12 units each,
-- suggesting evenly distributed demand across products.
-- However, revenue varies significantly by price —
-- Watch (Ksh 6,000) generated KES 72,000 while Notebook (Ksh 80)
-- generated only Ksh 960 despite selling the same quantity.
-- High-ticket items like Watch, Jacket and Desktop PC
-- generate more revenue.

-- Q3 FINDING: All 5 cities (Eldoret, Mombasa, Nakuru, Kisumu, Nairobi)
-- have exactly 60 customers each — a perfectly even 20% distribution.
-- This suggests that all the 4 cities have equal customer domination.

<<<<<<< HEAD
-- Q4 FINDING: Total revenue from completed orders is KES 6,296,160.
-- Desktop PC is the top revenue-generating product at KES 1,020,000
-- driven by its high price of KES 85,000 and 12 units sold.
-- Sofa (KES 780,000) and Dining Table (KES 540,000) follow closely.
-- High-ticket items (furniture + electronics) dominate the top 10
-- despite not always having the highest quantities sold 
-- e.g. Bed sold only 4 units but still made KES 320,000.
-- Key insight: price drives revenue more than volume in this dataset.
=======
-- Q4 FINDING: Query to be run in Day 2 revenue analysis.
>>>>>>> 0ef157b55877048ce58c3bd603ad48dab813efcd

-- Q5 FINDING: Automotive has the most products (12),
-- while all other categories have 10 products each except
-- Toys which has only 8. Suggesting a fairly balanced product catalogue.

-- Q6 FINDING: 120 out of 300 customers (40%) signed up in 2023,
-- meaning the remaining 60% signed up in other years.
-- This shows a steady customer acquisition over time.


=======

