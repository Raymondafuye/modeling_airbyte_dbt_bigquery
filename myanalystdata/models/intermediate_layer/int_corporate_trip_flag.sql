{{
    config(
        meta={
         'owner': 'data_engineering_team',
         'business_questions': 'Is the trip a corporate trip?'
        },
        materialized='view',
        tags=['operations']
    )
}}



with trips as (

    select * from {{ ref('stg_trips') }}

)

select
    trip_id,
    driver_id,
    rider_id,
    city_id,
    status,
    is_corporate,

    case
        when is_corporate = true then 1
        else 0
    end as corporate_trip_flag

from trips