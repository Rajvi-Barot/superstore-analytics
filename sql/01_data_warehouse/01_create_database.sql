/*
  01_create_database.sql
  Creates the SuperstoreDW database and its two schemas:
    stg - raw landing tables, loaded as-is from the CSV
    dw  - cleaned star schema (dimensions + fact) used for reporting
  Safe to re-run.
*/
IF DB_ID('SuperstoreDW') IS NULL
    CREATE DATABASE SuperstoreDW;
GO

USE SuperstoreDW;
GO

IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
IF SCHEMA_ID('dw')  IS NULL EXEC('CREATE SCHEMA dw');
GO
