{{
     config(
         materialized='view',
         tags='fraud',
         meta={'owner': 'data_engineering_team',
          'business_questions': 'Which trips had fraud indicators such as extreme surge, duplicate payments, or failed payments on completed trips?'}
     )
}}

with trips as (

    select * from {{ ref('stg_trips') }}

),

extreme_surge as (

    select
        trip_id,
        is_extreme_surge,
        surge_category,
        surge_multiplier
    from {{ ref('int_extreme_surge') }}

),

duplicate_payments as (

    select
        trip_id,
        is_duplicate_payment,
        payment_count
    from {{ ref('int_duplicate_trip_payments') }}

),

failed_payments as (

    select
        trip_id,
        is_failed_payment_on_completed_trip,
        payment_status
    from {{ ref('int_failed_payment_on_completed_trip') }}

)

select
    t.trip_id,
    t.driver_id,
    t.rider_id,
    t.city_id,
    t.status   as trip_status,
    t.actual_fare,
    t.requested_at,
    coalesce(es.is_extreme_surge, false)                as is_extreme_surge,
    coalesce(dp.is_duplicate_payment, false)            as is_duplicate_payment,
    coalesce(fp.is_failed_payment_on_completed_trip, false)
                                                        as is_failed_payment_on_completed_trip,
    es.surge_multiplier,
    es.surge_category,
    dp.payment_count,
    fp.payment_status,
    case
        when coalesce(es.is_extreme_surge, false)                               then true
        when coalesce(dp.is_duplicate_payment, false)                           then true
        when coalesce(fp.is_failed_payment_on_completed_trip, false)            then true
        else false
    end     as is_fraud_suspect,
 
from trips t
left join extreme_surge  es on t.trip_id = es.trip_id
left join duplicate_payments dp on t.trip_id = dp.trip_id
left join failed_payments    fp on t.trip_id = fp.trip_id
