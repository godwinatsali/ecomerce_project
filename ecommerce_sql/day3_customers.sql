-- ============================================================
-- DAY 3: Customer Behaviour Analysis
-- ============================================================
-- Techniques: JOINs, subqueries, GROUP BY, HAVING, DATE functions
-- Questions: Q9, Q12, Q13, Q15, Q23
-- ============================================================

-- ============================================================
-- Q12: Repeat buyer analysis
-- ============================================================

-- Part A: Confirm every customer_id has exactly 1 order

SELECT 
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT orders.customer_id) AS unique_customers,
    COUNT(DISTINCT orders.order_id) = 
    COUNT(DISTINCT orders.customer_id) AS one_order_per_customer
FROM 
    orders;

-- Part B: Find duplicate customer names (same person, different ID)

SELECT 
    customers.city,
    customers.first_name || ' ' || customers.last_name AS customer_name,
    COUNT(DISTINCT customers.customer_id) AS duplicate_ids,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(payments.amount_paid) AS total_spent,
    MIN(orders.order_date) AS first_order_date,
    MAX(orders.order_date) AS last_order_date,
    MAX(orders.order_date) - MIN(orders.order_date) AS days_as_customer
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN payments ON orders.order_id = payments.order_id
GROUP BY customer_name, customers.city
HAVING COUNT(DISTINCT customers.customer_id) > 1
ORDER BY total_orders DESC
LIMIT 10;

-- Q12 Findings:
 /*
Every customer_id placed exactly 1 order (confirmed by Part A).
However Part B reveals duplicate customer names across multiple IDs:
- John Kimani (Nairobi) appears 21 times with KES 334,700 total spend
- Jane Otieno (Mombasa) appears 21 times with KES 300,900 total spend
- Peter Wanjiku (Kisumu) appears 21 times with KES 206,300 total spend

This is a DATA QUALITY ISSUE — the same customers were registered
multiple times with different IDs instead of being linked to one account.
In a real business this would inflate customer count and undercount
true repeat purchase behaviour.
Business recommendation: implement email/phone deduplication logic
during customer registration to prevent duplicate accounts.
*/

-- ============================================================
-- Q13: Average order value (AOV) per city
-- ============================================================

SELECT 
    customers.city,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT customers.customer_id) AS total_customers,
    ROUND(SUM(payments.amount_paid), 2) AS total_revenue,
    ROUND(AVG(payments.amount_paid), 2) AS avg_order_value,
    ROUND(MAX(payments.amounT_paid), 2) AS max_order_value,
    ROUND(MIN(payments.amount_paid), 2) AS min_order_value
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN payments ON orders.order_id = payments.order_id
GROUP BY customers.city
ORDER BY avg_order_value DESC;

/*
Q13 FINDINGS: All 5 cities have exactly 60 orders and 60 customers.
Despite equal order volumes, revenue varies dramatically by city:
- Mombasa has the highest AOV at KES 18,926 — 7x higher than Nakuru
- Nakuru has the lowest AOV at KES 2,679 despite equal order count
- Mombasa generates KES 1,135,570 total — 41% of all revenue alone
- Nairobi surprisingly ranks 2nd not 1st despite being the capital

This confirms that order VALUE not order VOLUME drives revenue.
Mombasa customers consistently purchase higher-priced products
(max order KES 85,000) while Nakuru customers buy cheaper items
(max order only KES 25,000).
Business recommendation: target high-value product marketing
campaigns specifically at Mombasa and Nairobi customers.
*/