--=====================================
--Database Exploration
--=====================================
--Explore all Objects in the Database;
SELECT * FROM INFORMATION_SCHEMA.TABLES;

--Explore all the columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS; 

--=====================================
--Dimension Exploration
--=====================================
--Explore all the countries where our Customers come from;
SELECT DISTINCT country FROM Gold.dim_customers;

--Explore all 'Major Divisions ' of Products
SELECT DISTINCT category,subcategory,product_name FROM Gold.dim_products
ORDER BY 1,2,3

SELECT DISTINCT maintenance FROM Gold.dim_products;

--=====================================
--Date Exploration
--=====================================
--Find the First and Last order
SELECT 
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(YEAR,MIN(order_date),MAX(order_date) ) AS range_orders
FROM Gold.fact_sales;

--Find the youngest and oldest customer
SELECT 
MIN(birthdate) AS Oldest,
DATEDIFF(YEAR,MIN(birthdate),GETDATE()) AS Oldest_Age,
MAX(birthdate) AS Youngest,
DATEDIFF(YEAR,MAX(birthdate),GETDATE()) AS Youngest_Age,
DATEDIFF(YEAR,MIN(birthdate),MAX(birthdate)) AS Age_difference
FROM Gold.dim_customers;

--=====================================
--Measure Exploration
--=====================================
--Find the Total sales 
SELECT SUM(sales_amount) AS total_sales FROM Gold.fact_sales;
--Find the how many items are sold
SELECT SUM(quantity) AS total_quantity FROM Gold.fact_sales;
--Find the average selling price
SELECT AVG(price) AS avg_price FROM Gold.fact_sales;
--Find the Total number of orders
SELECT COUNT(order_number) AS total_orders FROM Gold.fact_sales;
SELECT COUNT(DISTINCT order_number) AS total_orders FROM Gold.fact_sales;
--Find the total number of products
SELECT COUNT(product_id) AS total_products FROM Gold.dim_products;
SELECT COUNT(DISTINCT product_id) AS total_products FROM Gold.dim_products;
--Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM Gold.dim_customers;
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM Gold.dim_customers;
--Find the total number of customers that place an order 
SELECT COUNT(DISTINCT customer_key) AS customers_orders_placed FROM Gold.fact_sales;

--Generate a report 
SELECT 'Total Sales' as measure_name,SUM(sales_amount) AS measure_values FROM Gold.fact_sales
UNION ALL
SELECT 'Total quantity' as measure_name,SUM(quantity) AS measure_values FROM Gold.fact_sales
UNION ALL
SELECT 'Average Price' as measure_name,AVG(price) AS measure_values FROM Gold.fact_sales
UNION ALL
SELECT 'Total Nr of Orders' as measure_name,COUNT(DISTINCT order_number) AS measure_values FROM Gold.fact_sales
UNION ALL
SELECT 'Total Nr of Products' as measure_name,COUNT(product_name) AS measure_values FROM Gold.dim_products
UNION ALL
SELECT 'Total Nr of Customers' as measure_name,COUNT(customer_key) AS measure_values FROM Gold.dim_customers;

--=====================================
--Magnitude Analysis
--=====================================
--Find total customers by countires
SELECT country,
COUNT(customer_key) AS total_customers 
FROM Gold.dim_customers
GROUP BY country;
--Total customers by Gender
SELECT gender,
COUNT(customer_key) AS total_customers
FROM Gold.dim_customers
GROUP BY gender;
--Find the products by category
SELECT category,
subcategory,
COUNT(product_name) AS total_products
FROM Gold.dim_products
GROUP BY category,subcategory
--ORDER BY COUNT(product_name);

--What is the average cost in each category?
SELECT  
category,
AVG(cost) AS avg_cost
FROM Gold.dim_products
GROUP BY category;

--What is the total revenue generated by each category?
SELECT 
pr.category,
SUM(fs.sales_amount) AS total_revenue
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_products pr
ON fs.product_key = pr.product_key
GROUP BY pr.category
ORDER BY total_revenue DESC;

--Find the total revenue genearted by each customer
SELECT 
cu.customer_key,
cu.first_name,
cu.last_name,
SUM(fs.sales_amount) AS total_revenue
FROM Gold.fact_sales AS fs
LEFT JOIN Gold.dim_customers AS cu
ON fs.customer_key = cu.customer_key
GROUP BY cu.customer_key,
cu.first_name,
cu.last_name
ORDER BY total_revenue DESC;

--What is the distribution of sold items across countries?
SELECT 
cu.country,
SUM(quantity) AS sold_items
FROM Gold.fact_sales AS fs
LEFT JOIN Gold.dim_customers AS cu
ON fs.customer_key = cu.customer_key
GROUP BY country
ORDER BY sold_items DESC;

-- Total number of revenue  by the  Customers who are married?
SELECT 
cu.martial_status,
SUM(fs.sales_amount) AS total_revenue
FROM Gold.fact_sales AS fs
LEFT JOIN Gold.dim_customers AS cu
ON fs.customer_key = cu.customer_key
GROUP BY cu.martial_status
HAVING cu.martial_status = 'Married'
--ORDER BY total_revenue DESC;

--=====================================
--Ranking  Analysis
--=====================================
--Which 5 products generate the highest revenue?
SELECT TOP 5
pr.product_name,
SUM(fs.sales_amount) AS total_revenue
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_products pr
ON fs.product_key = pr.product_key
GROUP BY pr.product_name
ORDER BY total_revenue DESC;

--Using Window Functions
SELECT * FROM 

(SELECT 
pr.product_name,
SUM(fs.sales_amount) AS total_revenue,
ROW_NUMBER() OVER(ORDER BY SUM(fs.sales_amount) DESC) AS rank_revenue
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_products pr
ON fs.product_key = pr.product_key
GROUP BY pr.product_name)t
WHERE rank_revenue <=5

--Which are 5 Worst performing products accoding to sales?
SELECT TOP 5
pr.product_name,
SUM(fs.sales_amount) AS total_revenue
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_products pr
ON fs.product_key = pr.product_key
GROUP BY pr.product_name
ORDER BY total_revenue ASC;

--Using Window Functions
SELECT * FROM 

(SELECT 
pr.product_name,
SUM(fs.sales_amount) AS total_revenue,
ROW_NUMBER() OVER(ORDER BY SUM(fs.sales_amount) ASC) AS rank_revenue
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_products pr
ON fs.product_key = pr.product_key
GROUP BY pr.product_name)t
WHERE rank_revenue <=5

--Find Top 10 customers who have generated the highest revenue
SELECT TOP 10
cu.customer_key,
cu.first_name,
cu.last_name,
SUM(fs.sales_amount) AS total_revenue
FROM Gold.fact_sales AS fs
LEFT JOIN Gold.dim_customers AS cu
ON fs.customer_key = cu.customer_key
GROUP BY cu.customer_key,
cu.first_name,
cu.last_name
ORDER BY total_revenue DESC;
--3 customers with fewest orders
SELECT TOP 3
cu.customer_key,
cu.first_name,
cu.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM Gold.fact_sales AS fs
LEFT JOIN Gold.dim_customers AS cu
ON fs.customer_key = cu.customer_key
GROUP BY cu.customer_key,
cu.first_name,
cu.last_name
ORDER BY total_orders ;
