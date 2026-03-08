{{
     config(
         materialized='table',
         tags='operations',
         meta={'owner': 'data_engineering_team',
          'business_questions': 'What is the lifetime value of each rider based on successful payments?'}
     )
}}



with trips as (
    select * from {{ ref('stg_trips') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

trip_payments as (
    select
        t.trip_id,
        t.rider_id,
        p.payment_id,
        p.amount,
        p.fee,
        p.payment_status
    from trips t
    left join payments p on t.trip_id = p.trip_id
)

select
    rider_id,
    sum(case when payment_status = 'success' then amount else 0 end) as lifetime_value
from trip_payments
group by rider_id