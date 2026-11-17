# Superstore Sales Analytics

End-to-end analytics project using the Superstore retail dataset.

## Project stages

- [x] **01 – Data Warehouse:** load raw data into SQL Server and model it as a star schema
- [ ] **02 – Data Quality:** validate the data with SQL and Python checks
- [ ] **03 – Power BI Dashboard:** build an interactive business performance dashboard

## Tools

SQL Server 2025 · T-SQL · Python (pandas) · Power BI · Git

## Stage 01 – Data Warehouse

The raw CSV (9,994 order lines, 2014–2017) is loaded into a `SuperstoreDW`
database in two layers:

- **`stg`**: the file landed as-is (all text columns), plus a cleaned and typed view, `stg.v_superstore_clean`
- **`dw`**: a star schema for reporting

```
                 dim_date (order date, ship date)
                         |
  dim_customer --- fact_sales --- dim_product
                    /       \
         dim_geography     dim_ship_mode
```

| Table | Grain | Rows |
|---|---|---|
| `fact_sales` | one order line (source `Row ID`) | 9,994 |
| `dim_customer` | customer ID | 793 |
| `dim_product` | product ID + product name | 1,894 |
| `dim_geography` | country / state / city / postal code | 632 |
| `dim_date` | calendar day, 2014-01-01 to 2018-12-31 | 1,826 |
| `dim_ship_mode` | ship mode | 4 |

Measures on `fact_sales`: `sales`, `quantity`, `discount`, `profit`.
`order_id` is kept on the fact as a degenerate dimension.

### Data issues found and handled

| Issue | Handling |
|---|---|
| File is Windows-1252 with CRLF line endings | `BULK INSERT` uses `CODEPAGE = '1252'` and a `0x0d0a` row terminator |
| Postal codes lost their leading zero (438 rows, e.g. `2108` for Boston) | Left-padded to 5 digits |
| Product names contain non-breaking spaces | Replaced with normal spaces |
| 32 product IDs are reused for different product names | `dim_product` grain is product ID + name, not ID alone |
| 8 order + product pairs appear on two separate lines | Kept as separate lines (each has its own `Row ID`); to be reviewed in Stage 02 |

### Reconciliation

`06_reconcile.sql` compares the raw staging table with `fact_sales`. All checks pass:

| Check | Source | Warehouse |
|---|---|---|
| Row count | 9,994 | 9,994 |
| Total sales | 2,297,200.8603 | 2,297,200.8603 |
| Total quantity | 37,873 | 37,873 |
| Total profit | 286,397.0217 | 286,397.0217 |

### How to run

Requires SQL Server (the scripts assume the local `SQLEXPRESS` instance) and `sqlcmd`.
From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File sql\01_data_warehouse\run_stage01.ps1
```

This runs scripts `01`–`06` in `sql/01_data_warehouse/` in order. It is safe to re-run, because
the scripts drop and rebuild the tables each time.
Use `-Server <name>` to target a different instance.

🚧 In progress
