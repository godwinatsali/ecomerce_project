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
-- ============================================================1
WITH q1_spenders AS (
    SELECT 
        customers.customer_id,
        customers.first_name || ' ' || customers.last_name AS customer_name,
        customers.city,
        ROUND(SUM(payments.amount_paid), 2) AS q1_spend,
        COUNT(DISTINCT orders.order_id) AS q1_orders
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    JOIN payments ON orders.order_id = payments.order_id
    WHERE orders.order_date BETWEEN '2024-01-01' AND '2024-03-31'
        AND orders.order_status = 'Completed'
    GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city
),
q2_buyers AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE orders.order_date BETWEEN '2024-04-01' AND '2024-06-30'
    AND orders.order_status = 'Completed'
)
SELECT 
    q1_spenders.customer_id,
    q1_spenders.customer_name,
    q1_spenders.city,
    q1_spenders.q1_spend,
    q1_spenders.q1_orders,
    'Active in Q1 — Silent in Q2' AS order_status
FROM q1_spenders
LEFT JOIN q2_buyers ON q1_spenders.customer_id = q2_buyers.customer_id
WHERE q2_buyers.customer_id IS NULL
ORDER BY q1_spenders.q1_spend DESC
LIMIT 15;
/*
Q27 FINDING: 15 high-value Q1 customers went completely silent in Q2.

Top silent customers by Q1 spend:
  John Kimani    (Nairobi) → KHS 65,000
  Faith Mwangi   (Nairobi) → KHS 65,000
  Mary Hassan    (Eldoret) → KHS 55,000
  James Odhiambo (Nairobi) → KHS 45,000
  Esther Mutua   (Kisumu)  → KHS 45,000

Combined Q1 revenue from these 15 customers: KHS 556,000
All of this revenue was lost in Q2 with no repeat purchases.

City breakdown of silent customers:
  Nairobi → 5 customers (highest loss)
  Kisumu  → 4 customers
  Eldoret → 4 customers
  Mombasa → 1 customer
  Nakuru  → 1 customer

This is consistent with Q20 and Q25 findings — 0% retention
across the entire dataset means ALL high value customers
went silent after their first purchase.

Business recommendation: these 15 customers represent the
highest priority re-engagement targets. A personalised
win-back campaign with a 10-15% discount voucher targeted
at customers who spent above KHS 40,000 in Q1 could
recover a significant portion of lost revenue.
*/

-- ============================================================
-- Q28: Product performance dashboard
-- ============================================================
WITH product_stats AS(
    SELECT 
        products.product_id,
        products.product_name,
        categories.category_name,
        products.price,
        COUNT(DISTINCT orders.order_id) AS total_orders,
        SUM(order_items.quantity) AS units_sold,
        ROUND(SUM(order_items.quantity * products.price), 2) AS total_revenue,
        round(avg(order_items.quantity * products.price), 2) AS avg_order_value,
        COUNT(CASE WHEN orders.order_status = 'Returned' THEN 1 END) AS returns,
        COUNT(CASE WHEN orders.order_status = 'Cancelled' THEN 1 END) AS cancellations,
        ROUND(COUNT(CASE WHEN orders.order_status = 'Returned'THEN 1 END) * 100.0 / 
        NULLIF(COUNT(DISTINCT orders.order_id), 0), 1) AS return_rate_pct 
    FROM products
    JOIN categories ON products.category_id = categories.category_id
    JOIN order_items ON products.product_id = order_items.product_id
    JOIN orders ON order_items.order_id = orders.order_id
    GROUP BY products.product_id, products.product_name, categories.category_name, products.price
)
SELECT 
    product_name,
    category_name,
    price,
    units_sold,
    total_revenue,
    avg_order_value,
    returns,
    cancellations,
    return_rate_pct,
RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,
RANK() OVER(ORDER BY units_sold DESC) AS volume_rank,
RANK() OVER(ORDER BY return_rate_pct DESC) AS quality_rank
FROM product_stats
ORDER BY total_revenue DESC
LIMIT 15;
/*
Q28 FINDING: Product performance dashboard — top 15 products

Revenue champions (zero returns):
  Desktop PC    → KHS 1,020,000 → revenue rank 1, quality rank 1
  Sofa          → KHS   780,000 → revenue rank 2, quality rank 1
  Dining Table  → KHS   540,000 → revenue rank 4, quality rank 1
  Laptop        → KHS   390,000 → revenue rank 6, quality rank 1
Products with return issues:
  Wardrobe      → KHS 660,000 but 2 returns (3rd highest revenue)
  Graphics Card → KHS 270,000 with 2 returns
  Fridge        → KHS 270,000 with 2 returns
  Mattress      → KHS 150,000 with 2 returns
  Vacuum Cleaner→ KHS 108,000 with 2 returns
The three-rank system reveals nuanced performance:
  Desktop PC: revenue_rank=1, volume_rank=1, quality_rank=1
  → Perfect performer across all dimensions
  Wardrobe: revenue_rank=3 but has returns
  → High revenue but quality issues need investigation
  Bed: revenue_rank=5, units=6 (half of top products)
  → High price (KES 80,000) compensates for lower volume
Business recommendation:
  1. Prioritise Desktop PC and Sofa — top revenue with zero returns
  2. Investigate Wardrobe return reasons — 3rd highest revenue
     product with quality issues is a significant risk
  3. Review Graphics Card, Fridge and Vacuum Cleaner quality
     control — all showing returns despite mid-range pricing
*/

-- ============================================================
-- Q30: Churn signal detection
-- Customers who show sudden drop in order frequency
-- ============================================================
WITH customer_monthly_orders AS (
    SELECT
        customers.customer_id,
        customers.first_name || ' ' || customers.last_name AS customer_name,
        customers.city,
        TO_CHAR(orders.order_date, 'YYYY-MM') AS order_month,
        COUNT(DISTINCT orders.order_id) AS monthly_orders,
        ROUND(SUM(payments.amount_paid), 2) AS monthly_spend
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    JOIN payments ON orders.order_id = payments.order_id
    GROUP BY customers.customer_id, customers.first_name, customers.last_name, customers.city, order_month
),
customer_activity AS (
    SELECT 
        customer_id,
        customer_name,
        city,
        MAX(order_month) AS first_active_month,
        MIN(order_month) AS last_active_month,
        COUNT(DISTINCT order_month) AS active_months,
        SUM(monthly_orders) AS total_orders,
        ROUND(SUM(monthly_spend), 2) AS total_spend
    FROM customer_monthly_orders
    GROUP BY customer_id, customer_name, city
),
churn_signals AS (
    SELECT
        customer_id,
        customer_name,
        city,
        first_active_month,
        last_active_month,
        active_months,
        total_orders,
        total_spend,
        CASE 
           WHEN last_active_month <= '2024-03'
           AND total_spend >= 10000
           THEN 'Early Churner - High Value'
           WHEN last_active_month <= '2024-06'
           AND total_spend >= 5000
           THEN 'Mid-year Churner'
           WHEN last_active_month <= '2024-08' 
           THEN 'Recent Churner'
           ELSE 'Still Active'
        END AS churn_status
    FROM customer_activity
)
SELECT
    churn_status,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    MIN(total_spend) AS min_spend,
    MAX(total_spend) AS max_spend,
    ROUND(COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM churn_signals
GROUP BY churn_status
ORDER BY avg_spend DESC;
/*
Q30 FINDINGS: Churn signal analysis reveals 80% of customers
show signs of churn — only 20% remain active.

Segment breakdown:
  Early Churner High Value: 20 customers (6.7%)
    → Avg spend KHS 33,750 (highest value lost customers)
    → Churned before April 2024 despite high spending
    → Range KHS 12,000 to KHS 85,000
    → PRIORITY 1 for win-back campaigns

  Mid-year Churner: 40 customers (13.3%)
    → Avg spend KHS 23,875
    → Churned between April and June 2024
    → Range KHS 5,000 to KHS 85,000
    → PRIORITY 2 for re-engagement

  Recent Churner: 180 customers (60.0%)
    → Avg spend KHS 5,348 (lowest value)
    → Largest segment — majority of customers
    → Ordered late 2024 and not returned
    → PRIORITY 3 — mass email campaign

  Still Active: 60 customers (20.0%)
    → Avg spend KHS 11,697
    → Only 20% of customer base remains engaged
    → Focus retention efforts here to prevent further churn

Total revenue at risk from churned customers:
  Early Churner:   20 × KHS 33,750 = KHS   675,000
  Mid-year Churner: 40 × KHS 23,875 = KHS   955,000
  Recent Churner:  180 × KHS  5,348 = KHS   962,640
  Total at risk:                      KHS 2,592,640

Business recommendation: implement a 3-tier win-back strategy
targeting each churn segment with different incentives based
on their value and recency of churn.
*/
