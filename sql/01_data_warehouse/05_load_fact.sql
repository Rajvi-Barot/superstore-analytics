/*
  05_load_fact.sql
  Loads dw.fact_sales at order-line grain (one row per source Row ID) by
  looking up each dimension's surrogate key.
  Inner joins are deliberate: if any line fails to find its dimension row,
  it drops out and the row-count check in 06_reconcile.sql fails.
*/
USE SuperstoreDW;
GO

INSERT INTO dw.fact_sales (row_id, order_id, order_date_key, ship_date_key,
                           customer_key, product_key, geography_key, ship_mode_key,
                           sales, quantity, discount, profit)
SELECT
    s.row_id,
    s.order_id,
    YEAR(s.order_date) * 10000 + MONTH(s.order_date) * 100 + DAY(s.order_date),
    YEAR(s.ship_date)  * 10000 + MONTH(s.ship_date)  * 100 + DAY(s.ship_date),
    c.customer_key,
    p.product_key,
    g.geography_key,
    m.ship_mode_key,
    s.sales,
    s.quantity,
    s.discount,
    s.profit
FROM stg.v_superstore_clean s
JOIN dw.dim_customer  c ON c.customer_id  = s.customer_id
JOIN dw.dim_product   p ON p.product_id   = s.product_id
                       AND p.product_name = s.product_name
JOIN dw.dim_geography g ON g.country      = s.country
                       AND g.state        = s.state
                       AND g.city         = s.city
                       AND g.postal_code  = s.postal_code
JOIN dw.dim_ship_mode m ON m.ship_mode    = s.ship_mode;
GO

SELECT COUNT(*) AS fact_rows FROM dw.fact_sales;
GO
