-- ANTI-PATTERN QUERY: Multiple performance issues intentionally included
-- Expected issues: excessive shuffling, no partition pruning, Cartesian products, 
-- unnecessary string operations, missing DISTINCT on aggregations

SELECT 
  CONCAT(c.c_first_name, ' ', c.c_last_name) as customer_name,
  UPPER(i.i_product_name) as product_name,
  i.i_category,
  CAST(d.d_year AS STRING) as sale_year,
  CAST(d.d_moy AS STRING) as sale_month,
  COUNT(*) as transaction_count,
  SUM(ss.ss_sales_price) as total_sales,
  AVG(ss.ss_sales_price) as avg_sale_price,
  SUM(ss.ss_net_profit) as total_profit
FROM samples.tpcds_sf1.store_sales ss
-- BAD: Using string-based join instead of surrogate keys
INNER JOIN samples.tpcds_sf1.customer c 
  ON CAST(ss.ss_customer_sk AS STRING) = CAST(c.c_customer_sk AS STRING)
-- BAD: Joining on non-key columns causing shuffle
INNER JOIN samples.tpcds_sf1.item i 
  ON CAST(ss.ss_item_sk AS STRING) = CAST(i.i_item_sk AS STRING)
-- BAD: No partition pruning on date dimension
INNER JOIN samples.tpcds_sf1.date_dim d 
  ON ss.ss_sold_date_sk = d.d_date_sk
-- BAD: Filtering AFTER join instead of before
WHERE d.d_year >= 2000 
  AND d.d_year <= 2003
  AND UPPER(i.i_category) IN ('BOOKS', 'ELECTRONICS', 'SPORTS')
  AND LENGTH(c.c_first_name) > 3
GROUP BY 
  CONCAT(c.c_first_name, ' ', c.c_last_name),
  UPPER(i.i_product_name),
  i.i_category,
  CAST(d.d_year AS STRING),
  CAST(d.d_moy AS STRING)
HAVING SUM(ss.ss_sales_price) > 100
ORDER BY total_sales DESC
LIMIT 1000
