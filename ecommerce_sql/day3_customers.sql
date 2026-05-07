-- ============================================================
-- DAY 3: Customer Behaviour Analysis
-- ============================================================
-- Techniques: JOINs, subqueries, GROUP BY, HAVING, DATE functions
-- Questions: Q9, Q12, Q13, Q15, Q23
-- ============================================================

-- ============================================================
-- Q9: Category with highest total revenue
-- ============================================================
SELECT 
    categories.category_name,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(order_items.quantity) AS units_sold,
    ROUND(SUM(order_items.quantity * products.price), 2) AS total_revenue,
    ROUND(SUM(order_items.quantity * products.price) * 100.00 /
         SUM(SUM(order_items.quantity * products.price)) OVER (), 1) AS revenue_pct
FROM order_items
JOIN orders ON order_items.order_id = orders.order_id
JOIN products ON order_items.product_id = products.product_id
JOIN categories ON products.category_id = categories.category_id
WHERE order_status = 'Completed'
GROUP BY categories.category_name
ORDER BY total_revenue DESC;

/*
Q9 FINDINGS: Furniture is the highest revenue category at KES 2,554,000
(40.6% of total completed revenue), followed by Electronics at
KES 2,203,000 (35.0%).

Together Furniture and Electronics account for 75.6% of all revenue
from just 2 out of 10 categories — a classic Pareto distribution.

Key insight: Volume does NOT equal revenue.
- Automotive sold the most units (82) but ranks only 4th in revenue
- Food and Books together contribute less than 1% of revenue
  despite having reasonable unit sales

Business recommendation: Prioritize Furniture and Electronics
in inventory management, marketing spend and promotions.
Reconsider the value of maintaining Food and Books categories
which contribute minimally to revenue (combined 0.9%).
*/

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

-- ============================================================
-- Q15: Products that have never been ordered
-- ============================================================

SELECT
    products.product_id,
    products.product_name,
    categories.category_name,
    products.price,
    COUNT(order_items.order_items_id) AS times_ordered
FROM 
    products
JOIN categories ON products.category_id = categories.category_id
LEFT JOIN order_items ON products.product_id = order_items.product_id
WHERE order_items.product_id IS NULL
GROUP BY products.product_id, products.product_name, categories.category_name, products.price
ORDER BY categories.category_name, products.price;

/*
Q15 FINDINGS: Query returns no results — every single product
in the catalogue has been ordered at least once.
With 100 products and 600 order items, each product averages
6 orders, confirming healthy demand across the entire catalogue.

This is a POSITIVE business insight — no dead stock exists.
In real e-commerce businesses, typically 20-30% of products
never get ordered (the "long tail" problem).
Having 100% product coverage suggests either:
1. The product catalogue is well curated to match demand
2. The dataset covers a short time period where all products
   had at least one order placed

Business recommendation: monitor this metric monthly —
any product going 30+ days without an order should be
flagged for review or promotion.
*/

-- ============================================================
-- Q23: Customers who ordered within 30 days of signing up
-- ============================================================

SELECT 
    customers.customer_id,
    customers.first_naMe || ' ' || customers.last_name AS customer_name,
    customers.city, 
    customers.signup_date,
    orders.order_date,
    orders.order_status,
    (orders.order_date - customers.signup_date) AS days_to_first_order,
    payments.amount_paid AS order_value
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN payments ON orders.order_id = payments.order_id
WHERE (orders.order_date - customers.signup_date) <= 30
AND (orders.order_date - customers.signup_date) >= 0
ORDER BY days_to_first_order ASC;

/*
Q23 FINDING: Multiple customers placed orders within 30 days of signup
showing strong early engagement after registration.

Notable findings:
- Esther Mutua (Kisumu) ordered on the SAME DAY as signup (0 days)
  — the fastest converter in the dataset
- Most early purchases happened within the first 2 weeks
- Early orders range from KSH 150 to KSH 25,000 in value
- Not all early orders completed — some were cancelled or returned,
  suggesting impulse purchases that were later reconsidered

Business recommendation: implement a welcome email with a
first-purchase discount triggered immediately after signup —
the data shows customers are most likely to buy in the first
2 weeks after registration.
*/