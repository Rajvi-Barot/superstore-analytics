/*
  03_create_star_schema.sql
  Star schema for Superstore sales.

      dim_date (order date / ship date)
      dim_customer        \
      dim_product          >---  fact_sales  (one row per order line)
      dim_geography       /
      dim_ship_mode

  Surrogate keys (INT IDENTITY) are used everywhere except dim_date, whose
  key is the date as YYYYMMDD so it is readable in queries.
  Drops and recreates all dw tables, so the whole load can be re-run.
*/
USE SuperstoreDW;
GO

DROP TABLE IF EXISTS dw.fact_sales;
DROP TABLE IF EXISTS dw.dim_date;
DROP TABLE IF EXISTS dw.dim_customer;
DROP TABLE IF EXISTS dw.dim_product;
DROP TABLE IF EXISTS dw.dim_geography;
DROP TABLE IF EXISTS dw.dim_ship_mode;
GO

CREATE TABLE dw.dim_date (
    date_key        INT          NOT NULL PRIMARY KEY,   -- YYYYMMDD
    full_date       DATE         NOT NULL UNIQUE,
    [year]          SMALLINT     NOT NULL,
    [quarter]       TINYINT      NOT NULL,
    quarter_label   CHAR(2)      NOT NULL,               -- Q1..Q4
    [month]         TINYINT      NOT NULL,
    month_name      VARCHAR(10)  NOT NULL,
    month_short     CHAR(3)      NOT NULL,
    year_month      CHAR(7)      NOT NULL,               -- e.g. 2016-11
    day_of_month    TINYINT      NOT NULL,
    day_of_week     TINYINT      NOT NULL,               -- 1 = Monday
    day_name        VARCHAR(10)  NOT NULL,
    is_weekend      BIT          NOT NULL
);

CREATE TABLE dw.dim_customer (
    customer_key    INT IDENTITY(1,1) PRIMARY KEY,
    customer_id     NVARCHAR(20)  NOT NULL UNIQUE,       -- natural key
    customer_name   NVARCHAR(100) NOT NULL,
    segment         NVARCHAR(30)  NOT NULL
);

-- Grain is product_id + product_name: in the source, 32 product IDs are
-- reused for more than one product name, so product_id alone is not unique.
CREATE TABLE dw.dim_product (
    product_key     INT IDENTITY(1,1) PRIMARY KEY,
    product_id      NVARCHAR(20)  NOT NULL,
    product_name    NVARCHAR(255) NOT NULL,
    category        NVARCHAR(30)  NOT NULL,
    sub_category    NVARCHAR(30)  NOT NULL,
    CONSTRAINT uq_dim_product UNIQUE (product_id, product_name)
);

CREATE TABLE dw.dim_geography (
    geography_key   INT IDENTITY(1,1) PRIMARY KEY,
    country         NVARCHAR(50)  NOT NULL,
    region          NVARCHAR(20)  NOT NULL,
    state           NVARCHAR(50)  NOT NULL,
    city            NVARCHAR(100) NOT NULL,
    postal_code     CHAR(5)       NOT NULL,
    CONSTRAINT uq_dim_geography UNIQUE (country, state, city, postal_code)
);

CREATE TABLE dw.dim_ship_mode (
    ship_mode_key   INT IDENTITY(1,1) PRIMARY KEY,
    ship_mode       NVARCHAR(30)  NOT NULL UNIQUE
);

CREATE TABLE dw.fact_sales (
    sales_key        INT IDENTITY(1,1) PRIMARY KEY,
    row_id           INT            NOT NULL UNIQUE,     -- source line id
    order_id         NVARCHAR(20)   NOT NULL,            -- degenerate dimension
    order_date_key   INT            NOT NULL REFERENCES dw.dim_date(date_key),
    ship_date_key    INT            NOT NULL REFERENCES dw.dim_date(date_key),
    customer_key     INT            NOT NULL REFERENCES dw.dim_customer(customer_key),
    product_key      INT            NOT NULL REFERENCES dw.dim_product(product_key),
    geography_key    INT            NOT NULL REFERENCES dw.dim_geography(geography_key),
    ship_mode_key    INT            NOT NULL REFERENCES dw.dim_ship_mode(ship_mode_key),
    sales            DECIMAL(18,4)  NOT NULL,
    quantity         INT            NOT NULL,
    discount         DECIMAL(5,4)   NOT NULL,
    profit           DECIMAL(18,4)  NOT NULL
);

CREATE INDEX ix_fact_sales_order_date ON dw.fact_sales(order_date_key);
CREATE INDEX ix_fact_sales_customer   ON dw.fact_sales(customer_key);
CREATE INDEX ix_fact_sales_product    ON dw.fact_sales(product_key);
CREATE INDEX ix_fact_sales_geography  ON dw.fact_sales(geography_key);
GO
