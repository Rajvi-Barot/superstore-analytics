/*
  02_load_staging.sql
  Lands data/superstore.csv into stg.superstore_raw exactly as it is in the file.
  Every column is text so the load never fails on bad values; type conversion
  happens later, where it can be checked.

  $(DataPath) is the full path to the CSV. run_stage01.ps1 sets it as an
  environment variable, which sqlcmd picks up as a scripting variable.
*/
USE SuperstoreDW;
GO

DROP TABLE IF EXISTS stg.superstore_raw;
CREATE TABLE stg.superstore_raw (
    row_id         NVARCHAR(20),
    order_id       NVARCHAR(50),
    order_date     NVARCHAR(20),
    ship_date      NVARCHAR(20),
    ship_mode      NVARCHAR(50),
    customer_id    NVARCHAR(50),
    customer_name  NVARCHAR(100),
    segment        NVARCHAR(50),
    country        NVARCHAR(50),
    city           NVARCHAR(100),
    state          NVARCHAR(50),
    postal_code    NVARCHAR(20),
    region         NVARCHAR(50),
    product_id     NVARCHAR(50),
    category       NVARCHAR(50),
    sub_category   NVARCHAR(50),
    product_name   NVARCHAR(255),
    sales          NVARCHAR(50),
    quantity       NVARCHAR(20),
    discount       NVARCHAR(20),
    profit         NVARCHAR(50)
);
GO

-- FORMAT = 'CSV' handles quoted fields that contain commas (e.g. product names).
-- CODEPAGE 1252: the file is Windows-1252 encoded, not UTF-8.
BULK INSERT stg.superstore_raw
FROM '$(DataPath)'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDQUOTE      = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0d0a',  -- file uses Windows (CRLF) line endings
    CODEPAGE        = '1252',
    TABLOCK
);
GO

SELECT COUNT(*) AS staged_rows FROM stg.superstore_raw;
GO
