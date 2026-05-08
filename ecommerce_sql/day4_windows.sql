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
