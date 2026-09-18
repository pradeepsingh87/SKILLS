-- OPTIMIZED QUERY: Best practices applied
-- Improvements: partition pruning, proper join keys, pre-filtering, 
-- efficient grouping, reduced shuffle

WITH filtered_dates AS (
  -- Push-down filter: reduce date dimension first
  SELECT d_date_sk, d_year, d_moy
  FROM samples.tpcds_sf1.date_dim
  WHERE d_year BETWEEN 2000 AND 2003
),
filtered_items AS (
  -- Push-down filter: reduce item dimension first
  SELECT i_item_sk, i_product_name, i_category
  FROM samples.tpcds_sf1.item
  WHERE i_category IN ('Books', 'Electronics', 'Sports')
),
filtered_customers AS (
  -- Push-down filter: reduce customer dimension first
  SELECT c_customer_sk, c_first_name, c_last_name
  FROM samples.tpcds_sf1.customer
  WHERE LENGTH(c_first_name) > 3
)
SELECT 
  c.c_first_name || ' ' || c.c_last_name as customer_name,
  i.i_product_name as product_name,
  i.i_category,
  d.d_year as sale_year,
  d.d_moy as sale_month,
  COUNT(DISTINCT ss.ss_ticket_number) as transaction_count,
  SUM(ss.ss_sales_price) as total_sales,
  AVG(ss.ss_sales_price) as avg_sale_price,
  SUM(ss.ss_net_profit) as total_profit
FROM samples.tpcds_sf1.store_sales ss
-- GOOD: Integer joins on surrogate keys (no type conversion)
INNER JOIN filtered_dates d 
  ON ss.ss_sold_date_sk = d.d_date_sk
INNER JOIN filtered_items i 
  ON ss.ss_item_sk = i.i_item_sk
INNER JOIN filtered_customers c 
  ON ss.ss_customer_sk = c.c_customer_sk
GROUP BY 
  c.c_first_name,
  c.c_last_name,
  i.i_product_name,
  i.i_category,
  d.d_year,
  d.d_moy
HAVING SUM(ss.ss_sales_price) > 100
ORDER BY total_sales DESC
LIMIT 1000
