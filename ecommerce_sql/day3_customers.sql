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