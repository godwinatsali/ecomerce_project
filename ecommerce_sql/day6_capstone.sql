-- ============================================================
-- DAY 6: Capstone — RFM Segmentation & Advanced Analytics
-- ============================================================
-- Techniques: RFM analysis, NTILE, cohort analysis,
--             churn detection, product dashboard
-- Questions: Q24, Q25, Q27, Q28, Q30
-- ============================================================

-- ============================================================
-- Q24: Full RFM (Recency, Frequency and Monetary) Customer
-- Segmentation using NTILE()
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

-- ============================================================
-- Q25: Cohort retention table by signup month
-- ============================================================
-- Part A: Full cohort analysis
WITH customer_cohorts AS (
    SELECT
        customers.customer_id,
        DATE_TRUNC('Month', customers.signup_date) AS cohort_month,
        DATE_TRUNC('month', orders.order_date) AS order_month
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
),
cohort_data AS (
    SELECT 
        cohort_month,
        order_month,
        EXTRACT(YEAR FROM AGE(order_month, cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(order_month, cohort_month)) AS month_number,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_cohorts
    GROUP BY cohort_month, order_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        customers AS cohort_size
    FROM cohort_data
    WHERE month_number = 0
)
SELECT
    TO_CHAR (cohort_data.cohort_month, 'YYYY-MM') AS cohort,
    cohort_sizes.cohort_size,
    cohort_data.cohort_month,
    cohort_data.customers AS active_customers,
    ROUND(cohort_data.customers * 100 / cohort_sizes.cohort_size, 1) AS retention_pct
FROM cohort_data
JOIN cohort_sizes ON cohort_data.cohort_month = cohort_sizes.cohort_month
GROUP BY cohort_data.cohort_month, cohort_data.month_number, cohort_sizes.cohort_size, cohort_data.customers;

-- ============================================================
-- Part B: Simplified cohort analysis (better for this dataset)
-- ============================================================
WITH first_orders AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS first_order_month
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
customer_cohorts AS (
    SELECT 
        orders.customer_id,
        TO_CHAR(first_orders.first_order_month, 'YYYY-MM') AS cohort_month,
        TO_CHAR(DATE_TRUNC('month', orders.order_date), 'YYYY-MM') AS order_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', orders.order_date),
            first_orders.first_order_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', orders.order_date),
            first_orders.first_order_month
        )) AS month_number
    FROM orders
    JOIN first_orders ON orders.customer_id = first_orders.customer_id
    WHERE orders.order_status = 'Completed'
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    WHERE month_number = 0
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM customer_cohorts
    GROUP BY cohort_month, month_number
)
SELECT
    cohort_activity.cohort_month,
    cohort_sizes.cohort_size,
    cohort_activity.month_number,
    cohort_activity.active_customers,
    ROUND(cohort_activity.active_customers * 100 / cohort_sizes.cohort_size, 1) AS retention_pct
FROM cohort_activity
JOIN cohort_sizes ON cohort_activity.cohort_month = cohort_sizes.cohort_month
ORDER BY cohort_activity.cohort_month, cohort_activity.month_number;

/*
Q25 FINDINGS: Cohort retention table (based on first order month)

All 10 monthly cohorts visible (Jan-Oct 2024):
  Jan cohort: 20 customers → 100% at month 0
  Feb cohort: 22 customers → 100% at month 0
  Mar cohort: 22 customers → 100% at month 0
  ...
  Oct cohort: 22 customers → 100% at month 0

Every cohort shows 100% retention at month 0 — expected
since month 0 IS the first order month.

NO cohort shows any month 1, 2 or 3 retention — confirming
the finding from Q20 that every customer placed exactly
1 order and never returned.

This means customer retention rate = 0% across ALL cohorts
and ALL time periods. The business acquires customers once
and never sees them again.

In a healthy e-commerce business a typical cohort table
would look like this:
  Cohort  | Month 0 | Month 1 | Month 2 | Month 3
  2024-01 | 100%    | 35%     | 22%     | 18%
  2024-02 | 100%    | 31%     | 25%     | 20%

The fact that our table shows only month 0 for every cohort
is itself the most important finding — zero repeat purchases
is a critical business problem requiring immediate action.

Business recommendation: implement post-purchase email
sequences, loyalty rewards and personalised re-engagement
campaigns targeting customers at the 30, 60 and 90 day
marks after their first purchase.
*/

-- ============================================================
-- Q27: High value customers active in Q1 but silent in Q2
-- ============================================================