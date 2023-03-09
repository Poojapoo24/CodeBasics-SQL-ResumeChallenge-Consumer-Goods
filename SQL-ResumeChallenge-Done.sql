QUERY 1- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT MARKET FROM gdb023.dim_customer WHERE REGION='APAC' AND CUSTOMER="Atliq Exclusive"

QUERY 2- What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields- unique_products_2020, unique_products_2021,
percentage_chg

WITH CTE_Unique_product_2020 AS (SELECT count(DISTINCT product_code) AS unique_products_2020 FROM gdb023.fact_sales_monthly
WHERE fiscal_year=2020),
CTE_Unique_product_2021 AS (SELECT COUNT(DISTINCT product_code) AS unique_products_2021 FROM gdb023.fact_sales_monthly
WHERE fiscal_year=2021)
SELECT unique_products_2020, unique_products_2021,
ROUND ((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
FROM CTE_Unique_product_2020 
CROSS JOIN CTE_Unique_product_2021

QUERY 3- Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains 2 fields- segment, product_count

SELECT segment, COUNT(DISTINCT product_code) AS 'product_count' 
FROM gdb023.dim_product
GROUP BY segment
ORDER BY 2 DESC;

QUERY 4- Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields- segment, product_count_2020,
product_count_2021, difference

WITH cte_2020 AS (SELECT pr.segment, COUNT(DISTINCT pr.product_code) AS 'product_count_2020'
FROM gdb023.dim_product pr 
JOIN gdb023.fact_sales_monthly sales 
ON pr.product_code=sales.product_code 
WHERE sales.fiscal_year=2020
GROUP BY pr.segment),
cte_2021 AS (SELECT pr.segment, COUNT(DISTINCT pr.product_code) AS 'product_count_2021'
FROM gdb023.dim_product pr 
JOIN gdb023.fact_sales_monthly sales 
ON pr.product_code=sales.product_code
WHERE sales.fiscal_year=2021
GROUP BY pr.segment)
SELECT c1.segment, c1.product_count_2020, c2.product_count_2021, c2.product_count_2021-c1.product_count_2020 AS difference 
FROM cte_2020 c1 
INNER JOIN cte_2021 c2
ON c1.segment=c2.segment 
ORDER BY difference ASC;

QUERY 5- Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields- product_code, product,
manufacturing_cost

SELECT pr.product_code, pr.product, mn.manufacturing_cost 
FROM gdb023.fact_manufacturing_cost mn 
INNER JOIN gdb023.dim_product pr 
ON mn.product_code=pr.product_code 
WHERE mn.manufacturing_cost=(SELECT max(manufacturing_cost) 
FROM gdb023.fact_manufacturing_cost)
OR mn.manufacturing_cost=(SELECT min(manufacturing_cost) 
FROM gdb023.fact_manufacturing_cost)

QUERY 6- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields- customer_code, customer, average_discount_percentage

SELECT ds.customer_code, cs.customer, ROUND(100.0*avg(ds.pre_invoice_discount_pct),2) AS 'average_discount_percentage'
FROM gdb023.fact_pre_invoice_deductions ds 
INNER JOIN gdb023.dim_customer cs
ON ds.customer_code=cs.customer_code 
WHERE ds.fiscal_year=2021 and cs.market='India' 
GROUP BY ds.customer_code, cs.customer
ORDER BY 3 DESC LIMIT 5

QUERY 7-Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
The final report contains these columns- Month, Year, Gross sales Amount

SELECT monthname(date) AS 'month', year(date) AS 'Year',
ROUND(sum(sales.sold_quantity*gross.gross_price),2) AS 'Gross sales Amount'
FROM gdb023.fact_sales_monthly sales 
INNER JOIN gdb023.fact_gross_price gross 
ON sales.product_code=gross.product_code 
INNER JOIN gdb023.dim_customer cs 
ON sales.customer_code=cs.customer_code
WHERE cs.customer="Atliq Exclusive" 
GROUP BY 1,2 
ORDER BY 2

QUERY 8- In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter, total_sold_quantity

SELECT
CASE
	WHEN monthname(date) in ('September','October','November') THEN "Q1 of 2020"
	WHEN monthname(date) in ('December','January','February') THEN "Q2 of 2020"
	WHEN monthname(date) in ('March','April','May') THEN "Q3 of 2020"
	WHEN monthname(date) in ('June','July','August') THEN "Q4 of 2020"
END as Quarter,
sum(sold_quantity) as total_sales 
FROM fact_sales_monthly 
WHERE fiscal_year="2020"
GROUP BY Quarter 
ORDER BY total_sales DESC;

QUERY 9- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields- channel, gross_sales_mln, percentage

WITH total_sales_f2021 AS (SELECT cs.channel, ROUND(sum(sales.sold_quantity*gross.gross_price)/1000000,2) AS 'gross_sales_mln'
FROM gdb023.fact_sales_monthly sales 
INNER JOIN gdb023.fact_gross_price gross 
ON sales.product_code=gross.product_code 
INNER JOIN gdb023.dim_customer cs
ON sales.customer_code=cs.customer_code
WHERE sales.fiscal_year=2021 and gross.fiscal_year=2021
GROUP BY 1
ORDER BY 2 DESC)
SELECT total_sales_f2021.channel, total_sales_f2021.gross_sales_mln,
ROUND(100.0*total_sales_f2021.gross_sales_mln/sum(total_sales_f2021.gross_sales_mln) 
OVER(),2) AS percentage 
FROM total_sales_f2021

QUERY 10- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields- division, product_code, product, total_sold_quantity, rank_order

WITH cte_total_sales AS (SELECT pr.division, pr.product_code, pr.product, sum(sales.sold_quantity) AS total_sold_quantity
FROM gdb023.dim_product pr
INNER JOIN gdb023.fact_sales_monthly sales
ON pr.product_code=sales.product_code
WHERE sales.fiscal_year=2021
GROUP BY 1,2,3),
cte_top3 AS (SELECT cte_total_sales.division, cte_total_sales.product_code, cte_total_sales.product, cte_total_sales.total_sold_quantity,
RANK() 
OVER(partition by cte_total_sales.division 
ORDER BY cte_total_sales.total_sold_quantity DESC) AS rank_order 
FROM cte_total_sales) 
SELECT * FROM cte_top3 
WHERE rank_order<=3