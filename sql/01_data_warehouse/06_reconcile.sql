/*
  06_reconcile.sql
  Confirms nothing was lost or changed between the raw file and the star
  schema: row count and the total of every measure must match exactly.
  Any row with status = 'FAIL' means the load needs investigating.
*/
USE SuperstoreDW;
GO

WITH src AS (
    SELECT COUNT(*)                            AS row_count,
           SUM(CONVERT(DECIMAL(18,4), sales))  AS sales,
           SUM(CONVERT(INT, quantity))         AS quantity,
           SUM(CONVERT(DECIMAL(18,4), profit)) AS profit
    FROM stg.superstore_raw
),
wh AS (
    SELECT COUNT(*) AS row_count, SUM(sales) AS sales,
           SUM(quantity) AS quantity, SUM(profit) AS profit
    FROM dw.fact_sales
)
SELECT v.check_name, v.source_value, v.warehouse_value,
       CASE WHEN v.source_value = v.warehouse_value THEN 'PASS' ELSE 'FAIL' END AS status
FROM src CROSS JOIN wh
CROSS APPLY (VALUES
    ('row count',      CAST(src.row_count AS DECIMAL(18,4)), CAST(wh.row_count AS DECIMAL(18,4))),
    ('total sales',    src.sales,                            wh.sales),
    ('total quantity', CAST(src.quantity AS DECIMAL(18,4)),  CAST(wh.quantity AS DECIMAL(18,4))),
    ('total profit',   src.profit,                           wh.profit)
) v(check_name, source_value, warehouse_value);
GO
