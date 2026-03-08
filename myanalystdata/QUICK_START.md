# Quick Start Guide

## Prerequisites
- dbt Core installed
- BigQuery connection configured in `~/.dbt/profiles.yml`
- Service account JSON key file in place

## Step-by-Step Execution

### 1. Navigate to Project Directory
```bash
cd myanalystdata
```

### 2. Install Dependencies
```bash
dbt deps
```
This installs:
- dbt-utils (for date_spine and other utilities)
- codegen (for code generation helpers)

### 3. Verify Connection
```bash
dbt debug
```
Expected output: "All checks passed!"

### 4. Check Source Freshness
```bash
dbt source freshness
```
Validates that raw data is up-to-date.

### 5. Run Models (Layered Approach)

#### Option A: Run All at Once
```bash
dbt run
```

#### Option B: Run by Layer (Recommended)
```bash
# Staging layer (views)
dbt run --select tag:staging

# Intermediate layer (ephemeral)
dbt run --select tag:intermediate

# Marts layer (tables + incremental)
dbt run --select tag:marts
```

### 6. Run Tests
```bash
dbt test
```
This runs:
- Generic tests (not_null, unique, relationships, accepted_values)
- Custom tests (negative revenue, trip duration, payment validation)

### 7. Run Snapshots
```bash
dbt snapshot
```
Creates SCD Type 2 table for driver history.

### 8. Generate Documentation
```bash
dbt docs generate
dbt docs serve
```
Access at: http://localhost:8080

## Common Commands

### Selective Runs
```bash
# Run single model
dbt run --select fct_trips

# Run model and all downstream
dbt run --select fct_trips+

# Run model and all upstream
dbt run --select +fct_trips

# Run specific layer
dbt run --select staging_layer.*
```

### Full Refresh Incremental Model
```bash
dbt run --full-refresh --select fct_trips
```

### Run Specific Tests
```bash
# Test single model
dbt test --select fct_trips

# Run custom tests only
dbt test --select test_type:singular
```

### Compile Without Running
```bash
dbt compile
```
Useful for debugging SQL.

## Troubleshooting

### Issue: "Profile should not be None"
**Solution**: Make sure you're in the `myanalystdata` directory, not the parent folder.

### Issue: "Compilation Error"
**Solution**: Run `dbt deps` to install packages first.

### Issue: "Database Error"
**Solution**: Check BigQuery credentials and permissions in `~/.dbt/profiles.yml`

### Issue: Incremental model not updating
**Solution**: Run with full refresh:
```bash
dbt run --full-refresh --select fct_trips
```

## Expected Runtime (Approximate)

| Command | Runtime |
|---------|---------|
| `dbt deps` | 10-30 seconds |
| `dbt run` (first time) | 5-10 minutes |
| `dbt run` (incremental) | 1-3 minutes |
| `dbt test` | 2-5 minutes |
| `dbt snapshot` | 30-60 seconds |
| `dbt docs generate` | 10-20 seconds |

## Validation Checklist

After running, verify:
- [ ] All models built successfully (check `target/run_results.json`)
- [ ] All tests passed (0 failures)
- [ ] Snapshot table created in `snapshots` schema
- [ ] Documentation site loads at localhost:8080
- [ ] Lineage graph shows all model dependencies

## Production Deployment

For production, run in this order:
```bash
dbt source freshness  # Check data freshness
dbt run              # Build models
dbt test             # Validate data quality
dbt snapshot         # Capture historical changes
```

Schedule this workflow to run daily/hourly based on your needs.

## Support

For issues or questions:
1. Check `logs/dbt.log` for detailed error messages
2. Review `target/compiled/` for compiled SQL
3. Consult README.md for detailed documentation
4. Contact Data Engineering Team
