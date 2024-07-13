-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select market from dim_customer where customer="Atliq Exclusive" and region="APAC" 

/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/

with up20 AS
(SELECT count(distinct(product_code)) AS unique_products_2020
FROM fact_sales_monthly WHERE fiscal_year=2020),

up21 AS (SELECT count(distinct(product_code)) AS unique_products_2021
FROM fact_sales_monthly WHERE fiscal_year=2021)

SELECT unique_products_2020,
	   unique_products_2021,
       round((((unique_products_2021-unique_products_2020)/unique_products_2020)*100),2) AS percent_chg
FROM up20
JOIN up21;

/* 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

select segment,
count(segment) as product_count from dim_product
group by segment
order by product_count desc

-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH unique_2020 AS
(SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count_2020
FROM dim_product as p
INNER JOIN fact_sales_monthly AS s
ON p.product_code=s.product_code
WHERE s.fiscal_year=2020
GROUP BY p.segment
ORDER BY product_count_2020 DESC
),

unique_2021 AS(SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count_2021
FROM dim_product AS p 
INNER JOIN fact_sales_monthly AS s
ON p.product_code=s.product_code
WHERE s.fiscal_year=2021
GROUP BY p.segment
ORDER BY product_count_2021 DESC)

SELECT a.segment, a.product_count_2020, b.product_count_2021, (b.product_count_2021-a.product_count_2020) as difference
FROM unique_2020 a
JOIN unique_2021 b
on a.segment = b.segment;

-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost


-- -------------------- -- solution-------------------
SELECT p.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost AS m 
INNER JOIN dim_product AS p
ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
UNION
SELECT p.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost AS m INNer join dim_product AS p
ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- ----------------------------------- -- or------------

SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F 
JOIN dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
	SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    ) 
ORDER BY manufacturing_cost DESC ;

-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

SELECT c.customer_code, c.customer, p.pre_invoice_discount_pct
FROM dim_customer as c
INNER join fact_pre_invoice_deductions AS p
ON c.customer_code = p.customer_code
WHERE p.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions) AND c.market='India' AND p.fiscal_year = 2021
ORDER BY p.pre_invoice_discount_pct DESC
LIMIT 5;


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount


SELECT MONTH(s.date) AS month,
YEAR(s.date) AS year,
SUM(ROUND((s.sold_quantity*g.gross_price),2)) AS gross_sales_amount
FROM fact_sales_monthly AS s 
INNER JOIN fact_gross_price AS g
ON s.product_code=g.product_code
INNER JOIN dim_customer AS c
ON s.customer_code=c.customer_code
WHERE c.customer = 'atliq exclusive'
GROUP BY month, year
ORDER BY year;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with tab1 as
(
select c.channel,
round(sum((s.sold_quantity*g.gross_price)/1000000),2) as gross_sales_mln
FROM fact_sales_monthly AS s
	INNER JOIN fact_gross_price AS g
	ON  s.product_code = g.product_code
	INNER JOIN dim_customer AS c
	ON s.customer_code = c.customer_code
where s.fiscal_year=2021
group by channel
ORDER BY gross_sales_mln DESC
)
SELECT *, gross_sales_mln*100/SUM(gross_sales_mln) OVER() AS percent
FROM tab1;



-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code

WITH division_sales_cte AS 
	(
    SELECT p.division, s.product_code,p.product, SUM(s.sold_quantity) AS 'total_sold_qty', 
	row_number() OVER (PARTITION BY p.division ORDER BY sum(s.sold_quantity) DESC) AS rank_order
	FROM fact_sales_monthly AS s 
	INNER JOIN dim_product AS p
	ON s.product_code = p.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.division, s.product_code, p.product
    )
SELECT division, product_code, product, total_sold_qty, rank_order
FROM division_sales_cte
WHERE rank_order <= 3;


