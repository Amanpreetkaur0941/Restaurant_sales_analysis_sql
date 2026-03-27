-- =====================================================
-- Project: Restaurant Sales Analysis
-- Duration: Jan 2023 – Mar 2023
-- Objective: Analyze revenue, order behavior, menu performance,
--            and operational trends to support business decisions
-- Tools: SQL
-- =====================================================

-- =====================================================
-- 1. Data Cleaning
-- =====================================================

SELECT COUNT(*) FROM order_details_staging
WHERE item_id IS NULL;

UPDATE order_details_staging                  
SET item_id = 0
WHERE item_id IS NULL;

-- Replacing NULL Values 

INSERT INTO menu_items_staging(menu_item_id, item_name,category, price) VALUES
(0,'Unknown','Other',0.00);



-- =====================================================
-- 2. Revenue Analysis
-- =====================================================
SELECT   SUM(m.price) AS total_revenue
FROM order_details_staging o 
LEFT JOIN menu_items_staging m ON o.item_id = m.menu_item_id;


-- Revenue distribution over months
SELECT  MONTHNAME(o.order_date) AS month_dist, SUM(m.price) AS total_revenue
FROM order_details_staging o 
LEFT JOIN menu_items_staging m ON o.item_id = m.menu_item_id
GROUP BY month_dist;

-- Average Revenue per order
SELECT SUM(m.price)/COUNT(DISTINCT(o.order_id)) AS avg_per_order
FROM order_details_staging o 
JOIN menu_items_staging m ON o.item_id = m.menu_item_id;

-- =====================================================
-- 2. Order Analysis
-- =====================================================

-- a. Total orders

SELECT COUNT(DISTINCT(order_id)) AS total_orders
FROM order_details_staging; 

--  Average order value (AOV)

SELECT SUM(m.price)/COUNT(DISTINCT(o.order_id)) AS Avg_order_value
FROM order_details_staging o 
LEFT JOIN menu_items_staging m ON o.item_id = m.menu_item_id;

-- =====================================================
-- 3. Customer Behaviour Analysis
-- =====================================================

-- • Items  ordered per order


SELECT 
    COUNT(item_id) * 1.0 / COUNT(DISTINCT order_id) AS avg_items_per_order
FROM order_details;

SELECT DISTINCT(order_id), COUNT(item_id) AS total_items
FROM order_details_staging
GROUP BY order_id;



SELECT o.order_id, m.item_name
FROM order_details_staging o
LEFT JOIN menu_items_staging m ON o.item_id = m.menu_item_id;

-- Frequency of items ordered in pairs

SELECT 
    m1.item_name AS item_1,
    m2.item_name AS item_2,
    COUNT(*) AS frequency
FROM order_details_staging o1
JOIN order_details_staging o2
    ON o1.order_id = o2.order_id
    AND o1.item_id < o2.item_id
JOIN menu_items_staging m1
    ON o1.item_id = m1.menu_item_id
JOIN menu_items_staging m2
    ON o2.item_id = m2.menu_item_id
GROUP BY m1.item_name, m2.item_name
ORDER BY frequency DESC
LIMIT 10;

-- =====================================================
-- --Product performance Analysis
-- -- =====================================================
--  Cuisine Category performance in terms of revenue

SELECT 
    m.category, 
    ROUND(SUM(m.price), 2) AS category_revenue,
    ROUND(
        (SUM(m.price) * 100.0) / SUM(SUM(m.price)) OVER(), 
        2
    ) AS percentage_contribution
FROM order_details_staging o
LEFT JOIN menu_items_staging m ON o.item_id = m.menu_item_id
GROUP BY m.category
ORDER BY percentage_contribution DESC;


-- Contribution of top item within category

WITH item_perf AS (
SELECT m.category AS category, m.item_name AS top_item, SUM(m.price) AS Total_sales,
ROW_NUMBER() OVER
(
PARTITION BY m.category
ORDER BY SUM(m.price) DESC
) AS rn
FROM order_details_staging o
JOIN menu_items_staging m ON o.item_id = m.menu_item_id
GROUP BY m.category, m.item_name
) 
SELECT category, top_item , Total_sales
FROM item_perf
WHERE rn=1;

--  Top vs Bottom perfromers

WITH item_sales AS(
SELECT m.item_name, SUM(m.price) AS total_sales
FROM order_details_staging o
 JOIN menu_items_staging m ON o.item_id = m.menu_item_id
GROUP BY m.item_name
)
SELECT * FROM item_sales
ORDER BY total_Sales DESC
LIMIT 5;
SELECT * FROM item_sales
ORDER BY total_Sales ASC
LIMIT 5;


-- =====================================================
-- --Time Based Analysis
-- -- =====================================================

-- Peak VS Non-peak hours

SELECT DATE_FORMAT(order_time, '%h %p') AS hour_of_day,COUNT(DISTINCT(order_id)) AS daily_orders FROM order_details_staging
GROUP BY hour_of_day,HOUR(order_time)
ORDER BY HOUR(order_time) ASC;

-- Busiest days

SELECT DAYNAME(order_date) AS Name_of_day,COUNT(DISTINCT(order_id)) AS daily_orders FROM order_details_staging
GROUP BY Name_of_day,DAYOFWEEK(order_date)
ORDER BY DAYOFWEEK(order_date);

