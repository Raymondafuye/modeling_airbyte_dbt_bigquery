{{
    config(
        meta={
         'owner': 'data_engineering_team',
         'business_questions': 'How many trips has each driver completed in their lifetime?'
        },
        materialized='table',
        tags='operations'
    )
}}



with trips as (

    select * from {{ ref('stg_trips') }}

)

select
    driver_id,

    count(trip_id)  as driver_lifetime_trips
   
from trips
group by driver_id