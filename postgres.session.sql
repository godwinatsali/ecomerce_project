SELECT 
    products.product_name,
    products.product_id,
    categories.category_name
FROM order_items
LEFT JOIN products ON order_items.product_id = products.product_id
LEFT JOIN categories ON products.category_id = categories.category_id
