         
           -- Q4: Total revenue from completed order
=========================================================================
SELECT 
    products.product_name,
    products.price AS price,
    SUM(order_items.quantity)  AS total_quantity,
    ROUND(SUM(order_items.quantity * products.price), 2) AS total_revenue
FROM 
    products
LEFT JOIN 
    order_items ON products.product_id = order_items.product_id
LEFT JOIN 
    orders ON order_items.order_id = orders.order_id
WHERE 
    orders.order_status = 'Completed'
GROUP BY 
    products.product_name, products.price
ORDER BY
    total_revenue DESC
LIMIT 10;

-- Q4b: Grand total revenue from completed orders

SELECT
    ROUND(SUM(order_items.quantity * products.price), 2)   AS grand_total_revenue
FROM products
LEFT JOIN order_items ON products.product_id = order_items.product_id
LEFT JOIN orders      ON order_items.order_id = orders.order_id
WHERE orders.order_status = 'Completed';

/*
Q4 FINDINGS: Total revenue from completed orders is KES 6,296,160.
Desktop PC is the top revenue-generating product at KES 1,020,000
driven by its high price of KES 85,000 and 12 units sold.
Sofa (KES 780,000) and Dining Table (KES 540,000) follow closely.
High ticket items (furniture + electronics) dominate the top 10.
Key insight: price drives revenue more than volume in this dataset.
*/
============================================================================

============================================================================ 

           -- Q7: Average shipping cost      
        
SELECT
    ROUND(AVG(shipping_cost), 2) AS Avg_shipping_cost,
    ROUND(MAX(shipping_cost), 2) AS max_shipping_cost,
    ROUND(MIN(shipping_cost), 2) AS min_shipping_cost,
    ROUND(STDDEV(shipping_cost), 2) AS stddev_shipping_cost
FROM
    shipping;

/*
Q7 FINDING: 
Average shipping cost is KES 658.70 per order.
Costs range from KES 120 (minimum) to KES 3,000 (maximum).
The standard deviation of KES 748.79 exceeds the average —
indicating highly inconsistent shipping costs across orders.
This suggests shipping pricing depends on distance or product size
rather than a flat rate model.
Business recommendation: consider a tiered shipping pricing structure
to make costs more predictable for customers.
*/
============================================================================

============================================================================

           -- Q8: Monthly revenue trend throughout 2024
SELECT 
    TO_CHAR(orders.order_date, 'MONTH') AS month_name,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(*),
    COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) AS completed,
    EXTRACT(MONTH FROM order_date) AS month_num,
    ROUND(SUM(payments.amount_paid), 2) AS monthly_tevenue,
    ROUND(AVG(payments.amount_paid), 2) AS avg_order_value,
    ROUND(SUM(payments.amount_paid) - LAG(SUM(payments.amount_paid)) 
    OVER (ORDER BY EXTRACT(MONTH  FROM orders.order_date)), 2) AS revenue_change
FROM Orders
JOIN payments ON orders.order_id = payments.order_id
GROUP BY month_name, month_num
ORDER BY month_num ASC;

/*
Q8 FINDING: Dataset covers January to October 2024 (10 months).
Total revenue across all orders (including cancelled and returned).
September was the strongest month at KES 447,300 in revenue.
Two major revenue crashes occurred:
March dropped KES 267,350 from February — biggest single drop
October dropped KES 192,800 from September — second biggest drop
February showed the strongest growth at +KES 148,800 from January.
July recovered strongly with +KES 135,700 after June's decline.
Revenue is highly volatile with no consistent upward trend —
alternating between growth and decline every 1-2 months.
Monthly revenue ranges from KES 147,350 (March - lowest) 
to KES 447,300 (September - highest) — a difference of KES 299,950.
Average order value ranges from KES 4,753 (March) to 
KES 14,910 (September) suggesting higher value orders
were placed in September driving that month's peak revenue.
Business recommendation: investigate March and October drops —
these two months alone lost KES 460,150 in revenue compared
to their preceding months, significantly impacting annual performance.
*/

===============================================================================

===============================================================================

            -- Q11: Cancellation & return rate by month
SELECT 
    TO_CHAR(order_date, 'Month') AS month_name,
    EXTRACT(MONTH FROM order_date) AS month_num,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS Cancelled,
    COUNT(CASE WHEN order_status = 'Returned' THEN 1 END) AS Returned,
    ROUND(COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*), 1) AS cancel_rate_pct,
    ROUND(COUNT(CASE WHEN order_status = 'Returned' THEN 1 END) * 100.0 / COUNT(*), 1) AS return_rate_pct
FROM orders
GROUP BY month_name, month_num
ORDER BY month_num ASC;

/*
Q11 FINDING: Cancellation rates peak in March (16.1%) and January (14.8%)
suggesting post-holiday budget constraints drive early-year cancellations.
Return rates peak in August (16.1%) possibly linked to back-to-school
purchasing decisions being reversed.
Overall both rates are consistent at ~13% monthly indicating a structural
issue rather than a seasonal one.
Combined loss rate of ~26% means 1 in 4 orders never results in a
completed sale — a serious business concern worth investigating.
*/

===============================================================================

===============================================================================

            -- Q14: Revenue % contribution per category
SELECT 
    categories.category_name,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(order_items.quantity) AS units_sold,
    ROUND(SUM(order_items.quantity * products.price), 2) AS category_revenue,
    ROUND(SUM(order_items.quantity * products.price) * 100.0 / SUM(SUM(order_items.quantity * products.price)) OVER(), 1) AS revenue_pct,
    RANK() OVER(ORDER BY SUM(order_items.quantity * products.price) DESC) AS revenue_rank
FROM order_items
JOIN orders ON order_items.order_id = orders.order_id
JOIN products ON order_items.product_id = products.product_id
JOIN categories ON products.category_id = categories.category_id
WHERE order_status = 'Completed'
GROUP BY category_name
ORDER BY category_revenue DESC;

/*
Q14 FINDING: Furniture dominates revenue at 40.6% (KES 2,554,000)
followed by Electronics at 35.0% (KES 2,203,000).
Together these two categories account for 75.6% of total revenue —
a classic Pareto distribution where a minority drives the majority.
Automotive sold the most units (82) but ranks only 4th in revenue
proving that volume does not equal revenue — price is the key driver.
Food (0.2%) and Books (0.7%) contribute minimally despite reasonable
unit sales — low price points severely limit their revenue impact.
Business recommendation: focus marketing and inventory investment
on Furniture and Electronics to maximise revenue returns.
*/

==============================================================================

-- Check the date range in our dataset
SELECT
    MIN(order_date)   AS earliest_order,
    MAX(order_date)   AS latest_order,
    COUNT(*)          AS total_orders
FROM orders;

--Earliest order date is 2024-01-05
--Latest order_date is 2024-10-30
--total orders = 300