{{
  config(
    materialized = 'view',
    tags=['finance'],
    meta={'owner': 'data_engineering_team'}
    )
}}

with payments as (

    select * from {{ ref('stg_payments') }}

),

int_net_revenue as (

    select * from {{ ref('int_net_revenue') }}
)

select
   p.payment_id,
    p.trip_id,
    p.payment_status,
    p.payment_provider,
    p.currency,
    p.amount,
   nr.net_revenue
   from payments p
   left join int_net_revenue nr on p.payment_id = nr.payment_id 

