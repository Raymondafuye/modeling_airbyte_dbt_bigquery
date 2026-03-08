{{
     config(
         materialized='view',
         tags='finance',
         meta={'owner': 'data_engineering_team',
          'business_questions': 'Which completed trips had a failed payment?'}
     )
}}


with trips as (

    select * from {{ ref('stg_trips') }}

),
payments as (

    select * from {{ ref('stg_payments') }}

)

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