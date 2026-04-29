-- =============================================
-- PIZZA HUT SALES ANALYSIS
-- Author: Ishwari Gurde
-- Tool: MySQL Workbench
-- Dataset: Pizza Hut Sales (orders, order_details,
--           pizzas, pizza_types)
-- =============================================


-- =============================================
-- DATABASE SETUP
-- =============================================

CREATE DATABASE pizzhut;
USE pizzhut;


-- =============================================
-- CREATE TABLES
-- =============================================

CREATE TABLE orders (
    order_id   INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

CREATE TABLE order_details (
    order_details_id INT NOT NULL,
    order_id         INT NOT NULL,
    pizza_id         TEXT NOT NULL,
    quantity         INT NOT NULL,
    PRIMARY KEY (order_details_id)
);

CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) NOT NULL,
    name          VARCHAR(100) NOT NULL,
    category      VARCHAR(50) NOT NULL,
    ingredients   VARCHAR(500) NOT NULL,
    PRIMARY KEY (pizza_type_id)
);

CREATE TABLE pizzas (
    pizza_id      VARCHAR(50) NOT NULL,
    pizza_type_id VARCHAR(50) NOT NULL,
    size          VARCHAR(10) NOT NULL,
    price         DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (pizza_id)
);


-- =============================================
-- BASIC QUESTIONS
-- =============================================

-- Q1: Total number of orders placed
SELECT COUNT(order_id) AS total_orders 
FROM orders;

-- Q2: Total revenue generated
SELECT ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details od 
JOIN pizzas p ON od.pizza_id = p.pizza_id;

-- Q3: Highest priced pizza
SELECT pt.name, p.price
FROM pizzas p
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC 
LIMIT 1;

-- Q4: Most common pizza size ordered
SELECT p.size, COUNT(od.order_details_id) AS order_count
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY order_count DESC
LIMIT 1;

-- Q5: Top 5 most ordered pizza types
SELECT pt.name, SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;


-- =============================================
-- INTERMEDIATE QUESTIONS
-- =============================================

-- Q6: Total quantity ordered per pizza category
SELECT pt.category, SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;

-- Q7: Orders distribution by hour of the day
SELECT HOUR(order_time) AS hour, 
       COUNT(order_id) AS order_count
FROM orders
GROUP BY hour
ORDER BY hour;

-- Q8: Category-wise pizza type count
SELECT category, COUNT(name) AS pizza_types
FROM pizza_types
GROUP BY category;

-- Q9: Average number of pizzas ordered per day
SELECT ROUND(AVG(daily_quantity), 0) AS avg_pizzas_per_day
FROM (
    SELECT DATE(o.order_date) AS order_date, 
           SUM(od.quantity) AS daily_quantity
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY order_date
) AS daily_data;

-- Q10: Top 3 pizza types by total revenue
SELECT pt.name, 
       ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;


-- =============================================
-- ADVANCED QUESTIONS
-- =============================================

-- Q11: Revenue contribution (%) by pizza category
SELECT pt.category,
    ROUND(SUM(od.quantity * p.price) /
    (SELECT SUM(od2.quantity * p2.price) 
     FROM order_details od2
     JOIN pizzas p2 ON od2.pizza_id = p2.pizza_id) * 100, 2) AS revenue_percentage
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY revenue_percentage DESC;

-- Q12: Cumulative revenue generated over time
SELECT order_date,
    ROUND(SUM(daily_revenue) OVER (ORDER BY order_date), 2) AS cumulative_revenue
FROM (
    SELECT DATE(o.order_date) AS order_date,
           SUM(od.quantity * p.price) AS daily_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY order_date
) AS daily;

-- Q13: Top 3 pizzas by revenue within each category
SELECT category, name, revenue
FROM (
    SELECT pt.category, pt.name,
        ROUND(SUM(od.quantity * p.price), 2) AS revenue,
        RANK() OVER (
            PARTITION BY pt.category 
            ORDER BY SUM(od.quantity * p.price) DESC
        ) AS rnk
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
) AS ranked
WHERE rnk <= 3;