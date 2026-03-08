{{
     config(
         materialized='view',
         tags='operations',
         meta={'owner': 'data_engineering_team',
          'business_questions': 'What is the net revenue for each payment, accounting for fees and payment status?'}
     )
}}
with payments as (

    select * from {{ ref('int_duplicate_trip_payments') }}

)

select
    payment_id,
    trip_id,
    payment_status,
    payment_provider,
    currency,
    amount,
    fee,

    case
        when payment_status = 'success'
            then {{ calculate_net_revenue('amount', 'fee') }}
        else 0
    end as net_revenue

from payments