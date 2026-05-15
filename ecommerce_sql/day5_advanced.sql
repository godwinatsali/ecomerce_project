-- ============================================================
-- DAY 5: Advanced Analytics & Data Quality
-- ============================================================
-- Techniques: Self-joins, CTEs, subqueries, anomaly detection,
--             data quality checks, retention analysis
-- Questions: Q18, Q20, Q22, Q26, Q29
-- ============================================================

-- ============================================================
-- Q18: Most frequently bought product pairs (self-join)
-- ============================================================
SELECT 
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
                    AND oi1.product_id < oi2.product_id
JOIN products p1 ON p1.product_id = oi1.product_id
JOIN products p2 ON p2.product_id = oi2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 10;
/*
Q18 FINDINGS: Top 10 most frequently bought product pairs
all appear together exactly 6 times — suggesting uniform
purchase patterns typical of a synthetic dataset.

Most pairs are logically complementary within the same category:
- Sports:      Cricket Bat + Skipping Rope
- Food:        Bread + Milk, Tea + Coffee
- Electronics: Smartwatch + Desktop PC
- Beauty:      Makeup Kit + Face Wash, Perfume + Lotion
- Toys:        Puzzle + Board Game
- Automotive:  Car Wax + Dash Cam
- Home:        Mattress + Mirror

Notable anomaly: Rice (Food) + Sofa (Furniture) appear together
6 times — a cross-category pair with no obvious logical connection.
In a real business this would warrant investigation — possibly
bulk buyers or a data entry error.

Business application: these pairs are the foundation of a
"Customers who bought this also bought..." recommendation engine.
Displaying Skipping Rope on the Cricket Bat product page could
increase average order value significantly.
*/

-- ===========================================================
-- Q20: Customer retention rate
-- Customers who reordered within 90 days of their first order
-- ============================================================
-- Part A: Formal retention rate (reorder within 90 days)
WITH customer_orders AS (
    SELECT
        customers.customer_id,
        customers.first_name || ' ' || customers.last_name AS customer_name,
        customers.city,
        MIN(orders.order_date) AS fastest_order_date,
        MAX(orders.order_date) AS slowest_order_date,
        COUNT(DISTINCT orders.order_id) AS total_orders,
        MAX(orders.order_date) - MIN(orders.order_date) AS days_between_orders
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city
), 
    retained_customers AS (
    SELECT *
        FROM customer_orders
        WHERE total_orders > 1
        AND days_between_orders <= 90
)
SELECT
    COUNT(*) AS retained_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM orders) AS total_customers,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM orders), 1) AS retained_rate_pct
FROM retained_customers;

-- Part B: Extended customer purchase behaviour analysis
WITH customer_orders AS (
    SELECT
        customers.customer_id,
        customers.first_name || ' ' || customers.last_name AS customer_name,
        customers.city,
        MIN(orders.order_date) AS fastest_order_date,
        MAX(orders.order_date) AS slowest_order_date,
        COUNT(DISTINCT orders.order_id) AS total_orders,
        MAX(orders.order_date) - MIN(orders.order_date) AS days_between_orders
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city
)
SELECT 
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    COUNT(CASE WHEN total_orders = 1 THEN 1 END) AS one_time_customers,
    ROUND(COUNT(CASE WHEN total_orders > 1 THEN 1 END) * 100 / COUNT(*), 1) AS repeat_rate_pct,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customers
FROM customer_orders
/*
Q20 FINDINGS: Customer retention rate = 0%

Part A Result: 0 customers reordered within 90 days.
Part B Result:
  Total customers:      300
  Repeat customers:     0
  One-time customers:   300 (100%)
  Repeat rate:          0.0%
  Avg orders/customer:  1.00

Every single customer in this dataset placed exactly 1 order.
This means the business has a 0% customer retention rate —
every sale comes from a brand new customer.

This is the most critical business finding in the entire project.
In e-commerce, acquiring a new customer costs 5-7x more than
retaining an existing one. A 0% retention rate means:
- The business depends entirely on new customer acquisition
- No customer has ever come back for a second purchase
- Customer Lifetime Value (CLV) equals a single order value
- Revenue growth requires constant new customer acquisition

In a real business this would be a RED ALERT requiring
immediate investigation into:
1. Post-purchase experience (delivery, product quality)
2. Email/SMS re-engagement campaigns
3. Loyalty programme implementation
4. Reasons for non-return (surveys, reviews)

Note: This pattern is consistent with a synthetic dataset
where each customer was generated with exactly one order.
In real e-commerce data, retention rates typically range
from 20-40% for healthy businesses.
*/

-- ============================================================
-- Q22: Data quality check — payment vs product total mismatch
-- ============================================================
WITH order_product_total AS(
    SELECT 
        order_items.order_id,
        ROUND(SUM(order_items.quantity * products.price), 2) AS expected_total
    FROM order_items
    JOIN products ON order_items.product_id = products.product_id
    GROUP BY order_items.order_id
),
order_payment AS (
    SELECT
        order_id,
        amount_paid AS actual_payment
    FROM payments
)
SELECT
    orders.order_id,
    orders.order_status,
    order_product_total.expected_total,
    order_payment.actual_payment,
    ROUND(order_product_total.expected_total - order_payment.actual_payment) AS difference,
    CASE
        WHEN order_payment.actual_payment > order_product_total.expected_total THEN 'Overpaid'
        WHEN order_payment.actual_payment < order_product_total.expected_total THEN 'Underpaid'
        ELSE 'Match'
    END AS payment_status
FROM orders
JOIN order_product_total ON orders.order_id = order_product_total.order_id
JOIN order_payment ON orders.order_id = order_payment.order_id
WHERE ROUND(order_payment.actual_payment - order_product_total.expected_total, 2) != 0
ORDER BY ABS(order_payment.actual_payment - order_product_total.expected_total) DESC
LIMIT 20;
/*
Q22 FINDINGS: CRITICAL DATA QUALITY ISSUE DETECTED

Every order in the dataset shows a significant underpayment gap
between expected product total and actual payment recorded.

Most extreme cases:
  Order 76:  expected KHS 182,000 → paid KHS 200    (0.1% paid)
  Order 68:  expected KHS 130,300 → paid KHS 800    (0.6% paid)
  Order 69:  expected KHS 120,000 → paid KHS 500    (0.4% paid)

Two possible explanations:

1. DATA MISMATCH: The payments table records individual item
   payments (e.g. one product in a multi-product order) while
   order_items records the full order total. The tables are
   not aligned at the same level of granularity.

2. GENUINE REVENUE LEAKAGE: If this were real data, customers
   are being charged only a fraction of their order value —
   representing massive revenue loss for the business.

Additional finding: Cancelled (order 19, 169) and Returned
(order 120) orders also show payments recorded — suggesting
refunds were never processed for failed orders.

Business recommendation: Immediately audit the payment
processing system to determine whether the mismatch is a
reporting/data alignment issue or genuine revenue leakage.
This should be escalated to the finance team as a priority.

Note: This finding demonstrates the value of data quality
checks in SQL analysis — without this query the revenue
discrepancy would go completely undetected.
*/

-- ============================================================
-- Q26: Revenue per category vs overall average using CTE
-- ============================================================
WITH category_revenue AS (
    SELECT
        categories.category_name,
        COUNT(DISTINCT orders.order_id) AS total_orders,
        ROUND(SUM(order_items.quantity * products.price), 2) AS category_revenue,
        ROUND(AVG(order_items.quantity * products.price), 2) AS avg_order_value
    FROM order_items
    JOIN orders ON order_items.order_id = orders.order_id
    JOIN products ON order_items.product_id = products.product_id
    JOIN categories ON products.category_id = categories.category_id
    WHERE orders.order_status = 'Completed'
    GROUP BY categories.category_name
),
overall_average AS (
    SELECT ROUND(AVG(category_revenue), 2) AS avg_revenue_across_categories
    FROM category_revenue
)
SELECT
    category_revenue.category_name,
    category_revenue.total_orders,
    category_revenue.category_revenue,
    overall_average.avg_revenue_across_categories,
    ROUND(category_revenue.category_revenue - overall_average.avg_revenue_across_categories, 2) AS diff_from_average,
    CASE
        WHEN category_revenue.category_revenue > overall_average.avg_revenue_across_categories
        THEN 'Above_average'
        ELSE 'Below_average'
    END AS perfomance
    FROM category_revenue
    CROSS JOIN overall_average
    ORDER BY category_revenue.category_revenue DESC;
/*
Q26 FINDINGS: Only 2 out of 10 categories perform above the
overall average revenue of KHS 629,816.

Above average performers:
  Furniture    - KHS 2,554,000 (304% above average)
  Electronics  - KHS 2,203,000 (249% above average)

Below average performers (8 categories):
  Home     - closest to average (only KHS 99,216 below)
  Food     - furthest below (KHS 614,216 below — 97% below average)

The average is heavily inflated by Furniture and Electronics
dominance — making it an unfair benchmark for other categories.
A better analysis would segment categories into tiers:

  Tier 1 (Premium):    Furniture, Electronics  (>KHS 1M)
  Tier 2 (Mid-range):  Home, Automotive        (KHS 300K-600K)
  Tier 3 (Low-value):  Clothing, Sports, Toys,
                       Beauty, Books, Food      (<KHS 250K)

Business recommendation: do not use a single average as the
performance benchmark when revenue distribution is this skewed.
Use tier-based benchmarks instead for fairer category evaluation.
*/

-- ============================================================
-- Q29: Shipping routes with highest average delay
-- ============================================================
WITH shipping_analysis AS (
    SELECT
        customers.city AS customer_city,
        COUNT(DISTINCT orders.order_id) AS total_shipments,
        ROUND(AVG(shipping.delivery_date - shipping.shipping_date), 1) AS avg_delivery_days,
        ROUND(AVG(shipping_cost), 2) AS avg_shipping_cost,
        MIN(shipping.delivery_date - shipping.shipping_date) AS fastest_days,
        MAX(shipping.delivery_date - shipping.shipping_date) AS slowest_days,
        ROUND(AVG(shipping.delivery_date - shipping.shipping_date) - 
        MIN(AVG(shipping.delivery_date - shipping.shipping_date))
        OVER(), 1) AS days_above_fastest_route
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    JOIN shipping ON orders.order_id = orders.order_id
    GROUP BY customers.city
)
SELECT
    customer_city,
    total_shipments,
    avg_delivery_days,
    avg_shipping_cost,
    fastest_days,
    slowest_days,
    days_above_fastest_route,
    RANK() OVER(ORDER BY avg_delivery_days DESC) AS delay_rank
FROM shipping_analysis
ORDER BY avg_delivery_days DESC;
/*
Q29 FINDINGS: All 5 shipping routes show identical performance —
exactly 3 days delivery, KHS 658.70 average shipping cost,
zero variation between fastest and slowest delivery.

All cities rank equally at position 1 — no route is slower
or faster than any other. Days above fastest route = 0.0
for all cities confirming perfect uniformity.

This uniformity is a synthetic dataset characteristic.
In real e-commerce shipping data you would expect:
- Nairobi:  1-2 days (closest to distribution hub)
- Mombasa:  2-3 days (coastal, port city)
- Kisumu:   3-4 days (western Kenya)
- Nakuru:   2-3 days (central Kenya)
- Eldoret:  3-5 days (furthest from Nairobi hub)

The identical shipping costs (KHS 658.70) across all cities
also confirms a flat-rate pricing model in this dataset.

Business recommendation: in a real scenario, route-based
delivery time analysis would identify underperforming
logistics partners and routes requiring service improvement.
*/
