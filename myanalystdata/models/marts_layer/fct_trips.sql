{{
    config(
        materialized='incremental',
        unique_key='trip_id',
        partition_by={'field': 'created_at', 'data_type': 'timestamp'},
        tags='operations',
        meta={'owner': 'data_engineering_team'}
    )
}}

with trips as (
    select * from {{ ref('stg_trips') }}
    {% if is_incremental() %}
    where created_at > (select max(created_at) from {{ this }})
    {% endif %}
),

payments as (
    select * from {{ ref('dim_payments') }}
),

trip_duration as (
    select * from {{ ref('int_duration_min') }}
),


fraud_indicators as (
    select * from {{ ref('int_fraud_indicators') }}
)

select
    t.trip_id,
    t.rider_id,
    t.driver_id,
    t.city_id,
    t.vehicle_id,
    t.status as trip_status,
    t.payment_method,
    t.is_corporate,
    t.estimated_fare,
    t.actual_fare,
    t.surge_multiplier,
    t.requested_at,
    t.pickup_at,
    t.dropoff_at,
    t.created_at,
    t.updated_at,
    td.trip_duration_minutes,
    p.net_revenue,
    p.payment_status,
    p.payment_provider,
    p.currency,
    fi.is_fraud_suspect,
    fi.is_extreme_surge,
    fi.is_duplicate_payment,
    fi.is_failed_payment_on_completed_trip
from trips t
left join trip_duration td on t.trip_id = td.trip_id
left join payments p on t.trip_id = p.trip_id
left join fraud_indicators fi on t.trip_id = fi.trip_id
