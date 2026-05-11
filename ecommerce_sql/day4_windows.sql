-- ============================================================
-- DAY 4: Window Functions & Ranking
-- ============================================================
-- Techniques: RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD,
--             Running totals, Moving averages, NTILE
-- Questions: Q16, Q17, Q19, Q21, Q10
-- ============================================================

-- ============================================================
-- Q16: Top 10 customers by lifetime spend using DENSE_RANK()
-- ============================================================
SELECT *
FROM(
    SELECT
    customers.customer_id,
    customers.first_name || ' ' || customers.last_name AS customer_name,
    customers.city,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    ROUND(SUM(payments.amount_paid), 2) AS lifetime_spend,
    DENSE_RANK() OVER (ORDER BY SUM(payments.amount_paid) DESC
     ) AS spend_rank
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN payments ON orders.order_id = payments.order_id
GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city
) ranked_customers
WHERE spend_rank <= 10
ORDER BY spend_rank;

/*
Q16 FINDINGS: Top spending customers are concentrated in Mombasa
confirming the high AOV finding from Q13.

Rank 1 (KES 85,000): 5 customers — all from Mombasa
Rank 2 (KES 80,000): 5 customers — all from Mombasa
Rank 3 (KES 65,000): 8 customers — mostly Nairobi

The duplicate customer name issue identified in Q12 is clearly
visible here — Daniel Kiptoo, Linda Njeri and Jane Otieno each
appear multiple times with different customer IDs but the same
spending amounts, confirming these are the same people registered
multiple times.

DENSE_RANK correctly handles the many ties — rank 1 has 5 customers
all spending exactly KES 85,000, rank 2 has 5 customers at KES 80,000.
Using RANK() instead would have produced gaps (rank 1, 1, 1, 1, 1, 6...)
making the leaderboard misleading.
*/

-- ============================================================
-- Q17: 3-month rolling average revenue using window functions
-- ============================================================
WITH monthly_revenue AS (
SELECT 
    TO_CHAR (orders.order_date, 'Month') AS month_name,
    EXTRACT(MONTH FROM orders.order_date) AS month_num,
    ROUND(SUM(payments.amount_paid), 2) AS monthly_revenue
FROM orders
JOIN payments ON orders.order_id = payments.order_id
GROUP BY month_name, month_num
)
SELECT 
    month_name,
    month_num,
    monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (ORDER BY month_num
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3month_avg
FROM monthly_revenue
ORDER BY month_num;

/*
Q17 FINDING: 3-month rolling average smooths out monthly volatility
and reveals the true revenue trend.

Key observations:
- Rolling average grows from KES 265,900 (Jan) to KSH 395,867 (Sep)
  showing genuine underlying business growth of 49% over 9 months
- March raw revenue crashed to KES 147,350 but rolling avg only
  dropped to KSH 275,983 — confirming March was a temporary dip
- September is the strongest period — highest in both raw revenue
  (KSH 447,300) and rolling average (KSH 395,867)
- October rolling avg (KSH 339,400) suggests Q4 may be slowing down

The rolling average is more reliable for business decisions than
raw monthly revenue — it filters out noise and shows the real trend.
Business recommendation: use rolling averages in monthly reports
to avoid overreacting to single good or bad months.
*/

-- ============================================================
-- Q19: Top product per category using ROW_NUMBER()
-- ============================================================
WITH product_revenue AS (
    SELECT 
        categories.category_name,
        products.product_name,
        products.price,
        SUM(order_items.quantity) AS units_sold,
        ROUND(SUM(order_items.quantity * products.price), 2) AS total_revenue,
        ROW_NUMBER() OVER 
                    (PARTITION BY categories.category_name
                    ORDER BY SUM(order_items.quantity * products.price) DESC) AS rank_in_category
FROM order_items
JOIN products ON order_items.product_id = products.product_id
JOIN categories ON products.category_id = categories.category_id
JOIN orders ON order_items.order_id = orders.order_id
WHERE order_status = 'Completed'
GROUP BY category_name, product_name, price
)
SELECT 
    category_name,
    product_name,
    price,
    units_sold,
    total_revenue,
    rank_in_category
FROM 
    product_revenue
WHERE rank_in_category = 1
ORDER BY total_revenue DESC;

/*
Q19 FINDING: Top product per category reveals massive revenue
disparity driven entirely by price differences.

Category Champions:
  Electronics → Desktop PC     (KSH 1,020,000) — revenue Top
  Furniture   → Sofa           (KSH   780,000) — strong 2nd
  Food        → Cooking Oil    (KSH    3,600) — bottom

Desktop PC generates 283 times more revenue than Cooking Oil
despite both being their category's top performer.
This confirms price is the dominant revenue driver.

Toys, Beauty and Sports all tie at KSH 30,000 —
ROW_NUMBER() selected one winner per category arbitrarily
when revenues were equal. In a real scenario DENSE_RANK()
would be more appropriate to identify ALL tied winners.

Business recommendation: focus inventory and promotions on
Desktop PC and Sofa — two products that alone account for
a significant portion of total completed revenue.
*/

-- ============================================================
-- Q21: Cumulative revenue over time (running total)
-- ============================================================
WITH monthly AS(
  SELECT 
    TO_CHAR(orders.order_date, 'Month') AS month_name,
    EXTRACT(MONTH FROM orders.order_date) AS month_num,
    ROUND(SUM(payments.amount_paid), 2) AS monthly_revenue
  FROM orders
  JOIN payments ON orders.order_id = payments.order_id
  GROUP BY month_name, month_num
)
SELECT 
  month_name,
  month_num,
  monthly_revenue,
  ROUND(SUM(monthly_revenue) OVER (
      ORDER BY month_num
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue,
  ROUND(monthly_revenue * 100 / SUM(monthly_revenue) OVER (), 1) AS monthly_pct_of_total
  FROM monthly
  ORDER BY month_num

  /*
Q21 FINDINGS: Cumulative revenue reached KHS 3,294,450 over 10 months
(January to October 2024).

Key milestones:
- KHS 1M crossed between March and April (end of Q1)
- KHS 2M crossed between June and July (mid-year)
- KHS 3M crossed in September (month 9 of 10)

Revenue concentration:
- Top 3 months (Sep 13.6%, May 13.0%, Feb 12.6%) = 39.2% of total
- Bottom 3 months (Mar 4.5%, Oct 7.7%, Jan 8.1%) = 20.3% of total
- September is the single strongest month at KES 447,300 (13.6%)
- March is the weakest at KES 147,350 (4.5%)

The business generates revenue unevenly — 3 months drive nearly
40% of annual revenue while the weakest 3 months contribute
only 20%. This volatility is a business risk worth addressing
through promotions in historically weak months (March, October).
*/

-- ============================================================
-- Q10: Average delivery time (days) per city
-- ============================================================
SELECT 
  customers.city,
  COUNT(DISTINCT orders.order_id) AS total_orders,
  ROUND(AVG(shipping.delivery_date - shipping.shipping_date), 1) AS avg_delivery_days,
  MIN(shipping.delivery_date - shipping.shipping_date) AS fastest_delivery,
  MAX(shipping.delivery_date - shipping.shipping_date) AS slowest_delivery,
  ROUND(SUM(shipping.shipping_cost), 2) AS avg_shipping_cost,
  RANK() OVER(ORDER BY AVG(shipping.delivery_date - shipping.shipping_date) ASC ) AS delivery_speed_rank
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN shipping ON orders.order_id = shipping.order_id
GROUP BY customers.city
ORDER BY avg_delivery_days ASC;

/*
Q10 FINDINGS: All 5 cities have identical average delivery time of
exactly 3 days with no variation (fastest = slowest = 3 days).

This uniformity suggests a standardised delivery policy or
synthetic dataset pattern. In real e-commerce data, delivery
times would vary based on distance, logistics partners and
order volume.

However shipping COSTS vary significantly despite equal times:
- Mombasa costs KES 52,210 total — most expensive to ship to
- Eldoret costs KES 29,820 total — cheapest despite being furthest
This cost variation without time variation suggests pricing
is based on route complexity not just distance or speed.

Business recommendation: if delivery time is truly uniform,
use this as a marketing advantage — advertise guaranteed
3-day delivery to all cities nationwide.
*/