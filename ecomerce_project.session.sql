SELECT 
    products.product_name,
    products.product_id,
    categories.category_id,
    products.price,
SUM (order_items.quantity) AS total_units_sold,
COUNT (DISTINCT order_items.order_id) AS times_ordered,
SUM (order_items.quantity) * products.price AS total_revenue,
DENSE_RANK () OVER (ORDER BY SUM(order_items.quantity) DESC) AS sales_rank
FROM 
    order_items
    LEFT JOIN products ON order_items.product_id = products.product_id
    LEFT JOIN categories ON products.category_id = categories.category_id
GROUP BY 
    products.product_name,
    products.product_id,
    categories.category_id,
    products.price
ORDER BY 
    total_units_sold DESC
LIMIT 
    10;
