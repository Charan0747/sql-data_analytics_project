--===================================
--Change-Over-Time Analysis
--===================================

SELECT 
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date) ;

--Monthly Report 
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date) ,MONTH(order_date) 
ORDER BY YEAR(order_date),MONTH(order_date);

SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date) 
ORDER BY DATETRUNC(month,order_date) ;


--===================================
--Cummulative Analysis
--===================================
--Calculate the total sales per month 
--and running taotal of each month

SELECT 
order_date,
total_sales,
SUM(total_sales) OVER(ORDER BY order_date) AS running_total,
AVG(avg_price) OVER(ORDER BY order_date) AS moving_avg_price
FROM
(
SELECT 
DATETRUNC(YEAR,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
FROM Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
)t

--===================================
--Performance Analysis
--===================================
/*Analyze the yearly performance of products by comparing each product's sales 
to both its average sales performance years sales*/
WITH yearly_avg_performance AS(
SELECT 
YEAR(fs.order_date) AS order_year,
pr.product_name,
SUM(fs.sales_amount) AS current_sales
FROM Gold.fact_sales AS fs
LEFT JOIN Gold.dim_products AS pr
ON fs.product_key = pr.product_key
WHERE order_date IS NOT NULL
GROUP BY pr.product_name,YEAR(fs.order_date)
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
	 ELSE 'Avg'
END AS avg_change,
--Year-over-year Analysis
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS prev_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_prev,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'No Change'
END AS prev_change
FROM yearly_avg_performance
ORDER BY product_name,order_year

--===================================
--Part-to-whole Analysis
--===================================
/* Which Categories contribute the most to overall sales*/
WITH category_sales AS
(
	SELECT 
	pr.category,
	SUM(fs.sales_amount) AS total_sales
	FROM Gold.fact_sales AS fs
	LEFT JOIN Gold.dim_products AS pr
	ON fs.product_key = pr.product_key
	GROUP BY pr.category
)
SELECT 
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER()) * 100, 2), '%') AS percentage_of_contribution
FROM category_sales
ORDER BY total_sales DESC;

--===================================
--Data Segmanetation
--===================================
/*Segment products into cost ranges and count how many products fall into each segment*/
WITH products_segment AS 
(
	SELECT 
	product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'Above 1000'
	END AS cost_range
	FROM Gold.dim_products
)
SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM products_segment
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group Customers into segments based on theor spending behaviour:
   VIP:atleast 12 months of history and spend more than 5000
    Regular:atleast 12 months of history and spending 5000 or less
	New : below history of 12 months
	and find the total number of customers by each group.*/
WITH customer_spending AS
(
	SELECT 
	c.customer_key,
	SUM(fs.sales_amount) AS total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
	FROM Gold.fact_sales AS fs
	LEFT JOIN Gold.dim_customers AS c
	ON fs.customer_key = c.customer_key
	GROUP BY c.customer_key
)

SELECT
customer_segment,
COUNT(customer_key) AS total_customers 
FROM
(
	SELECT 
	customer_key,
	CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment
	FROM customer_spending
)t
GROUP BY customer_segment
ORDER BY total_customers DESC;

		
