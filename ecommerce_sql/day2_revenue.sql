-- Q4: Total revenue from completed order

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

-- Q7: Average shipping cost

SELECT 
    shipping_id,
    ROUND(AVG(shipping_cost), 2) AS Avg_shipping_cost
FROM 
    shipping
GROUP BY
    shipping_id;


-- Q8: Monthly revenue trend throughout 2024

SELECT 
    TO_CHAR(orders.order_date, 'Month') AS month_name,
    EXTRACT (MONTH FROM orders.order_date) AS month_num,
    SUM(payments.amount_paid) AS total_revenue
FROM 
    payments
LEFT JOIN orders ON payments.order_id = orders.order_id
WHERE EXTRACT(YEAR FROM order_date) = 2024
GROUP BY month_name, month_num
ORDER BY month_num ASC;




SELECT
    TO_CHAR(orders.order_date, 'Month') AS month_name,
    EXTRACT(MONTH FROM orders.order_date) AS month_num,
    SUM(payments.amount_paid) AS Monthly_revenue
FROM
    payments
JOIN orders ON payments.order_id = orders.order_id
WHERE EXTRACT(YEAR FROM order_date) = 2024
GROUP BY
    month_name,
    month_num
ORDER BY
    month_num ASC;


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

