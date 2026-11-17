/*
  04_load_dimensions.sql
  Builds a typed, cleaned view over staging and loads the dimension tables.

  Cleaning rules (applied once, in stg.v_superstore_clean):
    - Dates are M/D/YYYY in the file, so they are converted with style 101.
    - Postal codes lost their leading zero (e.g. 2108 instead of 02108 for
      Boston), so they are left-padded to 5 digits.
    - Product names contain non-breaking spaces (CHAR 160), which are
      replaced with normal spaces and trimmed.
*/
USE SuperstoreDW;
GO

CREATE OR ALTER VIEW stg.v_superstore_clean AS
SELECT
    CONVERT(INT, row_id)                          AS row_id,
    TRIM(order_id)                                AS order_id,
    CONVERT(DATE, order_date, 101)                AS order_date,
    CONVERT(DATE, ship_date, 101)                 AS ship_date,
    TRIM(ship_mode)                               AS ship_mode,
    TRIM(customer_id)                             AS customer_id,
    TRIM(customer_name)                           AS customer_name,
    TRIM(segment)                                 AS segment,
    TRIM(country)                                 AS country,
    TRIM(city)                                    AS city,
    TRIM(state)                                   AS state,
    RIGHT('00000' + TRIM(postal_code), 5)         AS postal_code,
    TRIM(region)                                  AS region,
    TRIM(product_id)                              AS product_id,
    TRIM(category)                                AS category,
    TRIM(sub_category)                            AS sub_category,
    TRIM(REPLACE(product_name, NCHAR(160), N' ')) AS product_name,
    CONVERT(DECIMAL(18,4), sales)                 AS sales,
    CONVERT(INT, quantity)                        AS quantity,
    CONVERT(DECIMAL(5,4), discount)               AS discount,
    CONVERT(DECIMAL(18,4), profit)                AS profit
FROM stg.superstore_raw;
GO

-- dim_date: one row per day for every full calendar year the data touches
DECLARE @start DATE, @end DATE;
SELECT @start = DATEFROMPARTS(YEAR(MIN(d)), 1, 1),
       @end   = DATEFROMPARTS(YEAR(MAX(d)), 12, 31)
FROM (SELECT order_date AS d FROM stg.v_superstore_clean
      UNION ALL
      SELECT ship_date FROM stg.v_superstore_clean) x;

WITH days AS (
    SELECT DATEADD(DAY, value, @start) AS d
    FROM GENERATE_SERIES(0, DATEDIFF(DAY, @start, @end))
),
dow AS (
    -- Monday = 1 ... Sunday = 7, whatever the server's DATEFIRST setting
    SELECT d, (DATEPART(WEEKDAY, d) + @@DATEFIRST - 2) % 7 + 1 AS day_of_week
    FROM days
)
INSERT INTO dw.dim_date (date_key, full_date, [year], [quarter], quarter_label,
                         [month], month_name, month_short, year_month,
                         day_of_month, day_of_week, day_name, is_weekend)
SELECT
    YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
    d,
    YEAR(d),
    DATEPART(QUARTER, d),
    'Q' + CAST(DATEPART(QUARTER, d) AS CHAR(1)),
    MONTH(d),
    DATENAME(MONTH, d),
    LEFT(DATENAME(MONTH, d), 3),
    CONVERT(CHAR(7), d, 126),
    DAY(d),
    day_of_week,
    DATENAME(WEEKDAY, d),
    CASE WHEN day_of_week IN (6, 7) THEN 1 ELSE 0 END
FROM dow;

INSERT INTO dw.dim_customer (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM stg.v_superstore_clean;

INSERT INTO dw.dim_product (product_id, product_name, category, sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category
FROM stg.v_superstore_clean;

INSERT INTO dw.dim_geography (country, region, state, city, postal_code)
SELECT DISTINCT country, region, state, city, postal_code
FROM stg.v_superstore_clean;

INSERT INTO dw.dim_ship_mode (ship_mode)
SELECT DISTINCT ship_mode
FROM stg.v_superstore_clean;
GO

SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM dw.dim_date
UNION ALL SELECT 'dim_customer',  COUNT(*) FROM dw.dim_customer
UNION ALL SELECT 'dim_product',   COUNT(*) FROM dw.dim_product
UNION ALL SELECT 'dim_geography', COUNT(*) FROM dw.dim_geography
UNION ALL SELECT 'dim_ship_mode', COUNT(*) FROM dw.dim_ship_mode;
GO
