# Runs every Stage 01 script in order against the local SQL Server Express instance.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File sql\01_data_warehouse\run_stage01.ps1
param(
    [string]$Server = "localhost\SQLEXPRESS"
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# sqlcmd reads environment variables as scripting variables, so
# 02_load_staging.sql can use $(DataPath) for the CSV location.
$env:DataPath = (Resolve-Path (Join-Path $here "..\..\data\superstore.csv")).Path

$scripts = "01_create_database.sql", "02_load_staging.sql", "03_create_star_schema.sql",
           "04_load_dimensions.sql", "05_load_fact.sql", "06_reconcile.sql"

foreach ($s in $scripts) {
    Write-Host "`n=== $s ===" -ForegroundColor Cyan
    sqlcmd -S $Server -E -C -b -W -i (Join-Path $here $s)
    if ($LASTEXITCODE -ne 0) { throw "$s failed" }
}
