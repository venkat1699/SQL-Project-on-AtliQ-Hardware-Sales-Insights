-- 1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region--

select customer,market,region 
from 
dim_customer where region = 'APAC' 
and customer = 'Atliq Exclusive';


select count(distinct product_code),segment from dim_product group by segment order by segment desc;

-- 02 --

WITH unique_products_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
),
unique_products_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021
)
SELECT 
    u2020.unique_products_2020,
    u2021.unique_products_2021,
    ROUND(((u2021.unique_products_2021 - u2020.unique_products_2020) / CAST(u2020.unique_products_2020 AS FLOAT)) * 100, 2) AS percentage_change
FROM 
    unique_products_2020 u2020
CROSS JOIN 
    unique_products_2021 u2021;
    
-- 03 --


select distinct(count(product)) as product_count,
 segment from dim_product 
 group by segment 
 order by product_count;  
 
 
 -- 04 --
 
 
WITH product_counts AS (
    SELECT 
        dp.segment,
        COUNT(DISTINCT CASE WHEN fms.fiscal_year = 2020 THEN fms.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN fms.fiscal_year = 2021 THEN fms.product_code END) AS product_count_2021
    FROM 
        fact_sales_monthly fms
    JOIN 
        dim_product dp ON fms.product_code = dp.product_code
    GROUP BY 
        dp.segment
)
SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 AS difference
FROM 
    product_counts
ORDER BY 
    difference DESC
LIMIT 1;


-- 05 --

SELECT 
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM 
    fact_manufacturing_cost fmc
JOIN 
    dim_product dp ON fmc.product_code = dp.product_code
WHERE 
    fmc.manufacturing_cost  = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    OR 
    fmc.manufacturing_cost = (SELECT MIN(manufacturing_cost)  FROM fact_manufacturing_cost);

-- 06 --

SELECT 
    dc.customer_code,
    dc.customer,
    ROUND(AVG(fpid.pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM 
    fact_pre_invoice_deductions fpid
JOIN 
    dim_customer dc ON fpid.customer_code = dc.customer_code
WHERE 
    fpid.fiscal_year = 2021
    AND dc.market = 'India'
GROUP BY 
    dc.customer_code, dc.customer
ORDER BY 
    average_discount_percentage DESC
LIMIT 5;

select * from fact_sales_monthly;


-- 07 --


SELECT 
    EXTRACT(MONTH FROM fsm.date) AS month,
    EXTRACT(YEAR FROM fsm.date) AS year,
    ROUND(SUM(fgp.gross_price * fsm.sold_quantity), 2) AS gross_sales_amount
FROM 
    fact_sales_monthly fsm
JOIN 
    dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN 
    fact_gross_price fgp ON fsm.product_code = fgp.product_code
WHERE 
    dc.customer = 'Atliq Exclusive'
GROUP BY 
    year, month
ORDER BY 
    year, month;
    
    
-- 08 --


WITH sales_quarters AS (
    SELECT 
        CASE 
            WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
            WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
            WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
            WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
        END AS Quarter,
        SUM(sold_quantity) AS total_sold_quantity
    FROM 
        fact_sales_monthly
    WHERE 
        fiscal_year = 2020
    GROUP BY 
        Quarter
)
SELECT 
    Quarter, 
    total_sold_quantity
FROM 
    sales_quarters
ORDER BY 
    total_sold_quantity DESC
LIMIT 1;

-- 09 --

WITH sales_data AS (
    SELECT 
        dc.channel,
        ROUND(SUM(fgp.gross_price * fsm.sold_quantity) / 1000000, 2) AS gross_sales_mln
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_customer dc ON fsm.customer_code = dc.customer_code
    JOIN 
        fact_gross_price fgp ON fsm.product_code = fgp.product_code
    WHERE 
        fsm.fiscal_year = 2021
    GROUP BY 
        dc.channel
), total_sales AS (
    SELECT SUM(gross_sales_mln) AS total_gross_sales FROM sales_data
)
SELECT 
    sd.channel,
    sd.gross_sales_mln,
    ROUND((sd.gross_sales_mln / ts.total_gross_sales) * 100, 2) AS percentage
FROM 
    sales_data sd, total_sales ts
ORDER BY 
    gross_sales_mln DESC
LIMIT 1;

select * from fact_sales_monthly;    
 
-- 10 --

WITH product_sales AS (
    SELECT 
        dp.division,
        fsm.product_code,
        dp.product,
        SUM(fsm.sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS rank_order
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_product dp ON fsm.product_code = dp.product_code
    WHERE 
        fsm.fiscal_year = 2021
    GROUP BY 
        dp.division, fsm.product_code, dp.product
)
SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM 
    product_sales
WHERE 
    rank_order <= 3
ORDER BY 
    division, rank_order;

    
