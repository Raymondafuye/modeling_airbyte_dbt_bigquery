{{
    config(
        meta={
         'owner': 'data_engineering_team',
         'business_questions': 'Are there any duplicate payments for the same trip?'
        },
        materialized='view',
        tags='operations'
    )
}}



with payments as (

    select * from {{ ref('stg_payments') }}

),

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