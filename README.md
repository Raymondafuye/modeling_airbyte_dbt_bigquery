# Ride-Sharing Analytics Platform - dbt Project

## Project Overview
This dbt project transforms raw ride-sharing operational data that is extracted from postgresql into a bigquery database for a analytics-ready models supporting business intelligence, fraud detection, and operational reporting.

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
- **Materialization**: Table
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
- Removal of null primary keys using the where statement

#### 2. Intermediate Layer (`intermediate_layer/`)
- **Purpose**: Reusable business logic and metrics
- **Materialization**: View
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
  - `dim_payments`: Payment made for trips
  - `dim_cities`: City reference data

## Incremental Models

### fct_trips (Incremental Strategy)

**Why Incremental?**
- Trips table grows continuously and contains alot of denomalized data (high volume)
- Full refresh would be expensive and time-consuming
- Only new/updated trips need processing
- Reduces compute costs and runtime

**Tradeoffs**:

| Aspect | Full Refresh | Incremental |
|--------|-------------|-------------|
| **Runtime** | Hours for large datasets | Minutes |
| **Cost** | High (scans all data) | Low (scans new data only) |
| **Complexity** | Simple | Requires unique_key logic |
| **Data Quality** | Always consistent | Risk of drift if logic changes |
| **Use Case** | Small tables, dimension tables | Large fact tables, event logs |

Sample analytical queries demonstrating insights

```sql
-- 1. failed payment on completed trips
select
    t.trip_id,
    t.driver_id,
    t.rider_id,
    t.status,
    p.payment_status,
    case
        when t.status = 'completed' and p.payment_status = 'failed' then true
        else false
    end as is_failed_payment_on_completed_trip

from trips t
left join payments p
    on t.trip_id = p.trip_id
where t.status = 'completed'
-- 2. duplicate trip payments
payment_counts as (

    select
        trip_id,
        count(*) as payment_count
    from payments
    where payment_status = 'success'
    group by trip_id

)

select
    p.payment_id,
    p.trip_id,
    p.payment_status,
    p.payment_provider,
    p.currency,
    p.amount,
    p.fee,
    p.created_at,
    pc.payment_count,
    case
        when pc.payment_count > 1 then true
        else false
    end as is_duplicate_payment

from payments p
left join payment_counts pc on p.trip_id = pc.trip_id





