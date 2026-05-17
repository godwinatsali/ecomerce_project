-- ============================================================
-- DAY 6: Capstone — RFM Segmentation & Advanced Analytics
-- ============================================================
-- Techniques: RFM analysis, NTILE, cohort analysis,
--             churn detection, product dashboard
-- Questions: Q24, Q25, Q27, Q28, Q30
-- ============================================================

-- ============================================================
-- Q24: Full RFM (Recency, Frequency and Monetary) Customer Segmentation using NTILE()
-- ============================================================

WITH max_date AS (
    SELECT
        MAX(order_date) AS reference_date
    FROM orders
),
rfm_base AS (
    SELECT
        customers.customer_id,
        customers.first_name || ' ' || customers.last_name AS customer_name,
        customers.city,
        MAX(orders.order_date) AS last_order_date,
        (SELECT reference_date FROM max_date) - MAX(orders.order_date) AS recency_days,
        COUNT(DISTINCT orders.order_id) AS frequency,
        ROUND(SUM(payments.amount_paid), 2) AS monetary
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    JOIN payments ON orders.order_id = payments.order_id
    WHERE order_status = 'Completed'
    GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city
),
rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        city,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency_days) AS r_score,
        NTILE(4) OVER (ORDER BY frequency) AS f_score,
        NTILE(4) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT 
        customer_id,
        customer_name,
        city,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score) AS rfm_total_score,
    CASE 
        WHEN(r_score + f_score + m_score) >= 10 THEN 'Champion'
        WHEN(r_score + f_score + m_score) >= 8 THEN 'Loyal_customer'
        WHEN(r_score + f_score + m_score) >= 6 THEN 'Potential Loyalist'
        WHEN(r_score + f_score + m_score) >= 4 THEN 'At Risk'
        ELSE 'Lost_customer'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(), 1) AS pct_of_customers,
    ROUND(AVG(monetary), 2) AS avg_spend,
    ROUND(AVG(recency_days), 0) AS avg_recenct_days,
    ROUND(AVG(frequency), 2) AS avg_orders
FROM rfm_segments
GROUP BY segment
ORDER BY avg_spend DESC;
/*
Q24 FINDINGS: RFM Segmentation of 220 customers
(only completed orders included).

Segment Distribution:
  Champion          →  53 customers (24.1%) → avg KHS 23,623
  Loyal Customer    →  55 customers (25.0%) → avg KHS 13,507
  Potential Loyalist→  59 customers (26.8%) → avg KHS  2,297
  At Risk           →  41 customers (18.6%) → avg KHS    842
  Lost              →  12 customers  (5.5%) → avg KHS    604

Positive finding: 49.1% of customers (Champions + Loyal)
are high-value segments worth retaining and rewarding.

Concerning finding: 24.1% of customers (At Risk + Lost)
need immediate re-engagement campaigns before they churn
permanently.

The avg_orders = 1.00 across ALL segments confirms the
dataset limitation — in real data Champions would show
5-10+ orders while Lost customers would show 1-2.

Business recommendations by segment:
  Champions:          VIP rewards, early access to new products
  Loyal Customers:    Loyalty programme, referral incentives
  Potential Loyalist: Targeted promotions, email campaigns
  At Risk:            Win-back discounts, personalised offers
  Lost:               Last-chance re-engagement campaign
*/