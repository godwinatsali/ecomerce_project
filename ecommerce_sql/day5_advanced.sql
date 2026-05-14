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
