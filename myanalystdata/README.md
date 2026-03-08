# Ride-Sharing Analytics Platform - dbt Project

## Project Overview
This dbt project transforms raw ride-sharing operational data into analytics-ready models supporting business intelligence, fraud detection, and operational reporting.

## Architecture Diagram

<img width="1008" height="359" alt="image" src="https://github.com/user-attachments/assets/71bfa420-8a77-45a4-8bd9-c2eeb9c29a92" />

## Entity Relationship Diagram
<img width="1417" height="609" alt="image" src="https://github.com/user-attachments/assets/e6d7dff5-e5fe-47a0-b331-1d473a1f43bd" />

### Data flow explanation
```
raw → staging → intermediate → marts
```

#### 1. Staging Layer (`staging_layer/`)
- **Purpose**: Clean, deduplicate, and standardize raw data
- **Materialization**: Views
- **Models**:
  - `stg_trips`: Cleaned trip transactions
  - `stg_drivers`: Driver master data
  - `stg_riders`: Rider profiles
  - `stg_payments`: Payment transactions
  - `stg_cities`: City reference data
  - `stg_drivers_status_events`: Driver status event log

**Transformations Applied**:
- Column renaming to snake_case
- Data type casting (int64, numeric, timestamp)
- Deduplication using ROW_NUMBER() over primary keys
- Removal of null primary keys
- Timestamp standardization to UTC

#### 2. Intermediate Layer (`intermediate_layer/`)
- **Purpose**: Reusable business logic and metrics
- **Materialization**: Ephemeral (not persisted)
- **Models**:
  - `int_duration_min`: Trip duration calculation
  - `int_driver_life_time_trips`: Driver trip counts
  - `rider_lifetime_value`: Rider LTV calculation
  - `int_corporate_trip_flag`: Corporate trip identification
  - `int_net_revenue`: Revenue after fees
  - `int_fraud_indicators`: Fraud detection signals
  - `int_duplicate_trip_payments`: Duplicate payment detection
  - `int_failed_payment_on_completed_trip`: Payment failure detection
  - `int_extreme_surge`: Surge multiplier > 10 detection

#### 3. Marts Layer (`marts_layer/`)
- **Purpose**: Star schema for analytics consumption
- **Materialization**: Tables (except fct_trips which is incremental)

**Star Schema**:
- **Fact Table**:
  - `fct_trips`: Core transactional fact table with all trip metrics

- **Dimension Tables**:
  - `dim_drivers`: Driver attributes and lifetime metrics
  - `dim_riders`: Rider profiles and LTV
  - `dim_cities`: City reference data
  - `dim_dates`: Date dimension for time-based analysis

## Incremental Models

### fct_trips (Incremental Strategy)

**Why Incremental?**
- Trips table grows continuously (high volume)
- Full refresh would be expensive and time-consuming
- Only new/updated trips need processing
- Reduces compute costs and runtime

**Implementation**:
```sql
config(
    materialized='incremental',
    unique_key='trip_id',
    on_schema_change='fail'
)
```

**Filter Logic**:
```sql
{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %}
```

**Tradeoffs**:

| Aspect | Full Refresh | Incremental |
|--------|-------------|-------------|
| **Runtime** | Hours for large datasets | Minutes |
| **Cost** | High (scans all data) | Low (scans new data only) |
| **Complexity** | Simple | Requires unique_key logic |
| **Data Quality** | Always consistent | Risk of drift if logic changes |
| **Use Case** | Small tables, dimension tables | Large fact tables, event logs |

**When to Full Refresh**:
- Schema changes detected
- Logic changes in upstream models
- Data quality issues requiring reprocessing
- Run: `dbt run --full-refresh --select fct_trips`

## Snapshots (SCD Type 2)

### snap_drivers
Tracks historical changes to driver attributes:
- `driver_status` changes (active → suspended → inactive)
- `vehicle_id` changes (vehicle reassignments)
- `rating` updates (performance tracking)

**Strategy**: Timestamp-based using `updated_at`

**Usage**:
```bash
dbt snapshot
```

## Data Quality

### Generic Tests
- `not_null`: Primary keys, foreign keys, critical fields
- `unique`: Primary keys
- `relationships`: Foreign key integrity
- `accepted_values`: Status fields, categorical data

### Custom Tests
1. **test_no_negative_revenue.sql**
   - Ensures net_revenue ≥ 0
   - Catches fee > amount errors

2. **test_trip_duration_positive.sql**
   - Ensures completed trips have duration > 0
   - Validates pickup_at < dropoff_at

3. **test_completed_trip_has_payment.sql**
   - Ensures completed trips have successful payments
   - Validates referential integrity

### Freshness Tests
- `trips_raw`: < 2 hours (critical operational data)
- `payments_raw`: < 8 hours (financial data)
- `drivers_raw`: < 24 hours (reference data)

## Macros

### calculate_net_revenue
```sql
{% macro calculate_net_revenue(amount_input, fee_input) %}
    {{ amount_input }} - {{ fee_input }}
{% endmacro %}
```
**Usage**: Standardizes revenue calculation across models

## Business Metrics

| Metric | Definition | Location |
|--------|-----------|----------|
| **Trip Duration** | Minutes from pickup to dropoff | `int_duration_min` |
| **Net Revenue** | Amount - Fee | `int_net_revenue` |
| **Rider LTV** | Total successful payments per rider | `rider_lifetime_value` |
| **Driver Lifetime Trips** | Total trips per driver | `int_driver_life_time_trips` |
| **Fraud Suspect** | Extreme surge OR duplicate payment OR failed payment on completed trip | `int_fraud_indicators` |

## Analytics Use Cases

### 1. Daily Revenue Dashboard
```sql
select
    date(requested_at) as trip_date,
    sum(net_revenue) as daily_revenue,
    count(trip_id) as trip_count
from {{ ref('fct_trips') }}
where trip_status = 'completed'
group by 1
```

### 2. City-Level Profitability
```sql
select
    c.city_name,
    c.country,
    sum(f.net_revenue) as total_revenue,
    count(f.trip_id) as total_trips
from {{ ref('fct_trips') }} f
join {{ ref('dim_cities') }} c on f.city_id = c.city_id
group by 1, 2
```

### 3. Driver Leaderboard
```sql
select
    driver_id,
    lifetime_trips,
    rating
from {{ ref('dim_drivers') }}
where driver_status = 'active'
order by lifetime_trips desc
limit 100
```

### 4. Rider LTV Analysis
```sql
select
    country,
    avg(lifetime_value) as avg_ltv,
    count(rider_id) as rider_count
from {{ ref('dim_riders') }}
group by 1
```

### 5. Payment Reliability Report
```sql
select
    payment_provider,
    payment_status,
    count(*) as transaction_count,
    sum(net_revenue) as total_revenue
from {{ ref('fct_trips') }}
group by 1, 2
```

### 6. Fraud Monitoring View
```sql
select
    trip_id,
    rider_id,
    driver_id,
    is_extreme_surge,
    is_duplicate_payment,
    is_failed_payment_on_completed_trip
from {{ ref('fct_trips') }}
where is_fraud_suspect = true
```

## Metadata & Governance

### Tags
- `finance`: Revenue-impacting models
- `operations`: Operational metrics
- `fraud`: Fraud detection models
- `staging`: Staging layer
- `intermediate`: Intermediate layer
- `marts`: Marts layer

### Ownership
- **Staging/Intermediate**: Data Engineering Team
- **Marts**: Data Engineering Team
- **Dimensions**: Operations Team

## Running the Project

### Initial Setup
```bash
cd myanalystdata
dbt deps  # Install packages
dbt debug  # Verify connection
```

### Development Workflow
```bash
dbt run  # Run all models
dbt test  # Run all tests
dbt snapshot  # Run snapshots
dbt docs generate  # Generate documentation
dbt docs serve  # View docs locally
```

### Production Workflow
```bash
dbt source freshness  # Check data freshness
dbt run --select tag:staging  # Run staging layer
dbt run --select tag:intermediate  # Run intermediate layer
dbt run --select tag:marts  # Run marts layer
dbt test  # Validate data quality
dbt snapshot  # Capture SCD changes
```

### Selective Runs
```bash
dbt run --select fct_trips  # Run single model
dbt run --select fct_trips+  # Run model and downstream
dbt run --select +fct_trips  # Run model and upstream
dbt run --full-refresh --select fct_trips  # Full refresh incremental
```

## Documentation

Generate and view lineage graph:
```bash
dbt docs generate
dbt docs serve
```

Access at: http://localhost:8080

## Technology Stack
- **Orchestration**: Airbyte (data ingestion)
- **Transformation**: dbt Core
- **Warehouse**: BigQuery
- **Version Control**: Git & GitHub
- **Packages**: dbt-utils, codegen

## Project Structure
```
myanalystdata/
├── models/
│   ├── staging_layer/
│   ├── intermediate_layer/
│   └── marts_layer/
├── snapshots/
├── tests/
├── macros/
├── dbt_project.yml
└── packages.yml
```

## Contact
For questions or issues, contact the Data Engineering Team.
