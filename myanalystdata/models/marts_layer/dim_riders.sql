{{
    config(
        meta={
         'owner': 'data_engineering_team',
    },
        materialized='view',
        tags=['operations']
    )
}}

with riders as (
    select * from {{ ref('stg_riders') }}
),

rider_ltv as (
    select * from {{ ref('rider_lifetime_value') }}
)

select
    r.rider_id,
    r.country,
    r.signup_date,
    r.referral_code,
    r.created_at,
    coalesce(ltv.lifetime_value, 0) as lifetime_value
from riders r
left join rider_ltv ltv on r.rider_id = ltv.rider_id
