create database pizza_shakti

use pizza_shakti;

SELECT * FROM [dbo].[pizzas];
SELECT * FROM [dbo].[pizza_types];
SELECT * FROM [dbo].[orders];
SELECT * FROM [dbo].[order_details]

sp_help '[dbo].[order_details]';

sp_help '[dbo].[pizzas]';

ALTER TABLE [dbo].[order_details]
ALTER COLUMN quantity DECIMAL(10, 2);

ALTER TABLE [dbo].[order_details]
ALTER COLUMN quantity INT;


ALTER TABLE [dbo].[orders]
ALTER COLUMN order_id INT;


ALTER TABLE [dbo].[pizzas]
ALTER COLUMN price INT;

--Basic:
--1. Retrieve the total number of orders placed.

SELECT COUNT(*) AS total_orders FROM [dbo].[orders];

--Calculate the total revenue generated from pizza sales.
SELECT SUM(p.price*o.quantity) as total_renenuw FROM [dbo].[pizzas] as p
INNER JOIN [dbo].[order_details] as o 
ON p.pizza_id = o.pizza_id;


--Identify the highest-priced pizza.
SELECT  TOP 1 * FROM [dbo].[pizzas] ORDER BY price DESC;

--Identify the most common pizza size ordered.
SELECT * FROM [dbo].[pizzas] as p
INNER JOIN [dbo].[order_details] as o 
ON p.pizza_id = o.pizza_id

SELECT TOP 1 p.size, COUNT(p.size) as count_pizza FROM [dbo].[pizzas] as p
INNER JOIN [dbo].[order_details] as o 
ON p.pizza_id = o.pizza_id
GROUP BY p.size
ORDER BY count_pizza DESC;

--List the top 5 most ordered pizza types along with their quantities.
SELECT TOP 5
    p.pizza_id, 
    pt.name, 
    COUNT(p.pizza_type_id) AS count_ordered_pizza_type 
FROM 
    [dbo].[pizzas] AS p
INNER JOIN 
    [dbo].[pizza_types] AS pt ON p.pizza_type_id = pt.pizza_type_id
INNER JOIN 
    [dbo].[order_details] AS o ON p.pizza_id = o.pizza_id
GROUP BY 
    p.pizza_id, 
    pt.name
ORDER BY 
    count_ordered_pizza_type DESC;


--------------------------------------------------------Intermediate----------------------------------------
--Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_type_id,SUM(o.quantity) as total FROM [dbo].[pizzas] as p
INNER JOIN [dbo].[order_details] as o
ON p.pizza_id = o.pizza_id
GROUP BY pizza_type_id
ORDER BY total ASC;

--Determine the distribution of orders by hour of the day.

SELECT DATEPART(HOUR, time) as Hour,COUNT(*) as total_orders
FROM [dbo].[orders]
GROUP BY DATEPART(HOUR, time)
ORDER BY Hour ASC;

--Join relevant tables to find the category-wise distribution of pizzas.

SELECT pt.category, SUM(o.quantity) as total_numbers FROM [dbo].[pizzas] p
INNER JOIN [dbo].[pizza_types] pt
ON p.pizza_type_id = pt.pizza_type_id
INNER JOIN [dbo].[order_details] AS o
ON p.pizza_id = o.pizza_id
GROUP BY pt.category
ORDER BY pt.category ASC;

--Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT date, AVG(total_pizzas) as average_no_pizzas
FROM (
SELECT CAST(o.date AS DATE) AS date,
SUM(od.quantity) as total_pizzas FROM [dbo].[orders] o
INNER JOIN [dbo].[order_details] od
ON o.order_id = od.order_id
GROUP BY CAST(o.date AS DATE)
) totalpizzas
GROUP BY date
ORDER BY date;


--Determine the top 3 most ordered pizza types based on revenue.
SELECT * FROM [dbo].[pizza_types];
SELECT * FROM [dbo].[order_details];
SELECT * FROM [dbo].[pizzas];

SELECT TOP 3 pt.name, p.pizza_type_id,SUM(p.price*o.quantity) as total_amt
FROM  [dbo].[pizzas] p
INNER JOIN [dbo].[pizza_types] pt
ON p.pizza_type_id = pt.pizza_type_id
INNER JOIN [dbo].[order_details] o
ON p.pizza_id = o.pizza_id
GROUP BY pt.name,p.pizza_type_id
ORDER BY total_amt DESC;

-------------------------------------------------------Advanced-------------------------------------------------------------
--Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
    pt.category,
    ROUND((SUM(p.price * o.quantity) / 
    (SELECT ROUND(SUM(p1.price * o1.quantity),2)  as total_sales
     FROM [dbo].[order_details] o1
     INNER JOIN [dbo].[pizzas] p1  ON  o1.pizza_id = p1.pizza_id)) * 100, 2) AS revenue
FROM  
    [dbo].[pizza_types] pt
INNER JOIN 
    .[pizzas] p ON pt.pizza_type_id = p.pizza_type_id
INNER JOIN 
    [dbo].[order_details] o ON p.pizza_id = o.pizza_id
GROUP BY 
    pt.category;


--Analyze the cumulative revenue generated over time.

SELECT  o.date,
    SUM(p.price * od.quantity) AS daily_revenue,
    SUM(SUM(p.price * od.quantity)) OVER (ORDER BY o.date) AS cumulative_revenue
FROM [dbo].[pizzas] AS p
INNER JOIN [dbo].[order_details] AS od
ON p.pizza_id = od.pizza_id
INNER JOIN [dbo].[orders] AS o
ON od.order_id = o.order_id
GROUP BY o.date; 

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.

--BREAK DOWN: first step
SELECT pt.category,pt.name,
SUM((od.quantity) * p.price) as revenue
from [dbo].[pizza_types] as pt
JOIN [dbo].[pizzas] AS p
ON pt.pizza_type_id = p.pizza_type_id
JOIN [dbo].[order_details] as od
ON od.pizza_id = p.pizza_id
GROUP BY pt.category,pt.name;

SELECT category,name,revenue,
RANK() OVER(PARTITION BY category ORDER BY revenue DESC) as RN
FROM 
(SELECT pt.category,pt.name,
SUM((od.quantity) * p.price) as revenue
from [dbo].[pizza_types] as pt
JOIN [dbo].[pizzas] AS p
ON pt.pizza_type_id = p.pizza_type_id
JOIN [dbo].[order_details] as od
ON od.pizza_id = p.pizza_id
GROUP BY pt.category,pt.name) as DonotForgetAliasAfterSubQuery;

with cte as (
SELECT category,name,revenue,
RANK() OVER(PARTITION BY category ORDER BY revenue DESC) as RN
FROM 
(SELECT pt.category,pt.name,
SUM((od.quantity) * p.price) as revenue
from [dbo].[pizza_types] as pt
JOIN [dbo].[pizzas] AS p
ON pt.pizza_type_id = p.pizza_type_id
JOIN [dbo].[order_details] as od
ON od.pizza_id = p.pizza_id
GROUP BY pt.category,pt.name) as DonotForgetAliasAfterSubQuery
)

SELECT name,revenue FROM cte WHERE RN <=3;