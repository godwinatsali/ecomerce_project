-- ============================================================
-- DAY 3: Customer Behaviour Analysis
-- ============================================================
-- Techniques: JOINs, subqueries, GROUP BY, HAVING, DATE functions
-- Questions: Q9, Q12, Q13, Q15, Q23
-- ============================================================

-- ============================================================
-- Q12: Identify repeat buyers (customers with more than 1 order)
-- ============================================================
SELECT 
    customers.customer_id,
    customers.first_name || ' ' || customers.last_name AS customer_name,
    customers.city,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(payments.amount_paid) AS total_spent,
    MIN(orders.order_date) AS first_order_date,
    MAX(orders.order_date) AS last_order_date,
    MAX(orders.order_date) - MIN(orders.order_date) AS days_as_customer
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN payments ON orders.order_id = payments.order_id
GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city
HAVING COUNT(DISTINCT orders.order_id) >= 1
ORDER BY total_orders DESC, total_spent DESC
