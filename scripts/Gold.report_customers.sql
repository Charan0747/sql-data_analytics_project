/*
--=================================================================================
--Customer Report
--=================================================================================
Purpose :
	-This Reprt consolidate key metircs and behaviours
Highlights:
	1.Gather Essential fields, such as names,ages, and transcation details
	2.Segment Customers onto categories(VIP,Regular,New) and ages groups.
	3.Aggregate customer level mertics:
		-total orders,
		-total customers,
		-total sales,
		-total qunatity,
		-total products,
		-lifespan(in months)
	4.Calculate the valuable KPIs:
		-recency(months since last order)
		-average order value
		-average monthly spend
=================================================================================
*/
IF OBJECT_ID('Gold.report_customers' , 'V') IS NOT NULL
	DROP VIEW Gold.report_customers
GO


CREATE VIEW Gold.report_customers AS
WITH base_query AS 
--=======================================================
--Base Query:Retrieves the core columns from the tables
--=======================================================
(
	SELECT 
	fs.order_number,
	fs.product_key,
	fs.order_date,
	fs.sales_amount,
	fs.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name ,' ',c.last_name) AS customer_name,
	DATEDIFF(YEAR,c.birthdate,GETDATE()) AS age
	FROM Gold.fact_sales AS fs
	LEFT JOIN Gold.dim_customers AS c
	ON fs.customer_key = c.customer_key
	WHERE order_date IS NOT NULL
)
,customer_aggregation AS
(
	SELECT
	--=======================================================
	--Aggregation:Retrieves the key metrics and aggregations
	--=======================================================
		customer_key,
		customer_number,
		customer_name,
		age,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order_date,
		DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY 
		customer_key,
		customer_number,
		customer_name,
		age
)
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20-29'
		 WHEN age BETWEEN 30 AND 39 THEN '30-39'
		 WHEN age BETWEEN 40 AND 49 THEN '40-49'
		 ELSE '50 and Above'
	END AS age_group,

	CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
			WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
			ELSE 'New'
	END AS customer_segment,
	last_order_date,
	DATEDIFF(month,last_order_date,GETDATE()) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	--Compute average order value(AOV)
	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales / total_orders 
	END AS avg_order_value,
	--compute average monthly spend (AMS)
	CASE WHEN lifespan = 0 THEN total_sales
		 ELSE total_sales / lifespan
	END AS avg_montly_spend
FROM customer_aggregation;

