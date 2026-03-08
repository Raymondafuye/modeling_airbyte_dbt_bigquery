{{
     config(
         materialized='view',
         tags='operations',
         meta={'owner': 'data_engineering_team',
          'business_questions': 'What is the duration of each trip in minutes?'}
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
    pickup_at,
    dropoff_at,

    timestamp_diff(dropoff_at, pickup_at, minute) as trip_duration_minutes

from trips